-- P-03C integration fixture: delivery state references the P-02 ledger outbox directly.
-- This SQL is applied only after P-02 db/schema.sql in a disposable database.

DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'outbox_owner') THEN
    CREATE ROLE outbox_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'outbox_executor') THEN
    CREATE ROLE outbox_executor NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
END
$roles$;

ALTER ROLE outbox_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE outbox_executor NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;

GRANT USAGE ON SCHEMA public TO outbox_owner, outbox_executor;
GRANT USAGE ON SCHEMA private TO outbox_executor;
GRANT EXECUTE ON FUNCTION private.current_tenant_id() TO outbox_executor;
GRANT EXECUTE ON FUNCTION private.current_product_id() TO outbox_executor;
GRANT CREATE ON SCHEMA public TO outbox_owner, outbox_executor;
GRANT CREATE ON SCHEMA private TO outbox_owner, outbox_executor;

CREATE TABLE public.outbox_delivery_state (
  tenant_id uuid NOT NULL,
  product_id text NOT NULL DEFAULT 'affiliate_agent'
    CHECK (product_id IN ('affiliate_agent', 'lottery', 'shared')),
  event_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'leased', 'published', 'dead')),
  attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  max_attempts integer NOT NULL DEFAULT 3 CHECK (max_attempts BETWEEN 1 AND 20),
  available_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  lease_owner text,
  lease_token uuid,
  lease_until timestamptz,
  published_at timestamptz,
  last_error text CHECK (last_error IS NULL OR length(last_error) <= 1000),
  PRIMARY KEY (tenant_id, event_id),
  FOREIGN KEY (tenant_id, event_id)
    REFERENCES public.ledger_outbox (tenant_id, event_id),
  FOREIGN KEY (tenant_id, product_id, event_id)
    REFERENCES public.ledger_outbox (tenant_id, product_id, event_id),
  CHECK (attempts <= max_attempts),
  CHECK (
    (status = 'leased' AND lease_owner IS NOT NULL AND lease_token IS NOT NULL AND lease_until IS NOT NULL)
    OR
    (status <> 'leased' AND lease_owner IS NULL AND lease_token IS NULL AND lease_until IS NULL)
  ),
  CHECK ((status = 'published') = (published_at IS NOT NULL))
);

CREATE UNIQUE INDEX ledger_outbox_tenant_product_event_uidx
  ON public.ledger_outbox (tenant_id, product_id, event_id);

CREATE INDEX outbox_delivery_claim_idx
  ON public.outbox_delivery_state (tenant_id, product_id, status, available_at, event_id);

CREATE TABLE public.consumer_inbox (
  tenant_id uuid NOT NULL,
  product_id text NOT NULL DEFAULT 'affiliate_agent'
    CHECK (product_id IN ('affiliate_agent', 'lottery', 'shared')),
  consumer_name text NOT NULL CHECK (consumer_name ~ '^[A-Za-z0-9._:-]{1,80}$'),
  event_id uuid NOT NULL,
  processed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, consumer_name, event_id),
  FOREIGN KEY (tenant_id, event_id)
    REFERENCES public.ledger_outbox (tenant_id, event_id),
  FOREIGN KEY (tenant_id, product_id, event_id)
    REFERENCES public.ledger_outbox (tenant_id, product_id, event_id)
);

CREATE TABLE public.consumer_effects (
  tenant_id uuid NOT NULL,
  product_id text NOT NULL DEFAULT 'affiliate_agent'
    CHECK (product_id IN ('affiliate_agent', 'lottery', 'shared')),
  consumer_name text NOT NULL,
  event_id uuid NOT NULL,
  payload jsonb NOT NULL,
  applied_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, consumer_name, event_id),
  FOREIGN KEY (tenant_id, product_id, consumer_name, event_id)
    REFERENCES public.consumer_inbox (tenant_id, product_id, consumer_name, event_id)
);

