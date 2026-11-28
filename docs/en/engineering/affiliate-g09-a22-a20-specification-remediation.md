# G09-A22 — A20 Specification Remediation

**Document ID:** LOT-AFFILIATE-G09-A22-001  
**Version:** 1.0.0 | **Status:** PROPOSED SPECIFICATION AMENDMENT — RESEARCH ONLY  
**Date:** 2026-11-28  
**Parent:** G09-A20 / LOT-AFFILIATE-G09-A20-001  
**Review basis:** G09-A21 / LOT-AFFILIATE-G09-A21-001

## 1. Purpose and disposition

A22 converts the actionable P1 findings A21-F02 through A21-F10 into a testable specification structure without selecting unresolved policy, infrastructure, database, provider, retention duration, RPO/RTO, or business semantics.

A22 is a controlled companion amendment. It does not silently rewrite A20, close findings by adding prose, approve ADR-002, or authorize runtime work.

**Disposition:** A22 defines the minimum contract shape and evidence required before A20 can be promoted from research/test-design baseline to executable qualification specification. Owner-dependent values remain explicit blockers.

## 2. Normative language and authority

MUST, MUST NOT, SHOULD, SHOULD NOT and MAY are normative within this document.

Authority order:
1. Applicable law/regulation and executed customer/operator agreements, once identified and verified by the authorized owner/legal adviser.
2. Explicit owner-approved business/security constraints and decision-register entries.
3. Approved ADRs and versioned contracts.
4. This A22 specification and A20 test catalogue.
5. Candidate/vendor documentation and marketing material, which are evidence inputs, not authority.

A candidate feature or vendor statement cannot override law, owner-approved constraints or domain invariants. No value is inferred from examples.

Unresolved owner decisions are represented as OPEN_OWNER_INPUT; absent evidence as MISSING_EVIDENCE; unsupported claims as UNVERIFIED; violated assertions as FAIL; ambiguous/incomplete outcomes as INCONCLUSIVE. These states MUST NOT be collapsed into PASS.

## 3. Requirement-to-proof traceability

Every mandatory requirement and critical assertion MUST have a trace record containing:

| Field | Required content |
|---|---|
| trace_id | Stable unique ID |
| constraint_id | C-01..C-16 or NOT_APPLICABLE with approved rationale |
| gate_id | G1..G9 |
| owner_decision_ids | Related OD-01..OD-12; empty only with rationale |
| requirement/control | Exact normative statement and source/version |
| invariant_id | One or more I-IDs |
| scenario_ids | Positive, negative and fault-interleaving cases |
| preconditions | Topology, state, versions, identity, permissions and fixture |
| fault_schedule | Ordered deterministic fault/timing instructions |
| oracle_ids | Oracle, query/algorithm and trust boundary |
| expected_history | Allowed and forbidden observable histories |
| evidence_artifacts | Raw logs, traces, metrics, DB exports, config and hashes |
| owner/approver | Accountable owner and approval record |
| result | PASS / FAIL / INCONCLUSIVE / NOT_RUN / BLOCKED |
| residual_risk | Known limitation, scope and treatment |
| reviewer | Executor/reviewer; independence declared, never assumed |

Traceability MUST be bidirectional. Every applicable C-ID and G-ID maps to tests/evidence; every test maps to a requirement/invariant; every critical invariant maps to positive and adversarial tests. NOT_APPLICABLE requires owner-approved rationale. Unmapped mandatory requirements or orphan tests block qualification.

## 4. Source identity, canonicalization and deduplication — A21-F02

### 4.1 Identity contract — decision-gated

Event identity MUST be a versioned tuple, but its actual fields and scope remain subject to OD-01..OD-04. The approved contract MUST settle:
- tenant namespace and authoritative tenant identity source;
- source/operator identity and source installation or credential epoch, if applicable;
- event-ID scope and uniqueness guarantee;
- event type/domain and source epoch, if any;
- canonicalization algorithm/version;
- fingerprint algorithm, encoding and key use, if any;
- identity/fingerprint migration and rotation behavior;
- identity/tombstone retention and expiry semantics.

No implementation may substitute a global event ID, timestamp, payload hash or API key for the approved tuple without explicit approval.

### 4.2 Mandatory equivalence classes

