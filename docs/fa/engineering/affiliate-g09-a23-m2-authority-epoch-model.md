# G09-A23-M2 — مدل Epoch اختیار و حصارگذاری Writer

**شناسه سند:** LOT-AFFILIATE-G09-A23-M2-001  
**نسخه:** ۰.۱.۲ | **وضعیت:** با TLC در Bounds محدود بررسی شده؛ بازبینی مستقل و Refinement به Candidate در انتظار است  
**مدل:** formal/G09M2AuthorityEpochFencing.tla  
**Baseline:** formal/G09M2AuthorityEpochFencing.cfg  
**Runner:** scripts/formal/run_g09_m2.sh  
**Workflow:** .github/workflows/formal-g09-m2.yml  
**سند مادر هنجاری:** LOT-AFFILIATE-G09-A23-001 بخش‌های ۳ تا ۷؛ ADR-002 پیشنهادی؛ G09-A21/A22

## ۱. هدف و دامنه

M2 خانواده Authority Epoch در A23 را مدل می‌کند: دو Writer، دو Epoch، Partition شبکه، انتقال اختیار، اعمال Fence در مقصد Mutation، بازگشت Primary قدیمی و Restore داده قدیمی. مدل مستقل از Candidate است و هیچ Database، Consensus implementation، Cloud، Failover manager، Topology یا سازوکار فیزیکی Fence را انتخاب نمی‌کند.

مدل سه پرسش را از هم جدا نگه می‌دارد:

۱. **Election/Selection:** کدام Writer برای مالکیت بعدی پیشنهاد یا انتخاب شده است؟  
۲. **Authority Transfer:** مرجع معتبر از چه زمانی Epoch جدید و غیرقابل‌استفاده‌مجدد را تخصیص می‌دهد؟  
۳. **Fencing:** مقصد واقعی Mutation از چه زمانی Epoch قدیمی را رد می‌کند؟

انتخاب یا Election یک Writer به‌تنهایی مجوز امن Write نیست. مقصد باید Epoch اختیار را enforce کند و فعال‌سازی Writer جدید پس از تأیید این Enforcement انجام شود.

## ۲. انتزاع و فرض‌ها

| موضوع | انتزاع M2 |
|---|---|
| Writerها | دو Actor نمادین W0 (قدیمی) و W1 (نامزد) |
| دامنه Epoch | اعداد متناهی ۱ تا ۳؛ در Baseline یک انتقال قابل دسترسی است |
| Authority Root | متغیرهای rootEpoch، authorityOwner و authorityHighWater |
| Credential نویسنده | Token احراز‌شده انتزاعی و مقید به Writer/Epoch؛ رمزنگاری مدل نشده |
| Enforcement Mutation | یک Sink کانونی با sinkFenceEpoch |
| مراحل انتقال | active → frozen → allocated → fenced → active |
| Partition | W0 غیرقابل‌دسترسی و W1 قابل‌دسترسی می‌شود؛ این Fault abstraction است، نه الگوریتم Quorum |
| Restore | داده Restoreشده ممکن است Epoch قدیمی داشته باشد؛ Authority Root جداست و Restore در Quarantine می‌ماند |
| Writeها | هر Write پذیرفته‌شده، Writer، Token Epoch، Authority Epoch و Sink Fence Epoch زمان Transition را ثبت می‌کند |

مدل فرض می‌کند Authority Root/High-water Mark در پروتکل سالم معتبر است و بی‌صدا Rollback نمی‌شود. Mutant مربوط به Restore عمداً این فرض را نقض می‌کند تا حساسیت Oracle سنجیده شود. اگر خود Authority Root قابل Rollback باشد و مرجع بازیابی مستقلی وجود نداشته باشد، سامانه باید Fail Closed شود؛ این مدل سازوکار بازیابی اختراع نمی‌کند.

## ۳. پروتکل و مرز Linearization

انتقال سالم به این ترتیب است:

۱. **Freeze:** پذیرش Write از Writer قدیمی متوقف شود.  
۲. **Allocate:** Epoch جدید از Authority Root تخصیص یابد و به W1 متصل شود.  
۳. **Apply Fence:** Epoch پذیرفته‌شده در Sink کانونی Mutation جلو برده شود. این نقطه، Barrier و Linearization Fencing در مدل است.  
۴. **Verify:** شواهدی دریافت شود که Sink واقعاً Epoch جدید را enforce می‌کند.  
۵. **Activate:** فقط اکنون W1 فعال شود.  
۶. **Resume:** Write تنها زمانی مجاز باشد که Writer، Token احراز‌شده، Authority Owner، Root Epoch و Sink Epoch همگی منطبق باشند.

