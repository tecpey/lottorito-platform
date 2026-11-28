# G09-A20 — نظام اخذ شواهد و طراحی احراز صلاحیت خصمانه

**شناسه سند:** LOT-AFFILIATE-G09-A20-001  
**نسخه:** 1.0.0 | **وضعیت:** صرفاً تحقیق و طراحی آزمون پیشنهادی  
**تاریخ:** ۲۰۲۶-۱۱-۲۸

## ۱. هدف و حدود اختیار

این پرونده، محدودیت‌های C-01 تا C-16 و Gateهای سخت G1 تا G9 در G09-A19 را به (الف) فرایند قابل ممیزی اخذ Evidence و (ب) طراحی آزمون خصمانه مستقل از Candidate تبدیل می‌کند.

هیچ Provider، حوزه قضایی، Region، Database، Edition، Topology، سرویس Key، Retention، RPO/RTO، Budget یا مدل عملیاتی انتخاب نمی‌شود. ADR-002 تصویب نمی‌شود، یافته‌های A11 بسته نمی‌شوند، جای بازبینی مستقل A12 را نمی‌گیرد و اجرای Harness مرحله R2 یا Proof تولیدی R3 را مجاز نمی‌کند. تحلیل مدل، Assurance مستقل انسانی نیست.

## ۲. خط مبنا و وضعیت شواهد

ورودی‌ها: G09-A17 (تحقیق OD-01 تا OD-12)، G09-A18 (ارزیابی خانواده Candidateها)، G09-A19 (C-01 تا C-16، Data-flow Inventory و G1 تا G9)، ADR-002 (جفت اتمیک پیشنهادی InboxReceipt + WorkItem و Reconciliation برای Commit با نتیجه UNKNOWN)، A11 (هشت یافته باز)، A12 (بازبینی مستقل انجام‌نشده/غیرقابل ارزیابی).

وضعیت‌ها:
- MISSING: هیچ Evidence ارائه نشده است.
- UNVERIFIED: Evidence موجود اما اعتبارسنجی نشده است.
- CONTRADICTED: تعارض با منبع معتبر یا رفتار مشاهده‌شده.
- EXPIRED: انقضای اعتبار یا وقوع محرک بازاعتبارسنجی.
- ACCEPTED: مرجع پاسخ‌گوی نام‌برده، آن را برای دامنه/تاریخ مشخص پذیرفته است.
- NOT APPLICABLE: عدم شمول مکتوب و پذیرفته‌شده توسط مرجع پاسخ‌گو.
- PASS / FAIL / INCONCLUSIVE: نتیجه آزمون مشخص و بازتولیدپذیر؛ نبود شکست PASS نیست.

اظهار Vendor، Benchmark بازاریابی، ایمیل فروش، دیاگرام معماری، گزارش SOC، نشان Certification یا CI موفق، به‌تنهایی رفتار سرتاسری Lottorito را اثبات نمی‌کند.

## ۳. ماتریس اخذ شواهد

برای هر مورد ثبت شود: شناسه Evidence؛ پرسش دقیق؛ صادرکننده معتبر؛ Artifact/نسخه/تاریخ؛ دامنه (شخصیت حقوقی، محصول، Edition، Region، سرویس، کلاس داده)؛ مرجع کنترل‌شده؛ Hash یکپارچگی؛ طبقه‌بندی؛ بازبین؛ تأییدکننده پاسخ‌گو؛ انقضا/محرک بازاعتبارسنجی؛ وضعیت؛ Gate مرتبط و استثناها.

