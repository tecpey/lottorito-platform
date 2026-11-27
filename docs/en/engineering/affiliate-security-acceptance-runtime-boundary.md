# Affiliate Security Acceptance & Runtime Boundary Specification

**Document ID:** LOT-AFFILIATE-SEC-ACC-001 | **Version:** 0.1.0 | **Status:** Proposed; not implementation or security approval | **Date:** 2026-11-27

## 1. Purpose and boundary

This specification converts LOT-AFFILIATE-SEC-001 findings into testable requirements for a future isolated Affiliate runtime slice. It does not select an identity provider, token format, database, queue, KMS, partner, jurisdiction, retention period or numeric quota.

The only permitted proof target is a synthetic, non-customer event: authenticate it, bind it to a trusted tenant installation, durably accept it, deduplicate it and evaluate it under an explicit domain policy. A balanced commission journal is outside ingress and may be considered only after separate approval. No real player, payment, wallet credit, payout or partner formula is implied.

Ingress may create an immutable receipt and durable work item. It MUST NOT mutate Wallet, Ledger, Payment, Settlement or Payout. A separately authorized commission-domain command is the only possible route to a future economic effect.

## 2. Principal and authorization matrix

| Principal | Permitted surface | Required binding | Forbidden |
|---|---|---|---|
| Platform operator | Privileged control plane | Strong human auth, explicit privileged role, reason, time-bounded elevation, audit | Partner machine credential reuse; implicit tenant-wide access |
| Tenant administrator | Tenant-scoped program and membership management | Subject + active membership + capability + resource scope | Cross-tenant access; editing immutable financial history |
| Tenant operator/support | Explicitly delegated tenant resources | Membership + narrow capability + purpose; read/write separation | Platform-wide access; unapproved commission-policy changes |
| Affiliate/agent | Own profile, permitted referral resources and own statements | Subject-to-affiliate membership + tenant/product + ownership | Other affiliates' data; attribution or ledger mutation |
| Partner integration client | Event ingress only | Machine identity + active installation + server-side tenant/product/environment binding + allowlist | Management API; tenant selection; financial mutation |
| Background worker | Durable jobs only | Workload identity + receipt/job binding + policy re-check | Trusting tenant IDs from payload; arbitrary direct commands |

Authorization MUST be checked server-side for every operation and resource. Authentication is not authorization. Opaque IDs, path parameters, custom scope declarations and payload fields never grant authority. The human role-to-capability matrix and privileged-access process remain owner decisions.

Machine ingress requires a valid credential, approved issuer/audience/client binding, active installation, trusted tenant/product/environment binding, registered source namespace, allowed event/schema and quota policy. Do not assume JWT, OAuth issuer, mTLS or DPoP before the platform identity decision.

## 3. Trusted ingress flow

1. Resolve credential to principal; validate applicable issuer, audience, expiry, not-before, client binding and revocation.
2. Resolve installation from server-side credential binding; derive tenant, product and environment from that record.
3. Enforce request byte, parser, rate and concurrency guards before expensive work.
4. Strictly parse JSON; reject duplicate object member names, invalid UTF-8, unsupported content types and malformed CloudEvents.
5. Validate CloudEvents context and registered extension names. Source is a namespace claim, not an authorization input.
6. Resolve dataschema only to a pre-registered immutable schema/version or pinned local artifact. Never dereference partner URLs.
7. Validate event type, schema version, unknown-field policy and installation-specific constraints.
8. Calculate the approved versioned fingerprint; preserve raw-byte digest separately.
9. In one database transaction, persist Inbox receipt and durable Job/outbox record under the unique event identity. Commit before 202 Accepted.
10. Worker claims the job with lease/fencing, re-checks installation/policy and records monotonic processing transitions. Delivery is at-least-once.
11. Any future commission qualification is a separate domain command. Financial posting requires a separate authorization, economic-effect key, balanced immutable journal and reconciliation.
12. Publish downstream events through transactional outbox; preserve receipt/job/qualification/journal correlation.

## 4. Identity, idempotency and fingerprint

Keep four identities distinct:
- Request identity: HTTP Idempotency-Key scoped to principal/installation, operation and request fingerprint.
- Source event identity: tenant_id + product_id + integration_installation_id + source + id.
- Processing identity: durable Inbox receipt ID and Job ID.
- Economic-effect identity: domain-owned commission effect key, independent of source event ID.