After OD approval, tests MUST distinguish:
1. Same approved identity + same canonical semantic fingerprint: duplicate handling; no second business acceptance.
2. Same identity + different semantic fingerprint: conflict/quarantine; never silently overwrite or treat as harmless duplicate.
3. Different tenant + same source event ID: tenant isolation; no cross-tenant collision or information disclosure.
4. Different approved source namespace/epoch + same event ID: behavior follows the approved tuple, not inference.
5. Missing, malformed, oversized or unsupported-version identity: deterministic rejection/quarantine; no partial financial acceptance.
6. Same semantic content with permitted transport-only variation: result follows versioned canonicalization.
7. Old/new canonicalizer or key during rotation: explicit migration/dual-version policy; no silent fingerprint drift.
8. Replay after retention boundary and after restore: behavior follows approved lifecycle rule and source replay horizon.

### 4.3 Canonicalization requirements

The contract MUST define exact canonical bytes before fingerprinting: field inclusion/exclusion, null versus absent, numeric representation, Unicode normalization, timestamp precision/time zone, array ordering, duplicate keys, unknown fields, schema evolution and invalid-input behavior. If RFC 8785 JSON Canonicalization Scheme is selected, its constraints and incompatibilities MUST be documented; JSON payloads do not imply automatic selection.

Canonicalization MUST be deterministic across supported implementations and versions. Golden vectors MUST include normal, boundary, malformed and adversarial payloads. Vectors are fixtures, not algorithm approval.

### 4.4 Retention linkage

Identity protection MUST survive every permitted redelivery/replay path. Retention is not a guessed constant. Derivation MUST consider the maximum applicable horizon among:
- source retry/redelivery and operator replay;
- queue/broker retention and delayed delivery;
- restorable backup age and PITR window;
- replication/DR lag and failback;
- manual incident recovery/reprocessing;
- migration and legal retention/deletion obligations.

The owner MUST approve the resulting policy and exceptions. If source replay horizon is unbounded or unknown, use a proven non-reuse/epoch strategy or block qualification; never silently expire deduplication protection.

**Exit evidence:** approved OD-01..OD-04; versioned identity/canonicalization contract; golden vectors; migration/expiry strategy; tests for all eight equivalence classes.

## 5. Atomic acceptance and UNKNOWN commit — A21-F03

### 5.1 Atomic acceptance invariant

For an approved identity, the authoritative acceptance operation MUST atomically persist the complete acceptance record and required durable work representation, or persist neither. Exact Receipt/WorkItem cardinality/schema remain subject to ADR-002 and OD-05..OD-07.

A success acknowledgement MUST mean the approved durable acceptance point has been crossed. Timeout, connection reset or lost response MUST NOT be interpreted as proof of rollback or commit.

### 5.2 Abstract outcome model

The API/application boundary MUST distinguish at least:
- ACCEPTED: authoritative durable acceptance is proven.
- REJECTED: rejected before acceptance; no acceptance effect exists.
- DUPLICATE_CONFIRMED: same approved identity and semantic event already accepted; existing outcome is referenced.
- CONFLICT: identity exists with a different semantic fingerprint; no second acceptance.
- UNKNOWN: caller cannot establish whether the authoritative acceptance transaction committed.
- QUARANTINED: controlled/human resolution required; not normal accepted work.

UNKNOWN is not REJECTED, RETRYABLE_FAILURE or ACCEPTED. Final wire status mapping is a separate API-contract decision.

### 5.3 Reconciliation requirements

For UNKNOWN:
1. Preserve the original identity and fingerprint.
2. Never create a new identity to escape ambiguity.
3. Query the authoritative acceptance authority using a read consistency strong enough to resolve the acceptance point; stale replica/cache is not proof of absence.
4. Resolve races with the original in-flight transaction. A negative read is not final while the original transaction can still commit or become visible.
5. Reconcile by identity and fingerprint, not approximate timestamp or payload similarity.
6. If matching durable acceptance exists, return/reference the existing accepted result.
7. If conflicting fingerprint exists, enter conflict/quarantine.
8. If absence is proven under the approved concurrency/visibility protocol, retry only through the same idempotent path and same identity.
9. If unresolved, preserve UNKNOWN and escalate; no unbounded automatic retry or false terminal response.
10. Audit every transition/operator action and make it replay-safe.

