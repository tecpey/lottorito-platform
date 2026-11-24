# Lottorito Decision Register

**Document ID:** LOT-ADR-REG-001 | **Version:** 1.0.0 | **Status:** Maintained register; entries retain their individual authority state

## How to read this register
This register prevents agents from turning discussion, examples or proposals into product rules. A record is not approved merely because it is listed here. The state and authority column govern. Evidence must be linked for every change.

**States:** Owner direction = explicit strategic instruction; Proposed = candidate requiring review; Open = no decision; Rejected = explicitly disallowed; Superseded = replaced with a linked record.

## Recorded directions and proposals

| ID | Topic | Current state | Recorded position / constraint | Authority and next action |
|---|---|---|---|---|
| LDR-001 | Global product scope | Owner direction | Lottorito is intended as a global platform from inception; East Asia may be an initial entry market, not a product boundary. | Owner instruction in project context; preserve globally neutral design. |
| LDR-002 | Product independence | Owner direction | Affiliate & Agent and Lottery must be independently adoptable and commercializable; combined use is optional and explicit. | Owner instruction; validate every shared capability against independent adoption. |
| LDR-003 | Delivery models | Proposed | Affiliate-only, Lottery-only, combined, API-only, white-label and embedded/SSO are target models. | Not evidence of current availability or commercial offer; define entitlements and support model later. |
| LDR-004 | Multi-tenancy and white-label | Owner direction / design constraint | Multi-tenant and white-label are strategic requirements; tenant branding must not erase Lottorito platform identity, ownership or technical traceability. | Owner direction; detailed tenant isolation ADR and threat model required. |
| LDR-005 | Provider neutrality | Owner direction | Avoid dependence on one provider; provider-specific behavior belongs behind adapters and versioned contracts. | Owner direction; no provider is selected or certified by this statement. |
| LDR-006 | Global-first localization | Owner direction | Global readiness is required; language, timezone, currency, calendar and jurisdiction must be modeled explicitly. | Owner direction; market-specific activation remains gated. |
| LDR-007 | Bilingual documentation | Owner direction | Persian and English are equally authoritative and must be updated together with semantic parity. | Owner direction; automated parity CI is not yet verified. |
| LDR-008 | Initial architecture | Proposed | A domain-oriented modular monolith is the preferred starting hypothesis; extract services only when measured needs justify it. | Architecture proposal, not stack/deployment approval. See LOT-ARCH-001. |
| LDR-009 | Technology stack | Open | Framework, ORM, queue, hosting, database topology, cloud and deployment regions are not finally selected. | Requires comparative ADR and prototype; do not infer from examples. |
| LDR-010 | Lottery product scope | Proposed | Provider-neutral catalog, order/ticket lifecycle, draws/results, validation, claims, settlement and operations form a discovery baseline. | LOT-LOTTERY-001 is not approved for implementation or launch. |
| LDR-011 | Lottery legal activation | Open / release gate | Jurisdiction, licensing/operating model, permitted mechanics, responsible-use obligations and customer purchase flow are unresolved. | Legal/compliance and owner approval required before market activation. |
| LDR-012 | Lottery provider | Open | No provider, API, sandbox, credentials, callback schema or certification is verified. | Vendor research and technical/legal due diligence required. |
| LDR-013 | new-lotto.net API reference | Research lead only | The previously supplied API URL is a discovery lead, not validated evidence of capability, authority, security or commercial availability. | Inspect actual docs, ownership, terms, endpoints and sandbox before any adapter decision. |
| LDR-014 | RaidenBet | Proposed Affiliate pilot only | RaidenBet has been discussed as a possible Affiliate partner; no verified contract, API or sandbox is established here. | Do not describe as exclusive, integrated, or a Lottery provider. |
| LDR-015 | Financial source of truth | Design constraint | Financial truth should be represented by immutable double-entry records; balances are derived. Corrections are linked reversals/adjustments. | Architecture principle in LOT-FIN-001; chart of accounts and posting policy need finance approval. |
| LDR-016 | USD 100 agent credit | Open | USD 100 was discussed as an illustrative initial agent/promotional credit; ownership, funding, use, transfer, expiry, clawback, withdrawability and budget are undecided. | No default credit or financial commitment; keep separate from withdrawable commission. |
| LDR-017 | Commission rates | Open | A 20%–40% range appeared in prior discussion but is not approved. | Require signed commercial schedule and owner approval before configuration as a default. |
| LDR-018 | NGR definition | Open | No universal NGR formula is assumed; components and timing depend on each partner contract. | Partner-specific definition and versioned formula required. |
| LDR-019 | Network depth/progression | Open | L1–L10 and monthly progression were mentioned as initial needs, not approved policy. | Define attribution, qualification, share allocation, historical treatment and abuse controls. |
| LDR-020 | Custody and payouts | Open / excluded by default | No custody, banking, payout execution or end-user fund handling is approved by current documentation. | Requires legal, provider, finance, security and owner gates. |
| LDR-021 | Future product horizons | Not in current scope | Casino, poker, blackjack, backgammon, sportsbook and VPN/exchange-related ideas are future horizons, not approved current modules. | Separate product and legal decision required for each. |
| LDR-022 | Merge/deploy authority | Owner constraint | No merge, production deployment, repository settings change or destructive operation without explicit owner approval. | Mandatory across all agent tasks. |

| LDR-023 | Financial posting and reconciliation | Proposed | LOT-FIN-001 defines immutable posting, account dimensions, balance states and reconciliation controls; it does not authorize custody or payouts. | Owner/finance/legal review required; accounting policy and account mapping remain open. |
| LDR-024 | Security threat model | Proposed | LOT-SEC-TM-001 defines trust boundaries, abuse cases and minimum verification; it is not a security audit or certification. | Security review and implementation evidence required. |
| LDR-025 | API resource contract | Proposed | LOT-API-001 defines resource, auth, tenant context, error, pagination, idempotency and webhook conventions; no endpoint is thereby implemented. | Architecture and owner approval required before publishing API commitments. |

## Decision-change protocol
1. Propose a change with rationale, alternatives, impact and evidence.
2. Identify the decision owner and affected documents/domains.
3. Obtain explicit approval where required; record who/when and scope.
4. Update this register and all affected English/Persian documents in one PR.
5. Mark the previous record superseded rather than deleting history.
6. Link implementation, tests and release evidence separately; approval is not implementation.

## Required next decisions
Prioritize jurisdiction/operating model and initial Lottery product boundary; provider selection and source-of-truth policy; technology/deployment ADR; financial account ownership and USD 100 credit policy; commission basis/NGR and network progression; and the exact initial commercial release scope.