# G09-A16 — ADR-002 Adversarial Architecture Review & Independent Reviewer Dossier

**Document ID:** LOT-AFFILIATE-G09-A16-001  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** AUTHOR-LED META-REVIEW AND REVIEWER DOSSIER — NOT independent sign-off; no candidate/runtime proof  
**Frozen source baseline:** PR #76, head `8e9a880c14000bd158f66ae2001c02669ed4cc6b`  
**Review subject:** LOT-AFFILIATE-G09-ADR-002 v0.3.0 and its A7/A11/A12/A14/A15 supporting evidence  
**Authority:** Analysis and independent-review preparation only. No owner decision, technology selection, runtime/harness execution, partner integration, financial operation, merge or deployment authorization.

## 1. Executive disposition

This A16 review independently re-reads the current design package as a connected protocol rather than treating each document or CI result as proof. It challenges whether the proposed acceptance contract is complete, falsifiable, enforceable and reviewable.

**Disposition: ADR-002 remains PROPOSED; independent review is still required; all A11-F01..F08 remain OPEN.** The documentation is materially more mature, but the present evidence is not sufficient to approve a persistence architecture or to claim a runtime guarantee.

A16 is deliberately not an independent review. It is an author-led meta-review and a structured challenge dossier for the qualified reviewer. It may identify questions and potential gaps; it cannot close an A11 finding, approve an owner-controlled policy, or attest to a candidate that has not been selected and tested.

### What is established
- The contract and documentation CI passed on the frozen baseline head; this is source/contract validation only.
- A14 exact-head validation passed on its own historical exact head; A15 exact-head CI passed on the then-current head, and the later A16 baseline has its own CI requirement.
- The A7 catalogue has 47 canonical A4 IDs and 21 separately tracked extension IDs; the EN/FA identifier inventories were compared for parity.
- A15 defines seven candidate-neutral proof obligations, twelve owner decisions and twelve deterministic synthetic schedules.
- The PR record previously inspected had no GitHub review submissions. Off-platform review may exist but is not evidence in the repository record.

### What is not established
- Any database/queue/consensus/authority implementation or vendor has been selected.
- The semantics of a specific candidate's commit acknowledgement, failover, promotion, restore, isolation, uniqueness, fencing or read consistency.
- Acknowledged-write RPO/RTO, replay horizon, retention, legal hold, deletion and recovery policy.
- A runtime-enforced receipt/work-item cardinality invariant.
- A safe public HTTP mapping for COMMITTED / ABORTED / UNKNOWN / UNAVAILABLE.
- Any execution of A7/A8/A11/A15 proof schedules, or any production recovery/KMS/HSM/financial proof.

## 2. Frozen review input and change control

The independent reviewer must fetch the following artifacts at exactly the frozen source commit and record their blob hashes:
1. `docs/en/engineering/adr-002-atomic-ingress-acceptance-reconciliation.md` and Persian counterpart.
2. `docs/{en,fa}/engineering/affiliate-g09-a7-47-case-traceability.md`.
3. `docs/{en,fa}/engineering/affiliate-g09-a11-adr002-adversarial-review.md`.
4. `docs/{en,fa}/engineering/affiliate-g09-a12-adr002-independent-review-package.md`.
5. `docs/{en,fa}/engineering/affiliate-g09-a15-persistence-proof-readiness.md`.
6. OpenAPI, AsyncAPI, event/security acceptance contracts, validation manifest and fixtures.
7. The decision registers, project status and PR #76 metadata.

**Frozen baseline:** `8e9a880c14000bd158f66ae2001c02669ed4cc6b`.

A changed head invalidates the review scope. The reviewer must classify each intervening change as editorial, semantic, security-relevant or proof-affecting, then re-freeze the source and revisit impacted findings. CI results are attributable only to the exact commit on which they ran.

## 3. Independence and reviewer qualification protocol

Before substantive review, the reviewer must provide a signed declaration covering:
- no authorship or material co-authorship of ADR-002, A7, A11, A12, A15 or the implementation under review;
- employment, financial, reporting-line, vendor, delivery-deadline and personal conflicts;
- relevant hands-on experience in transactional persistence, concurrency control, distributed systems and failure recovery;
- ability to assess security boundaries, tenant isolation, data integrity and independent evidence;
- any domain outside their competence that requires a second specialist.

A reviewer who helped design the protocol may provide valuable technical feedback, but must not be represented as independent. If independence is uncertain, record **NOT ASSESSABLE** and appoint another reviewer. A16 authorship and prior assistant analysis are not independent review credentials.

