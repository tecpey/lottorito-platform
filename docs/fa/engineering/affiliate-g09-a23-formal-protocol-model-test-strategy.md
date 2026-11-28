# G09-A23 — مدل رسمی پروتکل و راهبرد آزمون خصمانه

**شناسه سند:** LOT-AFFILIATE-G09-A23-001  
**نسخه:** ۰.۱.۱۱ | **وضعیت:** پیشنهادی؛ M0 و M1 با TLC در Bounds محدود بررسی شده‌اند؛ Runtime اجرا نشده و M2–M7 تألیف نشده‌اند  
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
| claimGeneration | Generation افزایشی Claim برای هر WorkItem؛ بدون کاهش، Wrap، Reset یا Reuse |
| claimOwner | Principal احراز‌شده مالک Claim جاری |
| claimToken | Token محرمانه/غیرقابل‌حدس متصل به Owner و Generation جاری |
| lifecycleVersion | نسخه چرخه عمر برای Guard انتقال‌های محافظت‌شده |
| leaseExpiry | زمان انقضای مرجع Persistence برای Claim جاری |
| leaseState | وضعیت Lease؛ زمان انقضا به‌تنهایی مجوز Mutation نیست |
| leaseClockModel | مدل مرجع زمان/Skew و نحوه نمونه‌برداری زمان در ارتباط با نقطه Serialization |
| leaseObservation | مشاهده اعتبار Lease پس از گرفتن نقطه Serialization؛ نه Timestamp قدیمی پیش از انتظار Lock |
| workState | وضعیت انتزاعی WorkItem: ready / claimed / processing / completed / failed / quarantined / blocked |
| outboxState | وضعیت انتشار اختیاری پس از Commit مبدأ |
| consumerReceipt | Deduplication/Receipt مستقل Consumer |
| restoreIncarnation | شناسه یکتای چرخه Restore/Recovery |
| tombstone | نشانگر پایدار هویت مصرف‌شده/منقضی‌شده طبق سیاست مصوب |
| tombstoneState | چرخه عمر Marker: active / eligible_for_expiry / expired / legal_hold |
| sourceReplayHorizon | افق Redelivery/Replay مبدأ؛ کران مصوب متناهی یا صریحاً unbounded |
| identityProtectionHighWaterMark | High-water Mark مرجع برای جلوگیری از احیای Identity مصرف‌شده |
| restoreMode | وضعیت Restore: quarantined / reconciling / eligible_to_reopen |
| recoveryGateSet | مجموعه Gateهای لازم برای تطبیق و بازگشایی Restore |
| destinationIdentity | هویت پایدار اثر/عملیات در مقصد خارجی طبق قرارداد مقصد |
| destinationAuthority | Epoch/Generation یا مرجع پذیرش مستقل مقصد، در صورت پشتیبانی |
| destinationReceipt | Receipt مرجع مقصد برای Idempotency/Lookup |
| destinationOutcome | نتیجه مشاهده‌شده Caller در مقصد: confirmed / rejected / unknown |
| externalEffect | اثر مقصد خارجی؛ خارج از Transaction مبدأ و بدون تضمین اتمیک سرتاسری |
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
| ClaimWork | WorkItem و Binding Tenant/Installation از مرجع معتبر Resolve شوند؛ پس از Serialization، فقط READY یا CLAIMED با Lease منقضی و Policy مجاز Claim شود؛ Generation دقیقاً یک‌بار افزایش یابد و Owner/Token/Expiry/State در یک Transaction Commit شوند؛ مالکیت قبل از Commit اعلام نشود |
| ExpireAndReclaim | CLAIMED با Lease منقضی و Policy مجاز؛ Reclaim سریال‌شده دقیقاً یک‌بار Generation را افزایش دهد و Owner/Token/Expiry/State را اتمیک تغییر دهد؛ Generation قبلی پس از Commit رد شود |
| LinearizeLeaseTransition | پس از اخذ نقطه Serialization، Guard اعتبار Lease را همان‌جا ارزیابی کند؛ اگر منقضی است Mutation رد شود؛ فقط Transition دارای Lease معتبر و Guard کامل می‌تواند Linearize شود |
| ResumeStaleWorker | Mutation روی State محافظت‌شده مبدأ در صورت انقضای Lease در نقطه Guard یا عدم تطابق Owner/Generation/Token/Authority رد شود. این ردشدن، درخواست خارجی قبلاً ارسال‌شده را لغو نمی‌کند؛ نتیجه مقصد باید با قرارداد Receiver بررسی شود |
| RenewLease | CLAIMED؛ Owner/Token/Generation/Authority/State/LifecycleVersion معتبر و Lease در Guard پس از Serialization هنوز معتبر باشد؛ فقط Expiry تمدید شود و Generation تغییر نکند؛ Lease منقضی احیا نشود |
| CommitWorkTransition | WorkItem/Tenant/Installation Binding، State مورد انتظار، Principal احراز‌شده، Owner، Generation، Token، Lease معتبر در نقطه Linearization، Authority و LifecycleVersion همگی Guard شوند؛ شکست Guard صفر ردیف محافظت‌شده را تغییر دهد |
| PublishOutbox | فقط از Outbox Durable؛ تحویل ممکن است تکراری/نامرتب باشد |
| ConsumeMessage | Consumer مرجع Work را دوباره بخواند/Claim کند؛ پیام Broker به‌تنهایی Authority نیست |
| Restore | داده و Metadata بازیابی شوند، اما محیط ابتدا در Quarantine بالا بیاید؛ Ingress/Worker غیرفعال، Egress خارجی مسدود و Credentialها ایزوله باشند |
| ReconcileRestore | اختلاف داده، Epoch، Tombstone/Identity High-water Mark، Queue/Inbox/Outbox، Credential/Key، Schema و Tenant آشکار و تعیین تکلیف شود؛ محیط همچنان Quarantined بماند |
| ReopenAfterRestore | فقط پس از تکمیل همه Gateهای Recovery و ثبت Evidence مصوب؛ در غیر این صورت Fail Closed |
| ReplaySourceIdentity | Replay قبل/بعد از انقضای Tombstone طبق افق واقعی مبدأ و Source Epoch/Namespace بررسی شود؛ Identity مصرف‌شده نباید خاموش دوباره پذیرفته شود |
| ExpireTombstone | فقط پس از اثبات پایان افق متناهی Redelivery/Replay/Backup/PITR/Queue/Manual Replay و نبود Legal Hold؛ اگر افق متناهی اثبات‌پذیر نیست، Expiry ممنوع و Retention دائمی یا Epoch/Namespace Rollover با Cutover اثبات‌شده لازم است |
| Quarantine/Repair | Actor مجاز، دامنه محدود، Audit کامل؛ Worker عادی حق Claim مورد قرنطینه را ندارد |
| SubmitExternalEffect | فقط پس از Work/Outbox معتبر؛ مقصد خارجی قرارداد مستقل Identity/Idempotency/Fencing خود را اعمال کند |
| ReconcileExternalEffect | UNKNOWN مقصد با Lookup مرجع مقصد حل شود؛ نبود Receipt از Cache/Timeout نتیجه‌گیری نشود |
| RejectStaleDestinationActor | فقط مقصدی که Fencing سمت Receiver را پشتیبانی و اثبات کرده است Epoch/Generation قدیمی را در نقطه اثر رد کند؛ در غیر این صورت پذیرش دیرهنگام ممکن است و باید UNKNOWN/Residual Risk ثبت شود |
| DispatchExternalRequest | درخواست با destinationIdentity و Fingerprint ثابت از مرز Process خارج شود؛ وضعیت in-flight مستقل از Lease مبدأ ثبت شود |
| AcceptExternalRequest | Receiver درخواست را طبق Idempotency/Fencing/Ordering خودش بپذیرد یا رد کند؛ زمان رسیدن ممکن است پس از انقضای Lease مبدأ باشد |
| LoseExternalResponse | اثر Receiver ممکن است اعمال شده باشد، اما پاسخ گم شود؛ Caller نتیجه destinationOutcome=unknown مشاهده کند |
| RetryExternalRequest | فقط با همان destinationIdentity/Idempotency Key و Fingerprint مصوب Retry شود؛ تولید Key جدید برای همان اثر ممنوع است |
| ExpireReceiverDedupWindow | پایان Retention Dedup مقصد ثبت شود؛ Replay پس از آن نباید بدون قرارداد جدید به‌عنوان Duplicate امن فرض شود و باید Risk/Outcome صریح داشته باشد |

