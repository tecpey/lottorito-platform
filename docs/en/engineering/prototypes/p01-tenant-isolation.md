# P-01 — Tenant Isolation Prototype

**Document ID:** LOT-PROT-P01-001 | **Version:** 0.1.0 | **Status:** Implemented on a prototype branch; CI execution not yet verified | **Review date:** 2026-11-24

## Purpose and decision boundary

This disposable experiment tests one narrow slice of LOT-PROT-001: server-resolved tenant context across a native Node.js HTTP boundary and PostgreSQL row-level security (RLS), including pooled-connection reuse.

It is not a production service, authentication implementation, complete P-01 pass, approved technology decision, customer integration, or production-readiness claim. Node.js 26.13.0, PostgreSQL 18.7 and node-postgres 8.23.1 are pinned experiment candidates only. PostgreSQL 19 is not evaluated in this experiment.

## Implemented experiment slice

- Two synthetic tenants with intentionally colliding record UUIDs and natural keys.
- An injected authentication seam; the test-only authenticator maps synthetic bearer tokens to server-side principals. It is not production authentication and no token is valid outside the test fixture.
- Tenant identity is taken only from the authenticated principal. A caller-supplied x-tenant-id is ignored; a conflicting tenant_id in a write body is rejected.
- Every database operation checks out one pooled connection, opens a transaction, applies transaction-local set_config('app.tenant_id', ..., true), performs parameterized queries and commits/rolls back on that same connection.
- PostgreSQL RLS is enabled and forced on the fixture table. The runtime role is explicitly NOSUPERUSER, NOBYPASSRLS, non-owner, and lacks database/role creation privileges.
- A single-connection pool deliberately forces alternating tenant requests to reuse the same physical connection.

## Acceptance scenarios

| ID | Scenario | Expected outcome |
|---|---|---|
| P01-HTTP-01 | Missing/invalid synthetic credential | 401; no data access |
| P01-HTTP-02 | Tenant A and B list records | Each sees only its own fixture |
| P01-HTTP-03 | Forged tenant header | Authenticated tenant remains unchanged |
| P01-HTTP-04 | Same object UUID in two tenants | Each tenant sees only its own row |
| P01-HTTP-05 | Conflicting tenant ID in write body | 403; no write side effect |
| P01-HTTP-06 | Write without caller tenant ID | Server assigns authenticated tenant |
| P01-DB-01 | Alternate A/B/A through pool size 1 | No cross-request context leakage |
| P01-DB-02 | Inspect runtime role and table flags | Not superuser, owner or BYPASSRLS; RLS and FORCE RLS enabled |
| P01-DB-03 | Query/insert without tenant context | Select sees zero rows; insert denied |
| P01-DB-04 | Attempt to set app.tenant_id using shared app_runtime role | Expected exposure: role can assert another tenant; proves GUC RLS is not a boundary against compromised runtime credentials |
| P01-DB-05 | UPDATE/DELETE tenant-B-only object while scoped to A | Zero rows affected; B's object remains unchanged |
| P01-DB-06 | INSERT a tenant-B row while scoped to A, bypassing HTTP | RLS WITH CHECK rejects the write; failed transaction is rolled back before pool reuse |

## Important security interpretation

RLS is defense in depth, not a substitute for authentication, membership authorization or tenant-aware application design. A custom PostgreSQL setting is trusted only because the application controls the database connection and binds the value after authenticating the principal. An explicit red-team test demonstrates that app_runtime itself can set the custom GUC to another tenant and then read that tenant's rows. This is an expected exposure of the shared-role design, not a passing isolation control. Therefore this prototype proves defense against accidental missing tenant predicates and untrusted HTTP tenant hints, but it does NOT prove isolation against arbitrary SQL execution, SQL injection or compromise of the shared application credential. Parameterized SQL, strict query boundaries, least privilege and injection testing remain mandatory. A production threat model must decide whether the shared application process is inside the trusted computing base or whether a stronger database-verifiable tenant identity mechanism is required.

The table owner creates the fixture and owns the table; the application connects only as app_runtime. FORCE ROW LEVEL SECURITY is enabled. PostgreSQL superusers and BYPASSRLS roles can bypass RLS, and table ownership ordinarily bypasses it unless FORCE RLS is enabled. See the official [PostgreSQL 18 row security documentation](https://www.postgresql.org/docs/18/ddl-rowsecurity.html).

## Explicitly out of scope / not yet proven

- Real authentication, session revocation, MFA, workload identity or production membership storage.
- Operator/support/break-glass authorization and audit.
- Asynchronous queue jobs, retries, scheduled jobs and replay.
- Cache, object storage, search, exports, analytics and reporting isolation.
- Concurrent load, tenant skew, transaction isolation trade-offs and performance.
- Membership revocation during an active request/job.
- Database failover, connection loss during commit, migration and recovery.
- SQL injection, penetration testing, external security review or legal/privacy approval.

These omissions prevent declaring the complete LOT-PROT-001 P-01 experiment passed, even if this HTTP/database slice passes CI.

## Reproduction

From this directory, start the disposable local database:

```sh
docker compose -f compose.yaml up -d --wait
export ADMIN_DATABASE_URL='postgres://postgres:p01-admin-only-not-production@127.0.0.1:55432/lottorito_p01'
export DATABASE_URL='postgres://app_runtime:p01-only-not-for-production@127.0.0.1:55432/lottorito_p01'
npm install --ignore-scripts --no-audit --no-fund
npm test
docker compose -f compose.yaml down
```

The workflow provisions an ephemeral PostgreSQL 18.7 service and uses synthetic credentials only. The workflow also exposes a manual-dispatch trigger. The SQL setup drops and recreates the prototype table; never point it at a shared, staging or production database.

## Dependency and CI limitations

The prototype pins the direct pg dependency but does not yet commit an npm lockfile; transitive dependency reproducibility and supply-chain pinning remain follow-up work. GitHub Actions are referenced by version tags rather than immutable commit SHAs in this first experiment. These are explicit prototype limitations, not production recommendations.

## Result record

- Implementation state: files added on spike/p01-tenant-isolation.
- CI result: PASS — GitHub Actions run [45405602237](https://github.com/tecpey/lottorito-platform/actions/runs/45405602237), job `Node.js 26 + PostgreSQL 18.7 integration`, executed Node.js v26.13.0, PostgreSQL 18.7 and npm 11.20.0. All 12 Node test cases passed; 0 failed, 0 skipped. Dependency installation added 14 packages.
- The passing run includes the intentional red-team demonstration that shared `app_runtime` can set the custom GUC to another tenant; that test documents a known trust boundary and is not evidence of adversarial isolation.
- Local execution: Not run in this environment; the verified run is GitHub-hosted CI.
- Overall P-01: Inconclusive / partial scope only until the remaining asynchronous, revocation, privileged-support and other storage boundaries are tested.
- Technology decision: remains Proposed; no stack approval is implied.

## References

- LOT-PROT-001 — architecture prototype and evidence plan.
- LOT-TECH-ADR-001 — technology, deployment and reliability ADRs.
- PostgreSQL 18 — [Row Security Policies](https://www.postgresql.org/docs/18/ddl-rowsecurity.html).
- OWASP — [Multi-Tenant Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html), including tenant-context provenance, transaction-local context and isolation-strategy selection.
- AWS — [Choose the right PostgreSQL data access pattern for your SaaS application](https://aws.amazon.com/blogs/database/choose-the-right-postgresql-data-access-pattern-for-your-saas-application/), including the trade-off between shared runtime variables and per-tenant database roles.
- Node.js — [release schedule](https://github.com/nodejs/Release).
