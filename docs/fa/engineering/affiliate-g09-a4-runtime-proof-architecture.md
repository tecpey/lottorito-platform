# G09-A4 افیلیت — معماری اثبات Runtime و طراحی تست‌های خصمانه

**شناسه سند:** LOT-AFFILIATE-G09-A4-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیشنهادی؛ صرفاً طراحی معماری/تست؛ بدون پیاده‌سازی یا تأیید امنیتی | **تاریخ:** ۲۰۲۶-۱۱-۲۷
**وابستگی‌ها:** LOT-AFFILIATE-SEC-ACC-001؛ LOT-AFFILIATE-G09-A3-001؛ LOT-AFFILIATE-WIRE-001؛ LOT-IAM-TENANT-001؛ LOT-EVENT-001؛ LOT-FIN-POST-001؛ LOT-QA-001؛ LOT-TECH-ADR-001؛ LOT-PROT-001.

## ۱. هدف و مرز

G09-A4 تصمیم‌های امنیتی و مراحل اثبات P0 تا P6 در G09-A3 را به معماری تست قابل‌بازبینی، کاتالوگ سناریوهای خصمانه، مدل شواهد و ترتیب اجرا تبدیل می‌کند. این سند مجوز پیاده‌سازی، انتخاب فناوری، گزارش تست نفوذ یا ادعای آمادگی Production نیست.

هدف اثبات عمداً محدود است: برای Tenant و Installation ساختگی ثابت کنیم رویداد منبع ساختگی و احراز هویت‌شده به‌شکل قطعی پذیرفته یا رد می‌شود؛ رویداد پذیرفته‌شده دقیقاً یک InboxReceipt و یک WorkItem پایدار را به‌صورت اتمیک ایجاد می‌کند؛ Retry، هم‌زمانی و خطای Worker کار پایدار تکراری یا وضعیت قدیمی ایجاد نمی‌کنند؛ و این مسیر هیچ اثر مالی ندارد.

**موارد خارج از دامنه:** Adapter شریک، ترافیک یا Credential واقعی شریک، Endpoint عمومی، دسترسی Production/Staging، Attribution یا محاسبه کمیسیون تجاری، عملیات Wallet/Ledger/Payment/Payout، دریافت Schema خارجی، Deploy، تولید بار روی سیستم مشترک یا ادعای تحویل/اجرای اقتصادی Exactly-once.

## ۲. اختیار و وابستگی تصمیم‌ها

تمام انتخاب‌های معماری زیر تا زمان پذیرش از طریق Decision Register تحت اختیار مالک، صرفاً گزینه پیشنهادی‌اند. G09-A4 هیچ DB، Queue، Runtime، IAM Provider، قالب Token، کتابخانه Canonicalization، KMS/HSM، سقف عددی، مدت Retention یا ابزار تستی را بی‌صدا تصویب نمی‌کند.

| وابستگی | تصمیم/شاهد لازم پیش از اجرا | نقش‌های مالک/بازبین |
|---|---|---|
| A4-GATE-01 دامنه و ایزولاسیون | تصویب کتبی دامنه فقط Synthetic، محیط دورریختنی، منع Egress خارجی، نبود اتصال مالی، تخریب محیط و مدیریت شواهد | مالک محصول، امنیت، عملیات/SRE |
| A4-GATE-02 Fixture هویت | پروفایل اعتماد صرفاً تستی و سناریوهای تهدید؛ Issuer و Credential محلی/غیرتولیدی | IAM/امنیت، معماری |
| A4-GATE-03 کاندید Persistence | انتخاب کاندید دورریختنی در ADR فناوری؛ مستندسازی Transaction، Uniqueness، Isolation و Crash | معماری، داده/پلتفرم، SRE |
| A4-GATE-04 Queue/Worker | انتخاب مالکیت WorkItem پایدار و مدل Retry/Lease/Fencing؛ اعلان Queue منبع حقیقت نیست | معماری، SRE |
| A4-GATE-05 داده و Audit | تصویب فهرست فیلدهای صرفاً ساختگی، Redaction، Retention و دسترسی/انقضای شواهد | حریم خصوصی/حقوقی، امنیت، عملیات |
| A4-GATE-06 پروفایل منابع | تصویب پروفایل بار محدود و سقف‌ها پیش از آزمایش ظرفیت یا N/N+1 | محصول، امنیت، SRE، مالک |
| A4-GATE-07 عدم اثر مالی | اثبات نبود اتصال مالی و مجوز نوشتن از طریق DB Role/Schema و مرز شبکه | مالی، امنیت، معماری |
| A4-GATE-08 پذیرش تست | پذیرش Test Caseها، نتایج مورد انتظار، شدت Failure و بازبینان شواهد | QA، امنیت، معماری، مالک |

