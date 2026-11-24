# نقشه راه اجرایی Lottorito

**شناسه:** LOT-ROAD-001 | **نسخه:** ۰.۳.۰ | **وضعیت:** توالی پیشنهادی؛ دروازه‌های محصول نیازمند تأیید مالک

۱. **Foundation & Governance:** راهنمای دوزبانه ایجنت، Decision Register، شناسه پایدار اسناد، واژه‌نامه، قواعد مشارکت و کنترل خودکار مستندات؛ خط مبنای مالی، امنیت و API تا زمان بازبینی صریحاً پیشنهادی می‌ماند.
۲. **Cross-product Domain & Data Design:** بازبینی LOT-DOM-001؛ تصویب Bounded Context مستقل Affiliate و Lottery، مالکیت قابلیت مشترک، ERD منطقی، چرخه داده، مرز Tenant و راهبرد Migration.
۳. **Tenant & Security Architecture:** بازبینی LOT-TEN-001 و LOT-SEC-TM-001؛ تکمیل هویت/عضویت، زمینه Worker، تحلیل مرز اعتماد و سوءاستفاده، راستی‌آزمایی جداسازی، دسترسی پشتیبانی و کنترل پاسخ رخداد.
۴. **API & Event Foundation:** بازبینی LOT-API-001 و LOT-EVENT-001؛ نهایی‌سازی قرارداد Resource/احراز هویت، سازگاری Schema، Inbox/Outbox، Idempotency، امضای Webhook و کنترل Replay.
۵. **Technology & Platform ADRs:** بازبینی LOT-TECH-ADR-001؛ اجرای Prototypeهای لازم و اخذ تأیید مالک/امنیت/مالی/حقوقی پیش از انتخاب Stack، Hosting، Region یا SLO/RPO/RTO عددی.
۶. **Identity & Tenant Implementation:** هویت، نشست، RBAC، عضویت Tenant و تست جداسازی.
۷. **Affiliate & Attribution:** پروفایل، شبکه ارجاع، لینک رهگیری، رویداد و انتساب.
۸. **Finance Core:** بازبینی LOT-FIN-POST-001؛ تصویب مالکیت حساب، Chart of Accounts، ثبت تغییرناپذیر، معنای موجودی، صورت‌حساب، تطبیق و دروازه‌های پرداخت.
۹. **Commission Engine:** قوانین نسخه‌بندی‌شده، CPA/Revenue Share/Hybrid و محاسبات بازتولیدپذیر.
۱۰. **Affiliate Partner Pilot:** دریافت مستندات و Sandbox واقعی شریک، ساخت Adapter افیلیت و Contract Test.
۱۱. **Lottery Provider Discovery & Certification:** بررسی حقوقی/ارائه‌دهنده، پروفایل قابلیت، شواهد Sandbox، Adapter چرخه عمر و تطبیق نتیجه/تسویه؛ فقط پس از تأیید مالک.
۱۲. **Admin, Reporting & Operations:** تجربه اپراتور/ایجنت/مشتری، Audit، گزارش، پشتیبانی و گردش‌کار مالی کنترل‌شده.
۱۳. **Hardening & Pilot:** تست بار/امنیت، بازیابی پشتیبان، UAT، آمادگی عملیات و تأیید حقوقی مختص حوزه قضایی.

## دروازه عبور
هیچ مرحله‌ای صرفاً با پایان کدنویسی تمام نمی‌شود. تصمیم‌های مالک، معیارهای پذیرش، تست، بازبینی امنیت، مستندات دوزبانه و شواهد باید تکمیل شوند. Merge/Deploy عملیاتی فقط با تأیید صریح مالک مجاز است.