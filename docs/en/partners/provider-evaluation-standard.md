# Provider Evaluation, Due Diligence and RFI Standard

**Document ID:** LOT-PROVIDER-EVAL-001 | **Version:** 0.1.0 | **Status:** Proposed cross-product governance standard; no provider selected or approved

## 1. Purpose, authority and non-goals

This standard establishes one reusable, evidence-led method to classify, investigate, test, compare and approve external providers used by Lottorito products. It applies to Affiliate, Lottery, future Sportsbook, Live Casino and RNG/E-Gaming, and later platform capabilities such as identity, payments, communications, hosting and data services.

It is a process and evidence contract, not a supplier recommendation, legal opinion, licence, procurement commitment, technical certification or implementation authorization. No provider is selected by this document. Owner, legal/compliance, security, finance, product and engineering approvals remain separate and must be recorded for the exact scope.

The standard centralizes evaluation governance; it does not replace domain contracts:
- Affiliate: LOT-INT-001.
- Lottery: LOT-LOTINT-001.
- Future regulated gaming domains: LOT-GAMING-STRATEGY-001 and later domain-specific contracts.
- Shared API, security, finance, tenant and quality baselines remain applicable.

## 2. Evaluate the exact provider role and decision unit

The word "provider" is not a sufficient classification. Before issuing an RFI, record the supplier's actual role and contractual chain. Possible roles include:
- Licensed operator or merchant of record.
- Platform/PAM/back-office supplier.
- Lottery content, draw, ticketing or transaction-system supplier.
- Sportsbook technology, trading/risk, odds or sports-data supplier.
- Live-casino studio, game supplier or streaming supplier.
- RNG game studio, content aggregator or game-distribution network.
- Affiliate tracking/network, attribution or campaign supplier.
- Payment, identity/KYC, geolocation, messaging, cloud or infrastructure supplier.

One company may perform multiple roles, through different legal entities and licences. Do not infer that a content supplier is the licensed operator, that an aggregator owns the underlying content, or that a technology platform has authority to accept customers or hold funds.

Every evaluation must be scoped to a **decision unit**:

product/domain × supplier role × legal entity × jurisdiction × operating model × tenant/deployment model × transaction/wallet model

A conclusion for one decision unit must not be generalized to another country, product, legal entity, brand, wallet model or customer segment. Global availability is never inferred from a global sales statement.

## 3. Evidence discipline and provenance

Every material claim must be stored in an evidence register, not only in meeting notes or a score. Each evidence item records:
- Evidence ID and claim/requirement ID.
- Exact claim, scope and supplier legal entity.
- Source title, issuing party, URL or controlled document reference.
- Source type and evidence class.
- Publication/version date, retrieval date and validity/expiry date where applicable.
- Jurisdiction, product, service and legal entity covered.
- Reviewer, review date and conclusion.
- Integrity reference (document hash or immutable repository reference where practical).
- Limitations, contradictions, follow-up owner and due date.

### 3.1 Evidence classes

| Class | Meaning | Typical examples | Permitted use |
|---|---|---|---|
| A — authoritative/verified | Evidence directly verified from the competent authority, executed instrument, independent assurance source or witnessed test | Regulator register checked for exact entity/product/market; signed contract; witnessed sandbox test; independent audit report obtained and scope-checked | Can support a gate or verified finding within its exact scope |
| B — supplier primary | Supplier-controlled primary material, not independently proven | API specification, security whitepaper, SLA proposal, product catalogue, written sales response | Defines claims and test plans; does not alone prove operational behavior or legal permission |
| C — supplier assertion | Verbal, presentation or marketing claim | Sales deck, demo statement, website claim, unminuted call | Lead for investigation only |
| D — secondary | Third-party reporting or reference not issued by the competent authority or supplier | Press article, analyst report, public customer review | Context and corroboration only; investigate provenance and conflicts |
| U — unknown/unavailable | No adequate evidence, inaccessible source, expired evidence or unresolved contradiction | Missing licence record, unavailable API documentation, unsigned commercial terms | Must remain unknown; never convert absence of evidence into a positive assumption |

Class A is not a universal quality score. A regulator register can verify a licence entry but not API behavior; a witnessed sandbox test can verify one behavior but not legal authorization. Record evidence by claim and scope. An executed contract does not prove that the supplier has every required licence or that its service meets technical requirements.

### 3.2 Evidence freshness and contradiction

