-- Disposable P-03 provider-event inbox and reconciliation fixture only.
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'provider_owner') THEN
    CREATE ROLE provider_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'provider_executor') THEN
    CREATE ROLE provider_executor NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
END
$roles$;

ALTER ROLE provider_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE provider_executor NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;

DROP FUNCTION IF EXISTS public.reconcile_provider_events();
DROP FUNCTION IF EXISTS public.process_provider_event(uuid);
DROP FUNCTION IF EXISTS public.receive_provider_event(text,text,text,text,uuid,uuid,text,timestamptz,text,text,jsonb,text,text,timestamptz);
DROP TABLE IF EXISTS public.provider_inbox_outbox;
DROP TABLE IF EXISTS public.provider_event_processing;
DROP TABLE IF EXISTS public.provider_inbox;
DROP TABLE IF EXISTS public.provider_account_map;

GRANT USAGE ON SCHEMA private TO provider_executor;
GRANT EXECUTE ON FUNCTION private.current_tenant_id() TO provider_executor;
GRANT EXECUTE ON FUNCTION public.post_journal(text, uuid, uuid, jsonb) TO provider_executor;

CREATE TABLE public.provider_account_map (
  tenant_id uuid NOT NULL,
  provider_id text NOT NULL,
  provider_account_id text NOT NULL,
  currency_code text NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
  debit_account_id uuid NOT NULL,
  credit_account_id uuid NOT NULL,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, provider_id, provider_account_id, currency_code),
  FOREIGN KEY (tenant_id, debit_account_id, currency_code)
    REFERENCES public.ledger_accounts (tenant_id, account_id, currency_code),
  FOREIGN KEY (tenant_id, credit_account_id, currency_code)
    REFERENCES public.ledger_accounts (tenant_id, account_id, currency_code),
  CHECK (debit_account_id <> credit_account_id)
);

CREATE TABLE public.provider_inbox (
  tenant_id uuid NOT NULL,
  inbox_id uuid NOT NULL,
  provider_id text NOT NULL,
  provider_account_id text NOT NULL,
  provider_event_id text NOT NULL,
  event_type text NOT NULL,
  source_event_id uuid NOT NULL,
  effect_id uuid NOT NULL,
  idempotency_key text NOT NULL,
  occurred_at timestamptz,
  amount_minor text,
  currency_code text,
  payload jsonb NOT NULL,
  payload_sha256 text NOT NULL CHECK (payload_sha256 ~ '^[0-9a-f]{64}$'),
  signature_key_id text NOT NULL,
  signature_timestamp timestamptz NOT NULL,
  received_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, inbox_id),
  UNIQUE (tenant_id, provider_id, provider_account_id, provider_event_id),
  UNIQUE (tenant_id, effect_id),
  UNIQUE (tenant_id, idempotency_key),
  CHECK (length(provider_id) BETWEEN 1 AND 64),
  CHECK (length(provider_account_id) BETWEEN 1 AND 128),
  CHECK (length(provider_event_id) BETWEEN 1 AND 128),
  CHECK (length(event_type) BETWEEN 1 AND 96),
  CHECK (idempotency_key ~ '^[A-Za-z0-9._:-]{1,128}$'),
  CHECK (length(signature_key_id) BETWEEN 1 AND 64)
);

CREATE TABLE public.provider_event_processing (
  tenant_id uuid NOT NULL,
  inbox_id uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('received', 'processed', 'quarantined')),
  journal_id uuid,
  attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  last_error text,
  processed_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, inbox_id),
  FOREIGN KEY (tenant_id, inbox_id)
    REFERENCES public.provider_inbox (tenant_id, inbox_id),
  FOREIGN KEY (tenant_id, journal_id)
    REFERENCES public.ledger_journals (tenant_id, journal_id),
  CHECK ((status = 'processed') = (journal_id IS NOT NULL)),
  CHECK ((status = 'processed') = (processed_at IS NOT NULL))
);

CREATE TABLE public.provider_inbox_outbox (
  tenant_id uuid NOT NULL,
  event_id uuid NOT NULL,
  inbox_id uuid NOT NULL,
  event_type text NOT NULL CHECK (event_type = 'provider.event.accepted'),
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, event_id),
  UNIQUE (tenant_id, inbox_id, event_type),
  FOREIGN KEY (tenant_id, inbox_id)
    REFERENCES public.provider_inbox (tenant_id, inbox_id)
);

CREATE INDEX provider_inbox_tenant_received_idx
  ON public.provider_inbox (tenant_id, received_at);
