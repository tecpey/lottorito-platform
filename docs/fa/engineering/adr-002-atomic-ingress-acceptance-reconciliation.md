# ADR-002 — پذیرش اتمیک Ingress در Affiliate و تطبیق نتیجه نامعلوم Commit

**شناسه سند:** LOT-AFFILIATE-G09-ADR-002  
**شناسه تصمیم:** LOT-AFFILIATE-G09-ADR-002  
**اسناد مرتبط:** LOT-AFFILIATE-SEC-ACC-001؛ G09-A4؛ G09-A5؛ G09-A7؛ G09-A8  
**وضعیت:** پیشنهادی — نیازمند تصمیم مالک و بازبینی واقعاً مستقل  
**نسخه:** ۰.۱.۰ | **تاریخ:** ۲۰۲۶-۱۱-۲۸  
**دامنه:** فقط پذیرش Ingress مصنوعی Affiliate؛ بدون احراز کمیسیون، ثبت مالی، اثر جانبی خارجی، اتصال شریک یا مجوز Production.

## ۱. تصمیم پیشنهادی

قرارداد منطقی پذیرش زیر پیشنهاد می‌شود؛ مشروط به تصمیم‌های باز بخش ۱۲:

۱. پذیرش موفق Ingress برای هویت Event منبع مصوب، دقیقاً شامل یک جفت پایدار **InboxReceipt + WorkItem** است.  
۲. هر دو رکورد باید در یک تراکنش اتمیک Persistence Commit شوند؛ یا هر دو پایدار می‌شوند یا هیچ‌کدام.  
۳. سرویس فقط پس از داشتن شاهد معتبر Commit موفق می‌تواند پاسخ موفق پذیرش (برای مثال HTTP 202) بدهد.  
۴. اگر Caller نتواند تشخیص دهد Commit موفق شده یا خیر، وضعیت **UNKNOWN** است، نه FAILED. نباید جفت دوم بسازد یا اثر کسب‌وکاری را کورکورانه تکرار کند.  
۵. تطبیق باید با مرجع Persistence معتبر و به‌اندازه کافی سازگار و با هویت مصوب Event منبع انجام شود. Replica قدیمی، Cache، Queue، Log یا Timeout کلاینت اثبات نبود رکورد نیست.  
۶. DeliveryOutbox در صورت نیاز آتی به انتشار پایین‌دستی، رکوردی جدا و مشروط است؛ WorkItem نیست و جایگزین جفت الزامی نمی‌شود.

این ADR مستقل از فناوری است. هیچ Database، Isolation Level، Queue، محصول CDC، Schema، Vendor، تعداد Retry، Timeout یا توپولوژی انتخاب نمی‌کند.

## ۲. مدل شکست و طبقه‌بندی نتیجه

کلاینت Event احراز‌شده و متصل به Tenant ارسال می‌کند. Ingress آن را اعتبارسنجی کرده، Receipt و WorkItem را در تراکنش می‌نویسد و Commit می‌کند. قطع شبکه ممکن است پیش، حین یا پس از پاسخ Commit رخ دهد؛ Process ممکن است پس از Commit و پیش از پاسخ HTTP متوقف شود؛ Retry نیز ممکن است هم‌زمان یا پس از Failover برسد.

دریافت‌نشدن پاسخ مشخص نمی‌کند تراکنش پایدار Commit شده است یا خیر. Replay کورکورانه می‌تواند کار تکراری و در طراحی ناایمن آتی اثر اقتصادی تکراری ایجاد کند.

وضعیت‌ها باید تفکیک شوند:
- **KNOWN_COMMITTED:** موفقیت Commit به‌طور معتبر مشاهده شده است.
- **KNOWN_ABORTED:** شاهد معتبر نشان می‌دهد تراکنش Commit نشده است.
- **UNKNOWN:** Caller نمی‌تواند Commit یا Abort را با اطمینان اثبات کند.
- **CONFLICT:** هویت موجود است، اما Binding/Fingerprint تغییرناپذیر متفاوت است.
- **UNAVAILABLE:** تطبیق با مرجع معتبر فعلاً ممکن نیست.

