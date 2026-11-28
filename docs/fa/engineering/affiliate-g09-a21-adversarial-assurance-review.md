# G09-A21 — بازبینی خصمانه تضمین کیفیت سند G09-A20

**شناسه سند:** LOT-AFFILIATE-G09-A21-001  
**نسخه:** 1.0.0 | **وضعیت:** خودبازبینی خصمانه داخلی — نه Assurance مستقل  
**تاریخ:** ۲۰۲۶-۱۱-۲۸  
**موضوع:** G09-A20، پرونده LOT-AFFILIATE-G09-A20-001

## ۱. نتیجه مدیریتی

A20 خط مبنای مفید تحقیق و طراحی آزمون است، اما **هنوز مشخصات اجرایی احراز صلاحیت نیست**. این سند ۲۸ سناریوی خصمانه و ده ناوردای مستقل از Candidate دارد؛ بااین‌حال اتصال نیازمندی، History شکست، Oracle، معیار پذیرش و Evidence به‌اندازه کافی دقیق نشده است.

این بازبینی ۱۳ یافته ثبت می‌کند: P0 یک مورد؛ P1 نه مورد؛ P2 سه مورد. هیچ یافته‌ای با این سند بسته نمی‌شود. هیچ آزمونی اجرا نشده و هیچ اصلاحی به‌صورت پنهانی در A20 اعمال نشده است.

## ۲. استقلال و روش بازبینی

این بازبینی در همان بستر همکاری پروژه انجام شده که A20 را تدوین کرده است. بنابراین **نظر ارزیاب مستقل، Certification، Audit، Penetration Test، نظر حقوقی یا Assurance خارجی نیست**. دیدگاه انتقادی جداگانه شبیه‌سازی شده، اما تعارض ناشی از نویسندگی/زمینه همچنان وجود دارد.

NIST SP 800-53A روش‌های ارزیابی از جمله Examine، Interview و Test را تعریف می‌کند. بحث NIST درباره استقلال ارزیاب اشاره می‌کند که سازمان کوچک ممکن است برای بررسی کامل‌بودن، سازگاری و صحت نتایج به تیم متخصص مستقل نیاز داشته باشد. بنابراین:
- A21 = خودبازبینی خصمانه داخلی / بررسی اسناد.
- A12 = تا تعیین بازبین مستقل واجد صلاحیت و امضای بازبینی با دامنه مشخص، NOT PERFORMED / NOT ASSESSABLE.
- A20 یا A21 نباید مستقل بازبینی‌شده، گواهی‌شده، تصویب‌شده یا Assured معرفی شوند.

روش: بررسی نسخه‌های EN/FA، ادعاهای وضعیت، ناورداها، سناریوها و Adapterها؛ تفکیک Safety از Liveness؛ ردیابی نیازمندی ← ناوردا ← تست ← Oracle ← Evidence ← Gate؛ چالش ابهام، Oracle دوری، فرض پنهان، مرز مجوز متناقض و ترکیب Faultهای مفقود؛ مقایسه ساختاری دوزبانه. هم‌ارزی معنایی همچنان نیازمند بازبینی انسانی است.

## ۳. یافته‌ها

### A21-F01 — استقلال Assurance اثبات نشده است
**شدت:** P0 | **وضعیت:** OPEN / BLOCKING

**شاهد:** A20 خانواده Oracleها را مستقل می‌نامد، اما ابعاد استقلال را تعریف نمی‌کند و نشان نمی‌دهد Oracle خارج از Failure/Trust Domain سیستم تحت آزمون است. خود A21 نیز از نویسندگی A20 مستقل نیست.

**ریسک:** ادعای Assurance کاذب ممکن است با بازبینی شخص ثالث یا اثبات اثربخشی کنترل اشتباه گرفته شود.

**اصلاح لازم:**
- تا زمان اثبات استقلال، عبارت مطلق Independent Oracle با Separately Implemented/Cross-source Oracle جایگزین شود.
- ابعاد استقلال تعریف شوند: پیاده‌سازی، منبع داده، سطح دسترسی، کنترل مدیریتی، Failure Domain، ساعت/Time Source، زنجیره نگهداری و بازبین.
- برای هر Assertion ماتریس استقلال Oracle و وابستگی‌های مشترک ثبت شود.
- A12 تا بازبینی و امضای فردی فاقد مسئولیت طراحی/پیاده‌سازی/بهره‌برداری، NOT PERFORMED بماند.