اگر Gate تصویب نشده باشد، تست‌های وابسته **BLOCKED / NOT RUN** می‌مانند. Test Double می‌تواند Orchestration را بررسی کند، اما برای اثبات Atomicity، Unique Constraint، Isolation، Locking یا Recovery جایگزین موتور واقعی Persistence نیست.

## ۳. مدل تهدید و نگاشت پوشش

مهاجمان/منابع تهدید مورد بررسی: درخواست‌دهنده بدون احراز هویت؛ کلاینت شریک احراز هویت‌شده اما متعلق به Tenant نادرست؛ کلاینت افشاشده یا باطل‌شده؛ تولیدکننده Event مخرب/معیوب؛ مدیر Tenant مخرب؛ Worker قدیمی/تکراری؛ Workload داخلی افشاشده؛ و عامل Exhaustion منابع. صرف شناخته‌شده‌بودن شریک به معنی قابل‌اعتماد بودن او نیست.

| خانواده تهدید | سطح حمله | تست‌های اصلی | مرجع |
|---|---|---|---|
| اعتماد احراز هویت و Credential | Credential ورودی، Issuer/Audience/Client Binding، انقضا/ابطال | A4-IAM-01..06 | OWASP API2:2023 |
| مجوز Object/Function/Property | Tenant، Installation، Event، عملیات مدیریتی و فیلدهای پاسخ | A4-AUTH-01..07 | OWASP API1/API3/API5:2023 |
| Replay، برخورد هویت و دستکاری | Source/ID رویداد، Fingerprint، کلید Retry و تحویل هم‌زمان | A4-IDEM-01..08 | LOT-EVENT-001؛ پروفایل کاندید RFC 8785 |
| Parse و زنجیره تأمین Schema | JSON Parser، Attribute/Extensionهای CloudEvents، ارجاع Schema و Fetch خارجی | A4-PARSE-01..06 | OWASP API7/API9/API10:2023 |
| Exhaustion منابع | Body، Nesting، Array، CPU/Memory Parser، هم‌زمانی و عدالت Tenant | A4-RES-01..05 | OWASP API4:2023 |
| صحت Transaction/Worker | InboxReceipt، WorkItem، Commit/ACK، Lease، Fencing، Crash و Retry | A4-DUR-01..08 | LOT-AFFILIATE-G09-A3-001 |
| حریم خصوصی و Audit | Log، Trace، Error، Audit و Artifact شواهد | A4-DATA-01..04 | LOT-SEC-001؛ تصمیم‌های حریم خصوصی قابل‌اعمال |
| اثر مالی | مجوز DB، فراخوانی سرویس، Egress شبکه و رکورد Economic Effect | A4-FIN-01..03 | LOT-FIN-POST-001 |

OWASP API Security Top 10 یک طبقه‌بندی پوشش است، نه گواهی‌نامه. موفقیت در بخشی از آن، انطباق کامل OWASP یا تکمیل تست نفوذ را اثبات نمی‌کند.

## ۴. معماری پیشنهادی Test Harness

### ۴.۱ اجزای منطقی

۱. **Scenario Orchestrator:** اجرای Caseهای نام‌گذاری‌شده با Seed قطعی؛ ثبت Run ID، Test Case ID و SHA کامیت.
۲. **Synthetic Identity Authority:** Issuer/Fixture محلی صرفاً تستی یا Stub قطعی Verifier؛ کنترل Issuer، Audience، Client Binding، Expiry، Revocation و Key Version. هرگز Secret تولیدی را استفاده نمی‌کند و ادعای تأیید IAM تولیدی ندارد.
۳. **Tenant و Installation Fixture Registry:** ایجاد Tenant A/B، Installation A/B، Principalها و Bindingهای سمت سرور. Tenant معتبر از Body/Header درخواست انتخاب نمی‌شود.
۴. **Ingress تحت آزمون:** مسیر Parse، Authentication، Authorization، Registry و Persistence موردنظر Production، با Endpoint/Config تستی که آشکارا ایزوله شده باشد.
۵. **Strict Parser و Schema Fixture Store:** Parser محدود؛ فقط Schema محلی و Pinشده؛ بدون Resolver شبکه‌ای در Runtime؛ Member تکراری JSON پیش از Materialization شیء رد شود.
۶. **Transactional Persistence Adapter:** DB دورریختنی منتخب و موتور Transaction واقعی. برای تست Race به Connection/Process مستقل نیاز است. Mock ناورداهای DB را اثبات نمی‌کند.
۷. **Outbox/Worker Subsystem:** WorkItem پایدار همراه Inbox Commit شود؛ اعلان Queue فقط Hint با تحویل At-least-once است؛ Claim Worker از Lease صریح و در صورت انتخاب این مدل از Fencing/Claim Token افزایشی استفاده کند.
۸. **Fault و Time Controller:** تزریق خطا در مرزهای اعلام‌شده و جلو بردن Clock قابل‌کنترل برای Expiry/Lease/Retry.
۹. **Egress Deny Layer:** Policy شبکه یا Firewall معادل، خروجی را پیش‌فرض مسدود کند؛ تلاش DNS و Connection قابل مشاهده باشد. برای URLهای Schema استثنا ایجاد نشود.
۱۰. **Financial Isolation Sentinel:** DB Role و Wiring سرویس تست، اتصال Wallet/Ledger/Payment/Payout نداشته باشد؛ هر تلاش دسترسی Failure قطعی است.
۱۱. **Evidence Collector:** خروجی تست پاک‌سازی‌شده، Assertion وضعیت DB، Trace، Telemetry منع شبکه، Permission و Checksum را جمع کند؛ Credential و Payload خام را حذف کند.
۱۲. **Disposable Environment Controller:** Namespace/Database یکتا ایجاد کند، Fixtureهای مصوب را اعمال کند، ایزولاسیون را بررسی و پس از Seal شواهد تخریب کند.

