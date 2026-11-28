# G09-A23 — مدل رسمی پروتکل و راهبرد آزمون خصمانه

**شناسه سند:** LOT-AFFILIATE-G09-A23-001  
**نسخه:** ۰.۱.۰ | **وضعیت:** پیشنهادی، تحقیق و طراحی مدل — بدون اجرای Model Checker یا Runtime  
**تاریخ:** ۲۰۲۶-۱۱-۲۸  
**مبنای بازبینی:** G09-A21، G09-A22، G09-A20، G09-A7، ADR-001 و ADR-002  
**مرجعیت:** طراحی مشورتی؛ هیچ تصمیم مالک، Candidate، Gate یا مجوز اجرایی تصویب نمی‌شود.

## ۱. هدف و تعیین حدود

A23 مسیر اصلاحی A21 را برای F03، F04، F05، F11 و F12 تکمیل می‌کند: مدل‌سازی صریح State Machine، جداسازی Safety از Liveness، تعریف فرض‌های پیشرفت، بررسی ترکیب Faultها و تولید Scheduleهای تکرارپذیر.

این سند **قرارداد مدل و راهبرد آزمون** است؛ نه مدل TLA+ اجراشده، نه نتیجه TLC، نه تست Jepsen اجراشده و نه اثبات رفتار یک Candidate. هیچ نتیجه PASS، شمارش State، پوشش، Benchmark یا ادعای اثربخشی از آن استنباط نمی‌شود.

A23:
- ADR-002 را تصویب یا تصمیم‌های OD-01..OD-12 را حل نمی‌کند.
- دیتابیس، Queue، Cloud، Region، Vendor، Isolation Level یا Topology انتخاب نمی‌کند.
- A20-01..A20-28 را اجراشده تلقی نمی‌کند.
- A21-F01/F06/F08/F13 را نمی‌بندد؛ بسته Assurance و هم‌ارزی دوزبانه در A24 باقی می‌ماند.
- مجوز R2، اتصال Partner، داده واقعی، سامانه مالی، Production، Merge یا Deploy صادر نمی‌کند.

## ۲. ورودی‌ها و مرز مدل

ورودی‌های هنجاری عبارت‌اند از: جفت اتمیک پیشنهادی InboxReceipt + WorkItem در ADR-002؛ پروتکل Claim/Lease/Fencing در ADR-001؛ ۴۷ شناسه پایدار A4 و برنامه‌های S1..S5 در A7؛ کاتالوگ A20-01..A20-28؛ قرارداد Trace/Evidence در A22؛ و تصمیم‌های باز مالک.

### ۲.۱ اجزای داخل مدل

۱. Ingress با حداقل دو Caller/Node و درخواست‌های هم‌زمان.  
۲. هویت Source Event و Fingerprint معنایی نسخه‌دار، بدون فرض‌کردن Tuple نهایی.  
۳. Authority مرجع Persistence با Epoch/Term و امکان انتقال Authority.  
۴. Transaction پذیرش که Receipt و WorkItem را اتمیک ثبت می‌کند.  
۵. نتیجه Commit شامل ACCEPTED، REJECTED، DUPLICATE_CONFIRMED، CONFLICT، UNKNOWN و QUARANTINED.  
۶. Worker Claim با Generation و Lease و انتقال وضعیت سریال‌شده.  
۷. DeliveryOutbox اختیاری و مجزا از WorkItem؛ Broker و Consumer ناهم‌زمان.  
۸. Restore/PITR، Tombstone، Recovery Incarnation و Reconciliation.  
۹. Tenant/Installation Context مورد اعتماد و Principalهای دارای مجوز محدود.  
۱۰. Faultها: Crash، Partition، Delay، Reorder، Lost Response، Retry، Clock Skew، Failover، Restore، Key/Config/Schema Change و Resource Pressure.

### ۲.۲ موارد خارج از مدل پایه

