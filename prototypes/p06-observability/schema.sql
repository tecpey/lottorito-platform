-- P-06 synthetic observability/privacy fixture. No production telemetry.
DO $roles$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='p06_tenant_a_reader') THEN
  CREATE ROLE p06_tenant_a_reader LOGIN PASSWORD 'p06-tenant-a-not-production' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='p06_tenant_b_reader') THEN
  CREATE ROLE p06_tenant_b_reader LOGIN PASSWORD 'p06-tenant-b-not-production' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='p06_forensic_reader') THEN
  CREATE ROLE p06_forensic_reader LOGIN PASSWORD 'p06-forensic-not-production' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='p06_metrics_reader') THEN
  CREATE ROLE p06_metrics_reader LOGIN PASSWORD 'p06-metrics-not-production' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
 END IF;
END
$roles$;
CREATE SCHEMA p06 AUTHORIZATION postgres;
REVOKE ALL ON SCHEMA p06 FROM PUBLIC;
GRANT USAGE ON SCHEMA p06 TO p06_tenant_a_reader,p06_tenant_b_reader,p06_forensic_reader,p06_metrics_reader;

CREATE TABLE p06.role_tenant_map(database_role name PRIMARY KEY,tenant_ref text NOT NULL UNIQUE);
CREATE FUNCTION p06.current_tenant_ref() RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,p06
AS $$ SELECT tenant_ref FROM p06.role_tenant_map WHERE database_role=session_user::name $$;
REVOKE ALL ON FUNCTION p06.current_tenant_ref() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION p06.current_tenant_ref() TO p06_tenant_a_reader,p06_tenant_b_reader;

CREATE TABLE p06.spans(
 trace_id text NOT NULL CHECK(trace_id ~ '^[0-9a-f]{32}$'),
 span_id text NOT NULL CHECK(span_id ~ '^[0-9a-f]{16}$'),
 parent_span_id text CHECK(parent_span_id IS NULL OR parent_span_id ~ '^[0-9a-f]{16}$'),
 service_name text NOT NULL,
 span_name text NOT NULL,
 tenant_ref text NOT NULL,
 product_domain text NOT NULL CHECK(product_domain IN('affiliate_agent','lottery','platform')),
 source_event_ref text NOT NULL,
 economic_effect_ref text,
 journal_ref text,
 started_at timestamptz NOT NULL,
 ended_at timestamptz NOT NULL CHECK(ended_at>=started_at),
 status text NOT NULL CHECK(status IN('ok','error')),
 attributes jsonb NOT NULL DEFAULT '{}'::jsonb,
 PRIMARY KEY(trace_id,span_id)
);
ALTER TABLE p06.spans ENABLE ROW LEVEL SECURITY;
ALTER TABLE p06.spans FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_scope ON p06.spans USING(tenant_ref=p06.current_tenant_ref());
GRANT SELECT ON p06.spans TO p06_tenant_a_reader,p06_tenant_b_reader;

