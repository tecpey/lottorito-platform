-- Disposable P-02 schema. Never run against shared, staging or production databases.
DROP VIEW IF EXISTS public.ledger_reconciliation;
DROP VIEW IF EXISTS public.ledger_account_balances;
DROP TABLE IF EXISTS public.outbox_events CASCADE;
DROP TABLE IF EXISTS public.economic_effects CASCADE;
DROP TABLE IF EXISTS public.ledger_entries CASCADE;
DROP TABLE IF EXISTS public.journal_transactions CASCADE;
DROP TABLE IF EXISTS public.source_events CASCADE;
DROP TABLE IF EXISTS public.ledger_accounts CASCADE;
DROP TABLE IF EXISTS public.currency_definitions CASCADE;
DROP FUNCTION IF EXISTS public.guard_ledger_entry() CASCADE;
DROP FUNCTION IF EXISTS public.guard_journal_transaction() CASCADE;
DROP FUNCTION IF EXISTS public.guard_source_event() CASCADE;
DROP FUNCTION IF EXISTS public.guard_economic_effect() CASCADE;

DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ledger_runtime') THEN
    CREATE ROLE ledger_runtime LOGIN PASSWORD 'p02-runtime-not-for-production'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ledger_owner') THEN
    CREATE ROLE ledger_owner NOLOGIN
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
END;
$roles$;
ALTER ROLE ledger_runtime LOGIN PASSWORD 'p02-runtime-not-for-production'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE ledger_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;

CREATE TABLE public.currency_definitions (
  currency_code text PRIMARY KEY,
  decimal_scale smallint NOT NULL CHECK (decimal_scale BETWEEN 0 AND 18),
  asset_kind text NOT NULL CHECK (asset_kind IN ('fiat', 'crypto', 'token', 'other'))
);
ALTER TABLE public.currency_definitions OWNER TO ledger_owner;

CREATE TABLE public.ledger_accounts (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  account_id uuid NOT NULL,
  account_code text NOT NULL,
  currency_code text NOT NULL REFERENCES public.currency_definitions(currency_code),
  normal_side text NOT NULL CHECK (normal_side IN ('debit', 'credit')),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, account_id),
  UNIQUE (tenant_id, product_id, account_id, currency_code),
  UNIQUE (tenant_id, product_id, account_code, currency_code)
);
ALTER TABLE public.ledger_accounts OWNER TO ledger_owner;

-- This table represents an upstream, independently computed expected effect.
-- Amounts are synthetic inputs; no commission/NGR formula is defined here.
CREATE TABLE public.source_events (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  source_event_id text NOT NULL,
  effect_key text NOT NULL,
  currency_code text NOT NULL REFERENCES public.currency_definitions(currency_code),
  expected_amount numeric(38,18) NOT NULL CHECK (expected_amount > 0),
  received_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, source_event_id, effect_key)
);
ALTER TABLE public.source_events OWNER TO ledger_owner;

CREATE TABLE public.journal_transactions (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  journal_id uuid NOT NULL,
  source_event_id text NOT NULL,
  effect_type text NOT NULL,
  effect_key text NOT NULL,
  idempotency_key text NOT NULL,
  request_fingerprint text NOT NULL,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'posted')),
  reversal_of_journal_id uuid,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  posted_at timestamptz,
  PRIMARY KEY (tenant_id, product_id, journal_id),
  FOREIGN KEY (tenant_id, product_id, reversal_of_journal_id)
    REFERENCES public.journal_transactions (tenant_id, product_id, journal_id),
  UNIQUE (tenant_id, product_id, reversal_of_journal_id)
);
ALTER TABLE public.journal_transactions OWNER TO ledger_owner;

CREATE TABLE public.economic_effects (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  effect_type text NOT NULL,
  source_event_id text NOT NULL,
  effect_key text NOT NULL,
  idempotency_key text NOT NULL,
  request_fingerprint text NOT NULL,
  journal_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, effect_type, source_event_id, effect_key),
  UNIQUE (tenant_id, product_id, idempotency_key),
  FOREIGN KEY (tenant_id, product_id, journal_id)
    REFERENCES public.journal_transactions (tenant_id, product_id, journal_id)
);
ALTER TABLE public.economic_effects OWNER TO ledger_owner;

