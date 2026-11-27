# مشخصات پذیرش امنیتی و مرز Runtime افیلیت

**شناسه سند:** LOT-AFFILIATE-SEC-ACC-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیشنهادی؛ نه پیاده‌سازی و نه تأیید امنیتی | **تاریخ:** ۲۰۲۶-۱۱-۲۷

## ۱. هدف و مرز

این سند یافته‌های LOT-AFFILIATE-SEC-001 را به الزامات قابل‌آزمون برای یک برش Runtime ایزوله افیلیت تبدیل می‌کند. هیچ Identity Provider، قالب Token، دیتابیس، Queue، KMS، شریک، حوزه قضایی، دوره نگهداری یا Quota عددی را انتخاب نمی‌کند.

تنها هدف اثبات مجاز، یک رویداد Synthetic و غیرمشتری است: احراز هویت، اتصال به Installation معتبر Tenant، پذیرش پایدار، Deduplication و ارزیابی با Policy صریح دامنه. Journal کمیسیون خارج از Ingress است و فقط پس از تأیید جداگانه قابل بررسی خواهد بود. هیچ بازیکن واقعی، پرداخت، اعتبار Wallet، Payout یا فرمول شریک مفروض نیست.

Ingress می‌تواند Receipt تغییرناپذیر و Work Item پایدار بسازد؛ اما نباید Wallet، Ledger، Payment، Settlement یا Payout را تغییر دهد. هر اثر اقتصادی احتمالی آینده فقط از Command جداگانه و مجاز دامنه کمیسیون عبور می‌کند.

## ۲. ماتریس Principal و مجوزدهی

| Principal | سطح مجاز | Binding الزامی | ممنوع |
|---|---|---|---|
| اپراتور پلتفرم | Control Plane ممتاز | احراز هویت قوی انسانی، Role ممتاز صریح، علت، ارتقای زمان‌دار و Audit | استفاده مجدد از Credential شریک؛ دسترسی ضمنی همه Tenantها |
| مدیر Tenant | مدیریت Program و Membership در Tenant | Subject + عضویت فعال + Capability + محدوده Resource | Cross-tenant؛ تغییر تاریخچه مالی Immutable |
| اپراتور/پشتیبان Tenant | Resourceهای صریحاً تفویض‌شده | عضویت + Capability محدود + هدف؛ تفکیک Read/Write | دسترسی Platform-wide؛ تغییر Policy کمیسیون بدون مجوز |
| Affiliate/Agent | پروفایل، Referralهای مجاز و Statement خود | عضویت Subject در Affiliate + Tenant/Product + مالکیت | اطلاعات Affiliate دیگر؛ تغییر Attribution یا Ledger |
| Client شریک | فقط Event Ingress | Machine Identity + Installation فعال + Binding سمت سرور Tenant/Product/Environment + Allowlist | Management API؛ انتخاب Tenant؛ تغییر مالی |
| Worker پس‌زمینه | فقط Job پایدار | Workload Identity + Binding به Receipt/Job + بازبینی Policy | اعتماد به Tenant ID در Payload؛ Command مستقیم دلخواه |

مجوزدهی باید سمت سرور برای هر عملیات و هر Resource بررسی شود. Authentication معادل Authorization نیست. شناسه Opaque، Path Parameter، Scope Extension سفارشی و Payload هیچ اختیاری ایجاد نمی‌کنند. ماتریس Role-to-Capability انسانی و فرآیند دسترسی ممتاز همچنان تصمیم مالک است.

Machine Ingress به Credential معتبر، Binding تأییدشده Issuer/Audience/Client، Installation فعال، Binding معتبر سمت سرور Tenant/Product/Environment، Source Namespace ثبت‌شده، Event/Schema مجاز و Policy Quota نیاز دارد. پیش از تصویب تصمیم هویت پلتفرم، JWT، OAuth Issuer، mTLS یا DPoP را فرض نکنید.

## ۳. جریان ورودی مورداعتماد