### ۴.۲ مرزهای اعتماد و جریان داده

- **TB-1 درخواست بیرونی ← Ingress:** بایت‌ها غیرقابل‌اعتمادند. محدودیت Transport/Body پیش از Parse پرهزینه اعمال شود؛ هویت Client فقط پس از Authentication معتبر است.
- **TB-2 Principal ← Installation Binding:** Tenant از Binding فعال و کنترل‌شده سمت سرور برای Installation/Client استخراج می‌شود، نه فیلد Tenant ارسالی Caller.
- **TB-3 Event ← Registry/Parser:** Source، Type، Extension و Schema Version باید با رکورد محلی مصوب تطبیق کند. URL تحت کنترل Payload صرفاً داده است، نه دستور Fetch.
- **TB-4 Ingress ← Persistence:** Source Identity، Fingerprint، InboxReceipt و WorkItem الزامی در یک Transaction و تحت Uniqueness اعمال‌شده توسط DB Commit می‌شوند.
- **TB-5 Outbox ← Queue ← Worker:** Queue کانال بیدارسازی است؛ State پایدار مرجع است. Worker پیش از Transition باید Tenant/Installation/Status و مالکیت Claim را دوباره بررسی کند.
- **TB-6 Runtime ← دامنه مالی:** این اثبات هیچ Route، Credential، مسیر شبکه یا DB Grant به دامنه مالی ندارد. هر تلاش دسترسی، تست ناموفق و Stop Event است.
- **TB-7 Runtime ← Observability/Evidence:** Telemetry یک Sink داده مستقل با Allowlist فیلد و Redaction است؛ دسترسی شواهد محدود و Retention آن مشخص باشد.

### ۴.۳ ناورداهای Persistence برای اثبات

فرض کنیم E یک Source Event پذیرفته‌شده، I رکورد InboxReceipt و J رکورد الزامی WorkItem آن باشد.

- **INV-01 جفت اتمیک:** جفت الزامی InboxReceipt + WorkItem با هم Commit می‌شود یا هیچ‌کدام وجود ندارند؛ پیش از Commit هیچ ACK پذیرشی صادر نمی‌شود. DeliveryOutbox مشروط، رکورد جداگانه انتشار پایین‌دستی است و هرگز جای WorkItem را نمی‌گیرد.
- **INV-02 هویت منبع یکتا:** Uniqueness در DB هویت Source Event را بر اساس Tuple مصوب Tenant/Product/Installation/Source/ID اعمال می‌کند. Pre-check برنامه به‌تنهایی کافی نیست.
- **INV-03 Replay پایدار:** هویت یکسان با Fingerprint پذیرفته‌شده یکسان به Receipt اصلی ارجاع می‌دهد؛ Job دوم نمی‌سازد.
- **INV-04 Conflict یکپارچگی:** هویت یکسان با Fingerprint متفاوت نمی‌تواند Event اصلی را بازنویسی یا Work جدید Enqueue کند؛ نتیجه Conflict محدود و قابل Audit تولید می‌شود.
- **INV-05 مالکیت Claim:** فقط Worker دارای Claim معتبر و جاری می‌تواند Job را جلو ببرد؛ Claim منقضی/قدیمی نمی‌تواند Claim جدید یا State نهایی را بازنویسی کند.
- **INV-06 ایمنی Retry:** Retry و اعلان تکراری Queue ممکن است Delivery/Claim را تکرار کنند، اما Receipt/Job پایدار منبع را تکثیر نمی‌کنند.
- **INV-07 عدم دسترسی مالی:** Principalهای Ingress/Worker در این اثبات Permission یا Connection به Store/Service مالی ندارند.
- **INV-08 بسته بودن Tenant:** تمام Queryهای خواندن/نوشتن و Transitionهای Job با Tenant/Installation مورداعتماد Scope می‌شوند؛ Tenant ارسالی Caller هیچ‌گاه اختیار را گسترش نمی‌دهد.

