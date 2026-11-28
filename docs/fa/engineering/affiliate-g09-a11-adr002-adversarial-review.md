# Affiliate G09-A11 — بازبینی خصمانه طراحی ADR-002

**شناسه سند:** LOT-AFFILIATE-G09-A11-001  
**تصمیم مرتبط:** LOT-AFFILIATE-G09-ADR-002  
**نسخه:** ۰.۱.۰ | **تاریخ:** ۲۰۲۶-۱۱-۲۸  
**وضعیت:** بازبینی خصمانه در همان جریان تدوین — نه تأیید مستقل؛ بدون اجرای Runtime  
**سند بازبینی‌شده:** ADR-002 نسخه ۰.۱.۰ در Head مربوط به PR #76: 985cfee7ce233e6297b7de2d5d2339d8484b843e  
**دامنه:** پذیرش اتمیک Ingress، Commit نامعلوم، تطبیق معتبر، Failover و Retention هویت.

## ۱. نتیجه بازبینی

**بازبینی طراحی — شکاف‌های مهم؛ ADR-002 باید PROPOSED باقی بماند.**

ADR-002 به‌درستی UNKNOWN را وضعیت مستقل می‌داند، Retry کورکورانه و استنتاج نبود از Replica قدیمی را رد می‌کند و جفت الزامی InboxReceipt + WorkItem را از DeliveryOutbox اختیاری جدا نگه می‌دارد. بااین‌حال متن فعلی هنوز معنای Durability یک Commit تأییدشده در Failover، گذار مرجعیت و Fencing بین Primary قدیمی و Primary ارتقایافته، و Race میان Read منفی تطبیق و تراکنش درحال‌اجرا را کامل تعریف نکرده است. تضمین Idempotency نیز در حالی که Retention باز است، مرز زمانی صریح ندارد.

این بازبینی در همان جریان دستیار تدوین‌کننده ADR-002 انجام شده است؛ بنابراین **Self-review** است و تأیید بازبین مستقل محسوب نمی‌شود. بازبینی‌کننده‌ای که نویسنده ADR-002/A11 نبوده باید مستقلاً تمام یافته‌ها را بررسی و تعیین تکلیف کند.

هیچ Runtime، Database، Queue، Source Implementation، زیرساخت، IAM، Endpoint شریک یا Harness بررسی یا اجرا نشده است. یافته‌ها طراحی‌محورند و نقص تجربی در سامانه مستقر را ادعا نمی‌کنند.

## ۲. روش بازبینی

موارد زیر به چالش کشیده شدند: Commit تأییدشده در برابر Durability هنگام Crash/Failover؛ Epochهای مرجع Primary، جلوگیری از Split-brain و Fencing Primary قدیمی؛ Race بین Read منفی تطبیق و Commit درحال‌اجرا؛ Cardinality جفت و Invariantهای ارجاعی؛ معنای Conflict در Identity/Fingerprint؛ افق Deduplication، Retention و Replay پس از حذف؛ دامنه اثر Quarantine و امکان سوءاستفاده برای Denial-of-Service؛ و شواهد لازم برای اثبات هر ویژگی.

منابع رسمی جاری از جمله راهنمای Google Cloud Spanner درباره Unknown Commit و مستندات PostgreSQL درباره High Availability، Replication همگام/ناهمگام و Durability در WAL بررسی شدند. این منابع برای مقایسه‌اند، نه انتخاب فناوری.

## ۳. یافته‌ها

