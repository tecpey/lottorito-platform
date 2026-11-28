import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const prefix = process.env.SCHEMA_TOOLS_PREFIX;
assert.ok(prefix, "SCHEMA_TOOLS_PREFIX must point to the isolated pinned schema-tools install");
const require = createRequire(path.join(prefix, "package.json"));
const Ajv2020Module = require("ajv/dist/2020");
const AjvModule = require("ajv");
const addFormatsModule = require("ajv-formats");
const Ajv2020 = Ajv2020Module.default ?? Ajv2020Module;
const AjvDraft7 = AjvModule.default ?? AjvModule;
const addFormats = addFormatsModule.default ?? addFormatsModule;

const readJson = (file) => JSON.parse(fs.readFileSync(file, "utf8"));
const openApi = readJson("contracts/openapi/affiliate-management.v1.json");
const partnerApi = readJson("contracts/openapi/partner-event-ingestion.v1.json");
const asyncApi = readJson("contracts/asyncapi/affiliate-domain-events.v1.json");
const validationManifest = readJson("contracts/validation/affiliate-contract-validation-manifest.v1.json");

const ajv2020 = new Ajv2020({ allErrors: true, strict: false });
addFormats(ajv2020);
const ajv07 = new AjvDraft7({ allErrors: true, strict: false });
addFormats(ajv07);

let assertions = 0;
let activeSchemaRoot = null;
const executedFixtures = [];
const coveredSchemaRoots = new Set();
function contractAssert(label, condition) {
  assert.equal(condition, true, label);
  assertions += 1;
}
function recordFixture(label) {
  assert.ok(activeSchemaRoot, "Fixture has no active schema root: " + label);
  executedFixtures.push({ id: label, schemaRoot: activeSchemaRoot });
  coveredSchemaRoots.add(activeSchemaRoot);
}
function valid(label, validate, value) {
  const ok = validate(value);
  assert.equal(ok, true, label + ": expected valid; errors=" + JSON.stringify(validate.errors));
  recordFixture(label);
  assertions += 1;
}
function invalid(label, validate, value) {
  const ok = validate(value);
  assert.equal(ok, false, label + ": expected invalid but validation passed");
  recordFixture(label);
  assertions += 1;
}

const oasSchemas = openApi.components.schemas;
const HTTP_METHODS = new Set(["get", "post", "put", "patch", "delete", "head", "options", "trace"]);
function operationEntries(document) {
  return Object.entries(document.paths ?? {}).flatMap(([route, pathItem]) =>
    Object.entries(pathItem ?? {})
      .filter(([method]) => HTTP_METHODS.has(method.toLowerCase()))
      .map(([method, operation]) => ({ route, method: method.toLowerCase(), operation })));
}
function validateOperationSecurity(document, expected) {
  const errors = [];
  const scheme = expected.securityScheme;
  const declaredScheme = document.components?.securitySchemes?.[scheme];
  if (!declaredScheme || declaredScheme.type !== "http" || declaredScheme.scheme?.toLowerCase() !== "bearer") {
    errors.push("Expected HTTP bearer scheme " + scheme + " is missing or has the wrong type");
  }
  const entries = operationEntries(document);
  const seen = new Set();
  for (const entry of entries) {
    const route = entry.route;
    const method = entry.method;
    const operation = entry.operation;
    const id = operation.operationId;
    if (!id || !Object.hasOwn(expected.operations, id)) {
      errors.push("Undeclared operation " + method.toUpperCase() + " " + route + " (" + (id ?? "missing operationId") + ")");
      continue;
    }
    if (seen.has(id)) errors.push("Duplicate operationId: " + id);
    seen.add(id);
    const security = operation.security;
    if (!Array.isArray(security) || security.length !== 1 || !security[0] ||
        typeof security[0] !== "object" || Array.isArray(security[0])) {
      errors.push(id + " must declare exactly one non-optional Security Requirement Object");
    } else {
      const requirement = security[0];
      const keys = Object.keys(requirement).sort();
      if (keys.length !== 1 || keys[0] !== scheme) {
        errors.push(id + " must use only security scheme " + scheme + "; got " + (keys.join(",") || "empty requirement"));
      } else if (!Array.isArray(requirement[scheme]) || requirement[scheme].length !== 0) {
        errors.push(id + " HTTP bearer requirement must have an empty role/scope array");
      }
    }
    const actualScopes = operation["x-required-scopes"];
    const expectedScopes = expected.operations[id].requiredScopes;
    if (!Array.isArray(actualScopes) || actualScopes.length === 0 ||
        actualScopes.some((scope) => typeof scope !== "string" || scope.length === 0) ||
        new Set(actualScopes).size !== actualScopes.length ||
        JSON.stringify([...actualScopes].sort()) !== JSON.stringify([...expectedScopes].sort())) {
      errors.push(id + " x-required-scopes must exactly equal " + JSON.stringify(expectedScopes) + " with no duplicates");
    }
  }
  for (const id of Object.keys(expected.operations)) {
    if (!seen.has(id)) errors.push("Expected operation missing: " + id);
  }
  return errors;
}
function expectSecurityRejected(label, mutate) {
  const candidate = JSON.parse(JSON.stringify(openApi));
  mutate(candidate);
  contractAssert(label, validateOperationSecurity(candidate,
    validationManifest.operationSecurity["affiliate-management.v1.json"]).length > 0);
}
const managementExpected = validationManifest.operationSecurity["affiliate-management.v1.json"];
const ingestionExpected = validationManifest.operationSecurity["partner-event-ingestion.v1.json"];
contractAssert("Management operation security/scope mapping exactly matches manifest",
  validateOperationSecurity(openApi, managementExpected).length === 0);
