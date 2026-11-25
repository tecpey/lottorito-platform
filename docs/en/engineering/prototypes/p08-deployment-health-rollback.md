# P-08 — Deployment, Health Gates and Rollback Safety

**Document ID:** LOT-PROT-P08-001 | **Version:** 0.3.0 | **Status:** Synthetic deployment-control implementation; CI evidence tracked on Draft PR #59; no deployment platform or production release approved

## 1. Decision question and boundary

Can Lottorito promote one immutable artifact through isolated non-production environments, inject runtime-only secrets, block activation when API or worker health gates fail, and recover safely across compatible and incompatible schema states without changing financial state?

P-08 is the eighth required experiment in LOT-PROT-001. It follows P-07C and consumes its product lifecycle and schema-compatibility concepts. This experiment deliberately does **not** select Kubernetes, a managed container platform, a VM model, a registry, a secret manager, a deployment vendor or an infrastructure topology. The current repository has no production application or deployable product runtime; therefore the executable fixture is a vendor-neutral Python zipapp and an in-memory deployment control model.

Only test and staging fixture environments are eligible. Production is rejected by code. No public endpoint, cloud resource, real customer, real secret, financial transaction or production data is used.

## 2. Research-informed design

- **Artifact identity:** build a deterministic archive, calculate its SHA-256 digest and promote the exact bytes. Environment configuration and runtime secrets are not baked into the artifact.
- **Provenance:** create a detached in-toto Statement v1-shaped record using the SLSA provenance predicate URI https://slsa.dev/provenance/v1; bind its subject digest to the actual artifact, and check source revision, builder identity, build type and resolved entrypoint digest. SLSA v1.2 is the current specification. This fixture checks field consistency only; it does not create or verify a cryptographic signature, establish a trusted builder or claim SLSA conformance.
- **Secret separation:** the build step receives no application secret. A synthetic secret is supplied only to a fresh runtime process by a test-only injection function. Artifact, detached provenance and captured process output are checked for a unique canary value. This is not a general-purpose secret scanner or a production secret manager.
- **Health semantics:** startup completion, process liveness, API readiness and worker readiness are separate signals. Liveness depends on process health, not downstream dependency availability; readiness requires startup completion and every dependency classified as critical. Worker activation has its own readiness gate. Non-boolean health values fail closed, and component release-pointer drift blocks lifecycle transitions. This avoids turning a dependency outage into an unnecessary process-restart loop.
- **Safe rollout:** the API candidate is staged while traffic remains closed. The worker must also be ready before either API traffic or worker processing is enabled. If the worker gate fails after API staging, the partial candidate is reverted to the previous pointers.
- **Schema-aware recovery:** an older artifact may be rolled back only if it can read the current schema. Schema transitions are permitted only when the active release and any retained rollback target both support the target schema; each accepted schema transition records its actor and release digest in the synthetic audit. Contract is blocked while an incompatible rollback target remains. Retirement itself requires exact-environment/digest approval by a distinct release approver and an explicit target-schema confirmation. Once that target is retired, an incompatible rollback is rejected and a schema-compatible forward repair is required.
- **Separation of duties:** approval binds the exact artifact digest and environment. The approver must have the release-approver role and must differ from both requester and deployer. Staging/test promotion is auditable; production is not an allowed target.

The health model is informed by Kubernetes' distinction between startup, liveness and readiness probes, without selecting Kubernetes as the deployment platform. Release and rollback principles are informed by Google's SRE canary/release engineering guidance. Provenance fields follow the SLSA v1.2 / in-toto model; a field-shaped fixture is not a signed attestation.

## 3. Executable fixture

Files under prototypes/p08-deployment provide:

- build.py: deterministic zipapp construction with normalized archive timestamps, sorted entries and fixed file modes; refuses to overwrite an existing output.
- fixtures/v1, fixtures/v2, fixtures/v3: synthetic application versions with different supported schema ranges.
- src/pipeline.py: artifact digest verification, detached provenance checks, runtime secret injection, health snapshots, an immutable digest-keyed in-memory store, approval policy, staged promotion, schema transitions and rollback/forward-repair guards.
- tests/test_p08.py: positive and adversarial tests using only Python's standard library.
- .github/workflows/p08-deployment-health-rollback.yml: pinned-checkout CI validation, repeat-build byte comparison and test execution.

