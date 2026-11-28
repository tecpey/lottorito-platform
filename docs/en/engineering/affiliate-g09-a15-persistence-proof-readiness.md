# G09-A15 — ADR-002 Persistence Proof Readiness & Owner Decision Matrix

**Document ID:** LOT-AFFILIATE-G09-A15-001  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** PROOF-READINESS PACKAGE — candidate-neutral; owner decisions and independent review remain OPEN  
**Baseline PR:** #76  
**Baseline head inspected:** `736390f86ab425a8c273dcf254cc5974e9eb55ae`  
**Related:** LOT-AFFILIATE-G09-ADR-002 v0.3.0; G09-A11; G09-A12; G09-A7; G09-A4; G09-A8; G09-A14  
**Authority:** Design and proof preparation only. No persistence/queue/vendor selection, runtime or harness execution, partner integration, financial operation, merge or deployment authorization.

## 1. Purpose and disposition

G09-A15 converts the open ADR-002 obligations into a candidate-neutral proof contract and an accountable owner-decision matrix. It defines what must be decided, what a future persistence candidate must demonstrate, how the proof must be observed independently, and when the system must remain stopped.

This document is **not** an independent review, owner approval, candidate assessment, implementation plan for a selected vendor, or proof that any test has run. It does not close A11-F01..F08, A7/A8 findings, or any A4 gate. The A12 package remains the procedure for a genuinely independent reviewer; A15 makes the future evidence package more executable and auditable.

## 2. Frozen baseline and evidence boundary

The baseline inspected was PR #76 at head `736390f86ab425a8c273dcf254cc5974e9eb55ae`. On that exact head:
- Affiliate Contract Validation #235 (run `46071082568`): SUCCESS.
- Documentation Governance #1062 (run `46071082558`): SUCCESS.
- PR #76 was Open/Draft and not merged.

These runs validate the configured contract/documentation checks only. They do not establish database transaction behavior, durability, replica consistency, promotion safety, authority fencing, replay guarantees, or runtime authorization. Any later commit invalidates exact-head applicability and requires fresh CI verification before those workflow results are attributed to the new head.

The review of the PR recorded no submitted review objects or discussion comments at the time of inspection. This is not proof that no off-platform review exists; it means no GitHub review sign-off was available in the inspected PR record. A genuinely independent reviewer must be identified and must satisfy A12 §2.

## 3. Normative proof obligations

The following are acceptance obligations for a future candidate, not selected implementation mechanisms.

### PO-01 — Atomic acceptance pair

For one authenticated, installation-bound source-event identity, acceptance must produce exactly one InboxReceipt and exactly one linked WorkItem in one atomic commit boundary. Acknowledged success must never expose only one member of the pair. The linkage must enforce immutable tenant and installation equality. Duplicate delivery must resolve to the same durable acceptance reference and must not create another WorkItem.

Required evidence:
- direct authoritative persistence inspection in a documented consistency mode;
- transaction/constraint evidence for unique source identity and one-to-one/at-most-one linkage;
- fault injection between every logical write and before/after commit;
- same-key concurrency schedules;
- negative assertions that partial pairs and cross-tenant links cannot commit.

A textual invariant or application-level pre-check is insufficient if the persistence boundary does not enforce it.

### PO-02 — Commit outcome classification and reconciliation

The client-visible outcome must distinguish:
- **COMMITTED:** commit success is confirmed under the approved durability contract;
- **ABORTED:** the persistence authority conclusively confirms no commit;
- **UNKNOWN:** the caller cannot determine whether commit occurred;
- **UNAVAILABLE:** no authoritative decision can currently be made.

These are proof vocabulary for test schedules, not an approved HTTP status or public error enum. UNKNOWN must not be collapsed into retry-as-new, confirmed acceptance, or confirmed rejection. A negative read from a stale/weakly consistent replica is not evidence of abort. Reconciliation must arbitrate against an in-flight original transaction using the same stable identity and a proven serialization/consistency mechanism.