**پذیرش:** برای هر Assertion بحرانی تحلیل Trust Boundary وجود داشته باشد؛ هویت، صلاحیت، اظهارنامه تعارض منافع، دامنه و Disposition امضاشده بازبین مستقل ثبت شود. در غیر این صورت A12 باز می‌ماند.

### A21-F02 — معنای Source Identity و Deduplication مشخص نیست
**شدت:** P1 | **وضعیت:** OPEN / BLOCKING

**شاهد:** I-02/I-03/I-04 به Source Identity مصوب و Payload معنایی اشاره می‌کنند، اما Tuple Canonical، Namespace مربوط به Tenant، Source Installation، دامنه Event ID، نسخه Canonicalization، الگوریتم Fingerprint، رفتار Rotation کلید و افق Retention را تعریف نمی‌کنند. این موارد با OD-01 تا OD-04 و تصمیم‌های حل‌نشده ADR-002 مرتبط‌اند.

**ریسک:** برخورد بین Tenantها، Duplicate کاذب، Work تکراری پس از انقضا یا Fingerprint ناسازگار میان نسخه‌های Runtime/زبان.

**اصلاح لازم:**
- تصمیم‌های هویت حل‌نشده، تصمیم مالک باقی بمانند؛ پیش‌فرض اختراع نشود.
- Tuple هویت و قرارداد Canonicalization/Fingerprint نسخه‌دار فقط پس از تصویب ODها تعریف شود.
- حالت Identity/Fingerprint یکسان، Identity یکسان با Fingerprint متفاوت، Identity مفقود/بدساخت، مهاجرت Canonicalizer/Key و Replay نسخه قدیمی پوشش داده شود.
- Retention هویت به Redelivery/Replay مبدأ، عمر Backup، پنجره PITR، تأخیر DR و محدودیت قانونی متصل شود.

**پذیرش:** ODها تصویب شده باشند؛ قرارداد نسخه‌دار دامنه، بایت‌های Canonical، Fingerprint، Migration و انقضا را تعریف کند؛ آزمون‌ها نسخه قدیمی/جدید و برخورد Tenant را پوشش دهند.

### A21-F03 — Race مربوط به UNKNOWN Commit پروتکل کامل ندارد
**شدت:** P1 | **وضعیت:** OPEN / BLOCKING

**شاهد:** I-05 و A20-05/A20-06 Reconciliation را لازم می‌دانند، اما Visibility تراکنش، Linearization Point، Consistency مربوط به Read مرجع، رقابت با Transaction اولیه در حال اجرا، Retry محدود و رسیدگی نهایی UNKNOWN را تعریف نمی‌کنند.

**ریسک:** Read منفی با Transaction اولیه‌ای رقابت کند که بعداً Commit می‌شود؛ Retry، WorkItem دوم بسازد یا به Caller شکست کاذب اعلام شود.

**اصلاح لازم:**
- State Machine و Transitionهای چرخه عمر Receipt/WorkItem مشخص شود؛ نام نهایی تابع ADR-002 است.
- نقطه یگانه پذیرش/Linearization و Consistency لازم برای Readهای Reconciliation تعریف شود.
- رقابت Retry با Transaction اولیه‌ای که هنوز امکان Commit دارد اثبات شود؛ از Read قدیمی یا غیرسریال‌پذیر، نبود رکورد استنباط نشود.
- Escalation و رسیدگی به ابهام نهایی بدون Retry خودکار ناایمن تعریف شود.
- پیش از Harness Runtime، State Exploration مبتنی بر Model اضافه شود.

**پذیرش:** هیچ History قابل دسترسی با دو WorkItem پذیرفته‌شده برای یک Identity، رد نهایی کاذب یا Ack موفق بدون جفت پایدار وجود نداشته باشد. UNKNOWN تا حل مرجع صریح باقی بماند.

### A21-F04 — اتمیک‌بودن Database اثر جانبی خارجی را Fencing نمی‌کند
**شدت:** P1 | **وضعیت:** OPEN / BLOCKING

**شاهد:** A20-11 تحویل تکراری/نامرتب Outbox و I-06 Fencing بازیگر قدیمی را پوشش می‌دهند، اما قرارداد End-to-End دریافت‌کننده برای Payment/Provider/Webhook/Email وجود ندارد.

