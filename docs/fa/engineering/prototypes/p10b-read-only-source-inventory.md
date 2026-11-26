# P-10B — پروتکل Inventory فقط‌خواندنی منابع و داده‌های Legacy

**شناسه سند:** LOT-PROT-P10B-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پروتکل پیشنهادی Inventory؛ هیچ محیط منبعی بررسی یا مجاز نشده است | **بازبینی:** ۲۰۲۶-۱۱-۲۶

## ۱. هدف و مرز اختیار

P-10B روش Inventory یک محیط منبع مشخص Lottorito را پیش از طراحی هر Migration عملیاتی تعریف می‌کند. این سند عمداً **پروتکل و قالب Query** است، نه Inventory اجراشده. در این مرحله هیچ Endpoint دیتابیس، حساب، Credential، Export شریک یا منبع داده Production ارائه یا مجاز نشده است.

مرحله نخست فقط Metadata و Read-only است. نباید داده Row-level مشتری/بازیکن/پرداخت استخراج کند، Schema یا Data را تغییر دهد، Object موقت بسازد، Script تعمیر اجرا کند یا مالکیت Tenant/Product را حدس بزند. هر دسترسی بعدی به محیط مشخص نیازمند مجوز صریح مالک، مالک پاسخ‌گوی منبع/DBA مشخص، هدف تأییدشده، هویت فقط‌خواندنی، بازه محدود و نگهداری امن شواهد خارج از Git و CI است.

این سند مجوز دسترسی Production نیست. اگر محیط مشخص و مجوز موجود نباشد، P-10B در وضعیت آمادگی پروتکل باقی می‌ماند و نباید به‌عنوان Inventory اجراشده گزارش شود.

## ۲. سابقه مجوز الزامی

پیش از اتصال به هر منبع، موارد زیر باید ثبت و تصویب شوند:

| فیلد | شواهد الزامی |
|---|---|
| شناسه منبع | شناسه یکتا و غیرمحرمانه محیط؛ Password یا Connection URI را ثبت نکنید |
| طبقه محیط | Local / Disposable CI / Development / Staging / Production / Partner Sandbox |
| مالک پاسخ‌گو | مالک سیستم/داده و DBA یا اپراتور مسئول منبع |
| هدف | پرسش مشخص Migration، Reconciliation یا معماری که باید پاسخ داده شود |
| مبنای حقوقی/حریم خصوصی | هدف و بررسی حوزه قضایی/حریم خصوصی تأییدشده؛ مبنای قانونی را حدس نزنید |
| کلاس‌های داده | مشتری/PII، احراز هویت، مالی، شریک، عملیاتی، Telemetry، Gaming یا عمومی |
| مجوز | تأیید مکتوب، Scope، Queryهای مجاز، تاریخ انقضا و تماس توقف اضطراری |
| هویت دسترسی | Principal اختصاصی فقط‌خواندنی؛ بدون Admin مشترک، Superuser، BYPASSRLS یا هویت Runtime برنامه |
| شبکه/بازه زمانی | Endpoint، منطقه/Residency، Allowlist و بازه دسترسی محدود و مصوب |
| مقصد شواهد | محل امن و دارای کنترل دسترسی خارج از Repository، Issue، Prompt و CI |
| Retention | تاریخ انقضا و روش حذف خروجی Inventory |
| هماهنگی تغییر | تأیید DBA برای بار Query، انتخاب Replica، پنجره نگهداری و Escalation رخداد |

اگر مالکیت، هدف، مجوز، طبقه‌بندی منبع یا شیوه نگهداری شواهد مشخص نیست، اتصال ممنوع است. Endpoint ارائه‌شده توسط شریک به‌تنهایی مجوز دسترسی محسوب نمی‌شود.

## ۳. توالی Inventory

### B-0 — ثبت Scope و منابع

هر System of Record احتمالی و منبع مجاور را جداگانه فهرست کنید: دیتابیس اصلی، Replica، سیستم Provider/Partner، Event Broker، Object Storage، File Export، Cache، Search، Analytics/Warehouse، Identity Provider، Audit Store و Backup/Archive. فرض نکنید همه آن‌ها مرجع حقیقت یا داخل Scope هستند.