Schema دقیق، Isolation Level، Statement قفل/Claim، Unique Index، State Machine Retry و Response Codeها همچنان تصمیم ADR فناوری/دامنه هستند.

## ۵. کاتالوگ پذیرش خصمانه

**قاعده اجرا:** این موارد مشخصات تست‌اند، نه تست‌های انجام‌شده. فقط Fixture ساختگی استفاده شود. برای هر Case، نتیجه HTTP/دامنه، State ذخیره‌شده، Audit Event، تلاش شبکه، تلاش دسترسی مالی و Evidence ثبت شود. هر افشای Cross-tenant، نوشتن غیرمجاز، اثر پایدار تکراری، دسترسی مالی یا Fetch بیرونی Schema یک Stop بحرانی است.

| شناسه Case | ورودی/Interleaving خصمانه | ناوردا / نتیجه مورد انتظار |
|---|---|---|
| A4-IAM-01 | Credential وجود ندارد؛ Credential خراب؛ Scheme پشتیبانی‌نشده | پیش از ایجاد Principal رد شود؛ هیچ Inbox/Job نوشته نشود |
| A4-IAM-02 | Credential هنگام Ingress منقضی است | رد؛ پذیرش پایدار Event انجام نشود |
| A4-IAM-03 | Credential با State قدیمی Cache/Verifier باطل شده است | رفتار ابطال با SLA سازگاری مصوب منطبق باشد؛ پس از مرز زمانی ابطال، پذیرش نشود |
| A4-IAM-04 | Signature صحیح ولی Issuer یا Audience اشتباه | رد؛ به پروفایل اعتماد دیگری Fallback نشود |
| A4-IAM-05 | Credential معتبر Installation A برای Installation B ارائه شود | رد؛ اختیار بین Installationها منتقل نشود |
| A4-IAM-06 | هم‌پوشانی Rotation، کلید قدیمی پس از Retirement و Key ID ناشناخته | فقط Window صریح Rotation پذیرفته شود؛ کلید ناشناخته/بازنشسته رد و Secret از Log حذف شود |
| A4-AUTH-01 | Principal مربوط به Tenant A شناسه Tenant را در Path/Query/Header/Body به B تغییر دهد | Tenant سمت سرور ثابت بماند؛ داده و حتی وجود B افشا نشود |
| A4-AUTH-02 | Tenant A شناسه Event/Installation/Object مربوط به B را ارجاع دهد | رد Object-level؛ بدون Read/Write یا Oracle وجود |
| A4-AUTH-03 | Tenant Admin عملیات مختص Platform را فراخوانی کند | رد Function-level؛ بدون اثر ممتاز |
| A4-AUTH-04 | Operation مجاز تلاش کند فیلد محافظت‌شده (tenantId، status، commission، role، createdAt) را با Mass Assignment تغییر دهد | فیلد محافظت‌شده رد/نادیده گرفته شود؛ Mutation غیرمجاز رخ ندهد |
| A4-AUTH-05 | Response شامل فیلد داخلی، Credential، Payload خام یا Metadata مستأجر دیگر باشد | Allowlist فیلد پاسخ؛ فیلد حساس/Cross-tenant غایب باشد |
| A4-AUTH-06 | Membership یا Installation بین پذیرش و اجرای Worker تعلیق شود | Worker State جاری لازم را دوباره بررسی کند؛ Policy مصوب مانع پردازش غیرمجاز شود |
| A4-AUTH-07 | تلاش Confused Deputy با پیام Worker دارای Tenant/Install جعلی | Worker از رکورد پایدار مورداعتماد اختیار را استخراج و Binding را بررسی کند؛ فیلد پیام به‌تنهایی اختیار نمی‌دهد |
| A4-IDEM-01 | همان Event با Payload معنایی یکسان به‌صورت ترتیبی ارسال شود | یک Inbox Identity و یک WorkItem پایدار؛ Replay به نتیجه اصلی ارجاع دهد |
| A4-IDEM-02 | N تحویل هم‌زمان یکسان با Connection مستقل | دقیقاً یک جفت InboxReceipt/WorkItem پایدار؛ سایر درخواست‌ها به Duplicate همگرا شوند |
| A4-IDEM-03 | Source Identity یکسان، Payload/Fingerprint تغییرکرده | Conflict؛ رکورد اصلی تغییر نکند؛ Job دوم ساخته نشود |
| A4-IDEM-04 | Event ID یکسان با Source، Installation یا Tenant متفاوت | Namespace هویت فقط طبق قرارداد متمایز بماند؛ برخورد سراسری ناخواسته یا Dedup بین Tenant رخ ندهد |
| A4-IDEM-05 | ترتیب بایت/Whitespace خام JSON متفاوت ولی JSON معنایی پذیرفته‌شده یکسان | نتیجه مطابق پروفایل Fingerprint صریحاً منتخب؛ Raw Digest از Canonical Digest قابل تفکیک باشد |
| A4-IDEM-06 | Member تکراری JSON، UTF-8 نامعتبر، عدد خارج از I-JSON یا مرز عددی خارج پروفایل | پیش از Canonicalization رد شود؛ Parser داده را با Lossy Normalization تغییر ندهد |
| A4-IDEM-07 | گونه‌های Unicode Normalization، رشته Escapeشده/نشده معادل و Edge Caseهای Surrogate | رفتار مطابق استاندارد Canonicalization Pinشده؛ بدون Unicode Normalization مستندسازی‌نشده |
| A4-IDEM-08 | Client Retry Key متفاوت برای Source Identity یکسان؛ یا Retry Key یکسان برای Event متفاوت | Source Identity مرجع Dedup رویداد بماند؛ Request Key نتواند Uniqueness را دور بزند یا دو Event متفاوت را ادغام کند |
| A4-PARSE-01 | CloudEvents Source/Type/Extension/Schema Version ناشناخته | Fail closed؛ بدون Lookup خارجی و Work پایدار پذیرفته‌شده |
| A4-PARSE-02 | Payload یک URL از نوع http(s)، file، loopback، link-local، private، redirect یا DNS rebinding ارائه کند | هیچ Resolver/Network فراخوانی نشود؛ طبق قرارداد URL رد یا به‌عنوان Metadata غیرقابل‌اجرا تلقی شود |
| A4-PARSE-03 | Nesting عمیق، Body بزرگ، Array/String عظیم یا عدد Pathological | رد محدود پیش از CPU/Memory/Storage نامحدود؛ پذیرش پایدار ناقص ایجاد نشود |
| A4-PARSE-04 | Content-Type ناسازگار، گسترش بیش‌ازحد Body فشرده یا Encoding پشتیبانی‌نشده | طبق Policy صریح رد یا Decode محدود شود؛ Limit پس از Decompression نیز اعمال شود |
| A4-PARSE-05 | Extension ناشناخته، نام Extension تکراری یا تعارض Identity در Envelope/Payload | ابهام رد شود؛ فیلد Canonical Envelope با Payload بازنویسی نشود |
| A4-PARSE-06 | Artifact مربوط به Schema پس از پذیرش Event تغییر کند | Event قبلی Provenance نسخه/Schema تغییرناپذیر داشته باشد؛ Replay از Resolution خارجی/Mutable استفاده نکند |
| A4-RES-01 | اندازه درخواست دقیقاً برابر Limit مصوب و یک واحد بیشتر | مرز به‌صورت قطعی پذیرفته/رد شود؛ مقدار Limit نباید حدس زده شود |
| A4-RES-02 | Burst مربوط به یک Installation/Tenant با Tenant دیگر رقابت کند | Fairness/Backpressure مطابق Quota مصوب؛ یک Tenant ظرفیت رزروشده سراسری را مصرف نکند |
| A4-RES-03 | درخواست هم‌زمان DB Pool/Worker Slot را Exhaust کند | Queue/Reject محدود؛ بدون Connection Leak، Retry Storm نامحدود یا Starvation Tenant |
| A4-RES-04 | Authentication یا Parser Failure نامعتبر تکرار شود | کنترل Abuse/Rate محدود؛ جزئیات حساس افشا نشود؛ Alert عملیاتی قابل انتساب باشد |
| A4-RES-05 | Retry-after/Backoff و Poison Event هنگام Failure تکراری | Retry محدود؛ Jitter/Parking فقط در صورت تصویب؛ Poison Event پردازش Tenantهای دیگر را مسدود نکند |
| A4-DUR-01 | Crash پیش از شروع Transaction، پس از Insert Inbox، پس از Insert Job و بلافاصله پیش از Commit | Transaction Commitنشده هیچ‌کدام را باقی نگذارد؛ ACK موفقیت صادر نشود |
| A4-DUR-02 | Commit موفق شود ولی Response/ACK گم شود | Retry به همان Receipt/Job برسد؛ جفت تکراری ایجاد نشود |
| A4-DUR-03 | Deadlock/Serialization Failure یا Race روی Unique Constraint | Retry فقط در مرز امن Transaction؛ یک برنده؛ بدون Write ناقص |
| A4-DUR-04 | Worker پیش از Claim، پس از Claim، هنگام Processing و پیش از Commit تکمیل Crash کند | State پایدار Recovery ایمن را ممکن کند؛ Terminal Status کاذب ایجاد نشود |
| A4-DUR-05 | Lease منقضی شود و Worker قدیمی پس از Claim شدن توسط Worker جدید برگردد | Fencing/Claim Token نوشتن قدیمی را رد کند؛ State جدید بازنویسی نشود |
| A4-DUR-06 | اعلان Queue تکراری/خارج از ترتیب و Delivery مجدد | Queue فقط Hint باشد؛ DB State Claim را کنترل کند؛ Transition پایدار تکراری رخ ندهد |
| A4-DUR-07 | Job داخلی خراب یا Installation ارجاع‌شده حذف/ناسازگار باشد | Quarantine/Fail closed؛ بدون اثر Tenant/مالی؛ Alert فقط Correlation ID داشته باشد |
| A4-DUR-08 | Restart/Restore DB و Worker پس از حالت‌های Commitشده و Commitنشده | State بازیابی‌شده با مرز Commit منطبق؛ Work Commitنشده غایب و Work Commitشده یک‌بار قابل بازیابی باشد |
| A4-DATA-01 | Canary ساختگی Secret/PII در Payload و سپس Success/Error/Exception | Canary در Log/Trace/Metric Label/Client Error ظاهر نشود؛ Payload خام به Evidence کپی نشود |
| A4-DATA-02 | تلاش Cross-tenant موجب Error و Audit شود | Response وجود Object را لو ندهد؛ Security Audit زمینه کافی Actor/Tenant/Correlation را بدون Secret Payload حفظ کند |
| A4-DATA-03 | Principal غیرمجاز بخواهد Evidence و Audit را بخواند/Export کند | رد و Audit شود؛ دسترسی حداقلی؛ Retention Artifact محدود |
| A4-DATA-04 | سناریوی انقضای Retention/حذف/Restore Backup | فقط پس از تصویب Policy؛ حذف و رفتار Backup شواهد قابل‌راستی‌آزمایی داشته باشد؛ مدت فرضی تعیین نشود |
| A4-FIN-01 | Event پذیرفته‌شده مسیر Ingress و Worker را طی کند | هیچ اتصال، Query، Command، Service Call یا Permission به DB مالی وجود نداشته باشد |
| A4-FIN-02 | Variantهای Duplicate، Conflict، Retry، Exception و Replay | در همه مسیرها صفر Write به Wallet/Ledger/Payment/Settlement/Payout و صفر Economic Effect |
| A4-FIN-03 | فیلدهای کمیسیون/مبلغ/ارز/ذی‌نفع جعلی در Event ساختگی | این فیلدها اختیار یا دستور Posting تلقی نشوند؛ هیچ محاسبه یا Mutation مالی انجام نشود |

