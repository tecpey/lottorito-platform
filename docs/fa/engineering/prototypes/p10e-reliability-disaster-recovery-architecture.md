# P-10E — معماری قابلیت اطمینان، تاب‌آوری و بازیابی پس از بحران

**شناسه سند:** LOT-PROT-P10E-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیشنهاد طراحی مستقل از منبع؛ فاقد مجوز عملیات | **بازبینی:** ۲۰۲۶-۱۱-۲۶

## ۱. هدف و مرز اطمینان

این سند چارچوبی مستقل از منبع برای قابلیت اطمینان و بازیابی پس از بحران (DR) در پلتفرم چندمستاجری آینده Lottorito تعریف می‌کند: تداوم کسب‌وکار، دوام داده، Backup/Restore، بازیابی نقطه‌ای، Failover، بازیابی مختص Tenant، بازیابی Queue/Event، وابستگی‌های رمزنگاری، آمادگی عملیاتی و شواهد.

این سند ممیزی پیاده‌سازی، Runbook اجرایی Production، تعهد سطح سرویس یا مجوز دسترسی/تغییر محیط زنده نیست. هیچ توپولوژی Production، فهرست Backup، تنظیم PostgreSQL/Redis، Broker صف، Object Store، KMS، مانیتورینگ، قرارداد Provider، Region یا توافق عملیاتی بررسی نشده است. هیچ Backup زنده، Restore، Failover، تمرین DR، Migration یا داده Production دسترسی نشده است. همه هدف‌ها تا تکمیل BIA، Inventory منبع و بازبینی Ownerها تصویب‌نشده باقی می‌مانند.

این سند همراه P-10C (معماری مهاجرت مستقل از منبع) و P-10D (امنیت، جداسازی Tenant و حاکمیت) خوانده شود. این سند جایگزین Invariantهای ثبت مالی نیست و مجوز بازنویسی تاریخچه Ledger محسوب نمی‌شود.

## ۲. اهداف بازیابی تحت مالکیت کسب‌وکار

### ۲.۱ تعریف RTO و RPO

RTO بیشینه زمان سپری‌شده موردتأیید برای بازگرداندن سرویس مشخص به حداقل وضعیت عملیاتی توافق‌شده است. RPO بیشینه عمر داده قابل‌بازیابی در Recovery Point اعلام‌شده است. مرز اندازه‌گیری، رویداد شروع/پایان، منبع ساعت، وابستگی‌های مشمول و دامنه هدف (Tenant، محصول، Region یا کل پلتفرم) باید صریح باشد.

برای هر قابلیت، Ownerهای پاسخ‌گوی محصول، مالی، امنیت، Privacy/حقوقی و عملیات باید بیشینه اختلال و فقدان داده قابل‌تحمل، رکوردهای غیرقابل‌بازسازی، وابستگی خارجی، ترتیب بازیابی، حداقل حالت عملیاتی، روش جایگزین دستی، مرجع تصمیم و شواهد پذیرش را ارزیابی کنند.

RTO/RPO تصمیم کسب‌وکارند که با توان فنی اثبات‌شده و هزینه محدود می‌شوند. از Default ارائه‌دهنده کپی نکنید و هدف دلخواه نسازید. بازگشت سرویس را از تخلیه Backlog، تکمیل Reconciliation و بازگشت به عملیات عادی جدا کنید.

### ۲.۲ دفتر ثبت هدف مختص دامنه

تمام مقادیر زیر **TBD / تصویب‌نشده** هستند. جدول قالب تصمیم‌گیری است، نه پیشنهاد عددی.

