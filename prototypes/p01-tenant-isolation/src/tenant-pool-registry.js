import { isUuid } from "./tenant-db.js";

function normalizeTenantId(tenantId) {
  if (!isUuid(tenantId)) throw new TypeError("A server-resolved tenant UUID is required");
  return tenantId.toLowerCase();
}

export class TenantPoolCapacityError extends Error {
  constructor() {
    super("No tenant database pool can be safely evicted");
    this.name = "TenantPoolCapacityError";
    this.code = "TENANT_POOL_CAPACITY";
  }
}

export class TenantPoolRegistry {
  constructor({
    resolveCredential,
    createPool,
    maxTenantPools = 16,
    maxConnectionsPerPool = 4,
    idleTtlMs = 300000,
    now = Date.now
  }) {
    if (typeof resolveCredential !== "function" || typeof createPool !== "function") {
      throw new TypeError("resolveCredential and createPool are required");
    }
    if (!Number.isInteger(maxTenantPools) || maxTenantPools < 1) {
      throw new TypeError("maxTenantPools must be a positive integer");
    }
    if (!Number.isInteger(maxConnectionsPerPool) || maxConnectionsPerPool < 1) {
      throw new TypeError("maxConnectionsPerPool must be a positive integer");
    }
    if (!Number.isFinite(idleTtlMs) || idleTtlMs < 0 || typeof now !== "function") {
      throw new TypeError("idleTtlMs and now are invalid");
    }

    this.resolveCredential = resolveCredential;
    this.createPool = createPool;
    this.maxTenantPools = maxTenantPools;
    this.maxConnectionsPerPool = maxConnectionsPerPool;
    this.idleTtlMs = idleTtlMs;
    this.now = now;
    this.entries = new Map();
    this.pending = new Map();
    this.revokedTenants = new Set();
    this.closed = false;
    this.creationTail = Promise.resolve();
  }

  async withTenantPool(tenantId, operation) {
    const normalizedTenantId = normalizeTenantId(tenantId);
    if (typeof operation !== "function") throw new TypeError("operation must be a function");
    const entry = await this.#getEntry(normalizedTenantId);
    if (this.closed || this.revokedTenants.has(normalizedTenantId) || entry.revoked || entry.closed) {
      entry.pendingLeases -= 1;
      await this.#maybeCloseRetired(entry);
      throw new Error("tenant database access is unavailable");
    }

    entry.pendingLeases -= 1;
    entry.activeLeases += 1;
    entry.lastUsedAt = this.now();
    try {
      return await operation(entry.pool);
    } finally {
      entry.activeLeases -= 1;
      entry.lastUsedAt = this.now();
      await this.#maybeCloseRetired(entry);
    }
  }

  async evictIdle() {
    const cutoff = this.now() - this.idleTtlMs;
    const expired = [...this.entries.values()].filter(
      (entry) => entry.activeLeases === 0 && entry.pendingLeases === 0 && entry.lastUsedAt <= cutoff
    );
    for (const entry of expired) await this.#closeEntry(entry);
    return expired.length;
  }

  async revokeTenant(tenantId) {
    const normalizedTenantId = normalizeTenantId(tenantId);
    this.revokedTenants.add(normalizedTenantId);
    const entry = this.entries.get(normalizedTenantId);
    if (!entry) return false;
    entry.revoked = true;
    entry.retireWhenIdle = true;
    await this.#maybeCloseRetired(entry);
    return true;
  }