CREATE TABLE p06.logs(
 log_id bigserial PRIMARY KEY,
 trace_id text NOT NULL CHECK(trace_id ~ '^[0-9a-f]{32}$'),
 span_id text NOT NULL CHECK(span_id ~ '^[0-9a-f]{16}$'),
 tenant_ref text NOT NULL,
 level text NOT NULL CHECK(level IN('debug','info','warn','error')),
 event_name text NOT NULL CHECK(event_name ~ '^[a-z][a-z0-9_.]{2,80}$'),
 message_code text NOT NULL CHECK(message_code ~ '^[A-Z0-9_]{2,64}$'),
 fields jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE p06.logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE p06.logs FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_scope ON p06.logs USING(tenant_ref=p06.current_tenant_ref());
GRANT SELECT ON p06.logs TO p06_tenant_a_reader,p06_tenant_b_reader;

CREATE TABLE p06.metrics(
 metric_name text NOT NULL CHECK(metric_name IN('affiliate_events_total','commission_calculations_total','ledger_postings_total','reconciliation_checks_total')),
 operation text NOT NULL CHECK(operation IN('event_received','attribution_resolved','commission_calculated','ledger_posted','reconciliation_checked')),
 outcome text NOT NULL CHECK(outcome IN('success','rejected','retry')),
 product_domain text NOT NULL CHECK(product_domain IN('affiliate_agent','lottery','platform')),
 reason_code text CHECK(reason_code IS NULL OR reason_code IN('invalid_signature','schema_invalid','duplicate_event','provider_unavailable','reconciliation_gap','ledger_invariant_violation')),
 value bigint NOT NULL CHECK(value>=0),
 UNIQUE NULLS NOT DISTINCT(metric_name,operation,outcome,product_domain,reason_code)
);
GRANT SELECT ON p06.metrics TO p06_metrics_reader;

CREATE TABLE p06.alerts(
 alert_name text PRIMARY KEY CHECK(alert_name IN('queue.backlog','reconciliation.gap','provider.outage','ledger.invariant_violation','authorization.denied')),
 severity text NOT NULL CHECK(severity IN('critical','high','warning','info')),
 owner_team text NOT NULL,
 runbook_id text NOT NULL,
 safe_labels jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
GRANT SELECT ON p06.alerts TO p06_metrics_reader;

CREATE TABLE p06.correlation_map(
 tenant_id uuid NOT NULL,
 scope_kind text NOT NULL CHECK(scope_kind IN('product','platform')),
 scope_id text NOT NULL,
 tenant_ref text NOT NULL,
 actor_id uuid NOT NULL,
 actor_ref text NOT NULL,
 source_event_id uuid NOT NULL,
 source_event_ref text NOT NULL,
 economic_effect_id uuid NOT NULL,
 economic_effect_ref text NOT NULL,
 journal_id uuid NOT NULL,
 journal_ref text NOT NULL,
 trace_id text NOT NULL CHECK(trace_id ~ '^[0-9a-f]{32}
REVOKE ALL ON p06.correlation_map FROM PUBLIC,p06_tenant_a_reader,p06_tenant_b_reader,p06_metrics_reader,p06_forensic_reader;

CREATE TABLE p06.privileged_audit(
 audit_id bigserial PRIMARY KEY,
 actor_ref text NOT NULL,
 action text NOT NULL CHECK(action IN('telemetry.correlation_map.read','telemetry.export','event.replay.authorize','configuration.change')),
 target_ref text NOT NULL,
 reason_code text NOT NULL CHECK(reason_code IN('incident_review','export_approved','replay_authorized','configuration_approved')),
 trace_id text NOT NULL CHECK(trace_id ~ '^[0-9a-f]{32}$'),
 outcome text NOT NULL CHECK(outcome IN('allowed','denied')),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE FUNCTION p06.prevent_audit_mutation() RETURNS trigger
LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'P06_AUDIT_APPEND_ONLY'; END $$;
CREATE TRIGGER audit_append_only BEFORE UPDATE OR DELETE ON p06.privileged_audit
FOR EACH ROW EXECUTE FUNCTION p06.prevent_audit_mutation();

CREATE TABLE p06.forensic_access_sessions(
 backend_pid integer NOT NULL,
 actor_role name NOT NULL,
 tenant_id uuid NOT NULL,
 scope_kind text NOT NULL,
 scope_id text NOT NULL,
 source_event_id uuid NOT NULL,
 trace_id text NOT NULL,
 reason_code text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE FUNCTION p06.record_forensic_access(
 p_tenant_id uuid,p_scope_kind text,p_scope_id text,p_source_event_id uuid,
 p_trace_id text,p_reason_code text,p_actor_ref text
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,p06 AS $
BEGIN
 IF session_user <> 'p06_forensic_reader' THEN RAISE EXCEPTION 'P06_FORENSIC_ROLE_REQUIRED'; END IF;
 IF p_tenant_id IS NULL OR p_source_event_id IS NULL
    OR NOT ((p_scope_kind='product' AND p_scope_id IN('affiliate_agent','lottery'))
         OR (p_scope_kind='platform' AND p_scope_id='lottorito'))
    OR p_trace_id !~ '^[0-9a-f]{32}
GRANT SELECT ON p06.privileged_audit TO p06_forensic_reader;

CREATE VIEW p06.forensic_correlation_map WITH (security_barrier=true) AS
SELECT m.* FROM p06.correlation_map m
WHERE EXISTS(
 SELECT 1 FROM p06.forensic_access_sessions s
 WHERE s.backend_pid=pg_backend_pid()
 AND s.actor_role=session_user
 AND s.trace_id=m.trace_id
 AND s.created_at>clock_timestamp()-interval '5 minutes'
);
GRANT SELECT ON p06.forensic_correlation_map TO p06_forensic_reader;

INSERT INTO p06.alerts(alert_name,severity,owner_team,runbook_id,safe_labels) VALUES
('queue.backlog','high','platform-operations','RUNBOOK-QUEUE-BACKLOG-001','{"component":"event-worker"}'),
('reconciliation.gap','critical','finance-operations','RUNBOOK-RECONCILIATION-001','{"component":"ledger-reconciliation"}'),
('provider.outage','high','integrations','RUNBOOK-PROVIDER-OUTAGE-001','{"component":"partner-adapter"}'),
('ledger.invariant_violation','critical','finance-operations','RUNBOOK-LEDGER-INVARIANT-001','{"component":"ledger"}'),
('authorization.denied','warning','security-operations','RUNBOOK-AUTHZ-DENIED-001','{"component":"access-control"}');
),
 CHECK((scope_kind='product' AND scope_id IN('affiliate_agent','lottery'))
    OR (scope_kind='platform' AND scope_id='lottorito')),
 PRIMARY KEY(tenant_id,scope_kind,scope_id,source_event_id)
);
REVOKE ALL ON p06.correlation_map FROM PUBLIC,p06_tenant_a_reader,p06_tenant_b_reader,p06_metrics_reader,p06_forensic_reader;

CREATE TABLE p06.privileged_audit(
 audit_id bigserial PRIMARY KEY,
 actor_ref text NOT NULL,
 action text NOT NULL CHECK(action IN('telemetry.correlation_map.read','telemetry.export','event.replay.authorize','configuration.change')),
 target_ref text NOT NULL,
 reason_code text NOT NULL CHECK(reason_code IN('incident_review','export_approved','replay_authorized','configuration_approved')),
 trace_id text NOT NULL CHECK(trace_id ~ '^[0-9a-f]{32}$'),
 outcome text NOT NULL CHECK(outcome IN('allowed','denied')),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE FUNCTION p06.prevent_audit_mutation() RETURNS trigger
LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'P06_AUDIT_APPEND_ONLY'; END $$;
CREATE TRIGGER audit_append_only BEFORE UPDATE OR DELETE ON p06.privileged_audit
FOR EACH ROW EXECUTE FUNCTION p06.prevent_audit_mutation();

CREATE TABLE p06.forensic_access_sessions(
 backend_pid integer NOT NULL,
 actor_role name NOT NULL,
 trace_id text NOT NULL,
 reason_code text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE FUNCTION p06.record_forensic_access(p_trace_id text,p_reason_code text,p_actor_ref text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,p06 AS $$
BEGIN
 IF session_user <> 'p06_forensic_reader' THEN RAISE EXCEPTION 'P06_FORENSIC_ROLE_REQUIRED'; END IF;
 IF p_trace_id !~ '^[0-9a-f]{32}$' OR p_reason_code NOT IN('incident_review','export_approved','replay_authorized','configuration_approved') OR p_actor_ref !~ '^[0-9a-f]{64}$' THEN
  RAISE EXCEPTION 'P06_FORENSIC_ACCESS_CONTEXT_INVALID';
 END IF;
 INSERT INTO p06.privileged_audit(actor_ref,action,target_ref,reason_code,trace_id,outcome)
 VALUES(p_actor_ref,'telemetry.correlation_map.read',p_trace_id,p_reason_code,p_trace_id,'allowed');
 INSERT INTO p06.forensic_access_sessions(backend_pid,actor_role,trace_id,reason_code)
 VALUES(pg_backend_pid(),session_user,p_trace_id,p_reason_code);
END $$;
REVOKE ALL ON FUNCTION p06.record_forensic_access(text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION p06.record_forensic_access(text,text,text) TO p06_forensic_reader;
GRANT SELECT ON p06.privileged_audit TO p06_forensic_reader;

CREATE VIEW p06.forensic_correlation_map WITH (security_barrier=true) AS
SELECT m.* FROM p06.correlation_map m
WHERE EXISTS(
 SELECT 1 FROM p06.forensic_access_sessions s
 WHERE s.backend_pid=pg_backend_pid()
 AND s.actor_role=session_user
 AND s.trace_id=m.trace_id
 AND s.created_at>clock_timestamp()-interval '5 minutes'
);
GRANT SELECT ON p06.forensic_correlation_map TO p06_forensic_reader;

INSERT INTO p06.alerts(alert_name,severity,owner_team,runbook_id,safe_labels) VALUES
('queue.backlog','high','platform-operations','RUNBOOK-QUEUE-BACKLOG-001','{"component":"event-worker"}'),
('reconciliation.gap','critical','finance-operations','RUNBOOK-RECONCILIATION-001','{"component":"ledger-reconciliation"}'),
('provider.outage','high','integrations','RUNBOOK-PROVIDER-OUTAGE-001','{"component":"partner-adapter"}'),
('ledger.invariant_violation','critical','finance-operations','RUNBOOK-LEDGER-INVARIANT-001','{"component":"ledger"}'),
('authorization.denied','warning','security-operations','RUNBOOK-AUTHZ-DENIED-001','{"component":"access-control"}');

    OR p_reason_code NOT IN('incident_review','export_approved','replay_authorized','configuration_approved')
    OR p_actor_ref !~ '^[0-9a-f]{64}
GRANT SELECT ON p06.privileged_audit TO p06_forensic_reader;

CREATE VIEW p06.forensic_correlation_map WITH (security_barrier=true) AS
SELECT m.* FROM p06.correlation_map m
WHERE EXISTS(
 SELECT 1 FROM p06.forensic_access_sessions s
 WHERE s.backend_pid=pg_backend_pid()
 AND s.actor_role=session_user
 AND s.trace_id=m.trace_id
 AND s.created_at>clock_timestamp()-interval '5 minutes'
);
GRANT SELECT ON p06.forensic_correlation_map TO p06_forensic_reader;

INSERT INTO p06.alerts(alert_name,severity,owner_team,runbook_id,safe_labels) VALUES
('queue.backlog','high','platform-operations','RUNBOOK-QUEUE-BACKLOG-001','{"component":"event-worker"}'),
('reconciliation.gap','critical','finance-operations','RUNBOOK-RECONCILIATION-001','{"component":"ledger-reconciliation"}'),
('provider.outage','high','integrations','RUNBOOK-PROVIDER-OUTAGE-001','{"component":"partner-adapter"}'),
('ledger.invariant_violation','critical','finance-operations','RUNBOOK-LEDGER-INVARIANT-001','{"component":"ledger"}'),
('authorization.denied','warning','security-operations','RUNBOOK-AUTHZ-DENIED-001','{"component":"access-control"}');
),
 CHECK((scope_kind='product' AND scope_id IN('affiliate_agent','lottery'))
    OR (scope_kind='platform' AND scope_id='lottorito')),
 PRIMARY KEY(tenant_id,scope_kind,scope_id,source_event_id)
);
REVOKE ALL ON p06.correlation_map FROM PUBLIC,p06_tenant_a_reader,p06_tenant_b_reader,p06_metrics_reader,p06_forensic_reader;

CREATE TABLE p06.privileged_audit(
 audit_id bigserial PRIMARY KEY,
 actor_ref text NOT NULL,
 action text NOT NULL CHECK(action IN('telemetry.correlation_map.read','telemetry.export','event.replay.authorize','configuration.change')),
 target_ref text NOT NULL,
 reason_code text NOT NULL CHECK(reason_code IN('incident_review','export_approved','replay_authorized','configuration_approved')),
 trace_id text NOT NULL CHECK(trace_id ~ '^[0-9a-f]{32}$'),
 outcome text NOT NULL CHECK(outcome IN('allowed','denied')),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE FUNCTION p06.prevent_audit_mutation() RETURNS trigger
LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'P06_AUDIT_APPEND_ONLY'; END $$;
CREATE TRIGGER audit_append_only BEFORE UPDATE OR DELETE ON p06.privileged_audit
FOR EACH ROW EXECUTE FUNCTION p06.prevent_audit_mutation();

CREATE TABLE p06.forensic_access_sessions(
 backend_pid integer NOT NULL,
 actor_role name NOT NULL,
 trace_id text NOT NULL,
 reason_code text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE FUNCTION p06.record_forensic_access(p_trace_id text,p_reason_code text,p_actor_ref text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,p06 AS $$
BEGIN
 IF session_user <> 'p06_forensic_reader' THEN RAISE EXCEPTION 'P06_FORENSIC_ROLE_REQUIRED'; END IF;
 IF p_trace_id !~ '^[0-9a-f]{32}$' OR p_reason_code NOT IN('incident_review','export_approved','replay_authorized','configuration_approved') OR p_actor_ref !~ '^[0-9a-f]{64}$' THEN
  RAISE EXCEPTION 'P06_FORENSIC_ACCESS_CONTEXT_INVALID';
 END IF;
 INSERT INTO p06.privileged_audit(actor_ref,action,target_ref,reason_code,trace_id,outcome)
 VALUES(p_actor_ref,'telemetry.correlation_map.read',p_trace_id,p_reason_code,p_trace_id,'allowed');
 INSERT INTO p06.forensic_access_sessions(backend_pid,actor_role,trace_id,reason_code)
 VALUES(pg_backend_pid(),session_user,p_trace_id,p_reason_code);
END $$;
REVOKE ALL ON FUNCTION p06.record_forensic_access(text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION p06.record_forensic_access(text,text,text) TO p06_forensic_reader;
GRANT SELECT ON p06.privileged_audit TO p06_forensic_reader;

CREATE VIEW p06.forensic_correlation_map WITH (security_barrier=true) AS
SELECT m.* FROM p06.correlation_map m
WHERE EXISTS(
 SELECT 1 FROM p06.forensic_access_sessions s
 WHERE s.backend_pid=pg_backend_pid()
 AND s.actor_role=session_user
 AND s.trace_id=m.trace_id
 AND s.created_at>clock_timestamp()-interval '5 minutes'
);
GRANT SELECT ON p06.forensic_correlation_map TO p06_forensic_reader;

INSERT INTO p06.alerts(alert_name,severity,owner_team,runbook_id,safe_labels) VALUES
('queue.backlog','high','platform-operations','RUNBOOK-QUEUE-BACKLOG-001','{"component":"event-worker"}'),
('reconciliation.gap','critical','finance-operations','RUNBOOK-RECONCILIATION-001','{"component":"ledger-reconciliation"}'),
('provider.outage','high','integrations','RUNBOOK-PROVIDER-OUTAGE-001','{"component":"partner-adapter"}'),
('ledger.invariant_violation','critical','finance-operations','RUNBOOK-LEDGER-INVARIANT-001','{"component":"ledger"}'),
('authorization.denied','warning','security-operations','RUNBOOK-AUTHZ-DENIED-001','{"component":"access-control"}');
 THEN
  RAISE EXCEPTION 'P06_FORENSIC_ACCESS_CONTEXT_INVALID';
 END IF;
 INSERT INTO p06.privileged_audit(actor_ref,action,target_ref,reason_code,trace_id,outcome)
 VALUES(p_actor_ref,'telemetry.correlation_map.read',
        p_scope_kind || ':' || p_scope_id || ':' || p_source_event_id::text,
        p_reason_code,p_trace_id,'allowed');
 INSERT INTO p06.forensic_access_sessions(
   backend_pid,actor_role,tenant_id,scope_kind,scope_id,source_event_id,trace_id,reason_code
 )
 VALUES(pg_backend_pid(),session_user,p_tenant_id,p_scope_kind,p_scope_id,p_source_event_id,p_trace_id,p_reason_code);
END $;
REVOKE ALL ON FUNCTION p06.record_forensic_access(uuid,text,text,uuid,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION p06.record_forensic_access(uuid,text,text,uuid,text,text,text) TO p06_forensic_reader;
GRANT SELECT ON p06.privileged_audit TO p06_forensic_reader;

CREATE VIEW p06.forensic_correlation_map WITH (security_barrier=true) AS
SELECT m.* FROM p06.correlation_map m
WHERE EXISTS(
 SELECT 1 FROM p06.forensic_access_sessions s
 WHERE s.backend_pid=pg_backend_pid()
 AND s.actor_role=session_user
 AND s.trace_id=m.trace_id
 AND s.created_at>clock_timestamp()-interval '5 minutes'
);
GRANT SELECT ON p06.forensic_correlation_map TO p06_forensic_reader;

INSERT INTO p06.alerts(alert_name,severity,owner_team,runbook_id,safe_labels) VALUES
('queue.backlog','high','platform-operations','RUNBOOK-QUEUE-BACKLOG-001','{"component":"event-worker"}'),
('reconciliation.gap','critical','finance-operations','RUNBOOK-RECONCILIATION-001','{"component":"ledger-reconciliation"}'),
('provider.outage','high','integrations','RUNBOOK-PROVIDER-OUTAGE-001','{"component":"partner-adapter"}'),
('ledger.invariant_violation','critical','finance-operations','RUNBOOK-LEDGER-INVARIANT-001','{"component":"ledger"}'),
('authorization.denied','warning','security-operations','RUNBOOK-AUTHZ-DENIED-001','{"component":"access-control"}');
),
 CHECK((scope_kind='product' AND scope_id IN('affiliate_agent','lottery'))
    OR (scope_kind='platform' AND scope_id='lottorito')),
 PRIMARY KEY(tenant_id,scope_kind,scope_id,source_event_id)
);
REVOKE ALL ON p06.correlation_map FROM PUBLIC,p06_tenant_a_reader,p06_tenant_b_reader,p06_metrics_reader,p06_forensic_reader;

CREATE TABLE p06.privileged_audit(
 audit_id bigserial PRIMARY KEY,
 actor_ref text NOT NULL,
 action text NOT NULL CHECK(action IN('telemetry.correlation_map.read','telemetry.export','event.replay.authorize','configuration.change')),
 target_ref text NOT NULL,
 reason_code text NOT NULL CHECK(reason_code IN('incident_review','export_approved','replay_authorized','configuration_approved')),
 trace_id text NOT NULL CHECK(trace_id ~ '^[0-9a-f]{32}$'),
 outcome text NOT NULL CHECK(outcome IN('allowed','denied')),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE FUNCTION p06.prevent_audit_mutation() RETURNS trigger
LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'P06_AUDIT_APPEND_ONLY'; END $$;
CREATE TRIGGER audit_append_only BEFORE UPDATE OR DELETE ON p06.privileged_audit
FOR EACH ROW EXECUTE FUNCTION p06.prevent_audit_mutation();

CREATE TABLE p06.forensic_access_sessions(
 backend_pid integer NOT NULL,
 actor_role name NOT NULL,
 trace_id text NOT NULL,
 reason_code text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE FUNCTION p06.record_forensic_access(p_trace_id text,p_reason_code text,p_actor_ref text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,p06 AS $$
BEGIN
 IF session_user <> 'p06_forensic_reader' THEN RAISE EXCEPTION 'P06_FORENSIC_ROLE_REQUIRED'; END IF;
 IF p_trace_id !~ '^[0-9a-f]{32}$' OR p_reason_code NOT IN('incident_review','export_approved','replay_authorized','configuration_approved') OR p_actor_ref !~ '^[0-9a-f]{64}$' THEN
  RAISE EXCEPTION 'P06_FORENSIC_ACCESS_CONTEXT_INVALID';
 END IF;
 INSERT INTO p06.privileged_audit(actor_ref,action,target_ref,reason_code,trace_id,outcome)
 VALUES(p_actor_ref,'telemetry.correlation_map.read',p_trace_id,p_reason_code,p_trace_id,'allowed');
 INSERT INTO p06.forensic_access_sessions(backend_pid,actor_role,trace_id,reason_code)
 VALUES(pg_backend_pid(),session_user,p_trace_id,p_reason_code);
END $$;
REVOKE ALL ON FUNCTION p06.record_forensic_access(text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION p06.record_forensic_access(text,text,text) TO p06_forensic_reader;
GRANT SELECT ON p06.privileged_audit TO p06_forensic_reader;

CREATE VIEW p06.forensic_correlation_map WITH (security_barrier=true) AS
SELECT m.* FROM p06.correlation_map m
WHERE EXISTS(
 SELECT 1 FROM p06.forensic_access_sessions s
 WHERE s.backend_pid=pg_backend_pid()
 AND s.actor_role=session_user
 AND s.trace_id=m.trace_id
 AND s.created_at>clock_timestamp()-interval '5 minutes'
);
GRANT SELECT ON p06.forensic_correlation_map TO p06_forensic_reader;

INSERT INTO p06.alerts(alert_name,severity,owner_team,runbook_id,safe_labels) VALUES
('queue.backlog','high','platform-operations','RUNBOOK-QUEUE-BACKLOG-001','{"component":"event-worker"}'),
('reconciliation.gap','critical','finance-operations','RUNBOOK-RECONCILIATION-001','{"component":"ledger-reconciliation"}'),
('provider.outage','high','integrations','RUNBOOK-PROVIDER-OUTAGE-001','{"component":"partner-adapter"}'),
('ledger.invariant_violation','critical','finance-operations','RUNBOOK-LEDGER-INVARIANT-001','{"component":"ledger"}'),
('authorization.denied','warning','security-operations','RUNBOOK-AUTHZ-DENIED-001','{"component":"access-control"}');