**قاعده خطی‌سازی و انقضای Lease (هم‌راستا با ADR-001):** هر Transition محافظت‌شده باید نقطه Linearization مشخص داشته باشد. بررسی Lease/Epoch یا نمونه‌برداری زمان پیش از انتظار برای Lock کافی نیست؛ پس از اخذ نقطه Serialization، Guard باید Lease را در همان نقطه دوباره ارزیابی کند. اگر Lease در این نقطه منقضی شده باشد، Transition رد می‌شود، حتی اگر هنوز Reclaim یا Generation جدیدی ثبت نشده باشد. انقضا به‌تنهایی State یا Generation را تغییر نمی‌دهد؛ فقط شرط اعتبار Lease را نامعتبر و Work را واجد Reclaim می‌کند. اگر Worker قدیمی در نقطه Guard هنوز Lease معتبر و Owner/Generation/Token/Authority جاری داشته باشد و Mutation سریال‌شده موفق شود، آن Transition پیش از Reclaim مرتب می‌شود. اگر Reclaim زودتر Commit شده باشد، Generation قدیمی رد می‌شود. این قاعده با ساعت محلی Worker یا Timestamp پیش از Lock قابل جایگزینی نیست. A23 روش پیاده‌سازی خاصی را به‌عنوان پاسخ عمومی تحمیل نمی‌کند.

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
| S-07 Worker Fencing | هر Mutation محافظت‌شده تمام Guardهای Identity/Tenant/Installation، State مورد انتظار، Principal، Owner، Generation، Token، Lease معتبر در نقطه Linearization، Authority و LifecycleVersion را بررسی کند؛ Generation قدیمی رد شود و شکست Guard صفر ردیف محافظت‌شده را تغییر دهد. اثر خارجی فقط با کنترل اثبات‌شده سمت Receiver محافظت می‌شود و در غیر این صورت مشمول S-14/UNKNOWN/Residual Risk است |
| S-08 Restore Monotonicity | Restore/PITR نتواند Epoch، Identity مصرف‌شده یا Revocation را ناخواسته احیا/عقب ببرد؛ محیط Restoreشده تا تکمیل Reconciliation و Gateهای مصوب در Quarantine بماند و Ingress/Worker/Egress فعال نشوند |
| S-09 Tenant Isolation | هیچ Read/Write/Disclosure بین Tenantها از طریق Identity، Payload، Retry یا Repair رخ ندهد |
| S-10 Outbox Boundary | پیام Broker مرجع Acceptance نیست؛ Publisher/Consumer و Receipt داخلی طبق قرارداد Dedup سمت Consumer عمل کنند؛ تحویل تکراری Broker به‌تنهایی نباید Mutation تکراری در Store مرجع Consumer بسازد. تضمین اثر Receiver خارجی جداگانه تحت S-14 است |
| S-11 External Effect Boundary | Atomicity دیتابیس به‌عنوان Exactly-once برای مقصد خارجی معرفی نشود |
| S-12 Financial Non-effect | Ingress و Worker فاقد مسیر مجاز به Mutation مالی باشند؛ Delta مالی صفر بماند |
| S-13 Evidence Integrity | هر نتیجه به History، Config، Version، Clock، Actor و Artifact دارای Hash قابل انتساب باشد |
| S-14 Destination Safety | هر اثر خارجی یا با Idempotency/Lookup/Fencing قابل اثبات در مقصد محافظت شود، یا صریحاً خارج از تضمین Exactly-once و در وضعیت UNKNOWN/Residual Risk باقی بماند؛ Token دیتابیس به‌تنهایی مقصد را Fence نمی‌کند |
| S-15 Lease Linearization | اعتبار Lease پس از اخذ نقطه Serialization و در Guard همان Mutation سنجیده شود؛ اگر در آن نقطه منقضی باشد، Mutation رد شود حتی اگر Reclaim هنوز رخ نداده باشد؛ Expiry به‌تنهایی State/Generation را تغییر نمی‌دهد؛ Transition معتبر پیش از انقضا و پیش از Reclaim مرتب می‌شود؛ پس از Commit شدن Reclaim با Generation جدید، هر Mutation از Generation قدیمی رد شود |

