# P-05C — Failover, Writer Fencing and Failback

**Document ID:** LOT-PROT-P05C-001 | **Version:** 0.1.0 | **Status:** Synthetic implementation; CI validation pending

## Authority and boundary

P-05C is a disposable PostgreSQL 18.7 experiment that exercises a two-node physical replication lifecycle, process-level promotion gating, a database-local writer-epoch compare-and-swap primitive, stale-writer/expired-lease rejection, timeline rewind and controlled failback. It is not a production HA design, a quorum/DCS implementation, a hardware fencing system, or a vendor selection. No production data, real credentials, funds, cloud resources or customer systems are used.

## Research basis

- PostgreSQL 18 failover guidance states that the old primary must be prevented from returning as a writer after standby promotion; otherwise both nodes can believe they are primary and diverge. It describes external STONITH-style fencing and the use of pg_rewind to rejoin the former primary.
- PostgreSQL 18 pg_rewind documentation requires a cleanly shut-down target, common cluster ancestry, checksums or wal_log_hints, full_page_writes, and WAL back to the divergence point. After rewind, the target must replay WAL and be configured as a standby.
- Patroni documentation illustrates lease-based leader locks and watchdog protection when the HA controller cannot reliably stop PostgreSQL after losing its leader lock.
- etcd documentation describes atomic compare-and-swap transactions, revisions, leases and linearizable operations; watch streams alone are not linearizable.

These references inform the experiment only. PostgreSQL, Patroni, etcd or any specific DCS/watchdog is not selected for Lottorito.

## Synthetic experiment

### 1. Two-node physical replication

- Initialize two independent PostgreSQL 18 clusters with data checksums, wal_log_hints=on, full_page_writes=on, wal_level=replica and sufficient WAL retention for the small fixture.
- Create a primary, seed a synthetic control table and event, take a physical pg_basebackup, and start the standby using streaming replication.
- Confirm the standby is in recovery and has received the baseline event.

### 2. Promotion gate and failover

- Attempt promotion while the former primary process is still running. The local harness must refuse promotion.
- Stop the standby, commit one explicitly synthetic event on the primary that the standby cannot receive, and cleanly stop the primary process (local process-fence simulation).
- Restart the standby without the old primary, verify it is read-only/in recovery, then promote it.
- Advance the writer epoch from 1 to 2 and designate the promoted node as the active writer.
- Demonstrate the acknowledged-but-unreplicated old-primary tail is absent after promotion. This is intentional evidence of asynchronous-replication data-loss exposure, not a zero-RPO claim.

### 3. Epoch fencing and concurrency

A database-local control row stores current_epoch, active_writer and a synthetic lease_until. The effect-posting function locks this row and checks writer identity, epoch and lease validity in the same transaction as the effect insert.

- Reject writer A with epoch 1 after node B owns epoch 2.
- Reject writes after the synthetic lease expires.
- Race two promotion claimants using one expected epoch. An atomic conditional update must grant the next epoch to exactly one claimant; the other receives no token.
- Permit an effect only from the single current writer at the current epoch.

This demonstrates a transactional epoch-checking primitive only. The row is replicated application data, not an independent quorum-backed DCS or external fencing authority. It cannot by itself prevent a partitioned old primary from accepting local writes.

### 4. Rewind and controlled failback

- Rewind the stopped former primary to the promoted node with pg_rewind --write-recovery-conf.
- Rejoin it as a standby and assert it remains read-only, receives the promoted node's event and no longer contains the unreplicated divergent tail.
- Wait until the standby has replayed the new primary's current WAL position.
- Perform a controlled switchover back to the original node, advance the writer epoch to 4, write a failback marker, rewind the former primary and rejoin it as a standby.
- Verify exactly one writable primary, one read-only standby, epoch 4/active writer node A on both nodes, and visibility of the failback marker.

## Acceptance criteria

- P05C-REPLICATION: baseline event reaches standby; standby reports pg_is_in_recovery() = true.
- P05C-PROMOTION-GATE: promotion is refused while the old primary process is alive.
- P05C-PROCESS-FENCE: old primary process is stopped before promotion.
- P05C-FAILOVER: standby promotes and becomes writable; epoch advances 1 → 2.
- P05C-STALE-WRITER: old writer identity/epoch is rejected.
- P05C-LEASE: expired lease rejects writes.
- P05C-CAS: two concurrent claimants produce exactly one epoch-3 winner.
- P05C-REWIND: old primary is rewound and rejoins in recovery; the promoted event is present and the deliberately unreplicated tail is absent.
- P05C-READONLY: rewound standby rejects writes.
- P05C-FAILBACK: controlled switchover returns primary role to node A; epoch advances to 4; former primary is rewound and rejoins as standby.
- P05C-SINGLE-WRITER: after failback exactly one node is writable and the other remains in recovery.

## Safety and limitations

- The process stop is a local CI fence simulation, not host power fencing, cloud instance isolation, storage fencing, watchdog enforcement or proof against network partitions.
- The epoch/lease row is local PostgreSQL application state, not a consensus system. No etcd/Consul/Kubernetes DCS or Patroni controller is deployed.
- The experiment intentionally loses one old-primary event that was committed while the standby was disconnected. This demonstrates asynchronous replication's data-loss window. It does not establish a production RPO.
- No quorum loss, simultaneous partitioned writers, controller crash, watchdog failure, storage-level split brain, multi-region failover, provider-side fencing, concurrent transaction load, real traffic or production RTO is tested.
- pg_rewind prerequisites and WAL-retention constraints are exercised only with tiny synthetic clusters. Failure during rewind can leave the target unusable; a fresh base backup may be required.
- RPO/RTO remain TBD under LOT-QA-001. A passing test does not approve a HA technology, topology, provider, operational runbook or production rollout.

## References

- https://www.postgresql.org/docs/18/warm-standby-failover.html
- https://www.postgresql.org/docs/18/app-pgrewind.html
- https://www.postgresql.org/docs/18/hot-standby.html
- https://www.postgresql.org/docs/18/functions-admin.html
- https://patroni.readthedocs.io/en/latest/watchdog.html
- https://patroni.readthedocs.io/en/latest/dynamic_configuration.html
- https://patroni.readthedocs.io/en/latest/faq.html
- https://etcd.io/docs/v3.5/learning/api_guarantees/
- https://etcd.io/docs/v3.5/learning/api/
