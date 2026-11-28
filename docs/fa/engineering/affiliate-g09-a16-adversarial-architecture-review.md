# G09-A16 — بازبینی خصمانه معماری ADR-002 و پرونده بازبین مستقل

**شناسه سند:** LOT-AFFILIATE-G09-A16-001  
**نسخه:** ۰.۱.۰  
**تاریخ:** ۲۰۲۶-۱۱-۲۸  
**وضعیت:** فرابازبینی تحلیلی نویسنده و پرونده آماده‌سازی بازبین — نه تأیید مستقل؛ بدون Proof مربوط به Candidate/Runtime  
**خط مبنای ثابت بازبینی:** PR شماره ۷۶، Head برابر با `8e9a880c14000bd158f66ae2001c02669ed4cc6b`  
**موضوع بازبینی:** ADR-002 نسخه ۰.۳.۰ و شواهد پشتیبان A7/A11/A12/A14/A15  
**اختیار:** صرفاً تحلیل و آماده‌سازی بازبینی مستقل. بدون تصمیم مالک، انتخاب فناوری، اجرای Runtime/Harness، اتصال شریک، عملیات مالی، Merge یا Deploy.

## ۱. نتیجه مدیریتی

در A16، بسته فعلی به‌عنوان یک پروتکل به‌هم‌پیوسته بازخوانی می‌شود؛ نه اینکه هر سند یا نتیجه CI به‌تنهایی اثبات تلقی شود. پرسش اصلی این است که آیا قرارداد پذیرش پیشنهادی کامل، ابطال‌پذیر، قابل اعمال در مرز اجرایی و قابل بازبینی است یا خیر.

**نتیجه: ADR-002 همچنان PROPOSED است؛ بازبینی مستقل هنوز لازم است؛ هر هشت یافته A11-F01 تا F08 همچنان OPEN هستند.** بلوغ مستندات به‌طور محسوسی افزایش یافته، اما شواهد فعلی برای تصویب معماری Persistence یا ادعای تضمین Runtime کافی نیست.

A16 عمداً بازبینی مستقل نیست. این سند فرابازبینی تحلیلی نویسنده و پرونده چالش ساختاریافته برای بازبین واجد صلاحیت است. می‌تواند پرسش یا شکاف احتمالی را مشخص کند؛ اما نمی‌تواند یافته A11 را ببندد، سیاست تحت اختیار مالک را تصویب کند یا درباره Candidate انتخاب‌نشده و آزمون‌نشده گواهی بدهد.

### چه چیزهایی اثبات شده‌اند
- CI قرارداد و مستندات روی Head ثابت‌شده موفق بوده است؛ این فقط اعتبارسنجی Source/Contract است.
- اعتبارسنجی نهایی A14 روی Head تاریخی مخصوص خودش موفق بوده؛ CI دقیق A15 نیز روی Head زمان خود موفق شده است. A16 برای Head جدید خود نیازمند CI دقیق است.
- Catalogue مربوط به A7 شامل ۴۷ شناسه Canonical در A4 و ۲۱ شناسه Extension جداگانه است؛ موجودی شناسه‌های EN/FA برای تطابق مقایسه شده است.
- A15 هفت تعهد اثبات مستقل از Candidate، دوازده تصمیم مالک و دوازده Schedule ساختگی قطعی تعریف می‌کند.
- در زمان بررسی قبلی، هیچ Review ثبت‌شده‌ای در رکورد GitHub مربوط به PR وجود نداشت. احتمال بازبینی خارج از GitHub نفی نمی‌شود، اما در رکورد مخزن Evidence محسوب نمی‌شود.

### چه چیزهایی اثبات نشده‌اند
- هیچ Database/Queue/Consensus/Authority یا Vendor انتخاب نشده است.
- Semantics مربوط به Commit Acknowledgement، Failover، Promotion، Restore، Isolation، Uniqueness، Fencing یا Read Consistency در Candidate مشخصی اثبات نشده است.
- RPO/RTO نوشتن تأییدشده، Replay Horizon، Retention، Legal Hold، Deletion و Recovery Policy تعیین نشده‌اند.
- Invariant مربوط به Cardinality رسید و WorkItem در Runtime اثبات نشده است.
- نگاشت امن و عمومی COMMITTED / ABORTED / UNKNOWN / UNAVAILABLE به HTTP هنوز تصویب نشده است.
- هیچ‌یک از Scheduleهای اثبات A7/A8/A11/A15 اجرا نشده‌اند و هیچ Proof مربوط به Recovery/KMS/HSM/عملیات مالی Production وجود ندارد.

