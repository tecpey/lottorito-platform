-- All functions execute as a non-login, non-superuser owner and derive tenant from session_user.
CREATE FUNCTION public.claim_outbox_events(p_batch_size integer,p_lease_seconds integer,p_worker_id text)
RETURNS TABLE(event_id uuid,aggregate_id uuid,event_type text,payload jsonb,attempt integer,lease_token uuid,lease_until timestamptz)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,private,pg_temp
AS $fn$
DECLARE v_tenant uuid;
BEGIN
 v_tenant:=private.current_tenant_id();
 IF v_tenant IS NULL THEN RAISE EXCEPTION 'database identity is not mapped to a tenant' USING ERRCODE='42501'; END IF;
 IF p_batch_size IS NULL OR p_batch_size<1 OR p_batch_size>100 OR p_lease_seconds IS NULL OR p_lease_seconds<1 OR p_lease_seconds>300 OR p_worker_id IS NULL OR p_worker_id !~ '^[A-Za-z0-9._:-]{1,80}$' THEN
  RAISE EXCEPTION 'invalid outbox claim parameters' USING ERRCODE='22023';
 END IF;
 UPDATE public.outbox_delivery_state d SET status='dead',lease_owner=NULL,lease_token=NULL,lease_until=NULL,last_error='lease expired after maximum attempts'
 WHERE d.tenant_id=v_tenant AND d.status='leased' AND d.lease_until<=clock_timestamp() AND d.attempts>=d.max_attempts;
 RETURN QUERY
 WITH candidates AS (
  SELECT d.tenant_id,d.event_id FROM public.outbox_delivery_state d
  WHERE d.tenant_id=v_tenant AND d.attempts<d.max_attempts
   AND ((d.status='pending' AND d.available_at<=clock_timestamp()) OR (d.status='leased' AND d.lease_until<=clock_timestamp()))
  ORDER BY d.available_at,d.event_id FOR UPDATE SKIP LOCKED LIMIT p_batch_size
 ), claimed AS (
  UPDATE public.outbox_delivery_state d
  SET status='leased',attempts=d.attempts+1,lease_owner=p_worker_id,lease_token=gen_random_uuid(),
      lease_until=clock_timestamp()+make_interval(secs=>p_lease_seconds),published_at=NULL
  FROM candidates c WHERE d.tenant_id=c.tenant_id AND d.event_id=c.event_id
  RETURNING d.tenant_id,d.event_id,d.attempts,d.lease_token,d.lease_until
 )
 SELECT e.event_id,e.aggregate_id,e.event_type,e.payload,c.attempts,c.lease_token,c.lease_until
 FROM claimed c JOIN public.outbox_events e USING(tenant_id,event_id)
 ORDER BY e.created_at,e.event_id;
END
$fn$;
ALTER FUNCTION public.claim_outbox_events(integer,integer,text) OWNER TO outbox_executor;