Set a review/expiry date appropriate to the evidence type. Recheck licences and corporate status before contracting and before each market activation; recheck API versions, security attestations, subprocessors, service terms and certificates at defined intervals and on material change. Preserve superseded evidence and the reason it was replaced. Conflicting evidence is an open risk until resolved by an accountable reviewer.

Never:
- Treat a marketing page as proof of a licence, certification, SLA or API capability.
- Treat a sandbox demo as proof of production readiness.
- Treat a supplier's statement that it "supports a country" as legal market authorization.
- Treat a signed contract as a substitute for technical tests, or technical tests as a substitute for legal review.
- Publish a composite score without the underlying evidence and scope.

## 4. Evaluation workflow and decision states

1. **Intake and classification:** identify the business need, product/domain, supplier role, exact legal entities, target jurisdictions, operating model, data categories and expected transaction flows. Name the accountable business owner.
2. **Initial exclusion and conflict screen:** identify prohibited or incompatible activities, sanctions/adverse findings, ownership conflicts, concentration risk and obvious scope mismatch. Record the source and reviewer.
3. **Legal and regulatory gate:** obtain qualified jurisdiction-specific advice and verify the supplier's role, licences, permissions, contracting chain and permitted product/activity for the exact decision unit.
4. **RFI and evidence collection:** issue the standard questionnaire and collect versioned documents, evidence IDs, exceptions, unsupported capabilities and commercial terms.
5. **Architecture and security review:** map data, identity, tenant boundaries, network flows, secrets, APIs, webhooks, callbacks, storage, subprocessors and incident responsibilities.
6. **Controlled technical validation:** only after authorization, use synthetic data and a supplier-approved isolated sandbox. Execute negative, failure, replay, concurrency, reconciliation and version-compatibility tests. No real customer funds or live regulated activity.
7. **Finance and operational review:** validate transaction lifecycle, wallet/ledger semantics, statements, fees, settlement, support, service resilience and incident/exit procedures.
8. **Scoring and recommendation:** score only after hard gates are assessed. Provide a written recommendation, confidence, residual risks, alternatives and conditions. Do not rank unlike decision units.
9. **Named-scope approval:** record explicit approvers, product, entity, jurisdiction, tenant/deployment, permitted capabilities, limits, validity period and conditions. Approval does not authorize implementation or launch unless those approvals are separately granted.
10. **Continuous monitoring and exit:** monitor licence, ownership, security, SLA, API changes, incidents, financial variance, subcontractors and commercial changes. Suspend or exit when a gate fails or evidence expires.

Use only these decision states:
- **Not assessed**
- **Evidence requested**
- **Blocked** — a required gate cannot currently be evidenced or has failed.
- **Conditional** — further evidence or remediation is required; no production use.
- **Eligible for controlled pilot** — hard gates passed for the named sandbox/test scope only.
- **Approved for named scope** — all required accountable approvals recorded for the exact decision unit.
- **Suspended** — previously approved scope paused pending investigation or remediation.
- **Rejected**
- **Exited**

Do not use "approved provider" without naming the exact decision unit and approval date.

## 5. Non-compensable hard gates

A failed or unknown mandatory gate blocks progression regardless of weighted score. Mark each gate **Pass / Fail / Unknown / Not applicable**, attach evidence and name the accountable reviewer. "Not applicable" requires a written rationale and reviewer approval.

### 5.1 Legal entity, role and market eligibility
- Verify the exact contracting entity, service-delivery entities, beneficial ownership/control and relevant subcontractors.
- Verify the relevant licence/registration/authorization directly with the competent authority where a register exists; record regulator, licence number, legal entity, status, product, permitted role, territory, conditions and verification date.
- Obtain jurisdiction-specific legal advice on Lottorito's and the supplier's respective roles, customer journey, marketing, data, funds, outsourcing and responsibility allocation.
- Confirm the contract permits the intended product, brand, territory, customer type, integration, distribution and data use.
- Screen sanctions, enforcement, material litigation, insolvency, ownership changes and conflicts under an approved policy.
- Confirm required responsible-use, age/identity, geolocation, self-exclusion, complaints, reporting and advertising responsibilities have an accountable owner.
- A supplier licence does not automatically authorize Lottorito, an operator, a tenant or an affiliate to conduct the activity.