contractAssert("Partner ingestion operation security/scope mapping exactly matches manifest",
  validateOperationSecurity(partnerApi, ingestionExpected).length === 0);
expectSecurityRejected("Security validator rejects an anonymous empty requirement object",
  (doc) => { doc.paths["/v1/affiliate/me"].get.security = [{}]; });
expectSecurityRejected("Security validator rejects the wrong bearer scheme",
  (doc) => { doc.paths["/v1/affiliate/me"].get.security = [{ partnerBearerAuth: [] }]; });
expectSecurityRejected("Security validator rejects an anonymous alternative",
  (doc) => { doc.paths["/v1/affiliate/me"].get.security.push({}); });
expectSecurityRejected("Security validator rejects a substituted scope",
  (doc) => { doc.paths["/v1/affiliate/me"].get["x-required-scopes"] = ["affiliate.links.read"]; });
expectSecurityRejected("Security validator rejects duplicate scopes",
  (doc) => { doc.paths["/v1/affiliate/me"].get["x-required-scopes"].push("affiliate.profile.read"); });
expectSecurityRejected("Security validator rejects an undocumented operation",
  (doc) => { doc.paths["/v1/affiliate/me"].get.operationId = "unexpectedOperation"; });
expectSecurityRejected("Security validator rejects a missing expected operation",
  (doc) => { delete doc.paths["/v1/affiliate/me"]; });

function oasValidator(name) {
  assert.ok(oasSchemas[name], "Missing OpenAPI schema: " + name);
  activeSchemaRoot = "management." + name;
  // OpenAPI 3.2.1 uses the OAS Schema Object dialect. This isolated Ajv instance
  // checks the currently used JSON Schema 2020-12-compatible instance subset only;
  // Redocly remains the complete OpenAPI document/dialect validator.
  return ajv2020.compile({
    $schema: "https://json-schema.org/draft/2020-12/schema",
    components: { schemas: oasSchemas },
    $ref: "#/components/schemas/" + name,
  });
}

const program = oasValidator("Program");
valid("Program", program, { id: "program-1", name: "Standard", status: "active" });
invalid("Program rejects unknown status", program, { id: "p", name: "N", status: "enabled" });
invalid("Program rejects undeclared properties", program, { id: "p", name: "N", status: "active", tenantId: "t2" });

const programPage = oasValidator("ProgramPage");
valid("ProgramPage resolves local $ref", programPage, { data: [{ id: "p", name: "N", status: "draft" }], nextCursor: null });
valid("ProgramPage accepts the documented maximum page size", programPage, { data: Array.from({ length: 100 }, (_, i) => ({ id: `p-${i}`, name: "N", status: "draft" })) });
invalid("ProgramPage rejects more than 100 items", programPage, { data: Array.from({ length: 101 }, (_, i) => ({ id: `p-${i}`, name: "N", status: "draft" })) });
invalid("ProgramPage rejects invalid nested Program", programPage, { data: [{ id: "p", name: "N", status: "unknown" }] });

