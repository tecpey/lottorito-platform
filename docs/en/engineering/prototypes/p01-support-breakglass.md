# P-01 Support Access and Break-Glass Prototype

**Document ID:** LOT-PROT-P01-SUPPORT-001  
**Version:** 0.2.0  
**Status:** Synthetic experiment slice implemented; CI passed; production controls not verified  
**Parent experiment:** LOT-PROT-P01-001 / PR #36

## Purpose

Test a narrowly scoped, time-bound, read-only support access path without granting support identities direct access to tenant payload tables or broad application database credentials.

This is a disposable synthetic-data experiment. It is not a production support console or a grant of real customer access.

## Proposed trust boundaries

- A support principal is distinct from a tenant member and cannot use ordinary tenant routes.
- A support grant binds the support subject, target tenant, resource scope, human-readable reason, expiry and revocation state.
- The caller may present a grant identifier and target tenant, but neither is authorization proof. The database must match both to the authenticated support subject and an active grant.
- A dedicated support-authorizer DB role can read grant metadata and append audit events. RLS scopes grant metadata and audit inserts to the authenticated support subject using a transaction-local context set by the trusted API process. The role cannot read tenant records, jobs, wallet data or other payload tables. This context is an application trust boundary, not protection against compromise of the support-authorizer credential or arbitrary SQL execution.
- The existing least-privilege tenant application role performs the actual tenant-scoped read inside the RLS transaction.
- The grant row is locked for the duration of the data read so a concurrent revocation serializes with the access. PostgreSQL requires an UPDATE RLS policy for `SELECT ... FOR SHARE`; the support role therefore receives a narrowly scoped UPDATE policy plus column-level UPDATE on inert `lock_version` only. It cannot update `revoked_at`, scope, subject or tenant, so it cannot grant or revoke access.
- Audit events are append-only to the support-authorizer role and include subject, grant, tenant, resource, action, reason, outcome and database timestamp. The role has INSERT but no SELECT/UPDATE/DELETE on the audit table. This is database-role-enforced append-only behavior, not cryptographic tamper-proof or independently immutable storage.
- Support access is read-only. No write, financial, credential, payout, wallet or identity mutation is in scope.

## Acceptance scenarios

| ID | Scenario | Expected result |
|---|---|---|
| P01-SUPPORT-01 | Active grant matches support subject, tenant and records:read scope | Read allowed; audit event appended |
| P01-SUPPORT-02 | Grant expired by database time | Denied; denial audit appended |
| P01-SUPPORT-03 | Grant revoked | Denied; denial audit appended |
| P01-SUPPORT-04 | Grant belongs to another support subject or tenant | Denied; no tenant payload disclosed |
| P01-SUPPORT-05 | Scope is absent or not records:read | Denied |
| P01-SUPPORT-06 | Grant identifier is missing or unknown | Denied and audited without trusting caller reason |
| P01-SUPPORT-07 | Support principal attempts ordinary tenant route or mutation | Denied |
| P01-SUPPORT-08 | Support authorizer attempts tenant payload query | Database permission denied |
| P01-SUPPORT-09 | Grant is revoked while read is in flight | Revocation serializes behind the held row lock; race test required |
| P01-SUPPORT-10 | Audit table mutation is attempted by support-authorizer role | UPDATE/DELETE denied |

## Explicit non-goals

- No production identity provider, SSO, MFA or operator UI.
- No dual-control approval workflow or customer notification.
- No wallet, ledger, payment, payout, trading or credential access.
- No legal/privacy retention decision, SIEM connector or external audit export.
- No claim of protection against compromise of the trusted application or support-authorizer process.
- No production break-glass runbook or emergency access policy.

## Security notes

- Use database time for expiry and revocation checks.
- Use parameterized SQL and fixed resource/action allowlists.
- Never log record payloads or secrets in support audit events.
- Keep the support-authorizer role separate from the dispatcher and tenant application roles.
- A support grant is a capability with narrow scope, not a reusable tenant membership.
- This prototype still inherits the shared application role's custom-GUC trust boundary documented in LOT-PROT-P01-001.

## Reproduction and evidence

Implementation and synthetic fixtures are present on the stacked support branch. The integration suite exercises active/expired/revoked/mismatched grants, support-vs-tenant route separation, payload-table denial, audit-table restrictions and grant-revocation locking. CI result: PASS — [P-01 Tenant Isolation run 45414502363](https://github.com/tecpey/lottorito-platform/actions/runs/45414502363) on head `39fda51d98a65957906d670556aae7c6969cd9df`; 27 Node tests passed, 0 failed, 0 skipped, on Node.js 26.13.0 + PostgreSQL 18.7. [Documentation Governance run 45414502359](https://github.com/tecpey/lottorito-platform/actions/runs/45414502359) also passed. The support-specific cases cover subject-scoped grant RLS, active grant read/audit, expiry/revocation/mismatch denials, role separation, least privilege and grant-revocation locking. This is CI evidence for the synthetic slice only, not production support readiness.

For local reproduction, start the disposable PostgreSQL service from `prototypes/p01-tenant-isolation`, then export `ADMIN_DATABASE_URL`, `DATABASE_URL`, `DISPATCHER_DATABASE_URL` and `SUPPORT_DATABASE_URL` using the synthetic values documented in the parent P-01 runbook. Run `npm ci --ignore-scripts --no-audit --no-fund` and `npm test`. Never use these values against shared, staging or production databases.

## References

- OWASP — [Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html): security events, least-privilege log writers, sensitive-data exclusion, tamper detection and log monitoring. This prototype does not yet provide independent immutable storage, SIEM forwarding or a retention policy.