| دامنه | اولویت Integrity | RPO | RTO | شواهد پذیرش |
|---|---|---|---|---|
| Ledger و Journal مالی | حیاتی؛ بدون فقدان خاموش یا بازنویسی | TBD | TBD | بازیابی سازگار DB، توازن Journal، شناسه یکتای Effect و تطبیق |
| Wallet/Payment Orchestration و دستور پرداخت | حیاتی؛ State Transition باید تطبیق شود | TBD | TBD | Ledger + شواهد Provider + Idempotency؛ بدون حرکت تکراری وجه |
| Attribution و Commission | بالا؛ بازسازی قابل توضیح | TBD | TBD | رویداد منبع، نسخه Policy، Posting تغییرناپذیر و تطبیق دوره |
| Identity، Tenant و Authorization Control Plane | وابستگی امنیتی حیاتی | TBD | TBD | عضویت، Role، دسترسی Key، Revocation و تست مرز Tenant |
| Provider/Webhook Inbox و Outbox | بالا؛ Replay بدون اثر تکراری | TBD | TBD | Event Identity، ترتیب، منشأ Signature و سازگاری Inbox/Outbox |
| Live Chat و Notification | وابسته به محصول؛ تحمل فقدان پیام TBD | TBD | TBD | دوام پیام، وضعیت تحویل Provider و Replay مختص Tenant |
| Analytics، Search و گزارش مشتق‌شده | فقط با اثبات Lineage قابل بازسازی | TBD | TBD | بازسازی از منبع مرجع؛ اعتبارسنجی تازگی و فیلتر Tenant |
| محتوای ایستا و مستندات | اهمیت عملیاتی پایین‌تر؛ Integrity الزامی | TBD | TBD | Source نسخه‌بندی‌شده، Checksum و اعتبارسنجی انتشار |

هر دامنه ممکن است هدف‌های جدا برای دسترس‌پذیری Read-only، Write، مهلت Settlement، تخلیه Backlog و بازیابی کامل داشته باشد.

## ۳. مرجعیت داده و طبقه‌بندی قابلیت بازیابی

هر Store، Dataset، Keyspace، Queue و Bucket در یکی از این گروه‌ها طبقه‌بندی شود:
۱. **System of Record:** وضعیت کسب‌وکار مرجع؛ فقدان آن نیازمند بازیابی رسمی و تطبیق است.
۲. **Durable Event/Evidence:** رویداد منبع، Inbox/Outbox، شواهد Provider یا Audit لازم برای بازسازی/توضیح وضعیت.
۳. **Projection قابل‌بازسازی:** Cache، Search Index، Aggregate تحلیلی یا Materialized View؛ قابلیت بازسازی باید از ورودی مرجع نگهداری‌شده اثبات شود.
۴. **Ephemeral State:** Session، Presence، Rate Limit یا Coordination موقت؛ سیاست ممکن است Reset یا احراز هویت مجدد باشد.
۵. **External Authority:** شواهد Provider/بانک/پرداخت/Identity که بازیابی آن به Export، API و دسترسی قراردادی طرف خارجی وابسته است.

Redis، BullMQ، Object Storage، پیام Chat یا Database را صرفاً به دلیل نام فناوری قابل‌دورریختن فرض نکنید. Queue حاوی تنها نسخه یک رویداد قابل‌دورریختن نیست. Cache حاوی تنها نسخه یک تصمیم کسب‌وکار نشانه نقص معماری است.

برای هر Dataset، Owner، Scope مربوط به Tenant/Product، مرجع حقیقت، طبقه‌بندی، Retention، وابستگی Encryption/Key، روش Backup، گروه سازگاری، ترتیب Restore، کنترل Integrity، منبع Rebuild و RPO/RTO مصوب ثبت شود.

## ۴. حفاظت Backup

برای هر کلاس داده و Store سیاستی تعریف شود: نوع و زمان‌بندی Backup؛ Retention و Legal Hold؛ Encryption در انتقال/حالت سکون؛ Custody کلید و نگهداری نسخه تاریخی؛ Failure Domain/Account/Credential مستقل؛ نسخه Immutable یا Object-Locked در صورت توجیه؛ Catalog/Manifest، هویت Source، Timestamp، Version، Checksum، Size و وضعیت تکمیل؛ Alert برای Backup ازدست‌رفته، دیرهنگام، ناقص، خراب یا غیرقابل‌دسترسی؛ و وابستگی‌های Restore.

