# P-01 — نمونه جداسازی Tenant

**شناسه سند:** LOT-PROT-P01-001 | **نسخه:** ۰.۴.۰ | **وضعیت:** Prototype پیاده‌سازی‌شده؛ CI مقایسه هویت مستقل موفق؛ P-01 کامل همچنان جزئی | **تاریخ بازبینی:** ۲۰۲۶-۱۱-۲۴

## هدف و مرز تصمیم

این آزمایش موقت، بخش محدودی از LOT-PROT-001 را بررسی می‌کند: انتقال Context مربوط به Tenant از مرز HTTP بومی Node.js به PostgreSQL Row-Level Security (RLS)، همراه با استفاده مجدد از اتصال‌های Connection Pool.

این کار سرویس Production، پیاده‌سازی احراز هویت، قبولی کامل P-01، تصمیم نهایی فناوری، اتصال مشتری یا ادعای آمادگی Production نیست. نسخه‌های Node.js 26.13.0، PostgreSQL 18.7 و node-postgres 8.23.1 فقط کاندیدهای ثابت‌شده برای همین آزمایش‌اند. PostgreSQL 19 در این آزمایش ارزیابی نمی‌شود.

## محدوده پیاده‌سازی‌شده آزمایش

- دو Tenant ساختگی با UUID رکورد و Natural Key عمداً یکسان.
- یک نقطه اتصال تزریقی برای احراز هویت؛ Authenticator مخصوص تست، Bearer Tokenهای ساختگی را به Principalهای سمت سرور نگاشت می‌کند. این احراز هویت Production نیست و هیچ Token خارج از Fixture آزمایش اعتبار ندارد.
- هویت Tenant فقط از Principal احراز هویت‌شده گرفته می‌شود. هدر x-tenant-id ارسالی کاربر نادیده گرفته می‌شود؛ مقدار متعارض tenant_id در بدنه Write با پاسخ 403 رد می‌شود.
- هر عملیات دیتابیس یک اتصال از Pool می‌گیرد، Transaction باز می‌کند، مقدار set_config('app.tenant_id', ..., true) را در همان Transaction اعمال می‌کند، Queryهای پارامتری را اجرا و روی همان اتصال Commit/Rollback می‌کند.
- RLS روی جدول آزمایش فعال و اجباری است. Role اجرایی به‌صورت صریح NOSUPERUSER و NOBYPASSRLS است، مالک جدول نیست و مجوز ساخت Database یا Role ندارد.
- Pool تک‌اتصالی، درخواست‌های متناوب Tenantها را عمداً روی یک اتصال فیزیکی مشترک اجرا می‌کند.
- ایجاد Job، ردیف Job مختص Tenant و ردیف Dispatch فاقد Payload را در یک تراکنش دیتابیس می‌نویسد؛ Tenant ID از Principal احراز‌شده گرفته می‌شود.
- Role جداگانه Dispatcher که Superuser و BYPASSRLS نیست، می‌تواند Metadata سراسری Dispatch را با `FOR UPDATE SKIP LOCKED` Claim کند، اما هیچ مجوزی برای Payloadهای Job ندارد. مجوز UPDATE آن فقط به ستون‌های وضعیت/تلاش/Lease محدود است.
- Envelope مربوط به Dispatch، Key ID، نسخه، Tenant ID، Job ID، شماره تلاش و زمان صدور را با امضای Ed25519 مقید می‌کند. Dispatcher کلید خصوصی امضا را نگه می‌دارد؛ Worker فقط کلید عمومی اعتبارسنجی را دریافت می‌کند و پیش از ایجاد Tenant Context امضا را بررسی و سپس Job را تحت RLS دوباره بارگذاری می‌کند. تست‌ها در هر اجرا یک جفت کلید موقت و تازه تولید می‌کنند.
- Worker عضویت فعال Actor مبدأ را در تراکنش Job دوباره بررسی می‌کند، از Row Lock و تغییر وضعیت Idempotent استفاده می‌کند و Jobهایی را که عضویتشان پیش از اجرا لغو شده رد می‌کند.
- یک مدل مقایسه‌ای دوم برای هویت دیتابیس، از LOGIN Roleهای ساختگی جداگانه برای Tenant A و B استفاده می‌کند. نگاشت خصوصی Role به Tenant فقط برای Role مالک اختصاصی NOLOGIN، غیر Superuser و غیر BYPASSRLS قابل خواندن است؛ یک تابع محدود SECURITY DEFINER با `search_path` ثابت (`pg_catalog, private, pg_temp`)، `session_user` تغییرناپذیر را به Tenant ID نگاشت می‌کند و Policyهای RLS به‌جای GUC قابل‌تغییر برنامه از این هویت احرازشده دیتابیس استفاده می‌کنند. تست‌ها مالکیت/تنظیم تابع را بررسی و تلاش برای Shadow کردن نام جدول در Temporary Schema را اجرا می‌کنند.
- تست‌های Role مستقل تلاش می‌کنند `app.tenant_id` را جعل کنند، به Role Tenant دیگر سوئیچ کنند، `SESSION AUTHORIZATION` را تغییر دهند، نگاشت خصوصی هویت را بخوانند و رکوردی برای Tenant دیگر درج کنند؛ همچنین بررسی می‌کنند که ردیف‌های Membership و Payloadهای Job غیرهم‌زمان فقط در محدوده Role دیتابیس احراز‌شده قابل مشاهده باشند.

