# G09-A14 — سخت‌سازی اعتبارسنجی قرارداد و هم‌ترازی وضعیت پاسخ

**شناسه سند:** LOT-AFFILIATE-G09-A14-001  
**نسخه:** ۰.۱.۰  
**وضعیت:** سخت‌سازی فنی تأیید شد — تصمیم‌های مالک همچنان باز هستند (A14-C05)  
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
- مقدار Extension محدود به String، Boolean یا Integer علامت‌دار ۳۲ بیتی در JSON؛ تمام Attributeهای Context از نوع String در CloudEvents (اعم از Core و Extension) نباید کاراکتر کنترلی ممنوع، Surrogate جفت‌نشده یا Unicode Noncharacter داشته باشند؛
- هیچ Property سطح بالای ناشناخته‌ای خارج از فیلدهای Core و الگوی نحوی معتبر Extension پذیرفته نمی‌شود.

هیچ عددی برای تعداد Extension، اندازه Byte، زمان Parse، عمق Nesting یا Quota اختراع نشده است. سقف منابع همچنان به تصمیم مالک/عملیات در SEC-AFF-08 و شواهد Load وابسته است.

**مرز:** این Profile، Allowlist مختص Installation نیست. Runtime همچنان باید ابتدا Installation/Tenant/Product/Environment احرازشده را Bind کند و سپس هر نام یا نوع معنایی Extension ثبت‌نشده برای همان Installation را رد کند. نوع معنایی Stringهای ثبت‌شده (URI، URI-reference، Timestamp، Binary/Base64 یا String عادی) نیازمند اعتبارسنجی اختصاصی است. فیلد Provider یعنی `data` همچنان ورودی غیرقابل‌اعتماد است و باید پیش از Normalization با Schema دقیق و Pin‌شده Integration اعتبارسنجی شود. هیچ URL دلخواهی از `dataschema` نباید Fetch شود.

### A14-C03 — اصلاح Dialect در AsyncAPI و Guard برای Ajv

Validator اکنون پیش‌فرض AsyncAPI 3.0.0 را درست توصیف می‌کند: در نبود `schemaFormat`، Payload از AsyncAPI 3.0 Schema Object استفاده می‌کند که Superset مربوط به JSON Schema Draft 07 است. Ajv Draft 07 فقط Subset فعلی سازگار با Draft 07 را بررسی می‌کند. Guard، Keywordهای شناخته‌شده و اختصاصی AsyncAPI Schema Object را از مسیر Ajv-only رد می‌کند؛ AsyncAPI CLI همچنان Validator کامل سند و Dialect است.

بررسی Instance در OpenAPI 3.2.1 در Ajv 2020-12 جدا باقی می‌ماند. Redocly همچنان Validator کامل سند OpenAPI است.

### A14-C04 — Lockfileهای مجزا و نصب بازتولیدپذیر

Manifestهای نسخه‌دقیق و جداگانه در `.github/contract-tools/package.json` و `.github/schema-tools/package.json` اضافه شدند. دو Prefix عمداً Dependency Graph مربوط به CLIهای AsyncAPI/Redocly را از Dependencyهای Ajv مربوط به Fixture جدا می‌کنند تا Collision نسخه‌های Transitive مربوط به Ajv/Plugin رخ ندهد. هر دو Lockfile تولید، بررسی و Commit شده‌اند:
- `.github/contract-tools/package-lock.json` — شامل ۱٬۴۰۹ رکورد Package.
- `.github/schema-tools/package-lock.json` — شامل ۷ رکورد Package.

Bootstrap موقت، Artifact Upload و Job نوشتن Lockfile حذف شده‌اند. Workflow نهایی در هر دو Prefix مجزا، `npm ci` سخت‌گیرانه را اجباری می‌کند و در صورت نبود هر Lockfile ثبت‌شده Fail می‌شود. نسخه Node/npm ثبت می‌شود و Runner از `ubuntu-24.04` به‌جای برچسب متغیر `ubuntu-latest` استفاده می‌کند.

