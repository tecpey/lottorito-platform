# G09-A12 — ADR-002 Independent Review Package

**Document ID:** LOT-AFFILIATE-G09-A12-001  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** REVIEW PACKAGE PREPARED — independent review NOT PERFORMED  
**Related:** LOT-AFFILIATE-G09-ADR-002 v0.3.0; LOT-AFFILIATE-G09-A11-001; LOT-AFFILIATE-G09-A7-001; LOT-AFFILIATE-G09-A4-001; LOT-AFFILIATE-G09-A8-001  
**Authority:** Review preparation only. No owner decision, runtime authorization, technology selection, merge or deployment.

## 1. Purpose and review boundary

This package makes the current ADR-002 design reviewable by a reviewer who did not author the ADR, A11 self-review or this package. It is not itself an independent review and does not close any finding.

The review is limited to the logical contract for synthetic Affiliate ingress acceptance and unknown-commit reconciliation. It must not infer approval of a database, queue, authority service, topology, partner, financial workflow or production operation.

The reviewer must inspect the complete source artifacts at one frozen commit SHA and independently reconstruct the protocol. Do not rely on verbal assurances, this package's summaries or prior same-author conclusions.

## 2. Required reviewer independence and competence

The reviewer must:
- not be the author of ADR-002, A11, A7 or this package, and not have materially co-authored the design under review;
- disclose employment, financial, reporting and delivery conflicts relevant to the design;
- demonstrate hands-on expertise in transactional persistence/concurrency and distributed-systems failure analysis;
- have sufficient security/reliability expertise to challenge tenant isolation, fencing, recovery, replay and evidence integrity; use a second specialist where competence is not comprehensive;
- have read-only access to the exact source commit and the referenced artifacts.

If independence or competence cannot be established, record **NOT ASSESSABLE**; do not relabel a peer walkthrough as independent review.

## 3. Frozen review input set

At review start, record the exact repository, PR, base SHA, head SHA, timestamp, reviewer identity/role, conflicts declaration and the SHA-256 (or repository blob SHA) of each reviewed artifact.

Minimum artifacts:
1. ADR-002 v0.3.0 (English and Persian).
2. G09-A11 adversarial review (English and Persian), including its reconciliation crosswalk.
3. G09-A7 47-case traceability (English and Persian), including all extension subcases.
4. G09-A4 runtime proof architecture and eight approval gates.
5. G09-A8 adversarial review and G09-ADR-001 where relevant to worker/recovery interactions.
6. LOT-EVENT-001, wire contract and the security acceptance boundary for identity, schema and response semantics.
7. Both decision registers and project-status records.

A changed source SHA invalidates the review's exact-head scope. The reviewer must identify whether the change is editorial, semantic or safety-relevant and re-review affected areas.

## 4. Review method — adversarial reconstruction

The reviewer should independently draw the state machine and happens-before/linearization points for:
- initial acceptance, receipt/work-item creation and acknowledgement;
- duplicate and conflicting source-event identity;
- concurrent same-identity ingress;
- lost commit response and unknown outcome;
- authoritative reconciliation racing an in-flight transaction;
- primary failure, promotion, old-primary rejoin and restore;
- quarantine racing worker claim;
- replay after retention expiry, backup restore and tenant offboarding.

For each path, identify the authority that can make the decision, the exact persistence serialization point, the enforcement boundary, the independently observable evidence and the fail-closed outcome. A prose assertion without an enforceable mechanism and falsifiable oracle is insufficient.

Challenge counterexamples, not just happy paths. At minimum attempt to construct a schedule that produces (a) two accepted pairs, (b) an acknowledged pair lost after promotion, (c) writes from two primaries, (d) a false partial-pair diagnosis, (e) a stale worker claim after quarantine, (f) a replay accepted after its dedupe evidence was deleted, and (g) cross-tenant existence disclosure.

## 5. Finding-by-finding review matrix