const affiliateSelf = oasValidator("AffiliateSelf");
valid("AffiliateSelf", affiliateSelf, { membershipId: "m-1", displayName: null, status: "active", roles: ["affiliate"] });
invalid("AffiliateSelf rejects duplicate roles", affiliateSelf, { membershipId: "m-1", status: "active", roles: ["affiliate", "affiliate"] });

const createReferralLink = oasValidator("CreateReferralLink");
valid("CreateReferralLink", createReferralLink, { programId: "p-1", destinationKey: "public-home", campaignId: null, expiresAt: null });
invalid("CreateReferralLink rejects arbitrary destination URL field", createReferralLink, { programId: "p-1", destinationKey: "public-home", destinationUrl: "https://attacker.example" });
invalid("CreateReferralLink rejects malformed date-time", createReferralLink, { programId: "p-1", destinationKey: "public-home", expiresAt: "tomorrow" });

const referralLink = oasValidator("ReferralLink");
valid("ReferralLink", referralLink, { id: "r-1", programId: "p-1", destinationKey: "public-home", status: "active", createdAt: "2026-11-27T10:15:30Z", expiresAt: null });
invalid("ReferralLink rejects invalid status", referralLink, { id: "r-1", programId: "p-1", destinationKey: "public-home", status: "pending", createdAt: "2026-11-27T10:15:30Z" });

const attribution = oasValidator("Attribution");
valid("Attribution", attribution, { id: "a-1", status: "attributed", sourceReferralLinkId: "r-1", decidedAt: "2026-11-27T10:15:30Z", policyVersion: "v1" });
invalid("Attribution rejects missing decision timestamp", attribution, { id: "a-1", status: "attributed" });

const problem = oasValidator("Problem");
valid("Problem permits RFC 9457 extension members", problem, { type: "about:blank", title: "Conflict", status: 409, requestId: "req-1", traceHint: "opaque" });
invalid("Problem rejects non-error status", problem, { type: "about:blank", title: "OK", status: 200 });

const partnerSchema = partnerApi.components.schemas.PartnerCloudEvent;
activeSchemaRoot = "partner.PartnerCloudEvent";
const partnerEvent = ajv2020.compile({
  $schema: "https://json-schema.org/draft/2020-12/schema",
  $defs: { PartnerCloudEvent: partnerSchema },
  $ref: "#/$defs/PartnerCloudEvent",
});
function isValidCloudEventsString(value) {
  if (!value.isWellFormed() || /[\u0000-\u001f\u007f-\u009f]/u.test(value)) return false;
  for (const character of value) {
    const codePoint = character.codePointAt(0);
    if ((codePoint >= 0xfdd0 && codePoint <= 0xfdef) ||
        (codePoint & 0xffff) === 0xfffe || (codePoint & 0xffff) === 0xffff) return false;
  }
  return true;
}
function withCloudEventsStringSemantics(schemaValidator) {
  const validate = (event) => {
    if (!schemaValidator(event)) {
      validate.errors = schemaValidator.errors;
      return false;
    }
    for (const [name, value] of Object.entries(event)) {
      // "data" is the event payload, not a CloudEvents context attribute.
      // All other string-valued context attributes, core and extension, share
      // the CloudEvents String constraints.
      if (name !== "data" && typeof value === "string" && !isValidCloudEventsString(value)) {
        validate.errors = [{ keyword: "cloudEventsString", message: "context string contains a prohibited Unicode code point" }];
        return false;
      }
    }
    validate.errors = null;
    return true;
  };
  return validate;
}
const partnerEventValidator = withCloudEventsStringSemantics(partnerEvent);

