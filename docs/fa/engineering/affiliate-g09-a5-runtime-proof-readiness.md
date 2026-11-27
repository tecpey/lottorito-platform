# G09-A5 افیلیت — آمادگی اثبات Runtime و نقشه اجرایی پیاده‌سازی

**شناسه سند:** LOT-AFFILIATE-G09-A5-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیشنهادی؛ صرفاً نقشه اجرایی؛ بدون تصویب فناوری، Runtime یا امنیت | **تاریخ:** ۲۰۲۶-۱۱-۲۷
**وابستگی‌ها:** LOT-AFFILIATE-G09-A4-001، LOT-AFFILIATE-SEC-ACC-001، LOT-AFFILIATE-WIRE-001، LOT-EVENT-001، LOT-IAM-TENANT-001، LOT-FIN-POST-001، LOT-QA-001، LOT-TECH-ADR-001.

## ۱. هدف و مرز اختیار

A5، تعداد ۴۷ سناریوی خصمانه پایدار در A4 را به مشخصات اثباتی قابل‌بازبینی و آماده‌سازی برای پیاده‌سازی تبدیل می‌کند. این سند مدل منطقی Persistence، مرزهای اتمیک، پروتکل هم‌زمانی و Worker، معماری Fixture هویت، نقاط تزریق خطا، قرارداد تست اجرایی و الزامات شواهد را تعریف می‌کند.

A5 هیچ‌یک از PostgreSQL، Redis، Broker، فروشنده IAM، Framework، Hosting، Migration، پروتکل شریک، قاعده کمیسیون یا توپولوژی Production را انتخاب نمی‌کند. این سند مجوز پیاده‌سازی یا اجرای Runtime نیست. هشت Gate سند A4 همچنان لازم‌الاجرا هستند. تنها هدف اثبات آتی، محیطی ساختگی، دورریختنی، ایزوله و به‌طور قابل‌اثبات جدا از سامانه مالی و Endpointهای شریک خواهد بود.

ادعای هدف عمداً محدود است: Ingress ساختگیِ احراز هویت‌شده یا بدون پذیرش پایدار رد می‌شود، یا دقیقاً یک Receipt مقید به Tenant و یک Work Record پایدار را اتمیک ثبت می‌کند؛ تحویل تکراری/Retry/هم‌زمانی به نتیجه قطعی همگرا می‌شوند؛ Worker قدیمی قادر به بازنویسی مالکیت یا وضعیت جدید نیست؛ و تمام مسیرها فاقد هرگونه اثر اقتصادی یا مالی‌اند.

## ۲. واژگان الزام‌آور و تصمیم‌های باز

«باید» بیانگر ناوردای اثبات است، نه انتخاب فناوری. «کاندید» به‌معنی تصویب نیست. موارد زیر تا تصویب ADR/مالک باز می‌مانند: DB فیزیکی و سطح Isolation؛ Queue/Broker و معنای Notification؛ Issuer/Profile و SLA ابطال Credential؛ فضای نام هویت Event؛ پروفایل Canonicalization و بردارهای چندزبانه؛ سیاست Retry/Backoff/Parking؛ Quota؛ Retention/Deletion؛ ابزار Observability؛ سقف دقیق منابع.

SQL نمونه یا نمودار وضعیت را بدون ADR فناوری و Threat Model بازبینی‌شده به طراحی Production تبدیل نکنید.

## ۳. مدل منطقی Persistence مستقل از فناوری

حداقل مدل پایدار، رکوردهای منطقی زیر را دارد. نرمال‌سازی فیزیکی، نوع داده، Partitioning و Indexها به تصمیم بعدی موکول می‌شوند.

