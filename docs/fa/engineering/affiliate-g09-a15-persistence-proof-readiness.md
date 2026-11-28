# G09-A15 — آمادگی اثبات Persistence و ماتریس تصمیم‌های مالک برای ADR-002

**شناسه سند:** LOT-AFFILIATE-G09-A15-001  
**نسخه:** ۰.۱.۰  
**تاریخ:** ۲۰۲۶-۱۱-۲۸  
**وضعیت:** بسته آمادگی اثبات — مستقل از Candidate؛ تصمیم‌های مالک و بازبینی مستقل همچنان OPEN  
**PR مبنا:** شماره ۷۶  
**Head مبنای بررسی:** `736390f86ab425a8c273dcf254cc5974e9eb55ae`  
**اسناد مرتبط:** LOT-AFFILIATE-G09-ADR-002 نسخه ۰.۳.۰؛ G09-A11؛ G09-A12؛ G09-A7؛ G09-A4؛ G09-A8؛ G09-A14  
**اختیار:** صرفاً طراحی و آماده‌سازی اثبات. بدون انتخاب Persistence/Queue/Vendor، اجرای Runtime یا Harness، اتصال شریک، عملیات مالی، Merge یا مجوز Deploy.

## ۱. هدف و تعیین تکلیف

G09-A15 تعهدات باز ADR-002 را به یک قرارداد اثبات مستقل از فناوری و ماتریس تصمیم‌های پاسخ‌گو تبدیل می‌کند. این سند مشخص می‌کند چه چیزهایی باید تصمیم‌گیری شوند، Candidate آینده چه رفتارهایی را باید اثبات کند، شواهد چگونه باید به‌طور مستقل مشاهده شوند و در چه شرایطی سامانه باید متوقف بماند.

این سند **بازبینی مستقل، تصویب مالک، ارزیابی Candidate، انتخاب Vendor یا اثبات اجرای تست نیست**. هیچ‌یک از A11-F01 تا F08، یافته‌های A7/A8 یا Gateهای A4 را نمی‌بندد. بسته A12 همچنان روش انجام بازبینی واقعی توسط فرد مستقل است؛ A15 قرارداد شواهد آینده را اجرایی‌تر و قابل ممیزی‌تر می‌کند.

## ۲. خط مبنای ثابت و مرز شواهد

خط مبنای بررسی، PR شماره ۷۶ در Head برابر با `736390f86ab425a8c273dcf254cc5974e9eb55ae` بود. روی همان Head دقیق:
- Affiliate Contract Validation شماره ۲۳۵، Run برابر با `46071082568`: موفق.
- Documentation Governance شماره ۱۰۶۲، Run برابر با `46071082558`: موفق.
- PR شماره ۷۶ در وضعیت Open/Draft و Merge نشده بود.

این اجراها فقط اعتبارسنجی‌های پیکربندی‌شده قرارداد و مستندات را پوشش می‌دهند. آن‌ها رفتار تراکنش Database، Durability، سازگاری Replica، ایمنی Promotion، Fencing مرجعیت، تضمین Replay یا مجوزدهی Runtime را اثبات نمی‌کنند. هر Commit بعدی، قابلیت استناد این نتایج به Head جدید را از بین می‌برد و برای انتساب آن نتایج به Head جدید باید CI دقیقاً روی همان Head دوباره بررسی شود.

در زمان بررسی PR، هیچ Review ثبت‌شده یا Comment گفت‌وگویی در رکورد قابل مشاهده GitHub وجود نداشت. این موضوع اثبات نمی‌کند که بازبینی خارج از GitHub انجام نشده؛ فقط یعنی در رکورد بررسی‌شده، تأییدیه Review در GitHub موجود نبود. بازبین واقعاً مستقل باید تعیین شود و معیارهای بخش ۲ از A12 را برآورده کند.

## ۳. تعهدات هنجاری اثبات

موارد زیر تعهدات پذیرش برای Candidate آینده‌اند، نه انتخاب مکانیزم اجرایی.

### PO-01 — جفت پذیرش اتمیک

برای یک هویت Event منبع که احراز هویت و به Installation متصل شده است، پذیرش باید دقیقاً یک InboxReceipt و دقیقاً یک WorkItem مرتبط را در یک مرز Commit اتمیک ایجاد کند. پاسخ موفق نباید هیچ‌گاه فقط یکی از دو عضو جفت را قابل مشاهده کند. ارتباط باید برابری Tenant و Installation تغییرناپذیر را اعمال کند. تحویل تکراری باید به همان Reference پایدار پذیرش برسد و WorkItem دیگری نسازد.