UNKNOWN یک وضعیت مستقل پروتکل است، نه مترادف شکست موقت.

## ۳. هویت و اتصال معتبر Tenant

Tuple پیشنهادی یکتایی Event منبع:

    (trusted_tenant_id, trusted_installation_id, approved_source_namespace, source_event_id)

این Tuple تا تعیین تکلیف LOT-EVENT-001 و قرارداد واقعی شریک صرفاً کاندید است. Tenant و Installation از پیکربندی سمت سرور Installation احراز‌شده و Context مجوزدهی استخراج می‌شوند؛ Payload مرجع اختیار نیست.

سه فضای هویتی جدا باقی می‌مانند:
- هویت Event منبع؛
- HTTP Request Idempotency-Key با Scope و Retention مستقل؛
- هویت آتی اثر اقتصادی متعلق به فرمان جداگانه و مجازشده کمیسیون/مالی.

هیچ‌کدام جای دیگری استفاده نشود. یکتایی جهانی event_id فرض نشود. تکرار Source Identity با Binding تغییرناپذیر یکسان می‌تواند Duplicate باشد؛ همان هویت با Tenant، Installation، Source، Event Type، Schema Version یا Fingerprint متفاوت، Conflict/سیگنال امنیتی است، نه Update.

## ۴. ناورداهای پذیرش اتمیک

یک تراکنش منطقی باید:
- Binding معتبر Tenant و Installation را تعیین و اعتبارسنجی کند؛
- یکتایی هویت Event منبع مصوب را اعمال کند؛
- یک InboxReceipt تغییرناپذیر ثبت کند؛
- دقیقاً یک WorkItem مرتبط با آن Receipt در State اولیه مجاز ثبت کند؛
- فقط رکوردهای دیگری را وارد کند که Invariant مستقل و مصوبشان همان مرز اتمیک را الزام می‌کند؛
- یک‌بار Commit شود.

**A.** پس از هر نقطه Crash/Recovery، Receipt پذیرفته‌شده بدون WorkItem الزامی یا WorkItem بدون Receipt نباید وجود داشته باشد.  
**B.** پاسخ موفق پذیرش باید پس از Commit تأییدشده صادر شود.  
**C.** هیچ Queue Publish، HTTP خارجی، فرمان مالی یا Callback شریک داخل تراکنش پذیرش انجام نشود.  
**D.** یکتایی با Constraint سطح Persistence یا Primitive اتمیک/Serializable معادل اعمال شود. Read-then-insert صرفاً در Application در حضور هم‌زمانی کافی نیست.

جفت ناقص نقض Invariant است، نه وضعیت عادی Retry. پذیرش در Scope مربوط متوقف، شواهد حفظ، Pickup توسط Worker و اثرات پایین‌دستی مسدود، اپراتور مسئول مطلع و Repair فقط از مسیر کنترل‌شده و Auditدار انجام شود. در Retry عادی نیمه مفقود را بی‌صدا نسازید.

## ۵. نتایج Commit و رفتار Caller

