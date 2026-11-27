# بازبینی امنیتی قرارداد Wire افیلیت

**شناسه سند:** LOT-AFFILIATE-SEC-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** بازبینی امنیتی پیشنهادی؛ نه تأیید امنیت Production | **تاریخ بازبینی:** ۲۰۲۶-۱۱-۲۷

## ۱. هدف و محدوده بازبینی

این بازبینی Artifactهای LOT-AFFILIATE-WIRE-001 شامل OpenAPI 3.2.1، AsyncAPI 3.0.0 و CloudEvents 1.0.2 را در برابر Threat Model فعلی و راهنمای امنیتی عمومی ارزیابی می‌کند. این کار تست نفوذ، ممیزی پیاده‌سازی، نظر حقوقی، تأیید شریک یا مجوز Production نیست.

شواهد بررسی‌شده:
- `contracts/openapi/affiliate-management.v1.json`
- `contracts/openapi/partner-event-ingestion.v1.json`
- `contracts/asyncapi/affiliate-domain-events.v1.json`
- `scripts/validate_affiliate_contract_payloads.mjs`
- LOT-AFFILIATE-WIRE-001 و سوابق وضعیت/تصمیم دوزبانه آن.

مراجع بیرونی:
- OWASP API Security Top 10 (2023): مجوزدهی شکسته در سطح Object، احراز هویت، مجوزدهی Property/Function، مصرف بی‌مهار منابع، گردش تجاری حساس، SSRF، پیکربندی نادرست، Inventory و مصرف ناامن API.
- RFC 9700: بهترین رویه امنیت OAuth 2.0، از جمله محدودسازی Audience و Tokenهای Sender-constrained در صورت امکان.
- قالب JSON در CloudEvents: Extensionها در سطح بالای JSON قرار می‌گیرند؛ Allowlist در Runtime همچنان لازم است.
- RFC 8785: طرح Canonicalization JSON یا JCS، یک RFC اطلاع‌رسان و نه استاندارد Track؛ برای نمایش قطعی داده در Hash/Signature. پیش از Canonicalization باید نام Property تکراری در Object رد شود.

## ۲. یافته‌ها و اقدام الزامی