۱. Credential را به Principal Resolve کنید؛ Issuer، Audience، Expiry، Not-before، Client Binding و Revocation را متناسب بررسی کنید.
۲. Installation را از Binding سمت سرور Credential Resolve کنید؛ Tenant/Product/Environment از همان رکورد استخراج شود.
۳. Guardهای اندازه Request، Parser، Rate و Concurrency پیش از کار پرهزینه اعمال شوند.
۴. JSON را Strict Parse کنید؛ Member تکراری Object، UTF-8 نامعتبر، Content-Type پشتیبانی‌نشده و CloudEvents ناقص رد شوند.
۵. Context در CloudEvents و Extensionهای ثبت‌شده بررسی شوند. Source ادعای Namespace است، نه ورودی مجوزدهی.
۶. dataschema فقط به Schema/Version ثبت‌شده Immutable یا Artifact محلی Pinشده Resolve شود؛ URL شریک هرگز Dereference نشود.
۷. Event Type، نسخه Schema، Policy فیلد ناشناخته و محدودیت‌های Installation بررسی شوند.
۸. Fingerprint نسخه‌دار و مصوب محاسبه و Digest بایت خام جداگانه حفظ شود.
۹. در یک تراکنش دیتابیس، Inbox Receipt و Job/Outbox پایدار تحت هویت یکتای Event ذخیره و پیش از 202 Accepted Commit شوند.
۱۰. Worker، Job را با Lease/Fencing دریافت کند، Installation/Policy را دوباره بررسی و Transitionهای یکنواخت را ثبت کند. تحویل At-least-once است.
۱۱. Qualification کمیسیون در آینده Command جداگانه دامنه است. Posting مالی نیازمند مجوز جدا، Economic-effect Key، Journal دوبل متوازن و Immutable و Reconciliation است.
۱۲. Eventهای پایین‌دستی از Transactional Outbox منتشر و ارتباط Receipt/Job/Qualification/Journal حفظ شود.

## ۴. هویت، Idempotency و Fingerprint

چهار هویت مستقل بمانند:
- Request Identity: هدر HTTP Idempotency-Key با Scope مربوط به Principal/Installation، Operation و Request Fingerprint.
- Source Event Identity: tenant_id + product_id + integration_installation_id + source + id.
- Processing Identity: شناسه پایدار Inbox Receipt و Job.
- Economic-effect Identity: کلید اثر متعلق به دامنه کمیسیون، مستقل از Source Event ID.

| وضعیت | نتیجه الزامی | اثر جانبی |
|---|---|---|
| Event معتبر جدید | 202 فقط پس از Commit شدن Inbox + Job/Outbox | یک Receipt و یک Job پایدار |
| هویت Event و Fingerprint یکسان | بازگرداندن Receipt/نتیجه قبلی | بدون Job/اثر دوم |
| هویت یکسان و Fingerprint متفاوت | تعارض 409؛ Quarantine/Audit | بدون پردازش یا اثر مالی |
| Request Key و Fingerprint یکسان | Replay پاسخ قبلی طبق Retention مصوب | بدون Mutation تکراری |
| Request Key یکسان و Fingerprint متفاوت | 409 | بدون Mutation |
| Delivery هم‌زمان یکسان | Constraint پایدار/Transaction یک برنده انتخاب کند | یک Receipt/Job |
| Retry Worker پس از Crash | ادامه Idempotent | بدون Qualification/Journal تکراری |
| Event خارج از ترتیب | Policy صریح؛ در غیر این صورت Hold/Reject | بدون Reorder مالی بی‌صدا |

پروفایل پیشنهادی Fingerprint: Strict Parse؛ رد JSON Member تکراری؛ اعتبارسنجی Envelope/Schema؛ Canonicalization کل CloudEvents پذیرفته‌شده با RFC 8785 JCS؛ سپس SHA-256 روی UTF-8 Canonical. Digest بایت خام جداگانه حفظ شود. پروفایل باید نسخه‌دار، در ADR تصویب‌شده و دارای Test Vector چندزبانه برای Number و Unicode باشد. Typeها را Coerce و Unicode را بی‌صدا Normalize نکنید.

