# P-10B — Read-only Source and Legacy Data Inventory Protocol

**Document ID:** LOT-PROT-P10B-001 | **Version:** 0.1.0 | **Status:** Proposed inventory protocol; no source environment inspected or authorized | **Reviewed:** 2026-11-26

## 1. Purpose and boundary

P-10B defines how Lottorito will inventory a named source environment before designing any production migration. It is deliberately a **protocol and query template**, not an executed inventory. No database endpoint, account, credential, partner export or production data source has been supplied or authorized in this phase.

The initial pass is metadata-only and read-only. It must not extract row-level customer/player/payment data, mutate schema/data, create temporary objects, run repair scripts, or infer tenant/product ownership. Any later access to a named environment requires explicit owner authorization, a named accountable source owner/DBA, an approved purpose, a read-only identity, a bounded window and secure evidence storage outside Git and CI.

This document does not authorize production access. If a named environment and authorization are not available, P-10B remains at protocol readiness and must not be reported as an executed inventory.

## 2. Required authorization record

Before connecting to any source, record and approve:

| Field | Required evidence |
|---|---|
| Source identifier | Unique non-secret environment ID; never put a password or connection URI in the record |
| Environment class | Local / disposable CI / development / staging / production / partner sandbox |
| Accountable owner | Named system/data owner and DBA/operator responsible for the source |
| Purpose | Specific migration, reconciliation or architecture question being answered |
| Legal/privacy basis | Owner-approved purpose and jurisdiction/privacy review where applicable; do not invent lawful basis |
| Data classes | Customer/PII, authentication, financial, partner, operational, telemetry, gaming or public |
| Authorization | Written approval, scope, permitted queries, expiry and emergency stop contact |
| Access identity | Dedicated read-only principal; no shared admin login, superuser, BYPASSRLS or application runtime identity |
| Network/time window | Approved source endpoint, region/residency, allowlist and bounded access window |
| Evidence destination | Access-controlled approved location outside repository, issue comments, prompts and CI logs |
| Retention | Approved expiry and deletion procedure for inventory output |
| Change freeze/coordination | DBA approval for query load, replica selection, maintenance windows and incident escalation |

Do not connect if ownership, purpose, authorization, source classification or evidence handling is missing. A partner-provided endpoint is not authorization to access it.

## 3. Inventory sequence

### B-0 — Scope and source register

List every potential system of record and adjacent source separately: primary database, replicas, provider/partner systems, event broker, object storage, file exports, cache, search, analytics/warehouse, identity provider, audit store and backup/archive. Do not assume all are authoritative or in scope.

For each source capture owner, purpose, environment, engine/version, region/residency, data classes, writer/reader applications, consumers, backup/recovery mechanism, retention, estimated size, update cadence, dependencies and source-of-truth status. Distinguish confirmed facts from owner statements and hypotheses.

### B-1 — Metadata-only database snapshot

Use a dedicated least-privilege read-only account. Capture database version, schema/table/view inventory, approximate row counts and sizes, columns/types/nullability/default expressions, primary/unique/foreign/check constraints, index validity, table ownership, grants, RLS enabled/forced state, policies, extensions and table statistics.

- Use catalog/statistics estimates first. `pg_class.reltuples` and `pg_stat_user_tables` are estimates and may be stale; label them as estimates.
- Exact `COUNT(*)`, row sampling, query plans with execution, sequential scans, exports and large joins are not part of the default pass. They require a separate DBA-approved load window and query plan.
- Never select row payloads, secrets, password hashes, tokens, payment credentials, free-text conversations or player/customer details in this pass.
- Do not invoke arbitrary user-defined functions. Use only the reviewed catalog queries below.
- Save output only to the approved restricted evidence location. Do not paste raw inventory output into Git, PRs, issue comments or ChatGPT.

### B-2 — Logical ownership and lineage

For each table/event/object, identify:

- Owning bounded context and accountable data owner.
- Authoritative writer(s), consumers, ETL/replication jobs and manual operators.
- Tenant identifier and its authoritative derivation.
- Product identifier and its authoritative derivation.
- Legal entity/operating context where required.
- Primary key, business/natural key, foreign-key graph and lifecycle.
- Source-event ID, economic-effect ID, idempotency key and journal linkage where relevant.
- Created/updated/effective/settled timestamps, timezone and retention.
- PII/financial/sensitive columns and permitted purpose/access.
- Backup, restore, deletion, archival and audit dependencies.

Do not infer ownership from table names, UI labels, partner assumptions or current deployment configuration alone. Require the source owner and domain owner to confirm semantics.

### B-3 — Tenant/Product coverage and ambiguity register

Classify each observed identity pattern using metadata or approved aggregate queries:

- `KNOWN`: authoritative tenant and product mapping has documentary evidence.
- `NULL_OR_MISSING`: required identity absent.
- `LEGACY_SHARED`: ambiguous legacy value such as `shared`.
- `UNKNOWN_PRODUCT`: product not in the canonical allowlist.
- `CONFLICTED`: source, tenant, product, account or relationship disagree.
- `ORPHANED`: required parent/foreign-key relationship is missing.
- `DUPLICATE_KEY`: duplicate natural/economic-effect/idempotency identity candidate.
- `UNVERIFIED`: insufficient evidence to decide.

Unresolved, conflicted, orphaned and duplicate candidates are not eligible for automatic migration. They remain quarantined until documentary evidence and accountable owner adjudication are recorded. Never map `shared` to `affiliate_agent`, `lottery` or `lottorito` based on frequency, convenience, current UI or a default value.

### B-4 — Financial and event integrity inventory

For financial/event sources, capture only approved aggregates and metadata:

- Counts by tenant/product/currency/account/status/period.
- Debit and credit totals independently by currency and accounting period.
- Source-to-ledger effect linkage and missing/duplicate effect counts.
- Reversal/adjustment links, pending/held/quarantined states and suspense/exception aging.
- Provider event/delivery IDs versus economic-effect identity.
- Idempotency key collisions, same-key/different-payload conflicts and replay cursor gaps.
- Orphan journal lines, missing account mappings and currency/precision exceptions.

A matching total or row count is not proof of correct attribution. A financial aggregate cannot resolve legal ownership, revenue recognition, NGR, commission entitlement, funding, FX or payout policy. Those remain separate approved business/accounting decisions.

### B-5 — Reconcile, review and freeze the inventory

Produce a source register, metadata snapshot manifest, lineage matrix, identity coverage report, ambiguity register, financial/event aggregate report, risk register and unresolved-question list. Each artifact must record source ID, snapshot time, extraction tool/version, query version/digest, approximate/exact classification, reviewer and retention expiry.

The DBA validates query load and metadata completeness. Data/domain owners validate semantics. Security/privacy/legal review access and classification. Finance reviews financial aggregates and unresolved mappings. No one person may silently approve their own ambiguous financial mapping where dual control is required.

## 4. PostgreSQL metadata-only query template

The following is a **reviewable template**, not an instruction to connect to any environment. Run only after Section 2 authorization. It uses catalog/metadata views and does not query business-row contents. Confirm compatibility with the source PostgreSQL major version and have the DBA approve timeouts and replica selection.

```sql
BEGIN READ ONLY;

-- Example guardrails for a small metadata pass; DBA may tighten them.
SET LOCAL statement_timeout = '5s';
SET LOCAL lock_timeout = '1s';

-- 1. Database/session context. No endpoint, password or secret is selected.
SELECT
  current_database() AS database_name,
  current_user AS effective_role,
  session_user AS login_role,
  current_setting('server_version') AS server_version,
  current_setting('server_version_num') AS server_version_num,
  pg_database_size(current_database()) AS database_bytes;

-- 2. Relations and approximate size/row estimates.
-- reltuples is an estimate, not an exact count.
SELECT
  n.nspname AS schema_name,
  c.relname AS relation_name,
  c.relkind AS relation_kind,
  c.reltuples::bigint AS estimated_rows,
  pg_relation_size(c.oid) AS main_fork_bytes,
  pg_total_relation_size(c.oid) AS total_bytes,
  pg_get_userbyid(c.relowner) AS owner_name,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS rls_forced
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND c.relkind IN ('r', 'p', 'm', 'v', 'f')
ORDER BY n.nspname, c.relname;

-- 3. Column metadata. Default expressions must be reviewed before export.
SELECT
  table_schema, table_name, ordinal_position, column_name,
  data_type, udt_name, is_nullable, column_default,
  character_maximum_length, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name, ordinal_position;

-- 4. Constraints, including validation state.
SELECT
  n.nspname AS schema_name,
  c.relname AS table_name,
  con.conname AS constraint_name,
  con.contype AS constraint_type,
  con.convalidated AS is_validated,
  pg_get_constraintdef(con.oid, true) AS definition
FROM pg_constraint con
JOIN pg_class c ON c.oid = con.conrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, c.relname, con.conname;

-- 5. Index validity/readiness and definitions.
SELECT
  n.nspname AS schema_name,
  t.relname AS table_name,
  irel.relname AS index_name,
  ix.indisprimary AS is_primary,
  ix.indisunique AS is_unique,
  ix.indisvalid AS is_valid,
  ix.indisready AS is_ready,
  pg_get_indexdef(ix.indexrelid) AS definition
FROM pg_index ix
JOIN pg_class t ON t.oid = ix.indrelid
JOIN pg_class irel ON irel.oid = ix.indexrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, t.relname, irel.relname;

-- 6. RLS policies. Review role names and predicates before exporting.
SELECT
  schemaname, tablename, policyname, permissive,
  roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, tablename, policyname;

-- 7. Role capability metadata only; never query credential verifiers.
SELECT
  rolname, rolsuper, rolinherit, rolcreaterole,
  rolcreatedb, rolcanlogin, rolreplication, rolbypassrls
FROM pg_roles
ORDER BY rolname;

-- 8. Table statistics are approximate and may be stale.
SELECT
  schemaname, relname, n_live_tup, n_dead_tup,
  last_analyze, last_autoanalyze, last_vacuum, last_autovacuum
FROM pg_stat_user_tables
ORDER BY schemaname, relname;

-- 9. Installed extensions.
SELECT extname, extversion
FROM pg_extension
ORDER BY extname;

ROLLBACK;
```

