# P-03D — Provider Inbox to Product-Scoped Ledger Posting and Outbox

**Document ID:** LOT-PROT-P03D-001 | **Version:** 0.3.0 | **Status:** Synthetic integration prototype; 25 P-03D and 15 P-03C tests passed; no production claim | **Review date:** 2026-11-25

## Purpose

P-03D closes the remaining inbound integration gap in P-03 by connecting a signed provider event to the latest P-02 posting boundary and the P-03C transactional outbox bridge. It is built on the current P-02/P-03C ancestry, not the older P-02 branch used by PR #41.

The experiment must prove that durable provider acceptance, one idempotent financial effect, immutable journal/lines/outbox, and initial P-03C delivery state are committed or rolled back together.

## Scope

- Trusted server-side installation configuration binds provider, tenant and product. Request payload fields never select tenant, product or ledger accounts.
- Database session identity maps to both tenant and product. RLS uses `session_user`-derived tenant/product functions; no caller-controlled custom GUC is trusted.
- HMAC-SHA-256 verifies exact raw request bytes, signed event ID and timestamp, constant-time comparison, canonical Base64, bounded freshness, bounded header/body sizes and current/previous key rotation. This is a synthetic Standard Webhooks-style adapter, not a universal provider protocol.
- Provider event ID plus exact raw-body SHA-256 defines inbox duplicate/conflict behavior. Same ID/same hash is idempotent; same ID/different hash creates immutable conflict evidence and never overwrites the accepted event.
- The simulated HTTP 202 is returned only after the tenant/product-scoped inbox transaction commits.
- Provider event mapping is trusted configuration. Provider payload cannot supply account IDs, debit/credit direction or posting policy.
- A bounded worker lease and fencing token protect concurrent processing and stale workers; database constraints keep processed markers and attempt counts internally consistent.
- Worker processing calls P-02 `post_journal` on the same PostgreSQL connection/transaction that marks the inbox event processed. P-02 inserts the immutable journal, lines and ledger outbox; the P-03C trigger creates delivery state in that same transaction.
- A pre-commit failure rolls back inbox completion, journal, lines, outbox and delivery state. Retry/dead-letter/quarantine state is recorded in a separate fenced transaction.
- Product identity is recorded and enforced in P-02 ledger rows and P-03C delivery/consumer rows. A synthetic second product role proves that one tenant's Affiliate & Agent and Lottery data are not visible to each other.
- Reconciliation compares independently seeded expected provider events to inbox status, journal, outbox and delivery state.

## Transaction boundary

1. Verify signature and freshness against exact raw bytes.
2. Resolve trusted installation and verify the database role maps to the same tenant/product.
3. Commit the durable inbox record; only then return the simulated 202.
4. Claim an inbox row with `FOR UPDATE SKIP LOCKED`, a bounded lease and a fresh fencing token.
5. In one processing transaction: validate the claim, map the canonical event using trusted account mapping, call P-02 `post_journal`, mark the inbox processed and commit.
6. P-03C's after-insert trigger creates delivery state from the immutable ledger outbox inside that same transaction.
7. A failed transaction is rolled back in full; the still-claimed inbox row is moved to retry/dead-letter/quarantine only after rollback.

The delivery contract remains at-least-once. Idempotent financial-effect identity and consumer inbox semantics protect effects; the experiment does not claim exactly-once network delivery.

## Product and identity boundary

P-02's synthetic role map now associates each database LOGIN role with a tenant and product. The ledger's product field is checked by RLS and the posting function, and the selected account must belong to the current product. P-03C's delivery state and consumer inbox/effects carry the same product dimension.

For conservative compatibility, some existing P-02 uniqueness constraints remain tenant-wide rather than product-local. This is stricter (it can reject an otherwise independent cross-product identifier reuse) and does not permit cross-product access. Composite product-scoped key semantics remain an explicit follow-up review item; this prototype does not approve a production schema.

## Acceptance matrix

