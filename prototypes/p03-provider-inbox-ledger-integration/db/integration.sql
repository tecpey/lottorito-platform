-- P-03D: provider inbox -> P-02 posting -> P-03C ledger outbox, in one tenant/product-bound DB identity.
-- Applied only after P-02 schema and P-03C integration.sql in a disposable PostgreSQL database.

DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='tenant_a_affiliate_runtime') THEN
    CREATE ROLE tenant_a_affiliate_runtime LOGIN PASSWORD 'p03d-tenant-a-affiliate-not-production'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='tenant_b_affiliate_runtime') THEN
    CREATE ROLE tenant_b_affiliate_runtime LOGIN PASSWORD 'p03d-tenant-b-affiliate-not-production'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='provider_event_owner') THEN
    CREATE ROLE provider_event_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='provider_event_executor') THEN
    CREATE ROLE provider_event_executor NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
END
$roles$;

ALTER ROLE tenant_a_affiliate_runtime LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
ALTER ROLE tenant_b_affiliate_runtime LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
ALTER ROLE provider_event_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE provider_event_executor NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;

-- Product identity is derived from the authenticated database role, never from a caller-set GUC.
CREATE TABLE IF NOT EXISTS private.product_role_map (
  database_role name PRIMARY KEY,
  product_id uuid NOT NULL
);
ALTER TABLE private.product_role_map OWNER TO tenant_identity_owner;
REVOKE ALL ON private.product_role_map FROM PUBLIC;

