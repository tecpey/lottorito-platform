-- P-09E disposable recovery helper. SECURITY INVOKER is intentional:
-- tenant/product RLS must evaluate against the authenticated session_user.
CREATE OR REPLACE FUNCTION public.p09e_process_provider_event(
  p_provider_event_id text,
  p_debit_account_id uuid,
  p_credit_account_id uuid,
  p_amount_minor text,
  p_idempotency_key text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog, public, private, pg_temp
AS $function$
DECLARE
  v_event public.provider_event_inbox%ROWTYPE;
  v_journal_id uuid;
  v_updated integer;
BEGIN
  UPDATE public.provider_event_inbox
     SET status = 'processing',
         attempt_count = attempt_count + 1,
         lease_owner = 'p09e-recovery-worker',
         lease_token = gen_random_uuid(),
         lease_until = clock_timestamp() + interval '60 seconds'
   WHERE tenant_id = private.current_tenant_id()
     AND product_id = private.current_product_id()
     AND provider_id = 'synthetic-provider'
     AND provider_event_id = p_provider_event_id
     AND status IN ('accepted', 'retry')
     AND available_at <= clock_timestamp()
     AND attempt_count < max_attempts
   RETURNING * INTO v_event;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'P-09E provider event is not claimable in this tenant/product scope'
      USING ERRCODE = '55000';
  END IF;

  -- Recovery/replay is a trust boundary too: never post from an inbox row whose
  -- persisted CloudEvent no longer agrees with its tenant/product/source identity.
  IF v_event.canonical_event->>'specversion' IS DISTINCT FROM '1.0'
     OR v_event.canonical_event->>'id' IS DISTINCT FROM v_event.provider_event_id
     OR v_event.canonical_event->>'source' IS DISTINCT FROM v_event.event_source
     OR v_event.canonical_event->>'type' IS DISTINCT FROM v_event.event_type
     OR v_event.canonical_event->>'tenantid' IS DISTINCT FROM v_event.tenant_id::text
     OR v_event.canonical_event->'scope'->>'kind' IS DISTINCT FROM 'product'
     OR v_event.canonical_event->'scope'->>'id' IS DISTINCT FROM v_event.product_id
     OR v_event.canonical_event->>'sourceeventid' IS DISTINCT FROM v_event.source_event_id::text
     OR v_event.canonical_event->>'dataschema' IS NULL
     OR v_event.canonical_event->>'time' IS NULL
     OR v_event.canonical_event->>'schemaversion' !~ '^[1-9][0-9]*
    INTO v_journal_id
    FROM public.post_journal(
      p_idempotency_key,
      v_event.effect_id,
      v_event.source_event_id,
      jsonb_build_array(
        jsonb_build_object(
          'line_no', 1, 'account_id', p_debit_account_id,
          'currency_code', 'USD', 'direction', 'debit',
          'amount_minor', p_amount_minor
        ),
        jsonb_build_object(
          'line_no', 2, 'account_id', p_credit_account_id,
          'currency_code', 'USD', 'direction', 'credit',
          'amount_minor', p_amount_minor
        )
      )
    ) AS p;

  UPDATE public.provider_event_inbox
     SET status = 'processed',
         processed_at = clock_timestamp(),
         journal_id = v_journal_id,
         lease_owner = NULL,
         lease_token = NULL,
         lease_until = NULL,
         last_error_code = NULL
   WHERE tenant_id = v_event.tenant_id
     AND product_id = v_event.product_id
     AND provider_id = v_event.provider_id
     AND provider_event_id = v_event.provider_event_id
     AND status = 'processing'
     AND lease_token = v_event.lease_token
     AND lease_until > clock_timestamp();

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'P-09E provider inbox lease fencing failed'
      USING ERRCODE = '40001';
  END IF;

  RETURN v_journal_id;
END
$function$;

REVOKE ALL ON FUNCTION public.p09e_process_provider_event(text, uuid, uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.p09e_process_provider_event(text, uuid, uuid, text, text)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;

     OR v_event.canonical_event->>'traceparent' !~ '^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}
    INTO v_journal_id
    FROM public.post_journal(
      p_idempotency_key,
      v_event.effect_id,
      v_event.source_event_id,
      jsonb_build_array(
        jsonb_build_object(
          'line_no', 1, 'account_id', p_debit_account_id,
          'currency_code', 'USD', 'direction', 'debit',
          'amount_minor', p_amount_minor
        ),
        jsonb_build_object(
          'line_no', 2, 'account_id', p_credit_account_id,
          'currency_code', 'USD', 'direction', 'credit',
          'amount_minor', p_amount_minor
        )
      )
    ) AS p;

  UPDATE public.provider_event_inbox
     SET status = 'processed',
         processed_at = clock_timestamp(),
         journal_id = v_journal_id,
         lease_owner = NULL,
         lease_token = NULL,
         lease_until = NULL,
         last_error_code = NULL
   WHERE tenant_id = v_event.tenant_id
     AND product_id = v_event.product_id
     AND provider_id = v_event.provider_id
     AND provider_event_id = v_event.provider_event_id
     AND status = 'processing'
     AND lease_token = v_event.lease_token
     AND lease_until > clock_timestamp();

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'P-09E provider inbox lease fencing failed'
      USING ERRCODE = '40001';
  END IF;

  RETURN v_journal_id;
END
$function$;

REVOKE ALL ON FUNCTION public.p09e_process_provider_event(text, uuid, uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.p09e_process_provider_event(text, uuid, uuid, text, text)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;

     OR v_event.canonical_event->>'traceparent' ~ '^00-0{32}-'
     OR v_event.canonical_event->>'traceparent' ~ '-0{16}-'
  THEN
    RAISE EXCEPTION 'P-09E canonical event contract or inbox identity mismatch'
      USING ERRCODE = '22023';
  END IF;

  PERFORM (v_event.canonical_event->>'time')::timestamptz;

  SELECT p.journal_id
    INTO v_journal_id
    FROM public.post_journal(
      p_idempotency_key,
      v_event.effect_id,
      v_event.source_event_id,
      jsonb_build_array(
        jsonb_build_object(
          'line_no', 1, 'account_id', p_debit_account_id,
          'currency_code', 'USD', 'direction', 'debit',
          'amount_minor', p_amount_minor
        ),
        jsonb_build_object(
          'line_no', 2, 'account_id', p_credit_account_id,
          'currency_code', 'USD', 'direction', 'credit',
          'amount_minor', p_amount_minor
        )
      )
    ) AS p;

  UPDATE public.provider_event_inbox
     SET status = 'processed',
         processed_at = clock_timestamp(),
         journal_id = v_journal_id,
         lease_owner = NULL,
         lease_token = NULL,
         lease_until = NULL,
         last_error_code = NULL
   WHERE tenant_id = v_event.tenant_id
     AND product_id = v_event.product_id
     AND provider_id = v_event.provider_id
     AND provider_event_id = v_event.provider_event_id
     AND status = 'processing'
     AND lease_token = v_event.lease_token
     AND lease_until > clock_timestamp();

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'P-09E provider inbox lease fencing failed'
      USING ERRCODE = '40001';
  END IF;

  RETURN v_journal_id;
END
$function$;

REVOKE ALL ON FUNCTION public.p09e_process_provider_event(text, uuid, uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.p09e_process_provider_event(text, uuid, uuid, text, text)
  TO tenant_a_ledger_runtime, tenant_b_ledger_runtime, tenant_a_lottery_runtime;
