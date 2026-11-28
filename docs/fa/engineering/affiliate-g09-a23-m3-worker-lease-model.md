# G09-A23 M3 — مدل Lease و نسل Claim در Worker

**شناسه سند:** LOT-AFFILIATE-G09-A23-M3  
**نسخه:** ۰.۱.۹  
**وضعیت:** پیش‌نویس مدل — مدل اصلاح‌شده در انتظار اعتبارسنجی TLC روی Head دقیق؛ بازبینی مستقل و Candidate refinement انجام نشده است  
**سند مادر:** [راهبرد مدل رسمی و آزمون A23](affiliate-g09-a23-formal-protocol-model-test-strategy.md)  
**پیشنهاد هنجاری:** [ADR-001 — پروتکل Claim، Lease و Fencing برای WorkItem](adr-001-workitem-claim-lease-fencing.md)  
**ردیابی:** [ردیابی ۴۷ آزمون A7](affiliate-g09-a7-47-case-traceability.md)، A4-DUR-05، A8-DUR-05a/b/c و A11-WRK-01

## ۱. هدف و مرز

M3 یک WorkItem پایدار و دو Process مربوط به Worker را جداگانه مدل می‌کند تا مالکیت Claim، حصارگذاری Generation، تمدید Lease، Transitionهای محافظت‌شده، انتظار برای Lock و رقابت انقضا/بازیابی Claim بررسی شوند. مدل مستقل از Candidate است و هیچ Database، Queue، Clock Provider، IAM Provider، سیاست مدت Lease یا سطح Isolation را انتخاب نمی‌کند.

وضعیت پایدار WorkItem مرجع اختیار است. تحویل Queue فقط یک Wake-up Hint است و مالکیت ایجاد نمی‌کند. مدل فقط از مرز Persistence سمت مبدأ محافظت می‌کند و درخواست خارجی‌ای را که قبلاً Dispatch شده باشد لغو یا Fence نمی‌کند.

## ۲. تصمیم‌های کلیدی مدل‌سازی

۱. **هویت Process مربوط به Worker از هویت Principal احراز‌شده جداست.** هر دو Process با نام‌های W0 و W1 عمداً یک Principal انتزاعی یکسان (worker-service) دارند. این کار مانع اثبات کاذبی می‌شود که در آن Worker قدیمی فقط به‌دلیل تفاوت شناسه Process رد شده باشد. Generation و Token باید مستقلاً Process قدیمی را که با همان Service Principal بازمی‌گردد Fence کنند.

۲. **Claim Generation برای هر WorkItem تغییرناپذیر است.** هر Claim اولیه یا Reclaim موفق دقیقاً یک واحد آن را افزایش می‌دهد. Heartbeat/Renewal، پردازش، تکمیل، Retry و Park نباید Generation را افزایش دهند. دامنه ۰ تا ۲ فقط Bound اکتشاف مدل است، نه نمایش Production یا سیاست Exhaustion.

۳. **Claim Token یک نماد Opaque از دامنه نمادین متناهی و مستقل است؛ مقدار آن از Claim Generation مشتق نمی‌شود و با آن هم‌ارزی عددی ندارد.** TLC فقط Binding و Mismatch را مدل می‌کند، نه Entropy رمزنگاری، محرمانگی، انتقال Token یا سرقت Credential. Token به‌تنهایی Bearer Credential محسوب نمی‌شود.

۴. **زمان Persistence از زمان محلی Worker جداست.** هر Worker یک Clock Offset غیرقطعی در دامنه {-1، ۰، +1} نسبت به زمان Persistence دارد. این کار مشاهده ساعت کند/تند را در یک دامنه محدود بررسی می‌کند، بدون آن‌که Bound کمی برای Drift ادعا شود. درخواست همچنین Snapshot اعتبار Lease پیش از Lock را ثبت می‌کند؛ در Baseline هیچ‌یک از این مشاهدات محلی مرجع تصمیم نیستند. یک Context اسکالر برای درخواست، حداکثر یک درخواست Worker در حالت Pending برای این WorkItem را نمایش می‌دهد؛ یک Transition اتمیک جداگانه برای Competing Reclaim نشان می‌دهد Claimant دیگر چگونه می‌تواند در زمان انتظار درخواست قدیمی برنده شود. این روش Interleaving بحرانی را حفظ می‌کند، بدون آن‌که Queue نامحدود درخواست‌ها مدل شود.