CREATE TABLE public.ledger_entries (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  journal_id uuid NOT NULL,
  line_no integer NOT NULL CHECK (line_no > 0),
  account_id uuid NOT NULL,
  currency_code text NOT NULL REFERENCES public.currency_definitions(currency_code),
  side text NOT NULL CHECK (side IN ('debit', 'credit')),
  amount numeric(38,18) NOT NULL CHECK (amount > 0),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, journal_id, line_no),
  FOREIGN KEY (tenant_id, product_id, journal_id)
    REFERENCES public.journal_transactions (tenant_id, product_id, journal_id),
  FOREIGN KEY (tenant_id, product_id, account_id, currency_code)
    REFERENCES public.ledger_accounts (tenant_id, product_id, account_id, currency_code)
);
ALTER TABLE public.ledger_entries OWNER TO ledger_owner;

CREATE TABLE public.outbox_events (
  tenant_id uuid NOT NULL,
  product_id uuid NOT NULL,
  event_id uuid NOT NULL,
  journal_id uuid NOT NULL,
  event_type text NOT NULL,
  payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  published_at timestamptz,
  PRIMARY KEY (tenant_id, product_id, event_id),
  UNIQUE (tenant_id, product_id, journal_id),
  FOREIGN KEY (tenant_id, product_id, journal_id)
    REFERENCES public.journal_transactions (tenant_id, product_id, journal_id)
);
ALTER TABLE public.outbox_events OWNER TO ledger_owner;

CREATE INDEX ledger_entries_account_idx
  ON public.ledger_entries (tenant_id, product_id, account_id, currency_code, journal_id);
CREATE INDEX journal_transactions_source_idx
  ON public.journal_transactions (tenant_id, product_id, source_event_id, effect_key, status);

CREATE OR REPLACE FUNCTION public.guard_ledger_entry()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  parent_status text;
  allowed_scale smallint;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT status INTO parent_status
      FROM public.journal_transactions
     WHERE tenant_id = NEW.tenant_id
       AND product_id = NEW.product_id
       AND journal_id = NEW.journal_id;
    IF parent_status IS DISTINCT FROM 'draft' THEN
      RAISE EXCEPTION 'ledger entries may only be added to a draft journal'
        USING ERRCODE = '55000';
    END IF;

    SELECT decimal_scale INTO allowed_scale
      FROM public.currency_definitions
     WHERE currency_code = NEW.currency_code;
    IF allowed_scale IS NULL OR NEW.amount <> trunc(NEW.amount, allowed_scale) THEN
      RAISE EXCEPTION 'amount exceeds the currency decimal scale'
        USING ERRCODE = '22003';
    END IF;
    RETURN NEW;
  END IF;

  SELECT status INTO parent_status
    FROM public.journal_transactions
   WHERE tenant_id = OLD.tenant_id
     AND product_id = OLD.product_id
     AND journal_id = OLD.journal_id;
  IF parent_status = 'posted' THEN
    RAISE EXCEPTION 'posted ledger entries are immutable'
      USING ERRCODE = '55000';
  END IF;

  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER ledger_entry_guard
BEFORE INSERT OR UPDATE OR DELETE ON public.ledger_entries
FOR EACH ROW EXECUTE FUNCTION public.guard_ledger_entry();