مدل ApplyFenceAtSink را از VerifyFenceEvidence جدا می‌کند؛ تخصیص Epoch یا تأیید Control-plane به‌تنهایی Evidence مربوط به Fence نیست. Writeای که پیش از Barrier در نقطه Linearization قرار گرفته، به‌صورت پس‌نگر لغو نمی‌شود. پس از Barrier، Write باید Epoch جاری را حمل کند و همان Enforcement Boundary کانونی آن را بپذیرد.

Partition یا از دست رفتن Heartbeat به‌تنهایی اثبات نمی‌کند W0 از کار افتاده است و نمی‌تواند Promotion را مجاز کند. پیشرفت در مدل سالم فقط از مسیر Freeze/Allocate/Fence/Verify صریح ممکن است.

## ۴. متغیرها و Transitionهای اصلی

| متغیر | معنا |
|---|---|
| rootEpoch | Epoch جاری تخصیص‌یافته توسط مرجع معتبر |
| authorityHighWater | High-water Mark غیرقابل‌Rollback برای Epochهای تخصیص‌یافته |
| authorityOwner | Writer مجاز از دید Authority Root |
| writerEpoch | Epoch متصل به هر Writer |
| tokenEpoch، tokenAuthenticated | احراز اصالت انتزاعی Credential و اتصال آن به Epoch |
| sinkFenceEpoch | حداقل Epoch پذیرفته‌شده توسط Mutation Sink کانونی |
| fenceVerified | پرچم Evidence پس از Barrier در Sink |
| phase | مرحله انتقال/بازیابی |
| networkPartition، writerReachable | Fault ساده‌شده دسترسی |
| restoreMode، restoredEpoch | Quarantine بازیابی و Epoch موجود در داده Restoreشده |
| acceptedWrites | Tuple شواهد در لحظه Write، نه فقط شمارنده وضعیت نهایی |

Transitionهای اصلی: FreezeOldWriter، AllocateNewEpoch، ApplyFenceAtSink، VerifyFenceEvidence، ActivateNewWriter، SetPartition، HealPartition، CrashOldWriter، ReturnOldWriter، TryAuthorizedWrite، BeginRestore، ReconcileRestore و FinishRestore.

TryAuthorizedWrite فقط وقتی فعال می‌شود که Writer آنلاین/قابل‌دسترسی/فعال باشد، Token آن احراز شده و به Epoch مقید باشد و Writer Epoch = Token Epoch = Authority Epoch = Sink Fence Epoch باشد؛ همچنین Writer باید همان Authority Owner باشد. Writer قدیمی پس از بازگشت از Failover نمی‌تواند این Guard را برآورده کند.

## ۵. Invariantهای ایمنی بررسی‌شونده

| Invariant | قرارداد |
|---|---|
| TypeOK | تمام State در دامنه متناهی تعریف‌شده باقی بماند |
| SingleWriter | حداکثر یک Writer فعال باشد |
| RootEpochAtLeastHighWater | داده Restoreشده نتواند Authority Root را پایین‌تر از High-water Mark غیرقابل‌Rollback ببرد |
| SinkFenceEpochAtLeastHighWater | Restore نتواند Epoch حصارگذاری‌شده در Mutation Sink را پایین‌تر از High-water Mark مستقل آن ببرد |
| NewWriterActivationRequiresFence | W1 پیش از Fence تأییدشده Sink در Epoch جاری فعال نشود |
| RestoreQuarantine | در زمان Restore/Reconciliation هیچ Writer فعالی وجود نداشته باشد و Phase در Quarantined/Fenced بماند |
| EveryWriteWasFencedAndAuthorized | هر Write پذیرفته‌شده، برابری Writer/Token/Authority/Sink Epoch و Authority Owner را در لحظه Write ثبت کند |
| AuthenticatedCurrentTokenHasAuthorityOwner | Token مدعی Epoch جاری نمی‌تواند متعلق به Non-owner باشد |
| NoActiveWriterDuringUnverifiedTransfer | هنگام انتقال و پیش از تأیید Fence هیچ Writer فعالی نباشد |

این‌ها بررسی Safety هستند. M2 ادعای Liveness ندارد و فرض Fairness اضافه نمی‌کند. بن‌بست یا توقف امن به‌معنای پیشرفت نیست.

## ۶. Negative Controlها و حساسیت مورد انتظار Oracle