فرمول کمیسیون، محاسبه NGR، Ledger Posting، Wallet، Payment، Payout، Prize، Player State و رفتار واقعی Partner خارج از مدل پذیرش Ingress هستند. Ingress/Worker در مدل پایه هیچ قابلیت Mutation مالی ندارد. A20-27 فقط در صورت مجوز مستقل و مدل جداگانه قابل بررسی است؛ A23 آن مجوز نیست.

## ۳. واژگان State و قرارداد انتزاعی

| متغیر | معنای مدل |
|---|---|
| tenant | Tenant مرجع که از Installation/Trust Context معتبر می‌آید |
| sourceIdentity | Tuple نسخه‌دار Event طبق ODهای مصوب؛ فعلاً نمادین |
| semanticFingerprint | Fingerprint نسخه‌دار محتوای معنایی؛ فعلاً نمادین |
| authorityEpoch | Epoch افزایشی مرجع Write/Repair |
| authorityOwner | تنها Actor مجاز به Commit در Epoch جاری |
| acceptanceTxn | وضعیت Transaction پذیرش: absent / in-flight / committed / aborted / unknown |
| receipt | رکورد Durable پذیرش |
| workItem | رکورد Durable کار پذیرفته‌شده |
| callerOutcome | آخرین نتیجه‌ای که Caller واقعاً مشاهده کرده است |
| claimGeneration | Generation افزایشی Claim برای هر WorkItem |
| leaseState | وضعیت Lease؛ زمان انقضا به‌تنهایی مجوز Mutation نیست |
| outboxState | وضعیت انتشار اختیاری پس از Commit مبدأ |
| consumerReceipt | Deduplication/Receipt مستقل Consumer |
| restoreIncarnation | شناسه یکتای چرخه Restore/Recovery |
| tombstone | نشانگر پایدار هویت مصرف‌شده/منقضی‌شده طبق سیاست مصوب |
| externalEffect | اثر مقصد خارجی؛ در مدل پایه غیرقابل‌اجرا و خارج از Transaction |
| quarantineState | وضعیت مهار و عدم Claim توسط Worker عادی |

فیلدهای Identity، Fingerprint، Retention، Epoch authority، مرجع ساعت، Cardinality فیزیکی و نتیجه‌های Wire تا تصویب ODها پارامتر باز می‌مانند؛ مدل نباید مقدار نمونه را به Policy تبدیل کند.

## ۴. Transitionهای الزامی

مدل رسمی باید حداقل Transitionهای زیر را با Preconditions، تغییر State و اثرهای مجاز/ممنوع تعریف کند:

| Transition | پیش‌شرط و اثر مورد انتظار |
|---|---|
| BeginIngress | ثبت تلاش؛ هنوز هیچ Acceptance یا Ack موفقی ایجاد نمی‌کند |
| CommitAcceptance | فقط Authority جاری؛ Receipt و WorkItem با هم یا هیچ‌کدام Commit شوند |
| LoseResponse | پاسخ Caller گم شود؛ State سرور ممکن است committed یا aborted باشد |
| ObserveUnknown | Caller بدون مدرک کافی UNKNOWN ببیند؛ UNKNOWN نباید به شکست/موفقیت فرضی تبدیل شود |
| Reconcile | Read از مرجع با Consistency کافی؛ باید با Transaction اولیه در حال اجرا Race-safe باشد |
| DuplicateIngress | Identity و Fingerprint یکسان؛ حداکثر یک جفت Durable |
| ConflictingIngress | Identity یکسان و Fingerprint متفاوت؛ Conflict/Quarantine، بدون Overwrite |
| TransferAuthority | Epoch جدید فقط با پروتکل مرجع و Fencing قابل‌اعمال فعال شود |
| RejectStaleWriter | Writer با Epoch قدیمی در نقطه Mutation رد شود |
| ClaimWork | Claim و Generation جدید در مرجع پایدار و با Transition سریال‌شده |
| ExpireAndReclaim | Lease قبلی منقضی و Claim جدید صادر شود؛ Generation قبلی باطل بماند |
| ResumeStaleWorker | Worker قدیمی تلاش کند؛ Mutation محافظت‌شده و اثر خارجی باید رد شود |
| CommitWorkTransition | فقط Owner/Generation/Authority معتبر در لحظه Mutation |
| PublishOutbox | فقط از Outbox Durable؛ تحویل ممکن است تکراری/نامرتب باشد |
| ConsumeMessage | Consumer مرجع Work را دوباره بخواند/Claim کند؛ پیام Broker به‌تنهایی Authority نیست |
| Restore | داده و Metadata بازیابی شوند؛ Authority/Identity نباید عقب‌گرد خاموش داشته باشند |
| ReconcileRestore | اختلاف داده، Epoch، Tombstone، Credential، Schema و Outbox آشکار و تعیین تکلیف شود |
| Quarantine/Repair | Actor مجاز، دامنه محدود، Audit کامل؛ Worker عادی حق Claim مورد قرنطینه را ندارد |

