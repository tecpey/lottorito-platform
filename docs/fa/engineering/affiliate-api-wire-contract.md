# قرارداد Wire API افیلیت و پروفایل دریافت رویداد

**شناسه سند:** LOT-AFFILIATE-WIRE-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیش‌نویس قرارداد Wire پیشنهادی؛ تصویب، انتشار یا پیاده‌سازی نشده است

## ۱. هدف و اعتبار

این سند فهرست قابلیت‌های LOT-AFFILIATE-API-001 و قواعد مشترک LOT-API-001 / LOT-EVENT-001 را به یک پیشنهاد فنی قابل‌توصیف با ابزار تبدیل می‌کند. جایگزین اسناد مرجع نیست، کل سطح محصول Affiliate را تعریف نمی‌کند و وجود هیچ Endpoint را اثبات نمی‌کند.

محدوده نخست Affiliate و Agent است. Live Chat ماژولی مستقل و مرحله بعدی است و در این Artifactهای API قرار ندارد. قرارداد مستقل از Provider است. برای این کار، API واقعی مشتری، کاتالوگ رویداد، Credential، شخصیت حقوقی، حوزه قضایی، Sandbox یا نگاشت شریک دریافت و راستی‌آزمایی نشده است.

## ۲. دو مرز مستقل API

| مرز | هدف | هویت فراخوان | Artifact قرارداد |
|---|---|---|---|
| Affiliate Management API | مدیریت Tenant و منابع Self-service افیلیت/ایجنت | هویت کاربر/تفویض‌شده یا Application مجاز | `contracts/openapi/affiliate-management.v1.json` |
| Partner Event Ingestion API | ارسال Server-to-server رویدادهای منبع از Integration تأییدشده | هویت ماشینی اختصاصی متصل به یک Integration Installation | `contracts/openapi/partner-event-ingestion.v1.json` |

این دو مرز نباید Credential، Scope، بودجه Rate Limit یا فرض اعتماد مشترک داشته باشند. پارامتر مسیر فقط Selector است و اثبات‌کننده اختیار Tenant یا Integration نیست. هویت ماشینی احرازشده باید در سمت سرور دقیقاً به Integration Installation، Tenant، Product و Environment مجاز نگاشت شود.

Management API نباید ادعای رویداد شریک را جایگزین مجوزدهی دامنه کند. Ingestion API نیز نباید مدیریت عمومی Affiliate یا تغییر مالی ارائه دهد.

### معنای Server Base در OpenAPI

هر دو سند OpenAPI به‌صورت صریح Server Base نسبی `/` را اعلام می‌کنند. طبق OpenAPI 3.2.1، اگر `servers` حذف شود یا آرایه خالی باشد، مقدار پیش‌فرض باز هم `/` است؛ بنابراین حذف این فیلد به‌معنای «نبود سرور» نیست. Base نسبی صریح، بدون جعل Host، محیط یا استقرار، رفتار Resolution مشخصات را شفاف می‌کند. این مقدار Endpoint مستقرشده یا Host عملیاتی نیست. پس از این اصلاح، استثنای عمومی Redocly برای خاموش‌کردن `no-empty-servers` حذف شد.

## ۳. سطح محدود نخست برای Management API

فایل OpenAPI فقط این برش اولیه را تعریف می‌کند:

- `GET /v1/affiliate/programs` — فهرست Programهای قابل مشاهده برای فراخوان.
- `GET /v1/affiliate/me` — نمایش پروفایل محدود به Membership فعلی Affiliate احرازشده.
- `POST /v1/affiliate/referral-links` — ایجاد Referral Link با کلید مقصد از پیش Allowlistشده.
- `GET /v1/affiliate/referral-links/{referralLinkId}` — خواندن Link با مجوز صحیح.
- `GET /v1/affiliate/attributions/{attributionId}` — خواندن تصمیم Attribution مجاز و حداقلی از نظر حریم خصوصی.

این فهرست عمداً کل Inventory قابلیت‌ها نیست. انتشار Program، تأیید Membership، تغییر سلسله‌مراتب Agent، مدیریت Campaign، محاسبه کمیسیون، Statement، Adjustment، Export و گردش Payout خارج از این Wire Slice هستند. افزودن آن‌ها به تصمیم‌های دامنه و سیاست مربوط نیاز دارد.

