# Technology, Deployment and Reliability ADRs

**Document ID:** LOT-TECH-ADR-001 | **Version:** 0.2.0 | **Status:** Proposed decision framework; no stack or provider approved | **Review date:** 2026-11-24

## 1. Purpose and authority

This document turns technology selection into explicit, evidence-backed decisions. It records candidate defaults, alternatives, decision criteria, required experiments and approval gates. It is not a procurement decision, cloud commitment, architecture approval or statement that any technology is implemented.

All ADRs below are **Proposed**. An ADR becomes **Accepted** only after the owner and relevant security, finance, legal or operations authority approve the exact scope. A successful prototype is evidence, not approval.

## 2. Non-negotiable constraints

1. Global product direction; market activation and data location remain jurisdiction-gated.
2. Affiliate & Agent and Lottery must be independently deployable/adoptable product domains.
3. Authenticated tenant context must be propagated and enforced at every data and job boundary.
4. Financial records must be append-only, double-entry, idempotent and reconcilable; mutable balances are never the source of truth.
5. Provider-specific behavior stays behind versioned adapters and contracts.
6. API-first integration must not force the internal domain model to mirror a single partner.
7. Persian and English documentation remain semantically aligned.
8. No premature microservices, Kubernetes cluster, distributed database, event-streaming platform or workflow engine without measured need.
9. Operability, recoverability, security, portability and total cost are first-class selection criteria.
10. Secrets, credentials and personal/customer data must not enter source control, logs or agent prompts.

## 3. ADR-001 — Application architecture

**Status:** Proposed. **Question:** What topology should host the first production-capable product slices?

| Option | Strengths | Costs / risks | Current assessment |
|---|---|---|---|
| Modular monolith | Simple transactions, local debugging, low operational overhead, explicit domain boundaries | Requires discipline to prevent coupling; independent scaling is limited | Preferred starting hypothesis |
| Microservices from day one | Independent deployment/scaling and technology autonomy | Distributed transactions, network failure modes, observability and operations overhead | Not justified by verified scale or team evidence |
| Serverless/function-first | Low infrastructure management and burst scaling | Runtime limits, vendor coupling, local transaction/workflow complexity and cost unpredictability for sustained workloads | Workload-specific option, not default architecture |

**Proposed direction:** Start with a modular monolith and separately deployable worker process(es), sharing a clearly versioned application core. Enforce bounded contexts through module APIs, ownership rules and dependency tests. Affiliate and Lottery must be separable by product entitlement/configuration and deployment packaging; avoid cross-product data dependencies that prevent independent operation.

Extract a module only when a written ADR demonstrates measurable drivers: independent scaling, fault containment, release cadence, regulatory/data boundary, team ownership or technology requirement. Extraction requires explicit API/event contracts, data ownership and migration/rollback plan.

**Acceptance evidence:** no forbidden dependency cycles; explicit domain owners and module contracts; atomic financial posting within the authoritative database boundary; independent Affiliate-only and Lottery-only build/test configurations; demonstrated failure isolation and rollback.

## 4. ADR-002 — System of record and database

**Status:** Proposed. **Question:** What persistence foundation best protects financial integrity and tenant isolation?

| Option | Strengths | Risks / trade-offs |
|---|---|---|
| PostgreSQL as primary transactional store | Mature transactions, constraints, indexes, JSON support, row-level security, backup ecosystem | Requires careful schema, connection, migration, vacuum and failover operations |
| Distributed SQL | Multi-region consistency and horizontal scale options | Higher operational/financial complexity; no demonstrated need |
| Multiple databases per service from inception | Strong technical isolation | Duplicated operations and cross-domain consistency/reporting complexity before boundaries are proven |
| Document database as primary financial store | Flexible documents and horizontal patterns | Financial constraints, relational integrity and reconciliation become more application-dependent |

