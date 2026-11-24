# P-03 — نمونه تحویل رویداد و مدیریت خطای Provider

**شناسه سند:** LOT-PROT-P03-001 | **نسخه:** ۰.۳.۰ | **وضعیت:** CI مربوط به Prototype موفق؛ P-03 کامل همچنان جزئی است | **تاریخ بازبینی:** ۲۰۲۶-۱۱-۲۴

## هدف و مرز تصمیم

P-03 قابلیت دریافت و تحویل رویداد به‌صورت مستقل از Provider را که برای اتصال‌های Affiliate/Agent و Providerهای آینده لازم است بررسی می‌کند. تمرکز آن بر Webhook ورودی احرازشده، Replay و Duplicate، پردازش پایدار Inbox، Lease، Retry، Dead-letter، تحویل Webhook خروجی و Reconciliation است.

هیچ Partner یا Provider انتخاب یا متصل نشده است. مستندات واقعی API مربوط به RaidenBet، روش احراز هویت، قرارداد Event، Sandbox و Credentialهای مجاز آزمایش همچنان پیش‌نیاز ساخت Adapter واقعی هستند. HMAC این Prototype یک پیاده‌سازی ساختگی با الگوی امضای شبیه Standard Webhooks است و اثبات نمی‌کند هیچ Partner فعلی از آن پروتکل پشتیبانی می‌کند.

## برش آزمایشی پیاده‌سازی‌شده

- محدوده Installation از پیکربندی قابل‌اعتماد سمت سرور تأمین می‌شود. هویت Tenant، Product و Provider هرگز از Payload تحت کنترل Caller گرفته نمی‌شود.
- اعتبارسنجی امضای ورودی از بایت‌های دقیق Raw Request، شناسه Event و Timestamp تلاش امضاشده، HMAC-SHA-256، مقایسه Constant-time، پنجره محدود تازگی و چند Verification Key برای Rotation استفاده می‌کند.
- Secretهای ساختگی از قالب Base64 با پیشوند whsec_ استفاده می‌کنند. نگهداری و Rotation کلید Production از طریق KMS یا Secrets Manager پیاده‌سازی نشده است.
- اندازه Payload، اعتبار JSON، تطبیق Event ID امضاشده با Event ID داخل Payload و وجود Event Type پیش از پذیرش پایدار بررسی می‌شود.
- Payload اختصاصی Provider به یک Envelope استاندارد و فشرده با ساختار CloudEvents 1.0 تبدیل می‌شود. هویت Tenant در محدوده دیتابیس نگهداری می‌شود و داخل Context عمومی Event کپی نمی‌شود.
- Event ورودی پیش از پاسخ 202 به‌صورت پایدار در Inbox محدود به Tenant/Product ذخیره می‌شود. Hash بایت‌های دقیق Raw Body برای تشخیص Conflict نگهداری می‌شود؛ فقط Canonical Event در دیتابیس ذخیره می‌شود.
- تکرار همان Provider Event ID با Payload Hash یکسان، Duplicate محسوب می‌شود. همان ID با Payload Hash متفاوت، Conflict ایجاد می‌کند و پاسخ 409 می‌گیرد؛ ردیف اصلی بازنویسی نمی‌شود.
- Workerهای Inbox از Claim تراکنشی با FOR UPDATE SKIP LOCKED، Lease، شمارنده تلاش، رد Ack قدیمی، Retry نمایی محدود و وضعیت Dead-letter استفاده می‌کنند.
- Sequence اختیاری Provider ذخیره می‌شود، اما Prototype ترتیب سراسری یا ترتیب مبتنی بر Timestamp را فرض نمی‌کند.
- رکوردهای تحویل خروجی با هویت Tenant/Product/Endpoint/Event Idempotent هستند. Attemptها نوع پاسخ را ثبت می‌کنند؛ 2xx تکمیل می‌شود، کلاس‌های موقت منتخب Retry می‌شوند، 4xx دائمی Fail می‌شود و پس از پایان تلاش‌ها Dead-letter رخ می‌دهد.
- پیام خروجی با Helper امضای ساختگی قابل امضا است؛ هیچ درخواست شبکه‌ای ارسال نمی‌شود.
- View مربوط به Reconciliation، انتظار مستقل Event از Provider را با وضعیت Inbox مقایسه می‌کند و Event مفقود یا پردازش‌نشده را آشکار می‌سازد.
- RLS مربوط به Tenant/Product روی Inbox، Conflict، Expectation، Outbound Delivery و Delivery Attempt اعمال می‌شود.