**تعداد:** ۴۷ سناریوی خصمانه. شماره Caseها پایدار است؛ Case جدید اضافه کنید و ارجاع شواهد قبلی را با شماره‌گذاری مجدد نشکنید. یک تست می‌تواند چند Case را پوشش دهد، مشروط به اینکه گزارش هر Case را جداگانه مشخص کند.

## ۶. Oracleهای تست و الزامات شواهد

هر Case باید شش Oracle مستقل داشته باشد:

۱. **Protocol Oracle:** کلاس Status/Error و پاسخ قابل مشاهده بیرونی؛ صرفاً به متن Error وابسته نباشد.
۲. **Authorization Oracle:** Principal، Tenant/Installation مورداعتماد، تصمیم Capability و تصمیم Object/Property.
۳. **Persistence Oracle:** وضعیت Rowها قبل/بعد و Assertion یکتایی با Read مستقل DB؛ نتیجه Transaction و مرز Commit.
۴. **Worker Oracle:** Claim Token/Lease، Transition وضعیت، Retry Count، Terminal/Quarantine و رد نوشتن Worker قدیمی.
۵. **Boundary Oracle:** تلاش DNS/Egress، DB Grant، فراخوانی سرویس مالی و Integration خروجی.
۶. **Privacy/Audit Oracle:** نبود Canary در Log/Trace/Error؛ وجود Audit مورد انتظار و انتساب Actor/Correlation.