برای هر منبع، مالک، هدف، محیط، Engine/Version، منطقه/Residency، کلاس داده، برنامه‌های Writer/Reader، مصرف‌کنندگان، سازوکار Backup/Recovery، Retention، اندازه تخمینی، تناوب تغییر، وابستگی‌ها و وضعیت Source of Truth را ثبت کنید. واقعیت تأییدشده را از گفته مالک و فرضیه جدا کنید.

### B-1 — Snapshot دیتابیس فقط از Metadata

از حساب اختصاصی Least-Privilege و فقط‌خواندنی استفاده کنید. نسخه دیتابیس، فهرست Schema/Table/View، تعداد تقریبی Row و اندازه، Column/Type/Nullable/Default، Constraintهای Primary/Unique/Foreign/Check، اعتبار Index، مالکیت Table، Grantها، وضعیت RLS، Policyها، Extensionها و آمار Table را ثبت کنید.

- ابتدا از برآوردهای Catalog/Statistics استفاده کنید. `pg_class.reltuples` و `pg_stat_user_tables` تخمینی و ممکن است قدیمی باشند؛ آن‌ها را به‌عنوان Estimate برچسب بزنید.
- `COUNT(*)` دقیق، نمونه‌برداری Row، Query Plan همراه اجرا، Sequential Scan، Export و Joinهای حجیم جزو مرحله پیش‌فرض نیستند. این موارد به پنجره بار و برنامه Query جداگانه با تأیید DBA نیاز دارند.
- در این مرحله Payload رکوردها، Secret، Password Hash، Token، Credential پرداخت، متن مکالمه یا جزئیات مشتری/بازیکن را Select نکنید.
- Function دلخواه تعریف‌شده توسط کاربر را اجرا نکنید. فقط Queryهای Catalog بازبینی‌شده زیر مجازند.
- خروجی را فقط در محل محدود و تأییدشده نگهداری کنید. خروجی خام Inventory را در Git، PR، Comment، Issue یا ChatGPT قرار ندهید.

### B-2 — مالکیت منطقی و Lineage

برای هر Table/Event/Object موارد زیر را مشخص کنید:

- Bounded Context مالک و Data Owner پاسخ‌گو.
- Writerهای مرجع، Consumerها، ETL/Replication Jobها و اپراتورهای انسانی.
- شناسه Tenant و روش استخراج مرجع آن.
- شناسه Product و روش استخراج مرجع آن.
- شخصیت حقوقی/بافت عملیاتی، در صورت الزام.
- Primary Key، Business/Natural Key، گراف Foreign Key و چرخه عمر.
- Source Event ID، Economic Effect ID، Idempotency Key و پیوند Journal در صورت کاربرد.
- Timestampهای Created/Updated/Effective/Settled، منطقه زمانی و Retention.
- Columnهای PII/Financial/Sensitive و هدف/دسترسی مجاز.
- وابستگی Backup، Restore، Deletion، Archive و Audit.

مالکیت را فقط از نام Table، Label رابط کاربری، فرض شریک یا تنظیم Deployment فعلی استنباط نکنید. معنای داده باید توسط Source Owner و Domain Owner تأیید شود.

### B-3 — پوشش Tenant/Product و فهرست ابهام‌ها

هر الگوی هویتی مشاهده‌شده را با Metadata یا Aggregate Query تأییدشده طبقه‌بندی کنید:

- `KNOWN`: نگاشت Tenant و Product دارای مدرک مرجع است.
- `NULL_OR_MISSING`: هویت الزامی وجود ندارد.
- `LEGACY_SHARED`: مقدار مبهم قدیمی مانند `shared`.
- `UNKNOWN_PRODUCT`: محصول در Allowlist Canonical نیست.
- `CONFLICTED`: Source، Tenant، Product، Account یا Relationship با هم ناسازگارند.
- `ORPHANED`: رابطه والد/Foreign Key لازم وجود ندارد.
- `DUPLICATE_KEY`: نامزد کلید طبیعی، اثر مالی یا Idempotency تکراری است.
- `UNVERIFIED`: شواهد برای تصمیم کافی نیست.