## 4. Protocol reconstruction — required before accepting prose

The reviewer must produce their own state machine and happens-before diagram without relying on the ADR's narrative. At minimum model:
1. authentication and immutable tenant/installation binding;
2. source-event identity and HTTP request idempotency-key resolution;
3. parsing, schema validation and fingerprint/version selection;
4. InboxReceipt + WorkItem atomic acceptance;
5. commit acknowledgement and response loss;
6. duplicate, conflicting and concurrent same-identity requests;
7. UNKNOWN reconciliation against an in-flight original attempt;
8. primary loss, promotion, old-primary return and restore/PITR;
9. quarantine versus worker claim and in-flight processing;
10. replay after retention expiry, tombstone deletion, backup restore and tenant offboarding.

For each transition, identify: the single authority; the linearization/serialization point; the durable state transition; the enforcement boundary; the observable oracle; the permitted retry; and the fail-closed behavior. A paragraph, log line, HTTP response or application pre-check is not an enforcement mechanism by itself.

## 5. A16 cross-cutting challenge register

These are author-led challenge questions, not newly closed or independently accepted findings. The reviewer may split, reject, replace or add findings. Do not force a PASS.

| Challenge | Severity if unresolved | Required challenge / falsifiable acceptance condition | Related existing work |
|---|---|---|---|
| A16-C01 — Owner decisions are not protocol defaults | Critical | Verify all twelve A15 OD decisions have an accountable owner, approved value/rationale, scope, effective version and evidence. Unknowns must block only the claims that depend on them; no vendor default or plausible number may silently fill a gap. | A15 OD-01..OD-12; A11-F01/F02/F06/F07 |
| A16-C02 — Exact pair invariant must be enforceable | Critical | Construct every path that can write either row: API, retry, repair, migration, admin, background and restore. Prove no accepted receipt can commit without exactly one linked WorkItem and no orphan/duplicate WorkItem can become claimable. Atomic transaction semantics alone do not prove application code included both writes. | A11-F04; A15 PO-01/PO-06 |
| A16-C03 — Authority epoch must survive the failure it fences | Critical | Challenge epoch allocation, persistence, restore, backup rollback, split-brain, credential reuse and old-primary rejoin. Show that stale writers are rejected at the protected write boundary, not merely by a lease check in the caller. A counter stored only in rollback-prone state is not sufficient evidence. | A11-F02; A15 PO-04 |
| A16-C04 — UNKNOWN requires both safety and liveness analysis | Critical | Model lost response, transaction still running, transaction abort, leader election, unavailable authority and delayed packets. Prove no second pair can be created; also state when and how UNKNOWN can eventually resolve, who owns reconciliation, and how indefinite ambiguity is surfaced without inventing an unsafe retry. | A11-F03; A13-F05; A15 PO-02 |
| A16-C05 — Acknowledgement is relative to a failure model | Critical | Define included/excluded failures, local flush, replica/consensus acknowledgement, eligible promotion set, restore point and acknowledged-write RPO. Force loss immediately after acknowledgement and compare accepted identities before/after promotion and restore. Never infer zero RPO from the word synchronous. | A11-F01; A15 PO-03 |
| A16-C06 — Identity, fingerprint and numeric semantics need a frozen profile | High | Test duplicate JSON members before object materialization, escaped duplicate names, number precision/range, Unicode preservation, parser differentials, schema evolution and cross-language canonicalization. Bind fingerprint version to stored receipt; define mixed-version compatibility. | A11-F05; A15 PO-05 |
| A16-C07 — Idempotency guarantee has a time boundary | Critical | Separate source-event dedupe, HTTP request-key retention and economic-effect idempotency. Derive replay horizon from an actual source contract and legal/privacy policy; include tombstones, backups, restore, deletion and offboarding. Explicitly state when the guarantee ends. | A11-F06; A15 PO-05 |
| A16-C08 — Quarantine and worker claim need a common arbitration boundary | High | Interleave quarantine, claim, lease expiry, worker pause/resume and retry. Prove no new claim after quarantine linearizes; define what happens to a claim that linearized first; show scope cannot be widened by untrusted payloads and unaffected tenants remain serviceable. | A11-F07; A15 PO-06 |
| A16-C09 — Public acceptance semantics must not overclaim | High | Reconcile internal COMMITTED/ABORTED/UNKNOWN/UNAVAILABLE with OpenAPI status/code and the client retry contract. Ensure 202 means only the approved durable acceptance; never expose worker state or imply commission/financial completion. | A11-F08; A13-F05; A15 PO-07 |
| A16-C10 — Evidence must be independently attributable | High | Require a reproducible evidence manifest tying source SHA, binary/build, config, candidate version, topology, fault schedule, trusted timestamps, request IDs, authority epoch and oracle output together. System-under-test logs and dashboards alone cannot prove persistence state. | A12 §7; A15 evidence contract |

