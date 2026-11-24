# P-01 Tenant-Bound Export Download Grants

**Document ID:** LOT-PROT-P01-EXPORT-001 | **Version:** 0.2.0 | **Status:** Synthetic prototype; CI verification pending

## Purpose

Test the authorization boundary between a completed tenant export and the later act of downloading it. A tenant-scoped export row alone is not enough: download credentials must also be bound to the authenticated subject, expire, resist replay and remain unusable after export revocation.

This experiment uses synthetic PostgreSQL 18.7 data and the existing Node.js 26 prototype. It does not provide an HTTP download endpoint or connect to an object-storage provider.

## Implemented contract

- Export identity is composite: `(tenant_id, export_id)`; the object key must begin with that tenant's storage prefix.
- Grant issuance and redemption both reauthorize the authenticated subject's active tenant membership under a row-level `FOR SHARE` lock.
- Grant issuance requires a server-resolved tenant, authenticated subject, an export created by that subject and export status `ready`.
- Tokens contain 256 bits of cryptographically secure randomness and are returned once. PostgreSQL stores only a SHA-256 hash, never the raw token.
- Grants are bound to tenant, subject and export; expiry is computed by PostgreSQL's clock.
- TTL is constrained to 60–600 seconds (default 300 seconds).
- Grant issuance and redemption re-check active tenant membership inside the same tenant-scoped transaction and hold a `FOR SHARE` membership lock, serializing with membership revocation.
- Redemption locks the grant row and the export row, checks tenant/subject/hash/expiry/revocation/export status and atomically sets `consumed_at`.
- A successful redemption returns an internal object key and checksum to the trusted server layer. It does not return a public URL or storage credential.
- Tenant-scoped RLS and a composite foreign key protect export and grant rows independently.

## Acceptance scenarios

| ID | Scenario | Expected result |
|---|---|---|
| P01-EXPORT-01 | Authenticated owner requests a grant for a ready export | One high-entropy token is issued |
| P01-EXPORT-02 | Database inspects a newly issued grant | Only the token hash is stored |
| P01-EXPORT-03 | Another subject attempts redemption | No grant is returned or consumed |
| P01-EXPORT-04 | Another tenant attempts redemption | No grant is returned or consumed |
| P01-EXPORT-05 | The owner redeems a valid grant | Internal object key and checksum are returned once |
| P01-EXPORT-06 | The same token is replayed | Redemption is denied |
| P01-EXPORT-07 | Grant has expired according to database time | Redemption is denied |
| P01-EXPORT-08 | Export is revoked after grant issuance | Redemption is denied |
| P01-EXPORT-09 | Two requests redeem the same token concurrently | Exactly one redemption succeeds |
| P01-EXPORT-10 | TTL is outside 60–600 seconds or token is malformed | Request fails closed |
| P01-EXPORT-11 | Tenant membership is revoked after grant issuance | New grants and existing grant redemption are denied |
| P01-EXPORT-11 | Subject membership is revoked after grant issuance | New grants and existing grant redemption are denied; membership lock serializes concurrent revocation |

## Security boundaries and limitations

- This is a download-authorization primitive, not an end-to-end download service. No HTTP streaming endpoint, object-storage adapter, S3 pre-signed URL, CDN, malware/content scanning, range request, download audit trail, quota, rate limit or retention lifecycle is implemented.
- The application must authenticate the subject independently; the token alone is not sufficient identity proof. Current tenant membership is checked again at redemption, not only at issuance.
- The object key must remain server-side. Do not redirect to a public bucket or expose storage credentials.
- If the application later issues a provider-signed URL, its expiry, revocation semantics, replay window and cache headers need a separate threat model. A provider URL may remain usable after this database grant is consumed.
- One-time redemption can create a retry dilemma if the client disconnects after consumption but before receiving the file. A production flow must explicitly choose server streaming, a short-lived delivery lease, or an idempotent download-session design.
- The shared `app_runtime` custom-GUC trust boundary documented in LOT-PROT-P01-001 remains. This experiment does not prove isolation against a compromised application database role.
- No production readiness is claimed.

## Evidence status

The P-01 Tenant Isolation run [45426108704](https://github.com/tecpey/lottorito-platform/actions/runs/45426108704) passed on code head `b88c83ad5f5160681ec0e132c1efe07d8b913da0`: 36 tests passed, 0 failed, 0 skipped. Documentation Governance run [45426108688](https://github.com/tecpey/lottorito-platform/actions/runs/45426108688) also passed. Local execution and provider-specific download delivery remain unverified.

Code, schema and synthetic integration scenarios are implemented on a stacked Draft PR. All fixtures and credentials are synthetic.