| رکورد | ویژگی‌های منطقی لازم | ناوردا |
|---|---|---|
| Installation | هویت Tenant، هویت Installation، اتصال محصول/محیط، وضعیت، مرجع/نسخه Credential، نسخه Policy | Tenant/محصول/محیط از Registry مورد اعتماد سمت سرور می‌آید، نه Payload. |
| InboxReceipt | شناسه تغییرناپذیر Receipt؛ اتصال Tenant و Installation؛ Tuple هویت Event؛ نوع/نسخه Event؛ زمان دریافت؛ Digest بدنه خام؛ مرجع Schema/Version پذیرفته‌شده؛ Fingerprint فقط در صورت تصویب؛ نتیجه | هر هویت Event منبع، در فضای نام تعریف‌شده قرارداد، حداکثر یک Receipt پذیرفته‌شده دارد. |
| WorkItem | شناسه تغییرناپذیر کار؛ Receipt ID؛ اتصال Tenant/Installation؛ وضعیت؛ شمارنده تلاش؛ زمان مجاز بعدی؛ نسل/Token Claim؛ اطلاعات Lease؛ زمان ایجاد/به‌روزرسانی | Work در همان Transaction مربوط به Receipt ساخته می‌شود و منبع حقیقت پایدار است. |
| DeliveryOutbox (مشروط) | شناسه Outbox؛ مرجع Work/Event؛ کلاس مقصد؛ وضعیت ارسال؛ اطلاعات تلاش؛ زمان تلاش بعدی | فقط در صورت نیاز به Notification خارجیِ جداگانه و پس از تصویب ایجاد می‌شود؛ منبع حقیقت دوم برای Work داخلی نیست. |
| AuditRecord | کلاس Actor/Principal؛ Tenant/Installation؛ Action/Result؛ شناسه‌های Correlation؛ زمان؛ نسخه Policy؛ Reason Code امن | افزایشی/الحاقی، با حداقل دسترسی و بدون Payload/Secret. |
| EvidenceManifest | Run ID؛ Commit مخزن؛ نسخه Harness/Catalogue؛ Case ID؛ Seed Fixture؛ هویت محیط؛ Digest Artifact؛ وضعیت بازبینی | شامل ارجاع و Hash است، نه Secret خام یا نسخه نامحدود Payload. |

**شفاف‌سازی اصطلاحات (پیشنهادی؛ در انتظار تصویب مالک):** جفت اتمیک الزامی پذیرش دقیقاً InboxReceipt + WorkItem است. DeliveryOutbox رکوردی جدا و مشروط، صرفاً برای انتشار پایین‌دستی است؛ WorkItem نیست، برای پذیرش پایدار داخلی به‌صورت پیش‌فرض لازم نیست و نمی‌تواند جای WorkItem را بگیرد یا آن را اختیاری کند. Metadata اضافی Audit/Publication فقط زمانی وارد همان Transaction پذیرش می‌شود که ناوردای جداگانه و مصوب آن را صریحاً لازم بداند. این شفاف‌سازی Schema فیزیکی یا فناوری انتخاب نمی‌کند.

### ۳.۱ هویت و یکتایی

A4 الزام می‌کند هویت Event منبع، کلید Idempotency درخواست و هویت اثر اقتصادی از هم مستقل بمانند. پیش از پیاده‌سازی باید Tuple یکتای Ingress تصویب شود. Tuple کاندید:

`(tenant_id, installation_id, source, event_id)`

این قانون عمومی یا نهایی نیست: LOT-EVENT-001 و قرارداد شریک باید تعیین کنند Source و Installation در فضای نام حضور دارند یا نه، Tenant به‌صورت ضمنی مقید است یا نه، و تغییر هویت در زمان Rotation چگونه مدیریت می‌شود. قاعده یکتایی صرفاً بر مبنای event_id در کل سامانه ممنوع است، مگر آنکه قرارداد و شواهد صریحاً آن را توجیه کنند.

DB باید یکتایی را در مرز پایدار اعمال کند. الگوی Application-level «ابتدا بررسی، سپس Insert» در هم‌زمانی کافی نیست. هنگام Conflict، هویت تغییرناپذیر و Fingerprint مصوب مقایسه می‌شوند: Duplicate معنایی دقیق، نتیجه Receipt قبلی را بازمی‌گرداند؛ همان هویت با محتوای تغییرکرده Conflict است و نباید Receipt اصلی را تغییر دهد یا Work دیگری بسازد.

### ۳.۲ مرز اتمیک پذیرش

