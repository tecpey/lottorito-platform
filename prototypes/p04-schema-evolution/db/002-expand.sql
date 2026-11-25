ALTER TABLE public.partner_events ADD COLUMN canonical_payload jsonb;
CREATE FUNCTION public.p04_sync_payload_columns() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog,public,pg_temp AS $fn$
DECLARE old_changed boolean; new_changed boolean;
BEGIN
 IF TG_OP='INSERT' THEN
  IF NEW.payload IS NULL AND NEW.canonical_payload IS NULL THEN RAISE EXCEPTION 'payload required' USING ERRCODE='23514';
  ELSIF NEW.payload IS NULL THEN NEW.payload:=NEW.canonical_payload;
  ELSIF NEW.canonical_payload IS NULL THEN NEW.canonical_payload:=NEW.payload;
  ELSIF NEW.payload IS DISTINCT FROM NEW.canonical_payload THEN RAISE EXCEPTION 'payload conflict' USING ERRCODE='23514'; END IF;
 ELSE
  old_changed:=NEW.payload IS DISTINCT FROM OLD.payload; new_changed:=NEW.canonical_payload IS DISTINCT FROM OLD.canonical_payload;
  IF old_changed AND NOT new_changed THEN NEW.canonical_payload:=NEW.payload;
  ELSIF new_changed AND NOT old_changed THEN NEW.payload:=NEW.canonical_payload;
  ELSIF old_changed AND new_changed AND NEW.payload IS DISTINCT FROM NEW.canonical_payload THEN RAISE EXCEPTION 'payload conflict' USING ERRCODE='23514';
  ELSIF NEW.payload IS NULL AND NEW.canonical_payload IS NOT NULL THEN NEW.payload:=NEW.canonical_payload;
  ELSIF NEW.canonical_payload IS NULL AND NEW.payload IS NOT NULL THEN NEW.canonical_payload:=NEW.payload; END IF;
 END IF; RETURN NEW;
END $fn$;
CREATE TRIGGER p04_sync_payload_columns BEFORE INSERT OR UPDATE OF payload,canonical_payload ON public.partner_events FOR EACH ROW EXECUTE FUNCTION public.p04_sync_payload_columns();
ALTER TABLE public.partner_events ADD CONSTRAINT p04_payload_object CHECK(canonical_payload IS NULL OR jsonb_typeof(canonical_payload)='object') NOT VALID;