۵. **نقطه Serialization و Guard دو مرحله مجزا هستند.** درخواست فقط از Claim واجد شرایط یا State از نوع claimed/processing پذیرفته می‌شود و سپس State/Generation/Token/Lifecycle مورد انتظار و مشاهده پیش از Lock را ثبت می‌کند؛ سپس منتظر می‌ماند، نقطه Serialization را می‌گیرد و Guard را در برابر وضعیت پایدار و زمان Persistence فعلی ارزیابی می‌کند. زمان می‌تواند هنگام انتظار یا حتی در زمان نگه‌داشتن نقطه Serialization جلو برود. Guard و Mutation محافظت‌شده یک گام اتمیک و نقطه Linearization هستند.

۶. **انقضای Lease به‌خودی‌خود Transition وضعیت نیست.** انقضا WorkItem با وضعیت CLAIMED را واجد شرایط Reclaim می‌کند. مدل همچنین PROCESSING را State دارای Lease در نظر می‌گیرد که پس از انقضا قابل Reclaim است. این یک Refinement آگاهانه فراتر از عبارت فعلی ADR-001 است (که READY و CLAIMED منقضی‌شده را نام می‌برد)؛ مالک و بازبینان مستقل باید این شکاف State Machine را پیش از تصویب ADR حل کنند. پیش از Commit شدن Generation جدید نیز Worker قدیمی باید در صورتی که Lease در Guard پس از Serialization منقضی شده باشد رد شود. اگر Worker قدیمی درحالی‌که Lease معتبر است و نقطه Serialization را در اختیار دارد Mutation را Linearize کند، آن Mutation قبل از Reclaim بعدی مرتب می‌شود.

۷. **یک Transition مجاز و رقیب `CLAIMED → PROCESSING`** به‌صورت Action اتمیک Serialization/Guard/Mutation، درحالی‌که درخواست قدیمی در انتظار است، مدل شده است. این Mutation در همان Oracle تجمعی History ثبت می‌شود تا Negative Control مربوط به State قدیمی با اتکا به تغییر State ثبت‌نشده به‌اشتباه موفق نشود. تغییر Lifecycle Version نیز به‌عنوان ورودی مدل می‌شود؛ اما مدل درباره Policy مالک برای Receiptهای قبلاً پذیرفته‌شده تصمیم نمی‌گیرد.

## ۳. State و Transitionهای انتزاعی

ماژول مدل: formal/G09M3WorkerLeaseGeneration.tla

| موضوع | State / Operation انتزاعی |
|---|---|
| چرخه عمر WorkItem | ready، claimed، processing، completed، failed، quarantined |
| مالکیت پایدار | claimOwner، claimGeneration، claimToken، leaseExpiry |
| نسخه Guard/Recovery | lifecycleVersion |
| زمان | persistenceTime و Clock Offset محدود Worker برای W0/W1 |
| درخواست درحال‌اجرای Worker | State/Generation/Token/Lifecycle مورد انتظار، Tenant/Installation، زمان شروع و مشاهده پیش از Lock |
| Serialization | lockOwner، زمان گرفتن Lock و External Blocker برای مدل‌سازی انتظار |
| عملیات | Claim/Reclaim، Heartbeat، Start-processing، Complete، Retry و Park |
| Oracle ممیزی | تاریخچه Mutationهای پذیرفته‌شده، رویدادهای Generation، شمارنده Mutation و Baseline Guard ناموفق |

Claim موفق در یک Action انتزاعی، Generation، Owner، Token، Expiry و وضعیت CLAIMED را با هم Commit می‌کند. داده محلی Worker فقط در همان Action Claim موفق به‌روزرسانی می‌شود. Claim ناموفق هیچ Ownership یا Tokenای صادر نمی‌کند.

Retry وضعیت WorkItem را بدون Reset کردن Generation به ready بازمی‌گرداند. Claim بعدی از آخرین Generation پایدار افزایش می‌یابد. Park آیتم را به Quarantine منتقل می‌کند؛ Worker عادی در این مدل نمی‌تواند آیتم Quarantined را Claim کند.

## ۴. قرارداد Guard

Mutation محافظت‌شده Worker فقط در نقطه Serialization/Linearization و در صورت برقرار بودن تمام شروط لازم پذیرفته می‌شود:

- Principal احراز‌شده Worker همان Owner پایدار فعلی Claim باشد؛
- State مورد انتظار WorkItem همچنان برقرار باشد؛
- Generation و Token جاری Claim با مقادیر پایدار برابر باشند؛
- Lifecycle Version با Snapshot درخواست برابر باشد؛
- Binding تغییرناپذیر Tenant و Installation معتبر باشد؛
- WorkItem همچنان در State مجاز claimed یا processing باشد؛
- زمان مرجع Persistence به‌طور سخت‌گیرانه پیش از leaseExpiry باشد.

شکست Guard باید صفر ردیف محافظت‌شده را تغییر دهد. شمارنده Mutation انتزاعی برای متناهی‌ماندن State Graph، بودجه ۱۰ Mutation موفق دارد؛ پس از مصرف آن، Actionهای Mutation بیشتر غیرفعال می‌شوند. این صرفاً Bound اکتشاف مدل است، نه محدودیت Throughput یا عملیات. بررسی Clock محلی Worker، Timestamp پیش از Lock، پیام Queue، Lease Object محلی یا Thread مربوط به Heartbeat جای Guard پس از Serialization را نمی‌گیرد.

## ۵. Invariantها و Oracleها

| Invariant | Assertion |
|---|---|
| TypeOK | تمام متغیرهای انتزاعی در دامنه‌های متناهی تعریف‌شده باقی بمانند |
| RequestLockCoherence | وضعیت Idle/Waiting/Locked درخواست، Worker درخواست‌دهنده و Lock Owner با یکدیگر سازگار بمانند |
| SingleClaimOwner | WorkItemهای فعال CLAIMED/PROCESSING، Principal جاری و Token Opaque فعال را حفظ کنند؛ Stateهای READY/COMPLETED/FAILED/QUARANTINED فاقد Owner، Token یا Lease فعال باشند |
| HeartbeatDoesNotAdvanceGeneration | Heartbeat/Renewal هرگز Claim Generation را افزایش ندهد |
| EveryAcceptedMutationWasAuthorized | هر Mutation پذیرفته‌شده با Owner، Generation، Token، Lifecycle، Expected State، Tenant، Installation، زمان پس از Lock و Lease منقضی‌نشده تطبیق داشته باشد |
| GuardFailureHasZeroMutation | Guard ناموفق شمارنده Mutation محافظت‌شده را تغییر ندهد |
| LeaseNeverRenewedAfterExpiry | پس از زمان انقضا هیچ Heartbeat پذیرفته نشود |
| GenerationHighWaterNeverRegresses | Generation جاری با High-water Mark انتزاعی پایدار برابر باشد |
| ClaimAdvancesExactlyOnce | هر رویداد Claim موفق دقیقاً یک واحد افزایش داشته باشد |
| ClaimEventWellFormed | هر رویداد Claim/Reclaim، گام معتبر Generation، Principal، تغییر Token، بازه Lease، State قبلی و Binding مربوط به Tenant/Installation را ثبت کند |
| ClaimTokenNeverReused | در مدل متناهی، Generationهای متفاوت Token صادرشده را دوباره استفاده نکنند |
| ClaimTokenIsLatest | Token پایدار فعال با Token ثبت‌شده برای آخرین Generation Claim تطبیق داشته باشد |
| NewClaimHasCurrentOwnerAndToken | WorkItem در حالت Claimed/Processing دارای Principal و Token Opaque فعال باشد |

Oracle تاریخچه، زمان شروع درخواست، زمان گرفتن Lock و زمان Persistence در لحظه Guard را ثبت می‌کند. ترتیب الزامی چنین است: شروع درخواست ≤ گرفتن Lock ≤ مشاهده Guard. تصمیم معتبر انقضای Lease در آخرین نقطه گرفته می‌شود.

## ۶. Negative Controlها

Runner در هر Config مربوط به TLC عمداً یک نقص مستقل تزریق می‌کند:

| Mutant | نقص | Oracle مورد انتظار |
|---|---|---|
| prelock_time | استفاده از مشاهده پیش از Lock پس از انتظار نامحدود | EveryAcceptedMutationWasAuthorized |
| worker_clock | استفاده از Clock کند/تند Worker به‌عنوان مرجع اختیار | EveryAcceptedMutationWasAuthorized |
| stale_generation | فقط کنترل Generation را حذف می‌کند؛ درخواست دارای Generation قدیمی و Token جاری است | EveryAcceptedMutationWasAuthorized |
| wrong_token | فقط کنترل Token را حذف می‌کند؛ درخواست دارای Generation جاری و Token Opaque نامعتبر است | EveryAcceptedMutationWasAuthorized |
| wrong_tenant | حذف Binding تغییرناپذیر Tenant | EveryAcceptedMutationWasAuthorized |
| wrong_installation | حذف Binding تغییرناپذیر Installation | EveryAcceptedMutationWasAuthorized |
| stale_lifecycle | حذف Guard مربوط به Lifecycle Version | EveryAcceptedMutationWasAuthorized |
| stale_state | حذف Guard مربوط به Expected State | EveryAcceptedMutationWasAuthorized |
| expired_heartbeat | اجازه تمدید پس از انقضا | EveryAcceptedMutationWasAuthorized |
| heartbeat_generation | افزایش Generation هنگام Heartbeat | HeartbeatDoesNotAdvanceGeneration |
| guard_mutates | Mutation وضعیت محافظت‌شده پس از شکست Guard | GuardFailureHasZeroMutation |

Runner فقط وقتی موفق است که Baseline بدون نقض Invariant کامل شود و هر Mutant Counterexample مورد انتظار و نام‌برده‌شده خود را تولید کند. Parse Failure، Timeout، محدودیت منابع، نبود Counterexample یا نقض Invariant غیرمنتظره PASS محسوب نمی‌شود؛ بسته به علت FAIL یا INCONCLUSIVE است.

## ۷. Bounds و فرض‌ها

- یک WorkItem تغییرناپذیر و دو Process مربوط به Worker با نام W0 و W1.
- هر دو Process عمداً یک Service Principal احراز‌شده مشترک دارند.
- دو Generation Claim (۰، ۱، ۲)؛ LeaseDuration = 2 و دامنه زمان Persistence از ۰ تا ۲ فقط ثابت اکتشاف متناهی است. Claim اولیه می‌تواند در زمان صفر انجام و در زمان انقضای ۲ Reclaim شود؛ انقضای بعدی Generation دوم خارج از Bound این M3 است.
- Clock Offset محلی Worker به‌صورت غیرقطعی در دامنه ۱- تا ۱+ نسبت به زمان Persistence تغییر می‌کند؛ این یک Abstraction محدود از Skew است، نه Bound کمی Drift ساعت.
- یک نقطه Serialization و یک External Blocker برای مدل‌سازی Contention/انتظار Lock.
- فقط یک Tenant و یک Installation مدل شده‌اند؛ بررسی چندمستاجری فراتر از تشخیص Binding نامنطبق در M6 است.
- Entropy Token، اصالت رمزنگاری، پیاده‌سازی IAM، Semantics مربوط به Lock/Isolation/Time در Database، Kill/STONITH، رفتار Queue، اثرات خارجی و پروتکل Restore Incarnation انتزاع یا خارج از Scope هستند.
- Restart شدن Process در این مدل متناهی Transition مستقلی ندارد؛ داده محلی قدیمی Claim به‌صورت Abstraction مربوط به Worker بازگشته حفظ می‌شود. Schedule صریح Restart/Reload همچنان در زنجیره آزمون Candidate در A7/A8 الزامی است. مدل Liveness، Throughput، مناسب‌بودن مدت Lease، Policy مربوط به Retry/Backoff یا ظرفیت Production را اثبات نمی‌کند.

## ۸. موارد خارج از Scope و وابستگی‌ها

- M2: Authority Epoch در Database و Fence در Mutation Sink.
- M4: Outbox، Consumer، Receiver و پذیرش درخواست خارجی پس از از دست رفتن Lease مبدأ.
- M5: Restore/PITR، Recovery Incarnation و چرخه Quarantine/Reopen.
- M6: چند Tenant/Principal و مرزهای مجوزدهی خصمانه.
- M7: Liveness، Fairness، ظرفیت، Backpressure و بودجه منابع.
- A4-GATE-03/04 و ADRهای Persistence/Worker: آزمون Candidate اجرایی تا زمان تصویب Gateها مسدود است. ADR-001 همچنان PROPOSED است؛ M3 آن را تصویب نمی‌کند.

## ۹. بازتولید