تنها مرز موفقیت، یک Commit شامل موارد زیر است:
۱. InboxReceipt تغییرناپذیر؛
۲. دقیقاً یک WorkItem متناظر؛
۳. Metadata اضافی فقط در صورتی که ناوردای جداگانه و مصوب، ثبت آن را در همین Transaction صریحاً لازم بداند؛ DeliveryOutbox مشروط به‌صورت پیش‌فرض جزو جفت الزامی نیست.

پاسخ موفقیت (برای مثال HTTP 202، اگر در قرارداد Wire حفظ شود) فقط پس از معلوم‌شدن موفقیت Commit صادر می‌شود. شکست پیش از Commit یعنی هیچ جفت Receipt/Work پذیرفته‌شده‌ای وجود ندارد و پاسخ موفقیت صادر نمی‌شود. اگر Commit موفق شود اما پاسخ گم شود، Retry باید همان جفت ثبت‌شده را پیدا کند. انتشار Broker نباید شرط تکمیل Transaction پذیرش باشد.

### ۳.۳ ماشین حالت

وضعیت‌های WorkItem منطقی‌اند و هنوز Enum نهایی نیستند:

- `READY` ← `CLAIMED` → `SUCCEEDED`
- `CLAIMED` → `RETRY_WAIT` → `READY`
- `CLAIMED` → `PARKED` فقط تحت Policy مصوب خطای Poison.
- وضعیت نهایی با Worker قدیمی باز نمی‌شود. پردازش مجدد، در صورت تصویب آتی، به اقدام اپراتوری صریح و Auditشده و Generation جدید نیاز دارد.

هر Transition باید به وضعیت فعلی و Generation فعلی Claim مشروط باشد. پیام Queue صرفاً اعلان بیدارباش است؛ Worker باید وضعیت پایدار را بخواند و Claim کند. Visibility/Acknowledgement صف، اثبات تکمیل نیست.

## ۴. پروتکل هم‌زمانی، Lease و Fencing

### ۴.۱ پروتکل Claim

Worker فقط زمانی می‌تواند Work واجد شرایط READY/RETRY_WAIT را Claim کند که زمان not-before رسیده باشد. دریافت Claim باید یک عملیات اتمیک Compare-and-Set/Locking باشد که:
- وضعیت و شرایط فعلی را بررسی کند؛
- Generation یکنواخت Claim را افزایش دهد (Fencing Number) یا Token غیرقابل‌حدس و مقید به Generation بسازد؛
- Owner و زمان انقضای Lease را ثبت کند؛
- وضعیت را به CLAIMED تغییر دهد؛
- Generation/Token معتبر را برگرداند.

Lease به‌تنهایی کافی نیست: Worker متوقف‌شده ممکن است پس از انقضا دوباره فعال شود. هر Heartbeat، Completion، Retry و Error Transition باید به Generation/Token دقیق و وضعیت مورد انتظار مشروط باشد. Generation قدیمی باید صفر ردیف را تغییر دهد و نتیجه امن stale-claim ثبت کند؛ نباید بتواند وضعیت کسب‌وکار یا Audit را به‌عنوان Owner معتبر تغییر دهد.

### ۴.۲ انقضای Lease و بازیابی

انقضای Lease فقط Work را واجد Claim جدید می‌کند؛ اثبات نمی‌کند Worker قبلی متوقف شده است. Claim جدید Generation را افزایش می‌دهد. Worker قدیمی حتی با Resume شدن Process باید Fenced شود. منبع زمان، تحمل Clock Skew و مدت Lease نیازمند Policy عملیاتی مصوب‌اند؛ در این سند مقدار عددی تعیین نمی‌شود.

### ۴.۳ معنای Retry

Retry فقط برای خطاهای موقتِ طبقه‌بندی‌شده مجاز است و فقط وقتی تلاش قبلی قطعاً Rollback شده یا Transition Retry را امن ثبت کرده باشد. برای نتیجه نامعلوم Commit، Retry کور ممنوع است؛ ابتدا وضعیت پایدار بر اساس Receipt/Work Identity تطبیق داده شود. Backoff، Jitter، حداکثر تلاش و Parking تصمیم مالک/SRE است. Poison Work نباید Tenantهای دیگر را متوقف یا ظرفیت سراسری Worker را اشغال کند.

