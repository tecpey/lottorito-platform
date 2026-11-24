# معماری کلان Lottorito

**شناسه:** LOT-ARCH-001 | **نسخه:** ۰.۲.۰ | **وضعیت:** پیشنهاد معماری، نه تصمیم نهایی

## رویکرد
معماری دامنه‌محور، ماژولار، API-first و چندمستاجری. پیشنهاد اولیه Modular Monolith با مرزهای روشن است؛ استخراج سرویس مستقل فقط با توجیه مقیاس یا نیاز عملیاتی.

## دامنه‌ها
Identity & Access؛ Tenant & Partner؛ Affiliate & Agent Network؛ Tracking & Attribution؛ Partner Integration؛ Commission & Rules؛ Wallet & Ledger؛ Payout & Reconciliation؛ Campaign & Loyalty؛ Reporting & Audit؛ Sportsbook/Event Wagering (آینده)؛ Live Casino (آینده)؛ محتوای RNG/E-Gaming (آینده)؛ Poker/Peer-to-Peer Games (تصمیم مستقل آینده).

هر دامنه مالک منطق و داده خود است. دسترسی مستقیم به جداول داخلی دامنه دیگر ممنوع و ارتباط از قراردادهای مشخص انجام می‌شود.

## فناوری‌های پیشنهادی
هیچ Stack نهایی تصویب نشده است. LOT-TECH-ADR-001 چارچوب تصمیم فعلی است. PostgreSQL گزینه مخزن حقیقت اولیه و Modular Monolith همراه Transactional Outbox و Worker فرضیه شروع است. انتخاب Broker صف، Workflow Engine، Framework، ORM، Hosting، Cloud Region و Kubernetes به ADR مبتنی بر شواهد و Prototype نیاز دارد. پیشنهاد قبلی Next.js تصمیم نهایی نیست.

## چندمستاجری
هر رکورد باید tenant scope داشته باشد؛ tenant از نشست/عضویت معتبر استخراج شود، نه ورودی قابل جعل. تست منفی دسترسی بین Tenant اجباری است. RLS می‌تواند دفاع تکمیلی باشد، نه جایگزین مجوزدهی برنامه.

## جریان رویداد
دریافت خام ← اعتبارسنجی منبع/امضا ← ذخیره محدودشده ← idempotency و deduplication ← نرمال‌سازی ← attribution ← ارزیابی قانون نسخه‌بندی‌شده ← ثبت دفترکل ← گزارش و تطبیق.

## قابلیت اطمینان
تراکنش اتمیک برای عملیات مالی؛ الگوی outbox؛ retry محدود با backoff؛ صف بررسی خطاهای دائمی؛ لاگ ساختاریافته، metrics، tracing و هشدار مغایرت.

## قابلیت‌های تجربه جهانی
اسناد LOT-I18N-001، LOT-COMMS-001، LOT-GROWTH-001 و LOT-NOTIF-001 قابلیت‌ها و قراردادهای یکپارچه‌سازی پیشنهادی را تعریف می‌کنند. این قابلیت‌ها باید Tenant/Product-aware بمانند؛ قابلیت مشترک پلتفرم نباید وابستگی پنهان میان Affiliate و Lottery ایجاد کند.

## دامنه‌های آینده بازی تحت نظارت
LOT-GAMING-STRATEGY-001، Sportsbook، Live Casino و RNG/E-Gaming را به‌عنوان Bounded Contextهای مستقل آینده با Adapter ارائه‌دهنده، State Machine چرخه عمر، Entitlement، صلاحیت حوزه قضایی، معنای مالی و دروازه انتشار مستقل تعریف می‌کند. این موارد فقط افق نقشه راه‌اند؛ هیچ Provider، مجوز، API، Runtime یا راه‌اندازی بازار تصویب نشده است. اولویت تحویل همچنان Affiliate و پس از آن Lottery است؛ هر دامنه بعدی به شواهد حقوقی، Provider، مالی، امنیتی و Certification مستقل نیاز دارد.

## تصمیم‌های باز
مقیاس، مناطق استقرار، دسترس‌پذیری، پشتیبان‌گیری، RPO/RTO، جداسازی فیزیکی Tenant و فناوری‌های نهایی باید پیش از Production تعیین شوند.