شواهد لازم:
- بررسی مستقیم Persistence مرجع با حالت Consistency مستند؛
- شواهد Transaction/Constraint برای یکتایی هویت منبع و ارتباط یک‌به‌یک/حداکثر یک WorkItem؛
- تزریق خطا بین هر Write منطقی و قبل/بعد از Commit؛
- Scheduleهای هم‌زمانی با کلید یکسان؛
- Assertion منفی مبنی بر اینکه جفت ناقص و ارتباط بین Tenantها قابل Commit نیست.

Invariant متنی یا Pre-check در سطح Application کافی نیست، اگر مرز Persistence آن را اعمال نکند.

### PO-02 — طبقه‌بندی نتیجه Commit و تطبیق

نتیجه قابل مشاهده برای Client باید این وضعیت‌ها را از هم جدا کند:
- **COMMITTED:** موفقیت Commit تحت قرارداد Durability تصویب‌شده تأیید شده است؛
- **ABORTED:** مرجع Persistence به‌طور قطعی تأیید می‌کند Commit رخ نداده است؛
- **UNKNOWN:** فراخواننده نمی‌تواند تعیین کند Commit رخ داده یا نه؛
- **UNAVAILABLE:** در حال حاضر تصمیم از مرجع معتبر قابل دریافت نیست.

این‌ها واژگان اثبات برای Scheduleهای تست‌اند، نه HTTP Status یا Error Enum عمومی تصویب‌شده. UNKNOWN نباید به Retry به‌عنوان عملیات جدید، پذیرش قطعی یا رد قطعی تبدیل شود. Read منفی از Replica با Consistency ضعیف/قدیمی، مدرک Abort نیست. Reconciliation باید با همان هویت پایدار و یک مکانیزم اثبات‌شده Serialization/Consistency، تراکنش اولیه درحال‌اجرا را نیز تعیین تکلیف کند.

شواهد لازم:
- Interleaving قطعی تراکنش اولیه و Retry؛
- اثبات اینکه پیش از مجازشدن Write دوم، تراکنش اولیه Commit، Abort یا همچنان unresolved است؛
- Semantics مربوط به Read مرجع و حالت Consistency؛
- اثبات اینکه UNKNOWN هرگز جفت Receipt/WorkItem دوم ایجاد نمی‌کند؛
- اثبات Fail-closed در صورت عدم دسترسی به Authority.

### PO-03 — Durability پذیرش تأییدشده و نقطه Recovery

مالک باید Failure Model پشتیبانی‌شده و وعده دقیق Durability در نقطه Acknowledgement را پیش از تصویب هر ادعای 202/پذیرش پایدار تعیین کند. Candidate باید نشان دهد هر جفت Acknowledged در برابر تمام کلاس‌های خرابی مشمول آن وعده باقی می‌ماند و Promotion/Restore نمی‌تواند وضعیت تأییدشده را بی‌صدا حذف کند.

شواهد لازم:
- Semantics اختصاصی Candidate برای Write/Flush/Replication Acknowledgement؛
- کلاس‌های خرابی تحت پوشش و خرابی‌های مستثنا؛
- از دست‌دادن کنترل‌شده Primary بلافاصله پس از Acknowledgement؛
- Scheduleهای Promotion و بازگشت Primary قدیمی؛
- تست Restore/PITR همراه با مقایسه Recovery Point؛
- تأیید مستقل هویت‌های Acknowledged قبل و بعد از Recovery.

هیچ RPO، تعداد Replica همگام، Quorum، تعداد Region یا سطح Durability را نباید اختراع کرد. این‌ها تصمیم‌های مالک بر اساس تحمل زیان تجاری و قابلیت Candidate هستند.

### PO-04 — مرجعیت Single-writer و Fencing

دامنه پذیرش محافظت‌شده باید دقیقاً یک Writer معتبر داشته باشد. Authority Epoch افزایشی فقط زمانی مفید است که مرز Enforcement در تمام مسیرهای Write محافظت‌شده Epoch قدیمی را رد کند و خود Epoch با همان Failover/Restoreای که قرار است از آن محافظت کند، Rollback یا Fork نشود.

