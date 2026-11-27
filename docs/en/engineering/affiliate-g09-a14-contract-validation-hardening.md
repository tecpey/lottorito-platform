# G09-A14 — Contract Validation Hardening & Response-State Alignment

**Document ID:** LOT-AFFILIATE-G09-A14-001  
**Version:** 0.1.0  
**Status:** TECHNICAL HARDENING VERIFIED — owner decisions remain open (A14-C05)  
**Date:** 2026-11-28  
**Parent:** LOT-AFFILIATE-G09-A13-001  
**Scope:** Contract/CI validation only. No runtime implementation, persistence selection, partner integration, financial operation, merge or deployment authorization.

## 1. Objective

Remediate the six assurance gaps recorded by G09-A13 without converting documentation checks into runtime claims or silently deciding unresolved owner questions. The package hardens the contract validator, makes schema/fixture coverage fail closed, narrows the generic CloudEvents envelope to a standards-compatible local profile, and makes the acceptance response wording conditional on an owner-approved durability contract.

## 2. Changes prepared

### A14-C01 — Exact operation security/scope manifest and mutation checks

Added `contracts/validation/affiliate-contract-validation-manifest.v1.json` as the explicit operation and schema coverage inventory.

The validator now checks each current operation against its expected:
- operationId (unknown, duplicate and missing operations fail);
- one and only one non-optional Security Requirement Object;
- exact HTTP bearer scheme for the relevant API;
- no empty anonymous alternative, no wrong/extra scheme;
- exact `x-required-scopes` set, with no missing, extra or duplicate entries.

Seven mutation fixtures deliberately introduce anonymous security, wrong scheme, optional anonymous alternative, wrong scope, duplicate scope, unknown operation and missing operation. Each mutation must be rejected.

**Boundary:** `x-required-scopes` remains custom contract metadata. This does not define its normative platform semantics or prove resource-server enforcement. Token issuer, audience, credential profile and authorization implementation remain open.

### A14-C02 — Generic CloudEvents extension profile

The partner envelope and canonical event payload now enforce a shared generic profile:
- lowercase ASCII alphanumeric property names;
- first character lowercase letter;
- maximum 20 characters (the project intentionally strengthens CloudEvents SHOULD guidance into a local MUST);
- extension values limited to JSON string, boolean or signed 32-bit integer representations; all CloudEvents string-valued context attributes (core and extension) reject prohibited control characters, unpaired surrogates and Unicode noncharacters;
- no unknown top-level properties outside the core fields and syntactically valid extension pattern.

No extension-count, byte-size, parsing-time, nesting or quota number is invented. Those resource ceilings remain subject to the SEC-AFF-08 owner/operations decision and load evidence.

**Boundary:** this is not the installation-specific allowlist. Runtime must still bind authenticated installation/tenant/product/environment first, then reject every extension name or semantic type not registered for that installation. Registered string types (URI, URI-reference, Timestamp, Binary/base64 or ordinary String) require their own semantic validation. Provider `data` remains untrusted and must be checked against the exact pinned integration schema before normalization. No arbitrary `dataschema` URL may be fetched.

### A14-C03 — AsyncAPI dialect correction and Ajv guard

The validator now describes the AsyncAPI 3.0.0 default correctly: absent `schemaFormat`, the payload is an AsyncAPI 3.0 Schema Object, which is a superset of JSON Schema Draft 07. Ajv Draft 07 checks only the currently used Draft-07-compatible subset. A guard rejects known AsyncAPI-only Schema Object keywords from the Ajv-only path; the AsyncAPI CLI remains the complete document/dialect validator.

OpenAPI 3.2.1 instance checks remain isolated in the Ajv 2020-12 instance. Redocly remains the full OpenAPI document validator.

### A14-C04 — Isolated lockfiles and reproducible installation

Added separate exact-version manifests at `.github/contract-tools/package.json` and `.github/schema-tools/package.json`. The two prefixes intentionally isolate the AsyncAPI/Redocly CLI dependency graph from the Ajv fixture-validator dependency graph, avoiding transitive Ajv/plugin collisions. Both generated lockfiles have been verified and committed:
- `.github/contract-tools/package-lock.json` — 1,409 package records.
- `.github/schema-tools/package-lock.json` — 7 package records.

The temporary bootstrap, artifact-upload and write-back job have been removed. The final workflow requires strict `npm ci` in both isolated prefixes and fails if either committed lockfile is absent. Node/npm versions are recorded; the runner uses `ubuntu-24.04` rather than the moving `ubuntu-latest` label.

**Verified:** strict `npm ci` succeeded from both committed lockfiles on exact head `3a008718ab9cf40a551441e3a195f73874788f26`; A13-F04 is CLOSED for dependency-graph reproducibility. The hosted runner image is still updated by GitHub; `ubuntu-24.04` narrows the OS family but is not a fully immutable image digest.

### A14-C05 — 202/503/UNKNOWN response-state alignment

The partner API's 202 description and bilingual wire contract no longer make an unconditional durability claim. A 202 is proposed only after atomic Inbox + WorkItem commit and satisfaction of the owner-approved durability acknowledgement condition.

The 503 description now forbids asserting non-acceptance unless non-commit is known. UNKNOWN is explicitly neither confirmed acceptance nor confirmed non-acceptance. Retry must preserve the authenticated source identity and reconcile against the active authoritative persistence authority; a negative read alone cannot authorize a second insert.