The implementation MUST define arbitration with an original transaction still executing: database uniqueness/serializable behavior, fencing token, transaction-status facility or another justified mechanism. Read-then-insert without a race proof is insufficient.

### 5.4 Required histories

Test commit success/response loss; commit failure/response loss; retry during original in-flight transaction; stale replica read before original visibility; concurrent same-identity submissions; concurrent same-identity/different-fingerprint submissions; failover during commit/reconciliation; client retry after process restart; operator reconciliation racing automated retry; duplicate response while original worker remains incomplete.

**Exit evidence:** approved OD-05..OD-07 and OD-11; state machine; linearization point; isolation/consistency proof; concurrency history checker; explicit UNKNOWN resolution policy. No candidate-specific assumption before selection.

## 6. External side effects and delivery guarantees — A21-F04

### 6.1 Guarantee boundary

Atomicity inside one database transaction does not make an external HTTP call, payment-provider action, email, webhook, wallet transfer or partner-system mutation atomic with that transaction.

Guarantees MUST be stated separately for internal durable acceptance, internal ledger/workflow mutation, outbox publication, broker delivery, consumer processing and external receiver effect.

Do not claim end-to-end exactly-once external effect unless receiver contract, deduplication retention, reconciliation and failure behavior are demonstrated across the full boundary. Otherwise state actual at-least-once, at-most-once or unknown semantics.

### 6.2 Per-destination receiver contract

Before an external effect enters scope, define:

| Field | Required definition |
|---|---|
| destination_id | Stable logical destination |
| owner/operator | Accountable party/system owner |
| operation | Exact side effect and business semantics |
| idempotency | Receiver-supported key/equivalent |
| key scope | Tenant, account, operation and resource scope |
| fingerprint | Same key/same request versus different request |
| receiver retention | Guaranteed deduplication window and evidence |
| lookup | Authoritative outcome query |
| timeout behavior | Unknown-outcome semantics |
| duplicate behavior | Effect/response on redelivery |
| ordering | Aggregate/sequence ordering and gap handling |
| compensation | Available remedy; not presumed rollback |
| security | Auth, signing, key rotation and replay protection |
| evidence | Receiver receipts/logs, query access and retention |

If the receiver lacks idempotency or reliable lookup, classify the effect as explicit residual risk and exclude it from exactly-once claims. A local lease/fencing token cannot revoke a request already accepted by the receiver.

### 6.3 Outbox and consumer rules

- Domain mutation and outbox record MUST commit atomically where transactional outbox is claimed.
- Delivery MUST be treated as potentially duplicated unless a stronger broker/receiver contract is proven.
- Consumer deduplication and business mutation MUST commit atomically in its authoritative store.
- Ordering MUST be defined per aggregate/partition; global ordering is not presumed.
- Sequence gaps, stale/poison events, retry exhaustion and quarantine need explicit handling.
- A publisher losing its lease MUST be prevented from mutating protected internal state; downstream effects still require receiver idempotency.
- Delivery acknowledgement occurs only at the consumer-contract-defined point.

### 6.4 Adversarial cases

Stale worker sends after lease loss; downstream accepts but response is lost; downstream timeout before/after applying effect; concurrent duplicate; same key/different request; receiver dedupe window expiry; out-of-order event; sequence gap; receiver unavailable during reconciliation; compensation failure; credential rotation during retry.

**Exit evidence:** destination inventory; verified receiver contract or explicit scope exclusion; retention evidence; end-to-end duplicate/timeout histories; documented guarantee boundary.

## 7. Retention, tombstones, replay and restore — A21-F05/F10

### 7.1 Retention derivation

For each identity-bearing record (receipt, inbox/dedup marker, tombstone, outbox, consumer inbox, audit evidence), define creation, active, expiry-eligible, expired and legal-hold lifecycle semantics.

Minimum identity-protection horizon MUST cover the longest approved replay/recovery path, not merely normal queue retry. A lifecycle worksheet records each horizon, source, contractual/measured bound, uncertainty, legal constraint, owner and approval.

If a finite maximum cannot be evidenced:
- do not invent finite expiry;
- use permanent/non-reusable identity or epoch/namespace rollover with proven cutover; or
- block qualification pending source/operator evidence.

Privacy/deletion obligations MUST be reconciled with financial/audit integrity through separately approved data-minimization or cryptographic-erasure design. Legal deletion does not authorize deleting the only deduplication proof if that reopens replay risk.