**تأییدشده:** هر دو اجرای سخت‌گیرانه `npm ci` از Lockfileهای ثبت‌شده روی Head دقیق `3a008718ab9cf40a551441e3a195f73874788f26` موفق شدند؛ A13-F04 از نظر بازتولیدپذیری Dependency Graph بسته شد. Image میزبانی‌شده Runner همچنان توسط GitHub به‌روزرسانی می‌شود؛ `ubuntu-24.04` خانواده سیستم‌عامل را محدود می‌کند اما Digest کاملاً Immutable نیست.

### A14-C05 — هم‌ترازی وضعیت پاسخ 202/503/UNKNOWN

توصیف 202 در Partner API و قرارداد Wire دوزبانه دیگر ادعای بدون قید Durability نمی‌کند. 202 صرفاً پس از Commit اتمیک Inbox + WorkItem و تحقق شرط Acknowledgement مربوط به Durability که مالک تصویب کرده است، پیشنهاد می‌شود.

توصیف 503 اکنون اعلام عدم پذیرش را مگر در صورت معلوم‌بودن عدم Commit ممنوع می‌کند. UNKNOWN صریحاً نه پذیرش قطعی است و نه عدم پذیرش قطعی. Retry باید هویت منبع احرازشده را حفظ و در مرجع فعال و معتبر Persistence تطبیق دهد؛ Read منفی به‌تنهایی مجوز Insert دوم نیست.

**همچنان باز:** نگاشت دقیق HTTP Status و خطای Machine-readable برای UNKNOWN، کلاس‌های خرابی تحت پوشش، RPO، نقطه Acknowledgement، صلاحیت Promotion و رفتار Recovery به تصمیم مالک و Proof اختصاصی Candidate نیاز دارند. Enum جدید UNKNOWN برای Receipt یا مقدار عددی Durability اختراع نشده است. ADR-002 همچنان PROPOSED است.

### A14-C06 — Manifest پوشش Fail-closed برای Schema Root و Fixture

Manifest فعلی تمام ۱۱ Schema Root را فهرست می‌کند:
- ۷ Schema در OpenAPI مربوط به Affiliate Management؛
- ۳ Schema در OpenAPI مربوط به Partner Ingestion؛
- ۱ Payload رویداد Canonical در AsyncAPI.

در مجموع ۵۳ شناسه Fixture مثبت/منفی ثبت شده‌اند. Validator Manifest را دقیقاً با Schema Rootهای واقعی و Fixtureهای اجراشده تطبیق می‌دهد. Schema Root جدید یا حذف‌شده، Fixture مفقود/اضافه، شناسه تکراری یا Fixture متصل به Root اشتباه باعث شکست اعتبارسنجی می‌شود. Operation جدید نیز تا زمان ثبت صریح در Manifest امنیت عملیات Fail می‌شود.

این Guard جامعیت فهرست اعلام‌شده Schema Root را کنترل می‌کند؛ اثبات تمام رفتارهای معنایی یا تمام ورودی‌های ممکن نیست.

## ۳. فهرست فعلی پیاده‌سازی

- `contracts/validation/affiliate-contract-validation-manifest.v1.json`
- `.github/contract-tools/package.json` و `.github/schema-tools/package.json` همراه با Lockfileهای ثبت‌شده
- `.github/workflows/affiliate-contract-validation.yml`
- `scripts/validate_affiliate_contract_payloads.mjs`
- `contracts/openapi/partner-event-ingestion.v1.json`
- `contracts/asyncapi/affiliate-domain-events.v1.json`
- فایل دوزبانه `affiliate-api-wire-contract.md`

تطبیق ایستای برچسب Fixtureها در اسکریپت اکنون ۵۳ Fixture در Manifest و ۵۳ شناسه یکتای اجرایی را بدون شناسه مفقود، اضافه یا تکراری نشان می‌دهد. این نتیجه بازرسی منبع است، نه نتیجه اجرای Node/Ajv.

