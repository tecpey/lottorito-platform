# P-05A — PostgreSQL Backup, PITR and Financial Integrity

**Document ID:** LOT-PROT-P05-001 | **Version:** 0.7.0 | **Status:** Synthetic CI experiment passed; production recovery not approved

## Authority and decision boundary

This is a disposable synthetic experiment only. It does not approve PostgreSQL as Lottorito's production database, select a backup vendor, authorize production backup access, or set RPO/RTO. It covers P-05A only; object-byte/key recovery and failover/fencing remain separate P-05B/P-05C experiments.

## Research basis

- PostgreSQL 18 physical base backup and continuous WAL archiving/PITR.
- PostgreSQL 18 pg_verifybackup guidance: manifest verification does not replace a real test restore.
- Google SRE data-integrity guidance: recovery confidence requires end-to-end restore exercises.
- Google Cloud and AWS Well-Architected recovery testing and strategy guidance.
- LOT-FIN-POST-001 immutable double-entry, economic-effect idempotency and reconciliation invariants; LOT-QA-001 QA-01/03/04/07/08.

## Experiment

A disposable PostgreSQL 18.7 container enables WAL archiving before the base backup. Two synthetic tenant identities, balanced journal fixtures, source-event control totals and object-reference metadata are created. The test takes a physical base backup, verifies its manifest, tampers with a copy to test fail-closed behavior, creates a named restore point, commits a post-target incident marker, archives the required WAL, and restores into a second isolated data directory at that named point.

The restored database is started and checked for:
- exact PITR boundary: pre-target data present and post-target marker absent;
- journal balance and source-event-to-ledger control-total parity;
- uniqueness of economic-effect identities;
- object-reference metadata integrity (not object-byte recoverability);
- tenant RLS using distinct database login identities;
- recorded backup, verification, WAL archive and restore timings.

## Acceptance IDs

- P05-BACKUP: physical base backup and manifest created; pg_verifybackup succeeds.
- P05-TAMPER: corrupted manifest copy is rejected.
- P05-WAL: required WAL segment for named restore point is archived.
- P05-PITR: recovery reaches named restore point; later marker is absent.
- P05-LEDGER: all fixture journals balance and source/ledger totals reconcile.
- P05-IDEMPOTENCY: economic-effect IDs remain unique.
- P05-TENANT: restored RLS denies cross-tenant reads for both tenant identities.
- P05-OBJECT-REF: synthetic object-reference metadata remains structurally valid; object payload bytes are outside P-05A.
- P05-TIMING: backup/verification/restore durations and achieved recovery point are recorded without target-compliance claims.

## Negative recovery drills (P-05A continuation)

The combined P-05 workflow adds two fail-closed checks beyond the original positive PITR path:

1. **Incomplete restore staging:** create a disposable copy of the physical backup, remove the required `global/pg_control` file, and require both `pg_verifybackup` and PostgreSQL startup to reject the incomplete staging directory. This is an interrupted/incomplete restore-artifact simulation; it does not claim to kill a live production restore process mid-write.
2. **Missing target WAL:** create independent copies of the base backup and WAL archive, remove the exact WAL segment containing the named restore target from both the copied archive and copied `pg_wal`, and attempt targeted recovery. PostgreSQL may fail startup or may expose a valid earlier recovery state depending on the available WAL. Either way, the drill must reject the result as a successful named-target recovery unless the expected post-target marker is present. The negative test checks the requested segment in the recovery log and never alters the positive fixture or source archive.

The positive path also polls `pg_is_in_recovery()` until it returns `false` before running writable financial/RLS assertions. `pg_ctl` reporting readiness alone is insufficient because a server may accept read-only connections while recovery is still in progress. The missing-WAL negative path explicitly rejects a server that becomes writable before the requested target.

The distinction matters: a server that starts after exhausting available WAL is not, by that fact alone, proof that it reached the requested recovery target. The recovery acceptance gate must validate the expected business marker/control state before accepting traffic. PostgreSQL documents that `restore_command` must return nonzero for absent archive files and that interrupted recovery can be restarted; `pg_verifybackup` detects missing files but does not replace a real restore and content validation.

**Status:** Negative-drill implementation is in the combined CI workflow; validation is pending until the final branch head completes Integration and Documentation Governance.

## Safety and limits

No production data, credentials, partner secrets, real funds or live endpoints. No cloud resources or external services are provisioned. The test uses disposable container storage and synthetic passwords. It does not prove off-site/immutable retention, encryption/key custody, object-byte restoration, application/worker recovery, event replay, provider reconciliation, regional recovery, failover, split-brain fencing, failback, production-scale throughput or legal/compliance readiness. These require P-05B/P-05C and later review. RPO/RTO remain TBD pending owner/domain approval.

## References

- https://www.postgresql.org/docs/18/continuous-archiving.html
- https://www.postgresql.org/docs/18/app-pgbasebackup.html
- https://www.postgresql.org/docs/18/app-pgverifybackup.html
- https://www.postgresql.org/docs/18/runtime-config-wal.html
- https://www.postgresql.org/docs/18/functions-admin.html
- https://www.postgresql.org/docs/18/app-pgrewind.html
- https://sre.google/sre-book/data-integrity/
- https://docs.cloud.google.com/architecture/framework/reliability/perform-testing-for-recovery-from-data-loss
- https://docs.aws.amazon.com/wellarchitected/latest/framework/rel_planning_for_recovery_disaster_recovery.html

