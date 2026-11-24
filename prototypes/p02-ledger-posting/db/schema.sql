-- Disposable P-02 ledger posting fixture only. Never use in production.
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tenant_a_ledger_runtime') THEN
    CREATE ROLE tenant_a_ledger_runtime LOGIN PASSWORD 'p02-tenant-a-not-for-production'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tenant_b_ledger_runtime') THEN
    CREATE ROLE tenant_b_ledger_runtime LOGIN PASSWORD 'p02-tenant-b-not-for-production'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tenant_identity_owner') THEN
    CREATE ROLE tenant_identity_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ledger_owner') THEN
    CREATE ROLE ledger_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ledger_executor') THEN
    CREATE ROLE ledger_executor NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
END;
$roles$;

ALTER ROLE tenant_a_ledger_runtime LOGIN PASSWORD 'p02-tenant-a-not-for-production'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE tenant_b_ledger_runtime LOGIN PASSWORD 'p02-tenant-b-not-for-production'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE tenant_identity_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE ledger_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE ledger_executor NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;

DROP FUNCTION IF EXISTS public.post_journal(text, uuid, jsonb);
DROP FUNCTION IF EXISTS public.post_journal(text, uuid, uuid, jsonb);
DROP TABLE IF EXISTS public.ledger_outbox;
DROP TABLE IF EXISTS public.ledger_lines;
DROP TABLE IF EXISTS public.ledger_journals;
DROP TABLE IF EXISTS public.posting_requests;
DROP TABLE IF EXISTS public.financial_effects;
DROP TABLE IF EXISTS public.ledger_accounts;
DROP SCHEMA IF EXISTS private CASCADE;

CREATE SCHEMA private AUTHORIZATION tenant_identity_owner;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO ledger_executor;

CREATE TABLE private.tenant_role_map (
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
GRANT EXECUTE ON FUNCTION private.current_tenant_id() TO ledger_executor;

CREATE TABLE public.ledger_accounts (
  tenant_id uuid NOT NULL,
  account_id uuid NOT NULL,
  account_code text NOT NULL,
  currency_code text NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
  account_type text NOT NULL CHECK (account_type IN ('asset', 'liability', 'equity', 'income', 'expense', 'clearing')),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, account_id),
  UNIQUE (tenant_id, account_code),
  UNIQUE (tenant_id, account_id, currency_code),
  CHECK (length(account_code) BETWEEN 1 AND 64)
);

CREATE TABLE public.financial_effects (
  tenant_id uuid NOT NULL,
  effect_id uuid NOT NULL,
  request_fingerprint jsonb NOT NULL,
  journal_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, effect_id),
  UNIQUE (tenant_id, journal_id),
  UNIQUE (tenant_id, effect_id, journal_id)
);

CREATE TABLE public.posting_requests (
  tenant_id uuid NOT NULL,
  idempotency_key text NOT NULL,
  effect_id uuid NOT NULL,
  journal_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, idempotency_key),
  FOREIGN KEY (tenant_id, effect_id, journal_id)
    REFERENCES public.financial_effects (tenant_id, effect_id, journal_id),
  CHECK (idempotency_key ~ '^[A-Za-z0-9._:-]{1,128}

CREATE TABLE public.ledger_lines (
  tenant_id uuid NOT NULL,
  journal_id uuid NOT NULL,
  line_no integer NOT NULL CHECK (line_no BETWEEN 1 AND 100),
  account_id uuid NOT NULL,
  currency_code text NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
  direction text NOT NULL CHECK (direction IN ('debit', 'credit')),
  amount_minor numeric(38,0) NOT NULL CHECK (amount_minor > 0),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, journal_id, line_no),
  FOREIGN KEY (tenant_id, journal_id)
    REFERENCES public.ledger_journals (tenant_id, journal_id),
  FOREIGN KEY (tenant_id, account_id, currency_code)
    REFERENCES public.ledger_accounts (tenant_id, account_id, currency_code)
);