| شناسه | Evidence لازم | صادرکننده / راستی‌آزما | مانع قطعی |
|---|---|---|---|
| C-01 | سند ثبت، طرف قرارداد، Service Order، شرایط حاکم و زنجیره Subcontractor | مالک + مشاور حقوقی واجد صلاحیت | ابهام در طرف یا زنجیره قرارداد |
| C-02 | هویت و محل استقرار مشتری/اپراتور؛ مجوز در صورت لزوم؛ نقشه مکتوب حوزه قضایی | مشتری/اپراتور + حقوقی | اپراتور مسئول یا حوزه قضایی نامعلوم |
| C-03 | Inventory/طبقه‌بندی داده؛ نقش Controller/Processor؛ تعیین داده خاص و سوابق مالی | مالک حریم خصوصی + حقوقی | طبقه داده یا نقش ناقص |
| C-04 | دسترس‌پذیری Region/SKU دقیق؛ تعهد قراردادی Residency؛ نقشه انتقال و انتقال بعدی | قرارداد Provider + حقوقی | مکان/انتقال لازم پشتیبانی نشود |
| C-05 | مکان Storage، Replica، Support، Telemetry، Control Plane و Subprocessor؛ مسیر دسترسی ممتاز | Provider + امنیت | مکان یا مسیر دسترسی تأییدنشده |
| C-06 | Retention به تفکیک رکورد؛ انقضای Backup/Log؛ انتشار حذف؛ تعامل Legal Hold و Restore | حریم خصوصی/حقوقی + مالک سوابق | معنای حذف یا Hold نامعلوم/متعارض |
| C-07 | محصول/Region مربوط به KMS/HSM؛ مالک Key، Rotation، Revocation، Recovery، تفکیک وظایف و دسترسی Provider | مالک امنیت/رمزنگاری + Provider | مرجعیت یا بازیابی Key اثبات‌ناپذیر |
| C-08 | نقشه سرویس کسب‌وکار، SLO وابستگی‌ها، شرایط نگهداری/پشتیبانی و فرض Failure Domain | مالک سرویس + عملیات | نبود مالک کسب‌وکار یا مدل وابستگی |
| C-09 | BIA مصوب، اثر اختلال در طول زمان، حد تحمل فقدان داده/وقفه، طبقه بازیابی و مرز اندازه‌گیری | مالک کسب‌وکار + تداوم | RPO/RTO حدسی، تصویب‌نشده یا تعریف‌نشده |
| C-10 | جغرافیای کاربر/شریک، مسیر بحرانی، الزام Consistency، توپولوژی اندازه‌گیری‌شده و بودجه Latency | محصول/مهندسی + عملیات | ناتوانی در تحقق بودجه مصوب |
| C-11 | نرخ Event، توزیع Tenant، اندازه Payload، هم‌زمانی، Burst/Replay، رشد Retention و Headroom | محصول/مهندسی + مالک داده | پروفایل بار به‌طور مؤثر ناقص |
| C-12 | نقش‌های On-call، مهارت، Runbook، اختیار Incident، پوشش پشتیبانی و Drill بازیابی | مالک عملیات | نبود تیم بهره‌برداری/بازیابی |
| C-13 | ماتریس Feature دقیق سرویس/SKU/Edition/Region، Quota، SLA، Maintenance، Support، Subprocessor و استثناها | Provider + تدارکات/امنیت | رفتار لازم صرفاً فرض یا وعده فروش |
| C-14 | هزینه چرخه عمر: Compute، Replica، Storage، Backup، Egress، KMS، Observability، Support، DR، مالیات و خروج | مالی/تدارکات | هزینه ناقص یا بیش از سقف مصوب |
| C-15 | قالب/کامل‌بودن/Consistency خروجی، Restore جایگزین، دسترسی Key، زمان Migration، اثبات حذف و هزینه خروج | معماری + Provider + حقوقی | بازیابی داده/Key یا خروج غیرعملی |
| C-16 | Audit Catalogue، Export تغییرناپذیر، Retention، Timestamp معتبر، انتساب Actor، بازرسی مستقل و همکاری Incident | امنیت/ممیزی + Provider | Evidence لازم جمع‌آوری/بازرسی‌پذیر نباشد |

### ۳.۱ کنترل کیفیت Evidence

