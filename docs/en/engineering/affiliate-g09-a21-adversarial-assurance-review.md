# G09-A21 — Adversarial Assurance Review of G09-A20

**Document ID:** LOT-AFFILIATE-G09-A21-001  
**Version:** 1.0.0 | **Status:** INTERNAL ADVERSARIAL SELF-REVIEW — NOT INDEPENDENT ASSURANCE  
**Date:** 2026-11-28  
**Subject:** G09-A20, LOT-AFFILIATE-G09-A20-001

## 1. Executive disposition

A20 is a useful research/test-design baseline, but it is **not yet an executable qualification specification**. It contains 28 adversarial scenarios and ten candidate-neutral invariants, yet the links between requirements, failure histories, oracles, acceptance criteria and evidence are insufficiently precise.

This review records 13 findings: P0: 1; P1: 9; P2: 3. No finding is closed here. No test is run. No A20 remediation is silently applied.

## 2. Independence and review method

This review is performed in the same project-assistance context that authored A20. It is **not an independent assessor opinion**, certification, audit, penetration test, legal opinion or external assurance. A separate critical perspective is simulated, but authorship/context conflict remains.

NIST SP 800-53A defines assessment methods including examine, interview and test. NIST's assessor-independence discussion notes that small organizations may need an independent expert team to review completeness, consistency and veracity. Accordingly:
- A21 = internal adversarial self-review / document examination.
- A12 = NOT PERFORMED / NOT ASSESSABLE until an appropriately independent reviewer is appointed and signs a scoped review.
- Neither A20 nor A21 may be described as independently reviewed, certified, approved or assured.

Method: inspect A20 EN/FA, status claims, invariants, scenarios and adapters; separate safety from liveness; trace requirement → invariant → test → oracle → evidence → gate; challenge ambiguity, circular oracles, hidden assumptions, conflicting authorization boundaries and missing fault combinations; compare EN/FA structure. Semantic parity remains a human-review item.

## 3. Findings

### A21-F01 — Assurance independence is not demonstrated
**Severity:** P0 | **Status:** OPEN / BLOCKING

**Evidence:** A20 calls oracle families independent without defining independence dimensions or proving that an oracle is outside the system-under-test failure/trust domain. This A21 review is itself not independent of A20 authorship.

**Risk:** False assurance may be mistaken for third-party review or proof of control effectiveness.

**Required correction:**
- Replace unqualified “independent oracle” with “separately implemented/cross-source oracle” until independence is demonstrated.
- Define independence dimensions: implementation, data source, privilege, administrative control, failure domain, clock/time source, custody and reviewer.
- Create an oracle-independence matrix per assertion and disclose shared dependencies.
- Keep A12 NOT PERFORMED until a reviewer without design/implementation/operation responsibility performs and signs the review.

**Acceptance:** Every critical assertion has an oracle trust-boundary analysis; reviewer identity, competence, conflict declaration, scope and signed disposition exist. Otherwise A12 remains open.

### A21-F02 — Source identity and deduplication semantics are under-specified
**Severity:** P1 | **Status:** OPEN / BLOCKING

**Evidence:** I-02/I-03/I-04 refer to approved source identity and semantic payload without defining canonical tuple, tenant namespace, source installation, event-ID scope, canonicalization version, fingerprint algorithm, key-rotation behavior or retention horizon. These overlap unresolved OD-01..OD-04 and ADR-002 decisions.

**Risk:** Cross-tenant collisions, false duplicates, duplicate work after expiry, or inconsistent fingerprints across runtime/language versions.

**Required correction:**
- Keep unresolved identity decisions as owner decisions; do not invent defaults.
- Define a versioned identity tuple and canonicalization/fingerprint contract only after OD decisions are approved.
- Cover same identity/same fingerprint, same identity/different fingerprint, missing/malformed identity, canonicalizer/key migration and old-version replay.
- Link identity retention to source redelivery/replay, backup age, PITR window, DR lag and legal constraints.

