# P-04 — تکامل Schema و سازگاری

**شناسه سند:** LOT-PROT-P04-001 | **نسخه:** ۰.۳.۰ | **وضعیت:** آزمایش Migration ساختگی؛ جداسازی Tenant/Product؛ CI مربوط به P-09L موفق شد (۸ از ۸)

## هدف

یک آزمایش موقت PostgreSQL، تمرین Expand/Backfill/Validate/Contract را هنگام هم‌زیستی Roleهای برنامه نسخه v1/v2 بررسی می‌کند. P-04 یک آزمایشگاه مستقل Migration است و Schemaهای عملیاتی P-02/P-03 را تغییر نمی‌دهد.

## هویت محصول در P-09L

- Role Map هر نقش دیتابیس را به هر دو شناسه `tenant_id` و `product_id` Canonical متصل می‌کند.
- Tenant A نقش‌های v1/v2 مستقل برای Affiliate & Agent و نقش‌های v1/v2 جداگانه برای Lottery دارد. Tenant B همچنان Affiliate & Agent است.
- هویت Partner Event برابر `(tenant_id, product_id, event_id)` است؛ RLS و Backfill قابل‌ادامه نیز همین Tuple را اعمال می‌کنند.
- هویت Journal برابر `(tenant_id, product_id, journal_id)` است؛ هویت Line و Foreign Key مربوط به Journal نیز محصول را شامل می‌شوند.
- هویت Reporting برابر `(tenant_id, product_id, report_day)` است؛ RLS محصول را نیز کنترل می‌کند.
- Fixtureهای ساختگی عمداً همان UUID رویداد و Journal را در Affiliate & Agent و Lottery برای Tenant A دوباره استفاده می‌کنند.
- Writerهای قدیمی/جدید در هر محصول مستقل هم‌زیستی می‌کنند. حتی با UUID یکسان، یک Role نمی‌تواند ردیف‌های محصول دیگر را بخواند یا بنویسد.

## آزمایش مهاجرت موجود

- Trigger سازگاری دوطرفه برای ستون‌های Payload قدیمی/جدید؛ Dual-write متناقض رد می‌شود.
- Migration Runner تراکنشی با Checksum از نوع SHA-256، Advisory Lock، Replay تکرارپذیر و رد Fail-closed تغییر Checksum.
- Backfill محدود و قابل ادامه با قفل ردیف و SKIP LOCKED، همراه با Predicate صریح Tenant/Product.
- تست شکست Lock Timeout و بازیابی Index Concurrent نامعتبر.
- Constraint مرحله‌ای NOT VALID و اعتبارسنجی جداگانه.
- کنترل Invariantهای نماینده Ledger و Reporting قبل/بعد.
- فقط تمرین غیرمخرب Contract؛ ستون قدیمی حفظ می‌شود.

## پذیرش

P04-COMPAT: هم‌زیستی Writer/Reader قدیم و جدید در Affiliate و Lottery.
P04-BACKFILL: توقف/اتصال مجدد و ادامه مستقل برای هر Tenant/Product.
P04-TENANT-PRODUCT: رد دسترسی بین Tenantها و محصولات و جعل مالکیت با RLS.
P04-IDENTITY: پذیرش UUID یکسان Event/Journal در دو محصول، با هویت مرکب مستقل.
P04-MIGRATION: Replay تکرارپذیر، رد تغییر Checksum و Rollback شکست Migration.
P04-LOCK: توقف DDL مسدودشده با lock_timeout بدون تغییر ناقص Schema.
P04-INDEX: شناسایی و اصلاح شکست ساخت Index با ایندکس بازیابی Tenant/Product-aware.
P04-FINANCE: حفظ تعداد Journal/Line، توازن Debit/Credit و مجموع Reporting هر محصول.
P04-CONTRACT: بررسی برابری Projection؛ ستون قدیمی حذف نمی‌شود.

## محدودیت‌ها

Zero Downtime، رفتار Lock/Backfill در مقیاس Production، CDC، جدول Partitionشده، چندمنطقه‌ای یا Migration عملیاتی اثبات نمی‌شود. Trigger انتقالی است و نیازمند بررسی بار واقعی است. Migration Runner چارچوب کامل نیست. Contract ستون را حذف یا Rename نمی‌کند؛ Migration مخرب پس از بازنشستگی نسخه‌های قدیمی و راستی‌آزمایی مستقل داده، نیازمند تأیید صریح مالک است. هیچ داده، Credential یا Schema عملیاتی تغییر نمی‌کند. موفقیت تست ساختگی به‌معنای آمادگی Production نیست.

**شواهد CI مربوط به P-09L:** [اجرای 45863086577](https://github.com/tecpey/lottorito-platform/actions/runs/45863086577) — موفق، ۸ از ۸ تست روی PostgreSQL 18.7. این تست‌ها جداسازی Event/Journal با UUID یکسان بر اساس محصول، رد Foreign Key مرکب Journal-Line، RLS بین محصولات و رد مقدار Legacy یعنی `shared` را پوشش می‌دهند. Head دقیق کد: `a3c06e62a0a83d8ff73e81797d991242d9d5e489`.

## اعتبارسنجی P-09K روی Head دقیق (۲۰۲۶-۱۱-۲۶)

آزمایش سازگاری تکامل Schema در P-04 روی Head دقیق `75fd23701d4e28f047f8ebb73ea0b684bb144c7a` موفق شد: [Workflow شماره 45863298488](https://github.com/tecpey/lottorito-platform/actions/runs/45863298488)، شامل ۸ از ۸ تست Integration. این همچنان یک آزمایشگاه Migration ایزوله است و شاهدی برای اجرای Migration در Production محسوب نمی‌شود.