یکتایی Event و مقایسه Fingerprint با Constraint/Transaction پایدار دیتابیس اعمال شود، نه فقط Cache یا Deduplication در Queue.

## ۵. حاکمیت Event/Schema

Registration هر Installation باید نسخه‌دار و شامل Binding Tenant/Product/Environment، چرخه Credential، Sourceهای مجاز، Event Typeها، نام/Type Extensionها، Schema ID/Versionهای Immutable، Policy فیلد ناشناخته، Policy ترتیب، طبقه‌بندی/Retention Payload، پروفایل Quota، تاریخ اثر و Actor تأییدکننده باشد.

Source، Event Type، Extension، Schema ID یا Version ناشناخته باید Fail Closed شود. Resolve کردن Schema محلی/Registry-backed و برای هر Version Immutable باشد. Redirect، DNS یا URL دلخواه در dataschema، $ref، لینک Attachment یا Payload دنبال نشود. تغییر Schema نیازمند بازبینی سازگاری، Registration صریح، Fixture به‌روز و Approval است. Fallback از نوع Best-effort نباید داده ناشناخته را به واقعیت مالی تبدیل کند.

## ۶. حفاظت منابع

هیچ Limit عددی در این سند تصویب نمی‌شود. پیش از پیاده‌سازی، سقف و Load Test برای بایت خام/Decompressed؛ عمق/Node/Member در JSON؛ طول String/Array؛ تعداد/طول Extension؛ زمان Parse/Validation؛ Concurrency به‌ازای Credential/Installation/Tenant/Global؛ Rate/Burst؛ عمق Queue/Retry/Dead-letter؛ Page/Byte پاسخ؛ و Storage/Retention Payload خام Tenant تعریف شود.

Limit در اولین لایه ممکن اعمال شود؛ خطای پایدار و محدود برگردد؛ Quota نصب نتواند سقف سخت سراسری را دور بزند. مرزهای N و N+1، Burst خصمانه و Backpressure تست شوند. مقادیر عددی نیازمند تأیید Product/Security/Operations هستند، نه حدس.

## ۷. ناورداهای Persistence و Worker

- هویت یکتای Event در دیتابیس Enforce شود.
- Inbox Receipt و Job/Outbox پایدار اتمیک Commit شوند؛ پیش از Commit، 202 ممنوع است.
- شکست تراکنش نباید Receipt پذیرفته‌شده یا Job قابل‌اجرا باقی بگذارد.
- Lease/Fencing مانع بازنویسی وضعیت جدید توسط Worker قدیمی شود.
- Transitionها یکنواخت و قابل Audit باشند؛ Retry شواهد خطای قبلی را پاک نکند.
- Queue ابزار انتقال است، نه Source of Truth؛ رکورد پایدار دیتابیس مرجع است.
- Tenant/Product Context معتبر از Receipt بیاید، نه Event Body.
- Posting مالی در صورت تصویب آینده Command جدا و Idempotent با Debit/Credit متوازن، Journal Immutable و Reconciliation باشد.
- Replay/Reprocess نیازمند Permission، Reason، Scope و Audit صریح است؛ یکتایی را دور نمی‌زند و اثر اقتصادی دوم نمی‌سازد.

## ۸. حفاظت داده و Audit

پیش از Runtime، طبقه‌بندی/هدف داده، حداقل‌سازی، Encryption، مالکیت/چرخش Key، Retention/Deletion، Legal Hold، دسترسی Payload خام، Backup/Restore و Retention شواهد Audit تصویب شوند.