| ID | Scenario | Expected result |
|---|---|---|
| P03D-01 | Valid raw-body signature | Durable inbox commit precedes simulated 202 |
| P03D-02 | Raw-body tampering | Rejected; no inbox row |
| P03D-03 | Stale/future timestamp | Rejected |
| P03D-04 | Current/previous key rotation | Only configured keys accepted |
| P03D-05 | Same event ID and same body | Idempotent duplicate |
| P03D-06 | Same event ID and changed body | Immutable conflict; original preserved |
| P03D-07 | Caller-supplied tenant/product | Ignored; trusted installation and DB identity win |
| P03D-08 | Tenant/product RLS | No cross-tenant or cross-product inbox visibility |
| P03D-09 | Successful processing | One journal, one outbox event, one delivery-state row |
| P03D-10 | Failure before commit | All posting/outbox effects roll back; inbox becomes retryable |
| P03D-11 | Duplicate after processing | No second journal or outbox event |
| P03D-12 | Expired lease | New token reclaims; stale worker is fenced |
| P03D-13 | Retry exhaustion | Dead-letter state |
| P03D-14 | Unmapped provider event | Quarantined; no posting |
| P03D-15 | Product-specific account mapping | Lottery posting cannot use Affiliate & Agent accounts |
| P03D-16 | Direct ledger mutation | Runtime role denied |
| P03D-17 | Reconciliation | Missing events are surfaced; complete path clears the exception |
| P03D-18 | Unmapped database identity | Posting fails closed |
| P03D-19 | Partial processed state or attempt-count overflow | Rejected by database constraints |

## CI and reproduction

The dedicated workflow uses PostgreSQL 18.7, Node.js 26.13.0, a committed npm lockfile and SHA-pinned GitHub Actions. It also re-runs the P-02 and P-03C workflows because their schema/functions are extended by this integration branch.

Local execution must use only the disposable database in `compose.yaml`. The setup script applies the P-02 schema, P-03C integration SQL and P-03D inbox schema in order. It is destructive to its target fixture; never point it at shared, staging or production databases.

## Explicit limitations

- Synthetic identities, signing keys, provider events, account mappings and amounts only.
- No real HTTP server, API gateway, WAF, provider contract, partner sandbox, external network transport, broker, KMS/secrets manager, mTLS, endpoint SSRF controls, or production key rotation.
- No real commission, NGR, affiliate hierarchy, lottery ticket, payout, custody, FX, revenue-recognition or statutory accounting rule.
- P-02 product fields and role mapping are experimental. Existing tenant-wide unique keys remain conservative; product-local composite identity and physical migration policy need separate review.
- No load, chaos, failover, PITR, disaster recovery, provider statement reconciliation or production readiness is claimed.
- P-03D passing CI would prove only these synthetic scenarios. It does not complete all P-03 acceptance or approve a provider, database, stack, merge or deployment.

## Research basis