### 5.2 Technical and integration readiness
- Obtain current, versioned API/protocol documentation, schemas, error catalogue, changelog, deprecation policy and named technical support.
- Obtain an isolated sandbox and test accounts with documented capabilities and limitations before any integration approval.
- Verify authentication, signature validation, key rotation/revocation, replay defense, tenant binding, idempotency and payload/schema validation.
- Define timeout/unknown-outcome behavior, safe retry, query-by-reference, ordering, duplicate delivery, rate limits, pagination, backpressure and outage handling.
- Verify callbacks/webhooks, event ordering, correction/late-event behavior, API version compatibility and reconciliation endpoints/files.
- Unsupported capabilities must be explicitly declared. Never emulate a success response or silently downgrade a required control.

### 5.3 Security, privacy and data governance
- Complete threat, data-flow and trust-boundary reviews, including tenant isolation and privileged support access.
- Obtain security assurance with scope and date; review vulnerability handling, penetration-test summaries, secure development, access controls, encryption, key management and incident response.
- Identify data categories, controller/processor roles, processing purposes, legal basis where applicable, locations, transfers, retention/deletion, backups and subprocessors.
- Review DPA and contractual security/privacy terms, breach notification deadlines, audit rights, deletion evidence and data-subject request support.
- Confirm least privilege, credential separation, environment isolation, secret rotation, log redaction and export controls.
- No production personal data or secrets in an unapproved sandbox or evaluation channel.

### 5.4 Financial integrity and reconciliation
- Identify who legally owns, receives, safeguards, controls and pays each fund; if this is unresolved, no real-money flow is eligible.
- Document the exact transaction lifecycle, transaction IDs, economic-effect IDs, currencies, decimal precision, FX source/time, fees, taxes, reserves, limits and rounding.
- Define wallet model (if any), balance authority, debit/credit, reversal/rollback, void/regrade, negative balance, chargeback, refund, settlement and dispute semantics.
- Prove idempotency and ambiguous-timeout handling for every money-affecting operation.
- Obtain sample statements and prove record-level reconciliation from provider event through canonical transaction to immutable double-entry ledger.
- No cross-tenant or cross-product pooling. No mutable balance as financial source of truth. No unexplained break or silent overwrite.
- A provider's "wallet" label does not establish custody rights, legal ownership or permission to hold customer funds.

### 5.5 Operational resilience and service ownership
- Establish service ownership, support hours, severity definitions, escalation contacts and incident notification obligations.
- Review measured availability/latency/capacity evidence, maintenance policy, regional dependencies, BCP/DR tests, RTO/RPO proposals and recovery responsibilities.
- Define monitoring, status communication, data export, backup, replay, reconciliation and manual fallback procedures.
- Identify concentration and single-region/single-studio/single-feed risks and realistic alternatives.

### 5.6 Contract, commercial and exit minimums
- Identify pricing units, minimum guarantees, variable fees, taxes, FX, reserves, settlement, chargebacks, audit rights, liability, indemnities and insurance.
- Review exclusivity, territory, product restrictions, marketing/brand rights, subcontracting, change control and unilateral suspension rights.
- Define ownership and permitted use of customer, transaction, content, event, telemetry and derived data.
- Require practical data export, migration assistance, deletion/retention rules, transition period and continuity/step-in provisions appropriate to the service.
- Contract terms must not contradict security, legal, financial or operational gates.

## 6. Comparative scorecard (after hard gates)

The scorecard is a decision aid, not an automatic procurement engine. Score only comparable candidates within the same decision unit and only after mandatory gates have been reviewed. The weights below are a proposed default and require owner/domain approval before use in a binding procurement decision.

| Dimension | Proposed weight | What is assessed |
|---|---:|---|
| Legal and regulatory fit | 20 | Verified role, entity, market/product scope, licence conditions and responsibility allocation |
| Product/domain capability | 10 | Required catalogue, lifecycle, market/content coverage, limits and roadmap fit |
| API and architecture | 15 | Documentation quality, sandbox, versioning, idempotency, callbacks, extensibility and adapter fit |
| Security, privacy and data | 15 | Assurance quality, tenant boundaries, data residency/transfers, incident controls and subprocessors |
| Financial integrity | 15 | Wallet/transaction semantics, precision, statements, reconciliation, reversals and settlement |
| Reliability and operations | 10 | Availability evidence, capacity, support, incident handling, DR and observability |
| Commercial and contract | 10 | Total cost, transparency, contract risk, pricing flexibility and commercial sustainability |
| Exit and portability | 5 | Data portability, migration, termination support and lock-in exposure |
| **Total** | **100** | |

