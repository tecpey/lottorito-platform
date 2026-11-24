-- Disposable P-01 fixture only. Never use these credentials or objects in production.
DO $role$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_runtime') THEN
    CREATE ROLE app_runtime LOGIN PASSWORD 'p01-only-not-for-production'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
END;
$role$;

ALTER ROLE app_runtime
  LOGIN PASSWORD 'p01-only-not-for-production'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;

DROP TABLE IF EXISTS public.tenant_records;
DROP TABLE IF EXISTS public.tenant_memberships;

CREATE TABLE public.tenant_memberships (
  tenant_id uuid NOT NULL,
  subject_id text NOT NULL,
  active boolean NOT NULL DEFAULT true,
  lock_version bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (tenant_id, subject_id)
);

ALTER TABLE public.tenant_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_memberships FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_memberships_app_access
  ON public.tenant_memberships
  AS PERMISSIVE
  FOR ALL
  TO app_runtime
  USING (true)
  WITH CHECK (true);

CREATE POLICY tenant_memberships_tenant_guard
  ON public.tenant_memberships
  AS RESTRICTIVE
  FOR ALL
  TO app_runtime
  USING (
    tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
  )
  WITH CHECK (
    tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
  );

CREATE TABLE public.tenant_records (
  tenant_id uuid NOT NULL,
  record_id uuid NOT NULL,
  natural_key text NOT NULL,
  payload text NOT NULL,
  PRIMARY KEY (tenant_id, record_id),
  UNIQUE (tenant_id, natural_key),
  CHECK (length(natural_key) BETWEEN 1 AND 80),
  CHECK (length(payload) <= 1000)
);

ALTER TABLE public.tenant_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_records FORCE ROW LEVEL SECURITY;

-- At least one permissive policy is required for access. Keep it broad,
-- then make tenant ownership a RESTRICTIVE guard so future permissive policies
-- cannot widen access by OR-composition.
CREATE POLICY tenant_records_app_access
  ON public.tenant_records
  AS PERMISSIVE
  FOR ALL
  TO app_runtime
  USING (true)
  WITH CHECK (true);

CREATE POLICY tenant_records_tenant_guard
  ON public.tenant_records
  AS RESTRICTIVE
  FOR ALL
  TO app_runtime
  USING (
    tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
  )
  WITH CHECK (
    tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
  );

GRANT USAGE ON SCHEMA public TO app_runtime;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tenant_records TO app_runtime;
GRANT SELECT ON public.tenant_memberships TO app_runtime;
-- PostgreSQL requires UPDATE on at least one column for SELECT ... FOR SHARE.
-- Grant only the inert lock_version column, never the active authorization flag.
GRANT UPDATE (lock_version) ON public.tenant_memberships TO app_runtime;

-- Synthetic active memberships; production membership lifecycle is not implemented.
INSERT INTO public.tenant_memberships (tenant_id, subject_id, active) VALUES
  ('11111111-1111-4111-8111-111111111111', 'synthetic-user-a', true),
  ('22222222-2222-4222-8222-222222222222', 'synthetic-user-b', true);

-- Synthetic tenants and deliberately colliding record IDs/natural keys.
INSERT INTO public.tenant_records (tenant_id, record_id, natural_key, payload) VALUES
  ('11111111-1111-4111-8111-111111111111',
   'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
   'welcome', 'synthetic tenant A fixture'),
  ('22222222-2222-4222-8222-222222222222',
   'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
   'welcome', 'synthetic tenant B fixture'),
  ('22222222-2222-4222-8222-222222222222',
   'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
   'tenant-b-private', 'tenant B private fixture');
