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
- Job creation writes a tenant-scoped job row and metadata-only dispatch row in one database transaction; the tenant ID is derived from the authenticated principal.
- A separate non-superuser/non-BYPASSRLS dispatcher role can claim global dispatch metadata with `FOR UPDATE SKIP LOCKED`, but has no grant on job payloads. Its UPDATE grant is limited to dispatch status/attempt/lease columns.
- Dispatch envelopes bind key ID, version, tenant ID, job ID, attempt and issue time with Ed25519 signatures. The dispatcher holds the private signing key; the worker receives only the public verification key and verifies before setting tenant context and reloading the job under RLS. Tests generate a fresh ephemeral key pair for each run.
- The worker re-checks the originating subject's active membership in the job transaction, uses row locks and an idempotent status transition, and rejects jobs whose membership was revoked before execution.

## Acceptance scenarios

| ID | Scenario | Expected outcome |
|---|---|---|
| P01-HTTP-01 | Missing/invalid synthetic credential | 401; no data access |
| P01-HTTP-02 | Tenant A and B list records | Each sees only its own fixture |
| P01-HTTP-03 | Forged tenant header | Authenticated tenant remains unchanged |
| P01-HTTP-04 | Same object UUID in two tenants | Each tenant sees only its own row |
| P01-HTTP-05 | Conflicting tenant ID in write body | 403; no write side effect |
| P01-HTTP-06 | Write without caller tenant ID | Server assigns authenticated tenant |
| P01-HTTP-07 | Revoke a tenant membership, then issue a new request | Revoked subject is denied; another tenant remains unaffected |
| P01-DB-01 | Alternate A/B/A through pool size 1 | No cross-request context leakage |
| P01-DB-02 | Inspect runtime role, table flags, policy composition and membership grants | Not superuser, owner or BYPASSRLS; RLS and FORCE RLS enabled; tenant guard is RESTRICTIVE; UPDATE is granted only on inert lock_version, not active |
| P01-DB-03 | Query/insert without tenant context | Select sees zero rows; insert denied |
| P01-DB-04 | Attempt to set app.tenant_id using shared app_runtime role | Expected exposure: role can assert another tenant; proves GUC RLS is not a boundary against compromised runtime credentials |
| P01-DB-05 | UPDATE/DELETE tenant-B-only object while scoped to A | Zero rows affected; B's object remains unchanged |
| P01-DB-06 | INSERT a tenant-B row while scoped to A, bypassing HTTP | RLS WITH CHECK rejects the write; failed transaction is rolled back before pool reuse |
| P01-DB-07 | Read tenant membership rows under A and B contexts | Membership table RLS exposes only the active tenant's membership rows |
| P01-ASYNC-01 | Enqueue a job as A/B and attempt caller tenant override | Job and dispatch metadata are atomic; tenant comes from principal; forged tenant is denied |
| P01-ASYNC-02 | Inspect dispatcher role and query job payloads | Dispatcher can read/claim metadata only; payload SELECT is denied; role has no BYPASSRLS |
| P01-ASYNC-03 | Change tenant ID in a signed queue envelope | HMAC verification fails before any tenant-scoped data access |
| P01-ASYNC-04 | Two dispatcher connections claim concurrently; reclaim a lease and replay delivery | `SKIP LOCKED` yields distinct jobs; only current attempt can acknowledge; job effect completes once; replay is idempotent |
| P01-ASYNC-06 | Force dispatch foreign-key failure after job insert | Whole transaction rolls back; no orphan tenant job remains |
| P01-ASYNC-05 | Revoke actor membership after enqueue but before execution | Worker marks the job rejected and does not execute its payload |

## Important security interpretation

RLS is defense in depth, not a substitute for authentication, membership authorization or tenant-aware application design. This slice now checks active membership inside the same transaction as tenant data access and locks the membership row FOR SHARE; revocation affects subsequent requests, while a concurrent revocation must serialize with the in-flight transaction. A custom PostgreSQL setting is trusted only because the application controls the database connection and binds the value after authenticating the principal. An explicit red-team test demonstrates that app_runtime itself can set the custom GUC to another tenant and then read that tenant's rows. This is an expected exposure of the shared-role design, not a passing isolation control. Therefore this prototype proves defense against accidental missing tenant predicates and untrusted HTTP tenant hints, but it does NOT prove isolation against arbitrary SQL execution, SQL injection or compromise of the shared application credential. Parameterized SQL, strict query boundaries, least privilege and injection testing remain mandatory. A production threat model must decide whether the shared application process is inside the trusted computing base or whether a stronger database-verifiable tenant identity mechanism is required.