**قاعده خطی‌سازی:** هر Transition محافظت‌شده باید نقطه Linearization مشخص داشته باشد. بررسی Lease/Epoch پیش از انتظار برای Lock کافی نیست؛ اعتبار باید در نقطه Mutation سریال‌شده دوباره اثبات شود. A23 هیچ روش پیاده‌سازی خاصی را به‌عنوان پاسخ عمومی تحمیل نمی‌کند.

## ۵. Safety Properties — نقض‌ناپذیری

هر خاصیت باید با شناسه پایدار، State/Transition مرتبط، Oracle مستقل، Counterexample مورد انتظار و نگاشت به A20/A7 ثبت شود.

| ID | خاصیت اجباری |
|---|---|
| S-01 Atomic Pair | برای هر Identity پذیرفته‌شده، Receipt و WorkItem هر دو Durable یا هیچ‌کدام نباشند |
| S-02 Uniqueness | برای هر Tuple هویت مصوب، حداکثر یک جفت پذیرش وجود داشته باشد |
| S-03 Conflict Safety | Identity یکسان با Fingerprint متفاوت هرگز Duplicate بی‌خطر یا Overwrite نشود |
| S-04 Ack Soundness | ACCEPTED فقط پس از اثبات Commit پایدار تحت Policy مصوب صادر شود |
| S-05 Unknown Preservation | UNKNOWN تا Reconciliation معتبر، نه ACCEPTED و نه REJECTED تفسیر نشود |
| S-06 Authority Fencing | Actor با Epoch قدیمی پس از انتقال Authority نتواند State محافظت‌شده را تغییر دهد |
| S-07 Worker Fencing | Generation قدیمی نتواند State محافظت‌شده یا اثر جانبی را Commit کند |
| S-08 Restore Monotonicity | Restore/PITR نتواند Epoch، Identity مصرف‌شده یا Revocation را ناخواسته احیا/عقب ببرد |
| S-09 Tenant Isolation | هیچ Read/Write/Disclosure بین Tenantها از طریق Identity، Payload، Retry یا Repair رخ ندهد |
| S-10 Outbox Boundary | پیام Broker مرجع Acceptance نیست؛ انتشار/تحویل تکراری اثر دوم نسازد |
| S-11 External Effect Boundary | Atomicity دیتابیس به‌عنوان Exactly-once برای مقصد خارجی معرفی نشود |
| S-12 Financial Non-effect | Ingress و Worker فاقد مسیر مجاز به Mutation مالی باشند؛ Delta مالی صفر بماند |
| S-13 Evidence Integrity | هر نتیجه به History، Config، Version، Clock، Actor و Artifact دارای Hash قابل انتساب باشد |

Safety باید برای تمام Prefixهای قابل‌دسترسی برقرار باشد؛ نه فقط در پایان اجرای خوش‌شانس. هر Counterexample معتبر، FAIL است؛ فقدان Counterexample در مدل محدود، اثبات کلی سامانه واقعی نیست.

## ۶. Liveness، Fairness و Degraded Mode

Liveness فقط تحت فرض‌های صریح قابل طرح است. هیچ ادعای «همیشه پردازش می‌شود» در Partition دائمی، از دست‌رفتن Quorum، خرابی دائمی مقصد، نبود ظرفیت یا توقف Scheduler مجاز نیست.