Payload خام شریک نباید در Log، Trace، Metric، Exception یا Export پشتیبانی عادی ظاهر شود. Payload و Digest جداگانه محافظت شوند. دسترسی ممتاز/Break-glass نیازمند علت، مجوز زمان‌دار و Audit Immutable است. Token، Secret، داده شخصی و فیلد حساس شریک Redact شوند. تصمیم گرفته شود Hash پس از حذف Payload حفظ می‌شود یا نه و ریسک بازشناسایی بررسی شود.

Audit حداقل شامل چرخه Credential؛ تغییرات Installation؛ تغییر Membership/Permission؛ Eventهای پذیرفته/رد/Conflict/Quarantine؛ Replay؛ تغییر Schema/Allowlist؛ نسخه Policy؛ Lease/Retry/Dead-letter؛ تصمیم Qualification کمیسیون؛ و ارجاع Journal جداگانه مجاز باشد.

## ۹. ماتریس پذیرش Runtime الزامی

| شناسه | سناریو | Assertion موردانتظار |
|---|---|---|
| AUTH-01 | Credential ماشینی مفقود/نامعتبر/منقضی/باطل | رد پیش از Receipt |
| AUTH-02 | Issuer/Audience/Client Binding اشتباه | رد؛ بدون افشای Installation |
| AUTH-03 | Installation غیرفعال یا Credential باطل‌شده | رد پس از مرز Revocation مصوب |
| TEN-01 | Credential Tenant A شناسه Tenant B را ارسال کند | Claim غیرمعتبر رد/نادیده؛ هرگز Bind به B نشود |
| TEN-02 | Principal از Tenant A به Resource متعلق به B دسترسی یابد | رد بدون افشای وجود Resource |
| TEN-03 | Membership حین Session فعال لغو شود | Request بعدی در Bound مصوب رد شود |
| SCOPE-01 | Principal فاقد Capability عملیات | رد؛ بدون Mutation |
| SCOPE-02 | هر Operation محافظت‌شده Mapping سمت سرور داشته باشد | تست Contract/Runtime موفق |
| PROP-01 | Property متعلق به Server یا ناشناخته در Request | بدون Mass Assignment |
| EVT-01 | Source/Type/Extension/Schema ناشناخته | Fail Closed؛ بدون Job |
| EVT-02 | dataschema به Loopback/Private/Link-local/Redirect اشاره کند | صفر درخواست شبکه؛ رد |
| PARSE-01 | JSON Member تکراری، UTF-8 نامعتبر یا عمق زیاد | رد پیش از Persistence |
| IDEM-01 | هویت/Fingerprint یکسان در Delivery ترتیبی | Receipt اصلی؛ یک Job |
| IDEM-02 | هویت/Fingerprint یکسان در Delivery هم‌زمان | یک Receipt/Job در Race |
| IDEM-03 | هویت یکسان و Fingerprint متفاوت | 409 + Quarantine/Audit؛ بدون اثر تجاری |
| IDEM-04 | Request Key یکسان و Fingerprint متفاوت | 409؛ بدون Mutation |
| TX-01 | خطای تزریقی میان نوشتن Inbox و Job | Rollback؛ بدون 202 |
| TX-02 | Commit موفق اما Response گم و Retry شود | Receipt اصلی؛ بدون Job دوم |
| WORK-01 | Crash Worker پیش/پس از Domain Command | Retry ایمن؛ حداکثر یک اثر |
| WORK-02 | Worker قدیمی پس از انقضای Lease تکمیل کند | Fencing مانع بازنویسی |
| ORDER-01 | Event تکراری/تأخیری/خارج از ترتیب | Policy صریح؛ بدون Reorder مالی بی‌صدا |
| LIMIT-01 | مرزهای N و N+1 اندازه/عمق/Array/Rate | N معتبر؛ N+1 رد محدود |
| LIMIT-02 | یک Tenant از Quota عبور کند و ظرفیت کلی موجود باشد | فقط همان Tenant Throttle شود |
| LIMIT-03 | سقف سخت سراسری پر شود | Backpressure از سرویس محافظت کند |
| AUDIT-01 | Replay، آزادسازی Quarantine یا تغییر Allowlist | Actor/Reason/Policy/Correlation ثبت شود |
| PRIV-01 | Secret/PII مصنوعی در Log/Trace/Error | Assertionهای Redaction موفق |
| FIN-01 | Event ورودی پذیرفته شود | هیچ مسیر نوشتن Wallet/Ledger/Payment/Payout اجرا نشود |
| FIN-02 | Command کمیسیون جدا و مصوب Replay شود | یک Journal متوازن Immutable برای هر Effect Key |

