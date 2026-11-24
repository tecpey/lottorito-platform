# P-03 — Tenant Credential Broker and Connection-Pool Scaling Experiment

**Document ID:** LOT-PROT-P03-001  
**Version:** 0.1.0  
**Status:** Proposed experiment plan; no provider or architecture choice approved  
**Review date:** 2026-11-24

## 1. Purpose

P-03 evaluates whether the identity-bound PostgreSQL model demonstrated in P-01 can be operated safely and economically as the tenant estate grows. P-01 showed that a tenant-specific PostgreSQL LOGIN role and `session_user`-bound RLS can resist caller-controlled tenant-GUC spoofing in a synthetic test. It did not prove that thousands of tenant credentials, pools, role lifecycle operations or credential rotations can be managed reliably.

The experiment separates **identity assurance** from **operational scalability**. A faster model that weakens identity provenance is not an acceptable winner.

## 2. Boundaries

- Synthetic tenants, records and disposable PostgreSQL/PgBouncer only.
- No customer data, production credentials, live Vault cluster, AWS account or external secret manager.
- No selection of Vault, AWS RDS IAM, PgBouncer, RDS Proxy or a production database provider.
- No production-ready credential broker, provisioning API or migration framework.
- No final pool-size, tenant-count, latency or availability SLO; workload assumptions and thresholds require owner approval.
- P-01 remains partial/inconclusive; passing P-01 tests do not imply P-03 has passed.

## 3. Research evidence

### PostgreSQL identity and role membership