INSERT INTO private.tenant_role_map (database_role, tenant_id)
VALUES
  ('tenant_a_affiliate_runtime', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  ('tenant_b_affiliate_runtime', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb')
ON CONFLICT (database_role) DO UPDATE SET tenant_id = EXCLUDED.tenant_id;

INSERT INTO private.product_role_map (database_role, product_id)
VALUES
  ('tenant_a_affiliate_runtime', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'),
  ('tenant_b_affiliate_runtime', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01')
ON CONFLICT (database_role) DO UPDATE SET product_id = EXCLUDED.product_id;

CREATE OR REPLACE FUNCTION private.current_product_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, private, pg_temp
AS $function$
  SELECT product_id FROM private.product_role_map
   WHERE database_role = session_user::name
$function$;
ALTER FUNCTION private.current_product_id() OWNER TO tenant_identity_owner;
REVOKE ALL ON FUNCTION private.current_product_id() FROM PUBLIC;

GRANT USAGE ON SCHEMA public TO tenant_a_affiliate_runtime, tenant_b_affiliate_runtime,
  provider_event_owner, provider_event_executor;
GRANT USAGE ON SCHEMA private TO provider_event_executor;
GRANT EXECUTE ON FUNCTION private.current_tenant_id() TO provider_event_executor;
GRANT EXECUTE ON FUNCTION private.current_product_id() TO provider_event_executor;
GRANT EXECUTE ON FUNCTION public.post_journal(text, uuid, uuid, jsonb) TO provider_event_executor;

GRANT CREATE ON SCHEMA public TO provider_event_owner, provider_event_executor;
GRANT CREATE ON SCHEMA private TO provider_event_owner, provider_event_executor;

CREATE TABLE public.provider_installations (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  installation_id uuid NOT NULL,
  provider_id text NOT NULL CHECK (provider_id ~ '^[A-Za-z0-9._:-]{1,32}$'),
  active boolean NOT NULL DEFAULT true,
  allowed_event_types text[] NOT NULL,
  allowed_key_ids text[] NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, installation_id),
  UNIQUE (tenant_id, product_id, provider_id, installation_id),
  CHECK (cardinality(allowed_event_types) > 0),
  CHECK (cardinality(allowed_key_ids) > 0)
);

CREATE TABLE public.provider_account_mappings (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  provider_id text NOT NULL,
  event_type text NOT NULL,
  currency_code text NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
  debit_account_id uuid NOT NULL,
  credit_account_id uuid NOT NULL,
  active boolean NOT NULL DEFAULT true,
  PRIMARY KEY (tenant_id, product_id, provider_id, event_type, currency_code),
  CHECK (debit_account_id <> credit_account_id),
  FOREIGN KEY (tenant_id, debit_account_id, currency_code)
    REFERENCES public.ledger_accounts (tenant_id, account_id, currency_code),
  FOREIGN KEY (tenant_id, credit_account_id, currency_code)
    REFERENCES public.ledger_accounts (tenant_id, account_id, currency_code)
);

CREATE TABLE public.provider_event_inbox (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  installation_id uuid NOT NULL,
  provider_id text NOT NULL,
  provider_event_id text NOT NULL CHECK (provider_event_id ~ '^[A-Za-z0-9._:-]{1,80}$'),
  event_type text NOT NULL CHECK (event_type ~ '^[A-Za-z0-9._:-]{1,120}$'),
  provider_timestamp timestamptz NOT NULL,
  received_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
  payload_hash text NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  signature_key_id text NOT NULL CHECK (signature_key_id ~ '^[A-Za-z0-9._:-]{1,80}$'),
  effect_id uuid NOT NULL,
  source_event_id uuid NOT NULL,
  PRIMARY KEY (tenant_id, product_id, provider_id, provider_event_id),
  UNIQUE (tenant_id, product_id, installation_id, provider_event_id),
  FOREIGN KEY (tenant_id, product_id, installation_id)
    REFERENCES public.provider_installations (tenant_id, product_id, installation_id),
  CHECK (payload->>'type' = event_type),
  CHECK (payload->>'event_id' = provider_event_id)
);

CREATE TABLE public.provider_processing_state (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  provider_id text NOT NULL,
  provider_event_id text NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'leased', 'processed', 'dead')),
  attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  max_attempts integer NOT NULL DEFAULT 5 CHECK (max_attempts BETWEEN 1 AND 20),
  available_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  lease_owner text,
  lease_token uuid,
  lease_until timestamptz,
  journal_id uuid,
  processed_at timestamptz,
  last_error text CHECK (last_error IS NULL OR length(last_error) <= 1000),
  PRIMARY KEY (tenant_id, product_id, provider_id, provider_event_id),
  FOREIGN KEY (tenant_id, product_id, provider_id, provider_event_id)
    REFERENCES public.provider_event_inbox (tenant_id, product_id, provider_id, provider_event_id),
  FOREIGN KEY (tenant_id, journal_id)
    REFERENCES public.ledger_journals (tenant_id, journal_id),
  CHECK (attempts <= max_attempts),
  CHECK (
    (status = 'leased' AND lease_owner IS NOT NULL AND lease_token IS NOT NULL AND lease_until IS NOT NULL)
    OR (status <> 'leased' AND lease_owner IS NULL AND lease_token IS NULL AND lease_until IS NULL)
  ),
  CHECK ((status = 'processed') = (journal_id IS NOT NULL)),
  CHECK ((status = 'processed') = (processed_at IS NOT NULL))
);

CREATE TABLE public.provider_event_conflicts (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  provider_id text NOT NULL,
  provider_event_id text NOT NULL,
  accepted_payload_hash text NOT NULL,
  conflicting_payload_hash text NOT NULL,
  observed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, provider_id, provider_event_id, conflicting_payload_hash),
  FOREIGN KEY (tenant_id, product_id, provider_id, provider_event_id)
    REFERENCES public.provider_event_inbox (tenant_id, product_id, provider_id, provider_event_id),
  CHECK (accepted_payload_hash ~ '^[0-9a-f]{64}$'),
  CHECK (conflicting_payload_hash ~ '^[0-9a-f]{64}$'),
  CHECK (accepted_payload_hash <> conflicting_payload_hash)
);

CREATE TABLE public.provider_event_expectations (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  provider_id text NOT NULL,
  provider_event_id text NOT NULL,
  expected_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, provider_id, provider_event_id),
  FOREIGN KEY (tenant_id, product_id, provider_id)
    REFERENCES public.provider_installations (tenant_id, product_id, provider_id)
);