| وضعیت مشاهده‌شده | طبقه‌بندی | رفتار الزامی |
|---|---|---|
| پاسخ Commit دریافت شده | Known committed | Reference پایدار؛ بدون درج تکراری |
| Abort صریح با Semantics معتبر | Known aborted | طبقه‌بندی علت؛ Retry فقط در صورت مجازبودن |
| قطع اتصال/Timeout حین Commit | Unknown | بدون ادعای موفقیت/شکست؛ تطبیق |
| Crash پس از Commit و پیش از پاسخ HTTP | برای Caller نامعلوم | Retry با همان هویت؛ یافتن جفت موجود |
| Primary قطع و Read معتبر ممکن نیست | Unavailable/Unknown | Fail closed؛ بدون جفت جدید یا ادعای موفقیت |
| هویت و Binding تغییرناپذیر یکسان موجود است | Already accepted | پاسخ Idempotent با Reference موجود |
| هویت موجود ولی Binding/Fingerprint متفاوت | Conflict | رد؛ شاهد امنیتی Sanitized؛ بدون Overwrite |
| Replica قدیمی رکوردی نشان نمی‌دهد | بدون نتیجه | نبود رکورد استنباط نشود |
| Read معتبر رکوردی نشان نمی‌دهد | فقط کاندید نبود | ورود مجدد به همان عملیات اتمیک با یکتایی |

Status Code و Envelope دقیق HTTP تابع قرارداد API مصوب است. این ADR کد خاصی برای UNKNOWN تحمیل نمی‌کند. اگر نمایش ابهام ایمن ممکن نیست، پاسخ Non-success همراه دستور Retry با همان Identity/Key بدهید؛ Identity جدید صادر نکنید.

## ۶. الگوریتم تطبیق (منطقی)

۱. Source Identity، Request Idempotency Key، Binding معتبر Tenant/Installation و نسخه Fingerprint مصوب در تمام Retryها حفظ شود.  
۲. به‌دلیل گم‌شدن پاسخ، Event Identity جدید تولید نشود.  
۳. مرجع Persistence معتبر با Tuple یکتای کامل مصوب Query شود. Replica قدیمی، Cache یا Projection با Replication ناهمگام برای اثبات نبود کافی نیست.  
۴. اگر دقیقاً یک Receipt و دقیقاً یک WorkItem مرتبط وجود دارد، Bindingهای Tenant/Installation/Source/Event/Fingerprint/Schema و ارتباطشان بررسی شود. در صورت صحت، Already accepted و Reference پایدار موجود برگردانده شود.  
۵. اگر در Read معتبر هیچ‌کدام وجود نداشت، همان عملیات پذیرش اتمیک دوباره آغاز شود. Constraint/Serialization رقابت Attemptهای هم‌زمان را حل کند؛ Conflict هم‌زمان دوباره خوانده و طبقه‌بندی شود.  
۶. وجود فقط یک نیمه، چند WorkItem برای یک Receipt، Link شکسته یا فیلدهای تغییرناپذیر ناسازگار، Invariant breach/Conflict است؛ Scope قرنطینه و Retry خودکار متوقف شود.  
۷. اگر Read معتبر یا وضعیت Commit در دسترس نیست، UNKNOWN/UNAVAILABLE حفظ و تطبیق فقط طبق Policy آتی Backoff/Jitter/Resource مصوب تکرار شود. برای ایجاد قطعیت از Replica قدیمی استفاده نشود.  
۸. تصمیم تطبیق Sanitized و Append-only شامل Correlation ID، مرجع/منبع Read، کلاس Consistency، تعداد رکورد، تصمیم و Evidence Reference ثبت شود. Credential، Payload خام یا PII غیرضروری Log نشود.

Candidate Persistence باید تضمین‌های Read معتبر و یکتایی را در Failover، Restore و Replication مستند کند. در صورت عدم امکان اثبات، Candidate تا بازطراحی قرارداد پذیرفتنی نیست.

## ۷. هم‌زمانی، یکتایی و Semantics تراکنش

