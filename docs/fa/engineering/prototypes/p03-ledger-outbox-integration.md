# P-03C — اتصال انتهابه‌انتها Outbox مالی به تحویل رویداد Tenant-scoped

**شناسه سند:** LOT-PROT-P03C-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** آزمایش یکپارچه‌سازی ساختگی؛ شواهد CI در PR پیش‌نویس شماره ۶۰ پیگیری می‌شود؛ بدون تصویب Transport یا عملیات Production

## ۱. هدف و مرزبندی

P-02 یک Journal دوبل‌انتری تغییرناپذیر و یک رکورد تغییرناپذیر در public.ledger_outbox را به‌صورت اتمیک ثبت می‌کند. P-03 به‌صورت مستقل Lease، Retry، مهار Worker قدیمی و اثر Idempotent سمت Consumer را اثبات می‌کند. P-03C این دو مرز آزمایش‌شده را در یک دیتابیس PostgreSQL موقت به هم متصل می‌کند.

Invariant اصلی این است که ledger_outbox متعلق به P-02، **تنها منبع تغییرناپذیر رویداد** باقی بماند. P-03C جدول Source Outbox دوم نمی‌سازد و Payload را در جدول منبع دیگری کپی نمی‌کند. یک Trigger دیتابیس، ردیف اولیه وضعیت تحویل را در همان تراکنشی ایجاد می‌کند که رویداد Ledger Outbox را درج می‌کند. وضعیت تحویل و رسیدهای Consumer همچنان رکوردهای عملیاتی جداگانه با RLS مختص Tenant هستند.

این یک آزمایش یکپارچه‌سازی ساختگی است، نه پلتفرم رویداد Production. Broker خارجی، Endpoint واقعی Provider، سرویس Consumer واقعی، CDC، Policy عملیاتی Retry یا تحویل Exactly-once پیاده‌سازی نمی‌شود.

## ۲. طراحی و مالکیت

- **منبع مالی:** P-02 مالک Posting ژورنال، هویت Effect، خطوط تغییرناپذیر Journal و ردیف‌های تغییرناپذیر ledger_outbox است.
- **وضعیت تحویل:** P-03C مالک outbox_delivery_state با کلید (tenant_id, event_id) و وضعیت Lease، Attempt، Retry، Published و Dead-letter است.
- **پل اتمیک:** یک Trigger از نوع AFTER INSERT روی ledger_outbox، ردیف اولیه وضعیت تحویل Pending را در همان تراکنش دیتابیس ایجاد می‌کند. اگر Trigger یا بررسی RLS آن شکست بخورد، کل تراکنش Posting مالی شکست می‌خورد.
- **هویت Tenant:** از private.tenant_role_map و private.current_tenant_id موجود در P-02 استفاده می‌شود و Scope از PostgreSQL session_user استخراج می‌شود. Tenant ID ورودی کاربر یا Role Map دوم ایجاد نمی‌شود.
- **اختیار اجرا:** نقش outbox_executor از نوع NOLOGIN، غیرSuperuser و NOBYPASSRLS است. توابع SECURITY DEFINER آن Search Path ثابت و Grant محدود دارند. Trigger تطبیق Tenant رکورد منبع با Tenant نشست دیتابیس را بررسی می‌کند.
- **تحویل:** Claim از FOR UPDATE SKIP LOCKED، Batch/Lease محدود، Token جدید و شمارنده Attempt استفاده می‌کند. Ack/Nack به Token معتبر و منقضی‌نشده فعلی نیاز دارند. پایان Retry به وضعیت Dead منتهی می‌شود.
- **Consumer:** consumer_inbox و consumer_effects از Event ID پایدار و Tenant Scope استفاده می‌کنند. درج Inbox Receipt و Effect ساختگی در یک تراکنش تابع دیتابیس انجام می‌شود؛ Receipt تکراری مقدار false برمی‌گرداند و Effect را تکرار نمی‌کند.
- **معنای At-least-once:** انتشار Broker و تأیید دیتابیس اتمیک نیستند. Crash پس از Publish و پیش از Ack می‌تواند Redelivery ایجاد کند. Deduplication با Event ID پایدار از Effect دیتابیسی تکراری جلوگیری می‌کند؛ ادعای تحویل Exactly-once شبکه‌ای نداریم.

