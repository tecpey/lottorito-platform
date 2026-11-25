# P-06 — End-to-End Observability and Privacy

**Document ID:** LOT-PROT-P06-001 | **Version:** 0.3.0 | **Status:** Synthetic P-06 PR Integration and Documentation Governance passed on PR head 9f30a2966ce77aca8a7df6acf8e803733bd723dd; production instrumentation/privacy approval not implied

## Authority and boundary

P-06 tests whether a synthetic Affiliate & Agent event can be reconstructed from partner ingress through authentication, inbox, attribution, commission evaluation, outbox, worker, ledger posting and reconciliation—without turning telemetry into a second ledger or exposing secrets and unnecessary personal data.

The experiment reuses the P-02 disposable PostgreSQL ledger fixture to create one real synthetic double-entry journal. It adds a PostgreSQL-backed telemetry policy fixture with W3C Trace Context-compatible identifiers, OpenTelemetry-style spans, structured logs, bounded metrics, alert ownership, tenant-scoped RLS and an audited forensic mapping gate.

This is not an implemented application instrumentation layer, deployed OpenTelemetry Collector, SIEM, alerting service, privacy certification or production security audit. No real user, partner, financial or credential data is used.

## Research basis

- W3C Trace Context standardizes traceparent/tracestate propagation and explicitly prohibits using those fields for personally identifiable or otherwise sensitive information.
- OpenTelemetry context-propagation guidance warns against placing credentials, API keys or PII in baggage; messaging semantic conventions recommend propagating message-creation context to correlate producer and consumer work.
- OWASP Logging Cheat Sheet recommends excluding or masking access tokens, session identifiers, passwords, database connection strings, cryptographic keys, payment-card data and unnecessary PII; it also calls for validation, safe encoding, tamper detection and restricted access.
- Prometheus instrumentation guidance warns against high-cardinality labels such as user IDs and email addresses; each unique label set creates another time series.
- OpenTelemetry Collector can transform/filter telemetry, but the contrib redaction processor has mixed maturity (alpha for logs/metrics, beta for traces in the referenced status). Collector redaction is therefore defense-in-depth, not the application's primary privacy boundary.
- NIST SP 800-92 remains the published log-management guide; NIST's SP 800-92 Rev. 1 planning guide is a draft/revision effort and is not treated as a final normative control.

## Synthetic experiment

### 1. End-to-end trace and ledger correlation

1. Apply the existing P-02 ledger schema to a disposable PostgreSQL 18.7 database.
2. Post one balanced USD journal through the actual P-02 posting function under Tenant A's runtime role.
3. Generate a random W3C-format trace ID and span IDs; build a parent chain across partner ingress, authentication, inbox persistence, attribution, commission calculation, outbox publication, worker consumption, ledger posting and reconciliation.
4. Propagate the same trace context across the synthetic asynchronous producer/consumer boundary. Do not put tenant/user identifiers, credentials or PII in traceparent, tracestate or baggage.
5. Put HMAC-derived opaque references for tenant, actor, source event, economic effect and journal in access-controlled spans. Keep the raw-to-opaque mapping in a restricted forensic table.
6. Assert that the source-event reference appears throughout the trace, the economic-effect reference appears from qualification onward, and the actual P-02 journal reference appears in ledger and reconciliation spans.

### 2. Privacy and log-injection controls

- Create synthetic canaries for access token, API key, session cookie, password, database URL, email, phone and card PAN. Include them in the in-memory source payload and a synthetic exception message.
- Emit only allowlisted structured fields, bounded event names, safe message codes, pseudonymous references and exception type/error code. Do not persist raw exception text or the raw payload in telemetry.
- Supply an event-type value containing CR/LF and a canary. Record only a bounded validation-failure event and reason code.
- Supply baggage containing email, API key and tenant ID; drop it rather than propagating it.
- Scan spans, logs, metrics, alerts and privileged audit records for every canary, raw identifier and prohibited field name.

### 3. Tenant scope and forensic access

- Store telemetry spans and structured logs with an HMAC-derived tenant reference and enforce row-level security using the authenticated database role-to-tenant map, not a caller-supplied tenant field.
- Prove Tenant A can read its own trace and logs while Tenant B sees zero rows. Telemetry readers cannot access the raw correlation map.
- Require a forensic reader to record an approved reason code before the same database session can query the raw-to-opaque correlation view. Record actor reference, action, target trace, reason and outcome in an append-only privileged audit table.
- Reject audit UPDATE/DELETE.

### 4. Metrics and alert hygiene

- Simulate 500 tenant identities while aggregating metrics only by bounded operation, outcome, product-domain and reason-code dimensions.
- Assert the metric schema has no tenant, user, event, actor or journal identifier columns and the number of distinct series stays bounded.
- Seed alerts for queue backlog, reconciliation gap, provider outage, ledger invariant violation and authorization denial. Each must have a severity, owner team and stable runbook identifier.

