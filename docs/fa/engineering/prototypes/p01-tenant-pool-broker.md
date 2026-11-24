# رجیستری Credential و Connection Pool برای هر Tenant در P-01

**شناسه سند:** LOT-PROT-P01-POOL-001 | **نسخه:** ۰.۳.۰ | **وضعیت:** Prototype ساختگی؛ ۴۰ تست CI موفق؛ کنترل‌های Production تأییدنشده

## هدف

آزمایش اینکه آیا مدل قوی‌تر جداسازی PostgreSQL با LOGIN/session_user مستقل برای هر Tenant، از طریق رجیستری محدود Credential و Connection Pool در سمت برنامه قابل استفاده است، بدون آنکه Poolهای نامحدود ایجاد شوند یا Pool فعال از سرویس خارج شود.

این آزمایش فقط از Credential و Role ساختگی PostgreSQL استفاده می‌کند؛ Secret Broker عملیاتی، اتصال Vault یا سرویس مدیریت Connection در Production نیست.

## کنترل‌های پیاده‌سازی‌شده

- هویت Tenant پیش از Credential Lookup اعتبارسنجی و Canonicalize می‌شود.
- Resolve کردن Credential از طریق Provider تابعی سمت سرور انجام می‌شود؛ ورودی Caller هرگز Connection String یا Database Role را تعیین نمی‌کند.
- Credential Lookup و Pool Creation برای درخواست‌های هم‌زمان یک Tenant، Coalesce می‌شوند.
- پیش از انتشار یا اعطای Lease، Pool تازه‌ساخته‌شده یک Query ثابت هویت اجرا می‌کند و تطابق `private.current_tenant_id()` با Tenant درخواستی را بررسی می‌کند؛ Credential نامنطبق رد و Pool آن بسته می‌شود.
- هر Pool حداکثر تعداد Connection مشخص دارد؛ خود Registry نیز حداکثر تعداد Poolهای Tenant را محدود می‌کند.
- در زمان پرشدن ظرفیت، فقط Pool بیکار با کمترین زمان استفاده اخیر قابل Evict است. اگر همه Poolها فعال باشند، Acquisition با خطای ظرفیت نوع‌دار و به‌صورت Fail-closed رد می‌شود.
- Poolهای بیکار پس از TTL از طریق Sweep قطعی قابل Evict هستند.
- لغو Tenant فوراً Lease جدید را رد می‌کند و پیش از بستن Pool، Leaseهای فعال و Leaseهای رزروشده را تخلیه می‌کند.
- Shutdown رجیستری Idempotent است و تا پایان تمام Leaseهای فعال منتظر می‌ماند.
- خطاهای Credential Resolution و Pool Creation پاک‌سازی می‌شوند؛ Connection String در پیام خطا برگردانده نمی‌شود.
- تست یکپارچه‌سازی از Credentialهای واقعیِ ساختگی PostgreSQL برای LOGIN مستقل هر Tenant استفاده می‌کند و session_user و private.current_tenant_id() را بررسی می‌کند.

## سناریوهای پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P01-POOL-01 | Acquisition هم‌زمان برای یک Tenant | فقط یک Credential Lookup و یک Pool Creation انجام شود |
| P01-POOL-02 | Tenant A و B Pool می‌گیرند | Database Role و هویت Tenant متفاوت باشد |
| P01-POOL-03 | محدودیت Per-pool و Global Pool فعال می‌شود | سقف‌ها اعمال شوند |
| P01-POOL-04 | Registry پر است و تمام Poolها Lease فعال دارند | Acquisition با Fail-closed رد شود؛ Pool فعال Evict نشود |
| P01-POOL-05 | Registry پر است و Pool بیکار وجود دارد | Pool بیکار با کمترین زمان استفاده اخیر پیش از جایگزینی بسته شود |
| P01-POOL-06 | Credential Tenant در زمان Lease فعال لغو می‌شود | Lease جدید رد و Lease فعال پیش از بستن Pool تخلیه شود |
| P01-POOL-07 | Pool به Idle TTL می‌رسد | Sweep قطعی Pool بیکار را ببندد |
| P01-POOL-08 | Provider Credential خطایی حاوی Secret برمی‌گرداند | Caller خطای پاک‌سازی‌شده و بدون Secret دریافت کند |

## محدودیت‌های صریح

- Credentialها مقادیر ساختگی محیطی‌اند. Vault، Cloud Secret Manager، KMS، API چرخش Credential، Certificate Auth، Workload Identity یا چرخه عمر Secret عملیاتی متصل نشده است.
- وضعیت Registry فقط در Process محلی است. هماهنگی Multi-process/Multi-region، Quota سراسری Fleet، انتشار لغو Credential، Eviction توزیع‌شده و Failover پیاده‌سازی نشده‌اند.
- نسخه Credential برای Diagnostics ثبت می‌شود، اما Rotation بدون قطعی و تخلیه هم‌زمان Pool قدیم/جدید پیاده‌سازی نشده است.
- Callback رجیستری، کد مورداعتماد برنامه است؛ Caller نباید Pool یا Client را فراتر از Callback Lease نگه دارد.
- Connection Churn، بار واقعی، سازگاری PgBouncer، Failover، تغییر DNS، TLS Policy و مقیاس تعداد Tenantها Benchmark نشده‌اند.
- مدل مشترک app_runtime با custom-GUC همچنان جایگزین ضعیف‌تری است و مرز اعتماد مستندشده خود را دارد.

## وضعیت شواهد

اجرای P-01 در PR شماره ۴۵ با شناسه [45424342187](https://github.com/tecpey/lottorito-platform/actions/runs/45424342187) روی Head کد `5a9b18a0a1cd121ff89223fe5829c8975acbfe87` با ۴۰ تست موفق، صفر شکست و صفر Skip همراه بود. اجرای Documentation Governance با شناسه [45424342166](https://github.com/tecpey/lottorito-platform/actions/runs/45424342166) نیز موفق شد. این نتیجه فقط Prototype ساختگی را اعتبارسنجی می‌کند؛ اجرای محلی، مدیریت Secret عملیاتی، چرخش Credential، Quota سراسری Fleet، PgBouncer، سیاست TLS، Failover و مقیاس هنوز تأییدنشده‌اند. هیچ توپولوژی PostgreSQL، Secret Manager، Pooler یا Deploy عملیاتی تصویب نشده است.
