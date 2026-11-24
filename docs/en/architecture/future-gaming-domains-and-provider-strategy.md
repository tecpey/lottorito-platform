# Future Regulated Gaming Domains and Provider Strategy

**Document ID:** LOT-GAMING-STRATEGY-001 | **Version:** 1.0.0 | **Status:** Owner-directed future product horizon and research baseline; no product, provider, licence, API or launch approved

## 1. Purpose and authority

The owner has directed that Lottorito plan for future Sportsbook, Live Casino and professional E-Gaming capabilities, connected to reputable providers and designed to a high international quality bar. This document turns that direction into a bounded product and due-diligence framework.

The accepted strategic sequence remains Affiliate first, then Lottery, followed by separately validated Sportsbook/Betting, Casino/Live Casino and E-Gaming domains. The domains are future horizons, not current MVP scope, implementation authorization, operator licence, supplier contract or permission to offer gambling in any market.

Lottorito should be a global, modular, API-first, multi-tenant B2B platform. Each domain must be independently adoptable, entitled, contracted, configured, operated, audited and commercially packaged. Provider neutrality is a design constraint: provider-specific logic stays behind versioned adapters. No provider is selected by this research.

## 2. Product taxonomy: do not collapse unlike products

Use precise domain names. “E-Gaming” is ambiguous in the market and must not become one catch-all service.

1. **Sportsbook / Event Wagering:** pre-match and in-play fixed-odds betting, betslip, bet acceptance, trading/risk, cash-out (if supported), settlement, void/regrade, event integrity and sports-data rights. Esports wagering is a separately governed content category within the event-wagering domain, not the same thing as casino games.
2. **Live Casino:** streamed dealer-operated table games and game-show formats, with studio/table availability, streaming, round lifecycle, dealer-error correction and game-history evidence.
3. **RNG Casino / E-Gaming Content:** slots, RNG table games, video poker, bingo, crash/instant games and jackpots. Each mechanic and content family may have distinct certification, market availability and responsible-gaming implications.
4. **Poker and peer-to-peer games:** separate future domain if pursued; shared-liquidity network, player matching, tournaments, rake, collusion/fraud and game-integrity controls differ materially from house-banked casino games.
5. **Skill/social games:** separate classification and legal analysis; do not infer that a “social”, “free-to-play” or skill label makes a product unregulated.

The product registry must represent each as a separate bounded context and entitlement. A provider may supply several domains, but that must not merge their lifecycle, risk, ledger, permissions or release decisions.

## 3. Target architecture

Keep Lottorito's shared platform services separate from domain engines:

- **Shared platform:** tenant/identity/access, player-account identity mapping, jurisdiction and product eligibility policy, responsible-gambling control plane, immutable finance/ledger primitives, event/audit, provider registry, credential vault, observability, support, localization and reporting.
- **Sportsbook domain:** event/market catalogue, odds snapshots, market state, betslip, acceptance decision, bet lifecycle, trading/risk integration, settlement and corrections.
- **Live Casino domain:** studio/table/game catalogue, launch session, streaming handoff, round lifecycle, dealer correction, game history and round reconciliation.
- **RNG/E-Gaming domain:** content catalogue, jurisdictional availability, game launch, round/bet/win/rollback lifecycle, jackpot contribution/award and provider reporting.
- **Provider adapter layer:** provider-specific authentication, schemas, wallet protocol, callbacks, state mapping, limits, retry semantics, error translation, health and reconciliation. No domain core calls provider endpoints directly.
- **Operator/tenant surfaces:** operator back office, player-facing experience, support/risk tools and partner integration APIs; each uses explicit entitlements and least-privilege scopes.

Do not build a single generic “game transaction” abstraction that erases material differences between a sports bet, a live table round, a slot spin and a poker hand. Shared primitives may exist, but domain state machines and financial semantics remain explicit.

## 4. Provider delivery models

Evaluate vendors by delivery model, not marketing labels:

- **Turnkey / managed operator stack:** supplier may provide PAM, sportsbook/casino, trading, payments or operational services. Faster integration can create high vendor lock-in and may blur which party owns player identity, balances, regulatory records and customer relationship.
- **Modular platform / domain engine:** Lottorito owns more of the operator-facing experience and integrates individual engines and services. Requires stronger orchestration, reconciliation and operational capability.
- **Direct content studio:** direct integration with one game studio or live dealer supplier; potentially greater commercial/control clarity but more contracts, certification, wallet integrations and ongoing reconciliation.
- **Content aggregator:** one integration and contract may expose many studios. Validate underlying studio permissions, exact game/title availability by jurisdiction, subcontracting chain, data rights, certification responsibility, wallet semantics, fees and exit/portability. “One API” does not remove per-game/per-market obligations.
- **Data / odds / integrity supplier:** feeds and trading services are not a complete sportsbook engine. Verify official rights, latency, market coverage, settlement authority, integrity monitoring and liability.