الگوی 3-2-1 را محرک طراحی بدانید، نه اثبات استقلال. استقلال مدیریتی، Credential، Region، شبکه و Key را بررسی کنید. Replica و Snapshot زیر یک Account آلوده، حفاظت مستقل نیستند. Identity معمول Application، Tenant و Operator روزمره نباید بتواند Backup را حذف کند. در صورت امکان ایجاد Backup، مدیریت Retention، تأیید Restore و بازبینی Evidence تفکیک شوند. Credentialهای Backup در اختیار Workloadهای Application یا CI غیرقابل‌اعتماد قرار نگیرند.

### ۴.۱ کاندید PostgreSQL

اگر PostgreSQL به‌عنوان Store مرجع تأیید شد، Base Backup به‌همراه آرشیو پیوسته WAL و PITR متناسب با Version و مدل میزبانی ارزیابی شود. زنجیره کامل و مرتب WAL از Base Backup منتخب نگهداری و تکمیل Archive و فایل‌های Timeline/History لازم بررسی شود. Archive Lag، قدیمی‌ترین نقطه قابل‌بازیابی، سن Backup، خطای Archive، ظرفیت Storage و مدت Restore پایش شوند.

Base Backup بدون تمام WALهای لازم، مجموعه کامل PITR نیست. موفقیت فرمان Backup اثبات قابلیت Restore نیست. چند مجموعه معتبر نگهداری شود. Restore در Instance/Data Directory جدید و ایزوله انجام شود، نه روی تنها Source باقی‌مانده. Recovery Target و Timeline آگاهانه انتخاب شوند؛ PITR تاریخچه جدیدی ایجاد می‌کند. Role، Extension، Locale/Collation، Tablespace، Configuration، Replication Slot، Secret، Encryption و سازگاری Application جداگانه اعتبارسنجی شوند. بازیابی DB به‌طور خودکار Object خارجی، Queue، KMS یا تراکنش Provider را بازیابی نمی‌کند.

### ۴.۲ Redis و Queue

اگر Redis استفاده می‌شود، هر Logical Database/Keyspace به‌عنوان مرجع، Coordination بادوام، پشتوانه Queue یا Cache قابل‌بازسازی طبقه‌بندی شود. RDB، AOF، سیاست fsync، Replication و Backup مستقل متناسب با تحمل واقعی فقدان داده ارزیابی شوند. Replica دسترس‌پذیری را بهبود می‌دهد، اما در برابر حذف منطقی، خرابی، Write مخرب یا Credential افشاشده جای Backup را نمی‌گیرد. فایل Persistence در مقصد ایزوله Restore و اعتبارسنجی شود.

برای BullMQ یا Queue دیگر، Persistence Broker، توپولوژی Queue/Consumer، Jobهای Delayed/Scheduled/Repeatable، Active/Locked، Stalled Recovery، Retry/Backoff، Dead-letter، Retention و Graceful Shutdown مستند شوند. Event Identity و Idempotency Key حفظ شوند. Backup صف جایگزین Event Journal مرجع یا Transactional Outbox نیست. فقط از Source اثبات‌شده، با Replay محدود و حفاظت از اثر تکراری، Re-enqueue انجام شود.

### ۴.۳ Object Storage و کلیدها

Object، Metadata، Lifecycle Rule و Deletion Marker نسخه‌بندی و محافظت شوند. Checksum پس از انتقال و Restore بررسی شود. Referenceهای Application و Metadata مالکیت Tenant حفظ شوند. Access Policy جداگانه Backup شود؛ Object بازیابی‌شده با Metadata مجوز اشتباه می‌تواند داده Tenant دیگر را افشا کند.