CREATE TABLE public.ledger_outbox (
  tenant_id uuid NOT NULL,
  event_id uuid NOT NULL,
  journal_id uuid NOT NULL,
  event_type text NOT NULL CHECK (event_type = 'ledger.journal.posted'),
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, event_id),
  UNIQUE (tenant_id, journal_id, event_type),
  FOREIGN KEY (tenant_id, journal_id)
    REFERENCES public.ledger_journals (tenant_id, journal_id)
);

CREATE INDEX ledger_outbox_tenant_created_idx
  ON public.ledger_outbox (tenant_id, created_at);

REVOKE CREATE ON SCHEMA public FROM PUBLIC;

GRANT USAGE, CREATE ON SCHEMA public TO ledger_owner, ledger_executor;

ALTER TABLE public.ledger_accounts OWNER TO ledger_owner;
ALTER TABLE public.posting_requests OWNER TO ledger_owner;
ALTER TABLE public.ledger_journals OWNER TO ledger_owner;
ALTER TABLE public.ledger_lines OWNER TO ledger_owner;
ALTER TABLE public.ledger_outbox OWNER TO ledger_owner;

CREATE OR REPLACE FUNCTION private.reject_immutable_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
BEGIN
  RAISE EXCEPTION 'posted ledger records are immutable'
    USING ERRCODE = '55000';
END;
$function$;
REVOKE ALL ON FUNCTION private.reject_immutable_mutation() FROM PUBLIC;

CREATE TRIGGER financial_effects_immutable
  BEFORE UPDATE OR DELETE ON public.financial_effects
  FOR EACH ROW EXECUTE FUNCTION private.reject_immutable_mutation();
CREATE TRIGGER posting_requests_immutable
  BEFORE UPDATE OR DELETE ON public.posting_requests
  FOR EACH ROW EXECUTE FUNCTION private.reject_immutable_mutation();
CREATE TRIGGER ledger_journals_immutable
  BEFORE UPDATE OR DELETE ON public.ledger_journals
  FOR EACH ROW EXECUTE FUNCTION private.reject_immutable_mutation();
CREATE TRIGGER ledger_lines_immutable
  BEFORE UPDATE OR DELETE ON public.ledger_lines
  FOR EACH ROW EXECUTE FUNCTION private.reject_immutable_mutation();
CREATE TRIGGER ledger_outbox_immutable
  BEFORE UPDATE OR DELETE ON public.ledger_outbox
  FOR EACH ROW EXECUTE FUNCTION private.reject_immutable_mutation();

ALTER TABLE public.ledger_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_accounts FORCE ROW LEVEL SECURITY;
ALTER TABLE public.financial_effects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_effects FORCE ROW LEVEL SECURITY;
ALTER TABLE public.posting_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posting_requests FORCE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_journals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_journals FORCE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_outbox FORCE ROW LEVEL SECURITY;

CREATE POLICY ledger_accounts_executor_tenant
  ON public.ledger_accounts FOR SELECT TO ledger_executor
  USING (tenant_id = private.current_tenant_id());
CREATE POLICY financial_effects_executor_tenant
  ON public.financial_effects FOR ALL TO ledger_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());
CREATE POLICY posting_requests_executor_tenant
  ON public.posting_requests FOR ALL TO ledger_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());
CREATE POLICY ledger_journals_executor_tenant
  ON public.ledger_journals FOR ALL TO ledger_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());
CREATE POLICY ledger_lines_executor_tenant
  ON public.ledger_lines FOR ALL TO ledger_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());
CREATE POLICY ledger_outbox_executor_tenant
  ON public.ledger_outbox FOR ALL TO ledger_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());

GRANT USAGE ON SCHEMA public TO ledger_executor, tenant_a_ledger_runtime, tenant_b_ledger_runtime;
GRANT SELECT ON public.ledger_accounts TO ledger_executor;
GRANT SELECT, INSERT ON public.financial_effects TO ledger_executor;
GRANT SELECT, INSERT ON public.posting_requests TO ledger_executor;
GRANT SELECT, INSERT ON public.ledger_journals TO ledger_executor;
GRANT SELECT, INSERT ON public.ledger_lines TO ledger_executor;
GRANT SELECT, INSERT ON public.ledger_outbox TO ledger_executor;