**ریسک:** Worker قدیمی پس از Lease Loss همچنان API خارجی را فراخوانی کند؛ Outbox دوبار تحویل شود؛ Fencing پایگاه داده درخواست پذیرفته‌شده خارجی را برنمی‌گرداند.

**اصلاح لازم:**
- Fencing وضعیت داخلی از Idempotency اثر جانبی Downstream جدا شود.
- برای هر مقصد، Idempotency Key، Request Fingerprint، Retention سمت Receiver، Lookup نتیجه، Reconciliation، رفتار Timeout/Unknown و معنای Duplicate تعریف شود.
- ترتیب به‌ازای Aggregate/Sequence و رفتار Gap تعیین شود.
- اگر Receiver قابلیت Idempotency/Reconciliation ندارد، Trade-off بین At-most-once و At-least-once ثبت و ادعای Exactly-once خارجی ممنوع شود.
- فراخوانی Worker قدیمی پس از Lease Loss، ازدست‌رفتن پاسخ پس از پذیرش Downstream، Replay Receiver، انقضای Key و تحویل نامرتب آزموده شود.

**پذیرش:** هر اثر خارجی قرارداد Receiver اثبات‌شده یا صریحاً خارج از مرز تضمین داشته باشد.

### A21-F05 — Retention، Tombstone، Replay و Restore به هم متصل نشده‌اند
**شدت:** P1 | **وضعیت:** OPEN / BLOCKING

**شاهد:** A20-14/A20-21 احیای Tombstone و Replay پس از Retention را ذکر می‌کنند، اما کران Retention یا افق Replay مبدأ را تعریف نمی‌کنند. بازگذاشتن مقدار عددی درست است؛ حذف روش استخراج آن درست نیست.

**ریسک:** Event پس از حذف Marker مربوط به Deduplication یا پس از Restore یک Backup قدیمی Replay شود.

**اصلاح لازم:**
- حداقل Retention هویت/Tombstone از بیشینه افق Redelivery/Replay مبدأ، عمر Backup قابل Restore، پنجره PITR، تأخیر Replication/DR، Retention صف، Replay دستی و افق بازیابی Incident استخراج شود؛ با رعایت قانون و تصویب مالک.
- اگر کران بالای متناهی وجود ندارد، از عدم استفاده مجدد از Identity یا تغییر صریح Source Epoch/Namespace استفاده شود؛ حفاظت Identity خاموش منقضی نشود.
- پیش از فعال‌کردن Ingress/Worker، State بازیابی‌شده با High-water Mark/Registry مرجع تطبیق داده شود.
- Restore ناقص، Queue دیررس، Retry قدیمی مبدأ، مهاجرت Tenant و Rotation کلید/Canonicalizer پوشش داده شود.

**پذیرش:** کران/راهبرد مصوب صریح باشد؛ Restore نتواند Identity مصرف‌شده را دوباره باز کند؛ آزمون مرزهای قبل/هنگام/بعد از انقضا را پوشش دهد.

### A21-F06 — استقلال Oracle و Triangulation شواهد عملیاتی نشده است
**شدت:** P1 | **وضعیت:** OPEN

**شاهد:** A20 خانواده‌های Oracle را فهرست می‌کند، اما چند Oracle ممکن است از همان Database یا Event تولیدشده توسط همان Application بخوانند. استقلال ادعا شده، نه اندازه‌گیری.

**ریسک:** یک منبع معیوب باعث شود Implementation و Checker هر دو به نتیجه نادرست برسند.

**اصلاح لازم:**
- Assertionها را به Oracleها نگاشت و کد، Storage، Credential، Administrator، Clock و Failure Domain مشترک را مشخص کنید.
- برای ناورداهای بحرانی، در صورت امکان دو مسیر Evidence متمایز لازم باشد؛ مانند Constraint/Transaction در DB به‌علاوه History مشاهده‌شده Client، یا Query دفترکل به‌علاوه Export تغییرناپذیر Journal.
- Negative Control اضافه شود: ورودی Oracle خراب، Log حذف، Clock منحرف یا Evidence Source قطع شود؛ نتیجه باید INCONCLUSIVE باشد، نه PASS.
- محدودیت و Blind Spot هر Oracle ثبت شود.