Use a 0–5 scale for each applicable dimension:
- **0 — No evidence / unacceptable:** absent, contradictory or fundamentally inadequate.
- **1 — Critical gaps:** major requirements unmet; extensive remediation or unacceptable risk.
- **2 — Partial:** some requirements met, but material gaps remain.
- **3 — Meets documented baseline:** requirements supported by adequate evidence for the stated scope.
- **4 — Strong:** exceeds baseline and is supported by current, credible evidence.
- **5 — Demonstrated strength:** exceptional capability proven through relevant independent evidence and witnessed tests.

For each score record the requirement IDs, evidence IDs, reviewer, rationale, confidence (High/Medium/Low), unresolved risks and any conditions. A score of 5 without stronger evidence than a score of 3 is not defensible.

Do not average away hard-gate failures. Do not compare a licensed operator with a game studio as if they were interchangeable suppliers. If a dimension is genuinely not applicable, document why; do not silently redistribute its weight. If normalized scores are shown, publish the excluded dimension and formula, and do not compare them with scores using a different dimension set. The recommendation must show gate status and residual risk before any aggregate score.

## 7. Standard RFI questionnaire and response format

Request a written, versioned response for the exact decision unit. Each answer must be **Supported / Partially supported / Unsupported / Roadmap only / Unknown**, with evidence IDs and limitations.

1. Legal identity, group structure, beneficial ownership, contracting and service-delivery entities.
2. Licence/registration numbers, regulator links, product/territory scope, conditions, expiry and permitted role.
3. Exact service role and responsibility split among supplier, operator, platform, tenant and Lottorito.
4. Supported products, mechanics, markets, languages, currencies, limits and excluded capabilities.
5. Current API/protocol specification, version policy, schemas, SDKs, changelog and deprecation notice.
6. Sandbox availability, test-account process, test data, reset procedure, rate limits and production parity gaps.
7. Authentication, signing, encryption, key rotation, IP/network controls, replay defense and incident handling.
8. Tenant/player/account mapping, identity assurance, permissions and cross-tenant isolation evidence.
9. Full transaction/event lifecycle, idempotency, ordering, retries, timeouts, late events, corrections and query-by-reference.
10. Wallet/funds model, ownership, custody, currency precision, fees, taxes, FX, settlement and reconciliation artifacts.
11. Data categories, hosting locations, international transfers, subprocessors, retention, deletion and DPA.
12. Security assurance, vulnerability disclosure, penetration tests, certifications and material incidents.
13. SLA, availability/latency history, capacity, support coverage, escalation and DR evidence.
14. Pricing, minimums, revenue share, reserves, taxes, exclusivity, liability, indemnities and contract duration.
15. Data export, portability, migration, termination assistance, continuity and exit restrictions.
16. Customer references and permission to contact comparable customers.
17. All unsupported capabilities, known limitations, open defects, dependencies and roadmap-only statements.

Supplier responses are assertions until evidence is checked. Attach the exact question, answer, evidence and reviewer to the register.

## 8. Domain-specific supplements

The central standard is common; each domain must add its own lifecycle and evidence.

- **Affiliate:** attribution windows, click/registration/deposit event definitions, deduplication, fraud, commission basis and versioning, NGR components, reversals, hierarchy, reporting latency, partner statement and dispute process. Do not assume commission or NGR definitions are universal.
- **Lottery:** catalogue/rules, draw authority, ticket/order acceptance, ambiguous submission, ticket validation, result source and corrections, claim/settlement responsibility, cancelled draws, refunds, prize funding and reconciliation. Separate data-feed vendors from ticketing providers and licensed operators.
- **Sportsbook:** event/market/selection model, odds version, acceptance/rejection, suspend, in-play latency, bet limits, cash-out, settlement, void/regrade, integrity, trading and data rights.
- **Live Casino:** studio/game/table identity, session token, stream handoff, round lifecycle, dealer correction, late result, rollback, game history, studio availability and round-to-ledger reconciliation.
- **RNG/E-Gaming:** game build/version, jurisdictional certification, launch session, round/bet/win/rollback, RNG/RTP evidence, jackpot contributions/awards, bonus restrictions, game availability and provider reporting.
- **Shared platform services:** identity assurance, payment authorization/settlement, messaging consent/delivery, cloud/data residency, support access and cross-tenant isolation.

Do not create one universal transaction state machine for unlike domains. Use the domain contract and the provider adapter profile.

## 9. Technical validation and acceptance evidence