### ۴.۴ Isolation و اتصال Tenant

تمام Read/Writeهای پایدار باید به Context استخراج‌شده سمت سرور برای Tenant و Installation محدود شوند. اختیار Worker از رابطه Receipt/Installation پایدار دوباره استخراج می‌شود؛ فیلدهای Payload پیام نمی‌توانند اختیار Tenant ایجاد کنند. شناسه‌های Cross-tenant نباید Oracle وجود/عدم وجود بسازند. DB Role و Network Policy مربوط به Worker باید دسترسی به Wallet، Ledger، Payment، Settlement و Payout را ناممکن کند.

## ۵. معماری Fixture هویت و مجوزدهی

فقط هویت ساختگی استفاده می‌شود. Fixtureها قطعی و نسخه‌بندی‌شده‌اند؛ Credential عملیاتی، PII مشتری یا Secret شریک ممنوع است.

| کلاس Fixture | گونه‌های لازم | Assertion |
|---|---|---|
| Principal | غایب، خراب، منقضی، باطل‌شده، معتبر، Issuer/Audience اشتباه | احراز هویت Fail-closed؛ در رد درخواست Receipt/Work نوشته نمی‌شود. |
| Installation | فعال، معلق، Credential چرخش‌یافته، بازنشسته، ناشناخته | Credential فقط به یک Installation و Tenant مورد اعتماد متصل است. |
| Tenant | Tenant A، Tenant B، Principal پلتفرم، مدیر Tenant، Principal Worker | مجوز Function/Object/Property جداگانه اعمال می‌شود. |
| Race چرخه عمر | اعتبار هنگام Ingress و تعلیق پیش از Worker؛ Rotation کلید حین درخواست؛ Cache قدیمی | رفتار از مرز سازگاری مصوب پیروی می‌کند؛ Worker وضعیت لازم را دوباره بررسی می‌کند. |
| Worker | worker-1، worker-2، Generation قدیمی worker-1 | فقط Owner دارای Claim فعلی می‌تواند Work پایدار را تغییر دهد. |

Issuer، الگوریتم امضا، چرخه عمر کلید، شکل Token، سازگاری Revocation و سیاست ساعت تا تأیید IAM/Security باز می‌مانند. Mock نباید تنها شاهد مجوزدهی یا رفتار Persistence باشد.

## ۶. ماتریس تزریق خطا و نگاشت ۴۷ سناریوی A4

نقاط تزریق نسبت به مرزهای منطقی نام‌گذاری شده‌اند؛ Adapter آتی باید آن‌ها را به Hookهای قطعی نگاشت کند. هر تست هم نقطه تزریق و هم وضعیت پایدار مشاهده‌شده به‌طور مستقل را ثبت می‌کند.