Required evidence:
- deterministic original-commit/retry interleavings;
- proof that the original transaction has committed, aborted, or is still unresolved before a second write can be authorized;
- authoritative read semantics and consistency mode;
- proof that UNKNOWN never creates a second receipt/work item pair;
- proof that inability to reach the authority fails closed.

### PO-03 — Acknowledged-commit durability and recovery point

The owner must define the supported failure model and the exact acknowledgement durability promise before any 202/durable-acceptance claim is approved. The candidate must demonstrate that every acknowledged pair survives every failure class included in that promise, and that promotion/restore cannot silently discard acknowledged state.

Required evidence:
- candidate-specific write/flush/replication acknowledgement semantics;
- documented failure classes and excluded failures;
- controlled primary loss immediately after acknowledgement;
- promotion and old-primary rejoin schedules;
- restore/PITR tests with recovery-point comparison;
- independent confirmation of acknowledged identities before and after recovery.

Do not invent an RPO, synchronous replica count, quorum, region count, or durability tier. These are owner decisions tied to business loss tolerance and candidate capability.

### PO-04 — Single-writer authority and fencing

The system must have one authoritative writer for the protected acceptance domain. A monotonic authority epoch is useful only if the enforcement boundary rejects stale epochs on every protected write path and the epoch cannot be rolled back or forked by the same failure/restore operation it is intended to protect against.

Required evidence:
- authority-root threat model and failure analysis;
- partition/promotion/old-primary-rejoin schedules;
- direct proof that the stale writer cannot reach or mutate the protected persistence boundary;
- tests of every write path, including administrative, repair, migration and background paths;
- restore procedure proving old writer credentials/processes are fenced before writes resume.

A token stored only beside the data that can be rolled back is not, by itself, proof of a non-rollback authority epoch. Queue leadership or a worker lease does not prove storage-level fencing.

### PO-05 — Replay, fingerprint and retention lifecycle

Source-event identity, HTTP request idempotency identity and economic-effect identity remain distinct. Fingerprinting is a versioned compatibility contract, not an incidental hash function. A change in parser, canonicalization, schema, extension registry or semantic normalization must not silently reinterpret a previously accepted event.

Required evidence:
- strict parser behavior, including duplicate-member rejection before object materialization;
- cross-language canonicalization vectors and versioned test fixtures;
- explicit treatment of number range/representation and Unicode preservation;
- migration and mixed-version deployment schedules;
- replay tests before and after the approved retention horizon;
- tombstone/backup/restore/offboarding/legal-hold lifecycle evidence.

RFC 8785 JCS requires input to satisfy I-JSON constraints, including no duplicate property names, valid Unicode and interoperable number representation. This is relevant background, not approval of JCS for Lottorito. The existing ADR's fingerprint profile remains unapproved until owner approval, parser guarantees and cross-language vectors are supplied.

### PO-06 — Pair integrity, quarantine and tenant lifecycle

Pair cardinality and tenant/installation binding must be enforceable at the durable boundary. A partial/corrupt pair is an invariant breach, not a normal retry signal. Untrusted payload content must not independently trigger broad tenant quarantine. Quarantine must exclude the affected WorkItem from worker claim at a serialized boundary while preserving unaffected tenants.

Required evidence:
- uniqueness and relationship constraint tests;
- deliberate omitted-write and partial-restore injection;
- tenant/installation mismatch attempts;
- quarantine-vs-claim and quarantine-vs-in-flight-commit schedules;
- authorization and audit evidence for quarantine actions;
- unaffected-tenant availability/fairness assertions;
- explicit lifecycle policy for already accepted receipts after installation suspension/revocation.

### PO-07 — Acceptance is not execution

The acknowledgement means only that an event has been accepted durably under the approved contract. It does not mean claimed, processed, attributed, qualified, commission-calculated, posted to a ledger, paid or settled. Duplicate submissions return the same stable acceptance reference. No ingress path may mutate financial state.

