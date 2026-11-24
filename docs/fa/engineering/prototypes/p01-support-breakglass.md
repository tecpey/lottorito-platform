# نمونه دسترسی پشتیبانی و Break-Glass در P-01

**شناسه سند:** LOT-PROT-P01-SUPPORT-001  
**نسخه:** ۰.۱.۰  
**وضعیت:** برش آزمایشی با داده ساختگی پیاده‌سازی شده؛ تأیید CI در انتظار  
**آزمایش مادر:** LOT-PROT-P01-001 / PR شماره ۳۶

## هدف

آزمایش یک مسیر دسترسی پشتیبانی محدود، زمان‌دار و فقط‌خواندنی، بدون اعطای دسترسی مستقیم به جدول‌های Payload مربوط به Tenant یا Credential گسترده دیتابیس به هویت‌های پشتیبانی.

این آزمایش با داده‌های ساختگی و محیط دورریختنی انجام می‌شود؛ کنسول پشتیبانی Production نیست و هیچ دسترسی واقعی به مشتری ایجاد نمی‌کند.

## مرزهای اعتماد پیشنهادی

- Principal پشتیبانی از عضو Tenant متمایز است و نمی‌تواند از مسیرهای عادی Tenant استفاده کند.
- Grant پشتیبانی باید Subject پشتیبان، Tenant هدف، دامنه منبع، دلیل قابل‌خواندن برای انسان، زمان انقضا و وضعیت لغو را به هم متصل کند.
- Caller می‌تواند شناسه Grant و Tenant هدف را ارسال کند، اما هیچ‌کدام اثبات مجوز نیستند. دیتابیس باید هر دو را با Subject احراز‌شده پشتیبان و Grant فعال تطبیق دهد.
- Role اختصاصی Support Authorizer می‌تواند Metadata مربوط به Grant را بخواند و رویداد Audit اضافه کند. RLS، Metadata مربوط به Grant و درج Audit را با Context تراکنشی تنظیم‌شده توسط API مورداعتماد، به Subject احراز‌شده پشتیبان محدود می‌کند. این Role اجازه خواندن رکوردهای Tenant، Jobها، Wallet یا سایر جدول‌های Payload را ندارد. این Context یک مرز اعتماد در سطح برنامه است و در برابر تسخیر Credential مربوط به Support Authorizer یا اجرای SQL دلخواه محافظت نمی‌کند.
- Role اجرایی Tenant با حداقل مجوز، خواندن واقعی داده را در تراکنش RLS محدود به همان Tenant انجام می‌دهد.
- ردیف Grant در طول خواندن داده قفل می‌شود تا لغو هم‌زمان با دسترسی Serialize شود. PostgreSQL برای `SELECT ... FOR SHARE` به Policy از نوع UPDATE در RLS نیاز دارد؛ بنابراین Role پشتیبانی فقط یک Policy محدود UPDATE و مجوز ستونی UPDATE روی `lock_version` غیرحساس دریافت می‌کند. این Role نمی‌تواند `revoked_at`، Scope، Subject یا Tenant را تغییر دهد و در نتیجه قادر به اعطا یا لغو مجوز نیست.
- رویدادهای Audit برای Role مربوط به Support Authorizer فقط قابل‌افزودن هستند و Subject، Grant، Tenant، Resource، Action، دلیل، نتیجه و Timestamp دیتابیس را ثبت می‌کنند. این Role فقط INSERT دارد و مجوز SELECT/UPDATE/DELETE روی جدول Audit ندارد. این محدودیت در سطح Role دیتابیس اعمال شده است؛ به معنی ذخیره‌سازی رمزنگاری‌شده ضد‌دستکاری یا مخزن مستقل و Immutable نیست.
- دسترسی پشتیبانی فقط‌خواندنی است. هیچ Write، عملیات مالی، Credential، Payout، Wallet یا تغییر هویت در محدوده نیست.