| سناریو(های) A4 | تزریق/اقدام خصمانه | شرط پس از اجرا |
|---|---|---|
| IAM-01..06 | پیش از ایجاد Principal؛ پس از اعتبارسنجی Credential؛ هنگام بررسی Rotation/Revocation | هویت ردشده Receipt/Work نمی‌سازد؛ هویت پذیرفته‌شده به Installation مقید است؛ Secret افشا نمی‌شود. |
| AUTH-01..05 | تغییر Tenant/Object/Function/Property در Ingress و Response Projection | افشای Cross-tenant یا Mutation غیرمجاز رخ نمی‌دهد؛ فیلدهای محافظت‌شده تحت اختیار سرور می‌مانند. |
| AUTH-06 | تعلیق Membership/Installation پس از Commit Receipt و پیش از Claim | Worker از قاعده بازاعتبارسنجی مصوب پیروی می‌کند؛ پردازش غیرمجاز ندارد. |
| AUTH-07 | جعل Tenant/Installation ID در Payload صف/Job | Worker ادعای اختیار غیرقابل‌اعتماد را نادیده می‌گیرد و Binding را از رکورد پایدار استخراج می‌کند. |
| IDEM-01 | Duplicate ترتیبی پس از Commit موفق | همان نتیجه Receipt/Work؛ بدون جفت پایدار دوم. |
| IDEM-02 | همگام‌سازی N Transaction مستقل با Barrier روی یک Identity | دقیقاً یک برنده؛ بقیه به Duplicate/Conflict قطعی همگرا می‌شوند. |
| IDEM-03 | هویت یکسان با Payload تغییرکرده | رکورد اصلی تغییرناپذیر می‌ماند؛ Conflict؛ بدون Work دوم. |
| IDEM-04 | برخورد Event ID میان Source/Installation/Tenant | رفتار مطابق Namespace مصوب؛ بدون برخورد سراسری تصادفی یا ادغام Cross-tenant. |
| IDEM-05..07 | تغییر ترتیب بایت، فاصله، Member تکراری، Numeric و Unicode | پروفایل Parse/Canonicalization مصوب تعیین‌کننده است؛ بدون Normalization اتلافی یا هم‌ارزی مستندنشده. |
| IDEM-08 | تغییر Request Key با Event Identity ثابت؛ استفاده مجدد از Request Key برای Event دیگر | Request Key نمی‌تواند هویت Event منبع را دور بزند یا دو رویداد را ادغام کند. |
| PARSE-01..06 | Schema/Type ناشناخته؛ URL مخرب؛ مرز Parser؛ Compression؛ فیلد مبهم؛ تغییر Artifact Schema | رد قطعی/محدود؛ بدون Resolve شبکه‌ای؛ Receipt پذیرفته‌شده منشأ و نسخه Schema تغییرناپذیر دارد. |
| RES-01 | بدنه دقیقاً برابر سقف مصوب و یک واحد بیشتر | رفتار مرزی قطعی؛ مقدار سقف از Policy مصوب می‌آید. |
| RES-02..05 | Burst یک Tenant، اتمام Pool، درخواست نامعتبر تکراری، Retry خطای Poison | مصرف محدود، عدالت، Backpressure امن و بدون Retry Storm. |
| DUR-01 | Crash پیش از Transaction، پس از Insert Receipt، پس از Insert Work، درست پیش از Commit | Rollback هیچ‌یک را باقی نمی‌گذارد؛ پاسخ موفقیت صادر نمی‌شود. |
| DUR-02 | Commit موفق و سپس Drop پاسخ/Ack | Retry جفت Commit‌شده اصلی را پیدا می‌کند؛ بدون Duplicate. |
| DUR-03 | اجبار Unique Conflict، Deadlock یا Serialization Abort | یک برنده پایدار؛ Retry فقط در مرز امن Transaction. |
| DUR-04 | Crash پیش از Claim، پس از Claim، حین کار و پیش از Commit تکمیل | وضعیت پایدار بازیابی امن را ممکن می‌کند؛ موفقیت کاذب ندارد. |
| DUR-05 | انقضای Lease، Claim مجدد توسط worker-2، Resume شدن worker-1 | Generation قدیمی Fenced است؛ وضعیت جدید بازنویسی نمی‌شود. |
| DUR-06 | Notification تکراری/خارج از ترتیب و تحویل مجدد | DB پایدار Claim را کنترل می‌کند؛ Notification کار تکراری نمی‌سازد. |
| DUR-07 | Job داخلی خراب یا Reference نامنطبق Installation | طبق Policy رد/پارک می‌شود؛ بدون اثر Tenant یا مالی. |
| DUR-08 | Restart/Restore Persistence و Worker دورریختنی در حالت Commit/Uncommitted | مرز Commit حفظ می‌شود؛ کار Commit‌شده بازیافت‌پذیر و کار Uncommitted غایب است. |
| DATA-01..04 | Canary محرمانه در Payload؛ خواندن غیرمجاز Evidence؛ شبیه‌سازی Retention/Restore | Canary در Telemetry/Evidence نیست؛ دسترسی رد و Audit می‌شود؛ Retention فقط پس از تصویب Policy تست می‌شود. |
| FIN-01..03 | تلاش برای DB/Network/Service و جعل Amount/Currency/Beneficiary/Commission | هیچ اتصال، مجوز، فراخوانی، رکورد یا اثر مالی وجود ندارد. |