**Proposed direction:** Use PostgreSQL as the initial system of record for identity/membership, tenant-owned operational data, normalized partner events and financial journals, subject to prototype and operational review. Use relational constraints and transactions for invariants. Treat JSON as an integration/raw-payload boundary, not a substitute for typed, queryable financial facts.

Row-Level Security (RLS) may provide defense in depth. It does not replace application authorization, tenant-aware repository methods, least-privilege database roles or negative cross-tenant tests. Table owners, superusers and roles with RLS bypass privileges require explicit handling; verify the exact database role used by the application.

**Data rules:**
- Store money as integer minor units or exact fixed-precision decimal according to a currency-specific precision registry; never binary floating point.
- Store currency code with every monetary amount; never infer currency from tenant locale.
- Preserve source payloads under retention/privacy controls; separate raw evidence from canonical business records.
- Use immutable journal entries and linked reversals; corrections do not overwrite history.
- Tenant, product, legal entity, currency and account dimensions must be explicit where required by LOT-FIN-POST-001.
- Schema migrations must be backward-compatible across deployment windows or use expand/migrate/contract.
- Define data classification, retention, deletion/anonymization, export and residency before production.

**Acceptance evidence:** concurrency tests for duplicate economic effects; RLS and application authorization tests including pooled connections/context reset; backup restore and point-in-time recovery exercise; migration rollback/forward-repair procedure; load test with realistic tenant skew and financial write patterns.

## 5. ADR-003 — Asynchronous work, queue and workflow orchestration

**Status:** Proposed. **Question:** How should partner callbacks, attribution, commission calculation, reconciliation and long-running processes execute reliably?

**Stage A — transactional outbox + worker:** Begin with an outbox written in the same database transaction as the business change, plus a separately runnable worker that safely claims jobs. Use bounded retries with exponential backoff and jitter, attempt limits, dead-letter/quarantine state, operator replay and idempotent handlers. This minimizes infrastructure while preserving delivery intent.

**Stage B — dedicated broker:** Introduce a broker only when measured throughput, fan-out, consumer isolation, backlog, ordering or operational needs justify it. Evaluate managed queue/broker products against delivery semantics, ordering scope, retention, replay, dead-letter handling, regional availability, cost and portability.

**Stage C — durable workflow engine:** Evaluate Temporal or an equivalent when business processes span long periods, multiple external systems, human intervention, timers, compensation or resumability. Durable workflow execution does not remove the need for idempotent external activities, business-level deduplication or reconciliation.

**Mandatory semantics:**
- Assume at-least-once delivery unless a provider contract proves otherwise; consumers must be idempotent.
- Exactly-once economic effect is an application invariant, not a broker marketing claim.
- Separate delivery attempt ID, source event ID, economic effect ID and journal entry ID.
- Use transactional inbox/outbox, uniqueness constraints and explicit processing states.
- Retry only transient failures; quarantine validation, authorization and permanent business failures.
- Never let an external callback directly mutate balances.
- Replays preserve original source evidence and rule versions, and must not duplicate postings.

**Acceptance experiments:** worker crash before/after commit; duplicate and out-of-order callbacks; provider timeout after successful remote action; poison message; queue outage; retry storm; operator replay. Demonstrate one economic effect and a complete audit trail.

## 6. ADR-004 — Runtime, hosting and deployment topology

**Status:** Proposed. **Question:** What operational model minimizes risk while retaining global expansion options?

Options:
- Managed container platform/runtime: less cluster operation; evaluate vendor lock-in, network controls, region availability, jobs, private connectivity and observability.
- Managed Kubernetes: orchestration control and portability, but cluster lifecycle, upgrades, RBAC, networking, policy, capacity and incident response become platform responsibilities.
- Self-managed virtual machines: direct control and potentially straightforward initial operations, but patching, failover, scaling, secrets, deployment and recovery remain owner responsibilities.
- Function/serverless runtime: useful for bounded event handlers and bursty workloads; assess execution limits, cold starts, networking, observability and long-running work constraints.