| شناسه | شدت | یافته | شرط بستن |
|---|---|---|---|
| A11-F01 | بحرانی | **«Commit تأییدشده» در Failover تعریف کافی ندارد.** ممکن است Primary یک Commit محلی پایدار را تأیید کند، درحالی‌که هنوز به Replicaای که بعداً Promote می‌شود نرسیده باشد. پس از Failover مرجع جدید ممکن است جفت را نداشته باشد. در نتیجه پذیرش تأییدشده ناپدید می‌شود و Retry می‌تواند WorkItem جدید بسازد. | کلاس دقیق Durability لازم پیش از پاسخ موفق، شامل پایداری محلی، تأیید Replication/Consensus، شرایط مجاز Failover و RPO مستند شود. اگر پذیرش تأییدشده باید در تمام Failoverهای مجاز باقی بماند، قرارداد Commit بدون اتلاف برای همان Failure Set لازم است. در غیر این صورت پنجره اتلاف پذیرفته‌شده صریح تعریف و ادعاهای پذیرش/اجرای پایین‌دستی با آن سازگار شوند. |
| A11-F02 | بحرانی | **گذار مرجعیت و Fencing در برابر Split-brain تعریف نشده است.** عبارت‌های Primary unavailable و authoritative read فرض می‌کنند فقط یک Writer معتبر وجود دارد. هنگام Promotion، Partition یا بازگشت دیرهنگام Primary قدیمی، ممکن است هر دو مرجع Write بپذیرند مگر مکانیزم Epoch/Fencing بیرونی مانع شود. Unique Constraint روی هر Writer جداگانه، یکتایی جهانی ایجاد نمی‌کند. | Epoch/Incarnation مرجعیتِ یکنواخت افزایشی و غیرقابل‌بازیافت یا Fencing معادل مبتنی بر Consensus تعریف شود. تمام Writeهای Ingress و تصمیم‌های Reconciliation به Epoch فعال متصل شوند. Promotion فقط پس از Termination یا Fencing شبکه‌ای/ذخیره‌سازی Primary قدیمی مجاز باشد. Primary قدیمی هنگام بازگشت تا Reconciliation و پذیرش مجدد صریح، Read-only/Quarantined بماند. نبود Write Authority هم‌پوشان اثبات شود. |
| A11-F03 | بحرانی | **Read منفی معتبر به‌تنهایی اثبات نمی‌کند که Commit قبلیِ درحال‌اجرا بعداً ظاهر نخواهد شد.** C11 پس از Read بدون جفت، ورود مجدد به عملیات اتمیک را مجاز می‌داند. استدلال ایمنی به Unique Arbitration روی همان مرجع فعال و Semantics مشاهده/Serialization تراکنش وابسته است. در Failover، Fencing مربوط به Epoch نیز لازم است. | عبارت «Read نبود جفت را اثبات کرد» با «در نقطه Consistency مستند، جفتی یافت نشد؛ نبود موقت است» جایگزین شود. Retry فقط از مسیر همان عملیات اتمیک با Unique Key روی Writer فعال و Fenced انجام شود. Primitive یکتایی/Serialization باید تمام Attemptهای زنده را داوری کند. اگر Attempt قدیمی هنوز بیرون از آن مرجع امکان Commit دارد، وضعیت UNKNOWN باقی بماند تا Resolve یا Fence شود. تست قطعی برای Commit دیرهنگام در برابر Retry، Abort در برابر Retry و Promotion حین Commit اضافه شود. |
| A11-F04 | زیاد | **Exactly-one pair منطقی بیان شده اما اجزای اعمال Cardinality کامل نیست.** تراکنش اتمیک به‌تنهایی جلوی چند WorkItem متصل به یک Receipt را نمی‌گیرد، اگر Persistence رابطه را یکتا نکند؛ همچنین Orphan Detection پس از Restore/Corruption تعریف نشده است. | Invariantهای مستقل Persistence الزام شوند: یکتایی Source Identity برای Receipt؛ یکتایی رابطه WorkItem به Receipt؛ Referential Integrity قابل‌اعمال یا معادل آن؛ تطابق Tenant/Installation در هر دو رکورد؛ و Query تطبیق برای شناسایی صفر، یک یا چند WorkItem مرتبط. Schema/Constraint فیزیکی برای ADR دیتابیس و Proof موتور واقعی باقی بماند. |
| A11-F05 | زیاد | **Conflict هویت به Fingerprint Profile تعریف‌نشده وابسته است.** «Binding/Fingerprint تغییرناپذیر یکسان» تا تعیین Canonicalization، Allowlist فیلدها، Versioning، رفتار Duplicate JSON Member، Semantics یونیکد/اعداد و تفاوت Payload خام و معنایی، قابل اجرا نیست. | ADR-002 به LOT-EVENT-001 و تصمیم مستقل Fingerprint/Canonicalization متصل شود. نسخه Fingerprint و فیلدهای تغییرناپذیر تعریف شوند؛ ابهام Parser پیش از Fingerprinting رد شود. Migration نسخه نباید Eventهای قدیمی را بی‌صدا بازتفسیر کند. تا آن زمان Duplicate در برابر Conflict مسدود است. |
| A11-F06 | بحرانی | **Idempotency مرز زمانی مصوب ندارد.** اگر Receipt یا Tombstone هویت حذف/منقضی شود، Replay دیرهنگام می‌تواند به‌عنوان Event جدید پذیرفته شود. تضمین «هرگز جفت دوم نساز» فقط تا زمانی قابل اجراست که شاهد یکتایی هویت موجود باشد یا Tombstone فشرده معادل حفظ شود. | افق Replay منبع بر اساس قرارداد واقعی شریک و الزامات کسب‌وکار/قانون تعریف شود؛ Identity/Tombstone Dedup حداقل تا آن افق، با احتساب Backup/Restore و Offboarding Tenant حفظ شود. اگر Replay نامحدود ممکن است، Tombstone پایدار و حداقلیِ فاقد داده حساس حفظ شود یا تضمین صریحاً محدود شود. Retention مربوط به Request Key از Retention مربوط به Source Event جدا بماند. |
| A11-F07 | زیاد | **«Scope مربوط» برای Quarantine مبهم است و می‌تواند ابزار Denial-of-Service شود.** Event مخرب/نامعتبر ممکن است در صورت Scope گسترده باعث توقف Tenant/Installation شود؛ Scope بیش از حد محدود نیز ممکن است WorkItem خراب را قابل اجرا باقی بگذارد. | سلسله‌مراتب مهار مرحله‌ای تعریف شود: Event Identity ← Installation/Source Partition ← مرز Tenant فقط در صورت اثبات دامنه اثر. جفت ناقص باید از طریق Guard مستقل برای Worker غیرقابل‌دریافت شود. تغییر Quarantine نیازمند Authority احراز‌شده، Audit، زمان بازبینی/انقضا و رویه Recovery است. تست Poisoning هدفمند و Noisy-neighbor اضافه شود. |
| A11-F08 | زیاد | **معنای Commit Success، Acceptance Success و اجرای WorkItem به‌اندازه کافی از هم جدا نشده است.** پذیرش پایدار به معنای Claim یا Processing شدن WorkItem نیست. Retry کلاینت باید نتیجه پذیرش پایدار را برگرداند، بدون افشای وضعیت Worker یا ایجاد اجرای دوباره. | پاسخ صرفاً «پذیرفته/به‌طور پایدار ثبت‌شده» باشد؛ Reference پایدار و غیرقابل‌حدس ارائه شود؛ هیچ وعده Completion داده نشود. پاسخ Duplicate از رکورد پذیرش پایدار استخراج شود و WorkItem دوم Enqueue نکند. رفتار پس از Quarantine شدن رکوردی که قبلاً پذیرفته شده نیز تعریف شود. |

