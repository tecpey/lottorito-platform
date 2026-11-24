import { createHmac, timingSafeEqual } from "node:crypto";
import { isUuid } from "./tenant-db.js";

function envelopePayload(envelope) {
  return [
    "lottorito-p01-job-envelope-v1",
    envelope.tenant_id,
    envelope.job_id,
    String(envelope.attempt),
    String(envelope.issued_at)
  ].join("\n");
}

function assertSecret(secret) {
  if (typeof secret !== "string" || Buffer.byteLength(secret, "utf8") < 32) {
    throw new TypeError("JOB_ENVELOPE_SECRET must contain at least 32 UTF-8 bytes");
  }
}

export function signJobEnvelope(fields, secret) {
  assertSecret(secret);
  if (!isUuid(fields.tenant_id) || !isUuid(fields.job_id)) {
    throw new TypeError("tenant_id and job_id must be valid UUIDs");
  }
  if (!Number.isSafeInteger(fields.attempt) || fields.attempt < 1) {
    throw new TypeError("attempt must be a positive safe integer");
  }
  if (!Number.isSafeInteger(fields.issued_at) || fields.issued_at < 1) {
    throw new TypeError("issued_at must be a positive safe integer");
  }

  const envelope = {
    version: 1,
    tenant_id: fields.tenant_id,
    job_id: fields.job_id,
    attempt: fields.attempt,
    issued_at: fields.issued_at
  };
  envelope.signature = createHmac("sha256", secret)
    .update(envelopePayload(envelope), "utf8")
    .digest("base64url");
  return envelope;
}

export function verifyJobEnvelope(envelope, secret) {
  try {
    assertSecret(secret);
    if (!envelope || envelope.version !== 1 ||
        !isUuid(envelope.tenant_id) || !isUuid(envelope.job_id) ||
        !Number.isSafeInteger(envelope.attempt) || envelope.attempt < 1 ||
        !Number.isSafeInteger(envelope.issued_at) || envelope.issued_at < 1 ||
        typeof envelope.signature !== "string") {
      return false;
    }
    const expected = createHmac("sha256", secret)
      .update(envelopePayload(envelope), "utf8")
      .digest();
    const actual = Buffer.from(envelope.signature, "base64url");
    return actual.length === expected.length && timingSafeEqual(actual, expected);
  } catch {
    return false;
  }
}

/**
 * Claims one global dispatch-metadata row. The dispatcher can see tenant/job
 * identifiers and status only; it has no grant on tenant_jobs or payloads.
 */
export async function claimNextJob(dispatcherPool, secret, { leaseSeconds = 30 } = {}) {
  assertSecret(secret);
  if (!Number.isSafeInteger(leaseSeconds) || leaseSeconds < 0 || leaseSeconds > 3600) {
    throw new RangeError("leaseSeconds must be an integer between 0 and 3600");
  }

  const client = await dispatcherPool.connect();
  let transactionOpen = false;
  let destroyConnection = null;
  try {
    await client.query("BEGIN");
    transactionOpen = true;
    const selected = await client.query(
      `SELECT tenant_id, job_id
         FROM public.job_dispatch
        WHERE status = 'pending'
           OR (status = 'claimed'
               AND claimed_at < clock_timestamp() - ($1::int * interval '1 second'))
        ORDER BY created_at, tenant_id, job_id
        LIMIT 1
        FOR UPDATE SKIP LOCKED`,
      [leaseSeconds]
    );

    if (selected.rowCount === 0) {
      await client.query("COMMIT");
      transactionOpen = false;
      return null;
    }

    const row = selected.rows[0];
    const claimed = await client.query(
      `UPDATE public.job_dispatch
          SET status = 'claimed',
              attempts = attempts + 1,
              claimed_at = clock_timestamp()
        WHERE tenant_id = $1 AND job_id = $2
        RETURNING attempts`,
      [row.tenant_id, row.job_id]
    );
    await client.query("COMMIT");
    transactionOpen = false;

    return signJobEnvelope({
      tenant_id: row.tenant_id,
      job_id: row.job_id,
      attempt: claimed.rows[0].attempts,
      issued_at: Date.now()
    }, secret);
  } catch (error) {
    if (transactionOpen) {
      try {
        await client.query("ROLLBACK");
      } catch (rollbackError) {
        destroyConnection = rollbackError;
      }
    }
    throw error;
  } finally {
    client.release(destroyConnection);
  }
}

/** A stale attempt cannot acknowledge a job that has since been reclaimed. */
export async function acknowledgeJob(dispatcherPool, envelope, secret) {
  if (!verifyJobEnvelope(envelope, secret)) return false;
  const result = await dispatcherPool.query(
    `UPDATE public.job_dispatch
        SET status = 'completed', claimed_at = NULL
      WHERE tenant_id = $1
        AND job_id = $2
        AND status = 'claimed'
        AND attempts = $3`,
    [envelope.tenant_id, envelope.job_id, envelope.attempt]
  );
  return result.rowCount === 1;
}
