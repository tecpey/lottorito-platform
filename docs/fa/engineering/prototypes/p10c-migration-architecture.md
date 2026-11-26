# P-10C — معماری مهاجرت مرحله‌ای و چارچوب تصمیم همزیستی داده

**شناسه سند:** LOT-PROT-P10C-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیشنهاد معماری مستقل از منبع؛ هیچ مبدأ یا مقصدی تصویب نشده است | **بازبینی:** ۲۰۲۶-۱۱-۲۶

## ۱. هدف و مرز مجوز

P-10C روش طراحی مهاجرت امن و مرحله‌ای را پس از تکمیل Inventory دارای تأیید مالک در P-10B تعریف می‌کند. این سند عمداً مستقل از منبع است: هیچ Schema عملیاتی، حجم داده، توپولوژی Engine، الگوی ترافیک، مدل سازگاری، RPO/RTO، شخصیت حقوقی، سیاست حسابداری یا استقرار مقصد راستی‌آزمایی نشده است. این سند هیچ فناوری مهاجرتی را انتخاب نمی‌کند، تاریخ Cutover تعیین نمی‌کند، Dual-write را مجاز نمی‌کند و مجوز دسترسی به منبع، DDL، DML، Backfill، Replication، ثبت مالی، Merge یا Deploy نمی‌دهد.

برنامه مختص منبع به این ورودی‌ها نیاز دارد: (۱) Source Register، Snapshot متادیتا و Lineage بازبینی‌شده P-10B؛ (۲) داوری مالک درباره Tenant، Product و شخصیت حقوقی؛ (۳) نسخه Engine، Schema، Role، RLS، Writer/Reader، Job و وابستگی‌های مبدأ/مقصد؛ (۴) طبقه‌بندی داده، حوزه قضایی، Retention و مجوز انتقال؛ (۵) حجم، نرخ نوشتن، بار اوج و ظرفیت اندازه‌گیری‌شده؛ (۶) الزامات سازگاری، Downtime، RPO/RTO و بستن دوره مالی مصوب کسب‌وکار؛ و (۷) مالک منبع، DBA، مالک دامنه، بازبین امنیت/حریم خصوصی، تأییدکننده Finance و مرجع Cutover با نام مشخص. ورودی ناقص Blocker است، نه فرضی برای پرکردن با Default.

## ۲. ناورداهای غیرقابل مذاکره

- **در هر لحظه فقط یک Writer مرجع برای هر Aggregate.** دو مرجع مستقل و قابل‌نوشتن برای یک Aggregate مالی/کسب‌وکاری ایجاد نشود.
- **Dual-write کور ممنوع است.** نوشتن دیتابیس و ارسال مستقل Broker/API اتمیک نیست. Transactional Outbox در همان تراکنش دیتابیس یا CDC پشتیبانی‌شده از منبع با مدل Offset/Replay مستند ترجیح دارد. Dual-write فقط وقتی قابل‌قبول است که Atomicity و بازیابی شکست در سیستم‌های واقعی اثبات شده باشد.
- **Expand پیش از Contract.** ساختار سازگار اضافه شود؛ Reader/Writerهایی منتشر شوند که هر دو نمایش را تحمل کنند؛ Backfill و Validation انجام شود؛ مرجعیت پس از Gate تغییر کند؛ ساختار قدیمی فقط پس از پایان وابستگی Rollback و Retention حذف شود.
- **Backfill باید قطعی، Idempotent، قابل‌ادامه، محدود و قابل‌پایش باشد.** هر Chunk به Scope/Cursor پایدار، Checkpoint، نوشتن امن در Retry، Rate Limit، Metric و پروتکل توقف/ادامه نیاز دارد.
- **هویت Tenant، Product و شخصیت حقوقی صریح است.** انتساب مفقود را حدس نزنید یا Default نکنید. مقدار Legacy یعنی shared، Product یا Tenant Canonical نیست.
- **تاریخچه مالی تغییرناپذیر است.** Journal ثبت‌شده بازنویسی نشود و از Aggregate تاریخچه تراکنش جعل نشود. اصلاحات به Reversal/Compensating Entry تأییدشده نیاز دارند. ارزها بی‌صدا تبدیل نشوند.
- **Reconciliation پیش‌شرط انتقال مرجعیت است.** Count کافی نیست؛ هویت، رابطه، وضعیت، جمع دقیق هر ارز و Lineage از منبع تا Ledger بررسی شود.
- **Rollback به وضعیت وابسته است.** پیش از Write مقصد، بازگشت به مبدأ ممکن است امن باشد. پس از مرجع‌شدن مقصد و پذیرش Write، تغییر Pointer می‌تواند داده را گم یا دوشاخه کند. Forward-fix، Reverse-delta/CDC یا Restore/Replay باید تمرین شود؛ بدون اثبات، وعده Rollback ندهید.
- **شواهد بازتولیدپذیر و حداقلی باشند.** نسخه Query/Code، Manifest، Count، Checksum و ارجاع مجوز ثبت شود. PII خام، Credential و Payload مشتری/بازیکن/پرداخت وارد Git، CI یا Chat نشود.

