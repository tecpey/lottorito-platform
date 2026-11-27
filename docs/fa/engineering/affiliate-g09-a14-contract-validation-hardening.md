# G09-A14 — سخت‌سازی اعتبارسنجی قرارداد و هم‌ترازی وضعیت پاسخ

**شناسه سند:** LOT-AFFILIATE-G09-A14-001  
**نسخه:** ۰.۱.۰  
**وضعیت:** IN PROGRESS — نامزد پیاده‌سازی ثبت شده؛ CI روی Head دقیق و نهایی‌سازی Lockfile باقی است  
**تاریخ:** ۲۰۲۶-۱۱-۲۸  
**والد:** LOT-AFFILIATE-G09-A13-001  
**محدوده:** صرفاً اعتبارسنجی قرارداد/CI. بدون پیاده‌سازی Runtime، انتخاب Persistence، اتصال شریک، عملیات مالی، Merge یا مجوز Deploy.

## ۱. هدف

رفع شش شکاف اطمینان‌بخشی ثبت‌شده در G09-A13، بدون تبدیل کنترل مستندات به ادعای Runtime یا تصمیم‌گیری پنهانی به‌جای مالک. این بسته Validator قرارداد را سخت‌گیرانه‌تر می‌کند، پوشش Schema/Fixture را Fail-closed می‌سازد، Envelope عمومی CloudEvents را به Profile محلی سازگار با استاندارد محدود می‌کند و متن پاسخ پذیرش را به قرارداد Durability تصویب‌شده توسط مالک مشروط می‌سازد.

## ۲. تغییرات آماده‌شده

### A14-C01 — Manifest دقیق Security/Scope عملیات و آزمون‌های Mutation

فایل `contracts/validation/affiliate-contract-validation-manifest.v1.json` به‌عنوان فهرست صریح عملیات و پوشش Schema اضافه شد.

Validator اکنون هر Operation موجود را با موارد مورد انتظار تطبیق می‌دهد:
- operationId؛ عملیات ناشناخته، تکراری یا مفقود رد می‌شود؛
- دقیقاً یک Security Requirement Object غیراختیاری؛
- HTTP Bearer Scheme دقیق برای API مربوط؛
- نبود Alternative ناشناس، Scheme اشتباه یا اضافه؛
- مجموعه دقیق `x-required-scopes` بدون Scope مفقود، اضافه یا تکراری.

هفت Mutation Fixture عمداً Security ناشناس، Scheme اشتباه، Alternative ناشناس، Scope اشتباه، Scope تکراری، Operation ناشناخته و Operation مفقود ایجاد می‌کنند. هر Mutation باید رد شود.

**مرز:** `x-required-scopes` همچنان Metadata سفارشی قرارداد است. این تغییر معنای هنجاری آن در پلتفرم یا اجرای Resource Server را اثبات نمی‌کند. Issuer، Audience، Profile اعتبارنامه و پیاده‌سازی Authorization همچنان باز هستند.

### A14-C02 — Profile عمومی Extensionهای CloudEvents

Envelope شریک و Payload رویداد Canonical اکنون یک Profile عمومی مشترک را اعمال می‌کنند:
- نام Property متشکل از حروف کوچک ASCII و ارقام؛
- کاراکتر نخست حرف کوچک؛
- حداکثر ۲۰ کاراکتر (پروژه عمداً توصیه SHOULD در CloudEvents را به قاعده محلی MUST سخت‌گیرانه‌تر تبدیل می‌کند)؛
- مقدار Extension محدود به String، Boolean یا Integer علامت‌دار ۳۲ بیتی در JSON؛
- هیچ Property سطح بالای ناشناخته‌ای خارج از فیلدهای Core و الگوی نحوی معتبر Extension پذیرفته نمی‌شود.

هیچ عددی برای تعداد Extension، اندازه Byte، زمان Parse، عمق Nesting یا Quota اختراع نشده است. سقف منابع همچنان به تصمیم مالک/عملیات در SEC-AFF-08 و شواهد Load وابسته است.

**مرز:** این Profile، Allowlist مختص Installation نیست. Runtime همچنان باید ابتدا Installation/Tenant/Product/Environment احرازشده را Bind کند و سپس هر نام یا نوع معنایی Extension ثبت‌نشده برای همان Installation را رد کند. نوع معنایی Stringهای ثبت‌شده (URI، URI-reference، Timestamp، Binary/Base64 یا String عادی) نیازمند اعتبارسنجی اختصاصی است. فیلد Provider یعنی `data` همچنان ورودی غیرقابل‌اعتماد است و باید پیش از Normalization با Schema دقیق و Pin‌شده Integration اعتبارسنجی شود. هیچ URL دلخواهی از `dataschema` نباید Fetch شود.

### A14-C03 — اصلاح Dialect در AsyncAPI و Guard برای Ajv

