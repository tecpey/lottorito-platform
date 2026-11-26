-- P-05B synthetic-only inbox, replay cursor and event fixtures.
CREATE TABLE public.p05_inbox (
 tenant_id uuid NOT NULL, product_id text NOT NULL CHECK(product_id IN('affiliate_agent','lottery')), consumer_name text NOT NULL, source_event_id uuid NOT NULL,
 economic_effect_id uuid NOT NULL, aggregate_id uuid NOT NULL,
 aggregate_seq bigint NOT NULL CHECK(aggregate_seq>0),
 status text NOT NULL DEFAULT 'pending' CHECK(status IN('pending','processed')),
 PRIMARY KEY(tenant_id,product_id,consumer_name,source_event_id),
 UNIQUE(tenant_id,product_id,consumer_name,economic_effect_id),
 UNIQUE(tenant_id,product_id,consumer_name,aggregate_id,aggregate_seq)
);
CREATE TABLE public.p05_replay_cursor (
 tenant_id uuid NOT NULL, product_id text NOT NULL CHECK(product_id IN('affiliate_agent','lottery')), consumer_name text NOT NULL, aggregate_id uuid NOT NULL,
 last_sequence bigint NOT NULL DEFAULT 0 CHECK(last_sequence>=0),
 PRIMARY KEY(tenant_id,product_id,consumer_name,aggregate_id)
);
ALTER TABLE public.p05_inbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.p05_inbox FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_product_scope ON public.p05_inbox USING(tenant_id=p05_private.current_tenant_id() AND product_id=p05_private.current_product_id()) WITH CHECK(tenant_id=p05_private.current_tenant_id() AND product_id=p05_private.current_product_id());
ALTER TABLE public.p05_replay_cursor ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.p05_replay_cursor FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_product_scope ON public.p05_replay_cursor USING(tenant_id=p05_private.current_tenant_id() AND product_id=p05_private.current_product_id()) WITH CHECK(tenant_id=p05_private.current_tenant_id() AND product_id=p05_private.current_product_id());
GRANT SELECT,INSERT ON public.p05_inbox TO p05_tenant_a,p05_tenant_b,p05_tenant_a_lottery;
GRANT SELECT ON public.p05_replay_cursor TO p05_tenant_a,p05_tenant_b,p05_tenant_a_lottery;
INSERT INTO public.source_events(tenant_id,event_id,economic_effect_id,currency_code,amount_minor,product_id) VALUES
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000101','USD',300,'affiliate_agent'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000102','20000000-0000-4000-8000-000000000102','USD',400,'affiliate_agent'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000101','USD',300,'lottery'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000102','20000000-0000-4000-8000-000000000102','USD',400,'lottery');
INSERT INTO public.p05_replay_cursor(tenant_id,product_id,consumer_name,aggregate_id,last_sequence) VALUES
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','affiliate_agent','ledger-projection','50000000-0000-4000-8000-000000000001',0),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','lottery','ledger-projection','50000000-0000-4000-8000-000000000001',0);
-- Receive sequence 2 first. The consumer must not advance across the sequence gap.
INSERT INTO public.p05_inbox(tenant_id,product_id,consumer_name,source_event_id,economic_effect_id,aggregate_id,aggregate_seq,status) VALUES
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','affiliate_agent','ledger-projection','30000000-0000-4000-8000-000000000102','20000000-0000-4000-8000-000000000102','50000000-0000-4000-8000-000000000001',2,'pending'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','lottery','ledger-projection','30000000-0000-4000-8000-000000000102','20000000-0000-4000-8000-000000000102','50000000-0000-4000-8000-000000000001',2,'pending')
ON CONFLICT DO NOTHING;
