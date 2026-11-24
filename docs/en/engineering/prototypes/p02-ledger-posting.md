# P-02 Tenant-Bound Double-Entry Ledger Posting

**Document ID:** LOT-PROT-P02-001 | **Version:** 0.7.0 | **Status:** Synthetic prototype; separate effect/request identity stores and durable request aliases added; CI pending

## Purpose and authority

Test the smallest financially meaningful vertical slice after P-01: one tenant-bound posting request produces one immutable, balanced journal and one transactional outbox event, despite duplicate and concurrent delivery.

This is an engineering experiment, not an accounting policy, commission/NGR specification, custody design, payout authorization or production ledger. No real funds, customer records, provider events or settlement activity are used.

## Implemented model

- **Tenant identity:** PostgreSQL LOGIN identity maps to one tenant through a protected database identity map. The caller does not supply tenant_id, role name or account owner.
- **Posting boundary:** tenant roles can execute one fixed SECURITY DEFINER posting function; they have no direct SELECT/INSERT/UPDATE/DELETE grants on ledger tables. The function owner is NOLOGIN, non-superuser and not BYPASSRLS; tables use FORCE ROW LEVEL SECURITY and tenant-scoped policies.
- **Journal:** a posted journal has at least two lines. Each line has a tenant-owned account, currency code, direction and positive integer minor-unit amount.
- **Balance invariant:** debit and credit totals must match independently for every currency in the journal. A USD debit cannot be offset by a JPY credit. A multi-currency journal must balance each currency group independently.
- **Exact amounts:** amounts travel through the API as decimal strings and are stored as PostgreSQL NUMERIC(38,0); JavaScript floating-point numbers are rejected. The prototype does not define currency exponents or perform major-to-minor conversion.
- **Idempotency at two levels:** `(tenant_id, idempotency_key)` identifies a transport/API retry, while `(tenant_id, effect_id)` identifies the logical financial effect. Separate immutable tables store financial effects and request-key aliases. Every accepted request key is durably bound to its effect and journal, including retries arriving with a different key; reusing that alias later for another effect is rejected. The fingerprint includes effect ID, source event ID and normalized lines. Concurrent deliveries with different request keys but the same effect ID converge on one journal. One source event may legitimately produce multiple separately identified effects.
- **Atomic outbox:** journal header, lines, idempotency record and ledger.journal.posted outbox event (including journal ID, stable effect ID and source event ID) are created in one database statement/transaction. A failed posting leaves none of them committed.
- **Immutability:** posting requests, posted journals, lines and outbox events reject UPDATE and DELETE. Corrections require a future compensating/reversal design; this experiment does not mutate history.

## Acceptance scenarios

| ID | Scenario | Expected result |
|---|---|---|
| P02-LEDGER-01 | Balanced two-line USD journal | One posted journal, two exact lines, one outbox event |
| P02-LEDGER-02 | Same idempotency key and same request | Original journal ID returned; no duplicate journal or outbox |
| P02-LEDGER-03 | Concurrent duplicate requests | Exactly one journal and one outbox event |
| P02-LEDGER-04 | Same key with changed request content | Deterministic idempotency conflict |
| P02-LEDGER-05 | Unbalanced debit/credit | Rejected with no partial request, journal, line or outbox |
| P02-LEDGER-06 | Cross-currency netting attempt | Rejected; each currency balances independently |
| P02-LEDGER-07 | Balanced multi-currency journal | Accepted only when every currency group balances |
| P02-LEDGER-08 | 38-digit integer amount | Stored and read back exactly |
| P02-LEDGER-09 | Tenant A references Tenant B account | Generic rejection without cross-tenant account disclosure |
| P02-LEDGER-10 | Same idempotency key used by two tenants | Independent tenant-scoped operations |
| P02-LEDGER-11 | Tenant runtime attempts direct table access | Denied; only the bounded posting function is executable |
| P02-LEDGER-12 | UPDATE/DELETE against posted records | Rejected by immutability triggers |
| P02-LEDGER-13 | Unmapped database session identity | Posting denied before any journal effect |
| P02-LEDGER-14 | Float, fractional amount, duplicate line number or extra field | Rejected by application and database validation |
| P02-LEDGER-15 | Same financial effect delivered with a different request key | Original journal returned; no second posting |
| P02-LEDGER-16 | Concurrent requests with different keys but one effect ID | Exactly one journal and one outbox event |
| P02-LEDGER-17 | Same effect ID reused with changed economic content | Deterministic conflict; no second journal |
| P02-LEDGER-18 | One source event produces two distinct effect IDs | Two independent valid postings |
| P02-LEDGER-19 | SECURITY DEFINER owner, search_path and execute grants | Trusted NOLOGIN owner, fixed safe path, tenant-only execution |
| P02-LEDGER-20 | Outbox event carries stable effect identity | Downstream consumers receive the same effect ID as the journal |
| P02-LEDGER-21 | Previously accepted alias key is reused for another effect | Deterministic conflict; no new financial effect remains |