موارد حل‌نشده، متعارض، یتیم و تکراری واجد Migration خودکار نیستند. تا زمان ثبت مدرک و داوری مالک پاسخ‌گو در قرنطینه می‌مانند. هرگز `shared` را بر اساس فراوانی، سهولت، UI فعلی یا Default به `affiliate_agent`، `lottery` یا `lottorito` نگاشت نکنید.

### B-4 — Inventory سلامت مالی و Event

برای منابع مالی/Event فقط Aggregate و Metadata تأییدشده را ثبت کنید:

- تعداد بر اساس Tenant/Product/Currency/Account/Status/Period.
- مجموع Debit و Credit به‌صورت مستقل برای هر Currency و دوره حسابداری.
- پیوند Effect بین Source و Ledger و تعداد Effectهای مفقود/تکراری.
- پیوند Reversal/Adjustment، وضعیت Pending/Held/Quarantined و عمر Exception/Suspense.
- Provider Event/Delivery ID در برابر Economic Effect Identity.
- برخورد Idempotency Key، تعارض Key یکسان با Payload متفاوت و شکاف Replay Cursor.
- Journal Line یتیم، Account Mapping مفقود و Exceptionهای Currency/Precision.

برابری Total یا تعداد Row اثبات صحت Attribution نیست. Aggregate مالی نمی‌تواند مالکیت حقوقی، Revenue Recognition، NGR، استحقاق Commission، Funding، FX یا Policy پرداخت را حل کند. این‌ها تصمیم‌های مستقل تجاری/حسابداری و نیازمند تصویب هستند.

### B-5 — تطبیق، بازبینی و تثبیت Inventory

خروجی‌ها شامل Source Register، Manifest Snapshot Metadata، ماتریس Lineage، گزارش پوشش هویت، Ambiguity Register، گزارش Aggregate مالی/Event، Risk Register و فهرست پرسش‌های باز است. هر Artifact باید Source ID، زمان Snapshot، نسخه ابزار/استخراج، نسخه/Digest Query، برچسب تقریبی/دقیق، بازبین و تاریخ انقضای Retention را ثبت کند.

DBA بار Query و کامل‌بودن Metadata را تأیید می‌کند. Data/Domain Owner معنای داده را تأیید می‌کند. Security/Privacy/Legal دسترسی و طبقه‌بندی را بازبینی می‌کنند. Finance Aggregate مالی و نگاشت‌های حل‌نشده را بررسی می‌کند. در موارد نیازمند Dual Control، یک نفر نباید بی‌صدا نگاشت مالی مبهم خودش را تأیید کند.

## ۴. قالب Query فقط‌خواندنی برای Metadata در PostgreSQL

محتوای زیر **قالب قابل‌بازبینی** است، نه دستور اتصال به محیطی مشخص. فقط پس از مجوز بخش ۲ اجرا شود. از Viewهای Catalog/Metadata استفاده می‌کند و محتوای ردیف‌های کسب‌وکار را Query نمی‌کند. سازگاری با Major Version منبع را تأیید کنید و Timeout و انتخاب Replica را به تأیید DBA برسانید.