بسته شواهد هر اجرا:
- Repository، Branch، SHA دقیق Commit آزموده‌شده و وضعیت Clean/Dirty؛
- نسخه Harness، نسخه کاتالوگ سناریو، Fixture Seed و Case IDها؛
- شناسه محیط دورریختنی، Policy ایزولاسیون و نتیجه Teardown؛
- نسخه DB/Queue/Runtime و تنظیمات Isolation/Constraint مرتبط؛
- Command، زمان شروع/پایان، نتیجه کامل، تعدادها، Caseهای Skip/Blocked و Exit Code؛
- Trace پاک‌سازی‌شده، Assertionهای Transaction/DB، Snapshot مجوز DB و Telemetry Egress؛
- Telemetry اتصال/نوشتن مالی و گزارش اسکن Canary؛
- Checksum Artifact، بازبین، تاریخ بازبینی و دامنه دقیق Evidence.

Secret، داده واقعی شریک/مشتری/بازیکن، Payload حساس خام یا شناسه Production هرگز ثبت نشود. PASS فقط برای Case، محیط و SHA دقیق خود معتبر است.

## ۷. ترتیب اجرا و قواعد توقف

| ترتیب | بسته کاری | پیش‌نیاز | شاهد خروج |
|---|---|---|---|
| ۰ | بازبینی و تصویب دامنه G09-A3/A4، مالک‌ها و Threat Model | تأیید مالک/امنیت/عملیات | Decision Record امضاشده و دامنه محدود |
| ۱ | ساخت پوسته Harness دورریختنی و اثبات ایزولاسیون | A4-GATE-01، A4-GATE-05، A4-GATE-07 | گزارش P0؛ صفر دسترسی خارجی/مالی |
| ۲ | ساخت Fixture و تست مرز هویت/Tenant | A4-GATE-02 | Caseهای P1 و تأیید بازبین |
| ۳ | افزودن تست Parser/Registry سخت‌گیرانه و منع Egress | پروفایل مصوب Registry/Schema | Caseهای P2؛ صفر تلاش DNS/HTTP |
| ۴ | افزودن تست Transaction/Uniqueness و Concurrency با DB واقعی | A4-GATE-03 | Traceهای Transaction و شواهد Race در P3/P4 |
| ۵ | افزودن تست Lease/Fencing/Crash Recovery برای Worker | A4-GATE-04 | شواهد Recovery در P4 |
| ۶ | افزودن تست منابع/حریم خصوصی | A4-GATE-05/06 | گزارش P5 با پروفایل بار مصوب |
| ۷ | اثبات مستقل عدم اثر مالی | A4-GATE-07 | Permission، Network و شواهد صفر Write در P6 |
| ۸ | بازبینی خصمانه مستقل و Closeout | تمام مراحل قبلی | تعیین تکلیف تک‌تک Caseها، ریسک باقی‌مانده و تصمیم صریح مالک |