شواهد لازم:
- Threat Model و تحلیل خرابی ریشه Authority؛
- Scheduleهای Partition، Promotion و بازگشت Primary قدیمی؛
- اثبات مستقیم اینکه Writer قدیمی قادر به دسترسی یا تغییر مرز Persistence محافظت‌شده نیست؛
- تست همه مسیرهای Write، از جمله Administrative، Repair، Migration و Background؛
- Runbook بازیابی که Fencing فرآیندها/اعتبارنامه‌های Writer قدیمی را پیش از ازسرگیری Write اثبات کند.

Tokenای که فقط کنار داده‌ای ذخیره شده که ممکن است Rollback شود، به‌تنهایی اثبات Epoch غیرقابل‌Rollback نیست. Leadership در Queue یا Lease مربوط به Worker، Fencing در سطح Storage را اثبات نمی‌کند.

### PO-05 — چرخه Replay، Fingerprint و Retention

هویت Event منبع، Idempotency Key درخواست HTTP و هویت Economic Effect مستقل باقی می‌مانند. Fingerprint یک قرارداد سازگاری نسخه‌دار است، نه صرفاً یک تابع Hash. تغییر Parser، Canonicalization، Schema، Registry مربوط به Extension یا Normalization معنایی نباید یک Event پذیرفته‌شده قبلی را بی‌صدا با معنای دیگری تفسیر کند.

شواهد لازم:
- رفتار Parser سخت‌گیرانه، از جمله رد Memberهای تکراری پیش از Materialization آبجکت؛
- Vectorهای Canonicalization چندزبانه و Fixtureهای تست نسخه‌دار؛
- تعیین تکلیف صریح دامنه/نمایش Number و حفظ Unicode؛
- Scheduleهای Migration و Deployment با نسخه‌های مختلط؛
- تست Replay قبل و بعد از Horizon تصویب‌شده Retention؛
- شواهد چرخه Tombstone/Backup/Restore/Offboarding/Legal Hold.

RFC 8785 برای JCS الزام می‌کند ورودی از محدودیت‌های I-JSON پیروی کند؛ از جمله نداشتن نام Property تکراری، Unicode معتبر و نمایش عددی قابل‌تعامل. این مرجع برای فهم مسئله مرتبط است، اما به‌معنای تصویب JCS در Lottorito نیست. Profile مربوط به Fingerprint در ADR فعلی تا زمان تصویب مالک، تضمین Parser و Vectorهای چندزبانه همچنان تصویب‌نشده است.

### PO-06 — تمامیت جفت، Quarantine و چرخه عمر Tenant

Cardinality جفت و Binding مربوط به Tenant/Installation باید در مرز پایدار قابل اعمال باشد. جفت ناقص/خراب، نقض Invariant است، نه سیگنال Retry عادی. محتوای غیرقابل‌اعتماد Payload نباید به‌تنهایی Quarantine گسترده Tenant ایجاد کند. Quarantine باید WorkItem متأثر را در یک مرز Serialization‌شده از Claim توسط Worker خارج کند و هم‌زمان Tenantهای نامرتبط را فعال نگه دارد.

شواهد لازم:
- تست Constraintهای یکتایی و ارتباط؛
- تزریق عمدی Write حذف‌شده و Restore ناقص؛
- تلاش‌های عدم تطابق Tenant/Installation؛
- Scheduleهای رقابت Quarantine با Claim و Commit درحال‌اجرا؛
- شواهد Authorization و Audit برای عملیات Quarantine؛
- Assertionهای Availability/Fairness برای Tenantهای متأثرنشده؛
- Policy صریح برای Receiptهای پذیرفته‌شده قبلی پس از Suspend/Revocation نصب.

### PO-07 — Acceptance به‌معنای Execution نیست

Acknowledgement فقط یعنی Event طبق قرارداد Durability تصویب‌شده به‌طور پایدار پذیرفته شده است. این پاسخ به‌معنای Claim، Processing، Attribution، Qualification، محاسبه کمیسیون، ثبت Ledger، پرداخت یا Settlement نیست. Submission تکراری همان Reference پایدار را برمی‌گرداند. هیچ مسیر Ingress مجاز به تغییر وضعیت مالی نیست.

شواهد لازم:
- تست State Transition در قرارداد و Status Resource؛
- بررسی Capability و Credential؛
- بررسی Network/Service Binding و مسیرهای Queue؛
- Assertion مستقیم عدم اثر در Ledger/Wallet/Payment/Payout؛
- تست منفی برای Reachability ناخواسته از طریق فراخوانی غیرمستقیم سرویس‌ها.