## سناریوهای پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P01-HTTP-01 | نبود یا نامعتبر بودن Credential ساختگی | پاسخ 401؛ بدون دسترسی به داده |
| P01-HTTP-02 | فهرست رکوردهای Tenant A و B | هر Tenant فقط Fixture خودش را می‌بیند |
| P01-HTTP-03 | جعل هدر Tenant | Tenant احراز هویت‌شده تغییر نمی‌کند |
| P01-HTTP-04 | UUID یکسان شیء در دو Tenant | هر Tenant فقط سطر خودش را می‌بیند |
| P01-HTTP-05 | شناسه Tenant متعارض در بدنه Write | پاسخ 403؛ بدون اثر جانبی |
| P01-HTTP-06 | Write بدون Tenant ID ارسالی کاربر | سرور Tenant احراز هویت‌شده را تخصیص می‌دهد |
| P01-HTTP-07 | ابطال Membership یک Tenant و ارسال Request جدید | Subject ابطال‌شده رد می‌شود و Tenant دیگر تحت تأثیر قرار نمی‌گیرد |
| P01-DB-01 | اجرای متناوب A/B/A با Pool تک‌اتصالی | نشت Context بین درخواست‌ها رخ نمی‌دهد |
| P01-DB-02 | بررسی Role اجرایی، تنظیمات جدول، ترکیب Policyها و مجوز Membership | نه Superuser، نه مالک جدول و نه BYPASSRLS؛ RLS و FORCE RLS فعال؛ Tenant Guard از نوع RESTRICTIVE است؛ UPDATE فقط روی lock_version غیرحساس مجاز است و روی active مجاز نیست |
| P01-DB-03 | Query/Insert بدون Tenant Context | Select هیچ سطری نمی‌بیند؛ Insert رد می‌شود |
| P01-DB-04 | تلاش برای تغییر app.tenant_id با Role مشترک app_runtime | افشای مورد انتظار: Role می‌تواند Tenant دیگری را اظهار کند؛ اثبات می‌کند GUC/RLS در برابر Credential اجرایی تسخیرشده مرز امنیتی نیست |
| P01-DB-05 | اجرای UPDATE/DELETE روی شیء اختصاصی Tenant B در Context مربوط به A | هیچ ردیفی تغییر یا حذف نمی‌شود؛ شیء B بدون تغییر باقی می‌ماند |
| P01-DB-06 | INSERT ردیف Tenant B در Context مربوط به A، با دور زدن HTTP | قاعده RLS از طریق WITH CHECK نوشتن را رد می‌کند؛ تراکنش ناموفق پیش از استفاده مجدد Pool Rollback می‌شود |
| P01-DB-07 | خواندن ردیف‌های Membership در Contextهای A و B | RLS جدول Membership فقط ردیف‌های متعلق به Tenant فعال را نمایش می‌دهد |
| P01-DB-08 | اتصال با LOGIN Role مستقل Tenant A/B؛ جعل GUC، تلاش تغییر Role/Session Authorization، Shadow کردن نام Identity Map در Temp Schema و Write جعلی | `session_user` دقیقاً به یک Tenant نگاشت می‌شود؛ Owner از نوع NOLOGIN و فاقد Privilege ممتاز است؛ SECURITY DEFINER با search_path ثابت در برابر Temp Shadowing مقاوم است؛ GUC قابل‌تغییر Tenant را عوض نمی‌کند و سوئیچ Role/خواندن Map/Write بین Tenantها رد می‌شود |
| P01-ASYNC-01 | ساخت Job توسط A/B و تلاش برای جعل Tenant در Caller | Job و Metadata Dispatch اتمیک هستند؛ Tenant از Principal می‌آید و Tenant جعلی رد می‌شود |
| P01-ASYNC-02 | بررسی Role مربوط به Dispatcher و تلاش برای خواندن Payload | Dispatcher فقط Metadata را می‌خواند/Claim می‌کند؛ SELECT روی Payload رد می‌شود و Role فاقد BYPASSRLS است |
| P01-ASYNC-03 | تغییر Tenant ID در Envelope امضاشده صف | اعتبارسنجی امضای Ed25519 پیش از هر دسترسی به داده Tenant شکست می‌خورد |
| P01-ASYNC-04 | Claim هم‌زمان توسط دو اتصال Dispatcher، تمدید Lease و Replay تحویل | `SKIP LOCKED` Jobهای مجزا می‌دهد؛ فقط Attempt جاری Ack می‌شود؛ اثر Job یک بار تکمیل می‌شود و Replay بی‌اثر است |
| P01-ASYNC-06 | ایجاد خطای Foreign Key در Dispatch پس از درج Job | کل Transaction Rollback می‌شود و Job یتیم باقی نمی‌ماند |
| P01-ASYNC-05 | لغو Membership کاربر پس از Enqueue و پیش از اجرا | Worker وضعیت Job را Rejected می‌کند و Payload را اجرا نمی‌کند |