The table owner creates the fixture and owns the table; the application connects only as app_runtime. FORCE ROW LEVEL SECURITY is enabled. A permissive baseline policy is paired with a RESTRICTIVE tenant guard: PostgreSQL combines permissive policies with OR, so the restrictive guard remains ANDed with them and prevents a later broad permissive policy from widening tenant access. PostgreSQL superusers and BYPASSRLS roles can bypass RLS, and table ownership ordinarily bypasses it unless FORCE RLS is enabled. See the official [PostgreSQL 18 row security documentation](https://www.postgresql.org/docs/18/ddl-rowsecurity.html).

## Explicitly out of scope / not yet proven

- Real authentication, session revocation, MFA, workload identity or production membership storage.
- Concurrent race testing for membership revocation against an already in-flight request; the request/job transaction takes a row-level share lock so revocation must serialize behind it, but this race has not been stress-tested. PostgreSQL requires UPDATE privilege on at least one column for SELECT FOR SHARE; the runtime role receives this only on inert lock_version, not on the active authorization flag.
- A real message broker, external queue delivery, scheduled jobs, exponential backoff, dead-letter queue, dispatcher concurrency/load testing, and production key rotation/KMS integration. The current dispatch table is a provider-neutral outbox/claim simulation, not a selected queue product.
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
export DISPATCHER_DATABASE_URL='postgres://job_dispatcher:p01-dispatcher-not-for-production@127.0.0.1:55432/lottorito_p01'
npm ci --ignore-scripts --no-audit --no-fund
npm test
docker compose -f compose.yaml down
```

The workflow provisions an ephemeral PostgreSQL 18.7 service and uses synthetic credentials only. The workflow also exposes a manual-dispatch trigger. The SQL setup drops and recreates the prototype fixture tables and resets synthetic roles; never point it at a shared, staging or production database. The dispatcher credential is a synthetic test value only; Ed25519 test keys are generated ephemerally by the test process and are never stored in the repository.

## Dependency and CI limitations

The prototype pins the direct pg dependency but does not yet commit an npm lockfile; transitive dependency reproducibility and supply-chain pinning remain follow-up work. GitHub Actions are referenced by version tags rather than immutable commit SHAs in this first experiment. These are explicit prototype limitations, not production recommendations.

## Result record

- Implementation state: files added on spike/p01-tenant-isolation.
- CI result: PASS — latest verified GitHub Actions run [45409321843](https://github.com/tecpey/lottorito-platform/actions/runs/45409321843), on head `d9bcee4581523e0d9e4f11070f4196060ce7d537`. It used Node.js v26.13.0, PostgreSQL 18.7 and npm ci with the committed lockfile; all 18 Node test cases passed, 0 failed, 0 skipped. GitHub Actions are pinned to verified immutable commit SHAs.
- The passing run includes atomic job/outbox writes, concurrent dispatcher claims using `SKIP LOCKED`, lease retry and stale-ack rejection, Ed25519-signed tenant/job envelopes (private key at dispatcher; public key only at worker), metadata-only dispatcher permissions, idempotent replay, worker-side membership re-authorization and rejection after revocation. It also includes request-time membership revocation, tenant-table RLS, narrow `UPDATE(lock_version)` for `SELECT FOR SHARE` without permission to change `active`, cross-tenant UPDATE/DELETE denial, WITH CHECK rejection and pool reuse.
- A deliberate red-team test still demonstrates that a compromised shared `app_runtime` role can set the custom GUC to another tenant. This is a known trust boundary, not evidence of adversarial isolation.
- Local execution: Not run in this environment; the verified run is GitHub-hosted CI.
- Overall P-01: Inconclusive / partial scope only until the remaining asynchronous, revocation, privileged-support and other storage boundaries are tested.
- Technology decision: remains Proposed; no stack approval is implied.

## References

- LOT-PROT-001 — architecture prototype and evidence plan.
- LOT-TECH-ADR-001 — technology, deployment and reliability ADRs.
- PostgreSQL 18 — [Row Security Policies](https://www.postgresql.org/docs/18/ddl-rowsecurity.html) and [Privileges](https://www.postgresql.org/docs/18/ddl-priv.html) (SELECT FOR SHARE privilege requirement).
- OWASP — [Multi-Tenant Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html), including tenant-context provenance, transaction-local context and isolation-strategy selection.
- AWS — [Choose the right PostgreSQL data access pattern for your SaaS application](https://aws.amazon.com/blogs/database/choose-the-right-postgresql-data-access-pattern-for-your-saas-application/), including the trade-off between shared runtime variables and per-tenant database roles.
- AWS Prescriptive Guidance — [Transactional outbox pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html), including atomic outbox writes and idempotent at-least-once consumers.
- PostgreSQL 18 — [SELECT locking clause](https://www.postgresql.org/docs/current/sql-select.html), including `SKIP LOCKED` for queue-like multi-consumer claims.
- Node.js — [release schedule](https://github.com/nodejs/Release).