۱. قرارداد الزام‌آور، مستندات رسمی SKU دقیق، گزارش Assurance مستقل و آزمون بازتولیدپذیر تحت کنترل مشتری را ترجیح دهید؛ فقط برای پرسشی که آن منبع صلاحیت پاسخ‌گویی به آن را دارد.  
۲. ادعای عمومی Provider را از رفتار Product/Edition/Release/Region/Topology/Configuration دقیق جدا کنید.  
۳. استثناهای سرویس را ثبت کنید؛ وجود Region، دسترس‌پذیری همه سرویس‌های وابسته را اثبات نمی‌کند.  
۴. Snapshot کنترل‌شده و Hash منبع را نگه دارید؛ URL تغییرپذیر است.  
۵. Certification/Report فقط Evidence با دامنه مشخص است، نه اثبات Application یا انطباق حقوقی.  
۶. هنگام تمدید، تغییر Product/Edition/Region/Subprocessor/Control Plane، Incident مهم، کلاس داده جدید، تغییر قانون یا انقضا، بازاعتبارسنجی کنید.  
۷. اگر Evidence محرمانه است، بررسی مستقل واجد صلاحیت را درخواست کنید؛ در غیر این صورت UNVERIFIED ثبت شود، نه PASS.

## ۴. Inventory کامل جریان داده و مکان

داده، Metadata، Credential و سیگنال کنترلی را دنبال کنید، نه فقط Database اصلی. برای هر مؤلفه، کلاس داده، دامنه Tenant، مسیر Read/Write، مکان مبدأ/مقصد، حوزه قضایی، رمزنگاری، مالک Key، Replica/Cache، Backup/Retention/Deletion، دسترسی Support، Subprocessor، Audit و وابستگی بازیابی ثبت شود.

مؤلفه‌های الزامی:
- Edge: DNS، CDN، WAF، Gateway، Ingress و Edge Log.
- Application/API Worker، Background Worker، Scheduler و Admin/Control Plane.
- Database اصلی، Replica، WAL/Transaction Log، CDC و Schema Registry.
- InboxReceipt، WorkItem، DeliveryOutbox و Broker/Queue.
- Cache، Lock، Lease، Coordination و Authority/Fencing.
- Object Storage، Backup، Snapshot، PITR/WAL Archive و Restore Staging.
- KMS/HSM، Secrets Manager، Certificate و Identity Provider.
- Metrics، Traces، Logs، Crash Dump، Profiling و Alert Payload.
- CI/CD، Build Artifact، Package Registry، IaC State و Deployment Metadata.
- Support Ticket/Attachment، بسته پشتیبانی Provider و Break-glass.
- Analytics، Export، Warehouse، Search Index و Downstream Consumer.

**آزمون کامل‌بودن:** یک Event ID ساختگی و یک Tenant ID ساختگی را در تمام مؤلفه‌ها، از جمله Log، Backup، Support و Restore ردیابی کنید. هر نسخه، مکان، Principal یا مسیر Retention توضیح‌نداده‌شده مانع احراز صلاحیت است.

## ۵. ناورداهای مستقل از Candidate و Oracleهای مستقل

همه Adapterهای Candidate باید ناورداهای یکسان را با سازوکار اختصاصی محصول اثبات کنند.

- I-01: پاسخ موفق فقط پس از Commit جفت پایدار InboxReceipt + WorkItem تحت Policy دوام مصوب.
- I-02: دقیقاً یک جفت برای هر Source Identity مصوب؛ یکتایی/کاردینالیتی در مرجع Persistence، نه فقط Application.
- I-03: Identity و Payload معنایی یکسان، WorkItem یا اثر اقتصادی دوم نسازد.
- I-04: Identity یکسان با Fingerprint معنایی متفاوت رد/Quarantine شود؛ Duplicate بی‌ضرر تلقی نشود.
- I-05: UNKNOWN نه موفقیت فرض شود نه شکست؛ Reconciliation مرجع با Transaction اولیه در حال اجرا ایمن رقابت کند.
- I-06: Primary/Worker/Lease Holder/Authority Epoch/محیط Restoreشده فاقد Authority نتواند State محافظت‌شده را تغییر دهد.
- I-07: Tenant از Installation Context مورد اعتماد بیاید؛ Payload نتواند مرز Tenant را عبور کند.
- I-08: Restore/PITR، Tombstone منقضی، Credential/Authority لغوشده یا Identity اقتصادی مصرف‌شده را خاموش احیا نکند.
- I-09: هویت Ingress/Worker به قابلیت Posting مالی دسترسی نداشته باشد؛ آزمون Ingress صفر بودن اثر مالی را Assert کند.
- I-10: Audit/Evidence قابل انتساب، دارای زمان معتبر، Integrity-protected و برای بازسازی تصمیم کافی باشد.

