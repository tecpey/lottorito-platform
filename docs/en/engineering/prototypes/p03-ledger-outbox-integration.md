# P-03C — End-to-End Ledger Outbox and Tenant-Scoped Delivery

**Document ID:** LOT-PROT-P03C-001 | **Version:** 0.1.0 | **Status:** Synthetic integration slice; CI evidence tracked on Draft PR #60; no production transport or operations approved

## 1. Purpose and boundary

P-02 atomically posts an immutable double-entry journal and an immutable row in public.ledger_outbox. P-03 separately proves tenant-scoped leasing, retries, stale-worker fencing and idempotent consumer effects. P-03C joins those two proven fixture boundaries in one disposable PostgreSQL database.

The key invariant is that P-02's ledger_outbox is the **single immutable source of truth for the event**. P-03C does not create a second source-outbox table or copy event payloads into another source table. A database trigger inserts the corresponding mutable delivery-state row in the same transaction that inserts the ledger outbox event. Delivery state and consumer receipts remain separate, mutable/append-only operational records with their own tenant-scoped RLS.

This is a synthetic integration experiment, not a production event platform. It does not implement an external broker, provider HTTP endpoint, real consumer service, CDC, production retry policy or exactly-once delivery.

## 2. Design and ownership

- **Financial source:** P-02 owns journal posting, effect identity, immutable journal lines and immutable ledger_outbox rows.
- **Delivery state:** P-03C owns outbox_delivery_state, keyed by (tenant_id, product_id, event_id), with lease, attempt, retry, published and dead-letter state.
- **Atomic bridge:** an AFTER INSERT trigger on ledger_outbox inserts the initial pending delivery-state row in the same database transaction. If that trigger or its RLS check fails, the financial posting transaction fails as a whole.
- **Tenant identity:** reuse P-02's private.tenant_role_map and private.current_tenant_id(), deriving tenant scope from PostgreSQL session_user. No caller-supplied tenant ID or second role map is introduced.
- **Execution authority:** outbox_executor is NOLOGIN, non-superuser and NOBYPASSRLS. Its SECURITY DEFINER functions have fixed search paths and narrow grants. The trigger checks that the source row tenant matches the database-session tenant.
- **Delivery:** claim uses FOR UPDATE SKIP LOCKED, bounded batches/leases, a fresh token and an attempt counter. Ack/nack require the current unexpired token. Retry exhaustion becomes dead.
- **Consumer:** consumer_inbox and consumer_effects use the stable source event ID and tenant scope. Inbox receipt and synthetic effect are inserted in one database function transaction; duplicate receipt returns false and does not repeat the effect.
- **At-least-once semantics:** publish and database acknowledgement are not atomic. A crash after publish but before ack may redeliver. The consumer's stable event ID deduplication prevents a second synthetic database effect; no exactly-once network delivery is claimed.

## 3. Executable fixture

- prototypes/p03-ledger-outbox-integration/db/integration.sql: P-03C delivery state, consumer tables, RLS, trigger and security-definer functions. It references P-02 ledger_outbox directly using the full (tenant_id, product_id, event_id) identity.
- scripts/setup-db.js: applies P-02's schema, then P-03C integration SQL, in a disposable database; verifies there is one source outbox and six seeded accounts.
- src/relay.js: tenant-bound claim, ack, nack, consume and batch-delivery helpers.
- test/integration.test.js: 15 positive/adversarial end-to-end scenarios.
- compose.yaml: local PostgreSQL 18.7 fixture.
- package.json/package-lock.json: Node.js 26.13.x and pg 8.23.1 pinned.
- .github/workflows/p03-ledger-outbox-integration.yml: PostgreSQL 18.7 and Node.js 26.13.0 CI.

The P-02 schema and P-03C schema run together in one database. The original P-03 outbox fixture remains separately useful for its isolated delivery-state tests; this P-03C slice proves the previously missing connection to the actual P-02 ledger_outbox schema.

## 4. Acceptance criteria

