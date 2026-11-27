# G09-A13 — Contract Validation Assurance Review

**Document ID:** LOT-AFFILIATE-G09-A13-001  
**Version:** 0.1.0  
**Review snapshot:** `e88c6b6fac04b451926a8137ca68571f19e18fa8`  
**Date:** 2026-11-28  
**Status:** SAME-AUTHOR ASSURANCE REVIEW — NOT INDEPENDENT; findings OPEN  
**Related:** PR #76; LOT-AFFILIATE-WIRE-001; LOT-AFFILIATE-SEC-001; LOT-AFFILIATE-G09-ADR-002; G09-A11; G09-A12  
**Authority:** Documentation/contract assurance only. No runtime, partner, financial, merge or deployment authorization.

## 1. Executive result

At the frozen review snapshot, both exact-head GitHub workflows completed successfully:
- Documentation Governance #1014 — SUCCESS.
- Affiliate Contract Validation #151 — SUCCESS.

The contract workflow ran pinned direct CLI/validator package versions, Redocly OpenAPI lint, AsyncAPI CLI validation, and the Node/Ajv payload fixture script. Its success is valid evidence that those configured checks passed on the reviewed commit.

It is not evidence of runtime authorization, tenant binding, source/extension allowlist enforcement, atomic Inbox/WorkItem persistence, idempotent concurrency, commit durability, failover safety, ledger non-reachability or production readiness.

This review inspected the workflow, validation script, OpenAPI/AsyncAPI artifacts and related wire/security/ADR text. It is authored in the same project workflow and is **not an independent review**.

## 2. Findings

### A13-F01 — Operation security assertions do not enforce the expected scheme/scope mapping

**Severity:** HIGH — contract-regression protection gap  
**Status:** OPEN

The current validator verifies that each operation has a non-empty `security` array and a non-empty `x-required-scopes` array. It also verifies that the management and ingestion documents define distinct bearer scheme names.

It does not assert that each operation references the correct scheme, nor that its scope list equals the intended operation-specific policy. An OpenAPI Security Requirement Object such as an empty object (`{}`) permits anonymous access; the current array-length assertion would still pass. An operation using the wrong existing scheme or an unintended scope can also pass these generic presence checks.

The frozen contract currently declares:
- Management: `bearerAuth` on `listAffiliatePrograms`, `getAffiliateSelf`, `createReferralLink`, `getReferralLink`, `getAttribution`, with their individually declared `affiliate.*` scopes.
- Ingestion: `partnerBearerAuth` on `submitPartnerEvent`, with `partner.events.write`.

**Required remediation**
1. Add a reviewed, explicit operationId → expected security scheme → expected scope-set manifest.
2. Assert exact scheme mapping and exact scope-set equality, not merely non-empty arrays.
3. Reject empty security requirement objects, missing/duplicate/unknown scopes, wrong-scheme substitution, unrecognized operation IDs and undocumented operations.
4. Add mutation/negative fixtures proving each regression is rejected.
5. Keep the distinction explicit: `x-required-scopes` remains a custom contract extension/review metadata until LOT-API-PLATFORM-001 approves its normative semantics. These tests do not prove runtime enforcement.

### A13-F02 — CloudEvents extension shape is intentionally permissive; CI does not enforce the CloudEvents extension type/name rules or installation allowlist

**Severity:** HIGH — wire-conformance and trust-boundary gap  
**Status:** OPEN; runtime allowlist requirement already tracked in SEC-AFF-06

The partner and canonical event schemas use permissive top-level extension handling (`additionalProperties: true`). The fixture suite checks that a representative top-level extension is accepted. It does not prove that arbitrary extension names/types are CloudEvents-conformant or registered for a given installation.

CloudEvents requires extension attributes to follow the standard attribute naming convention and type system. Names are restricted to lowercase ASCII letters/digits, and values must use the CloudEvents attribute type system. The existing security review already requires installation-specific registered extension names/types and fail-closed handling.

**Required remediation**
1. Preserve the distinction between generic transport envelope and runtime trust: permissive schema shape is not authorization to accept arbitrary extensions.
2. Define a versioned extension profile/allowlist contract, including reserved core names, allowed name syntax, value types, size/count limits, semantic ownership and compatibility policy.
3. Add schema/fixture checks for invalid names, reserved-name collisions, invalid value types and extension-count/size boundaries where the generic profile can enforce them.
4. Add runtime proof later for installation-bound allowlist enforcement; do not claim this CI proves it.
5. Keep `data.additionalProperties` provider-specific: validate against the exact registered schema before normalization.