## تفسیر امنیتی مهم

RLS یک لایه دفاع در عمق است و جایگزین احراز هویت، مجوز عضویت یا طراحی Tenant-aware در برنامه نیست. این برش اکنون Active Membership را در همان تراکنش دسترسی به داده Tenant بررسی و ردیف Membership را با FOR SHARE قفل می‌کند؛ ابطال بر درخواست‌های بعدی اثر می‌گذارد و ابطال هم‌زمان باید با تراکنش در حال اجرا Serialize شود. یک تنظیم سفارشی PostgreSQL فقط به این دلیل قابل اعتماد است که برنامه اتصال دیتابیس را کنترل می‌کند و مقدار را پس از احراز هویت Principal تنظیم می‌کند. یک تست Red-Team صریح نشان می‌دهد خود Role به نام app_runtime می‌تواند GUC سفارشی را به Tenant دیگری تغییر دهد و سپس ردیف‌های همان Tenant را بخواند. این یک افشای مورد انتظار در طراحی Role مشترک است، نه یک کنترل جداسازی موفق. بنابراین این Prototype فقط در برابر فراموش‌شدن Predicateهای Tenant در Query و Hintهای غیرقابل‌اعتماد Tenant در HTTP دفاع را نشان می‌دهد؛ اما جداسازی در برابر اجرای SQL دلخواه، SQL Injection یا تسخیر Credential مشترک برنامه را اثبات نمی‌کند. Query پارامتری، مرزهای سخت‌گیرانه Query، حداقل مجوز و تست Injection همچنان الزامی‌اند. مدل تهدید Production باید مشخص کند آیا Process مشترک برنامه بخشی از Trusted Computing Base است یا به سازوکار قوی‌تری برای احراز هویت Tenant در خود دیتابیس نیاز داریم. نسخه مقایسه‌ای Roleهای مستقل، RLS را به `session_user` در PostgreSQL متصل می‌کند؛ تنظیم `app.tenant_id` دیگر نتیجه را تغییر نمی‌دهد و Role اتصال نمی‌تواند بدون Membership صریح با `SET ROLE` به Tenant دیگر سوئیچ کند. این مدل دامنه اثر SQL Injection را برای اتصالی که از ابتدا با هویت یک Tenant احراز شده کاهش می‌دهد. اما در برابر تسخیر Credential Broker یا بخشی از برنامه که قادر به دریافت Credential تمام Tenantهاست محافظت کامل نمی‌کند. همچنین Credential جداگانه برای هر Tenant، چرخش Secret، Pool مستقل اتصال، Onboarding/Offboarding و احتمالاً تعداد اتصال بیشتر ایجاد می‌کند. این صرفاً آزمایش مقایسه‌ای است، نه معماری انتخاب‌شده. راهنمای AWS نیز این Trade-off عملیاتی را توضیح می‌دهد: متغیر Context در Runtime ساده‌تر است، درحالی‌که یک PostgreSQL User برای هر Tenant مدیریت User و Credential را افزایش می‌دهد.