## سناریوهای پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P01-SUPPORT-01 | Grant فعال با Subject پشتیبان، Tenant و Scope برابر records:read تطبیق دارد | خواندن مجاز و رویداد Audit ثبت شود |
| P01-SUPPORT-02 | Grant طبق زمان دیتابیس منقضی شده است | دسترسی رد و Audit رد ثبت شود |
| P01-SUPPORT-03 | Grant لغو شده است | دسترسی رد و Audit رد ثبت شود |
| P01-SUPPORT-04 | Grant متعلق به Subject پشتیبان یا Tenant دیگری است | دسترسی رد و هیچ Payload مربوط به Tenant افشا نشود |
| P01-SUPPORT-05 | Scope وجود ندارد یا records:read نیست | دسترسی رد شود |
| P01-SUPPORT-06 | شناسه Grant مفقود یا ناشناخته است | دسترسی رد و بدون اعتماد به دلیل ارسالی Caller ثبت شود |
| P01-SUPPORT-07 | Principal پشتیبانی مسیر عادی Tenant یا Mutation را امتحان می‌کند | دسترسی رد شود |
| P01-SUPPORT-08 | Support Authorizer تلاش می‌کند Payloadهای Tenant را بخواند | دیتابیس به‌دلیل نبود مجوز دسترسی را رد کند |
| P01-SUPPORT-09 | Grant هنگام خواندن داده لغو می‌شود | لغو پشت قفل ردیف منتظر بماند؛ آزمون Race الزامی است |
| P01-SUPPORT-10 | Role مربوط به Support Authorizer تغییر یا حذف Audit را امتحان می‌کند | UPDATE/DELETE رد شود |

## موارد خارج از هدف

- Identity Provider، SSO، MFA یا رابط اپراتوری Production.
- فرایند تأیید دوگانه یا اطلاع‌رسانی به مشتری.
- دسترسی به Wallet، Ledger، Payment، Payout، Trading یا Credential.
- تصمیم نگهداری حقوقی/حریم خصوصی، اتصال SIEM یا خروجی ممیزی خارجی.
- ادعای محافظت در برابر تسخیر برنامه یا Process مورداعتماد Support Authorizer.
- Runbook عملیاتی Break-Glass یا سیاست دسترسی اضطراری Production.

## نکات امنیتی

- زمان انقضا و لغو باید با ساعت دیتابیس بررسی شود.
- SQL پارامتری و Allowlist ثابت برای Resource/Action استفاده شود.
- Payload رکوردها یا Secretها هرگز در رویدادهای Audit ثبت نشوند.
- Role مربوط به Support Authorizer از Roleهای Dispatcher و Tenant Application جدا بماند.
- Grant پشتیبانی یک Capability با دامنه محدود است، نه عضویت قابل‌استفاده مجدد در Tenant.
- این Prototype همچنان محدودیت اعتماد GUC سفارشی در Role مشترک برنامه را که در LOT-PROT-P01-001 ثبت شده به ارث می‌برد.

## اجرا و شواهد

پیاده‌سازی و Fixtureهای ساختگی در شاخه پشته‌شده Support قرار دارند. مجموعه تست یکپارچگی، Grant فعال/منقضی/لغوشده/نامنطبق، جداسازی مسیر Support از Tenant، منع خواندن Payload، محدودیت جدول Audit و قفل‌گذاری هنگام لغو Grant را آزمایش می‌کند. تأیید CI هنوز در انتظار است؛ تا مشاهده نتیجه موفق Workflow هیچ سناریویی را **تأییدشده** اعلام نمی‌کنیم.

برای اجرای محلی، سرویس PostgreSQL دورریختنی را از مسیر `prototypes/p01-tenant-isolation` اجرا و متغیرهای `ADMIN_DATABASE_URL`، `DATABASE_URL`، `DISPATCHER_DATABASE_URL` و `SUPPORT_DATABASE_URL` را با مقادیر ساختگی موجود در راهنمای والد P-01 تنظیم کنید. سپس `npm ci --ignore-scripts --no-audit --no-fund` و `npm test` را اجرا کنید. این مقادیر را هرگز به دیتابیس مشترک، Staging یا Production متصل نکنید.

## منابع

- OWASP — [راهنمای ثبت رویدادها](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html): رویدادهای امنیتی، حداقل مجوز نویسنده Log، حذف داده حساس، تشخیص دستکاری و پایش Log. ذخیره‌سازی مستقل و Immutable، ارسال SIEM و سیاست نگهداری در این Prototype پیاده‌سازی نشده‌اند.
