# G09-A23 M3 — مدل Lease و نسل Claim در Worker

**شناسه سند:** LOT-AFFILIATE-G09-A23-M3  
**نسخه:** ۰.۱.۰  
**وضعیت:** پیش‌نویس مدل — اعتبارسنجی TLC در انتظار؛ بازبینی مستقل و Candidate refinement انجام نشده است  
**سند مادر:** [راهبرد مدل رسمی و آزمون A23](affiliate-g09-a23-formal-protocol-model-test-strategy.md)  
**پیشنهاد هنجاری:** [ADR-001 — پروتکل Claim، Lease و Fencing برای WorkItem](adr-001-workitem-claim-lease-fencing.md)  
**ردیابی:** [ردیابی ۴۷ آزمون A7](affiliate-g09-a7-47-case-traceability.md)، A4-DUR-05، A8-DUR-05a/b/c و A11-WRK-01

## ۱. هدف و مرز

M3 یک WorkItem پایدار و دو Process مربوط به Worker را جداگانه مدل می‌کند تا مالکیت Claim، حصارگذاری Generation، تمدید Lease، Transitionهای محافظت‌شده، انتظار برای Lock و رقابت انقضا/بازیابی Claim بررسی شوند. مدل مستقل از Candidate است و هیچ Database، Queue، Clock Provider، IAM Provider، سیاست مدت Lease یا سطح Isolation را انتخاب نمی‌کند.

وضعیت پایدار WorkItem مرجع اختیار است. تحویل Queue فقط یک Wake-up Hint است و مالکیت ایجاد نمی‌کند. مدل فقط از مرز Persistence سمت مبدأ محافظت می‌کند و درخواست خارجی‌ای را که قبلاً Dispatch شده باشد لغو یا Fence نمی‌کند.

## ۲. تصمیم‌های کلیدی مدل‌سازی

۱. **هویت Process مربوط به Worker از هویت Principal احراز‌شده جداست.** هر دو Process با نام‌های W0 و W1 عمداً یک Principal انتزاعی یکسان (worker-service) دارند. این کار مانع اثبات کاذبی می‌شود که در آن Worker قدیمی فقط به‌دلیل تفاوت شناسه Process رد شده باشد. Generation و Token باید مستقلاً Process قدیمی را که با همان Service Principal بازمی‌گردد Fence کنند.

۲. **Claim Generation برای هر WorkItem تغییرناپذیر است.** هر Claim اولیه یا Reclaim موفق دقیقاً یک واحد آن را افزایش می‌دهد. Heartbeat/Renewal، پردازش، تکمیل، Retry و Park نباید Generation را افزایش دهند. دامنه ۰ تا ۲ فقط Bound اکتشاف مدل است، نه نمایش Production یا سیاست Exhaustion.

۳. **Claim Token یک نماد انتزاعی و Opaque وابسته به Generation است.** TLC فقط Binding و Mismatch را مدل می‌کند، نه Entropy رمزنگاری، محرمانگی، انتقال Token یا سرقت Credential. Token به‌تنهایی Bearer Credential محسوب نمی‌شود.

۴. **زمان Persistence از زمان محلی Worker جداست.** Clockهای Worker مستقل از زمان Persistence جلو می‌روند تا Scheduleهای Clock کند/تند و مشاهده کهنه بررسی شوند. در Baseline، مشاهده محلی Worker و Snapshot پیش از Lock مرجع تصمیم نیستند.

۵. **نقطه Serialization و Guard دو مرحله مجزا هستند.** درخواست، State/Generation/Token/Lifecycle مورد انتظار و مشاهده پیش از Lock را ثبت می‌کند؛ سپس منتظر می‌ماند، نقطه Serialization را می‌گیرد و Guard را در برابر وضعیت پایدار و زمان Persistence فعلی ارزیابی می‌کند. زمان می‌تواند هنگام انتظار یا حتی در زمان نگه‌داشتن نقطه Serialization جلو برود. Guard و Mutation محافظت‌شده یک گام اتمیک و نقطه Linearization هستند.

۶. **انقضای Lease به‌خودی‌خود Transition وضعیت نیست.** انقضا WorkItem با وضعیت CLAIMED را واجد شرایط Reclaim می‌کند. پیش از Commit شدن Generation جدید نیز Worker قدیمی باید در صورتی که Lease در Guard پس از Serialization منقضی شده باشد رد شود. اگر Worker قدیمی درحالی‌که Lease معتبر است و نقطه Serialization را در اختیار دارد Mutation را Linearize کند، آن Mutation قبل از Reclaim بعدی مرتب می‌شود.

۷. **یک Transition مجاز و رقیب State** برای آزمون Guard مربوط به Expected State مدل شده است. تغییر Lifecycle Version نیز به‌عنوان ورودی مدل می‌شود؛ اما مدل درباره Policy مالک برای Receiptهای قبلاً پذیرفته‌شده تصمیم نمی‌گیرد.

## ۳. State و Transitionهای انتزاعی

ماژول مدل: formal/G09M3WorkerLeaseGeneration.tla

| موضوع | State / Operation انتزاعی |
|---|---|
| چرخه عمر WorkItem | ready، claimed، processing، completed، failed، quarantined |
| مالکیت پایدار | claimOwner، claimGeneration، claimToken، leaseExpiry |
| نسخه Guard/Recovery | lifecycleVersion |
| زمان | persistenceTime و workerClock[W0/W1] مستقل |
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