- OWASP — [Webhook Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Webhook_Security_Cheat_Sheet.html).
- Standard Webhooks — [Webhook signature specification](https://github.com/standard-webhooks/standard-webhooks/blob/main/spec/standard-webhooks.md).
- IETF — [RFC 9421 HTTP Message Signatures](https://www.rfc-editor.org/rfc/rfc9421.html); this prototype does not claim RFC 9421 conformance.
- CloudEvents — [Core specification](https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md).
- AWS Prescriptive Guidance — [Transactional outbox pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html).
- PostgreSQL 18 — [Row security policies](https://www.postgresql.org/docs/18/ddl-rowsecurity.html) and [SELECT locking clause](https://www.postgresql.org/docs/18/sql-select.html).

## Stack and authority

This is a Draft experiment branch based on P-03C PR #60 head `32b34f4c7c67b12874cdf6a14a2788d9a2f4c6dc`. PR #41 is an older provider-delivery fixture based on an older P-02 branch; its raw-body verification and duplicate/conflict patterns are research inputs, not code to cherry-pick without the current session-identity and product-scope model. No PR is merged and no production deployment or destructive operation is authorized.


## CI failure analysis and corrective pass — 2026-11-25

The first combined CI attempt exposed three setup/contract issues before P-03D's dedicated test file could run:

1. P-02's security assertion queried the SECURITY DEFINER identity helper rather than the private mapping table. The assertion now tests direct SELECT denial against `private.tenant_role_map`, which is the actual protected object; the helper remains available to RLS policies and trusted SECURITY DEFINER boundaries.
2. P-03C created the composite unique index on `ledger_outbox(tenant_id, product_id, event_id)` after declaring foreign keys that reference it. The index is now created before the referencing tables.
3. The P-03D schema had a malformed provider-event identifier CHECK and a duplicated SQL tail. The schema is reduced to one complete definition, the identifier constraint is syntactically complete, and schema CREATE privileges for the no-login provider owner are granted only during ownership setup and revoked immediately afterward.

The plain-text synthetic signing-secret path now enforces the same minimum 128-bit length as Buffer and `whsec_` inputs; a regression test covers undersized secrets.

**Validation status:** synthetic acceptance is verified on the exact head and CI runs recorded below.

## Verified synthetic CI result — 2026-11-25

Exact current validated PR head: `14d69ec5be1a9285049c1f88529f375782f2de51`.

- P-02 Ledger Posting: [run 135](https://github.com/tecpey/lottorito-platform/actions/runs/45619908420) — 25 passed, 0 failed, 0 skipped.
- P-03C/P-03D combined integration: [run 57](https://github.com/tecpey/lottorito-platform/actions/runs/45619908381) — P-03C 15 passed and P-03D 22 passed; 37 total, 0 failed, 0 skipped. All setup, test, and cleanup steps succeeded.
- Documentation Governance: [run 725](https://github.com/tecpey/lottorito-platform/actions/runs/45619908378) — passed.

This verifies the synthetic acceptance matrix on the cited branch head only. PR #61 remains Draft/open and stacked on PR #60; no merge, production provider integration, production database migration, technology approval or deployment is implied.

## P-09F concurrency and cross-scope regression (2026-11-25)

On candidate head 2b393cc8c41226a20333f34559ac6952883901a3, P-03C/P-03D workflow [45637659485](https://github.com/tecpey/lottorito-platform/actions/runs/45637659485) passed: P-03C **15/15**, P-03D **25/25**. Three added tests run the real Node.js provider worker against PostgreSQL 18.7: one-winner concurrent inbox claim and process race; stale/current lease-token fencing under concurrent processing; and same provider event ID/source-event UUID processed independently across Affiliate, Lottery and a second tenant. Each scope receives exactly one journal, immutable outbox event and delivery-state row, with zero reconciliation exceptions. Synthetic evidence only; aggregate ordering and Node-worker replay on the P-09E restored cluster remain open.


### P-09H — Canonical contract enforcement (2026-11-25)

The signed ingress path now builds its canonical CloudEvent from the trusted installation and approved event mapping. Tenant/product scope is not accepted from provider payload fields. The provider event ID remains the CloudEvents `id`; a distinct UUID `sourceeventid` is generated and persisted in both the canonical envelope and inbox row, with a fresh W3C trace context. Unknown schema mappings and non-RFC3339 timestamps are rejected before inbox persistence. The worker revalidates the stored envelope and its tenant/product/source-event identity before posting; a tampered scope is quarantined before journal/outbox effects. This is synthetic integration evidence only; final P-03D acceptance depends on CI for the final head.


P-09H ingress regressions now also prove that provider-supplied `tenantid`, `scope`, `sourceeventid`, `traceparent`, `dataschema` and `schemaversion` cannot override trusted metadata, and that the same provider event ID can be accepted independently through signed ingress in Affiliate/Tenant-A, Lottery/Tenant-A and Affiliate/Tenant-B. The three rows receive distinct canonical source-event UUIDs. The P-03C/P-03D workflow on the code-bearing head reported 15/15 and 35/35 tests passing, respectively; the P-03D count includes seven direct Node.js contract-conformance tests.


The P-03D test runner also includes a direct Node.js conformance suite for the shared P-09 validator. It exercises valid and adversarial envelope cases independently of the PostgreSQL-backed ingress tests, so a future worker change cannot silently bypass the validator's core rules.

## P-09K — Product-qualified account and outbox references (2026-11-26)

P-03D deliberately reuses the same account UUIDs for the same tenant in Affiliate & Agent and Lottery. P-02's composite key `(tenant_id, product_id, account_id)` keeps these identifiers independent; posting and account foreign keys preserve product scope end to end. The Lottery provider integration must post with those reused identifiers without seeing or mutating Affiliate account rows. P-03D removes a redundant journal unique index already guaranteed by P-02's composite primary key and rejects legacy `shared` product tokens in provider inbox/conflict/expectation state. CI is pending exact-head validation.
