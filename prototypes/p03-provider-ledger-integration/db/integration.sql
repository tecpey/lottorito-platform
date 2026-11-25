-- P-03D provider inbox -> product-scoped P-02 posting -> P-03C outbox.
-- Disposable synthetic fixture only. Never run against shared, staging or production.

DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'provider_event_owner') THEN
    CREATE ROLE provider_event_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
END
$roles$;
ALTER ROLE provider_event_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;

CREATE UNIQUE INDEX IF NOT EXISTS ledger_journals_tenant_product_journal_uidx
  ON public.ledger_journals (tenant_id, product_id, journal_id);

CREATE TABLE public.provider_event_inbox (
  tenant_id uuid NOT NULL,
  product_id text NOT NULL CHECK (product_id IN ('affiliate_agent', 'lottery', 'shared')),
  provider_id text NOT NULL CHECK (provider_id ~ '^[A-Za-z0-9._:-]{1,80}$'),
  provider_event_id text NOT NULL CHECK (length(provider_event_id) BETWEEN 1 AND 255),
  event_type text NOT NULL CHECK (length(event_type) BETWEEN 1 AND 160),
  event_source text NOT NULL CHECK (length(event_source) BETWEEN 1 AND 255),
  payload_hash text NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  signature_key_id text NOT NULL CHECK (signature_key_id ~ '^[A-Za-z0-9._:-]{1,80}$'),
  canonical_event jsonb NOT NULL CHECK (jsonb_typeof(canonical_event) = 'object'),
  effect_id uuid NOT NULL DEFAULT gen_random_uuid(),
  source_event_id uuid NOT NULL DEFAULT gen_random_uuid(),
  status text NOT NULL DEFAULT 'accepted'
    CHECK (status IN ('accepted', 'processing', 'retry', 'processed', 'dead_letter', 'quarantined')),
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  max_attempts integer NOT NULL DEFAULT 5 CHECK (max_attempts BETWEEN 1 AND 20),
  available_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  lease_owner text,
  lease_token uuid,
  lease_until timestamptz,
  last_error_code text CHECK (last_error_code IS NULL OR last_error_code ~ '^[A-Z0-9_:-]{1,80}$'),
  received_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  processed_at timestamptz,
  journal_id uuid,
  PRIMARY KEY (tenant_id, product_id, provider_id, provider_event_id),
  UNIQUE (tenant_id, product_id, effect_id),
  UNIQUE (tenant_id, product_id, source_event_id),
  FOREIGN KEY (tenant_id, product_id, journal_id)
    REFERENCES public.ledger_journals (tenant_id, product_id, journal_id),
  CHECK (
    (status = 'processing' AND lease_owner IS NOT NULL AND lease_token IS NOT NULL AND lease_until IS NOT NULL)
    OR
    (status <> 'processing' AND lease_owner IS NULL AND lease_token IS NULL AND lease_until IS NULL)
  ),
  CHECK ((status = 'processed') = (processed_at IS NOT NULL AND journal_id IS NOT NULL))
);
ALTER TABLE public.provider_event_inbox OWNER TO provider_event_owner;

CREATE TABLE public.provider_event_conflicts (
  tenant_id uuid NOT NULL,
  product_id text NOT NULL,
  provider_id text NOT NULL,
  provider_event_id text NOT NULL,
  accepted_payload_hash text NOT NULL CHECK (accepted_payload_hash ~ '^[0-9a-f]{64}$'),
  conflicting_payload_hash text NOT NULL CHECK (conflicting_payload_hash ~ '^[0-9a-f]{64}$'),
  detected_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, provider_id, provider_event_id, conflicting_payload_hash),
  CHECK (accepted_payload_hash <> conflicting_payload_hash)
);
ALTER TABLE public.provider_event_conflicts OWNER TO provider_event_owner;

CREATE TABLE public.provider_event_expectations (
  tenant_id uuid NOT NULL,
  product_id text NOT NULL,
  provider_id text NOT NULL,
  provider_event_id text NOT NULL,
  expected_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, product_id, provider_id, provider_event_id)
);
ALTER TABLE public.provider_event_expectations OWNER TO provider_event_owner;