## ۳. الگوهای مهاجرت کاندید (نه انتخاب فناوری)

| الگو | تناسب | ریسک و شواهد لازم |
|---|---|---|
| Snapshot آفلاین و Cutover در پنجره نگهداری | منبع کوچک/کم‌تغییر و Downtime قابل‌قبول | Snapshot سازگار، Delta کامل یا Freeze نوشتن، تمرین Restore و مدت قطعی اندازه‌گیری‌شده |
| Expand و Backfill محدود در Application | همزیستی نسخه قدیم/جدید برنامه در یک دیتابیس تراکنشی ممکن باشد | سازگاری نسخه مختلط، Lock Chunk، Idempotency و بازنشستگی Client قدیمی |
| Snapshot به‌همراه CDC/Logical Replication | حجم زیاد یا Downtime کم و Log Capture قابل‌اعتماد در منبع | هماهنگی DDL، Replica Identity، وضعیت Sequence، نگهداری WAL/Slot، Lag، Conflict، Failover و LSN دقیق Cutover |
| مهاجرت تدریجی دامنه‌به‌دامنه | Bounded Context با مالکیت روشن و قابلیت انتقال مستقل | Reference بین دامنه‌ای، API/Event Contract، همزیستی موقت و Reconciliation |
| ETL/Import دسته‌ای | تبدیل تاریخچه یا مقصد تحلیلی غیرعملیاتی | Lineage تبدیل، تغییرات دیررس، Deduplication، حریم خصوصی و تکرارپذیری |

صرف PostgreSQL بودن هر دو Endpoint دلیل انتخاب Logical Replication نیست. این قابلیت DDL را تکثیر نمی‌کند؛ وضعیت Sequence نیازمند رسیدگی جداگانه است؛ Large Objectها و بعضی انواع Relation محدودیت دارند. هماهنگی Schema و همگام‌سازی Sequence باید صریح باشد. پیش از انتخاب، محدودیت‌های رسمی نسخه دقیق مبدأ/مقصد بررسی شود.

**رویکرد پیش‌فرض برنامه‌ریزی:** برنامه محدود و دامنه‌به‌دامنه با توالی Expand/Backfill/Validate/Cutover/Contract ترجیح دارد. CDC فقط وقتی انتخاب شود که حجم و نیاز Downtime اندازه‌گیری‌شده پیچیدگی آن را توجیه کند و توپولوژی منبع پشتیبانش باشد. اگر مسیر تدریجی امن وجود ندارد، مهاجرت در پنجره نگهداری کنترل‌شده انتخاب شود؛ آن را Zero-downtime ننامید.

## ۴. Mapping مبدأ به مقصد و قرارداد همزیستی

برای هر خانواده Object مشخص کنید: Object و Bounded Context مالک مبدأ/مقصد؛ Writer مرجع در هر فاز؛ Source Key، Target Key، Natural Key و Scope یکتایی؛ قواعد استخراج Tenant/Product/شخصیت حقوقی/Currency همراه شواهد؛ تبدیل Field، معنای Null، Precision/Scale، Timezone و Enum؛ ترتیب Parent/Child و رفتار Delete؛ هویت Event/Economic-effect/Idempotency و Trace Link؛ طبقه PII، هدف، Retention، Masking و انتشار Delete؛ موارد رد/ابهام، دلیل Quarantine و مالک داوری انسانی.

Mapping برای رکورد پذیرفته‌شده باید کامل و برای رکورد مستثنا/قرنطینه‌شده صریحاً Partial باشد. Enum ناشناخته، Currency غایب، Tenant/Product Null یا shared مبهم بی‌صدا نگاشت نشود. هیچ Defaultی نباید هویت مفقود را به affiliate_agent، lottery یا Scope پلتفرم تبدیل کند.