### 7.2 Restore gate

A restored environment MUST start quarantined: ingress/workers disabled, external egress denied, credentials isolated, and no live partner/payment/production-control-plane access. Reopening requires:
- backup and WAL/PITR chain integrity evidence;
- schema/application/config compatibility;
- key hierarchy and decryptability/revocation status;
- tenant isolation checks;
- identity/tombstone high-water-mark reconciliation;
- queue/outbox/inbox reconciliation and replay plan;
- authority epoch/fencing reset proof;
- ledger/source-to-ledger reconciliation where applicable;
- observability/audit evidence integrity;
- owner-approved RPO/RTO result and residual-risk acceptance.

Database startup is not domain-recovery proof. A restore omitting identity/tombstone state MUST NOT reopen ingress. A restored old authority MUST be fenced from writing.

### 7.3 Required restore scenarios

Restore before/after committed event; partial backup/WAL gap; old backup after tombstone expiry; delayed broker message after restore; lost KMS/key service; revoked/rotated key; compromised credentials in backup; tenant migration; failback with old primary returning; outbox published before checkpoint but receiver effect unknown.

**Exit evidence:** approved lifecycle horizon/strategy; clean-room restore procedure; reconciliation oracles; isolation proof; domain-level restore report. Numeric retention/RPO/RTO remain OPEN pending owner evidence.

## 8. Oracle, evidence and result contract — A21-F06/F08 interface

A22 does not claim oracle independence; A24 assesses trust boundaries. Every test record MUST identify assertion/property; oracle implementation/version and exact query/algorithm; source data/consistency; shared dependencies with system under test; credentials/admin/clock/failure domains; raw evidence path/hash/timestamp source/custody; completeness checks and known blind spots.

Test outcomes:
- PASS: every required assertion evaluated, evidence complete and integrity-checked, and no forbidden history observed within declared scope.
- FAIL: at least one required assertion demonstrably violated.
- INCONCLUSIVE: evidence/oracle/fault schedule incomplete, inconsistent or ambiguous; no PASS inference.
- NOT_RUN: not executed.
- BLOCKED: prerequisite, owner decision, authorization or environment missing.

Missing logs, broken oracle, unverified clock or absent fault injection MUST NOT become PASS. Performance, availability, correctness and recovery are reported separately. Repetition, duration and thresholds require owner-approved workload/risk objectives.

## 9. Financial and production isolation — A21-F09

A20/A22 research/design grants no permission to connect to or mutate any real financial system.

Any future test fixture, only if separately authorized, MUST be synthetic, isolated, non-settleable and incapable of initiating real payment, wallet transfer, partner-balance change, withdrawal, prize, player transaction or production-ledger posting. Isolation evidence MUST include environment/account/project and network topology; absence of production credentials/trust paths; deny-by-default egress and explicit allowlist; no real customer/partner/player personal data; synthetic identifiers/ledger namespace; proof payment/provider endpoints are unreachable; logs showing no real financial side effect.

A20-27 is limited to a pure model/fixture assertion unless separate written owner authorization and relevant gates exist. A22 is not such authorization.

## 10. Minimum machine-readable test-record semantics

JSON, YAML or a test-management system may be used, but records MUST express:

    test_record:
      test_id: REQUIRED
      specification_version: REQUIRED
      trace_ids: [REQUIRED]
      scenario_id: REQUIRED
      candidate:
        product: OPEN_UNTIL_SELECTED
        version_edition: REQUIRED_AT_EXECUTION
        topology_config_hash: REQUIRED_AT_EXECUTION
      environment:
        isolation_proof: REQUIRED
        synthetic_data_only: true
        production_connectivity: PROVEN_ABSENT
      preconditions: REQUIRED
      fault_schedule:
        seed: REQUIRED
        ordered_steps: REQUIRED
      assertions:
        - invariant_id: REQUIRED
          expected: REQUIRED
          oracle_id: REQUIRED
          observed: REQUIRED
          result: PASS | FAIL | INCONCLUSIVE
      evidence:
        artifacts: REQUIRED
        integrity_hashes: REQUIRED
        clock_source: REQUIRED
        custody: REQUIRED
      run:
        started_at: REQUIRED
        ended_at: REQUIRED
        executor: REQUIRED
        reviewer: REQUIRED
      overall_result: PASS | FAIL | INCONCLUSIVE | NOT_RUN | BLOCKED
      deviations: []
      residual_risk: REQUIRED
      owner_approval_ref: REQUIRED_WHEN_REQUIRED

