"""Vendor-neutral synthetic deployment, health and rollback control model.

This module is an executable experiment, not a deployment controller. It does
not contact cloud infrastructure, a container registry, a secret manager, a
database, a load balancer, or a production environment.
"""
from __future__ import annotations

import hashlib
import io
import json
import subprocess
import sys
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Mapping

from build import BUILD_TYPE, BUILDER_ID

SECRET_ENV = "LOTTORITO_SYNTHETIC_RUNTIME_SECRET"
ALLOWED_ENVIRONMENTS = {"test", "staging"}
RETIRE_CONFIRMATION = "RETIRE_ROLLBACK_TARGET"


class DeploymentError(RuntimeError):
    pass


class GateRejected(DeploymentError):
    pass


class DeploymentConflict(DeploymentError):
    pass


def digest_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def verify_artifact_bytes(data: bytes, expected_digest: str) -> bool:
    return expected_digest == f"sha256:{digest_bytes(data)}"


def read_release_metadata(data: bytes) -> dict[str, Any]:
    try:
        with zipfile.ZipFile(io.BytesIO(data), "r") as archive:
            names = archive.namelist()
            if sorted(names) != ["__main__.py", "release.json"] or len(names) != len(set(names)):
                raise GateRejected("artifact_file_set_invalid")
            for name in names:
                if name.startswith("/") or ".." in Path(name).parts:
                    raise GateRejected("artifact_path_invalid")
            metadata = json.loads(archive.read("release.json"))
    except (zipfile.BadZipFile, KeyError, json.JSONDecodeError) as exc:
        raise GateRejected("artifact_invalid") from exc
    if metadata.get("product") != "affiliate_agent":
        raise GateRejected("artifact_product_invalid")
    if not isinstance(metadata.get("version"), str) or not metadata["version"].strip():
        raise GateRejected("artifact_version_missing")
    if (
        isinstance(metadata.get("min_schema"), bool)
        or not isinstance(metadata.get("min_schema"), int)
        or isinstance(metadata.get("max_schema"), bool)
        or not isinstance(metadata.get("max_schema"), int)
    ):
        raise GateRejected("artifact_schema_support_invalid")
    if metadata["min_schema"] < 1 or metadata["max_schema"] < metadata["min_schema"]:
        raise GateRejected("artifact_schema_range_invalid")
    return metadata


def verify_provenance(data: bytes, provenance: Mapping[str, Any], expected_digest: str,
                      expected_source_revision: str) -> bool:
    try:
        subject = provenance["subject"]
        predicate = provenance["predicate"]
        build_definition = predicate["buildDefinition"]
        run_details = predicate["runDetails"]
        subject_digest = subject[0]["digest"]["sha256"]
        source_revision = build_definition["externalParameters"]["source_revision"]
        product = build_definition["externalParameters"]["product"]
        build_type = build_definition["buildType"]
        builder_id = run_details["builder"]["id"]
        dependency_digest = build_definition["resolvedDependencies"][0]["digest"]["sha256"]
    except (KeyError, IndexError, TypeError):
        return False
    try:
        with zipfile.ZipFile(__import__("io").BytesIO(data), "r") as archive:
            entrypoint_digest = digest_bytes(archive.read("__main__.py"))
    except (zipfile.BadZipFile, KeyError):
        return False
    if not isinstance(subject, list) or not isinstance(predicate, dict) or not isinstance(build_definition, dict):
        return False
    if not isinstance(run_details, dict):
        return False
    return (
        provenance.get("_type") == "https://in-toto.io/Statement/v1"
        and provenance.get("predicateType") == "https://slsa.dev/provenance/v1"
        and len(subject) == 1
        and subject_digest == expected_digest.removeprefix("sha256:")
        and verify_artifact_bytes(data, expected_digest)
        and source_revision == expected_source_revision
        and product == "affiliate_agent"
        and build_type == BUILD_TYPE
        and builder_id == BUILDER_ID
        and dependency_digest == entrypoint_digest
    )


