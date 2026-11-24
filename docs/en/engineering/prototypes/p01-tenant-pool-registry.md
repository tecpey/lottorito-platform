# P-01 Tenant Credential Broker and Bounded Connection Pools

**Document ID:** LOT-PROT-P01-POOL-001 | **Version:** 0.1.0 | **Status:** Synthetic prototype; CI verification pending

## Purpose

Test a bounded connection-pool registry for identity-bound per-tenant PostgreSQL credentials. This is a follow-on to LOT-PROT-P01-001 and LOT-PROT-P01-DATA-001. The objective is to explore whether database session identity can bind a connection to one tenant without relying on a caller-controlled custom GUC.

## Implemented experiment

- A registry accepts only a server-resolved tenant UUID and coalesces concurrent pool creation for the same tenant.
- A trusted credential resolver maps that tenant ID to a tenant-specific connection string. The registry does not accept a connection string from the request.
- Each pool is configured with a bounded maximum connection count and a tenant-labelled application name that excludes credentials.
- A global pool-count cap prevents unbounded per-tenant pool creation. When at capacity, only an idle pool may be evicted; if all pools are leased, acquisition fails closed with a typed capacity error.
- Idle TTL eviction and least-recently-used idle eviction are supported.
- Tenant revocation blocks new leases immediately and drains an already active lease before closing its pool.
- Registry shutdown blocks new leases, retires pools, waits for pending creation, and closes idle pools. Active leases close their pool when released.
- Synthetic Tenant A and Tenant B connection strings authenticate as distinct PostgreSQL LOGIN roles. RLS maps the session_user identity to exactly one tenant.

## Acceptance scenarios

| ID | Scenario | Expected result |
|---|---|---|
| P01-POOL-01 | Two tenants request a pool | Each authenticates as its own DB role and resolves only its mapped tenant |
| P01-POOL-02 | Concurrent requests for one tenant | One credential resolution and one pool creation |
| P01-POOL-03 | Per-pool connection limit | Pool factory receives the configured maximum |
| P01-POOL-04 | Registry at capacity with all pools leased | New tenant acquisition fails closed; active pool is not evicted |
| P01-POOL-05 | Registry at capacity with an idle pool | Least-recently-used idle pool is closed before a new pool is created |
| P01-POOL-06 | Tenant credential revocation | New leases are rejected; active lease drains before pool close |
| P01-POOL-07 | Credential resolver fails | Caller receives a sanitized error without credential details |
| P01-POOL-08 | Pool idle TTL expires | Idle pool is closed and removed |
| P01-POOL-09 | Registry shutdown | New leases are blocked and idle pools are closed |

## Security model and unresolved design questions

- The credential resolver is a trusted control-plane component. It must authenticate the caller independently, resolve tenant membership from authoritative server-side state, retrieve secrets from a managed secret store, and never accept a caller-provided tenant ID or connection string as authorization.
- Per-tenant DB credentials provide a stronger database identity boundary than a shared application role with a user-settable custom GUC. They do not protect against compromise of the credential broker, secret store, application process or privileged database administrator.
- A production design must assess connection-count multiplication (tenant count × pool max × service replicas), PostgreSQL connection limits, PgBouncer compatibility, credential rotation/revocation, TLS verification, secret caching, failover, tenant suspension, pool warm-up, queueing/back-pressure and observability.
- This prototype uses synthetic local connection strings and a small in-process registry. It does not implement a production secret manager, dynamic role provisioning, PgBouncer, credential rotation, distributed revocation, multi-process coordination or production failover.
- The pool registry is process-local. Multiple application replicas require coordinated tenant suspension/revocation and bounded aggregate connection budgets.
- Existing shared app_runtime + custom-GUC RLS remains vulnerable to a compromised application DB credential issuing arbitrary SQL and setting its own custom GUC. Parameterized queries reduce injection risk but do not make a user-settable GUC a hard isolation boundary. Do not claim this model protects against full application-role compromise.
- The identity-bound roles are an experiment, not a selected architecture. Role-per-tenant may become operationally expensive at high tenant counts; alternatives such as a trusted connection broker, PgBouncer auth integration, database-per-tenant or schema-per-tenant require measured comparison.

## Evidence status

The code is a disposable synthetic experiment. CI and integration results are pending until a run is observed. No production readiness, credential-management provider, pooler or tenancy architecture is approved.
