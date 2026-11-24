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
export function createTenantServer({ pool, authenticate }) {
  if (!pool || typeof authenticate !== "function") {
    throw new TypeError("pool and authenticate are required");
  }

  return createServer(async (req, res) => {
    try {
      const url = new URL(req.url ?? "/", "http://localhost");
      const isCollection = url.pathname === "/records";
      const isJobsCollection = url.pathname === "/jobs";
      const recordMatch = url.pathname.match(/^\/records\/([0-9a-f-]+)$/i);

      if (!isCollection && !isJobsCollection && !recordMatch) {
        respond(res, 404, { error: "not_found" });
        return;
      }

      const principal = await authenticate(req);
      if (!principal || typeof principal.subjectId !== "string" || !isUuid(principal.tenantId)) {
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