**پذیرش:** هر Assertion بحرانی Trust Boundary و Evidence تأییدی داشته باشد؛ فقدان/خرابی Oracle هرگز PASS تولید نکند.

### A21-F07 — ماتریس Traceability سرتاسری وجود ندارد
**شدت:** P1 | **وضعیت:** OPEN

**شاهد:** C-01..C-16، G1..G9، I-01..I-10 و A20-01..A20-28 فهرست‌های جدا هستند و نگاشت کامل ندارند.

**ریسک:** نیازمندی تست‌نشده بماند ولی مجموعه آزمون گسترده به نظر برسد؛ نتیجه تست به Constraint یا Gate مصوب مالک متصل نباشد.

**اصلاح لازم:** Traceability دوطرفه اضافه شود:
C-ID → G-ID → requirement/control → invariant → scenario(s) → oracle(s) → evidence artifact → owner/approver → result → residual risk.
توجیه N/A و موارد بدون پوشش ثبت شود. هر Test به Assertionها و هر Assertion بحرانی به Case مثبت و منفی/خصمانه نگاشت شود.

**پذیرش:** هیچ Gate اجباری یا ناوردای بحرانی شکاف پوشش توضیح‌نداده‌شده نداشته باشد؛ Traceability به‌صورت مکانیکی بررسی شود.

### A21-F08 — قرارداد اجرایی PASS/FAIL/INCONCLUSIVE ناقص است
**شدت:** P1 | **وضعیت:** OPEN

**شاهد:** A20 برچسب نتیجه دارد، اما Schema ماشین‌خوان، Granularity Assertion، تعداد تکرار، مدت، پروفایل بار، Stop Rule، Variance/Confidence و مدیریت تست Flaky را تعیین نمی‌کند.

**ریسک:** بازبین‌ها یک مشاهده را متفاوت طبقه‌بندی کنند؛ یک اجرای خوش‌شانس Proof تلقی شود.

**اصلاح لازم:**
- برای هر Case، Preconditions، Fault Schedule دقیق، History مشاهده‌شده، Invariant مورد انتظار، Queryهای Oracle، Time Bound، کامل‌بودن Evidence و Cleanup تعریف شود.
- PASS فقط با ارزیابی همه Assertionهای لازم و Evidence کامل؛ FAIL برای نقض اثبات‌شده؛ INCONCLUSIVE برای نبود اثبات Fault، ازدست‌رفتن Oracle، ابهام Evidence یا انحراف کنترل‌نشده.
- تعداد تکرار، Seed، Workload و مدت از اهداف ریسک/بار مصوب مالک استخراج شود؛ عدد اختراع نشود.
- Correctness، Availability، Performance و Recovery جدا گزارش شوند.
- Counterexample در صورت امکان بازتولید و کوچک‌سازی شود.

**پذیرش:** Schema/Decision Table وضعیت Test Record را قطعی کند؛ Evidence ناقص هرگز PASS نشود.

### A21-F09 — مرز مالی و عبارت مجوز مبهم است
**شدت:** P1 | **وضعیت:** OPEN / BLOCKING

**شاهد:** I-09 صفر بودن اثر مالی در آزمون Ingress را می‌خواهد؛ A20-27 مرز Posting ساختگی و جداگانه مجاز را می‌آزماید؛ بخش ۷ می‌گوید هیچ عملیات مالی مجاز نیست. تفاوت Fixture دفترکل ساختگی/ایزوله با سامانه مالی واقعی صریح نیست.

**ریسک:** مجری آزمون، Case را مجوز اتصال به Ledger واقعی یا Integration مالی زنده تلقی کند.

**اصلاح لازم:**
- تنها مرز مجاز A20/A21، Fixture ساختگی، ایزوله و غیرقابل Settlement باشد؛ بدون Secret تولیدی، Payment Rail خارجی، Wallet، موجودی شریک یا Ledger زنده.
- A20-27 Assertion مدل/Fixture خالص باشد یا مجوز کتبی و Gate جدا بخواهد؛ این سند مجوزی اعطا نمی‌کند.
- عدم اثر اقتصادی واقعی و نبود اتصال Production به‌طور مستقل اثبات شود.
- هر Proof مالی واقعی آینده Stage و Approval Record جدا داشته باشد.

**پذیرش:** Topology/Credential ایزوله‌بودن را اثبات کند؛ Journal ساختگی Settlement/Transfer خارجی نداشته باشد؛ مجوز صریح و محدود باشد.

