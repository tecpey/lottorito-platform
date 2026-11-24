-- P-03 disposable PostgreSQL fixture. Synthetic data only; never use in production.
CREATE ROLE tenant_a_outbox_runtime LOGIN PASSWORD 'p03-tenant-a-not-production' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
CREATE ROLE tenant_b_outbox_runtime LOGIN PASSWORD 'p03-tenant-b-not-production' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
CREATE ROLE outbox_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
CREATE ROLE outbox_executor NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
CREATE ROLE tenant_identity_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;

CREATE SCHEMA private AUTHORIZATION tenant_identity_owner;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO outbox_executor;
CREATE TABLE private.tenant_role_map(database_role name PRIMARY KEY, tenant_id uuid NOT NULL UNIQUE);
ALTER TABLE private.tenant_role_map OWNER TO tenant_identity_owner;
CREATE FUNCTION private.current_tenant_id()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
SET search_path=pg_catalog,private,pg_temp
AS $fn$
 SELECT tenant_id FROM private.tenant_role_map WHERE database_role=session_user::name
$fn$;
ALTER FUNCTION private.current_tenant_id() OWNER TO tenant_identity_owner;
REVOKE ALL ON FUNCTION private.current_tenant_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.current_tenant_id() TO outbox_executor;

CREATE TABLE public.outbox_events(
 tenant_id uuid NOT NULL,event_id uuid NOT NULL,aggregate_id uuid NOT NULL,event_type text NOT NULL,
 payload jsonb NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),PRIMARY KEY(tenant_id,event_id)
);
CREATE TABLE public.outbox_delivery_state(
 tenant_id uuid NOT NULL,event_id uuid NOT NULL,status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','leased','published','dead')),
 attempts integer NOT NULL DEFAULT 0 CHECK(attempts>=0),max_attempts integer NOT NULL DEFAULT 3 CHECK(max_attempts BETWEEN 1 AND 20),
 available_at timestamptz NOT NULL DEFAULT clock_timestamp(),lease_owner text,lease_token uuid,lease_until timestamptz,published_at timestamptz,last_error text,
 PRIMARY KEY(tenant_id,event_id),FOREIGN KEY(tenant_id,event_id) REFERENCES public.outbox_events(tenant_id,event_id),
 CHECK((status='leased')=(lease_owner IS NOT NULL AND lease_token IS NOT NULL AND lease_until IS NOT NULL)),
 CHECK((status='published')=(published_at IS NOT NULL))
);
CREATE INDEX outbox_delivery_claim_idx ON public.outbox_delivery_state(tenant_id,status,available_at,event_id);
CREATE TABLE public.consumer_inbox(
 tenant_id uuid NOT NULL,consumer_name text NOT NULL,event_id uuid NOT NULL,processed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(tenant_id,consumer_name,event_id),FOREIGN KEY(tenant_id,event_id) REFERENCES public.outbox_events(tenant_id,event_id)
);
CREATE TABLE public.consumer_effects(
 tenant_id uuid NOT NULL,consumer_name text NOT NULL,event_id uuid NOT NULL,payload jsonb NOT NULL,applied_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(tenant_id,consumer_name,event_id),FOREIGN KEY(tenant_id,consumer_name,event_id) REFERENCES public.consumer_inbox(tenant_id,consumer_name,event_id)
);

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO outbox_owner,outbox_executor,tenant_a_outbox_runtime,tenant_b_outbox_runtime;
ALTER TABLE public.outbox_events OWNER TO outbox_owner;
ALTER TABLE public.outbox_delivery_state OWNER TO outbox_owner;
ALTER TABLE public.consumer_inbox OWNER TO outbox_owner;
ALTER TABLE public.consumer_effects OWNER TO outbox_owner;

CREATE FUNCTION private.reject_outbox_mutation()
RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog
AS $fn$ BEGIN RAISE EXCEPTION 'immutable outbox record' USING ERRCODE='55000'; END $fn$;
ALTER FUNCTION private.reject_outbox_mutation() OWNER TO outbox_owner;
REVOKE ALL ON FUNCTION private.reject_outbox_mutation() FROM PUBLIC;
CREATE TRIGGER outbox_events_immutable BEFORE UPDATE OR DELETE ON public.outbox_events FOR EACH ROW EXECUTE FUNCTION private.reject_outbox_mutation();
CREATE TRIGGER consumer_inbox_immutable BEFORE UPDATE OR DELETE ON public.consumer_inbox FOR EACH ROW EXECUTE FUNCTION private.reject_outbox_mutation();
CREATE TRIGGER consumer_effects_immutable BEFORE UPDATE OR DELETE ON public.consumer_effects FOR EACH ROW EXECUTE FUNCTION private.reject_outbox_mutation();

ALTER TABLE public.outbox_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outbox_events FORCE ROW LEVEL SECURITY;
ALTER TABLE public.outbox_delivery_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outbox_delivery_state FORCE ROW LEVEL SECURITY;
ALTER TABLE public.consumer_inbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consumer_inbox FORCE ROW LEVEL SECURITY;
ALTER TABLE public.consumer_effects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consumer_effects FORCE ROW LEVEL SECURITY;
CREATE POLICY outbox_events_tenant_policy ON public.outbox_events FOR ALL TO outbox_executor USING(tenant_id=private.current_tenant_id()) WITH CHECK(tenant_id=private.current_tenant_id());
CREATE POLICY outbox_delivery_tenant_policy ON public.outbox_delivery_state FOR ALL TO outbox_executor USING(tenant_id=private.current_tenant_id()) WITH CHECK(tenant_id=private.current_tenant_id());
CREATE POLICY consumer_inbox_tenant_policy ON public.consumer_inbox FOR ALL TO outbox_executor USING(tenant_id=private.current_tenant_id()) WITH CHECK(tenant_id=private.current_tenant_id());
CREATE POLICY consumer_effects_tenant_policy ON public.consumer_effects FOR ALL TO outbox_executor USING(tenant_id=private.current_tenant_id()) WITH CHECK(tenant_id=private.current_tenant_id());
GRANT SELECT ON public.outbox_events TO outbox_executor;
GRANT SELECT,UPDATE ON public.outbox_delivery_state TO outbox_executor;
GRANT SELECT,INSERT ON public.consumer_inbox TO outbox_executor;
GRANT SELECT,INSERT ON public.consumer_effects TO outbox_executor;