const partnerFixture = {
  specversion: "1.0",
  id: "source-event-1",
  source: "urn:partner:configured-source",
  type: "com.partner.registration.v1",
  time: "2026-11-27T10:15:30Z",
  datacontenttype: "application/json",
  data: { externalSubjectReference: "subject-1" },
  traceparent: "00-opaque",
};
valid("Partner CloudEvent with top-level extension attribute", partnerEventValidator, partnerFixture);
invalid("Partner CloudEvent rejects missing source identity", partnerEventValidator, { ...partnerFixture, id: "" });
invalid("Partner CloudEvent rejects unsupported specversion", partnerEventValidator, { ...partnerFixture, specversion: "0.3" });
invalid("Partner CloudEvent rejects wrong data content type", partnerEventValidator, { ...partnerFixture, datacontenttype: "text/plain" });
invalid("Partner CloudEvent rejects non-object data", partnerEventValidator, { ...partnerFixture, data: "not-an-object" });
invalid("Partner CloudEvent enforces data maxProperties", partnerEventValidator, { ...partnerFixture, data: Object.fromEntries(Array.from({ length: 65 }, (_, i) => [`k${i}`, i])) });
invalid("Partner CloudEvent rejects uppercase extension name", partnerEventValidator, { ...partnerFixture, TraceParent: "00-opaque" });
invalid("Partner CloudEvent rejects extension name with underscore", partnerEventValidator, { ...partnerFixture, trace_parent: "00-opaque" });
invalid("Partner CloudEvent rejects extension name over 20 characters", partnerEventValidator, { ...partnerFixture, abcdefghijklmnopqrstu: "x" });
invalid("Partner CloudEvent rejects array extension value", partnerEventValidator, { ...partnerFixture, traceparent: ["bad"] });
invalid("Partner CloudEvent rejects null extension value", partnerEventValidator, { ...partnerFixture, traceparent: null });
invalid("Partner CloudEvent rejects object extension value", partnerEventValidator, { ...partnerFixture, traceparent: { value: "bad" } });
invalid("Partner CloudEvent rejects out-of-range integer extension", partnerEventValidator, { ...partnerFixture, retrycount: 2147483648 });
invalid("Partner CloudEvent rejects extension string control character", partnerEventValidator, { ...partnerFixture, traceparent: "bad\u0001value" });
invalid("Partner CloudEvent rejects extension string unpaired surrogate", partnerEventValidator, { ...partnerFixture, traceparent: "\uD800" });
invalid("Partner CloudEvent rejects extension string Unicode noncharacter", partnerEventValidator, { ...partnerFixture, traceparent: "\uFDD0" });
invalid("Partner CloudEvent rejects prohibited Unicode in core id", partnerEventValidator, { ...partnerFixture, id: "bad\u0001id" });

activeSchemaRoot = "partner.EventReceipt";
const receipt = ajv2020.compile({
  $schema: "https://json-schema.org/draft/2020-12/schema",
  $defs: partnerApi.components.schemas,
  $ref: "#/$defs/EventReceipt",
});
valid("EventReceipt", receipt, { receiptId: "rcpt-1", status: "accepted", acceptedAt: "2026-11-27T10:15:31Z", duplicate: false, correlationId: "c-1" });
invalid("EventReceipt rejects unknown status", receipt, { receiptId: "rcpt-1", status: "done", acceptedAt: "2026-11-27T10:15:31Z", duplicate: false, correlationId: "c-1" });

activeSchemaRoot = "partner.Problem";
const partnerProblem = ajv2020.compile({
  $schema: "https://json-schema.org/draft/2020-12/schema",
  $defs: partnerApi.components.schemas,
  $ref: "#/$defs/Problem",
});
valid("Partner Problem Details", partnerProblem, { type: "about:blank", title: "Unavailable", status: 503, code: "temporary_unavailable" });
invalid("Partner Problem Details rejects non-error status", partnerProblem, { type: "about:blank", title: "OK", status: 200 });

const canonicalSchema = asyncApi.components.messages.AffiliateCanonicalEvent.payload;
const canonicalMessage = asyncApi.components.messages.AffiliateCanonicalEvent;
contractAssert("AsyncAPI 3.0 payload is its default Schema Object, not mislabeled as Draft 07",
  asyncApi.asyncapi === "3.0.0" && !Object.hasOwn(canonicalMessage, "schemaFormat"));
