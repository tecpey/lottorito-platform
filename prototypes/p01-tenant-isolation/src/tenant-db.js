const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isUuid(value) {
  return typeof value === "string" && UUID_PATTERN.test(value);
}

/**
 * Run tenant-scoped queries on one checked-out connection and one transaction.
 * set_config(..., true) is transaction-local; it must never be issued outside
 * this transaction or on a different pooled connection.
 */
export async function withTenantTransaction(pool, tenantId, operation) {
  if (!isUuid(tenantId)) {
    throw new TypeError("A server-resolved tenant UUID is required");
  }

  const client = await pool.connect();
  let transactionOpen = false;
  let destroyConnection = null;

  try {
    await client.query("BEGIN");
    transactionOpen = true;
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenantId]);

    const result = await operation(client);
    await client.query("COMMIT");
    transactionOpen = false;
    return result;
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