برای هر دامنه و فاز، یک مرجع Write و Read مجاز تعریف شود. Facade مسیریاب باید Idempotency را enforce و Source Identity را حفظ کند. رفتار Read-after-write و تحمل Stale Read مستند شود. Cache، Search، Analytics، Export، Job زمان‌بندی‌شده، Webhook، Worker و عملیات دستی نیز بخشی از سطح مهاجرت‌اند، نه فقط دیتابیس اصلی.

## ۵. قرارداد مهندسی Backfill

برنامه مختص منبع باید این موارد را تعریف کند:

۱. **Eligibility:** فقط رکوردهای داخل Scope، داوری‌شده توسط مالک، با هویت لازم کامل و Parent معتبر.
۲. **Partitioning قطعی:** بازه Primary Key پایدار یا Cursor تغییرناپذیر؛ از Offset Pagination روی Dataset متغیر پرهیز شود.
۳. **اندازه Chunk:** بر اساس Lock Duration، اندازه تراکنش، اثر WAL/Replication، I/O و Lag Replica اندازه‌گیری شود؛ نه تعداد دلخواه Row.
۴. **Idempotency:** کلید قطعی مانند (migration_id, source_id, source_pk) با Unique Constraint در مقصد. کلید و Payload Canonical یکسان Retry امن است؛ همان کلید با Payload متفاوت Conflict سخت است.
۵. **Checkpoint:** بازه تکمیل‌شده و مرز Snapshot/LSN ثبت شود؛ Checkpoint فقط پس از Commit مقصد ثبت گردد.
۶. **Concurrency:** Worker محدود، Partition بر اساس Tenant/Product فقط در صورت ایمنی، بدون Fan-out نامحدود؛ ترتیب FK رعایت و رقابت Hot-key کنترل شود.
۷. **Rate Control:** در آستانه‌های مصوب DBA برای Lock Wait، عمر تراکنش، رشد WAL، Lag، CPU/I/O، نرخ خطا یا افت SLO، Pause/Throttle انجام شود.
۸. **Failure Handling:** رکورد نامعتبر با ارجاع غیرحساس Quarantine شود؛ بی‌صدا Skip نشود؛ Retry محدود با Exponential Backoff و Jitter انجام شود.
۹. **Repeatability:** اجرای مجدد Chunk تکمیل‌شده نباید Business Identity تکراری، اثر مالی جدید یا تغییر تاریخچه Immutable ایجاد کند.
۱۰. **Audit:** Migration ID، Digest کد/تنظیمات، Snapshot/LSN مبدأ، Range، Count، Checksum، زمان، Actor، نتیجه و تعداد Exception ثبت شود.

اگر Update/Delete می‌تواند پشت High-water Mark رخ دهد، High-water Mark به‌تنهایی کافی نیست. Snapshot سازگار به‌همراه Change Stream ثبت‌شده یا Write Freeze/Delta Window مستند انتخاب شود. معنای Delete/Tombstone لحاظ شود تا رکورد حذف‌شده دوباره زنده نشود.

## ۶. تطبیق مالی و هویتی

مهاجرت مالی Workstream کنترلی جداست، نه کپی معمول Table.

- در صورت ایمنی، Journal ID اصلی، Source Reference، Currency، دقت Integer Minor Unit مصوب، زمان Posting، دوره حسابداری، نگاشت حساب و Lineage Audit تغییرناپذیر حفظ شود.
- Debit و Credit برای هر Currency، شخصیت حقوقی، Tenant، Product، کلاس حساب و دوره حسابداری مستقل تطبیق داده شوند. ارزهای متفاوت با هم Net نشوند.
- Source Event به Economic Effect و Journal ثبت‌شده تطبیق داده شود. Delivery ID، Webhook ID، Request Idempotency Key و Economic-effect Identity متمایزند.
- وضعیت Posted، Pending، Held، Reversed، Disputed، Voided و Quarantined جداگانه مقایسه شود. زنجیره Reversal بررسی و از ثبت دوباره Pending جلوگیری شود.
- NGR، درآمد واجد شرایط، کمیسیون، استحقاق Agent، مالیات، FX یا تعهد پرداخت از نام Field استنباط نشود؛ قواعد دامنه/حسابداری و شواهد منبع لازم است.
- اگر تاریخچه ناقص است Journal تاریخی جعل نشود. Opening Balance یا Migration Adjustment فقط با تأیید Finance، شواهد مبدأ، ثبت متوازن، تعیین دوره و Migration Reference قابل‌ردیابی مجاز است.
- فعالیت مالی هم‌زمان در Reconciliation نهایی Freeze یا صریحاً لحاظ شود. هر اختلاف توضیح‌نداده‌شده Cutover را متوقف می‌کند.