## ۴. تعیین تکلیف یافته‌های A13

| یافته A13 | اقدام A14 | وضعیت فعلی |
|---|---|---|
| F01 — نگاشت دقیق Security/Scope عملیات | Manifest دقیق، Assertion عملیات و هفت Mutation Case | با CI روی Head دقیق تأیید شد؛ Authorization در Runtime اثبات نشده است |
| F02 — Syntax/Type در Extensionهای CloudEvents در برابر Allowlist نصب | Profile عمومی Schema و Fixture منفی؛ Allowlist Runtime جدا باقی می‌ماند | جزئی؛ الزام Runtime باز است |
| F03 — توصیف Dialect در AsyncAPI | اصلاح Comment/Output و Guard برای Ajv | با CI روی Head دقیق و AsyncAPI CLI تأیید شد |
| F04 — بازتولیدپذیری Dependencyهای Transitive | Manifestهای مجزای ابزار و Lockfileهای Commit‌شده؛ Workflow مبتنی بر npm ci سخت‌گیرانه | تأیید شد؛ هر دو npm ci سخت‌گیرانه موفق شدند |
| F05 — هم‌ترازی 202/503/UNKNOWN | متن پاسخ مشروط و مرز صریح UNKNOWN | جزئی؛ تصمیم مالک و Proof Runtime باز است |
| F06 — پوشش Fixtureهای Schema | Manifest ماشینی ۱۱ Root/۵۳ Fixture و Assertion برابری دقیق | با CI روی Head دقیق تأیید شد؛ ۶۶ Assertion موفق |

## ۵. شواهد اعتبارسنجی روی Head دقیق

**Head تأییدشده:** `3a008718ab9cf40a551441e3a195f73874788f26`

- Documentation Governance #1057 — SUCCESS (Run: `46070895494`).
- Affiliate Contract Validation #227 — SUCCESS (Run: `46070891292`).
- هر دو نصب سخت‌گیرانه `npm ci` با Node نسخه `24.11.1` و npm نسخه `11.6.2` موفق شدند.
- کنترل‌های OpenAPI توسط Redocly موفق شدند؛ اعتبارسنجی کامل سند AsyncAPI توسط CLI نسخه `6.2.2` نیز موفق شد.
- Validator مبتنی بر Node/Ajv با **۶۶ Assertion**، شامل **۱۱ Schema Root** و **۵۳ Fixture مثبت/منفی** موفق شد.
- نگاشت دقیق Security/Scope و هفت Mutation Case، Profile عمومی CloudEvents و کنترل Unicode، Guard مربوط به Dialect در AsyncAPI و برابری Manifest/Fixture موفق شدند.
- هشدارهای Governance غیرمسدودکننده: Redocly نبود Metadata مربوط به `info.license` را گزارش کرد؛ AsyncAPI CLI نسخه 3.1.0 را آخرین نسخه Schema اعلام کرد، درحالی‌که قرارداد فعلی عمداً 3.0.0 باقی مانده است. از این هشدارها هیچ License یا Migration مربوط به Dialect جعل یا استنباط نمی‌شود.

**موارد باز پیش از تصویب ADR-002:** بازبینی مستقل؛ Proof مربوط به Allowlist نصب در Runtime؛ تصمیم‌های مالک و Proof اختصاصی Candidate برای نگاشت UNKNOWN Commit، Failure Model، RPO، نقطه Acknowledgement و قواعد Promotion/Recovery. این موارد شکست CI نیستند و با این بسته بسته نمی‌شوند.

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


## ۸. تأیید نهایی روی Head دقیق — ۲۰۲۶-۱۱-۲۸

شواهد قبلی در بخش‌های ۴ و ۵ به‌عنوان سابقه تاریخی Head برابر با `3a008718ab9cf40a551441e3a195f73874788f26` حفظ می‌شوند. شواهد زیر، نتیجه نهایی و ملاک فعلی A14 هستند:

**Head دقیق:** `736390f86ab425a8c273dcf254cc5974e9eb55ae`