## ۴. ماتریس تصمیم مالک — هیچ Defaultی قابل استنباط نیست

| شناسه | تصمیم لازم | مالک/مالکان پاسخ‌گو | Artifact تصمیم موردنیاز | موانع |
|---|---|---|---|---|
| OD-01 | Namespace منبع و دامنه هویت Event تغییرناپذیر | مالک Product/Domain + شریک + امنیت | قرارداد نسخه‌دار هویت منبع و Policy برخورد | PO-01/02/05 |
| OD-02 | Scope، Binding و Retention مربوط به Request Idempotency-Key | API/Platform + امنیت + حریم خصوصی | چرخه عمر Key، Binding به Tenant/Installation و Replay Horizon | PO-02/05 |
| OD-03 | Parser، Policy مربوط به JSON Member تکراری، الگوریتم/نسخه Fingerprint و Migration | معماری + امنیت + Integration | ADR، Vectorهای چندزبانه و Policy سازگاری/Migration | PO-05 |
| OD-04 | Failure Model پشتیبانی‌شده و وعده Durability برای Commit تأییدشده | مالک + SRE/پلتفرم داده + مالی | ماتریس کلاس خرابی، تصمیم RPO/RTO و قرارداد Acknowledgement | PO-03 |
| OD-05 | ریشه Authority مربوط به Single-writer، تخصیص Epoch و Enforcement مربوط به Writer قدیمی | Platform/SRE + امنیت | ADR مرجعیت/Fencing و Threat Model | PO-04 |
| OD-06 | Isolation/Serialization در Persistence و Arbitration تراکنش درحال‌اجرا | پلتفرم داده + معماری | پرونده Semantics مختص Candidate و Scheduleها | PO-01/02/04 |
| OD-07 | Cardinality جفت Receipt/WorkItem و Policy تعمیر/Quarantine | پلتفرم داده + Domain + امنیت | طراحی Constraint/Capability و Runbook تعمیر | PO-01/06 |
| OD-08 | Replay Horizon، Tombstone، Backup/Restore، Deletion و Legal Hold | حقوقی/حریم خصوصی + امنیت + عملیات + مالک | Policy چرخه داده و Retention | PO-05 |
| OD-09 | مرجع مجاز Quarantine، Scope، انقضا، بازبینی و Recovery | امنیت + عملیات + مالک Domain | ماتریس Authorization و State Machine قابل Audit | PO-06 |
| OD-10 | اثر Suspend/Revocation نصب بر Receiptهای قبلاً پذیرفته‌شده | Product/Domain + امنیت + شریک | تصمیم Lifecycle و Semantics مربوط به Race | PO-06 |
| OD-11 | پاسخ عمومی UNKNOWN/Unavailable و راهنمای Retry | API/Platform + مالک + شریک | قرارداد Wire و نگاشت خطای Machine-readable | PO-02/07 |
| OD-12 | Retention، دسترسی، تمامیت Evidence و مرجع بازبینی مستقل | امنیت + حقوقی/حریم خصوصی + QA + مالک | Policy شواهد، انتصاب بازبین و Disposition امضاشده | تمام POها |

هیچ مقدار عددی، Default مربوط به Vendor، Tier تبلیغاتی Provider یا مثال در سند محصول جای تصمیم مالک را نمی‌گیرد. اگر مالک پاسخ‌گو تعیین نشده باشد، مورد OPEN می‌ماند و اثبات وابسته به آن نمی‌تواند PASS شود.

## ۵. Scheduleهای اثبات مستقل از فناوری

تمام Scheduleها از Tenant، Installation، Event و Credential ساختگی استفاده می‌کنند. استفاده از داده واقعی شریک/مشتری/بازیکن و هرگونه Capability مالی ممنوع است.