وابستگی KMS/HSM و بازیابی نسخه تاریخی Key ثبت شود. Ciphertext بدون Decryption Key، Wrapping Key، Policy، Identity یا Region لازم بی‌استفاده است. بازیابی Key کنترل جداگانه و آزموده‌شده با Dual Control و Audit است. کلید Plaintext را کنار Backup قرار ندهید.

## ۵. سازگاری بین‌سیستمی و بازیابی مالی

Snapshotهای مستقل در زمان‌های متفاوت لزوماً یک نقطه کسب‌وکار سازگار نیستند. Consistency Group و پروتکل بازیابی برای Database/WAL مرجع، Inbox/Outbox و شواهد Provider، Redis/Queue و Worker Lease، Object Storage و Metadata، Identity/Authorization/Secret/Key و شواهد Provider/Payment تعریف شود.

بازسازی Component موقت/مشتق‌شده از رکورد مرجع بادوام فقط در صورت اثبات ترجیح داده شود؛ در غیر این صورت در Consistency Group حفاظت‌شده قرار گیرد. Recovery Manifest مقاوم در برابر دستکاری شامل Snapshot ID، هویت Source/Target، Timestamp/Timezone، LSN/Timeline در صورت کاربرد، نسخه Object، Queue Offset/ID، نسخه Key، نسخه Software/Configuration و Checksum نگهداری شود.

برای Workflow مالی:
۱. Writerها و Side Effect خارجی متوقف یا ایزوله شوند.
۲. آخرین مرز Durable Event/Ledger پذیرفته‌شده مشخص شود.
۳. در محیط جدید و ایزوله Restore انجام شود.
۴. توازن Journal، شناسه یکتای Effect، ردیابی Source-to-Ledger و جمع دوره بررسی شود.
۵. شواهد Provider/Bank و Outcomeهای Pending/Unknown تطبیق شوند.
۶. فقط رویداد مجاز با Idempotency Key پایدار و ترتیب صریح Replay شود.
۷. Worker قدیمی و Region قبلی از Write منع شوند.
۸. پیش از ازسرگیری Write، تأیید مستقل Finance و Operations اخذ شود.

نبود ACK محلی به‌معنای شکست Payment نیست. پیش از Retry یک Side Effect خارجی که ممکن است تکمیل شده باشد، با Provider استعلام/تطبیق شود. ادعای Exactly-once نکنید؛ پردازش At-least-once با Effectهای Idempotent و Reconciliation قابل ممیزی طراحی شود.

## ۶. Failover، Split-brain و Fencing

تشخیص خرابی، مرجع تصمیم، معیار Promotion، Quorum، آستانه Replication Lag و Failback امن تعریف شوند. Failover خودکار برای Write مالی لزوماً ایمن نیست. پیش از Promotion Writer جدید، Writer قبلی از Client، Worker، Scheduler و Provider Callbackها Fence شود. Epoch/Term/Lease Fencing یا سازوکار معادل متصل به وضعیت مرجع مانع Commit/Publish توسط Process قدیمی پس از Promotion شود.

رفتار از دست رفتن Database Primary، Redis/Cluster، Crash Worker و تحویل تکراری، Stalled Lock، Partition شبکه/Region، اختلال Identity/Secrets/KMS، Timeout Provider با Outcome نامعلوم Payment، نفوذ Storage/Account و Ransomware مستند شود.

حالت Degraded می‌تواند ابتدا Read-only را بازگرداند، اما نباید Ledger، Authorization، Tenant Isolation، Audit یا Approval را دور بزند. اگر Quorum یا مالکیت Writer نامطمئن است، عملیات مالی برگشت‌ناپذیر Fail-closed شود. Failback یک Migration کنترل‌شده است: Writeهای واگرا تطبیق، یک Writer مرجع تثبیت، Replicaها Seed مجدد، Lag/Consistency بررسی و Writer قبلی بازنشسته شود.

## ۷. Tenant Restore و کنترل Blast Radius

بازیابی Tenant در Database مشترک، Workflow استخراج پرریسک است، نه Restore مستقیم روی Production. Recovery Point در محیط موقت و ایزوله Restore و سپس با Procedure نسخه‌بندی‌شده و Tenant-aware به مقصد پاک استخراج شود.

