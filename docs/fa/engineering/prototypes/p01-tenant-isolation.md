# P-01 — نمونه جداسازی Tenant

**شناسه سند:** LOT-PROT-P01-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیاده‌سازی‌شده در شاخه آزمایشی؛ اجرای CI هنوز تأیید نشده است | **تاریخ بازبینی:** ۲۰۲۶-۱۱-۲۴

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

## سناریوهای پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P01-HTTP-01 | نبود یا نامعتبر بودن Credential ساختگی | پاسخ 401؛ بدون دسترسی به داده |
| P01-HTTP-02 | فهرست رکوردهای Tenant A و B | هر Tenant فقط Fixture خودش را می‌بیند |
| P01-HTTP-03 | جعل هدر Tenant | Tenant احراز هویت‌شده تغییر نمی‌کند |
| P01-HTTP-04 | UUID یکسان شیء در دو Tenant | هر Tenant فقط سطر خودش را می‌بیند |
| P01-HTTP-05 | شناسه Tenant متعارض در بدنه Write | پاسخ 403؛ بدون اثر جانبی |
| P01-HTTP-06 | Write بدون Tenant ID ارسالی کاربر | سرور Tenant احراز هویت‌شده را تخصیص می‌دهد |
| P01-DB-01 | اجرای متناوب A/B/A با Pool تک‌اتصالی | نشت Context بین درخواست‌ها رخ نمی‌دهد |
| P01-DB-02 | بررسی Role اجرایی و تنظیمات جدول | نه Superuser، نه مالک جدول و نه BYPASSRLS؛ RLS و FORCE RLS فعال |
| P01-DB-03 | Query/Insert بدون Tenant Context | Select هیچ سطری نمی‌بیند؛ Insert رد می‌شود |

## تفسیر امنیتی مهم

RLS یک لایه دفاع در عمق است و جایگزین احراز هویت، مجوز عضویت یا طراحی Tenant-aware در برنامه نیست. یک تنظیم سفارشی PostgreSQL فقط به این دلیل قابل اعتماد است که برنامه اتصال دیتابیس را کنترل می‌کند و مقدار را پس از احراز هویت Principal تنظیم می‌کند. هر نوع اجرای SQL دلخواه با Role اجرایی می‌تواند تلاش کند همین تنظیم سفارشی را تغییر دهد؛ بنابراین Query پارامتری، مرزهای سخت‌گیرانه Query، حداقل مجوز و تست SQL Injection همچنان الزامی‌اند.

جدول توسط Role مالک ساخته و مالکیت آن نگهداری می‌شود؛ برنامه فقط با Role به نام app_runtime متصل می‌شود. گزینه FORCE ROW LEVEL SECURITY فعال است. Superuserهای PostgreSQL و Roleهای دارای BYPASSRLS می‌توانند RLS را دور بزنند؛ مالک جدول نیز معمولاً از آن مستثناست، مگر آنکه FORCE RLS فعال شود. مرجع رسمی: [مستندات Row Security در PostgreSQL 18](https://www.postgresql.org/docs/18/ddl-rowsecurity.html).

## موارد خارج از محدوده / هنوز اثبات‌نشده

- احراز هویت واقعی، ابطال Session، MFA، Workload Identity یا ذخیره‌سازی Production عضویت‌ها.
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
npm install --ignore-scripts --no-audit --no-fund
npm test
docker compose -f compose.yaml down
```

Workflow یک سرویس موقت PostgreSQL 18.7 ایجاد می‌کند و فقط از Credentialهای ساختگی استفاده می‌کند. Workflow امکان اجرای دستی نیز دارد. اسکریپت SQL جدول Prototype را حذف و دوباره ایجاد می‌کند؛ هرگز آن را به دیتابیس مشترک، Staging یا Production متصل نکنید.

## محدودیت Dependency و CI

Dependency مستقیم pg در Prototype Pin شده است، اما هنوز npm Lockfile در مخزن Commit نشده؛ بنابراین بازتولیدپذیری Dependencyهای انتقالی و Pin کردن زنجیره تأمین باید در گام بعد تکمیل شود. GitHub Actions نیز در این آزمایش اولیه با Version Tag ارجاع داده شده‌اند، نه SHA تغییرناپذیر Commit. این‌ها محدودیت‌های صریح Prototype هستند، نه توصیه Production.

## ثبت نتیجه

- وضعیت پیاده‌سازی: فایل‌ها در شاخه spike/p01-tenant-isolation اضافه شده‌اند.
- نتیجه CI: اجرا نشده / هنوز مشاهده نشده در زمان ثبت این سند.
- اجرای محلی: در این محیط اجرا نشده است.
- وضعیت کلی P-01: نامعین / فقط بخشی از محدوده تا زمان آزمایش مرزهای Async، ابطال دسترسی، Support ممتاز و سایر مسیرهای ذخیره‌سازی.
- تصمیم فناوری: همچنان Proposed است؛ هیچ تصویب نهایی Stack از این آزمایش استنباط نمی‌شود.

## مراجع

- LOT-PROT-001 — برنامه Prototype و شواهد معماری.
- LOT-TECH-ADR-001 — ADR فناوری، استقرار و قابلیت اطمینان.
- PostgreSQL 18 — [سیاست‌های Row Security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html).
- Node.js — [برنامه انتشار و پشتیبانی](https://github.com/nodejs/Release).