| Schedule | خرابی/Interleaving | نتیجه لازم | Evidence مستقل |
|---|---|---|---|
| S01 | دو Event منبع یکسان به‌صورت هم‌زمان | یک جفت پذیرش؛ هر دو Caller به Reference پایدار یکسان برسند | Query جفت در Authority + Trace تراکنش |
| S02 | هویت یکسان با Payload معنایی متفاوت | Conflict قطعی؛ بدون جفت دوم یا Overwrite خاموش | Capture درخواست خام + رکورد Fingerprint/Version + Query DB |
| S03 | Crash پس از Write Receipt و قبل از WorkItem | هیچ جفت ناقص Commit‌شده باقی نماند | Fault Controller + Snapshot مستقیم Persistence |
| S04 | Crash پس از Write WorkItem و قبل از Commit | پذیرش ناقص قابل مشاهده نباشد | Fault Controller + Read مستقل |
| S05 | Commit موفق و گم‌شدن پاسخ | Retry به جفت اولیه تطبیق یابد؛ WorkItem تکراری ایجاد نشود | Evidence خطای شبکه + Read از Authority + Timeline تراکنش |
| S06 | تراکنش اولیه هنگام شروع Retry همچنان درحال‌اجرا باشد | دقیقاً یک نتیجه Serialization‌شده؛ بدون Abort کاذب از Read منفی | Schedule با Barrier قطعی + Trace تراکنش/DB |
| S07 | Authority هنگام Reconciliation مربوط به UNKNOWN در دسترس نباشد | Fail-closed؛ جفت دوم ساخته نشود | Evidence Partition شبکه + Assertion صفر Write |
| S08 | Primary بلافاصله پس از Acknowledgement از دست برود | نتیجه مطابق قرارداد Durability/RPO تصویب‌شده باشد | Log Acknowledgement + Trace Failover + State بازیابی‌شده |
| S09 | Primary قدیمی پس از Promotion برگردد | Authority قدیمی قادر به تغییر داده محافظت‌شده نباشد | Evidence مرز Fencing + تلاش Write ردشده |
| S10 | Restore، Generation/Epoch مربوط به WorkItem را Rollback کند | Claim/Write تا برقراری مجدد Recovery Fence متوقف بماند | Manifest Restore + رد Worker قدیمی + Attestation بازیابی |
| S11 | Replay پس از مرز Retention مربوط به Dedup | رفتار مطابق Policy صریح منبع/حقوقی باشد؛ تضمین مستندنشده ایجاد نشود | Query Tombstone/Retention + Trace Replay |
| S12 | Quarantine با Claim Worker و Revocation نصب رقابت کند | یک برنده Serialization‌شده؛ بدون Claim قدیمی یا Transition ممنوع پس از Revocation | Trace تراکنش + Version چرخه عمر + Assertion صفر تغییر برای عملیات Stale |

Scheduleهای S01 تا S12 تعهدات اثبات پیشنهادی‌اند و **NOT RUN** هستند. این موارد مکمل ۴۷ Case Canonical مربوط به A4 و Subcaseهای موجود در A7/A8/A10/A11 هستند و شماره‌گذاری آن‌ها را تغییر نمی‌دهند.

## ۶. قرارداد بسته شواهد

هر اجرای آینده باید یک Manifest شواهد مقاوم در برابر دستکاری تولید کند که حداقل شامل موارد زیر باشد:
- Repository، Branch، Source Commit SHA، Hash Artifactهای منبع و شناسه Build؛
- هویت نسخه/پیکربندی Candidate و Topology (بدون Secret)؛
- نسخه Harness تست، Fixture IDها، شناسه Schedule قطعی و نسخه Fault-injection Controller؛
- زمان شروع/پایان همراه با Clock Source و عدم‌قطعیت اعلام‌شده؛
- Request/Correlation ID و هویت‌های ساختگی Tenant/Installation؛
- شناسه Authority مربوط به Persistence، حالت Consistency در Read، شناسه Transaction و Metadata مربوط به Commit/Replication Acknowledgement که Candidate ارائه می‌کند؛
- Fault-injection Event که رسیدن به نقطه خرابی هدف را ثابت کند؛
- مشاهدات خام هر Oracle مستقل، روش جمع‌آوری و هویت دسترسی؛
- نتیجه مورد انتظار در برابر نتیجه مشاهده‌شده، خروجی Assertion و انحراف‌ها؛
- Integrity Hash/Signature و Reference ذخیره‌سازی Immutable؛
- هویت بازبین، اظهارنامه استقلال/تعارض و Disposition امضاشده.

Logهای Application مشاهده پشتیبان‌اند، نه Oracle مستقل Persistence. Dashboard، CI سبز، پاسخ HTTP یا Read از Replica با Consistency نامستند به‌تنهایی Durability Commit را اثبات نمی‌کند. Harness تست نباید تنها Oracle برای خاصیتی باشد که ادعای اثبات آن را دارد.

