import test from "node:test";
import assert from "node:assert/strict";
import { ContractViolation, validateEvent } from "../../p09-contract-recovery/contract.mjs";

const validEvent = (overrides = {}) => ({
  specversion: "1.0",
  id: "provider-event-001",
  source: "urn:lottorito:provider:synthetic",
  type: "com.synthetic.settlement.posted.v1",
  time: "2026-11-25T12:00:00.123Z",
  dataschema: "urn:lottorito:schema:synthetic-settlement:1",
  tenantid: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  scope: { kind: "product", id: "affiliate_agent" },
  sourceeventid: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
  schemaversion: 1,
  traceparent: "00-0123456789abcdef0123456789abcdef-0123456789abcdef-00",
  data: { amount_minor: "12500", currency_code: "USD" },
  ...overrides
});

test("JavaScript validator accepts the canonical provider settlement envelope", () => {
  const result = validateEvent(validEvent());
  assert.equal(result.identity[1], "product");
  assert.equal(result.identity[2], "affiliate_agent");
  assert.equal(result.schema_version, 1);
  assert.equal(result.trace_id, "0123456789abcdef0123456789abcdef");
});

test("JavaScript validator enforces RFC3339 calendar and offset semantics", () => {
  for (const time of ["2026-02-30T12:00:00Z", "2026-11-25 12:00:00Z",
    "2026-11-25T24:00:00Z", "2026-11-25T12:00:00+24:00", "November 25, 2026"]) {
    assert.throws(() => validateEvent(validEvent({ time })), ContractViolation);
  }
});

test("JavaScript validator enforces URI-reference syntax and percent escapes", () => {
  for (const source of ["", "not a uri", "urn:bad:%Q0", "https://[::1"]) {
    assert.throws(() => validateEvent(validEvent({ source })), ContractViolation);
  }
  assert.equal(validateEvent(validEvent({ source: "../provider/events" })).event_type,
    "com.synthetic.settlement.posted.v1");
});

test("JavaScript validator rejects zero trace and parent identifiers", () => {
  for (const traceparent of [
    "00-00000000000000000000000000000000-0123456789abcdef-00",
    "00-0123456789abcdef0123456789abcdef-0000000000000000-00"
  ]) {
    assert.throws(() => validateEvent(validEvent({ traceparent })), ContractViolation);
  }
});

test("JavaScript validator rejects non-canonical UUID and unsafe schema versions", () => {
  assert.throws(() => validateEvent(validEvent({
    sourceeventid: "BBBBBBBB-BBBB-4BBB-8BBB-BBBBBBBBBBBB"
  })), /source_event_id_invalid/);
  assert.throws(() => validateEvent(validEvent({ schemaversion: 9007199254740992 })),
    /schema_version_invalid/);
});

test("JavaScript validator rejects financial events in platform scope", () => {
  assert.throws(() => validateEvent(validEvent({
    scope: { kind: "platform", id: "lottorito" }
  })), /financial_event_requires_product_scope/);
});

test("JavaScript validator permits a non-financial platform event", () => {
  const result = validateEvent(validEvent({
    type: "platform.tenant.provisioned",
    scope: { kind: "platform", id: "lottorito" }
  }));
  assert.deepEqual(result.identity.slice(1, 3), ["platform", "lottorito"]);
});