A finalized record MUST be immutable or preserve append-only correction history. Overall PASS is valid only when every mandatory assertion passes and no required field/evidence is missing. A test cannot self-declare its own independence.

## 11. A22 remediation matrix

| A21 finding | A22 control | Closure evidence required | Status |
|---|---|---|---|
| F02 Identity/dedup | §4 | OD approvals, versioned contract, vectors, migration tests | OPEN |
| F03 UNKNOWN commit | §5 | State machine, linearization/isolation proof, race histories | OPEN |
| F04 External effects | §6 | Destination contracts and full-boundary tests | OPEN |
| F05 Retention/restore | §7 | Approved horizon, lifecycle and clean-room restore evidence | OPEN |
| F06 Oracle trust | §8 + A24 | Trust-boundary matrix, negative controls, corroboration | OPEN |
| F07 Traceability | §3 | Complete bidirectional matrix and orphan check | OPEN |
| F08 Result contract | §8, §10 | Schema, deterministic classification and complete records | OPEN |
| F09 Financial boundary | §9 | Isolation proof and scoped authorization | OPEN |
| F10 Recovery controls | §7.2–7.3 | Restore integrity/domain reconciliation evidence | OPEN |

A22 is a specification response, not evidence that a control is implemented/effective. Findings close only after closure evidence is reviewed and accepted by an authorized approver.

## 12. Owner decision and evidence blockers

Remain OPEN until supplied by the accountable owner and verified:
- OD-01..OD-04: source identity, namespace, canonicalization and fingerprint.
- OD-05..OD-07: atomic acceptance and Receipt/WorkItem cardinality.
- OD-08..OD-10: replay/tombstone lifecycle, quarantine and revocation.
- OD-11: UNKNOWN outcome and client contract.
- OD-12: evidence retention/independence policy.
- C-01..C-16: legal entity, jurisdiction, data/residency, processing, retention, key custody, availability, recovery, latency, workload, operations, provider, cost, portability and audit evidence.
- G1..G9: no gate passes without approved evidence.

No example value in A20/A22 may be promoted into a default or owner decision.

## 13. Research basis

- RFC 9110 §9.2.2 — idempotent methods and safe retry semantics: https://www.rfc-editor.org/rfc/rfc9110.html
- Google Cloud Spanner — unknown commit status and duplicate side-effect risk: https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once
- AWS Prescriptive Guidance — transactional outbox, duplicate delivery and ordering: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- AWS Builders' Library — timeout, retry, backoff, jitter and overload amplification: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- PostgreSQL transaction isolation: https://www.postgresql.org/docs/current/transaction-iso.html
- PostgreSQL constraints and unique constraints: https://www.postgresql.org/docs/current/ddl-constraints.html
- PostgreSQL pg_verifybackup limitations: https://www.postgresql.org/docs/current/app-pgverifybackup.html
- NIST SP 800-53A Rev. 5 — assessment planning and evidence methods: https://csrc.nist.gov/pubs/sp/800/53/a/r5/final
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html

These sources inform protocol design; they do not prove Lottorito correctness or resolve owner decisions.

## 14. Final disposition

- A22: PROPOSED SPECIFICATION AMENDMENT; RESEARCH ONLY.
- A21-F02..F10 addressed at specification-structure level; all remain OPEN pending implementation-independent evidence and authorized review.
- A21-F01/F06/F08/F13 assurance work remains for A24; no independence claim.
- A20-01..A20-28: DESIGNED / NOT RUN.
- OD-01..OD-12 OPEN; C-01..C-16 OPEN; G1..G9 NOT TESTED / NOT PASSED.
- ADR-002 PROPOSED; A11-F01..F08 OPEN; A12 NOT PERFORMED / NOT ASSESSABLE.
- R0 BLOCKED; R1 research-only; R2 NOT STARTED; R3 NOT AUTHORIZED; A4 NOT APPROVED.
- No runtime/harness, candidate selection, partner integration, financial operation, production access, merge or deployment authorized.

**Conclusion:** A22 makes missing contracts and proof obligations explicit while preserving owner authority. It does not claim the system now satisfies them.
