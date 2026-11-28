# وابسته G09-A8 — راستی‌آزمایی مستقل و چالش خصمانه

**شناسه سند:** LOT-AFFILIATE-G09-A8-001  
**نسخه:** 0.1.0  
**وضعیت:** خودبازبینی و چالش طراحی؛ تأیید مستقل نیست؛ هیچ اجرای Runtime انجام نشده است  
**تاریخ:** 2026-11-27  
**دامنه:** اسناد G09-A4، G09-A5 و G09-A7 روی Head بازبینی‌شده PR #76 با شناسه `aa9573f90eb5283409d20d33a3b963078ed93f7f`.

## ۱. جمع‌بندی و تصمیم بازبینی

این بازبینی، اسناد طراحی را به چالش می‌کشد، نه یک سامانه در حال اجرا را. نتیجه آن است که A4/A5/A7 یک نقشه اثبات مفید و نسبتاً دقیق فراهم کرده‌اند، اما هنوز ایمنی Runtime، راستی‌آزمایی مستقل، آمادگی Production یا مجوز پیاده‌سازی/اجرای Harness را اثبات نمی‌کنند.

**نتیجه: بازبینی طراحی مشروط، همراه با یافته‌های باز و بااهمیت.** این بازبینی در همان جریان تدوین و توسط همان دستیار انجام شده است؛ بنابراین خودبازبینی است و نباید به‌عنوان تأیید مستقل ثبت شود. یک بازبین واجد صلاحیت که نویسنده A4/A5/A7/A8 نبوده است باید یافته‌ها را مستقلاً بررسی و تعیین تکلیف کند.

ردیابی ۴۷ سناریو از نظر ساختاری مفید است، اما اتصال هر سناریو به یک Oracle به‌تنهایی استقلال Oracle یا کامل بودن پوشش خطاها را ثابت نمی‌کند. پیش از پذیرش طراحی Runtime باید رفتارهای زمانی، مجوزها، شبکه، شواهد و چرخه عمر دقیق‌تر شوند.

هیچ‌یک از هشت Gate سند A4 لغو یا معاف نمی‌شود. این سند مجوز Runtime، Harness، پایگاه داده، صف، IAM Provider، Schema، Partner Adapter، Sandbox خارجی، عملیات مالی، Merge یا Deploy نیست.

## ۲. روش و محدودیت‌های بازبینی

نسخه‌های فارسی و انگلیسی A4، A5 و A7 و ارجاعات حاکمیتی آن‌ها روی Head دقیق اعلام‌شده بررسی شدند. محورهای چالش:
- استقلال هر Oracle از سیستم مورد آزمون (SUT)؛
- صحت زمانی Claim، Lease، Fencing، تأیید دریافت و رقابت‌های چرخه عمر؛
- دسترسی مستقیم و غیرمستقیم به دامنه مالی؛
- مرجعیت Tenant/Installation در Ingress، داده پایدار و Worker؛
- برنامه‌های شکست، هم‌پوشانی سناریوها و Interleavingهای پوشش‌داده‌نشده؛
- منشأ شواهد، صحت زمان، دستکاری‌ناپذیری، نگهداری و حذف؛
- هم‌ارزی معنایی دو زبان و ردیابی حاکمیتی.

این فقط بازبینی اسناد است. هیچ Runtime، زیرساخت، پایگاه داده، صف، Identity Provider، تنظیمات استقرار، سیاست IAM/شبکه، مخزن Secret یا Harness بررسی اجرایی یا آزمایش نشده است. یافته‌ها درباره طراحی هستند، نه مشاهده تجربی کنترل‌های مستقرشده.

## ۳. یافته‌های اصلی طراحی