| Condition | Required result | Side effect |
|---|---|---|
| New valid event | 202 only after Inbox + Job/outbox commit | One receipt and one durable job |
| Same event identity and same fingerprint | Return original receipt/outcome | No second job/effect |
| Same event identity and different fingerprint | 409 integrity conflict; quarantine/audit | No processing or financial effect |
| Same request key and same request fingerprint | Replay original response per approved retention | No duplicate mutation |
| Same request key and different fingerprint | 409 | No mutation |
| Concurrent identical deliveries | Durable uniqueness/transaction selects one winner | Exactly one receipt/job |
| Worker retry after crash | Resume idempotently | No duplicate qualification/journal |
| Out-of-order event | Explicit ordering policy; otherwise hold/reject | Never silently reorder financial effects |

Proposed fingerprint profile: strict parse; reject duplicate JSON members; validate envelope/schema; canonicalize the complete accepted CloudEvents object with RFC 8785 JCS; SHA-256 the canonical UTF-8 bytes. Preserve a separate raw-byte digest. Version the profile, approve it in an ADR and publish cross-language vectors covering numbers and Unicode. Do not coerce types or normalize Unicode silently.

Enforce event uniqueness and fingerprint comparison with durable database constraints/transactions, not only cache or queue deduplication.

## 5. Event/schema registry

Each installation registration must version and bind tenant/product/environment, credential lifecycle, allowed source namespaces, event types, extension names/types, immutable schema IDs/versions, unknown-field policy, ordering policy, payload classification/retention, quota profile, effective date and approving actor.

Unknown source, event type, extension, schema ID or schema version fails closed. Schema resolution is local/registry-backed and immutable per version. Never follow redirects, resolve DNS or fetch arbitrary URLs from dataschema, $ref, attachment links or payload content. Schema changes require compatibility review, explicit registration, fixture updates and approval. No best-effort fallback may turn unknown data into financial facts.

## 6. Resource protection

No numeric limits are approved here. Before implementation, owners must define and load-test ceilings for raw/decompressed bytes; JSON depth/nodes/member count; string/array lengths; extension count/attribute length; parse/validation time; concurrency by credential/installation/tenant/global; rate/burst; queue depth/retry age/count/dead-letter capacity; response page/byte budget; and tenant storage/raw-payload retention.

Enforce limits at the earliest layer, return bounded stable errors, and ensure installation quotas cannot exceed global hard ceilings. Test N and N+1 boundaries, adversarial bursts and backpressure. Numeric values require product, security and operations approval, not guesses.

## 7. Persistence and worker invariants

- Database-enforced unique event identity.
- Inbox receipt and durable Job/outbox commit atomically; no 202 before commit.
- Failed transaction leaves neither accepted receipt nor runnable job.
- Lease/fencing prevents stale workers overwriting newer state.
- Monotonic, auditable transitions; retries preserve failure evidence.
- Queue is transport, not source of truth; durable database record is authoritative.
- Trusted tenant/product context comes from receipt, never event body.
- Financial posting, if later approved, is a separate idempotent command with balanced debit/credit, immutable journal and reconciliation references.
- Replay/reprocess requires explicit permission, reason, scope and audit; it cannot bypass uniqueness or create a second economic effect.

## 8. Privacy and audit

Before runtime, approve data classification/purpose, minimization, encryption, key ownership/rotation, retention/deletion, legal hold, raw-payload access, backup/restore and audit retention.

Raw partner payloads MUST NOT appear in ordinary logs, traces, metrics, exception text or support exports. Protect raw payload and digests separately. Privileged/break-glass access requires reason, time-bounded authorization and immutable audit. Redact tokens, secrets, personal data and partner-sensitive fields. Decide whether hashes survive payload deletion and assess re-identification risk.

Audit credential lifecycle; installation changes; membership/permission changes; accepted/rejected/conflicted/quarantined events; replay; schema/allowlist changes; policy version; worker lease/retry/dead-letter; commission qualification; and any separately authorized journal reference.

## 9. Required runtime acceptance matrix