const unsupportedAsyncApiSchemaKeywords = new Set([
  "discriminator", "externalDocs", "example", "deprecated", "nullable",
  "readOnly", "writeOnly", "xml",
]);
function assertDraft7CompatibleSubset(value, at = "$") {
  if (Array.isArray(value)) {
    value.forEach((item, index) => assertDraft7CompatibleSubset(item, at + "[" + index + "]"));
    return;
  }
  if (!value || typeof value !== "object") return;
  for (const [key, child] of Object.entries(value)) {
    assert.ok(!unsupportedAsyncApiSchemaKeywords.has(key),
      "AsyncAPI-only schema keyword " + key + " at " + at + " is not covered by the Ajv Draft 07 subset validator");
    assertDraft7CompatibleSubset(child, at + "/" + key);
  }
}
assertDraft7CompatibleSubset(canonicalSchema);
// AsyncAPI 3.0 defaults this payload to its Schema Object, a superset of JSON Schema
// Draft 07. Ajv checks only the current Draft-07-compatible subset; AsyncAPI CLI
// validates the complete document and its normative schema dialect.
activeSchemaRoot = "asyncapi.AffiliateCanonicalEvent.payload";
const canonicalEvent = ajv07.compile(canonicalSchema);
const canonicalEventValidator = withCloudEventsStringSemantics(canonicalEvent);
const canonicalFixture = asyncApi.components.messages.AffiliateCanonicalEvent.examples[0].payload;
valid("Canonical Affiliate CloudEvent example", canonicalEventValidator, canonicalFixture);
valid("Canonical event allows a top-level CloudEvents extension", canonicalEventValidator, { ...canonicalFixture, tenantregion: "eu" });
invalid("Canonical event rejects missing trusted tenant context", canonicalEventValidator, (() => { const x = { ...canonicalFixture }; delete x.tenantid; return x; })());
invalid("Canonical event rejects wrong product domain", canonicalEventValidator, { ...canonicalFixture, productdomain: "wallet" });
invalid("Canonical event rejects unversioned/non-domain event type", canonicalEventValidator, { ...canonicalFixture, type: "affiliate.registration" });
invalid("Canonical event rejects malformed timestamp", canonicalEventValidator, { ...canonicalFixture, receivedat: "not-a-date" });
invalid("Canonical event rejects non-object data", canonicalEventValidator, { ...canonicalFixture, data: [] });
invalid("Canonical event rejects uppercase extension name", canonicalEventValidator, { ...canonicalFixture, TenantRegion: "eu" });
invalid("Canonical event rejects invalid extension value type", canonicalEventValidator, { ...canonicalFixture, tenantregion: ["eu"] });
invalid("Canonical event rejects out-of-range integer extension", canonicalEventValidator, { ...canonicalFixture, retrycount: -2147483649 });
invalid("Canonical event rejects extension string control character", canonicalEventValidator, { ...canonicalFixture, tenantregion: "bad\u0001value" });
invalid("Canonical event rejects extension string unpaired surrogate", canonicalEventValidator, { ...canonicalFixture, tenantregion: "\uD800" });
invalid("Canonical event rejects extension string Unicode noncharacter", canonicalEventValidator, { ...canonicalFixture, tenantregion: "\uFDD0" });
invalid("Canonical event rejects prohibited Unicode in core id", canonicalEventValidator, { ...canonicalFixture, id: "bad\u0001id" });


const PARAMETER_DOCUMENTS = [
  { prefix: "management", document: openApi },
  { prefix: "ingestion", document: partnerApi },
];

function resolveJsonPointer(root, reference) {
  if (reference === "#") return root;
  if (typeof reference !== "string" || !reference.startsWith("#/")) {
    throw new Error("Only local JSON Pointer references are supported in parameter coverage: " + reference);
  }
  const tokens = reference.slice(2).split("/").map((token) =>
    token.replace(/~1/g, "/").replace(/~0/g, "~"));
  return tokens.reduce((value, token) => {
    if (!value || typeof value !== "object" || !Object.hasOwn(value, token)) {
      throw new Error("Unresolvable local reference: " + reference);
    }
    return value[token];
  }, root);
}

function resolveParameter(document, rawParameter, operationLabel) {
  let parameter = rawParameter;
  const visited = new Set();
  while (parameter && typeof parameter === "object" && typeof parameter.$ref === "string") {
    const reference = parameter.$ref;
    if (visited.has(reference)) throw new Error("Cyclic parameter reference at " + operationLabel + ": " + reference);
    visited.add(reference);
    parameter = resolveJsonPointer(document, reference);
  }
  if (!parameter || typeof parameter !== "object" || Array.isArray(parameter)) {
    throw new Error("Parameter reference did not resolve to an object at " + operationLabel);
  }
  return { parameter, reference: rawParameter.$ref ?? null };
}