## ۲. ورودی ثابت بازبینی و کنترل تغییر

بازبین مستقل باید Artifactهای زیر را دقیقاً روی Commit ثابت دریافت کند و Blob Hash آن‌ها را ثبت کند:
1. `docs/en/engineering/adr-002-atomic-ingress-acceptance-reconciliation.md` و نسخه فارسی آن.
2. فایل‌های `docs/{en,fa}/engineering/affiliate-g09-a7-47-case-traceability.md`.
3. فایل‌های `docs/{en,fa}/engineering/affiliate-g09-a11-adr002-adversarial-review.md`.
4. فایل‌های `docs/{en,fa}/engineering/affiliate-g09-a12-adr002-independent-review-package.md`.
5. فایل‌های `docs/{en,fa}/engineering/affiliate-g09-a15-persistence-proof-readiness.md`.
6. قراردادهای OpenAPI، AsyncAPI، Event/Security Acceptance، Manifest اعتبارسنجی و Fixtureها.
7. Decision Registerها، Project Status و Metadata مربوط به PR شماره ۷۶.

**خط مبنای ثابت:** `8e9a880c14000bd158f66ae2001c02669ed4cc6b`.

تغییر Head، محدوده بازبینی را باطل می‌کند. بازبین باید هر تغییر بعدی را Editorial، Semantic، Security-relevant یا Proof-affecting طبقه‌بندی کند، سپس Source را دوباره Freeze کند و بخش‌های متأثر را بازبینی کند. نتیجه CI فقط به Commit دقیقی تعلق دارد که روی آن اجرا شده است.

## ۳. پروتکل استقلال و صلاحیت بازبین

پیش از بازبینی محتوایی، بازبین باید اظهارنامه امضاشده‌ای ارائه کند که شامل موارد زیر باشد:
- عدم نویسندگی یا مشارکت مؤثر در تدوین ADR-002، A7، A11، A12، A15 یا Implementation مورد بررسی؛
- افشای تعارض‌های استخدامی، مالی، خط گزارش‌دهی، Vendor، موعد تحویل و تعارض شخصی؛
- تجربه عملی مرتبط در Persistence تراکنشی، Concurrency Control، Distributed Systems و Failure Recovery؛
- توان ارزیابی مرزهای امنیتی، Tenant Isolation، Data Integrity و Evidence مستقل؛
- مشخص‌کردن هر حوزه خارج از تخصص که به متخصص دوم نیاز دارد.

فردی که در طراحی پروتکل کمک کرده است می‌تواند بازخورد فنی ارزشمند بدهد، اما نباید مستقل معرفی شود. اگر استقلال محل تردید باشد، نتیجه باید **NOT ASSESSABLE** ثبت و بازبین دیگری تعیین شود. نویسندگی A16 و تحلیل قبلی دستیار، صلاحیت بازبینی مستقل ایجاد نمی‌کند.

## ۴. بازسازی پروتکل — پیش از پذیرش متن مستندات

بازبین باید بدون اتکا به روایت ADR، State Machine و نمودار Happens-before خود را بسازد. حداقل موارد:
1. احراز هویت و اتصال تغییرناپذیر Tenant/Installation؛
2. تعیین Source-event identity و HTTP request idempotency-key؛
3. Parsing، اعتبارسنجی Schema و انتخاب Fingerprint/Version؛
4. پذیرش اتمیک InboxReceipt + WorkItem؛
5. Acknowledgement مربوط به Commit و گم‌شدن Response؛
6. درخواست‌های Duplicate، Conflicting و هم‌زمان با Identity یکسان؛
7. Reconciliation وضعیت UNKNOWN در برابر Attempt اولیه درحال‌اجرا؛
8. از دست‌رفتن Primary، Promotion، بازگشت Primary قدیمی و Restore/PITR؛
9. رقابت Quarantine با Worker Claim و Processing درحال‌اجرا؛
10. Replay پس از پایان Retention، حذف Tombstone، Restore نسخه پشتیبان و Offboarding مستأجر.