- Affiliate Contract Validation شماره ۲۳۵ — SUCCESS (Run: `46071082568`).
- Documentation Governance شماره ۱۰۶۲ — SUCCESS (Run: `46071082558`).
- هر دو Workflow روی همین Head دقیق تکمیل شدند.
- اعتبارسنجی قرارداد ۶۶ Assertion، ۱۱ Schema Root و ۵۳ Fixture مثبت/منفی را گزارش کرد؛ نصب‌های سخت‌گیرانه `npm ci`، اعتبارسنجی OpenAPI با Redocly و اعتبارسنجی AsyncAPI CLI موفق شدند.
- A13-F01/F03/F04/F06 فقط در محدوده قرارداد/CI تأیید شده‌اند. A13-F02 تا زمان اثبات Allowlist مختص Installation در Runtime جزئی باقی می‌ماند. A13-F05 تا تصمیم مالک و Proof اختصاصی Durability/UNKNOWN باز است.

**تعیین تکلیف ملاک:** سخت‌سازی فنی G09-A14 تأیید شده است. عبارت‌های قبلی این سند درباره «IN PROGRESS تا نهایی‌شدن Lockfile/CI» با این بخش جایگزین می‌شوند. این نتیجه ADR-002، مجوز Runtime، انتخاب Persistence/Queue، اتصال شریک، عملیات مالی، Merge یا Deploy را تصویب نمی‌کند. بازبینی مستقل همچنان باقی است و هر هشت Gate مربوط به A4 تصویب‌نشده‌اند.


## ۹. پیگیری پس از بازبینی — پوشش مؤثر پارامترهای OpenAPI (۲۰۲۶-۱۱-۲۸)

در بازبینی Inline مربوط به Codex یک شکاف معتبر با شدت P2 شناسایی شد: Manifest قبلی A14، یازده ریشه Schema مربوط به Payloadهای OpenAPI/AsyncAPI را فهرست می‌کرد، اما Parameter Objectهای مؤثر OpenAPI را در موجودی آزمون قرار نمی‌داد. بنابراین محدودیت‌هایی مانند طول Cursor، بازه اندازه صفحه و طول Idempotency-Key می‌توانستند تغییر کنند، بدون آنکه Fixture اختصاصی پارامتر شکست بخورد.

**تعیین تکلیف: یافته تأیید و در اعتبارسنجی قرارداد برطرف شد.**

اکنون Validator و Manifest:

- پارامترهای مؤثر تمام عملیات HTTP را در هر دو سند OpenAPI استخراج می‌کنند؛
- پارامترهای Path Item را به عملیات به ارث می‌دهند و Overrideهای سطح Operation را بر اساس هویت پارامتر OpenAPI یعنی ترکیب `(name, in)` اعمال می‌کنند؛
- Referenceهای محلی `#/components/parameters/...` را حل می‌کنند و در برابر Reference نامعتبر، چرخه‌ای یا غیرمحلی Fail Closed می‌شوند؛
- دقیقاً یکی از دو نمایش Schema پارامتر یعنی `schema` یا Schema مربوط به یک Media Type در `content` را الزامی می‌کنند؛
- مجموعه کامل شناسه پارامترهای مؤثر را با Manifest، شامل Operation، مسیر، محل و نام، تطبیق می‌دهند؛
- مقدار Required، منشأ Reference و نوع نمایش Schema هر پارامتر را با Manifest تطبیق می‌دهند؛
- Schema واقعی قرارداد را با دسترسی به Namespace مربوط به Componentهای همان سند کامپایل و Fixtureهای مثبت و منفی مرزی را اجرا می‌کنند.

**موجودی فعلی پارامترها:** شش پارامتر مؤثر و ۲۵ Fixture مثبت/منفی:

- `cursor`: نوع و مرز طول ۲۰۴۸/۲۰۴۹ کاراکتر؛
- `limit`: نوع عدد صحیح و مرزهای ۱/۱۰۰ در برابر ۰/۱۰۱؛
- `Idempotency-Key`: مرز طول ۳/۲۵۵ در برابر ۲/۲۵۶ کاراکتر؛
- `referralLinkId`، `attributionId` و `integrationId`: غیرخالی بودن و مرز طول ۱۲۸/۱۲۹ کاراکتر.

یازده Schema Root و ۵۳ Fixture مربوط به Schemaهای Payload قبلی بدون تغییر باقی مانده‌اند و جداگانه گزارش می‌شوند؛ موجودی جدید پارامترها به‌اشتباه به‌عنوان Schema Rootهای Payload شمرده نمی‌شود. خروجی Validator شامل **۱۱۷ Assertion، یازده Schema Root، ۵۳ Fixture مربوط به Payload Schema، شش پارامتر مؤثر و ۲۵ Fixture پارامتری** است.

### شواهد CI روی Head دقیق

Head منبع بررسی‌شده: `16143c822578e1b4d8d7b38e4283ab4ac0f466a9`.

- Documentation Governance، اجرای PR شماره ۱۲۶۷ (`46164546372`): **SUCCESS**.
- Affiliate Contract Validation، اجرای PR شماره ۲۵۳ (`46164546461`): **SUCCESS**.
- Affiliate Contract Validation، اجرای Push شماره ۲۵۲ (`46164543052`): **SUCCESS**.
- Job قرارداد، نصب سخت‌گیرانه مبتنی بر Lockfile، اعتبارسنجی هر دو سند OpenAPI با Redocly، اعتبارسنجی AsyncAPI CLI و اجرای Validator مبتنی بر Node/Ajv را با موفقیت تکمیل کرد.
- خروجی Validator صریحاً ۱۱۷ Assertion و موجودی مستقل پارامترها را گزارش کرد.

هشدارهای غیرمسدودکننده قبلی بدون تغییرند: Redocly نبود Metadata مربوط به `info.license` را گزارش می‌کند؛ AsyncAPI CLI نسخه ۳.۱.۰ را جدیدتر از قرارداد ۳.۰.۰ اعلام می‌کند که عمداً حفظ شده است. هیچ‌یک از این هشدارها مجوز استنباط License یا مهاجرت تأییدنشده Dialect نیست.

### وضعیت بازبینی و مجوزها

- یافته P2 مربوط به Codex در منبع اصلاح شده است، اما Thread بازبینی Inline تا تأیید اصلاح توسط Reviewer باز می‌ماند و بدون بررسی مجدد، Resolved اعلام نمی‌شود.
- GitHub یک Review با وضعیت `APPROVED` از حساب `xrayman6zfm-ux` روی Head قبلی ثبت کرده است. بااین‌حال، رویه A12 ارائه اظهارنامه امضاشده استقلال، صلاحیت و تعارض منافع و یک Disposition جداگانه برای تک‌تک یافته‌ها را الزامی می‌کند. این مدارک در آن Approval با متن خالی وجود ندارند. بنابراین بازبینی مستقل A12 همچنان **NOT PERFORMED / NOT ASSESSABLE** است و A11-F01 تا A11-F08 باز می‌مانند.
- GitHub در حال حاضر PR شماره ۷۶ را Open و با `draft=false` نشان می‌دهد. عبارت‌های قبلی Draft در این سند و توضیحات PR تاریخی‌اند و وضعیت فعلی GitHub جایگزین آن‌هاست.
- ADR-002 همچنان PROPOSED است؛ هر هشت Gate مربوط به A4 تصویب‌نشده‌اند. هیچ Runtime، انتخاب Persistence/Queue، اتصال شریک، عملیات مالی، Merge یا Deploy مجاز نیست.

این پیگیری فقط شکاف شناسایی‌شده در پوشش Validator قرارداد را پس از CI روی Head دقیق می‌بندد. رفتار پارامترها در Runtime، رفتار Persistence یا هیچ‌یک از Invariantهای ADR-002 را اثبات نمی‌کند.