CREATE OR REPLACE FUNCTION public.guard_journal_transaction()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  line_count bigint;
  unbalanced boolean;
  original_status text;
  reversal_mismatch boolean;
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status <> 'draft' OR NEW.posted_at IS NOT NULL THEN
      RAISE EXCEPTION 'journal transactions must be created as draft'
        USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    IF OLD.status = 'posted' THEN
      RAISE EXCEPTION 'posted journal transactions are immutable'
        USING ERRCODE = '55000';
    END IF;
    RETURN OLD;
  END IF;

  IF OLD.status = 'posted' THEN
    RAISE EXCEPTION 'posted journal transactions are immutable'
      USING ERRCODE = '55000';
  END IF;

  IF (to_jsonb(NEW) - 'status' - 'posted_at')
     IS DISTINCT FROM
     (to_jsonb(OLD) - 'status' - 'posted_at') THEN
    RAISE EXCEPTION 'journal metadata cannot change during posting'
      USING ERRCODE = '55000';
  END IF;

  IF OLD.status <> 'draft' OR NEW.status <> 'posted' THEN
    RAISE EXCEPTION 'only draft to posted transition is allowed'
      USING ERRCODE = '55000';
  END IF;

  SELECT count(*) INTO line_count
    FROM public.ledger_entries
   WHERE tenant_id = NEW.tenant_id
     AND product_id = NEW.product_id
     AND journal_id = NEW.journal_id;
  IF line_count < 2 THEN
    RAISE EXCEPTION 'a posted journal requires at least two entries'
      USING ERRCODE = '23514';
  END IF;

  SELECT EXISTS (
    SELECT currency_code
      FROM public.ledger_entries
     WHERE tenant_id = NEW.tenant_id
       AND product_id = NEW.product_id
       AND journal_id = NEW.journal_id
     GROUP BY currency_code
    HAVING sum(CASE WHEN side = 'debit' THEN amount ELSE -amount END) <> 0
  ) INTO unbalanced;
  IF unbalanced THEN
    RAISE EXCEPTION 'journal must balance independently for every currency'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.reversal_of_journal_id IS NOT NULL THEN
    SELECT status INTO original_status
      FROM public.journal_transactions
     WHERE tenant_id = NEW.tenant_id
       AND product_id = NEW.product_id
       AND journal_id = NEW.reversal_of_journal_id
     FOR UPDATE;
    IF original_status IS DISTINCT FROM 'posted' THEN
      RAISE EXCEPTION 'only a posted journal can be reversed'
        USING ERRCODE = '23514';
    END IF;

    WITH expected AS (
      SELECT account_id, currency_code,
             CASE side WHEN 'debit' THEN 'credit' ELSE 'debit' END AS side,
             amount
        FROM public.ledger_entries
       WHERE tenant_id = NEW.tenant_id
         AND product_id = NEW.product_id
         AND journal_id = NEW.reversal_of_journal_id
    ),
    actual AS (
      SELECT account_id, currency_code, side, amount
        FROM public.ledger_entries
       WHERE tenant_id = NEW.tenant_id
         AND product_id = NEW.product_id
         AND journal_id = NEW.journal_id
    )
    SELECT EXISTS (
      (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
      UNION ALL
      (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
    ) INTO reversal_mismatch;

    IF reversal_mismatch THEN
      RAISE EXCEPTION 'reversal entries must exactly invert the original journal'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  NEW.posted_at := clock_timestamp();
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS journal_transaction_guard ON public.journal_transactions;
CREATE TRIGGER journal_transaction_guard
BEFORE INSERT OR UPDATE OR DELETE ON public.journal_transactions
FOR EACH ROW EXECUTE FUNCTION public.guard_journal_transaction();

CREATE OR REPLACE FUNCTION public.guard_source_event()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  allowed_scale smallint;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT decimal_scale INTO allowed_scale
      FROM public.currency_definitions
     WHERE currency_code = NEW.currency_code;
    IF allowed_scale IS NULL OR NEW.expected_amount <> trunc(NEW.expected_amount, allowed_scale) THEN
      RAISE EXCEPTION 'source event amount exceeds the currency decimal scale'
        USING ERRCODE = '22003';
    END IF;
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'source events are immutable'
    USING ERRCODE = '55000';
END;
$function$;
CREATE TRIGGER source_event_immutable
BEFORE INSERT OR UPDATE OR DELETE ON public.source_events
FOR EACH ROW EXECUTE FUNCTION public.guard_source_event();

CREATE OR REPLACE FUNCTION public.guard_economic_effect()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  RAISE EXCEPTION 'economic effects are immutable'
    USING ERRCODE = '55000';
END;
$function$;
CREATE TRIGGER economic_effect_immutable
BEFORE UPDATE OR DELETE ON public.economic_effects
FOR EACH ROW EXECUTE FUNCTION public.guard_economic_effect();

-- All tenant-owned tables use both tenant and product context. The shared GUC
-- remains a trusted-application boundary, as proven in P-01.
DO $rls$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'ledger_accounts', 'source_events', 'journal_transactions',
    'economic_effects', 'ledger_entries', 'outbox_events'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_name);
    EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', table_name);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS PERMISSIVE FOR ALL TO ledger_runtime USING (true) WITH CHECK (true)',
      table_name || '_runtime_access', table_name
    );
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR ALL TO ledger_runtime USING (tenant_id = NULLIF(current_setting(''app.tenant_id'', true), '''')::uuid AND product_id = NULLIF(current_setting(''app.product_id'', true), '''')::uuid) WITH CHECK (tenant_id = NULLIF(current_setting(''app.tenant_id'', true), '''')::uuid AND product_id = NULLIF(current_setting(''app.product_id'', true), '''')::uuid)',
      table_name || '_tenant_product_guard', table_name
    );
  END LOOP;
END;
$rls$;

CREATE VIEW public.ledger_account_balances
WITH (security_invoker = true)
AS
SELECT a.tenant_id, a.product_id, a.account_id, a.account_code,
       a.currency_code, a.normal_side,
       COALESCE(sum(
         CASE WHEN e.side = a.normal_side THEN e.amount ELSE -e.amount END
       ), 0)::numeric(38,18) AS balance
  FROM public.ledger_accounts a
  LEFT JOIN public.ledger_entries e
    ON e.tenant_id = a.tenant_id
   AND e.product_id = a.product_id
   AND e.account_id = a.account_id
  LEFT JOIN public.journal_transactions j
    ON j.tenant_id = e.tenant_id
   AND j.product_id = e.product_id
   AND j.journal_id = e.journal_id
   AND j.status = 'posted'
 WHERE e.journal_id IS NULL OR j.journal_id IS NOT NULL
 GROUP BY a.tenant_id, a.product_id, a.account_id, a.account_code,
          a.currency_code, a.normal_side;

CREATE VIEW public.ledger_reconciliation
WITH (security_invoker = true)
AS
SELECT s.tenant_id, s.product_id, s.source_event_id, s.effect_key,
       s.currency_code, s.expected_amount,
       COALESCE(sum(
         CASE
           WHEN a.account_code = 'affiliate_payable' AND a.currency_code = s.currency_code AND e.side = 'credit' THEN e.amount
           WHEN a.account_code = 'affiliate_payable' AND a.currency_code = s.currency_code AND e.side = 'debit' THEN -e.amount
           ELSE 0
         END
       ), 0)::numeric(38,18) AS posted_payable_amount
  FROM public.source_events s
  LEFT JOIN public.journal_transactions j
    ON j.tenant_id = s.tenant_id
   AND j.product_id = s.product_id
   AND j.source_event_id = s.source_event_id
   AND j.effect_key = s.effect_key
   AND j.effect_type = 'affiliate_commission_accrual'
   AND j.status = 'posted'
   AND j.reversal_of_journal_id IS NULL
  LEFT JOIN public.ledger_entries e
    ON e.tenant_id = j.tenant_id
   AND e.product_id = j.product_id
   AND e.journal_id = j.journal_id
  LEFT JOIN public.ledger_accounts a
    ON a.tenant_id = e.tenant_id
   AND a.product_id = e.product_id
   AND a.account_id = e.account_id
 GROUP BY s.tenant_id, s.product_id, s.source_event_id, s.effect_key,
          s.currency_code, s.expected_amount
HAVING s.expected_amount <> COALESCE(sum(
  CASE
    WHEN a.account_code = 'affiliate_payable' AND a.currency_code = s.currency_code AND e.side = 'credit' THEN e.amount
    WHEN a.account_code = 'affiliate_payable' AND a.currency_code = s.currency_code AND e.side = 'debit' THEN -e.amount
    ELSE 0
  END
), 0);

GRANT USAGE ON SCHEMA public TO ledger_runtime;
GRANT SELECT ON public.currency_definitions, public.ledger_accounts,
  public.source_events, public.journal_transactions, public.economic_effects,
  public.ledger_entries, public.outbox_events,
  public.ledger_account_balances, public.ledger_reconciliation TO ledger_runtime;
GRANT INSERT ON public.journal_transactions, public.economic_effects,
  public.ledger_entries, public.outbox_events TO ledger_runtime;
GRANT UPDATE (status) ON public.journal_transactions TO ledger_runtime;

INSERT INTO public.currency_definitions (currency_code, decimal_scale, asset_kind) VALUES
  ('USD', 2, 'fiat'),
  ('EUR', 2, 'fiat'),
  ('USDT', 6, 'token'),
  ('BTC', 8, 'crypto');

INSERT INTO public.ledger_accounts
  (tenant_id, product_id, account_id, account_code, currency_code, normal_side) VALUES
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '10000000-0000-4000-8000-000000000001', 'commission_expense', 'USD', 'debit'),
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '10000000-0000-4000-8000-000000000002', 'affiliate_payable', 'USD', 'credit'),
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '10000000-0000-4000-8000-000000000003', 'commission_expense', 'USDT', 'debit'),
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '10000000-0000-4000-8000-000000000004', 'affiliate_payable', 'USDT', 'credit'),
  ('11111111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '10000000-0000-4000-8000-000000000005', 'commission_expense', 'USD', 'debit'),
  ('11111111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '10000000-0000-4000-8000-000000000006', 'affiliate_payable', 'USD', 'credit'),
  ('22222222-2222-4222-8222-222222222222', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '20000000-0000-4000-8000-000000000001', 'commission_expense', 'USD', 'debit'),
  ('22222222-2222-4222-8222-222222222222', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '20000000-0000-4000-8000-000000000002', 'affiliate_payable', 'USD', 'credit');

INSERT INTO public.source_events
  (tenant_id, product_id, source_event_id, effect_key, currency_code, expected_amount) VALUES
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'source-evt-001', 'agent-01', 'USD', 125.37),
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'source-evt-002', 'agent-02', 'USDT', 5.123456),
  ('22222222-2222-4222-8222-222222222222', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'source-evt-001', 'agent-01', 'USD', 99.99),
  ('11111111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'source-evt-001', 'agent-01', 'USD', 10.00);