برای هر Transition باید Authority واحد، نقطه Linearization/Serialization، تغییر State پایدار، مرز Enforcement، Oracle قابل مشاهده، Retry مجاز و رفتار Fail-closed مشخص شود. پاراگراف، Log، پاسخ HTTP یا Pre-check در Application به‌تنهایی Enforcement محسوب نمی‌شود.

## ۵. دفتر چالش‌های میان‌برشی A16

این موارد پرسش‌های چالشی تدوین‌کننده‌اند؛ نه یافته‌های تازه‌ای که مستقلاً پذیرفته یا بسته شده باشند. بازبین می‌تواند آن‌ها را تفکیک، رد، جایگزین یا موارد جدیدی اضافه کند. هیچ موردی نباید به اجبار PASS شود.

| چالش | شدت در صورت حل‌نشدن | چالش لازم / شرط پذیرش ابطال‌پذیر | کار مرتبط موجود |
|---|---|---|---|
| A16-C01 — تصمیم‌های مالک، Default پروتکل نیستند | Critical | بررسی شود هر ۱۲ تصمیم OD در A15 مالک پاسخ‌گو، مقدار/منطق تصویب‌شده، Scope، نسخه مؤثر و Evidence دارد. موارد نامعلوم باید ادعاهای وابسته را متوقف کنند؛ هیچ Default فروشنده یا عدد حدسی جای خالی را پر نکند. | A15 OD-01..OD-12؛ A11-F01/F02/F06/F07 |
| A16-C02 — Invariant جفت باید قابل Enforcement باشد | Critical | تمام مسیرهای نوشتن هر یک از دو رکورد بررسی شوند: API، Retry، Repair، Migration، Admin، Background و Restore. ثابت شود Receipt پذیرفته‌شده بدون دقیقاً یک WorkItem مرتبط Commit نمی‌شود و WorkItem یتیم/تکراری قابل Claim نیست. Atomic Transaction به‌تنهایی ثابت نمی‌کند کد هر دو Write را وارد کرده است. | A11-F04؛ A15 PO-01/PO-06 |
| A16-C03 — Epoch مرجعیت باید از همان Failure که مهارش می‌کند جان سالم به‌در ببرد | Critical | تخصیص و ذخیره Epoch، Restore، Rollback نسخه پشتیبان، Split-brain، استفاده مجدد از Credential و بازگشت Primary قدیمی بررسی شود. نشان داده شود Writer قدیمی در مرز Write محافظت‌شده رد می‌شود، نه صرفاً با بررسی Lease در Caller. Counter ذخیره‌شده فقط در State قابل Rollback کافی نیست. | A11-F02؛ A15 PO-04 |
| A16-C04 — UNKNOWN هم تحلیل Safety می‌خواهد هم Liveness | Critical | Lost Response، تراکنش درحال‌اجرا، Abort، Leader Election، Authority unavailable و Packet delay مدل شوند. عدم ایجاد جفت دوم اثبات شود؛ همچنین مشخص شود UNKNOWN چه زمانی و چگونه حل می‌شود، مالک Reconciliation کیست و ابهام نامحدود چگونه بدون Retry ناامن گزارش می‌شود. | A11-F03؛ A13-F05؛ A15 PO-02 |
| A16-C05 — Acknowledgement نسبت به Failure Model معنا دارد | Critical | Failureهای داخل/خارج تعهد، Local Flush، Replica/Consensus Acknowledgement، مجموعه Promotion مجاز، Restore Point و RPO نوشتن تأییدشده تعریف شوند. بلافاصله پس از Acknowledgement خرابی ایجاد و Identityهای پذیرفته‌شده قبل/بعد از Promotion و Restore مقایسه شوند. از واژه Synchronous، RPO صفر استنباط نشود. | A11-F01؛ A15 PO-03 |
| A16-C06 — Identity، Fingerprint و Semantics عددی نیازمند Profile ثابت‌اند | High | Duplicate JSON Member پیش از Materialization، نام‌های Escaped تکراری، Precision/Range اعداد، حفظ Unicode، اختلاف Parserها، Evolution مربوط به Schema و Canonicalization بین زبان‌ها آزموده شود. نسخه Fingerprint به Receipt ذخیره‌شده متصل و سازگاری نسخه‌های هم‌زمان تعریف شود. | A11-F05؛ A15 PO-05 |
| A16-C07 — تضمین Idempotency مرز زمانی دارد | Critical | Source-event dedupe، Retention کلید HTTP و Economic-effect idempotency از هم جدا شوند. Replay Horizon از قرارداد واقعی Source و سیاست Legal/Privacy استخراج شود؛ Tombstone، Backup، Restore، Deletion و Offboarding نیز لحاظ شوند. زمان پایان تضمین دقیقاً اعلام شود. | A11-F06؛ A15 PO-05 |
| A16-C08 — Quarantine و Worker Claim به Arbitration مشترک نیاز دارند | High | Quarantine، Claim، Lease expiry، Pause/Resume Worker و Retry درهم‌تنیده شوند. ثابت شود پس از Linearize شدن Quarantine، Claim جدید رخ نمی‌دهد؛ تکلیف Claimی که زودتر Linearize شده مشخص باشد؛ Payload غیرقابل‌اعتماد نتواند Scope را گسترش دهد و Tenantهای سالم فعال بمانند. | A11-F07؛ A15 PO-06 |
| A16-C09 — Semantics عمومی Acceptance نباید بیش‌ادعا کند | High | COMMITTED/ABORTED/UNKNOWN/UNAVAILABLE داخلی با HTTP Status/Code در OpenAPI و Retry Contract کلاینت تطبیق داده شود. 202 فقط پذیرش پایدارِ تصویب‌شده را معنا دهد؛ State مربوط به Worker افشا نشود و Completion کمیسیون/مالی القا نشود. | A11-F08؛ A13-F05؛ A15 PO-07 |
| A16-C10 — Evidence باید مستقلاً قابل انتساب باشد | High | Manifest بازتولیدپذیر Evidence باید Source SHA، Binary/Build، Config، نسخه Candidate، Topology، Fault Schedule، زمان معتبر، Request ID، Authority Epoch و خروجی Oracle را به هم متصل کند. Log و Dashboard سامانه تحت آزمون به‌تنهایی State پایدار را ثابت نمی‌کنند. | A12 §7؛ قرارداد Evidence در A15 |