## ۷. Gateهای مرحله‌ای آمادگی

| Gate | معیار ورود | معیار خروج | وضعیت فعلی |
|---|---|---|---|
| R0 — تثبیت قرارداد | ورودی‌های A7/A11/A12/A14 ثابت شده باشند | تصمیم‌های OD-01 تا OD-12 ثبت یا با منطق و اثر صریح به تعویق افتاده باشند | BLOCKED |
| R1 — پرونده Semantics مربوط به Candidate | Candidate توسط مالک پاسخ‌گو پس از R0 پیشنهاد شود | Semantics مربوط به Isolation، Transaction، Uniqueness، Replication، Failover، Fencing، Restore و Consistency به POها نگاشت و مستقلاً بررسی شوند | NOT STARTED |
| R2 — طراحی Harness ساختگی | R1 پذیرفته شده باشد؛ هیچ Capability مالی وجود نداشته باشد | Barrier/Fault Injection قطعی، Oracle مستقل، Fixture و Manifest شواهد بازبینی شوند | NOT STARTED |
| R3 — اجرای اثبات Candidate | دامنه تست ایزوله صریحاً توسط مالک/امنیت/QA/SRE مجاز شده باشد | S01 تا S12 اجرا؛ شکست‌ها تحلیل؛ Evidence لازم حفظ؛ بدون داده/اثر Production | NOT AUTHORIZED |
| R4 — Disposition مستقل | Evidence و Source SHA ثابت؛ بازبین واجد صلاحیت تعیین شده باشد | Disposition امضاشده برای هر یافته؛ ثبت یافته‌های جدید؛ پذیرش محدودیت‌ها و ریسک باقیمانده توسط مالک | NOT STARTED |
| R5 — بازبینی Gateهای انتشار A4 | R0 تا R4 تکمیل شده باشد | هر Gate از A4 جداگانه توسط مرجع پاسخ‌گوی خودش بررسی و تصویب شود | NOT APPROVED |

عبور از یک مرحله به‌صورت خودکار مرحله بعد را تأیید نمی‌کند. Candidate می‌تواند در یک تعهد اثبات شکست بخورد و بدون تضعیف Invariant برای سازگارشدن با Candidate رد شود.

## ۸. شرایط توقف بحرانی

اگر هر یک از موارد زیر رخ دهد، مسیر Ingress/Worker متأثر متوقف شود و پذیرش جدید Acknowledged نشود:
- دو جفت Receipt/WorkItem برای یک هویت Commit شوند؛
- پذیرش Acknowledged خارج از Failure Model صریحاً تصویب‌شده از دست برود؛
- Primary قدیمی پس از انتقال Authority همچنان قادر به Write باشد؛
- UNKNOWN صرفاً بر اساس Read منفی ضعیف/قدیمی، Abort تلقی شود؛
- جفت ناقص به‌عنوان پذیرش‌شده قابل مشاهده باشد؛
- هویت Tenant یا Installation قابل تغییر یا عبور باشد؛
- Replay پس از Horizon وعده‌داده‌شده، Duplicate مستندنشده ایجاد کند؛
- Quarantine با ورودی غیرقابل‌اعتماد به‌طور گسترده فعال شود یا بدون Serialization با Claim Worker رقابت کند؛
- هر Credential/Service مسیر Ingress بتواند Ledger، Wallet، Payment، Commission، Settlement یا Payout را تغییر دهد؛
- Evidence نتواند Source SHA، هویت Candidate، نقطه Fault یا منشأ Oracle را ثابت کند.

نتیجه مورد انتظار را پس از مشاهده شکست تغییر ندهید تا تست سبز شود. هر تغییر پروتکل به‌روزرسانی ADR نسخه‌دار و اجرای مجدد Scheduleهای متأثر را لازم دارد.

## ۹. ارتباط با یافته‌های موجود

