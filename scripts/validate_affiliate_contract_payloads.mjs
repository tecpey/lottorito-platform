import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const prefix = process.env.CONTRACT_TOOLS_PREFIX;
assert.ok(prefix, "CONTRACT_TOOLS_PREFIX must point to the pinned contract-tools install");
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

const ajv2020 = new Ajv2020({ allErrors: true, strict: false });
addFormats(ajv2020);
const ajv07 = new AjvDraft7({ allErrors: true, strict: false });
addFormats(ajv07);

let assertions = 0;
function valid(label, validate, value) {
  const ok = validate(value);
  assert.equal(ok, true, `${label}: expected valid; errors=${JSON.stringify(validate.errors)}`);
  assertions += 1;
}
function invalid(label, validate, value) {
  const ok = validate(value);
  assert.equal(ok, false, `${label}: expected invalid but validation passed`);
  assertions += 1;
}

const oasSchemas = openApi.components.schemas;
function oasValidator(name) {
  assert.ok(oasSchemas[name], `Missing OpenAPI schema: ${name}`);
  // The contract currently uses JSON Schema 2020-12 keywords only. Redocly validates
  // the complete OAS document and OAS dialect; Ajv validates representative instances.
  return ajv2020.compile({
    $schema: "https://json-schema.org/draft/2020-12/schema",
    components: { schemas: oasSchemas },
    $ref: `#/components/schemas/${name}`,
  });
}

const program = oasValidator("Program");
valid("Program", program, { id: "program-1", name: "Standard", status: "active" });
invalid("Program rejects unknown status", program, { id: "p", name: "N", status: "enabled" });
invalid("Program rejects undeclared properties", program, { id: "p", name: "N", status: "active", tenantId: "t2" });

const programPage = oasValidator("ProgramPage");
valid("ProgramPage resolves local $ref", programPage, { data: [{ id: "p", name: "N", status: "draft" }], nextCursor: null });
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
const partnerEvent = ajv2020.compile({
  $schema: "https://json-schema.org/draft/2020-12/schema",
  $defs: { PartnerCloudEvent: partnerSchema },
  $ref: "#/$defs/PartnerCloudEvent",
});
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
valid("Partner CloudEvent with top-level extension attribute", partnerEvent, partnerFixture);
invalid("Partner CloudEvent rejects missing source identity", partnerEvent, { ...partnerFixture, id: "" });
invalid("Partner CloudEvent rejects unsupported specversion", partnerEvent, { ...partnerFixture, specversion: "0.3" });
invalid("Partner CloudEvent rejects wrong data content type", partnerEvent, { ...partnerFixture, datacontenttype: "text/plain" });
invalid("Partner CloudEvent rejects non-object data", partnerEvent, { ...partnerFixture, data: "not-an-object" });
invalid("Partner CloudEvent enforces data maxProperties", partnerEvent, { ...partnerFixture, data: Object.fromEntries(Array.from({ length: 65 }, (_, i) => [`k${i}`, i])) });

const receipt = ajv2020.compile({
  $schema: "https://json-schema.org/draft/2020-12/schema",
  $defs: partnerApi.components.schemas,
  $ref: "#/$defs/EventReceipt",
});
valid("EventReceipt", receipt, { receiptId: "rcpt-1", status: "accepted", acceptedAt: "2026-11-27T10:15:31Z", duplicate: false, correlationId: "c-1" });
invalid("EventReceipt rejects unknown status", receipt, { receiptId: "rcpt-1", status: "done", acceptedAt: "2026-11-27T10:15:31Z", duplicate: false, correlationId: "c-1" });

const canonicalSchema = asyncApi.components.messages.AffiliateCanonicalEvent.payload;
// AsyncAPI 3.0.0 Schema Object defaults to Draft 07 unless schemaFormat overrides it.
const canonicalEvent = ajv07.compile(canonicalSchema);
const canonicalFixture = asyncApi.components.messages.AffiliateCanonicalEvent.examples[0].payload;
valid("Canonical Affiliate CloudEvent example", canonicalEvent, canonicalFixture);
valid("Canonical event allows a top-level CloudEvents extension", canonicalEvent, { ...canonicalFixture, tenantregion: "eu" });
invalid("Canonical event rejects missing trusted tenant context", canonicalEvent, (() => { const x = { ...canonicalFixture }; delete x.tenantid; return x; })());
invalid("Canonical event rejects wrong product domain", canonicalEvent, { ...canonicalFixture, productdomain: "wallet" });
invalid("Canonical event rejects unversioned/non-domain event type", canonicalEvent, { ...canonicalFixture, type: "affiliate.registration" });
invalid("Canonical event rejects malformed timestamp", canonicalEvent, { ...canonicalFixture, receivedat: "not-a-date" });
invalid("Canonical event rejects non-object data", canonicalEvent, { ...canonicalFixture, data: [] });

console.log(`Affiliate payload contract validation passed: ${assertions} assertions across OpenAPI 3.2.1 (JSON Schema 2020-12 instance subset) and AsyncAPI 3.0.0 (Draft 07).`);
console.log("Scope note: this suite validates schema instances and representative constraints; it does not test runtime authorization, tenant binding, Inbox/Job atomicity, deduplication, ledger effects, or provider allowlists.");