CREATE INDEX provider_processing_tenant_status_idx
  ON public.provider_event_processing (tenant_id, status, updated_at);

ALTER TABLE public.provider_account_map OWNER TO provider_owner;
ALTER TABLE public.provider_inbox OWNER TO provider_owner;
ALTER TABLE public.provider_event_processing OWNER TO provider_owner;
ALTER TABLE public.provider_inbox_outbox OWNER TO provider_owner;

CREATE OR REPLACE FUNCTION private.p03_reject_immutable_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
BEGIN
  RAISE EXCEPTION 'provider inbox and outbox records are immutable'
    USING ERRCODE = '55000';
END
$function$;
REVOKE ALL ON FUNCTION private.p03_reject_immutable_mutation() FROM PUBLIC;

CREATE TRIGGER provider_inbox_immutable
  BEFORE UPDATE OR DELETE ON public.provider_inbox
  FOR EACH ROW EXECUTE FUNCTION private.p03_reject_immutable_mutation();
CREATE TRIGGER provider_inbox_outbox_immutable
  BEFORE UPDATE OR DELETE ON public.provider_inbox_outbox
  FOR EACH ROW EXECUTE FUNCTION private.p03_reject_immutable_mutation();

ALTER TABLE public.provider_account_map ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_account_map FORCE ROW LEVEL SECURITY;
ALTER TABLE public.provider_inbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_inbox FORCE ROW LEVEL SECURITY;
ALTER TABLE public.provider_event_processing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_event_processing FORCE ROW LEVEL SECURITY;
ALTER TABLE public.provider_inbox_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_inbox_outbox FORCE ROW LEVEL SECURITY;

CREATE POLICY provider_account_map_tenant
  ON public.provider_account_map FOR SELECT TO provider_executor
  USING (tenant_id = private.current_tenant_id());
CREATE POLICY provider_inbox_tenant
  ON public.provider_inbox FOR ALL TO provider_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());
CREATE POLICY provider_processing_tenant
  ON public.provider_event_processing FOR ALL TO provider_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());
CREATE POLICY provider_outbox_tenant
  ON public.provider_inbox_outbox FOR ALL TO provider_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());

CREATE POLICY provider_executor_ledger_journals_tenant
  ON public.ledger_journals FOR SELECT TO provider_executor
  USING (tenant_id = private.current_tenant_id());
CREATE POLICY provider_executor_financial_effects_tenant
  ON public.financial_effects FOR SELECT TO provider_executor
  USING (tenant_id = private.current_tenant_id());
CREATE POLICY provider_executor_ledger_lines_tenant
  ON public.ledger_lines FOR SELECT TO provider_executor
  USING (tenant_id = private.current_tenant_id());
CREATE POLICY provider_executor_ledger_outbox_tenant
  ON public.ledger_outbox FOR SELECT TO provider_executor
  USING (tenant_id = private.current_tenant_id());

GRANT USAGE ON SCHEMA public TO provider_executor;
GRANT SELECT ON public.ledger_journals, public.financial_effects,
  public.ledger_lines, public.ledger_outbox TO provider_executor;
GRANT SELECT ON public.provider_account_map TO provider_executor;
GRANT SELECT, INSERT ON public.provider_inbox TO provider_executor;
GRANT SELECT, INSERT, UPDATE ON public.provider_event_processing TO provider_executor;
GRANT SELECT, INSERT ON public.provider_inbox_outbox TO provider_executor;