| ID | Required result |
|---|---|
| P03C-01 | A successful P-02 post_journal call creates exactly one ledger_outbox row and exactly one pending delivery-state row. |
| P03C-02 | The source event payload preserves journal_id, effect_id and source_event_id from P-02. |
| P03C-03 | The delivery-state row is created by a trigger in the same transaction as the ledger_outbox insert. |
| P03C-04 | Rolling back the posting transaction removes journal, source event and delivery-state row together. |
| P03C-05 | Idempotent request replay returns the original journal and creates no duplicate source event or delivery row. |
| P03C-06 | A second request key for the same financial effect does not create a second ledger event. |
| P03C-07 | P-03C uses P-02 ledger_outbox as the only immutable source; no duplicate outbox_events table exists. |
| P03C-08 | Tenant A cannot claim, read or consume Tenant B's ledger event. |
| P03C-09 | Concurrent workers claim disjoint events; stale lease tokens cannot acknowledge a replacement lease. |
| P03C-10 | Retry exhaustion transitions the event to dead-letter state. |
| P03C-11 | Consumer inbox and synthetic effect are committed once under concurrent redelivery. |
| P03C-12 | Publish-before-ack crash simulation demonstrates at-least-once redelivery and one consumer effect. |
| P03C-13 | Tenant runtime identities cannot directly read or mutate ledger, delivery-state or consumer tables. |
| P03C-14 | Unmapped database identities and invalid claim/consumer parameters fail closed. |
| P03C-15 | The trigger rejects a source insert when the database session has no mapped tenant; no event or delivery row is committed. |

## 5. Reproduction

From the repository root:

~~~bash
cd prototypes/p03-ledger-outbox-integration
docker compose up -d --wait
export ADMIN_DATABASE_URL='postgres://postgres:p03c-admin-only-not-production@127.0.0.1:55435/lottorito_p03c'
export TENANT_A_DATABASE_URL='postgres://tenant_a_ledger_runtime:p02-tenant-a-not-for-production@127.0.0.1:55435/lottorito_p03c'
export TENANT_B_DATABASE_URL='postgres://tenant_b_ledger_runtime:p02-tenant-b-not-for-production@127.0.0.1:55435/lottorito_p03c'
npm ci --ignore-scripts --no-audit --no-fund
npm test
docker compose down -v
~~~

The setup script drops/recreates only P-02/P-03C fixture objects. Use only the disposable local database; never point it at shared, staging or production data.

## 6. Explicit limitations

- No real broker, provider, HTTP server, API gateway, CDC connector, queue service, external consumer or network delivery is used.
- P-03 provider webhook ingestion from PR #41 remains a separate synthetic slice; this experiment does not connect inbound provider callbacks to P-02 posting.
- P-03C uses the existing P-02 tenant runtime identities and role map; it does not prove a global cross-tenant relay or a production service identity model.
- The consumer effect is a synthetic database row, not a real projection, notification, payout, commission or external side effect.
- Delivery is at-least-once. The broker publish and PostgreSQL ack are not atomic; external consumers must deduplicate by stable event ID and commit inbox/effect atomically.
- Retry values, batch sizes and lease durations are fixture defaults, not provider SLAs or production policy.
- No load/chaos test, retention policy, key management, observability, failover, disaster recovery, legal review or production readiness is claimed.
- No commission formula, NGR rule, wallet balance, payout or cross-product settlement is introduced.
- Passing P-03C closes only the P-02 ledger-outbox to P-03 delivery-state integration gap in this synthetic fixture; it does not close all P-01/P-02/P-03 production gaps.

## 7. Research references

- PostgreSQL 18, [SELECT locking clause and SKIP LOCKED](https://www.postgresql.org/docs/18/sql-select.html).
- PostgreSQL 18, [Row-level security policies](https://www.postgresql.org/docs/18/ddl-rowsecurity.html).
- AWS Prescriptive Guidance, [Transactional outbox pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html).
- CloudEvents, [Core specification](https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md).

## 8. Completion gate

P-03C is complete only when the exact PR head has passing PostgreSQL 18.7/Node.js 26.13.0 integration tests and Documentation Governance, all positive and negative scenarios pass with zero skips, the bilingual pair is reviewed for semantic parity, and limitations remain explicit. Passing this experiment does not authorize merge, production deployment or technology selection.

## P-09K — Product-qualified outbox and delivery identity (2026-11-26)

P-02's outbox key is now `(tenant_id, product_id, event_id)`. P-03C delivery-state primary keys and foreign keys use that same complete tuple; the obsolete tenant-only FK and redundant unique index have been removed. Consumer inbox references use the product-qualified event key. Claim candidates carry product_id through the locked-row update, and expired-lease cleanup is explicitly product-scoped. Canonical product checks reject the legacy `shared` token.

The P-03C disposable integration now opens a distinct Lottery runtime session for the same tenant and asserts that Affiliate workers cannot claim or consume Lottery events and vice versa. Delivery receipts, effects and acknowledgements remain bound to the product identity. Validation is pending exact-head CI.
