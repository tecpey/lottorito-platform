# P-01 Tenant Credential and Connection-Pool Registry

**Document ID:** LOT-PROT-P01-POOL-001 | **Version:** 0.4.0 | **Status:** Synthetic prototype; 40 CI tests passed; production controls unverified

## Purpose

Test whether the stronger per-tenant PostgreSQL LOGIN/session_user isolation model can be used through a bounded application-side credential and connection-pool registry without creating unbounded pools or evicting pools that are in active use.

This experiment uses synthetic credentials and PostgreSQL roles only. It is not a production secret broker, vault integration or connection-management service.

## Implemented controls

- Tenant identity is validated and canonicalized before credential lookup.
- Credential resolution is injected through a server-side provider function; caller input never supplies a connection string or database role.
- Credential lookup and pool creation are coalesced for concurrent requests for the same tenant.
- Before publication or lease, the new pool executes a fixed identity query and verifies that `private.current_tenant_id()` matches the requested tenant; a mismatched credential is closed and rejected.
- Every pool has an explicit maximum connection count; the registry has a maximum number of tenant pools.
- At capacity, only the least-recently-used idle pool may be evicted. If every pool is active, acquisition fails closed with a typed capacity error.
- Idle pools can be evicted after a deterministic TTL sweep.
- Tenant revocation blocks new leases immediately and drains active and already-reserved leases before closing its pool.
- Registry shutdown is idempotent and waits for all active leases to drain.
- Credential-resolution and pool-creation failures are sanitized; connection strings are not returned in errors.
- The integration test uses actual synthetic PostgreSQL per-tenant LOGIN credentials and verifies session_user and private.current_tenant_id().

## Acceptance scenarios

| ID | Scenario | Expected result |
|---|---|---|
| P01-POOL-01 | Concurrent acquisition for one tenant | One credential lookup and one pool creation |
| P01-POOL-02 | Tenant A and B acquire pools | Distinct database roles and tenant identities |
| P01-POOL-03 | Per-pool and global pool limits are reached | Limits are enforced |
| P01-POOL-04 | Registry is full and every pool has an active lease | New acquisition fails closed; no active pool is evicted |
| P01-POOL-05 | Registry is full with an idle pool | Least-recently-used idle pool is closed before replacement |
| P01-POOL-06 | Tenant credential is revoked during an active lease | New leases denied; active lease drains before pool close |
| P01-POOL-07 | Pool reaches idle TTL | Deterministic sweep closes the idle pool |
| P01-POOL-08 | Credential provider throws an error containing secret text | Caller receives a sanitized error without secret material |
| P01-POOL-09 | Resolver returns credentials mapped to a different tenant | Database identity check rejects and closes the pool before any lease |
| P01-POOL-10 | Shutdown begins while a lease is active | New leases fail; shutdown completes only after the active lease drains |

## Explicit limitations

- Credentials are synthetic environment values. No Vault, cloud secret manager, KMS, rotation API, certificate auth, workload identity or production secret lifecycle is integrated.
- Pool registry state is process-local. Multi-process/multi-region coordination, fleet-wide quotas, credential revocation propagation, distributed eviction and failover are not implemented.
- Credential version is recorded for diagnostics, but seamless credential rotation and overlapping old/new pool draining are not implemented.
- The registry callback is trusted application code; callers must not retain a pool or client beyond the lease callback.
- Connection churn, real workload load, PgBouncer compatibility, failover, DNS changes, TLS policy and tenant-count scale have not been benchmarked.
- The shared app_runtime custom-GUC model remains a weaker alternative and retains its documented trust boundary.

## Evidence status

The rebuilt PR #45 P-01 run [45424792886](https://github.com/tecpey/lottorito-platform/actions/runs/45424792886) passed 40 tests (0 failed, 0 skipped) on code head `153fc8974c9c620acd8d509afdea0341669e5c`. Documentation Governance run [45424793114](https://github.com/tecpey/lottorito-platform/actions/runs/45424793114) also passed. This verifies the synthetic prototype only; local execution, production secret management, credential rotation, fleet-wide quotas, PgBouncer, TLS policy, failover and scale remain unverified. No PostgreSQL topology, secret manager, pooler or production deployment is approved.