در درخواست ساخت Referral از `destinationKey` ثبت‌شده استفاده می‌شود، نه URL دلخواه Redirect. این کار مانع تبدیل API به ابزار Open Redirect می‌شود. شناسه Opaque نیز جایگزین مجوزدهی Object-level نیست.

## ۴. پروفایل احراز هویت و مجوزدهی

همه عملیات به HTTPS و Bearer Access Token نیاز دارند. قرارداد OpenAPI عمداً URL صادرکننده Token، قالب Token، عمر آن یا نحوه استقرار OAuth را جعل یا فرض نمی‌کند. روش پیشنهادی برای صدور Server-to-server، OAuth 2.0 Client Credentials همراه احراز هویت قوی Client محرمانه (برای نمونه private-key JWT یا mutual TLS) است که باید با تصمیم صریح LOT-API-PLATFORM-001 و بازبینی RFC 9700 تعیین شود.

Scope لازم است اما کافی نیست. هر درخواست علاوه بر آن باید Membership جاری Tenant یا Binding اتصال ماشینی، Entitlement محصول، مالکیت Object، Role، وضعیت Resource و Policy قابل‌اعمال را بررسی کند. Context مربوط به Tenant و Product باید از هویت/پیکربندی معتبر سمت سرور استخراج شود. شناسه Tenant ارسالی فراخوان هرگز مرجع اختیار نیست.

قابلیت‌های حداقلی پیشنهادی با Extension سفارشی `x-required-scopes` در سطح Operation فایل OpenAPI ثبت شده‌اند. این سازوکار، مکانیزم استاندارد Scope در OAuth2 یعنی `security` نیست؛ HTTP Bearer Schemeهای فعلی عمداً Issuer یا Flow مربوط به OAuth را جعل نمی‌کنند. این Extension تا تصویب معنای آن در LOT-API-PLATFORM-001 صرفاً Metadata بازبینی است؛ پس از تصویب، Resource Server باید تمام قابلیت‌های فهرست‌شده را اعمال کند و Code Generatorهای Client نباید آن را Flow دریافت Token تلقی کنند. نام نهایی، رفتار تفویض/Consent و نیاز به احراز هویت تقویتی برای عملیات ممتاز همچنان باز است.

## ۵. پروفایل ورودی رویداد شریک

عملیات دریافت:

`POST /v1/integrations/{integrationId}/events`

در هر درخواست دقیقاً یک رویداد JSON با حالت Structured در CloudEvents و با `Content-Type: application/cloudevents+json` دریافت می‌شود. نسخه منتخب پروفایل CloudEvents 1.0.2 است. پارامتر `integrationId` نه Secret است و نه مجوز دسترسی می‌دهد. Token باید به همان Integration Installation و Tenant، Product و Environment آن متصل باشد.

قواعد ورودی:

۱. Integration، Tenant، Product، Environment و Namespace مجاز Source از هویت ماشینی احرازشده استخراج شود.
۲. مقدار `source` در CloudEvents باید با Namespace ثبت‌شده برای همان Installation منطبق باشد؛ `type` نیز باید در Allowlist صریح Eventهای آن قرار داشته باشد.
۳. زوج `source + id` در CloudEvents هویت رویداد منبع است. Namespace مربوط به Source باید Allowlist و به Integration Installation احرازشده متصل باشد. مرز یکتایی پایدار در دیتابیس برابر `tenant_id + product_id + integration_installation_id + source + id` اعمال شود.
۴. `data` ورودی غیرقابل‌اعتماد Provider است. پیش از Normalization باید با Schema دقیق و نسخه‌بندی‌شده Provider که برای همان Integration پیکربندی شده اعتبارسنجی شود. Schema عمومی Object در OpenAPI فقط مرز انتقال را تعریف می‌کند؛ مجوز پذیرش فیلد دلخواه یا Event Type ناشناخته نیست.
۵. به Tenant، Product، Affiliate، Currency، Amount، Role، Commission یا وضعیت Payable ادعاشده در Payload اعتماد نشود. نگاشت و راستی‌آزمایی آن‌ها با پیکربندی و قواعد دامنه تحت مالکیت سرور انجام شود.
۶. Provenance و Hash تمامیت Payload طبق سیاست Retention و دسترسی مصوب حفظ شود. دسترسی به Payload خام محدود باشد و Payload خام در Logهای عادی کپی نشود.
۷. Inbox Receipt و Job پردازش پایدار در یک تراکنش، پیش از بازگرداندن `202 Accepted` ذخیره شوند.
۸. پردازش At-least-once است. مصرف‌کننده و اثرهای پایین‌دستی باید Idempotent باشند؛ پلتفرم تحویل Exactly-once در شبکه را تضمین نمی‌کند.

