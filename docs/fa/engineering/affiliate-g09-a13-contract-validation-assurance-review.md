# G09-A13 — بازبینی اطمینان‌بخشی اعتبارسنجی قرارداد

**شناسه سند:** LOT-AFFILIATE-G09-A13-001  
**نسخه:** ۰.۱.۰  
**Snapshot بازبینی:** `e88c6b6fac04b451926a8137ca68571f19e18fa8`  
**تاریخ:** ۲۰۲۶-۱۱-۲۸  
**وضعیت:** بازبینی اطمینان‌بخشی توسط همان نویسنده — مستقل نیست؛ یافته‌ها OPEN  
**مرتبط:** PR #76؛ LOT-AFFILIATE-WIRE-001؛ LOT-AFFILIATE-SEC-001؛ LOT-AFFILIATE-G09-ADR-002؛ G09-A11؛ G09-A12  
**اختیار:** صرفاً اطمینان‌بخشی مستندات/قرارداد؛ بدون مجوز Runtime، شریک، عملیات مالی، Merge یا Deploy.

## ۱. نتیجه اجرایی

در Snapshot ثابت‌شده، هر دو Workflow گیت‌هاب روی همان Head با موفقیت تکمیل شدند:
- Documentation Governance #1014 — SUCCESS.
- Affiliate Contract Validation #151 — SUCCESS.

Workflow قرارداد، نسخه‌های مستقیم ابزارهای CLI/Validator را نصب کرد، OpenAPI را با Redocly بررسی کرد، AsyncAPI را با CLI مربوطه اعتبارسنجی کرد و اسکریپت Fixtureهای Node/Ajv را اجرا کرد. موفقیت آن Evidence معتبر برای عبور همین کنترل‌های پیکربندی‌شده روی Commit بررسی‌شده است.

این نتیجه Evidence مربوط به مجوز Runtime، Tenant Binding، اجرای Allowlist منبع/Extension، Persistence اتمیک Inbox/WorkItem، هم‌زمانی Idempotency، Durability Commit، ایمنی Failover، عدم دسترسی به Ledger یا آمادگی Production نیست.

این بازبینی Workflow، اسکریپت اعتبارسنجی، Artifactهای OpenAPI/AsyncAPI و اسناد مرتبط Wire/Security/ADR را بررسی کرده است. در همان جریان پروژه و توسط همان نویسنده تهیه شده و **بازبینی مستقل محسوب نمی‌شود**.

## ۲. یافته‌ها

### A13-F01 — Assertionهای امنیت عملیات، نگاشت مورد انتظار Scheme/Scope را اعمال نمی‌کنند

**شدت:** HIGH — شکاف در حفاظت از Regression قرارداد  
**وضعیت:** OPEN

Validator فعلی بررسی می‌کند که هر Operation آرایه `security` غیرخالی و آرایه `x-required-scopes` غیرخالی داشته باشد. همچنین وجود نام Schemeهای Bearer مجزای Management و Ingestion را بررسی می‌کند.

اما بررسی نمی‌کند که هر Operation دقیقاً به Scheme صحیح متصل شده باشد یا Scopeهای آن دقیقاً برابر Policy همان Operation باشند. یک Security Requirement Object خالی در OpenAPI مانند `{}` امکان دسترسی ناشناس را فراهم می‌کند، ولی Assertion فعلی طول آرایه همچنان آن را می‌پذیرد. استفاده از Scheme اشتباه یا Scope ناخواسته نیز ممکن است از این بررسی عمومی عبور کند.

قرارداد فعلی در Snapshot بررسی‌شده چنین نگاشتی دارد:
- Management: استفاده از `bearerAuth` برای `listAffiliatePrograms`، `getAffiliateSelf`، `createReferralLink`، `getReferralLink` و `getAttribution` همراه با Scope اختصاصی `affiliate.*` هر عملیات.
- Ingestion: استفاده از `partnerBearerAuth` برای `submitPartnerEvent` با Scope برابر `partner.events.write`.