## Acceptance criteria

- P06-LEDGER: a real P-02 journal is posted and referenced by the trace.
- P06-TRACE: nine spans form one valid W3C-compatible trace with a complete parent chain.
- P06-CORRELATION: source event, economic effect and journal references are consistent across the expected spans.
- P06-ASYNC: producer/outbox and worker spans retain trace correlation.
- P06-PRIVACY: no secret/PII canary, raw tenant/user identifier or prohibited field appears in telemetry.
- P06-BAGGAGE: sensitive baggage is dropped.
- P06-INJECTION: CR/LF event-name input is converted to a bounded validation-failure event.
- P06-TENANT: tenant-scoped RLS returns only the authenticated tenant's spans/logs.
- P06-FORENSIC: raw correlation mapping is unavailable until reason-coded access is recorded; the access is audited.
- P06-AUDIT: privileged audit records reject UPDATE/DELETE.
- P06-CARDINALITY: 500 synthetic tenants do not increase metric series beyond the bounded label set.
- P06-ALERTS: all five alert classes have severity, owner and runbook identifiers.

## Safety and limitations

- The harness creates W3C-compatible trace identifiers and OTel-style span records but does not link an OpenTelemetry SDK into the Lottorito application and does not send OTLP to a real Collector/exporter.
- The HMAC key is ephemeral CI-only test material. Key custody, rotation, cross-service pseudonym consistency and re-identification governance remain open.
- PostgreSQL RLS and role mapping are a synthetic access-control proof, not a complete telemetry-platform authorization design.
- No log/trace storage encryption, retention/deletion lifecycle, cross-region data residency, sampling strategy, collector hardening, telemetry export controls, production SLOs, alert delivery, paging, or on-call runbooks are implemented.
- Alert owner/runbook identifiers are checked as metadata only; no real alert routing occurs.
- Logs, spans, metrics and audit records are not the ledger and must never be used to calculate balances or authorize financial transitions.
- RPO/RTO, legal basis, jurisdictional privacy requirements and production telemetry access policies remain owner/security/legal decisions.



## Final CI evidence

- P-06 PR Integration [run 45535315659](https://github.com/tecpey/lottorito-platform/actions/runs/45535315659) and Documentation Governance [run 45535315503](https://github.com/tecpey/lottorito-platform/actions/runs/45535315503) passed on PR head `9f30a2966ce77aca8a7df6acf8e803733bd723dd`.
- Nine linked spans correlated the actual P-02 journal from partner ingress to reconciliation. The run generated 500 unique synthetic tenant references while retaining only four metric series.
- All assertions passed: P-02 journal, W3C parent chain, async trace correlation, secret/PII canary absence, baggage filtering, log-injection normalization, tenant RLS, audited forensic access, least privilege, append-only audit, bounded cardinality and alert owner/severity/runbook.
- An initial harness run failed only because the test compared PostgreSQL boolean text `false` with psql's display form `f`; the assertion was corrected and the final PR-head run passed.

## References

- https://www.w3.org/TR/trace-context/
- https://opentelemetry.io/docs/concepts/context-propagation/
- https://opentelemetry.io/docs/specs/semconv/messaging/messaging-spans/
- https://opentelemetry.io/docs/collector/transforming-telemetry/
- https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/redactionprocessor
- https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- https://prometheus.io/docs/practices/instrumentation/
- https://prometheus.io/docs/practices/naming/
- https://csrc.nist.gov/pubs/sp/800/92/final
- https://csrc.nist.gov/Projects/log-management

## P-09B scope-aware correlation addendum (2026-11-25)

The P-09 continuation extends the synthetic correlation key from `(tenant_id, source_event_id)` to `(tenant_id, scope_kind, scope_id, source_event_id)`. The forensic access session and grant are bound to the same tuple plus `trace_id`; the forensic view matches every dimension rather than trace ID alone. The P-06 runner inserts the same tenant/source-event UUID for Affiliate and Lottery and proves that an Affiliate forensic grant returns only the Affiliate row, while a separate Lottery grant returns only the Lottery row. The P-06 workflow on the current P-09 candidate is the acceptance gate; this remains a synthetic fixture, not production telemetry authorization.

P-09B candidate validation: P-06 End-to-End Observability and Privacy run [45628562800](https://github.com/tecpey/lottorito-platform/actions/runs/45628562800) passed on candidate head `109530985a00bd158866e45a8c11e3bb5f520f53`. The run confirms same-tenant Affiliate/Lottery rows with a colliding source UUID and trace ID remain independently addressable; each audited forensic grant reveals only its matching product row. The canary scan also confirms raw source UUIDs are not written into the audit target reference.