**Proposed direction:** Do not choose Kubernetes by default. For the first production pilot, compare a managed container/runtime option with a small, well-automated VM/container deployment. Select the least complex option satisfying availability, private networking, encryption, regional/data-residency, backup, deployment rollback, worker scheduling and incident-response requirements.

Separate development, test, staging and production environments and credentials. Never copy production data into lower environments; use synthetic or irreversibly de-identified fixtures. Deploy immutable artifacts by digest, use staged/rolling rollout, health/readiness checks and tested rollback. Infrastructure as Code is required before repeatable production infrastructure is considered mature.

**Region/residency gate:** No cloud region or hosting vendor is selected. Establish contracting entity, customer/agent location, data categories, legal basis, cross-border transfer constraints, subprocessors, retention/deletion, encryption/key control, support access and disaster-recovery region before selection. Global product scope does not mean unrestricted cross-border replication.

## 7. ADR-005 — Observability and operational evidence

**Status:** Proposed. Adopt vendor-neutral instrumentation based on OpenTelemetry for traces, metrics and logs, using common semantic conventions; select a backend/vendor later.

Minimum signals:
- Request rate, latency percentiles, error rate and saturation.
- Queue age/depth, retry count, dead-letter count and worker lag.
- Provider callback acceptance/rejection, signature failures, latency and reconciliation drift.
- Ledger posting/reversal counts, invariant violations and unbalanced journal attempts.
- Tenant-scoped authorization denials and suspicious access patterns.
- Backup age, restore-test age, deployment version and dependency health.

Never put access tokens, secrets, raw payment details, full personal data or unbounded partner payloads into telemetry. Avoid tenant/customer identifiers as high-cardinality metric labels; use controlled correlation IDs and access-controlled traces. Logs are not the financial ledger or audit journal.

Define service-level indicators and objectives only after workload and business criticality are known. Alerts need an owner, actionable runbook and severity; avoid alerting on every transient retry.

## 8. ADR-006 — Availability, backup and disaster recovery

**Status:** Proposed; numeric targets open.

Do not invent RPO/RTO targets before the owner defines business impact and contractual obligations. For each critical capability, document service criticality and maximum tolerable outage; owner-approved RPO/RTO; backup frequency, retention, encryption and access; point-in-time recovery; cross-region replication policy if legally permitted; restore-test frequency and accountable operator; recovery order and dependencies (identity, database, keys, queues, partner adapters); and reconciliation for events received during outages and provider replay windows.

A backup is not verified until a restore has been exercised. Replication is not a backup. DR is not complete until failover/failback and financial reconciliation have been tested.

## 9. ADR-007 — Security, secrets and software supply chain

**Status:** Proposed.
- Use a managed secret store or tightly controlled deployment secret mechanism; never store secrets in Git, images, logs or agent context.
- Separate human identity, workload identity and partner credentials; apply least privilege, rotation and revocation.
- Use signed/verified artifacts where supported, dependency pinning, vulnerability scanning, SBOM generation and protected release provenance.
- Define patch SLAs by severity and exposure; document exception expiry and compensating controls.
- Enforce TLS in transit and encryption at rest; document key ownership, rotation, recovery and access audit.
- Use private networking for data stores; do not expose databases or queue administration publicly.
- Review the threat model and OWASP API risks before external API exposure.

## 10. ADR-008 — Data lifecycle, privacy and residency

**Status:** Proposed; jurisdiction-specific review required.

Create a data inventory before production. For each data class record purpose, lawful/contractual basis, controller/processor role, collection source, tenant/product owner, sensitivity, storage region, recipients/subprocessors, retention period, deletion/anonymization method, export/access process and audit requirement.

Separate operational, financial, security, support and raw-provider data. Financial record retention and privacy deletion obligations must be reconciled by qualified legal/accounting review; do not promise deletion or indefinite retention without an approved policy.

## 11. Decision matrix and scoring