| ID | Scenario | Expected assertion |
|---|---|---|
| AUTH-01 | Missing, invalid, expired or revoked machine credential | Reject before receipt creation |
| AUTH-02 | Wrong issuer/audience/client binding | Reject; no installation leakage |
| AUTH-03 | Disabled installation or revoked old credential | Reject after approved revocation boundary |
| TEN-01 | Tenant A credential submits Tenant B identifiers | Ignore/reject untrusted claims; never bind to B |
| TEN-02 | Tenant A principal accesses Tenant B resource ID | Deny without existence disclosure |
| TEN-03 | Membership revoked during active session | Subsequent request denied within approved consistency bound |
| SCOPE-01 | Principal lacks operation capability | Deny; no mutation |
| SCOPE-02 | Every secured operation has server-enforced capability mapping | Contract/runtime mapping test passes |
| PROP-01 | Server-owned or unknown request properties | No mass assignment |
| EVT-01 | Unknown source/type/extension/schema | Fail closed; no job |
| EVT-02 | dataschema points to loopback/private/link-local/redirect URL | Zero network requests; reject |
| PARSE-01 | Duplicate JSON member, invalid UTF-8 or excessive depth | Reject before persistence |
| IDEM-01 | Sequential same identity and fingerprint | Original receipt; one job |
| IDEM-02 | Concurrent same identity and fingerprint | One receipt/job under race |
| IDEM-03 | Same identity, different fingerprint | 409 + quarantine/audit; zero business effect |
| IDEM-04 | Same request key, different request fingerprint | 409; no mutation |
| TX-01 | Inject failure between Inbox and Job writes | Rollback; no 202 |
| TX-02 | Commit succeeds but response is lost; client retries | Original receipt; no duplicate job |
| WORK-01 | Worker crashes before/after domain command | Retry safe; at most one domain effect |
| WORK-02 | Stale worker completes after lease expiry | Fencing blocks stale overwrite |
| ORDER-01 | Duplicate, delayed and out-of-order events | Explicit policy; no silent financial reorder |
| LIMIT-01 | Approved N and N+1 size/depth/array/rate boundaries | N valid; N+1 bounded rejection |
| LIMIT-02 | One tenant exceeds quota while global capacity remains | Throttle tenant without harming others |
| LIMIT-03 | Global hard ceiling reached | Global backpressure protects service |
| AUDIT-01 | Replay, quarantine release or allowlist change | Actor/reason/policy/correlation recorded |
| PRIV-01 | Synthetic secret/PII appears in logs/traces/errors | Automated redaction assertions pass |
| FIN-01 | Ingress event accepted | No Wallet/Ledger/Payment/Payout write path invoked |
| FIN-02 | Separately approved commission command replayed | One balanced immutable journal per effect key |

Use synthetic identities/data. Record fixture version, environment, commit, tool versions, run IDs and artifacts. Passing this matrix is necessary but not sufficient for production authorization.

## 10. Release gates and evidence

**Gate A — design, before implementation:** approve principal model, capability matrix, issuer/audience/client binding, credential lifecycle, strict parser, fingerprint ADR/vectors, event registry ownership, resource ceilings, data lifecycle and audit policy.

**Gate B — isolated runtime proof, before partner sandbox:** implement synthetic ingress only. Demonstrate tenant/object authorization, no-fetch schema resolution, atomic Inbox/Job, duplicate concurrency, conflict quarantine, worker recovery, quotas and zero financial side effects. Independently review high-risk controls.

**Gate C — partner sandbox, before adapter certification:** obtain actual partner API/event documentation, authorized sandbox, source namespace, schema examples, retry/order semantics, credential profile and written permission. Map approved events only; infer no partner formula or customer status.

**Gate D — production:** require legal/jurisdiction and operating-model approval; security assessment/penetration test; SLO/alert/incident ownership; key rotation/revocation evidence; backup/restore/DR; data-protection sign-off; partner certification; finance-approved commission policy/reconciliation; and explicit owner release approval.

Evidence labels: PASS = completed observed test/workflow on exact commit; FAIL = observed failure; PENDING = execution incomplete; NOT TESTED = no evidence; BLOCKED = prerequisite/permission prevents execution. A proposal, schema CI, mock or design review is never runtime PASS or production approval.

## 11. Open decisions

Identity provider and token profile; human capability matrix; installation ownership and credential SLA; event/schema registry ownership; fingerprint ADR; numeric quotas/retry/order; payload minimization/retention/encryption/deletion; audit catalog; commission qualification/economic-effect identity; partner documentation/sandbox/jurisdiction/authorization.

## 12. References

LOT-AFFILIATE-WIRE-001; LOT-AFFILIATE-SEC-001; LOT-API-PLATFORM-001; LOT-EVENT-001; RFC 9700; RFC 8785 (Informational); CloudEvents 1.0.2 JSON Event Format; OWASP API Security Top 10 (2023).

This is a proposed acceptance specification, not implementation, partner certification, legal opinion, penetration test or production security approval.