Safety باید برای تمام Prefixهای قابل‌دسترسی برقرار باشد؛ نه فقط در پایان اجرای خوش‌شانس. هر Counterexample معتبر، FAIL است؛ فقدان Counterexample در مدل محدود، اثبات کلی سامانه واقعی نیست.

## ۶. Liveness، Fairness و Degraded Mode

Liveness فقط تحت فرض‌های صریح قابل طرح است. هیچ ادعای «همیشه پردازش می‌شود» در Partition دائمی، از دست‌رفتن Quorum، خرابی دائمی مقصد، نبود ظرفیت یا توقف Scheduler مجاز نیست.

خواص پیشرفت پیشنهادی، مشروط به فرض‌ها:

- L-01: اگر Authority معتبر و پایدار، Persistence در دسترس، منابع زیر سقف مصوب و Scheduler منصف باشد، WorkItem واجد شرایط نهایتاً Claim و به مرحله پردازش/نتیجه صریح برسد؛ Quarantine فقط با Predicate مشخص و Audit مجاز است و نباید مسیر فرار عمومی از پیشرفت باشد.
- L-02: اگر Transaction اولیه پایان قطعی پیدا کند و مرجع Reconciliation در دسترس باشد، UNKNOWN نهایتاً به نتیجه قابل‌اثبات تبدیل شود؛ در غیر این صورت UNKNOWN حفظ و Escalate شود.
- L-03: پس از بازیابی Broker/Consumer و رفع Backpressure، Outbox واجد شرایط نهایتاً دوباره تلاش شود؛ تحویل تکراری مجاز است، اثر دوم نه.
- L-04: یک Tenant پرحجم نتواند بدون حد مصوب منابع، پیشرفت همه Tenantهای دیگر را نامحدود متوقف کند.
- L-05: Quarantine/Repair مسیر انسانی/عملیاتی قابل مشاهده داشته باشد و به صف پنهان بی‌انتها تبدیل نشود.

