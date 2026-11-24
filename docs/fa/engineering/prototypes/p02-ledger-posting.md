# ثبت سند دوطرفه محدود به Tenant در P-02

**شناسه سند:** LOT-PROT-P02-001 | **نسخه:** ۰.۶.۰ | **وضعیت:** Prototype ساختگی؛ Effect ID پایدار در Outbox منتشر می‌شود؛ CI نهایی در انتظار

## هدف و اعتبار

آزمایش کوچک‌ترین برش مالی معنادار پس از P-01: یک درخواست ثبت محدود به Tenant باید با وجود تحویل تکراری و هم‌زمان، دقیقاً یک Journal متوازن و تغییرناپذیر و یک رویداد Transactional Outbox ایجاد کند.

این یک آزمایش مهندسی است، نه سیاست حسابداری، مشخصات کمیسیون/NGR، طراحی نگهداری وجوه، مجوز پرداخت یا Ledger عملیاتی. هیچ وجه واقعی، داده مشتری، رویداد Provider یا فعالیت تسویه‌ای استفاده نمی‌شود.

## مدل پیاده‌سازی‌شده

- **هویت Tenant:** هویت LOGIN در PostgreSQL از طریق Identity Map محافظت‌شده دیتابیس به یک Tenant نگاشت می‌شود. Caller نمی‌تواند tenant_id، نام Role یا مالک حساب را تعیین کند.
- **مرز ثبت:** Roleهای Tenant فقط اجازه اجرای یک تابع ثابت SECURITY DEFINER را دارند؛ مجوز مستقیم SELECT/INSERT/UPDATE/DELETE روی جدول‌های Ledger ندارند. مالک تابع NOLOGIN، غیر Superuser و فاقد BYPASSRLS است؛ جدول‌ها FORCE ROW LEVEL SECURITY و Policy محدود به Tenant دارند.
- **Journal:** یک Journal ثبت‌شده حداقل دو Line دارد. هر Line شامل حساب متعلق به Tenant، کد ارز، جهت و مبلغ مثبت صحیح در واحد خرد است.
- **ناوردای توازن:** مجموع Debit و Credit باید برای هر ارز در همان Journal جداگانه برابر باشد. Debit دلاری نمی‌تواند با Credit ین جبران شود. Journal چندارزی فقط زمانی معتبر است که هر گروه ارزی مستقل توازن داشته باشد.
- **مبلغ دقیق:** مبلغ از API به‌صورت رشته ده‌دهی منتقل و در PostgreSQL با NUMERIC(38,0) ذخیره می‌شود؛ عدد ممیز شناور JavaScript رد می‌شود. این Prototype توان یا Exponent ارزها و تبدیل واحد اصلی به خرد را تعریف نمی‌کند.
- **Idempotency در دو سطح:** `(tenant_id, idempotency_key)` شناسه Retry در سطح API/انتقال است، در حالی که `(tenant_id, effect_id)` اثر مالی منطقی را مشخص می‌کند. هرکدام از این دو هویت به همان Journal اصلی می‌رسد؛ استفاده مجدد با محتوای اقتصادی متفاوت رد می‌شود. Fingerprint شامل Effect ID، Source Event ID و Lineهای نرمال‌شده است. تحویل‌های هم‌زمان با Request Key متفاوت اما Effect ID یکسان به یک Journal همگرا می‌شوند. یک Source Event می‌تواند چند Effect مستقل با شناسه‌های مجزا داشته باشد.
- **Outbox اتمیک:** Header، Lineها، رکورد Idempotency و رویداد ledger.journal.posted (شامل Journal ID، شناسه پایدار Effect و Source Event ID) در یک Statement/Transaction دیتابیس ساخته می‌شوند. ثبت ناموفق نباید هیچ‌یک از آن‌ها را Commit کند.
- **تغییرناپذیری:** Posting Request، Journal ثبت‌شده، Lineها و Outbox Event در برابر UPDATE و DELETE محافظت می‌شوند. اصلاحات باید در طراحی آینده به‌صورت Reversal/Compensating Entry انجام شوند؛ این آزمایش تاریخچه را تغییر نمی‌دهد.

