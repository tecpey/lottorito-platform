# P-05A — PostgreSQL Backup, PITR and Financial Integrity

**Document ID:** LOT-PROT-P05-001 | **Version:** 0.5.0 | **Status:** Synthetic CI experiment passed; production recovery not approved

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


## Reconciled P-05B continuation — 2026-11-25

P-05B is being carried onto replacement branch `spike/p05b-object-key-event-recovery-p03d`, based on P-05A PR #63's latest synchronized head `481a0ab2ac15ee982745e0a3b48d4d93cc829431`. The branch includes the P-05A recovery-complete gate and both missing-WAL/incomplete-restore negative drills before the P-05B object/key/event suite. Original PR #53 evidence is historical; the replacement must pass its own complete P-05 workflow and upstream P-02/P-03C/P-03D/P-04 regressions.



## Verified reconciled-stack CI — 2026-11-25

Exact tested PR #64 head: bbad5969fc3c952ebafdaed3c8d2306dbd018ad4.

- P-02 [run 45611209596](https://github.com/tecpey/lottorito-platform/actions/runs/45611209596): 25 passed, 0 failed, 0 skipped.
- P-03C/P-03D [run 45611209613](https://github.com/tecpey/lottorito-platform/actions/runs/45611209613): 15 + 19 passed, 0 failed, 0 skipped.
- P-04 [run 45611209559](https://github.com/tecpey/lottorito-platform/actions/runs/45611209559): 7 passed, 0 failed, 0 skipped.
- Combined P-05A/P-05B [run 45611209642](https://github.com/tecpey/lottorito-platform/actions/runs/45611209642): P05A_RESULT=PASS, P05B_OBJECT_KEY_RESULT=PASS, P05B_EVENT_RESULT=PASS, P05B_RESULT=PASS, P05A_NEGATIVE_RESULT=PASS. Incomplete restore manifest/server startup were rejected; missing target WAL failed closed.
- Documentation Governance [run 45611209546](https://github.com/tecpey/lottorito-platform/actions/runs/45611209546): passed.

All five workflows passed on the same exact PR head. The P-02 through P-04 automated suites total 66 tests, all passed with zero skips; P-05 assertions also passed. This is synthetic-only recovery evidence, not production readiness or RPO/RTO approval.


## P-05C downstream regression gate — 2026-11-25

P-05C's synthetic HA drill is stacked on the reconciled P-05A/P-05B branch. The combined P-05A/P-05B recovery workflow must be rerun on the P-05C replacement head, proving PITR, object/key/event recovery and negative restore/WAL drills remain intact before the independent failover/fencing workflow is accepted.