| مورد موجود | پوشش در A15 | وضعیت پس از A15 |
|---|---|---|
| A11-F01 — Durability/RPO مربوط به Acknowledgement | PO-03، OD-04، S08 | OPEN |
| A11-F02 — Authority Epoch/Split-brain | PO-04، OD-05، S09–S10 | OPEN |
| A11-F03 — Commit درحال‌اجرا در برابر Read منفی | PO-02، OD-06، S05–S07 | OPEN |
| A11-F04 — Cardinality/Linkage جفت | PO-01/06، OD-07، S01/S03/S04 | OPEN |
| A11-F05 — Versioning مربوط به Fingerprint | PO-05، OD-03، S02/S11 | OPEN |
| A11-F06 — Idempotency محدود به Retention | PO-05، OD-02/08، S11 | OPEN |
| A11-F07 — دامنه اثر Quarantine | PO-06، OD-09/10، S12 | OPEN |
| A11-F08 — تفکیک Accepted از Executed | PO-07، OD-11، شواهد Capability/عدم اثر مالی | OPEN |

A15 ساختار و Scheduleهای اثبات را صریح‌تر می‌کند؛ هیچ یافته‌ای را نمی‌بندد. A12 همچنان روش بازبینی مستقل است. A11 همچنان خودبازبینی همان جریان است. ADR-002 همچنان PROPOSED است.

## ۱۰. مبنای تحقیق و محدودیت منابع

- مستند رسمی Google Cloud Spanner توضیح می‌دهد که Commit ممکن است UNKNOWN برگرداند و Caller ممکن است نیازمند Read مجدد State باشد. این نمونه مشخص نشان می‌دهد چرا ابهام Commit به پروتکل صریح نیاز دارد؛ اثبات قابل‌انتقال رفتار Database دیگر نیست: https://docs.cloud.google.com/spanner/docs/reference/rest/v1/projects.instances.databases.sessions/commit
- مستند تراکنش Spanner، رفتار Transactionهای Serializable و Consistency در زمان Commit را توضیح می‌دهد. این‌ها Semantics مختص محصول‌اند و نباید به Candidate انتخاب‌نشده تعمیم داده شوند: https://docs.cloud.google.com/spanner/docs/transactions
- PostgreSQL مستندات Replication همگام، Failover و ریسک Split-brain/فعال‌ماندن Primary قدیمی را ارائه می‌کند. هر Candidate مبتنی بر PostgreSQL به Topology مشخص و Proof مربوط به Fencing نیاز دارد، نه صرفاً فعال‌کردن Replication: https://www.postgresql.org/docs/current/warm-standby.html و https://www.postgresql.org/docs/current/warm-standby-failover.html
- RFC 8785، JCS و محدودیت‌های I-JSON از جمله منع نام Property تکراری و الزامات Unicode/Number را تعریف می‌کند: https://www.rfc-editor.org/rfc/rfc8785.html
- NIST SP 800-204D درباره امنیت زنجیره تأمین نرم‌افزار، Provenance و Attestation در DevSecOps CI/CD است: https://csrc.nist.gov/pubs/sp/800/204/d/final

این منابع برای صورت‌بندی پرسش‌ها و طراحی شواهد استفاده شده‌اند؛ هیچ Database، Queue، Authority Provider، پیاده‌سازی Fingerprint، مدت Retention یا Topology عملیاتی را انتخاب نمی‌کنند.

## ۱۱. تعیین تکلیف نهایی

**G09-A15: بسته آمادگی اثبات آماده شد — بازبینی مستقل نیست؛ هیچ اثبات Runtime اجرا نشده است.**

- ADR-002 همچنان PROPOSED است.
- A11-F01 تا F08 همچنان OPEN هستند.
- Extensionهای A7/A8/A10/A11 همچنان NOT RUN/BLOCKED هستند، مگر اینکه جداگانه Evidence ارائه شود.
- هر هشت Gate مربوط به A4 تصویب‌نشده‌اند.
- Proof مربوط به Allowlist نصب در Runtime در A13-F02 باز است.
- نگاشت UNKNOWN، Durability/Failure Model، RPO و تصمیم‌های Recovery در A13-F05 به تصمیم مالک وابسته و باز هستند.
- هیچ Persistence/Queue/Vendor انتخاب نشده؛ هیچ Runtime/Harness اجرا، شریک متصل یا عملیات مالی انجام نشده است.
- PR شماره ۷۶ همچنان Draft است؛ Merge و Deploy مجاز نیست.

**وابستگی بعدی:** یک بازبین مستقل واجد صلاحیت مطابق بخش ۲ از A12 تعیین شود و مالک پاسخ‌گو برای OD-01 تا OD-12 مشخص گردد. تا آن زمان پروژه می‌تواند طراحی را دقیق‌تر و قرارداد شواهد را آماده کند، اما نباید ادعای تأیید مستقل یا آمادگی Persistence مطرح کند.