Fairness قوی/ضعیف، Scheduler، نرخ ورود، ظرفیت، Retry Budget، Quota و Deadline باید پارامتر و تصمیم جداگانه باشند. مدل باید حالت Degraded، توقف امن، Backpressure، Retry Storm، Starvation و Recovery پس از رفع Fault را جدا بررسی کند. Safety PASS به‌معنای Liveness PASS نیست.

## ۷. معماری Model Checking و Bounds

### ۷.۱ خانواده مدل‌ها

مدل واحد و عظیم از ابتدا ساخته نشود. مدل‌ها به‌صورت مرحله‌ای و با Interface/Invariant مشترک تفکیک شوند:

1. **M0 — Atomic Acceptance:** دو Caller، یک Identity، یک Receipt و یک WorkItem؛ Crash قبل/بعد نقطه Commit. ماژول و Configهای پایه/Mutant در `formal/G09M0AtomicAcceptance.tla` و فایل‌های همراه تألیف شده و TLC v1.7.4 در Run #11 با ۵۲ State متمایز Baseline و سه Counterexample منطبق با Mutantها اجرا شده است؛ این نتیجه فقط به Bounds M0 تعلق دارد.
2. **M1 — UNKNOWN Arbitration:** Transaction اولیه In-flight، گم‌شدن پاسخ، Negative Read، Retry هم‌زمان و Commit/Abort دیرهنگام.
3. **M2 — Authority Epoch:** دو Writer، دو Epoch، Partition، Promotion، بازگشت Primary قدیمی و Restore Epoch.
4. **M3 — Worker Lease:** دو Worker/Generation، Claim و Reclaim، تمدید Lease، Heartbeat/Completion/Retry/Park، State/Token/LifecycleVersion mismatch، شکست Guard با صفر Mutation، توقف Lock، Timestamp قبل/بعد Lock، Clock Skew، انقضای Lease پیش از Reclaim و Resume Worker قدیمی.
5. **M4 — Outbox/Consumer/Receiver:** انتشار تکراری، Delay، Reorder، Broker outage، Consumer crash، درخواست خارجی in-flight، پذیرش Receiver پس از انقضای Lease مبدأ، پاسخ گم‌شده، Retry، Idempotency/Fencing مقصد و انقضای Retention Dedup Receiver.
6. **M5 — Restore/Lifecycle:** PITR/Backup قدیمی، Tombstone و مرز انقضا، افق Replay متناهی/نامتناهی، پیام دیررس Queue، Credential/Key/Schema Rotation، Recovery Incarnation، Failback، Clean-room Quarantine و Gate بازگشایی.
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