**اصلاح لازم**
۱. Manifest صریح و بازبینی‌شده‌ای از OperationId به Security Scheme مورد انتظار و مجموعه دقیق Scopeها اضافه شود.
۲. برابری دقیق Scheme و Scope بررسی شود، نه صرفاً غیرخالی‌بودن آرایه‌ها.
۳. Security Requirement Object خالی، Scope مفقود/تکراری/ناشناخته، جایگزینی Scheme اشتباه، Operation ID ناشناخته و Operation مستندسازی‌نشده رد شود.
۴. Fixtureهای Mutation/Negative برای اثبات رد هر Regression اضافه شود.
۵. تفکیک روشن حفظ شود: `x-required-scopes` تا زمان تصویب معنای هنجاری آن در LOT-API-PLATFORM-001 همچنان Extension سفارشی و Metadata بازبینی است. این تست‌ها اجرای Runtime را اثبات نمی‌کنند.

### A13-F02 — شکل Extensionهای CloudEvents عمداً باز است؛ CI قواعد نام/نوع CloudEvents و Allowlist نصب را اعمال نمی‌کند

**شدت:** HIGH — شکاف انطباق Wire و مرز اعتماد  
**وضعیت:** OPEN؛ الزام Runtime Allowlist قبلاً در SEC-AFF-06 ثبت شده است.

Schemaهای Partner و Canonical Event برای Extensionهای سطح بالا از `additionalProperties: true` استفاده می‌کنند. مجموعه Fixture بررسی می‌کند که یک Extension نمونه در سطح بالا پذیرفته شود. اما اثبات نمی‌کند که نام/نوع هر Extension دلخواه مطابق CloudEvents است یا برای یک Installation مشخص ثبت شده است.

CloudEvents الزام می‌کند Extension Attributeها از قرارداد نام‌گذاری و Type System استاندارد پیروی کنند. نام‌ها به حروف کوچک ASCII و رقم محدودند و مقادیر باید از Type System مربوط به CloudEvents پیروی کنند. بازبینی امنیتی موجود نیز الزام می‌کند نام/نوع Extensionها برای هر Installation ثبت شوند و رفتار Fail-closed اعمال شود.

**اصلاح لازم**
۱. تفکیک میان Envelope عمومی انتقال و اعتماد Runtime حفظ شود: بازبودن Schema به معنی مجوز پذیرش Extension دلخواه نیست.
۲. قرارداد Versioned برای Extension Profile/Allowlist تعریف شود؛ شامل نام‌های Core رزروشده، Syntax مجاز نام، نوع مقادیر، حدود اندازه/تعداد، مالک معنایی و Policy سازگاری.
۳. در بخش‌هایی که Profile عمومی امکان اعمال دارد، Fixture برای نام نامعتبر، برخورد با نام رزروشده، نوع مقدار نامعتبر و مرز تعداد/اندازه Extension اضافه شود.
۴. اثبات آتی Runtime برای Allowlist متصل به Installation جداگانه انجام شود؛ این CI نباید مدعی اثبات آن شود.
۵. `data.additionalProperties` در سطح Provider-specific باقی بماند و پیش از Normalization با Schema دقیق ثبت‌شده اعتبارسنجی شود.

این یافته با الزام Runtime Allowlist مستندشده تعارض ندارد؛ بلکه نشان می‌دهد Workflow سبز فعلی آن الزام را اعمال یا اثبات نمی‌کند.

### A13-F03 — Dialect مربوط به Schema در AsyncAPI در Validator مربوط به Ajv نادرست توصیف شده است

**شدت:** MEDIUM — ابهام Dialect و خطر Drift در آینده  
**وضعیت:** OPEN

Comment و خروجی موفقیت اسکریپت می‌گویند Payload در AsyncAPI 3.0 به‌صورت پیش‌فرض Draft 07 است. طبق AsyncAPI 3.0.0، وقتی `schemaFormat` وجود ندارد، مقدار پیش‌فرض AsyncAPI 3.0.0 Schema Object است. این Schema Object یک Superset از JSON Schema Draft 07 است و Vocabulary/Semantics اختصاصی AsyncAPI را نیز اضافه می‌کند.

