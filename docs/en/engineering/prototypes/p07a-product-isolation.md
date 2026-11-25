# P-07A — Independent Product Composition: Build and Runtime Isolation

**Document ID:** LOT-PROT-P07A-001 | **Version:** 0.1.0 | **Status:** Initial synthetic implementation; CI validation pending

## Decision question

Can Affiliate & Agent and Lottery each be packaged and booted without shipping, importing, or enabling the sibling product module?

P-07A is the first of three execution slices under P-07:
- **P-07A:** product build/runtime composition isolation.
- **P-07B:** shared-platform ownership, authorization and cross-product trust boundaries.
- **P-07C:** independent product lifecycle, configuration, migration and operations.

The parent experiment remains LOT-PROT-001. This slice does not close P-07.

## Research-informed approach

The experiment uses business-capability boundaries rather than horizontal technical layers. It deliberately does not prescribe microservices or separate databases: DDD bounded contexts are a domain boundary, not an automatic deployment mandate. A small, explicit composition manifest and a build-time dependency check are used as architectural fitness functions. The produced artifact is then executed in a fresh Python process containing only the selected product module and the synthetic shared-platform port.

This follows the bounded-context and coupling guidance in Microsoft's domain-analysis material, while keeping tenant isolation as a separate security concern (OWASP Multi-Tenant Security Cheat Sheet). Contract testing and stronger authorization proofs are reserved for P-07B.

## Synthetic fixture

- Two product IDs: `affiliate_agent` and `lottery`.
- Shared ports: synthetic identity context, tenant context and audit sink.
- Product-owned composition smoke capability for each product.
- No external dependencies, database, network, live provider, partner, user, tenant or financial data.
- Product manifests declare zero product-to-product dependencies and explicitly forbid the sibling dependency.

The build step emits a minimal artifact with exactly four files: `product.py`, `platform_core.py`, `manifest.json` and `run.py`. The sibling product module is not copied. Product entrypoints are checked for direct, package-qualified and dynamic cross-product imports.

## Experiments and pass criteria

| ID | Experiment | Pass criterion |
|---|---|---|
| P07A-01 | Build Affiliate & Agent | Artifact builds with only Affiliate & Agent entrypoint and shared ports |
| P07A-02 | Run Affiliate & Agent | Fresh process starts and returns its own composition smoke result |
| P07A-03 | Build Lottery | Artifact builds with only Lottery entrypoint and shared ports |
| P07A-04 | Run Lottery | Fresh process starts and returns its own composition smoke result |
| P07A-05 | Dependency enforcement | Direct and dynamic sibling imports are rejected; manifests contain no product dependency |
| P07A-06 | Artifact inspection | Each artifact contains no sibling module or sibling-specific package |
| P07A-07 | Shared-port attribution | Synthetic audit output retains the selected product identity |

Any failure is a P-07A failure; no partial pass is promoted to full P-07 success.

## Reproduction

From the repository root:

```bash
python3 -m compileall -q prototypes/p07-product-composition
python3 -m unittest discover -s prototypes/p07-product-composition/tests -v
python3 prototypes/p07-product-composition/build.py affiliate_agent --out /tmp/lottorito-p07a-affiliate
python3 /tmp/lottorito-p07a-affiliate/run.py
python3 prototypes/p07-product-composition/build.py lottery --out /tmp/lottorito-p07a-lottery
python3 /tmp/lottorito-p07a-lottery/run.py
```

CI: `.github/workflows/p07a-product-composition.yml`. CI results must be tied to the exact PR head before a pass is recorded.

## Explicit limitations

- This is a synthetic composition harness, not the Lottorito application or a production package.
- The smoke operation proves module bootstrap and composition only. It does not implement or prove an Affiliate referral/commission journey or any Lottery ticket/draw/prize workflow.
- Shared identity, tenant and audit functions are stubs. No authentication, authorization, RLS, ledger, event broker, data ownership, encryption or tenant isolation is proven.
- Static import analysis is intentionally narrow and is not a general Python dependency scanner or proof against arbitrary runtime code execution.
- No independent deployment, migration, rollback, configuration lifecycle or white-label traceability is proven; those belong to P-07C.
- No production architecture, microservice split, database topology, vendor or technology is approved.
- No production data, real credentials, real funds, merge or deployment are used.

## Research references

- Microsoft Learn, [Use domain analysis to model microservices](https://learn.microsoft.com/en-us/azure/architecture/microservices/model/domain-analysis).
- Microsoft Learn, [Use tactical DDD to design microservices](https://learn.microsoft.com/en-us/azure/architecture/microservices/model/tactical-ddd).
- OWASP, [Multi-Tenant Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html).
- AWS Well-Architected, [SaaS Lens: Software and architecture patterns](https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/software-and-architecture-patterns.html).
- Pact, [Consumer-driven contracts](https://docs.pact.io/).