### A21-F10 — آزمون Recovery کنترل‌های پرخطر Restore را کامل پوشش نمی‌دهد
**شدت:** P1 | **وضعیت:** OPEN

**شاهد:** A20 خرابی Backup، PITR، DR، Failback و Rotation کلید را دارد، اما حفاظت Backup تغییرناپذیر/Offline، حذف مخرب، جداسازی Credential هنگام Restore، Clean-room Restore، تطبیق Integrity، بازیابی Key Hierarchy و تطبیق State بازیابی‌شده با Checkpoint مصوب را کامل تعریف نمی‌کند.

**ریسک:** Restore فنی موفق، Credential تسخیرشده، Authority قدیمی، داده آلوده، WAL ناقص یا تاریخچه اقتصادی واگرا را برگرداند.

**اصلاح لازم:**
- آزمون مقاومت Backup تغییرناپذیر/Offline در برابر حذف و حذف ممتاز اضافه شود.
- Clean-room Restore با Egress پیش‌فرض‌ممنوع، Credential قرنطینه و بدون دسترسی به Production Control Plane/Partner/Payment تعریف شود.
- پیوستگی Backup + WAL/PITR، سازگاری Schema/Config، Key Hierarchy، Tenant Isolation، Authority Epoch، Event High-water Mark و Ledger Reconciliation اعتبارسنجی شود.
- Invariantهای دامنه پس از Restore لازم باشد؛ نه فقط بالا آمدن Process/Database.
- Restore از نسخه جداگانه محافظت‌شده و ازدست‌رفتن مسیر اصلی Key Management در شرایط ساختگی مجازشده تمرین شود.

**پذیرش:** Evidence بازیابی Integrity، ناورداهای دامنه، تداوم Identity، بازیابی Key و Isolation را اثبات کند؛ مؤلفه نامعلوم، بازگشایی Ingress/Worker را مسدود کند.

### A21-F11 — پوشش Safety از Liveness، Fairness و Degraded Mode قوی‌تر است
**شدت:** P2 | **وضعیت:** OPEN

**شاهد:** A20 بر نبود Duplicate/Split-brain/نشت Tenant تمرکز دارد، اما Backlog محدود، Fair Scheduling و نبود Starvation تعریف عملیاتی ندارند.

**ریسک:** سیستم ایمن بماند ولی متوقف شود؛ Tenant گرسنه بماند؛ Work بدون حد انباشته شود؛ UNKNOWN هرگز حل نشود.

**اصلاح لازم:**
- Liveness جدا تعریف شود: Work پذیرفته‌شده تحت فرض‌های بازیابی به وضعیت نهایی/قابل مشاهده برسد؛ Retry محدود و Backoffدار؛ Quarantine قابل مشاهده؛ تخلیه Backlog در ظرفیت مصوب؛ عدم انحصار Worker مشترک توسط یک Tenant.
- فرض Fairness، کلاس سرویس و اندازه‌گیری فقط پس از تصویب Workload/SLO مالک تعیین شود.
- Partition طولانی، تغییر مکرر Leader، Retry Storm، Tenant داغ، Poison Message و بازیابی ناقص وابستگی‌ها آزموده شوند.

**پذیرش:** هر ادعای Liveness دارای فرض، Metric، پنجره مشاهده و حد مصوب مالک باشد. PASS در Safety به‌معنای PASS در Liveness نیست.

### A21-F12 — ترکیب Faultها و تولید آزمون بیش از حد دستی است
**شدت:** P2 | **وضعیت:** OPEN

**شاهد:** A20 دارای ۲۸ Case دست‌نویس است، اما Schedule Generation، State Machine، Property-based Testing، Deterministic Simulation، پوشش Combinatorial، Mutation Testing یا کوچک‌سازی Counterexample ندارد.

**ریسک:** فهرست گزینش‌شده Interleavingها و تعامل‌های نادر Fault را از دست بدهد.