حداقل شواهد: Count به تفکیک Scope؛ جمع دقیق Debit/Credit هر ارز؛ پوشش Source-to-effect و effect-to-journal؛ تعداد هویت تکراری/مفقود؛ Orphan/Quarantine؛ توزیع وضعیت؛ پیوند Reversal؛ Control Total قبل/بعد؛ تعیین تکلیف Exceptionها با بازبین مستقل. برابری Count یا Aggregate، مالکیت و حسابداری صحیح را اثبات نمی‌کند.

## ۷. ماشین وضعیت Cutover

| فاز | مرجع مبدأ | مرجع مقصد | Gate خروج |
|---|---|---|---|
| C0 آماده‌سازی | مبدأ | هیچ‌کدام | Mapping، کنترل، Backup، Rehearsal و برنامه Abort/Forward-fix مصوب |
| C1 Expand | مبدأ | هیچ‌کدام | Schema افزایشی با نسخه‌های فعال برنامه مبدأ سازگار باشد |
| C2 Snapshot/Backfill | مبدأ | هیچ‌کدام | مرز Snapshot ثابت؛ Backfill کامل یا در Delta Window تعریف‌شده |
| C3 Catch-up | مبدأ | هیچ‌کدام | Lag در آستانه مصوب؛ بدون Apply Error حل‌نشده |
| C4 Validate | مبدأ | Shadow فقط‌خواندنی | Reconciliation، امنیت، Performance و تأیید کسب‌وکار موفق |
| C5 Freeze/Fence | مبدأ موقتاً متوقف | فقط‌خواندنی | Writer/Job/Webhookها Fence؛ Delta نهایی تخلیه؛ Writer قدیمی فعال نباشد |
| C6 Promote | مقصد | مقصد | تغییر اتمیک مرجعیت، آمادگی Sequence/Identity، Health Gate، Smoke و Ledger Check |
| C7 Observe | مقصد | مقصد | پایش و Reconciliation کسب‌وکار موفق؛ مبدأ فقط‌خواندنی بماند |
| C8 Contract | مقصد | مقصد | پایان پنجره Rollback؛ بازنشستگی Client/Job قدیمی؛ تأیید صریح پاک‌سازی مخرب |

Feature Flag یا تغییر DNS به‌تنهایی Fencing نیست. Writer Epoch/Lease قابل‌راستی‌آزمایی یا کنترل معادل لازم است تا Worker قدیمی و Instanceهای قبلی پس از Promotion نتوانند Write کنند. Checkpoint Cutover (LSN یا معادل)، High-water Mark مبدأ/مقصد، هویت Writer فعال و تأیید اپراتور ثبت شود.

## ۸. Rollback، Forward-fix و Recovery

- پیش از Write مقصد: فقط پس از اثبات کامل و مرجع‌بودن مبدأ، ترافیک به مبدأ برگردد.
- در Shadow Read: Shadow Read خاموش شود؛ مبدأ Writer باقی می‌ماند.
- در Freeze نهایی: Promotion لغو شود؛ نوشتن مبدأ فقط پس از اثبات نبود اثر Commitشده مختص مقصد فعال شود.
- پس از Write مقصد: کورکورانه برنگردید. Forward-fix روی مقصد ترجیح دارد؛ در غیر این صورت Reverse-delta/CDC تمرین‌شده با مدیریت Conflict یا Restore/Replay از نقطه بازیابی راستی‌آزمایی‌شده استفاده شود.
- اگر هر دو سیستم Write پذیرفته‌اند، هر دو Writer متوقف، Log/Snapshot حفظ، Worker قدیمی Fence و پیش از ادامه Reconciliation انجام شود. برای داده مالی یا مالکیت از Last-write-wins استفاده نشود.
- Contract/تغییر مخرب فقط پس از پایان پنجره Rollback و تأیید Artifact/Dependencyهای نگهداری‌شده انجام شود.

Backup تا زمانی که Restore، Integrity Check، بازیابی Application/Worker و Replay تمرین نشده باشد برنامه Rollback نیست. RPO/RTO بر اساس Business Impact Analysis مصوب تعیین شود؛ در این سند عدد هدف جعل نمی‌شود.

## ۹. کنترل‌های امنیت، حریم خصوصی و عملیات

