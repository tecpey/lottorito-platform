# G09-A18 — Persistence & Authority Candidate Architecture Evaluation

**Document ID:** LOT-AFFILIATE-G09-A18-001  
**Version:** 0.1.0 | **Date:** 2026-11-28  
**Status:** RESEARCH / CONDITIONAL RECOMMENDATION ONLY — no owner decision, candidate selection, runtime authorization or independent approval  
**Baseline:** PR #76, head `d51304467a97d25a69bfcb18e2b0dc7d69ef176b`  
**Related:** ADR-002 v0.3.0; G09-A11..A17; LOT-EVENT-001; LOT-API-001; LOT-QA-001  
**Authority:** Advisory architecture research. No candidate is approved or selected.

## 1. Executive disposition

The persistence question is not “which database is best?” It is whether one concrete deployment can prove the ADR-002 acceptance protocol under the failure model already documented: concurrent duplicate requests, commit-response loss, process crash, primary failure, stale-primary reappearance, replica lag, restore, and operator repair.

**No candidate passes by product documentation alone.** Product guarantees are inputs to a proof plan; acceptance requires a version-pinned, configuration-pinned, failure-injected test against the actual enforcement points and independent oracles.

### Conditional recommendation

1. Keep ADR-002 technology-neutral.
2. Build the R1 shortlist around:
   - **Candidate family P:** PostgreSQL single-writer with deliberately engineered HA, synchronous durability where the approved RPO requires it, and independently enforced fencing.
   - **Candidate family D:** one distributed-SQL implementation (CockroachDB or YugabyteDB, evaluated separately rather than treated as interchangeable).
   - **Candidate family M:** managed distributed SQL such as Google Cloud Spanner only if jurisdiction, data residency, region availability, cloud dependency, cost and latency are acceptable.
3. Treat a managed PostgreSQL service as a distinct sub-candidate, not as proof that generic PostgreSQL failover concerns disappear. Its actual failover, synchronous-commit, backup and fencing semantics must be documented for the exact service/region/tier.
4. Do not add a separate queue, cache, lock service or “exactly-once” middleware as a second source of truth. The database transaction remains the acceptance authority; asynchronous delivery must be derived from committed state (transactional outbox or equivalent).
5. Do not choose a winner or numeric score until owner risk decisions OD-04/OD-08/OD-12 and deployment constraints are known.

**Current disposition:** candidate families identified for evidence collection; no R1 candidate qualification has been executed. R2 harness design and R3 runtime proof remain not started / not authorized.

## 2. Frozen invariants and scope

Every candidate must preserve all of the following without relying on best-effort application behavior:

- One approved source-event identity maps to at most one accepted InboxReceipt + WorkItem pair.
- The pair is atomic: both durable or neither durable.
- A success acknowledgement is emitted only after the defined durability/commit condition is met.
- A lost response is UNKNOWN until authoritative reconciliation establishes the outcome.
- Same identity with a different immutable binding is a conflict, not a replay.
- A stale writer, stale worker, stale repair process or old primary cannot mutate protected state after authority has moved.
- Restore cannot resurrect a consumed identity or roll back the authority epoch in a way that permits duplicate acceptance.
- Queue delivery, caches, logs, replicas with weaker consistency and client-side state are not authoritative evidence of absence.
- Ingress acceptance cannot directly mutate wallet, ledger, settlement, payment or payout state.

This evaluation covers the persistence and authority layer only. It does not choose partner transport, queue product, deployment provider, schema, parser, commission formula or financial runtime.

## 3. Candidate families

### P — PostgreSQL single-writer with engineered HA

**Shape:** one writable primary; one or more standbys; explicit replication mode; a separately specified promotion controller; an enforceable fencing mechanism; tested backup/PITR and restore procedures.

**Strengths**
- Mature relational transactions, constraints, unique indexes, foreign keys, locking and operational ecosystem.
- The InboxReceipt + WorkItem pair can be committed in one database transaction.
- A single-writer topology is conceptually straightforward for a narrow acceptance authority.
- Broad hosting and operational options can reduce platform lock-in.

**Risks and proof obligations**
- PostgreSQL does not itself supply the complete HA/failure-detection/promotion system. Official documentation warns that an old primary must be prevented from returning as writable after standby promotion; otherwise both nodes can believe they are primary.
- Asynchronous replication can lose acknowledged-primary transactions during failover. Synchronous replication changes latency and availability behavior; the precise `synchronous_commit`, standby quorum and failover policy must be tested, not inferred from the word “synchronous”.
- A witness or heartbeat is not sufficient fencing unless the protected write resource rejects stale authority.
- The application must treat connection loss during commit as UNKNOWN and reconcile by the stable identity, not by blindly replaying.
- A successful database restore can still be unsafe if external authority epochs, idempotency tombstones, credential revocation or outbox publication state are restored inconsistently.