## ۳. Fixture اجرایی

- prototypes/p03-ledger-outbox-integration/db/integration.sql: وضعیت تحویل P-03C، جدول‌های Consumer، RLS، Trigger و توابع Security Definer؛ مستقیماً به ledger_outbox در P-02 ارجاع می‌دهد.
- scripts/setup-db.js: Schema مربوط به P-02 و سپس SQL یکپارچه‌سازی P-03C را در دیتابیس موقت اجرا و وجود تنها یک Source Outbox و شش حساب Seedشده را بررسی می‌کند.
- src/relay.js: توابع Tenant-bound برای Claim، Ack، Nack، Consume و تحویل Batch.
- test/integration.test.js: پانزده سناریوی مثبت و خصمانه انتهابه‌انتها.
- compose.yaml: Fixture محلی PostgreSQL 18.7.
- package.json/package-lock.json: نسخه‌های Node.js 26.13.x و pg 8.23.1 قفل‌شده.
- .github/workflows/p03-ledger-outbox-integration.yml: CI با PostgreSQL 18.7 و Node.js 26.13.0.

Schema مربوط به P-02 و Schema یکپارچه‌سازی P-03C در یک دیتابیس اجرا می‌شوند. Fixture اصلی Outbox در P-03 همچنان برای تست مستقل Delivery State مفید است؛ این P-03C اتصال مفقود آن به Schema واقعی ledger_outbox در P-02 را اثبات می‌کند.

## ۴. معیارهای پذیرش

| شناسه | نتیجه الزامی |
|---|---|
| P03C-01 | فراخوانی موفق post_journal در P-02 دقیقاً یک ردیف ledger_outbox و یک ردیف Pending وضعیت تحویل ایجاد کند. |
| P03C-02 | Payload رویداد منبع، journal_id، effect_id و source_event_id مربوط به P-02 را حفظ کند. |
| P03C-03 | ردیف وضعیت تحویل با Trigger و در همان تراکنش درج ledger_outbox ایجاد شود. |
| P03C-04 | Rollback تراکنش Posting، Journal، رویداد منبع و وضعیت تحویل را با هم حذف کند. |
| P03C-05 | Replay با Idempotency، Journal اصلی را برگرداند و Event یا Delivery Row تکراری ایجاد نکند. |
| P03C-06 | Request Key دوم برای همان Financial Effect، رویداد Ledger دوم ایجاد نکند. |
| P03C-07 | P-03C فقط از ledger_outbox در P-02 به‌عنوان Source تغییرناپذیر استفاده کند؛ جدول تکراری outbox_events وجود نداشته باشد. |
| P03C-08 | Tenant A نتواند Event مالی Tenant B را Claim، Read یا Consume کند. |
| P03C-09 | Workerهای هم‌زمان Eventهای مجزا Claim کنند؛ Lease Token قدیمی نتواند Lease جایگزین را Ack کند. |
| P03C-10 | پایان Retry، Event را به وضعیت Dead-letter منتقل کند. |
| P03C-11 | Inbox و Effect ساختگی Consumer در Redelivery هم‌زمان فقط یک‌بار Commit شوند. |
| P03C-12 | شبیه‌سازی Crash میان Publish و Ack، Redelivery از نوع At-least-once و تنها یک Consumer Effect را نشان دهد. |
| P03C-13 | هویت Runtime مربوط به Tenant نتواند مستقیماً جدول‌های Ledger، Delivery State یا Consumer را بخواند یا تغییر دهد. |
| P03C-14 | هویت دیتابیس بدون Mapping و پارامترهای نامعتبر Claim/Consumer به‌صورت Fail-closed رد شوند. |
| P03C-15 | Trigger در صورت نبود Tenant نگاشت‌شده برای نشست دیتابیس، درج Source را رد کند؛ هیچ Event یا Delivery Row ثبت نشود. |