function collectEffectiveParameters(document, prefix) {
  const collected = [];
  for (const [route, pathItem] of Object.entries(document.paths ?? {})) {
    for (const [method, operation] of Object.entries(pathItem ?? {})) {
      if (!HTTP_METHODS.has(method.toLowerCase())) continue;
      const operationLabel = method.toUpperCase() + " " + route;
      const inherited = new Map();
      for (const raw of pathItem.parameters ?? []) {
        const resolved = resolveParameter(document, raw, operationLabel);
        const key = resolved.parameter.in + "\u0000" + resolved.parameter.name;
        if (inherited.has(key)) throw new Error("Duplicate path-item parameter " + key + " at " + operationLabel);
        inherited.set(key, resolved);
      }
      const overrides = new Map();
      for (const raw of operation.parameters ?? []) {
        const resolved = resolveParameter(document, raw, operationLabel);
        const key = resolved.parameter.in + "\u0000" + resolved.parameter.name;
        if (overrides.has(key)) throw new Error("Duplicate operation parameter " + key + " at " + operationLabel);
        overrides.set(key, resolved);
      }
      const effective = new Map(inherited);
      for (const [key, value] of overrides) effective.set(key, value);
      for (const resolved of effective.values()) {
        const parameter = resolved.parameter;
        if (typeof parameter.name !== "string" || typeof parameter.in !== "string") {
          throw new Error("Parameter is missing name/in at " + operationLabel);
        }
        collected.push({
          id: prefix + "." + method.toUpperCase() + " " + route + " :: " + parameter.in + "." + parameter.name,
          operation: operationLabel,
          parameter,
          reference: resolved.reference,
        });
      }
    }
  }
  return collected;
}

function parameterSchemaDescriptor(parameter, parameterId) {
  if (parameter.schema && parameter.content) {
    throw new Error(parameterId + " must not declare both schema and content");
  }
  if (parameter.schema) {
    return { schema: parameter.schema, schemaKind: "schema", contentMediaType: null };
  }
  if (parameter.content && typeof parameter.content === "object") {
    const entries = Object.entries(parameter.content);
    if (entries.length !== 1 || !entries[0][1]?.schema) {
      throw new Error(parameterId + " content must contain exactly one media type with a schema");
    }
    return {
      schema: entries[0][1].schema,
      schemaKind: "content",
      contentMediaType: entries[0][0],
    };
  }
  throw new Error(parameterId + " has neither a schema nor a content schema");
}

function compileParameterSchema(document, schema) {
  // Keep the OpenAPI components namespace available so local component-schema
  // references inside a parameter schema resolve against the same contract.
  return ajv2020.compile({
    $schema: "https://json-schema.org/draft/2020-12/schema",
    components: document.components ?? {},
    parameterSchema: schema,
    $ref: "#/parameterSchema",
  });
}

function materializeParameterFixture(value) {
  if (value && typeof value === "object" && !Array.isArray(value) &&
      Object.keys(value).length === 1 && value.$repeatString) {
    const spec = value.$repeatString;
    assert.equal(typeof spec.character, "string", "repeatString character must be a string");
    assert.equal([...spec.character].length, 1, "repeatString character must be one Unicode code point");
    assert.ok(Number.isInteger(spec.length) && spec.length >= 0, "repeatString length must be a non-negative integer");
    return spec.character.repeat(spec.length);
  }
  return value;
}

const actualParameterEntries = PARAMETER_DOCUMENTS.flatMap(({ prefix, document }) =>
  collectEffectiveParameters(document, prefix));
const actualParameterMap = new Map(actualParameterEntries.map((entry) => [entry.id, entry]));
const expectedParameterEntries = validationManifest.parameterCoverage;
assert.ok(Array.isArray(expectedParameterEntries) && expectedParameterEntries.length > 0,
  "Manifest must enumerate effective OpenAPI parameter schemas");
const expectedParameterIds = expectedParameterEntries.map((entry) => entry.id).sort();
const actualParameterIds = actualParameterEntries.map((entry) => entry.id).sort();
contractAssert("Manifest enumerates every effective OpenAPI parameter exactly once",
  JSON.stringify(expectedParameterIds) === JSON.stringify(actualParameterIds) &&
  new Set(expectedParameterIds).size === expectedParameterIds.length);

