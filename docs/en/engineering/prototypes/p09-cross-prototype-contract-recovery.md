# P-09 — Cross-Prototype Contract & Recovery Integration

**Document ID:** LOT-PROT-P09-001 | **Version:** 0.6.0 | **Status:** Proposed cross-prototype contract; P-09A passed and P-09B scope-aware P-06 correlation passed on synthetic CI; no production approval

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
- **P-09E — shared-record recovery integration:** restore/replay the same P-02/P-03D schema and records; prove atomic rollback, idempotency, reconciliation and product isolation. Aggregate ordering remains a separate follow-up because P-03D has no aggregate-sequence contract.
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


### P-09E acceptance evidence

P-09E passed in the P-05 recovery workflow [45635972222](https://github.com/tecpey/lottorito-platform/actions/runs/45635972222) on exact candidate head 73d7d0daa46e6a019020fc25ace315836d270a6f. The run applied the actual P-02, P-03C and P-03D SQL schemas in a separate disposable database, took a physical base backup, passed pg_verifybackup, started an isolated restored cluster, injected and verified rollback of a failed posting transaction, replayed three accepted P-03D inbox records through P-02 post_journal, verified idempotent retry, product/tenant RLS after restore, balanced journals, outbox delivery-state atomicity and zero provider-to-ledger reconciliation exceptions. The same source-event UUID and provider event ID were deliberately reused across Affiliate/Lottery for one tenant and Affiliate for a second tenant.

Documentation Governance [45635972312](https://github.com/tecpey/lottorito-platform/actions/runs/45635972312) passed on the same head (58 bilingual Markdown pairs and 136 local links). This closes the P-09E physical restore + transactional replay slice only. It does not prove aggregate sequence ordering, concurrent stale-lease fencing, full Node.js provider-worker orchestration, production PITR architecture, RPO/RTO, or production readiness; those remain explicit follow-up gates.

### P-09E latest exact-head confirmation

P-05 recovery [45637659268](https://github.com/tecpey/lottorito-platform/actions/runs/45637659268) passed again on 2b393cc8c41226a20333f34559ac6952883901a3. P-09E markers confirm physical backup, pg_verifybackup, isolated restore, actual P-02/P-03C/P-03D schema and records, injected transaction rollback, provider-inbox replay, financial-effect idempotency, outbox delivery-state atomicity, tenant/product RLS after restore, same-source-UUID collision isolation and zero provider/ledger/outbox reconciliation exceptions. P-05A PITR, P-05B and negative-WAL drills also passed. Documentation Governance [45637659297](https://github.com/tecpey/lottorito-platform/actions/runs/45637659297) passed on the same head (58 bilingual Markdown pairs, 136 local links).


### P-09F concurrency and scope-isolation acceptance slice

P-03C/P-03D workflow [45637659485](https://github.com/tecpey/lottorito-platform/actions/runs/45637659485) passed on 2b393cc8c41226a20333f34559ac6952883901a3: P-03C **15/15**, P-03D **25/25**, zero failures. Three tests use the real Node.js 26 provider worker on PostgreSQL 18.7: (1) two workers race to claim one event; exactly one lease is granted, and concurrent processing resolves to one `processed` and one `stale` with one journal/outbox/delivery row; (2) an expired lease is reclaimed and old/current lease holders race, with the old token rejected and only the current token posting; (3) the same provider event ID and source-event UUID across Affiliate/Lottery in one tenant and Affiliate in a second tenant are processed independently, with one journal/outbox/delivery per scope and zero reconciliation exceptions.

PostgreSQL documents `FOR UPDATE SKIP LOCKED` as suitable for queue-like consumers, while warning it gives an inconsistent view unsuitable for general-purpose reads ([SELECT locking clause](https://www.postgresql.org/docs/18/sql-select.html), [row-level locks](https://www.postgresql.org/docs/18/explicit-locking.html)). Lease tokens provide an additional application-level fencing condition, not a substitute for row locks.

This closes only the first P-09F concurrency/scope slice. Aggregate sequence semantics are not defined in P-03D; direct Node-worker replay on the P-09E restored cluster and broader failure interleavings remain open.


### P-09A validator conformance correction — 2026-11-25

An independent contract-to-validator review found that `contract.json` declared `traceparent` mandatory while `validate_event()` did not enforce its presence. The validator now requires the field and validates the W3C Trace Context version-00 shape, lowercase hexadecimal encoding, and non-zero trace-id and parent-id. The returned validated event includes the trace ID for downstream correlation. Bare correlation trace IDs also reject the all-zero value.

Regression coverage now includes missing traceparent, malformed/version-invalid values, zero trace-id/parent-id, and all-zero correlation IDs. The paired P-09A suite is expected to contain 15 tests; CI must pass on the exact new PR head before acceptance is claimed. This correction does not yet validate RFC 3339 timestamps or URI-reference semantics, nor does it wire the validator into P-02–P-08.

Research basis: [W3C Trace Context Recommendation](https://www.w3.org/TR/trace-context/) (version-00 traceparent format and invalid all-zero identifiers); [CloudEvents Core Specification](https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md) (required core attributes and extension-attribute model).


### P-09G — Semantic event validation (2026-11-25)

P-09 now validates non-empty CloudEvents `id` and `type`, non-empty RFC 3986 URI-reference forms for `source` and `dataschema`, and RFC 3339 date-time syntax with calendar, clock and offset range checks. CloudEvents extension attributes remain permitted. The Lottorito-specific required envelope remains declared in `contract.json`.

The explicit `ledger.journal.posted` event type is product-scope-only: platform-scoped financial events are rejected, while non-financial platform events remain structurally valid. This is a narrow policy rule, not a complete event-type registry. P-07B remains responsible for producer-bound authorization. Runtime ingress/dispatch wiring is a separate P-09H gate.


### P-09H — Runtime ingress, dispatch and replay enforcement (2026-11-25)

The canonical validator now has a Node.js implementation at `prototypes/p09-contract-recovery/contract.mjs`, aligned with the Python validator for UUID shape, scope, CloudEvents attributes, RFC 3986 URI-reference characters, RFC 3339 time, schema version and W3C Trace Context v00. The provider worker consumes this implementation directly rather than maintaining a third, independent validation rule set.

P-03D now constructs its canonical envelope only from trusted installation metadata and an explicitly approved event mapping. After raw-body signature verification, it binds tenant and product scope from the installation, uses the provider event ID as the CloudEvents `id`, generates a distinct canonical `sourceeventid` and a new trace context, and persists the same source-event UUID in both the envelope and inbox row. A provider-supplied tenant/product field cannot override these values. Missing schema mappings and non-RFC3339 event times are rejected before inbox persistence. The stored envelope and its tenant/product/source-event identity are validated again before journal posting; corrupted identity is quarantined before any economic effect.

P-07B dispatch invokes the shared Python validator after its existing authentication, producer-scope and denial-reason checks. P-05E recovery/replay checks the persisted envelope against the inbox row and refuses to post if tenant, product, provider event, source event, schema or trace metadata disagree. Its synthetic recovery fixtures now carry the full required envelope.

These are synthetic prototype integrations, not production deployment evidence. P-09H acceptance remains contingent on the complete CI matrix for the exact final PR head; live provider integrations, production key custody, and production runtime wiring remain out of scope.


P-09H also bounds `schemaversion` to the interoperable JSON safe-integer range (1 through 9007199254740991) in both language implementations, preventing Python's arbitrary-precision integers from accepting values that JavaScript cannot represent exactly.


The Node.js contract implementation now has a dedicated direct conformance suite under the P-03D test runner, covering valid envelopes, malformed RFC3339 dates, URI-reference failures, zero trace identifiers, non-canonical UUIDs, unsafe schema versions and financial platform-scope rejection. This complements—not replaces—the Python P-09 unit suite and end-to-end signed-ingress tests.


### P-09I — Observability and release-provenance identity (2026-11-25)

The contract inventory was reconciled with the actual P-06 and P-07B schemas: P-06 already stores tenant, scope kind, scope ID and source-event identity in its composite correlation key, while P-07B already enforces source-event identity and trace context. P-09I removes the stale inventory claims and makes the integration executable. P-06 imports the P-09 validator and derives its correlation identity from a validated CloudEvent; P-08 imports the P-09 product registry and binds a canonical product scope into both artifact metadata and detached provenance. The P-08 gate rejects product/scope substitution. P-09I acceptance passed on code-bearing head `d76b55944911a6366f01dff930ab5fb4de23688e`. Evidence: P-03C/P-03D [run 45657721071](https://github.com/tecpey/lottorito-platform/actions/runs/45657721071) (15/15 and 35/35 tests); P-05 recovery [run 45657721185](https://github.com/tecpey/lottorito-platform/actions/runs/45657721185) (`replay_contract_corruption_blocked`, P09E, P05B and P05A negative drills all PASS); P-05C [run 45657721462](https://github.com/tecpey/lottorito-platform/actions/runs/45657721462); P-06 [run 45657721183](https://github.com/tecpey/lottorito-platform/actions/runs/45657721183); P-07B [run 45657721263](https://github.com/tecpey/lottorito-platform/actions/runs/45657721263) (43/43 tests); P-08 [run 45657721443](https://github.com/tecpey/lottorito-platform/actions/runs/45657721443) (56/56 tests); P-09 [run 45657721322](https://github.com/tecpey/lottorito-platform/actions/runs/45657721322) (20/20 tests); and Documentation Governance [run 45657721181](https://github.com/tecpey/lottorito-platform/actions/runs/45657721181) (58 bilingual pairs and 136 local links). These are synthetic prototype acceptance results, not production certification.

### P-09J — Product-qualified P-05B replay and legacy token rejection (2026-11-25)

P-05B now carries canonical `product_id` through its inbox, replay cursor, source-event fixture, journal/line writes, and product-aware RLS identity map. Primary/unique keys distinguish the same source-event, economic-effect and aggregate identifiers across Affiliate & Agent and Lottery. A same-product duplicate economic effect still collapses; cross-product reuse is isolated. Cursor `FOR UPDATE` serialization is exercised with two concurrent Affiliate workers and a concurrent Lottery worker using the same aggregate identifier. Sequence gaps, transaction rollback, retry/no-op, journal balance, product-level reconciliation and tenant/product RLS are asserted.

P-02's disposable schema rejects new `shared` product values. Existing legacy records are not rewritten: they require inventory and quarantine pending an authoritative owner mapping. P-02's tenant-only financial keys remain an explicitly open follow-up and are not represented as solved by P-09J.

**Validation:** the exact source-code head `dfaa8120340cc6b4b80450dbf0e5755b21111080` passed all nine applicable workflows. Synthetic acceptance only; no production migration, merge or deployment.

### P-09J exact-head workflow evidence

All results below ran on source-code head dfaa8120340cc6b4b80450dbf0e5755b21111080.

| Workflow | Run | Result |
|---|---:|---|
| P-05 recovery / P-09E / P-05B | [45662750801](https://github.com/tecpey/lottorito-platform/actions/runs/45662750801) | PASS — PITR, physical restore, replay, product scope and concurrency |
| P-02 ledger posting | [45662750926](https://github.com/tecpey/lottorito-platform/actions/runs/45662750926) | PASS — 26/26 |
| P-09 contract | [45662750745](https://github.com/tecpey/lottorito-platform/actions/runs/45662750745) | PASS — 20/20 |
| P-03C/P-03D | [45662750837](https://github.com/tecpey/lottorito-platform/actions/runs/45662750837) | PASS — 15/15 and 35/35 |
| P-06 observability/privacy | [45662750890](https://github.com/tecpey/lottorito-platform/actions/runs/45662750890) | PASS |
| P-05C failover/fencing | [45662750722](https://github.com/tecpey/lottorito-platform/actions/runs/45662750722) | PASS |
| P-07B trust boundaries | [45662750966](https://github.com/tecpey/lottorito-platform/actions/runs/45662750966) | PASS — 43 tests |
| P-08 deployment health/rollback | [45662750833](https://github.com/tecpey/lottorito-platform/actions/runs/45662750833) | PASS — 56 tests |
| Documentation Governance | [45662750791](https://github.com/tecpey/lottorito-platform/actions/runs/45662750791) | PASS — 58 bilingual pairs, 136 local links |

P-05B's exact assertions included duplicate aggregate-sequence rejection, product-scoped event/effect identity, independent cursors, concurrent same-product serialization, cross-product RLS on Inbox/source events/journals/lines, rollback and ledger reconciliation. P-02's 26/26 tests include rejection of new legacy shared values. Existing legacy data was not rewritten.

These results establish synthetic prototype acceptance only. P-02 tenant-only financial keys remain open. No production migration, merge or deployment was performed.

### P-09K — Product-qualified financial keys across P-02, P-03C, P-03D and P-09E (2026-11-26)

P-02 now uses `(tenant_id, product_id, ...)` for every financial primary/unique key and every financial foreign-key relationship. P-03C delivery state and consumer inbox now reference the immutable P-02 outbox with `(tenant_id, product_id, event_id)`; claim/update/expiry operations preserve the product dimension. P-03D provider inbox, conflict and expectation records accept canonical product IDs only and retain product-qualified journal references. The same account UUIDs are deliberately reused by Affiliate & Agent and Lottery, with access resolved exclusively by database session product identity. P-09E physical recovery/replay uses those same identifiers to verify that the composite product boundary survives backup and restore.

The first P-09K CI cycle exposed dependent fixtures that still assumed product-specific account UUIDs and a tenant-only outbox event key. Those were corrected at P-03C/P-03D/P-09E boundaries. Exact-head CI remains pending. No production migration is implied; legacy data still requires inventory, collision analysis, and an approved staged migration plan.

### P-09K exact-head validation (2026-11-26)

All nine applicable workflows passed on source head `75148b41220bb26adf0e8c01e05860a8fd83d7fa`:

| Workflow | Run | Result |
|---|---:|---|
| P-02 Ledger Posting | [45862006791](https://github.com/tecpey/lottorito-platform/actions/runs/45862006791) | PASS — 27/27 |
| P-03C/P-03D Ledger and Provider Integration | [45862006903](https://github.com/tecpey/lottorito-platform/actions/runs/45862006903) | PASS — 16/16 + 35/35 |
| P-05 Backup Restore, Object, Key and Event Recovery | [45862006811](https://github.com/tecpey/lottorito-platform/actions/runs/45862006811) | PASS — P-09E, P-05B and P-05A |
| P-05C Failover/Fencing/Failback | [45862006891](https://github.com/tecpey/lottorito-platform/actions/runs/45862006891) | PASS |
| P-06 Observability/Privacy | [45862006805](https://github.com/tecpey/lottorito-platform/actions/runs/45862006805) | PASS |
| P-07B Trust Boundaries | [45862006830](https://github.com/tecpey/lottorito-platform/actions/runs/45862006830) | PASS |
| P-08 Deployment Health/Rollback | [45862006895](https://github.com/tecpey/lottorito-platform/actions/runs/45862006895) | PASS |
| P-09 Contract Baseline | [45862006822](https://github.com/tecpey/lottorito-platform/actions/runs/45862006822) | PASS — 20/20 |
| Documentation Governance | [45862006823](https://github.com/tecpey/lottorito-platform/actions/runs/45862006823) | PASS — 58 bilingual pairs, 136 local links |

P-09K is synthetic acceptance only. No production migration, merge or deployment is approved.

### P-09L — Product-qualified schema evolution in P-04 (2026-11-26)

The independent P-04 migration lab now binds database roles to tenant and product. Partner event PK/RLS/backfill, journal and line PK/FK, and reporting keys/RLS all include product scope. Affiliate & Agent and Lottery deliberately reuse the same event and journal UUIDs for Tenant A, while v1/v2 roles coexist independently in each product. The lab verifies cross-product read/write denial, per-product resumable backfill and unchanged product-level ledger/reporting totals. CI is pending exact-head validation. This does not modify production schemas or imply a production migration.