A controlled pilot requires an approved test plan, named test owner, supplier permission, isolated environment, synthetic data and explicit stop conditions. At minimum test:
- Valid, invalid, expired and revoked credentials; signature failure and replay.
- Wrong tenant, wrong product, wrong account and cross-installation/cross-tenant attempts.
- Duplicate delivery, same idempotency key/same payload, same key/changed payload and concurrent submissions.
- Timeout before/after supplier acceptance, connection loss, delayed callback and query-by-reference.
- Out-of-order, late, corrected, duplicated and contradictory events.
- Rate limit, pagination, partial outage, recovery, backpressure and poison-message handling.
- Version change, unknown enum/field, malformed/oversized payload and schema incompatibility.
- Financial precision, currency mismatch, rounding, fee/tax, reversal, statement gap and full reconciliation.
- Data minimization, log redaction, access boundaries, export/deletion and incident workflow.
- Domain-specific negative and boundary cases.

Record request/response fixtures with secrets and personal data removed, test environment/version, timestamps, correlation IDs, expected/actual results, logs, test commit, defects and reviewer. A passing happy-path demo is insufficient. Sandbox success is not production certification.

## 10. Evaluation dossier and approval record

Maintain one dossier per decision unit. Minimum fields:

| Field | Required value |
|---|---|
| Evaluation ID | Stable ID; never reuse for another decision unit |
| Supplier | Legal entity, group and service-delivery entity |
| Role | Exact supplier role(s) |
| Scope | Product/domain, jurisdiction, operating model, tenant/deployment and wallet model |
| Accountable owner | Named business owner and decision authority |
| Reviewers | Legal, compliance, security, privacy, finance, product, architecture, operations |
| Gate register | Pass/Fail/Unknown/N/A, evidence IDs, reviewer and date |
| Evidence register | Claim, source, class, scope, date, validity, hash/reference and limitations |
| Capability matrix | Supported/partial/unsupported/roadmap/unknown per requirement |
| Test dossier | Plan, fixtures, environment, results, defects and test commit |
| Scorecard | Dimension score, weight, rationale, confidence and reviewer |
| Risks/exceptions | Severity, owner, mitigation, expiry and accepted authority |
| Commercial record | Versioned proposal and contract status; no inferred acceptance |
| Decision | State, exact approved scope, conditions, limits, approvers and date |
| Reassessment | Trigger events, review cadence and expiry |
| Exit plan | Export, migration, deletion, continuity and termination evidence |

Approval must be explicit and recorded by accountable roles. Silence, a demo, a score, a sales email or a passing documentation CI run is not approval. Any material change to entity, licence, jurisdiction, product, API, wallet, data location, subcontractor or contract triggers reassessment.

## 11. Current Lottorito baseline and next action

- No provider is selected or approved by this standard.
- No supplier API, sandbox, credentials, certification, contract or production integration is verified by the existence of this document.
- RaidenBet remains a proposed Affiliate pilot lead only; it is not a verified provider, exclusive partner or Lottery supplier.
- new-lotto.net/api.php remains a research lead, not a validated API or provider.
- Public vendor names in LOT-GAMING-STRATEGY-001 remain discovery candidates, not ranked recommendations.
- Affiliate remains the first delivery priority and Lottery the second. Future gaming domains remain later discovery horizons.
- The next step is to choose one exact Affiliate pilot decision unit and one Lottery research decision unit, confirm the target jurisdiction and operating/legal model, then issue scoped RFIs. Do not start a real-money integration before all relevant gates and approvals pass.

## 12. References and related contracts

Use current, authoritative, jurisdiction-specific sources and record the exact version/date consulted. Relevant Lottorito documents:
- [Affiliate integration contract](integration-contract.md) — LOT-INT-001.
- [Lottery provider contract](lottery-provider-contract.md) — LOT-LOTINT-001.
- [Future regulated gaming domains and provider strategy](../architecture/future-gaming-domains-and-provider-strategy.md) — LOT-GAMING-STRATEGY-001.
- [Security baseline](../security/security-baseline.md) and [threat model](../security/threat-model.md).
- [Financial posting and reconciliation](../finance/financial-posting-and-reconciliation.md).
- [API resource specification](../engineering/api-resource-specification.md).
- [Architecture quality attributes](../architecture/quality-attributes.md).

**Status reminder:** this is a proposed governance standard. It does not select a provider, grant a licence, approve a contract, certify an API, authorize custody or payouts, authorize real-money activity, or establish implementation readiness.