CREATE INDEX provider_event_inbox_claim_idx
  ON public.provider_event_inbox (tenant_id, product_id, status, available_at, received_at);
CREATE INDEX provider_event_inbox_lease_idx
  ON public.provider_event_inbox (tenant_id, product_id, status, lease_until);

ALTER TABLE public.provider_event_inbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_event_inbox FORCE ROW LEVEL SECURITY;
ALTER TABLE public.provider_event_conflicts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_event_conflicts FORCE ROW LEVEL SECURITY;

CREATE POLICY provider_event_inbox_product_scope
  ON public.provider_event_inbox FOR ALL
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime
  USING (tenant_id = private.current_tenant_id() AND product_id = private.current_product_id())
  WITH CHECK (tenant_id = private.current_tenant_id() AND product_id = private.current_product_id());

CREATE POLICY provider_event_conflicts_product_scope
  ON public.provider_event_conflicts FOR SELECT
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime
  USING (tenant_id = private.current_tenant_id() AND product_id = private.current_product_id());

CREATE POLICY provider_event_conflicts_insert_scope
  ON public.provider_event_conflicts FOR INSERT
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime
  WITH CHECK (tenant_id = private.current_tenant_id() AND product_id = private.current_product_id());

CREATE FUNCTION private.reject_provider_conflict_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
BEGIN
  RAISE EXCEPTION 'provider conflict evidence is immutable' USING ERRCODE = '55000';
END
$function$;
ALTER FUNCTION private.reject_provider_conflict_mutation() OWNER TO provider_event_owner;
REVOKE ALL ON FUNCTION private.reject_provider_conflict_mutation() FROM PUBLIC;
CREATE TRIGGER provider_event_conflicts_immutable
  BEFORE UPDATE OR DELETE ON public.provider_event_conflicts
  FOR EACH ROW EXECUTE FUNCTION private.reject_provider_conflict_mutation();

GRANT USAGE ON SCHEMA public TO provider_event_owner,
  tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;
GRANT USAGE ON SCHEMA private TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;
GRANT EXECUTE ON FUNCTION private.current_tenant_id() TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;
GRANT EXECUTE ON FUNCTION private.current_product_id() TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;

GRANT SELECT, INSERT ON public.provider_event_inbox
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;
GRANT UPDATE (status, attempt_count, available_at, lease_owner, lease_token, lease_until,
              last_error_code, processed_at, journal_id)
  ON public.provider_event_inbox
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;
GRANT SELECT, INSERT ON public.provider_event_conflicts
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;

CREATE VIEW public.provider_event_reconciliation
WITH (security_invoker = true)
AS
SELECT e.tenant_id, e.product_id, e.provider_id, e.provider_event_id,
       i.status AS inbox_status, i.journal_id,
       j.journal_id AS journal_found, o.event_id AS outbox_event_id,
       d.status AS delivery_status, e.expected_at
  FROM public.provider_event_expectations e
  LEFT JOIN public.provider_event_inbox i
    ON i.tenant_id = e.tenant_id AND i.product_id = e.product_id
   AND i.provider_id = e.provider_id AND i.provider_event_id = e.provider_event_id
  LEFT JOIN public.ledger_journals j
    ON j.tenant_id = i.tenant_id AND j.product_id = i.product_id AND j.journal_id = i.journal_id
  LEFT JOIN public.ledger_outbox o
    ON o.tenant_id = j.tenant_id AND o.product_id = j.product_id
   AND o.journal_id = j.journal_id AND o.event_type = 'ledger.journal.posted'
  LEFT JOIN public.outbox_delivery_state d
    ON d.tenant_id = o.tenant_id AND d.product_id = o.product_id AND d.event_id = o.event_id
 WHERE i.provider_event_id IS NULL
    OR i.status <> 'processed'
    OR j.journal_id IS NULL
    OR o.event_id IS NULL
    OR d.event_id IS NULL;

GRANT SELECT ON public.provider_event_reconciliation TO postgres;
