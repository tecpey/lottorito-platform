# P-04 — تکامل Schema و سازگاری

**شناسه سند:** LOT-PROT-P04-001 | **نسخه:** ۰.۲.۰ | **وضعیت:** Prototype ساختگی؛ ۷ تست CI موفق؛ بدون تصویب Migration عملیاتی

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

## محدودیت‌ها

Zero Downtime، رفتار Lock/Backfill در مقیاس Production، CDC، جدول Partitionشده، چندمنطقه‌ای یا Migration عملیاتی اثبات نمی‌شود. Trigger انتقالی است و نیازمند بررسی بار واقعی است. Migration Runner چارچوب کامل نیست. Contract ستون را حذف یا Rename نمی‌کند؛ Migration مخرب پس از بازنشستگی نسخه‌های قدیمی و راستی‌آزمایی مستقل داده، نیازمند تأیید صریح مالک است. Fixtureهای P-02/P-03 تغییر یا متصل نمی‌شوند. داده و Credential فقط ساختگی‌اند.

## شواهد

اجرای Integration با شناسه [45471750215](https://github.com/tecpey/lottorito-platform/actions/runs/45471750215) تعداد ۷ تست موفق، صفر شکست و صفر Skip روی Head کد 15c536e5be2f61b1805191f5977a46b17eaf1971 داشته است؛ اجرای تکراری Push با شناسه [45471737779](https://github.com/tecpey/lottorito-platform/actions/runs/45471737779) نیز موفق بوده است. Documentation Governance با شناسه [45471750133](https://github.com/tecpey/lottorito-platform/actions/runs/45471750133) روی همان Head موفق شده است. PostgreSQL 18.7، Node.js 26.13.0، npm ci و pg 8.23.1 استفاده شده‌اند. موفقیت تست ساختگی به‌معنای آمادگی Production یا تصویب فناوری نیست.


## اعتبارسنجی روی زنجیره Rebaseشده — ۲۰۲۶-۱۱-۲۵

Head کد PR اصلی شماره ۵۱، مجموعه هفت‌تستی P-04 را با موفقیت گذرانده بود؛ اما آن شاخه هم‌سطح P-03C/P-03D بود. این Prototype به شاخه `spike/p04-schema-evolution-p03d` منتقل شده که والد آن PR شماره ۶۱ در P-03D است. تست P-04 همراه Regression مربوط به P-02/P-03C/P-03D و Documentation Governance دوزبانه باید روی Head جدید PR دوباره اجرا شوند. تا آن زمان اجرای هفت‌تستی اصلی فقط شاهد تاریخی است و وضعیت P-04 در زنجیره Rebaseشده در انتظار راستی‌آزمایی باقی می‌ماند.


## CI تأییدشده روی زنجیره تطبیق‌یافته — ۲۰۲۶-۱۱-۲۵

Head دقیق کد آزمایش‌شده: `dca0762678ed45da122ba109276c54ce61ac0846`.

- Regression مربوط به P-02: [اجرای ۱۱۹](https://github.com/tecpey/lottorito-platform/actions/runs/45608274029) — ۲۵ موفق، صفر شکست و صفر Skip.
- Regression مربوط به P-03C/P-03D: [اجرای ۳۸](https://github.com/tecpey/lottorito-platform/actions/runs/45608274098) — ۱۵ تست P-03C و ۱۹ تست P-03D موفق؛ در مجموع ۳۴ تست، صفر شکست و صفر Skip.
- تکامل Schema در P-04: [اجرای ۲۲](https://github.com/tecpey/lottorito-platform/actions/runs/45608274118) — ۷ موفق، صفر شکست و صفر Skip.
- Documentation Governance دوزبانه: [اجرای ۷۰۷](https://github.com/tecpey/lottorito-platform/actions/runs/45608274060) — موفق.

هر چهار Workflow روی یک Head دقیق کد با موفقیت کامل شدند. این نتیجه فقط آزمایش ساختگی P-04 را در زنجیره تطبیق‌یافته P-03D راستی‌آزمایی می‌کند؛ ایمنی Migration عملیاتی، Zero Downtime یا تصویب فناوری را اثبات نمی‌کند.