هویت/مالکیت Tenant از شواهد مرجع تأیید شود؛ از shared، null یا Legacy مبهم استنتاج نشود. Referenceهای Cross-tenant، رکوردهای Shared/Global و وابستگی Product/Legal Entity شناسایی شوند. Referential Integrity، Event Lineage، Invariantهای Ledger و Audit حفظ شوند. از کپی داده، Secret، Token، Key یا داده شخصی Tenant دیگر جلوگیری شود. ID فقط با Mapping قطعی و بازبینی‌شده Remap و Collision بررسی شود. Authorization و Retention جاری دوباره اعمال شوند. جمع‌ها و Referenceهای استخراج‌شده با Source Restore تطبیق و در صورت لزوم تأیید مستقل Data Owner، Security/Privacy و Finance اخذ شود. Manifest شامل Recovery Point، نسخه کد Extraction، Scope، Checksum و تأییدکنندگان نگهداری شود.

اگر Extraction امن اثبات‌پذیر نیست، کل محیط ایزوله Restore و Quarantine شود. Snapshot مشترک هرگز برای تعمیر یک Tenant روی Production زنده Restore نشود.

## ۸. Runbook و توالی بازیابی

Runbook نسخه‌بندی‌شده شامل Prerequisite، مرجع تصمیم، فرمان‌های اعتبارسنجی‌شده مختص Source، خروجی موردانتظار، Stop Condition، معیار Abort/Rollback و محل Evidence باشد. این معماری هیچ فرمان عمومی یا مجوز اجرای Production ارائه نمی‌کند.

توالی پیشنهادی:
۱. اعلام Incident، شدت، Incident Commander و هدف بازیابی.
۲. حفظ Evidence و ایزوله‌کردن Writer آلوده/متعارض.
۳. ایجاد محیط Recovery پاک، مرز شبکه و Identity معتبر.
۴. بازیابی دسترسی Secret/KMS با Dual Control.
۵. Restore دیتابیس مرجع و WAL لازم تا Recovery Point مصوب.
۶. Restore/Verify اشیای بادوام و شواهد خارجی.
۷. Restore یا Rebuild صف/Redis طبق طبقه‌بندی.
۸. اعتبارسنجی Identity، Tenant Scope، RLS، Grant و Audit.
۹. کنترل Integrity مالی، Event، Referential و Cross-tenant.
۱۰. تطبیق Provider/Payment و قرنطینه وضعیت Unknown.
۱۱. تأیید بازگشایی محدود Read-only یا Write کنترل‌شده.
۱۲. تخلیه/Replay Backlog با Concurrency محدود و Idempotency.
۱۳. پایش SLO، Lag، خطا، رویداد تکراری/ردشده و Deltaهای Reconciliation.
۱۴. بستن Incident پس از پذیرش Owner و ثبت Evidence.

برای Incident Response، Cyber Recovery، Database PITR، Region Failover، Tenant Restore و Routine Backup Restore، Playbook جدا نگهداری شود. بازیابی Ransomware به Clean-room، Recovery Point سالم پیش از Compromise، چرخش Credential آلوده، حفظ شواهد Forensic و اعتبارسنجی Artifact پیش از اتصال مجدد نیاز دارد.

## ۹. SLO، Observability و ظرفیت

SLI از Outcome قابل‌مشاهده برای کاربر استخراج شود، نه فقط سلامت Process. شاخص‌های کاندید: موفقیت Read/Write مجاز در Journey حیاتی؛ موفقیت Posting Ledger و نقض Invariant؛ پذیرش Provider Callback، رد Duplicate/Replay و سن Reconciliation؛ قدیمی‌ترین پیام Queue، Backlog، Retry/DLQ و Stalled Job؛ دسترس‌پذیری DB، اشباع Connection، Replication/WAL Lag و فضای Storage؛ تازگی Backup و سن آخرین Restore تأییدشده؛ موفقیت دریافت KMS/Secret و Denialهای Authorization؛ و وضعیت Persistence/Delivery پیام Chat در صورت کاربرد.

