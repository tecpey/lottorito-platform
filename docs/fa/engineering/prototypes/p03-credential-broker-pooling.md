# P-03 — آزمایش Broker اعتبارنامه Tenant و مقیاس‌پذیری Connection Pool

**شناسه سند:** LOT-PROT-P03-001  
**نسخه:** ۰.۱.۰  
**وضعیت:** برنامه آزمایش پیشنهادی؛ هیچ Provider یا انتخاب معماری تصویب نشده است  
**تاریخ بازبینی:** ۲۰۲۶-۱۱-۲۴

## ۱. هدف

P-03 بررسی می‌کند آیا مدل PostgreSQL مبتنی بر هویت مستقل که در P-01 نشان داده شد، با رشد تعداد Tenantها از نظر امنیتی و عملیاتی قابل اداره باقی می‌ماند یا نه. در P-01 نشان داده شد که PostgreSQL LOGIN Role مستقل برای هر Tenant و RLS مبتنی بر `session_user` می‌تواند در تست ساختگی در برابر جعل Tenant GUC توسط Caller مقاومت کند. اما P-01 مدیریت قابل‌اعتماد هزاران Credential، Pool، چرخه عمر Role یا چرخش Credential را اثبات نکرد.

آزمایش دو موضوع مستقل را بررسی می‌کند: **تضمین هویت** و **مقیاس‌پذیری عملیاتی**. مدلی که سریع‌تر باشد اما منشأ هویت را تضعیف کند، برنده قابل‌قبول نیست.

## ۲. مرزها و موارد خارج از محدوده

- فقط Tenant، Record و Credential ساختگی و PostgreSQL/PgBouncer دورریختنی.
- بدون داده مشتری، Credential واقعی Production، Vault واقعی، AWS Account یا Secret Manager خارجی.
- بدون انتخاب Vault، AWS RDS IAM، PgBouncer، RDS Proxy یا Provider دیتابیس Production.
- بدون ادعای ساخت Credential Broker آماده Production، API Provisioning یا Framework مهاجرت.
- بدون SLO نهایی برای اندازه Pool، تعداد Tenant، Latency یا Availability؛ فرض‌های Workload و Thresholdها نیازمند تأیید مالک هستند.
- P-01 همچنان جزئی/نامعین است؛ موفقیت تست‌های P-01 به معنی قبولی P-03 نیست.

## ۳. شواهد مستندات معتبر

### هویت PostgreSQL و عضویت Role