| شناسه | ریسک / حوزه | شواهد و ارزیابی | کنترل لازم / تعیین تکلیف |
|---|---|---|---|
| SEC-AFF-01 | مجوزدهی شکسته در سطح Object (بالا) | مسیرهای Management منابع را با شناسه Opaque می‌خوانند. قرارداد الزام مجوزدهی Object-level را دارد، اما پیاده‌سازی وجود ندارد. | هر Query خواندن/نوشتن باید در همان مسیر مجوزدهی با Tenant احرازشده، Entitlement محصول، Membership/Role و مالکیت Resource Scope شود. شناسه یا Scope به‌تنهایی مجوز نیست. برای هر مسیر Object، تست منفی Cross-tenant و Cross-membership لازم است. مسدودکننده انتشار Runtime. |
| SEC-AFF-02 | پروفایل احراز هویت و Replay توکن (بالا) | دو API از Bearer Schemeهای جدا استفاده می‌کنند، اما Issuer، Audience، قالب Token، عمر، ابطال و احراز هویت Client عمداً باز مانده‌اند. | Credential انسانی/تفویض‌شده Management از Credential ماشینی شریک جدا بماند. پیش از Runtime، Trust مربوط به Issuer، Audience دقیق، انقضا/Not-before، Binding به Subject/Client، چرخش/ابطال Key، معنای Scope و چرخه Credential مشخص شود. در صورت امکان برای Token ماشینی Audience-restricted و Sender-constrained مانند mTLS یا DPoP طبق RFC 9700 ترجیح دارد. JWT را فرض نکنید. |
| SEC-AFF-03 | اعلام Scope غیراستاندارد (متوسط) | `x-required-scopes` یک OpenAPI Operation Extension سفارشی است؛ HTTP Bearer Scheme به‌تنهایی Scopeهای OAuth را برای Clientهای تولیدشده کدگذاری نمی‌کند. | این Extension فقط پس از مستندسازی Schema، معنای Enforcement و رفتار Generatorها به‌عنوان فیلد قراردادی الزام‌آور تلقی شود. Runtime باید هر Scope اعلام‌شده را اعمال کند. نام نهایی و Issuer/پروفایل OAuth تا تصمیم LOT-API-PLATFORM-001 باز بماند. تست قراردادی لازم است که هر Operation محافظت‌شده Extension غیرخالی داشته باشد. |
| SEC-AFF-04 | هویت Source و Duplicate/Conflict (بالا) | Ingress هویت CloudEvents یعنی source + id، کلید Idempotency درخواست و هویت اثر اقتصادی را جدا می‌کند؛ مرز یکتایی Tenant + Product + Installation + Source + ID است. | این مرز با Unique Constraint پایدار اعمال شود. Duplicate دقیق با Fingerprint یکسان، Receipt قبلی را برگرداند و Job جدید نسازد. همان هویت با Fingerprint متفاوت، تعارض تمامیت ثبت‌شده (409) باشد و بدون Side Effect قرنطینه شود. Commit اتمیک Inbox + Job باید پیش از 202 انجام شود. تست Duplicate هم‌زمان و Crash/Retry لازم است. |
| SEC-AFF-05 | ابهام Fingerprint Payload (بالا) | سند Wire الزام Fingerprint را دارد اما Canonicalization بایتی یا معنایی را تعریف نکرده است. | پیشنهاد پیش‌فرض: نام‌های تکراری JSON در Parse سخت‌گیرانه رد شوند؛ Envelope اعتبارسنجی شود؛ سپس کل Object پذیرفته‌شده CloudEvents با RFC 8785 JCS Canonicalize و بایت‌های UTF-8 حاصل Hash شوند (مثلاً SHA-256). بایت/Hash خام جداگانه با Retention محدود حفظ شود. Typeها بی‌صدا Coerce و Unicode Normalize نشوند. این پیشنهاد پیش از استفاده نیازمند ADR پیاده‌سازی و Test Vector چندزبانه است. |
| SEC-AFF-06 | اعتماد به Extension و Schema رویداد (بالا) | Envelope عمومی شریک Extensionهای سطح بالای JSON و `data.additionalProperties=true` را مجاز می‌داند؛ این برای توسعه‌پذیری CloudEvents لازم است، اما Allowlist نیست. | Runtime فقط Attributeهای اصلی به‌علاوه نام/نوع Extensionهای ثبت‌شده برای همان Installation را مجاز کند؛ برخورد با نام رزروشده، Extension ناشناخته، Event Type ناشناخته و Source ثبت‌نشده رد شود. `data` پیش از Normalization با Schema دقیق و نسخه‌دار همان Integration و Policy سخت‌گیرانه فیلد ناشناخته اعتبارسنجی شود. |
| SEC-AFF-07 | SSRF از طریق Schema Reference (بالا) | `dataschema` یک URI-reference است و توضیح Schema دریافت دلخواه را منع می‌کند؛ اما Resolution در Runtime انجام می‌شود. | شناسه Schema فقط به شناسه Immutable از پیش ثبت‌شده یا Artifact محلی Pinشده Resolve شود. هیچ Dereference شبکه‌ای، Redirect، DNS Resolution یا بارگذاری Schema از URL رویداد مجاز نیست. تست شود که مقصدهای Private/Link-local/Loopback و زنجیره Redirect اصلاً Fetch نمی‌شوند. |
| SEC-AFF-08 | مصرف بی‌مهار منابع (بالا) | اندازه صفحه حداکثر ۱۰۰ و `data` رویداد حداکثر ۶۴ Property دارد، اما سقف سخت Body، عمق JSON، String، Array، تعداد Extension، زمان Parse، هم‌زمانی یا Quota اتصال تعیین نشده است. برخی Arrayهای پاسخ/Role نیز در Schema سقف ندارند. | پیش از Runtime، Quota قابل‌تنظیم برای هر Installation به‌علاوه سقف‌های سراسری غیرقابل‌افزایش برای بایت Body، عمق JSON، تعداد Node، طول String، طول Array، تعداد Extension، زمان Parse، هم‌زمانی و Rate تعیین شود. درخواست بزرگ پیش از پردازش پرهزینه رد شود؛ اندازه صفحه پاسخ نیز محدود باشد. مقادیر عددی نیازمند تأیید محصول/عملیات و Load Test هستند، نه حدس. |
| SEC-AFF-09 | Mass Assignment و حداقل‌سازی داده (متوسط) | Schemaهای Request/Response در Management عمدتاً Object بسته هستند؛ Event Data عمومی تا زمان اعتبارسنجی اختصاصی Provider باز است. | Objectهای Management به‌طور پیش‌فرض بسته بمانند. JSON درخواست مستقیماً به Model دامنه/دیتابیس Bind نشود. از DTO و Command صریح با Mapping مجاز استفاده شود. مجوزدهی Property-level و حداقل‌سازی داده برای Attribution و خروجی Affiliate اعمال شود. |
| SEC-AFF-10 | معنای Idempotency-Key (متوسط) | ساخت Referral Link کلید Idempotency را الزام می‌کند و Binding به Principal/Tenant/Operation/Fingerprint را توضیح می‌دهد؛ مرجع IETF هنوز Draft است. | Key، Scope، Fingerprint درخواست، ارجاع نتیجه و وضعیت با Unique Constraint مقاوم در برابر هم‌زمانی و به‌صورت پایدار ذخیره شوند. Retention و رفتار Conflict در حال پردازش پیش از Runtime تعیین شود. استفاده مجدد همان Key با Fingerprint متفاوت رد شود. مرجع Draft فعلی غیرنهایی باقی بماند و پس از استانداردشدن بازبینی شود. |
| SEC-AFF-11 | افشای اطلاعات از طریق خطا (متوسط) | Problem Details Extensionها را مجاز می‌داند؛ فیلد `detail` در Schema آزاد و بدون سقف است. | از Error Code پایدار و ماشینی استفاده شود؛ Payload شریک، Credential، SQL، Host داخلی یا وجود Resource در Tenant دیگر Echo نشود. Detail محدود و پاک‌سازی شود؛ Policy عمومی 404/403 یکدست باشد. Correlation ID محرمانه نیست اما نباید Secret باشد. |
| SEC-AFF-12 | Audit، حریم خصوصی و شواهد عملیاتی (بالا) | اسناد Wire حفظ Provenance/Hash و منع Payload خام در Log عادی را الزام می‌کنند، اما Retention، دسترسی، رمزنگاری، حذف و Audit کامل نشده است. | Retention مبتنی بر هدف، رمزنگاری در انتقال/ذخیره، دسترسی محدود Payload خام، Break-glass ممیزی‌شده، Redaction، مدیریت حذف/Legal Hold و بازبینی دسترسی تعریف شود. تغییرات ممتاز Membership/Program/Link و تمام رخدادهای Quarantine/Replay/Identity Conflict Audit شوند. Bearer Token و Payload حساس خام هرگز Log نشوند. |
| SEC-AFF-13 | محدودیت Collection پاسخ (متوسط) | آرایه `ProgramPage.data` با وجود سقف ۱۰۰ برای Page Size، در Schema دارای `maxItems` نیست. | **در پیش‌نویس فعلی رفع شده است:** مقدار `ProgramPage.data.maxItems=100` با سقف درخواست منطبق شد و Fixture مثبت برای ۱۰۰ و منفی برای ۱۰۱ مورد اضافه شد. اجرای CI جدید باید این موارد را تأیید کند. همه Arrayهای دیگر (از جمله فهرست Roleها) پیش از Runtime باید سقف مصوب دامنه داشته باشند. |