CREATE OR REPLACE FUNCTION public.receive_provider_event(
  p_provider_id text,
  p_provider_account_id text,
  p_provider_event_id text,
  p_event_type text,
  p_source_event_id uuid,
  p_effect_id uuid,
  p_idempotency_key text,
  p_occurred_at timestamptz,
  p_amount_minor text,
  p_currency_code text,
  p_payload jsonb,
  p_payload_sha256 text,
  p_signature_key_id text,
  p_signature_timestamp timestamptz
)
RETURNS TABLE (inbox_id uuid, duplicate boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE
  v_tenant_id uuid;
  v_inbox_id uuid;
  v_existing_hash text;
  v_inserted integer;
BEGIN
  v_tenant_id := private.current_tenant_id();
  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'database identity is not mapped to a tenant' USING ERRCODE = '42501';
  END IF;

  IF p_provider_id IS NULL OR p_provider_id !~ '^[a-z0-9._-]{1,64}$'
     OR p_provider_account_id IS NULL OR length(p_provider_account_id) NOT BETWEEN 1 AND 128
     OR p_provider_event_id IS NULL OR length(p_provider_event_id) NOT BETWEEN 1 AND 128
     OR p_event_type IS NULL OR length(p_event_type) NOT BETWEEN 1 AND 96
     OR p_source_event_id IS NULL OR p_effect_id IS NULL
     OR p_idempotency_key IS NULL OR p_idempotency_key !~ '^[A-Za-z0-9._:-]{1,128}$'
     OR p_payload IS NULL OR jsonb_typeof(p_payload) IS DISTINCT FROM 'object'
     OR p_payload_sha256 IS NULL OR p_payload_sha256 !~ '^[0-9a-f]{64}$'
     OR p_signature_key_id IS NULL OR length(p_signature_key_id) NOT BETWEEN 1 AND 64
     OR p_signature_timestamp IS NULL THEN
    RAISE EXCEPTION 'invalid provider event envelope' USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.provider_account_map AS m
     WHERE m.tenant_id = v_tenant_id
       AND m.provider_id = p_provider_id
       AND m.provider_account_id = p_provider_account_id
       AND m.active = true
  ) THEN
    RAISE EXCEPTION 'provider account is not mapped to this tenant' USING ERRCODE = '42501';
  END IF;

  v_inbox_id := gen_random_uuid();
  INSERT INTO public.provider_inbox (
    tenant_id, inbox_id, provider_id, provider_account_id, provider_event_id,
    event_type, source_event_id, effect_id, idempotency_key, occurred_at,
    amount_minor, currency_code, payload, payload_sha256, signature_key_id,
    signature_timestamp
  ) VALUES (
    v_tenant_id, v_inbox_id, p_provider_id, p_provider_account_id, p_provider_event_id,
    p_event_type, p_source_event_id, p_effect_id, p_idempotency_key, p_occurred_at,
    p_amount_minor, p_currency_code, p_payload, p_payload_sha256, p_signature_key_id,
    p_signature_timestamp
  )
  ON CONFLICT DO NOTHING;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted = 0 THEN
    SELECT i.inbox_id, i.payload_sha256
      INTO v_inbox_id, v_existing_hash
      FROM public.provider_inbox AS i
     WHERE i.tenant_id = v_tenant_id
       AND i.provider_id = p_provider_id
       AND i.provider_account_id = p_provider_account_id
       AND i.provider_event_id = p_provider_event_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'provider event identity conflicts with an existing effect' USING ERRCODE = '22023';
    END IF;
    IF v_existing_hash IS DISTINCT FROM p_payload_sha256 THEN
      RAISE EXCEPTION 'provider event ID was redelivered with different payload content'
        USING ERRCODE = '22023';
    END IF;
    RETURN QUERY SELECT v_inbox_id, true;
    RETURN;
  END IF;

  INSERT INTO public.provider_event_processing (tenant_id, inbox_id, status)
  VALUES (v_tenant_id, v_inbox_id, 'received');

  INSERT INTO public.provider_inbox_outbox (
    tenant_id, event_id, inbox_id, event_type, payload
  ) VALUES (
    v_tenant_id,
    gen_random_uuid(),
    v_inbox_id,
    'provider.event.accepted',
    jsonb_build_object(
      'inbox_id', v_inbox_id,
      'provider_id', p_provider_id,
      'provider_account_id', p_provider_account_id,
      'provider_event_id', p_provider_event_id,
      'effect_id', p_effect_id
    )
  );

  RETURN QUERY SELECT v_inbox_id, false;
END
$function$;