خواص پیشرفت پیشنهادی، مشروط به فرض‌ها:

- L-01: اگر Authority معتبر و پایدار، Persistence در دسترس، منابع زیر سقف مصوب و Scheduler منصف باشد، WorkItem واجد شرایط نهایتاً Claim یا به وضعیت صریح Quarantine/Blocked برسد.
- L-02: اگر Transaction اولیه پایان قطعی پیدا کند و مرجع Reconciliation در دسترس باشد، UNKNOWN نهایتاً به نتیجه قابل‌اثبات تبدیل شود؛ در غیر این صورت UNKNOWN حفظ و Escalate شود.
- L-03: پس از بازیابی Broker/Consumer و رفع Backpressure، Outbox واجد شرایط نهایتاً دوباره تلاش شود؛ تحویل تکراری مجاز است، اثر دوم نه.
- L-04: یک Tenant پرحجم نتواند بدون حد مصوب منابع، پیشرفت همه Tenantهای دیگر را نامحدود متوقف کند.
- L-05: Quarantine/Repair مسیر انسانی/عملیاتی قابل مشاهده داشته باشد و به صف پنهان بی‌انتها تبدیل نشود.

Fairness قوی/ضعیف، Scheduler، نرخ ورود، ظرفیت، Retry Budget، Quota و Deadline باید پارامتر و تصمیم جداگانه باشند. مدل باید حالت Degraded، توقف امن، Backpressure، Retry Storm، Starvation و Recovery پس از رفع Fault را جدا بررسی کند. Safety PASS به‌معنای Liveness PASS نیست.

## ۷. معماری Model Checking و Bounds

### ۷.۱ خانواده مدل‌ها

مدل واحد و عظیم از ابتدا ساخته نشود. مدل‌ها به‌صورت مرحله‌ای و با Interface/Invariant مشترک تفکیک شوند:

1. **M0 — Atomic Acceptance:** دو Caller، یک Identity، یک Receipt و یک WorkItem؛ Crash قبل/حین/بعد Commit.
2. **M1 — UNKNOWN Arbitration:** Transaction اولیه In-flight، گم‌شدن پاسخ، Negative Read، Retry هم‌زمان و Commit/Abort دیرهنگام.
3. **M2 — Authority Epoch:** دو Writer، دو Epoch، Partition، Promotion، بازگشت Primary قدیمی و Restore Epoch.
4. **M3 — Worker Lease:** دو Worker، دو Generation، Expiry/Reclaim، توقف Lock و Resume Worker قدیمی.
5. **M4 — Outbox/Consumer:** انتشار تکراری، Delay، Reorder، Broker outage، Consumer crash و Deduplication مقصد.
6. **M5 — Restore/Lifecycle:** PITR، Tombstone، Retention، Credential/Key/Schema Rotation، Recovery Incarnation و Failback.
7. **M6 — Tenant/Principal:** حداقل دو Tenant و دو Principal با سطح دسترسی متفاوت؛ جعل Payload و Repair کم‌اختیار.
8. **M7 — Liveness/Resources:** Tenant داغ، Burst، Retry، Quota، Backpressure، Fairness و Degraded Mode.

### ۷.۲ Bounds اولیه برای مدل محدود

Bounds زیر فقط نقطه شروع Model Exploration هستند، نه ظرفیت، SLO یا Policy محصول:

- ۲ Tenant؛ ۲ Source Identity؛ ۲ Fingerprint؛
- ۲ Ingress Node/Caller؛ ۲ Authority Epoch؛
- ۲ Worker؛ ۲ Claim Generation؛
- ۱ Broker؛ ۱ Consumer؛ حداکثر ۲ پیام؛
- ۱ Restore Incarnation قدیمی و ۱ جدید؛
- ۲ تلاش Retry و تعداد محدود Crash/Partition/Delay.