**Still OPEN:** exact HTTP status and machine-readable error mapping for UNKNOWN, supported failure classes, RPO, acknowledgement point, promotion eligibility and recovery behavior require owner decisions and candidate-specific proof. No UNKNOWN receipt enum or numeric durability value is invented. ADR-002 remains PROPOSED.

### A14-C06 — Fail-closed schema-root and fixture coverage manifest

The manifest currently enumerates all 11 schema roots:
- 7 Affiliate Management OpenAPI schemas;
- 3 Partner Ingestion OpenAPI schemas;
- 1 AsyncAPI canonical-event payload.

It lists 53 positive/negative fixture IDs. The validator compares the manifest to the actual schema roots and executed fixtures exactly. A new or removed schema root, missing/extra fixture, duplicate fixture ID or fixture associated with the wrong root fails validation. New operations also fail until explicitly added to the operation-security manifest.

This is a completeness guard over the declared schema-root inventory, not a proof of every semantic behavior or every possible input.

## 3. Current implementation inventory

- `contracts/validation/affiliate-contract-validation-manifest.v1.json`
- `.github/contract-tools/package.json` and `.github/schema-tools/package.json` with their committed lockfiles
- `.github/workflows/affiliate-contract-validation.yml`
- `scripts/validate_affiliate_contract_payloads.mjs`
- `contracts/openapi/partner-event-ingestion.v1.json`
- `contracts/asyncapi/affiliate-domain-events.v1.json`
- bilingual `affiliate-api-wire-contract.md`

The exact-head Node/Ajv run executed all 53 manifest fixtures with no missing, extra or duplicate IDs; it also passed the schema-root and fixture parity assertions.

## 4. A13 finding disposition

| A13 finding | A14 treatment | Current disposition |
|---|---|---|
| F01 — exact operation security/scope mapping | exact manifest, operation assertions and seven mutation cases | VERIFIED BY EXACT-HEAD CI; runtime authorization remains unproven |
| F02 — CloudEvents extension syntax/type vs installation allowlist | generic schema profile and negative fixtures; runtime allowlist retained as a separate blocker | PARTIAL; runtime requirement OPEN |
| F03 — AsyncAPI dialect wording | corrected comment/output and guarded Ajv subset | VERIFIED BY EXACT-HEAD CI and AsyncAPI CLI |
| F04 — transitive dependency reproducibility | isolated package manifests and committed lockfiles; strict npm ci workflow | VERIFIED; both strict npm ci installs passed on exact head |
| F05 — 202/503/UNKNOWN alignment | conditional response language and explicit UNKNOWN boundary | PARTIAL; owner decision and runtime proof OPEN |
| F06 — schema fixture coverage | 11-root/53-fixture machine manifest and exact-set assertions | VERIFIED BY EXACT-HEAD CI; 66 assertions passed |

## 5. Required verification before marking A14 complete

1. Verify strict `npm ci` succeeds from both committed lockfiles on the final exact head; no bootstrap fallback remains.
3. Verify exact operation security and scope mutation cases fail as intended.
4. Verify CloudEvents extension profile positive and negative cases under Ajv 2020-12 and the guarded Draft-07 subset.
5. Verify the AsyncAPI CLI and Redocly full-document checks pass.
6. Verify the 11 schema roots and 53 fixture IDs reconcile exactly.
7. Run Documentation Governance and Affiliate Contract Validation on the same final head; inspect all job steps and record exact SHA.
8. Read back English and Persian documents and compare semantic parity.
9. Record all remaining owner decisions without changing their status.

## 6. Standards and references

- OpenAPI 3.2.1, Security Requirement Object and anonymous alternative: https://spec.openapis.org/oas/v3.2.1.html
- AsyncAPI 3.0.0, Multi Format Schema Object defaults and Schema Object dialect: https://www.asyncapi.com/docs/reference/specification/v3.0.0
- CloudEvents specification, attribute naming, type system and extension attributes: https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md
- CloudEvents JSON event format, mapping of extension attributes to JSON: https://github.com/cloudevents/spec/blob/main/cloudevents/formats/json-format.md
- npm `ci`, clean lockfile-based installation: https://docs.npmjs.com/cli/npm-ci
- NIST SP 800-204D, Software Supply Chain Security in DevSecOps CI/CD Pipelines: https://csrc.nist.gov/pubs/sp/800/204/d/final

Standards inform the contract and checks; they do not prove runtime implementation behavior.

## 7. Explicit non-claims and stop conditions

- No runtime authorization, installation binding or tenant isolation has been implemented or proven.
- No partner-specific event schema, extension registry, source allowlist or token issuer has been approved.
- No Inbox/WorkItem transaction, idempotency race, UNKNOWN reconciliation, database durability, failover or fencing test has run.
- No ledger, commission, payout, wallet or customer balance operation has run.
- No persistence engine, queue, vendor, RPO, retention period or quota value has been selected.
- A11-F01..F08 remain OPEN; A7/A8 cases remain design-only/NOT RUN; all eight A4 gates remain NOT APPROVED.
- Independent review remains outstanding.
- PR #76 remains Open/Draft. No merge or deployment is authorized.

**Disposition:** G09-A14 is IN PROGRESS. Validator hardening is an implementation candidate; final lockfile closure and exact-head CI evidence are mandatory before claiming completion.