ALTER TABLE public.outbox_delivery_state OWNER TO outbox_owner;
ALTER TABLE public.consumer_inbox OWNER TO outbox_owner;
ALTER TABLE public.consumer_effects OWNER TO outbox_owner;

ALTER TABLE public.outbox_delivery_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outbox_delivery_state FORCE ROW LEVEL SECURITY;
ALTER TABLE public.consumer_inbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consumer_inbox FORCE ROW LEVEL SECURITY;
ALTER TABLE public.consumer_effects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consumer_effects FORCE ROW LEVEL SECURITY;

CREATE POLICY ledger_outbox_delivery_executor_tenant
  ON public.ledger_outbox FOR SELECT TO outbox_executor
  USING (tenant_id = private.current_tenant_id()
     AND product_id = private.current_product_id());

CREATE POLICY outbox_delivery_executor_tenant
  ON public.outbox_delivery_state FOR ALL TO outbox_executor
  USING (tenant_id = private.current_tenant_id()
     AND product_id = private.current_product_id())
  WITH CHECK (tenant_id = private.current_tenant_id()
     AND product_id = private.current_product_id());

CREATE POLICY consumer_inbox_executor_tenant
  ON public.consumer_inbox FOR ALL TO outbox_executor
  USING (tenant_id = private.current_tenant_id()
     AND product_id = private.current_product_id())
  WITH CHECK (tenant_id = private.current_tenant_id()
     AND product_id = private.current_product_id());

CREATE POLICY consumer_effects_executor_tenant
  ON public.consumer_effects FOR ALL TO outbox_executor
  USING (tenant_id = private.current_tenant_id()
     AND product_id = private.current_product_id())
  WITH CHECK (tenant_id = private.current_tenant_id()
     AND product_id = private.current_product_id());

GRANT SELECT ON public.ledger_outbox TO outbox_executor;
GRANT SELECT, INSERT, UPDATE ON public.outbox_delivery_state TO outbox_executor;
GRANT SELECT, INSERT ON public.consumer_inbox TO outbox_executor;
GRANT SELECT, INSERT ON public.consumer_effects TO outbox_executor;

CREATE FUNCTION private.reject_outbox_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
BEGIN
  RAISE EXCEPTION 'consumer receipt and effect records are immutable'
    USING ERRCODE = '55000';
END
$function$;
ALTER FUNCTION private.reject_outbox_mutation() OWNER TO outbox_owner;
REVOKE ALL ON FUNCTION private.reject_outbox_mutation() FROM PUBLIC;

CREATE TRIGGER consumer_inbox_immutable
  BEFORE UPDATE OR DELETE ON public.consumer_inbox
  FOR EACH ROW EXECUTE FUNCTION private.reject_outbox_mutation();

CREATE TRIGGER consumer_effects_immutable
  BEFORE UPDATE OR DELETE ON public.consumer_effects
  FOR EACH ROW EXECUTE FUNCTION private.reject_outbox_mutation();

-- The P-02 ledger_outbox insert and this delivery-state insert share one transaction.
CREATE FUNCTION private.initialize_outbox_delivery_state()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
BEGIN
  IF NEW.tenant_id IS DISTINCT FROM private.current_tenant_id()
     OR NEW.product_id IS DISTINCT FROM private.current_product_id() THEN
    RAISE EXCEPTION 'outbox tenant context mismatch' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.outbox_delivery_state (tenant_id, product_id, event_id)
  VALUES (NEW.tenant_id, NEW.product_id, NEW.event_id);
  RETURN NEW;
END
$function$;
ALTER FUNCTION private.initialize_outbox_delivery_state() OWNER TO outbox_executor;
REVOKE ALL ON FUNCTION private.initialize_outbox_delivery_state() FROM PUBLIC;

CREATE TRIGGER ledger_outbox_delivery_state_after_insert
  AFTER INSERT ON public.ledger_outbox
  FOR EACH ROW EXECUTE FUNCTION private.initialize_outbox_delivery_state();

