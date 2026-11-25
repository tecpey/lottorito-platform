# P-07B — Shared Platform Ownership and Trust Boundaries

**Document ID:** LOT-PROT-P07B-001 | **Version:** 0.2.0 | **Status:** Synthetic fixture validated in CI on PR head 42083a2

## Decision question

Can shared platform capabilities be governed by explicit ownership and least-privilege grants, while direct cross-product resource access and undocumented event consumption are denied by default?

P-07B is the second execution slice of P-07:
- P-07A: independent product build/runtime composition.
- **P-07B: shared capability ownership, tenant-aware authorization and event trust boundaries.**
- P-07C: independent product lifecycle, configuration, migration and operations.

## Research-informed design

The fixture separates a Policy Decision Point (PDP) from Policy Enforcement Points (PEPs). Decisions are based on service identity, service-to-tenant scope, tenant product entitlement, capability owner, requested operation and explicit consumer grants. Unknown identities, unavailable policy, unknown capabilities and missing grants fail closed.

This is an ABAC-inspired test model informed by NIST SP 800-162/800-205. It does not implement the OpenID AuthZEN protocol or select an authorization vendor. The enforcement model follows OWASP guidance: deny by default, least privilege, server-side enforcement at the protected operation, and auditable decisions.

Events use the CloudEvents 1.0 envelope (id, source, specversion, type) and the standard dataschema attribute. The fixture adds narrowly scoped tenantid and classification extensions. A consumer must match an explicit producer/type/schema contract, be named as an allowed consumer, and be entitled and service-scoped for the event tenant. A valid CloudEvents envelope alone never grants authorization.

## Ownership and access model

| Capability | Owner | Affiliate & Agent | Lottery |
|---|---|---|---|
| Identity | Platform Identity | resolve_subject | resolve_subject |
| Tenant | Platform Tenant | resolve_membership | resolve_membership |
| Finance | Platform Finance | post_journal | Denied |
| Notifications | Platform Notifications | request_delivery | request_delivery |
| Audit | Platform Audit | append_event | append_event |
| Affiliate network | Affiliate & Agent | Own resource only | Denied |
| Lottery domain | Lottery | Denied | Own resource only |

The tenant fixture contains three synthetic cases:
- tenant-alpha: Affiliate & Agent enabled; Lottery disabled.
- tenant-beta: both products enabled and within both service scopes.
- tenant-gamma: both product entitlements enabled, but neither service principal is scoped to this tenant.

This deliberately separates product entitlement from service-to-tenant authorization. A product being enabled for a tenant does not automatically grant every service identity access to that tenant.

## Cross-product event contract

One explicitly **test-only** contract permits a synthetic Affiliate & Agent signal to be consumed by Lottery:
- Producer product: affiliate_agent.
- Consumer product: lottery.
- Event type: com.lottorito.p07b.demo.signal.v1.
- Schema URI: urn:lottorito:schema:affiliate.demo.signal:1.
- Classification: exactly internal.
- Required payload field: reference.
- Payload contains no business, financial or personal data.

This hypothetical contract exists only to test the positive path. It does not approve or imply a production Affiliate-to-Lottery integration. No contract means deny.

## Experiments and pass criteria

| ID | Experiment | Pass criterion |
|---|---|---|
| P07B-01 | Shared capability grants | Each product can call only the explicitly granted platform capability operations |
| P07B-02 | Capability ownership | Unknown owners and sibling-owned product capabilities are denied |
| P07B-03 | Product resource isolation | A product cannot directly access a sibling-owned resource |
| P07B-04 | Tenant authorization | Service tenant scope and product entitlement are both required |
| P07B-05 | Default deny / fail closed | Unknown identity, capability, operation or unavailable policy is denied |
| P07B-06 | Producer authenticity binding | The event source must match the authenticated producer product |
| P07B-07 | Explicit event contract | Missing contract or unauthorized consumer is denied; the test-only contract permits only its named consumer |
| P07B-08 | Schema and classification | CloudEvents profile, exact dataschema, required fields and contract classification are enforced |
| P07B-09 | Data minimization | Sensitive payload keys and unregistered context extensions are denied |
| P07B-10 | Audit hygiene | Authorization audit records contain decision metadata, not credentials or payload content |

