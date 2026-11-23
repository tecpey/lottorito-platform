# نقشه راه اجرایی Lottorito

**شناسه:** LOT-ROAD-001 | **نسخه:** 0.1.0 | **وضعیت:** پیشنهادی و وابسته به بازبینی

1. **Foundation & Governance:** تکمیل اسناد، واژه‌نامه، ADR، قواعد مشارکت و parity CI.
2. **Domain & Data Design:** مدل دامنه، ERD، چرخه عمر داده، tenant boundaries و migration strategy.
3. **Platform Skeleton:** انتخاب stack، اسکلت API/Worker/Web، config امن، logging، health و CI پایه.
4. **Identity & Tenant:** هویت، نشست، RBAC، عضویت Tenant و تست جداسازی.
5. **Affiliate & Attribution:** پروفایل، شبکه ارجاع، لینک رهگیری، رویداد و انتساب.
6. **Finance Core:** Chart of Accounts، Ledger، invariants، statement و reconciliation.
7. **Commission Engine:** قوانین نسخه‌بندی‌شده، CPA/RS/Hybrid و محاسبات بازتولیدپذیر.
8. **Partner Pilot:** دریافت مستندات و Sandbox واقعی، ساخت Adapter و contract tests.
9. **Admin & Reporting:** داشبوردها، audit، گزارش‌ها و گردش‌کار برداشت.
10. **Hardening & Pilot:** threat model، تست بار/امنیت، بازیابی پشتیبان، UAT و تأیید حقوقی.

## دروازه عبور
هیچ مرحله‌ای صرفاً با پایان کدنویسی تمام نمی‌شود؛ معیارهای پذیرش، تست، بازبینی امنیت، اسناد دوزبانه و شواهد باید تکمیل شوند. Merge/Deploy عملیاتی تابع مجوزهای مالک است.