## سناریوهای پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P02-LEDGER-01 | Journal دوخطی متوازن USD | یک Journal ثبت‌شده، دو Line دقیق و یک Outbox Event |
| P02-LEDGER-02 | همان Idempotency Key و همان درخواست | بازگشت Journal ID اصلی، بدون Journal یا Outbox تکراری |
| P02-LEDGER-03 | درخواست‌های تکراری هم‌زمان | دقیقاً یک Journal و یک Outbox Event |
| P02-LEDGER-04 | همان Key با محتوای متفاوت | تعارض قطعی Idempotency |
| P02-LEDGER-05 | Debit/Credit نامتوازن | رد شدن بدون باقی‌ماندن Request، Journal، Line یا Outbox ناقص |
| P02-LEDGER-06 | تلاش برای جبران بین دو ارز | رد شدن؛ هر ارز باید مستقل متوازن باشد |
| P02-LEDGER-07 | Journal چندارزی متوازن | فقط در صورت توازن مستقل تمام گروه‌های ارزی پذیرفته شود |
| P02-LEDGER-08 | مبلغ صحیح ۳۸ رقمی | بدون تغییر دقت ذخیره و بازیابی شود |
| P02-LEDGER-09 | ارجاع Tenant A به حساب Tenant B | رد عمومی بدون افشای حساب Tenant دیگر |
| P02-LEDGER-10 | استفاده دو Tenant از یک Idempotency Key | دو عملیات مستقل در محدوده Tenant خود |
| P02-LEDGER-11 | تلاش Role اجرایی Tenant برای دسترسی مستقیم به جدول | رد شود؛ فقط تابع محدود ثبت قابل اجرا باشد |
| P02-LEDGER-12 | UPDATE/DELETE روی رکورد ثبت‌شده | توسط Trigger تغییرناپذیری رد شود |
| P02-LEDGER-13 | هویت Session دیتابیس بدون نگاشت Tenant | پیش از هر اثر مالی رد شود |
| P02-LEDGER-14 | Float، مبلغ اعشاری، شماره Line تکراری یا فیلد اضافی | توسط اعتبارسنجی برنامه و دیتابیس رد شود |
| P02-LEDGER-15 | تحویل همان اثر مالی با Request Key متفاوت | Journal اصلی برگردد؛ ثبت دوم انجام نشود |
| P02-LEDGER-16 | درخواست‌های هم‌زمان با Key متفاوت و Effect ID یکسان | دقیقاً یک Journal و یک Outbox Event |
| P02-LEDGER-17 | استفاده مجدد از Effect ID با محتوای اقتصادی متفاوت | تعارض قطعی؛ بدون Journal دوم |
| P02-LEDGER-18 | یک Source Event با دو Effect ID مستقل | دو ثبت مستقل و معتبر |
| P02-LEDGER-19 | مالکیت، Search Path و مجوزهای SECURITY DEFINER | مالک NOLOGIN مورد اعتماد، مسیر امن ثابت و اجرای محدود به Tenant |
| P02-LEDGER-20 | رویداد Outbox شناسه پایدار Effect را حمل می‌کند | Consumer پایین‌دستی همان Effect ID سند را دریافت می‌کند |

## موارد خارج از محدوده و تصمیم‌های باز

