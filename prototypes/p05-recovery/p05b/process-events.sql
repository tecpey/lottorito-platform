CREATE OR REPLACE FUNCTION public.p05_process_pending(p_tenant uuid,p_product text,p_consumer text,p_aggregate uuid)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
DECLARE v_last bigint; v_event public.p05_inbox%ROWTYPE; v_count integer:=0; v_amount bigint; v_currency text;
BEGIN
 IF p_product NOT IN('affiliate_agent','lottery') THEN RAISE EXCEPTION 'invalid product scope'; END IF;
 SELECT last_sequence INTO v_last FROM public.p05_replay_cursor
 WHERE tenant_id=p_tenant AND product_id=p_product AND consumer_name=p_consumer AND aggregate_id=p_aggregate FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'replay cursor missing'; END IF;
 LOOP
  SELECT * INTO v_event FROM public.p05_inbox
  WHERE tenant_id=p_tenant AND product_id=p_product AND consumer_name=p_consumer AND aggregate_id=p_aggregate
   AND aggregate_seq=v_last+1 AND status='pending' FOR UPDATE;
  EXIT WHEN NOT FOUND;
  SELECT amount_minor,currency_code INTO v_amount,v_currency FROM public.source_events
  WHERE tenant_id=p_tenant AND product_id=p_product AND event_id=v_event.source_event_id AND economic_effect_id=v_event.economic_effect_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'source event missing or mismatched'; END IF;
  INSERT INTO public.ledger_journals(tenant_id,journal_id,economic_effect_id,currency_code,source_event_id,product_id)
  VALUES(p_tenant,v_event.source_event_id,v_event.economic_effect_id,v_currency,v_event.source_event_id,p_product);
  INSERT INTO public.ledger_lines(tenant_id,journal_id,line_no,account_code,direction,amount_minor,product_id) VALUES
   (p_tenant,v_event.source_event_id,1,'cash','debit',v_amount,p_product),
   (p_tenant,v_event.source_event_id,2,'clearing','credit',v_amount,p_product);
  UPDATE public.p05_inbox SET status='processed'
   WHERE tenant_id=p_tenant AND product_id=p_product AND consumer_name=p_consumer AND source_event_id=v_event.source_event_id;
  v_last:=v_event.aggregate_seq;
  UPDATE public.p05_replay_cursor SET last_sequence=v_last
   WHERE tenant_id=p_tenant AND product_id=p_product AND consumer_name=p_consumer AND aggregate_id=p_aggregate;
  v_count:=v_count+1;
 END LOOP;
 RETURN v_count;
END $$;
REVOKE ALL ON FUNCTION public.p05_process_pending(uuid,text,text,uuid) FROM PUBLIC;
DO $$ DECLARE n integer; BEGIN
 SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','affiliate_agent','ledger-projection','50000000-0000-4000-8000-000000000001') INTO n;
 IF n<>0 THEN RAISE EXCEPTION 'affiliate out-of-order event bypassed sequence gate'; END IF;
 SELECT public.p05_process_pending('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','lottery','ledger-projection','50000000-0000-4000-8000-000000000001') INTO n;
 IF n<>0 THEN RAISE EXCEPTION 'lottery out-of-order event bypassed sequence gate'; END IF;
END $$;
-- Deliver sequence 1, duplicate sequence 2, and a different event ID for an existing economic effect.
INSERT INTO public.p05_inbox(tenant_id,product_id,consumer_name,source_event_id,economic_effect_id,aggregate_id,aggregate_seq,status) VALUES
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','affiliate_agent','ledger-projection','30000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000101','50000000-0000-4000-8000-000000000001',1,'pending'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','affiliate_agent','ledger-projection','30000000-0000-4000-8000-000000000102','20000000-0000-4000-8000-000000000102','50000000-0000-4000-8000-000000000001',2,'pending'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','affiliate_agent','ledger-projection','30000000-0000-4000-8000-000000000199','20000000-0000-4000-8000-000000000101','50000000-0000-4000-8000-000000000001',1,'pending'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','lottery','ledger-projection','30000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000101','50000000-0000-4000-8000-000000000001',1,'pending'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','lottery','ledger-projection','30000000-0000-4000-8000-000000000102','20000000-0000-4000-8000-000000000102','50000000-0000-4000-8000-000000000001',2,'pending'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','lottery','ledger-projection','30000000-0000-4000-8000-000000000199','20000000-0000-4000-8000-000000000101','50000000-0000-4000-8000-000000000001',1,'pending')
ON CONFLICT DO NOTHING;

-- A sequence number is unique inside one product-qualified aggregate stream.
DO $$
BEGIN
 BEGIN
  INSERT INTO public.p05_inbox(tenant_id,product_id,consumer_name,source_event_id,economic_effect_id,aggregate_id,aggregate_seq,status)
  VALUES('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','affiliate_agent','ledger-projection','30000000-0000-4000-8000-000000000201','20000000-0000-4000-8000-000000000201','50000000-0000-4000-8000-000000000001',1,'pending');
  RAISE EXCEPTION 'duplicate aggregate sequence unexpectedly accepted';
 EXCEPTION WHEN unique_violation THEN
  NULL;
 END;
END $$;
