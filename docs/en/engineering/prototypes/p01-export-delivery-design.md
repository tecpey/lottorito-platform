# P-01 Secure Export Delivery — Design Study

**Document ID:** LOT-PROT-P01-DELIVERY-001 | **Version:** 0.1.0 | **Status:** Research-backed proposal; no delivery architecture or provider approved

## 1. Decision context

PR #44 proves a synthetic authorization primitive: a tenant- and subject-bound, expiring one-time grant can be issued and atomically redeemed. It deliberately does not stream bytes or contact object storage.

The next experiment must solve the gap between successful grant redemption and reliable file delivery. A one-time grant must not be confused with a provider-signed URL that may itself be reusable.

## 2. Evidence from primary sources

- Amazon S3 documents that a presigned URL can be used multiple times until it expires. It is a bearer capability: anyone possessing it can perform the signed operation. S3 checks expiry when a request starts; an already-started transfer can continue after expiry, while a restarted request can fail. Temporary credential expiry or revocation can shorten URL validity. Source: [AWS — Download and upload objects with presigned URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html).
- OWASP recommends Content-Disposition: attachment, application/octet-stream for unknown/binary content and X-Content-Type-Options: nosniff for secure downloads. Source: [OWASP HTTP Headers Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html).
- OWASP path-traversal guidance recommends avoiding user input in filesystem paths and mapping server-generated identifiers to stored paths. Source: [OWASP Path Traversal Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Path_Traversal_Prevention_Cheat_Sheet.html).
- Node.js 26 stream documentation describes pipeline as the mechanism for handling backpressure and stream errors, with cancellation support through AbortSignal. Source: [Node.js v26 Stream API](https://nodejs.org/api/stream.html).

## 3. Delivery options

| Option | Security properties | Operational trade-off | Current recommendation |
|---|---|---|---|
| Application-mediated streaming proxy | Each request can re-check subject, tenant, membership, session state and export status; no provider URL leaves the server | Application bears egress, connection and streaming load; must implement backpressure, cancellation, Range and retry behavior | Preferred candidate for sensitive affiliate/financial exports |
| Short-lived provider-signed URL | Storage traffic bypasses application; provider can enforce object-level authorization and short expiry | URL is a reusable bearer capability until expiry; revocation is provider/credential-policy dependent; URL/query-string leakage risk | Conditional alternative for large files only after provider guardrails are proven |
| Public or semi-public object URL | Weak/no per-request authorization | Simple but incompatible with private tenant export guarantees | Rejected |

**Important:** A one-time grant followed by a presigned URL is not end-to-end one-time access. The grant is single-use; the resulting URL can still be replayed until provider expiry. This distinction must appear in product and security documentation.

## 4. Proposed experiment direction

Prototype a provider-neutral application-mediated streaming adapter first, using a synthetic in-memory object source. Do not integrate a real storage provider until the adapter contract and threat model pass.

### 4.1 Session lifecycle

Create a separate download_sessions record when the one-time grant is redeemed:

created → active → completed

Exceptional states:

- failed_retryable: bounded retry is allowed while the session lease and authorization remain valid
- revoked: membership, export status or an administrative control invalidated the session
- expired: session TTL elapsed
- failed_terminal: retry budget exhausted or integrity validation failed

The grant remains consumed once a session is created. The session is a distinct, short-lived delivery capability bound to tenant_id, subject_id and export_id; it must not become a reusable tenant-wide URL.

### 4.2 Required controls

1. Revalidate tenant membership, subject binding, export readiness and session status before each transfer or Range request.
2. Store only a hash of the session secret. Never put grant/session secrets in query strings, logs, analytics, referrers or error messages.
3. Keep buckets/containers private. The storage adapter receives a server-derived object key from the export record; clients never submit object keys or filesystem paths.
4. Define a provider-neutral openReadStream contract returning a readable stream plus trusted metadata: size, content type, object version/ETag and checksum where available.
5. Use Node.js stream.pipeline with cancellation tied to client disconnect/request abort. Respect backpressure; never buffer the entire export in application memory.
6. Define Range semantics explicitly: validate byte ranges, return correct 206/416 and Content-Range, pin the object version, and prevent a resumed transfer from silently reading a different object.
7. Use safe response headers: Content-Disposition: attachment with RFC 6266-safe filename handling, a verified content type or application/octet-stream, X-Content-Type-Options: nosniff, and private/no-store caching.
8. Record append-only events for session creation, transfer start, completion, abort, retry, revocation and integrity failure. Do not record raw tokens, signed URLs or sensitive object keys.
9. Verify object size and trusted checksum metadata. Do not assume an S3 ETag is a SHA-256 checksum, especially for multipart objects.
10. Bound session TTL, retry count, concurrent transfers per subject/tenant, maximum object size, stream duration and total tenant egress.

### 4.3 Retry and idempotency requirement

The design must explicitly handle a lost HTTP response after grant redemption and client disconnect during transfer. The initial prototype should compare one session with bounded retry/Range resume against a new authenticated session-credential rotation flow tied to an idempotency key.

Do not silently re-enable the consumed grant. A retry must remain bound to the same authenticated subject and tenant, and must not create parallel unlimited downloads.

## 5. Acceptance scenarios for the next experiment

| ID | Scenario | Expected result |
|---|---|---|
| P01-DELIVERY-01 | Valid session starts a stream | Only the bound export is streamed |
| P01-DELIVERY-02 | Subject or tenant differs | Request is denied before object access |
| P01-DELIVERY-03 | Membership/export/session revoked after session creation | Next transfer/Range request is denied |
| P01-DELIVERY-04 | Client disconnects mid-stream | Upstream stream is cancelled and resources released |
| P01-DELIVERY-05 | Slow client | Backpressure bounds memory; no whole-file buffering |
| P01-DELIVERY-06 | Valid Range resume | Same immutable object version and correct byte range are returned |
| P01-DELIVERY-07 | Invalid or unsatisfiable Range | Deterministic 416 or documented policy; no cross-object read |
| P01-DELIVERY-08 | Retry after transient failure | Only bounded same-session retry is allowed |
| P01-DELIVERY-09 | Session completed or retry budget exhausted | Replay is denied |
| P01-DELIVERY-10 | Unsafe filename or MIME type | Safe attachment headers and nosniff are enforced |
| P01-DELIVERY-11 | Storage object missing or checksum mismatch | No successful completion is recorded; integrity failure is audited |
| P01-DELIVERY-12 | Provider-signed URL is enabled in an alternate adapter | Replay-until-expiry is explicitly demonstrated; it is never described as one-time |

## 6. Open decisions

- Maximum export size, stream duration, Range support and retry budget.
- Whether download policies differ for B2B operators, Agents and B2C customers.
- Data residency, encryption-at-rest, malware scanning and retention/deletion requirements.
- Whether the first real provider supports trustworthy checksum metadata, object versioning and revocation controls.
- Egress cost and capacity budget for proxy streaming versus signed URLs.
- Audit retention, support access and incident-response requirements.

## 7. Scope boundary

This document is a design study only. It does not implement an HTTP endpoint, storage adapter, session table, signed URL, streaming worker or provider integration. No storage provider, cloud account, bucket policy, production key or delivery architecture is approved.