**Acceptance:** OD decisions approved; one versioned contract defines scope, canonical bytes/fingerprint, migration and expiry; tests cover old/new versions and cross-tenant collisions.

### A21-F03 — UNKNOWN-commit race lacks a complete protocol
**Severity:** P1 | **Status:** OPEN / BLOCKING

**Evidence:** I-05 and A20-05/A20-06 require reconciliation but do not define transaction visibility, linearization point, authoritative read consistency, in-flight transaction arbitration, bounded retry or terminal UNKNOWN handling.

**Risk:** A negative read races an original transaction that commits later; retry creates a second work item or caller receives false failure.

**Required correction:**
- Specify a state machine and allowed transitions for receipt/work-item lifecycle; final state names remain subject to ADR-002.
- Define the single acceptance/linearization point and consistency required for reconciliation reads.
- Prove how retry competes with an original transaction still capable of committing; do not infer absence from stale or non-serializable reads.
- Define escalation and terminal ambiguity handling without unsafe automatic retry.
- Add model-based state exploration before runtime harness work.

**Acceptance:** No reachable history has two accepted work items for one identity, false terminal rejection or success acknowledgement without the durable pair. UNKNOWN remains explicit until authoritative resolution.

### A21-F04 — Database atomicity does not fence external side effects
**Severity:** P1 | **Status:** OPEN / BLOCKING

**Evidence:** A20-11 covers duplicate/reordered outbox delivery and I-06 fences stale actors at protected mutation time, but no end-to-end receiver contract exists for payment/provider/webhook/email effects.

**Risk:** A stale worker loses its database lease but still calls an external system; outbox delivery repeats; database fencing cannot undo an already accepted external request.

**Required correction:**
- Separate internal-state fencing from downstream side-effect idempotency.
- For each destination define idempotency key, request fingerprint, receiver retention, result lookup/reconciliation, timeout-unknown behavior and duplicate semantics.
- Define per-aggregate ordering/sequence and gap handling.
- If a receiver lacks idempotency/reconciliation, document at-most-once/at-least-once trade-offs and prohibit exactly-once external claims.
- Test stale-worker calls after lease loss, response loss after downstream acceptance, receiver replay, key expiry and out-of-order delivery.

**Acceptance:** Every external effect has a proven receiver contract or is explicitly outside the guarantee boundary.

### A21-F05 — Retention, tombstones, replay and restore are not linked
**Severity:** P1 | **Status:** OPEN / BLOCKING

**Evidence:** A20-14/A20-21 mention tombstone resurrection and replay beyond retention but define no retention bound or source replay horizon. Leaving the numeric value open is correct; omitting the derivation method is not.

**Risk:** An event is replayed after its deduplication marker is purged or after an old backup is restored.

**Required correction:**
- Derive minimum identity/tombstone retention from the maximum of source redelivery/replay, restorable backup age, PITR window, replication/DR lag, queue retention, manual replay and incident recovery horizon, subject to law and owner approval.
- If no finite upper bound exists, use durable non-reuse or explicit source epoch/namespace change; do not silently expire identity protection.
- Reconcile restored state against an authoritative high-water mark/event registry before enabling ingress/workers.
- Cover partial restore, delayed queue, old source retry, tenant migration and key/canonicalizer rotation.

**Acceptance:** Approved bound/strategy is explicit; restore cannot reopen a consumed identity; lifecycle tests cover immediately before/at/after expiry.

### A21-F06 — Oracle independence and evidence triangulation are not operationalized
**Severity:** P1 | **Status:** OPEN

**Evidence:** A20 lists oracle families, but multiple oracles may read the same database or trust the same application-generated event. Independence is asserted, not measured.

**Risk:** One faulty source makes implementation and checker agree on an incorrect result.

**Required correction:**
- Map assertions to oracles and identify shared code, storage, credentials, administrators, clocks and failure domains.
- For critical invariants, require two meaningfully distinct evidence paths where feasible (e.g. database constraints plus client-observed history; ledger query plus immutable journal export).
- Add negative controls: corrupt oracle input, suppress a log, skew a clock or remove an evidence source; the run must become INCONCLUSIVE, not PASS.
- Record oracle limitations and blind spots.