## ۶. Scheduleهای خصمانه قطعی

بازبین ابتدا Scheduleهای A7 و A15 را بررسی کند؛ خانواده‌های زیر حداقل ترتیب‌ها و Faultهایی هستند که نباید پشت تست‌های Happy-path پنهان بمانند:

| خانواده Schedule | ترتیب/Fault لازم | Oracle ایمنی |
|---|---|---|
| S-A — Ingress هم‌زمان با Key یکسان | دو Caller پیش از مشاهده Commit یکدیگر آغاز شوند؛ برنده تراکنش و گم‌شدن Response تغییر کند. | دقیقاً یک Source Identity، یک Receipt و یک WorkItem؛ Reference پایدار؛ بدون Lookup بین Tenantها. |
| S-B — گم‌شدن پاسخ Commit | Commit ممکن است موفق شود و سپس Connection پیش از دریافت Response توسط Client قطع شود. | Client تا Resolution معتبر در UNKNOWN بماند؛ جفت تکراری ایجاد نشود. |
| S-C — Commit درحال‌اجرا در برابر Read منفی | تراکنش اولیه پیش از Commit متوقف شود؛ Reconciliation هیچ Row قابل مشاهده‌ای نبیند؛ Retry همان Identity را آغاز کند. | Retry Serialize/Block شود یا در Arbitration یکتایی ببازد؛ Snapshot منفی هرگز مجوز جفت دوم نباشد. |
| S-D — Race میان Abort و Retry | تراکنش اولیه درحالی‌که Retry منتظر است، به Abort اجباری برسد. | حداکثر یک جفت Commit شود؛ نتیجه قطعی فقط پس از پایان قطعی Attempt اولیه. |
| S-E — Acknowledgement و سپس از دست‌رفتن Primary | Primary بلافاصله پس از Acknowledgement متوقف شود؛ Candidate ارتقا یابد و Identityهای پذیرفته‌شده بررسی شوند. | نتیجه مطابق Failure Model/RPO تصویب‌شده؛ Worker روی State واگرا اجرا نشود. |
| S-F — بازگشت Primary قدیمی | Primary قدیمی Partition شود، Authority جدید ارتقا یابد و سپس Node قدیمی با تمام مسیرها دوباره متصل و Write کند. | Writer قدیمی در مرز Enforcement/Storage رد شود؛ State دو Writer ایجاد نشود. |
| S-G — Rollback در Restore | Backup/PITR قدیمی Restore شود و Epochها و Identityهای Idempotency قبل از Restore دوباره استفاده شوند. | Authority و Dedupe Policy ایمن بمانند؛ اگر Proof ممکن نیست، سیستم Fenced باقی بماند. |
| S-H — ماتریس تغییر جفت | Receipt و WorkItem جداگانه حذف شوند؛ Partial Restore، SQL/Admin مستقیم و Repair تزریق شود. | Cardinality/Linkage نامعتبر Commit یا قابل اجرا نشود. |
| S-I — Race بین Quarantine و Claim | Claim پیش و پس از نقطه Serialization متوقف شود؛ Quarantine و Resume Worker هم‌زمان شوند. | یک برنده قطعی؛ پس از مرز Quarantine، Claim جدید نباشد؛ Scope Audit شود. |
| S-J — چرخه عمر Replay | Replay قبل/بعد Retention، حذف Tombstone، انقضای Backup، Offboarding و Legal Hold اجرا شود. | رفتار دقیقاً مطابق Horizon تصویب‌شده؛ بدون تضمین دائمی و مستندنشده. |
| S-K — اختلاف Parser/Fingerprint | Duplicate Keyهای Escaped، مرز عددی، Unicode و اختلاف نسخه Schema/Fingerprint بین زبان‌ها آزموده شود. | ابهام رد شود یا Profile ثابت یکسان اعمال گردد؛ تغییر Intent بی‌صدا Duplicate تلقی نشود. |
| S-L — در دسترس نبودن Authority | دسترسی به Authority Service یا Quorum هنگام Reconciliation/Promotion قطع شود. | Fail-closed؛ بدون Acceptance حدسی، Promotion یا Retry به‌عنوان درخواست جدید. |

