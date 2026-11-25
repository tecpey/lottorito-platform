# P-05B — Object, Key and Event Recovery

**Document ID:** LOT-PROT-P05B-001 | **Version:** 0.5.0 | **Status:** Combined P-05A/P-05B synthetic CI passed on executable-code head 146a9bc635e3b03db568c423fb0958b62bc31c7b; production recovery not approved

## Authority and boundary

P-05B extends the P-05A PostgreSQL PITR experiment with independent object-byte recovery, synthetic envelope-key recovery, and idempotent ordered event replay. It is an isolated, disposable CI experiment. It does not select an object-store, KMS/HSM, broker, database, cloud provider or production architecture. It does not authorize custody, production key export, live provider replay, real funds, production data, merge or deployment.

## Research basis

- AWS S3 object integrity guidance: validate checksums on upload/download; an ETag is not a universal full-object checksum, especially for multipart objects.
- Google Cloud Storage integrity guidance: calculate checksums over the complete received object and compare against a trusted expected value; range reads require special handling.
- NIST SP 800-57 Part 1 Rev. 5: protect and retain data-encryption keys for the required recovery period; wrap archived DEKs under separately protected key-wrapping material. Rev. 6 is an initial public draft and is not treated as final guidance.
- AWS transactional-outbox and event-processing guidance: duplicate delivery is expected in at-least-once systems; consumers must be idempotent and preserve required ordering.
- LOT-FIN-POST-001, LOT-EVENT-001 and LOT-QA-001: immutable economic-effect identity, tenant isolation, ledger balance and source-to-ledger reconciliation.

## Experiment

### Object bytes and integrity

1. Create a binary synthetic payload and record its byte length and SHA-256 in a manifest and the restored PostgreSQL object-reference row.
2. Encrypt the payload with a random 256-bit DEK using AES-256-GCM and context-bound associated data (tenant, object and format version).
3. Wrap the DEK with a separate synthetic 256-bit KEK using AES-256-GCM and context-bound associated data (key ID and object ID).
4. Back up object payload/manifest/envelope and key-recovery material into separate disposable directories; remove active copies.
5. Restore both sets independently, authenticate/decrypt, recompute the complete plaintext SHA-256 and compare it to the database reference and expected byte count.
6. Prove missing key material, corrupt ciphertext and corrupt wrapped DEK fail closed. Confirm plaintext is not stored in the object backup.

The raw synthetic KEK file is deliberately only a CI fixture. It is not a production key-custody pattern, KMS/HSM integration, split-knowledge process, key ceremony or recovery authorization design.

### Event replay and financial invariants

1. Persist source events and inbox records with tenant, consumer, source-event ID, economic-effect ID, aggregate ID and sequence.
2. Deliver aggregate sequence 2 before sequence 1, redeliver sequence 2, and submit a different source-event ID carrying an already-used economic-effect ID.
3. Require the replay cursor to stop at a sequence gap; after sequence 1 arrives, process 1 then 2.
4. Inject a failure after the replay function has written journal, lines, inbox status and cursor but before transaction commit. Verify the whole transaction rolls back.
5. Retry pending events; assert exactly two journals, two balanced effects, both inbox records processed, cursor at sequence 2, and source totals equal ledger cash totals.
6. Verify a repeated replay is a no-op and cross-tenant inbox reads/writes are denied.

The experiment demonstrates database-transaction atomicity for this fixture, not exactly-once delivery across independent systems. External provider reconciliation and broker durability remain out of scope.

## Acceptance criteria

- P05B-OBJECT: restored plaintext byte count and SHA-256 match the trusted database reference.
- P05B-OBJECT-NEGATIVE: altered ciphertext is rejected before plaintext acceptance.
- P05B-KEY: separately restored synthetic recovery material unwraps the DEK and authenticates the object.
- P05B-KEY-NEGATIVE: missing recovery key and altered wrapped DEK fail closed.
- P05B-TENANT: Tenant B cannot read Tenant A object metadata.
- P05B-INBOX: duplicate source event and duplicate economic-effect identity collapse to one inbox record.
- P05B-ORDER: sequence 2 cannot advance while sequence 1 is absent; processing order is 1 then 2.
- P05B-ATOMICITY: injected transaction failure leaves no journal, no processed inbox state and no cursor advance.
- P05B-REPLAY: retry creates exactly one journal per economic effect; a further replay creates none.
- P05B-LEDGER: every journal balances and source-event totals reconcile to ledger cash totals.
- P05B-TENANT-EVENT: cross-tenant inbox read/write is denied.
- All assertions run against the PostgreSQL database restored by P-05A in the same disposable job.

## Final CI evidence