## ۴. اصلاحات پروتکل موردنیاز

### ۴.۱ قرارداد Durability مربوط به Commit
پیش از پاسخ موفق پذیرش، سامانه باید بداند چه تضمین Durability به‌دست آمده است. «Database موفقیت Commit را برگرداند» کافی نیست، مگر آنکه پیکربندی مستند Candidate ثابت کند تراکنش تأییدشده در Failure Set اعلام‌شده باقی می‌ماند. قرارداد باید Flush پایدار محلی، تأیید Replication/Consensus، مجموعه Failoverهای مجاز و قاعده Promotion، RPO مربوط به Writeهای تأییدشده و رفتار Fail-closed هنگام نامشخص‌بودن Durability را مشخص کند.

از واژه «Synchronous» به‌تنهایی تضمین اتلاف صفر استنباط نشود؛ Mode واقعی، نقطه Acknowledgement و توپولوژی Failover تعیین‌کننده‌اند.

### ۴.۲ Epoch مرجعیت تک‌نویسنده
یک Authority Epoch/Incarnation منطقی، مستقل از Claim Generation مربوط به WorkItem، معرفی و ارزیابی شود:
- Epoch مرجعیت به‌صورت یکنواخت افزایش یابد و هرگز بازاستفاده نشود؛
- هر Write پذیرفته‌شده به Epoch فعال Fenced شود؛
- در هر لحظه فقط یک Epoch اختیار Write داشته باشد؛
- Promotion تا Fence/Terminate شدن Writer قدیمی و Attestation مرجع Recovery مسدود بماند؛
- Write با Epoch قدیمی Fail closed شود؛
- Backup Restore شده نتواند Epoch قدیمی را بی‌صدا برگرداند.

این یک الزام طراحی برای ارزیابی است، نه الزام به استفاده از Consensus یا Lease Service خاص.

