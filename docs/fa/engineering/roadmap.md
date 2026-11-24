# نقشه راه اجرایی Lottorito

**شناسه:** LOT-ROAD-001 | **نسخه:** 0.1.0 | **وضعیت:** پیشنهادی و وابسته به بازبینی

۱. **Foundation & Governance:** راهنمای دوزبانه ایجنت، Decision Register، فهرست اسناد، واژه‌نامه، ADR، قواعد مشارکت و CI هم‌ارزی زبان‌ها.
۲. **Cross-product Domain & Data Design:** Bounded Context مستقل Affiliate و Lottery، مالکیت قابلیت مشترک، مدل دامنه، ERD، چرخه عمر داده، مرز Tenant و راهبرد Migration.
3. **Platform Skeleton:** انتخاب stack، اسکلت API/Worker/Web، config امن، logging، health و CI پایه.
4. **Identity & Tenant:** هویت، نشست، RBAC، عضویت Tenant و تست جداسازی.
5. **Affiliate & Attribution:** پروفایل، شبکه ارجاع، لینک رهگیری، رویداد و انتساب.
6. **Finance Core:** Chart of Accounts، Ledger، invariants، statement و reconciliation.
7. **Commission Engine:** قوانین نسخه‌بندی‌شده، CPA/RS/Hybrid و محاسبات بازتولیدپذیر.
۸. **Affiliate Partner Pilot:** دریافت مستندات و Sandbox واقعی شریک، ساخت Adapter افیلیت و Contract Test.
۹. **Lottery Provider Discovery & Certification:** بررسی حقوقی/ارائه‌دهنده، پروفایل قابلیت، شواهد Sandbox، Adapter چرخه عمر و تطبیق نتیجه/تسویه؛ فقط پس از تأیید مالک.
۱۰. **Admin, Reporting & Operations:** تجربه اپراتور/ایجنت/مشتری، Audit، گزارش، پشتیبانی و گردش‌کار مالی کنترل‌شده.
۱۱. **Hardening & Pilot:** Threat Model، تست بار/امنیت، بازیابی پشتیبان، UAT، آمادگی عملیات و تأیید حقوقی مختص حوزه قضایی.

## دروازه عبور
هیچ مرحله‌ای صرفاً با پایان کدنویسی تمام نمی‌شود؛ معیارهای پذیرش، تست، بازبینی امنیت، اسناد دوزبانه و شواهد باید تکمیل شوند. Merge/Deploy عملیاتی تابع مجوزهای مالک است.