| شناسه | شدت | یافته | شواهد لازم برای بستن |
|---|---|---|---|
| A8-F01 | بحرانی | **انقضای Lease هنوز شرط کامل Fencing نیست.** A5 الزام Claim Generation/Token را بیان می‌کند، اما به‌صورت یکپارچه شرط نمی‌کند که Lease دقیقاً هنگام Mutation/Commit هنوز معتبر باشد. Worker ممکن است پس از انقضا و پیش از افزایش Generation توسط Worker جدید، عملیات را تکمیل کند. | تعریف انتقال شرطی در پایگاه داده با کنترل State، Owner، Generation/Token و Lease معتبر در لحظه Mutation؛ تعیین semantics تراکنش و ساعت؛ آزمون Completion، Heartbeat، Retry و Error. |
| A8-F02 | بحرانی | **Fencing رکورد WorkItem به‌تنهایی اثر جانبی بیرونی را Fence نمی‌کند.** Worker قدیمی ممکن است قبل از ردشدن Completion، اثر جانبی ایجاد کند. دامنه فعلی اثر مالی را ممنوع می‌کند، اما نباید Fencing رکورد با تضمین اثر سرتاسری اشتباه شود. | این برش Runtime بدون اثر جانبی خارج از داده پایدار خودش باقی بماند. برای هر اثر پایین‌دستی آینده، Idempotency/Fencing سمت دریافت‌کننده یا Command مالی مجاز و مستقل لازم است. |
| A8-F03 | بحرانی | **عدم دسترسی مالی هنوز به‌صورت اثبات کامل Capability تعریف نشده است.** DB Role و Network Sentinel به‌تنهایی مسیرهای غیرمستقیم از Shared Credentials، Service Mesh، Internal API، Workload Identity، Cloud Metadata، Secret Mount، Dynamic Config، DNS یا Control Plane را پوشش نمی‌دهند. | فهرست کامل قابلیت‌های هویت Ingress و Worker شامل Grants، Schema، Credential، Secret، Workload Identity، Route، DNS/Egress، Service Discovery، Internal API و Runtime Config؛ منع پیش‌فرض در چند لایه و مشاهده مستقل مجوز مؤثر و تلاش‌های ممنوع. |
| A8-F04 | زیاد | **رقابت چرخه عمر Tenant نیازمند Linearization Rule است.** عبارت «وضعیت فعلی را دوباره بررسی کند» کافی نیست؛ ممکن است Suspension پس از بررسی و پیش از انتقال Worker Commit شود. | سیاست مالک باید مشخص کند Receipt پذیرفته‌شده هنگام Active ماندگار و قابل پردازش است یا وضعیت فعلی اولویت دارد. نقطه خطی‌شدن مشخص و Race با Barrier در دو سوی آن آزمایش شود؛ بررسی و انتقال باید اتمیک یا Version-conditioned باشند. |
| A8-F05 | زیاد | **استقلال Oracleها به‌صورت عملیاتی تعریف نشده است.** O-DB، O-WRK، O-FIN و Telemetry ممکن است از Log تولیدشده توسط SUT، هویت سرویس مشترک، کد مشترک یا مسیر Query مشترک استفاده کنند. | برای هر Oracle هویت، منبع داده، مسیر کد، مرز اعتماد، Read-only بودن، Failure Mode و دلیل استقلال ثبت شود. حداقل یک Persistence Observer و یک Permission/Network Observer مستقل و فاقد امکان Mutation لازم است. |
| A8-F06 | زیاد | **چرخه عمر و حدود Monotonicity برای Claim Generation/Token روشن نیست.** واژه Monotonic عرض عدد، Overflow، Reset در Restore، استفاده مجدد از Job، یکتایی Token و اثر Rollback Backup را تعیین نمی‌کند. | دامنه Generation و عدم استفاده مجدد تعریف شود؛ پیش از Overflow توقف امن؛ Reset/Recycle ممنوع؛ Token به Job Identity و Generation ثابت متصل شود؛ Restore/Rollback و Reuse آزمایش شوند. |
| A8-F07 | زیاد | **Reconciliation برای Commit نامعلوم به جدول تصمیم کامل نیاز دارد.** A5 به‌درستی Retry کور را رد می‌کند، اما مرجع Reconciliation، Consistency و حالت‌های Pair کامل، نبود Pair، Partial/Corrupt، Fingerprint Conflict و DB unavailable باید روشن شوند. | جدول تصمیم اضافه شود. Reconcile از منبع معتبر و با Identity کامل انجام شود؛ Replica قدیمی مبنای اثبات عدم وجود نیست. Partial Pair نقض Invariant و Stop است، نه Retry عادی. |
| A8-F08 | زیاد | **تمامیت و منشأ زمانی Evidence کافی تعریف نشده است.** Digest تغییر را فقط نسبت به Digest قابل اعتماد تشخیص می‌دهد؛ هویت تولیدکننده، زمان، ساعت مورد استفاده یا جلوگیری از جایگزینی هم‌زمان Artifact و Manifest را ثابت نمی‌کند. | Manifest امضاشده یا مستقل Anchorشده، هویت/نگهداری کلید امضا، منبع زمان معتبر، Sequence یکنواخت، زنجیره Artifact، Access Audit، امضای بازبین و حفظ شواهد شکست تعریف شود. |
| A8-F09 | زیاد | **نگهداری/حذف داده با حفظ Audit ممکن است تعارض داشته باشد.** Retention-bounded بودن Evidence مشخص نمی‌کند چه چیزی باید حذف شود و چه حداقل مدرکی می‌تواند بماند یا Backup و Legal Hold چگونه مدیریت شوند. | پیش از A4-GATE-05 سیاست Data Lifecycle شامل طبقه‌بندی، هدف، دسترسی، محرک نگهداری، انتشار حذف، انقضای Backup، Legal Hold، حداقل‌سازی Evidence و اثبات حذف تصویب شود. هیچ مدت‌زمانی فرض نشده است. |
| A8-F10 | زیاد | **هم‌پوشانی سناریوها ممکن است Interleavingهای مهم را پنهان کند.** DUR-02/03/04/05/06 و Scheduleهای A7 مهم‌اند، اما Completion پس از انقضای Lease و پیش از Reclaim، رقابت Heartbeat با Reclaim، رقابت Revocation با Commit و Restore درحالی‌که Worker قدیمی زنده است، صریح نیستند. | Scheduleها با این Interleavingها توسعه یابند؛ شناسه‌های اصلی A4 تغییر نکنند و Subcase اضافه شود. |
| A8-F11 | متوسط | **کنترل منابع به پوشش چندبعدی Fairness و Amplification نیاز دارد.** اندازه، Burst، Pool و Retry پوشش داده شده‌اند؛ اما هزینه ترکیبی Decompression، Parse، Schema Validation، Logging، Retry، Tenant Contention و Queue-age starvation صریح نیست. | ابعاد هزینه و بودجه Tenant/Global در A4-GATE-06 تعریف شوند؛ Amplification و Noisy-neighbor با Workload Telemetry بیرونی آزموده شوند. این سند عددی تعیین نمی‌کند. |
| A8-F12 | متوسط | **کنترل دوزبانه و Governance ساختاری است، نه اثبات هم‌ارزی معنایی.** تطابق ID/ترتیب و CI موفق، یکسان بودن معنای Normative، شدت، وضعیت و Stop Condition در FA/EN را ثابت نمی‌کند. | تأیید بازبین دوزبانه با Clause-level parity checklist و تطبیق نسخه/Head در README، Status، Decision Register و PR لازم است. |

