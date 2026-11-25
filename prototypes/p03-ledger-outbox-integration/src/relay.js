export async function claimOutboxEvents(pool, { batchSize = 10, leaseSeconds = 30, workerId }) {
  if (!pool || typeof pool.query !== "function") throw new TypeError("a tenant-bound PostgreSQL pool is required");
  if (typeof workerId !== "string" || !/^[A-Za-z0-9._:-]{1,80}$/.test(workerId)) throw new TypeError("workerId is invalid");
  const result = await pool.query(
    "SELECT * FROM public.claim_outbox_events($1,$2,$3)",
    [batchSize, leaseSeconds, workerId]
  );
  return result.rows;
}

export async function acknowledgeOutboxEvent(pool, eventId, leaseToken) {
  const result = await pool.query("SELECT public.ack_outbox_event($1,$2) AS acknowledged", [eventId, leaseToken]);
  return result.rows[0].acknowledged;
}

export async function rejectOutboxEvent(pool, eventId, leaseToken, error, retrySeconds = 0) {
  const safeMessage = error instanceof Error ? error.message : String(error);
  const result = await pool.query(
    "SELECT public.nack_outbox_event($1,$2,$3,$4) AS outcome",
    [eventId, leaseToken, safeMessage.slice(0, 1000), retrySeconds]
  );
  return result.rows[0].outcome;
}

export async function consumeOutboxEvent(pool, consumerName, eventId) {
  const result = await pool.query(
    "SELECT public.consume_outbox_event($1,$2) AS applied",
    [consumerName, eventId]
  );
  return result.rows[0].applied;
}

export async function deliverOutboxBatch(pool, publish, { batchSize = 10, leaseSeconds = 30, workerId, retrySeconds = 5 }) {
  if (typeof publish !== "function") throw new TypeError("publish must be a function");
  const events = await claimOutboxEvents(pool, { batchSize, leaseSeconds, workerId });
  const results = [];
  for (const event of events) {
    try {
      await publish(event);
      const acknowledged = await acknowledgeOutboxEvent(pool, event.event_id, event.lease_token);
      results.push({ eventId: event.event_id, outcome: acknowledged ? "published" : "published_unacknowledged" });
    } catch (error) {
      const outcome = await rejectOutboxEvent(pool, event.event_id, event.lease_token, error, retrySeconds);
      results.push({ eventId: event.event_id, outcome });
    }
  }
  return results;
}