جدول توسط Role مالک ساخته و مالکیت آن نگهداری می‌شود؛ برنامه فقط با Role به نام app_runtime متصل می‌شود. گزینه FORCE ROW LEVEL SECURITY فعال است. یک Policy پایه از نوع Permissive با Tenant Guard از نوع Restrictive ترکیب شده است: PostgreSQL Policyهای Permissive را با OR ترکیب می‌کند؛ بنابراین Guard محدودکننده همچنان با AND اعمال می‌شود و مانع گسترش دسترسی Tenant بر اثر افزودن یک Policy گسترده Permissive در آینده خواهد شد. Superuserهای PostgreSQL و Roleهای دارای BYPASSRLS می‌توانند RLS را دور بزنند؛ مالک جدول نیز معمولاً از آن مستثناست، مگر آنکه FORCE RLS فعال شود. مرجع رسمی: [مستندات Row Security در PostgreSQL 18](https://www.postgresql.org/docs/18/ddl-rowsecurity.html).

## موارد خارج از محدوده / هنوز اثبات‌نشده

- احراز هویت واقعی، ابطال Session، MFA، Workload Identity یا ذخیره‌سازی Production عضویت‌ها.
- آزمون Race هم‌زمانی ابطال Membership با Request در حال اجرا؛ تراکنش Request/Job ردیف Membership را با FOR SHARE قفل می‌کند تا ابطال با آن Serialize شود، اما این Race هنوز تحت بار آزمایش نشده است. PostgreSQL برای SELECT FOR SHARE به مجوز UPDATE روی حداقل یک ستون نیاز دارد؛ Role اجرایی فقط روی ستون غیرحساس lock_version این مجوز را دارد، نه روی Flag مجوزدهی active.
- Message Broker واقعی، تحویل Queue خارجی، Job زمان‌بندی‌شده، Backoff نمایی، Dead-letter Queue، تست هم‌زمانی/بار Dispatcher و اتصال KMS/چرخش کلید Production. جدول Dispatch فعلی یک شبیه‌سازی Outbox/Claim مستقل از Provider است، نه انتخاب یک محصول Queue.
- مجوزدهی Operator/Support/Break-glass و Audit.
- Jobهای صف، Retry، Jobهای زمان‌بندی‌شده و Replay.
- جداسازی Cache، Object Storage، Search، Export، Analytics و Reporting.
- بار هم‌زمان، توزیع نامتوازن Tenantها، ملاحظات Isolation Level و کارایی.
- ابطال Membership در زمان اجرای Request/Job.
- Failover دیتابیس، قطع اتصال هنگام Commit، Migration و Recovery.
- SQL Injection، تست نفوذ، بررسی امنیتی مستقل یا تأیید حقوقی/حریم خصوصی.

این موارد مانع از آن هستند که کل آزمایش P-01 در LOT-PROT-001 را قبول‌شده اعلام کنیم؛ حتی اگر این بخش HTTP/Database در CI موفق شود.

## روش اجرای مجدد

از این پوشه دیتابیس محلی موقت را اجرا کنید:

```sh
docker compose -f compose.yaml up -d --wait
export ADMIN_DATABASE_URL='postgres://postgres:p01-admin-only-not-production@127.0.0.1:55432/lottorito_p01'
export DATABASE_URL='postgres://app_runtime:p01-only-not-for-production@127.0.0.1:55432/lottorito_p01'
export DISPATCHER_DATABASE_URL='postgres://job_dispatcher:p01-dispatcher-not-for-production@127.0.0.1:55432/lottorito_p01'
export TENANT_A_DATABASE_URL='postgres://tenant_a_runtime:p01-tenant-a-not-for-production@127.0.0.1:55432/lottorito_p01'
export TENANT_B_DATABASE_URL='postgres://tenant_b_runtime:p01-tenant-b-not-for-production@127.0.0.1:55432/lottorito_p01'
npm ci --ignore-scripts --no-audit --no-fund
npm test
docker compose -f compose.yaml down
```

Workflow یک سرویس موقت PostgreSQL 18.7 ایجاد می‌کند و فقط از Credentialهای ساختگی استفاده می‌کند. Workflow امکان اجرای دستی نیز دارد. اسکریپت SQL جدول‌های Fixture مربوط به Prototype را حذف و دوباره ایجاد می‌کند و Roleهای ساختگی را Reset می‌کند؛ هرگز آن را به دیتابیس مشترک، Staging یا Production متصل نکنید. Credential مربوط به Dispatcher فقط یک مقدار آزمایشی ساختگی است؛ کلیدهای Ed25519 در هر اجرای تست به‌صورت موقت تولید می‌شوند و در مخزن ذخیره نمی‌شوند.

## محدودیت Dependency و CI

Dependency مستقیم pg در Prototype Pin شده است، اما هنوز npm Lockfile در مخزن Commit نشده؛ بنابراین بازتولیدپذیری Dependencyهای انتقالی و Pin کردن زنجیره تأمین باید در گام بعد تکمیل شود. GitHub Actions نیز در این آزمایش اولیه با Version Tag ارجاع داده شده‌اند، نه SHA تغییرناپذیر Commit. این‌ها محدودیت‌های صریح Prototype هستند، نه توصیه Production.

## ثبت نتیجه

- وضعیت پیاده‌سازی: فایل‌ها در شاخه spike/p01-tenant-isolation اضافه شده‌اند.
- نتیجه CI: موفق — اجرای GitHub Actions با شناسه [45411486646](https://github.com/tecpey/lottorito-platform/actions/runs/45411486646)، روی Head با شناسه `278ac96a161cd545ca60d4f9d43be220c9eabf16`. Node.js نسخه 26.13.0 + PostgreSQL نسخه 18.7؛ نصب با `npm ci` و Lockfile ثبت‌شده؛ ۱۹ تست Node موفق، صفر شکست و صفر تست Skip‌شده. اجرای Documentation Governance با شناسه [45411486650](https://github.com/tecpey/lottorito-platform/actions/runs/45411486650) نیز موفق شد. GitHub Actions با SHAهای Commit تغییرناپذیر Pin شده‌اند.
- اجرای موفق شامل تست‌های قبلی RLS در Request، Pool Reuse، بررسی مجدد Membership و مسیر Async Outbox/Dispatcher/Envelope امضاشده Ed25519 است؛ همچنین تست مقایسه‌ای LOGIN Roleهای مستقل Tenant را پوشش می‌دهد: هویت Session دقیقاً به یک Tenant نگاشت می‌شود؛ تغییر GUC قابل‌تغییر، Visibility را تغییر نمی‌دهد؛ `SET ROLE` به Tenant دیگر، خواندن Identity Map خصوصی و Insert بین Tenantها رد می‌شود.
- تست Red-Team عمدی همچنان نشان می‌دهد Role مشترک `app_runtime` در صورت تسخیر می‌تواند GUC سفارشی را به Tenant دیگری تغییر دهد. این یک مرز اعتماد شناخته‌شده است، نه اثبات جداسازی در برابر نفوذگر. مدل LOGIN Role مستقل در برابر SQL Injection محدود به اتصال یک Tenant مقاوم‌تر است، اما به Credential Broker امن و Poolهای تفکیک‌شده وابسته است؛ این کنترل‌های عملیاتی و رفتار در مقیاس هنوز آزمایش نشده‌اند.
- اجرای محلی: در این محیط اجرا نشده است؛ اجرای تأییدشده در CI میزبانی‌شده GitHub انجام شده است.
- وضعیت کلی P-01: نامعین / فقط بخشی از محدوده. آزمایش مقایسه‌ای یک الگوی هویت دیتابیس را در Fixture ساختگی اثبات می‌کند، نه جداسازی End-to-End در Cache، Object Storage، Search، Export، Reporting، Support، Workload Identity یا مرزهای Deployment.
- تصمیم فناوری: همچنان Proposed است؛ هیچ تصویب نهایی Stack از این آزمایش استنباط نمی‌شود.

## مراجع

- LOT-PROT-001 — برنامه Prototype و شواهد معماری.
- LOT-TECH-ADR-001 — ADR فناوری، استقرار و قابلیت اطمینان.
- PostgreSQL 18 — [سیاست‌های Row Security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html)، [توابع اطلاعات Session](https://www.postgresql.org/docs/18/functions-info.html)، [SET ROLE](https://www.postgresql.org/docs/18/sql-set-role.html)، [SET SESSION AUTHORIZATION](https://www.postgresql.org/docs/18/sql-set-session-authorization.html)، [CREATE FUNCTION و امنیت SECURITY DEFINER](https://www.postgresql.org/docs/18/sql-createfunction.html) و [مجوزها](https://www.postgresql.org/docs/18/ddl-priv.html) (الزام مجوز SELECT FOR SHARE).
- OWASP — [راهنمای امنیت چندمستاجری](https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html)، شامل منشأ Tenant Context، Context تراکنش‌محور و انتخاب راهبرد جداسازی.
- AWS — [انتخاب الگوی دسترسی PostgreSQL مناسب برای SaaS](https://aws.amazon.com/blogs/database/choose-the-right-postgresql-data-access-pattern-for-your-saas-application/)، شامل Trade-off متغیرهای Runtime مشترک و Roleهای دیتابیس مستقل برای هر Tenant.
- AWS Prescriptive Guidance — [الگوی Transactional Outbox](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html)، شامل نوشتن اتمیک Outbox و Consumerهای Idempotent با تحویل At-least-once.
- PostgreSQL 18 — [قفل‌گذاری در SELECT](https://www.postgresql.org/docs/current/sql-select.html)، شامل `SKIP LOCKED` برای Claim چندمصرف‌کننده‌ای شبیه Queue.
- Node.js — [برنامه انتشار و پشتیبانی](https://github.com/nodejs/Release).