## ماتریس پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P03-EVENT-01 | Event ورودی با امضای معتبر | ردیف پایدار Inbox و پاسخ 202 |
| P03-EVENT-02 | دستکاری Raw Body | رد شدن امضا |
| P03-EVENT-03 | Timestamp قدیمی یا آینده | رد شدن امضا |
| P03-EVENT-04 | امضای مفقود یا پشتیبانی‌نشده | رد درخواست |
| P03-EVENT-05 | کلید قبلی هنگام Rotation | فقط تا زمانی پذیرفته شود که کلید قبلی فعال است |
| P03-EVENT-06 | Event ID و Payload یکسان | پاسخ Duplicate به‌صورت Idempotent |
| P03-EVENT-07 | Event ID یکسان با Payload تغییرکرده | ثبت Conflict؛ حفظ ردیف اصلی |
| P03-EVENT-08 | جعل Tenant/Product در Payload | Installation قابل‌اعتماد مرجع نهایی باقی بماند |
| P03-EVENT-09 | Payload بزرگ، JSON نامعتبر یا Event ID نامنطبق | رد پیش از پذیرش پایدار |
| P03-EVENT-10 | Installation ناشناخته یا غیرفعال | رد درخواست |
| P03-EVENT-11 | Adapter اختصاصی Provider | تولید Envelope استاندارد CloudEvent |
| P03-EVENT-12 | Claim و تکمیل توسط Inbox Worker | Event پایدار به وضعیت Processed برسد |
| P03-EVENT-13 | Workerهای هم‌زمان Inbox | SKIP LOCKED، Claimهای مجزا برگرداند |
| P03-EVENT-14 | انقضای Lease و Ack قدیمی | تلاش جدید Claim شود؛ Worker قدیمی نتواند Ack کند |
| P03-EVENT-15 | تأخیر Retry | برنامه نمایی محدود اعمال شود |
| P03-EVENT-16 | رسیدن به حداکثر تلاش | Event به Dead-letter برود |
| P03-EVENT-17 | Reconciliation رویداد Provider | Event مورد انتظار مفقود/پردازش‌نشده آشکار شود |
| P03-EVENT-18 | Replay در هویت Outbound Event/Endpoint | Payload یکسان Delivery قبلی را برگرداند؛ تغییر Payload Conflict شود |
| P03-EVENT-19 | امضای Outbound | امضا در دوره Key Rotation معتبرسنجی شود |
| P03-EVENT-20 | کلاس‌های پاسخ HTTP در Outbound | پاسخ موقت Retry و پاسخ دائمی Fail شود |
| P03-EVENT-21 | انقضای Lease در Outbound | Ack فرستنده قدیمی رد شود |
| P03-EVENT-22 | نبود Tenant/Product Context | RLS هیچ ردیف Inbox نمایش ندهد |

## شواهد CI تأییدشده

