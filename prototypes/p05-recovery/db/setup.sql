-- Disposable synthetic P-05A fixture only.
DO $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='p05_tenant_a') THEN
  CREATE ROLE p05_tenant_a LOGIN PASSWORD 'p05-tenant-a-not-production' NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='p05_tenant_b') THEN
  CREATE ROLE p05_tenant_b LOGIN PASSWORD 'p05-tenant-b-not-production' NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
 END IF;
END $$;
CREATE SCHEMA p05_private;
REVOKE ALL ON SCHEMA p05_private FROM PUBLIC;
CREATE TABLE p05_private.role_tenant(role_name name PRIMARY KEY,tenant_id uuid NOT NULL UNIQUE);
INSERT INTO p05_private.role_tenant VALUES ('p05_tenant_a','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),('p05_tenant_b','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
CREATE FUNCTION p05_private.current_tenant_id() RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,p05_private AS $$ SELECT tenant_id FROM p05_private.role_tenant WHERE role_name=session_user::name $$;
REVOKE ALL ON FUNCTION p05_private.current_tenant_id() FROM PUBLIC;
GRANT USAGE ON SCHEMA p05_private TO p05_tenant_a,p05_tenant_b;
GRANT EXECUTE ON FUNCTION p05_private.current_tenant_id() TO p05_tenant_a,p05_tenant_b;
CREATE TABLE public.ledger_journals(tenant_id uuid NOT NULL,journal_id uuid NOT NULL,economic_effect_id uuid NOT NULL,currency_code text NOT NULL CHECK(currency_code ~ '^[A-Z]{3}$'),source_event_id uuid NOT NULL,PRIMARY KEY(tenant_id,journal_id),UNIQUE(tenant_id,economic_effect_id));
CREATE TABLE public.ledger_lines(tenant_id uuid NOT NULL,journal_id uuid NOT NULL,line_no integer NOT NULL,account_code text NOT NULL,direction text NOT NULL CHECK(direction IN('debit','credit')),amount_minor bigint NOT NULL CHECK(amount_minor>0),PRIMARY KEY(tenant_id,journal_id,line_no),FOREIGN KEY(tenant_id,journal_id) REFERENCES public.ledger_journals(tenant_id,journal_id));
CREATE TABLE public.source_events(tenant_id uuid NOT NULL,event_id uuid NOT NULL,economic_effect_id uuid NOT NULL,currency_code text NOT NULL,amount_minor bigint NOT NULL CHECK(amount_minor>0),PRIMARY KEY(tenant_id,event_id),UNIQUE(tenant_id,economic_effect_id));
CREATE TABLE public.object_refs(tenant_id uuid NOT NULL,object_id uuid NOT NULL,content_sha256 text NOT NULL CHECK(content_sha256 ~ '^[0-9a-f]{64}$'),PRIMARY KEY(tenant_id,object_id));
CREATE TABLE public.recovery_markers(marker text PRIMARY KEY,created_at timestamptz NOT NULL DEFAULT clock_timestamp());
INSERT INTO public.ledger_journals VALUES
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','USD','30000000-0000-4000-8000-000000000001'),
('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','USD','30000000-0000-4000-8000-000000000002');
INSERT INTO public.ledger_lines VALUES
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000001',1,'cash','debit',1000),('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000001',2,'clearing','credit',1000),
('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','10000000-0000-4000-8000-000000000002',1,'cash','debit',2000),('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','10000000-0000-4000-8000-000000000002',2,'clearing','credit',2000);
INSERT INTO public.source_events VALUES
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','USD',1000),
('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','30000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','USD',2000);
INSERT INTO public.object_refs VALUES
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','40000000-0000-4000-8000-000000000001',repeat('a',64)),
('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','40000000-0000-4000-8000-000000000002',repeat('b',64));
DO $$
DECLARE t text;
BEGIN
 FOREACH t IN ARRAY ARRAY['ledger_journals','ledger_lines','source_events','object_refs'] LOOP
  EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
  EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY',t);
  EXECUTE format('CREATE POLICY tenant_scope ON public.%I USING (tenant_id=p05_private.current_tenant_id()) WITH CHECK (tenant_id=p05_private.current_tenant_id())',t);
 END LOOP;
END $$;
GRANT SELECT ON public.ledger_journals,public.ledger_lines,public.source_events,public.object_refs TO p05_tenant_a,p05_tenant_b;