برای هر SLI صورت/مخرج، Exclusion، Window تجمیع، تفکیک Tenant، آستانه Alert، Owner و Data Source تعریف شود. SLO فقط پس از Baseline اندازه‌گیری و بازبینی Product Owner تصویب شود. Error Budget می‌تواند سیاست Release را هدایت کند، اما توجیه تضعیف صحت مالی، امنیت، Privacy یا کنترل حقوقی نیست.

Capacity Planning شامل Throughput بازیابی، WAL Replay، پهنای باند Object، نرخ Replay صف، Rebuild Index، Connection Storm، Cache Warm-up و Rate Limit Provider باشد. طرح فراتر از پهنای باند، Storage، Quota یا محدودیت Provider قابل‌اجرا نیست. Recovery در محیط ایزوله Load Test شود و Production از Replay Storm محافظت گردد.

## ۱۰. تمرین DR و شواهد پذیرش

تست بازیابی باید زمان‌بندی‌شده، دارای Scope، مجوز و سابقه باشد. با Tabletop و Restore ایزوله شروع شود؛ سپس فقط با پیش‌نیاز و تأیید به Component Failure، شبیه‌سازی Region و Failover کنترل‌شده برسد. این سند مجوز Failover مخرب یا Production نیست.

سناریو/فرض، Scope، Recovery Point دقیق، تأییدها، شرکت‌کنندگان، RTO/RPO اندازه‌گیری‌شده و روش، نتایج Integrity/مالی/Tenant/Security، وابستگی مفقود، دسترسی Key، Logهای Restore، انحراف، ریسک باقیمانده، Owner/موعد اصلاح، Retest و پذیرش رسمی ثبت شوند.

تست فقط در صورت صحت داده، نبود افشای Cross-tenant غیرمجاز، نبود Effect مالی تکراری/حذف‌شده، تحقق هدف یا Exception رسمی، Evidence کامل و امضای Owner موفق است. «سرویس بالا آمد» یا «Job بکاپ سبز شد» به‌تنهایی معیار پذیرش نیست.

تناوب تمرین مبتنی بر ریسک و مصوب Owner باشد. محرک برنامه‌ریزی: مانیتورینگ پیوسته Backup/Lag؛ Restore Sampling تکرارشونده؛ تمرین کامل Recovery حداقل سالانه و پس از تغییر معماری مهم؛ تمرین پرتکرارتر مسیر مالی حیاتی در صورت توجیه. این موارد تعهد مصوب نیستند.

## ۱۱. حاکمیت و کنترل تغییر

Owner پاسخ‌گوی نام‌دار برای Service، Data، Tenant، Finance، Security، Privacy/Legal، Platform/DBA، Backup، KMS، Provider، Incident Command و Release تعیین شود. اختیار اعلام Disaster، انتخاب Recovery Point، Promotion Writer، پذیرش Data Loss، ازسرگیری Payment، تصویب Tenant Extraction و بستن Incident مشخص شود. برای اقدام مالی، Key و Cross-tenant با اثر بالا Dual Control اعمال شود.

هر Exception نیازمند Scope، دلیل، کنترل جبرانی، Risk Owner، انقضا، تاریخ بازبینی و Evidence است. پس از تغییر Schema/Store/Provider/Key/Tenant/Region یا Incident و تغییر مهم Workload، Recovery Plan بازبینی شود.

## ۱۲. معیارهای پذیرش و اقلام تحویل

