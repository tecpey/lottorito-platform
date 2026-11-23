# Commission Rules and Calculation Engine

**Document ID:** LOT-COM-001 | **Version:** 0.1.0 | **Status:** Draft; commercial formulas are not approved

## Models
CPA, Revenue Share, and Hybrid. Each agreement defines tenant, partner, program, affiliate cohort, effective period, currency, calculation basis, and rule version.

## Inputs
Normalized and validated events such as registration, deposit, qualified activity, NGR, and partner adjustments. Field definitions depend on the actual API contract and commercial agreement.

## NGR
NGR has no universal fixed formula. Each partner must define gross revenue and items such as bonuses, reversals, taxes/fees, and chargebacks. Every formula version has an effective period.

## Multi-level network
L1–L10 is an initial stated need. Attribution, referrer changes, level semantics, share distribution, payout caps, duplicate-payout prevention, and the effect of hierarchy changes on historical periods must be specified.

## Reproducible execution
Rules are immutable and versioned; record inputs, outputs, rule version, and calculation explanation; define rounding, minimums/maximums, negative carryover, and adjustments; control duplicate and late events.

## Figures previously mentioned
A 20%–40% range and monthly progression evaluation appeared in earlier discussions; they are unapproved and must not become executable rules until a contract or written approval exists.