## Evidence

- Latest combined Integration [run 45532825694](https://github.com/tecpey/lottorito-platform/actions/runs/45532825694) and Documentation Governance [run 45532825916](https://github.com/tecpey/lottorito-platform/actions/runs/45532825916) passed on executable-code head `146a9bc635e3b03db568c423fb0958b62bc31c7b`.
- The positive PITR path now waits for `pg_is_in_recovery() = false` before writable financial/RLS assertions (`pitr_recovery_complete=PASS`); `pg_ctl` readiness alone is not treated as proof that recovery has finished.
- Final negative assertions: `incomplete_restore_manifest_rejected=PASS`, `incomplete_restore_server_start_rejected=PASS`, `missing_wal_startup_failed_closed=PASS`, `missing_wal_target_segment_absence_detected=PASS`, `P05A_NEGATIVE_RESULT=PASS`.

- Combined P-05A/P-05B Integration: [run 45532382323](https://github.com/tecpey/lottorito-platform/actions/runs/45532382323), passed on final branch head `0a6b8f992161cd9f9d760698b1c9d0c8e30867a9`.
- Documentation Governance: [run 45532382310](https://github.com/tecpey/lottorito-platform/actions/runs/45532382310), passed on the same head.
- Negative assertions: `incomplete_restore_manifest_rejected=PASS`, `incomplete_restore_server_start_rejected=PASS`, `missing_wal_startup_not_ready=PASS`, `missing_wal_target_segment_absence_detected=PASS`, `P05A_NEGATIVE_RESULT=PASS`.

- Integration: [run 45524388676](https://github.com/tecpey/lottorito-platform/actions/runs/45524388676), passed on head f2303a647aefd5bd8d48ba9d2e1830c881f60041.
- Documentation Governance: [run 45524388734](https://github.com/tecpey/lottorito-platform/actions/runs/45524388734), passed on the same head.
- PostgreSQL 18.7; base backup plus verification: 12–13 seconds (latest final-head run: 13 seconds); restored server startup: 1 second in this disposable GitHub-hosted runner. These are observations, not production RTO targets.
- The run asserted manifest verification and tamper rejection, archived WAL presence, the named PITR log entry, pre-target marker present/post-target marker absent, tenant-scoped reads and denied cross-tenant insert, balanced journals, source-to-ledger totals, unique economic effects and valid object-reference hash format.
- Negative drills passed on combined executable-code head `146a9bc635e3b03db568c423fb0958b62bc31c7b`: an incomplete restore staging directory was rejected by both `pg_verifybackup` and PostgreSQL startup; removal of the exact target WAL segment caused the recovery startup to fail closed before the requested named target. The missing-WAL log recorded the absent target segment. Object-byte/key recovery is covered by P-05B; failover/fencing/failback remains P-05C and has not run.
- Synthetic success is not production readiness, a technology decision or RPO/RTO approval.


## P-09E shared-record recovery evidence (2026-11-25)

The P-05 workflow [45635972222](https://github.com/tecpey/lottorito-platform/actions/runs/45635972222) passed on candidate head 73d7d0daa46e6a019020fc25ace315836d270a6f. In addition to the existing P-05A PITR, P-05B object/key/event fixture and P-05A negative drills, it ran P-09E against the exact P-02/P-03C/P-03D SQL schemas and actual provider inbox, ledger, journal, line, outbox and delivery-state tables. The physical backup passed pg_verifybackup; the restored cluster replayed three accepted inbox records with one journal/effect/outbox/delivery row per scope. Failure injection rolled back the posting transaction as a unit. Same-source-ID collisions across product and tenant scopes, idempotent retries, RLS and P-03D reconciliation all passed. See the P-09 integration record for scope and limitations.

This does not replace the simplified P-05B fixture or establish production backup architecture, PITR retention, off-site durability, key/object restore, aggregate ordering, concurrent fencing, RPO/RTO or Production readiness. Documentation Governance [45635972312](https://github.com/tecpey/lottorito-platform/actions/runs/45635972312) passed on the same head (58 bilingual pairs, 136 local links).

## P-09E latest exact-head confirmation (2026-11-25)

P-09E passed again in P-05 workflow [45637659268](https://github.com/tecpey/lottorito-platform/actions/runs/45637659268) on 2b393cc8c41226a20333f34559ac6952883901a3. Physical backup, pg_verifybackup, isolated restore, actual P-02/P-03C/P-03D records, atomic rollback under injected failure, inbox replay, idempotency, tenant/product RLS, balanced journals, outbox delivery-state atomicity and zero provider-ledger reconciliation exceptions all emitted PASS. P-05A PITR, P-05B and negative-WAL/incomplete-restore drills also passed. Documentation Governance [45637659297](https://github.com/tecpey/lottorito-platform/actions/runs/45637659297) passed on the same head.
