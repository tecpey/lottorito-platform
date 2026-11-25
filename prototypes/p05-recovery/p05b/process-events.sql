CREATE OR REPLACE FUNCTION public.p05_process_pending(p_tenant uuid,p_consumer text,p_aggregate uuid)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public,pg_temp AS $
DECLARE v_last bigint; v_event public.p05_inbox%ROWTYPE; v_count integer:=0; v_amount bigint; v_currency text;
BEGIN
 SELECT last_sequence INTO v_last FROM public.p05_replay_cursor
 WHERE tenant_id=p_tenant AND consumer_name=p_consumer AND aggregate_id=p_aggregate FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'replay cursor missing'; END IF;
 LOOP
  SELECT * INTO v_event FROM public.p05_inbox
  WHERE tenant_id=p_tenant AND consumer_name=p_consumer AND aggregate_id=p_aggregate
   AND aggregate_seq=v_last+1 AND status='pending' ORDER BY source_event_id LIMIT 1 FOR UPDATE;
  EXIT WHEN NOT FOUND;
  SELECT amount_minor,currency_code INTO v_amount,v_currency FROM public.source_events
  WHERE tenant_id=p_tenant AND event_id=v_event.source_event_id AND economic_effect_id=v_event.economic_effect_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'source event missing or mismatched'; END IF;
  INSERT INTO public.ledger_journals VALUES(p_tenant,v_event.source_event_id,v_event.economic_effect_id,v_currency,v_event.source_event_id);
  INSERT INTO public.ledger_lines VALUES
   (p_tenant,v_event.source_event_id,1,'cash','debit',v_amount),
   (p_tenant,v_event.source_event_id,2,'clearing','credit',v_amount);
  UPDATE public.p05_inbox SET status='processed'
   WHERE tenant_id=p_tenant AND consumer_name=p_consumer AND source_event_id=v_event.source_event_id;
  v_last:=v_event.aggregate_seq;
  UPDATE public.p05_replay_cursor SET last_sequence=v_last
   WHERE tenant_id=p_tenant AND consumer_name=p_consumer AND aggregate_id=p_aggregate;
  v_count:=v_count+1;
 END LOOP;
 RETURN v_count;
END $$;
REVOKE ALL ON FUNCTION public.p05_process_pending(uuid,text,uuid) FROM PUBLIC;
DO $$ DECLARE n integer; BEGIN
 SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','ledger-projection','50000000-0000-4000-8000-000000000001') INTO n;
 IF n<>0 THEN RAISE EXCEPTION 'out-of-order event bypassed sequence gate'; END IF;
END $$;
-- Deliver sequence 1, duplicate sequence 2, and a different event ID for an existing economic effect.
INSERT INTO public.p05_inbox VALUES
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','ledger-projection','30000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000101','50000000-0000-4000-8000-000000000001',1,'pending'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','ledger-projection','30000000-0000-4000-8000-000000000102','20000000-0000-4000-8000-000000000102','50000000-0000-4000-8000-000000000001',2,'pending'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','ledger-projection','30000000-0000-4000-8000-000000000199','20000000-0000-4000-8000-000000000101','50000000-0000-4000-8000-000000000001',1,'pending')
ON CONFLICT DO NOTHING;