| Finding | ADR-002 response to inspect | Required independent challenge and closure evidence | Current status |
|---|---|---|---|
| A11-F01 — acknowledged-commit durability/RPO | §§16.4, 17.2 | Define supported failure classes; local flush and replication/consensus acknowledgement point; promotion eligibility and recovery-point selection; forced failover/restore evidence; prove no success/worker execution beyond the declared durability boundary. | OPEN |
| A11-F02 — authority epoch / split brain | §§17.1, 17.7 | Identify the authority root and explain why it cannot fork or roll back across partition, promotion and restore. Prove every write path rejects stale epochs at an enforcement point the old writer cannot bypass; prove old-primary rejoin is fenced. | OPEN |
| A11-F03 — negative read vs in-flight commit | §§16.3, 6, 7 | Construct deterministic original-commit/retry schedules, including promotion. Prove same-key arbitration, transaction termination/serialization, consistent reconciliation snapshot and exactly one winner. A negative snapshot alone is not proof of abort. | OPEN |
| A11-F04 — pair cardinality/linkage | §§4, 16.5, 17.7 | Prove receipt uniqueness, at-most-one WorkItem per receipt, mandatory receipt reference, exact tenant/installation match and commit-time/capability enforcement against omitted writes. Test partial/corrupt/restore states. | OPEN |
| A11-F05 — fingerprint versioning | §§3, 16.6 | Challenge parser ambiguity, duplicate JSON members, numeric/Unicode equivalence, schema/extension changes, canonicalization version migration and cross-language vectors. Prove mismatches never silently reuse an acceptance. | OPEN |
| A11-F06 — retention-bounded idempotency | §§3, 12, 17.3 | Establish replay horizon from an actual source contract and legal/privacy policy; account for tombstones, backups, restore, offboarding and late replay. State exactly when the dedupe guarantee ends. | OPEN |
| A11-F07 — quarantine blast radius/DoS | §§4, 16.7, 17.4 | Prove untrusted input cannot trigger tenant-wide quarantine; test graduated scope, authorization, audit, expiry/recovery, unaffected-tenant fairness and quarantine-vs-claim linearization. | OPEN |
| A11-F08 — accepted vs executed semantics | §§1, 5, 8, 17.5 | Verify wire response and status resources distinguish durable acceptance from claim, processing, qualification and financial posting; duplicates return a stable reference; no second WorkItem or internal security disclosure. | OPEN |

The reviewer must be free to add findings. Do not force a finding into PASS merely because the current ADR contains a corresponding paragraph.

## 6. A7 traceability coverage to verify

The A7 manifest must retain exactly 47 canonical A4 IDs, with no renumbering, deletion or substitution. Extension subcases are supplemental and must be reported separately from their parents.

Expected extension inventory:
- 8 A8 subcases;
- 9 A11 subcases;
- 4 A10 supplemental subcases;
- 21 unique extension IDs in total, with exact English/Persian set and parent parity.

Specific ADR-002 supplemental challenge mapping:
- C18 → A11-DUR-02b;
- C19 → A11-DUR-08b;
- C20 → A10-DUR-02d;
- C21 → A10-DUR-02e;
- C22 → A10-AUTH-06b;
- C23 → A10-IDEM-08a.

Verify each mapping against the current A7 files, not this list alone. Every case needs a versioned synthetic fixture, deterministic stimulus/schedule, protocol and authorization assertion, direct persistence assertion, financial non-effect assertion, independent oracle, evidence provenance and explicit NOT RUN/BLOCKED state until an authorized execution exists. Parent PASS must never conceal a failing or unrun subcase.

## 7. Independent oracle and evidence challenge