PostgreSQL میان `session_user` که معمولاً هویت احراز‌شده هنگام اتصال دیتابیس است و `current_user` که هویت مؤثر برای بررسی Permission است تفاوت می‌گذارد. `current_user` ممکن است از طریق `SET ROLE` یا `SECURITY DEFINER` تغییر کند. آزمایش باید هر دو را بررسی کند و آن‌ها را قابل‌جایگزینی فرض نکند.  
منابع: [توابع اطلاعات سیستم](https://www.postgresql.org/docs/18/functions-info.html)، [عضویت Role](https://www.postgresql.org/docs/18/role-membership.html).

عضویت Role دارای رفتارهای مستقل `INHERIT` و `SET` است. یک Login Role می‌تواند مجوزهای Group Role مربوط به Tenant را به ارث ببرد، درحالی‌که امکان `SET ROLE` فقط از طریق زنجیره عضویتی با مجوز SET فراهم می‌شود. هرگز نباید عضویت بین Roleهای Tenantهای مختلف اعطا شود. Roleهای PostgreSQL همچنین ویژگی‌هایی مانند `LOGIN`، `NOLOGIN`، `NOBYPASSRLS`، `CONNECTION LIMIT` و اعتبار زمانی Password دارند.  
منابع: [CREATE ROLE](https://www.postgresql.org/docs/18/sql-createrole.html)، [ALTER ROLE](https://www.postgresql.org/docs/18/sql-alterrole.html).

### توپولوژی Pool در PgBouncer

در Transaction Pooling، PgBouncer یک Connection سرور را فقط برای مدت یک Transaction به Client اختصاص می‌دهد و پس از پایان Transaction آن را آزاد می‌کند. قابلیت‌های وابسته به Session با این حالت سازگار نیستند و باید حذف یا صریحاً آزمایش شوند.  
منبع: [سازگاری قابلیت‌ها در PgBouncer](https://www.pgbouncer.org/features.html).

اگر User اجباری برای Database تنظیم نشود، PgBouncer برای هر زوج User/Database یک Pool دارد. فرمول مستندشده حد بالای File Descriptor با تعداد Userها و Databaseهای متمایز رشد می‌کند؛ همچنین محدودیت Connection به‌ازای User و Database دارد. تنظیم Forced User، هویت Backend را به User اجباری تغییر می‌دهد و برای طراحی هویت مبتنی بر `session_user` یک Negative Control محسوب می‌شود.  
منابع: [تنظیمات PgBouncer](https://www.pgbouncer.org/config.html)، [تنظیمات Authentication](https://www.pgbouncer.org/config.html#authentication-settings).

### گزینه‌های چرخه عمر Credential

Vault PostgreSQL Secrets Engine از Credential پویا با TTL/Max-TTL و Static Role با چرخش Password پشتیبانی می‌کند. Usernameهای پویا می‌توانند Attribution را بهتر کنند اما ممکن است تعداد Poolها را افزایش دهند؛ Static Roleها از ایجاد Username جدید برای هر Lease جلوگیری می‌کنند اما به روش امن Rotation و Drain نیاز دارند.  
منابع: [Vault PostgreSQL Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases/postgresql)، [Vault Database Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases).

احراز هویت IAM در AWS RDS از Token امضاشده با طول عمر ۱۵ دقیقه استفاده می‌کند. User دیتابیس PostgreSQL باید برای IAM Authentication پیکربندی شود (در RDS PostgreSQL از طریق `rds_iam`)؛ این روش مخصوص AWS است و تصمیم مستقل از Provider را اثبات نمی‌کند. RDS Proxy ممکن است هنگام تغییر Session Variable در PostgreSQL، Session را Pin کند و Multiplexing را کاهش دهد؛ رفتار Transaction-local state باید اندازه‌گیری شود.  
منابع: [IAM Database Authentication در RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html)، [Pinning در RDS Proxy](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy-pinning.html)، [ملاحظات Workload در RDS Proxy](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy-best-practices.workload-considerations.html).

## ۴. مدل‌های مورد مقایسه

| مدل | هویت دیتابیس | توپولوژی Pool | هدف |
|---|---|---|---|
| A. LOGIN Role ثابت برای هر Tenant | `session_user` مختص Tenant | PgBouncer Pool برای هر User دیتابیس | خط مبنای هویت قوی |
| B. LOGIN موقت برای هر Credential Lease | User یکتای Lease متصل به یک Role Tenant | احتمالاً Pool مجزا برای هر User موقت | فشارآزمایی Dynamic Secret و تعداد Pool |
| C. LOGIN مشترک برنامه + Tenant GUC محلی Transaction | `session_user` مشترک؛ Tenant از GUC | Pool مشترک | خط مبنای کنترل/منفی؛ مرز جعل آن در P-01 نشان داده شده |
| D. Forced Backend User در PgBouncer | هویت مشترک Backend اجباری | یک Pool برای Database پیکربندی‌شده | Negative Control؛ هویت Tenant نیست |
| E. `pg.Pool` مستقل برای هر Tenant در برنامه | LOGIN Role مختص Tenant | Pool Registry در برنامه | اندازه‌گیری انفجار Pool محلی و پیچیدگی Eviction |

مدل B می‌تواند از Group Role غیرقابل Login و مختص Tenant با Grant محدود و یک LOGIN موقت عضو آن استفاده کند. آزمایش باید عضویت Role، `INHERIT`، `SET`، رفتار RLS، Revocation و این واقعیت را بررسی کند که `session_user` همان Login موقت است، نه Group Role مربوط به Tenant.

## ۵. Workload و شاخص‌ها

Workloadهای قطعی و قابل‌تکرار را با جمعیت **۱۰، ۱۰۰ و ۱۰۰۰ Tenant** و نسبت Tenant فعال **۱۰٪، ۵۰٪ و ۱۰۰٪** اجرا کنید. نرخ دقیق درخواست و آستانه Latency تا زمان تأیید Workload نماینده، TBD باقی می‌ماند.

برای هر مدل ثبت شود:

- تعداد Tenant و Tenant فعال، درخواست هم‌زمان و Transaction در ثانیه.
- Client/Server Connectionهای PgBouncer، تعداد Pool، Clientهای منتظر، محدودیت User/Database و مصرف File Descriptor.
- Connectionهای Active/Idle در PostgreSQL، تعداد Role، Churn اتصال و Connectionهای ردشده.
- تعداد Poolهای برنامه، Connectionهای Idle/Active، زمان انتظار، تعداد Eviction و حافظه.
- تأخیر صدور/تمدید/لغو Credential، خطاهای Authentication و Latency وابستگی به Secret Manager.
- Latency درخواست و Connection Acquisition در p50/p95/p99، CPU و حافظه.
- نقض Isolation، `session_user` اشتباه، تلاش برای Role Switch و استفاده مجدد از Credential قدیمی.

از Seed تصادفی ثابت، Tenant ID ساختگی، Record IDهای برخوردکننده، Barrierهای هم‌زمانی قابل‌تکرار و Artifactهای نتیجه Machine-readable استفاده کنید. یک اجرای پرنویز به‌تنهایی مبنای تصمیم معماری نیست.

## ۶. سناریوهای امنیت و چرخه عمر

| شناسه | سناریو | شواهد لازم |
|---|---|---|
| P02-IAM-01 | Tenant A و B با هویت DB متمایز احراز هویت شوند | `session_user` در هر Transaction به Tenant درست نگاشت شود |
| P02-IAM-02 | تلاش برای `SET ROLE` به Role Tenant دیگر | Permission Denied؛ بدون زنجیره عضویت بین Tenantها |
| P02-IAM-03 | PgBouncer Transaction Pooling با Backend Reuse | Reuse اتصال هویت Tenant را تغییر ندهد یا Rowهای Tenant قبلی را افشا نکند |
| P02-IAM-04 | Forced Backend User در PgBouncer | اثبات شود `session_user` Backend مشترک است؛ این مدل برای هویت Tenant نامناسب است |
| P02-IAM-05 | بررسی هویت SECURITY DEFINER | تفاوت `session_user` و `current_user` روشن باشد؛ Policy هویت Definer را مبنا نگیرد |
| P02-CRED-01 | صدور/Cache/تمدید Credential | Tenant Binding و نسخه Credential صریح؛ بدون برخورد Cache Key |
| P02-CRED-02 | Rotation از N به N+1 | اتصال‌های جدید از N+1 استفاده کنند؛ Poolهای N تخلیه شوند؛ Credential لغوشده اتصال جدید نسازد |
| P02-CRED-03 | لغو/انقضای Lease حین Transaction فعال | رفتار Session موجود و حداکثر تأخیر Revocation اندازه‌گیری شود؛ اتصال جدید Fail-closed باشد |
| P02-CRED-04 | قطع Broker یا Cache قدیمی | هیچ Fallback به Credential مشترک Privileged نباشد؛ خطای محدود و صریح |
| P02-POOL-01 | رشد از ۱۰ به ۱۰۰۰ Tenant | تعداد Pool و Server Connection در بودجه موردتأیید مالک بماند |
| P02-POOL-02 | Burst و Eviction Tenant غیرفعال | Tenantهای دیگر Starve نشوند؛ Poolهای Idle امن آزاد شوند |
| P02-POOL-03 | Pool Exhaustion | Backpressure، Queue Timeout و Recovery قطعی باشند |
| P02-POOL-04 | Backend Reuse پس از Commit/Rollback/Error | State محلی Transaction Reset شود؛ نشت بین Tenant رخ ندهد |

## ۷. Invariantهای ایمنی Credential و Pool

۱. هویت Tenant از Principal احراز‌شده و نگاشت Credential کنترل‌شده توسط سرور می‌آید، نه Header، Query Parameter یا Body درخواست.

۲. هر Login Credential دیتابیس دقیقاً به یک مرز Authorization مربوط به Tenant نگاشت می‌شود و نمی‌تواند با `SET ROLE` وارد Tenant دیگری شود.

۳. کلید Pool حداقل شامل Endpoint دیتابیس، نام Database، Username/Identity احراز‌شده دیتابیس و نسخه Credential است؛ هرگز فقط بر اساس متن ارسالی Tenant Pool نسازید.

۴. Rotation یک نسخه جدید و صریح ایجاد می‌کند: صدور نسخه قدیمی متوقف شود، Pool Manager اتصال نسخه قدیمی نسازد، Poolهای قدیمی Drain شوند و سپس Credential قبلی Revoked شود.

۵. Revocation باید Sessionهای PostgreSQL که قبلاً احراز هویت شده‌اند را در نظر بگیرد. انقضای Password به‌تنهایی اثبات نمی‌کند Sessionهای موجود بسته شده‌اند.

۶. تعداد Pool، Connection، عمق Queue، File Descriptor و عمر Idle در سطح Global و هر Tenant محدود باشند.

۷. قطع Broker، انقضای Credential، حذف Role، Pool Exhaustion و Cache قدیمی باید Fail-closed شوند؛ هیچ Fallback به Superuser مشترک یا Credential بدون محدودیت مجاز نیست.

۸. Transaction Pooling در PgBouncer فقط زمانی مجاز است که برنامه از Session State ناسازگار استفاده نکند و تست هویت در Backend Reuse موفق باشد.

۹. Secret هرگز در Log، Trace، Test Artifact، خروجی PR یا API قابل‌مشاهده Tenant نوشته نشود.

۱۰. Provision/Deprovision و Rotation باید Idempotent، قابل مشاهده و قابل Reconcile با وضعیت Roleهای PostgreSQL باشند.

## ۸. مراحل پیشنهادی

۱. **P02-A — توپولوژی Pool:** مدل قطعی PgBouncer برای ۱۰/۱۰۰/۱۰۰۰ User مختص Tenant؛ اندازه‌گیری Pool، Connection، File Descriptor و رفتار Queue.

۲. **P02-B — هویت در Transaction Pooling:** بررسی `session_user`، `current_user`، عضویت و RLS در Backend Reuse؛ همراه با Forced User و Shared GUC به‌عنوان Negative Control.

۳. **P02-C — شبیه‌سازی Credential Broker:** Interface مستقل از Provider با SCRAM ساختگی و Leaseهای Versioned؛ بدون اتصال واقعی به Vault/AWS.

۴. **P02-D — Rotation و Revocation:** صدور N/N+1، توقف صدور نسخه قدیمی، Drain Pool، Revocation نسخه N و اندازه‌گیری رفتار Sessionهای موجود و Recovery.

۵. **P02-E — ارزیابی Adapterهای Provider:** مقایسه Vault Dynamic/Static Role و AWS RDS IAM فقط پس از تست Contract مستقل از Provider.

هر مرحله Result Record مستقل دارد. قبولی یک مرحله به معنی قبولی مرحله بعد یا کل P-03 نیست.

## ۹. دروازه‌های تصمیم

هیچ مدلی انتخاب نمی‌شود مگر اینکه تست‌های هویت و Isolation تحت هم‌زمانی و Backend Reuse موفق باشند؛ رشد Connection و Pool در جمعیت‌های توافق‌شده Tenant اندازه‌گیری شود؛ رفتار Rotation و Revocation شامل Sessionهای باز قبلی مشاهده شود؛ قطع Broker و Pool Exhaustion Fail-closed باشند؛ Trade-offهای Performance/Operations/Cost با Artifact قابل‌بازتولید مستند شوند؛ رفتار PostgreSQL، PgBouncer و Managed Proxy از هم تفکیک شود؛ و مالک فرض‌های Workload و Thresholdهای عددی را تصویب کند.

**تصمیم فعلی:** هیچ Credential Broker، Pooler، Provider یا معماری هویت دیتابیس Tenant تصویب نشده است. P-03 فقط برنامه تحقیق و Prototype است.

## ۱۰. منابع

- [PostgreSQL 18 — توابع اطلاعات سیستم](https://www.postgresql.org/docs/18/functions-info.html)
- [PostgreSQL 18 — عضویت Role](https://www.postgresql.org/docs/18/role-membership.html)
- [PostgreSQL 18 — CREATE ROLE](https://www.postgresql.org/docs/18/sql-createrole.html)
- [PostgreSQL 18 — ALTER ROLE](https://www.postgresql.org/docs/18/sql-alterrole.html)
- [PgBouncer — قابلیت‌ها و سازگاری Pooling](https://www.pgbouncer.org/features.html)
- [PgBouncer — تنظیمات](https://www.pgbouncer.org/config.html)
- [PgBouncer — تنظیمات Authentication](https://www.pgbouncer.org/config.html#authentication-settings)
- [Vault — PostgreSQL Database Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases/postgresql)
- [Vault — Database Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases)
- [AWS — RDS IAM Database Authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html)
- [AWS — Pinning در RDS Proxy](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy-pinning.html)