## ۵. روش بازتولید

از ریشه مخزن:

~~~bash
cd prototypes/p03-ledger-outbox-integration
docker compose up -d --wait
export ADMIN_DATABASE_URL='postgres://postgres:p03c-admin-only-not-production@127.0.0.1:55435/lottorito_p03c'
export TENANT_A_DATABASE_URL='postgres://tenant_a_ledger_runtime:p02-tenant-a-not-for-production@127.0.0.1:55435/lottorito_p03c'
export TENANT_B_DATABASE_URL='postgres://tenant_b_ledger_runtime:p02-tenant-b-not-for-production@127.0.0.1:55435/lottorito_p03c'
npm ci --ignore-scripts --no-audit --no-fund
npm test
docker compose down -v
~~~

اسکریپت Setup فقط Objectهای Fixture مربوط به P-02/P-03C را حذف و بازسازی می‌کند. فقط از دیتابیس محلی موقت استفاده کنید؛ هرگز آن را به داده Shared، Staging یا Production متصل نکنید.

## ۶. محدودیت‌های صریح

- Broker واقعی، Provider، HTTP Server، API Gateway، اتصال CDC، Queue Service، Consumer خارجی یا تحویل شبکه‌ای وجود ندارد.
- دریافت Webhook مربوط به Provider در PR شماره ۴۱، یک Slice ساختگی جداگانه است؛ این آزمایش Callback ورودی Provider را به Posting در P-02 متصل نمی‌کند.
- P-03C از هویت‌های Runtime و Role Map موجود در P-02 استفاده می‌کند؛ Relay سراسری بین Tenantها یا مدل هویت سرویس Production را اثبات نمی‌کند.
- Consumer Effect یک ردیف دیتابیسی ساختگی است، نه Projection، Notification، Payout، Commission یا Side Effect خارجی.
- تحویل At-least-once است. Publish در Broker و Ack در PostgreSQL اتمیک نیستند؛ Consumer خارجی باید با Event ID پایدار Deduplicate کند و Inbox/Effect را اتمیک Commit کند.
- Retry، Batch Size و Lease Duration مقادیر Fixture هستند، نه SLA Provider یا Policy Production.
- تست Load/Chaos، Retention، مدیریت کلید، Observability، Failover، Disaster Recovery، بررسی حقوقی یا آمادگی Production ادعا نمی‌شود.
- هیچ فرمول کمیسیون، قاعده NGR، Wallet Balance، Payout یا Settlement بین محصولات وارد نشده است.
- موفقیت P-03C فقط شکاف اتصال Outbox مالی P-02 به Delivery State در P-03 را در Fixture ساختگی می‌بندد؛ تمام شکاف‌های Production در P-01/P-02/P-03 بسته نمی‌شوند.

## ۷. مراجع پژوهش

- PostgreSQL 18، [قفل‌گذاری SELECT و SKIP LOCKED](https://www.postgresql.org/docs/18/sql-select.html).
- PostgreSQL 18، [سیاست‌های Row-Level Security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html).
- AWS Prescriptive Guidance، [الگوی Transactional Outbox](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html).
- CloudEvents، [مشخصات اصلی](https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md).

## ۸. دروازه تکمیل

P-03C فقط زمانی تکمیل است که Head دقیق PR دارای Integration موفق با PostgreSQL 18.7 و Node.js 26.13.0 و Documentation Governance موفق باشد، تمام سناریوهای مثبت و منفی با صفر Skip عبور کنند، هم‌ارزی معنایی نسخه‌های فارسی و انگلیسی بازبینی شود و محدودیت‌ها صریح باقی بمانند. موفقیت این آزمایش مجوز Merge، Deploy در Production یا انتخاب فناوری نیست.
