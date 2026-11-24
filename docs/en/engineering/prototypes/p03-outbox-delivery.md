# P-03 Tenant-Scoped Transactional Outbox Delivery

**Document ID:** LOT-PROT-P03-001 | **Version:** 0.4.0 | **Status:** Synthetic prototype; 10 integration tests passed on head `a52e8c248e4a2dbc7e9e88eeb6f71b96ec3f8b02` (0 failed, 0 skipped); no production transport or operations approved

## Purpose and authority

P-03 tests the delivery boundary that follows P-02's atomic journal/outbox write. The source event is immutable; delivery state is mutable and separate. This experiment tests lease-based claiming, bounded retries, stale-worker fencing and consumer-side deduplication. It is not a production messaging platform or a claim of exactly-once delivery.

## Implemented slice

- Immutable source outbox events and a separate mutable delivery-state table.
- Tenant identity resolved from PostgreSQL session_user through a private role map; caller-supplied tenant IDs are not accepted.
- SECURITY DEFINER claim/ack/nack/consume functions owned by a NOLOGIN, non-superuser, non-BYPASSRLS role; tenant-scoped FORCE ROW LEVEL SECURITY.
- Short claim operation using FOR UPDATE SKIP LOCKED, bounded batch/lease parameters, attempt counter and fresh lease token.
- Acknowledgement requires the current, unexpired lease token. Expired workers are fenced from acknowledging a replacement lease.
- Retry state with bounded attempts and terminal dead status.
- Immutable consumer inbox keyed by (tenant_id, consumer_name, event_id); the inbox receipt and synthetic consumer effect are committed in one database transaction.
- Node.js relay helpers, PostgreSQL 18.7 fixture, Node 26.13.0, pinned pg dependency, lockfile and SHA-pinned workflow.

## Acceptance scenarios

| ID | Scenario | Expected invariant |
|---|---|---|
| P03-OUTBOX-01 | Tenant A claims events while Tenant B has pending events | No cross-tenant event disclosure |
| P03-OUTBOX-02 | Two workers claim concurrently | Disjoint claims; no simultaneous active lease for one event |
| P03-OUTBOX-03 | Acknowledge with wrong/repeated token | Rejected; only current lease can transition to published |
| P03-OUTBOX-04 | Lease expires and another worker reclaims | Fresh token fences stale worker |
| P03-OUTBOX-05 | Retry reaches configured attempt limit | Event transitions to dead and is no longer claimable |
| P03-OUTBOX-06 | Concurrent consumer redelivery | One inbox receipt and one synthetic effect |
| P03-OUTBOX-07 | Process crashes after publish but before ack | Redelivery is possible; consumer effect remains deduplicated |
| P03-OUTBOX-08 | Broker publish throws | Event is negatively acknowledged and retried, not marked published |
| P03-OUTBOX-09 | Tenant runtime reads delivery tables directly | Permission denied |
| P03-OUTBOX-10 | Invalid claim/consumer parameters | Deterministic validation error |

## Delivery semantics and limitations

The relay is at-least-once, not exactly-once. The external publish and database acknowledgement cannot be made atomic by this database transaction. A crash after broker acceptance but before acknowledgement can cause a second publish. The stable event ID is the consumer deduplication key.

The synthetic in-memory broker only demonstrates the crash window; it does not prove broker durability, network behavior, partition ordering or provider guarantees. A real consumer must commit its inbox receipt and its own business side effect in the same transaction, or use a separate outbox/saga. Consumer deduplication does not make arbitrary external side effects exactly-once.

This P-03 database is a separate disposable fixture: no migration or runtime adapter currently connects the P-02 ledger_outbox table to this delivery-state schema. That integration is a later, separately reviewed step. No CDC/Debezium, Kafka/SQS, external broker, provider integration, cross-tenant relay credential, production retention/replay, schema evolution, observability, SLO, key management or operational recovery is implemented or approved. Per-tenant runtime identities are used; a global relay authority is intentionally not introduced.

## Reproduction

From prototypes/p03-outbox-delivery with Docker and Node.js 26.13.x:

    docker compose -f compose.yaml up -d --wait
    export ADMIN_DATABASE_URL='postgres://postgres:p03-admin-only-not-production@127.0.0.1:55434/lottorito_p03'
    export TENANT_A_DATABASE_URL='postgres://tenant_a_outbox_runtime:p03-tenant-a-not-production@127.0.0.1:55434/lottorito_p03'
    export TENANT_B_DATABASE_URL='postgres://tenant_b_outbox_runtime:p03-tenant-b-not-production@127.0.0.1:55434/lottorito_p03'
    npm ci --ignore-scripts --no-audit --no-fund
    npm test
    docker compose -f compose.yaml down

The Compose database is disposable. Do not point these scripts at shared, staging or production databases. The setup script creates fixture roles and schema and is intended for a fresh local container.

## Result record

P-03 run [45468686909](https://github.com/tecpey/lottorito-platform/actions/runs/45468686909) passed all 10 integration tests (0 failed, 0 skipped) on head `a52e8c248e4a2dbc7e9e88eeb6f71b96ec3f8b02`; Documentation Governance run [45468686901](https://github.com/tecpey/lottorito-platform/actions/runs/45468686901) also passed on that head. The workflow used PostgreSQL 18.7, Node.js 26.13.0 and npm ci with the committed lockfile. This prototype does not establish production readiness or financial/accounting correctness.

## References

- PostgreSQL 18 SELECT locking clause and SKIP LOCKED: https://www.postgresql.org/docs/18/sql-select.html
- PostgreSQL explicit row locking: https://www.postgresql.org/docs/18/explicit-locking.html
- AWS Prescriptive Guidance, transactional outbox and idempotent consumers: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- Debezium Outbox Event Router: https://debezium.io/documentation/reference/stable/transformations/outbox-event-router.html