Required evidence:
- contract/status-resource state-transition tests;
- capability and credential inspection;
- network/service-binding and queue-path inspection;
- direct ledger/wallet/payment/payout non-effect assertions;
- negative tests for accidental reachability through indirect service calls.

## 4. Owner decision matrix — no defaults may be inferred

| ID | Decision required | Accountable owner(s) | Required decision artifact | Blocks |
|---|---|---|---|---|
| OD-01 | Source namespace and immutable event identity scope | Product/domain + partner owner + security | Versioned source identity contract and collision policy | PO-01/02/05 |
| OD-02 | Request idempotency-key scope, binding and retention | API/platform + security + privacy | Key lifecycle, tenant/installation binding, replay horizon | PO-02/05 |
| OD-03 | Parser, duplicate JSON member policy, fingerprint algorithm/version and migration | Architecture + security + integration | ADR, cross-language vectors, compatibility/migration policy | PO-05 |
| OD-04 | Supported failure model and acknowledged-commit durability promise | Owner + SRE/data platform + finance/risk | Failure-class matrix, RPO/RTO decision, acknowledgement contract | PO-03 |
| OD-05 | Single-writer authority root, epoch allocation and stale-writer enforcement | Platform/SRE + security | Authority/fencing ADR and threat model | PO-04 |
| OD-06 | Persistence isolation/serialization and in-flight transaction arbitration | Data platform + architecture | Candidate-specific semantics dossier and schedules | PO-01/02/04 |
| OD-07 | Receipt/WorkItem cardinality and repair/quarantine policy | Data platform + domain + security | Constraint/capability design and repair runbook | PO-01/06 |
| OD-08 | Replay horizon, tombstones, backup/restore, deletion and legal hold | Privacy/legal + security + operations + owner | Data lifecycle and retention policy | PO-05 |
| OD-09 | Quarantine authority, scope, expiry, review and recovery | Security + operations + domain owner | Authorization matrix and audited state machine | PO-06 |
| OD-10 | Installation suspension/revocation effect on accepted receipts | Product/domain + security + partner owner | Lifecycle decision and race semantics | PO-06 |
| OD-11 | Public UNKNOWN/unavailable response and retry guidance | API/platform + owner + partner owner | Wire contract and machine-readable error mapping | PO-02/07 |
| OD-12 | Evidence retention, access, integrity and independent review authority | Security + privacy/legal + QA + owner | Evidence policy, reviewer assignment and signed disposition | All POs |

No numeric value, vendor default, provider marketing tier or example in a product document substitutes for an owner decision. If an accountable owner is not assigned, the item remains OPEN and the dependent proof cannot pass.

## 5. Candidate-neutral proof schedule

All schedules use synthetic tenants, installations, events and credentials. No real partner/customer/player data and no financial capability are permitted.

| Schedule | Fault/interleaving | Required result | Independent evidence |
|---|---|---|---|
| S01 | Two concurrent identical source events | One acceptance pair; both callers resolve to same stable reference | Authoritative pair query + transaction trace |
| S02 | Same identity, different semantic payload | Deterministic conflict; no second pair or silent overwrite | Raw request capture + fingerprint/version record + DB query |
| S03 | Crash after Receipt write but before WorkItem write | Transaction leaves no partial committed pair | Fault controller + direct persistence snapshot |
| S04 | Crash after WorkItem write but before commit | No visible partial acceptance | Fault controller + independent read |
| S05 | Commit succeeds but response is lost | Retry reconciles to original pair; no duplicate WorkItem | Network fault evidence + authority read + transaction timeline |
| S06 | Original commit remains in flight while retry begins | Exactly one serialized outcome; no negative-read false abort | Deterministic barrier schedule + DB/transaction trace |
| S07 | Authority unavailable during UNKNOWN reconciliation | Fail closed; do not create a second pair | Network partition evidence + zero-write assertion |
| S08 | Primary lost immediately after acknowledgement | Outcome conforms to approved durability/RPO contract | Acknowledgement log + failover trace + recovered state |
| S09 | Old primary rejoins after promotion | Old authority cannot mutate protected data | Fencing boundary evidence + rejected write attempt |
| S10 | Restore rolls back WorkItem generation/epoch state | Claims/writes remain stopped until recovery fence is re-established | Restore manifest + old-worker rejection + recovery attestation |
| S11 | Replay after dedupe retention boundary | Behavior matches explicit source/legal policy; no undocumented guarantee | Tombstone/retention query + replay trace |
| S12 | Quarantine races worker claim and installation revocation | One serialized winner; no stale claim or prohibited post-revocation transition | Transaction trace + lifecycle version + zero-row stale assertion |