## 6. Deterministic adversarial schedules

The reviewer should first inspect A7 and A15 schedules; the following are minimum schedule families to ensure no important interleaving is hidden by happy-path tests:

| Schedule family | Required ordering/fault | Safety oracle |
|---|---|---|
| S-A — same-key concurrent ingress | Two callers start before either can observe the other's commit; vary transaction winner and response loss. | Exactly one source identity, one receipt, one WorkItem; stable reference; no cross-tenant lookup. |
| S-B — lost commit response | Commit may succeed, then connection is cut before client receives response. | Client remains UNKNOWN until authoritative resolution; no duplicate pair. |
| S-C — in-flight commit vs negative read | Original transaction pauses before commit; reconciliation sees no visible row; retry attempts same identity. | Retry serializes/blocks/loses uniqueness arbitration; negative snapshot never authorizes second pair. |
| S-D — abort vs retry race | Original transaction is forced to abort while retry is waiting. | At most one committed pair; definitive outcome only after original is known terminated. |
| S-E — acknowledgement then primary loss | Kill primary immediately after acknowledgement; promote candidate and inspect accepted identities. | Result matches owner-approved failure model/RPO; no worker runs on divergent state. |
| S-F — old primary resurrection | Partition old primary, promote new authority, then reconnect old node and attempt writes through every route. | Old writer rejected at storage/enforcement boundary; no dual-writer state. |
| S-G — restore rollback | Restore an older backup/PITR point and attempt reuse of pre-restore epochs and idempotency identities. | Authority and dedupe policy remain safe; system stays fenced if proof is unavailable. |
| S-H — pair mutation matrix | Omit receipt/work-item writes independently; inject partial restore, direct SQL/admin and repair paths. | Invalid cardinality/linkage cannot commit or become executable. |
| S-I — quarantine/claim race | Pause claim before/after its serialization point; race quarantine and worker resumption. | One deterministic winner; no claim after quarantine boundary; audited scope. |
| S-J — replay lifecycle | Replay before/after retention, tombstone deletion, backup expiration, offboarding and legal hold. | Behavior exactly matches approved horizon; no undocumented permanent guarantee. |
| S-K — parser/fingerprint differential | Duplicate escaped keys, number edge cases, Unicode and schema/fingerprint version skew across languages. | Reject ambiguity or apply the same frozen profile; never silently treat changed intent as duplicate. |
| S-L — authority unavailable | Remove access to authority service or its quorum during reconciliation/promotion. | Fail closed; no speculative acceptance, promotion or retry-as-new. |

These are schedules to implement only after owner decisions, candidate selection and runtime authorization. They are not executed by this document.

## 7. Independent oracle and evidence contract

Every future candidate proof must triangulate independent evidence:
1. client/API observation, recorded separately from persistence truth;
2. authoritative persistence inspection with exact consistency mode and authority identity;
3. transaction/constraint evidence for atomicity and same-key arbitration;
4. a single-snapshot receipt/WorkItem cardinality and tenant/installation linkage query;
5. fault-controller record proving the intended injection point was reached;
6. authority/fencing evidence at the actual enforcement boundary;
7. negative financial-reachability evidence across credentials, service bindings, queues, network/DNS and indirect execution paths;
8. immutable evidence manifest with hashes, timestamps, correlation IDs, configuration and candidate identity.

A test is **INCONCLUSIVE**, not PASS, if the fault was not proven to occur, the oracle is stale/ambiguous, evidence is missing, the test did not cover the declared failure class, or the run cannot be tied to the exact source/configuration. A successful process exit alone is not proof of a safety property.

## 8. Standards and leading-practice interpretation