  async close() {
    if (this.closed) return;
    this.closed = true;
    for (const tenantId of this.entries.keys()) this.revokedTenants.add(tenantId);
    for (const entry of this.entries.values()) {
      entry.revoked = true;
      entry.retireWhenIdle = true;
    }
    await Promise.allSettled([...this.pending.values()]);
    const entries = [...this.entries.values()];
    await Promise.all(entries.map((entry) => this.#maybeCloseRetired(entry)));
    await Promise.all(entries.map((entry) => entry.closedPromise));
  }

  get size() {
    return this.entries.size;
  }

  async #getEntry(tenantId) {
    if (this.closed || this.revokedTenants.has(tenantId)) {
      throw new Error("tenant database access is unavailable");
    }
    const existing = this.entries.get(tenantId);
    if (existing && !existing.revoked && !existing.retireWhenIdle && !existing.closed) {
      existing.pendingLeases += 1;
      return existing;
    }
    const inFlight = this.pending.get(tenantId);
    if (inFlight) {
      const entry = await inFlight;
      if (entry.revoked || entry.retireWhenIdle || entry.closed || this.closed || this.revokedTenants.has(tenantId)) {
        throw new Error("tenant database access is unavailable");
      }
      entry.pendingLeases += 1;
      return entry;
    }

    const creation = this.#serializeCreation(async () => {
      if (this.closed || this.revokedTenants.has(tenantId)) {
        throw new Error("tenant database access is unavailable");
      }
      const raced = this.entries.get(tenantId);
      if (raced && !raced.revoked && !raced.retireWhenIdle && !raced.closed) return raced;
      await this.#ensureCapacity();

      let credential;
      try {
        credential = await this.resolveCredential(tenantId);
      } catch {
        throw new Error("tenant database credential resolution failed");
      }
      if (!credential || typeof credential.connectionString !== "string" || credential.connectionString.length < 1) {
        throw new Error("tenant database credential resolution failed");
      }

      let pool;
      try {
        pool = await this.createPool({
          connectionString: credential.connectionString,
          max: this.maxConnectionsPerPool,
          application_name: "lottorito-tenant-" + tenantId.slice(0, 8)
        });
      } catch {
        throw new Error("tenant database pool creation failed");
      }
      if (!pool || typeof pool.end !== "function" || typeof pool.query !== "function") {
        if (pool && typeof pool.end === "function") {
          try { await pool.end(); } catch { /* Keep factory failures sanitized. */ }
        }
        throw new Error("tenant database pool creation failed");
      }

      try {
        const identity = await pool.query(
          "SELECT session_user::text AS role_name, private.current_tenant_id()::text AS tenant_id"
        );
        if (identity.rowCount !== 1 || identity.rows[0]?.tenant_id !== tenantId) {
          throw new Error("database identity does not match requested tenant");
        }
      } catch {
        try { await pool.end(); } catch { /* Keep identity failures sanitized. */ }
        throw new Error("tenant database pool identity verification failed");
      }

      if (this.closed || this.revokedTenants.has(tenantId)) {
        await pool.end();
        throw new Error("tenant database access is unavailable");
      }

      const entry = {
        tenantId,
        pool,
        credentialVersion: typeof credential.version === "string" ? credential.version : "unversioned",
        activeLeases: 0,
        pendingLeases: 0,
        lastUsedAt: this.now(),
        revoked: false,
        retireWhenIdle: false,
        closed: false,
        closingPromise: null,
        closedPromise: null
      };
      entry.closedPromise = new Promise((resolve) => { entry.resolveClosed = resolve; });
      this.entries.set(tenantId, entry);
      return entry;
    });

    this.pending.set(tenantId, creation);
    try {
      const entry = await creation;
      if (entry.revoked || entry.retireWhenIdle || entry.closed || this.closed || this.revokedTenants.has(tenantId)) {
        throw new Error("tenant database access is unavailable");
      }
      entry.pendingLeases += 1;
      return entry;
    } finally {
      if (this.pending.get(tenantId) === creation) this.pending.delete(tenantId);
    }
  }

  async #ensureCapacity() {
    if (this.entries.size < this.maxTenantPools) return;
    const candidates = [...this.entries.values()]
      .filter((entry) => entry.activeLeases === 0 && entry.pendingLeases === 0 && !entry.closed)
      .sort((a, b) => a.lastUsedAt - b.lastUsedAt);
    if (candidates.length === 0) throw new TenantPoolCapacityError();
    await this.#closeEntry(candidates[0]);
  }

  async #maybeCloseRetired(entry) {
    if (!entry.retireWhenIdle || entry.activeLeases > 0 || entry.pendingLeases > 0) return;
    await this.#closeEntry(entry);
  }

  async #closeEntry(entry) {
    if (entry.closingPromise) return entry.closingPromise;
    if (entry.closed) return;
    entry.closed = true;
    if (this.entries.get(entry.tenantId) === entry) this.entries.delete(entry.tenantId);
    entry.closingPromise = (async () => {
      try {
        await entry.pool.end();
      } finally {
        entry.resolveClosed?.();
      }
    })();
    return entry.closingPromise;
  }

  async #serializeCreation(operation) {
    const previous = this.creationTail;
    let release;
    this.creationTail = new Promise((resolve) => { release = resolve; });
    await previous;
    try {
      return await operation();
    } finally {
      release();
    }
  }
}
