# P-01 Support Access and Break-Glass Prototype

**Document ID:** LOT-PROT-P01-SUPPORT-001 | **Version:** 0.2.1 | **Status:** Synthetic prototype slice; 26 CI tests passed; not production-ready  
**Status:** Implemented prototype slice; CI verification pending  
**Parent experiment:** LOT-PROT-P01-001

## Purpose

Test a narrowly scoped, time-bound, read-only support access path without granting support identities direct access to tenant payload tables or broad application database credentials.

This is a disposable synthetic-data experiment. It is not a production support console or a grant of real customer access.

## Trust boundaries

- A support principal is distinct from a tenant member and cannot use ordinary tenant routes.
- A grant binds support subject, target tenant, resource scope, documented reason, expiry and revocation state.
- Caller-supplied grant/tenant identifiers are not authorization proof; the database lookup matches the authenticated support subject, tenant, scope, expiry and revocation state.
- A dedicated support-authorizer DB role can read grant metadata and append audit events. It cannot read tenant records, jobs, wallet data or other payload tables.
- The tenant-scoped read is performed through the existing RLS transaction. The support role itself never receives tenant payload privileges.
- The grant row is locked with FOR SHARE for the duration of the read so concurrent revocation serializes with access. PostgreSQL also evaluates an UPDATE RLS policy for this row-locking clause; the support role receives only column-level UPDATE on inert lock_version, never revoked_at.
- Audit events are append-only for the support-authorizer role and include subject, grant, tenant, resource, action, reason, outcome and database timestamp.
- Support access is read-only. No write, financial, credential, payout, wallet or identity mutation is in scope.

## Implemented acceptance scenarios

| ID | Scenario | Expected result |
|---|---|---|
| P01-SUPPORT-01 | Active grant matches subject, tenant and records:read scope | Read allowed; audit event appended |
| P01-SUPPORT-02 | Grant expired by database time | Denied; denial audit appended |
| P01-SUPPORT-03 | Grant revoked | Denied; denial audit appended |
| P01-SUPPORT-04 | Grant belongs to another support subject or tenant | Denied; no tenant payload disclosed |
| P01-SUPPORT-05 | Scope is absent or not records:read | Denied |
| P01-SUPPORT-06 | Grant identifier is missing or unknown | Denied and audited |
| P01-SUPPORT-07 | Support principal attempts ordinary tenant route or mutation | Denied |
| P01-SUPPORT-08 | Support authorizer attempts tenant payload query | Database permission denied |
| P01-SUPPORT-09 | Grant is revoked while read is in flight | Revocation serializes behind held row lock |
| P01-SUPPORT-10 | Support-authorizer attempts audit UPDATE/DELETE | Database permission denied |

## Important implementation limitations

- The shared support_authorizer role can read grant metadata across all synthetic tenants. Payload data remains unavailable, but this broad metadata visibility is a known limitation; production should bind support authorization to an individual database identity or a narrowly scoped authorization service.
- The support route uses the shared app_runtime tenant-context path to read tenant payloads. The P-01 red-team test demonstrates that a compromised shared runtime role can set its custom tenant GUC; this is a trust boundary, not protection against arbitrary SQL or application credential compromise.
- The audit allowed event records an authorized read attempt, not necessarily a successful resource return if the record is absent or a later read fails.
- The current race test verifies row-lock serialization. It does not yet exercise full endpoint revocation races under load or failure injection.

## Explicit non-goals

No production identity provider, SSO/MFA, operator UI, dual-control approval, customer notification, legal/privacy retention decision, SIEM export, emergency runbook or production access policy is implemented. No wallet, ledger, payment, payout, trading or credential access is in scope.

## Reproduction and evidence

The support tests are included in the P-01 PostgreSQL integration workflow. Required synthetic environment variable: SUPPORT_DATABASE_URL. Run [45417482780](https://github.com/tecpey/lottorito-platform/actions/runs/45416768795) passed on head `370d3b801caff4aa48970e90e7eb1e6eb9cd8567`: 26 tests passed, 0 failed, 0 skipped, using Node.js 26.13.0, PostgreSQL 18.7, npm ci and immutable action SHAs. Documentation Governance run [45417482477](https://github.com/tecpey/lottorito-platform/actions/runs/45416768461) also passed. These results validate this synthetic experiment only, not production readiness.