این Scheduleها فقط پس از تصمیم مالک، انتخاب Candidate و مجوز اجرای Runtime قابل پیاده‌سازی‌اند. این سند آن‌ها را اجرا نمی‌کند.

## ۷. قرارداد Oracle مستقل و Evidence

هر Proof آتی برای Candidate باید شواهد مستقل زیر را با یکدیگر تطبیق دهد:
1. مشاهده Client/API که جدا از حقیقت Persistence ثبت شده باشد؛
2. بررسی Persistence مرجع با Consistency Mode و Authority Identity دقیق؛
3. Evidence مربوط به Transaction/Constraint برای Atomicity و Arbitration روی Key یکسان؛
4. Query مربوط به Cardinality و Linkage Receipt/WorkItem و Tenant/Installation در یک Snapshot واحد؛
5. رکورد Fault Controller که رسیدن به نقطه تزریق خطا را اثبات کند؛
6. Evidence مربوط به Authority/Fencing در مرز واقعی Enforcement؛
7. Evidence منفی عدم دسترسی مالی در Credential، Service Binding، Queue، Network/DNS و مسیرهای اجرای غیرمستقیم؛
8. Manifest تغییرناپذیر Evidence شامل Hash، Timestamp، Correlation ID، Configuration و هویت Candidate.