**Acceptance:** Every critical assertion has a declared trust boundary and corroborating evidence; missing/corrupt oracle data cannot produce PASS.

### A21-F07 — No end-to-end traceability matrix
**Severity:** P1 | **Status:** OPEN

**Evidence:** C-01..C-16, G1..G9, I-01..I-10 and A20-01..A20-28 are separate lists without complete mapping.

**Risk:** Requirements remain untested while the suite appears broad; test results cannot be traced to owner-approved constraints or gates.

**Required correction:** Add bidirectional traceability:
C-ID → G-ID → requirement/control → invariant → scenario(s) → oracle(s) → evidence artifact → owner/approver → result → residual risk.
Record N/A rationale and uncovered items. Each test maps to assertions; each critical assertion maps to at least one positive and one negative/adversarial case.

**Acceptance:** No mandatory gate or critical invariant has an unexplained coverage gap; traceability is mechanically checked.

### A21-F08 — PASS/FAIL/INCONCLUSIVE lacks an executable result contract
**Severity:** P1 | **Status:** OPEN

**Evidence:** A20 defines labels but not a machine-readable result schema, assertion granularity, run repetitions, duration, load profile, stop rules, variance/confidence or flaky-test handling.

**Risk:** Reviewers classify the same observation differently; one lucky run is mistaken for proof.

**Required correction:**
- Define per-case preconditions, exact fault schedule, observed history, expected invariants, oracle queries, time bounds, evidence completeness and cleanup.
- PASS only when every required assertion is evaluated and evidence is complete; FAIL for demonstrated violation; INCONCLUSIVE for missing fault proof, oracle loss, ambiguous evidence or uncontrolled deviation.
- Derive repetitions, schedule seeds, workload and duration from owner-approved risk/workload objectives; invent no numeric thresholds.
- Separate correctness, availability, performance and recovery results.
- Preserve and minimize counterexamples where applicable.

**Acceptance:** A schema/decision table yields deterministic test-record status; incomplete evidence can never be PASS.

### A21-F09 — Financial boundary and authorization wording is ambiguous
**Severity:** P1 | **Status:** OPEN / BLOCKING

**Evidence:** I-09 says ingress tests assert zero financial side effects; A20-27 tests a separately authorized synthetic posting boundary; Section 7 says no financial operation is authorized. The distinction between an isolated synthetic ledger fixture and a real financial system is not explicit.

**Risk:** An operator interprets the case as permission to touch a real ledger or live financial integration.

**Required correction:**
- Define the only permitted A20/A21 boundary as synthetic, isolated, non-settleable fixtures with no production secrets, external payment rails, wallet, partner balance or live ledger.
- A20-27 must be a pure model/fixture assertion or require separate written authorization and gates; this dossier grants no authorization.
- Assert no real economic side effect and independently prove no production connectivity.
- Put any future real financial proof in a separate stage and approval record.

**Acceptance:** Topology/credentials prove isolation; synthetic journals cannot settle or trigger external transfers; authorization is explicit and scoped.

### A21-F10 — Recovery testing omits high-risk restore controls
**Severity:** P1 | **Status:** OPEN

**Evidence:** A20 covers backup corruption, PITR, DR, failback and key rotation, but not fully immutable/offline backup protection, malicious deletion, restore-time credential isolation, clean-room restore, integrity reconciliation, key hierarchy recovery or proof that recovered state matches an approved checkpoint.

**Risk:** A technically successful restore reintroduces compromised credentials, stale authority, poisoned data, incomplete WAL or divergent economic history.

**Required correction:**
- Add immutable/offline backup deletion-resistance and privileged-delete tests.
- Define clean-room restore with deny-by-default egress, quarantined credentials and no production control-plane/partner/payment reachability.
- Validate backup + WAL/PITR continuity, schema/config compatibility, key hierarchy, tenant isolation, authority epoch, event high-water marks and ledger reconciliation.
- Require post-restore domain invariants, not merely process startup/database health.
- Exercise restore from a separately protected copy and loss of the primary key-management path under authorized synthetic conditions.

