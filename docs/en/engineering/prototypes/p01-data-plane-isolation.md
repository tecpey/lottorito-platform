# P-01 Secondary Data-Plane Tenant Isolation

**Document ID:** LOT-PROT-P01-DATA-001 | **Version:** 0.2.0 | **Status:** Synthetic prototype; 30 CI tests passed; provider behavior unverified

## Purpose

Extend LOT-PROT-P01-001 beyond the primary PostgreSQL tables to test the tenant boundaries commonly lost in secondary data planes: cache, object storage, search and reporting.

This experiment uses synthetic data and local in-memory adapters for cache, object storage and search, plus PostgreSQL 18 RLS for reporting. It does not integrate Redis, S3-compatible storage, OpenSearch, Elasticsearch or a production analytics warehouse.

## Implemented contracts

- **Cache:** derive every key from a validated server-resolved tenant UUID, a safe namespace and a single safe logical-key segment. Caller-supplied tenant identifiers are not accepted by the cache adapter.
- **Object storage:** every object key is namespaced under tenants/{tenantId}/{namespace}/{objectId}; path separators, traversal segments, encoded separators and unsafe characters are rejected.
- **Search:** the adapter injects an immutable tenant filter from trusted context; the caller supplies only a bounded query string. Provider adapters must translate this filter into a mandatory backend filter, not a scoring hint.
- **Reporting:** report rows have tenant-scoped composite identity and their own PostgreSQL RLS policies. Both shared-GUC and per-tenant session_user models are exercised independently of the source record tables.

## Acceptance scenarios

| ID | Scenario | Expected result |
|---|---|---|
| P01-DATA-01 | Same logical cache key exists for Tenant A and B | Keys and values remain isolated |
| P01-DATA-02 | Cache namespace/key contains traversal or encoded path input | Rejected before backend access |
| P01-DATA-03 | Same object ID exists under two tenants | Each tenant resolves only its own prefixed object |
| P01-DATA-04 | Object namespace/ID contains path traversal | Rejected before backend access |
| P01-DATA-05 | Same search phrase matches documents in two tenants | Results contain only the trusted tenant |
| P01-DATA-06 | Caller attempts to pass a tenant override in search input | Rejected; tenant filter remains server-derived |
| P01-DATA-07 | Same report ID/key exists in both tenants | Composite identity and RLS return only the current tenant row |
| P01-DATA-08 | Reporting query runs without tenant context | Default-deny returns no rows |
| P01-DATA-09 | Shared app role filters for another tenant | RLS returns no cross-tenant rows |
| P01-DATA-10 | Per-tenant LOGIN role queries the other tenant's report | Identity-bound RLS returns no rows |

## Security and operational limits

- In-memory adapters prove key derivation and adapter contracts only. They do not prove Redis ACLs, cluster/keyspace behavior, S3 bucket/IAM policy, object versioning, CDN behavior, OpenSearch alias/filter enforcement, index lifecycle, warehouse row-level security or export isolation.
- Search filter enforcement depends on each production provider adapter; a backend that ignores the filter invalidates the boundary.
- Cache invalidation, TTL expiry, stampede protection, distributed locks, object lifecycle, signed URL expiry, CDN caching, search reindexing, analytics extracts and export/download delivery remain untested.
- The shared app_runtime custom-GUC trust boundary remains as documented in LOT-PROT-P01-001. The per-tenant session_user model is stronger in this experiment but credential brokering and connection-pool scaling remain open.

## Evidence status

The initial data-plane CI run `45419470701` passed all 30 tests (0 failed, 0 skipped) on the pre-hardening revision `361a7706c57558aea871b2a80c35088b0935db9d`. Subsequent hardening canonicalized tenant UUIDs and rejected blank/control-character search queries; the first CI attempt for that exact revision was cancelled before a result could be established. A fresh run is required before treating the hardened revision as verified.

Run [45419828256](https://github.com/tecpey/lottorito-platform/actions/runs/45419828256) passed on head `02850c6374dd295ec0df6ba42addf266a2d8a977`: 30 tests passed, 0 failed, 0 skipped, using Node.js 26.13.0, PostgreSQL 18.7, npm ci and immutable action SHAs. Documentation Governance run [45419828218](https://github.com/tecpey/lottorito-platform/actions/runs/45419828218) passed. Local execution, provider-specific behavior, performance and failure recovery remain unverified. No production readiness or provider selection is claimed.