برای هر Run: نسخه ابزار و Runtime، Hash فایل‌های Model/Config، Constants/Bounds، Assumptions، Invariants/Temporal Properties، State/Transition count، زمان/منابع، وضعیت تکمیل/قطع، Counterexample کامل، Trace و روش بازتولید ثبت شود. M0 با TLC v1.7.4 بررسی شده؛ Baseline تمام ۵۲ State متمایز را بدون نقض Invariant طی کرد و سه Negative Control دقیقاً نقض‌های پیش‌بینی‌شده را کشف کردند. Evidence و Hashها در سند همراه M0 ثبت شده‌اند. این نتیجه محدود به همان مدل و Bounds است. State-space exhaustion فقط برای همان مدل و Bounds گزارش شود. اگر Run ناقص، محدودیت منابع یا Property بررسی‌نشده وجود داشت، نتیجه INCONCLUSIVE است.

TLC یک Explicit-state Model Checker برای زیرمجموعه‌ای از TLA+ و مدل‌های محدود است؛ بنابراین نتیجه به مدل، Bounds و Propertyهای واقعاً بررسی‌شده محدود می‌ماند. [R1]

## ۸. راهبرد آزمون پیاده‌سازی: Model → History → Fault

Model Checking جای تست Candidate واقعی را نمی‌گیرد. پس از Gate و مجوز جداگانه، زنجیره آزمون باید سه لایه داشته باشد:

### ۸.۱ لایه Model

- TLA+/TLC برای Safety و Temporal Propertyهای قابل‌مدل‌سازی؛
- State-space bounds، Assumption و Abstraction آشکار؛
- Counterexampleهای حداقلی و قابل‌تکرار؛
- مقایسه مدل Abstract با قرارداد و پیاده‌سازی واقعی.

### ۸.۲ لایه History/Concurrency

- ثبت Operationهای Invoke/Complete با شناسه Correlation، Identity، Actor، Epoch، Generation و نتیجه مشاهده‌شده؛ برای اثر خارجی، زمان Dispatch، پذیرش Receiver، Receipt و نتیجه Caller جدا ثبت شوند؛
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

Mutantهای حداقلی اجباری: حذف Unique Constraint؛ Ack قبل از Commit؛ قبول Negative Read از Replica قدیمی؛ عدم بررسی Epoch در Mutation؛ قبول Worker Generation قدیمی؛ قبول Mutation پس از انقضای Lease پیش از Reclaim؛ تمدید Lease منقضی یا افزایش Generation در Heartbeat؛ Commit با Token/State/LifecycleVersion نادرست؛ تغییر ردیف با Guard ناموفق؛ بازنشانی Epoch پس از Restore؛ انقضای Tombstone پیش از پایان افق Replay/Backup؛ فعال‌سازی Ingress/Worker/Egress پیش از تکمیل Gateهای Restore؛ Retry با Identity جدید؛ پذیرش درخواست خارجی قدیمی بدون قرارداد Receiver؛ Retry اثر خارجی با Idempotency Key جدید؛ اجرای Side Effect داخل Transaction قابل Retry؛ حذف Consumer Dedup؛ و تبدیل UNKNOWN به REJECTED/ACCEPTED بدون Evidence. اگر Checker Mutant متناظر را تشخیص ندهد، آزمون حساسیت آن INCONCLUSIVE است.

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

**یادداشت بازبینی نسخه ۰.۱.۳:** بازبینی تطبیقی با ADR-001 و A22 سه مرز را صریح کرد: Lease منقضی در Guard پس از Serialization، حتی پیش از Reclaim، Mutation را رد می‌کند؛ Fencing مبدأ درخواست خارجی in-flight را لغو نمی‌کند؛ Restore باید در Quarantine بماند تا High-water Mark هویت، Tombstone، Queue/Outbox، Credential/Key، Schema و Tenant تطبیق و Gateهای بازگشایی تکمیل شوند. Transitionهای Restore/Reopen/Replay/ExpireTombstone، متغیرهای Lifecycle، S-08 و M5 اصلاح شدند. A21-F04/F05/F10/F11 همچنان OPEN هستند و این اصلاحات جایگزین Model Checking، Evidence یا Assurance مستقل نیستند.


