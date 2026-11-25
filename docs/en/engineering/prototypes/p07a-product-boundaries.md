# P-07A — Product Boundaries and Dependency Isolation

**Document ID:** LOT-PROT-P07A-001 | **Version:** 0.1.0 | **Status:** Synthetic architecture-contract implementation; CI validation pending; not a product runtime or production architecture approval

## 1. Purpose and authority

P-07A is the first of three independently reviewable slices of P-07:

- **P-07A — Boundary and dependency isolation:** identify ownership and enforce a directed dependency policy.
- **P-07B — Independent build, runtime, migration and configuration:** prove each product can be built, configured, started, disabled and migrated without requiring the other product.
- **P-07C — Event contracts and security isolation:** prove cross-product data/event access is denied by default and enabled only through explicit, versioned, authorized contracts.

P-07A does not claim that Lottorito already has an executable product application. The repository baseline remains documentation plus isolated synthetic prototypes. This slice validates an explicit architecture manifest and a fail-closed validator; P-07B must later test actual product artifacts and runtime behavior.

## 2. Hypothesis

Affiliate & Agent and Lottery can evolve as independent bounded contexts. Both may consume shared platform capabilities through stable contracts, but neither product may import the other's domain or implementation, and platform implementations may not depend on product internals.

The target is a **modular platform with enforceable boundaries**, not a premature commitment to microservices, separate databases, a specific framework, or a deployment topology.

## 3. Ownership model

| Capability | Platform-owned responsibility | Product-owned responsibility |
|---|---|---|
| Identity | Canonical principals and authentication contracts | Product-specific profile extensions |
| Tenant | Tenant, organization and membership identity | Product-specific records and activation behavior |
| Authorization | Policy evaluation and enforcement primitives | Product permission vocabulary and business rules |
| Finance | Ledger/posting primitives and immutable financial records | Economic intent, commission/prize calculations and product policy |
| Notifications | Delivery infrastructure and provider adapters | Triggers, eligibility and product content |
| Audit | Protected audit store and access controls | Business-event meaning and attributable context |
| Events | Envelope, routing and delivery infrastructure | Producer-owned event semantics and schema |

For Finance, a shared posting capability does **not** create a shared balance. Each product retains its own economic intent, policy and accounting attribution. No commission formula, NGR definition, prize liability, currency conversion, or cross-product netting rule is approved by this experiment.

The ownership values in architecture.json are accountable logical owners for the synthetic model, not named individuals or a staffing decision.

## 4. Dependency policy

1. A product domain may depend on its own domain modules only.
2. Product application and adapter modules may depend on their own product modules and published platform contract modules.
3. Product modules may not depend directly on platform implementation modules.
4. Affiliate modules may not depend on Lottery modules; Lottery modules may not depend on Affiliate modules.
5. Platform contracts are dependency-free declarations.
6. Platform implementations may depend on platform contracts/implementations, but never on product modules.
7. Unknown dependencies, missing owners, duplicate module IDs and dependency cycles fail closed.
8. Shared capabilities declare one platform owner, contract module, implementation module, data owner, product-policy owners, both product consumers, tenant scope and deny-by-default access.

This is a logical dependency graph. It is not yet an import-graph scan of a production application; there is no verified application workspace to scan. P-07B must bind these rules to actual build/package graphs if an application workspace is introduced.

## 5. Executable fixture and scenarios

The synthetic manifest declares three layers for each product (domain, application, adapter), seven platform contracts, seven platform implementations and seven shared capabilities.

The validator uses Python's standard library only. The test suite covers:

- Valid reference graph.
- Unknown module dependency.
- Affiliate-to-Lottery and Lottery-to-Affiliate imports.
- Product-to-platform-implementation bypass.
- Platform-to-product dependency.
- Platform contract depending on implementation.
- Dependency cycle and duplicate module ID.
- Missing owner and invalid ownership classification.
- Shared capability with permissive default or missing tenant scope.
- Capability implementation owned by a different platform capability.
- Finance ownership split between platform ledger primitives and product economic policy.

