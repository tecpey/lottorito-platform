# P-05A — PostgreSQL Backup, PITR and Financial Integrity

**Document ID:** LOT-PROT-P05-001 | **Version:** 0.2.0 | **Status:** Synthetic CI experiment passed; production recovery not approved

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

## Safety and limits

No production data, credentials, partner secrets, real funds or live endpoints. No cloud resources or external services are provisioned. The test uses disposable container storage and synthetic passwords. It does not prove off-site/immutable retention, encryption/key custody, object-byte restoration, application/worker recovery, event replay, provider reconciliation, regional recovery, failover, split-brain fencing, failback, production-scale throughput or legal/compliance readiness. These require P-05B/P-05C and later review. RPO/RTO remain TBD pending owner/domain approval.

## References

- https://www.postgresql.org/docs/18/continuous-archiving.html
- https://www.postgresql.org/docs/18/app-pgbasebackup.html
- https://www.postgresql.org/docs/18/app-pgverifybackup.html
- https://www.postgresql.org/docs/18/app-pgrewind.html
- https://sre.google/sre-book/data-integrity/
- https://docs.cloud.google.com/architecture/framework/reliability/perform-testing-for-recovery-from-data-loss
- https://docs.aws.amazon.com/wellarchitected/latest/framework/rel_planning_for_recovery_disaster_recovery.html

## Evidence

- Integration: [run 45524388676](https://github.com/tecpey/lottorito-platform/actions/runs/45524388676), passed on head f2303a647aefd5bd8d48ba9d2e1830c881f60041.
- Documentation Governance: [run 45524388734](https://github.com/tecpey/lottorito-platform/actions/runs/45524388734), passed on the same head.
- PostgreSQL 18.7; base backup plus verification: 12–13 seconds (latest final-head run: 13 seconds); restored server startup: 1 second in this disposable GitHub-hosted runner. These are observations, not production RTO targets.
- The run asserted manifest verification and tamper rejection, archived WAL presence, the named PITR log entry, pre-target marker present/post-target marker absent, tenant-scoped reads and denied cross-tenant insert, balanced journals, source-to-ledger totals, unique economic effects and valid object-reference hash format.
- Missing-WAL and interrupted-restore negative drills remain open. Object-byte/key recovery and failover/fencing/failback are P-05B/P-05C and have not run.
- Synthetic success is not production readiness, a technology decision or RPO/RTO approval.


## Reconciled-stack continuation — 2026-11-25

Original P-05A PR #52 was stacked on original P-04 PR #51, which was a sibling of P-03C/P-03D. This continuation is carried onto `spike/p05-backup-restore-recovery-p03d`, based on reconciled P-04 PR #62 head `1013f3b93b55b2cb0859b371db58e1e17ec4ad5e`. The original P-05A CI evidence above is historical. Re-run the P-05A workflow plus P-02, P-03C/P-03D, P-04 and bilingual Documentation Governance on the new branch before accepting P-05A in the reconciled chain. Preserve the existing scope: P-05A does not cover missing-WAL or interrupted-restore negative drills, object-byte/key recovery, or failover/fencing/failback.


## Verified reconciled-stack CI — 2026-11-25

Exact tested code head: 76650b0c799e2f2a5b2f3ae4831bb55d3a3811a6.

- P-02 regression: [run 128](https://github.com/tecpey/lottorito-platform/actions/runs/45609220358) — 25 passed, 0 failed, 0 skipped.
- P-03C/P-03D regression: [run 47](https://github.com/tecpey/lottorito-platform/actions/runs/45609220468) — P-03C 15 passed and P-03D 19 passed; 34 total, 0 failed, 0 skipped.
- P-04 compatibility: [run 31](https://github.com/tecpey/lottorito-platform/actions/runs/45609220377) — 7 passed, 0 failed, 0 skipped.
- P-05A backup/PITR: [run 90](https://github.com/tecpey/lottorito-platform/actions/runs/45609220359) — completed with P05A_RESULT=PASS; base backup, manifest verification/tamper rejection, WAL/PITR, tenant RLS and financial reconciliation all passed.
- Bilingual Documentation Governance: [run 716](https://github.com/tecpey/lottorito-platform/actions/runs/45609220328) — passed.

All five workflows completed successfully on the same exact code head. This verifies only the synthetic P-05A acceptance slice. Off-site immutable retention, key custody, object-byte recovery, missing-WAL/interrupted-restore negative drills, application/worker recovery, provider reconciliation, regional recovery and RPO/RTO approval remain out of scope.
