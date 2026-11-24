# تحویل Outbox تراکنشی محدود به Tenant در P-03

**شناسه سند:** LOT-PROT-P03-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** Prototype ساختگی؛ CI در انتظار؛ بدون تأیید Transport یا عملیات Production

## هدف و اعتبار

P-03 مرز تحویلی را آزمایش می‌کند که پس از ثبت اتمیک Journal و Outbox در P-02 قرار دارد. رویداد منبع تغییرناپذیر است و وضعیت تحویل در جدول جداگانه و تغییرپذیر نگهداری می‌شود. این آزمایش Claim مبتنی بر Lease، Retry محدود، جلوگیری از تأیید توسط Worker منقضی و Deduplication سمت Consumer را بررسی می‌کند. این کار پلتفرم پیام‌رسانی Production یا ادعای تحویل دقیقاً یک‌بار نیست.

## برش پیاده‌سازی‌شده

- رویدادهای منبع Outbox تغییرناپذیر و جدول مستقل وضعیت تحویل.
- استخراج هویت Tenant از session_user دیتابیس PostgreSQL و نگاشت خصوصی Role؛ Tenant ID ارسالی Caller پذیرفته نمی‌شود.
- توابع SECURITY DEFINER برای Claim/Ack/Nack/Consume با مالک NOLOGIN، غیر Superuser و غیر BYPASSRLS؛ به‌همراه FORCE ROW LEVEL SECURITY محدود به Tenant.
- عملیات کوتاه Claim با FOR UPDATE SKIP LOCKED، محدودیت اندازه Batch و مدت Lease، شمارنده تلاش و Lease Token جدید.
- تأیید فقط با Lease Token جاری و منقضی‌نشده؛ Worker قدیمی نمی‌تواند Lease جایگزین را تأیید کند.
- وضعیت Retry با تعداد تلاش محدود و وضعیت نهایی dead.
- Inbox تغییرناپذیر Consumer با کلید (tenant_id, consumer_name, event_id)؛ ثبت Receipt و اثر ساختگی Consumer در یک تراکنش دیتابیس Commit می‌شوند.
- Helperهای Relay در Node.js، Fixture مربوط به PostgreSQL 18.7، Node 26.13.0، وابستگی pg نسخه ثابت، Lockfile و Workflow دارای SHA ثابت.

## سناریوهای پذیرش

| شناسه | سناریو | Invariant مورد انتظار |
|---|---|---|
| P03-OUTBOX-01 | Tenant A در حالی Claim می‌کند که Tenant B رویداد معلق دارد | عدم افشای رویداد بین Tenantها |
| P03-OUTBOX-02 | دو Worker هم‌زمان Claim می‌کنند | Claimهای مجزا؛ بدون Lease فعال هم‌زمان برای یک رویداد |
| P03-OUTBOX-03 | تأیید با Token اشتباه یا تکراری | رد شود؛ فقط Lease جاری به Published برسد |
| P03-OUTBOX-04 | Lease منقضی و توسط Worker دیگر بازیابی شود | Token جدید، Worker قدیمی را Fence کند |
| P03-OUTBOX-05 | Retry به سقف تلاش برسد | رویداد Dead شود و دیگر Claim نشود |
| P03-OUTBOX-06 | تحویل مجدد هم‌زمان به Consumer | یک Inbox Receipt و یک اثر ساختگی |
| P03-OUTBOX-07 | فرایند پس از Publish و پیش از Ack متوقف شود | تحویل مجدد ممکن باشد؛ اثر Consumer Deduplicate شود |
| P03-OUTBOX-08 | Publish به Broker خطا دهد | رویداد Nack و Retry شود، نه اینکه Published اعلام شود |
| P03-OUTBOX-09 | Runtime یک Tenant مستقیماً جدول تحویل را بخواند | Permission Denied |
| P03-OUTBOX-10 | پارامتر Claim یا Consumer نامعتبر باشد | خطای اعتبارسنجی قطعی |

## معنای تحویل و محدودیت‌ها

Relay از الگوی At-least-once استفاده می‌کند، نه Exactly-once. Publish بیرونی و تأیید دیتابیس را نمی‌توان با همین تراکنش دیتابیس اتمیک کرد. توقف فرایند پس از پذیرش پیام توسط Broker و پیش از ثبت Ack می‌تواند به Publish مجدد منجر شود. Event ID پایدار، کلید Deduplication سمت Consumer است.

Broker ساختگی In-memory فقط پنجره Crash را نمایش می‌دهد؛ دوام Broker، رفتار شبکه، ترتیب Partition یا تضمین Provider را اثبات نمی‌کند. Consumer واقعی باید Inbox Receipt و اثر تجاری خودش را در همان تراکنش Commit کند یا از Outbox/Saga مستقل استفاده کند. Deduplication، اثرات خارجی دلخواه را Exactly-once نمی‌کند.

CDC/Debezium، Kafka/SQS، Broker بیرونی، اتصال Provider، اعتبارنامه Relay سراسری بین Tenantها، Retention/Replay در Production، تکامل Schema، Observability، SLO، مدیریت کلید یا بازیابی عملیاتی پیاده‌سازی یا تصویب نشده‌اند. از هویت Runtime مستقل برای هر Tenant استفاده شده و عمداً اختیار سراسری Relay ایجاد نشده است.

## اجرای مجدد

از مسیر prototypes/p03-outbox-delivery با Docker و Node.js 26.13.x:

    docker compose -f compose.yaml up -d --wait
    export ADMIN_DATABASE_URL='postgres://postgres:p03-admin-only-not-production@127.0.0.1:55434/lottorito_p03'
    export TENANT_A_DATABASE_URL='postgres://tenant_a_outbox_runtime:p03-tenant-a-not-production@127.0.0.1:55434/lottorito_p03'
    export TENANT_B_DATABASE_URL='postgres://tenant_b_outbox_runtime:p03-tenant-b-not-production@127.0.0.1:55434/lottorito_p03'
    npm ci --ignore-scripts --no-audit --no-fund
    npm test
    docker compose -f compose.yaml down

دیتابیس Compose دورریختنی است. این اسکریپت‌ها را به دیتابیس مشترک، Staging یا Production متصل نکن. اسکریپت Setup نقش‌ها و Schema آزمایشی را ایجاد می‌کند و برای Container محلی تازه در نظر گرفته شده است.

## ثبت نتیجه

CI مربوط به PR شماره ۵۰ در انتظار است. هیچ سناریویی تا زمان بررسی Logهای Workflow موفق اعلام نشود. این Prototype آمادگی Production یا صحت مالی/حسابداری را اثبات نمی‌کند.

## منابع

- قفل‌گذاری SELECT و SKIP LOCKED در PostgreSQL 18: https://www.postgresql.org/docs/18/sql-select.html
- قفل‌گذاری صریح ردیف‌ها در PostgreSQL: https://www.postgresql.org/docs/18/explicit-locking.html
- راهنمای AWS درباره Transactional Outbox و Consumerهای Idempotent: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- مستندات Debezium Outbox Event Router: https://debezium.io/documentation/reference/stable/transformations/outbox-event-router.html
