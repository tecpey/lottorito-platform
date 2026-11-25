# P-09 — Cross-Prototype Contract & Recovery Integration

**Document ID:** LOT-PROT-P09-001 | **Version:** 0.4.0 | **Status:** Proposed cross-prototype contract; P-09A passed and P-09B scope-aware P-06 correlation passed on synthetic CI; no production approval

**Status:** Proposed contract baseline; implementation and owner approval remain open.  
**Baseline:** `integration/p03d-p04-p08-candidate` at `c7f9ffa1f499fbd34d260b2aa6d3122d32e1ac7f`.  
**Execution branch:** `spike/p09-cross-prototype-contract-recovery`.  
**Safety:** Synthetic fixtures only. No merge, main update, production integration, destructive migration or deployment.

## 1. Problem statement

P-02/P-03D use tenant/product-scoped financial and provider identities, while P-05B replay keys and its simplified ledger fixture omit the product dimension. P-06 correlation is keyed by tenant/source event only and uses `platform` beside product names. P-07B authorizes producer/consumer product contracts but does not carry the P-03D source-event identity or P-06 trace context. P-08 artifact naming, metadata and provenance verification are hard-coded to Affiliate & Agent.

Passing each workflow on one candidate commit proves those defined test suites ran together; it does not prove a shared canonical identity, recovery path or product-independent release pipeline.

## 2. ADR-009 — Product scope vs platform scope

### Decision proposed

1. Canonical product identifiers are exactly `affiliate_agent` and `lottery` for the current product set.
2. `shared` is not a product. It is a legacy/ambiguous value and must not be silently translated.
3. `platform` is a scope kind, not a product identifier. Its stable scope ID is `lottorito`.
4. Every event has a discriminated scope:
   - Product: `{ "kind": "product", "id": "affiliate_agent" | "lottery" }`
   - Platform: `{ "kind": "platform", "id": "lottorito" }`
5. Financial effects and journals are product-only. A platform-scoped event cannot post a financial journal.
6. A tenant-scoped source-event identity is the tuple `(tenant_id, scope_kind, scope_id, source_event_id)`. UUIDs alone are not globally unique identities.
7. Economic-effect and journal identities are respectively `(tenant_id, product_id, economic_effect_id)` and `(tenant_id, product_id, journal_id)`.
8. Trace correlation includes `(tenant_id, scope_kind, scope_id, source_event_id, trace_id)`. W3C trace IDs correlate distributed work; they do not replace business identity or authorization.

### Rationale

Affiliate & Agent and Lottery must remain independently adoptable. Platform capabilities are shared infrastructure with explicit ownership, not a third customer-facing product. Conflating `shared`, `platform` and a product creates ambiguous uniqueness, authorization, telemetry and artifact provenance. Explicit scope prevents an event with the same UUID in two products from colliding or being correlated across product boundaries.

### Alternatives considered

- **Treat `shared` as a product:** rejected; it confuses infrastructure ownership with a product boundary.
- **Treat `platform` as an alias for `shared`:** rejected; aliases hide inconsistent historical data and do not solve identity.
- **Keep tenant-only UUID keys:** rejected; source IDs can collide across products within one tenant.
- **Infer product from payload or consumer:** rejected; identity must come from trusted producer/install context and a validated contract.

### Compatibility and migration

The existing P-02/P-03D schemas are experiments, not a production migration target. P-02 currently contains legacy `shared` allowances and several tenant-only primary/unique keys; P-03D is more explicit in provider inbox keys. No destructive schema edit is made in this first P-09 slice.

Before migration, inventory every existing row and producer. Product scope must be derived from trusted database role/installation and verified against source records. Ambiguous `shared` rows are quarantined for owner adjudication and reconciliation; never bulk-map them to Affiliate, Lottery or Platform. The target schema must use composite foreign keys and unique constraints carrying the same scope dimensions as the identity tuples.

## 3. Canonical event envelope

The machine-readable baseline is `prototypes/p09-contract-recovery/contract.json`. Events use CloudEvents 1.0 context attributes plus explicit `tenantid`, `scope`, `sourceeventid` and positive integer `schemaversion`. `sourceeventid` is the stable business source identity, distinct from the CloudEvents envelope `id` (delivery/envelope identity). `dataschema` identifies the payload schema. W3C `traceparent` is propagated separately.

A financial event must carry product scope. A platform event may carry platform scope but cannot be used as a ledger posting command. The event's tenant, product/platform scope, provider installation, schema and authorization are validated from trusted context; untrusted payload values are not authority.

## 4. Cross-prototype conformance map