| پیکربندی | Fault عمدی | Invariant مورد انتظار برای نقض |
|---|---|---|
| G09M2MutantEarlyPromotion.cfg | فعال‌سازی W1 پیش از Sink Fence/Evidence | NewWriterActivationRequiresFence |
| G09M2MutantPartitionPromotion.cfg | تلقی Partition به‌عنوان اختیار کافی برای Promotion | NewWriterActivationRequiresFence |
| G09M2MutantStaleWrite.cfg | اجازه Write به W0 پس از جلو رفتن Sink Epoch | EveryWriteWasFencedAndAuthorized |
| G09M2MutantRestoreRollback.cfg | Rollback کردن Authority Epoch به Epoch داده قدیمی | RootEpochAtLeastHighWater |
| G09M2MutantSinkFenceRollback.cfg | Rollback کردن Fence در Mutation Sink هنگام Restore | SinkFenceEpochAtLeastHighWater |
| G09M2MutantForgedEpoch.cfg | دادن Token ظاهراً احراز‌شده Epoch جاری به W0 غیرمالک | AuthenticatedCurrentTokenHasAuthorityOwner |

Mutant فقط زمانی پذیرفته است که TLC دقیقاً Invariant نام‌برده را نقض کند. اگر Baseline شکست بخورد، Mutant معتبر تلقی نمی‌شود. اگر Mutant Oracle مورد انتظار را فعال نکند، Transition و Invariant باید بازبینی شوند؛ Oracle را صرفاً برای سبز شدن CI تضعیف نکنید.

## ۷. بازتولید اجرا

Runner پیش از اجرا، SHA-256 فایل JAR ثابت‌شده TLA+ Tools v1.7.4 را بررسی می‌کند و یک Baseline به‌همراه پنج Negative Control را اجرا می‌کند:

    TLA2TOOLS_JAR=/path/to/tla2tools.jar \
    TLC_OUT_DIR=/tmp/g09-m2-results \
    bash scripts/formal/run_g09_m2.sh

GitHub Actions همان JAR ثابت‌شده را دریافت و Hash آن را بررسی می‌کند، Runner را اجرا می‌کند و Logهای TLC و State metadata را به‌عنوان Artifact نگه می‌دارد. الگوی Runner با M0/M1 یکسان است.