## 6. Acceptance criteria

| ID | Required result |
|---|---|
| P07A-01 | Reference graph validates with no errors. |
| P07A-02 | Cross-product dependency is rejected in both directions. |
| P07A-03 | Product-to-platform implementation bypass is rejected. |
| P07A-04 | Platform-to-product dependency is rejected. |
| P07A-05 | Unknown nodes, duplicate IDs, missing owners and cycles are rejected. |
| P07A-06 | All seven shared capabilities have explicit owner, contract, implementation, data owner and product-policy owners. |
| P07A-07 | Shared capability access defaults to deny and requires tenant scope. |
| P07A-08 | Finance ledger ownership is separate from each product's economic policy; no implicit cross-product balance pooling exists. |
| P07A-09 | CI executes both the manifest validator and positive/adversarial unit tests. |
| P07A-10 | Persian and English specifications preserve the same rules, ownership distinctions and acceptance IDs. |

A phase is not Pass merely because the validator itself runs. CI must execute the positive baseline and every mandatory negative case. The test suite must report zero failures and zero skips.

## 7. Security and failure model

The experiment treats dependency metadata as untrusted input and rejects unknown or malformed relationships. It tests architectural misuse, not runtime authorization. A dependency graph cannot prove database RLS, tenant context provenance, API authorization, event authenticity, secrets handling, or deployment isolation; those belong to P-07B/P-07C and the existing P-01/P-03/P-06 evidence chain.

Cross-product access must ultimately be authorized on the receiving side. An event name, tenant ID, internal network location, or possession of a shared platform credential is not authorization by itself. Any cross-product grant must identify the source product, destination capability, action, tenant scope, contract/version and audit context. P-07C will test this boundary.

## 8. Research basis and design rationale

- **DDD bounded contexts and context maps:** use business-model boundaries and explicit relationships rather than arbitrary technical folders. [Microsoft domain-model boundary guidance](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/architect-microservice-container-applications/identify-microservice-domain-model-boundaries) and [Martin Fowler — Bounded Context](https://martinfowler.com/bliki/BoundedContext.html).
- **Modular monolith/domain isolation:** keep domain internals behind public APIs and preserve exclusive data ownership before extracting services. [GitLab modular monolith: isolating the domain layer](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/modular_monolith/domain_layer/).
- **Automated dependency constraints:** express allowed/forbidden dependencies as CI-enforced rules. [Nx Enforce Module Boundaries](https://nx.dev/docs/features/enforce-module-boundaries).
- **Tenant security:** derive tenant context from verified identity, classify shared resources and authorize asynchronous consumers. [OWASP Multi-Tenant Application Security](https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Application_Security_Cheat_Sheet.html).
- **SaaS isolation:** select pooled, silo or bridge isolation per capability and risk; product independence does not require one physical deployment per tenant. [AWS SaaS Lens](https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/silo-pool-and-bridge-models.html).
- **Event interoperability:** CloudEvents may inform the P-07C envelope contract, but no event standard or broker is selected here. [CloudEvents](https://cloudevents.io/).

## 9. Explicit non-goals and open decisions

- No production application, import graph, package manager, framework or deployment unit is claimed.
- No microservice split, database-per-product, broker, cloud vendor, or tenant isolation topology is selected.
- No real Lottery provider, partner, customer, user data, secret or money is used.
- No commercial commission, NGR, prize, wallet, payout, FX or cross-product settlement rule is approved.
- No production, legal, regulatory, privacy or security certification is implied.
- P-07B and P-07C remain unexecuted until their own scope, fixtures and acceptance evidence are added.

## 10. Completion gate

P-07A is complete only when the exact PR head has passing P-07A Integration and Documentation Governance runs, the negative cases are visible in CI output, the bilingual pair is reviewed for semantic parity, and the known limitations remain explicit. Passing P-07A does not pass P-07 as a whole and does not authorize merge or deployment.