CREATE FUNCTION public.ack_outbox_event(p_event_id uuid,p_lease_token uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,private,pg_temp
AS $fn$
DECLARE v_tenant uuid; v_count integer;
BEGIN
 v_tenant:=private.current_tenant_id();
 IF v_tenant IS NULL OR p_event_id IS NULL OR p_lease_token IS NULL THEN RAISE EXCEPTION 'invalid acknowledgement' USING ERRCODE='22023'; END IF;
 UPDATE public.outbox_delivery_state SET status='published',published_at=clock_timestamp(),lease_owner=NULL,lease_token=NULL,lease_until=NULL,last_error=NULL
 WHERE tenant_id=v_tenant AND event_id=p_event_id AND status='leased' AND lease_token=p_lease_token AND lease_until>clock_timestamp();
 GET DIAGNOSTICS v_count=ROW_COUNT;
 RETURN v_count=1;
END
$fn$;
ALTER FUNCTION public.ack_outbox_event(uuid,uuid) OWNER TO outbox_executor;

CREATE FUNCTION public.nack_outbox_event(p_event_id uuid,p_lease_token uuid,p_error text,p_retry_seconds integer)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,private,pg_temp
AS $fn$
DECLARE v_tenant uuid; v_status text; v_attempts integer; v_max integer;
BEGIN
 v_tenant:=private.current_tenant_id();
 IF v_tenant IS NULL OR p_event_id IS NULL OR p_lease_token IS NULL OR p_retry_seconds IS NULL OR p_retry_seconds<0 OR p_retry_seconds>86400 THEN RAISE EXCEPTION 'invalid negative acknowledgement' USING ERRCODE='22023'; END IF;
 SELECT attempts,max_attempts INTO v_attempts,v_max FROM public.outbox_delivery_state
 WHERE tenant_id=v_tenant AND event_id=p_event_id AND status='leased' AND lease_token=p_lease_token AND lease_until>clock_timestamp()
 FOR UPDATE;
 IF NOT FOUND THEN RETURN 'stale'; END IF;
 v_status:=CASE WHEN v_attempts>=v_max THEN 'dead' ELSE 'pending' END;
 UPDATE public.outbox_delivery_state SET status=v_status,available_at=clock_timestamp()+make_interval(secs=>p_retry_seconds),
  lease_owner=NULL,lease_token=NULL,lease_until=NULL,last_error=left(COALESCE(p_error,'delivery failed'),1000)
 WHERE tenant_id=v_tenant AND event_id=p_event_id;
 RETURN v_status;
END
$fn$;
ALTER FUNCTION public.nack_outbox_event(uuid,uuid,text,integer) OWNER TO outbox_executor;

CREATE FUNCTION public.consume_outbox_event(p_consumer_name text,p_event_id uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,private,pg_temp
AS $fn$
DECLARE v_tenant uuid; v_payload jsonb; v_inserted integer;
BEGIN
 v_tenant:=private.current_tenant_id();
 IF v_tenant IS NULL OR p_consumer_name IS NULL OR p_consumer_name !~ '^[A-Za-z0-9._:-]{1,80}$' OR p_event_id IS NULL THEN
  RAISE EXCEPTION 'invalid consumer receipt' USING ERRCODE='22023';
 END IF;
 SELECT payload INTO v_payload FROM public.outbox_events WHERE tenant_id=v_tenant AND event_id=p_event_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'outbox event is unavailable' USING ERRCODE='P0002'; END IF;
 INSERT INTO public.consumer_inbox(tenant_id,consumer_name,event_id) VALUES(v_tenant,p_consumer_name,p_event_id) ON CONFLICT DO NOTHING;
 GET DIAGNOSTICS v_inserted=ROW_COUNT;
 IF v_inserted=0 THEN RETURN false; END IF;
 INSERT INTO public.consumer_effects(tenant_id,consumer_name,event_id,payload) VALUES(v_tenant,p_consumer_name,p_event_id,v_payload);
 RETURN true;
END
$fn$;
ALTER FUNCTION public.consume_outbox_event(text,uuid) OWNER TO outbox_executor;

REVOKE ALL ON FUNCTION public.claim_outbox_events(integer,integer,text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.ack_outbox_event(uuid,uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.nack_outbox_event(uuid,uuid,text,integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.consume_outbox_event(text,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_outbox_events(integer,integer,text) TO tenant_a_outbox_runtime,tenant_b_outbox_runtime;
GRANT EXECUTE ON FUNCTION public.ack_outbox_event(uuid,uuid) TO tenant_a_outbox_runtime,tenant_b_outbox_runtime;
GRANT EXECUTE ON FUNCTION public.nack_outbox_event(uuid,uuid,text,integer) TO tenant_a_outbox_runtime,tenant_b_outbox_runtime;
GRANT EXECUTE ON FUNCTION public.consume_outbox_event(text,uuid) TO tenant_a_outbox_runtime,tenant_b_outbox_runtime;