این پروفایل عمومی هیچ Event Type، فیلد Payload، قالب Signature یا نگاشت مختص شریک را تصویب نمی‌کند. جزئیات مذکور تا دریافت قرارداد واقعی شریک و شواهد Sandbox باز می‌مانند.

## ۶. مدل هویت: درخواست، رویداد منبع و اثر اقتصادی

سه هویت مستقل می‌مانند:

- **Idempotency درخواست HTTP:** Retry یک درخواست تغییردهنده API را مشخص می‌کند. در عملیاتی که قرارداد الزام می‌کند از Header `Idempotency-Key` استفاده شود؛ کلید به Principal/Integration احرازشده، Tenant، عملیات و Fingerprint نرمال‌شده درخواست Scope شود.
- **هویت رویداد منبع:** زوج CloudEvents `source + id` که یک ادعای منبع را مشخص می‌کند. تلاش تحویل جدید نباید هویت منبع جدید بسازد.
- **هویت اثر اقتصادی:** هویت تحت مالکیت دامنه که حداقل بر اساس Tenant، Product، نوع اثر و هویت اقتصادی Canonical Scope می‌شود. این هویت فقط پس از اعتبارسنجی منبع و احراز شرایط تجاری ارزیابی می‌شود.

یک رویداد منبع می‌تواند صفر، یک یا چند اثر جداگانه و تحت کنترل ایجاد کند. شناسه رویداد منبع، شناسه اثر اقتصادی و شناسه سند دفترکل یکی نیستند. اصلاح و برگشت باید رکوردهای جدید و مرتبط باشند؛ هویت رویداد اصلی هرگز ویرایش یا مجدداً استفاده نشود.

برای Idempotency درخواست HTTP، نسخه فعلی IETF draft-ietf-httpapi-idempotency-key-header-09 فقط مرجع طراحی است، نه RFC نهایی. نحو Structured Field String آن در مثال‌ها منعکس شده است. پروفایل پاسخ پیشنهادی: کلید و Fingerprint یکسان نتیجه قبلی/وضعیت جاری را برمی‌گرداند؛ همان کلید با Fingerprint متفاوت `422` می‌دهد؛ درخواست هم‌زمانی که هنوز در حال پردازش است `409` می‌دهد. پس از نهایی‌شدن سند IETF این پروفایل بازبینی شود. برخورد CloudEvents با زوج source/id یکسان و Fingerprint متفاوت `409` است؛ زیرا تعارض تمامیت هویت رویداد منبع است، نه اختلاف Idempotency-Key درخواست HTTP.

## ۷. معیار پذیرش و معنای پاسخ HTTP

برای Ingress رویداد:

| وضعیت | پاسخ | رفتار الزامی |
|---|---:|---|
| پذیرش پیشنهادی رویداد جدید | 202 | فقط پس از Commit اتمیک Inbox + Job و تحقق شرط Acknowledgement مربوط به Durability که مالک تصویب می‌کند؛ Failure Model/RPO فعلی تصویب نشده است |
| Duplicate دقیق با Source + ID + Fingerprint یکسان | 200 | Receipt قبلی برگردد؛ Job دوم ایجاد نشود |
| Source + ID یکسان با Fingerprint متفاوت | 409 | تعارض هویت ثبت/قرنطینه شود؛ هیچ Side Effect ایجاد نشود |
| Schema یا Type نامعتبر/پشتیبانی‌نشده | 422 | طبق قرارداد تنظیم‌شده رد یا قرنطینه شود؛ بدون اثر اقتصادی |
| Body بیش از حد مجاز | 413 | پیش از Parse پرهزینه رد شود |
| Content-Type پشتیبانی‌نشده | 415 | رد شود |
| Rate Limit یا Quota مربوط به Tenant تمام شده | 429 | راهنمای Retry برگردد؛ حذف بی‌صدا ممنوع |
| عدم دسترسی موقت سرویس | 503 | عدم پذیرش فقط زمانی قطعی اعلام شود که عدم Commit اثبات شده باشد؛ UNKNOWN نباید رد قطعی تلقی شود؛ تطبیق/Retry با همان Source + ID |