Validator اکنون پیش‌فرض AsyncAPI 3.0.0 را درست توصیف می‌کند: در نبود `schemaFormat`، Payload از AsyncAPI 3.0 Schema Object استفاده می‌کند که Superset مربوط به JSON Schema Draft 07 است. Ajv Draft 07 فقط Subset فعلی سازگار با Draft 07 را بررسی می‌کند. Guard، Keywordهای شناخته‌شده و اختصاصی AsyncAPI Schema Object را از مسیر Ajv-only رد می‌کند؛ AsyncAPI CLI همچنان Validator کامل سند و Dialect است.

بررسی Instance در OpenAPI 3.2.1 در Ajv 2020-12 جدا باقی می‌ماند. Redocly همچنان Validator کامل سند OpenAPI است.

### A14-C04 — Bootstrap برای Lockfile و مسیر نصب بازتولیدپذیر

Manifest ابزار با نسخه‌های مستقیم دقیق در `.github/contract-validation/package.json` اضافه شد. Workflow اکنون:
۱. فقط در صورت نبود Lockfile، موقتاً آن را تولید می‌کند؛
۲. با `npm ci` نصب انجام می‌دهد؛
۳. Lockfile تولیدشده را به‌صورت Artifact کوتاه‌مدت Workflow بارگذاری می‌کند؛
۴. نسخه Node و npm را ثبت می‌کند؛
۵. به‌جای برچسب متغیر `ubuntu-latest` از `ubuntu-24.04` استفاده می‌کند.

**هنوز بسته نشده:** Lockfile تولیدشده باید دریافت، بررسی و Commit شود. سپس مراحل موقت Bootstrap و Upload Artifact باید حذف شوند و Workflow فقط `npm ci` سخت‌گیرانه داشته باشد؛ در نبود Lockfile ثبت‌شده باید Fail شود. تا زمان این تغییر نهایی و PASS روی Head دقیق، A13-F04 باز است. Image میزبانی‌شده Runner همچنان توسط GitHub به‌روزرسانی می‌شود؛ `ubuntu-24.04` خانواده سیستم‌عامل را محدود می‌کند اما Digest کاملاً Immutable نیست.

### A14-C05 — هم‌ترازی وضعیت پاسخ 202/503/UNKNOWN

توصیف 202 در Partner API و قرارداد Wire دوزبانه دیگر ادعای بدون قید Durability نمی‌کند. 202 صرفاً پس از Commit اتمیک Inbox + WorkItem و تحقق شرط Acknowledgement مربوط به Durability که مالک تصویب کرده است، پیشنهاد می‌شود.

توصیف 503 اکنون اعلام عدم پذیرش را مگر در صورت معلوم‌بودن عدم Commit ممنوع می‌کند. UNKNOWN صریحاً نه پذیرش قطعی است و نه عدم پذیرش قطعی. Retry باید هویت منبع احرازشده را حفظ و در مرجع فعال و معتبر Persistence تطبیق دهد؛ Read منفی به‌تنهایی مجوز Insert دوم نیست.

**همچنان باز:** نگاشت دقیق HTTP Status و خطای Machine-readable برای UNKNOWN، کلاس‌های خرابی تحت پوشش، RPO، نقطه Acknowledgement، صلاحیت Promotion و رفتار Recovery به تصمیم مالک و Proof اختصاصی Candidate نیاز دارند. Enum جدید UNKNOWN برای Receipt یا مقدار عددی Durability اختراع نشده است. ADR-002 همچنان PROPOSED است.

### A14-C06 — Manifest پوشش Fail-closed برای Schema Root و Fixture

Manifest فعلی تمام ۱۱ Schema Root را فهرست می‌کند:
- ۷ Schema در OpenAPI مربوط به Affiliate Management؛
- ۳ Schema در OpenAPI مربوط به Partner Ingestion؛
- ۱ Payload رویداد Canonical در AsyncAPI.

در مجموع ۴۵ شناسه Fixture مثبت/منفی ثبت شده‌اند. Validator Manifest را دقیقاً با Schema Rootهای واقعی و Fixtureهای اجراشده تطبیق می‌دهد. Schema Root جدید یا حذف‌شده، Fixture مفقود/اضافه، شناسه تکراری یا Fixture متصل به Root اشتباه باعث شکست اعتبارسنجی می‌شود. Operation جدید نیز تا زمان ثبت صریح در Manifest امنیت عملیات Fail می‌شود.

این Guard جامعیت فهرست اعلام‌شده Schema Root را کنترل می‌کند؛ اثبات تمام رفتارهای معنایی یا تمام ورودی‌های ممکن نیست.

## ۳. فهرست فعلی پیاده‌سازی

- `contracts/validation/affiliate-contract-validation-manifest.v1.json`
- `.github/contract-validation/package.json`
- `.github/workflows/affiliate-contract-validation.yml`
- `scripts/validate_affiliate_contract_payloads.mjs`
- `contracts/openapi/partner-event-ingestion.v1.json`
- `contracts/asyncapi/affiliate-domain-events.v1.json`
- فایل دوزبانه `affiliate-api-wire-contract.md`

تطبیق ایستای برچسب Fixtureها در اسکریپت اکنون ۴۵ Fixture در Manifest و ۴۵ شناسه یکتای اجرایی را بدون شناسه مفقود، اضافه یا تکراری نشان می‌دهد. این نتیجه بازرسی منبع است، نه نتیجه اجرای Node/Ajv.