**شرایط توقف فوری:** هر Read/Write یا افشای وجود Cross-tenant؛ دورزدن Authentication؛ Override Tenant غیرقابل‌اعتماد؛ Job/Receipt پایدار تکراری؛ ACK پیش از Commit؛ بازنویسی توسط Worker قدیمی؛ Fetch شبکه/Schema خارجی؛ مصرف نامحدود منابع؛ نشت Canary حساس؛ دسترسی یا Mutation DB/Service مالی؛ داده/اعتبارنامه غیرساختگی؛ یا شکست ایزولاسیون محیط.

هنگام توقف: اجرا متوقف شود، شواهد پاک‌سازی‌شده حفظ شوند، Retry خودکار سناریوی ناامن ادامه پیدا نکند، محیط دورریختنی ایزوله شود، بازبینان تعیین‌شده مطلع شوند و Finding قابل‌ردیابی ثبت شود. بدون حفظ شواهد Failure اولیه، صرفاً «اصلاح و اجرای مجدد» نکنید.

## ۸. شدت و تعیین تکلیف

| شدت | نمونه‌ها | تعیین تکلیف لازم |
|---|---|---|
| Critical / Stop | دسترسی Cross-tenant، دورزدن Auth، دسترسی/Mutation مالی، اثر اقتصادی تکراری، Egress خارجی، نشت Secret/PII یا رفتار مخرب و نامحدود منابع | توقف اثبات؛ بازبینی امنیت/مالک؛ تحلیل علت ریشه‌ای و شواهد اصلاح پیش از اجرای مجدد |
| High | دسترسی غیرمجاز Function/Property، ابهام Fingerprint، Work پایدار تکراری، بازنویسی Worker قدیمی یا نبود Audit تغییر ممتاز | Gate مربوطه مسدود؛ اصلاح و اجرای مجدد تست‌های مرتبط و Regression |
| Medium | زمینه ناقص Audit، انتساب ضعیف Alert یا شکاف Recovery بدون فساد داده/مالی | مالک ریسک و مهلت اصلاح ثبت شود؛ ناوردای بحرانی قابل Waive نیست |
| Low / Informational | اعلان غیرمسدودکننده ابزار یا ابهام نگارشی مستندات | جداگانه پیگیری شود؛ بدون شواهد به Finding امنیتی تبدیل نشود |