This section is a technology-profile supplement; the parent scoring semantics in LOT-EVAL-001 §8.3 and §17.10 are normative. Suggested weights are starting points only, not approved priorities or an active default. Adopt them only by explicit owner decision for a named technology decision unit, after confirming applicability and removing double-counting with mandatory gates.

| Criterion | Suggested weight |
|---|---:|
| Financial integrity and transactional correctness | 20% |
| Tenant isolation and security controls | 15% |
| Operational simplicity and team capability | 15% |
| Reliability, backup and recoverability | 15% |
| Integration/API and event fit | 10% |
| Global region and data-residency fit | 10% |
| Portability and exit strategy | 5% |
| Total cost of ownership at forecast scale | 10% |

Use the parent 0–5 capability rubric only when evidence is sufficient for the full atomic criterion; otherwise record NS. Missing/insufficient evidence is NS, never 0. A 0 requires sufficient evidence demonstrating the capability is absent or unacceptable. Partial evidence cannot pass a compound criterion; split it into atomic subcriteria. N/A requires prior rationale and approval, cannot remove mandatory gates, and requires transparent effective-weight normalization. Do not publish a definitive aggregate if a material criterion is NS. Keep confidence separate from score and do not multiply it into the result.

A high weighted score does not override a failed/unknown mandatory control, a minimum critical-criterion threshold, unacceptable residual risk or legal restriction. Preserve raw ratings, evidence states, weights, exclusions, gate status, uncertainty and evaluator disagreement. For T2/T3 or other material decisions, use independent scoring before consensus where practicable and record limitations if a competent second evaluator is unavailable.

## 12. Required prototypes and acceptance gates

Before accepting technology choices, run reproducible experiments:
1. Tenant boundary: propagate authenticated context through HTTP, worker, scheduled task and database; prove cross-tenant denial.
2. Financial transaction: concurrent duplicate event processing; prove one economic effect, balanced journal and linked reversal.
3. Provider failure: timeout, retry, duplicate callback, signature failure and reconciliation discrepancy.
4. Schema evolution: zero-downtime expand/migrate/contract and rollback/forward repair.
5. Recovery: restore a backup into an isolated environment and reconcile journal/event counts.
6. Observability: trace a partner event from ingress through attribution, commission decision and journal reference without exposing secrets/PII.
7. Independent products: build/run Affiliate-only and Lottery-only configurations without undeclared cross-domain dependency.
8. Deployment: immutable artifact, health gate, rollback and secrets injection with no credentials in logs.

## 13. Open owner decisions

Initial legal entity/operating model/market; data controller/processor responsibilities and residency; availability class and approved RPO/RTO; expected tenants/users/event volume/seasonality/financial transaction rates; hosting procurement authority, budget and acceptable lock-in; key custody, secret management and incident ownership; retention/deletion/export/audit policy; technology acceptance authority and signatories for financial/security controls.

## 14. References

- [Parent product, technology and supplier evaluation standard](../governance/enterprise-evaluation-standard.md) — LOT-EVAL-001; technology decision evidence and scoring semantics inherit the parent standard.

These sources inform decision criteria; they do not select a vendor or prove Lottorito implementation:
- PostgreSQL Row Security Policies: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- Kubernetes Production Environment: https://kubernetes.io/docs/setup/production-environment/
- Kubernetes setup and managed-service considerations: https://kubernetes.io/docs/setup/
- OpenTelemetry Semantic Conventions: https://opentelemetry.io/docs/concepts/semantic-conventions/
- Temporal Durable Execution: https://docs.temporal.io/durable-execution
- Temporal idempotent Activities and error handling: https://docs.temporal.io/best-practices/error-handling
- OWASP API Security Top 10: https://owasp.org/www-project-api-security/

## 15. Change history

0.2.0 — Aligned the technology matrix with the LOT-EVAL-001 v0.3.0 evidence/rating rubric; weights remain proposed and all ADRs remain PROPOSED.

0.1.0 — Initial evidence-informed technology, deployment, reliability and data-governance decision framework. All decisions remain proposed.