CREATE OR REPLACE FUNCTION public.post_journal(
  p_idempotency_key text,
  p_effect_id uuid,
  p_source_event_id uuid,
  p_lines jsonb
)
RETURNS TABLE (journal_id uuid, duplicate boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE
  v_tenant_id uuid;
  v_line_count integer;
  v_normalized_lines jsonb;
  v_fingerprint jsonb;
  v_new_journal_id uuid;
  v_existing_fingerprint jsonb;
  v_existing_journal_id uuid;
  v_existing_effect_id uuid;
  v_inserted integer;
  v_effect_inserted integer;
BEGIN
  v_tenant_id := private.current_tenant_id();
  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'database identity is not mapped to a tenant' USING ERRCODE = '42501';
  END IF;

  IF p_idempotency_key IS NULL
     OR p_idempotency_key !~ '^[A-Za-z0-9._:-]{1,128}$'
     OR p_effect_id IS NULL
     OR p_source_event_id IS NULL
     OR p_lines IS NULL
     OR jsonb_typeof(p_lines) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'invalid journal request' USING ERRCODE = '22023';
  END IF;

  v_line_count := jsonb_array_length(p_lines);
  IF v_line_count < 2 OR v_line_count > 100 THEN
    RAISE EXCEPTION 'journal must contain between 2 and 100 lines' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_lines) AS item(value)
    WHERE jsonb_typeof(value) IS DISTINCT FROM 'object'
  ) THEN
    RAISE EXCEPTION 'journal lines must be objects' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_lines) AS item(value)
    WHERE value->>'line_no' IS NULL OR value->>'line_no' !~ '^[1-9][0-9]{0,2}$'
  ) THEN
    RAISE EXCEPTION 'journal line numbers must be positive integers' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_lines) AS item(value)
    WHERE (value - ARRAY['line_no','account_id','currency_code','direction','amount_minor']::text[]) <> '{}'::jsonb
       OR NOT (value ?& ARRAY['line_no','account_id','currency_code','direction','amount_minor']::text[])
  ) THEN
    RAISE EXCEPTION 'journal line fields are invalid' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM jsonb_to_recordset(p_lines) AS x(
        line_no integer,
        account_id text,
        currency_code text,
        direction text,
        amount_minor text
      )
     WHERE line_no IS NULL OR line_no < 1 OR line_no > 100
        OR account_id IS NULL OR account_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
        OR currency_code IS NULL OR char_length(currency_code) <> 3 OR currency_code !~ '^[A-Z]{3}'
        OR direction IS NULL OR direction NOT IN ('debit','credit')
        OR amount_minor IS NULL OR amount_minor !~ '^[1-9][0-9]{0,37}$'
  ) THEN
    RAISE EXCEPTION 'journal line values are invalid' USING ERRCODE = '22023';
  END IF;

  IF (
    SELECT count(DISTINCT line_no)
      FROM jsonb_to_recordset(p_lines) AS x(line_no integer)
  ) <> v_line_count THEN
    RAISE EXCEPTION 'journal line numbers must be unique' USING ERRCODE = '22023';
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'line_no', line_no,
      'account_id', lower(account_id),
      'currency_code', currency_code,
      'direction', direction,
      'amount_minor', amount_minor
    ) ORDER BY line_no
  )
    INTO v_normalized_lines
    FROM jsonb_to_recordset(p_lines) AS x(
      line_no integer,
      account_id text,
      currency_code text,
      direction text,
      amount_minor text
    );

  IF EXISTS (
    SELECT 1
      FROM jsonb_to_recordset(v_normalized_lines) AS x(
        currency_code text,
        direction text,
        amount_minor text
      )
     GROUP BY currency_code
    HAVING sum(CASE WHEN direction = 'debit' THEN amount_minor::numeric(38,0) ELSE 0 END)
        <> sum(CASE WHEN direction = 'credit' THEN amount_minor::numeric(38,0) ELSE 0 END)
  ) THEN
    RAISE EXCEPTION 'journal is not balanced per currency' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM jsonb_to_recordset(v_normalized_lines) AS x(
        account_id text,
        currency_code text
      )
      LEFT JOIN public.ledger_accounts AS a
        ON a.tenant_id = v_tenant_id
       AND a.account_id = x.account_id::uuid
       AND a.currency_code = x.currency_code
       AND a.active = true
     WHERE a.account_id IS NULL
  ) THEN
    RAISE EXCEPTION 'ledger account or currency is unavailable' USING ERRCODE = '22023';
  END IF;

  v_fingerprint := jsonb_build_object(
    'effect_id', p_effect_id,
    'source_event_id', p_source_event_id,
    'lines', v_normalized_lines
  );

  -- A request key is a transport retry identity. Resolve it before looking up the business effect.
  SELECT r.effect_id, r.journal_id, f.request_fingerprint
    INTO v_existing_effect_id, v_existing_journal_id, v_existing_fingerprint
    FROM public.posting_requests AS r
    JOIN public.financial_effects AS f
      ON f.tenant_id = r.tenant_id
     AND f.effect_id = r.effect_id
     AND f.journal_id = r.journal_id
   WHERE r.tenant_id = v_tenant_id
     AND r.idempotency_key = p_idempotency_key