## ۴. قرارداد استقلال Oracle

A7 شناسه‌های O-API، O-DB، O-TX، O-IAM، O-WRK، O-NET، O-FIN، O-OBS، O-LOAD، O-DATA و O-SCHEMA را معرفی می‌کند. این‌ها دسته‌بندی مفید هستند، نه اثبات استقلال.

پیش از اجرا یک Oracle Register با ستون‌های اجباری بسازید:
۱. شناسه Oracle و Assertion دقیق؛  
۲. منبع حقیقت و روش جمع‌آوری؛  
۳. هویت اجرا و مجوزهای مؤثر؛  
۴. اشتراک یا عدم اشتراک کد با SUT؛  
۵. Read-only بودن و روش اعمال آن؛  
۶. بازبین/اپراتور مستقل؛  
۷. Failure Mode و Blind Spot؛  
۸. Artifact، Digest، Provenance و منبع Timestamp؛  
۹. نتیجه مورد انتظار برای هر Case/Subcase مرتبط.

حداقل قواعد استقلال:
- O-API رفتار قابل مشاهده سمت Client را می‌سنجد، اما Persistence را اثبات نمی‌کند.
- O-DB باید با هویت Read-only جداگانه و مستقیماً از Persistence معتبر بخواند، نه از Repository/Service خود SUT.
- O-TX باید به شواهد Native پایگاه داده از Constraint/Transaction/Lock متکی باشد، نه فقط Log برنامه.
- O-WRK وضعیت Durable Row و Claim History را با Timeline مستقل Worker/Process مقایسه کند.
- O-NET باید Enforcement Point خارج از Process سامانه، مانند Egress Policy، DNS و Connection Telemetry را مشاهده کند.
- O-FIN باید Effective DB Grants، Secret/Workload Identity، Route/Service Discovery و Prohibited-call Sentinel را ترکیب کند؛ نبود یک Metric فراخوانی کافی نیست.
- O-OBS باید Sinkها و Artifactهای مستقل را برای Canary اسکن کند؛ Assertion مربوط به Redaction در Logger کافی نیست.
- O-DATA باید حذف/دسترسی را در Primary، Replica، Backup و Evidence Store طبق Policy مصوب بررسی کند.