- **AWS Builders' Library — idempotent APIs:** stable caller intent, request-token binding, parameter mismatch detection and a deliberately chosen retention lifetime are essential. It does not imply exactly-once transport or an indefinite dedupe guarantee.
- **AWS Well-Architected retries:** idempotency is a precondition for safe retries; retry count/time must be bounded; backoff/jitter and one retry layer reduce retry amplification. This is relevant to load safety, not a substitute for same-key transactional arbitration.
- **PostgreSQL WAL and synchronous replication documentation:** acknowledgement strength depends on the configured commit mode and which replica acknowledgement is awaited. Asynchronous commit may acknowledge before WAL reaches durable storage; synchronous modes have different local/remote persistence and replay semantics. This is an example of why the candidate configuration and failure model must be inspected, not a PostgreSQL recommendation.
- **PostgreSQL failover documentation:** after promotion, the old primary must be prevented from acting as primary; otherwise both nodes may believe they are writable. A witness or heartbeat alone is not proof that the old writer is fenced.
- **Fencing-token analysis:** a token protects only when the resource performing the write remembers/compares the monotonic token and rejects stale writes. A lock/lease held by a client is insufficient if a paused client can later write.
- **Jepsen methodology:** record invocation/completion histories while injecting faults, then check the history against an explicit correctness model. A test without a checker/oracle and a replayable schedule is not a distributed-systems proof.
- **RFC 8785 / I-JSON:** canonicalization requires input constraints including no duplicate property names, interoperable number representation and preservation of Unicode strings. JCS is informational, not a default decision for Lottorito; high-precision values may require string representation under an explicitly chosen profile.

References:
- AWS Builders' Library, Making retries safe with idempotent APIs: https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- AWS Well-Architected, Make mutating operations idempotent: https://docs.aws.amazon.com/wellarchitected/2025-02-25/framework/rel_prevent_interaction_failure_idempotent.html
- AWS Well-Architected, Control and limit retry calls: https://docs.aws.amazon.com/wellarchitected/latest/framework/rel05-bp03.html
- PostgreSQL asynchronous commit: https://www.postgresql.org/docs/current/wal-async-commit.html
- PostgreSQL synchronous replication and failover: https://www.postgresql.org/docs/current/warm-standby.html
- PostgreSQL failover and old-primary fencing: https://www.postgresql.org/docs/current/warm-standby-failover.html
- Martin Kleppmann, How to do distributed locking (fencing tokens): https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html
- Jepsen framework and history checking: https://github.com/jepsen-io/jepsen and https://jepsen-io.github.io/jepsen/jepsen.checker.html
- RFC 8785, JSON Canonicalization Scheme: https://www.rfc-editor.org/rfc/rfc8785.html
- RFC 7493, I-JSON: https://www.rfc-editor.org/rfc/rfc7493.html

These sources inform review questions. They do not select a technology, establish a vendor guarantee for Lottorito, or prove an implementation.

## 9. Required independent reviewer output

The independent reviewer must submit a separate, attributable report containing:
- reviewer identity, qualifications and signed independence/conflict declaration;
- exact source commit, PR, artifact blob hashes and reviewed language versions;
- independent state machine, linearization points and authority map;
- findings accepted / accepted with conditions / rejected / not assessable;
- concrete counterexample schedules and reproducible evidence;
- A11-F01..F08 disposition individually, plus new findings and A4/A7 mappings;
- explicit owner decisions that remain unresolved;
- whether ADR-002 is fit for owner decision, requires redesign or is not assessable;
- limitations, untested assumptions and the exact evidence needed next.

No author may mark a finding closed merely by editing a crosswalk. The reviewer must affirm closure evidence; policy choices additionally require the accountable owner. If the reviewer lacks competence in any material area, the report must identify the gap and request a second specialist.

## 10. Stop conditions and non-authorization

Stop and report REJECTED or NOT ASSESSABLE if the design permits any of:
- split-brain writes or a stale writer bypassing fencing;
- acknowledged acceptance loss outside the explicitly approved failure model;
- duplicate or partial receipt/work-item pair;
- cross-tenant existence disclosure;
- stale worker claim after quarantine's serialization boundary;
- replay beyond the approved guarantee without a surviving dedupe record;
- broad quarantine triggered by untrusted payload;
- ingress reaching commission, wallet, ledger, payout or any financial capability;
- a green CI/dashboard being used as a substitute for persistence evidence.

**Current disposition:** ADR-002 PROPOSED; A11-F01..F08 OPEN; A7/A8 extension proof NOT RUN/BLOCKED; all eight A4 gates NOT APPROVED. No candidate, runtime, partner or financial operation is authorized. PR #76 remains Open/Draft and must not be merged or deployed on the basis of A16.

## 11. Owner/reviewer hand-off

The accountable owner should provide the twelve OD decisions in A15 with evidence and rationale. The independent reviewer should then review the frozen artifact set and return the report in §9. Only after that review and owner decisions should the team consider selecting a disposable candidate environment for authorized proof execution. The order must not be reversed.

