-- Disposable P-03 schema. Never run against shared, staging or production databases.
DROP VIEW IF EXISTS public.provider_event_reconciliation;
DROP TABLE IF EXISTS public.webhook_delivery_attempts CASCADE;
DROP TABLE IF EXISTS public.outbound_webhook_deliveries CASCADE;
DROP TABLE IF EXISTS public.provider_event_conflicts CASCADE;
DROP TABLE IF EXISTS public.provider_event_expectations CASCADE;
DROP TABLE IF EXISTS public.provider_event_inbox CASCADE;

DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'event_runtime') THEN
    CREATE ROLE event_runtime LOGIN PASSWORD 'p03-runtime-not-for-production'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'event_owner') THEN
    CREATE ROLE event_owner NOLOGIN
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
END;
$roles$;
ALTER ROLE event_runtime LOGIN PASSWORD 'p03-runtime-not-for-production'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE event_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;

CREATE TABLE public.provider_event_inbox (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  provider_id text NOT NULL,
  provider_event_id text NOT NULL,
  event_type text NOT NULL,
  event_source text NOT NULL,
  event_subject text,
  event_time timestamptz,
  provider_sequence bigint,
  payload_hash text NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  signature_key_id text NOT NULL,
  canonical_event jsonb NOT NULL CHECK (jsonb_typeof(canonical_event) = 'object'),
  status text NOT NULL DEFAULT 'accepted'
    CHECK (status IN ('accepted', 'processing', 'retry', 'processed', 'dead_letter', 'quarantined')),
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  available_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  lease_until timestamptz,
  claimed_by text,
  last_error_code text,
  received_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  processed_at timestamptz,
  PRIMARY KEY (tenant_id, product_id, provider_id, provider_event_id)
);
ALTER TABLE public.provider_event_inbox OWNER TO event_owner;

CREATE TABLE public.provider_event_conflicts (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  provider_id text NOT NULL,
  provider_event_id text NOT NULL,
  accepted_payload_hash text NOT NULL,
  conflicting_payload_hash text NOT NULL,
  detected_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, provider_id, provider_event_id, conflicting_payload_hash)
);
ALTER TABLE public.provider_event_conflicts OWNER TO event_owner;

-- Synthetic expectations model a partner's independently queried event log.
CREATE TABLE public.provider_event_expectations (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  provider_id text NOT NULL,
  provider_event_id text NOT NULL,
  expected_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, provider_id, provider_event_id)
);
ALTER TABLE public.provider_event_expectations OWNER TO event_owner;

CREATE TABLE public.outbound_webhook_deliveries (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  delivery_id uuid NOT NULL,
  endpoint_id text NOT NULL,
  event_id text NOT NULL,
  payload_hash text NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'retry', 'delivered', 'failed', 'dead_letter')),
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  available_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  lease_until timestamptz,
  claimed_by text,
  last_http_status integer,
  last_error_code text,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  delivered_at timestamptz,
  PRIMARY KEY (tenant_id, product_id, delivery_id),
  UNIQUE (tenant_id, product_id, endpoint_id, event_id)
);
ALTER TABLE public.outbound_webhook_deliveries OWNER TO event_owner;

CREATE TABLE public.webhook_delivery_attempts (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  delivery_id uuid NOT NULL,
  attempt_no integer NOT NULL CHECK (attempt_no > 0),
  attempted_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  finished_at timestamptz,
  outcome text NOT NULL CHECK (outcome IN ('in_flight', 'delivered', 'retryable_failure', 'permanent_failure')),
  http_status integer,
  error_code text,
  PRIMARY KEY (tenant_id, product_id, delivery_id, attempt_no),
  FOREIGN KEY (tenant_id, product_id, delivery_id)
    REFERENCES public.outbound_webhook_deliveries (tenant_id, product_id, delivery_id)
);
ALTER TABLE public.webhook_delivery_attempts OWNER TO event_owner;

CREATE INDEX provider_inbox_claim_idx
  ON public.provider_event_inbox (tenant_id, product_id, status, available_at, received_at);
CREATE INDEX provider_inbox_lease_idx
  ON public.provider_event_inbox (tenant_id, product_id, status, lease_until);
CREATE INDEX outbound_delivery_claim_idx
  ON public.outbound_webhook_deliveries (tenant_id, product_id, status, available_at, created_at);

DO $rls$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'provider_event_inbox', 'provider_event_conflicts',
    'provider_event_expectations', 'outbound_webhook_deliveries',
    'webhook_delivery_attempts'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_name);
    EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', table_name);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS PERMISSIVE FOR ALL TO event_runtime USING (true) WITH CHECK (true)',
      table_name || '_runtime_access', table_name
    );
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR ALL TO event_runtime USING (tenant_id = NULLIF(current_setting(''app.tenant_id'', true), '''')::uuid AND product_id = NULLIF(current_setting(''app.product_id'', true), '''')::uuid) WITH CHECK (tenant_id = NULLIF(current_setting(''app.tenant_id'', true), '''')::uuid AND product_id = NULLIF(current_setting(''app.product_id'', true), '''')::uuid)',
      table_name || '_tenant_product_guard', table_name
    );
  END LOOP;
END;
$rls$;

CREATE VIEW public.provider_event_reconciliation
WITH (security_invoker = true)
AS
SELECT e.tenant_id, e.product_id, e.provider_id, e.provider_event_id,
       i.status AS inbox_status, e.expected_at
  FROM public.provider_event_expectations e
  LEFT JOIN public.provider_event_inbox i
    ON i.tenant_id = e.tenant_id
   AND i.product_id = e.product_id
   AND i.provider_id = e.provider_id
   AND i.provider_event_id = e.provider_event_id
 WHERE i.provider_event_id IS NULL
    OR i.status NOT IN ('processed');

GRANT USAGE ON SCHEMA public TO event_runtime;
GRANT SELECT, INSERT ON public.provider_event_inbox TO event_runtime;
GRANT UPDATE (status, attempt_count, available_at, lease_until, claimed_by, last_error_code, processed_at)
  ON public.provider_event_inbox TO event_runtime;
GRANT SELECT, INSERT ON public.provider_event_conflicts TO event_runtime;
GRANT SELECT ON public.provider_event_expectations TO event_runtime;
GRANT SELECT, INSERT ON public.outbound_webhook_deliveries TO event_runtime;
GRANT UPDATE (status, attempt_count, available_at, lease_until, claimed_by, last_http_status, last_error_code, delivered_at)
  ON public.outbound_webhook_deliveries TO event_runtime;
GRANT SELECT, INSERT ON public.webhook_delivery_attempts TO event_runtime;
GRANT UPDATE (finished_at, outcome, http_status, error_code)
  ON public.webhook_delivery_attempts TO event_runtime;
GRANT SELECT ON public.provider_event_reconciliation TO event_runtime;