Schedules S01–S12 are proposed proof obligations. They have **NOT RUN**. They supplement rather than renumber the canonical 47 A4 cases and the existing A7/A8/A10/A11 subcases.

## 6. Evidence package contract

Every future run must produce a tamper-evident evidence manifest containing, at minimum:
- repository, branch, source commit SHA, source artifact hashes and build identifier;
- candidate product/version/configuration identity and topology (without secrets);
- test harness version, fixture IDs, deterministic schedule ID and fault-injection controller version;
- start/end timestamps with declared clock source and uncertainty;
- request/correlation IDs and synthetic tenant/installation identities;
- persistence authority identity, read consistency mode, transaction identifiers and commit/replication acknowledgement metadata available from the candidate;
- fault-injection event proving the intended fault point was reached;
- raw observations from each independent oracle, with collection method and access identity;
- expected versus observed result, assertion output and deviations;
- integrity hashes/signature and immutable storage reference;
- reviewer identity, independence/conflict declaration and signed disposition.

Application logs are supporting observations, not an independent persistence oracle. A dashboard, green CI job, HTTP response or replica read with undocumented consistency cannot alone prove commit durability. The test harness must not be its own sole oracle for the property it claims to prove.

## 7. Staged readiness gates

| Gate | Entry criteria | Exit criteria | Current state |
|---|---|---|---|
| R0 — Contract freeze | A7/A11/A12/A14 inputs pinned | Owner decisions OD-01..12 recorded or explicitly deferred with rationale and impact | BLOCKED |
| R1 — Candidate semantics dossier | Candidate proposed by accountable owner after R0 | Isolation, transaction, uniqueness, replication, failover, fencing, restore and consistency semantics independently mapped to POs | NOT STARTED |
| R2 — Synthetic harness design | R1 accepted; no financial capabilities | Deterministic barriers/fault injection, independent oracles, fixtures and evidence manifest reviewed | NOT STARTED |
| R3 — Candidate proof execution | Explicit owner/security/QA/SRE approval of isolated test scope | S01–S12 executed; failures triaged; all required evidence retained; no production data/effects | NOT AUTHORIZED |
| R4 — Independent disposition | Frozen evidence/source SHA; qualified reviewer assigned | Signed finding-by-finding disposition; new findings tracked; limitations and residual risk accepted by owner | NOT STARTED |
| R5 — A4 release-gate review | R0–R4 complete | Each A4 gate separately reviewed and approved by its accountable authority | NOT APPROVED |

Passing a stage does not automatically pass the next stage. A candidate may fail a proof obligation and be rejected without weakening the invariant to fit the candidate.

## 8. Critical stop conditions

Stop the affected ingress/worker path and do not acknowledge new acceptance if any of the following is observed:
- two committed receipt/work-item pairs for one identity;
- acknowledged acceptance lost outside the explicitly approved failure model;
- stale/old primary can write after authority transfer;
- UNKNOWN is treated as abort based only on a weak/stale negative read;
- partial pair is externally visible as accepted;
- tenant or installation identity can be changed or crossed;
- replay after the promised horizon can create an undocumented duplicate;
- quarantine can be triggered broadly by untrusted input or can race with worker claim without serialization;
- any ingress credential/service path can mutate ledger, wallet, payment, commission, settlement or payout state;
- evidence cannot establish source SHA, candidate identity, fault point or oracle provenance.