حالت‌های ۰، ۱ و ۲ برای Cardinality، و ترتیب‌های متفاوت Transition باید بررسی شوند. Symmetry Reduction فقط وقتی مجاز است که هویت Actorها از نظر خاصیت مورد آزمون واقعاً متقارن باشد. Bound کوچک، رفتارهای ۳+ Actor، ظرفیت واقعی، زمان واقعی یا تمام Interleavingها را اثبات نمی‌کند.

### ۷.۳ خروجی اجباری TLC/Model Checker

برای هر Run آینده: نسخه ابزار و Runtime، Hash فایل‌های Model/Config، Constants/Bounds، Assumptions، Invariants/Temporal Properties، State/Transition count، زمان/منابع، وضعیت تکمیل/قطع، Counterexample کامل، Trace و روش بازتولید ثبت شود. State-space exhaustion فقط برای همان مدل و Bounds گزارش شود. اگر Run ناقص، محدودیت منابع یا Property بررسی‌نشده وجود داشت، نتیجه INCONCLUSIVE است.

TLC یک Explicit-state Model Checker برای زیرمجموعه‌ای از TLA+ و مدل‌های محدود است؛ بنابراین نتیجه به مدل، Bounds و Propertyهای واقعاً بررسی‌شده محدود می‌ماند. [R1]

## ۸. راهبرد آزمون پیاده‌سازی: Model → History → Fault

Model Checking جای تست Candidate واقعی را نمی‌گیرد. پس از Gate و مجوز جداگانه، زنجیره آزمون باید سه لایه داشته باشد:

### ۸.۱ لایه Model

- TLA+/TLC برای Safety و Temporal Propertyهای قابل‌مدل‌سازی؛
- State-space bounds، Assumption و Abstraction آشکار؛
- Counterexampleهای حداقلی و قابل‌تکرار؛
- مقایسه مدل Abstract با قرارداد و پیاده‌سازی واقعی.

### ۸.۲ لایه History/Concurrency

- ثبت Operationهای Invoke/Complete با شناسه Correlation، Identity، Actor، Epoch، Generation و نتیجه مشاهده‌شده؛
- History Checker مستقل برای یکتایی، ترتیب، Linearization و عدم اثر دوم؛
- Fault Injector برای Partition، Process Kill، Network Delay/Loss، Node Restart، Failover و Clock Skew؛
- Seed قطعی، Barrier و Schedule مرتب برای تکرار دقیق Race؛
- تحلیل جداگانه Safety، Liveness، Availability و Performance.

Jepsen الگوی مرجع مفیدی برای اجرای عملیات هم‌زمان، ثبت History، تزریق Fault توسط Nemesis و تحلیل History با Checker ارائه می‌کند؛ استفاده از آن به معنی انتخاب ابزار یا Candidate نیست. [R2]

### ۸.۳ لایه Simulation/Failure Injection

رویکرد Simulation قطعی FoundationDB نشان می‌دهد می‌توان اجرای شبیه‌سازی‌شده و تولیدی را با Runtime مشترک طراحی کرد و Faultهای گسترده را در محیط کنترل‌شده تکرار کرد. این یک الگوی تحقیق است، نه پیشنهاد انتخاب FoundationDB. [R3]

### ۸.۴ Retry و Transaction Callback

هر Transaction قابل Retry باید فقط عملیات داخل مرز Transaction را انجام دهد. Side Effect خارجی، ارسال Webhook، Email، Payment یا Mutation غیرتراکنشی نباید در Callbackای قرار گیرد که Engine ممکن است دوباره اجرا کند. Spanner مستند می‌کند که بدنه Transaction ممکن است چندبار اجرا شود و Side Effect بیرونی می‌تواند تکرار شود؛ PostgreSQL نیز برای Serialization Failure، Retry کل Transaction و منطق تصمیم‌گیری آن را لازم می‌داند. [R4][R5]

Retry باید Error-classified، Idempotent، محدود به Budget/Deadline و دارای Backoff/Jitter باشد؛ Retry در چند لایه نباید روی هم انباشته شود. این‌ها خواسته‌های طراحی‌اند و مقادیرشان تا تصویب Workload/Owner باز است. [R6]