خانواده Oracle مستقل:
- Database: Read مرجع، Constraint یکتایی/کاردینالیتی، Transaction History و Metadata سازگاری.
- Protocol: Request/Response ثبت‌شده و Event Identity/Fingerprint با Parser مستقل.
- Authority: Epoch/Term/Fencing و رد Actor قدیمی در لحظه Mutation.
- Financial Non-effect: Query مستقل Ledger/Journal و بررسی Privilege؛ بدون تغییر Balance/Journal.
- Tenant: Query منفی بین Tenantها و Authorization Trace.
- Recovery: داده Restoreشده، Checkpoint مبدأ/مقصد، موقعیت WAL/CDC/Replication و گزارش Reconciliation.
- Evidence: Hash Artifact خام، زمان معتبر، Runner Identity و Manifest تغییرناپذیر.

کد Application تحت آزمون نباید تنها Oracle صحت خودش باشد.

## ۶. فهرست احراز صلاحیت خصمانه

این موارد طراحی شده‌اند و NOT RUN هستند. پیش از Adapter کردن، Product/Version/Edition/Region/Topology/Configuration و Client/Driver دقیق را Pin کنید. اگر وقوع Fault اثبات نشود یا Oracle نتواند Historyها را تفکیک کند، نتیجه INCONCLUSIVE است.