### ۴.۳ Race در Reconciliation و Retry
Read بدون جفت، Insert بدون Guard را مجاز نمی‌کند. فقط Retry از مسیر همان عملیات اتمیک با هویت یکتای یکسان روی مرجع فعال و Fenced مجاز است. اگر Attempt قبلی هنوز روی Writer زنده یا مرجع قدیمیِ Fence‌نشده امکان Commit دارد، نتیجه UNKNOWN باقی می‌ماند. نتیجه Duplicate Key/Serialization باید با Read دارای Semantics سازگاری مستند و مقایسه کامل Bindingهای تغییرناپذیر دنبال شود.

### ۴.۴ Idempotency محدود به Retention
تضمین باید تابع یک Replay Horizon تعریف‌شده باشد. Policy حذف که تنها رکورد یکتایی را پاک کند، توان Deduplicate کردن Replay بعدی را نیز حذف می‌کند. محتوای حداقلی Tombstone، کنترل حریم خصوصی، Trigger Retention، انقضای Backup و تعامل Legal Hold پیش از تعیین مدت عددی مشخص شوند. افق Replay شریک را جعل نکنید.

### ۴.۵ Invariantهای رابطه جفت
طراحی فیزیکی آتی Persistence باید مستقلاً یکتایی Source Identity در InboxReceipt، حداکثر یک WorkItem برای هر Receipt، ارجاع هر WorkItem پذیرفته‌شده دقیقاً به یک Receipt معتبر، تطابق Bindingهای Tenant و Installation در هر دو رکورد، و عدم Claim جفت Quarantined یا ناسازگار را اعمال کند. Schema، Syntax Constraint و Isolation تراکنش برای تصمیم دیتابیس آتی و Proof موتور واقعی باقی می‌مانند.

## ۵. سناریوهای خصمانه تکمیلی

این موارد به‌عنوان Subcase زیر Parentهای موجود A4/A8 افزوده شوند؛ ۴۷ شناسه Canonical در A4 تغییر نکنند:

| Subcase پیشنهادی | حوزه Parent | تحریک | نتیجه الزامی |
|---|---|---|---|
| A11-DUR-02b | A4-IDEM-02 / A4-DUR | Commit اولیه هنوز درحال‌اجراست و Retry با همان Identity آغاز می‌شود | دقیقاً یک جفت؛ Retry نتواند از Attempt حل‌نشده جلو بزند یا یکتایی را دور بزند |
| A11-DUR-02c | A4-DUR | تراکنش اولیه هم‌زمان با Retry Abort می‌شود | حداکثر یک جفت موفق؛ بازنده وضعیت پایدار نهایی را بازیابی کند |
| A11-DUR-08b | A4-DUR | Primary Commit محلی را تأیید می‌کند ولی Failover Candidate آن Write را ندارد | هیچ ادعای نادرست Durability؛ رفتار مطابق RPO صریح |
| A11-DUR-08c | A4-DUR | Primary قدیمی پس از Promotion برمی‌گردد و Write می‌کند | Epoch قدیمی رد شود؛ Split-brain Pair ایجاد نشود |
| A11-DUR-08d | A4-DUR | هنگام گم‌شدن پاسخ Commit، Promotion رخ می‌دهد | تا Fencing مرجع جدید و تطبیق مطابق Durability Contract، UNKNOWN |
| A11-IDEM-09 | A4-IDEM | Replay پس از Expiry/Deletion رکورد Event می‌رسد | نتیجه مطابق Replay Horizon/Tombstone Policy مصوب؛ بدون ادعای Dedup نامستند |
| A11-IDEM-10 | A4-IDEM | همان Source Identity با Fingerprint Version یا Parser Profile متفاوت | Conflict صریح و آگاه از نسخه؛ بدون بازتفسیر بی‌صدا |
| A11-AUTH-08 | A4-AUTH | Event آلوده می‌کوشد Quarantine گسترده ایجاد کند | مهار به Scope مصوب محدود؛ Tenantهای بی‌ارتباط فعال بمانند |
| A11-WRK-01 | A4-AUTH / A4-DUR | Quarantine با Worker Claim رقابت می‌کند | یا Claim ابتدا Linearize و از Stop Rule مصوب پیروی کند، یا Quarantine برنده شود و Claim صفر ردیف تغییر دهد؛ پس از مرز Quarantine هیچ Pickup انجام نشود |