Payload فعلی ظاهراً از Keywordهای سازگار با Draft 07 استفاده می‌کند؛ بنابراین Ajv Draft 07 می‌تواند همان Subset را اعتبارسنجی کند. اما این کار تمام Semantics مربوط به AsyncAPI Schema Object یا Keywordهای اختصاصی آینده را اعتبارسنجی نمی‌کند. CLI مربوط به AsyncAPI همچنان Validator سطح سند است.

**اصلاح لازم**
۱. Comment و خروجی موفقیت اصلاح شود تا بگوید: «AsyncAPI 3.0 Schema Object؛ Ajv فقط Subset فعلی Keywordهای JSON Schema سازگار با Draft 07 را بررسی می‌کند.»
۲. یا Guard اضافه شود تا Keywordهای اختصاصی AsyncAPI که در مسیر Ajv پشتیبانی نمی‌شوند رد شوند، یا اگر واقعاً Draft 07 هدف قرارداد است، صریحاً Multi Format Schema Object از نوع JSON Schema Draft 07 انتخاب شود.
۳. اعتبارسنجی AsyncAPI CLI اجباری بماند و برای هر تصمیم Dialect/Keyword، Fixture اضافه شود.
۴. Ajv Draft 07 به‌عنوان Dialect هنجاری AsyncAPI معرفی نشود.

### A13-F04 — نسخه مستقیم بسته‌های npm دقیق است، اما Toolchain فاقد بازتولیدپذیری مبتنی بر Lockfile است

**شدت:** MEDIUM — بازتولیدپذیری Build و اطمینان زنجیره تأمین  
**وضعیت:** OPEN

Workflow نسخه مستقیم بسته‌ها (`@redocly/cli`، `@asyncapi/cli`، `ajv` و `ajv-formats`) را دقیق تعیین کرده و GitHub Actionها را با Commit SHA و نسخه Node.js Pin کرده است. اما نصب در Prefix موقت با `npm install` انجام می‌شود و Lockfile ثبت‌شده در Repository برای اجرای `npm ci` وجود ندارد. بنابراین Resolution وابستگی‌های Transitive ممکن است با تغییر Semver Rangeهای بالادستی تغییر کند، حتی اگر نسخه مستقیم بسته‌ها ثابت بماند.

**اصلاح لازم**
۱. Lockfile اختصاصی Toolchain اعتبارسنجی، شامل نسخه‌های Transitive و Integrity Hashها، در Repository ثبت شود.
۲. نصب در Prefix موقت با `npm ci` و بر اساس همان Lockfile انجام شود.
۳. نسخه Node/npm و شناسه Toolchain Resolve‌شده در Evidence مربوط به Workflow ثبت شود.
۴. جایگزینی `ubuntu-latest` با خانواده مشخص Runner بررسی شود؛ با این توضیح که محتوای Image میزبانی‌شده همچنان ممکن است تغییر کند.
۵. تغییرات Dependency به‌صورت صریح و قابل بازبینی انجام شود.

Run موفق فعلی برای Dependencyهایی که همان زمان Resolve شده‌اند معتبر است؛ اما تضمین بازتولیدپذیری Dependency Graph برای Runهای آینده نیست.

### A13-F05 — معنای پاسخ Wire جلوتر از تصمیم Durability تصویب‌نشده است و نتیجه UNKNOWN برای Commit را تعریف نمی‌کند

**شدت:** CRITICAL — مانع سازگاری قرارداد و ADR  
**وضعیت:** OPEN؛ مرتبط با A11-F01 و A11-F03

قرارداد Ingestion پاسخ HTTP 202 را «پذیرش پایدار» پس از Commit شدن Inbox و Processing Job تعریف می‌کند. پاسخ 503 نیز به‌عنوان عدم دسترسی موقت «پیش از Receipt پایدار» تعریف شده است. در مقابل، ADR-002 نسخه ۰.۳.۰ به‌درستی مدل خرابی، RPO، نقطه Acknowledgement Replication، صلاحیت Promotion و Recovery Point را همچنان باز گذاشته است.