Runner ثابت‌شده در scripts/formal/run_g09_m3.sh و Workflow در .github/workflows/formal-g09-m3.yml قرار دارد. نسخه TLA+ Tools v1.7.4 / TLC 2.19 با SHA-256 Pin شده و Log و Metadata هر Case به‌صورت Artifact در GitHub Actions نگهداری می‌شود. Hash دقیق Model/Config، Bounds، شمار Stateها، وضعیت تکمیل، Trace و Digest Artifact فقط پس از اجرای موفق روی Head دقیق به این سند افزوده می‌شوند.

**وضعیت اعتبارسنجی:** در انتظار اجرای TLC روی Head دقیق PR. هیچ Runtime یا Candidate آزمایش یا تصویب نشده است.


## ۱۰. منابع پژوهشی

- Martin Kleppmann، [How to do distributed locking](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html) (۲۰۱۶): Process متوقف‌شده و Request با تأخیر می‌توانند پس از انقضای Lease هم فعال شوند؛ Resource محافظت‌شده باید Token قدیمی Fencing را فعالانه رد کند.
- Marc Brooker / AWS Builders' Library، [Leader election in distributed systems](https://aws.amazon.com/builders-library/leader-election-in-distributed-systems/) (۲۰۱۹): رفتار Lease/Heartbeat، توقف Process، فرض‌های مربوط به مدت زمان Clock و ریسک‌های Leader Election؛ در صورت عدم نیاز به Leader، Idempotency و Optimistic Concurrency گزینه‌های جایگزین‌اند.
- PostgreSQL، [Date/Time Functions and Operators](https://www.postgresql.org/docs/current/functions-datetime.html): Timestamp آغاز Transaction با نمونه‌برداری زمان واقعی تفاوت دارد؛ این فقط مثال معنایی است، نه انتخاب Database.
- PostgreSQL، [Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html): Serialization مبتنی بر Row Lock و رفتار انتظار Lock؛ فقط مرجع ارزیابی Candidate است.

این منابع Scheduleهای خصمانه مدل را توجیه می‌کنند؛ هیچ‌کدام پیاده‌سازی Lottorito را اثبات یا Providerی را انتخاب نمی‌کنند.


دامنه محدود Clock Offset به ۱- تا ۱+ کاهش یافت تا جست‌وجوی Explicit-state قابل‌کنترل بماند و در عین حال Counterexample مربوط به Clock کند و تند حفظ شود. این صرفاً Bound مربوط به Abstraction است؛ رفتار Clock در Production انتخاب یا اثبات نشده است.


Context درخواست Pending به‌صورت State اسکالر مدل شده، نه Mapهای جداگانه برای هر Worker. دو Process همچنان در Mapهای محلی Generation/Token/Clock از هم متمایزند؛ Abstraction تک‌درخواستی با Action صریح Competing Reclaim همراه شده تا رقابت درخواست قدیمی با Claim جدید همچنان در مدل حضور داشته باشد.


**یادداشت بازبینی نسخه ۰.۱.۶ — کامل‌بودن Oracle مربوط به Mutation:** در بازبینی مشخص شد Transition قبلی `AuthorizedStartProcessing` وضعیت WorkItem را خارج از History مربوط به Mutationهای پذیرفته‌شده تغییر می‌داد. این Transition با یک Transition رقیبِ صریحاً مجاز جایگزین شد که Generation/Token/Lifecycle/Lease مربوط به Claimant جاری را بررسی و رویداد را به همان History اضافه می‌کند. History اکنون همه رویدادهای پذیرفته‌شده را به‌صورت تجمعی نگه می‌دارد، نه فقط آخرین رویداد را. Invariant مربوط به SingleClaimOwner نیز الزام می‌کند Stateهای Ready/Terminal هیچ Owner/Token/Lease فعالی نداشته باشند؛ Completion این فیلدها را پاک می‌کند و Generation را حفظ می‌کند. اعتبارسنجی TLC روی Head دقیق در انتظار است.


**یادداشت بازبینی نسخه ۰.۱.۷ — هویت رویداد:** مجموعه تجمعی Mutationهای پذیرفته‌شده اکنون در هر Record یک Sequence متناهی و یکنواخت افزایشی دارد. این کار مانع ادغام دو رویداد پذیرفته‌شده با مقادیر دیگر یکسان (برای نمونه Heartbeat تکراری در یک زمان انتزاعی Persistence) در یک عضو Set می‌شود. این Sequence صرفاً شناسه داخل مدل متناهی و محدود به بودجه ده Mutation است و شناسه Production محسوب نمی‌شود.


**یادداشت بازبینی نسخه ۰.۱.۸ — انضباط Scope:** Transition مدیریتی `OperatorQuarantine` که خارج از History ثبت می‌شد از M3 حذف شد. مسیر Park آغازشده توسط Worker همچنان راه مدل‌شده برای رسیدن به QUARANTINED است و تحت Guard/History مربوط به Mutation محافظت‌شده قرار دارد. Policy مربوط به Quarantine مدیریتی باید در مدل مرتبط با Operator/Recovery بررسی شود و نباید بی‌صدا Oracle مربوط به Mutationهای Worker در M3 را دور بزند.


**یادداشت بازبینی خصمانه و اصلاح نسخه ۰.۱.۹ — شواهد Head دقیق**

- اجرای قبلی با Run #87 و شناسه 46179279712 روی Head مربوط به PR با SHA کامل 97ce124972c3ae5f010bda2857ed1517b9d96650، هنگام اجرای Baseline و در اثر محدودیت ۲۰ دقیقه‌ای Job با وضعیت **CANCELLED** متوقف شد. از آن Run هیچ تکمیل Baseline، تعداد State، عمق، نتیجه Mutant یا Counterexample اثبات نمی‌شود.
- فایل JAR نسخه Pin‌شده TLA+ Tools v1.7.4 / TLC 2.19 بررسی SHA-256 را با موفقیت گذراند: 936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88. مقدار SHA-256 مدل قبلی 838ac00aba8b5f299bff30b9a76bffc4dc58c993c3d5d2f685bdab49982beb6a بود.
- Run لغوشده Artifact با شناسه 15277697910، Digest برابر sha256:0b49bb2efbc9f66cad02c9ee50850d3523ad0a38cc806780a26751cd94d7c0db و حجم ۸۱۷٬۷۱۱٬۵۸۵ بایت (۱٬۷۹۵ فایل) حفظ کرد. پوشه‌های Metadata مربوط به TLC به‌دلیل قرارگرفتن در مسیر خروجی Upload در Artifact قرار گرفتند؛ این نقص بسته‌بندی شواهد است و به‌تنهایی علت زمان اجرای TLC را اثبات نمی‌کند.
- بازبینی خصمانه Source نشان داد مدل قبلی Claim Token و Generation را از نظر عددی برابر می‌گرفت و Mutant مربوط به stale-generation هر دو کنترل Generation و Token را حذف می‌کرد. اصلاح جدید Tokenها را در دامنه نمادین Opaque و مستقل قرار می‌دهد؛ Mutant مربوط به Generation فقط درخواست دارای Generation قدیمی و Token جاری را می‌سازد و Mutant مربوط به Token فقط درخواست دارای Generation جاری و Token نامعتبر را.
- تاریخچه Claim/Reclaim اکنون Generation و Token قبلی/جدید، Worker/Principal، زمان Persistence، انقضای قبلی/جدید Lease، Lifecycle Version، State قبلی، Tenant، Installation و نوع Claim/Reclaim را ثبت می‌کند. Invariantهای جدید، صحت ساختار رویداد، عدم استفاده مجدد از Token و تطبیق Token فعال با آخرین رویداد Claim را بررسی می‌کنند.
- مسیرهای Protected Transition و Competing Authorized Transition اکنون از Predicateهای Guard مشترک استفاده می‌کنند تا احتمال اختلاف معنایی بین دو مسیر مجوزدهی کاهش یابد.
- Runner، Metadata حجیم TLC را خارج از مسیر Artifact نگه می‌دارد. Timeout مربوط به Workflow به ۴۵ دقیقه افزایش یافته تا امکان تشخیص تکمیل یا عدم تکمیل مدل فراهم شود؛ این تغییر به‌معنای اثبات Tractability یا تکمیل TLC نیست.
- مدل اصلاح‌شده و هر ۱۲ Configuration مربوط به TLC در انتظار اجرای تازه روی Head دقیق هستند. تا زمان تکمیل Baseline و تولید Counterexample اختصاصی مورد انتظار برای هر Mutant، وضعیت M3 همچنان **NOT ACCEPTED** است. شروع M4، تأیید Runtime/Candidate، Assurance مستقل، Merge یا Deploy از این تغییرات نتیجه نمی‌شود.
