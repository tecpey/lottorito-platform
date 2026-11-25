# P-05B — Object, Key and Event Recovery

**Document ID:** LOT-PROT-P05B-001 | **Version:** 0.1.0 | **Status:** Synthetic experiment implementation; CI verification pending

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

## Safety, limitations and open work

No live KMS/HSM, cloud object storage, external broker, provider, real credential, customer/player data or real funds are used. AES-GCM is a candidate experiment primitive, not an approved platform decision. The experiment does not test key rotation/revocation, key compromise, split custody, KMS outage, IAM policy, object versioning/immutability, retention/legal hold, large/multipart objects, regional replication, external broker replay, provider reconciliation, cross-service sagas, high concurrency, production load, RPO/RTO objectives or compliance. Missing-WAL and interrupted-restore P-05A negative drills remain open. P-05C failover/fencing/failback is not part of this work.

RPO/RTO remain TBD under LOT-QA-001. CI timings are observations only. A successful synthetic test is not production readiness or approval of any technology/vendor.

## References

- https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity-upload.html
- https://docs.cloud.google.com/storage/docs/data-validation
- https://docs.cloud.google.com/storage/docs/object-versioning
- https://nvlpubs.nist.gov/nistpubs/specialpublications/nist.sp.800-57pt1r5.pdf
- https://csrc.nist.gov/pubs/sp/800/57/pt1/r6/ipd
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html
