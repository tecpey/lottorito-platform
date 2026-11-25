# P-03D — Provider Inbox to Product-Scoped Ledger Posting and Outbox

**Document ID:** LOT-PROT-P03D-001 | **Version:** 0.1.0 | **Status:** Synthetic integration prototype; CI validation pending | **Review date:** 2026-11-25

## Purpose

P-03D closes the remaining inbound integration gap in P-03 by connecting a signed provider event to the latest P-02 posting boundary and the P-03C transactional outbox bridge. It is built on the current P-02/P-03C ancestry, not the older P-02 branch used by PR #41.

The experiment must prove that durable provider acceptance, one idempotent financial effect, immutable journal/lines/outbox, and initial P-03C delivery state are committed or rolled back together.

## Scope

- Trusted server-side installation configuration binds provider, tenant and product. Request payload fields never select tenant, product or ledger accounts.
- Database session identity maps to both tenant and product. RLS uses `session_user`-derived tenant/product functions; no caller-controlled custom GUC is trusted.
- HMAC-SHA-256 verifies exact raw request bytes, signed event ID and timestamp, constant-time comparison, bounded freshness and current/previous key rotation. This is a synthetic Standard Webhooks-style adapter, not a universal provider protocol.
- Provider event ID plus exact raw-body SHA-256 defines inbox duplicate/conflict behavior. Same ID/same hash is idempotent; same ID/different hash creates immutable conflict evidence and never overwrites the accepted event.
- The simulated HTTP 202 is returned only after the tenant/product-scoped inbox transaction commits.
- Provider event mapping is trusted configuration. Provider payload cannot supply account IDs, debit/credit direction or posting policy.
- A bounded worker lease and fencing token protect concurrent processing and stale workers.
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

Exact validated PR head: `40d002a2af5875a6ead178604b90dc92aa678dc5`.

- P-02 Ledger Posting: [run 114](https://github.com/tecpey/lottorito-platform/actions/runs/45607187120) — 25 passed, 0 failed, 0 skipped.
- P-03C/P-03D combined integration: [run 31](https://github.com/tecpey/lottorito-platform/actions/runs/45607186885) — P-03C 15 passed and P-03D 19 passed; 34 total, 0 failed, 0 skipped. All setup, test, and cleanup steps succeeded.
- Documentation Governance: [run 702](https://github.com/tecpey/lottorito-platform/actions/runs/45607186745) — passed.

This verifies the synthetic acceptance matrix on the cited branch head only. PR #61 remains Draft/open and stacked on PR #60; no merge, production provider integration, production database migration, technology approval or deployment is implied.



## Downstream stack handoff — 2026-11-25

P-04 PR #51 was a sibling of P-03C/P-03D, not a descendant. Its P-04-only files are being carried onto branch `spike/p04-schema-evolution-p03d`, based on P-03D PR #61's docs-synchronized head `11f2069b537d4cf74175fd7b628a331650c45f52`. P-04 is independent of the P-02/P-03 schema, but the new branch must re-run P-02, P-03C/P-03D and P-04 workflows together before its acceptance. PR #51 remains untouched as the original review source; no merge or retarget is authorized.


## P-04 downstream regression result — 2026-11-25

The P-04 continuation is now stacked on this P-03D branch through PR #62. On PR #62 code head `dca0762678ed45da122ba109276c54ce61ac0846`, the combined P-03C/P-03D run [45608274098](https://github.com/tecpey/lottorito-platform/actions/runs/45608274098) passed 15 P-03C and 19 P-03D tests (34 total; 0 failed, 0 skipped). P-02 run [45608274029](https://github.com/tecpey/lottorito-platform/actions/runs/45608274029) passed 25 tests, P-04 run [45608274118](https://github.com/tecpey/lottorito-platform/actions/runs/45608274118) passed 7, and Documentation Governance [45608274060](https://github.com/tecpey/lottorito-platform/actions/runs/45608274060) passed. This confirms regression on the new branch; it does not upgrade the synthetic prototype to production readiness.


## P-05A downstream regression gate — 2026-11-25

P-05A is being replayed onto reconciled P-04 PR #62, which descends from this P-03D branch. Re-run the combined P-03C/P-03D 34-test workflow on the P-05A replacement head to prove the ledger/outbox/provider bridge remains present. P-05A's synthetic database recovery fixture is separate and does not replace provider event or ledger posting acceptance.


## P-05A reconciled-stack regression result — 2026-11-25

The combined P-03C/P-03D regression passed on P-05A replacement code head 76650b0c799e2f2a5b2f3ae4831bb55d3a3811a6: [run 45609220468](https://github.com/tecpey/lottorito-platform/actions/runs/45609220468), P-03C 15/15 and P-03D 19/19, 0 failures and 0 skips. P-05A does not replace or modify the provider-to-ledger integration.


## P-05B downstream regression gate — 2026-11-25

P-05B event replay is a synthetic recovery projection, not a replacement for P-03D provider inbox or P-03C delivery state. Re-run the 34-test P-03C/P-03D suite on the P-05B replacement head to preserve the provider-to-ledger bridge and tenant/product isolation.