@dataclass(frozen=True)
class RuntimeSecret:
    reference: str
    value: str


def run_artifact(artifact_path: Path, secret: RuntimeSecret | None = None) -> str:
    # Pass an allowlisted environment only; never inherit ambient CI/host secrets.
    env: dict[str, str] = {}
    if secret is not None:
        if not isinstance(secret.reference, str) or not secret.reference.startswith("secret://") or not isinstance(secret.value, str) or not secret.value:
            raise GateRejected("runtime_secret_reference_invalid")
        env[SECRET_ENV] = secret.value
    result = subprocess.run(
        [sys.executable, str(artifact_path)],
        check=False,
        capture_output=True,
        text=True,
        env=env,
        timeout=5,
    )
    if result.returncode != 0:
        raise GateRejected("artifact_runtime_failed")
    if secret is not None and secret.value in result.stdout + result.stderr:
        raise GateRejected("runtime_secret_leaked_to_output")
    return result.stdout.strip()


@dataclass(frozen=True)
class HealthSnapshot:
    startup_complete: bool = True
    process_alive: bool = True
    critical_dependencies: Mapping[str, bool] = field(default_factory=dict)
    worker_ready: bool = True

    @property
    def liveness_ok(self) -> bool:
        # Downstream dependency outages must not trigger restart loops.
        return self.process_alive is True

    @property
    def readiness_ok(self) -> bool:
        return (
            self.startup_complete is True
            and self.process_alive is True
            and all(value is True for value in self.critical_dependencies.values())
        )

    @property
    def worker_readiness_ok(self) -> bool:
        return self.readiness_ok and self.worker_ready is True


@dataclass(frozen=True)
class Approval:
    requested_by: str
    approved_by: str
    role: str
    environment: str
    artifact_digest: str
    valid: bool = True


@dataclass
class DeploymentState:
    environment: str
    schema_version: int
    current_digest: str
    previous_digest: str | None = None
    api_digest: str | None = None
    worker_digest: str | None = None
    traffic_enabled: bool = False
    workers_enabled: bool = False
    financial_state_digest: str = "synthetic-ledger-state-v1"
    audit: list[dict[str, Any]] = field(default_factory=list)


class ImmutableArtifactStore:
    def __init__(self) -> None:
        self._artifacts: dict[str, bytes] = {}

    def put(self, data: bytes) -> str:
        digest = f"sha256:{digest_bytes(data)}"
        existing = self._artifacts.get(digest)
        if existing is not None and existing != data:
            raise DeploymentConflict("digest_collision")
        self._artifacts.setdefault(digest, bytes(data))
        return digest

    def get(self, digest: str) -> bytes:
        data = self._artifacts.get(digest)
        if data is None:
            raise GateRejected("artifact_not_found")
        if not verify_artifact_bytes(data, digest):
            raise GateRejected("stored_artifact_digest_mismatch")
        return bytes(data)

    def contains(self, digest: str) -> bool:
        return digest in self._artifacts


def _require_actor_identity(actor: str) -> None:
    if not isinstance(actor, str) or not actor.strip():
        raise GateRejected("actor_identity_invalid")


def _require_approval_identities(approval: Approval, actor: str) -> None:
    _require_actor_identity(actor)
    if (
        not isinstance(approval.requested_by, str) or not approval.requested_by.strip()
        or not isinstance(approval.approved_by, str) or not approval.approved_by.strip()
    ):
        raise GateRejected("approval_identity_invalid")