| شناسه | سناریو و محرک | شرط PASS لازم |
|---|---|---|
| A20-01 | Partition کردن Primary قدیمی از Quorum/Authority در حالی که برخی Clientها متصل‌اند | حداکثر یک Authority Commit کند؛ Primary قدیمی Fenced باشد |
| A20-02 | اتصال مجدد Primary جداشده با State قدیمی | Primary سابق بدون Reconciliation ایمن Write/Authority نگیرد |
| A20-03 | حذف رأی‌دهندگان/Failure Domain تا ازدست‌رفتن Quorum | Write محافظت‌شده Fail-closed؛ بدون پذیرش محلی ناایمن |
| A20-04 | Ack جفت و خرابی فوری Node/Domain فعال | جفت Ackشده در محدوده RPO مصوب باقی بماند |
| A20-05 | حذف Response سمت Client پس از Commit سمت Server | UNKNOWN؛ Reconciliation مرجع یک جفت؛ Retry بدون Duplicate |
| A20-06 | توقف Commit اولیه و رقابت Retry/Negative Read | تا امکان Linearize شدن Commit، عدم وجود نتیجه‌گیری نشود؛ دقیقاً یک جفت نهایی |
| A20-07 | آزادسازی هم‌زمان درخواست‌های Identity یکسان از چند Node | دقیقاً یک جفت؛ نتیجه Duplicate/In-progress مستند برای بازنده |
| A20-08 | Identity یکسان با Payload معنایی متفاوت به‌صورت هم‌زمان | تعارض رد/Quarantine؛ بدون Overwrite خاموش |
| A20-09 | Epoch قدیمی/بازگشت‌یافته یا Replay Token قدیمی | Fencing در لحظه Mutation؛ Epoch عقب‌گرد/تکرار نکند |
| A20-10 | انقضای Lease، Reclaim با Generation جدید و ادامه Worker قدیمی | Generation قدیمی نه State محافظت‌شده و نه Side Effect خارجی را Commit کند |
| A20-11 | Duplicate/Delay/Reorder/Redelivery پیام Outbox | Idempotency مصرف‌کننده؛ قرارداد ترتیب صریح؛ اتمیک‌بودن مبدأ حفظ شود |
| A20-12 | قطعی Broker، انباشت Backlog و Replay Storm | عدم فقدان/تکثیر Work پایدار؛ منابع محدود و زمان‌بندی منصفانه |
| A20-13 | خرابی Backup، حذف Log Segment لازم یا تغییر Manifest | Integrity/Recovery با Fail-closed شکست بخورد؛ Restore سالم کاذب نباشد |
| A20-14 | PITR قبل/بعد Event پذیرفته‌شده ساختگی | نقطه Restore صریح؛ بدون Replay تکراری یا احیای Tombstone |
| A20-15 | Restore در دو سوی تغییر Schema/Config/Registry/Key/Credential | سازگاری اثبات یا Restore تا Migration/Reconciliation متوقف شود |
| A20-16 | جداسازی Region اصلی و اجرای DR از پیش مجازشده | RPO/RTO مصوب اندازه‌گیری؛ Single Writer؛ حفظ Residency/Key |
| A20-17 | Failback پس از Write در DR | بدون Dual Writer؛ رفع واگرایی صریح؛ عدم فقدان Work تأییدشده |
| A20-18 | Rotation/Revocation/Denial/Recovery کلید در آزمون کنترل‌شده | رفتار Availability/Confidentiality مصوب؛ Decrypt غیرمجاز رد شود |
| A20-19 | ID بین Tenantها و Principal کم‌اختیار Operator تسخیرشده | بدون Read/Write/Disclosure بین Tenant؛ Break-glass محدود و قابل انتساب |
| A20-20 | ردیابی Marker ساختگی در Log/Trace/Backup/Support/Analytics | همه مکان‌ها با Inventory پذیرفته‌شده منطبق؛ مقصد ناشناخته مردود |
| A20-21 | انقضای رکورد، Restore Backup قدیمی و Replay پس از مرز Retention | چرخه عمر مصوب؛ بدون اثر اقتصادی تکراری یا احیای خاموش Identity |
| A20-22 | Rolling Upgrade، ناسازگاری Client، Downgrade یا Migration قطع‌شده | حفظ ناوردا؛ مسدودسازی Downgrade پشتیبانی‌نشده؛ Recovery مستند |
| A20-23 | Payload بزرگ، Tenant داغ، Retry Amplification و فشار Storage | Quota/Backpressure صریح؛ بدون Starvation فراتر از حد مصوب |
| A20-24 | انحراف ساعت، توقف Time Sync و تأخیر Lock | صحت Authority/Lease متکی به فرض اثبات‌نشده ساعت دیواری نباشد |
| A20-25 | تلاش برای حذف Audit، تغییر Policy، حذف Backup یا دستکاری Evidence | تفکیک وظایف و Evidence غیرقابل‌تغییر/خارجی مانع یا آشکارکننده باشد |
| A20-26 | Restore ایزوله با Secret قدیمی شبیه Production | محیط Restoreشده به Production/Partner/Payment/Authority/Ledger وصل نشود |
| A20-27 | خرابی در مرز Posting جداگانه مجازشده و ساختگی | Journal تغییرناپذیر متوازن یا عدم Posting؛ بدون اثر اقتصادی نیمه‌کاره |
| A20-28 | بار Steady/Burst/Soak همراه خرابی‌های منتخب | صحت PASS بماند؛ Performance جداگانه با SLO مصوب سنجیده شود |

### ۶.۱ ملاحظات Adapter اختصاصی Candidate

- PostgreSQL HA: پیکربندی واقعی Standby همگام، Commit Mode، عضویت Quorum، Failover Controller/Fencing، پیوستگی WAL Archive، Timeline و Restore اثبات شود. synchronous_commit=on بدون Standby همگام پیکربندی‌شده، Ack راه دور را اثبات نمی‌کند. pg_verifybackup جای Restore ایزوله و Assertion دامنه را نمی‌گیرد.
- CockroachDB: Release، Locality/Lease/Replication، Retry و معنای Ambiguous Commit دقیق تثبیت شود. Retry سریال‌پذیر و Backup/Recovery با Driver دقیق آزموده شود. راهنمای عمومی Retry برای SQLSTATE، Idempotency اثر جانبی Application را اثبات نمی‌کند.
- YugabyteDB: Replication همگام Raft درون Universe از xCluster ناهمگام بین Universeها جدا شود. RF، Placement، Consistency، رفتار Conflict/DDL، مبدأ Backup و Restore پشتیبانی‌شده تثبیت شود. از Target ناهمگام، DR منطقه‌ای بدون اتلاف استنباط نشود.
- Spanner: Instance Configuration، محل Replica، Dialect، Backup/PITR، مدل Key و Client API دقیق شود. UNKNOWN مسیر Reconciliation است، نه Retry خودکار. Copy/Restore بین Region و Residency بررسی شود.