;

  IF FOUND THEN
    IF v_existing_effect_id IS DISTINCT FROM p_effect_id
       OR v_existing_fingerprint IS DISTINCT FROM v_fingerprint THEN
      RAISE EXCEPTION 'idempotency key was reused with different request content'
        USING ERRCODE = '22023';
    END IF;
    RETURN QUERY SELECT v_existing_journal_id, true;
    RETURN;
  END IF;

  v_new_journal_id := gen_random_uuid();

  -- The effect identity is unique independently of any transport/request key.
  INSERT INTO public.financial_effects (
    tenant_id, effect_id, request_fingerprint, journal_id
  ) VALUES (
    v_tenant_id, p_effect_id, v_fingerprint, v_new_journal_id
  )
  ON CONFLICT (tenant_id, effect_id) DO NOTHING;

  GET DIAGNOSTICS v_effect_inserted = ROW_COUNT;
  IF v_effect_inserted = 0 THEN
    SELECT request_fingerprint, journal_id
      INTO v_existing_fingerprint, v_existing_journal_id
      FROM public.financial_effects
     WHERE tenant_id = v_tenant_id
       AND effect_id = p_effect_id
;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'financial effect state is unavailable' USING ERRCODE = '40001';
    END IF;
    IF v_existing_fingerprint IS DISTINCT FROM v_fingerprint THEN
      RAISE EXCEPTION 'financial effect identity was reused with different economic content'
        USING ERRCODE = '22023';
    END IF;
    v_new_journal_id := v_existing_journal_id;
  ELSE
    INSERT INTO public.ledger_journals (
      tenant_id, journal_id, source_event_id, status
    ) VALUES (
      v_tenant_id, v_new_journal_id, p_source_event_id, 'posted'
    );

    INSERT INTO public.ledger_lines (
      tenant_id, journal_id, line_no, account_id, currency_code, direction, amount_minor
    )
    SELECT
      v_tenant_id,
      v_new_journal_id,
      line_no,
      account_id::uuid,
      currency_code,
      direction,
      amount_minor::numeric(38,0)
    FROM jsonb_to_recordset(v_normalized_lines) AS x(
      line_no integer,
      account_id text,
      currency_code text,
      direction text,
      amount_minor text
    );

    INSERT INTO public.ledger_outbox (
      tenant_id, event_id, journal_id, event_type, payload
    ) VALUES (
      v_tenant_id,
      gen_random_uuid(),
      v_new_journal_id,
      'ledger.journal.posted',
      jsonb_build_object(
        'journal_id', v_new_journal_id,
        'effect_id', p_effect_id,
        'source_event_id', p_source_event_id
      )
    );
  END IF;

  -- Persist every request token, including aliases that redeliver an existing financial effect.
  INSERT INTO public.posting_requests (
    tenant_id, idempotency_key, effect_id, journal_id
  ) VALUES (
    v_tenant_id, p_idempotency_key, p_effect_id, v_new_journal_id
  )
  ON CONFLICT DO NOTHING;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted = 0 THEN
    SELECT r.effect_id, r.journal_id, f.request_fingerprint
      INTO v_existing_effect_id, v_existing_journal_id, v_existing_fingerprint
      FROM public.posting_requests AS r
      JOIN public.financial_effects AS f
        ON f.tenant_id = r.tenant_id
       AND f.effect_id = r.effect_id
       AND f.journal_id = r.journal_id
     WHERE r.tenant_id = v_tenant_id
       AND r.idempotency_key = p_idempotency_key
  ;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'idempotency state is unavailable' USING ERRCODE = '40001';
    END IF;
    IF v_existing_effect_id IS DISTINCT FROM p_effect_id
       OR v_existing_fingerprint IS DISTINCT FROM v_fingerprint THEN
      RAISE EXCEPTION 'idempotency key was reused with different request content'
        USING ERRCODE = '22023';
    END IF;
    RETURN QUERY SELECT v_existing_journal_id, true;
    RETURN;
  END IF;

  RETURN QUERY SELECT v_new_journal_id, (v_effect_inserted = 0);