- هیچ فرمول کمیسیون، تعریف NGR، Revenue Share، نحوه Bonus، Negative Carryover، سیاست Chargeback، سلسله‌مراتب Agent، نرخ کمیسیون یا زمان‌بندی Settlement تعریف یا فرض نشده است.
- هیچ Wallet/Balance Projection، وجه مشتری، سرمایه عملیاتی، اعتبار تبلیغاتی، برداشت، پرداخت یا Provider پرداخت پیاده‌سازی نشده است.
- هیچ نرخ FX، تبدیل ارز، سیاست Rounding، Registry توان ارز، دوره حسابداری، حاکمیت Chart of Accounts، مالیات یا بستن گزارش مالی تصویب نشده است.
- Full Reversal، Partial Reversal، گردش اصلاح، تطبیق Source Event با صورت‌حساب بیرونی Provider، رسیدگی اختلاف و سیاست رویدادهای خارج از ترتیب، آزمایش‌های آینده‌اند.
- Transactional Outbox با Journal اتمیک است، اما تحویل پیام در معماری توزیع‌شده باید At-least-once فرض شود؛ Consumer عملیاتی باید Idempotent و قابل Observability باشد. Queue، Relay، سیاست Retry/Dead-letter یا اثبات تحویل End-to-end در این Prototype وجود ندارد.
- تابع SECURITY DEFINER و Identity Mapping ساختگی‌اند. Threat Model عملیاتی، چرخه Secret، ساخت Role، مدیریت کلید، Backup/Restore، Disaster Recovery، عملکرد، Lock Contention و بازبینی مستقل امنیت همچنان لازم‌اند.
- `effect_id` مالی باید توسط یک مؤلفه بالادستی مورد اعتماد و بر اساس هویت پایدار عملیات کسب‌وکار تعیین شود. تولید UUID تصادفی جدید در هر بار تحویل، تضمین Deduplication را از بین می‌برد. چرخه عمر، Namespace، مدت نگهداری و انتقال این شناسه بین سرویس‌ها هنوز تعریف نشده است.
- اعتبارنامه دیتابیسی مستقل برای هر Tenant به‌عنوان توپولوژی Production تصویب نشده است. این برش P-02 فقط برای Test Harness از آزمایش Process-local Credential/Pool در P-01 استفاده می‌کند.

## وضعیت شواهد

تمام داده‌ها و Credentialها ساختگی‌اند. اجرای P-02 با شناسه [45463594552](https://github.com/tecpey/lottorito-platform/actions/runs/45463594552) روی Head کد `63a5ced2f3611e200a9c681e1a972d77c176c0e4` با ۲۵ تست موفق، صفر شکست و صفر Skip همراه بود؛ اجرای Documentation Governance با شناسه [45463594523](https://github.com/tecpey/lottorito-platform/actions/runs/45463594523) نیز موفق شد. این نتیجه فقط ناورداهای دیتابیسی Prototype ساختگی را اثبات می‌کند، نه صحت حسابداری، صلاحیت قانونی، پذیرش مشتری یا آمادگی Production.

## مراجع تحقیق

- [PostgreSQL 18 — Numeric Types](https://www.postgresql.org/docs/18/datatype-numeric.html): نوع Numeric دقیق و دقت مبالغ.
- [PostgreSQL 18 — INSERT / ON CONFLICT](https://www.postgresql.org/docs/18/sql-insert.html): مدیریت تعارض Unique در درج‌های هم‌زمان.
- [node-postgres — Transactions](https://node-postgres.com/features/transactions): برای چند Statement در یک Transaction باید از یک Client Checkoutشده استفاده شود.
- [AWS Builders' Library — Making retries safe with idempotent APIs](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/): هویت درخواست، تعارض پارامترها و اثر Idempotent اتمیک.
- [AWS Prescriptive Guidance — Transactional outbox](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html): ذخیره اتمیک وضعیت کسب‌وکار و Outbox؛ Consumer باید تحویل تکراری را تحمل کند.
- [AWS Well-Architected — Make mutating operations idempotent](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel04-bp04.html): شناسه پایدار Idempotency، ثبت اتمیک وضعیت، Retry و مدیریت رویدادهای تکراری.
- [Microsoft Architecture Center — Idempotent consumer](https://learn.microsoft.com/azure/architecture/patterns/idempotent-consumer): استفاده از هویت پایدار عملیات کسب‌وکار، نه Correlation ID عمومی، برای Deduplicate کردن تحویل مجدد.
