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

DO $dispatcher_role$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'job_dispatcher') THEN
    CREATE ROLE job_dispatcher LOGIN PASSWORD 'p01-dispatcher-not-for-production'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
END;
$dispatcher_role$;

ALTER ROLE job_dispatcher
  LOGIN PASSWORD 'p01-dispatcher-not-for-production'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;

-- Alternative identity-bound isolation experiment: a database login identity
-- maps to exactly one tenant. These are synthetic per-tenant credentials.
DO $tenant_roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tenant_a_runtime') THEN
    CREATE ROLE tenant_a_runtime LOGIN PASSWORD 'p01-tenant-a-not-for-production'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tenant_b_runtime') THEN
    CREATE ROLE tenant_b_runtime LOGIN PASSWORD 'p01-tenant-b-not-for-production'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tenant_identity_owner') THEN
    CREATE ROLE tenant_identity_owner NOLOGIN
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
END;
$tenant_roles$;

ALTER ROLE tenant_a_runtime LOGIN PASSWORD 'p01-tenant-a-not-for-production'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE tenant_b_runtime LOGIN PASSWORD 'p01-tenant-b-not-for-production'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE tenant_identity_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;

CREATE SCHEMA IF NOT EXISTS private AUTHORIZATION tenant_identity_owner;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO tenant_a_runtime, tenant_b_runtime;

CREATE TABLE IF NOT EXISTS private.tenant_role_map (
  database_role name PRIMARY KEY,
  tenant_id uuid NOT NULL UNIQUE
);
ALTER TABLE private.tenant_role_map OWNER TO tenant_identity_owner;
GRANT SELECT ON private.tenant_role_map TO tenant_identity_owner;

CREATE OR REPLACE FUNCTION private.current_tenant_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, private, pg_temp
AS $function$
  SELECT tenant_id
    FROM private.tenant_role_map
   WHERE database_role = session_user::name
$function$;
ALTER FUNCTION private.current_tenant_id() OWNER TO tenant_identity_owner;
REVOKE ALL ON FUNCTION private.current_tenant_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.current_tenant_id() TO tenant_a_runtime, tenant_b_runtime;

DROP TABLE IF EXISTS public.job_dispatch;
DROP TABLE IF EXISTS public.tenant_jobs;
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

CREATE POLICY tenant_memberships_identity_guard
  ON public.tenant_memberships
  AS PERMISSIVE
  FOR ALL
  TO tenant_a_runtime, tenant_b_runtime
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());

CREATE TABLE public.tenant_jobs (
  tenant_id uuid NOT NULL,
  job_id uuid NOT NULL,
  subject_id text NOT NULL,
  payload text NOT NULL,
  status text NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued', 'completed', 'rejected')),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  completed_at timestamptz,
  PRIMARY KEY (tenant_id, job_id),
  CHECK (length(payload) <= 1000)
);

ALTER TABLE public.tenant_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_jobs FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_jobs_app_access
  ON public.tenant_jobs
  AS PERMISSIVE
  FOR ALL
  TO app_runtime
  USING (true)
  WITH CHECK (true);

CREATE POLICY tenant_jobs_tenant_guard
  ON public.tenant_jobs
  AS RESTRICTIVE
  FOR ALL
  TO app_runtime
  USING (
    tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
  )
  WITH CHECK (
    tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
  );

CREATE POLICY tenant_jobs_identity_guard
  ON public.tenant_jobs
  AS PERMISSIVE
  FOR ALL
  TO tenant_a_runtime, tenant_b_runtime
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());

-- Cross-tenant dispatch metadata contains no job payload. Only the dispatcher
-- can scan/claim it; the application can insert only within its current tenant.
CREATE TABLE public.job_dispatch (
  tenant_id uuid NOT NULL,
  job_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'claimed', 'completed')),
  attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  claimed_at timestamptz,
  PRIMARY KEY (tenant_id, job_id),
  FOREIGN KEY (tenant_id, job_id)
    REFERENCES public.tenant_jobs (tenant_id, job_id)
);

ALTER TABLE public.job_dispatch ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_dispatch FORCE ROW LEVEL SECURITY;

CREATE POLICY job_dispatch_app_insert
  ON public.job_dispatch
  AS PERMISSIVE
  FOR INSERT
  TO app_runtime
  WITH CHECK (true);

CREATE POLICY job_dispatch_app_tenant_guard
  ON public.job_dispatch
  AS RESTRICTIVE
  FOR INSERT
  TO app_runtime
  WITH CHECK (
    tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
  );

CREATE POLICY job_dispatcher_read
  ON public.job_dispatch
  AS PERMISSIVE
  FOR SELECT
  TO job_dispatcher
  USING (true);

CREATE POLICY job_dispatcher_update
  ON public.job_dispatch
  AS PERMISSIVE
  FOR UPDATE
  TO job_dispatcher
  USING (true)
  WITH CHECK (true);

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

CREATE POLICY tenant_records_identity_guard
  ON public.tenant_records
  AS PERMISSIVE
  FOR ALL
  TO tenant_a_runtime, tenant_b_runtime
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());

GRANT USAGE ON SCHEMA public TO app_runtime;
GRANT USAGE ON SCHEMA public TO job_dispatcher;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tenant_records TO app_runtime;
GRANT SELECT ON public.tenant_memberships TO app_runtime;
-- PostgreSQL requires UPDATE on at least one column for SELECT ... FOR SHARE.
-- Grant only the inert lock_version column, never the active authorization flag.
GRANT UPDATE (lock_version) ON public.tenant_memberships TO app_runtime;
GRANT SELECT, INSERT, UPDATE (status, completed_at) ON public.tenant_jobs TO app_runtime;
GRANT INSERT ON public.job_dispatch TO app_runtime;
GRANT SELECT, UPDATE (status, attempts, claimed_at) ON public.job_dispatch TO job_dispatcher;
-- Per-tenant login roles receive data access only through identity-bound RLS.
GRANT USAGE ON SCHEMA public TO tenant_a_runtime, tenant_b_runtime;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tenant_records TO tenant_a_runtime, tenant_b_runtime;
GRANT SELECT ON public.tenant_memberships TO tenant_a_runtime, tenant_b_runtime;
GRANT UPDATE (lock_version) ON public.tenant_memberships TO tenant_a_runtime, tenant_b_runtime;
GRANT SELECT, INSERT, UPDATE (status, completed_at) ON public.tenant_jobs TO tenant_a_runtime, tenant_b_runtime;


INSERT INTO private.tenant_role_map (database_role, tenant_id) VALUES
  ('tenant_a_runtime', '11111111-1111-4111-8111-111111111111'),
  ('tenant_b_runtime', '22222222-2222-4222-8222-222222222222')
ON CONFLICT (database_role) DO UPDATE SET tenant_id = EXCLUDED.tenant_id;

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
   'tenant-b-private', 'tenant B private fixture'),
  ('11111111-1111-4111-8111-111111111111',
   'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
   'tenant-a-private', 'tenant A private fixture');