شکست Guard باید صفر ردیف محافظت‌شده را تغییر دهد. بررسی Clock محلی Worker، Timestamp پیش از Lock، پیام Queue، Lease Object محلی یا Thread مربوط به Heartbeat جای Guard پس از Serialization را نمی‌گیرد.

## ۵. Invariantها و Oracleها

| Invariant | Assertion |
|---|---|
| TypeOK | تمام متغیرهای انتزاعی در دامنه‌های متناهی تعریف‌شده باقی بمانند |
| SingleClaimOwner | مالکیت و State چرخه عمر WorkItem سازگار بمانند |
| HeartbeatDoesNotAdvanceGeneration | Heartbeat/Renewal هرگز Claim Generation را افزایش ندهد |
| EveryAcceptedMutationWasAuthorized | هر Mutation پذیرفته‌شده با Owner، Generation، Token، Lifecycle، Expected State، Tenant، Installation، زمان پس از Lock و Lease منقضی‌نشده تطبیق داشته باشد |
| GuardFailureHasZeroMutation | Guard ناموفق شمارنده Mutation محافظت‌شده را تغییر ندهد |
| LeaseNeverRenewedAfterExpiry | پس از زمان انقضا هیچ Heartbeat پذیرفته نشود |
| GenerationHighWaterNeverRegresses | Generation جاری با High-water Mark انتزاعی پایدار برابر باشد |
| ClaimAdvancesExactlyOnce | هر رویداد Claim موفق دقیقاً یک واحد افزایش داشته باشد |
| NewClaimHasCurrentOwnerAndToken | WorkItem در حالت Claimed/Processing دارای Principal و Token وابسته به Generation جاری باشد |

Oracle تاریخچه، زمان شروع درخواست، زمان گرفتن Lock و زمان Persistence در لحظه Guard را ثبت می‌کند. ترتیب الزامی چنین است: شروع درخواست ≤ گرفتن Lock ≤ مشاهده Guard. تصمیم معتبر انقضای Lease در آخرین نقطه گرفته می‌شود.

## ۶. Negative Controlها

Runner در هر Config مربوط به TLC عمداً یک نقص مستقل تزریق می‌کند:

| Mutant | نقص | Oracle مورد انتظار |
|---|---|---|
| prelock_time | استفاده از مشاهده پیش از Lock پس از انتظار نامحدود | EveryAcceptedMutationWasAuthorized |
| worker_clock | استفاده از Clock کند/تند Worker به‌عنوان مرجع اختیار | EveryAcceptedMutationWasAuthorized |
| stale_generation | حذف هر دو کنترل Generation و Token | EveryAcceptedMutationWasAuthorized |
| wrong_token | پذیرش Claim Token نامنطبق | EveryAcceptedMutationWasAuthorized |
| wrong_tenant | حذف Binding تغییرناپذیر Tenant | EveryAcceptedMutationWasAuthorized |
| stale_lifecycle | حذف Guard مربوط به Lifecycle Version | EveryAcceptedMutationWasAuthorized |
| stale_state | حذف Guard مربوط به Expected State | EveryAcceptedMutationWasAuthorized |
| expired_heartbeat | اجازه تمدید پس از انقضا | EveryAcceptedMutationWasAuthorized |
| heartbeat_generation | افزایش Generation هنگام Heartbeat | HeartbeatDoesNotAdvanceGeneration |
| guard_mutates | Mutation وضعیت محافظت‌شده پس از شکست Guard | GuardFailureHasZeroMutation |

Runner فقط وقتی موفق است که Baseline بدون نقض Invariant کامل شود و هر Mutant Counterexample مورد انتظار و نام‌برده‌شده خود را تولید کند. Parse Failure، Timeout، محدودیت منابع، نبود Counterexample یا نقض Invariant غیرمنتظره PASS محسوب نمی‌شود؛ بسته به علت FAIL یا INCONCLUSIVE است.

## ۷. Bounds و فرض‌ها

- یک WorkItem تغییرناپذیر و دو Process مربوط به Worker با نام W0 و W1.
- هر دو Process عمداً یک Service Principal احراز‌شده مشترک دارند.
- دو Generation Claim (۰، ۱، ۲)؛ LeaseDuration = 2 و دامنه زمان Persistence از ۰ تا ۴ فقط ثابت‌های اکتشاف متناهی هستند.
- Clockهای محلی Worker مستقل از زمان Persistence جلو می‌روند؛ این یک Abstraction غیرقطعی از Skew/کهنگی است، نه Bound کمی Drift ساعت.
- یک نقطه Serialization و یک External Blocker برای مدل‌سازی Contention/انتظار Lock.
- فقط یک Tenant و یک Installation مدل شده‌اند؛ بررسی چندمستاجری فراتر از تشخیص Binding نامنطبق در M6 است.
- Entropy Token، اصالت رمزنگاری، پیاده‌سازی IAM، Semantics مربوط به Lock/Isolation/Time در Database، Kill/STONITH، رفتار Queue، اثرات خارجی و پروتکل Restore Incarnation انتزاع یا خارج از Scope هستند.
- مدل Liveness، Throughput، مناسب‌بودن مدت Lease، Policy مربوط به Retry/Backoff یا ظرفیت Production را اثبات نمی‌کند.

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