هر Subcase به Barrier/Schedule قطعی، Authority Epoch دقیق، State Persistence قبل/بعد، Oracle مستقل Read-only، شاهد Fault Controller و Assertion عدم اثر مالی نیاز دارد. همه NOT RUN هستند.

## ۶. اثر تصمیم

- ADR-002 همچنان **PROPOSED** است.
- A11-F01، F02، F03 و F06 بحرانی و مسدودکننده تصویب هستند.
- A11-F04، F05، F07 و F08 شدت بالا و مسدودکننده تصویب هستند.
- هیچ یافته‌ای با Documentation CI بسته نمی‌شود.
- هیچ یافته A7/A8 با این بازبینی بسته نمی‌شود.
- هر هشت Gate مربوط به A4 همچنان الزامی و NOT APPROVED هستند.
- هیچ Runtime، Candidate Persistence، Queue، Partner، مسیر مالی، Merge یا Deploy مجاز نشده است.

## ۷. شواهد لازم برای بستن یافته‌ها

برای هر یافته لازم است: ADR دوزبانه اصلاح‌شده با شناسه پایدار و زبان Normative صریح؛ تصمیم مالک برای انتخاب‌های Policy؛ تعیین تکلیف توسط بازبین واقعاً مستقل؛ Semantics و شواهد پیکربندی Vendor Candidate؛ Fault Test روی موتور واقعی Disposable، هرجا رفتار به Persistence/Failover وابسته است؛ نتایج Oracle مستقل و Provenance تغییرناپذیر Evidence؛ CI مستندات/قرارداد روی Head دقیق نهایی؛ و تفکیک روشن Design، Implementation، Test Execution و Acceptance.

## ۸. منابع

- Google Cloud Spanner، Unknown Commit Status و ریسک Retry: https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once
- Google Cloud Spanner Commit API، راهنمای Commit با وضعیت UNKNOWN: https://docs.cloud.google.com/workflows/docs/reference/googleapis/spanner/v1/projects.instances.databases.sessions/commit
- PostgreSQL High Availability، سازگاری Replication و Trade-offهای Failover: https://www.postgresql.org/docs/current/high-availability.html
- PostgreSQL Synchronous Replication و رفتار Failover: https://www.postgresql.org/docs/current/warm-standby.html
- PostgreSQL WAL و پنجره Durability در Asynchronous Commit: https://www.postgresql.org/docs/current/wal-async-commit.html
- PostgreSQL Constraints: https://www.postgresql.org/docs/current/ddl-constraints.html
- AWS Transactional Outbox: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html

این منابع Semantics شکست واقعی را روشن می‌کنند؛ PostgreSQL، Spanner، AWS یا Provider دیگری را انتخاب نمی‌کنند و رفتار Runtime در Lottorito را اثبات نمی‌کنند.


## ۹. تطبیق بازبینی با ADR-002 نسخه ۰.۲.۰ / ۰.۳.۰

بازبینی اولیه بالا ADR-002 نسخه ۰.۱.۰ را ارزیابی کرده است. نسخه‌های بعدی بخشی از یافته‌ها را در طراحی منعکس کرده‌اند؛ اما **این موضوع به‌معنای بسته‌شدن یافته‌ها نیست**: این بخش نیز تطبیق همان تدوین‌گر است و راستی‌آزمایی مستقل لازم دارد.