**مرز تصویب:** این موارد معنای پیشنهادی Wire هستند، نه تضمین Runtime تصویب‌شده. ADR-002 همچنان PROPOSED است؛ هیچ Candidate مربوط به Persistence، Failure Model، RPO، قاعده Promotion یا Recovery Point تصویب نشده است. پاسخ `202` فقط پس از تأیید Persistence اتمیک Inbox + WorkItem و تحقق شرط Acknowledgement مربوط به Durability که مالک تصویب کرده است مجاز خواهد بود.

نتیجه Commit از نوع `UNKNOWN` نه پذیرش قطعی است و نه عدم پذیرش قطعی. API نباید آن را به‌عنوان شکست اثبات‌شده پیش از Commit توصیف کند. نگاشت دقیق HTTP Status و خطای Machine-readable برای UNKNOWN همچنان تصمیم باز مالک است. هر Retry باید همان CloudEvents `source + id` احرازشده را حفظ کند و در مرجع Persistence فعال و معتبر تطبیق داده شود؛ Read منفی به‌تنهایی مجوز Insert دوم نیست.

پاسخ موفق HTTP فقط به‌معنای پذیرش/Receipt تحت قرارداد Durability مصوب است؛ نه احراز شرایط تجاری، Attribution، ارزیابی کمیسیون، ثبت دفترکل، Payment، Settlement یا Payout.

خطاها از RFC 9457 Problem Details با `application/problem+json` پیروی می‌کنند. جزئیات خطا نباید وجود Resource در Tenant دیگر، Secret، Payload خام Provider، SQL، Host داخلی یا قواعد حساس نگاشت را افشا کند. شناسه Request/Correlation تولیدشده توسط سرور برای پشتیبانی بازگردانده می‌شود.

## ۸. نگاشت رویداد Canonical

LOT-EVENT-001 همچنان مرجع معنایی Lottorito است. CloudEvents پاکت Wire برای تعامل‌پذیری است، نه جایگزین هویت دامنه یا معنای حسابداری.

در زمان Ingress، زوج `source + id` رویداد CloudEvents شریک به‌عنوان Provenance منبع ذخیره می‌شود. پس از پذیرش و Normalization، رویداد Canonical داخلی یک Event ID جدید و تولیدشده توسط پلتفرم می‌گیرد:

| مفهوم LOT-EVENT-001 | نگاشت در CloudEvents داخلی |
|---|---|
| `event_id` | CloudEvents `id` (تولید پلتفرم؛ نه شناسه شریک) |
| تولیدکننده رویداد پلتفرم | CloudEvents `source` (URI/URN تحت مالکیت دامنه) |
| `event_type` | CloudEvents `type` |
| نوع/شناسه Aggregate | CloudEvents `subject` |
| `occurred_at` | CloudEvents `time` |
| `tenant_id` | Extension به نام `tenantid` که فقط از Context معتبر پلتفرم تعیین می‌شود |
| `product_domain` | Extension به نام `productdomain` |
| `correlation_id` / `causation_id` | Extensionهای `correlationid` / `causationid` |
| `source_system` / `source_event_id` اصلی | Extensionهای Provenance با نام `sourcesystem` / `sourceeventid` |
| `received_at` / `recorded_at` | Extensionهای `receivedat` / `recordedat` |
| Payload دامنه | CloudEvents `data` |

پروفایل عمومی JSON در Lottorito برای Attributeهای CloudEvents نام‌های متشکل از حروف کوچک ASCII و ارقام، شروع با حرف کوچک، حداکثر ۲۰ کاراکتر و مقدارهای Primitive شامل String، Boolean یا Integer علامت‌دار ۳۲ بیتی را اعمال می‌کند. این پروفایل، توصیه‌های SHOULD در CloudEvents را به قاعده محلی سخت‌گیرانه‌تر تبدیل می‌کند. این کار Allowlist نصب را تعریف نمی‌کند: Runtime همچنان باید نام Extension و نوع معنایی آن را برای Installation احرازشده ثبت‌شده بداند و پیش از Normalization موارد ناشناخته/ثبت‌نشده را رد کند. معنای Stringها (URI، URI-reference، Timestamp، Binary/Base64 یا String عادی) به Profile اختصاصی Installation وابسته است. نام منطقی Channel در AsyncAPI برابر `affiliate.canonical-events` است. این نام به‌معنای انتخاب Kafka، RabbitMQ، HTTP Callback یا Transport دیگر نیست.

## ۹. معنای داده و امور مالی