CREATE FUNCTION public.claim_outbox_events(
  p_batch_size integer,
  p_lease_seconds integer,
  p_worker_id text
)
RETURNS TABLE (
  event_id uuid,
  aggregate_id uuid,
  event_type text,
  payload jsonb,
  attempt integer,
  lease_token uuid,
  lease_until timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE
  v_tenant uuid;
  v_product text;
BEGIN
  v_tenant := private.current_tenant_id();
  v_product := private.current_product_id();
  IF v_tenant IS NULL OR v_product IS NULL THEN
    RAISE EXCEPTION 'database identity is not mapped to a tenant' USING ERRCODE = '42501';
  END IF;
  IF p_batch_size IS NULL OR p_batch_size < 1 OR p_batch_size > 100
     OR p_lease_seconds IS NULL OR p_lease_seconds < 1 OR p_lease_seconds > 300
     OR p_worker_id IS NULL OR p_worker_id !~ '^[A-Za-z0-9._:-]{1,80}$' THEN
    RAISE EXCEPTION 'invalid outbox claim parameters' USING ERRCODE = '22023';
  END IF;

  UPDATE public.outbox_delivery_state d
     SET status = 'dead', lease_owner = NULL, lease_token = NULL, lease_until = NULL,
         last_error = 'lease expired after maximum attempts'
   WHERE d.tenant_id = v_tenant AND d.status = 'leased'
     AND d.lease_until <= clock_timestamp() AND d.attempts >= d.max_attempts;

  RETURN QUERY
  WITH candidates AS (
    SELECT d.tenant_id, d.event_id
      FROM public.outbox_delivery_state d
     WHERE d.tenant_id = v_tenant
       AND d.product_id = v_product
       AND d.attempts < d.max_attempts
       AND (
         (d.status = 'pending' AND d.available_at <= clock_timestamp())
         OR (d.status = 'leased' AND d.lease_until <= clock_timestamp())
       )
     ORDER BY d.available_at, d.event_id
     FOR UPDATE SKIP LOCKED
     LIMIT p_batch_size
  ),
  claimed AS (
    UPDATE public.outbox_delivery_state d
       SET status = 'leased',
           attempts = d.attempts + 1,
           lease_owner = p_worker_id,
           lease_token = gen_random_uuid(),
           lease_until = clock_timestamp() + make_interval(secs => p_lease_seconds),
           published_at = NULL
      FROM candidates c
     WHERE d.tenant_id = c.tenant_id AND d.event_id = c.event_id
    RETURNING d.tenant_id, d.event_id, d.attempts, d.lease_token, d.lease_until
  )
  SELECT e.event_id, e.journal_id AS aggregate_id, e.event_type, e.payload,
         c.attempts, c.lease_token, c.lease_until
    FROM claimed c
    JOIN public.ledger_outbox e USING (tenant_id, product_id, event_id)
   ORDER BY e.created_at, e.event_id;
END
$function$;

CREATE FUNCTION public.ack_outbox_event(p_event_id uuid, p_lease_token uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE
  v_tenant uuid;
  v_product text;
  v_count integer;
BEGIN
  v_tenant := private.current_tenant_id();
  v_product := private.current_product_id();
  IF v_tenant IS NULL OR v_product IS NULL OR p_event_id IS NULL OR p_lease_token IS NULL THEN
    RAISE EXCEPTION 'invalid acknowledgement' USING ERRCODE = '22023';
  END IF;
  UPDATE public.outbox_delivery_state
     SET status = 'published', published_at = clock_timestamp(),
         lease_owner = NULL, lease_token = NULL, lease_until = NULL, last_error = NULL
   WHERE tenant_id = v_tenant AND product_id = v_product AND event_id = p_event_id
     AND status = 'leased' AND lease_token = p_lease_token
     AND lease_until > clock_timestamp();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count = 1;
END
$function$;

CREATE FUNCTION public.nack_outbox_event(
  p_event_id uuid, p_lease_token uuid, p_error text, p_retry_seconds integer
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE
  v_tenant uuid;
  v_product text;
  v_status text;
  v_attempts integer;
  v_max integer;
BEGIN
  v_tenant := private.current_tenant_id();
  v_product := private.current_product_id();
  IF v_tenant IS NULL OR v_product IS NULL OR p_event_id IS NULL OR p_lease_token IS NULL
     OR p_retry_seconds IS NULL OR p_retry_seconds < 0 OR p_retry_seconds > 86400 THEN
    RAISE EXCEPTION 'invalid negative acknowledgement' USING ERRCODE = '22023';
  END IF;
  SELECT attempts, max_attempts
    INTO v_attempts, v_max
    FROM public.outbox_delivery_state
   WHERE tenant_id = v_tenant AND product_id = v_product AND event_id = p_event_id
     AND status = 'leased' AND lease_token = p_lease_token
     AND lease_until > clock_timestamp()
   FOR UPDATE;
  IF NOT FOUND THEN
    RETURN 'stale';
  END IF;
  v_status := CASE WHEN v_attempts >= v_max THEN 'dead' ELSE 'pending' END;
  UPDATE public.outbox_delivery_state
     SET status = v_status,
         available_at = clock_timestamp() + make_interval(secs => p_retry_seconds),
         lease_owner = NULL, lease_token = NULL, lease_until = NULL,
         last_error = left(COALESCE(p_error, 'delivery failed'), 1000)
   WHERE tenant_id = v_tenant AND product_id = v_product AND event_id = p_event_id;
  RETURN v_status;
END
$function$;

CREATE FUNCTION public.consume_outbox_event(p_consumer_name text, p_event_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE
  v_tenant uuid;
  v_product text;
  v_payload jsonb;
  v_inserted integer;
BEGIN
  v_tenant := private.current_tenant_id();
  v_product := private.current_product_id();
  IF v_tenant IS NULL OR v_product IS NULL OR p_consumer_name IS NULL
     OR p_consumer_name !~ '^[A-Za-z0-9._:-]{1,80}$' OR p_event_id IS NULL THEN
    RAISE EXCEPTION 'invalid consumer receipt' USING ERRCODE = '22023';
  END IF;
  SELECT payload INTO v_payload
    FROM public.ledger_outbox
   WHERE tenant_id = v_tenant AND product_id = v_product AND event_id = p_event_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ledger outbox event is unavailable' USING ERRCODE = 'P0002';
  END IF;
  INSERT INTO public.consumer_inbox (tenant_id, product_id, consumer_name, event_id)
  VALUES (v_tenant, v_product, p_consumer_name, p_event_id)
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted = 0 THEN
    RETURN false;
  END IF;
  INSERT INTO public.consumer_effects (tenant_id, product_id, consumer_name, event_id, payload)
  VALUES (v_tenant, v_product, p_consumer_name, p_event_id, v_payload);
  RETURN true;
END
$function$;

ALTER FUNCTION public.claim_outbox_events(integer, integer, text) OWNER TO outbox_executor;
ALTER FUNCTION public.ack_outbox_event(uuid, uuid) OWNER TO outbox_executor;
ALTER FUNCTION public.nack_outbox_event(uuid, uuid, text, integer) OWNER TO outbox_executor;
ALTER FUNCTION public.consume_outbox_event(text, uuid) OWNER TO outbox_executor;

REVOKE ALL ON FUNCTION public.claim_outbox_events(integer, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.ack_outbox_event(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.nack_outbox_event(uuid, uuid, text, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.consume_outbox_event(text, uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.claim_outbox_events(integer, integer, text)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;
GRANT EXECUTE ON FUNCTION public.ack_outbox_event(uuid, uuid)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;
GRANT EXECUTE ON FUNCTION public.nack_outbox_event(uuid, uuid, text, integer)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;
GRANT EXECUTE ON FUNCTION public.consume_outbox_event(text, uuid)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;

REVOKE CREATE ON SCHEMA public FROM outbox_owner, outbox_executor;
REVOKE CREATE ON SCHEMA private FROM outbox_owner, outbox_executor;