## ۹. Schedule Generation و پوشش ترکیبی

هر Schedule باید Manifest تغییرناپذیر داشته باشد: Schedule ID، Seed، ترتیب Eventها، Actor، Preconditions، Fault، Trigger/Release Barrier، انتظار، Observation Point، Oracle، Expected History و Hash.

روش تولید:

1. Scheduleهای دستی A7/A20 به‌عنوان Regression Corpus حفظ شوند.
2. State Machine و Transitionها مبنای تولید Property-based باشند.
3. Pairwise و Risk-weighted t-way برای ترکیب Faultها به‌کار روند؛ ترکیب‌های Critical به‌صورت Explicit اضافه شوند.
4. Shrinking، Counterexample را به کوتاه‌ترین Schedule بازتولیدپذیر کاهش دهد.
5. هر Bug کشف‌شده به Regression دائمی با Seed/Trace ثابت تبدیل شود.
6. Mutation Testing صحت Oracle/Checker را با Mutantهای شناخته‌شده ارزیابی کند.

Mutantهای حداقلی اجباری: حذف Unique Constraint؛ Ack قبل از Commit؛ قبول Negative Read از Replica قدیمی؛ عدم بررسی Epoch در Mutation؛ قبول Worker Generation قدیمی؛ بازنشانی Epoch پس از Restore؛ Retry با Identity جدید؛ اجرای Side Effect داخل Transaction قابل Retry؛ حذف Consumer Dedup؛ و تبدیل UNKNOWN به REJECTED/ACCEPTED بدون Evidence. اگر Checker Mutant متناظر را تشخیص ندهد، آزمون حساسیت آن INCONCLUSIVE است.

تعداد Seed، تکرار، مدت Soak، پوشش ترکیبی و Thresholdها باید با Workload/Risk مصوب تعیین شوند؛ هیچ عدد نمونه‌ای Default نیست.

## ۱۰. نگاشت به A20 و A7

| حوزه مدل | A20 | A7 / A4 | خروجی مورد انتظار |
|---|---|---|---|
| Atomic Pair و Commit | 04–08 | A4-DUR-01/02؛ S2/S4 | History یکتایی و UNKNOWN |
| Authority و Failover | 01–04، 09، 16–17، 24 | A4-DUR-03/05 | اثبات Fencing و Durability |
| Worker Lease و Stale Actor | 09–10 | A4-DUR-05؛ S3 | رد Generation قدیمی |
| Outbox و Consumer | 11–12 | A4-DUR-06 و Caseهای مرتبط | Dedup، Ordering و Backpressure |
| Restore و Lifecycle | 13–18، 21–22، 26 | A4-DUR/AUTH؛ S4/S5 | عدم احیای Identity/Authority |
| Tenant و Principal | 19–20 | A4-AUTH؛ S5 | عدم عبور مرز Tenant |
| Resource و Liveness | 12، 23، 28 | A4-RESOURCE | Fairness و Degraded Mode |
| Financial Non-effect | 27 | A4-FIN | صفر بودن اثر مالی؛ بدون مجوز Posting |
| Evidence/Audit | 20، 25 | A4-EVIDENCE | بازسازی و تمامیت Evidence |

نگاشت بالا اولیه است؛ ماتریس دوطرفه کامل Requirement→Property→Schedule→Oracle→Artifact باید در A24/Manifest ماشین‌خوان تثبیت شود. Case جدید نباید شناسه پایدار A4 را تغییر دهد؛ Subcaseها شناسه مستقل داشته باشند و Parent/Child جدا گزارش شوند.

## ۱۱. نتیجه، طبقه‌بندی و معیار توقف

- **PASS:** تمام Assertionهای اجباری در Scope/Bounds/Configuration مشخص با Oracle معتبر قبول شده‌اند.
- **FAIL:** Counterexample معتبر یا نقض Assertion مشاهده شده است.
- **INCONCLUSIVE:** مدل/Run ناقص، Fault اثبات‌نشده، Oracle نامعتبر، Evidence مفقود یا Bounds ناکافی است.
- **NOT_RUN:** اجرا نشده است.
- **BLOCKED:** پیش‌نیاز، تصمیم مالک، Gate یا مجوز مفقود است.