| یافته | پاسخ طراحی موجود | شواهد باقیمانده برای بستن |
|---|---|---|
| A11-F01 Durability در Failover | بخش ۱۷.۲ ADR-002 قرارداد صریح Durability/RPO برای Commit تأییدشده را الزام می‌کند. | Failure Model مصوب مالک؛ Semantics مربوط به Replication/Flush/Promotion در Candidate؛ تست خطا برای بقای Writeهای تأییدشده در Failover پشتیبانی‌شده. |
| A11-F02 مرجعیت/Split-brain | بخش ۱۷.۱ ADR-002، Authority Epoch افزایشی، اثبات تک‌نویسنده، Fencing Primary قدیمی و حفاظت Restore را الزام می‌کند. | تعیین ریشه مرجعیت؛ اثبات عدم Fork/Rollback در Epoch؛ رد Writer قدیمی در Partition شبکه/Control Plane و بازگشت مجدد. |
| A11-F03 Read منفی/Commit درحال‌اجرا | بخش‌های ۱۶.۳ و ۱۷.۱ ADR-002، Arbitration همان Key روی مرجع فعال و Fenced را الزام می‌کنند؛ Snapshot منفی به‌معنای خاتمه تراکنش قبلی نیست. | Schedule قطعی Commit اولیه/Retry/Promotion روی Engine کاندید؛ اثبات دقیق Conflict/Serialization و Consistency خواندن. |
| A11-F04 Cardinality جفت | بخش‌های ۱۶.۵ و ۱۷.۷ ADR-002، اعمال جفت در لحظه Commit/Capability و اثبات Cardinality/Linkage را الزام می‌کنند. | Constraintهای Unique/FK/Relationship مخصوص Candidate یا Aggregate توجیه‌شده؛ تست مستقیم رابطه صفر/یک/چندگانه، از جمله Restore/Corruption. |
| A11-F05 نسخه Fingerprint | بخش ۱۶.۶ ADR-002، تشخیص Duplicate را به پروفایل Canonicalization/Fingerprint نهایی و نسخه‌دار وابسته می‌کند. | هم‌راستایی LOT-EVENT-001؛ تصمیم Parser/Canonicalization و Vectorهای چندزبانه؛ تست Compatibility و Migration. |
| A11-F06 افق Retention | بخش ۱۷.۳ ADR-002، Replay Horizon مصوب مالک و Policy مربوط به Tombstone/Backup/Offboarding را الزام می‌کند. | قرارداد واقعی Source؛ تصمیم حقوقی/حریم خصوصی؛ تست حذف/Restore/Legal Hold و Replay دیرهنگام. هیچ افق عددی فرض نشده است. |
| A11-F07 دامنه Quarantine | بخش ۱۷.۴ ADR-002، مهار مرحله‌ای Event ← Installation/Source ← Tenant و منع Claim توسط Worker را الزام می‌کند. | Scope مصوب مالک؛ Policy مجوزدهی/Audit/Expiry/Recovery؛ تست Poisoning هدفمند/Noisy-neighbor و Race Claim. |
| A11-F08 تفکیک Acceptance از Execution | بخش ۱۷.۵ ADR-002 پاسخ را فقط پذیرش پایدار با Reference ثابت و بدون وعده Completion تعریف می‌کند. | هم‌راستایی Wire Contract/API؛ رفتار پس از Quarantine؛ تست قرارداد برای عدم ساخت WorkItem تکراری و عدم افشای State Worker. |

### ۹.۱ شفاف‌سازی‌های تکمیلی هویت و Snapshot

ADR-002 نسخه ۰.۲.۰ همچنین روشن می‌کند هویت Source در Scope هر Tenant نباید باعث Lookup/افشای بین‌مستاجری شود؛ Request Idempotency-Key باید به Fingerprint پایدار درخواست و Source Identity حل‌شده متصل باشد؛ بررسی Linkage Receipt/WorkItem باید در یک Snapshot سازگار انجام شود؛ و تغییر Fingerprint Profile نباید Receipt قدیمی را بی‌صدا بازتفسیر کند. چهار Case تکمیلی A10-DUR-02d، A10-DUR-02e، A10-AUTH-06b و A10-IDEM-08a در A7 ردیابی شده‌اند. نه Subcase مربوط به A11 نیز در آن منعکس شده‌اند. Catalogue اصلی A4 همچنان ۴۷ شناسه دارد.

نسخه سند مورد تطبیق در این بخش ADR-002 v0.3.0 است؛ اما هیچ بازبینی مستقلی روی نسخه ۰.۲.۰/۰.۳.۰ انجام نشده است. بازبین مستقل از نویسنده باید کل ADR جاری، Mappingهای A7 و تمام یافته‌ها را از ابتدا بازبینی کند و به این Crosswalk اکتفا نکند.

## ۱۰. وضعیت فعلی

- A11-F01 تا F08 همچنان OPEN هستند؛ متن طراحی تقویت شده اما یافته‌ها بسته نشده‌اند.
- تمام Subcaseهای A11 و A10 همچنان NOT RUN/BLOCKED هستند.
- Catalogue Canonical در A4 همچنان ۴۷ مورد است؛ توسعه‌ها جداگانه ردیابی می‌شوند.
- هر هشت Gate مربوط به A4 تصویب نشده‌اند.
- هیچ Database/Queue/Provider/Authority Service، Runtime، شریک، عملیات مالی، Merge یا Deploy مجاز نشده است.