هویت Migration اختصاصی، کم‌دسترسی و زمان‌دار و جدا از Application باشد. مالکیت Role و دورزدن RLS صریحاً بررسی شود. Scope Tenant/Product در مرز استخراج و نوشتن مقصد enforce شود؛ RLS دفاع در عمق است، نه جایگزین Scope صحیح. انتقال/نگهداری با سازوکار مصوب رمزنگاری شود؛ Secret یا Credential Verifier کپی نشود. Column و Retention حداقل و Manifest محدود خارج از Repository و CI Log نگهداری شود.

Lock Wait، تراکنش طولانی، Dead Tuple/Bloat، رشد WAL/Archive، Replication Slot، Lag Replica، فضای دیسک، CPU/I/O، نرخ خطا/Quarantine، Latency API و Backlog Worker پایش شوند. آستانه Abort و اختیار اپراتور نام‌برده پیش از اجرا تعیین شود. اختلاف مالی توضیح‌نداده‌شده، ابهام هویت، شگفتی Privilege/RLS، خطای Replication، Data Loss، بار غیرمنتظره یا فقدان شواهد موجب توقف است.

پیش از مهاجرت واقعی، Tenant Isolation، Authorization، Replay، Duplicate، شکست جزئی، Chunk قطع‌شده، Schema Skew، Worker قدیمی، Restore و Failover در محیط Disposable آزمایش شوند.

## ۱۰. سابقه تصمیم و اقلام تحویل

تصویب مختص منبع نیازمند این اقلام است: Migration Architecture ADR با مقایسه الگوهای ممکن؛ Source-to-target Mapping و ماتریس سازگاری؛ ماتریس مرجعیت Writer/Reader؛ Runbook Backfill با طراحی Chunk/Checkpoint/Idempotency و بودجه ظرفیت؛ مشخصات Reconciliation مالی و Exception Register مصوب؛ Runbookهای Cutover/Fencing/Abort/Forward-fix/Rollback/Restore؛ بازبینی امنیت/حریم خصوصی/حقوقی؛ نتایج Rehearsal اندازه‌گیری‌شده روی داده ساختگی نماینده یا داده Maskشده دارای مجوز؛ و تأیید مالک منبع/DBA، مالک دامنه، Security/Privacy، Finance و مرجع انتشار.

## ۱۱. معیارهای پذیرش

P-10C فقط وقتی برای برنامه‌ریزی پیاده‌سازی مختص منبع آماده است که Inventory در P-10B با مجوز اجرا و مستقلاً بازبینی شده باشد؛ هویت Tenant/Product/شخصیت حقوقی مهاجرتی با شواهد اثبات شود؛ موارد حل‌نشده حذف و قرنطینه باشند؛ یک مرجع Write برای هر دامنه تعریف شود؛ Backfill قطعی، محدود، قابل‌ادامه، Idempotent و قابل‌پایش بوده و Update/Delete/Replay را پوشش دهد؛ Reconciliation مالی برای هر ارز/دوره دقیق و بدون اختلاف توضیح‌نداده‌شده باشد؛ Fencing و Promotion/Abort/Forward-fix تمرین شده باشد؛ Restore الزامات RPO/RTO و Integrity مصوب را برآورده کند؛ و Security، Privacy، Legal، DBA، Finance و مالکان کسب‌وکار برنامه مشخص را تصویب کنند.

تا آن زمان P-10C چارچوب طراحی است؛ نه گواهی آمادگی Production و نه مجوز Migration.

## ۱۲. منابع پژوهشی

- AWS Prescriptive Guidance، راهبرد مهاجرت دیتابیس رابطه‌ای: https://docs.aws.amazon.com/prescriptive-guidance/latest/strategy-database-migration/
- AWS Prescriptive Guidance، الگوی Transactional Outbox: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- PostgreSQL، Logical Replication: https://www.postgresql.org/docs/current/logical-replication.html
- PostgreSQL، محدودیت‌های Logical Replication: https://www.postgresql.org/docs/current/logical-replication-restrictions.html
- PostgreSQL، Explicit Locking: https://www.postgresql.org/docs/current/explicit-locking.html
- PostgreSQL، CREATE INDEX: https://www.postgresql.org/docs/current/sql-createindex.html
- Google Cloud، آزمون بازیابی از شکست: https://docs.cloud.google.com/architecture/framework/reliability/perform-testing-for-recovery-from-failures
- NIST SP 800-207، Zero Trust Architecture: https://csrc.nist.gov/pubs/sp/800/207/final

این منابع مبنای طراحی‌اند؛ به‌معنای انتخاب Vendor، گواهی انطباق یا اعتبارسنجی محیط واقعی Lottorito نیستند.