شدت یافته صرفاً به دلیل Synthetic بودن محیط کاهش نمی‌یابد. تست ساختگی میزان مواجهه را کم می‌کند، نه اهمیت نقص طراحی اثبات‌شده را.

## ۹. خروجی‌های لازم پیش از پیاده‌سازی Runtime

G09-A4 زمانی آماده بازبینی مالک است که:
- هر ۴۷ Case مالک، پیش‌شرط، نتیجه مورد انتظار و Oracle شواهد صریح داشته باشد؛
- محیط تست، کاندید DB/Queue و مکانیزم ایزولاسیون از طریق ADR مصوب انتخاب شوند؛
- هر هشت Gate A4 صریحاً Accepted یا با مالک پاسخ‌گو Blocked باشند؛
- هیچ تستی به داده واقعی شریک، Credential تولیدی یا دسترسی مالی نیاز نداشته باشد؛
- هم‌ارزی دوزبانه و CI مستندات روی Head دقیق PR موفق شوند؛
- Security/QA/Architecture، Threat Model مربوط به Harness و استقلال Oracleها را بازبینی کنند.

پذیرش G09-A4 **مجوز Integration شریک یا Runtime تولیدی نیست**. پیاده‌سازی Runtime نیازمند تصمیم و دامنه جداگانه مورد تأیید مالک، مستندات/مجوز واقعی شریک برای هر Adapter و Gateهای مستقل انتشار در مراحل بعدی است.

## ۱۰. پرسش‌های باز

۱. مالک‌ها و بازبینان پاسخ‌گوی مشخص برای هشت Gate مربوط به A4 چه کسانی هستند؟
۲. کدام کاندید Persistence و Queue طبق LOT-TECH-ADR-001 / LOT-PROT-001 مجاز به ارزیابی است؟
۳. کدام پروفایل Identity صرفاً تستی را می‌توان بدون القای تصویب IAM تولیدی استفاده کرد؟
۴. کدام Registry Fixture و Policy سازگاری Schema برای پروفایل Event ساختگی استفاده شود؟
۵. کدام Workload Profile و سقف عددی تصویب می‌شود و مرجع تصویب کیست؟
۶. چه Policy دسترسی/Retention برای Artifactهای تست ساختگی اعمال می‌شود؟
۷. کدام بازبینان مالی/امنیت عدم دسترسی به دامنه مالی را تأیید می‌کنند؟

تا زمان حل این موارد، اجرای وابسته BLOCKED می‌ماند. ساخت Adapter شریک، Credential واقعی، درخواست Sandbox خارجی، محاسبه کمیسیون، ثبت مالی، Merge یا Deploy مجاز نیست.

## ۱۱. استانداردها و منابع مرجع

- OWASP API Security Top 10 (2023)، به‌ویژه API1 BOLA، API2 Broken Authentication، API3 مجوز Property، API4 مصرف منابع، API5 مجوز Function، API7 SSRF، API9 Inventory و API10 مصرف ناامن API: https://owasp.org/API-Security/editions/2023/en/0x11-t10/
- پروژه OWASP API Security: https://owasp.org/www-project-api-security/
- RFC 8785، طرح Canonicalization برای JSON (JCS): https://www.rfc-editor.org/rfc/rfc8785.html — صرفاً پروفایل کاندید؛ انتخاب پیاده‌سازی مصوب نیست. RFC 8785 از نوع Informational است و ورودی را به I-JSON محدود می‌کند؛ هویت Event یا معنای Idempotency برنامه را تعریف نمی‌کند.
- مشخصات CloudEvents: https://github.com/cloudevents/spec — از نسخه دقیق Pinشده در LOT-EVENT-001 استفاده شود؛ از مشخصات عمومی، رفتار شریک استنباط نشود.
- مستندات Transaction Isolation در PostgreSQL، فقط در صورتی که بعداً PostgreSQL به‌عنوان کاندید اثبات انتخاب شود: https://www.postgresql.org/docs/current/transaction-iso.html — منبع مرجع است، نه انتخاب DB.