- Persistence باید یکتایی Tuple مصوب Event منبع را اعمال کند.
- درخواست‌های هم‌زمان و یکسان به یک جفت همگرا شوند. تراکنش بازنده نتیجه پایدار برنده را بازیابی و Bindingهای تغییرناپذیر را مقایسه کند.
- Unique Conflict به‌تنهایی Duplicate معتبر نیست؛ هویت کامل و Fingerprint Profile مصوب مقایسه شود.
- Isolation باید Write Skew یا Race منجر به چند WorkItem برای یک Receipt یا جفت ناقص را جلوگیری کند.
- ارزیابی Candidate باید Serialization Point، رفتار Unique Constraint/Index، مشاهده Conflict، Semantics Abort قابل Retry، تضمین Read-your-writes/Linearizability، Failover و Durability را مستند کند. هیچ Isolation Level انتخاب نشده است.
- Syntax مشابه INSERT ... ON CONFLICT به‌تنهایی اثبات صحت نیست؛ صحت به Unique Key، مرز تراکنش، Semantics ردیف مشاهده‌شده، Isolation، Updateهای هم‌زمان و Recovery وابسته است.
- Unknown Commit نباید به Replay کورکورانه تبدیل شود. Retry ایمن همان Identity را با همان Invariant یکتایی Persistence استفاده می‌کند.
- تراکنش کوتاه و فاقد External I/O باشد. اجرای WorkItem فقط پس از Commit پایدار پذیرش شروع شود.

## ۸. مرز DeliveryOutbox

InboxReceipt + WorkItem جفت الزامی پذیرش است. DeliveryOutbox اختیاری است و فقط اگر طراحی مصوب آتی به انتشار پایدار Wake-up/Event به Subsystem دیگر نیاز داشته باشد، اضافه می‌شود.

در صورت افزودن، Outbox باید Owner، Event Contract، Idempotency Identity، نیاز ترتیب، Retention و Policy تطبیق مشخص داشته باشد. رابطه اتمیک آن با جفت باید جداگانه تعیین شود. فقط اگر Invariant مصوب قصد انتشار را جدایی‌ناپذیر از پذیرش بداند، می‌توان آن را در همان تراکنش نوشت. تحویل Queue At-least-once است مگر قرارداد واقعی Provider خلاف آن را ثابت کند؛ Consumerها باید Idempotent باشند. انتشار Outbox به‌معنای Completion WorkItem یا مجوز پردازش مالی نیست.

## ۹. ماتریس Crash Point و تست خصمانه

تمام موارد **NOT RUN** هستند؛ معیار پذیرش آتی‌اند، نه اثبات.

| مورد | نقطه تزریق/رقابت | نتیجه الزامی |
|---|---|---|
| C01 | Crash پیش از هر Insert | بدون جفت و پاسخ موفق |
| C02 | پس از Receipt و پیش از WorkItem، پیش از Commit | Rollback؛ هیچ‌کدام پایدار نمانند |
| C03 | پس از WorkItem و پیش از Commit | Rollback؛ هیچ‌کدام پایدار نمانند |
| C04 | Commit موفق و پاسخ گم‌شده | Retry یک جفت بیابد؛ جفت دوم ساخته نشود |
| C05 | ارسال Commit و قطع اتصال پیش از تعیین نتیجه | UNKNOWN؛ فقط تطبیق معتبر |
| C06 | Abort صریح | بدون جفت؛ Retry فقط اگر مجاز باشد |
| C07 | دو Ingress یکسان هم‌زمان | دقیقاً یک جفت؛ بازنده همان پذیرش را بیابد |
| C08 | هویت یکسان با Fingerprint/Binding متفاوت | Conflict؛ بدون Overwrite یا جفت دوم |
| C09 | Primary قطع و Replica قدیمی بدون رکورد | نبود استنباط نشود؛ حل‌نشده بماند |
| C10 | بازیابی Primary و یافتن جفت در Read معتبر | پس از بررسی Binding، پذیرش موجود برگردد |
| C11 | بازیابی Primary و اثبات نبود جفت در Read معتبر | همان عملیات اتمیک با Constraint یکتا |
| C12 | جفت ناقص در تست Disposable | Invariant breach؛ قرنطینه؛ بدون Repair/Pickup خودکار |
| C13 | تحویل تکراری پس از Restart | همان جفت/Reference پایدار |
| C14 | Outbox Publish موفق و Acknowledgement گم‌شده | انتشار تکراری تحمل شود؛ Consumer Idempotent |
| C15 | شکست Outbox Publish پس از Commit پذیرش | پذیرش پایدار؛ Retry انتشار جدا |
| C16 | تغییر Lifecycle Tenant/Installation حین Ingress | تابع Linearization مصوب؛ بدون پذیرش بین Tenantها |
| C17 | Restore/Failover با نمای قدیمی/واگرا | تا Attestation مرجع Recovery/Consistency، Fail closed |