## ۳. ناورداهای امنیتی

۱. احراز هویت Principal یا Integration را مشخص می‌کند؛ مجوزدهی برای هر Operation و Resource دوباره ارزیابی می‌شود.
۲. Tenant، Product، Environment، Source Namespace و Integration Installation از Binding معتبر سمت سرور استخراج می‌شوند، نه از ادعای شریک.
۳. `integrationId` در مسیر، شناسه Opaque منبع، Extension رویداد و `dataschema` هیچ اختیاری ایجاد نمی‌کنند.
۴. هیچ رویداد شریک مستقیماً Wallet، Ledger، Payment، Settlement یا Payout را تغییر نمی‌دهد.
۵. پذیرش رویداد فقط به‌معنای Receipt پایدار است؛ احراز شرایط تجاری و اثر مالی تصمیم جداگانه دامنه هستند.
۶. تحویل At-least-once فرض می‌شود؛ یکتایی پایدار، ساخت اتمیک Inbox/Job و Idempotency اثرهای پایین‌دستی الزامی‌اند.
۷. هنگام اعتبارسنجی Schema، URL یا Reference تحت کنترل شریک هیچ Fetch دلخواه شبکه‌ای مجاز نیست.
۸. CI سند/Schema هیچ‌گاه ادعای آمادگی Production را ایجاد نمی‌کند.