- اجرای P-03 با شناسه [45418365951](https://github.com/tecpey/lottorito-platform/actions/runs/45418365951) روی Head شاخه PR یعنی 20f0903f4d996ed2b5fece6730b53f908579ddfd موفق شد: ۲۲ تست موفق، صفر شکست و صفر Skip؛ با npm ci، Lockfile ثبت‌شده، Node.js 26.13.0 و PostgreSQL 18.7.
- اجرای Documentation Governance با شناسه [45418367980](https://github.com/tecpey/lottorito-platform/actions/runs/45418367980) روی Head مستندات دوزبانه موفق شد.
- اجرای محلی یا اتصال واقعی به Provider انجام نشده است. موفقیت CI فقط سناریوهای ساختگی تعریف‌شده را اثبات می‌کند.

## اجرای محلی و بازتولیدپذیری

فقط از دیتابیس محلی دورریختنی استفاده کنید. اسکریپت Setup جدول‌های Fixture مربوط به P-03 را حذف و دوباره ایجاد می‌کند؛ هرگز آن را به دیتابیس مشترک، Staging یا Production متصل نکنید.

    cd prototypes/p03-provider-event-delivery
    docker compose up -d
    export ADMIN_DATABASE_URL='postgres://postgres:p03-admin-only-not-production@127.0.0.1:55434/lottorito_p03'
    export RUNTIME_DATABASE_URL='postgres://event_runtime:p03-runtime-not-for-production@127.0.0.1:55434/lottorito_p03'
    npm ci --ignore-scripts --no-audit --no-fund
    npm test
    docker compose down -v

تمام Keyها، هویت‌ها، Payloadها و داده‌ها ساختگی هستند.

## محدودیت‌های امنیتی و عملیاتی

- Prototype یک روش HMAC شبیه Standard Webhooks را آزمایش می‌کند، نه تمام پروتکل‌های امضای اختصاصی Providerها را. هر Adapter واقعی باید دقیقاً از قرارداد امضای Partner پیروی کند و با Fixtureهای رسمی آن آزمایش شود.
- HTTP Server/Router، API Gateway، WAF، IP Allowlist، پیکربندی mTLS، KMS/Secrets Manager Production، Workflow ابطال کلید یا Broker خارجی وجود ندارد.
- Outbound Sender فقط یک State Machine است و اتصال شبکه برقرار نمی‌کند. DNS Rebinding، SSRF، Allowlist مقصد، سیاست Redirect، اعتبارسنجی TLS، محدودیت Response Body و Network Timeout هنوز آزمایش نشده‌اند.
- پاسخ 202 فقط پس از Commit شدن Inbox برگردانده می‌شود. تحویل و پردازش At-least-once هستند؛ Exactly-once ادعا نمی‌شود. اثرات مالی پایین‌دستی باید از Idempotency مربوط به Business Effect در P-02 استفاده کنند.
- طبقه‌بندی Retry و محدودیت‌ها پیش‌فرض ساختگی هستند؛ رفتار واقعی Retry، Retry-After، Rate Limit و سیاست غیرفعال‌سازی باید برای هر قرارداد Provider جداگانه توافق شود.
- Sequence اختیاری Provider ثبت می‌شود، اما برای استنتاج ترتیب Event استفاده نمی‌شود. Timestamp به‌تنهایی تضمین ترتیب نیست.
- Reconciliation از ردیف‌های Expected Event ساختگی استفاده می‌کند، نه API یا صورت‌حساب Provider.
- هیچ ادعایی درباره Load، Chaos، Failover، Disaster Recovery، Retention حریم خصوصی، بازبینی حقوقی یا آمادگی Production وجود ندارد. P-03 کامل همچنان جزئی است.

## منابع تحقیق

- OWASP — [Webhook Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Webhook_Security_Cheat_Sheet.html): امضای Raw Body، Replay Protection، مدیریت Duplicate، Rate Limiting، پاسخ Fail-secure و Logging حساس.
- Standard Webhooks — [مشخصات امضای Webhook](https://github.com/standard-webhooks/standard-webhooks/blob/main/spec/standard-webhooks.md): امضای Message ID/Timestamp/Body، اعتبارسنجی Constant-time، تازگی Timestamp و Key Rotation بدون Downtime.
- IETF — [RFC 9421 HTTP Message Signatures](https://www.rfc-editor.org/rfc/rfc9421.html): امضای استاندارد اجزای HTTP، الزامات Componentهای امضاشده، Key Identifier، Timestamp و مقابله با Replay با Nonce. P-03 ادعای پیاده‌سازی RFC 9421 ندارد.
- CloudEvents — [مشخصات اصلی](https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md) و [قالب JSON Event](https://github.com/cloudevents/spec/blob/main/cloudevents/formats/json-format.md): Attributeهای Context استاندارد و جداسازی Data.
- AWS Prescriptive Guidance — [الگوی Transactional Outbox](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html): ذخیره‌سازی اتمیک، تحویل At-least-once و Consumerهای Idempotent.
- Stripe — [مدیریت Webhook Endpointها](https://docs.stripe.com/webhooks): اعتبارسنجی امضا با Raw Request Body، Event تکراری و رفتار تحویل اختصاصی Provider. این فقط نمونه مرجع است، نه انتخاب Provider.
- PostgreSQL 18 — [قفل‌گذاری در SELECT](https://www.postgresql.org/docs/18/sql-select.html): رفتار SKIP LOCKED برای Claim چندمصرف‌کننده‌ای شبیه Queue.

## جایگاه در زنجیره تغییرات

این PR روی شاخه P-02 با نام spike/p02-financial-ledger قرار می‌گیرد. PR شماره ۳۸ را Merge نمی‌کند، شاخه main را تغییر نمی‌دهد، Deploy انجام نمی‌دهد و به RaidenBet یا هیچ Provider خارجی متصل نمی‌شود.