- A23: قرارداد مدل و راهبرد آزمون پیشنهادی؛ **NOT EXECUTED**.
- M0 با TLC v1.7.4 بررسی شده: ۵۲ State متمایز Baseline؛ سه Counterexample مورد انتظار برای Partial Commit، Duplicate Pair و Early Ack. بازبینی مستقل و Refinement به Candidate انجام نشده‌اند؛ M1–M7 تألیف نشده‌اند.
- Jepsen/History Checker/Simulation: هنوز اجرا نشده است.
- A20-01..A20-28: DESIGNED / NOT RUN.
- A21-F03/F04/F05/F11/F12: در سطح روش/مدل پاسخ طراحی دریافت می‌کنند؛ تا تکمیل Model، بازبینی و Evidence همچنان OPEN.
- A21-F01/F06/F08/F13: برای A24 باز می‌مانند.
- OD-01..OD-12، C-01..C-16، G1..G9: OPEN / NOT APPROVED.
- ADR-002: PROPOSED؛ A11-F01..F08 OPEN؛ A12 انجام‌نشده.
- R0 BLOCKED؛ R1 تحقیق؛ R2 شروع‌نشده؛ R3 غیرمجاز؛ A4 تصویب‌نشده.
- هیچ Candidate، Runtime، Harness اجرایی، Partner، عملیات مالی، Production، Merge یا Deploy مجاز نیست.

**یادداشت بازبینی نسخه ۰.۱.۴:** نخستین ماژول TLA+ برای M0 و یک پیکربندی Baseline به‌همراه سه Negative Control تألیف شد؛ مستند دوزبانه M0 نیز اضافه شد.

**یادداشت بازبینی نسخه ۰.۱.۶:** M0 مجدداً در GitHub Actions Run `46170218651`، منتسب به PR head `c9d2e2b7e3d80bf53a64e928df647bcd1cb20ebc`، اجرا شد. Runner رویداد pull_request روی synthetic merge commit `9a9aa076de9700717e4d41d14766d8414fdd2b5b` کار کرد. TLC v2.19 / Tools v1.7.4، Java Temurin 17.0.21.1؛ Baseline: ۸۷ تولیدشده، ۵۲ متمایز، صفر در Queue، عمق ۷، بدون نقض. سه Mutant به‌ترتیب `PairAtomicity`، `AtMostOneReceipt` و `AcceptedAckSoundness` را نقض کردند. Artifact ID `15273631651`، SHA-256 آرشیو `0ae142aac63ca8bc9e9cdd1e802b98bdd8abf8e829045e3d99879ba92bd60d4d`. این مدل محدود هنوز بازبینی مستقل نشده و هیچ Candidate/Runtime را پوشش نمی‌دهد. M1–M7، History Checker و Simulation همچنان شروع‌نشده‌اند.

**نتیجه:** A23 مدل‌سازی و آزمون را از فهرست سناریو به روش مهندسی قابل‌ردیابی ارتقا می‌دهد؛ اما هیچ شواهدی از اجرای واقعی یا قبولی سامانه ادعا نمی‌کند.


**یادداشت بازبینی نسخه ۰.۱.۱۱:** M0 و M1 روی PR head `0feb174268beb68ed3e557e6012edf5b325158cf` و synthetic merge commit `62a1470a557ed22251315f9b1d8572b2792101a7` اجرا شدند. M0 Run `46172096434`: ۵۲ State متمایز در Baseline، سه Mutant با نقض‌های مورد انتظار؛ Artifact ID `15274440322`، SHA-256 `5ca154ba0f89fc986fd99917b70b2b592420bad0568857bf36052343cdd51e1d`. M1 Run `46172096370`: هر دو Baseline (Fingerprint یکسان/متفاوت) ۱۹ State متمایز، ۲۵ تولیدشده، عمق ۸؛ سه Mutant به‌ترتیب `NoRetryCommitWhileOriginalInflight`، `ReceiptCardinality` و `ConflictSoundness` را نقض کردند؛ Artifact ID `15273862792`، SHA-256 `3a7f263ff1d23b4d09a60cf996f54b17f81aa7c4aff2a0c0a46dcc7fb2422e11`. M1 ReceiptShape با تطبیق دقیق Owner/Fingerprint در مدل اعمال شده است. Documentation Governance Run `46172096375` و Affiliate Contract Validation Run `46172096485` نیز روی همین Head موفق شدند. شواهد فقط مدل‌های محدودند؛ بازبینی مستقل، Refinement به Candidate، Jepsen/History Checker و Simulation انجام نشده‌اند. M2–M7 تألیف نشده‌اند.