هیچ Oracle هنگام مشاهده نباید SUT را تغییر دهد. خرابی یا عدم دسترسی Oracle یعنی **INCONCLUSIVE**، نه PASS.

## ۵. شفاف‌سازی‌های الزامی پروتکل زمانی

### ۵.۱ Claim و Lease مربوط به Worker

انتقال معتبر باید در نقطه Mutation پایگاه داده، به‌صورت شرطی همه موارد زیر را کنترل کند:
- شناسه تغییرناپذیر WorkItem و Binding مربوط به Tenant/Installation؛
- State فعلی مورد انتظار؛
- Claim Generation و Token فعلی؛
- هویت Owner مورد انتظار؛
- معتبر بودن Lease بر اساس یک ساعت مرجع مصوب؛
- شرط Version چرخه عمر در مواردی که Policy الزام می‌کند.

عدم تطابق Generation، انقضای Lease، تغییر Owner/State یا شکست شرط Version چرخه عمر باید به صفر تغییر در رکورد محافظت‌شده منجر شود. مشخص شود Heartbeat پس از انقضا می‌تواند Lease را تمدید کند یا خیر (پیشنهاد: Fail Closed) و رقابت Heartbeat با Reclaim چگونه با همان پروتکل اتمیک سریال می‌شود.

برای تصمیم Lease از ساعت مرجع پایگاه داده استفاده شود، مگر اینکه جایگزین با بازبینی مستقل Semantics معادل را اثبات کند. رفتار Clock در Failover/Restore تعریف شود. ساعت محلی Worker نباید تنها مرجع باشد.

Generation نباید Wrap، Reset یا Reuse شود. در صورت اتمام فضای Generation یا ابهام وضعیت، پردازش متوقف/پارک و به اپراتور ارجاع شود؛ بازیافت بی‌صدای مقدار ممنوع است.

### ۵.۲ نتیجه نامعلوم Commit

برای تراکنش Ingress که تأیید Commit آن گم شده است:
۱. Insert بدون شرط جدید انجام ندهید و Rollback را فرض نکنید.  
۲. با Identity کامل Event از Persistence معتبر Reconcile کنید.  
۳. اگر دقیقاً یک Pair معتبر Receipt+WorkItem با Fingerprint/Provenance منطبق وجود دارد، نتیجه پایدار Accepted/Replay برگردد.  
۴. اگر هیچ‌کدام وجود ندارد، فقط وقتی Retry مجاز است که تضمین Consistency نبود رکورد و عدم امکان Commit دیرهنگام تراکنش قبلی را ثابت کند.  
۵. اگر فقط یک رکورد از Pair وجود دارد، چند رکورد وجود دارد، Identity/Fingerprint متعارض است یا وضعیت قابل اثبات نیست، Stop و ثبت Incident لازم است.  
۶. اگر Store معتبر در دسترس نیست یا فقط Replica قدیمی موجود است، نتیجه Indeterminate/Retryable برگردد؛ پذیرش ادعا نشود.

### ۵.۳ Linearization چرخه عمر

مالک باید تصمیم بگیرد Receipt پذیرفته‌شده در زمان Active بودن Installation پس از Suspension/Revocation بعدی همچنان پردازش شود یا وضعیت جاری آن را Cancel/Park کند. تصمیم باید نقطه Linearization و مرز Version/Transaction آن را مشخص کند. «بررسی سپس اقدام» در دو عملیات بدون محافظت کافی نیست.

## ۶. مرز اثبات عدم دسترسی مالی

ادعای اثبات باید این‌گونه محدود شود: **در محیط ایزوله تعریف‌شده، Capability مؤثر وجود ندارد و تلاش مشاهده‌شده‌ای رخ نداده است**؛ نه ادعای مطلق درباره هر استقرار آینده.

موارد زیر باید Inventory و Deny شوند:
- Credentialهای DB، Roleها، Schemaها، Grantها، Connection Stringها و Secret Referenceها؛
- Workload Identity، مجوز Service Account، Token Exchange و Metadata Endpoint؛
- فایل‌های Mountشده، Environment Variableها، Secret Manager و Dynamic Config؛
- مسیر سرویس‌های داخلی، Service Mesh Authorization، DNS/Service Discovery و Egress؛
- API/Eventهای Wallet، Ledger، Payment، Settlement، Payout، Commission و Economic Effect؛
- مسیرهای Privileged Operator/Debug که می‌توانند در Runtime قابلیت تزریق کنند.