از هویت/داده Synthetic استفاده شود. نسخه Fixture، محیط، Commit، نسخه ابزار، Run ID و Artifact ثبت شوند. قبولی ماتریس لازم است اما برای Production کافی نیست.

## ۱۰. دروازه انتشار و شواهد

**Gate A — طراحی، پیش از پیاده‌سازی:** تصویب مدل Principal، ماتریس Capability، Issuer/Audience/Client Binding، چرخه Credential، Strict Parser، ADR و Vectorهای Fingerprint، مالک Event Registry، سقف منابع، چرخه داده و Policy Audit.

**Gate B — اثبات Runtime ایزوله، پیش از Sandbox شریک:** فقط Ingress مصنوعی پیاده‌سازی شود. شواهد مجوزدهی Tenant/Object، عدم Fetch برای Schema، اتمیک بودن Inbox/Job، Duplicate هم‌زمان، Quarantine تعارض، بازیابی Worker، Quota و صفر اثر مالی ارائه شود. کنترل‌های پرریسک مستقل بازبینی شوند.

**Gate C — Sandbox شریک، پیش از Certification Adapter:** مستندات واقعی API/Event شریک، Sandbox مجاز، Source Namespace، نمونه Schema، معنای Retry/Order، پروفایل Credential و مجوز کتبی دریافت شود. فقط Event تأییدشده Mapping شود؛ فرمول شریک یا وضعیت مشتری استنباط نشود.

**Gate D — Production:** تصویب حقوقی/حوزه قضایی و مدل عملیاتی؛ ارزیابی امنیتی/تست نفوذ؛ مالکیت SLO/Alert/Incident؛ شواهد چرخش/ابطال Key؛ Backup/Restore/DR؛ تأیید حفاظت داده؛ Certification شریک؛ Policy کمیسیون و Reconciliation تأییدشده Finance؛ و مجوز صریح انتشار مالک لازم است.

برچسب شواهد: PASS = تست/Workflow مشاهده‌شده و تکمیل‌شده روی Commit دقیق؛ FAIL = شکست مشاهده‌شده؛ PENDING = اجرا کامل نشده؛ NOT TESTED = شاهدی جمع‌آوری نشده؛ BLOCKED = پیش‌نیاز/مجوز مانع اجراست. پیشنهاد مستند، Schema CI، Mock یا بازبینی طراحی هرگز Runtime PASS یا تأیید Production نیست.

## ۱۱. تصمیم‌های باز

Identity Provider و Token Profile؛ ماتریس Capability انسانی؛ مالکیت Installation و SLA Credential؛ مالک Event/Schema Registry؛ ADR Fingerprint؛ Quota عددی/Retry/Order؛ حداقل‌سازی و Retention/Encryption/Deletion Payload؛ Audit Catalog؛ Qualification کمیسیون و Economic-effect Identity؛ مستندات/Sandbox/حوزه قضایی/مجوز شریک.

## ۱۲. مراجع

LOT-AFFILIATE-WIRE-001؛ LOT-AFFILIATE-SEC-001؛ LOT-API-PLATFORM-001؛ LOT-EVENT-001؛ RFC 9700؛ RFC 8785 (اطلاع‌رسان)؛ CloudEvents 1.0.2 JSON Event Format؛ OWASP API Security Top 10 (2023).

این سند مشخصات پذیرش پیشنهادی است؛ نه پیاده‌سازی، Certification شریک، نظر حقوقی، تست نفوذ یا تأیید امنیت Production.