This finding does not contradict the existing documented runtime allowlist requirement; it identifies that the current green contract workflow does not enforce or prove it.

### A13-F03 — AsyncAPI schema dialect is described inaccurately in the Ajv fixture validator

**Severity:** MEDIUM — dialect clarity and future-drift risk  
**Status:** OPEN

The script comment and success output describe the AsyncAPI 3.0 payload as Draft 07 by default. AsyncAPI 3.0.0 specifies that, when `schemaFormat` is absent, the default is the AsyncAPI 3.0.0 Schema Object. That Schema Object is a superset of JSON Schema Draft 07 and adds AsyncAPI-specific vocabulary/semantics.

The current payload appears to use Draft-07-compatible JSON Schema keywords, so Ajv Draft 07 can validate that subset. It does not thereby validate all AsyncAPI Schema Object semantics or future AsyncAPI-specific keywords. The AsyncAPI CLI remains the document-level validator.

**Required remediation**
1. Correct the comment and success output to say “AsyncAPI 3.0 Schema Object; Ajv checks the currently used Draft-07-compatible JSON Schema keyword subset.”
2. Either add a guard that rejects unsupported AsyncAPI-specific schema keywords in the Ajv-only instance path, or explicitly choose a JSON Schema Draft 07 Multi Format Schema Object if that is the intended contract.
3. Keep AsyncAPI CLI validation mandatory and add fixtures for every supported dialect/keyword decision.
4. Do not describe Ajv Draft 07 as the normative AsyncAPI dialect.

### A13-F04 — Direct npm package versions are exact, but the validator toolchain is not lockfile-reproducible

**Severity:** MEDIUM — build reproducibility / supply-chain assurance  
**Status:** OPEN

The workflow pins direct package versions (`@redocly/cli`, `@asyncapi/cli`, `ajv`, `ajv-formats`) and pins the GitHub Actions by commit SHA and Node.js version. It installs into temporary prefixes with `npm install`, but no repository-committed lockfile is used by `npm ci`. Transitive dependency resolution can therefore change as upstream semver ranges evolve, even when direct versions remain unchanged.

**Required remediation**
1. Commit a dedicated lockfile for the isolated validator toolchain, including transitive versions and integrity hashes.
2. Install with `npm ci` from that lockfile in the temporary tool prefix.
3. Record Node/npm versions and resolved toolchain identity in workflow evidence.
4. Consider replacing mutable `ubuntu-latest` with an explicitly selected runner image family; recognize that hosted image contents can still evolve.
5. Keep dependency-update changes explicit and reviewable.

The current successful run is valid for the dependencies it resolved at that time; it is not a reproducible dependency-graph guarantee for future runs.

### A13-F05 — Wire response semantics are ahead of the still-unapproved durability decision and do not define UNKNOWN commit outcome

**Severity:** CRITICAL — contract/ADR consistency blocker  
**Status:** OPEN; overlaps A11-F01 and A11-F03

The ingestion contract describes HTTP 202 as “durably accepted” after Inbox and processing-job commit. It describes 503 as temporary unavailability “before durable receipt.” ADR-002 v0.3.0 correctly leaves the acknowledged durability/failure model, RPO, replication acknowledgement, promotion eligibility and recovery-point behavior open.

The response contract therefore uses the word “durable” before the failure classes covered by that promise have been approved. It also does not explicitly define the externally observable state when the commit outcome is UNKNOWN (for example, response loss or timeout while the transaction may still commit). UNKNOWN must not be mislabeled as a proven pre-commit failure.

**Required remediation**
1. Bind the 202 durability promise to an owner-approved failure model and candidate-specific durability contract; until then, retain PROPOSED/BLOCKED status.
2. Define a distinct UNKNOWN outcome in the API/status/retry contract, separate from confirmed NOT ACCEPTED and confirmed ACCEPTED.
3. Specify that a 503 statement “before durable receipt” is valid only when the system can prove the operation did not commit. If outcome is unknown, the response must not assert non-acceptance.
4. Require retries to preserve the same source identity and immutable request binding and re-enter arbitration on the currently fenced authority; a negative read alone must not authorize a second insert.
5. Define stable receipt-reference behavior for confirmed duplicates and ensure no second WorkItem is created.
6. Add positive/negative contract fixtures for ACCEPTED, DUPLICATE, CONFLICT, NOT ACCEPTED and UNKNOWN semantics without pretending that schema fixtures prove the runtime state machine.