ALTER TABLE public.provider_installations OWNER TO provider_event_owner;
ALTER TABLE public.provider_account_mappings OWNER TO provider_event_owner;
ALTER TABLE public.provider_event_inbox OWNER TO provider_event_owner;
ALTER TABLE public.provider_processing_state OWNER TO provider_event_owner;
ALTER TABLE public.provider_event_conflicts OWNER TO provider_event_owner;
ALTER TABLE public.provider_event_expectations OWNER TO provider_event_owner;

DO $rls$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'provider_installations', 'provider_account_mappings', 'provider_event_inbox',
    'provider_processing_state', 'provider_event_conflicts', 'provider_event_expectations'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_name);
    EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', table_name);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR ALL TO provider_event_executor USING (tenant_id = private.current_tenant_id() AND product_id = private.current_product_id()) WITH CHECK (tenant_id = private.current_tenant_id() AND product_id = private.current_product_id())',
      table_name || '_tenant_product_guard', table_name
    );
  END LOOP;
END
$rls$;

CREATE INDEX provider_event_claim_idx
  ON public.provider_processing_state (tenant_id, product_id, status, available_at, provider_event_id);

CREATE FUNCTION private.reject_provider_event_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
BEGIN
  RAISE EXCEPTION 'provider inbox and conflict records are immutable' USING ERRCODE = '55000';
END
$function$;
ALTER FUNCTION private.reject_provider_event_mutation() OWNER TO provider_event_owner;
REVOKE ALL ON FUNCTION private.reject_provider_event_mutation() FROM PUBLIC;

CREATE TRIGGER provider_event_inbox_immutable
  BEFORE UPDATE OR DELETE ON public.provider_event_inbox
  FOR EACH ROW EXECUTE FUNCTION private.reject_provider_event_mutation();

CREATE TRIGGER provider_event_conflicts_immutable
  BEFORE UPDATE OR DELETE ON public.provider_event_conflicts
  FOR EACH ROW EXECUTE FUNCTION private.reject_provider_event_mutation();

CREATE FUNCTION private.initialize_provider_processing_state()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
BEGIN
  IF NEW.tenant_id IS DISTINCT FROM private.current_tenant_id()
     OR NEW.product_id IS DISTINCT FROM private.current_product_id() THEN
    RAISE EXCEPTION 'provider inbox tenant/product context mismatch' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.provider_processing_state (tenant_id, product_id, provider_id, provider_event_id)
  VALUES (NEW.tenant_id, NEW.product_id, NEW.provider_id, NEW.provider_event_id);
  RETURN NEW;
END
$function$;
ALTER FUNCTION private.initialize_provider_processing_state() OWNER TO provider_event_executor;
REVOKE ALL ON FUNCTION private.initialize_provider_processing_state() FROM PUBLIC;

CREATE TRIGGER provider_event_processing_state_after_insert
  AFTER INSERT ON public.provider_event_inbox
  FOR EACH ROW EXECUTE FUNCTION private.initialize_provider_processing_state();

GRANT SELECT ON public.provider_installations, public.provider_account_mappings,
  public.provider_event_inbox, public.provider_event_conflicts,
  public.provider_event_expectations TO provider_event_executor;
GRANT INSERT ON public.provider_event_inbox, public.provider_event_conflicts,
  public.provider_processing_state TO provider_event_executor;
GRANT SELECT, UPDATE ON public.provider_processing_state TO provider_event_executor;