Lottorito should preserve the ability to integrate direct providers and aggregators in parallel. An aggregator must not be the only source of truth for wallet movements, player restrictions, game rounds or financial statements.

## 5. Initial market map for RFI discovery (not endorsements)

The following names are research candidates based on public first-party material. This is not a ranking, certification check, API compatibility claim, commercial recommendation or proof of availability in any target jurisdiction. Verify the exact contracting legal entity and current regulator register entry before procurement.

### 5.1 Sportsbook and event wagering

- **Kambi:** publicly describes an end-to-end turnkey sportsbook with trading/risk services and a separate Odds Feed+ API product. Useful RFI candidate when comparing managed sportsbook against data-only integration. Source: [Kambi](https://www.kambi.com/).
- **EveryMatrix / OddsMatrix:** describes an API-first modular sports/casino platform; OddsMatrix publishes sports-data feed/API capabilities for pre-match/live odds, scores, stats and settlements. Its 2024 announcement says OddsMatrix was certified to GLI-33; confirm current certificate scope, version and target jurisdiction directly. Sources: [EveryMatrix](https://everymatrix.com/), [OddsMatrix Data Services](https://omfeeds.everymatrix.com/), [certification announcement](https://everymatrix.com/news/gaming-laboratories-international-gli-delivers-gold-standard-certification-to-core-everymatrix-platform-products/).
- **Altenar:** describes managed and self-managed sportsbook options, 24/7 trading/risk, and API integration with existing PAM/front ends. Its site publishes specific licence/registration statements; verify the named legal entity and activity in each target register. Source: [Altenar sportsbook](https://altenar.com/services/sportsbook/).
- **OpenBet, Sportradar, Digitain and other enterprise providers:** retain as discovery candidates for a structured RFI, but do not infer fit or API terms from brand recognition. Ask separately for platform, trading, official data, settlement and integrity capabilities.

### 5.2 Live Casino

- **Evolution Group:** its annual report describes a One Stop Shop integration spanning Evolution, Ezugi and several RNG brands; its solutions page also describes dedicated live environments. This is relevant to multi-brand content distribution and bespoke studio assessment. Sources: [Evolution solutions](https://www.evolution.com/about/solutions), [2025 annual report](https://www.evolution.com/wp-content/uploads/2026/04/Annual_Report_English_2026_04_01.pdf).
- **Playtech Live:** publicly describes live studios across multiple regions and a portfolio of table games and branded game-show formats. Source: [Playtech Live](https://www.playtech.com/products/live/).
- **Pragmatic Play Live:** evaluate alongside its broader slots/content offering; its public company material describes a single API for slots, live casino and other content. Verify the actual API, wallet model, game catalogue and market entitlements during RFI. Source: [Pragmatic Play](https://www.pragmaticplay.com/en/about-us/).

### 5.3 RNG / E-Gaming content and aggregation

- **EveryMatrix CasinoEngine:** candidate for broad multi-studio content aggregation and modular platform comparison; verify direct studio contracts, game-level market mapping, reporting and wallet modes.
- **Games Global:** describes 1,300+ proprietary games and 40+ in-house/partner studios, including slots, table games, video bingo, video poker and crash content. Source: [Games Global](https://www.gamesglobal.com/Company/About).
- **Relax Gaming:** describes aggregation and its Powered By Relax distribution programme; its Relax Vantage business portal includes game availability, configuration, analytics and compliance information. Sources: [Relax Vantage](https://www.relax-gaming.com/news/2024/08/relax-gaming-reveals-game-changing-business-portal-relax-vantage), [Powered By Relax expansion](https://www.relax-gaming.com/news/2026/01/relax-gaming-expands-powered-by-relax-platform-with-wicked-games-integration).
- **Pragmatic Play and Play'n GO:** candidate content suppliers for regulated markets; require title-level certification and jurisdiction matrix, not just company-level claims. Sources: [Pragmatic Play](https://www.pragmaticplay.com/en/about-us/), [Play'n GO](https://www.playngo.com/).

### 5.4 How to interpret this market map

Provider websites are primary evidence of what a company claims to offer, not independent proof of performance, licensing scope, API quality or suitability. Public marketing pages are not a substitute for current technical documentation, sandbox tests, regulator-register checks, contract review and references from operators in the same jurisdiction and delivery model.

## 6. Provider due-diligence scorecard

No provider advances based on catalogue size, sales presentation or an introductory demo alone. Require evidence in each category:

1. **Legal entity and authorization:** exact contracting/supplying entities; current licences, registrations and permitted activities; jurisdictions and product types; ownership/control; sanctions/adverse regulatory history; subcontractors and studio chain.
2. **Technical documentation:** current API/OpenAPI or protocol docs, schema versions, sandbox, test accounts, sample callbacks, SDK maintenance, changelog, deprecation policy and named technical support.
3. **Wallet and transaction model:** seamless versus transfer wallet; balance ownership; debit/credit/rollback semantics; round/bet identifiers; idempotency; callback signature; ordering; retries; late results; partial failures; negative balances; reconciliation statements; fee and tax records.
4. **Data and integrity:** source and rights for sports data; timestamp/latency guarantees; odds/market suspension; result authority; game RNG/RTP certification; game build/version hashes; tamper-evident round history; correction and dispute process.
5. **Security and privacy:** credential rotation/revocation; mTLS or signed requests; key custody; network controls; vulnerability disclosure; penetration-test summaries; incident notification; data residency, retention, deletion and subprocessor inventory.
6. **Regulatory fit:** market-by-market game/event allowlists; certificate scope and version; geolocation dependencies; age/identity verification responsibility; self-exclusion and limits propagation; audit exports; advertising/affiliate restrictions.
7. **Reliability and operations:** independently evidenced uptime and incident history; peak-event capacity; latency percentiles; regional failover; status page; RTO/RPO; support coverage; escalation and disaster-recovery tests.
8. **Commercial and exit:** minimum guarantees, rev share, fixed fees, currency/FX, taxes, settlement cycle, reserves, chargebacks, audit rights, liability caps, exclusivity, data portability, termination assistance and continuity plan.
9. **References and proof:** at least two comparable operator references where available; observed sandbox contract tests; reconciliation samples; regulator/certification evidence; signed capability matrix.

Use a weighted scorecard only after hard legal/security gates. A high aggregate score must never compensate for an unlicensed product, unverifiable game integrity, unsafe wallet semantics or missing jurisdictional approval.

## 7. Canonical integration invariants

These are proposed cross-domain invariants; detailed domain contracts must refine them:

- Provider callbacks are authenticated, replay-protected, schema-versioned and tenant-resolved from trusted connection configuration—not a tenant ID in an untrusted payload.
- Persist intent and stable idempotency identity before external mutations. On timeout, mark the result UNKNOWN and query/reconcile before retrying; never create a second bet/round by blind resubmission.
- Separate provider event ID, domain transaction ID, game round/bet ID and economic effect ID. Deduplicate transport without erasing distinct economic effects.
- Preserve raw signed payload evidence, hashes, source/received timestamps, provider version and canonical mapping version.
- Late win/settlement, rollback, void, regrade and dealer/game correction are explicit state transitions and compensating financial entries—not destructive edits.
- Realtime odds/score/game updates are not financial truth. Persist accepted bets, game rounds and economic effects in the canonical system of record.
- Reconcile continuously and at statement close: accepted vs rejected bets, open vs settled bets, round debits vs credits/rollbacks, jackpot contributions/awards, provider statements and ledger entries.
- Do not assume one provider's "seamless wallet" or "transfer wallet" semantics match another's. Each adapter has executable contract tests.
- No cross-tenant or cross-product balance pooling. Any player wallet, if ever approved, must be designed with explicit legal owner, currency, product restrictions and immutable double-entry records.
- Chat, affiliate attribution, promotions and notifications cannot override eligibility, self-exclusion, marketing consent, limits or cooling-off restrictions.

## 8. Responsible-gambling and regulatory-by-design controls

Regulatory approval is jurisdiction- and activity-specific. A B2B software supplier, game studio, aggregator, platform provider and B2C operator may have different licence obligations. A supplier's licence does not automatically authorize a customer or a product in a territory.

Minimum design topics include age and identity verification; sanctions/PEP and AML obligations where applicable; geolocation and prohibited-territory controls; self-exclusion and multi-operator schemes where required; deposit/loss/time limits; reality checks and time-outs; cooling-off; affordability/customer-interaction duties where applicable; complaints and dispute handling; game fairness/RNG and RTP disclosure; sports integrity and suspicious-betting monitoring; advertising/affiliate restrictions; record retention and regulator access.

For the UK, the Gambling Commission's Remote Gambling and Software Technical Standards (RTS) apply to relevant remote gambling and software licence holders; the Commission states that its RTS updates took effect on 30 October 2026. Its technical standards and security requirements must be assessed against the actual role and licence. Source: [UKGC RTS guide](https://www.gamblingcommission.gov.uk/licensees-and-businesses/guide/remote-gambling-and-software-technical-standards).

For Malta, the MGA distinguishes B2B critical gaming supply and game-provider/back-office licensing; its public material identifies fixed-odds betting as Type 2 and certain peer-to-peer/pool-betting activities as Type 3. The precise entity, supply activity and jurisdictional reach must be checked against the current MGA framework. Sources: [MGA game providers and back office](https://www.mga.org.mt/licensee-hub/applications/b2b-licences/game-providers-and-back-office/), [MGA back office](https://www.mga.org.mt/licensee-hub/applications/b2b-licences/back-office/).

GLI standards are useful technical reference points, not universal licences. GLI-19 addresses interactive gaming systems; GLI-33 addresses event wagering systems. The UAE GCGRA's published technical standards list both and states that operators are responsible for compliance. Applicable regulator rules and adopted versions always prevail. Sources: [GCGRA technical standards](https://www.gcgra.gov.ae/en/legislation-compliance/legislation/technical-standards/), [GLI standards catalogue](https://www.trisigma.com/gli-standards/).

This is an architecture checklist, not legal advice or a jurisdictional opinion. Obtain specialist counsel and regulator confirmation before any market or product activation.

## 9. Release and activation gates

A future domain progresses through distinct gates:

- **G0 — Discovery:** product owner, user journeys, domain taxonomy, target operator model and market hypotheses documented.
- **G1 — Legal feasibility:** market-by-market legal memo, operator/supplier role, licence pathway, restricted mechanics and advertising/affiliate rules approved by accountable counsel/owner.
- **G2 — Provider due diligence:** contracting entity, licences, technical docs, sandbox, commercial terms, references and data processing reviewed.
- **G3 — Architecture proof:** threat model, wallet semantics, idempotency, settlement/correction, tenant isolation, capacity, observability and recovery prototypes pass in synthetic environments.
- **G4 — Certification and integration:** required independent lab/regulator certification, provider approval, adapter contract tests, game/event catalogue allowlists and reconciliation evidence.
- **G5 — Controlled pilot:** licensed entity and approved market only; limited cohort/limits; operational monitoring, incident response, responsible-gambling controls and rollback tested.
- **G6 — General availability:** audit evidence, support/SLA, financial reconciliation, regulator reporting, change management and owner release approval complete.

No gate is implied by this document. No real-money activity, customer onboarding, provider credentials, provider sandbox, market launch or promotional campaign is authorized.

## 10. Research backlog and next work

For each domain, produce a separate PRD, domain state machine, canonical provider contract, threat model, data/ledger mapping, jurisdiction matrix, provider scorecard and reproducible sandbox test plan.

Recommended sequence:
1. Preserve Affiliate as the first delivery priority and complete its independent product/finance/security foundation.
2. Complete Lottery discovery and provider due diligence as a separate bounded domain.
3. Run Sportsbook RFI research: compare Kambi, EveryMatrix/OddsMatrix, Altenar and selected enterprise alternatives across managed vs self-managed trading, data rights, APIs, settlement and jurisdiction coverage.
4. Run Live Casino RFI research: compare Evolution, Playtech Live and Pragmatic Play Live on studios, market availability, streaming, round corrections, wallet integration and audit evidence.
5. Run RNG/E-Gaming content RFI research: compare direct studios and aggregators, including Games Global, Relax Gaming, EveryMatrix CasinoEngine, Pragmatic Play and Play'n GO.
6. Decide whether poker, esports wagering, crash/instant and skill/social games are separate product modules or separately licensed subdomains before any build.

No provider is selected. No public claim of API compatibility or launch readiness is permitted until vendor documentation, sandbox tests, contracts and legal evidence are reviewed.

## 11. References

- Kambi — https://www.kambi.com/
- EveryMatrix — https://everymatrix.com/
- OddsMatrix Data Services — https://omfeeds.everymatrix.com/
- Altenar — https://altenar.com/services/sportsbook/
- Evolution solutions — https://www.evolution.com/about/solutions
- Evolution 2025 annual report — https://www.evolution.com/wp-content/uploads/2026/04/Annual_Report_English_2026_04_01.pdf
- Playtech Live — https://www.playtech.com/products/live/
- Pragmatic Play — https://www.pragmaticplay.com/en/about-us/
- Games Global — https://www.gamesglobal.com/Company/About
- Relax Gaming — https://www.relax-gaming.com/
- Play'n GO — https://www.playngo.com/
- UK Gambling Commission RTS — https://www.gamblingcommission.gov.uk/licensees-and-businesses/guide/remote-gambling-and-software-technical-standards
- Malta Gaming Authority B2B licensing — https://www.mga.org.mt/licensee-hub/applications/b2b-licences/game-providers-and-back-office/
- UAE GCGRA technical standards — https://www.gcgra.gov.ae/en/legislation-compliance/legislation/technical-standards/
- GLI standards catalogue — https://www.trisigma.com/gli-standards/

**Status reminder:** future product and research baseline only. Provider names are discovery candidates, not recommendations or approvals. No API, sandbox, contract, certification, licence, runtime or production service has been verified for Lottorito.
