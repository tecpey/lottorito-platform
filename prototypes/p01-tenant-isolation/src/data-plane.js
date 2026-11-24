import { isUuid } from "./tenant-db.js";

const SAFE_SEGMENT = /^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/;

function requireTenant(tenantId) {
  if (!isUuid(tenantId)) throw new TypeError("A server-resolved tenant UUID is required");
  return tenantId.toLowerCase();
}

function requireSegment(value, label) {
  if (
    typeof value !== "string" ||
    !SAFE_SEGMENT.test(value) ||
    value === "." ||
    value === ".." ||
    value.includes("..") ||
    value.includes("%")
  ) {
    throw new TypeError(label + " must be one safe, non-path segment");
  }
}

export function tenantCacheKey(tenantId, namespace, logicalKey) {
  tenantId = requireTenant(tenantId);
  requireSegment(namespace, "namespace");
  requireSegment(logicalKey, "logical key");
  return "lottorito:v1:tenant:" + tenantId + ":cache:" + namespace + ":" + logicalKey;
}

export function tenantObjectKey(tenantId, namespace, objectId) {
  tenantId = requireTenant(tenantId);
  requireSegment(namespace, "namespace");
  requireSegment(objectId, "object ID");
  return "tenants/" + tenantId + "/" + namespace + "/" + objectId;
}

export class TenantScopedCache {
  constructor(backend) {
    if (!backend || typeof backend.get !== "function" || typeof backend.set !== "function" || typeof backend.delete !== "function") {
      throw new TypeError("cache backend must implement get, set and delete");
    }
    this.backend = backend;
  }

  get(tenantId, namespace, logicalKey) {
    return this.backend.get(tenantCacheKey(tenantId, namespace, logicalKey));
  }

  set(tenantId, namespace, logicalKey, value) {
    return this.backend.set(tenantCacheKey(tenantId, namespace, logicalKey), value);
  }

  delete(tenantId, namespace, logicalKey) {
    return this.backend.delete(tenantCacheKey(tenantId, namespace, logicalKey));
  }
}

export class TenantScopedObjectStore {
  constructor(backend) {
    if (!backend || typeof backend.get !== "function" || typeof backend.put !== "function" || typeof backend.delete !== "function") {
      throw new TypeError("object backend must implement get, put and delete");
    }
    this.backend = backend;
  }

  get(tenantId, namespace, objectId) {
    return this.backend.get(tenantObjectKey(tenantId, namespace, objectId));
  }

  put(tenantId, namespace, objectId, value) {
    return this.backend.put(tenantObjectKey(tenantId, namespace, objectId), value);
  }

  delete(tenantId, namespace, objectId) {
    return this.backend.delete(tenantObjectKey(tenantId, namespace, objectId));
  }
}

export class TenantScopedSearch {
  constructor(client) {
    if (!client || typeof client.search !== "function") {
      throw new TypeError("search client must implement search");
    }
    this.client = client;
  }

  search(tenantId, query) {
    tenantId = requireTenant(tenantId);
    if (
      typeof query !== "string" ||
      query.trim().length < 1 ||
      query.length > 256 ||
      /[\u0000-\u001f\u007f]/.test(query)
    ) {
      throw new TypeError("search query must contain 1 to 256 safe characters");
    }
    // Tenant filter is injected from trusted context, never from caller query data.
    return this.client.search({
      query,
      tenantFilter: Object.freeze({ tenant_id: tenantId })
    });
  }
}