| Prototype | Existing shape | P-09 target / gap |
|---|---|---|
| P-02 | Some identities and uniqueness constraints are tenant-only; `shared` is allowed | Composite tenant/product identity; product-only financial effects and journals |
| P-03D | Provider inbox includes tenant + product + provider + provider-event and source event | Preserve this boundary; map to canonical source/effect/journal tuples |
| P-05B | Inbox and replay cursor omit product; writes a separate simplified ledger fixture | Replay the actual P-02/P-03D records after restore; product-scoped cursor and inbox |
| P-06 | `correlation_map` PK is tenant + source event; product domain includes `platform` | Include scope kind/id in correlation key; map platform to platform scope |
| P-07B | Producer/consumer products and schema version are checked; no canonical source identity/trace mapping | Bind event authorization to canonical envelope, source identity and trace context |
| P-08 | Build and verifier hard-code Affiliate & Agent | Product becomes an explicit allow-listed build input, included in artifact metadata and provenance |

## 5. P-09 implementation sequence

- **P-09A — Contract baseline:** canonical scope model, identity tuples, envelope, stdlib validator and negative/positive tests. This PR implements this first slice.
- **P-09B — P-06 correlation:** product/platform scoped correlation key; collision tests with identical source UUIDs in Affiliate and Lottery and denial of cross-scope reads.
- **P-09C — P-08 product-aware artifacts:** parameterized Affiliate and Lottery build, product-bound artifact metadata/provenance, compatibility and promotion/rollback tests.
- **P-09D — P-07B event contract mapping:** producer contract, consumer authorization, canonical source identity, schema version and W3C trace context.
- **P-09E — P-05B recovery integration:** restore/replay the same P-02/P-03D schema and records; prove order, idempotency, fencing, reconciliation and product isolation.
- **P-09F — integrated failure/concurrency suite:** disposable candidate, duplicate delivery, sequence gaps, conflicting product IDs, interrupted replay, restore failure, stale trace/correlation, artifact tampering and rollback.

## 6. Acceptance gates

- Same source-event UUID in Affiliate and Lottery remains two distinct identities for the same tenant.
- `shared` cannot pass as a product; platform scope cannot create financial effects or journals.
- Event envelope requires explicit tenant, scope, source identity, schema and CloudEvents context.
- P-06 lookup cannot disclose or ambiguously resolve a source event from another product.
- P-07B cannot authorize an event whose producer identity, tenant, scope, schema or trace contract is inconsistent.
- P-08 can build and verify separate Affiliate and Lottery artifacts; provenance binds the selected product and exact artifact digest.
- P-05 recovery restores and replays the actual ledger/outbox/provider-inbox records, not a parallel accounting model.
- Positive, negative, concurrency and injected-failure cases pass on the exact final candidate SHA; no skipped checks counted as passes.
- Persian and English documents are updated in the same change and semantically reviewed.

## 7. Explicit non-goals

No real provider, production KMS/HSM, broker, object store, customer data, production database, money movement, accounting policy, RPO/RTO commitment, production deployment or release approval. No PR is merged and no main-branch ref is modified.

## P-09B — Product-scoped observability correlation

The P-06 implementation now uses the canonical tenant/scope/source-event tuple for correlation uniqueness, forensic access grants and view filtering. A deterministic adversarial case reuses one source-event UUID and trace ID across Affiliate and Lottery within the same tenant; each product's audited forensic grant must reveal exactly its own row. This closes the prior tenant-only correlation ambiguity in the synthetic P-06 slice. It does not yet make P-05 recovery, P-07B event authorization or P-08 artifact provenance conformant; those remain separate P-09 slices.


### P-09B acceptance evidence

- P-09A contract workflow: [45628562955](https://github.com/tecpey/lottorito-platform/actions/runs/45628562955) passed, including JSON validation, compilation and 13/13 tests.
- P-06 scope-aware correlation: [45628562800](https://github.com/tecpey/lottorito-platform/actions/runs/45628562800) passed on exact branch head `109530985a00bd158866e45a8c11e3bb5f520f53`.
- Documentation Governance: [45628562765](https://github.com/tecpey/lottorito-platform/actions/runs/45628562765) passed (58 bilingual pairs, 136 local links).

The P-06 fixture now proves product-scoped uniqueness and forensic filtering for colliding source-event UUIDs. P-05B, P-07B and P-08 remain open integration gates.

### P-09C acceptance evidence

P-08 product-aware build/provenance and lifecycle enforcement passed in [45629980686](https://github.com/tecpey/lottorito-platform/actions/runs/45629980686): **53/53 tests**. Both product artifacts are built independently; the product identity is embedded in the artifact payload, release metadata and provenance. The deployment controller rejects promotion and rollback across product scopes. This closes the synthetic P-08 slice only; P-05B recovery and P-07B event-contract alignment remain open.

### P-09D acceptance evidence

P-07B now validates the canonical product event envelope: tenant UUID, producer-bound product scope, source-event UUID, schema version and W3C traceparent. The dispatch result returns the exact source identity tuple and trace ID required by P-06. CI [45631269584](https://github.com/tecpey/lottorito-platform/actions/runs/45631269584) passed **42/42 tests**. The registry and synthetic tenant fixtures now use the same identity types as the P-09 contract. Platform-originated events are not implicitly accepted by product service identities.