END
$function$;

ALTER FUNCTION public.post_journal(text, uuid, uuid, jsonb) OWNER TO ledger_executor;
REVOKE ALL ON FUNCTION public.post_journal(text, uuid, uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.post_journal(text, uuid, uuid, jsonb)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime;
REVOKE CREATE ON SCHEMA public FROM ledger_owner, ledger_executor;

INSERT INTO private.tenant_role_map (database_role, tenant_id) VALUES
  ('tenant_a_ledger_runtime', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  ('tenant_b_ledger_runtime', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');

INSERT INTO public.ledger_accounts (tenant_id, account_id, account_code, currency_code, account_type) VALUES
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111101', 'A-USD-CASH', 'USD', 'asset'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111102', 'A-USD-CLEARING', 'USD', 'clearing'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111103', 'A-JPY-CASH', 'JPY', 'asset'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111104', 'A-JPY-CLEARING', 'JPY', 'clearing'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222201', 'B-USD-CASH', 'USD', 'asset'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222202', 'B-USD-CLEARING', 'USD', 'clearing');
)
);

CREATE TABLE public.ledger_journals (
  tenant_id uuid NOT NULL,
  journal_id uuid NOT NULL,
  source_event_id uuid NOT NULL,
  status text NOT NULL CHECK (status = 'posted'),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, journal_id),
  FOREIGN KEY (tenant_id, journal_id)
    REFERENCES public.financial_effects (tenant_id, journal_id)
);

CREATE TABLE public.ledger_lines (
  tenant_id uuid NOT NULL,
  journal_id uuid NOT NULL,
  line_no integer NOT NULL CHECK (line_no BETWEEN 1 AND 100),
  account_id uuid NOT NULL,
  currency_code text NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
  direction text NOT NULL CHECK (direction IN ('debit', 'credit')),
  amount_minor numeric(38,0) NOT NULL CHECK (amount_minor > 0),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, journal_id, line_no),
  FOREIGN KEY (tenant_id, journal_id)
    REFERENCES public.ledger_journals (tenant_id, journal_id),
  FOREIGN KEY (tenant_id, account_id, currency_code)
    REFERENCES public.ledger_accounts (tenant_id, account_id, currency_code)
);

CREATE TABLE public.ledger_outbox (
  tenant_id uuid NOT NULL,
  event_id uuid NOT NULL,
  journal_id uuid NOT NULL,
  event_type text NOT NULL CHECK (event_type = 'ledger.journal.posted'),
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, event_id),
  UNIQUE (tenant_id, journal_id, event_type),
  FOREIGN KEY (tenant_id, journal_id)
    REFERENCES public.ledger_journals (tenant_id, journal_id)
);