هر Case اجرایی باید Fixture Version، Schedule قطعی، Assertionهای API، Persistence مستقیم، مجوز Tenant، Sentinel عدم اثر مالی، Oracle مستقل، Provenance شواهد و Cleanup را نیز مشخص کند. نتایج Parentهای A4 و Subcaseهای A8 جدا گزارش شوند.

## ۱۰. Oracleهای مستقل و شواهد

برای اجرای آتی لازم است:
۱. مشاهده API/Client (نه Oracle مربوط به Commit).  
۲. بررسی Read-only از Persistence معتبر با Consistency Mode و هویت Endpoint مستند.  
۳. Constraint/Index و Trace تراکنش برای اثبات Arbitration یکتا و جفت اتمیک.  
۴. Query مستقل Cardinality/Linkage برای اثبات دقیقاً یک Receipt و یک WorkItem.  
۵. شاهد Fault Injection Controller برای اثبات نقطه تزریق.  
۶. Sentinel عدم دسترسی مالی به Wallet/Ledger/Payment/Settlement/Payout.  
۷. Audit/Evidence Manifest پاک‌سازی‌شده با Correlation، Timestamp معتبر، Source/Head/Build Identity و Integrity Hash.

Log تولیدشده توسط سامانه تحت تست Oracle مستقل نیست. پاسخ موفق API به‌تنهایی State پایدار را ثابت نمی‌کند. Read از Replica بدون تضمین Consistency نبود رکورد را ثابت نمی‌کند. شواهد باید Design Review، CI مستندات، Isolated Runtime Proof، Partner Sandbox Proof و Production Attestation را تفکیک کنند.

## ۱۱. گزینه‌های بررسی‌شده

- Retry کور پس از Timeout — رد؛ امکان تکرار کار/اثر اقتصادی.
- Idempotency Key جدید در هر Retry — رد؛ از بین رفتن هویت پایدار Retry.
- Read-before-write بدون یکتایی Persistence — رد؛ Race درخواست‌های هم‌زمان.
- Queue به‌عنوان Source of Truth — رد؛ Delivery/Acknowledgement پذیرش پایدار را ثابت نمی‌کند.
- پذیرش فقط با Receipt و ساخت بعدی WorkItem — رد؛ نقض جفت اتمیک.
- پذیرش فقط با Outbox — رد؛ DeliveryOutbox معادل WorkItem نیست.
- بررسی نبود رکورد در Replica قدیمی — رد؛ Replication ناهمگام می‌تواند State Commit‌شده را پنهان کند.
- ادعای Exactly-once در کل زنجیره — بدون قرارداد دقیق End-to-end رد؛ به‌جای آن پذیرش پایدار Idempotent و Consumerهای Idempotent لازم‌اند.

## ۱۲. تصمیم‌های باز مالک و ارزیابی Candidate

هیچ‌یک از موارد زیر بی‌صدا انتخاب نمی‌شود:
- Tuple یکتایی Event منبع و مرجع اختیار Source Namespace (هماهنگ با LOT-EVENT-001 و قرارداد شریک)؛
- Scope و Retention مربوط به Request Idempotency-Key و Policy پاسخ Replay؛
- مدل Consistency Persistence و تعریف Read معتبر پس از Commit، Failover و Restore؛
- Isolation/Locking/Unique Constraint قابل قبول؛
- Durability Acknowledgement و RPO/RTO مربوط به Replication/Failover؛
- طبقه‌بندی Conflict و مرجع قرنطینه/Repair؛
- Linearization مربوط به ابطال Lifecycle در Tenant/Installation؛
- Retry محدود، Backoff، Queueing و Resource Quota تطبیق؛
- نیاز DeliveryOutbox و Owner/مرز اتمیک آن؛
- Retention شواهد، حریم خصوصی، حذف، Backup و Legal Hold.

