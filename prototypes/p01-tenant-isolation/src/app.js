import { createServer } from "node:http";
import { randomUUID } from "node:crypto";
import { isUuid, withTenantTransaction } from "./tenant-db.js";

const MAX_BODY_BYTES = 4096;

function respond(res, status, body) {
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    "x-content-type-options": "nosniff"
  });
  res.end(JSON.stringify(body));
}

function httpError(status, message) {
  const error = new Error(message);
  error.statusCode = status;
  return error;
}

async function withAuthorizedTenantTransaction(pool, principal, operation) {
  return withTenantTransaction(pool, principal.tenantId, async (client) => {
    // Re-check active membership inside the same transaction as tenant data.
    // FOR SHARE serializes a concurrent membership revocation with this request.
    const membership = await client.query(
      "SELECT active FROM public.tenant_memberships WHERE subject_id = $1 FOR SHARE",
      [principal.subjectId]
    );
    if (!membership.rows[0]?.active) {
      throw httpError(403, "tenant membership is inactive");
    }
    return operation(client);
  });
}

async function readSupportRecord({ supportPool, pool, principal, tenantId, recordId, grantId }) {
  const client = await supportPool.connect();
  let transactionOpen = false;
  let destroyConnection = null;
  try {
    await client.query("BEGIN");
    transactionOpen = true;
    const safeGrantId = isUuid(grantId) ? grantId : null;
    const grant = safeGrantId
      ? await client.query(
          `SELECT grant_id, reason
             FROM public.support_grants
            WHERE grant_id = $1
              AND support_subject_id = $2
              AND tenant_id = $3
              AND resource_scope = 'records:read'
              AND revoked_at IS NULL
              AND expires_at > clock_timestamp()
            FOR SHARE`,
          [safeGrantId, principal.subjectId, tenantId]
        )
      : { rows: [] };

    if (grant.rows.length !== 1) {
      await client.query(
        `INSERT INTO public.support_audit
          (audit_id, grant_id, support_subject_id, tenant_id, resource_id, action, outcome, reason)
         VALUES ($1, $2, $3, $4, $5, 'records:read', 'denied', $6)`,
        [
          randomUUID(),
          safeGrantId,
          principal.subjectId,
          tenantId,
          recordId,
          "No active grant matches support subject, tenant, scope and expiry"
        ]
      );
      await client.query("COMMIT");
      transactionOpen = false;
      return { authorized: false, row: null };
    }

    await client.query(
      `INSERT INTO public.support_audit
        (audit_id, grant_id, support_subject_id, tenant_id, resource_id, action, outcome, reason)
       VALUES ($1, $2, $3, $4, $5, 'records:read', 'allowed', $6)`,
      [
        randomUUID(),
        grant.rows[0].grant_id,
        principal.subjectId,
        tenantId,
        recordId,
        grant.rows[0].reason
      ]
    );

    let row;
    try {
      row = await withTenantTransaction(pool, tenantId, async (dataClient) => {
        const result = await dataClient.query(
          "SELECT record_id, natural_key, payload FROM public.tenant_records WHERE record_id = $1",
          [recordId]
        );
        return result.rows[0] ?? null;
      });
    } catch (error) {
      // Preserve the audit event even when the subsequent tenant read fails.
      await client.query("COMMIT");
      transactionOpen = false;
      throw error;
    }

    await client.query("COMMIT");
    transactionOpen = false;
    return { authorized: true, row };
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

async function readJson(req) {
  const contentType = String(req.headers["content-type"] ?? "").split(";")[0].trim().toLowerCase();
  if (contentType !== "application/json") throw httpError(415, "application/json is required");

  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) throw httpError(413, "request body too large");
    chunks.push(chunk);
  }

  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw httpError(400, "invalid JSON body");
  }
}

/**
 * authenticate(req) must validate credentials and resolve a server-side
 * principal/tenant selection. Active membership is re-checked under a row lock
 * inside the same transaction as tenant data access. Caller tenant IDs are never
 * authorization proof.
 */