CI is defined in .github/workflows/p07b-shared-trust-boundaries.yml. A pass is recorded only against the exact PR head after both integration and Documentation Governance complete.

## Reproduction

From the repository root:

~~~bash
python3 -m json.tool prototypes/p07-shared-trust-boundaries/registry/capabilities.json
python3 -m json.tool prototypes/p07-shared-trust-boundaries/registry/tenant-entitlements.json
python3 -m json.tool prototypes/p07-shared-trust-boundaries/registry/event-contracts.json
python3 -m compileall -q prototypes/p07-shared-trust-boundaries
python3 -m unittest discover -s prototypes/p07-shared-trust-boundaries/tests -v
~~~

## Explicit limitations

- Synthetic fixture only. Service tokens are static test credentials; there is no cryptographic authentication, OAuth/OIDC, signed claims, key rotation or production identity provider.
- PDP/PEP are local Python functions, not deployed authorization services. AuthZEN is a design reference, not implemented.
- Capability and entitlement registries are static JSON fixtures, not a database-backed policy administration system.
- The event dispatcher is not a broker and does not prove delivery guarantees, retries, ordering, replay protection, idempotency, encryption, signatures or consumer isolation in a real transport.
- The CloudEvents profile validator is intentionally narrow; it is not a complete CloudEvents conformance suite or JSON Schema validator.
- Sensitive-key screening is a fixture-level denylist, not DLP, semantic classification or proof that all PII/secrets are detected.
- The synthetic audit list is not immutable or tamper-evident.
- No PostgreSQL RLS, database grants, object storage, cache, search index or cross-tenant data isolation is proven.
- The test-only Affiliate-to-Lottery event does not authorize a production integration or change the MVP boundary. Lottery ticketing, draws and prizes remain out of scope.
- No vendor, authorization engine, event broker, microservice split, database topology or production policy is approved. No merge or deployment is performed.

## Research references

- NIST, [SP 800-162 — Guide to ABAC](https://csrc.nist.gov/pubs/sp/800/162/upd2/final).
- NIST, [SP 800-205 — Attribute Considerations for Access Control Systems](https://csrc.nist.gov/pubs/sp/800/205/final).
- OWASP, [Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html) and [Authorization Patterns](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Patterns_Cheat_Sheet.html).
- OpenID Foundation, [AuthZEN Authorization API 1.0](https://openid.net/wg/authzen/specifications/).
- CNCF, [CloudEvents Specification 1.0.2](https://github.com/cloudevents/spec/tree/v1.0.2).
- Pact, [Contract Testing](https://docs.pact.io/).


## CI evidence

- Integration [run 45570485750](https://github.com/tecpey/lottorito-platform/actions/runs/45570055150): PASS on PR head 78c69234; all 33 tests passed.
- Push integration [run 45570199339](https://github.com/tecpey/lottorito-platform/actions/runs/45570037120): PASS.
- Documentation Governance [run 45570485718](https://github.com/tecpey/lottorito-platform/actions/runs/45570055148): PASS on the same PR head.
- PR [#57](https://github.com/tecpey/lottorito-platform/pull/57) remains Draft, open and unmerged.

## P-09D canonical event identity and trace-context addendum (2026-11-25)

P-07B now requires a product-scoped envelope aligned to ADR-009: canonical UUID tenant identity, explicit `scope={kind: product, id: source_product}`, canonical UUID `sourceeventid`, positive integer `schemaversion`, and W3C Trace Context `traceparent`. The contract registry binds source scope, schema version and required envelope fields. The dispatch result exposes the canonical source-event tuple and trace ID for mapping to P-06 correlation. Synthetic tenant fixtures were converted from labels to UUIDs so the same tenant identity type is used across P-02/P-03D/P-06/P-07B. P-07B CI [45631269584](https://github.com/tecpey/lottorito-platform/actions/runs/45631269584) passed **42/42 tests**. Product-originated P-07B events currently require product scope; platform-originated events remain a separately governed future extension.


### P-09H — Shared contract enforcement (2026-11-25)

P-07B event dispatch now invokes the canonical Python validator from P-09 after its existing principal authentication, tenant/product scope and detailed denial checks. This preserves P-07B's established denial reasons for its existing authorization cases while adding the common CloudEvents, URI-reference and RFC3339 conformance gate. The synthetic event fixture now includes the profile-required `time` attribute. Runtime policy remains prototype-only.