CREATE OR REPLACE FUNCTION public.process_provider_event(p_inbox_id uuid)
RETURNS TABLE (journal_id uuid, processing_status text, duplicate boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE
  v_tenant_id uuid;
  v_event record;
  v_debit_account_id uuid;
  v_credit_account_id uuid;
  v_lines jsonb;
  v_journal_id uuid;
  v_duplicate boolean;
BEGIN
  v_tenant_id := private.current_tenant_id();
  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'database identity is not mapped to a tenant' USING ERRCODE = '42501';
  END IF;

  SELECT i.inbox_id, i.provider_id, i.provider_account_id, i.provider_event_id,
         i.event_type, i.source_event_id, i.effect_id, i.idempotency_key,
         i.amount_minor, i.currency_code, p.status, p.journal_id
    INTO v_event
    FROM public.provider_inbox AS i
    JOIN public.provider_event_processing AS p
      ON p.tenant_id = i.tenant_id AND p.inbox_id = i.inbox_id
   WHERE i.tenant_id = v_tenant_id AND i.inbox_id = p_inbox_id
   FOR UPDATE OF p;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'provider inbox event is unavailable' USING ERRCODE = 'P0002';
  END IF;

  IF v_event.status = 'processed' THEN
    RETURN QUERY SELECT v_event.journal_id, 'processed'::text, true;
    RETURN;
  END IF;
  IF v_event.status = 'quarantined' THEN
    RETURN QUERY SELECT NULL::uuid, 'quarantined'::text, true;
    RETURN;
  END IF;

  IF v_event.event_type <> 'transaction.settled' THEN
    UPDATE public.provider_event_processing
       SET status = 'quarantined',
           last_error = 'unsupported_event_type',
           attempts = attempts + 1,
           updated_at = clock_timestamp()
     WHERE tenant_id = v_tenant_id AND inbox_id = p_inbox_id;
    RETURN QUERY SELECT NULL::uuid, 'quarantined'::text, false;
    RETURN;
  END IF;

  IF v_event.amount_minor IS NULL OR v_event.amount_minor !~ '^[1-9][0-9]{0,37}$'
     OR v_event.currency_code IS NULL OR v_event.currency_code !~ '^[A-Z]{3}$' THEN
    UPDATE public.provider_event_processing
       SET status = 'quarantined',
           last_error = 'invalid_amount_or_currency',
           attempts = attempts + 1,
           updated_at = clock_timestamp()
     WHERE tenant_id = v_tenant_id AND inbox_id = p_inbox_id;
    RETURN QUERY SELECT NULL::uuid, 'quarantined'::text, false;
    RETURN;
  END IF;

  SELECT m.debit_account_id, m.credit_account_id
    INTO v_debit_account_id, v_credit_account_id
    FROM public.provider_account_map AS m
   WHERE m.tenant_id = v_tenant_id
     AND m.provider_id = v_event.provider_id
     AND m.provider_account_id = v_event.provider_account_id
     AND m.currency_code = v_event.currency_code
     AND m.active = true;

  IF NOT FOUND THEN
    UPDATE public.provider_event_processing
       SET status = 'quarantined',
           last_error = 'provider_account_currency_mapping_missing',
           attempts = attempts + 1,
           updated_at = clock_timestamp()
     WHERE tenant_id = v_tenant_id AND inbox_id = p_inbox_id;
    RETURN QUERY SELECT NULL::uuid, 'quarantined'::text, false;
    RETURN;
  END IF;

  v_lines := jsonb_build_array(
    jsonb_build_object(
      'line_no', 1, 'account_id', v_debit_account_id, 'currency_code', v_event.currency_code,
      'direction', 'debit', 'amount_minor', v_event.amount_minor
    ),
    jsonb_build_object(
      'line_no', 2, 'account_id', v_credit_account_id, 'currency_code', v_event.currency_code,
      'direction', 'credit', 'amount_minor', v_event.amount_minor
    )
  );

  SELECT p.journal_id, p.duplicate
    INTO v_journal_id, v_duplicate
    FROM public.post_journal(
      v_event.idempotency_key,
      v_event.effect_id,
      v_event.source_event_id,
      v_lines
    ) AS p;

  UPDATE public.provider_event_processing
     SET status = 'processed',
         journal_id = v_journal_id,
         last_error = NULL,
         attempts = attempts + 1,
         processed_at = clock_timestamp(),
         updated_at = clock_timestamp()
   WHERE tenant_id = v_tenant_id AND inbox_id = p_inbox_id;

  RETURN QUERY SELECT v_journal_id, 'processed'::text, v_duplicate;
END
$function$;

CREATE OR REPLACE FUNCTION public.reconcile_provider_events()
RETURNS TABLE (
  pending_count integer,
  processed_count integer,
  quarantined_count integer,
  exception_count integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
  SELECT
    count(*) FILTER (WHERE p.status = 'received')::integer,
    count(*) FILTER (WHERE p.status = 'processed')::integer,
    count(*) FILTER (WHERE p.status = 'quarantined')::integer,
    count(*) FILTER (
      WHERE p.status = 'processed'
        AND (
          p.journal_id IS NULL
          OR j.journal_id IS NULL
          OR f.effect_id IS NULL
          OR j.source_event_id IS DISTINCT FROM i.source_event_id
          OR o.event_id IS NULL
          OR lo.event_id IS NULL
          OR lines.currency_code IS DISTINCT FROM i.currency_code
          OR COALESCE(lines.debit_total, 0) <> COALESCE(CASE WHEN i.amount_minor ~ '^[1-9][0-9]{0,37}
          OR COALESCE(lines.currency_count, 0) <> 1
        )
    )::integer
  FROM public.provider_event_processing AS p
  JOIN public.provider_inbox AS i
    ON i.tenant_id = p.tenant_id AND i.inbox_id = p.inbox_id
  LEFT JOIN public.ledger_journals AS j
    ON j.tenant_id = p.tenant_id AND j.journal_id = p.journal_id
  LEFT JOIN public.financial_effects AS f
    ON f.tenant_id = p.tenant_id AND f.effect_id = i.effect_id AND f.journal_id = p.journal_id
  LEFT JOIN public.provider_inbox_outbox AS o
    ON o.tenant_id = p.tenant_id AND o.inbox_id = p.inbox_id AND o.event_type = 'provider.event.accepted'
  LEFT JOIN public.ledger_outbox AS lo
    ON lo.tenant_id = p.tenant_id AND lo.journal_id = p.journal_id AND lo.event_type = 'ledger.journal.posted'
  LEFT JOIN LATERAL (
    SELECT
      sum(amount_minor) FILTER (WHERE direction = 'debit') AS debit_total,
      sum(amount_minor) FILTER (WHERE direction = 'credit') AS credit_total,
      count(DISTINCT currency_code) AS currency_count,
      min(currency_code) AS currency_code
    FROM public.ledger_lines AS ll
    WHERE ll.tenant_id = p.tenant_id AND ll.journal_id = p.journal_id
  ) AS lines ON true
  WHERE p.tenant_id = private.current_tenant_id()
$function$;

ALTER FUNCTION public.receive_provider_event(text,text,text,text,uuid,uuid,text,timestamptz,text,text,jsonb,text,text,timestamptz) OWNER TO provider_executor;
ALTER FUNCTION public.process_provider_event(uuid) OWNER TO provider_executor;
ALTER FUNCTION public.reconcile_provider_events() OWNER TO provider_executor;

REVOKE ALL ON FUNCTION public.receive_provider_event(text,text,text,text,uuid,uuid,text,timestamptz,text,text,jsonb,text,text,timestamptz) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.process_provider_event(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reconcile_provider_events() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.receive_provider_event(text,text,text,text,uuid,uuid,text,timestamptz,text,text,jsonb,text,text,timestamptz)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime;
GRANT EXECUTE ON FUNCTION public.process_provider_event(uuid)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime;
GRANT EXECUTE ON FUNCTION public.reconcile_provider_events()
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime;

INSERT INTO public.provider_account_map (
  tenant_id, provider_id, provider_account_id, currency_code, debit_account_id, credit_account_id
) VALUES
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'synthetic_payments', 'acct-a-001', 'USD',
   '11111111-1111-4111-8111-111111111101', '11111111-1111-4111-8111-111111111102'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'synthetic_payments', 'acct-b-001', 'USD',
   '22222222-2222-4222-8222-222222222201', '22222222-2222-4222-8222-222222222202');
 THEN i.amount_minor::numeric END, -1)
          OR COALESCE(lines.credit_total, 0) <> COALESCE(CASE WHEN i.amount_minor ~ '^[1-9][0-9]{0,37}
          OR COALESCE(lines.currency_count, 0) <> 1
        )
    )::integer
  FROM public.provider_event_processing AS p
  JOIN public.provider_inbox AS i
    ON i.tenant_id = p.tenant_id AND i.inbox_id = p.inbox_id
  LEFT JOIN public.ledger_journals AS j
    ON j.tenant_id = p.tenant_id AND j.journal_id = p.journal_id
  LEFT JOIN public.financial_effects AS f
    ON f.tenant_id = p.tenant_id AND f.effect_id = i.effect_id AND f.journal_id = p.journal_id
  LEFT JOIN public.provider_inbox_outbox AS o
    ON o.tenant_id = p.tenant_id AND o.inbox_id = p.inbox_id AND o.event_type = 'provider.event.accepted'
  LEFT JOIN LATERAL (
    SELECT
      sum(amount_minor) FILTER (WHERE direction = 'debit') AS debit_total,
      sum(amount_minor) FILTER (WHERE direction = 'credit') AS credit_total,
      count(DISTINCT currency_code) AS currency_count,
      min(currency_code) AS currency_code
    FROM public.ledger_lines AS ll
    WHERE ll.tenant_id = p.tenant_id AND ll.journal_id = p.journal_id
  ) AS lines ON true
  WHERE p.tenant_id = private.current_tenant_id()
$function$;

ALTER FUNCTION public.receive_provider_event(text,text,text,text,uuid,uuid,text,timestamptz,text,text,jsonb,text,text,timestamptz) OWNER TO provider_executor;
ALTER FUNCTION public.process_provider_event(uuid) OWNER TO provider_executor;
ALTER FUNCTION public.reconcile_provider_events() OWNER TO provider_executor;

REVOKE ALL ON FUNCTION public.receive_provider_event(text,text,text,text,uuid,uuid,text,timestamptz,text,text,jsonb,text,text,timestamptz) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.process_provider_event(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reconcile_provider_events() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.receive_provider_event(text,text,text,text,uuid,uuid,text,timestamptz,text,text,jsonb,text,text,timestamptz)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime;
GRANT EXECUTE ON FUNCTION public.process_provider_event(uuid)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime;
GRANT EXECUTE ON FUNCTION public.reconcile_provider_events()
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime;

INSERT INTO public.provider_account_map (
  tenant_id, provider_id, provider_account_id, currency_code, debit_account_id, credit_account_id
) VALUES
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'synthetic_payments', 'acct-a-001', 'USD',
   '11111111-1111-4111-8111-111111111101', '11111111-1111-4111-8111-111111111102'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'synthetic_payments', 'acct-b-001', 'USD',
   '22222222-2222-4222-8222-222222222201', '22222222-2222-4222-8222-222222222202');
 THEN i.amount_minor::numeric END, -1)
          OR COALESCE(lines.currency_count, 0) <> 1
        )
    )::integer
  FROM public.provider_event_processing AS p
  JOIN public.provider_inbox AS i
    ON i.tenant_id = p.tenant_id AND i.inbox_id = p.inbox_id
  LEFT JOIN public.ledger_journals AS j
    ON j.tenant_id = p.tenant_id AND j.journal_id = p.journal_id
  LEFT JOIN public.financial_effects AS f
    ON f.tenant_id = p.tenant_id AND f.effect_id = i.effect_id AND f.journal_id = p.journal_id
  LEFT JOIN public.provider_inbox_outbox AS o
    ON o.tenant_id = p.tenant_id AND o.inbox_id = p.inbox_id AND o.event_type = 'provider.event.accepted'
  LEFT JOIN LATERAL (
    SELECT
      sum(amount_minor) FILTER (WHERE direction = 'debit') AS debit_total,
      sum(amount_minor) FILTER (WHERE direction = 'credit') AS credit_total,
      count(DISTINCT currency_code) AS currency_count,
      min(currency_code) AS currency_code
    FROM public.ledger_lines AS ll
    WHERE ll.tenant_id = p.tenant_id AND ll.journal_id = p.journal_id
  ) AS lines ON true
  WHERE p.tenant_id = private.current_tenant_id()