اگر Fault رخ‌دادنش اثبات نشده، Oracle قدیمی/مبهم است، Evidence ناقص است، Failure Class اعلام‌شده پوشش داده نشده یا Run به Source/Configuration دقیق قابل انتساب نیست، نتیجه **INCONCLUSIVE** است، نه PASS. خروج موفق Process به‌تنهایی Proof یک ویژگی ایمنی نیست.

## ۸. تفسیر استانداردها و رویه‌های پیشتاز

- **AWS Builders' Library — APIهای Idempotent:** تثبیت Intent فراخوان، اتصال Token درخواست به پارامترها، تشخیص عدم تطابق و انتخاب آگاهانه Retention ضروری است. این منبع Exactly-once در Transport یا Dedupe نامحدود را تضمین نمی‌کند.
- **AWS Well-Architected — Retry:** Idempotency پیش‌شرط Retry امن است؛ تعداد/زمان Retry باید محدود باشد؛ Backoff/Jitter و یک لایه Retry از Amplification می‌کاهند. این موارد برای ایمنی بار مهم‌اند، اما جای Arbitration تراکنشی روی Key یکسان را نمی‌گیرند.
- **مستندات PostgreSQL درباره WAL و Synchronous Replication:** قدرت Acknowledgement به Commit Mode پیکربندی‌شده و نوع تأیید Replica وابسته است. Async Commit ممکن است پیش از رسیدن WAL به Storage پایدار پاسخ دهد؛ حالت‌های Synchronous نیز در Local/Remote Persistence و Replay یکسان نیستند. این مثال نشان می‌دهد Configuration و Failure Model Candidate باید بررسی شوند؛ توصیه‌ای برای انتخاب PostgreSQL نیست.
- **مستندات PostgreSQL درباره Failover:** پس از Promotion باید Primary قدیمی از Primary بودن منع شود؛ وگرنه هر دو Node ممکن است خود را Writable بدانند. Witness یا Heartbeat به‌تنهایی Proof مربوط به Fencing Writer قدیمی نیست.
- **تحلیل Fencing Token:** Token فقط زمانی محافظت می‌کند که Resource انجام‌دهنده Write، مقدار Monotonic را به خاطر بسپارد/مقایسه کند و Write قدیمی را رد کند. Lock/Lease در اختیار Client کافی نیست اگر Client متوقف‌شده بعداً بتواند Write کند.
- **روش Jepsen:** History مربوط به Invocation/Completion ثبت شود، هم‌زمان Fault تزریق گردد و سپس History با مدل صریح صحت بررسی شود. تست بدون Checker/Oracle و Schedule قابل تکرار، Proof سیستم توزیع‌شده نیست.
- **RFC 8785 / I-JSON:** Canonicalization به محدودیت‌هایی از جمله نبود Property Name تکراری، نمایش عددی قابل‌تبادل و حفظ رشته‌های Unicode نیاز دارد. JCS سند Informational است و Default تصمیم Lottorito نیست؛ مقادیر دقیق با Precision بالا ممکن است در Profile منتخب به نمایش String نیاز داشته باشند.

منابع:
- AWS Builders' Library، Making retries safe with idempotent APIs: https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- AWS Well-Architected، Make mutating operations idempotent: https://docs.aws.amazon.com/wellarchitected/2025-02-25/framework/rel_prevent_interaction_failure_idempotent.html
- AWS Well-Architected، Control and limit retry calls: https://docs.aws.amazon.com/wellarchitected/latest/framework/rel05-bp03.html
- PostgreSQL Asynchronous Commit: https://www.postgresql.org/docs/current/wal-async-commit.html
- PostgreSQL Synchronous Replication و Failover: https://www.postgresql.org/docs/current/warm-standby.html
- PostgreSQL Failover و Fencing مربوط به Primary قدیمی: https://www.postgresql.org/docs/current/warm-standby-failover.html
- Martin Kleppmann، How to do distributed locking (Fencing Tokens): https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html
- Jepsen Framework و History Checking: https://github.com/jepsen-io/jepsen و https://jepsen-io.github.io/jepsen/jepsen.checker.html
- RFC 8785، JSON Canonicalization Scheme: https://www.rfc-editor.org/rfc/rfc8785.html
- RFC 7493، I-JSON: https://www.rfc-editor.org/rfc/rfc7493.html