## ۴. تعیین تکلیف یافته‌های A13

| یافته A13 | اقدام A14 | وضعیت فعلی |
|---|---|---|
| F01 — نگاشت دقیق Security/Scope عملیات | Manifest دقیق، Assertion عملیات و هفت Mutation Case | نامزد پیاده‌سازی؛ CI باقی است |
| F02 — Syntax/Type در Extensionهای CloudEvents در برابر Allowlist نصب | Profile عمومی Schema و Fixture منفی؛ Allowlist Runtime جدا باقی می‌ماند | جزئی؛ الزام Runtime باز است |
| F03 — توصیف Dialect در AsyncAPI | اصلاح Comment/Output و Guard برای Ajv | نامزد پیاده‌سازی؛ CI باقی است |
| F04 — بازتولیدپذیری Dependencyهای Transitive | Manifest ابزار و Bootstrap یک‌باره Lockfile | باز تا Commit Lockfile و PASS در npm ci سخت‌گیرانه |
| F05 — هم‌ترازی 202/503/UNKNOWN | متن پاسخ مشروط و مرز صریح UNKNOWN | جزئی؛ تصمیم مالک و Proof Runtime باز است |
| F06 — پوشش Fixtureهای Schema | Manifest ماشینی ۱۱ Root/۴۵ Fixture و Assertion برابری دقیق | نامزد پیاده‌سازی؛ CI باقی است |

## ۵. اعتبارسنجی الزامی پیش از تکمیل A14

۱. دریافت و بررسی Artifact مربوط به Bootstrap Lockfile و Commit کردن همان Lockfile تولیدشده.
۲. حذف منطق Bootstrap/Artifact موقت و الزام `npm ci` با Lockfile ثبت‌شده.
۳. تأیید اینکه Mutationهای Security/Scope دقیقاً مطابق انتظار Fail می‌شوند.
۴. تأیید Caseهای مثبت/منفی Profile Extensionهای CloudEvents در Ajv 2020-12 و Subset محافظت‌شده Draft 07.
۵. موفقیت AsyncAPI CLI و کنترل کامل سند توسط Redocly.
۶. تطبیق دقیق ۱۱ Schema Root و ۴۵ شناسه Fixture.
۷. اجرای Documentation Governance و Affiliate Contract Validation روی یک Head نهایی مشترک؛ بررسی تمام Job Stepها و ثبت SHA دقیق.
۸. بازخوانی اسناد فارسی و انگلیسی و مقایسه هم‌ارزی معنایی.
۹. ثبت تمام تصمیم‌های باز مالک بدون تغییر وضعیت آن‌ها.

## ۶. استانداردها و منابع

- OpenAPI 3.2.1، Security Requirement Object و Alternative ناشناس: https://spec.openapis.org/oas/v3.2.1.html
- AsyncAPI 3.0.0، پیش‌فرض Multi Format Schema Object و Dialect مربوط به Schema Object: https://www.asyncapi.com/docs/reference/specification/v3.0.0
- CloudEvents، نام‌گذاری Attribute، Type System و Extensionها: https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md
- CloudEvents JSON Event Format، نگاشت Extension به JSON: https://github.com/cloudevents/spec/blob/main/cloudevents/formats/json-format.md
- دستور `npm ci` و نصب پاک مبتنی بر Lockfile: https://docs.npmjs.com/cli/npm-ci
- NIST SP 800-204D، امنیت زنجیره تأمین نرم‌افزار در DevSecOps CI/CD: https://csrc.nist.gov/pubs/sp/800/204/d/final

استانداردها مبنای قرارداد و کنترل هستند؛ رفتار پیاده‌سازی Runtime را اثبات نمی‌کنند.

## ۷. موارد خارج از ادعا و شرایط توقف

- هیچ Authorization، Binding نصب یا Tenant Isolation در Runtime پیاده‌سازی یا اثبات نشده است.
- هیچ Schema رویداد اختصاصی شریک، Registry افزونه، Allowlist منبع یا Token Issuer تصویب نشده است.
- هیچ تراکنش Inbox/WorkItem، Race مربوط به Idempotency، تطبیق UNKNOWN، Durability دیتابیس، Failover یا Fencing آزموده نشده است.
- هیچ عملیات Ledger، کمیسیون، Payout، Wallet یا موجودی مشتری انجام نشده است.
- هیچ Persistence Engine، Queue، Vendor، مقدار RPO، مدت Retention یا Quota انتخاب نشده است.
- A11-F01 تا F08 باز هستند؛ Caseهای A7/A8 صرفاً طراحی و NOT RUN هستند؛ هر هشت Gate مربوط به A4 تصویب‌نشده‌اند.
- بازبینی مستقل همچنان باقی است.
- PR #76 همچنان Open/Draft است. Merge و Deploy مجاز نیست.

**تعیین تکلیف:** G09-A14 در وضعیت IN PROGRESS است. سخت‌سازی Validator یک نامزد پیاده‌سازی است؛ نهایی‌سازی Lockfile و Evidence مربوط به CI روی Head دقیق، شرط لازم برای اعلام تکمیل است.