This finding must be resolved jointly with A11-F01/F03, not by editing response prose alone.

### A13-F06 — Payload fixture coverage is representative, not exhaustive

**Severity:** MEDIUM — assurance coverage limitation  
**Status:** OPEN / acknowledged scope limitation

The validator compiles and exercises selected component schemas and representative positive/negative payloads. It does not enumerate every OpenAPI request/response schema, every operation response, all error variants, every AsyncAPI message schema or all referenced schemas as fixture targets. Redocly/AsyncAPI CLI validate document structure, but document validity does not equal exhaustive instance coverage.

**Required remediation**
1. Produce a machine-readable schema/operation coverage manifest.
2. Enumerate all request and response schema roots, including error responses and referenced schemas.
3. Require at least one positive fixture for each supported schema root and negative fixtures for security/tenant/identity/size/enum invariants.
4. Make CI fail if a new schema/operation is added without a declared test disposition.
5. Mark intentionally untested schemas explicitly with an owner-approved reason and risk classification.

## 3. Existing requirements that must not be misrepresented as closed

- SEC-AFF-06: installation-specific extension/source/event/schema allowlist enforcement remains a runtime requirement.
- SEC-AFF-03 / LOT-API-PLATFORM-001: custom scope extension semantics and enforcement remain open.
- A11-F01/F03: durability and UNKNOWN commit arbitration remain open.
- A11-F02: authority epoch and old-writer fencing remain open.
- A11-F04/F05/F06/F07/F08: pair integrity, fingerprinting, retention, quarantine and response semantics remain open.
- A7 canonical 47-case suite and 21 extension subcases remain design-only; no runtime proof is implied.
- All eight A4 approval gates remain NOT APPROVED.

## 4. Recommended next work package

**G09-A14 — Contract Validation Hardening & Response-State Alignment**

Sequence:
1. Correct the AsyncAPI dialect statement and output wording.
2. Add exact operation security/scope mapping assertions and mutation tests.
3. Add a declared CloudEvents extension profile and conformance fixtures; keep runtime allowlist proof separate.
4. Make the validator dependency graph lockfile-reproducible.
5. Build the complete schema/operation fixture coverage manifest.
6. Reconcile 202/503/UNKNOWN semantics with ADR-002 owner decisions before changing the public wire promise.
7. Run both workflows on one exact final head and capture the complete job evidence.

Do not change runtime code, select a persistence engine, invent a durability/RPO value, approve an identity issuer, infer partner-specific event rules, merge or deploy.

## 5. Reference standards and engineering guidance

- AsyncAPI 3.0.0 — Multi Format Schema Object defaults and Schema Object dialect: https://www.asyncapi.com/docs/reference/specification/v3.0.0
- CloudEvents specification — attribute naming, type system, extensions and source+id identity: https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md
- OpenAPI 3.2.1 — default OAS Schema Object dialect and JSON Schema Draft 2020-12 basis: https://spec.openapis.org/oas/latest.html
- RFC 8785 — JSON Canonicalization Scheme; duplicate property names, Unicode preservation and IEEE-754 number constraints: https://www.rfc-editor.org/rfc/rfc8785.html
- AWS Builders’ Library — Making retries safe with idempotent APIs; atomic idempotency recording, semantic equivalence, late arrivals and parameter mismatch: https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- PostgreSQL failover and old-primary fencing/STONITH: https://www.postgresql.org/docs/current/warm-standby-failover.html
- PostgreSQL synchronous replication: https://www.postgresql.org/docs/current/warm-standby.html
- PostgreSQL WAL durability settings: https://www.postgresql.org/docs/current/runtime-config-wal.html

These references inform the review; they do not establish Lottorito implementation behavior.

## 6. Disposition

G09-A13 is a same-author assurance review of the contract-validation mechanism and its boundary. It is not an independent audit and does not close any A11/A7/A8/A4 finding.

**Disposition: CI PASS is accepted for the checks actually executed; contract assurance is NOT COMPLETE.** A13-F01..F06 remain OPEN. G09-A14 is the recommended next documentation/contract-hardening package. PR #76 remains Open/Draft; no merge or deployment is authorized.