```sql
BEGIN READ ONLY;

-- Guardrail نمونه برای Inventory کوچک Metadata؛ DBA می‌تواند محدودتر کند.
SET LOCAL statement_timeout = '5s';
SET LOCAL lock_timeout = '1s';

-- 1. Context دیتابیس/Session؛ هیچ Endpoint یا Secret انتخاب نمی‌شود.
SELECT
  current_database() AS database_name,
  current_user AS effective_role,
  session_user AS login_role,
  current_setting('server_version') AS server_version,
  current_setting('server_version_num') AS server_version_num,
  pg_database_size(current_database()) AS database_bytes;

-- 2. Relationها و برآورد اندازه/تعداد Row.
-- reltuples تخمینی است، نه تعداد دقیق.
SELECT
  n.nspname AS schema_name,
  c.relname AS relation_name,
  c.relkind AS relation_kind,
  c.reltuples::bigint AS estimated_rows,
  pg_relation_size(c.oid) AS main_fork_bytes,
  pg_total_relation_size(c.oid) AS total_bytes,
  pg_get_userbyid(c.relowner) AS owner_name,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS rls_forced
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND c.relkind IN ('r', 'p', 'm', 'v', 'f')
ORDER BY n.nspname, c.relname;

-- 3. Metadata ستون‌ها. پیش از Export، Default Expressionها را بازبینی کنید.
SELECT
  table_schema, table_name, ordinal_position, column_name,
  data_type, udt_name, is_nullable, column_default,
  character_maximum_length, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name, ordinal_position;

-- 4. Constraintها و وضعیت Validation.
SELECT
  n.nspname AS schema_name,
  c.relname AS table_name,
  con.conname AS constraint_name,
  con.contype AS constraint_type,
  con.convalidated AS is_validated,
  pg_get_constraintdef(con.oid, true) AS definition
FROM pg_constraint con
JOIN pg_class c ON c.oid = con.conrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, c.relname, con.conname;

-- 5. اعتبار/آمادگی Index و تعریف آن.
SELECT
  n.nspname AS schema_name,
  t.relname AS table_name,
  irel.relname AS index_name,
  ix.indisprimary AS is_primary,
  ix.indisunique AS is_unique,
  ix.indisvalid AS is_valid,
  ix.indisready AS is_ready,
  pg_get_indexdef(ix.indexrelid) AS definition
FROM pg_index ix
JOIN pg_class t ON t.oid = ix.indrelid
JOIN pg_class irel ON irel.oid = ix.indexrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, t.relname, irel.relname;

-- 6. RLS Policyها. نام Role و Predicate را پیش از Export بازبینی کنید.
SELECT
  schemaname, tablename, policyname, permissive,
  roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, tablename, policyname;

-- 7. فقط Metadata قابلیت Role؛ هرگز Credential Verifier را Query نکنید.
SELECT
  rolname, rolsuper, rolinherit, rolcreaterole,
  rolcreatedb, rolcanlogin, rolreplication, rolbypassrls
FROM pg_roles
ORDER BY rolname;

-- 8. آمار Table تخمینی است و ممکن است قدیمی باشد.
SELECT
  schemaname, relname, n_live_tup, n_dead_tup,
  last_analyze, last_autoanalyze, last_vacuum, last_autovacuum
FROM pg_stat_user_tables
ORDER BY schemaname, relname;

-- 9. Extensionهای نصب‌شده.
SELECT extname, extversion
FROM pg_extension
ORDER BY extname;

ROLLBACK;
```

این قالب Object Storage، Broker Topic، سیستم Provider، Secret Manager، Writerهای سطح Application یا مالکیت حقوقی را Inventory نمی‌کند. برای آن‌ها پروتکل‌های Read-only جداگانه لازم است. مشاهده Catalog به Privilege بستگی دارد؛ Metadata غیرقابل‌دسترسی را «غایب» تفسیر نکنید.

## ۵. مدل شواهد و ساختار خروجی

از Source ID و Snapshot ID پایدار استفاده کنید. نام مشتری، ایمیل، شماره حساب، Credential یا شناسه خام کسب‌وکار را به‌عنوان نام فایل یا مرجع عمومی Issue به کار نبرید.

### Source Register

| فیلد | معنا |
|---|---|
| source_id | شناسه مبهم و پایدار منبع |
| environment_class | Development/Staging/Production/Partner Sandbox |
| system_owner / data_owner | افراد/تیم‌های پاسخ‌گو |
| engine_version / region | Metadata فنی و Residency تأییدشده |
| authoritative_domains | دامنه‌هایی که منبع برای آن‌ها مرجع است |
| writers / consumers | سرویس‌ها، Jobها و اپراتورهای انسانی |
| data_classes | برچسب‌های طبقه‌بندی تأییدشده |
| backup / restore / retention | مراجع تأییدشده و شکاف‌ها |
| access_approval_id | مرجع پرونده مجوز در محل محدود |
| snapshot_id / captured_at | Metadata قابلیت بازتولید |