P-10E فقط زمانی برای برنامه‌ریزی پیاده‌سازی مختص Source آماده است که:
۱. BIA و دفتر RTO/RPO هر دامنه تأیید Owner نام‌دار داشته باشد.
۲. هر Dataset/Store مرجعیت و طبقه‌بندی قابلیت بازیابی داشته باشد.
۳. سیاست Backup، Retention، Isolation، Encryption، Key و Integrity تعریف شده باشد.
۴. PITR و کامل‌بودن WAL در صورت کاربرد قابل‌اندازه‌گیری باشد.
۵. معنای بازیابی Queue، Redis، Object و Provider مستند باشد.
۶. Consistency Group و Recovery Manifest تعریف شده باشد.
۷. Writer Fencing، Failover/Failback و Outcome نامعلوم Payment مشخص باشد.
۸. Tenant Restore طراحی Extraction ایزوله و تست منفی داشته باشد.
۹. Runbook، حق تصمیم، ارتباطات و Clean-room Owner داشته باشد.
۱۰. تمرین Restore/DR، Integrity، Tenant Isolation و اهداف اندازه‌گیری‌شده را اثبات کند.
۱۱. SLI/SLO، Alert، Capacity و Error Budget تصویب شده باشد.
۱۲. Finance، Security، Privacy/Legal، Product و Operations تأیید کنند.

خروجی‌ها: BIA؛ دفتر RTO/RPO؛ Inventory مرجعیت/قابلیت بازیابی؛ ماتریس Backup/Retention؛ برنامه بازیابی Key؛ نقشه Consistency Group؛ Schema مربوط به Recovery Manifest؛ رویه Restore PostgreSQL/Redis/Queue/Object؛ ADR مربوط به Failover/Fencing؛ رویه Tenant Restore؛ Incident/DR Runbook؛ کاتالوگ SLI/SLO؛ تقویم تمرین؛ Evidence و Exception Register؛ تأییدها.

## ۱۳. موارد خارج از دامنه و وضعیت فعلی

این سند Hosting، Region، Vendor Backup، توپولوژی، Version PostgreSQL/Redis، Provider صف، KMS/HSM یا هدف SLO انتخاب نمی‌کند. وجود، کامل‌بودن، Immutable بودن یا قابلیت Restore بکاپ را ادعا نمی‌کند. RTO/RPO را Certification نمی‌کند، Restore/Failover انجام نمی‌دهد، Production را بررسی نمی‌کند، بازیابی مالی را تصویب نمی‌کند و مجوز Migration/Tenant Extraction نمی‌دهد.

P-10B پروتکل Inventory منبعِ اجرا‌نشده است؛ P-10C چارچوب مهاجرت مستقل از منبع؛ P-10D طراحی امنیت/حاکمیت مستقل از منبع؛ و P-10E فقط خط مبنای طراحی Reliability/DR مستقل از منبع است.

## ۱۴. منابع پژوهشی

- PostgreSQL 18، Continuous Archiving و PITR: https://www.postgresql.org/docs/current/continuous-archiving.html
- PostgreSQL Backup و Restore: https://www.postgresql.org/docs/current/backup.html
- Redis Open Source Persistence: https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/
- BullMQ Idempotent Jobs: https://docs.bullmq.io/patterns/idempotent-jobs
- BullMQ Going to Production: https://docs.bullmq.io/guide/going-to-production
- BullMQ Graceful Shutdown: https://docs.bullmq.io/guide/workers/graceful-shutdown
- Google Cloud Well-Architected، تست بازیابی از فقدان داده (بازبینی ۲۰۲۶-۱۰-۲۷): https://docs.cloud.google.com/architecture/framework/reliability/perform-testing-for-data-loss
- AWS Well-Architected Reliability Pillar: https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/
- Google SRE Workbook، Error Budget Policy: https://sre.google/workbook/error-budget-policy/
- NIST SP 800-34 Rev. 1، راهنمای برنامه‌ریزی اقتضایی: https://csrc.nist.gov/pubs/sp/800/34/r1/upd1/final

این منابع صرفاً مبنای طراحی‌اند؛ پیاده‌سازی Lottorito، شمول حقوقی، آمادگی Production یا انتخاب Vendor را اثبات نمی‌کنند.