**Candidate is disqualified if**
- promotion can occur without a demonstrated old-primary write fence;
- the chosen RPO allows acknowledged receipt loss while the API returns success;
- the actual commit acknowledgement condition is undocumented or untested;
- restore can re-enable a consumed identity or stale writer;
- operators cannot independently determine which node was authoritative at each point.

**Assessment:** a strong baseline candidate when a single-region/single-writer model is sufficient and the team can operate and test the full HA envelope. It is not “safe by default”; fencing and durability are first-class product requirements.

### P-M — Managed PostgreSQL HA (separate sub-candidate)

**Shape:** provider-managed primary/standby, endpoint failover and backup/PITR, with service-specific replication and promotion behavior.

**Strengths**
- May reduce the amount of database-cluster automation operated directly by the project.
- Can provide documented regional HA, backups and operational telemetry.
- Preserves PostgreSQL transactional model and ecosystem.

**Risks and proof obligations**
- “Managed HA” does not identify whether commits acknowledged to the application survive every failover class.
- The project may not control host-level STONITH; therefore it must establish what the provider guarantees about fencing, endpoint routing, stale sessions and old-primary isolation.
- Service tier, region, maintenance behavior, failover triggers, replica promotion, restore semantics and PITR limits are product-specific.
- Provider-specific backup/restore may not preserve external identity/epoch state held elsewhere.
- Data residency, sanctions/export constraints, payment/financial data rules and contractual terms require owner/legal review; no provider suitability is assumed here.

**Assessment:** evaluate only against exact provider, region, service tier and configuration. Do not inherit generic PostgreSQL assumptions or assume provider marketing language proves the acceptance protocol.

### D — Distributed SQL (CockroachDB and YugabyteDB as separate candidates)

**Shape:** SQL-facing distributed database with replicated data, consensus/quorum behavior and distributed transaction coordination. Evaluate each product and version independently.

**Strengths**
- Replication and node/zone failure handling are built into the database architecture rather than assembled solely from an external primary/standby controller.
- Distributed transaction and serializable-isolation options can make cross-node consistency obligations more explicit.
- Potentially attractive when multi-zone or multi-region availability is a real requirement rather than a speculative future goal.

**Risks and proof obligations**
- Distributed SQL does not remove transaction retries. Serialization/transaction-retry errors must be handled by a correct retry loop that re-executes the entire transaction body safely; external effects must not occur inside a retried transaction.
- CockroachDB and YugabyteDB differ in transaction implementation, isolation details, retry surfaces, DDL behavior, operational tooling and topology. They are not one interchangeable category for qualification.
- Cross-region quorum placement can increase write latency and make availability dependent on quorum reachability.
- Schema design, key distribution, hotspots, transaction span and contention can materially affect latency and operational stability.
- A database's internal consensus does not automatically fence an independent queue, cache, object store, payment API or worker side effect.
- Compatibility with PostgreSQL drivers/SQL syntax is not proof of identical semantics, extensions, migration behavior or failure handling.
- Need version-specific review of constraints, unique-key behavior, transactional DDL, backup/restore, changefeeds, client retry semantics, and support lifecycle.

**Assessment:** qualify one implementation only if actual multi-zone/multi-region requirements justify the added distributed-system complexity and the team can operate its failure modes. Do not choose distributed SQL merely because “more replicas” sounds safer.

### M — Google Cloud Spanner (conditional managed distributed SQL candidate)

**Shape:** managed distributed relational database with serializable transactions/external consistency by default, replicated configurations and provider-operated consensus/replica management.

**Strengths**
- Official documentation describes serializable transactions and external consistency; transaction effects are ordered consistently with real-time commit observations.
- Regional and multi-region topologies have explicit quorum and replica layouts.
- Reduces the project's direct responsibility for database node failover and consensus operations.

**Risks and proof obligations**
- A strong transaction guarantee does not remove application-level UNKNOWN commit outcomes; the client still needs identity-based reconciliation.
- Region choice determines data placement, latency, availability, cost and residency. Multi-region configurations have different quorum and write-latency trade-offs from regional configurations.
- Cloud-provider dependency, service availability in legally acceptable regions, billing model, capacity planning, exportability and exit strategy must be assessed.
- The team must test client-library retry behavior and ensure transaction callbacks are free of non-transactional side effects.
- A Spanner guarantee applies to Spanner-managed data, not automatically to external systems or asynchronous consumers.

**Assessment:** technically compelling where the Google Cloud footprint, region/residency rules, cost model and operational model are acceptable. It is not a default recommendation for this project absent those facts.

### X — Split authority / asynchronous processing architecture

This is an architecture pattern, not a database candidate.