این‌ها تعهد آزمون‌اند، نه رأی مقایسه‌ای. مستندات محصول جای آزمون Candidate دقیق را نمی‌گیرد.

## ۷. ایمنی و Gateهای مجوز

پیش از اجرا:
۱. مالک، مرحله/محیط/بودجه/بازه زمانی مشخص را کتبی مجاز کند.  
۲. حقوقی/حریم خصوصی/امنیت داده ساختگی و تمام مکان‌های آزمون را تأیید کنند.  
۳. Gateهای مرتبط A4 صریحاً تصویب شوند.  
۴. دامنه Harness مرحله R2، Candidate دقیق و برنامه آزمون بازبینی شوند؛ داده واقعی مشتری/بازیکن/شریک و Credential تولیدی ممنوع است.  
۵. محیط آزمون هیچ Route یا Credential به Production، Partner، Payment، Wallet، Payout یا Ledger زنده نداشته باشد.  
۶. Fault Injection دارای Kill Switch، محدودیت Blast Radius، Rollback و Operator مشخص باشد.  
۷. Evidence پیش از محرک فعال؛ Clock/Time Source ثبت شود.  
۸. بازبین مستقل پیش از Run، Oracle و نتیجه مورد انتظار را تأیید کند.

توقف فوری: داده/Credential واقعی؛ Side Effect خارجی؛ افشای بین Tenant؛ تغییر مالی؛ دو Authority فعال؛ فقدان Write تأییدشده و تطبیق‌نیافته؛ دستکاری Evidence؛ اتمام کنترل‌نشده منابع؛ یا نقض مرز آزمون.

موفقیت آزمون ساختگی ایزوله، Production را مجاز نمی‌کند. R3 به تصمیم جداگانه مالک و تأییدهای حقوقی/امنیتی/عملیاتی نیاز دارد.

## ۸. Manifest بازتولیدپذیری

هر Run باید حفظ کند:
- Run/Case ID، ترتیب، شروع/پایان UTC و شاهد Time Source معتبر؛
- مجوز مالک، مرحله مصوب، Operator و بازبین مستقل نام‌برده؛
- Product/Edition/Release/Region/Topology و Hash خروجی Configuration؛
- Digestهای IaC، Application، Schema، Driver، Client و Harness؛
- نسخه Generator، Seed، Tenant/Event ID و Hash Payload ساختگی؛
- سازوکار Fault، Schedule، هدف، زمان و اثبات وقوع Fault؛
- History مورد انتظار، Assertionها، Queryهای Oracle مستقل و خروجی خام؛
- Log/Trace/Metric، موقعیت Replication، Backup ID و Recovery Checkpoint؛
- PASS/FAIL/INCONCLUSIVE، انحراف‌ها، Parser و Variance/Confidence در صورت لزوم؛
- اثبات Cleanup/Deletion و Artifactهای باقی‌مانده؛
- Disposition بازبین، استثناها، امضا و تاریخ بازاعتبارسنجی.

Secret یا داده شخصی خام در Evidence Bundle قرار نگیرد. Redaction باید معنای Forensic را حفظ کند؛ اصل محافظت‌شده فقط با کنترل دسترسی و Retention مصوب نگهداری شود.

## ۹. روش تصمیم‌گیری غیرقابل‌جبران با امتیاز

احراز صلاحیت ترتیبی است:
۱. Admissibility: پذیرش محدودیت‌های حقوقی، Residency، Data-flow، قرارداد و امنیت.  
۲. Correctness: اثبات I-01 تا I-10 روی Candidate دقیق.  
۳. Recovery: نمایش Backup، PITR، Failover، Failback و بازیابی Key در اهداف مصوب.  
۴. Operability: Runbook دارای نیروی مسئول، Monitoring، Escalation و Drill تکرارشده.  
۵. Performance/Economics: فقط پس از عبور از Gate سخت؛ Workload هم‌ارز و گزارش جداگانه Distribution، Tail Latency، Error Rate، Backlog، Recovery Time، Cost و عدم‌قطعیت.

