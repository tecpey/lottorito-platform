import { isDeepStrictEqual } from "node:util";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const TRACEPARENT = /^00-([0-9a-f]{32})-([0-9a-f]{16})-([0-9a-f]{2})$/;
const URI_ALLOWED = new Set("-._~:/?#[]@!$&'()*+,;=%ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
const FINANCIAL_PRODUCT_ONLY = new Set(["ledger.journal.posted", "com.synthetic.settlement.posted.v1"]);

export class ContractViolation extends Error {
  constructor(code) { super(code); this.name = "ContractViolation"; this.code = code; }
}

function uriReference(value, field) {
  if (typeof value !== "string" || value.length === 0 ||
      [...value].some((char) => char.charCodeAt(0) > 127 || !URI_ALLOWED.has(char)) ||
      /%(?![0-9a-fA-F]{2})/.test(value)) {
    throw new ContractViolation(field + "_uri_reference_invalid");
  }
  const authority = value.match(/^[A-Za-z][A-Za-z0-9+.-]*:\/\/([^/?#]*)/);
  if (authority && authority[1].includes("[") && !/^\[[0-9a-fA-F:.]+\](?::[0-9]+)?$/.test(authority[1])) {
    throw new ContractViolation(field + "_uri_reference_invalid");
  }
  return value;
}

function rfc3339(value) {
  if (typeof value !== "string") throw new ContractViolation("event_time_invalid");
  const m = /^(\d{4})-(\d{2})-(\d{2})[Tt](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:[Zz]|([+-])(\d{2}):(\d{2}))$/.exec(value);
  if (!m) throw new ContractViolation("event_time_invalid");
  const [, y, mo, d, hh, mm, ss, , oh, om] = m;
  if (+hh > 23 || +mm > 59 || +ss > 60 || (oh !== undefined && (+oh > 23 || +om > 59))) {
    throw new ContractViolation("event_time_invalid");
  }
  const day = new Date(Date.UTC(+y, +mo - 1, +d));
  if (day.getUTCFullYear() !== +y || day.getUTCMonth() !== +mo - 1 || day.getUTCDate() !== +d) {
    throw new ContractViolation("event_time_invalid");
  }
  return value;
}

function scopeIdentity(scope) {
  if (!scope || typeof scope !== "object" || Array.isArray(scope) ||
      !isDeepStrictEqual(Object.keys(scope).sort(), ["id", "kind"])) {
    throw new ContractViolation("scope_shape_invalid");
  }
  if (scope.kind === "product" && ["affiliate_agent", "lottery"].includes(scope.id)) return ["product", scope.id];
  if (scope.kind === "platform" && scope.id === "lottorito") return ["platform", "lottorito"];
  throw new ContractViolation("scope_unknown_or_mismatched");
}

export function validateEvent(event) {
  if (!event || typeof event !== "object" || Array.isArray(event)) throw new ContractViolation("event_not_object");
  const required = ["specversion", "id", "source", "type", "time", "dataschema",
    "tenantid", "scope", "sourceeventid", "schemaversion", "traceparent"];
  if (required.some((key) => !Object.hasOwn(event, key))) throw new ContractViolation("event_required_attribute_missing");
  if (event.specversion !== "1.0") throw new ContractViolation("cloudevents_version_unsupported");
  if (typeof event.id !== "string" || !event.id || typeof event.type !== "string" || !event.type) {
    throw new ContractViolation("event_attribute_invalid");
  }
  uriReference(event.source, "source");
  uriReference(event.dataschema, "dataschema");
  rfc3339(event.time);
  if (typeof event.tenantid !== "string" || !UUID.test(event.tenantid)) {
    throw new ContractViolation("tenant_id_invalid");
  }
  if (typeof event.sourceeventid !== "string" || !UUID.test(event.sourceeventid)) {
    throw new ContractViolation("source_event_id_invalid");
  }
  const [scopeKind, scopeId] = scopeIdentity(event.scope);
  if (!Number.isSafeInteger(event.schemaversion) || event.schemaversion < 1) {
    throw new ContractViolation("schema_version_invalid");
  }
  if (typeof event.traceparent !== "string") throw new ContractViolation("traceparent_invalid");
  const trace = TRACEPARENT.exec(event.traceparent);
  if (!trace || /^0+$/.test(trace[1]) || /^0+$/.test(trace[2])) throw new ContractViolation("traceparent_invalid");
  if (FINANCIAL_PRODUCT_ONLY.has(event.type) && scopeKind !== "product") {
    throw new ContractViolation("financial_event_requires_product_scope");
  }
  return {
    identity: [event.tenantid, scopeKind, scopeId, event.sourceeventid],
    schema_version: event.schemaversion,
    event_type: event.type,
    trace_id: trace[1],
  };
}
