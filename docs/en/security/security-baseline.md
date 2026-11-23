# Security and Privacy Baseline

**Document ID:** LOT-SEC-001 | **Version:** 0.1.0 | **Status:** Draft

## Baseline controls
Secure authentication and sessions; MFA for privileged roles; least privilege; RBAC and tenant scope on every request; input validation and parameterized queries; secret manager and no secrets in Git/logs; encryption in transit and for sensitive data at rest; rate limits and replay protection; audit sensitive operations; dependency and license scanning; encrypted backups and restore tests; personal-data minimization and retention policy.

## Key threats
Cross-tenant leakage, forged partner events, replay, duplicate commissions, ledger tampering, affiliate account takeover, administrator abuse, secret disclosure, and inconsistent financial reporting.

## Security acceptance
Negative authorization and tenant-isolation tests, webhook signatures, idempotency, session revocation, audit integrity, and dependency scanning must be covered in QA/CI. Legal and privacy requirements must be reviewed per market.