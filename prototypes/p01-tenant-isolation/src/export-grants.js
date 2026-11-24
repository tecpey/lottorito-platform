import { createHash, randomBytes, randomUUID } from "node:crypto";
import { isUuid, withTenantTransaction } from "./tenant-db.js";

const TOKEN_PATTERN = /^[A-Za-z0-9_-]{43}$/;
const DEFAULT_TTL_SECONDS = 300;
const MIN_TTL_SECONDS = 60;
const MAX_TTL_SECONDS = 600;

function validSubject(subjectId) {
  return typeof subjectId === "string" && subjectId.length >= 1 && subjectId.length <= 160;
}

function hashToken(token) {
  if (typeof token !== "string" || !TOKEN_PATTERN.test(token)) return null;
  const decoded = Buffer.from(token, "base64url");
  if (decoded.length !== 32 || decoded.toString("base64url") !== token) return null;
  return createHash("sha256").update(decoded).digest();
}

export async function issueExportDownloadGrant({
  pool,
  tenantId,
  exportId,
  subjectId,
  ttlSeconds = DEFAULT_TTL_SECONDS
}) {
  if (!pool || typeof pool.connect !== "function") throw new TypeError("database pool is required");
  if (!isUuid(tenantId) || !isUuid(exportId)) throw new TypeError("server-resolved tenant and export UUIDs are required");
  if (!validSubject(subjectId)) throw new TypeError("authenticated subject is required");
  if (!Number.isInteger(ttlSeconds) || ttlSeconds < MIN_TTL_SECONDS || ttlSeconds > MAX_TTL_SECONDS) {
    throw new RangeError("download grant TTL must be between 60 and 600 seconds");
  }

  const rawToken = randomBytes(32).toString("base64url");
  const tokenHash = hashToken(rawToken);
  const grantId = randomUUID();

  return withTenantTransaction(pool, tenantId, async (client) => {
    const ownedExport = await client.query(
      `SELECT export_id
         FROM public.tenant_exports
        WHERE export_id = $1
          AND created_by = $2
          AND status = 'ready'`,
      [exportId, subjectId]
    );
    if (ownedExport.rowCount !== 1) return null;

    const inserted = await client.query(
      `INSERT INTO public.export_download_grants
         (grant_id, tenant_id, export_id, subject_id, token_hash, expires_at)
       VALUES ($1, $2, $3, $4, $5, clock_timestamp() + ($6 * interval '1 second'))
       RETURNING expires_at`,
      [grantId, tenantId, exportId, subjectId, tokenHash, ttlSeconds]
    );

    return Object.freeze({
      grantId,
      token: rawToken,
      expiresAt: inserted.rows[0].expires_at
    });
  });
}

export async function consumeExportDownloadGrant({
  pool,
  tenantId,
  subjectId,
  token
}) {
  if (!pool || typeof pool.connect !== "function") throw new TypeError("database pool is required");
  if (!isUuid(tenantId)) throw new TypeError("server-resolved tenant UUID is required");
  if (!validSubject(subjectId)) throw new TypeError("authenticated subject is required");
  const tokenHash = hashToken(token);
  if (!tokenHash) return null;

  return withTenantTransaction(pool, tenantId, async (client) => {
    const selected = await client.query(
      `SELECT g.grant_id, g.export_id, g.expires_at, g.consumed_at,
              g.revoked_at, e.object_key, e.content_sha256, e.status AS export_status
         FROM public.export_download_grants AS g
         JOIN public.tenant_exports AS e
           ON e.tenant_id = g.tenant_id
          AND e.export_id = g.export_id
        WHERE g.tenant_id = $1
          AND g.subject_id = $2
          AND g.token_hash = $3
        FOR UPDATE OF g`,
      [tenantId, subjectId, tokenHash]
    );
    const grant = selected.rows[0];
    if (
      !grant ||
      grant.consumed_at !== null ||
      grant.revoked_at !== null ||
      grant.export_status !== "ready" ||
      new Date(grant.expires_at).getTime() <= Date.now()
    ) {
      return null;
    }

    const consumed = await client.query(
      `UPDATE public.export_download_grants
          SET consumed_at = clock_timestamp()
        WHERE grant_id = $1
          AND tenant_id = $2
          AND consumed_at IS NULL
          AND revoked_at IS NULL
          AND expires_at > clock_timestamp()
       RETURNING grant_id`,
      [grant.grant_id, tenantId]
    );
    if (consumed.rowCount !== 1) return null;

    return Object.freeze({
      exportId: grant.export_id,
      objectKey: grant.object_key,
      contentSha256: grant.content_sha256
    });
  });
}
