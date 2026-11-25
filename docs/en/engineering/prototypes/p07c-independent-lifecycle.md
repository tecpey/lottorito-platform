# P-07C — Independent Product Lifecycle, Release and White-Label Traceability

**Document ID:** LOT-PROT-P07C-001 | **Version:** 0.1.0 | **Status:** Synthetic fixture validated in CI on PR head f488f34

## Decision question

Can each product be enabled, configured, migrated, promoted and rolled back independently for a tenant, while preserving shared platform capabilities, existing data/ledger state and tenant/operator traceability?

P-07C is the third execution slice of P-07:
- P-07A: product build/runtime isolation.
- P-07B: shared capability ownership and trust boundaries.
- **P-07C: independent lifecycle, configuration, migration, release operations and white-label traceability.**

## Research-informed design

The fixture treats tenant product enablement, product configuration, schema lifecycle and release promotion as separate state transitions. A product toggle cannot disable shared Identity, Tenant, Finance, Notifications or Audit capabilities and cannot delete product data or ledger history.

Configuration is namespaced by tenant and product. Secret values are never accepted; only opaque secret references are permitted. Migration ownership is explicit. Product migrations can update only the owning product schema; shared-platform migrations require the platform migration role. Expand migrations require the active release to support the target schema. Contract migrations additionally require the designated new release and retirement of any incompatible rollback pointer. Retiring a rollback pointer does not delete the old artifact or data.

Release promotion validates product identity, staging environment, schema compatibility, artifact digest and a synthetic in-toto/SLSA provenance-shaped record. Promotion uses compare-and-swap against the expected active release. Rollback changes only the selected product release pointer and is rejected when the target release cannot read the current schema.

This is informed by SaaS tenant lifecycle and isolation guidance, expand/contract migration practice and SLSA provenance. No deployment system, database topology, secret manager or production supply-chain verifier is selected.

## Synthetic tenant and product fixture

- tenant-alpha is operated by operator-alpha and brand-alpha. Affiliate & Agent is enabled; Lottery is disabled but its configuration, release pointer, schema version, records and ledger counters remain present.
- tenant-beta is operated by operator-beta and brand-beta. Both products are enabled.
- Product configuration schemas are separate. Secret-bearing settings accept only secret:// references.
- Product-owned schemas are logically namespaced as affiliate_agent and lottery; platform schema is owned by the shared platform.
- All environments are staging-only. No production deployment is possible in this fixture.

## Expand/contract and rollback safety

The Affiliate migration sequence is intentionally ordered:
1. Apply affiliate-expand-v2 while affiliate-v1 supports schema versions 1 and 2.
2. Reject affiliate-contract-v3 while affiliate-v1 remains active.
3. Promote affiliate-v2, which supports schema version 3.
4. Reject contract while affiliate-v1 remains the rollback target, because it cannot read schema 3.
5. Explicitly retire the old rollback pointer with compare-and-swap and confirmation. The old artifact remains in the registry.
6. Apply the contract migration. A rollback to the retired release is no longer available.

This makes the loss of an old rollback path explicit rather than silently allowing an unsafe schema contraction.

## Release provenance fixture

Each synthetic release carries:
- product ID, version, staging environment and validated status;
- SHA-256 artifact digest and source revision;
- an in-toto Statement v1-shaped record with SLSA provenance predicate type, subject digest, source revision and builder ID;
- supported schema versions.

The fixture verifies field consistency only. It does not verify signatures, trusted builders, transparency logs, SBOMs or actual SLSA conformance.

## Experiments and pass criteria

| ID | Experiment | Pass criterion |
|---|---|---|
| P07C-01 | Independent enable/disable | Disabling one product does not change sibling product state |
| P07C-02 | State preservation | Product records, ledger counters, config, release and schema state survive disable/enable |
| P07C-03 | Shared platform continuity | Identity, Tenant, Finance, Notifications and Audit remain enabled |
| P07C-04 | Disabled product guard | New product operations and config writes are rejected while disabled |
| P07C-05 | Configuration isolation | Product config keys and versions are namespaced; sibling and other-tenant access is denied |
| P07C-06 | Secret reference discipline | Raw secret values are rejected; only secret references are accepted and never written to audit |
| P07C-07 | Migration ownership | Product migration runners cannot apply sibling or platform migrations |
| P07C-08 | Schema isolation | A product migration changes only its own logical schema |
| P07C-09 | Expand/contract safety | Contract is blocked until the new release is active and incompatible rollback targets are explicitly retired |
| P07C-10 | Release integrity | Product identity, digest, source revision, provenance fields and schema compatibility are checked |
| P07C-11 | Independent promotion/rollback | Promotion and rollback affect only the selected product and reject stale compare-and-swap state |
| P07C-12 | White-label traceability | Tenant, operator, brand, product, release, config version, schema version and correlation ID remain linked without exposing config secrets |

CI is defined in .github/workflows/p07c-independent-lifecycle.yml. A pass is recorded only against the exact PR head after integration and Documentation Governance complete.

## Reproduction

From the repository root:

~~~bash
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/products.json
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/config-schemas.json
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/tenant-state.json
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/releases.json
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/migrations.json
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/actors.json
python3 -m compileall -q prototypes/p07-independent-lifecycle
python3 -m unittest discover -s prototypes/p07-independent-lifecycle/tests -v
~~~

## Explicit limitations

- Synthetic in-memory state only. No real tenant provisioning, product activation service, database migration, release orchestration, container deployment or rollback is executed.
- Logical schema ownership is tested; physical database/schema separation and PostgreSQL RLS are not.
- The fixture's actors and tokens are static test credentials, not production identity or authorization.
- Config validation is a small schema fixture. secret:// values are references only; no KMS, Vault, secret rotation or secret retrieval is implemented.
- Migration tests mutate Python dictionaries. They do not prove SQL migration safety, transactional DDL, backup/restore, zero-downtime deployment or real expand/contract compatibility.
- Provenance checks validate a small set of fields in a synthetic in-toto/SLSA-shaped record. They do not verify cryptographic signatures, trusted builders, SLSA levels, attestations, SBOMs or supply-chain integrity.
- Release promotion and rollback are metadata state transitions in staging fixtures, not production deployment operations.
- Retiring a rollback pointer does not delete artifacts or data. No automated destructive migration or data deletion is included.
- White-label traceability is metadata-only. No real operator portal, custom domain, billing, payment, tenant branding service or customer data is used.
- The audit list is in-memory and not immutable/tamper-evident.
- Lottery remains future scope; no ticketing, draw, prize or payout workflow is implemented.
- No merge, deployment, real credentials, production data or real funds are used.

## Research references

- AWS, [SaaS Lens — tenant isolation and operational guidance](https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/saas-lens.html).
- Martin Fowler, [Parallel Change / Expand-Contract](https://martinfowler.com/bliki/ParallelChange.html).
- AWS Prescriptive Guidance, [Database migration strategies](https://docs.aws.amazon.com/prescriptive-guidance/latest/strategy-database-migration/welcome.html).
- SLSA, [Provenance v1 specification](https://slsa.dev/spec/v1.1/provenance).
- in-toto, [Attestation Framework](https://github.com/in-toto/attestation).


## CI evidence

- Integration [run 45571477383](https://github.com/tecpey/lottorito-platform/actions/runs/45571477383): PASS on PR head f488f34; all 41 tests passed.
- Documentation Governance [run 45571477357](https://github.com/tecpey/lottorito-platform/actions/runs/45571477357): PASS on the same PR head.
- PR [#58](https://github.com/tecpey/lottorito-platform/pull/58) remains Draft, open and unmerged.