The artifact store and deployment controller are in-memory test doubles. The zipapp is a real generated file with a verifiable digest, but it is not a container image and is not deployed to an infrastructure environment.

## 4. Acceptance criteria

| ID | Required result |
|---|---|
| P08-01 | Identical build inputs produce byte-identical artifacts and the same SHA-256 digest. |
| P08-02 | Any pre-existing build output directory content is rejected rather than overwritten; artifact tampering is detected by digest verification. |
| P08-03 | Detached provenance subject digest, source revision, product, build type, builder and resolved entrypoint digest must match the artifact/build inputs. |
| P08-04 | A canary secret injected at runtime is absent from artifact bytes, provenance and captured process output; ambient host/CI environment secrets are not inherited by the child process. |
| P08-05 | Startup, liveness, API readiness and worker readiness have distinct semantics; critical dependency failure blocks readiness without falsely failing process liveness, non-boolean health values fail closed, and component pointer drift blocks promotion/rollback. |
| P08-06 | The exact same artifact digest can be promoted from test to staging; stale compare-and-swap state is rejected for promotion and rollback. |
| P08-07 | Approval must match digest and environment; requester, approver and deployer separation is enforced; production target is denied. |
| P08-08 | API readiness failure prevents candidate activation; worker readiness failure restores partial API staging and leaves stable traffic/workers active. |
| P08-09 | Rollback is accepted only when the target artifact supports the current schema. |
| P08-10 | Schema expansion/contraction is blocked if the active or retained rollback release cannot read the target schema; rollback-target retirement requires two-person approval and explicit target-schema confirmation; after retirement, unsafe rollback is denied and compatible forward repair succeeds. |
| P08-11 | Promotion, rollback and schema transitions preserve the synthetic financial-state fingerprint. |
| P08-12 | Audit records for promotion, rollback, rollback-target retirement and schema transitions require a non-empty actor identity and identify environment, artifact digest, action, outcome and schema version without recording runtime secret values. |
| P08-13 | CI performs deterministic double-build comparison and runs every positive/adversarial test with zero skips. |
| P08-14 | Persian and English documents preserve the same scope, constraints, acceptance IDs and limitations. |
| P08-15 | Promotion, rollback, rollback-target retirement and schema migration must be rejected in the synthetic production environment without changing state. |

A successful test run proves only these fixture behaviors. It does not prove a production rollout, actual database migration, zero-downtime release, service-level objective, production secret handling or financial safety under a live workload.

## 5. Failure and recovery scenarios

1. Artifact corruption: mutate bytes after digest creation; verification must reject the artifact.
2. Provenance substitution: change the subject digest, source revision or builder identity; verification must fail.
3. Secret exposure: use a unique synthetic canary; it must not appear in the archive, provenance or runtime output.
4. Dependency outage: critical dependency failure makes the service unready while process liveness remains true.
5. Unhealthy API: do not promote or route traffic.
6. Unhealthy worker after API staging: revert the partial API pointer; preserve the previously active API/worker and traffic state.
7. Stale release pointer or mismatched approval: reject promotion without changing the active release.
8. Incompatible rollback: reject rollback when the old artifact cannot read the current schema.
9. Forward repair: allow a new artifact that supports the current schema to replace the failed release without changing the financial-state fingerprint.
10. Production target: reject it regardless of otherwise valid fixture approval.

## 6. Reproduction

From the repository root:

~~~bash
REVISION="$(git rev-parse HEAD)"
python3 -m compileall -q prototypes/p08-deployment
python3 prototypes/p08-deployment/build.py v1 --out /tmp/p08-build-a --source-revision "$REVISION"
python3 prototypes/p08-deployment/build.py v1 --out /tmp/p08-build-b --source-revision "$REVISION"
cmp /tmp/p08-build-a/affiliate-agent-v1.pyz /tmp/p08-build-b/affiliate-agent-v1.pyz
python3 -m unittest discover -s prototypes/p08-deployment/tests -v
~~~