$function$;

ALTER FUNCTION public.receive_provider_event(text,text,text,text,uuid,uuid,text,timestamptz,text,text,jsonb,text,text,timestamptz) OWNER TO provider_executor;
ALTER FUNCTION public.process_provider_event(uuid) OWNER TO provider_executor;
ALTER FUNCTION public.reconcile_provider_events() OWNER TO provider_executor;

REVOKE ALL ON FUNCTION public.receive_provider_event(text,text,text,text,uuid,uuid,text,timestamptz,text,text,jsonb,text,text,timestamptz) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.process_provider_event(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reconcile_provider_events() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.receive_provider_event(text,text,text,text,uuid,uuid,text,timestamptz,text,text,jsonb,text,text,timestamptz)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime;
GRANT EXECUTE ON FUNCTION public.process_provider_event(uuid)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime;
GRANT EXECUTE ON FUNCTION public.reconcile_provider_events()
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime;

INSERT INTO public.provider_account_map (
  tenant_id, provider_id, provider_account_id, currency_code, debit_account_id, credit_account_id
) VALUES
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'synthetic_payments', 'acct-a-001', 'USD',
   '11111111-1111-4111-8111-111111111101', '11111111-1111-4111-8111-111111111102'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'synthetic_payments', 'acct-b-001', 'USD',
   '22222222-2222-4222-8222-222222222201', '22222222-2222-4222-8222-222222222202');
