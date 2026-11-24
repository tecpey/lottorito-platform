# Tenant Isolation and Context Model

**Document ID:** LOT-TEN-001 | **Version:** 0.1.0 | **Status:** Proposed security architecture; threat-model and implementation review required

## 1. Objective
Define how tenant identity is established, propagated, enforced and audited across interactive requests, machine integrations, asynchronous work, data stores and operations. Authentication answers who is calling; authorization answers what they may do; tenant isolation prevents one tenant's authority/data from crossing into another tenant's boundary. These controls are complementary.

## 2. Tenant context sources
Accept tenant context only from trusted sources:
- Authenticated user session plus an active membership resolved server-side.
- Authenticated service principal/client credential mapped server-side to allowed tenant(s), provider connection and scopes.
- A platform-controlled system job with an explicit, narrowly scoped service identity and recorded purpose.

A tenant_id in a URL, request body, header, queue payload or webhook is an untrusted selector until checked against the authenticated principal and server-side membership/connection mapping. Reject mismatches. Never allow a caller to self-assert a tenant.

## 3. Context propagation
Every request/job should carry a validated context envelope with tenant ID, actor/service identity, authorization scope, correlation ID, purpose, creation time, expiry where applicable and originating request/job ID. Context is integrity-protected in transit or re-derived from a durable trusted job record. Do not rely on mutable client-controlled queue fields.

Workers must:
- Validate the job identity and tenant binding before reading data.
- Run under least-privilege service identity.
- Re-check authorization and current tenant status at execution time.
- Include tenant scope in every query and storage/cache key.
- Preserve actor, source, correlation and job lineage in audit records.
- Fail closed if tenant context is missing, invalid, expired or inconsistent.

## 4. Isolation layers
- **API/UI:** object-level authorization and tenant-scoped query filters on every operation.
- **Application/domain:** tenant ownership checked at aggregate boundaries; no cross-tenant references by default.
- **Database:** tenant-aware keys/constraints; consider PostgreSQL RLS as defense in depth with safe connection/session context handling. RLS does not replace application authorization.
- **Cache:** include tenant and relevant authorization/version scope in keys; never share private cached results across tenants.
- **Queues/workers:** isolate routing, job context, retry/dead-letter and replay; do not let a job change tenant during retries.
- **Object/file storage:** tenant-scoped paths/buckets or equivalent policy; signed URLs short-lived and authorized.
- **Search/analytics/export:** tenant filters enforced before aggregation, export or download; prevent side-channel leakage.
- **Logs/observability/support:** redact sensitive fields; scope support access, record break-glass access and review it.
- **Backups/restore:** define tenant-aware restore and deletion/retention implications; test recovery without cross-tenant exposure.

## 5. Pool, bridge and silo placement
Choose isolation topology per tenant risk, contractual promises, workload, jurisdiction, residency and cost:
- **Pool:** shared infrastructure with strong logical isolation and quotas.
- **Bridge:** shared control plane with selected isolated data/compute resources.
- **Silo:** dedicated resources where required by risk, regulation, contract or scale.

The platform must support an explicit placement decision and migration path; do not imply every tenant can be moved transparently without downtime or data migration controls.

## 6. Noisy-neighbor and fairness controls
Use per-tenant quotas and rate limits for API requests, provider calls, event intake, queue depth, worker concurrency, exports, storage and expensive reports. Maintain global safety limits as well. Apply backpressure and fair scheduling; one tenant must not starve critical work for others. Quota exhaustion must be observable and produce defined retry/429 behavior without losing accepted financial events.

## 7. Cross-tenant access exceptions
Any platform support, compliance or incident access must be purpose-bound, time-limited, least-privileged, approved where required and fully audited. Cross-tenant aggregation for platform reporting must use an explicitly authorized, minimized data product; it must not expose raw tenant records to another tenant.

## 8. Verification requirements
Negative tests must attempt cross-tenant access through direct IDs, nested resources, bulk APIs, search, exports, cache hits, file URLs, background jobs, replay, support tools and reporting. Test missing/mismatched tenant context, revoked membership, suspended tenant, stale jobs, concurrent role changes and restore workflows.

## 9. Incident response
On suspected isolation breach: stop affected processing, preserve evidence, revoke compromised credentials/sessions, assess scope and affected tenants, follow contractual/legal notification requirements, remediate root cause, add regression tests and record owner/security approval before resuming.

## 10. Open decisions
Tenant hierarchy and delegated administration; per-tenant vs per-product placement; identity provider and session model; PostgreSQL RLS policy strategy; key management and encryption boundaries; data residency; support break-glass process; quota defaults and service objectives; and tenant migration/restore runbooks.