در صورت امکان Ingress و Worker از Identityهای مستقل و Least-Privilege استفاده کنند. Harness باید واقعاً از زیرساخت مالی جدا باشد، نه اینکه صرفاً دستور «فراخوانی نکن» داشته باشد. هر تلاش ممنوع، کشف Secret، Route غیرمنتظره یا Drift مجوز، Stop بحرانی است. Command مالی آینده مرز مجوزدهی و طراحی مستقل دارد و خارج از این Proof است.

## ۷. چالش پوشش Caseهای A4 و موارد تکمیلی

۴۷ شناسه اصلی A4 ثابت می‌مانند و ساختار یک ردیف برای هر شناسه در A7 حفظ می‌شود. Subcaseهای زیر باید اضافه شوند؛ این موارد به معنی اجرای تست نیستند:

| Subcase پیشنهادی | والد | Interleaving / چالش | Assertion لازم |
|---|---|---|---|
| A8-DUR-05a | A4-DUR-05 | Lease منقضی می‌شود؛ Worker قدیمی پیش از Claim جدید Completion می‌زند. | خود انقضا Completion را نامعتبر می‌کند؛ صفر تغییر در رکورد محافظت‌شده. |
| A8-DUR-05b | A4-DUR-05 | Heartbeat با انقضا و Claim Worker دوم رقابت می‌کند. | دقیقاً یک برنده سریال‌شده؛ تمدید مجدد Lease پس از انقضا ممنوع. |
| A8-DUR-05c | A4-DUR-05 | Worker قدیمی پس از افزایش Generation و Restart فرایند Completion می‌زند. | Generation قدیمی همچنان Fence می‌شود؛ State به عقب برنمی‌گردد. |
| A8-DUR-08a | A4-DUR-08 | Durable State بازیابی می‌شود درحالی‌که Worker/Process قدیمی زنده است. | Process قدیمی نمی‌تواند روی Identity بازیابی‌شده/استفاده‌مجددشده عمل کند؛ Generation/Token غیرقابل استفاده مجدد است. |
| A8-AUTH-06a | A4-AUTH-06 | Suspension/Revocation بین Lifecycle Read و Worker Transition Commit می‌شود. | Policy خطی‌شدن مصوب به‌صورت اتمیک/Version-conditioned اعمال می‌شود. |
| A8-DUR-02a | A4-DUR-02 | نتیجه Commit نامعلوم است، Primary در دسترس نیست و Replica قدیمی است. | پذیرش/عدم وجود کاذب استنتاج نمی‌شود؛ نتیجه Indeterminate است. |
| A8-FIN-01a | A4-FIN-01 | مسیر غیرمستقیم از Service Discovery، Workload Identity، Secret Mount یا Metadata Route امتحان می‌شود. | در Policy Layer مستقل Deny؛ بدون Credential/Call یا اثر مالی. |
| A8-DATA-04a | A4-DATA-04 | حذف/انقضای Evidence با Backup/Restore و Legal Hold متفاوت رقابت می‌کند. | نتیجه طبق Data Lifecycle Policy مصوب و با شواهد مستقل تعیین می‌شود. |

تعداد ۴۷ Case اصلی تغییر نمی‌کند. این Subcaseها باید پیش از پذیرش طراحی Runtime به Manifest در هر دو زبان افزوده شوند. این سند هیچ سقف عددی، مقدار Policy یا فناوری انتخاب نمی‌کند.

## ۸. تعیین تکلیف یافته‌ها و وابستگی تصمیم‌ها