CREATE FUNCTION public.ingest_provider_event(
  p_installation_id uuid,
  p_provider_id text,
  p_provider_event_id text,
  p_event_type text,
  p_provider_timestamp timestamptz,
  p_payload jsonb,
  p_payload_hash text,
  p_signature_key_id text,
  p_effect_id uuid,
  p_source_event_id uuid
)
RETURNS TABLE(outcome text, product_id uuid, existing_status text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE
  v_tenant uuid;
  v_product uuid;
  v_allowed_events text[];
  v_allowed_keys text[];
  v_existing_hash text;
  v_status text;
  v_inserted integer;
BEGIN
  v_tenant := private.current_tenant_id();
  v_product := private.current_product_id();
  IF v_tenant IS NULL OR v_product IS NULL THEN
    RAISE EXCEPTION 'database role is not mapped to tenant and product' USING ERRCODE = '42501';
  END IF;
  IF p_installation_id IS NULL OR p_provider_id IS NULL OR p_provider_event_id IS NULL
     OR p_provider_event_id !~ '^[A-Za-z0-9._:-]{1,80}$'
     OR p_event_type IS NULL OR p_event_type !~ '^[A-Za-z0-9._:-]{1,120}$'
     OR p_provider_timestamp IS NULL OR p_payload IS NULL OR jsonb_typeof(p_payload) <> 'object'
     OR p_payload->>'event_id' IS DISTINCT FROM p_provider_event_id
     OR p_payload->>'type' IS DISTINCT FROM p_event_type
     OR p_payload_hash IS NULL OR p_payload_hash !~ '^[0-9a-f]{64}$'
     OR p_signature_key_id IS NULL OR p_effect_id IS NULL OR p_source_event_id IS NULL THEN
    RAISE EXCEPTION 'invalid provider event envelope' USING ERRCODE = '22023';
  END IF;

  SELECT i.allowed_event_types, i.allowed_key_ids, i.product_id
    INTO v_allowed_events, v_allowed_keys, v_product
    FROM public.provider_installations i
   WHERE i.tenant_id = v_tenant AND i.product_id = v_product
     AND i.installation_id = p_installation_id
     AND i.provider_id = p_provider_id AND i.active = true;
  IF NOT FOUND THEN
    RETURN QUERY SELECT 'unknown_installation'::text, NULL::uuid, NULL::text;
    RETURN;
  END IF;
  IF NOT (p_event_type = ANY(v_allowed_events))
     OR NOT (p_signature_key_id = ANY(v_allowed_keys)) THEN
    RETURN QUERY SELECT 'installation_policy_rejected'::text, v_product, NULL::text;
    RETURN;
  END IF;

  INSERT INTO public.provider_event_inbox (
    tenant_id, product_id, installation_id, provider_id, provider_event_id,
    event_type, provider_timestamp, payload, payload_hash, signature_key_id,
    effect_id, source_event_id
  ) VALUES (
    v_tenant, v_product, p_installation_id, p_provider_id, p_provider_event_id,
    p_event_type, p_provider_timestamp, p_payload, p_payload_hash, p_signature_key_id,
    p_effect_id, p_source_event_id
  )
  ON CONFLICT DO NOTHING
  RETURNING provider_event_id INTO p_provider_event_id;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted = 1 THEN
    RETURN QUERY SELECT 'accepted'::text, v_product, 'pending'::text;
    RETURN;
  END IF;

  SELECT i.payload_hash, s.status
    INTO v_existing_hash, v_status
    FROM public.provider_event_inbox i
    JOIN public.provider_processing_state s USING (tenant_id, product_id, provider_id, provider_event_id)
   WHERE i.tenant_id = v_tenant AND i.product_id = v_product
     AND i.provider_id = p_provider_id AND i.provider_event_id = p_provider_event_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'provider event conflict row is not visible in installation scope' USING ERRCODE = '40001';
  END IF;
  IF v_existing_hash = p_payload_hash THEN
    RETURN QUERY SELECT 'duplicate'::text, v_product, v_status;
    RETURN;
  END IF;

  INSERT INTO public.provider_event_conflicts (
    tenant_id, product_id, provider_id, provider_event_id,
    accepted_payload_hash, conflicting_payload_hash
  ) VALUES (
    v_tenant, v_product, p_provider_id, p_provider_event_id, v_existing_hash, p_payload_hash
  ) ON CONFLICT DO NOTHING;
  RETURN QUERY SELECT 'payload_conflict'::text, v_product, v_status;
END
$function$;

CREATE FUNCTION public.claim_provider_events(p_batch_size integer, p_lease_seconds integer, p_worker_id text)
RETURNS TABLE(
  installation_id uuid, provider_id text, provider_event_id text, event_type text,
  payload jsonb, effect_id uuid, source_event_id uuid, attempt integer,
  lease_token uuid, lease_until timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE v_tenant uuid; v_product uuid;
BEGIN
  v_tenant := private.current_tenant_id();
  v_product := private.current_product_id();
  IF v_tenant IS NULL OR v_product IS NULL THEN
    RAISE EXCEPTION 'database role is not mapped to tenant and product' USING ERRCODE = '42501';
  END IF;
  IF p_batch_size IS NULL OR p_batch_size < 1 OR p_batch_size > 100
     OR p_lease_seconds IS NULL OR p_lease_seconds < 1 OR p_lease_seconds > 300
     OR p_worker_id IS NULL OR p_worker_id !~ '^[A-Za-z0-9._:-]{1,80}$' THEN
    RAISE EXCEPTION 'invalid provider claim parameters' USING ERRCODE = '22023';
  END IF;

  UPDATE public.provider_processing_state s
     SET status='dead', lease_owner=NULL, lease_token=NULL, lease_until=NULL,
         last_error='provider lease expired after maximum attempts'
   WHERE s.tenant_id=v_tenant AND s.product_id=v_product
     AND s.status='leased' AND s.lease_until <= clock_timestamp()
     AND s.attempts >= s.max_attempts;

  RETURN QUERY
  WITH candidates AS (
    SELECT s.tenant_id, s.product_id, s.provider_id, s.provider_event_id
      FROM public.provider_processing_state s
     WHERE s.tenant_id=v_tenant AND s.product_id=v_product
       AND s.attempts < s.max_attempts
       AND ((s.status='pending' AND s.available_at <= clock_timestamp())
         OR (s.status='leased' AND s.lease_until <= clock_timestamp()))
     ORDER BY s.available_at, s.provider_event_id
     FOR UPDATE SKIP LOCKED
     LIMIT p_batch_size
  ),
  claimed AS (
    UPDATE public.provider_processing_state s
       SET status='leased', attempts=s.attempts+1,
           lease_owner=p_worker_id, lease_token=gen_random_uuid(),
           lease_until=clock_timestamp()+make_interval(secs=>p_lease_seconds)
      FROM candidates c
     WHERE s.tenant_id=c.tenant_id AND s.product_id=c.product_id
       AND s.provider_id=c.provider_id AND s.provider_event_id=c.provider_event_id
    RETURNING s.tenant_id,s.product_id,s.provider_id,s.provider_event_id,
              s.attempts,s.lease_token,s.lease_until
  )
  SELECT i.installation_id,i.provider_id,i.provider_event_id,i.event_type,
         i.payload,i.effect_id,i.source_event_id,c.attempts,c.lease_token,c.lease_until
    FROM claimed c
    JOIN public.provider_event_inbox i USING(tenant_id,product_id,provider_id,provider_event_id)
   ORDER BY i.received_at,i.provider_event_id;
END
$function$;

CREATE FUNCTION public.process_provider_event(
  p_installation_id uuid,p_provider_id text,p_provider_event_id text,p_lease_token uuid
)
RETURNS TABLE(journal_id uuid,duplicate boolean,outcome text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE
  v_tenant uuid; v_product uuid;
  v_state public.provider_processing_state%ROWTYPE;
  v_inbox public.provider_event_inbox%ROWTYPE;
  v_mapping public.provider_account_mappings%ROWTYPE;
  v_amount text; v_currency text; v_lines jsonb;
  v_journal_id uuid; v_duplicate boolean;
BEGIN
  v_tenant := private.current_tenant_id();
  v_product := private.current_product_id();
  IF v_tenant IS NULL OR v_product IS NULL THEN
    RAISE EXCEPTION 'database role is not mapped to tenant and product' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_state
    FROM public.provider_processing_state s
   WHERE s.tenant_id=v_tenant AND s.product_id=v_product
     AND s.provider_id=p_provider_id AND s.provider_event_id=p_provider_event_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT NULL::uuid,false,'not_found'::text;
    RETURN;
  END IF;
  IF v_state.status='processed' THEN
    RETURN QUERY SELECT v_state.journal_id,true,'processed'::text;
    RETURN;
  END IF;
  IF v_state.status <> 'leased' OR v_state.lease_token IS DISTINCT FROM p_lease_token
     OR v_state.lease_until <= clock_timestamp() THEN
    RETURN QUERY SELECT NULL::uuid,false,'stale'::text;
    RETURN;
  END IF;

  SELECT * INTO v_inbox
    FROM public.provider_event_inbox i
   WHERE i.tenant_id=v_tenant AND i.product_id=v_product
     AND i.provider_id=p_provider_id AND i.provider_event_id=p_provider_event_id
     AND i.installation_id=p_installation_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'provider inbox source is unavailable' USING ERRCODE = 'P0002';
  END IF;

  v_amount := v_inbox.payload #>> '{data,amount_minor}';
  v_currency := v_inbox.payload #>> '{data,currency_code}';
  IF v_amount IS NULL OR v_amount !~ '^[1-9][0-9]{0,37}$'
     OR v_currency IS NULL OR v_currency !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION 'provider financial data is invalid' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_mapping
    FROM public.provider_account_mappings m
   WHERE m.tenant_id=v_tenant AND m.product_id=v_product
     AND m.provider_id=p_provider_id AND m.event_type=v_inbox.event_type
     AND m.currency_code=v_currency AND m.active=true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'provider account mapping is unavailable' USING ERRCODE = 'P0002';
  END IF;

  v_lines := jsonb_build_array(
    jsonb_build_object('line_no',1,'account_id',v_mapping.debit_account_id,
      'currency_code',v_currency,'direction','debit','amount_minor',v_amount),
    jsonb_build_object('line_no',2,'account_id',v_mapping.credit_account_id,
      'currency_code',v_currency,'direction','credit','amount_minor',v_amount)
  );

  SELECT p.journal_id,p.duplicate INTO v_journal_id,v_duplicate
    FROM public.post_journal(
      'provider:'||p_provider_id||':'||p_provider_event_id,
      v_inbox.effect_id,v_inbox.source_event_id,v_lines
    ) p;

  UPDATE public.provider_processing_state
     SET status='processed',journal_id=v_journal_id,processed_at=clock_timestamp(),
         lease_owner=NULL,lease_token=NULL,lease_until=NULL,last_error=NULL
   WHERE tenant_id=v_tenant AND product_id=v_product
     AND provider_id=p_provider_id AND provider_event_id=p_provider_event_id
     AND status='leased' AND lease_token=p_lease_token
     AND lease_until > clock_timestamp();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'provider lease changed during processing' USING ERRCODE = '40001';
  END IF;
  RETURN QUERY SELECT v_journal_id,v_duplicate,'processed'::text;
END
$function$;

CREATE FUNCTION public.fail_provider_event(
  p_provider_id text,p_provider_event_id text,p_lease_token uuid,p_error text,p_retry_seconds integer
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE v_tenant uuid; v_product uuid; v_attempts integer; v_max integer; v_status text;
BEGIN
  v_tenant := private.current_tenant_id();
  v_product := private.current_product_id();
  IF v_tenant IS NULL OR v_product IS NULL OR p_retry_seconds IS NULL
     OR p_retry_seconds < 0 OR p_retry_seconds > 86400 THEN
    RAISE EXCEPTION 'invalid provider failure request' USING ERRCODE = '22023';
  END IF;
  SELECT attempts,max_attempts INTO v_attempts,v_max
    FROM public.provider_processing_state
   WHERE tenant_id=v_tenant AND product_id=v_product
     AND provider_id=p_provider_id AND provider_event_id=p_provider_event_id
     AND status='leased' AND lease_token=p_lease_token
     AND lease_until > clock_timestamp()
   FOR UPDATE;
  IF NOT FOUND THEN RETURN 'stale'; END IF;
  v_status := CASE WHEN v_attempts >= v_max THEN 'dead' ELSE 'pending' END;
  UPDATE public.provider_processing_state
     SET status=v_status,available_at=clock_timestamp()+make_interval(secs=>p_retry_seconds),
         lease_owner=NULL,lease_token=NULL,lease_until=NULL,
         last_error=left(COALESCE(p_error,'provider processing failed'),1000)
   WHERE tenant_id=v_tenant AND product_id=v_product
     AND provider_id=p_provider_id AND provider_event_id=p_provider_event_id;
  RETURN v_status;
END
$function$;

CREATE FUNCTION public.list_provider_event_reconciliation()
RETURNS TABLE(provider_id text,provider_event_id text,inbox_status text,processing_status text,journal_id uuid,expected_at timestamptz)
LANGUAGE sql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
  SELECT e.provider_id,e.provider_event_id,
         CASE WHEN i.provider_event_id IS NULL THEN 'missing' ELSE 'received' END,
         COALESCE(s.status,'missing'),s.journal_id,e.expected_at
    FROM public.provider_event_expectations e
    LEFT JOIN public.provider_event_inbox i
      ON i.tenant_id=e.tenant_id AND i.product_id=e.product_id
     AND i.provider_id=e.provider_id AND i.provider_event_id=e.provider_event_id
    LEFT JOIN public.provider_processing_state s
      ON s.tenant_id=i.tenant_id AND s.product_id=i.product_id
     AND s.provider_id=i.provider_id AND s.provider_event_id=i.provider_event_id
   WHERE e.tenant_id=private.current_tenant_id()
     AND e.product_id=private.current_product_id()
   ORDER BY e.provider_id,e.provider_event_id
$function$;

ALTER FUNCTION public.ingest_provider_event(uuid,text,text,text,timestamptz,jsonb,text,text,uuid,uuid) OWNER TO provider_event_executor;
ALTER FUNCTION public.claim_provider_events(integer,integer,text) OWNER TO provider_event_executor;
ALTER FUNCTION public.process_provider_event(uuid,text,text,uuid) OWNER TO provider_event_executor;
ALTER FUNCTION public.fail_provider_event(text,text,uuid,text,integer) OWNER TO provider_event_executor;
ALTER FUNCTION public.list_provider_event_reconciliation() OWNER TO provider_event_executor;

REVOKE ALL ON FUNCTION public.ingest_provider_event(uuid,text,text,text,timestamptz,jsonb,text,text,uuid,uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.claim_provider_events(integer,integer,text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.process_provider_event(uuid,text,text,uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.fail_provider_event(text,text,uuid,text,integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_provider_event_reconciliation() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.ingest_provider_event(uuid,text,text,text,timestamptz,jsonb,text,text,uuid,uuid)
  TO tenant_a_affiliate_runtime,tenant_b_affiliate_runtime;
GRANT EXECUTE ON FUNCTION public.claim_provider_events(integer,integer,text)
  TO tenant_a_affiliate_runtime,tenant_b_affiliate_runtime;
GRANT EXECUTE ON FUNCTION public.process_provider_event(uuid,text,text,uuid)
  TO tenant_a_affiliate_runtime,tenant_b_affiliate_runtime;
GRANT EXECUTE ON FUNCTION public.fail_provider_event(text,text,uuid,text,integer)
  TO tenant_a_affiliate_runtime,tenant_b_affiliate_runtime;
GRANT EXECUTE ON FUNCTION public.list_provider_event_reconciliation()
  TO tenant_a_affiliate_runtime,tenant_b_affiliate_runtime;

REVOKE CREATE ON SCHEMA public FROM provider_event_owner,provider_event_executor;
REVOKE CREATE ON SCHEMA private FROM provider_event_owner,provider_event_executor;