CI workflow: .github/workflows/p08-deployment-health-rollback.yml.

## 7. Security, operations and financial limitations

- The artifact store is an in-memory digest map, not an immutable OCI registry, WORM store or independently administered artifact repository.
- Provenance is unsigned synthetic metadata. There is no Sigstore/Cosign verification, GitHub artifact attestation verification, trusted build service, transparency-log check, SBOM, dependency vulnerability scan or SLSA level claim.
- The builder is a local Python process. Deterministic output does not establish a hermetic, reproducible or trusted production build.
- The runtime secret is a synthetic string passed to a child process. No Vault/KMS/cloud secret store, workload identity federation, short-lived credential, rotation, revocation or memory-dump protection is implemented.
- Canary assertions are narrow regression tests, not comprehensive secret discovery, DLP or log redaction.
- Health is represented by deterministic booleans. No HTTP endpoint, load balancer, service mesh, queue, database, external dependency, SLO, alert delivery or real worker is exercised.
- Deployment state and audit records are in-memory. Audit is not immutable, tamper-evident or independently retained.
- Schema migration changes only a synthetic integer. No SQL, PostgreSQL DDL, lock behavior, backup, restore, data backfill or real ledger reconciliation is executed.
- The financial-state fingerprint is a sentinel invariant in the fixture, not a ledger or accounting proof.
- No canary percentage, error budget, latency threshold, RPO/RTO, rollout duration or availability target is invented. These require workload evidence and accountable owner approval under LOT-QA-001.
- No production deployment, merge, repository-setting change or destructive action is performed.

## 8. Research references

- SLSA, [Build Provenance v1.2](https://slsa.dev/spec/v1.2/build-provenance) and [Build Requirements](https://slsa.dev/spec/v1.2/build-requirements).
- in-toto, [Attestation framework](https://github.com/in-toto/attestation).
- GitHub, [Using artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations).
- Sigstore, [Cosign signature verification](https://docs.sigstore.dev/cosign/verifying/verify/).
- OWASP, [Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html).
- Kubernetes, [Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/concepts/workloads/pods/probes/).
- Google SRE Workbook, [Canarying Releases](https://sre.google/workbook/canarying-releases/).

## 9. Completion gate

P-08 is complete only when the exact PR head has a successful Integration run and Documentation Governance run, the deterministic artifact comparison succeeds, all positive and negative tests pass with zero skips, the bilingual pair is manually reviewed for semantic parity, and limitations remain explicit. Passing P-08 does not select a production platform, approve technology, authorize merge or authorize deployment.

## P-09C product-aware artifact and provenance addendum (2026-11-25)

P-08 now accepts an explicit allow-listed `--product` input (`affiliate_agent` or `lottery`). Product identity is embedded in the zipapp entrypoint, release metadata, artifact filename and SLSA-shaped provenance external parameters. Promotion verifies the artifact and provenance against the deployment state's product; rollback, rollback-target retirement and schema migration also reject cross-product artifacts. The P-08 CI run [45629980686](https://github.com/tecpey/lottorito-platform/actions/runs/45629980686) passed **53/53 tests**, including separate Affiliate/Lottery artifact builds, product-bound provenance, successful Lottery promotion, cross-product promotion denial and cross-product rollback denial. This remains a synthetic deployment-control experiment; no real environment was touched.


### P-09I — Canonical product scope in release artifacts (2026-11-25)

P-08 no longer maintains an independent product-ID allowlist: its build imports the canonical product registry and scope normalizer from P-09. Each release artifact now carries both the product identifier and an explicit `{kind: product, id: ...}` scope in `release.json`; detached provenance binds the same scope object in `externalParameters`. Artifact inspection rejects a scope/product mismatch, and provenance verification rejects a substituted scope. This is a synthetic zipapp/provenance fixture; it is not a signed attestation or a production release controller.
