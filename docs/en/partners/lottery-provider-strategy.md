# Lottorito Lottery Provider Strategy

**Document ID:** LOT-LOT-INT-001 | **Version:** 0.1.0 | **Status:** Evaluation framework; no provider selected or approved  
**Related:** LOT-LOT-PRD-001, LOT-LOT-ARCH-001

## 1. Purpose

Establish a repeatable method to evaluate, contract, integrate and operate external Lottery providers without coupling Lottorito's core domain to one supplier.

No provider is selected, endorsed, contracted, certified or integrated by this document. Public websites and API documentation are preliminary evidence only; commercial, legal, security, technical and operational due diligence remains mandatory.

## 2. Classify the provider before comparing it

A vendor must first be assigned one or more capability classes:

| Class | Typical capabilities | Does not prove |
|---|---|---|
| Lottery data/results API | game catalog, schedules, draw results, history, jackpots, corrections | ticket sales, game operation, prize payment |
| Game/content supplier | game definitions, content, RNG/game engine or draw services | operator license, customer acquisition, payment or settlement |
| Ticketing / transaction API | ticket creation, acceptance, status, cancellation, receipts | broad catalog coverage or legal authorization in every market |
| Turnkey lottery platform | several operator workflows, administration and customer interfaces | portability, independent licensing or suitability for every jurisdiction |
| Payment / identity / geolocation provider | a specific supporting control | lottery provider status or authority to operate |
| Official operator / licensed partner | market-specific authorized operation | authority outside its license, territory or contracted scope |

A vendor may cover multiple classes. Each capability must be evidenced independently.

## 3. Preliminary public-source landscape

The following is a research starting point, not a ranked or approved shortlist:

- **Lottevo:** public documentation describes a versioned REST API for catalog, schedules, draw results, historical data, ticket checking against historical results, change/revision feeds, data-quality indicators and event delivery. Its public site states it is a lottery data service and not a ticket retailer or operator. Treat it as a candidate for a data/results adapter only until a contract and service validation establish otherwise.
- **Lottery Results API:** public documentation exposes an interactive Swagger API and endpoints for lottery discovery/results. Public material indicates a results/data-oriented service. Coverage, accuracy, correction process, service levels, licensing of data and commercial rights require independent verification.
- **new-lotto.net/api.php:** previously supplied as a reference URL. Its current API schema, operator identity, authorization, service scope, authentication, availability and commercial terms have not been verified in this review. Do not infer functionality from the URL or from a sample response alone.
- **Large lottery technology suppliers and local licensed operators:** may offer enterprise platform, draw, retail, digital, or managed services through procurement and private contracts rather than a self-service public API. A public website is not proof that an API or partner program is available.

Do not compare a data API and a ticketing platform as if they were equivalent products.

## 4. Due-diligence checklist

### 4.1 Corporate, legal and commercial

- Contracting entity, beneficial ownership, operating history and financial stability.
- Exact role: data licensor, technology supplier, ticketing processor, operator, reseller or subcontractor.
- Markets and games covered; territory restrictions and customer eligibility conditions.
- Required operator/supplier licenses, certifications, regulator approvals and independent audits.
- Data, game-content, ticket, result and brand intellectual-property rights.
- Subprocessor list, subcontracting, data location and cross-border transfers.
- Commercial model, minimums, revenue share, transaction fees, taxes, refunds and termination rights.
- Exclusivity, non-compete, white-label, sublicensing and portability clauses.
- Exit assistance, data export, deletion certification and continuity provisions.

### 4.2 API and technical

- Complete OpenAPI/Swagger or equivalent documentation and version policy.
- Sandbox access, test fixtures, test identities and deterministic test scenarios.
- Authentication, key scopes, signature verification, key rotation and replay protection.
- Catalog/game-rule model, stable identifiers and change notifications.
- Ticket quote, submission, idempotency, lookup, cancellation and refund capabilities.
- Result source, publication latency, provisional/confirmed/corrected states and revision history.
- Webhook delivery guarantees, retry policy, ordering, cursor/replay and dead-letter process.
- Pagination, rate limits, quotas, payload limits, error taxonomy and correlation IDs.
- Currency precision, time zones, DST behavior, localization and historical retention.
- Availability, latency, maintenance windows, incident notification and support escalation.
- Security testing, vulnerability disclosure, penetration testing and independent assurance.
- Data export, portability, disaster recovery, backup, RPO/RTO and business continuity.

### 4.3 Operational and financial

- Who is merchant/operator of record and who accepts customer terms?
- Who owns ticket acceptance, customer funds, prize liability, claims and payout decisions?
- Which party is authoritative for ticket state, draw schedule, results, corrections and settlement?
- Settlement statement format, cadence, currency, cutoffs, fees, taxes and variance resolution.
- Dispute, chargeback, refund, cancellation and unclaimed-prize workflows.
- Reconciliation references that link provider records to Lottorito orders, tickets and ledger effects.
- Manual support responsibilities and incident ownership.