const executedParameterFixtures = [];
const seenParameterFixtureIds = new Set();
for (const expected of expectedParameterEntries) {
  const actual = actualParameterMap.get(expected.id);
  assert.ok(actual, "Missing effective parameter: " + expected.id);
  const parameter = actual.parameter;
  contractAssert(expected.id + " required flag matches contract",
    (parameter.required ?? false) === expected.required);
  contractAssert(expected.id + " reference origin matches contract",
    actual.reference === expected.reference);
  const descriptor = parameterSchemaDescriptor(parameter, expected.id);
  contractAssert(expected.id + " schema representation matches manifest",
    descriptor.schemaKind === expected.schemaKind &&
    descriptor.contentMediaType === expected.contentMediaType);

  const validateParameter = compileParameterSchema(
    PARAMETER_DOCUMENTS.find((entry) => entry.prefix === expected.id.split(".")[0]).document,
    descriptor.schema
  );
  assert.ok(Array.isArray(expected.fixtures) && expected.fixtures.length >= 2,
    expected.id + " must have positive and negative boundary fixtures");
  const hasPositive = expected.fixtures.some((fixture) => fixture.valid === true);
  const hasNegative = expected.fixtures.some((fixture) => fixture.valid === false);
  contractAssert(expected.id + " has both positive and negative fixtures", hasPositive && hasNegative);

  for (const fixture of expected.fixtures) {
    const fixtureKey = expected.id + "::" + fixture.id;
    assert.ok(typeof fixture.id === "string" && fixture.id.length > 0, "Parameter fixture requires a stable ID");
    assert.ok(!seenParameterFixtureIds.has(fixtureKey), "Duplicate parameter fixture ID: " + fixtureKey);
    seenParameterFixtureIds.add(fixtureKey);
    const value = materializeParameterFixture(fixture.value);
    const validResult = validateParameter(value);
    assert.equal(validResult, fixture.valid,
      fixtureKey + ": expected " + (fixture.valid ? "valid" : "invalid") +
      "; errors=" + JSON.stringify(validateParameter.errors));
    executedParameterFixtures.push(fixtureKey);
    assertions += 1;
  }
}
const expectedParameterFixtureIds = expectedParameterEntries.flatMap((entry) =>
  entry.fixtures.map((fixture) => entry.id + "::" + fixture.id)).sort();
const actualParameterFixtureIds = executedParameterFixtures.sort();
contractAssert("Every parameter manifest fixture executes exactly once",
  JSON.stringify(expectedParameterFixtureIds) === JSON.stringify(actualParameterFixtureIds) &&
  new Set(expectedParameterFixtureIds).size === expectedParameterFixtureIds.length);

const expectedRoots = validationManifest.schemaRoots.map((entry) => entry.id).sort();
const actualRoots = [
  ...Object.keys(openApi.components.schemas).map((name) => "management." + name),
  ...Object.keys(partnerApi.components.schemas).map((name) => "partner." + name),
  "asyncapi.AffiliateCanonicalEvent.payload",
].sort();
contractAssert("Manifest enumerates every current OpenAPI/AsyncAPI schema root exactly once",
  JSON.stringify(expectedRoots) === JSON.stringify(actualRoots) && new Set(expectedRoots).size === expectedRoots.length);
const expectedFixtures = validationManifest.schemaRoots.flatMap((entry) =>
  entry.fixtureIds.map((id) => entry.id + "::" + id)).sort();
const actualFixtures = executedFixtures.map((entry) => entry.schemaRoot + "::" + entry.id).sort();
contractAssert("Every manifest fixture executes against its declared schema root, with no missing or extra fixtures",
  JSON.stringify(expectedFixtures) === JSON.stringify(actualFixtures) && new Set(actualFixtures).size === actualFixtures.length);
contractAssert("Every declared schema root has at least one executed fixture",
  validationManifest.schemaRoots.every((entry) => coveredSchemaRoots.has(entry.id) && entry.fixtureIds.length > 0));

console.log("Affiliate contract validation passed: " + assertions + " assertions; exact operation security/scope manifest; " + actualRoots.length + " schema roots; " + actualFixtures.length + " schema fixtures; " + actualParameterEntries.length + " effective parameters; " + actualParameterFixtureIds.length + " parameter fixtures.");
console.log("Dialect note: OpenAPI 3.2.1 instance subset uses Ajv 2020-12; AsyncAPI 3.0.0 defaults to its own Schema Object (a Draft 07 superset), with Ajv limited to the guarded Draft-07-compatible subset. Redocly and AsyncAPI CLI remain full-document validators.");
console.log("Scope note: this suite does not prove runtime authorization, tenant binding, installation-specific extension allowlists, Inbox/WorkItem atomicity, deduplication, durability, failover, ledger effects or provider compatibility.");