CREATE INDEX ledger_outbox_tenant_created_idx
  ON public.ledger_outbox (tenant_id, created_at);

REVOKE CREATE ON SCHEMA public FROM PUBLIC;

GRANT USAGE, CREATE ON SCHEMA public TO ledger_owner, ledger_executor;

ALTER TABLE public.ledger_accounts OWNER TO ledger_owner;
ALTER TABLE public.posting_requests OWNER TO ledger_owner;
ALTER TABLE public.ledger_journals OWNER TO ledger_owner;
ALTER TABLE public.ledger_lines OWNER TO ledger_owner;
ALTER TABLE public.ledger_outbox OWNER TO ledger_owner;

CREATE OR REPLACE FUNCTION private.reject_immutable_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
BEGIN
  RAISE EXCEPTION 'posted ledger records are immutable'
    USING ERRCODE = '55000';
END;
$function$;
REVOKE ALL ON FUNCTION private.reject_immutable_mutation() FROM PUBLIC;

CREATE TRIGGER posting_requests_immutable
  BEFORE UPDATE OR DELETE ON public.posting_requests
  FOR EACH ROW EXECUTE FUNCTION private.reject_immutable_mutation();
CREATE TRIGGER ledger_journals_immutable
  BEFORE UPDATE OR DELETE ON public.ledger_journals
  FOR EACH ROW EXECUTE FUNCTION private.reject_immutable_mutation();
CREATE TRIGGER ledger_lines_immutable
  BEFORE UPDATE OR DELETE ON public.ledger_lines
  FOR EACH ROW EXECUTE FUNCTION private.reject_immutable_mutation();
CREATE TRIGGER ledger_outbox_immutable
  BEFORE UPDATE OR DELETE ON public.ledger_outbox
  FOR EACH ROW EXECUTE FUNCTION private.reject_immutable_mutation();

ALTER TABLE public.ledger_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_accounts FORCE ROW LEVEL SECURITY;
ALTER TABLE public.posting_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posting_requests FORCE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_journals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_journals FORCE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_outbox FORCE ROW LEVEL SECURITY;

CREATE POLICY ledger_accounts_executor_tenant
  ON public.ledger_accounts FOR SELECT TO ledger_executor
  USING (tenant_id = private.current_tenant_id());
CREATE POLICY posting_requests_executor_tenant
  ON public.posting_requests FOR ALL TO ledger_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());
CREATE POLICY ledger_journals_executor_tenant
  ON public.ledger_journals FOR ALL TO ledger_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());
CREATE POLICY ledger_lines_executor_tenant
  ON public.ledger_lines FOR ALL TO ledger_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());
CREATE POLICY ledger_outbox_executor_tenant
  ON public.ledger_outbox FOR ALL TO ledger_executor
  USING (tenant_id = private.current_tenant_id())
  WITH CHECK (tenant_id = private.current_tenant_id());

GRANT USAGE ON SCHEMA public TO ledger_executor, tenant_a_ledger_runtime, tenant_b_ledger_runtime;
GRANT SELECT ON public.ledger_accounts TO ledger_executor;
GRANT SELECT, INSERT ON public.posting_requests TO ledger_executor;
-- Required for SELECT ... FOR UPDATE idempotency serialization; the immutability trigger still rejects UPDATE.
GRANT UPDATE (journal_id) ON public.posting_requests TO ledger_executor;
GRANT SELECT, INSERT ON public.ledger_journals TO ledger_executor;
GRANT SELECT, INSERT ON public.ledger_lines TO ledger_executor;
GRANT SELECT, INSERT ON public.ledger_outbox TO ledger_executor;