This template does not inventory object storage, broker topics, provider systems, secrets managers, application-level writers or legal ownership. Those require separate source-specific read-only protocols. Catalog visibility is privilege-dependent; missing metadata must be reported as inaccessible, not interpreted as absent.

## 5. Evidence model and output schemas

Use stable source IDs and a snapshot ID. Do not use customer names, email addresses, account numbers, credentials or raw business identifiers as filenames or public issue references.

### Source register

| Field | Meaning |
|---|---|
| source_id | Opaque stable identifier |
| environment_class | Development/staging/production/partner sandbox |
| system_owner / data_owner | Accountable people/teams |
| engine_version / region | Verified technical and residency metadata |
| authoritative_domains | Explicit domains for which the source is authoritative |
| writers / consumers | Services, jobs and human operators |
| data_classes | Approved classification labels |
| backup / restore / retention | Verified references and gaps |
| access_approval_id | Reference to restricted approval record |
| snapshot_id / captured_at | Reproducibility metadata |

### Table/asset lineage register

| Field | Meaning |
|---|---|
| source_id / snapshot_id | Source and snapshot |
| schema / object | Metadata name |
| object_type / estimated_rows / bytes | Kind and estimates |
| owner_context / data_owner | Domain and accountable owner |
| authoritative_writer | Verified writer(s) |
| tenant_key / product_key | Column or derivation, with evidence |
| source_event / economic_effect / idempotency | Relevant identity fields |
| legal_entity_key | If present and approved |
| pii_financial_classification | Data classification |
| retention / deletion / backup_dependency | Lifecycle |
| evidence_ref / confidence | Restricted evidence pointer and confidence |

### Ambiguity register

Each exception has a non-sensitive opaque reference, classification, affected source/object, count or estimate, reason, evidence required, accountable adjudicator, decision, decision date and migration disposition. Allowed dispositions are `QUARANTINE`, `OWNER_CONFIRMED_MAPPING`, `EXCLUDE_FROM_SCOPE` or `REMEDIATE_AT_SOURCE`. No disposition is inferred by the inventory script.

## 6. Stop conditions

Stop the inventory and notify the source owner/DBA and security contact if:

- The account is not read-only, has superuser/BYPASSRLS or unexpected write privileges.
- The source identity, environment, region or database does not match the authorization record.
- Query latency, lock waits, replica lag, CPU/I/O or application error rates exceed the DBA-approved guardrails.
- Query output includes unexpected personal data, secrets, payload content or credential verifiers.
- A request asks to bypass RLS, inspect business rows without approval, change source state, run DDL, repair records or export a full dataset.
- A source owner disputes authority, purpose, data ownership or retention.
- Evidence would need to be stored in Git, CI logs, public issues or an unapproved system.

Preserve the minimum necessary operational evidence and stop; do not attempt a workaround.

## 7. Acceptance criteria

P-10B protocol readiness is accepted when:

- A named source register and accountable owner template exist.
- Authorization and stop conditions are explicit.
- Metadata queries are read-only, bounded and reviewed for the target engine/version.
- Estimates are distinguished from exact counts.
- Tenant/product identity, legacy ambiguity and financial/event integrity are separately inventoried.
- `shared`, null, conflicting, orphaned and duplicate candidates cannot be auto-mapped.
- Sensitive row-level data is excluded from Git/CI/agent context.
- Output schemas include evidence provenance, reviewer, confidence and retention.
- The bilingual structure check passes and semantic parity receives human review.

**Current state:** the protocol is documented only. No source environment has been inspected. P-10B execution remains blocked until the owner names a source and grants scoped read-only authorization. No production migration or data access is authorized.