انتخاب Candidate به مستندات Vendor و Proof روی موتور واقعی و Disposable نیاز دارد. ادعای مستنداتی به‌تنهایی کافی نیست. PostgreSQL، Spanner، CockroachDB، Queue یا سرویس Cloud انتخاب نشده است.

## ۱۳. معیارهای تصویب آتی

ADR-002 فقط زمانی از PROPOSED خارج شود که:
۱. مالک پاسخ‌گو همه تصمیم‌های بخش ۱۲ را تصویب کند یا Deferral صریح با Safe Default ثبت کند.  
۲. بازبین واقعاً مستقل دامنه هویت، قرارداد تراکنش، پروتکل Unknown Commit و ماتریس شکست را به چالش بکشد.  
۳. Candidate Persistence منتخب، Atomic Pair Commit/Rollback، یکتایی هم‌زمان و تطبیق معتبر را تحت مدل Failover مستند اثبات کند.  
۴. تست‌ها ثابت کنند Response Loss پس از Commit جفت دوم نمی‌سازد.  
۵. تست‌ها ثابت کنند Primary Unavailable و Replica قدیمی هرگز نبود رکورد را استنباط نمی‌کنند.  
۶. تست‌ها ثابت کنند جفت ناقص شناسایی و قرنطینه می‌شود، نه بی‌صدا ترمیم.  
۷. Binding Tenant/Installation مستقل راستی‌آزمایی شود.  
۸. عدم دسترسی مالی با شواهد فنی و Attestation مالی/امنیتی تأیید شود.  
۹. هم‌ارزی معنایی دوزبانه و Documentation Governance روی Commit نهایی دقیقاً موفق باشند.  
۱۰. هر هشت Gate مربوط به A4 پیش از هر اجرای Runtime در G09-A4/A5 جداگانه تصویب شوند.

## ۱۴. مرجع اختیار و وضعیت فعلی

این ADR در وضعیت **PROPOSED** است؛ تصمیم معماری مصوب، مشخصات پیاده‌سازی، مجوز Runtime، قرارداد شریک، سیاست حسابداری یا بیانیه آمادگی Production نیست. هیچ تست Runtime به‌واسطه این ADR اجرا نشده است. A7-F01 تا A7-F10 و A8-F01 تا A8-F12 باز می‌مانند، مگر آنکه جداگانه با شواهد مستقل بسته شوند. همه Gateهای A4 همچنان NOT APPROVED هستند. هیچ Database، Queue، Vendor، Schema فیزیکی، اتصال مالی، Merge یا Deploy مجاز نشده است.

## ۱۵. منابع

- PostgreSQL INSERT / ON CONFLICT (صرفاً Semantics نمونه برای ارزیابی): https://www.postgresql.org/docs/current/sql-insert.html
- PostgreSQL Transaction Isolation: https://www.postgresql.org/docs/current/transaction-iso.html
- PostgreSQL Constraints: https://www.postgresql.org/docs/current/ddl-constraints.html
- AWS Prescriptive Guidance، الگوی Transactional Outbox: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- Google Cloud Spanner، Unknown Commit Status و راهنمای Retry ایمن: https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once
- NIST SP 800-204D، امنیت زنجیره تأمین نرم‌افزار در DevSecOps CI/CD: https://csrc.nist.gov/pubs/sp/800/204/d/final

این منابع در ارزیابی کمک می‌کنند؛ نه فناوری‌ای انتخاب می‌کنند و نه رفتار Lottorito را اثبات می‌کنند.