export function createTenantServer({ pool, supportPool, authenticate }) {
  if (!pool || typeof authenticate !== "function") {
    throw new TypeError("pool and authenticate are required");
  }

  return createServer(async (req, res) => {
    try {
      const url = new URL(req.url ?? "/", "http://localhost");
      const isCollection = url.pathname === "/records";
      const isJobsCollection = url.pathname === "/jobs";
      const recordMatch = url.pathname.match(/^\/records\/([0-9a-f-]+)$/i);
      const supportMatch = url.pathname.match(/^\/support\/tenants\/([0-9a-f-]+)\/records\/([0-9a-f-]+)$/i);

      if (!isCollection && !isJobsCollection && !recordMatch && !supportMatch) {
        respond(res, 404, { error: "not_found" });
        return;
      }

      const principal = await authenticate(req);
      if (!principal || typeof principal.subjectId !== "string") {
        respond(res, 401, { error: "unauthorized" });
        return;
      }

      if (principal.kind === "support") {
        if (!supportMatch || req.method !== "GET" || !supportPool) {
          respond(res, 403, { error: "support_access_denied" });
          return;
        }
        const tenantId = supportMatch[1];
        const recordId = supportMatch[2];
        if (!isUuid(tenantId) || !isUuid(recordId)) {
          respond(res, 404, { error: "not_found" });
          return;
        }
        const result = await readSupportRecord({
          supportPool,
          pool,
          principal,
          tenantId,
          recordId,
          grantId: req.headers["x-support-grant-id"]
        });
        if (!result.authorized) {
          respond(res, 403, { error: "support_access_denied" });
          return;
        }
        if (!result.row) {
          respond(res, 404, { error: "not_found" });
          return;
        }
        respond(res, 200, { data: result.row });
        return;
      }

      if (supportMatch) {
        respond(res, 403, { error: "support_access_denied" });
        return;
      }

      if (!isUuid(principal.tenantId)) {
        respond(res, 401, { error: "unauthorized" });
        return;
      }

      // Enqueue a tenant-owned job and its dispatch metadata atomically.
      if (req.method === "POST" && isJobsCollection) {
        const body = await readJson(req);
        if (body === null || typeof body !== "object" || Array.isArray(body)) {
          throw httpError(400, "a JSON object is required");
        }
        if (body.tenant_id !== undefined && body.tenant_id !== principal.tenantId) {
          respond(res, 403, { error: "tenant_scope_mismatch" });
          return;
        }
        if (typeof body.payload !== "string" || body.payload.length < 1 || body.payload.length > 1000) {
          throw httpError(400, "payload must contain 1 to 1000 characters");
        }

        const jobId = randomUUID();
        await withAuthorizedTenantTransaction(pool, principal, async (client) => {
          await client.query(
            "INSERT INTO public.tenant_jobs (tenant_id, job_id, subject_id, payload) VALUES ($1, $2, $3, $4)",
            [principal.tenantId, jobId, principal.subjectId, body.payload]
          );
          await client.query(
            "INSERT INTO public.job_dispatch (tenant_id, job_id) VALUES ($1, $2)",
            [principal.tenantId, jobId]
          );
        });
        respond(res, 202, { data: { job_id: jobId, status: "queued" } });
        return;
      }

      // Caller-supplied tenant hints are deliberately ignored.
      if (req.method === "GET" && isCollection) {
        const rows = await withAuthorizedTenantTransaction(pool, principal, async (client) => {
          const result = await client.query(
            "SELECT record_id, natural_key, payload FROM public.tenant_records ORDER BY natural_key, record_id"
          );
          return result.rows;
        });
        respond(res, 200, { data: rows });
        return;
      }

      if (req.method === "GET" && recordMatch) {
        const recordId = recordMatch[1];
        if (!isUuid(recordId)) {
          respond(res, 404, { error: "not_found" });
          return;
        }
        const row = await withAuthorizedTenantTransaction(pool, principal, async (client) => {
          const result = await client.query(
            "SELECT record_id, natural_key, payload FROM public.tenant_records WHERE record_id = $1",
            [recordId]
          );
          return result.rows[0] ?? null;
        });
        if (!row) {
          respond(res, 404, { error: "not_found" });
          return;
        }
        respond(res, 200, { data: row });
        return;
      }

      if (req.method === "POST" && isCollection) {
        const body = await readJson(req);
        if (body === null || typeof body !== "object" || Array.isArray(body)) {
          throw httpError(400, "a JSON object is required");
        }
        if (body.tenant_id !== undefined && body.tenant_id !== principal.tenantId) {
          respond(res, 403, { error: "tenant_scope_mismatch" });
          return;
        }
        if (typeof body.natural_key !== "string" || body.natural_key.length < 1 || body.natural_key.length > 80) {
          throw httpError(400, "natural_key must contain 1 to 80 characters");
        }
        if (typeof body.payload !== "string" || body.payload.length > 1000) {
          throw httpError(400, "payload must be a string of at most 1000 characters");
        }

        if (body.record_id !== undefined && !isUuid(body.record_id)) {
          throw httpError(400, "record_id must be a valid UUID when supplied");
        }
        const recordId = body.record_id ?? randomUUID();
        const row = await withAuthorizedTenantTransaction(pool, principal, async (client) => {
          const result = await client.query(
            "INSERT INTO public.tenant_records (tenant_id, record_id, natural_key, payload) VALUES ($1, $2, $3, $4) RETURNING record_id, natural_key, payload",
            [principal.tenantId, recordId, body.natural_key, body.payload]
          );
          return result.rows[0];
        });
        respond(res, 201, { data: row });
        return;
      }

      respond(res, 405, { error: "method_not_allowed" });
    } catch (error) {
      const status = Number.isInteger(error.statusCode) ? error.statusCode : 500;
      respond(res, status, {
        error: status === 500 ? "internal_error" : status === 403 ? "forbidden" : "bad_request",
        message: status === 500 ? "request failed" : error.message
      });
    }
  });
}
