# کارگزار اعتبارنامه Tenant و Connection Pool محدود در P-01

**شناسه سند:** LOT-PROT-P01-POOL-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** Prototype ساختگی؛ تأیید CI در انتظار

## هدف

آزمایش Registry محدودکننده Connection Pool برای اعتبارنامه‌های PostgreSQL مستقل هر Tenant و متصل به هویت دیتابیس. این کار ادامه LOT-PROT-P01-001 و LOT-PROT-P01-DATA-001 است. هدف بررسی این است که آیا هویت Session دیتابیس می‌تواند اتصال را به یک Tenant مشخص متصل کند، بدون آن‌که به Custom GUC قابل‌کنترل توسط Caller متکی باشیم.

## آزمایش پیاده‌سازی‌شده

- Registry فقط UUID مربوط به Tenant را که سمت سرور Resolve شده می‌پذیرد و درخواست‌های هم‌زمان برای ساخت Pool یک Tenant را ادغام می‌کند.
- Credential Resolver مورداعتماد، شناسه Tenant را به Connection String اختصاصی همان Tenant نگاشت می‌کند. Registry، Connection String ارسالی از Request را نمی‌پذیرد.
- برای هر Pool سقف تعداد Connection تعیین می‌شود و Application Name دارای برچسب Tenant است، بدون آن‌که Credential در آن قرار گیرد.
- سقف سراسری تعداد Poolها از ایجاد نامحدود Pool برای Tenantها جلوگیری می‌کند. در زمان پر بودن ظرفیت فقط Pool بدون Lease قابل حذف است؛ اگر همه Poolها فعال باشند، دریافت اتصال با خطای ظرفیت مشخص و به‌صورت Fail-Closed رد می‌شود.
- حذف Poolهای Idle بر اساس TTL و نیز حذف LRU از میان Poolهای Idle پشتیبانی می‌شود.
- لغو دسترسی Tenant فوراً Leaseهای جدید را مسدود می‌کند و پیش از بستن Pool، اجازه می‌دهد Lease فعال قبلی تخلیه شود.
- Shutdown Registry دریافت Lease جدید را مسدود، Poolها را بازنشسته و ساخت‌های درحال‌انجام را منتظر می‌ماند؛ Poolهای Idle بسته می‌شوند و Pool مربوط به Lease فعال پس از آزادشدن آن بسته خواهد شد.
- Connection Stringهای ساختگی Tenant A و Tenant B با Roleهای مستقل PostgreSQL از نوع LOGIN احراز هویت می‌شوند. RLS هویت session_user را به دقیقاً یک Tenant نگاشت می‌کند.

## سناریوهای پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P01-POOL-01 | دو Tenant درخواست Pool می‌کنند | هرکدام با Role دیتابیسی خودش احراز هویت شود و فقط Tenant متناظر را ببیند |
| P01-POOL-02 | درخواست‌های هم‌زمان برای یک Tenant | فقط یک بار Credential Resolve و Pool ساخته شود |
| P01-POOL-03 | محدودیت Connection هر Pool | Factory مقدار حداکثر تنظیم‌شده را دریافت کند |
| P01-POOL-04 | ظرفیت Registry پر و همه Poolها دارای Lease باشند | دریافت Tenant جدید Fail-Closed رد شود و Pool فعال حذف نشود |
| P01-POOL-05 | ظرفیت پر اما یک Pool بدون Lease باشد | Pool Idle با قدیمی‌ترین استفاده بسته شود و سپس Pool جدید ساخته شود |
| P01-POOL-06 | لغو Credential یک Tenant | Lease جدید رد شود و Lease فعال پیش از بستن Pool تخلیه شود |
| P01-POOL-07 | شکست Credential Resolver | خطای پاک‌سازی‌شده بدون افشای جزئیات Credential به Caller برسد |
| P01-POOL-08 | پایان TTL مربوط به Pool Idle | Pool بسته و از Registry حذف شود |
| P01-POOL-09 | Shutdown Registry | Lease جدید مسدود و Poolهای Idle بسته شوند |

## مدل امنیتی و پرسش‌های باز طراحی

- Credential Resolver یک مؤلفه مورداعتماد در Control Plane است. باید Caller را مستقل احراز هویت کند، عضویت Tenant را از منبع معتبر سمت سرور Resolve کند، Secretها را از Secret Store مدیریت‌شده بخواند و هرگز Tenant ID یا Connection String ارسالی Caller را مبنای مجوز قرار ندهد.
- اعتبارنامه مستقل هر Tenant، مرز هویت دیتابیسی قوی‌تری از Role مشترک برنامه همراه Custom GUC قابل‌تنظیم توسط کاربر فراهم می‌کند. این مدل در برابر Compromise شدن Credential Broker، Secret Store، Process برنامه یا مدیر دارای امتیاز دیتابیس محافظت کامل نمی‌کند.
- طراحی Production باید تکثیر تعداد Connectionها (تعداد Tenant × حداکثر Pool × تعداد Replica سرویس)، محدودیت Connection در PostgreSQL، سازگاری PgBouncer، چرخش/لغو Credential، اعتبارسنجی TLS، Cache کردن Secret، Failover، تعلیق Tenant، گرم‌کردن Pool، صف و Back-pressure و Observability را ارزیابی کند.
- این Prototype از Connection Stringهای ساختگی محلی و Registry کوچک درون یک Process استفاده می‌کند. Secret Manager عملیاتی، ساخت پویای Role، PgBouncer، چرخش Credential، لغو توزیع‌شده، هماهنگی چند Process یا Failover عملیاتی را پیاده‌سازی نمی‌کند.
- Registry به Process محدود است. در چند Replica برنامه، تعلیق/لغو Tenant و بودجه کل Connectionها نیازمند هماهنگی سراسری است.
- مدل فعلی app_runtime مشترک همراه Custom GUC در برابر Credential دیتابیسی برنامه‌ای که Compromise شده و SQL دلخواه اجرا کرده و Custom GUC خود را تغییر دهد، آسیب‌پذیر است. Query پارامتری ریسک Injection را کاهش می‌دهد، اما Custom GUC قابل‌تنظیم توسط Role برنامه را به مرز امنیتی سخت تبدیل نمی‌کند. نباید ادعا شود این مدل در برابر Compromise کامل Role برنامه محافظت می‌کند.
- Role مستقل برای هر Tenant صرفاً یک آزمایش است، نه معماری انتخاب‌شده. در مقیاس بالای Tenantها، مدیریت Role به‌ازای هر Tenant ممکن است پرهزینه شود؛ گزینه‌هایی مانند Connection Broker مورداعتماد، یکپارچگی احراز هویت PgBouncer، Database-per-tenant یا Schema-per-tenant باید با معیارهای قابل‌اندازه‌گیری مقایسه شوند.

## وضعیت شواهد

کد یک آزمایش ساختگی و قابل‌دورریختن است. نتیجه CI و Integration تا زمان مشاهده اجرای واقعی در انتظار است. هیچ آمادگی Production، Provider مدیریت Credential، Pooler یا معماری Tenancy تصویب نشده است.