**آخرین شواهد اجرای واقعی:** [GitHub Actions Run 46175422477 — G09 M2 Authority Epoch Fencing](https://github.com/tecpey/lottorito-platform/actions/runs/46175422477) — SUCCESS روی PR head دقیق 96fc7a4830af452f214921ac9af68d7ae4265f33؛ Runner مربوط به pull_request روی Synthetic merge commit با شناسه کوتاه 547cd6f اجرا شد (Base: f032065f47fe85de2aabf8d47565a57af6af3ae9). Toolchain: TLA+ Tools v1.7.4 / TLC 2.19، SHA-256 فایل JAR برابر با 936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88؛ Eclipse Temurin OpenJDK 17.0.21.1؛ Ubuntu 24.04؛ BFS، یک Worker، Seed=1، fp=0 و Heap برابر 1 GiB.

| Case | نتیجه TLC | Generated / Distinct | Depth |
|---|---|---:|---:|
| Baseline | بدون نقض Invariant؛ کل State graph محدود بررسی شد | 515 / 136 | 12 |
| Early promotion | نقض NewWriterActivationRequiresFence | 31 / 22 | 4 |
| Partition-only promotion | نقض NewWriterActivationRequiresFence | 76 / 39 | 5 |
| Stale old-writer mutation | نقض EveryWriteWasFencedAndAuthorized | 72 / 37 | 5 |
| Restore authority rollback | نقض RootEpochAtLeastHighWater | 27 / 18 | 3 |
| Restore sink-fence rollback | نقض SinkFenceEpochAtLeastHighWater | 27 / 18 | 3 |
| Forged current-epoch token | نقض AuthenticatedCurrentTokenHasAuthorityOwner | 31 / 22 | 4 |

شمارش State در Mutantها ناقص است؛ TLC پس از نخستین Counterexample مورد انتظار متوقف شده و این اعداد State-space کامل نیستند. Runner فقط به این دلیل موفق شد که Baseline بدون خطا کامل شد و هر شش Mutant دقیقاً Invariant نام‌برده را نقض کردند.

**Manifest بازتولیدپذیری:** SHA-256 ماژول M2 برابر با ad773d328db633da4789ad064633f933e5ba5870655045a033c1ac82587b4e78 است. SHA-256 پیکربندی Baseline برابر با f3f4eda5b755e91da9c19cb1e5695a04f5ed69f16361c7d317a2bde1ee09a55a است. Artifact اجرا: [g09-a23-m2-tlc-46175422477-1](https://github.com/tecpey/lottorito-platform/actions/runs/46175422477/artifacts/15275536520)، SHA-256 آرشیو: f289ee443e87d314d2df7d97f4908361b8aba4a9d99a9b0c1cc9d50fc133c410.

این اجرا نسبت به Run قبلی با پنج Mutant، یک آزمون مستقل برای Rollback شدن Metadata حصارگذاری Mutation Sink اضافه می‌کند و شواهد Canonical فعلی M2 محسوب می‌شود. نتیجه همچنان فقط به همین ماژول/Config/Toolchain و Bounds متناهی تعلق دارد؛ اثبات نامتناهی، بازبینی مستقل، Candidate refinement یا راستی‌آزمایی Runtime/Production نیست.

## ۸. محدودیت‌ها و تعهدهای Refinement

- مدل متناهی از دو Writer و حداکثر یک انتقال Epoch استفاده می‌کند؛ اثبات نامتناهی نیست.
- tokenAuthenticated اعتبارسنجی Signature/Issuer را انتزاع می‌کند؛ مدیریت کلید، Unforgeability، انتشار Revocation یا Rotation Credential را اثبات نمی‌کند.
- یک Sink کانونی مدل شده است. اگر Writer قدیمی و جدید بتوانند به Storeهای مستقل و قابل‌نوشتن Mutation بزنند، Fence یک Sink، دیگری را Fence نمی‌کند. چنین Topologyای به Enforcement Authority مشترک یا Physical Fencing مستقل و اثبات‌شده (مثلاً STONITH) نیاز دارد.
- Reachability در Partition عمداً ساده است. مدل Raft/Paxos، عضویت Quorum، Failure Detector یا پروتکل Witness را پیاده‌سازی نمی‌کند.
- Root/High-water Mark به‌صورت انتزاعی معتبر فرض شده است. Restore از Backup/PITR مربوط به Authority Root، از دست رفتن Quorum State، Disaster Recovery و تخصیص Recovery Incarnation به Evidence و Refinement جداگانه نیاز دارند.
- ترتیب Writeهای In-flight در مرز Transaction/Commit موتور Storage واقعی تعریف نشده است. Candidate باید Linearization و Durability واقعی Mutation را اثبات کند.
- هیچ Database، Queue، Vendor، Topology، RPO، Failover Timer یا آستانه عددی عملیاتی انتخاب نشده است.
- TLC صحت Database، Runtime، Failover Controller یا Production واقعی را اثبات نمی‌کند. Candidate Refinement، Fault Injection قطعی و History/Linearizability Checking مراحل بعدی و نیازمند مجوز جداگانه‌اند.

## ۹. مبنای تحقیق

- Google، Mike Burrows، **The Chubby lock service for loosely-coupled distributed systems**، OSDI 2006. Sequencerهای Chubby اطلاعات Lock Generation را حمل می‌کنند و Resource Server دریافت‌کننده باید Sequencer نامعتبر/قدیمی را رد کند: https://www.usenix.org/legacy/event/osdi06/tech/full_papers/burrows/burrows_html/
- PostgreSQL، **Warm Standby — Failover**. پس از Promotion یک Standby، Primary قدیمی باید از طریق سازوکار مناسب مطلع/محدود شود تا هر دو Node خود را Primary ندانند: https://www.postgresql.org/docs/current/warm-standby-failover.html
- Leslie Lamport، **Proving Safety Properties**. Invariantها باید در تمام Stateهای قابل‌دستیابی مدل مشخص بررسی شوند؛ نتیجه همچنان به همان Specification محدود است: https://lamport.org/tla/proving-safety.pdf

این منابع روش طراحی و مدل شکست را پشتیبانی می‌کنند؛ مدل حاضر یا هیچ پیاده‌سازی Lottorito را تأیید نمی‌کنند.

## ۱۰. تعیین وضعیت

M2 یک مدل State-machine متناهی و مستقل از Candidate با یک Baseline و شش Negative Control هدفمند Oracle است. Baseline محدود TLC و هر شش Negative Control روی آخرین Head دقیق ثبت‌شده با موفقیت اجرا شدند. وضعیت **TLC-CHECKED WITHIN FINITE BOUNDS** است؛ بازبینی مستقل و Candidate refinement همچنان در انتظارند. این سند A21 Findings را نمی‌بندد، ADR-002 را تصویب نمی‌کند، هیچ A4 Gate را برآورده نمی‌کند، R2 را مجاز نمی‌کند، Candidate مربوط به Persistence را انتخاب نمی‌کند و مجوز Runtime/Partner/Finance/Production، Merge یا Deploy صادر نمی‌کند.