FAIL یا INCONCLUSIVE در Gate اجباری، Qualification را متوقف می‌کند. امتیاز وزنی شکست حقوقی، امنیتی، دوام، اتمیک‌بودن یا بازیابی را جبران نمی‌کند. پیش از پذیرش C-01 تا C-16 و Freeze مجموعه مقایسه دقیق، Candidateها رتبه‌بندی نشوند.

Decision Record: هویت Candidate؛ دامنه/استثنا؛ فهرست و Hash شواهد؛ نتیجه Gateها؛ ریسک و نظر مخالف؛ هزینه/خروج؛ تأییدکنندگان؛ اعتبار؛ محرک بازاعتبارسنجی؛ تصمیم صریح انتخاب/رد/تعویق/عدم پذیرش.

## ۱۰. مبنای تحقیق و محدودیت‌ها

- NIST SP 800-34 Rev. 1: https://csrc.nist.gov/pubs/sp/800/34/r1/upd1/final
- PostgreSQL Backup/Restore: https://www.postgresql.org/docs/current/backup.html
- PostgreSQL Continuous Archiving/PITR/Timeline: https://www.postgresql.org/docs/current/continuous-archiving.html
- PostgreSQL محدودیت‌های pg_verifybackup: https://www.postgresql.org/docs/current/app-pgverifybackup.html
- PostgreSQL Synchronous Replication/Standby: https://www.postgresql.org/docs/current/warm-standby.html
- CockroachDB Transaction/Retry: https://www.cockroachlabs.com/docs/stable/developer-basics.html
- YugabyteDB Backup/Restore/PITR: https://docs.yugabyte.com/stable/manage/backup-restore/
- YugabyteDB xCluster ناهمگام: https://docs.yugabyte.com/stable/explore/going-beyond-sql/asynchronous-replication-ysql/
- YugabyteDB Replication: https://docs.yugabyte.com/stable/architecture/docdb-replication/
- Spanner UNKNOWN Commit: https://docs.cloud.google.com/spanner/docs/reference/rest/v1/projects.instances.databases.sessions/commit
- Spanner Backup Copy/Restore: https://docs.cloud.google.com/spanner/docs/backup
- Spanner PITR: https://docs.cloud.google.com/spanner/docs/pitr

راهنمای NIST از چرخه BIA، راهبرد بازیابی، تمرین و نگهداری پشتیبانی می‌کند؛ اهداف Lottorito را تعیین نمی‌کند. PostgreSQL میان Integrity بکاپ و Restore موفق و صحت داده Application تمایز می‌گذارد. محصولات توزیع‌شده در رفتار همگام/ناهمگام، Retry، UNKNOWN و Backup تفاوت دارند. مستند رسمی، پیکربندی دقیق Lottorito، پذیرش حقوقی، صلاحیت Operator یا ناورداهای Application را اثبات نمی‌کند.

## ۱۱. وضعیت فعلی

- G09-A20: PROPOSED؛ صرفاً تحقیق/طراحی آزمون.
- C-01 تا C-16: OPEN؛ این سند Evidence مالک را جمع‌آوری/پذیرفته نمی‌کند.
- Data-flow Inventory: الزامی؛ کامل‌بودن اثبات نشده.
- A20-01 تا A20-28: DESIGNED / NOT RUN.
- Candidateها: UNSELECTED / NOT QUALIFIED.
- G1 تا G9: NOT TESTED / NOT PASSED.
- ADR-002: PROPOSED؛ OD-01 تا OD-12 باز.
- A11-F01 تا F08 باز؛ A12 مستقل انجام‌نشده/غیرقابل ارزیابی.
- R0 مسدود؛ R1 صرفاً تحقیق؛ R2 شروع‌نشده؛ R3 غیرمجاز.
- Gateهای A4 تصویب‌نشده.
- هیچ Runtime/Harness، انتخاب Provider، اتصال Partner، عملیات مالی، Merge یا Deploy مجاز نیست.

**نتیجه:** این پرونده روش اخذ Evidence و ابطال ایمن ادعاهای Candidate را تعریف می‌کند؛ عبور هیچ Candidateای از آزمون را ادعا نمی‌کند.