## Explicit non-goals and unresolved decisions

- No commission formula, NGR definition, revenue share, bonus treatment, negative carryover, chargeback policy, agent hierarchy, commission rate or settlement schedule is defined or inferred.
- No wallet/balance projection, customer funds, operator float, promotional credit, withdrawal, payout or payment provider is implemented.
- No FX rate, conversion, rounding policy, currency exponent registry, accounting period, chart-of-accounts governance, tax treatment, or financial reporting close is approved.
- Full reversal, partial reversal, correction workflows, source-event reconciliation against external provider statements, dispute handling and out-of-order event policy remain future experiments.
- The transactional outbox is atomic with the journal, but delivery is expected to be at-least-once; a production consumer must be idempotent and observable. No queue, relay, retry/dead-letter policy or end-to-end delivery proof is included.
- The SECURITY DEFINER function and database identity mapping are synthetic. Production threat modelling, secret lifecycle, role provisioning, key management, backup/restore, disaster recovery, performance, lock contention and independent security review remain required.
- The financial `effect_id` must be assigned from a stable business operation identity by a trusted upstream component. Generating a new random effect ID on every delivery defeats the guarantee. Its lifecycle, namespace, retention and cross-service propagation are not yet defined.
- Per-tenant identity-bound database credentials are not approved as the production topology. This P-02 slice inherits the P-01 process-local credential/pool experiment only as a test harness.

## Evidence status

All data and credentials are synthetic. P-02 run [45463594552](https://github.com/tecpey/lottorito-platform/actions/runs/45463594552) passed 25 tests (0 failed, 0 skipped) on code head `63a5ced2f3611e200a9c681e1a972d77c176c0e4`; Documentation Governance run [45463594523](https://github.com/tecpey/lottorito-platform/actions/runs/45463594523) passed. This establishes only the tested synthetic database posting invariants, not accounting correctness, regulatory eligibility, customer acceptance or production readiness.

## Research references

- [PostgreSQL 18 — Numeric Types](https://www.postgresql.org/docs/18/datatype-numeric.html): exact numeric types and monetary precision.
- [PostgreSQL 18 — INSERT / ON CONFLICT](https://www.postgresql.org/docs/18/sql-insert.html): unique-conflict handling under concurrent inserts.
- [node-postgres — Transactions](https://node-postgres.com/features/transactions): one checked-out client is required when multiple statements form a transaction.
- [AWS Builders' Library — Making retries safe with idempotent APIs](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/): request identity, parameter mismatch and atomic idempotent effects.
- [AWS Prescriptive Guidance — Transactional outbox](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html): atomically persist business state and outbox events; consumers must tolerate duplicate delivery.
- [AWS Well-Architected — Make mutating operations idempotent](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel04-bp04.html): stable idempotency tokens, atomic state tracking, retries and duplicate event handling.
- [Microsoft Architecture Center — Idempotent consumer](https://learn.microsoft.com/azure/architecture/patterns/idempotent-consumer): use a stable business-operation identity, not a broad correlation ID, to deduplicate redelivered events.