For any future candidate-specific proof, require independent evidence for:
1. client/API observation (not a commit oracle);
2. authoritative read-only persistence inspection, with consistency mode and authority identity;
3. transaction/constraint trace establishing atomicity and same-key arbitration;
4. direct cardinality/linkage query in one consistent snapshot;
5. fault-injection controller record showing the intended failure point was reached;
6. authority epoch/fencing evidence from the enforcement boundary;
7. financial non-reachability evidence across credentials, service bindings, network/DNS, queues and indirect paths;
8. immutable evidence manifest with source SHA, build/config identity, trusted time, correlation IDs and integrity hash.

System-under-test logs alone are not independent oracles. A dashboard, HTTP 202, green documentation CI, or a replica read without documented consistency does not prove durable state.

## 8. Decision questions that must remain explicit

The reviewer must not silently answer these owner-controlled questions:
- What source namespace and event-identity scope are authoritative?
- What request Idempotency-Key scope, fingerprint binding and retention apply?
- What replay horizon and tombstone/legal-hold/deletion policy apply?
- What failure model, acknowledged-write RPO/RTO and recovery classes are promised?
- What authority root provides non-forking epoch allocation and externally enforceable fencing?
- What consistency/isolation/serialization contract is required?
- What exact pair invariant is enforced at commit/capability boundary?
- What fingerprint/parser profile and compatibility/migration policy are approved?
- Who may quarantine, at what scope, with what review/expiry/recovery process?
- What reconciliation retry/resource bounds and operational SLOs apply?
- Is DeliveryOutbox needed, and who owns its atomicity and lifecycle?
- What evidence retention, privacy, deletion, backup and legal-hold rules apply?

Unknown answers remain OPEN/BLOCKED; do not fill them with plausible numbers or vendor defaults.

## 9. Review disposition record

The independent reviewer must produce a separate signed disposition containing:
- frozen repository/PR/head SHA and artifact hashes;
- reviewer qualifications, independence/conflict declaration and review date;
- methods, tools and failure schedules considered;
- finding-by-finding result: **ACCEPTED**, **ACCEPTED WITH CONDITIONS**, **REJECTED**, or **NOT ASSESSABLE**;
- exact counterexample, evidence reference and remediation for each non-accepted item;
- new findings and affected A4/A7 IDs;
- explicit statement whether ADR-002 is fit for owner decision, still requires redesign, or is not assessable.

No finding is closed by the author updating this package. Closure requires the independent reviewer’s evidence-backed disposition and any required accountable owner decision. A second reviewer is required where a material specialist domain is outside the primary reviewer's competence.

## 10. Stop conditions and non-authorization

Stop the review and report **REJECTED** or **NOT ASSESSABLE** if the design permits split-brain writes, acknowledged-commit loss outside its declared RPO, duplicate pair creation, cross-tenant disclosure, stale-worker mutation after fencing, unbounded replay without an explicit guarantee, broad quarantine by untrusted input, or any financial capability reachable from ingress.

This package does not approve ADR-002, close A11-F01..F08, close A7/A8 findings, approve any A4 gate, select technology, authorize runtime/harness execution, partner integration, financial processing, merge or deployment.

## 11. Reference set

- PostgreSQL transaction isolation: https://www.postgresql.org/docs/current/transaction-iso.html
- PostgreSQL high availability and failover: https://www.postgresql.org/docs/current/high-availability.html
- PostgreSQL synchronous replication: https://www.postgresql.org/docs/current/warm-standby.html
- PostgreSQL failover and old-primary fencing cautions: https://www.postgresql.org/docs/current/warm-standby-failover.html
- PostgreSQL asynchronous commit durability window: https://www.postgresql.org/docs/current/wal-async-commit.html
- PostgreSQL constraints: https://www.postgresql.org/docs/current/ddl-constraints.html
- Google Cloud Spanner unknown commit status: https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once
- AWS transactional outbox: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- RFC 8785 JSON Canonicalization Scheme: https://www.rfc-editor.org/rfc/rfc8785
- NIST SP 800-204D: https://csrc.nist.gov/pubs/sp/800/204/d/final

These references are evaluation inputs, not a technology selection or evidence that Lottorito has implemented the described guarantees.
