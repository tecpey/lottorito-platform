# Lottorito System Architecture

**Document ID:** LOT-ARCH-001 | **Version:** 0.2.0 | **Status:** Proposal, not a final decision

## Approach
Domain-oriented, modular, API-first, multi-tenant architecture. The initial proposal is a Modular Monolith with explicit boundaries; extract services only when scale or operational needs justify it.

## Domains
Identity & Access; Tenant & Partner; Affiliate & Agent Network; Tracking & Attribution; Partner Integration; Commission & Rules; Wallet & Ledger; Payout & Reconciliation; Campaign & Loyalty; Reporting & Audit; Sportsbook/Event Wagering (future); Live Casino (future); RNG/E-Gaming Content (future); Poker/Peer-to-Peer Games (separate future decision).

Each domain owns its logic and data. Direct access to another domain's internal tables is prohibited; communication uses explicit contracts.

## Proposed technology
No final stack is approved. LOT-TECH-ADR-001 is the current decision framework. PostgreSQL is a candidate for the initial system of record; a modular monolith with transactional outbox and workers is the starting hypothesis. Queue broker, workflow engine, framework, ORM, hosting, cloud region and Kubernetes adoption require evidence-backed ADRs and prototypes. The earlier Next.js suggestion is not a final decision.

## Multi-tenancy
Every record must have tenant scope; tenant identity comes from authenticated session/membership, not forgeable input. Negative cross-tenant access tests are mandatory. RLS may provide defense in depth, not replace application authorization.

## Event flow
Raw intake → source/signature validation → constrained storage → idempotency and deduplication → normalization → attribution → versioned rule evaluation → ledger posting → reporting and reconciliation.

## Reliability
Atomic transactions for financial operations; outbox pattern; bounded retries with backoff; review queue for permanent failures; structured logs, metrics, tracing, and discrepancy alerts.

## Global experience capabilities
LOT-I18N-001, LOT-COMMS-001, LOT-GROWTH-001 and LOT-NOTIF-001 define proposed bounded capabilities and integration contracts. They must remain tenant- and product-aware; shared platform capability must not create hidden coupling between Affiliate and Lottery.

## Future regulated gaming domains
LOT-GAMING-STRATEGY-001 defines future Sportsbook, Live Casino and RNG/E-Gaming as separate bounded contexts with independent provider adapters, lifecycle state machines, entitlements, jurisdictional eligibility, financial semantics and release gates. These are roadmap horizons only; no provider, licence, API, runtime or market launch is approved. Affiliate remains the first delivery priority, followed by Lottery; each later domain requires separate legal, provider, finance, security and certification evidence.

## Open decisions
Scale, deployment regions, availability, backups, RPO/RTO, physical tenant isolation, and final technology choices must be decided before production.