Do not repair a failed proof by changing the expected result after observing it. Any protocol change requires a versioned ADR update and rerun of affected schedules.

## 9. Relationship to existing findings

| Existing item | A15 treatment | Status after A15 |
|---|---|---|
| A11-F01 — acknowledged durability/RPO | PO-03, OD-04, S08 | OPEN |
| A11-F02 — authority epoch/split brain | PO-04, OD-05, S09–S10 | OPEN |
| A11-F03 — in-flight commit vs negative read | PO-02, OD-06, S05–S07 | OPEN |
| A11-F04 — pair cardinality/linkage | PO-01/06, OD-07, S01/S03/S04 | OPEN |
| A11-F05 — fingerprint versioning | PO-05, OD-03, S02/S11 | OPEN |
| A11-F06 — retention-bounded idempotency | PO-05, OD-02/08, S11 | OPEN |
| A11-F07 — quarantine blast radius | PO-06, OD-09/10, S12 | OPEN |
| A11-F08 — accepted vs executed | PO-07, OD-11, capability/non-effect evidence | OPEN |

A15 adds structure and explicit proof scheduling; it closes no finding. A12 remains the independent-review procedure. A11 remains same-author self-review. ADR-002 remains PROPOSED.

## 10. Research basis and limits

- Google Cloud Spanner documents that commit can return UNKNOWN and that the caller may need to read state again. This is a concrete example of why commit ambiguity needs an explicit protocol; it is not portable proof that another database behaves the same way: https://docs.cloud.google.com/spanner/docs/reference/rest/v1/projects.instances.databases.sessions/commit
- Spanner's transaction documentation describes serializable transactions and consistent commit-time behavior. These are product-specific semantics and must not be generalized to an unselected candidate: https://docs.cloud.google.com/spanner/docs/transactions
- PostgreSQL documents synchronous replication, failover and the risk of split-brain/old-primary operation. Any PostgreSQL candidate would require a concrete topology and fencing proof, not merely enabling replication: https://www.postgresql.org/docs/current/warm-standby.html and https://www.postgresql.org/docs/current/warm-standby-failover.html
- RFC 8785 defines JCS and its I-JSON constraints, including duplicate property-name prohibition and Unicode/number requirements: https://www.rfc-editor.org/rfc/rfc8785.html
- NIST SP 800-204D discusses supply-chain security, provenance and attestations in DevSecOps CI/CD: https://csrc.nist.gov/pubs/sp/800/204/d/final

These sources inform the questions and evidence design. They do not select a database, queue, authority provider, fingerprint implementation, retention period or operating topology.

## 11. Final disposition

**G09-A15: PROOF-READINESS PACKAGE PREPARED — NOT AN INDEPENDENT REVIEW; NO RUNTIME PROOF EXECUTED.**

- ADR-002 remains PROPOSED.
- A11-F01..F08 remain OPEN.
- A7/A8/A10/A11 extensions remain NOT RUN/BLOCKED unless separately evidenced.
- All eight A4 gates remain NOT APPROVED.
- A13-F02 runtime installation allowlist proof remains OPEN.
- A13-F05 UNKNOWN mapping, durability/failure model, RPO and recovery decisions remain owner-blocked.
- No persistence/queue/vendor selected; no runtime/harness execution, partner integration or financial operation authorized.
- PR #76 remains Draft; no merge or deployment authorized.

**Next dependency:** appoint a qualified independent reviewer meeting A12 §2 and assign accountable owners for OD-01..OD-12. Until then, the project may refine design and prepare evidence contracts, but it must not claim independent approval or persistence readiness.