## 5. Weighted evaluation model

Score each criterion from 0 to 5 with evidence and reviewer notes. A high total cannot override a failed legal, licensing, security, integrity or financial-control gate.

| Dimension | Weight |
|---|---:|
| Legal authorization, role clarity and market fit | 20% |
| API capability and contract quality | 15% |
| Ticket/result integrity and auditability | 15% |
| Security, privacy and independent assurance | 15% |
| Operational resilience and support | 10% |
| Financial settlement and reconciliation | 10% |
| Commercial terms, portability and exit | 10% |
| Coverage, localization and roadmap fit | 5% |
| **Total** | **100%** |

Score scale: 0 = absent/failed; 1 = serious gap; 2 = partial with material conditions; 3 = meets minimum evidence threshold; 4 = strong verified capability; 5 = independently evidenced and contractually committed. Unknown is not a score of 3; mark it **unverified** and request evidence.

### Hard gates

Do not progress to production procurement or live integration if any of these remain unresolved:

- Legal role and market authorization.
- Rights to provide the games/data and to resell or display them.
- Security and authentication model.
- Ticket submission idempotency and unknown-outcome recovery, if ticketing is in scope.
- Result provenance and correction history, if results affect validation or settlement.
- Financial statement and reconciliation responsibilities, if money is in scope.
- Data protection, retention and incident obligations.
- Executable contract, support SLA and termination/portability rights.

## 6. Integration pattern

1. **Discovery:** record vendor identity, capability class, supported markets/games, evidence links and open questions.
2. **Due diligence:** complete legal, commercial, security, technical, financial and operational reviews.
3. **Contract baseline:** freeze API version, credentials model, event schema, SLAs, data rights and responsibilities.
4. **Adapter implementation:** map only verified capabilities to canonical Lottery contracts; preserve source identifiers and evidence.
5. **Sandbox verification:** run contract tests, duplicate/replay tests, timeout recovery, result corrections, tenant isolation and reconciliation fixtures.
6. **Controlled pilot:** use approved market, operator, games, test accounts and transaction limits with named incident owners.
7. **Production approval:** require signed-off compliance, security, finance, operations and product gates.
8. **Continuous assurance:** monitor freshness, completeness, error rates, drift, settlement variance, vendor changes and SLA breaches.

## 7. Resilience and multi-provider policy

- Multiple providers may be configured per capability and market; no universal failover assumption.
- Define one authoritative ticketing provider per transaction. Never submit the same purchase to two providers as an automatic failover.
- For uncertain ticket submission, resolve the original provider outcome before considering any alternate route.
- Result-source fallback must be explicit, source-ranked, timestamped and visible; conflicting results enter a dispute workflow.
- Maintain provider-specific rate limits, circuit breakers, credentials, queues and health signals.
- Provider migration requires data mapping, reconciliation, historical traceability and an approved cutover plan.
- Provider neutrality means replaceable contracts and controlled adapters, not identical capabilities or frictionless switching.

## 8. Research conclusions and next evidence requests

The public material reviewed supports a clear first step: separate data/results sourcing from transactional ticketing and turnkey operation. Lottevo is a plausible data/results evaluation candidate based on its public API description; it is not evidence of a ticketing or operator solution. Lottery Results API and the user-supplied new-lotto reference need endpoint-level and contractual verification before any shortlist decision.

Before selecting a provider, obtain:

1. Legal entity and role statement.
2. Full API/OpenAPI specification and version policy.
3. Sandbox credentials and test fixtures through an authorized channel.
4. Supported markets, games, rights and source-of-truth declarations.
5. Ticket lifecycle and idempotency documentation, if relevant.
6. Result provenance, correction and dispute policy.
7. Security pack, data-processing terms and subprocessor list.
8. Settlement samples, fee schedule and reconciliation specification.
9. SLA, support escalation, incident and exit/portability terms.

## 9. References

- [Lottevo — API reference](https://lottevo.com/docs/reference)
- [Lottevo — API quickstart](https://lottevo.com/docs)
- [Lottery Results API — documentation](https://docs.lotteryresultsapi.com/documentation/)
- [UK Gambling Commission — Lottery sector guidance](https://www.gamblingcommission.gov.uk/licensees-and-businesses/sectors/sector/lotteries)
- [World Lottery Association — Code of Conduct](https://www.world-lotteries.org/volumes/downloads/Download_Center/Legal/Code_of_Conduct/202103_EN_WLA_Code_of_Conduct.pdf)

## 10. Status

No provider has been selected or approved. No API credentials, sandbox, integration, certification, commercial agreement or production readiness is claimed. Update this document only when new evidence is obtained and reviewed.