این جدول نگاشت است، نه ادعای پیاده‌سازی یا قبولی تست. شناسه‌های دقیق ۴۷گانه A4 مرجع اصلی Catalogue هستند و A5 نباید آن‌ها را شماره‌گذاری مجدد کند.

## ۷. قرارداد مشخصات تست اجرایی

هر Case اجرایی باید Data-driven باشد و شامل این موارد شود:

- `case_id`: شناسه دقیق A4؛ `case_version`؛ شدت؛ ارجاع به Requirement/Invariant.
- `preconditions`: شناسه Fixture، وضعیت Tenant/Installation، وضعیت پایدار Seedشده و نسخه Policy.
- `stimulus`: Request/Job/Action، Barrier هم‌زمانی، نقطه Fault و Seed قطعی.
- `expected_api`: کلاس Status و Response Code امن؛ بدون اتکا به متن خام و ناپایدار خطا.
- `expected_persistence`: تعداد دقیق رکوردها، فیلدهای تغییرناپذیر، Transitionها و Assertionهای عدم وجود.
- `expected_authorization`: Principal، Tenant، Installation و عملیات مجاز.
- `expected_financial_non_effect`: صفر اتصال/فراخوانی/نوشتن مالی و صفر Economic-effect row.
- `evidence`: Transaction Trace پالایش‌شده، Snapshot وضعیت، Correlation ID، Log/Metric مرتبط و Digest Artifact.
- `cleanup`: اثبات Teardown محیط دورریختنی؛ پاک‌سازی نباید شواهد شکست اصلی را حذف کند.
- `oracle`: روش مستقلی که صرفاً پاسخ خود SUT را تکرار نکند.

### ۷.۱ لایه‌های تست

۱. Unit خالص: قواعد Parser، Predicateهای Transition، بردارهای Fingerprint و Response Projection.
۲. Integration واقعی Persistence: موتور انتخاب‌شده واقعی، Constraint/Transaction/Locking واقعی و Read مستقل.
۳. تست پروتکل Worker: رفتار واقعی Claim/Fencing پایدار با تزریق خطای قطعی.
۴. تست مرز امنیتی: Principal/Tenant/Object/Function/Property با Assertionهای منفی.
۵. اثبات End-to-End ساختگی: فقط پس از تمام Gateهای A4، از Ingress تا Work پایدار و عدم دسترسی مالی.
۶. تست Contract/Schema: اعتبارسنجی OpenAPI/AsyncAPI و بردارهای Schema Pinشده؛ جایگزین اثبات Runtime نیست.

Mock می‌تواند همکاران غیرحیاتی را جدا کند، اما تنها Oracle برای Unique Constraint، Atomicity، Isolation، Crash Recovery، Worker Fencing یا عدم دسترسی مالی نیست.

## ۸. Oracleهای مستقل و شواهد

حداقل شش Oracle مستقل لازم است: (۱) پاسخ API؛ (۲) بازرسی مستقیم و Read-only Persistence؛ (۳) Trace Constraint/Transaction در DB؛ (۴) Audit نسل Claim در Worker؛ (۵) Sentinel مستقل DB/Network Permission برای اثبات عدم دسترسی مالی؛ (۶) اسکن Telemetry/Evidence پالایش‌شده برای Secret Canary.

Manifest هر Run باید Commit مخزن، نسخه Harness، نسخه Catalogue در A4، نسخه مشخصات A5، Seed Fixture، هویت محیط دورریختنی، Case IDها، Timestampها، Digest Artifactها، نسخه ابزارها و نظر بازبین را به هم متصل کند. شواهد شکست باید پیش از هر اصلاح یا Retry حفظ شوند. شواهد باید Tamper-evident، کنترل‌دسترسی‌شده و دارای Retention محدود بر اساس Policy مصوب باشند؛ Credential خام یا Payload نامحدود ذخیره نشود.

## ۹. توالی اجرا و Gateها