**Required shape**
- The selected transactional database is the only authority for acceptance identity, Receipt/WorkItem pair and state transitions.
- An outbox row or equivalent is committed in the same transaction when downstream publication is required.
- Queue messages are wake-up/delivery hints; consumers re-read and claim authoritative work from the database.
- A cache is never the source of truth for acceptance, dedupe, authority or repair.
- A lock service or lease may coordinate, but it is not fencing unless every protected resource validates a monotonically advancing authority token and rejects stale tokens.
- Any future economic effect has a separate domain-level identity and authorization boundary.

**Assessment:** this pattern is compatible with P, P-M, D and M. It is the recommended logical separation regardless of database selection. It must not be misrepresented as “exactly once”.

## 4. Comparative decision matrix

| Dimension | P: PostgreSQL HA | P-M: Managed PG | D: Distributed SQL | M: Spanner |
|---|---|---|---|---|
| Atomic Receipt + WorkItem | Native single-DB transaction | Native, service-specific | Distributed ACID transaction | Read-write transaction |
| Primary/authority model | Explicit single-writer promotion | Provider-managed; verify guarantees | Replicated consensus/leader model | Provider-managed quorum/leader model |
| Stale-primary protection | Must engineer and prove | Must obtain service-specific proof | Internal DB authority; external side effects still need fencing | Internal DB authority; external side effects still need fencing |
| Commit ambiguity | Application reconciliation required | Required | Required; retry errors also matter | UNKNOWN reconciliation required |
| Cross-region write latency | Depends on synchronous standby placement | Depends on service topology | Quorum/topology dependent | Quorum/leader-region dependent |
| Operational burden | Highest if self-managed | Lower DB operations, provider dependency | Specialized distributed DB operations | Lower DB operations, stronger provider dependency |
| Portability | Generally strongest | Medium; provider features create coupling | Product-specific SQL/ops coupling | Highest cloud-specific coupling |
| Evidence needed | HA controller + storage + fencing + restore | Exact service/tier/region behavior | Exact product/version/topology/retry | Exact config/client/region/restore |
| Current qualification | NOT TESTED | NOT TESTED | NOT TESTED | NOT TESTED |

The matrix is qualitative. No weighted score is defensible before the owner approves risk priorities, jurisdiction and operating constraints.

## 5. Hard gates before any candidate can be shortlisted

A candidate is **not qualified** unless all gates below have an evidence owner, exact test procedure, independent oracle and pass/fail rule.

### G1 — Atomic pair and uniqueness
- Concurrent same-identity requests produce exactly one Receipt and one WorkItem.
- Same identity with conflicting immutable binding produces deterministic conflict.
- No orphan Receipt or orphan WorkItem is observable after commit, abort or crash.
- Constraints and transaction logic are proven under real concurrency, not only sequential unit tests.

### G2 — Commit acknowledgement and UNKNOWN
- API success follows the explicitly approved durability acknowledgement.
- Fault injection before commit, during commit, after commit and before response distinguishes KNOWN_ABORTED, KNOWN_COMMITTED and UNKNOWN correctly.
- A retry with the same identity reconciles to the original pair without duplicate creation.
- A stale/weakly consistent read cannot be used as proof of absence.

### G3 — Failover and fencing
- Kill, isolate and restart the old primary during and after promotion.
- Attempt writes using old connections, credentials, DNS endpoints and worker processes.
- Prove rejection at the actual protected storage boundary, not merely at the load balancer or application router.
- If authority is represented by an epoch/term, prove that the epoch cannot be rolled back or bypassed by restore.

### G4 — Backup, restore and disaster recovery
- Restore from snapshots taken before and after acceptance, dedupe tombstones, revocation and authority changes.
- Prove no consumed identity can be accepted again after restore.
- Reconcile database state with outbox, worker state, credentials, audit records and external authority.
- Demonstrate that RPO/RTO values are measured outcomes for the selected topology, not marketing targets.

### G5 — Tenant isolation and privilege boundaries
- Cross-tenant lookups, uniqueness conflicts, repair, replay and metadata queries do not leak record existence.
- Application, worker, repair and operator roles have separate least-privilege capabilities.
- Administrative bypasses are audited and cannot bypass immutable identity constraints.

### G6 — Operational recoverability
- Runbooks cover promotion, failback, rejoin, backup verification, restore, degraded quorum, credential revocation and manual repair.
- Observability exposes authoritative node/term, replication state, transaction outcome, retry and reconciliation metrics.
- A second operator can reconstruct what happened from retained evidence without relying on the original process memory.

### G7 — Independent evidence and repeatability
- Pin product version, configuration, topology, client library and infrastructure.
- Store deterministic fault schedules, raw observations, source SHA, test artifact hashes and oracle outputs.
- Repeat critical scenarios enough to cover race windows; use property-based/concurrency histories where appropriate.
- Reviewer must be independent of the author and have relevant database/distributed-systems competence.