این منابع پرسش‌های بازبینی را تقویت می‌کنند؛ نه فناوری انتخاب می‌کنند، نه تضمین Vendor برای Lottorito می‌سازند و نه رفتار Implementation را اثبات می‌کنند.

## ۹. خروجی الزامی بازبین مستقل

بازبین مستقل باید گزارش جداگانه و قابل انتسابی ارائه کند که شامل این موارد باشد:
- هویت، صلاحیت‌ها و اظهارنامه امضاشده استقلال/تعارض؛
- Source Commit، PR، Blob Hash اسناد و نسخه‌های زبانی بررسی‌شده؛
- State Machine مستقل، نقاط Linearization و نقشه Authority؛
- تعیین وضعیت هر مورد: ACCEPTED / ACCEPTED WITH CONDITIONS / REJECTED / NOT ASSESSABLE؛
- Counterexampleهای مشخص، Scheduleهای قابل تکرار و Evidence؛
- تعیین تکلیف جداگانه A11-F01 تا F08 و یافته‌های جدید با Mapping به A4/A7؛
- تصمیم‌های مالک که همچنان حل‌نشده‌اند؛
- نظر صریح درباره آمادگی ADR-002 برای تصمیم مالک، نیاز به Redesign یا غیرقابل ارزیابی بودن؛
- محدودیت‌ها، فرض‌های آزمون‌نشده و Evidence دقیق مورد نیاز در ادامه.

نویسنده نباید صرفاً با ویرایش Crosswalk، یافته‌ای را ببندد. بسته‌شدن نیازمند تأیید Evidence توسط بازبین و برای تصمیم‌های سیاستی، تصویب مالک پاسخ‌گو است. اگر صلاحیت بازبین در حوزه‌ای مهم کافی نیست، گزارش باید آن شکاف را مشخص و متخصص دوم را درخواست کند.

## ۱۰. شرایط توقف و عدم صدور مجوز

در صورت امکان هر یک از موارد زیر، بازبینی متوقف و نتیجه REJECTED یا NOT ASSESSABLE اعلام شود:
- Write در Split-brain یا دور زدن Fencing توسط Writer قدیمی؛
- از دست‌رفتن Acceptance تأییدشده خارج از Failure Model صریحاً تصویب‌شده؛
- جفت تکراری یا ناقص Receipt/WorkItem؛
- افشای وجود داده بین Tenantها؛
- Claim قدیمی Worker پس از مرز Serialization مربوط به Quarantine؛
- Replay فراتر از تضمین تصویب‌شده بدون باقی‌ماندن Dedupe Record؛
- Quarantine گسترده با محرک Payload غیرقابل‌اعتماد؛
- دسترسی Ingress به Commission، Wallet، Ledger، Payout یا هر قابلیت مالی؛
- استفاده از CI سبز/Dashboard به‌جای Evidence مربوط به Persistence.

**وضعیت فعلی:** ADR-002 برابر PROPOSED؛ A11-F01 تا F08 باز؛ Proof مربوط به Extensionهای A7/A8 در وضعیت NOT RUN/BLOCKED؛ هر هشت Gate مربوط به A4 تصویب‌نشده‌اند. هیچ Candidate، Runtime، شریک یا عملیات مالی مجاز نیست. PR شماره ۷۶ همچنان Open/Draft است و نباید بر اساس A16 Merge یا Deploy شود.

## ۱۱. تحویل به مالک و بازبین

مالک پاسخ‌گو باید دوازده تصمیم OD در A15 را همراه با Evidence و منطق تصمیم ارائه کند. سپس بازبین مستقل باید مجموعه Artifactهای Freeze‌شده را بررسی و گزارش بخش ۹ را تحویل دهد. فقط پس از بازبینی و تصمیم‌های مالک می‌توان درباره انتخاب یک محیط Candidate دورریختنی برای اجرای Proof مجاز تصمیم گرفت. ترتیب نباید معکوس شود.