## ۴. دروازه‌های انتشار

### الزامی پیش از پیاده‌سازی برنامه
- تصویب مدل Trust احراز هویت و جداسازی دقیق Principal انسانی/ماشینی.
- تصویب معنای الزام‌آور Extension مربوط به Scope و ماتریس اولیه مجوزها.
- تصمیم درباره Parse سخت‌گیرانه JSON، رد Property تکراری و الگوریتم Canonical Fingerprint.
- تعیین مالکیت Allowlist مربوط به Event/Source/Extension/Schema و Pin کردن Schema.
- تصویب سقف منابع و ابعاد Quota.
- تعریف Retention، رمزنگاری، دسترسی Payload خام و الزامات Audit.
- افزودن تست Cross-tenant، Object-level، Property-level، Scope، Duplicate هم‌زمان، Conflict، عدم Fetch برای SSRF و مرز مصرف منابع.

### الزامی پیش از Production
- به‌روزرسانی Threat Model، بازبینی امنیتی مستقل و تست نفوذ.
- شواهد Runtime برای Tenant Isolation، ابطال/Audience/Sender Binding توکن، ذخیره اتمیک، Retry/Replay و بازیابی خطا.
- Dashboard/Alert عملیاتی، Incident Response، چرخش Key، Backup/Restore و نگهداری شواهد.
- قرارداد واقعی شریک، نگاشت Schema تأییدشده و شواهد Sandbox مجاز.

## ۵. شواهد اعتبارسنجی فعلی

روی Head شماره `5877746173cbc83e715a7134426d2c086c0181b8` از PR #76:
- Documentation Governance، Run ID `46054085669`، شماره ۹۳۰: **PASS**.
- Affiliate Contract Validation، Run ID `46054085685`، شماره ۳۲: **PASS**.
- Redocly 2.83.0: هر دو سند OpenAPI معتبر؛ هرکدام یک Warning غیرمسدودکننده License دارند.
- AsyncAPI CLI 6.2.2: سند AsyncAPI 3.0.0 معتبر؛ یک پیشنهاد Informational برای بررسی نسخه 3.1.0 ثبت شده است.
- Ajv 8.17.1 / ajv-formats 3.0.1: تعداد ۳۱ Assertion مثبت/منفی روی OpenAPI 3.2.1 (زیرمجموعه Instance نسخه 2020-12) و AsyncAPI 3.0.0 (Draft 07) موفق بوده است.

این‌ها فقط تست سند و نمونه‌های Schema هستند؛ هیچ کنترل امنیتی Runtime در این بازبینی را پیاده‌سازی یا راستی‌آزمایی نمی‌کنند.

## ۶. وضعیت تصمیم

این بازبینی کنترل‌ها را پیشنهاد و دروازه‌های پیاده‌سازی را مشخص می‌کند. هیچ OAuth Provider، قالب Token، شریک، حوزه قضایی، Schema Registry، سقف عددی Quota، دوره Retention یا معماری امنیتی Production را انتخاب نمی‌کند. این موارد تحت مالکیت تصمیم‌گیرندگان پلتفرم/دامنه باز می‌مانند.