بنابراین قرارداد پاسخ از واژه «پایدار» استفاده می‌کند، درحالی‌که کلاس‌های خرابی تحت پوشش این تضمین هنوز تصویب نشده‌اند. همچنین رفتار قابل مشاهده بیرونی در وضعیتی که نتیجه Commit برابر UNKNOWN است (مثلاً از دست‌رفتن پاسخ یا Timeout درحالی‌که تراکنش ممکن است هنوز Commit شود) صریحاً تعریف نشده است. UNKNOWN نباید به‌اشتباه به‌عنوان شکست قطعی پیش از Commit گزارش شود.

**اصلاح لازم**
۱. تضمین Durability پاسخ 202 به Failure Model تصویب‌شده توسط مالک و قرارداد Durability اثبات‌شده برای Candidate متصل شود؛ تا آن زمان وضعیت PROPOSED/BLOCKED حفظ شود.
۲. نتیجه UNKNOWN در API/Status/Retry به‌صورت مستقل از NOT ACCEPTED قطعی و ACCEPTED قطعی تعریف شود.
۳. عبارت 503 با معنای «پیش از Receipt پایدار» فقط زمانی معتبر باشد که سامانه بتواند عدم Commit عملیات را اثبات کند. اگر نتیجه نامعلوم است، پاسخ نباید عدم پذیرش را قطعی اعلام کند.
۴. Retry باید همان Source Identity و Binding تغییرناپذیر درخواست را حفظ کند و روی Authority فعال و Fenced دوباره وارد Arbitration شود؛ Read منفی به‌تنهایی مجوز Insert دوم نیست.
۵. رفتار Stable Receipt Reference برای Duplicate قطعی تعریف شود و ایجاد WorkItem دوم ممنوع بماند.
۶. Fixtureهای مثبت/منفی برای معنای ACCEPTED، DUPLICATE، CONFLICT، NOT ACCEPTED و UNKNOWN اضافه شود؛ بدون ادعای اینکه Fixtureهای Schema ماشین حالت Runtime را اثبات می‌کنند.

این یافته باید همراه A11-F01/F03 حل شود، نه صرفاً با ویرایش متن پاسخ.

### A13-F06 — پوشش Fixtureهای Payload نماینده است، نه جامع

**شدت:** MEDIUM — محدودیت پوشش اطمینان‌بخشی  
**وضعیت:** OPEN / محدودیت دامنه اعلام‌شده

Validator تعدادی از Component Schemaها را Compile می‌کند و Payloadهای مثبت/منفی منتخب را می‌آزماید. تمام Schemaهای Request/Response در OpenAPI، تمام Responseهای Operationها، همه Variantهای خطا، تمام Message Schemaهای AsyncAPI یا همه Schemaهای ارجاع‌شده به‌عنوان Fixture Target فهرست نشده‌اند. Redocly/AsyncAPI CLI ساختار سند را اعتبارسنجی می‌کنند، اما معتبر بودن سند برابر با پوشش جامع Instanceها نیست.

**اصلاح لازم**
۱. Manifest ماشینی پوشش Schema/Operation ایجاد شود.
۲. تمام Rootهای Request و Response، از جمله Error Responseها و Schemaهای Referenced، فهرست شوند.
۳. برای هر Root پشتیبانی‌شده حداقل یک Fixture مثبت و برای Invariantهای امنیتی/Tenant/Identity/Size/Enum Fixture منفی تعریف شود.
۴. افزودن Schema/Operation جدید بدون تعیین وضعیت آزمون باید CI را Fail کند.
۵. Schemaهایی که عمداً آزمون ندارند، با دلیل مورد تأیید مالک و طبقه‌بندی ریسک مشخص شوند.

## ۳. الزام‌های موجودی که نباید به‌اشتباه بسته‌شده اعلام شوند

