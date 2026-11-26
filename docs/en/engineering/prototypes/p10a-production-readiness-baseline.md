# P-10A — Verified Production Readiness Baseline and Repository Inventory

**Document ID:** LOT-PROT-P10A-001 | **Version:** 0.1.0 | **Status:** Verified repository snapshot; migration and production decisions remain Proposed | **Reviewed:** 2026-11-26

## 1. Purpose, authority and non-goals

P-10A establishes an evidence-backed starting point for Production Migration and Operational Readiness. It inventories repository state, prototype evidence, known limitations, governance records and migration blockers. It does not select a production stack, approve a database topology, define accounting policy, authorize access to customer data, or execute a migration.

The evidence in this document is repository/CI evidence. It is not an independent security audit, accounting opinion, legal assessment, provider certification or production-readiness attestation.

**Hard safety boundary:** no production database, live partner/customer/player data, production credential, real funds, destructive DDL, data backfill, provider connection, merge or deployment is used or authorized by P-10A.

## 2. Exact repository snapshot

Snapshot inspected on 2026-11-26:

| Item | Verified state |
|---|---|
| Repository | `tecpey/lottorito-platform` |
| Default branch | `main` |
| Latest observed default-branch commit | [94999b9](https://github.com/tecpey/lottorito-platform/commit/94999b9890581f56995c1e7050f02974522f0871) |
| P-03D–P-08 integration candidate | [PR #67](https://github.com/tecpey/lottorito-platform/pull/67), Open, Draft, unmerged |
| Candidate branch/head | `integration/p03d-p04-p08-candidate` / `c7f9ffa1f499fbd34d260b2aa6d3122d32e1ac7f` |
| P-09 cross-prototype contract | [PR #68](https://github.com/tecpey/lottorito-platform/pull/68), Open, Draft, unmerged |
| P-09 branch/head | `spike/p09-cross-prototype-contract-recovery` / `cd3ce2862868ac340e65562e5146449663a1fb16` |
| PR #68 ancestry | Based on PR #67 candidate branch; 206 commits and 68 changed files at snapshot |
| PR #68 mergeability | GitHub reported mergeable at snapshot; this is not approval to merge |
| P-10 working branch | `spike/p10-production-migration-readiness`, created from exact PR #68 head above |

PR #67 itself is stacked on `spike/p03-outbox-delivery`. PR #68 is stacked on the PR #67 candidate. These branches are deliberately not treated as merged into `main`. P-10 work is kept on a new branch based on PR #68 so the dependency remains visible. Do not retarget or flatten the ancestry without an explicit integration review.

The default branch is not the current integration candidate. Its latest observed commit is `94999b9`; the P-09 code and its CI evidence live on the Draft PR chain, not on `main`.

## 3. Exact-head CI evidence for P-09 candidate

All ten relevant workflows were observed completed successfully on PR #68 head `cd3ce2862868ac340e65562e5146449663a1fb16` on 2026-11-26:

| Workflow | Run | Evidence |
|---|---:|---|
| P-02 Ledger Posting | [45867211134](https://github.com/tecpey/lottorito-platform/actions/runs/45867211134) | PASS; 28/28 tests |
| P-03C/P-03D Ledger and Provider Integration | [45867211069](https://github.com/tecpey/lottorito-platform/actions/runs/45867211069) | PASS; P-03C 16/16 and P-03D 35/35 |
| P-04 Schema Evolution | [45867211371](https://github.com/tecpey/lottorito-platform/actions/runs/45867211371) | PASS; 8/8 tests |
| P-05 Backup/Restore and Recovery | [45867211761](https://github.com/tecpey/lottorito-platform/actions/runs/45867211761) | PASS; scripted PITR, restore/replay and negative recovery phases |
| P-05C Failover/Fencing/Failback | [45867211367](https://github.com/tecpey/lottorito-platform/actions/runs/45867211367) | PASS; 15 named assertions |
| P-06 Observability/Privacy | [45867211054](https://github.com/tecpey/lottorito-platform/actions/runs/45867211054) | PASS; 13 named assertions |
| P-07B Shared Trust Boundaries | [45867211663](https://github.com/tecpey/lottorito-platform/actions/runs/45867211663) | PASS; 43 tests |
| P-08 Deployment Health/Rollback | [45867212248](https://github.com/tecpey/lottorito-platform/actions/runs/45867212248) | PASS; 56 tests |
| P-09 Contract Baseline | [45867211939](https://github.com/tecpey/lottorito-platform/actions/runs/45867211939) | PASS; 20/20 assertions |
| Documentation Governance | [45867211454](https://github.com/tecpey/lottorito-platform/actions/runs/45867211454) | PASS; 58 bilingual pairs and 136 local links |

These are synthetic prototype workflows. A passing workflow is scoped to its test fixture, software versions and assertions; it does not prove production topology, real workload capacity, external-provider behavior, operational RPO/RTO, legal compliance or production security.

## 4. Prototype evidence and remaining boundary

| Area | What is evidenced | What remains unproven / open |
|---|---|---|
| P-01 tenant isolation | Partial HTTP/PostgreSQL RLS, job context and secondary data-plane experiments exist in separate PRs; tenant credential/pool broker has synthetic evidence | Full P-01 remains partial/inconclusive. Shared-role/custom-GUC trust boundary, real provider enforcement, credential broker at fleet scale, Redis/S3/search/warehouse, exports, revocation propagation and recovery are not production-proven |
| P-02 ledger | Disposable PostgreSQL ledger tests cover exact integer amounts, balancing, immutability, scoped idempotency, RLS/SECURITY DEFINER and atomic outbox | No production database, accounting policy, chart-of-accounts approval, commission/NGR rules, FX, custody, payout, statutory entity mapping or external reconciliation |
| P-03C/P-03D | Synthetic provider inbox → product-scoped ledger posting → outbox/delivery path, duplicate/replay and rollback assertions | No real provider, signed partner contract, certified sandbox, production transport, provider key lifecycle or live operational replay |
| P-04 | Synthetic schema evolution, compatibility, backfill and concurrent-index recovery experiments | No real tenant data, production migration rehearsal, measured lock/replication impact or approved schema lifecycle |
| P-05/P-05C | Disposable physical backup/restore, PITR, object/key/event recovery and local failover/fencing assertions | No production backup isolation/durability, regional DR, independent quorum/fencing service, proven off-site recovery, approved RPO/RTO or operator runbook rehearsal |
| P-06 | Synthetic trace/log correlation, privacy redaction, tenant scoping and forensic access assertions | No production telemetry backend, retention/cost controls, paging/on-call service or measured alert quality |
| P-07 | Synthetic independent product composition and shared trust-boundary contracts | No production IAM, cryptographic workload identity, real policy decision point, service mesh or external trust federation |
| P-08 | Synthetic artifact build/promotion/health/rollback gates | Artifact/deployment state includes in-memory fixtures; provenance is not yet production-grade signed/verified; no real deployment, migration runner or secrets platform |
| P-09 | Cross-prototype tenant+product identity, replay/recovery, provider correlation and explicit product identity | No production legacy inventory, approved mapping for historical `shared` records, physical production migration, production KMS/HSM or customer data recovery |

### Specific P-09M evidence

P-09M removed implicit `DEFAULT 'affiliate_agent'` from seven P-02 product identity columns (including the private role map) and three P-03C delivery/consumer product columns. Tests assert all ten have no default and an insert omitting `product_id` fails with SQLSTATE `23502`. This is a disposable-schema safety improvement, not a migration of historical or production rows.

## 5. Canonical documents and governance already present

Do not create duplicate specifications or issues for work already tracked. Current canonical references include:

- `LOT-TEN-001`: tenant isolation and context model.
- `LOT-IAM-TENANT-001`: tenant, identity, membership and authorization.
- `LOT-FIN-POST-001`: financial posting and reconciliation.
- `LOT-SEC-TM-001`: threat model and data governance.
- `LOT-TECH-ADR-001`: technology, deployment and reliability decision framework.
- `LOT-QA-001`: quality attributes and release gates.
- `LOT-PROT-001`: prototype and evidence plan.
- `LOT-OPS-001`: verified project status and continuation point.

Existing issue tracking:
- [LOT-011 — SRE, observability, backup and operational readiness (#14)](https://github.com/tecpey/lottorito-platform/issues/14).
- [LOT-009 — Threat model and data governance (#12)](https://github.com/tecpey/lottorito-platform/issues/12).
- LOT-005 remains the existing ledger and financial-invariant workstream; do not create a duplicate ledger-design issue.

The project status document and issue bodies contain historical snapshots. Always re-fetch exact branch/PR heads and CI status before acting on a SHA or run.

## 6. Production-readiness gaps that block migration design approval

1. **No authoritative source inventory:** no production database, tenant roster, partner export, schema catalog, row counts or retention inventory has been inspected. This is intentional; P-10A is repository-only.
2. **Ambiguous legacy ownership:** historical `shared` values cannot be automatically interpreted as Affiliate, Lottery or platform-global. A row with missing or conflicting tenant/product identity must be quarantined for adjudication, not defaulted.
3. **Identity and authority:** P-01 remains partial. A production tenant context cannot be trusted merely because a request, header, queue payload or shared database session variable carries a tenant/product identifier.
4. **Financial semantics:** legal entity, account ownership, commission recognition, provider settlement, funding, FX and payout treatment remain approval-gated. Reconciliation totals cannot manufacture missing business meaning.
5. **Migration compatibility:** production application/worker versions, deployment order, lock budgets, replica lag, connection pool behavior and rollback compatibility are unknown.
6. **Recovery:** P-05 evidence is synthetic. Production backup durability, off-site copy, key recovery, restore dependencies, recovery access and tested operator execution are not verified.
7. **Security/data governance:** production identity provider, secret manager, key hierarchy, encryption boundaries, retention/deletion, audit immutability and jurisdictional controls are not approved.
8. **Operational targets:** RPO, RTO, SLO, alert thresholds, data-volume assumptions, peak event rates and support/on-call coverage are TBD. Do not invent numeric targets.
9. **Evidence governance:** documentation CI validates structure and links, not semantic translation, legal correctness or financial-policy approval.

## 7. P-10 sequence and decision gates

| Work package | Required output | Gate |
|---|---|---|
| P-10A — repository baseline | This verified snapshot, branch/PR ancestry, CI matrix and blockers | Complete for this repository snapshot only |
| P-10B — source/legacy inventory | Read-only source catalog, schema/column inventory, tenant/product coverage, ambiguous-row register, data lineage and evidence hashes | No mapping assumptions; unknowns remain quarantined |
| P-10C — migration design | Expand/backfill/validate/cutover/contract plan, compatibility matrix, lock/replication budget, idempotent batch design, rollback/forward-fix decision tree | Architecture and data owners review; no production execution |
| P-10D — security and governance | Trust-boundary model, service identity, least-privilege roles, RLS bypass analysis, secrets/key ownership, data classification/retention and audit controls | Security/privacy/legal review; jurisdiction-specific questions remain explicit |
| P-10E — reliability and recovery | Workload profiles, backup dependencies, restore drills, RPO/RTO proposals, observability and incident runbooks | Numeric objectives require accountable owner approval and measured evidence |
| P-10F — operational acceptance | Reproducible rehearsal, evidence bundle, residual-risk register and go/no-go checklist | Explicit owner approval; separate release/deployment authorization |

### P-10B inventory rules

- Start read-only. Do not copy production personal, player or payment data into this repository, CI logs or agent context.
- Prefer schema metadata, aggregate counts and minimized, access-controlled evidence. Any row-level inspection requires a documented purpose, authorization, minimization and secure handling outside Git.
- Inventory each source independently: owner, environment, engine/version, schema, tables, columns, constraints, indexes, row/byte estimates, update rate, retention, backups, consumers, writers, replicas, PII/financial classification and extraction method.
- Measure tenant/product coverage and null/unknown/legacy values. Report counts and percentages with a reproducible query/version and snapshot timestamp.
- Detect collisions before proposing new composite uniqueness: tenant/product/account, source-event, economic-effect, idempotency, provider-event and foreign-key relationships.
- Never map `shared` to a product by frequency, name, current UI, partner assumption or convenience. Require documentary evidence and accountable owner adjudication; unresolved records remain quarantined.
- Record source snapshot, extraction code/version, query digest, timestamp, row counts and cryptographic digest for minimized manifests. A digest proves artifact integrity, not the correctness of semantic ownership.

## 8. Migration design principles to evaluate in P-10C

These are candidate controls, not approved production instructions:

1. Prefer a staged expand → compatible application/worker release → idempotent backfill → shadow validation → controlled cutover → contract sequence when the source/target and downtime requirements justify it.
2. Do not assume dual writes are safe. If both representations must be written, define a single atomic transaction boundary or a durable outbox/CDC protocol, ordering, idempotency, reconciliation and failure recovery.
3. Backfill in bounded, restartable keyset batches with a durable checkpoint, deterministic mapping version, rate limits and lag/lock monitoring. Avoid unbounded transactions.
4. Validate both structure and semantics: row counts, grouped financial totals by tenant/product/currency/account/period, balanced journals, unique-key collisions, orphan references, source-to-target effect mapping, replay state and exception counts. A matching row count alone is insufficient.
5. Keep source authoritative until explicit cutover criteria pass. Define read/write ownership and stop conditions; avoid split-brain dual authority.
6. Distinguish application rollback from schema/data rollback. After irreversible transformations or financial postings, a forward-fix or controlled restore/replay may be safer than a reverse migration.
7. Never update or delete posted financial history to make reconciliation pass. Use approved linked reversals/adjustments and preserve original evidence.
8. Use explicit lock and statement budgets, preflight lock inspection, cancellation behavior and post-migration catalog verification. PostgreSQL concurrent index creation avoids write-blocking locks but has longer execution, snapshot waits and invalid-index failure modes; it cannot be treated as risk-free.
9. RLS is defense in depth. Test table-owner and BYPASSRLS behavior, role grants, session identity, connection-pool reset, backup/restore paths and privileged access. A shared custom GUC is not a trusted identity by itself.
10. Define restore points and recovery dependencies before any contract/drop step. Verify backups and perform restore drills; backup creation alone is not recovery evidence.

## 9. Research basis

- PostgreSQL 19 documentation, Backup and Restore: SQL dumps, file-system backups and continuous archiving/PITR are distinct strategies with different assumptions: https://www.postgresql.org/docs/current/backup.html
- PostgreSQL Row Security Policies: table owners normally bypass RLS unless FORCE RLS is enabled; superusers and BYPASSRLS roles always bypass: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- PostgreSQL CREATE INDEX: CONCURRENTLY avoids locks that prevent writes but requires extra scans/waits and can leave an invalid index after failure: https://www.postgresql.org/docs/current/sql-createindex.html
- PostgreSQL Transaction Isolation and Explicit Locking: isolation levels, serialization anomalies, lock modes and monitoring must inform concurrency design: https://www.postgresql.org/docs/current/transaction-iso.html and https://www.postgresql.org/docs/current/explicit-locking.html
- NIST SP 800-207: zero trust removes implicit trust based solely on network location or asset ownership and protects individual resources: https://csrc.nist.gov/pubs/sp/800/207/final
- Google Cloud Well-Architected recovery testing: evaluate recovery by data integrity, RTO and RPO, and test restoration from loss/corruption scenarios: https://docs.cloud.google.com/architecture/framework/reliability/perform-testing-for-recovery-from-failures
- AWS Prescriptive Guidance, Migration strategy for relational databases: prepare, plan, migrate, test, cut over and operate; incremental migration and workload qualification are explicit strategy choices: https://docs.aws.amazon.com/pdfs/prescriptive-guidance/latest/strategy-database-migration/strategy-database-migration.pdf

Research informs the candidate controls; it does not select a vendor or replace Lottorito-specific workload, security, finance, legal and owner review.

## 10. P-10A acceptance and handoff

- [x] Exact repository, default branch, PR ancestry and P-09 head inspected.
- [x] Ten relevant P-09 workflows checked on the exact current PR head.
- [x] Existing canonical documents and LOT-009/LOT-011 workstreams identified; duplicate issues avoided.
- [x] Synthetic evidence separated from production claims.
- [x] Legacy `shared` ownership explicitly left unresolved; no automatic mapping proposed.
- [x] P-10B–P-10F deliverables and gates defined.
- [ ] Semantic bilingual review by a human reviewer.
- [x] Documentation Governance passed on the latest P-10 branch head; see exact-head run in PR #69.
- [ ] Owner/security/finance/legal approval of any production-facing decision.

**Current disposition:** P-10A repository baseline is documented. P-10B may proceed only as an authorized, read-only inventory of a named source environment. No production data access is implied by this document.