نتیجه Model، Simulation، History، Performance و Recovery جدا ثبت شود. PASS مدل محدود، PASS Candidate یا Production نیست. هیچ Finding با تعداد تست موفق یا Benchmark جبران نمی‌شود.

## ۱۲. توالی Gateها و مجوز

| مرحله | کار | شرط ورود/خروج |
|---|---|---|
| R1 / A23 | تکمیل مدل و Test Strategy | A23 بازبینی؛ Bounds/Assumptions/Properties و Traceability روشن |
| R1 / A24 | Assurance، Oracle Trust و دوزبانگی | F01/F06/F08/F13 و بسته شواهد تعیین تکلیف شوند |
| R1 Exit | بازبینی مجدد A20–A24 | تمام P0/P1 و تصمیم‌های لازم دارای Disposition مجاز؛ هیچ Blocker پنهان |
| R2 | Harness و Candidate Proof | مجوز کتبی Scope، محیط Synthetic ایزوله، Candidate دقیق و Gateهای مرتبط |
| R3 | Production Proof/Release | مجوز مستقل و تمام Legal/Security/Finance/Operations gates؛ خارج از A23 |

## ۱۳. مبنای تحقیق

- [R1] TLA+ Wiki — TLC Explicit-State Model Checker: https://docs.tlapl.us/using:tlc:start
- [R2] Jepsen — Distributed Systems Verification with Fault Injection: https://github.com/jepsen-io/jepsen
- [R3] FoundationDB — Simulation and Testing: https://github.com/apple/foundationdb/blob/main/documentation/sphinx/source/testing.rst
- [R4] Google Cloud Spanner — Transactions overview and transaction callback retry behavior: https://docs.cloud.google.com/spanner/docs/transactions
- [R5] PostgreSQL — Transaction Isolation and Serializable failure handling: https://www.postgresql.org/docs/current/transaction-iso.html ; https://www.postgresql.org/docs/16/mvcc-serialization-failure-handling.html
- [R6] AWS Well-Architected — Control and limit retry calls: https://docs.aws.amazon.com/wellarchitected/latest/framework/rel05-bp03.html
- Lamport — Safety and Liveness: https://lamport.azurewebsites.net/tla/safety-liveness.pdf

این منابع روش و کلاس شکست را پشتیبانی می‌کنند؛ صحت Lottorito، Candidate خاص یا Deployment را اثبات نمی‌کنند.

## ۱۴. وضعیت نهایی

- A23: قرارداد مدل و راهبرد آزمون پیشنهادی؛ **NOT EXECUTED**.
- TLA+ Model/TLC: هنوز ساخته/اجرا/بررسی نشده است.
- Jepsen/History Checker/Simulation: هنوز اجرا نشده است.
- A20-01..A20-28: DESIGNED / NOT RUN.
- A21-F03/F04/F05/F11/F12: در سطح روش/مدل پاسخ طراحی دریافت می‌کنند؛ تا تکمیل Model، بازبینی و Evidence همچنان OPEN.
- A21-F01/F06/F08/F13: برای A24 باز می‌مانند.
- OD-01..OD-12، C-01..C-16، G1..G9: OPEN / NOT APPROVED.
- ADR-002: PROPOSED؛ A11-F01..F08 OPEN؛ A12 انجام‌نشده.
- R0 BLOCKED؛ R1 تحقیق؛ R2 شروع‌نشده؛ R3 غیرمجاز؛ A4 تصویب‌نشده.
- هیچ Candidate، Runtime، Harness اجرایی، Partner، عملیات مالی، Production، Merge یا Deploy مجاز نیست.

**نتیجه:** A23 مدل‌سازی و آزمون را از فهرست سناریو به روش مهندسی قابل‌ردیابی ارتقا می‌دهد؛ اما هیچ شواهدی از اجرای واقعی یا قبولی سامانه ادعا نمی‌کند.