| مرحله | کار | شرط ورود | شاهد خروج |
|---|---|---|---|
| A5-0 | بازبینی/تصویب مدل منطقی، Tuple هویت و State Machine | بازبینی A4-GATE-01/08؛ بدون فرض انتخاب فیزیکی | تصمیم‌های ثبت‌شده و فهرست موارد باز |
| A5-1 | انتخاب کاندید Persistence دورریختنی | A4-GATE-03؛ ADR فناوری | مستندات یکتایی، Isolation، Rollback و Crash |
| A5-2 | انتخاب مدل Worker/Queue Notification | A4-GATE-04 | تصمیم Durable Claim، Lease، Fencing و Recovery |
| A5-3 | تصویب Fixture هویت و Policy | A4-GATE-02 | Issuer/Profile صرفاً تستی و مرز Revocation |
| A5-4 | تصویب Policy داده، شواهد و بار | A4-GATE-05/06 | فهرست فیلد، Redaction، Retention و سقف منابع |
| A5-5 | اثبات عدم دسترسی مالی | A4-GATE-07 | DB Grants، شواهد Network Deny و Sentinel مستقل |
| A5-6 | پیاده‌سازی و اجرای اثبات ساختگی | تصویب تمام هشت Gate A4 | نتایج بازتولیدپذیر ۴۷ Case با Oracle مستقل |
| A5-7 | بازبینی یافته‌ها و تصمیم Gate بعدی | تکمیل A5-6 | یافته‌های امضاشده؛ بدون ارتقای خودکار به Production |

A5-0 تا A5-5 فعالیت طراحی/حاکمیت‌اند. A5-6 تا زمان تصویب صریح تمام Gateهای لازم مسدود است. قبولی A5-6 فقط محدوده ایزوله و ساختگی را اثبات می‌کند، نه سازگاری شریک، صحت تجاری، امنیت Production یا آمادگی قانونی.

## ۱۰. شرایط توقف

در صورت هرگونه خروج شبکه‌ای خارجی، دسترسی به سامانه مالی، مشاهده Credential/PII واقعی، افشای Cross-tenant، بازنویسی توسط Worker قدیمی، ایجاد Work پایدار تکراری، Partial Commit توضیح‌نداده‌شده، رشد نامحدود Retry/مصرف منابع، Secret در Telemetry، نقص یکپارچگی Evidence یا عدم تطابق Catalogue با Caseهای اجراشده، فوراً متوقف شوید. شواهد پالایش‌شده را حفظ، محیط را ایزوله و فقط طبق رویه مصوب Teardown کنید و Finding ثبت کنید. شواهد شکست اولیه را هرگز پنهان، بازنویسی یا حذف نکنید.

## ۱۱. منابع طراحی

- راهنمای AWS درباره Transactional Outbox: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html — مرز اتمیک Dual-write، تحویل تکراری و ترتیب؛ نه انتخاب Broker.
- مستند PostgreSQL درباره INSERT / ON CONFLICT: https://www.postgresql.org/docs/current/sql-insert.html — مرجع مشروط برای مدیریت Unique Conflict در صورت انتخاب PostgreSQL.
- قفل‌گذاری صریح PostgreSQL: https://www.postgresql.org/docs/current/explicit-locking.html — مرجع مشروط Row Lock.
- Transaction Isolation در PostgreSQL: https://www.postgresql.org/docs/current/transaction-iso.html — مرجع مشروط ناهنجاری‌های هم‌زمانی و Retry.
- OWASP ASVS 5.0: https://asvs.owasp.org/ — کاتالوگ الزامات راستی‌آزمایی؛ سطح و انطباق باید توسط Security تعیین شود.
- OWASP Authorization Regression Testing: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Regression_Testing_Cheat_Sheet.html — رویکرد Regression پیوسته مجوزدهی.
- Martin Fowler، Practical Test Pyramid: https://martinfowler.com/articles/practical-test-pyramid.html — توازن تست Unit/Integration/Contract/System.

این منابع در طراحی راهنما هستند و هیچ فناوری، کنترل، فروشنده یا پیاده‌سازی را تصویب نمی‌کنند.