- Latest combined P-05A/P-05B Integration [run 45532825694](https://github.com/tecpey/lottorito-platform/actions/runs/45532825694) and Documentation Governance [run 45532825916](https://github.com/tecpey/lottorito-platform/actions/runs/45532825916) passed on executable-code head `146a9bc635e3b03db568c423fb0958b62bc31c7b`.
- P-05A recovery-complete gate passed (`pg_is_in_recovery() = false`); missing-WAL startup failed closed; incomplete restore staging was rejected by manifest verification and server startup.

- Final combined P-05A/P-05B Integration [run 45532382323](https://github.com/tecpey/lottorito-platform/actions/runs/45532382323) and Documentation Governance [run 45532382310](https://github.com/tecpey/lottorito-platform/actions/runs/45532382310) both passed on branch head `0a6b8f992161cd9f9d760698b1c9d0c8e30867a9`.
- The combined run also closed the two P-05A negative drills: incomplete restore staging was rejected by manifest verification and server startup; the missing target WAL segment prevented readiness at the requested restore point and was identified in the recovery log.


- P-05A + P-05B Integration (pull request) [run 45526975173](https://github.com/tecpey/lottorito-platform/actions/runs/45526975173): passed on validated branch head e4820884194ecf1ab3acd539d77145904f14ab73.
- Documentation Governance [run 45526975222](https://github.com/tecpey/lottorito-platform/actions/runs/45526975222): passed on the same head.
- Restored object payload: 4,409 bytes; SHA-256 `2db4a9b021abba0ce01480ceda665284f023310ce909c0b0b9bcb084f771eaca`, matched against the restored PostgreSQL object reference.
- Object/key assertions passed: independent backup recovery, missing-key fail-closed, modified ciphertext rejection, modified wrapped-DEK rejection and tenant object-reference isolation.
- Event assertions passed: out-of-order delivery (2, then 1), duplicate delivery/economic-effect collapse, sequence-gap block, interrupted transaction rollback, retry with exactly two effects, balanced ledger, source-to-ledger reconciliation, no-op replay and tenant inbox isolation.
- The same integration job reran P-05A backup verification/PITR and its financial/RLS assertions before P-05B. The P-05A positive path explicitly waited for `pg_is_in_recovery() = false` before write assertions. The job also reran missing-WAL and incomplete-restore negative drills. PostgreSQL 18.7 was used in a disposable container; no production RPO/RTO claim is made.

## Safety, limitations and open work

No live KMS/HSM, cloud object storage, external broker, provider, real credential, customer/player data or real funds are used. AES-GCM is a candidate experiment primitive, not an approved platform decision. The experiment does not test key rotation/revocation, key compromise, split custody, KMS outage, IAM policy, object versioning/immutability, retention/legal hold, large/multipart objects, regional replication, external broker replay, provider reconciliation, cross-service sagas, high concurrency, production load, RPO/RTO objectives or compliance. P-05A missing-WAL and incomplete-restore negative drills now pass in the combined workflow; this proves only the synthetic fail-closed checks described in the P-05A report. P-05C failover/fencing/failback is not part of this work.

RPO/RTO remain TBD under LOT-QA-001. CI timings are observations only. A successful synthetic test is not production readiness or approval of any technology/vendor.

## References

- https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity-upload.html
- https://docs.cloud.google.com/storage/docs/data-validation
- https://docs.cloud.google.com/storage/docs/object-versioning
- https://nvlpubs.nist.gov/nistpubs/specialpublications/nist.sp.800-57pt1r5.pdf
- https://csrc.nist.gov/pubs/sp/800/57/pt1/r6/ipd
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html

## P-09J — Product-qualified recovery identity (2026-11-25)

P-05B's inbox and replay cursor now include `product_id` in their primary/unique keys. The same tenant, consumer, source-event UUID, economic-effect UUID and aggregate UUID are seeded independently for Affiliate & Agent and Lottery. Product identity is carried through source-event lookup, journal/line creation, inbox status updates and cursor updates; the disposable role map and RLS policies bind both tenant and product.

The replay function locks the product-qualified cursor row with `FOR UPDATE`. Two concurrent workers against the same Affiliate cursor serialize to exactly two effects in total, while a worker for the same aggregate in Lottery advances its independent cursor. The tests also verify sequence-gap blocking, rollback after injected interruption, retry/no-op behavior, balanced journals, per-product source-to-ledger reconciliation, and cross-tenant/cross-product RLS denial.

On source-code head `dfaa8120340cc6b4b80450dbf0e5755b21111080`, [P-05 recovery run 45662750801](https://github.com/tecpey/lottorito-platform/actions/runs/45662750801) passed. Its P-05B event stage emitted `product_scope_event_identity=PASS`, `product_scope_replay_cursor_isolation=PASS`, `concurrent_replay_cursor_serialization=PASS`, `interrupted_replay_rollback=PASS`, `ledger_reconciliation=PASS`, and `P05B_RESULT=PASS`. The same run also passed P-05A PITR/negative restore drills and P-09E physical restore/replay. These remain synthetic disposable fixtures, not a production recovery design. The P-02 canonical-token test rejects new `shared` values; any legacy rows still require explicit inventory/quarantine rather than automatic reassignment.

The product-qualified Inbox also enforces one event per `(tenant, product, consumer, aggregate, sequence)`, preventing two distinct effects from competing for the same sequence slot. RLS assertions cover the Inbox, source events, journals and lines—not only the Inbox.