**اصلاح لازم:**
- Source Identity، Receipt/WorkItem، Authority Epoch، Worker Lease، Outbox Delivery و Reconciliation به‌صورت State Machine صریح مدل شوند.
- Safety و بخشی از Liveness با Bounded Model Checker مانند TLA+/TLC پیش از Chaos Test وابسته به پیاده‌سازی بررسی شود؛ حدود State و Abstraction مستند شوند.
- برای عملیات هم‌زمان و Fault Schedule از Seedهای Deterministic و History Checker به سبک Jepsen استفاده شود.
- Property-based Generation/Shrinking اضافه شود؛ Pairwise و ترکیب‌های وزن‌دهی‌شده بر اساس ریسک جای Cartesian Product نامحدود را بگیرد.
- Checker/Oracle با Mutation Test در برابر نقض‌های شناخته‌شده سنجیده شود.

**پذیرش:** راهبرد تست، Traceability مدل به Case، Seed تکرارپذیر، منطق پوشش و حساسیت شناخته‌شده Checker را نشان دهد. Model Checking جای آزمون Implementation را نمی‌گیرد.

### A21-F13 — هم‌ارزی معنایی دوزبانه و واژگان کنترل‌شده اثبات نشده است
**شدت:** P2 | **وضعیت:** OPEN

**شاهد:** شناسه Caseها در EN/FA تطابق دارد، اما تطابق شناسه، هم‌ارزی Preconditions، Expected Outcome، Severity، Prohibition یا Status را اثبات نمی‌کند. اصطلاحات فنی بدون واژه‌نامه کنترل‌شده ترکیب شده‌اند.

**ریسک:** اپراتور متکی به یک زبان، مجوز یا معیار PASS متفاوت برداشت کند.

**اصلاح لازم:**
- واژه‌نامه کنترل‌شده برای Authority، Acceptance، Durable، Unknown Commit، Tombstone، Fencing، Independent، PASS/FAIL/INCONCLUSIVE و Authorization نگهداری شود.
- Checklist تطابق Section/Case شامل تمام ردیف‌ها، ممنوعیت‌ها، وضعیت‌ها و معیارهای پذیرش ساخته شود.
- بازبینی فنی دوزبانه توسط فرد واجد صلاحیت الزامی و نام/تاریخ ثبت شود.
- هر اختلاف بااهمیت Blocker باشد؛ انگلیسی خودبه‌خود مرجع نهایی نیست مگر مالک صریحاً تصویب کند.

**پذیرش:** بازبینی هم‌ارزی معنایی هر دو نسخه امضا شده باشد؛ اصطلاحات کلیدی سازگار باشند؛ معنای مجوز/PASS در دو زبان متفاوت نباشد.

## ۴. فهرست اولیه شکاف‌های Traceability

این فهرست اولیه شکاف است، نه اثبات پوشش:

| حوزه | وضعیت A20 | کار لازم در A22/A23 |
|---|---|---|
| C-01..C-16 ← G1..G9 | فهرست‌های جدا | نگاشت هر Constraint به Gate و ماتریس پذیرش Evidence |
| OD-01..OD-12 ← I-01..I-10 | هم‌پوشانی مفهومی نسبی | Identity، Canonicalization، Retention، UNKNOWN، Authority و Cardinality حل‌نشده |
| I-01..I-10 ← A20-01..28 | چند ارتباط آشکار | نگاشت مثبت/منفی کامل برای هر Invariant |
| Scenario ← Oracle ← Artifact | خانواده عمومی Oracle | Query، Trust Boundary، Schema و مسیر Evidence اختصاصی هر Case |
| A20-27 ← Financial Gate | مبهم | مرز Fixture ساختگی و مالی واقعی |
| A20-14/21 ← Lifecycle | ناقص | کران Retention/Replay/Restore و High-water Mark مرجع |
| A20-16/17 ← DR | کلی | Topology مصوب، مرز Recovery، Oracle تطبیق و Objective |
| EN ↔ FA | فقط تطابق شناسه | امضای هم‌ارزی معنایی |

## ۵. توالی اصلاحات لازم

A20 در یک Patch بزرگ و غیرقابل ممیزی بازنویسی نشود. اصلاحات کنترل‌شده باشند:

۱. **A22 — اصلاح مشخصات A20:** F02 تا F10 را به قرارداد دقیق وابسته به تصمیم مالک، Traceability و Schema نتیجه تبدیل کند. تصمیم مالک/OD بدون تصویب بسته نشود.  
۲. **A23 — مدل رسمی و راهبرد آزمون:** F03/F04/F05/F11/F12 را با State Machine، Invariant، Safety/Liveness، حدود Model و Schedule تولیدشده پوشش دهد. بدون مجوز جداگانه، صرفاً تحقیق/طراحی مدل.  
۳. **A24 — بسته Assurance شواهد و دوزبانگی:** F01/F06/F08/F13 را با ماتریس Trust Boundary اوراکل، Schema شواهد و بازبینی معنایی دوزبانه پوشش دهد. A12 همچنان به ارزیاب انسانی مستقل نیاز دارد.  
۴. پس از آن، Artifactهای اصلاح‌شده در برابر A21 بازبینی شوند؛ سپس درباره تحقق معیار خروج R1 تصمیم گرفته شود. خروج R1 مجوز R2 یا R3 نیست.

F01 و تمام Blockerهای P1 باید تعیین تکلیف شوند تا A20 «مشخصات احراز صلاحیت» نامیده شود. پذیرش ریسک به مالک مجاز و دلیل نیاز دارد؛ نویسنده/بازبین نمی‌تواند ریسک خود را بپذیرد.

## ۶. مبنای تحقیق

- NIST SP 800-53A Rev. 5: https://csrc.nist.gov/pubs/sp/800/53/a/r5/final
- بحث استقلال ارزیاب در NIST SP 800-53A (منبع تاریخی Rev. 4؛ فقط زمینه روش‌شناختی): https://www.govinfo.gov/content/pkg/GOVPUB-C13-440ea190bd4667fad986ae0fbb1844a5/pdf/GOVPUB-C13-440ea190bd4667fad986ae0fbb1844a5.pdf
- روش‌های ارزیابی NIST: https://csrc.nist.gov/glossary/term/assessment_method
- چارچوب Jepsen: https://github.com/jepsen-io/jepsen
- شبیه‌سازی Deterministic و آزمون FoundationDB: https://github.com/apple/foundationdb/blob/main/documentation/sphinx/source/testing.rst
- ابزارهای TLA+ و Model Checking: https://lamport.org/tla/tools.html
- Lamport، Safety و Liveness: https://lamport.azurewebsites.net/tla/safety-liveness.pdf
- Google SRE Launch Checklist: https://sre.google/sre-book/launch-checklist/
- Google SRE Production Launch Planning: https://sre.google/resources/practices-and-processes/production-launch-planning/
- AWS Builders' Library، Timeout/Retry/Backoff با Jitter: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- RFC 9110 بخش 9.2.2، Idempotency و Retry: https://www.rfc-editor.org/rfc/rfc9110.html
- Google Cloud Spanner، Commit نامعلوم و Idempotency: https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- محدودیت‌های PostgreSQL pg_verifybackup: https://www.postgresql.org/docs/current/app-pgverifybackup.html

منابع روش بازبینی و کلاس‌های شکست را پشتیبانی می‌کنند؛ Lottorito را گواهی نمی‌کنند، Candidate انتخاب نمی‌کنند، تصمیم مالک را حل نمی‌کنند و Deployment آزمون‌نشده را اثبات نمی‌کنند.

## ۷. وضعیت نهایی

- A21: خودبازبینی خصمانه داخلی تکمیل؛ Assurance مستقل نیست.
- یافته‌ها: ۱۳ مورد — P0: یک مورد باز؛ P1: نه مورد باز؛ P2: سه مورد باز.
- A20: خط مبنای تحقیق/طراحی آزمون؛ هنوز مشخصات اجرایی احراز صلاحیت نیست.
- A20-01 تا A20-28: DESIGNED / NOT RUN.
- C-01 تا C-16: OPEN؛ هیچ Evidence مالک پذیرفته نشده.
- G1 تا G9: NOT TESTED / NOT PASSED.
- ADR-002: PROPOSED؛ OD-01 تا OD-12 باز.
- A11-F01 تا F08 باز؛ A12 بازبینی مستقل انجام‌نشده/غیرقابل ارزیابی.
- R0 مسدود؛ R1 صرفاً تحقیق؛ R2 شروع‌نشده؛ R3 غیرمجاز؛ A4 تصویب‌نشده.
- هیچ Runtime/Harness، انتخاب Provider، اتصال Partner، عملیات مالی، Merge یا Deploy مجاز نیست.

**نتیجه:** A20 از نظر جهت‌گیری قوی است، اما نباید «مستقل تضمین‌شده» یا مشخصات اجرایی احراز صلاحیت معرفی شود. A22 تا A24 مسیر کنترل‌شده اصلاح هستند.