### Table/Asset Lineage Register

| فیلد | معنا |
|---|---|
| source_id / snapshot_id | منبع و Snapshot |
| schema / object | نام Metadata |
| object_type / estimated_rows / bytes | نوع و برآورد |
| owner_context / data_owner | دامنه و مالک پاسخ‌گو |
| authoritative_writer | Writerهای تأییدشده |
| tenant_key / product_key | Column یا روش استخراج همراه مدرک |
| source_event / economic_effect / idempotency | فیلدهای هویتی مرتبط |
| legal_entity_key | در صورت وجود و تصویب |
| pii_financial_classification | طبقه‌بندی داده |
| retention / deletion / backup_dependency | چرخه عمر |
| evidence_ref / confidence | مرجع شواهد محدود و سطح اطمینان |

### Ambiguity Register

هر Exception دارای مرجع مبهم و غیرحساس، طبقه‌بندی، Source/Object، تعداد یا Estimate، علت، مدرک موردنیاز، داور پاسخ‌گو، تصمیم، تاریخ تصمیم و وضعیت Migration است. وضعیت‌های مجاز عبارت‌اند از `QUARANTINE`، `OWNER_CONFIRMED_MAPPING`، `EXCLUDE_FROM_SCOPE` یا `REMEDIATE_AT_SOURCE`. هیچ وضعیتی توسط Script Inventory حدس زده نمی‌شود.

## ۶. شرایط توقف

در موارد زیر Inventory را متوقف و به Source Owner/DBA و تماس امنیت اطلاع دهید:

- حساب Read-only نیست، Superuser/BYPASSRLS دارد یا مجوز Write غیرمنتظره مشاهده می‌شود.
- هویت Source، Environment، Region یا Database با پرونده مجوز تطبیق ندارد.
- Latency Query، Lock Wait، Replica Lag، CPU/I/O یا خطای Application از Guardrail مصوب DBA عبور می‌کند.
- خروجی Query شامل داده شخصی غیرمنتظره، Secret، Payload یا Credential Verifier است.
- درخواستی برای دورزدن RLS، مشاهده Row کسب‌وکار بدون مجوز، تغییر وضعیت منبع، DDL، تعمیر رکورد یا Export کل Dataset مطرح می‌شود.
- Source Owner درباره اختیار، هدف، مالکیت داده یا Retention اختلاف دارد.
- شواهد باید در Git، CI Log، Issue عمومی یا سامانه تأییدنشده ذخیره شوند.

حداقل شواهد عملیاتی لازم را حفظ و توقف کنید؛ راهکار دورزننده اجرا نکنید.

## ۷. معیارهای پذیرش

آمادگی پروتکل P-10B زمانی پذیرفته است که:

- Source Register و قالب مالک پاسخ‌گو وجود داشته باشد.
- مجوز و شرایط توقف صریح باشند.
- Queryهای Metadata فقط‌خواندنی، محدود و برای Engine/Version هدف بازبینی شده باشند.
- Estimate از Count دقیق تفکیک شده باشد.
- هویت Tenant/Product، ابهام Legacy و سلامت مالی/Event جداگانه Inventory شوند.
- نامزدهای `shared`، Null، متعارض، یتیم و تکراری قابل نگاشت خودکار نباشند.
- داده حساس Row-level از Git/CI/Context ایجنت خارج بماند.
- ساختار خروجی Provenance شواهد، Reviewer، Confidence و Retention را داشته باشد.
- کنترل ساختاری دوزبانه موفق و هم‌ارزی معنایی توسط بازبین انسانی بررسی شود.

**وضعیت فعلی:** فقط پروتکل مستند شده است. هیچ محیط منبعی بررسی نشده است. اجرای P-10B تا زمان معرفی منبع توسط مالک و اعطای مجوز Read-only محدود، مسدود است. هیچ Migration یا دسترسی به داده Production مجاز نیست.
