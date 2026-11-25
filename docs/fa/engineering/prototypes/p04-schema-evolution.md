# P-04 — تکامل Schema و سازگاری

**شناسه سند:** LOT-PROT-P04-001 | **نسخه:** ۰.۳.۰ | **وضعیت:** Prototype ساختگی؛ ۸ تست CI موفق؛ بدون تصویب Migration عملیاتی

## هدف

یک آزمایش موقت PostgreSQL، تکامل Schema را هنگام هم‌زیستی Roleهای برنامه نسخه v1/v2 بررسی می‌کند. PostgreSQL 18.7، Node.js 26.13.0 و pg 8.23.1 ورودی آزمایش‌اند، نه فناوری مصوب پلتفرم.

## محدوده

- Partner Event محدود به Tenant با Payload قدیمی و ستون افزایشی canonical_payload.
- دو Tenant ساختگی با Roleهای LOGIN نسخه v1/v2 مستقل و نگاشت به هویت یکسان Tenant؛ RLS هویت را از session_user استخراج می‌کند.
- Trigger سازگاری دوطرفه Writer قدیمی/جدید؛ Dual-write متناقض رد می‌شود.
- Migration Runner تراکنشی با Checksum از نوع SHA-256، Advisory Lock، Replay تکرارپذیر و رد Fail-closed تغییر Checksum.
- Backfill محدود و قابل ادامه با قفل ردیف و SKIP LOCKED.
- تست شکست Lock Timeout و بازیابی Index Concurrent نامعتبر.
- Constraint مرحله‌ای NOT VALID و اعتبارسنجی جداگانه.
- کنترل Invariantهای نماینده Ledger و Reporting قبل/بعد.
- فقط تمرین غیرمخرب Contract؛ ستون قدیمی حفظ می‌شود.

## پذیرش

P04-COMPAT: هم‌زیستی Writer/Reader قدیم و جدید و رد تعارض.
P04-BACKFILL: توقف/اتصال مجدد و ادامه محدود به Tenant.
P04-TENANT: رد دسترسی بین Tenantها و جعل مالکیت با RLS.
P04-MIGRATION: Replay تکرارپذیر، رد تغییر Checksum و Rollback شکست Migration.
P04-LOCK: توقف DDL مسدودشده با lock_timeout بدون تغییر ناقص Schema.
P04-INDEX: شناسایی و اصلاح شکست ساخت Concurrent Unique Index.
P04-FINANCE: حفظ تعداد Journal/Line، توازن Debit/Credit و مجموع Reporting.
P04-CONTRACT: بررسی برابری Projection؛ ستون قدیمی حذف نمی‌شود.
P04-PAYLOAD-INVARIANT: هیچ Writer قدیمی یا جدیدی نمی‌تواند هر دو نمایش Payload را خالی کند؛ مقادیر قبلی در شکست Update حفظ می‌شوند.

## محدودیت‌ها

Zero Downtime، رفتار Lock/Backfill در مقیاس Production، CDC، جدول Partitionشده، چندمنطقه‌ای یا Migration عملیاتی اثبات نمی‌شود. Trigger انتقالی است و نیازمند بررسی بار واقعی است. Migration Runner چارچوب کامل نیست. Contract ستون را حذف یا Rename نمی‌کند؛ Migration مخرب پس از بازنشستگی نسخه‌های قدیمی و راستی‌آزمایی مستقل داده، نیازمند تأیید صریح مالک است. Fixtureهای P-02/P-03 تغییر یا متصل نمی‌شوند. داده و Credential فقط ساختگی‌اند.

## شواهد

Integration با شناسه [45619282469](https://github.com/tecpey/lottorito-platform/actions/runs/45619282469) روی Head دقیق `27f8dd2b089574c980c25c862e97525b57ff96be` هر ۸ تست را با صفر شکست و صفر Skip گذرانده است. تست جدید جلوگیری از خالی‌شدن هم‌زمان دو نمایش Payload نیز موفق شده است. Documentation Governance با شناسه [45619282483](https://github.com/tecpey/lottorito-platform/actions/runs/45619282483) روی همان Head موفق شده است. محیط اجرا PostgreSQL 18.7، Node.js 26.13.0، npm ci و pg 8.23.1 بوده است. این موفقیت فقط آزمایش ساختگی است و به‌معنای آمادگی Production یا تصویب فناوری نیست. PostgreSQL 18.7، Node.js 26.13.0، npm ci و pg 8.23.1 استفاده شده‌اند. موفقیت تست ساختگی به‌معنای آمادگی Production یا تصویب فناوری نیست.
