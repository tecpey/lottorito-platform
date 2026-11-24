import { withTenantTransaction } from "./tenant-db.js";
import { verifyJobEnvelope } from "./job-dispatch.js";

/**
 * The queue envelope is authenticated before tenant context is established.
 * The job and its actor membership are then reloaded under tenant RLS.
 */
export async function processTenantJob(pool, envelope, secret) {
  if (!verifyJobEnvelope(envelope, secret)) {
    return { status: "invalid_envelope" };
  }

  return withTenantTransaction(pool, envelope.tenant_id, async (client) => {
    const selected = await client.query(
      `SELECT subject_id, payload, status
         FROM public.tenant_jobs
        WHERE job_id = $1
        FOR UPDATE`,
      [envelope.job_id]
    );
    const job = selected.rows[0];
    if (!job) return { status: "not_found" };
    if (job.status !== "queued") return { status: "already_processed", job_status: job.status };

    const membership = await client.query(
      "SELECT active FROM public.tenant_memberships WHERE subject_id = $1 FOR SHARE",
      [job.subject_id]
    );
    if (!membership.rows[0]?.active) {
      await client.query(
        "UPDATE public.tenant_jobs SET status = 'rejected', completed_at = clock_timestamp() WHERE job_id = $1 AND status = 'queued'",
        [envelope.job_id]
      );
      return { status: "membership_revoked" };
    }

    const completed = await client.query(
      `UPDATE public.tenant_jobs
          SET status = 'completed', completed_at = clock_timestamp()
        WHERE job_id = $1 AND status = 'queued'
        RETURNING payload`,
      [envelope.job_id]
    );
    if (completed.rowCount !== 1) return { status: "already_processed" };
    return { status: "completed", payload: completed.rows[0].payload };
  });
}
