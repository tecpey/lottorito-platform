-- Disposable synthetic P-05C fixture. Never use these roles or settings in production.
CREATE ROLE repl WITH REPLICATION LOGIN;
CREATE TABLE public.p05c_events(
 event_id text PRIMARY KEY,
 writer_id text NOT NULL,
 epoch bigint NOT NULL,
 payload text NOT NULL
);
CREATE TABLE public.p05c_fence_state(
 singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
 current_epoch bigint NOT NULL,
 active_writer text NOT NULL,
 lease_until timestamptz NOT NULL
);
INSERT INTO public.p05c_fence_state VALUES(true,1,'node-a',clock_timestamp()+interval '1 hour');

CREATE FUNCTION public.p05c_post_effect(p_writer text,p_epoch bigint,p_event_id text,p_payload text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE s record;
BEGIN
 SELECT current_epoch,active_writer,lease_until INTO s
 FROM public.p05c_fence_state WHERE singleton FOR UPDATE;
 IF NOT FOUND OR s.current_epoch<>p_epoch OR s.active_writer<>p_writer OR s.lease_until<=clock_timestamp() THEN
  RAISE EXCEPTION 'P05C_WRITER_FENCED';
 END IF;
 INSERT INTO public.p05c_events VALUES(p_event_id,p_writer,p_epoch,p_payload);
END $$;

CREATE FUNCTION public.p05c_claim_epoch(p_expected bigint,p_writer text)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE v_epoch bigint;
BEGIN
 UPDATE public.p05c_fence_state
 SET current_epoch=current_epoch+1,active_writer=p_writer
 WHERE singleton AND current_epoch=p_expected AND lease_until>clock_timestamp()
 RETURNING current_epoch INTO v_epoch;
 RETURN v_epoch;
END $$;