**Acceptance:** Restore evidence proves integrity, domain invariants, identity continuity, key recovery and isolation; unknown components block ingress/worker reopening.

### A21-F11 — Safety is stronger than liveness, fairness and degraded-mode coverage
**Severity:** P2 | **Status:** OPEN

**Evidence:** A20 emphasizes no duplicate/split-brain/tenant leak, but “bounded backlog”, “fair scheduling” and “no starvation” have no operational definitions.

**Risk:** System remains safe but permanently stuck; a tenant starves; work grows without bound; UNKNOWN never resolves.

**Required correction:**
- Define liveness separately: accepted work reaches a terminal/visible state under stated recovery assumptions; retries are bounded/backed off; quarantine is observable; backlog drains under approved capacity; one tenant cannot monopolize shared workers.
- Define fairness assumptions, service classes and measurements only after owner workload/SLO approval.
- Test long partitions, repeated leader churn, retry storms, hot tenants, poison messages and partial dependency recovery.

**Acceptance:** Each liveness claim names assumptions, metric, observation window and owner-approved bound. Safety PASS does not imply liveness PASS.

### A21-F12 — Fault combinations and test generation are too manual
**Severity:** P2 | **Status:** OPEN

**Evidence:** A20 has 28 hand-authored cases but no systematic schedule generation, state-machine model, property-based strategy, deterministic simulation, combinatorial coverage, mutation testing or counterexample minimization.

**Risk:** Curated cases miss rare interleavings and fault interactions.

**Required correction:**
- Model source identity, receipt/work item, authority epoch, worker lease, outbox delivery and reconciliation as an explicit state machine.
- Check safety and selected liveness properties with a bounded model checker such as TLA+/TLC before implementation-specific chaos tests; document bounds and abstraction limits.
- Use deterministic seeds and history checkers (Jepsen-style) for concurrent operations and fault schedules.
- Add property-based generation/shrinking; choose pairwise and risk-weighted combinations instead of unbounded Cartesian products.
- Mutation-test the checker/oracle against known violations.

**Acceptance:** Strategy demonstrates model-to-case traceability, repeatable seeds, coverage rationale and known checker sensitivity. Model checking does not replace implementation testing.

### A21-F13 — Bilingual semantic parity and terminology are not proven
**Severity:** P2 | **Status:** OPEN

**Evidence:** A20 EN/FA case identifiers match, but identifier parity does not prove equivalent preconditions, expected outcomes, severity, prohibitions or status language. Technical terms are mixed without a controlled glossary.

**Risk:** Operators using different language versions infer different permissions or PASS conditions.

**Required correction:**
- Maintain a controlled glossary for authority, acceptance, durable, unknown commit, tombstone, fencing, independent, PASS/FAIL/INCONCLUSIVE and authorization.
- Build section/case parity checklist covering every table row, prohibition, status and acceptance criterion.
- Require competent bilingual technical review; record reviewer and date.
- Treat material divergence as a blocker; English is not authoritative unless owner explicitly decides so.

**Acceptance:** Semantic parity review is signed for both versions; key terms are consistent; authorization/PASS meanings do not differ.

## 4. Initial traceability gap register

This is an initial gap register, not proof of coverage:

| Area | A20 state | Required A22/A23 work |
|---|---|---|
| C-01..C-16 → G1..G9 | Separate registers | Per-constraint gate mapping and evidence acceptance matrix |
| OD-01..OD-12 → I-01..I-10 | Partial conceptual overlap | Identity, canonicalization, retention, UNKNOWN, authority and cardinality remain unresolved |
| I-01..I-10 → A20-01..28 | Some obvious links | Complete positive/negative case mapping per invariant |
| Scenario → oracle → artifact | General oracle families | Per-case oracle query, trust boundary, schema and evidence path |
| A20-27 → financial gate | Ambiguous | Synthetic fixture versus real financial boundary |
| A20-14/21 → lifecycle | Partial | Retention/replay/restore bound and authoritative high-water mark |
| A20-16/17 → DR | Broad | Approved topology, recovery boundary, reconciliation oracle and objective |
| EN ↔ FA | Identifier parity only | Semantic equivalence sign-off |