class DeploymentController:
    def __init__(self, store: ImmutableArtifactStore) -> None:
        self.store = store

    def _metadata(self, digest: str) -> dict[str, Any]:
        return read_release_metadata(self.store.get(digest))

    def _gate(self, state: DeploymentState, digest: str, approval: Approval,
              actor: str, api_health: HealthSnapshot) -> dict[str, Any]:
        if state.environment not in ALLOWED_ENVIRONMENTS:
            raise GateRejected("environment_not_allowed")
        _require_approval_identities(approval, actor)
        if approval.valid is not True or approval.environment != state.environment:
            raise GateRejected("approval_invalid_or_wrong_environment")
        if approval.artifact_digest != digest:
            raise GateRejected("approval_digest_mismatch")
        if approval.role != "release_approver":
            raise GateRejected("release_approver_required")
        if approval.approved_by in {approval.requested_by, actor}:
            raise GateRejected("separation_of_duties_violation")
        metadata = self._metadata(digest)
        if not (metadata["min_schema"] <= state.schema_version <= metadata["max_schema"]):
            raise GateRejected("artifact_schema_incompatible")
        if not api_health.readiness_ok:
            raise GateRejected("api_readiness_failed")
        return metadata

    def promote(self, state: DeploymentState, digest: str, approval: Approval,
                actor: str, expected_current_digest: str,
                api_health: HealthSnapshot, worker_health: HealthSnapshot,
                provenance: Mapping[str, Any], expected_source_revision: str) -> dict[str, Any]:
        if state.environment not in ALLOWED_ENVIRONMENTS:
            raise GateRejected("environment_not_allowed")
        if state.current_digest != expected_current_digest:
            raise DeploymentConflict("stale_current_release")
        if state.api_digest != state.current_digest or state.worker_digest != state.current_digest:
            raise DeploymentConflict("active_component_release_drift")
        artifact = self.store.get(digest)
        if not verify_provenance(artifact, provenance, digest, expected_source_revision):
            raise GateRejected("provenance_verification_failed")
        metadata = self._gate(state, digest, approval, actor, api_health)
        before = (state.api_digest, state.worker_digest, state.traffic_enabled, state.workers_enabled)
        # Stage API first. Traffic remains closed until the worker also passes.
        state.api_digest = digest
        state.traffic_enabled = False
        if not worker_health.worker_readiness_ok:
            state.api_digest, state.worker_digest, state.traffic_enabled, state.workers_enabled = before
            state.audit.append(self._audit(actor, state, digest, "rollout.rejected", "worker_readiness_failed"))
            raise GateRejected("worker_readiness_failed")
        state.worker_digest = digest
        state.workers_enabled = False
        # Both API and worker are healthy before either receives live work.
        state.current_digest = digest
        state.previous_digest = expected_current_digest
        state.traffic_enabled = True
        state.workers_enabled = True
        state.audit.append(self._audit(actor, state, digest, "release.promoted", "accepted"))
        return {"status": "promoted", "digest": digest, "version": metadata["version"]}

    def rollback(self, state: DeploymentState, target_digest: str, expected_current_digest: str,
                 actor: str, approval: Approval, api_health: HealthSnapshot,
                 worker_health: HealthSnapshot) -> dict[str, Any]:
        if state.environment not in ALLOWED_ENVIRONMENTS:
            raise GateRejected("environment_not_allowed")
        if state.current_digest != expected_current_digest:
            raise DeploymentConflict("stale_current_release")
        if state.api_digest != state.current_digest or state.worker_digest != state.current_digest:
            raise DeploymentConflict("active_component_release_drift")
        _require_approval_identities(approval, actor)
        if approval.valid is not True or approval.environment != state.environment or approval.artifact_digest != target_digest:
            raise GateRejected("approval_invalid_or_wrong_environment")
        if approval.role != "release_approver" or approval.approved_by in {approval.requested_by, actor}:
            raise GateRejected("separation_of_duties_violation")
        if target_digest != state.previous_digest:
            raise GateRejected("rollback_target_not_previous_release")
        metadata = self._metadata(target_digest)
        if not (metadata["min_schema"] <= state.schema_version <= metadata["max_schema"]):
            raise GateRejected("rollback_schema_incompatible")
        if not api_health.readiness_ok or not worker_health.worker_readiness_ok:
            raise GateRejected("rollback_health_gate_failed")
        failed_digest = state.current_digest
        state.current_digest = target_digest
        state.api_digest = target_digest
        state.worker_digest = target_digest
        state.previous_digest = failed_digest
        state.traffic_enabled = True
        state.workers_enabled = True
        state.audit.append(self._audit(actor, state, target_digest, "release.rolled_back", "accepted"))
        return {"status": "rolled_back", "digest": target_digest}

    @staticmethod
    def _audit(actor: str, state: DeploymentState, digest: str, action: str, outcome: str) -> dict[str, Any]:
        return {
            "actor": actor,
            "environment": state.environment,
            "artifact_digest": digest,
            "action": action,
            "outcome": outcome,
            "schema_version": state.schema_version,
            "financial_state_digest": state.financial_state_digest,
        }

    def retire_rollback_target(self, state: DeploymentState, target_schema_version: int,
                               confirmation: str, actor: str, approval: Approval) -> None:
        if state.environment not in ALLOWED_ENVIRONMENTS:
            raise GateRejected("environment_not_allowed")
        if state.api_digest != state.current_digest or state.worker_digest != state.current_digest:
            raise DeploymentConflict("active_component_release_drift")
        if confirmation != RETIRE_CONFIRMATION:
            raise GateRejected("explicit_retirement_confirmation_required")
        _require_approval_identities(approval, actor)
        if approval.valid is not True or approval.environment != state.environment or approval.artifact_digest != state.current_digest:
            raise GateRejected("approval_invalid_or_wrong_environment")
        if approval.role != "release_approver" or approval.approved_by in {approval.requested_by, actor}:
            raise GateRejected("separation_of_duties_violation")
        if state.previous_digest is None:
            raise GateRejected("no_rollback_target")
        if target_schema_version != state.schema_version + 1:
            raise GateRejected("rollback_retirement_target_schema_invalid")
        active = self._metadata(state.current_digest)
        if not (active["min_schema"] <= state.schema_version <= active["max_schema"]):
            raise GateRejected("active_release_current_schema_incompatible")
        if not (active["min_schema"] <= target_schema_version <= active["max_schema"]):
            raise GateRejected("active_release_cannot_read_target_schema")
        previous = self._metadata(state.previous_digest)
        if previous["min_schema"] <= target_schema_version <= previous["max_schema"]:
            raise GateRejected("rollback_target_still_compatible")
        retired_digest = state.previous_digest
        state.previous_digest = None
        state.audit.append({
            "actor": actor,
            "environment": state.environment,
            "artifact_digest": state.current_digest,
            "retired_artifact_digest": retired_digest,
            "action": "rollback_target.retired",
            "outcome": "accepted",
            "schema_version": state.schema_version,
            "financial_state_digest": state.financial_state_digest,
        })

    def migrate_schema(self, state: DeploymentState, target_version: int, phase: str, actor: str) -> None:
        if state.environment not in ALLOWED_ENVIRONMENTS:
            raise GateRejected("environment_not_allowed")
        _require_actor_identity(actor)
        if phase not in {"expand", "contract"} or target_version != state.schema_version + 1:
            raise GateRejected("migration_transition_invalid")
        if state.api_digest != state.current_digest or state.worker_digest != state.current_digest:
            raise DeploymentConflict("active_component_release_drift")
        active = self._metadata(state.current_digest)
        if not (active["min_schema"] <= state.schema_version <= active["max_schema"]):
            raise GateRejected("active_release_current_schema_incompatible")
        if not (active["min_schema"] <= target_version <= active["max_schema"]):
            raise GateRejected("active_release_cannot_read_target_schema")
        if state.previous_digest is not None:
            previous = self._metadata(state.previous_digest)
            if not (previous["min_schema"] <= target_version <= previous["max_schema"]):
                raise GateRejected("rollback_target_incompatible")
        state.schema_version = target_version
        state.audit.append(self._audit(actor, state, state.current_digest, f"schema.{phase}", "accepted"))