Any failed or unobservable hard gate means **NO-GO**, not “conditional pass”.

## 6. Candidate qualification plan (R1 only)

R1 is a research and evidence-collection phase, not a runtime test authorization.

1. Record deployment constraints first: acceptable cloud/provider, permitted regions, data residency, jurisdiction, network placement, expected load envelope, availability target, budget envelope, operational staffing and exit requirements.
2. Obtain the provider's exact architecture and failure semantics for the service/tier/region being considered.
3. Produce a versioned candidate profile: database version, client driver, topology, replication mode, quorum, failover controller, fencing, backup/PITR, restore and operational roles.
4. Map every A15 schedule S01–S12 and G1–G7 to a candidate-specific mechanism and an independently observable result.
5. Identify untestable or provider-opaque guarantees. Treat them as unresolved risk, not presumed PASS.
6. Only after desk research, compare one PostgreSQL HA candidate with one distributed-SQL candidate. Add Spanner only if cloud and jurisdiction constraints make it viable.
7. Produce an evidence-based shortlist and residual-risk register. No numeric scoring until the owner approves weights.

**R1 exit:** candidate profiles and evidence gaps reviewed; no candidate selected by this document.  
**R2:** design a disposable synthetic harness only after R1 and A4 approvals.  
**R3:** execute runtime fault tests only under separate explicit authorization.

## 7. Preliminary recommendation and decision dependencies

**Preliminary recommendation for the next research iteration:** use engineered PostgreSQL HA as the baseline control case, and compare it against exactly one distributed-SQL candidate selected after deployment constraints are known. Keep Spanner as a conditional reference candidate, not an assumed finalist.

Why this is the most disciplined next step:
- It compares a simpler single-writer model against a distributed consensus model without prematurely multiplying candidates.
- It forces the project to account for the actual cost of fencing, synchronous durability and restore in the PostgreSQL case.
- It tests whether distributed SQL provides a material requirement-driven advantage rather than a theoretical one.
- It avoids a false comparison between self-managed PostgreSQL and a fully managed global service before jurisdiction, cost and data-location requirements exist.

This recommendation is **not a technology decision**. OD-04 (loss tolerance), OD-05 (authority/fencing), OD-08 (retention and restore lifecycle), OD-12 (evidence retention), and deployment/jurisdiction constraints remain dependencies.

## 8. Explicit non-decisions and stop conditions

This dossier does not:
- select PostgreSQL, CockroachDB, YugabyteDB, Spanner, a managed service, cloud, queue or topology;
- approve RPO/RTO, retention, replica count, timeout, retry count, availability target or budget;
- assert that any vendor's service is available or legally suitable for the owner's deployment;
- close A11 findings or perform A12 independent review;
- authorize schema changes, runtime code, harness execution, partner integration, financial processing, merge or deployment.

**Stop:** if the approved failure model, jurisdiction, data residency, recovery objective or authority model is unknown, do not select a candidate. If a candidate cannot expose enough evidence to prove a hard gate, disqualify it for this use case regardless of its advertised SLA.

## 9. Research references

- PostgreSQL, High Availability, Load Balancing, and Replication: https://www.postgresql.org/docs/current/high-availability.html
- PostgreSQL, Failover and the old-primary/STONITH warning: https://www.postgresql.org/docs/current/warm-standby-failover.html
- PostgreSQL, synchronous replication and performance/availability trade-offs: https://www.postgresql.org/docs/current/warm-standby.html
- CockroachDB, Developer Basics (serializable transactions and retry errors): https://www.cockroachlabs.com/docs/stable/developer-basics.html
- YugabyteDB, Transactions and ACID/transaction support: https://docs.yugabyte.com/stable/explore/transactions/
- YugabyteDB, Transaction isolation levels: https://docs.yugabyte.com/stable/architecture/transactions/isolation-levels/
- Google Cloud Spanner, Transactions overview: https://docs.cloud.google.com/spanner/docs/transactions
- Google Cloud Spanner, TrueTime and external consistency: https://docs.cloud.google.com/spanner/docs/true-time-external-consistency
- Google Cloud Spanner, Regional, dual-region and multi-region configurations: https://docs.cloud.google.com/spanner/docs/instance-configurations
- Jepsen, published distributed-systems analyses: https://jepsen.io/analyses
- AWS, Transactional Outbox Pattern: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html

**Final disposition:** G09-A18 is a comparative research dossier with a conditional next-step recommendation. All candidate families remain UNSELECTED / NOT QUALIFIED. ADR-002 remains PROPOSED; OD-01..OD-12 remain OPEN; A11 findings remain OPEN; A12 independent review remains NOT PERFORMED; R0 remains BLOCKED; R1 is research-only; R2 NOT STARTED; R3 NOT AUTHORIZED; A4 gates remain NOT APPROVED.