- زمان‌ها معنای مستقل خود را حفظ می‌کنند: وقوع در منبع، دریافت در پلتفرم، ذخیره پایدار و هر زمان بعدی شناسایی/ثبت تجاری یا مالی.
- مقدار ارز هرگز JSON Floating-point نیست. اگر Schema رویداد به مبلغ نیاز داشته باشد، از String عدد صحیح واحد خرد همراه ارز صریح ISO 4217 و سیاست توان اعشاری/گردکردن مستند استفاده شود. Fixture اولیه مبتنی بر ثبت‌نام، فیلد پولی ندارد.
- ارز ناشناخته، مبلغ مبهم، Event Type پشتیبانی‌نشده، هویت منبع خراب یا نگاشت خارجی متعارض هرگز به صفر تبدیل یا بی‌صدا پذیرفته نمی‌شود.
- Event احرازشده لزوماً واقعیت تجاری معتبر نیست؛ واقعیت معتبر نیز لزوماً قابل Attribution، کمیسیون، پرداخت یا ثبت نیست.
- هیچ Event شریک اجازه تغییر مستقیم Wallet، موجودی دفترکل، Payout یا وضعیت Payment را ندارد.

## ۱۰. تست‌های الزامی قرارداد و شکست

مجموعه تست Wire Contract حداقل باید موارد زیر را پوشش دهد:

۱. Event معتبر فقط پس از Commit پایدار Inbox و Job پذیرفته شود.
۲. Source/ID/Body تکراری Receipt قبلی را برگرداند و Job دوم نسازد.
۳. همان Source/ID با Body تغییرکرده قرنطینه و با 409 پاسخ داده شود.
۴. تحویل همان Event با Attempt ID متفاوت همچنان بر اساس Source/ID Deduplicate شود.
۵. Source Namespace یا Event Type ناشناخته رد شود.
۶. Binding اشتباه Tenant/Product/Environment رد شود.
۷. Tenant ID ارسالی در Payload نتواند Context معتبر را Override کند.
۸. Attributeهای الزامی CloudEvents در صورت خرابی رد شوند.
۹. Media Type پشتیبانی‌نشده و Body بزرگ رد شوند.
۱۰. Timestamp قدیمی/آینده طبق سیاست Tolerance صریح پیکربندی‌شده کنترل شود.
۱۱. Duplicate هم‌زمان فقط یک Receipt پایدار و یک Job بسازد.
۱۲. شکست دیتابیس پیش از Commit هیچ ACK موفقی ندهد.
۱۳. Crash/Retry Worker اثر پایین‌دستی را تکرار نکند.
۱۴. نقض ترتیب Event طبق Policy دامنه تشخیص یا قرنطینه شود.
۱۵. داده خام Provider از Log حذف و دسترسی Evidence Storage محدود شود.
۱۶. Token با Scope یا Integration Binding اشتباه رد شود.
۱۷. Credential منقضی/ابطال‌شده رد شود.
۱۸. دسترسی بین Tenant و Object در Management API رد شود.
۱۹. Destination Key فقط Allowlistشده باشد و Redirect دلخواه نسازد.
۲۰. Replay، اختلاف Payload و وضعیت پردازش هم‌زمان Idempotency-Key طبق پروفایل پاسخ مستندشده باشد.
۲۱. سازگاری عقب‌رو و تغییر Schema Version با Contract Test بررسی شود.
۲۲. خطاها Correlation ID داشته باشند و داده محافظت‌شده افشا نکنند.

این موارد معیار پذیرش‌اند، نه ادعای اجرای موفق تست‌ها.

### مجموعه اعتبارسنجی ماشینی نمونه‌های Schema

CI قرارداد علاوه بر اعتبارسنجی سند کامل، اسکریپت `scripts/validate_affiliate_contract_payloads.mjs` را روی نمونه‌های مثبت و منفی نماینده اجرا می‌کند:

- Schemaهای Component در OpenAPI 3.2.1 با نمونه مستقل Ajv مبتنی بر JSON Schema 2020-12 اعتبارسنجی می‌شوند. Schemaهای فعلی از Keywordهای سازگار با Instance Validation نسخه 2020-12 استفاده می‌کنند؛ Redocly همچنان اعتبارسنج کامل سند OpenAPI و Dialect مربوط به OAS است.
- Payload پیام AsyncAPI 3.0.0 با نمونه مستقل Ajv مبتنی بر Draft 07 اعتبارسنجی می‌شود؛ مطابق مبنای Schema Object در AsyncAPI 3.0.0.
- ارجاع‌های محلی Component، فیلدهای الزامی، نوع، Enum، حدود، Formatهای date-time/URI، یکتایی، Objectهای بسته و Extensionهای RFC 9457 دارای نمونه‌های مثبت/منفی نماینده هستند.
- پاکت عمومی CloudEvents پروفایل نحوی/نوعی Lottorito را اعمال می‌کند (نام حروف کوچک الفبایی‌عددی، شروع با حرف کوچک، حداکثر ۲۰ کاراکتر؛ مقدار String/Boolean/Integer علامت‌دار ۳۲ بیتی). این موضوع **مجوز پذیرش Extension دلخواه نیست**؛ Runtime باید پیش از Normalization، Allowlist اختصاصی Installation برای نام و نوع معنایی Extension را اعمال کند.
- این مجموعه، احراز هویت Runtime، Binding مستأجر، اتمیک‌بودن پایدار Inbox/Job، Deduplication، Replay، اثر دفترکل یا سازگاری Provider را اثبات نمی‌کند.

Validatorهای دو Dialect عمداً جدا هستند. در AsyncAPI 3.0.0، Payload بدون `schemaFormat` از AsyncAPI 3.0 Schema Object استفاده می‌کند که Superset مربوط به JSON Schema Draft 07 است. Ajv فقط Subset محافظت‌شده و سازگار با Draft 07 را بررسی می‌کند؛ AsyncAPI CLI سند کامل و Dialect هنجاری آن را اعتبارسنجی می‌کند. Payloadهای AsyncAPI را به Validator نسخه 2020-12 منتقل نکنید و اعتبارسنجی نمونه با Ajv را جایگزین اعتبارسنجی سند کامل توسط Redocly/AsyncAPI تلقی نکنید.

## ۱۱. استانداردها و حاکمیت نسخه

- OpenAPI Specification 3.2.1 برای قرارداد HTTP API.
- AsyncAPI 3.0.0 برای رابط منطقی رویداد.
- CloudEvents 1.0.2 برای پاکت تعامل‌پذیر رویداد.
- JSON Schema Draft 2020-12 برای محدودیت Payloadهای مستقل، در صورت پشتیبانی Validator منتخب.
- RFC 9457 برای Problem Details در HTTP.
- RFC 9700 برای بازبینی امنیت OAuth 2.0.
- IETF draft-ietf-httpapi-idempotency-key-header-09 صرفاً به‌عنوان مرجع غیراستاندارد نهایی.
- راهنمای OWASP Webhook Security برای بازبینی تهدید Replay، Signature، Duplicate و SSRF.

سازگاری Toolchain با همین نسخه‌ها باید پیش از الزام‌آورشدن در CI آزموده شود. فایل قرارداد اثبات‌کننده وجود Endpoint پیاده‌سازی‌شده یا سازگاری Provider نیست. تغییر ناسازگار به نسخه‌بندی صریح و بازبینی اثر بر مصرف‌کننده نیاز دارد.

## ۱۲. تصمیم‌های باز و دروازه انتشار

موارد باز: شریک و شخصیت حقوقی واقعی؛ حوزه قضایی؛ مالکیت Integration؛ صادرکننده Token و پروفایل آن و احراز Client؛ Namespace دقیق Source؛ کاتالوگ Event و Schemaهای Provider؛ Tolerance زمان؛ Retention Payload؛ محدودیت اندازه و نرخ؛ پنجره Retry؛ Allowlist رویداد؛ Policy Attribution؛ معنای Commission و قواعد شناسایی مالی.

پیش از تصویب Adapter شریک یا API عملیاتی، مستند رسمی API/Event و Sandbox مجاز شریک دریافت شود؛ هر فیلد و Event نگاشت شود؛ رفتار احراز هویت، Replay و Retry توافق شود؛ تست قرارداد، جداسازی Tenant، هم‌زمانی و Reconciliation با داده ساختگی بگذرد؛ و بازبینی محصول، مالی، حقوقی، امنیت، حریم خصوصی و عملیات تکمیل شود.

**اعتبار:** صرفاً پیشنهادی. این سند هیچ Endpoint مشتری، Schema شریک، پروفایل OAuth، Transport، کاتالوگ Event، فرمول کمیسیون، ثبت مالی یا دسترسی Production را تصویب نمی‌کند.