## 5. Required corrective sequence

Do not rewrite A20 in one unreviewable patch. Use controlled amendments:

1. **A22 — A20 Specification Remediation:** resolve F02–F10 into precise owner-dependent contracts, traceability and result schema. Do not close owner/OD decisions without approval.
2. **A23 — Formal Model & Test Strategy:** address F03/F04/F05/F11/F12 with state machine, invariants, safety/liveness, model bounds and generated schedules. Research/model design only unless separately authorized.
3. **A24 — Evidence & Bilingual Assurance Package:** address F01/F06/F08/F13 with oracle trust-boundary matrix, evidence schema and bilingual semantic review. A12 still requires an independent human assessor.
4. Re-review all amended artifacts against A21; only then decide whether R1 research exit criteria are met. R1 does not authorize R2 or R3.

F01 and all P1 blockers must be dispositioned before A20 can be called a qualification specification. Accepted risk requires an authorized owner and rationale; author/reviewer cannot self-accept it.

## 6. Research basis

- NIST SP 800-53A Rev. 5: https://csrc.nist.gov/pubs/sp/800/53/a/r5/final
- NIST SP 800-53A assessor-independence discussion (historical Rev. 4 source; methodological context only): https://www.govinfo.gov/content/pkg/GOVPUB-C13-440ea190bd4667fad986ae0fbb1844a5/pdf/GOVPUB-C13-440ea190bd4667fad986ae0fbb1844a5.pdf
- NIST assessment methods: https://csrc.nist.gov/glossary/term/assessment_method
- Jepsen framework: https://github.com/jepsen-io/jepsen
- FoundationDB deterministic simulation/testing: https://github.com/apple/foundationdb/blob/main/documentation/sphinx/source/testing.rst
- Lamport TLA+ tools/model checking: https://lamport.org/tla/tools.html
- Lamport safety and liveness: https://lamport.azurewebsites.net/tla/safety-liveness.pdf
- Google SRE launch checklist: https://sre.google/sre-book/launch-checklist/
- Google SRE production launch planning: https://sre.google/resources/practices-and-processes/production-launch-planning/
- AWS Builders' Library timeouts/retries/backoff with jitter: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- RFC 9110 §9.2.2 idempotency/retry semantics: https://www.rfc-editor.org/rfc/rfc9110.html
- Google Cloud Spanner unknown commit/idempotency: https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- PostgreSQL pg_verifybackup limitations: https://www.postgresql.org/docs/current/app-pgverifybackup.html

Sources inform review methods and failure classes. They do not certify Lottorito, select a candidate, settle owner decisions or prove an untested deployment.

## 7. Final disposition

- A21: INTERNAL ADVERSARIAL SELF-REVIEW COMPLETE; NOT INDEPENDENT ASSURANCE.
- Findings: 13 total — P0: 1 OPEN; P1: 9 OPEN; P2: 3 OPEN.
- A20: RESEARCH/TEST-DESIGN BASELINE; NOT AN EXECUTABLE QUALIFICATION SPECIFICATION.
- A20-01..A20-28: DESIGNED / NOT RUN.
- C-01..C-16: OPEN; no owner evidence accepted.
- G1..G9: NOT TESTED / NOT PASSED.
- ADR-002: PROPOSED; OD-01..OD-12 OPEN.
- A11-F01..F08 OPEN; A12 independent review NOT PERFORMED / NOT ASSESSABLE.
- R0 BLOCKED; R1 research-only; R2 NOT STARTED; R3 NOT AUTHORIZED; A4 NOT APPROVED.
- No runtime/harness, provider selection, partner integration, financial operation, merge or deployment authorized.

**Conclusion:** A20 is directionally strong but must not be promoted as independently assured or as an executable qualification specification. A22–A24 are the controlled remediation path.