| یافته | تصمیم/سند لازم | وضعیت |
|---|---|---|
| A8-F01 | ADR پروتکل Claim/Lease و قرارداد انتقال زمانی | باز |
| A8-F02 | ADR مرز اثر جانبی و Capability پایین‌دستی | باز |
| A8-F03 | Inventory قابلیت‌های عدم دسترسی مالی و تأیید Security/Finance | باز |
| A8-F04 | ADR خطی‌شدن چرخه عمر Installation/Tenant | باز |
| A8-F05 | Oracle Independence Register و تعیین بازبین | باز |
| A8-F06 | ADR چرخه عمر Claim Generation/Token | باز |
| A8-F07 | جدول تصمیم Reconciliation برای Commit نامعلوم | باز |
| A8-F08 | سیاست Provenance و Integrity شواهد | باز |
| A8-F09 | سیاست چرخه عمر داده، حذف، Backup و Legal Hold | باز |
| A8-F10 | کاتالوگ توسعه‌یافته Scheduleهای قطعی | باز |
| A8-F11 | سیاست اندازه‌گیری منابع/Fairness و Budget | باز |
| A8-F12 | رکورد بازبینی هم‌ارزی معنایی دوزبانه | باز |

F01 تا F10 در A7 با این خودبازبینی بسته نمی‌شوند. به‌ویژه A7-F01 فقط آماده بازبینی مستقل است؛ این سند آن بازبینی مستقل نیست. F02 تا F10 تا زمان تصمیم پاسخ‌گوی مشخص، ADR و Evidence باز می‌مانند. یافته‌های A8 افزوده‌اند و یافته‌های A7 را جایگزین یا شماره‌گذاری مجدد نمی‌کنند.

## ۹. وضعیت Gate و اجرا

- A4-GATE-01 تا A4-GATE-08: **تصویب نشده / اجرا مسدود است**.
- ۴۷ Case در A4: **NOT RUN**؛ موارد وابسته به Policy/ADR در A7 همچنان Blocked هستند.
- بازبینی A8: **خودبازبینی چالشی طراحی انجام شد؛ بازبینی مستقل در انتظار است**.
- پیاده‌سازی Runtime/Harness/Database/Queue/IAM: **مجوز ندارد**.
- Partner Adapter، Credential واقعی، Sandbox خارجی، Commission Logic، Financial Posting، Merge و Deploy: **مجوز ندارند**.
- فناوری، Quota عددی، مدت Retention و Vendor: **انتخاب نشده‌اند**.

## ۱۰. توالی الزامی بعدی

۱. بازبینی مستقل واقعی معماری/امنیت/QA از A4 تا A8 دریافت شود؛ هویت و نقش بازبین، تعارض منافع، دامنه، یافته‌ها و تعیین تکلیف ثبت شود.  
۲. A8-F01/F04/F06/F07 به‌عنوان یک پروتکل زمانی منسجم پیش از انتخاب جزئیات پیاده‌سازی حل شوند.  
۳. A8-F03 با حضور Finance/Security و Operations تکمیل شود؛ Denial قابلیت اثبات شود، نه فقط نبود Call مشاهده‌شده.  
۴. A8-F05/F08/F09 پیش از اتکا به Test Evidence تصویب شوند.  
۵. هشت Subcase جدید به A7 در هر دو زبان اضافه شوند؛ ۴۷ شناسه اصلی ثابت بمانند.  
۶. برای F02–F10 و یافته‌های A8، ADR و Decision Record با Owner پاسخ‌گو ایجاد شود.  
۷. بازبینی معنایی دوزبانه و CI اسناد/قرارداد روی Head نهایی تکرار شود.  
۸. تنها پس از تصویب صریح هر هشت Gate A4، مالک می‌تواند Proof Runtime مصنوعی و Disposable را مجاز کند.

## ۱۱. منابع

- نسخه پایدار OWASP ASVS 5.0.0: https://asvs.owasp.org/ و https://github.com/OWASP/ASVS/releases
- OWASP API Security Top 10 (2023): https://owasp.org/API-Security/
- NIST SP 800-204D، راهبردهای ادغام امنیت زنجیره تأمین نرم‌افزار در DevSecOps CI/CD: https://csrc.nist.gov/pubs/sp/800/204/d/final
- مستندات Transaction Isolation و Explicit Locking در PostgreSQL (صرفاً مرجع مفهومی؛ پایگاه داده‌ای انتخاب نشده): https://www.postgresql.org/docs/current/transaction-iso.html و https://www.postgresql.org/docs/current/explicit-locking.html
- AWS Prescriptive Guidance، الگوی Transactional Outbox (صرفاً مرجع الگو؛ Cloud/Provider انتخاب نشده): https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- Google SRE، Handling Overload (مرجع منابع و Fairness): https://sre.google/sre-book/handling-overload/

این منابع پرسش‌های بازبینی را هدایت می‌کنند؛ انطباق، انتخاب Vendor یا مجوز پیاده‌سازی را اثبات نمی‌کنند.