CREATE OR REPLACE FUNCTION public.post_journal(
  p_idempotency_key text,
  p_effect_id uuid,
  p_source_event_id uuid,
  p_lines jsonb
)
RETURNS TABLE (journal_id uuid, duplicate boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE
  v_tenant_id uuid;
  v_line_count integer;
  v_normalized_lines jsonb;
  v_fingerprint jsonb;
  v_new_journal_id uuid;
  v_existing_fingerprint jsonb;
  v_existing_journal_id uuid;
  v_inserted integer;
  v_conflict_count integer;
BEGIN
  v_tenant_id := private.current_tenant_id();
  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'database identity is not mapped to a tenant' USING ERRCODE = '42501';
  END IF;

  IF p_idempotency_key IS NULL
     OR p_idempotency_key !~ '^[A-Za-z0-9._:-]{1,128}$'
     OR p_effect_id IS NULL
     OR p_source_event_id IS NULL
     OR p_lines IS NULL
     OR jsonb_typeof(p_lines) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'invalid journal request' USING ERRCODE = '22023';
  END IF;

  v_line_count := jsonb_array_length(p_lines);
  IF v_line_count < 2 OR v_line_count > 100 THEN
    RAISE EXCEPTION 'journal must contain between 2 and 100 lines' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_lines) AS item(value)
    WHERE jsonb_typeof(value) IS DISTINCT FROM 'object'
  ) THEN
    RAISE EXCEPTION 'journal lines must be objects' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_lines) AS item(value)
    WHERE value->>'line_no' IS NULL OR value->>'line_no' !~ '^[1-9][0-9]{0,2}$'
  ) THEN
    RAISE EXCEPTION 'journal line numbers must be positive integers' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_lines) AS item(value)
    WHERE (value - ARRAY['line_no','account_id','currency_code','direction','amount_minor']::text[]) <> '{}'::jsonb
       OR NOT (value ?& ARRAY['line_no','account_id','currency_code','direction','amount_minor']::text[])
  ) THEN
    RAISE EXCEPTION 'journal line fields are invalid' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM jsonb_to_recordset(p_lines) AS x(
        line_no integer,
        account_id text,
        currency_code text,
        direction text,
        amount_minor text
      )
     WHERE line_no IS NULL OR line_no < 1 OR line_no > 100
        OR account_id IS NULL OR account_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
        OR currency_code IS NULL OR char_length(currency_code) <> 3 OR currency_code !~ '^[A-Z]{3}'
        OR direction IS NULL OR direction NOT IN ('debit','credit')
        OR amount_minor IS NULL OR amount_minor !~ '^[1-9][0-9]{0,37}$'
  ) THEN
    RAISE EXCEPTION 'journal line values are invalid' USING ERRCODE = '22023';
  END IF;

  IF (
    SELECT count(DISTINCT line_no)
      FROM jsonb_to_recordset(p_lines) AS x(line_no integer)
  ) <> v_line_count THEN
    RAISE EXCEPTION 'journal line numbers must be unique' USING ERRCODE = '22023';
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'line_no', line_no,
      'account_id', lower(account_id),
      'currency_code', currency_code,
      'direction', direction,
      'amount_minor', amount_minor
    ) ORDER BY line_no
  )
    INTO v_normalized_lines
    FROM jsonb_to_recordset(p_lines) AS x(
      line_no integer,
      account_id text,
      currency_code text,
      direction text,
      amount_minor text
    );

  IF EXISTS (
    SELECT 1
      FROM jsonb_to_recordset(v_normalized_lines) AS x(
        currency_code text,
        direction text,
        amount_minor text
      )
     GROUP BY currency_code
    HAVING sum(CASE WHEN direction = 'debit' THEN amount_minor::numeric(38,0) ELSE 0 END)
        <> sum(CASE WHEN direction = 'credit' THEN amount_minor::numeric(38,0) ELSE 0 END)
  ) THEN
    RAISE EXCEPTION 'journal is not balanced per currency' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM jsonb_to_recordset(v_normalized_lines) AS x(
        account_id text,
        currency_code text
      )
      LEFT JOIN public.ledger_accounts AS a
        ON a.tenant_id = v_tenant_id
       AND a.account_id = x.account_id::uuid
       AND a.currency_code = x.currency_code
       AND a.active = true
     WHERE a.account_id IS NULL
  ) THEN
    RAISE EXCEPTION 'ledger account or currency is unavailable' USING ERRCODE = '22023';
  END IF;

  v_fingerprint := jsonb_build_object(
    'effect_id', p_effect_id,
    'source_event_id', p_source_event_id,
    'lines', v_normalized_lines
  );
  v_new_journal_id := gen_random_uuid();

  INSERT INTO public.posting_requests (
    tenant_id, idempotency_key, effect_id, request_fingerprint, journal_id
  ) VALUES (
    v_tenant_id, p_idempotency_key, p_effect_id, v_fingerprint, v_new_journal_id
  )
  ON CONFLICT DO NOTHING;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted = 0 THEN
    SELECT count(*) INTO v_conflict_count
      FROM public.posting_requests
     WHERE tenant_id = v_tenant_id
       AND (idempotency_key = p_idempotency_key OR effect_id = p_effect_id);

    IF v_conflict_count > 1 THEN
      RAISE EXCEPTION 'idempotency key and financial effect identify different postings'
        USING ERRCODE = '22023';
    END IF;

    SELECT request_fingerprint, posting_requests.journal_id
      INTO v_existing_fingerprint, v_existing_journal_id
      FROM public.posting_requests
     WHERE tenant_id = v_tenant_id
       AND (idempotency_key = p_idempotency_key OR effect_id = p_effect_id)