PostgreSQL distinguishes `session_user` (normally the identity that authenticated the database connection) from `current_user` (the effective permission identity, which can change through `SET ROLE` or `SECURITY DEFINER`). Test both; do not treat them as interchangeable.  
Sources: [system information functions](https://www.postgresql.org/docs/18/functions-info.html), [role membership](https://www.postgresql.org/docs/18/role-membership.html).

Role membership has separate inheritance and `SET` semantics. A login role may inherit privileges from a tenant group role, while `SET ROLE` is possible only through a membership chain that permits it. Cross-tenant membership must never be granted. PostgreSQL roles also support `LOGIN`, `NOLOGIN`, `NOBYPASSRLS`, `CONNECTION LIMIT` and password validity controls.  
Sources: [CREATE ROLE](https://www.postgresql.org/docs/18/sql-createrole.html), [ALTER ROLE](https://www.postgresql.org/docs/18/sql-alterrole.html).

### PgBouncer pool topology

PgBouncer transaction pooling assigns a server connection only for the duration of a transaction and releases it when the transaction ends. Session-dependent features are incompatible and must be excluded or explicitly tested.  
Source: [PgBouncer feature compatibility](https://www.pgbouncer.org/features.html).

Without a forced database user, PgBouncer maintains pools per user/database pair. Its documented file-descriptor upper-bound calculation grows with distinct users and databases; it also provides per-user and per-database server-connection limits. A forced user collapses backend identity to that configured user, making it a negative control for a `session_user` design.  
Sources: [PgBouncer configuration](https://www.pgbouncer.org/config.html), [authentication settings](https://www.pgbouncer.org/config.html#authentication-settings).

### Credential lifecycle candidates

Vault's PostgreSQL secrets engine supports dynamic credentials with TTL/max-TTL and static roles with password rotation. Dynamic usernames may improve attribution but increase pool cardinality; static roles avoid a new username per lease but require a safe rotation/drain procedure.  
Sources: [Vault PostgreSQL secrets engine](https://developer.hashicorp.com/vault/docs/secrets/databases/postgresql), [Vault database secrets engine](https://developer.hashicorp.com/vault/docs/secrets/databases).

AWS RDS IAM database authentication uses signed tokens with a 15-minute lifetime. The PostgreSQL user must be configured for IAM authentication (for RDS PostgreSQL, through `rds_iam`); this is AWS-specific, not a provider-neutral decision. RDS Proxy can pin sessions when PostgreSQL session variables change, reducing multiplexing; measure transaction-local state rather than assuming it will multiplex.  
Sources: [RDS IAM authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html), [RDS Proxy pinning](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy-pinning.html), [RDS Proxy workload considerations](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy-best-practices.workload-considerations.html).

## 4. Models to compare

| Model | Database identity | Pool topology | Purpose |
|---|---|---|---|
| A. Per-tenant static LOGIN role | Tenant-specific `session_user` | PgBouncer pool per tenant DB user | Strong identity baseline |
| B. Ephemeral LOGIN per credential lease | Unique lease user mapped to one tenant role | Potentially one pool per ephemeral user | Dynamic-secret lifecycle and pool-cardinality stress |
| C. Shared application LOGIN + transaction-local tenant GUC | Shared `session_user`; tenant comes from GUC | Shared pool | Negative/control baseline; P-01 already demonstrates spoofing boundary |
| D. PgBouncer forced backend user | Forced shared backend identity | One pool per configured database | Negative control; not tenant identity |
| E. Per-tenant application-side `pg.Pool` | Tenant-specific LOGIN role | Application pool registry | Measures local pool explosion and eviction complexity |

Model B may use a tenant-specific non-login group role with narrowly scoped grants and a lease-specific LOGIN member. Explicitly test membership, `INHERIT`, `SET`, RLS behavior, revocation and the fact that `session_user` remains the lease login, not the tenant group role.

## 5. Workload and metrics

Run deterministic workloads at **10, 100 and 1,000 tenants**, with **10%, 50% and 100%** active-tenant ratios and controlled concurrency. Exact request rates and latency thresholds remain TBD pending an approved representative workload.

Record for every model:
- Tenant/active-tenant count, concurrent requests and transactions per second.
- PgBouncer client/server connections, pools, queued clients, per-user/per-database limits and file-descriptor use.
- PostgreSQL active/idle connections, role count, connection churn and rejected connections.
- Application pool count, idle/active connections, acquisition wait, eviction and memory.
- Credential issue/renew/revoke latency, authentication failures and secret-manager latency.
- p50/p95/p99 request and connection-acquisition latency, CPU and memory.
- Isolation violations, wrong `session_user`, role-switch attempts and stale-credential reuse.

Use fixed random seeds, synthetic tenant IDs, colliding record IDs, repeatable concurrency barriers and machine-readable result artifacts. A single noisy run is not an architecture decision.

## 6. Security and lifecycle scenarios

| ID | Scenario | Required evidence |
|---|---|---|
| P02-IAM-01 | Tenant A/B use distinct DB identities | `session_user` maps to the intended tenant on every transaction |
| P02-IAM-02 | Attempt `SET ROLE` to another tenant | Permission denied; no cross-tenant membership chain |
| P02-IAM-03 | PgBouncer transaction pooling with backend reuse | Reuse never changes tenant identity or exposes prior tenant rows |
| P02-IAM-04 | Forced PgBouncer backend user | Demonstrate shared backend `session_user`; mark unsuitable for tenant identity |
| P02-IAM-05 | SECURITY DEFINER identity check | Distinguish `session_user` and `current_user`; policy does not trust definer identity |
| P02-CRED-01 | Issue/cache/renew credentials | Explicit tenant binding and credential version; no cache-key collision |
| P02-CRED-02 | Rotate N to N+1 | New connections use N+1; N pools drain; revoked credentials cannot open new connections |
| P02-CRED-03 | Revoke/expire lease during active transaction | Existing-session behavior and maximum revocation delay measured; new connections fail closed |
| P02-CRED-04 | Broker unavailable or cache stale | No shared privileged fallback; bounded explicit failure |
| P02-POOL-01 | Scale 10 to 1,000 tenants | Pool and server-connection counts stay within an owner-approved budget |
| P02-POOL-02 | Tenant burst and idle eviction | No starvation; idle pools reclaimed safely |
| P02-POOL-03 | Pool exhaustion | Backpressure, queue timeout and recovery are deterministic |
| P02-POOL-04 | Backend reuse after commit/rollback/error | Transaction-local state resets; no cross-tenant leakage |

## 7. Safety invariants

1. Tenant identity comes from the authenticated principal and a server-controlled credential mapping, never a request header, query parameter or body field.
2. Each database login credential maps to exactly one tenant boundary and cannot `SET ROLE` into another tenant.
3. Pool keys include endpoint, database, authenticated database username/identity and credential version; never key only on caller-supplied tenant text.
4. Rotation creates an explicit new version: stop issuing old credentials, stop creating old-version connections, drain old pools, then revoke the old credential.
5. Revocation accounts for already-authenticated PostgreSQL sessions. Password expiry alone does not prove existing sessions have terminated.
6. Pool count, connection count, queue depth, file descriptors and idle lifetime are bounded globally and per tenant.
7. Broker outage, credential expiry, role deletion, pool exhaustion and stale cache fail closed; no shared superuser/unrestricted fallback.
8. PgBouncer transaction pooling is eligible only if session-dependent features are avoided and identity tests pass under backend reuse.
9. Secret material never appears in logs, traces, test artifacts, PR output or tenant-visible APIs.
10. Provision/deprovision and credential rotation are idempotent, observable and reconcilable against PostgreSQL role state.

## 8. Proposed stages

1. **P02-A — Pool topology:** deterministic PgBouncer model for 10/100/1,000 per-tenant users; measure pools, connections, file descriptors and queue behavior.
2. **P02-B — Identity under transaction pooling:** verify `session_user`, `current_user`, membership and RLS through backend reuse; include forced-user and shared-GUC negative controls.
3. **P02-C — Credential broker simulation:** provider-neutral interface with synthetic SCRAM credentials and versioned leases; no real Vault/AWS connection.
4. **P02-D — Rotation and revocation:** issue N/N+1, stop issuance, drain pools, revoke N and measure existing-session behavior/recovery.
5. **P02-E — Provider adapter evaluation:** compare Vault dynamic/static roles and AWS RDS IAM only after the provider-neutral contract is tested.

Each stage has a separate result record. Passing one stage does not imply the next stage or full P-03 has passed.

## 9. Decision gates

No model is selected until identity/isolation tests pass under concurrency and backend reuse; pool/connection growth is measured at agreed tenant populations; rotation/revocation includes already-open sessions; broker outage and pool exhaustion fail closed; performance/operations/cost trade-offs have reproducible evidence; PostgreSQL, PgBouncer and managed-proxy behavior are distinguished; and the owner approves workload assumptions and numeric thresholds.

**Current decision:** no credential broker, pooler, provider or tenant database identity architecture is approved. P-03 is a research/prototype plan only.

## 10. References

- [PostgreSQL 18 — system information functions](https://www.postgresql.org/docs/18/functions-info.html)
- [PostgreSQL 18 — role membership](https://www.postgresql.org/docs/18/role-membership.html)
- [PostgreSQL 18 — CREATE ROLE](https://www.postgresql.org/docs/18/sql-createrole.html)
- [PostgreSQL 18 — ALTER ROLE](https://www.postgresql.org/docs/18/sql-alterrole.html)
- [PgBouncer — features and pooling compatibility](https://www.pgbouncer.org/features.html)
- [PgBouncer — configuration](https://www.pgbouncer.org/config.html)
- [PgBouncer — authentication settings](https://www.pgbouncer.org/config.html#authentication-settings)
- [Vault — PostgreSQL database secrets engine](https://developer.hashicorp.com/vault/docs/secrets/databases/postgresql)
- [Vault — database secrets engine](https://developer.hashicorp.com/vault/docs/secrets/databases)
- [AWS — RDS IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html)
- [AWS — RDS Proxy pinning](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy-pinning.html)