- SEC-AFF-06: اجرای Allowlist منبع/Event/Schema/Extension مختص Installation همچنان الزام Runtime است.
- SEC-AFF-03 / LOT-API-PLATFORM-001: معنای Extension سفارشی Scope و Enforcement آن همچنان باز است.
- A11-F01/F03: Durability و Arbitration نتیجه UNKNOWN مربوط به Commit همچنان باز است.
- A11-F02: Authority Epoch و Fencing نویسنده قدیمی همچنان باز است.
- A11-F04/F05/F06/F07/F08: تمامیت جفت، Fingerprint، Retention، Quarantine و معنای پاسخ همچنان باز است.
- مجموعه Canonical شامل ۴۷ Case در A7 و ۲۱ Subcase تکمیلی همچنان طراحی است؛ Runtime Proof اجرا نشده است.
- هر هشت Gate مربوط به A4 همچنان NOT APPROVED هستند.

## ۴. بسته کاری پیشنهادی بعدی

**G09-A14 — سخت‌سازی اعتبارسنجی قرارداد و هم‌ترازی وضعیت پاسخ**

ترتیب اجرا:
۱. اصلاح توصیف Dialect در AsyncAPI و متن خروجی Validator.
۲. افزودن Assertion دقیق نگاشت Security Scheme/Scope هر Operation و Mutation Test.
۳. تعریف CloudEvents Extension Profile و Fixtureهای انطباق؛ اثبات Runtime Allowlist جدا بماند.
۴. بازتولیدپذیر کردن Dependency Graph ابزارهای Validator با Lockfile.
۵. ایجاد Manifest کامل پوشش Fixtureهای Schema/Operation.
۶. هم‌تراز کردن معنای 202/503/UNKNOWN با تصمیم‌های مالک در ADR-002 پیش از تغییر Promise عمومی Wire.
۷. اجرای هر دو Workflow روی یک Head نهایی و ثبت Evidence کامل Jobها.

هیچ Runtime Code، Persistence Engine، مقدار Durability/RPO، Identity Issuer یا قاعده اختصاصی Partner انتخاب نمی‌شود. Merge و Deploy نیز مجاز نیست.

## ۵. استانداردها و منابع مرجع

- AsyncAPI 3.0.0 — پیش‌فرض Multi Format Schema Object و Dialect مربوط به Schema Object: https://www.asyncapi.com/docs/reference/specification/v3.0.0
- CloudEvents — نام‌گذاری Attribute، Type System، Extensionها و هویت source+id: https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md
- OpenAPI 3.2.1 — Dialect پیش‌فرض OAS Schema Object و مبنای JSON Schema Draft 2020-12: https://spec.openapis.org/oas/latest.html
- RFC 8785 — JSON Canonicalization Scheme؛ Property تکراری، حفظ Unicode و محدودیت IEEE-754: https://www.rfc-editor.org/rfc/rfc8785.html
- AWS Builders’ Library — ایمن‌سازی Retry با Idempotent API؛ ثبت اتمیک Idempotency، پاسخ معادل، درخواست دیررس و عدم تطابق پارامتر: https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- PostgreSQL Failover و Fencing/STONITH برای Primary قدیمی: https://www.postgresql.org/docs/current/warm-standby-failover.html
- PostgreSQL Synchronous Replication: https://www.postgresql.org/docs/current/warm-standby.html
- PostgreSQL WAL Durability Settings: https://www.postgresql.org/docs/current/runtime-config-wal.html

این منابع ورودی بازبینی‌اند؛ رفتار پیاده‌سازی Lottorito را اثبات نمی‌کنند.

## ۶. تعیین تکلیف

G09-A13 بازبینی اطمینان‌بخشی توسط همان نویسنده برای سازوکار اعتبارسنجی قرارداد و مرزهای آن است. این سند ممیزی مستقل نیست و هیچ یافته A11/A7/A8/A4 را نمی‌بندد.

**نتیجه: PASS مربوط به CI برای کنترل‌هایی که واقعاً اجرا شده‌اند پذیرفته است؛ اما اطمینان‌بخشی قرارداد کامل نیست.** یافته‌های A13-F01 تا F06 باز هستند. بسته G09-A14 گام بعدی پیشنهادی برای سخت‌سازی مستندات/قرارداد است. PR #76 همچنان Open/Draft است و هیچ Merge یا Deploy مجاز نیست.