;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'idempotency state is unavailable' USING ERRCODE = '40001';
    END IF;
    IF v_existing_fingerprint IS DISTINCT FROM v_fingerprint THEN
      RAISE EXCEPTION 'idempotency key was reused with different request content'
        USING ERRCODE = '22023';
    END IF;
    RETURN QUERY SELECT v_existing_journal_id, true;
    RETURN;
  END IF;

  INSERT INTO public.ledger_journals (
    tenant_id, journal_id, source_event_id, status
  ) VALUES (
    v_tenant_id, v_new_journal_id, p_source_event_id, 'posted'
  );

  INSERT INTO public.ledger_lines (
    tenant_id, journal_id, line_no, account_id, currency_code, direction, amount_minor
  )
  SELECT
    v_tenant_id,
    v_new_journal_id,
    line_no,
    account_id::uuid,
    currency_code,
    direction,
    amount_minor::numeric(38,0)
  FROM jsonb_to_recordset(v_normalized_lines) AS x(
    line_no integer,
    account_id text,
    currency_code text,
    direction text,
    amount_minor text
  );

  INSERT INTO public.ledger_outbox (
    tenant_id, event_id, journal_id, event_type, payload
  ) VALUES (
    v_tenant_id,
    gen_random_uuid(),
    v_new_journal_id,
    'ledger.journal.posted',
    jsonb_build_object(
      'journal_id', v_new_journal_id,
      'effect_id', p_effect_id,
      'source_event_id', p_source_event_id
    )
  );

  RETURN QUERY SELECT v_new_journal_id, false;
END
$function$;

ALTER FUNCTION public.post_journal(text, uuid, uuid, jsonb) OWNER TO ledger_executor;
REVOKE ALL ON FUNCTION public.post_journal(text, uuid, uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.post_journal(text, uuid, uuid, jsonb)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime;
REVOKE CREATE ON SCHEMA public FROM ledger_owner, ledger_executor;

INSERT INTO private.tenant_role_map (database_role, tenant_id) VALUES
  ('tenant_a_ledger_runtime', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  ('tenant_b_ledger_runtime', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');

INSERT INTO public.ledger_accounts (tenant_id, account_id, account_code, currency_code, account_type) VALUES
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111101', 'A-USD-CASH', 'USD', 'asset'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111102', 'A-USD-CLEARING', 'USD', 'clearing'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111103', 'A-JPY-CASH', 'JPY', 'asset'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111104', 'A-JPY-CLEARING', 'JPY', 'clearing'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222201', 'B-USD-CASH', 'USD', 'asset'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222202', 'B-USD-CLEARING', 'USD', 'clearing');
