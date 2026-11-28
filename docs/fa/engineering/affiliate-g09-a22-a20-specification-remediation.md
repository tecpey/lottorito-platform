# G09-A22 — اصلاح مشخصات A20

**شناسه سند:** LOT-AFFILIATE-G09-A22-001  
**نسخه:** 1.0.0 | **وضعیت:** اصلاحیه پیشنهادی مشخصات — صرفاً تحقیق  
**تاریخ:** ۲۰۲۶-۱۱-۲۸  
**سند والد:** G09-A20 / LOT-AFFILIATE-G09-A20-001  
**مبنای بازبینی:** G09-A21 / LOT-AFFILIATE-G09-A21-001

## ۱. هدف و تعیین وضعیت

A22 یافته‌های عملیاتی P1 از A21-F02 تا A21-F10 را به ساختار مشخصاتی قابل آزمون تبدیل می‌کند؛ بدون انتخاب سیاست، زیرساخت، Database، Provider، مدت Retention، مقدار RPO/RTO یا معنای کسب‌وکاری که هنوز تعیین نشده است.

A22 یک اصلاحیه همراه و کنترل‌شده است. این سند A20 را بی‌صدا بازنویسی نمی‌کند، صرفاً با افزودن متن یافته‌ای را نمی‌بندد، ADR-002 را تصویب نمی‌کند و مجوز Runtime صادر نمی‌کند.

**تعیین وضعیت:** A22 حداقل شکل قرارداد و شواهد لازم را تعریف می‌کند تا A20 بتواند از خط مبنای تحقیق/طراحی آزمون به مشخصات اجرایی احراز صلاحیت ارتقا یابد. مقادیر وابسته به مالک، صریحاً مسدودکننده باقی می‌مانند.

## ۲. زبان هنجاری و مرجعیت تصمیم

واژه‌های MUST، MUST NOT، SHOULD، SHOULD NOT و MAY در این سند معنای هنجاری دارند.

ترتیب مرجعیت:
۱. قانون/مقررات قابل اعمال و قراردادهای امضاشده مشتری/اپراتور، پس از شناسایی و راستی‌آزمایی توسط مالک مجاز/مشاور حقوقی.
۲. محدودیت‌های صریح کسب‌وکار/امنیت مصوب مالک و ثبت‌شده در Decision Register.
۳. ADRهای تصویب‌شده و قراردادهای نسخه‌دار.
۴. این مشخصات A22 و کاتالوگ آزمون A20.
۵. مستندات Candidate/Vendor و مطالب بازاریابی؛ این‌ها ورودی Evidence هستند، نه مرجع تصمیم.

قابلیت محصول یا ادعای Vendor نمی‌تواند قانون، الزام مصوب مالک یا Invariant دامنه را نقض کند. هیچ مقداری از مثال‌ها استنباط نمی‌شود.

تصمیم مالک حل‌نشده با OPEN_OWNER_INPUT، مدرک مفقود با MISSING_EVIDENCE، ادعای پشتیبانی‌نشده با UNVERIFIED، Assertion نقض‌شده با FAIL و نتیجه مبهم/ناقص با INCONCLUSIVE مشخص می‌شود. این وضعیت‌ها هرگز نباید به PASS تبدیل شوند.

## ۳. ردیابی Requirement-to-Proof — A21-F07

هر Requirement اجباری و Assertion بحرانی MUST رکورد Trace با فیلدهای زیر داشته باشد:

| فیلد | محتوای لازم |
|---|---|
| trace_id | شناسه یکتای پایدار |
| constraint_id | C-01..C-16 یا NOT_APPLICABLE با دلیل مصوب |
| gate_id | G1..G9 |
| owner_decision_ids | OD-01..OD-12 مرتبط؛ خالی فقط با دلیل |
| requirement/control | عبارت هنجاری دقیق و منبع/نسخه |
| invariant_id | یک یا چند I-ID |
| scenario_ids | سناریوهای مثبت، منفی و Interleaving خرابی |
| preconditions | Topology، State، Version، Identity، Permission و Fixture |
| fault_schedule | دستورهای مرتب و قطعی Fault/زمان‌بندی |
| oracle_ids | Oracle، Query/Algorithm و Trust Boundary |
| expected_history | Historyهای مجاز و ممنوع مشاهده‌پذیر |
| evidence_artifacts | Log خام، Trace، Metric، Export دیتابیس، Config و Hash |
| owner/approver | مالک پاسخ‌گو و رکورد تصویب |
| result | PASS / FAIL / INCONCLUSIVE / NOT_RUN / BLOCKED |
| residual_risk | محدودیت، دامنه و نحوه برخورد |
| reviewer | اجراکننده/بازبین؛ استقلال اظهار می‌شود، فرض نمی‌شود |

Traceability باید دوطرفه باشد. هر C-ID و G-ID قابل اعمال به آزمون‌ها/شواهد نگاشت شود؛ هر Test به Requirement/Invariant؛ هر Invariant بحرانی به آزمون مثبت و خصمانه. NOT_APPLICABLE به دلیل مصوب مالک نیاز دارد. Requirement اجباری بدون نگاشت یا Test یتیم، Qualification را مسدود می‌کند.

## ۴. Source Identity، Canonicalization و Deduplication — A21-F02

### ۴.۱ قرارداد Identity — وابسته به تصمیم

هویت Event MUST یک Tuple نسخه‌دار باشد، اما فیلدها و دامنه واقعی آن تابع OD-01 تا OD-04 است. قرارداد مصوب MUST این موارد را تعیین کند:
- Namespace و منبع مرجع هویت Tenant؛
- هویت Source/Operator و در صورت لزوم Source Installation یا Credential Epoch؛
- دامنه Event ID و تضمین یکتایی؛
- نوع Event/Domain و Source Epoch احتمالی؛
- الگوریتم/نسخه Canonicalization؛
- الگوریتم Fingerprint، Encoding و استفاده از Key؛
- رفتار Migration/Rotation هویت و Fingerprint؛
- Retention و انقضای Identity/Tombstone.

هیچ پیاده‌سازی بدون تصویب صریح مجاز نیست Global Event ID، Timestamp، Payload Hash یا API Key را جایگزین Tuple مصوب کند.

### ۴.۲ کلاس‌های هم‌ارزی اجباری

پس از تصویب ODها، آزمون‌ها MUST موارد زیر را تفکیک کنند:
۱. Identity مصوب یکسان + Fingerprint معنایی Canonical یکسان: Duplicate؛ بدون پذیرش کسب‌وکاری دوم.
۲. Identity یکسان + Fingerprint معنایی متفاوت: Conflict/Quarantine؛ بدون بازنویسی خاموش یا Duplicate بی‌خطر.
۳. Tenant متفاوت + Source Event ID یکسان: Isolation؛ بدون برخورد بین Tenant یا افشای اطلاعات.
۴. Namespace/Epoch مصوب متفاوت + Event ID یکسان: رفتار طبق Tuple مصوب، نه حدس.
۵. Identity مفقود، بدساخت، بیش‌ازحد بزرگ یا با نسخه پشتیبانی‌نشده: رد/Quarantine قطعی؛ بدون پذیرش مالی ناقص.
۶. محتوای معنایی یکسان با تفاوت مجاز Transport-only: نتیجه طبق Canonicalization نسخه‌دار.
۷. Canonicalizer/Key قدیمی و جدید هنگام Rotation: سیاست صریح Migration/Dual-version؛ بدون Drift خاموش Fingerprint.
۸. Replay پس از مرز Retention و پس از Restore: رفتار طبق چرخه عمر مصوب و افق Replay مبدأ.

### ۴.۳ الزامات Canonicalization

قرارداد MUST بایت‌های Canonical دقیق پیش از Fingerprint را تعریف کند: ورود/حذف فیلد، Null در برابر Absent، نمایش عدد، Unicode Normalization، دقت Timestamp/Time Zone، ترتیب Array، Duplicate Key، فیلد ناشناخته، تکامل Schema و رفتار ورودی نامعتبر. اگر RFC 8785 JSON Canonicalization Scheme انتخاب شود، محدودیت‌ها و ناسازگاری‌های آن MUST مستند شود؛ JSON بودن Payload به‌معنای انتخاب خودکار نیست.

Canonicalization باید بین Implementationها و Versionهای پشتیبانی‌شده Deterministic باشد. Golden Vectorها باید Payload عادی، مرزی، بدساخت و خصمانه را پوشش دهند. Vectorها Fixture هستند، نه تصویب الگوریتم.

### ۴.۴ اتصال Retention

حفاظت Identity MUST تمام مسیرهای مجاز Redelivery/Replay را پوشش دهد. Retention مقدار حدسی نیست. استخراج آن MUST بیشینه افق‌های قابل اعمال را در نظر بگیرد:
- Retry/Redelivery مبدأ و Replay اپراتور؛
- Retention صف/Broker و تحویل با تأخیر؛
- عمر Backup قابل Restore و پنجره PITR؛
- تأخیر Replication/DR و Failback؛
- بازیابی دستی Incident و Reprocessing؛
- Migration و تعهدات قانونی Retention/Deletion.

مالک باید سیاست و استثناها را تصویب کند. اگر افق Replay مبدأ نامحدود یا نامعلوم است، راهبرد عدم استفاده مجدد/Epoch اثبات‌شده لازم است یا Qualification مسدود می‌شود؛ حفاظت Deduplication نباید بی‌صدا منقضی شود.

**Evidence خروج:** تصویب OD-01..OD-04؛ قرارداد نسخه‌دار Identity/Canonicalization؛ Golden Vector؛ راهبرد Migration/Expiry؛ آزمون هر هشت کلاس هم‌ارزی.

## ۵. Atomic Acceptance و UNKNOWN Commit — A21-F03

### ۵.۱ Invariant پذیرش اتمیک

برای Identity مصوب، عملیات مرجع Acceptance MUST کل رکورد پذیرش و نمایش Durable موردنیاز را اتمیک ذخیره کند یا هیچ‌کدام را ذخیره نکند. Cardinality/Schema دقیق Receipt/WorkItem تابع ADR-002 و OD-05..OD-07 است.

Ack موفق MUST به‌معنای عبور از نقطه Durable Acceptance مصوب باشد. Timeout، Connection Reset یا پاسخ ازدست‌رفته MUST اثبات Rollback یا Commit تلقی نشود.

### ۵.۲ مدل انتزاعی نتیجه

مرز API/Application MUST حداقل این نتایج را تفکیک کند:
- ACCEPTED: پذیرش Durable مرجع اثبات شده است.
- REJECTED: پیش از Acceptance رد شده؛ اثر پذیرش وجود ندارد.
- DUPLICATE_CONFIRMED: همان Identity و Event معنایی قبلاً پذیرفته شده؛ نتیجه موجود ارجاع می‌شود.
- CONFLICT: Identity با Fingerprint معنایی متفاوت وجود دارد؛ پذیرش دوم رخ نمی‌دهد.
- UNKNOWN: Caller نمی‌تواند تعیین کند Transaction مرجع Acceptance Commit شده است یا نه.
- QUARANTINED: حل‌وفصل کنترل‌شده/انسانی لازم است؛ Work عادی پذیرفته‌شده نیست.

UNKNOWN معادل REJECTED، RETRYABLE_FAILURE یا ACCEPTED نیست. نگاشت نهایی Wire Status تصمیم جداگانه قرارداد API است.

### ۵.۳ الزامات Reconciliation

برای UNKNOWN:
۱. Identity و Fingerprint اولیه حفظ شود.
۲. برای فرار از ابهام Identity جدید ساخته نشود.
۳. مرجع Acceptance با Read دارای Consistency کافی Query شود؛ Replica/Cache قدیمی مدرک نبود رکورد نیست.
۴. Race با Transaction اولیه در حال اجرا حل شود. Read منفی تا وقتی Transaction اولیه می‌تواند Commit/Visible شود، نبود قطعی نیست.
۵. Reconcile بر اساس Identity و Fingerprint باشد، نه Timestamp تقریبی یا شباهت Payload.
۶. Acceptance پایدار منطبق، نتیجه موجود را بازگرداند/ارجاع دهد.
۷. Fingerprint متعارض به Conflict/Quarantine برود.
۸. اگر نبود رکورد تحت پروتکل مصوب Concurrency/Visibility اثبات شد، Retry فقط از همان مسیر Idempotent و با همان Identity انجام شود.
۹. اگر حل‌نشده ماند، UNKNOWN حفظ و Escalate شود؛ نه Retry خودکار نامحدود و نه پاسخ نهایی کاذب.
۱۰. هر Transition/اقدام اپراتور Auditپذیر و Replay-safe باشد.

Implementation MUST Arbitration با Transaction اولیه در حال اجرا را تعریف کند: رفتار Unique/Serializable دیتابیس، Fencing Token، قابلیت Transaction Status یا سازوکار دیگری با توجیه. Read-then-insert بدون اثبات Race کافی نیست.

### ۵.۴ Historyهای لازم

آزمون‌ها باید Commit موفق/پاسخ گم‌شده؛ Commit ناموفق/پاسخ گم‌شده؛ Retry هنگام Transaction اولیه؛ Read از Replica قدیمی؛ Submit هم‌زمان با Identity یکسان؛ Identity یکسان/Fingerprint متفاوت؛ Failover هنگام Commit/Reconciliation؛ Retry پس از Restart؛ رقابت Reconciliation اپراتور و Retry خودکار؛ و پاسخ Duplicate پیش از تکمیل Worker اولیه را پوشش دهند.

**Evidence خروج:** تصویب OD-05..OD-07 و OD-11؛ State Machine؛ Linearization Point؛ اثبات Isolation/Consistency؛ History Checker هم‌زمانی؛ سیاست صریح حل UNKNOWN. پیش از انتخاب Candidate هیچ فرض محصول‌محوری مجاز نیست.

## ۶. اثرهای جانبی خارجی و Delivery Guarantee — A21-F04

### ۶.۱ مرز تضمین

Atomicity داخل یک Transaction دیتابیس، فراخوانی HTTP خارجی، اقدام Payment Provider، Email، Webhook، Wallet Transfer یا Mutation سامانه Partner را با آن Transaction اتمیک نمی‌کند.

تضمین‌ها MUST جداگانه برای پذیرش Durable داخلی، Mutation دفترکل/Workflow داخلی، انتشار Outbox، تحویل Broker، پردازش Consumer و اثر Receiver خارجی بیان شوند.

ادعای Exactly-once برای اثر خارجی سرتاسری ممنوع است، مگر قرارداد Receiver، Retention مربوط به Deduplication، Reconciliation و رفتار شکست در کل مرز اثبات شده باشد. در غیر این صورت معنای واقعی At-least-once، At-most-once یا Unknown اعلام شود.

### ۶.۲ قرارداد Receiver به‌ازای هر مقصد

پیش از ورود اثر خارجی به Scope، موارد زیر تعریف شوند:

| فیلد | تعریف لازم |
|---|---|
| destination_id | مقصد منطقی پایدار |
| owner/operator | طرف پاسخ‌گو/مالک سامانه |
| operation | اثر جانبی و معنای کسب‌وکاری دقیق |
| idempotency | Key یا سازوکار معادل Receiver |
| key scope | دامنه Tenant، Account، Operation و Resource |
| fingerprint | رفتار Key/Request یکسان در برابر Request متفاوت |
| receiver retention | پنجره تضمین‌شده Deduplication و Evidence |
| lookup | Query مرجع نتیجه |
| timeout behavior | معنای نتیجه نامعلوم |
| duplicate behavior | اثر/پاسخ در Redelivery |
| ordering | ترتیب Aggregate/Sequence و مدیریت Gap |
| compensation | Remedy موجود؛ Rollback فرض نشود |
| security | Auth، Signing، Rotation کلید و Replay Protection |
| evidence | Receipt/Log Receiver، دسترسی Query و Retention |

اگر Receiver Idempotency یا Lookup قابل اعتماد ندارد، اثر به‌عنوان Residual Risk صریح طبقه‌بندی و از ادعای Exactly-once خارج شود. Lease/Fencing محلی نمی‌تواند درخواست پذیرفته‌شده Receiver را باطل کند.

### ۶.۳ قواعد Outbox و Consumer

- Mutation دامنه و Outbox در معماری مدعی Transactional Outbox باید اتمیک Commit شوند.
- تا اثبات قرارداد قوی‌تر Broker/Receiver، Delivery بالقوه Duplicate است.
- Consumer باید Deduplication و Mutation کسب‌وکار را در Store مرجع خود اتمیک Commit کند.
- Ordering به‌ازای Aggregate/Partition تعریف شود؛ Ordering سراسری فرض نشود.
- Sequence Gap، Event قدیمی/Poison، پایان Retry و Quarantine مدیریت صریح داشته باشند.
- Publisher پس از Lease Loss از Mutation وضعیت داخلی محافظت‌شده منع شود؛ اثر Downstream همچنان Idempotency Receiver می‌خواهد.
- Ack تحویل فقط در نقطه تعریف‌شده قرارداد Consumer صادر شود.

### ۶.۴ موارد خصمانه

ارسال Worker قدیمی پس از Lease Loss؛ پذیرش Downstream و گم‌شدن پاسخ؛ Timeout پیش/پس از اعمال اثر؛ Duplicate هم‌زمان؛ Key یکسان/Request متفاوت؛ انقضای پنجره Deduplication Receiver؛ Event نامرتب؛ Sequence Gap؛ عدم دسترسی Receiver هنگام Reconciliation؛ شکست Compensation؛ Rotation Credential هنگام Retry.

**Evidence خروج:** فهرست مقصدها؛ قرارداد Receiver راستی‌آزمایی‌شده یا حذف صریح از Scope؛ Evidence Retention؛ History سرتاسری Duplicate/Timeout؛ مرز تضمین مستند.

## ۷. Retention، Tombstone، Replay و Restore — A21-F05/F10

### ۷.۱ استخراج Retention

برای هر رکورد دارای Identity (Receipt، Inbox/Dedup Marker، Tombstone، Outbox، Consumer Inbox، Audit Evidence)، معنای چرخه عمر ایجاد، فعال، واجد شرایط انقضا، منقضی و Legal Hold تعریف شود.

افق حداقل حفاظت Identity باید طولانی‌ترین مسیر Replay/Recovery مصوب را پوشش دهد، نه فقط Retry عادی Queue. Worksheet چرخه عمر هر افق، منبع، کران قراردادی/اندازه‌گیری‌شده، عدم قطعیت، محدودیت قانونی، مالک و تصویب را ثبت کند.

اگر حداکثر متناهی قابل اثبات نیست:
- انقضای متناهی اختراع نشود؛
- Identity دائمی/غیرقابل استفاده مجدد یا Epoch/Namespace Rollover با Cutover اثبات‌شده استفاده شود؛ یا
- Qualification تا دریافت Evidence مبدأ/اپراتور مسدود بماند.

تعهدات Privacy/Deletion باید با Integrity مالی/Audit از طریق طراحی جداگانه و مصوب Data Minimization یا Cryptographic Erasure سازگار شود. حذف قانونی مجوز حذف تنها مدرک Deduplication و بازگشایی Replay نیست.

### ۷.۲ Gate بازیابی

محیط Restoreشده MUST در Quarantine شروع شود: Ingress/Worker غیرفعال، Egress خارجی مسدود، Credential ایزوله و بدون دسترسی زنده Partner/Payment/Production Control Plane. بازگشایی نیازمند:
- Evidence صحت زنجیره Backup و WAL/PITR؛
- سازگاری Schema/Application/Config؛
- وضعیت Key Hierarchy و Decryptability/Revocation؛
- بررسی Tenant Isolation؛
- تطبیق Identity/Tombstone High-water Mark؛
- تطبیق Queue/Outbox/Inbox و برنامه Replay؛
- اثبات Reset مربوط به Authority Epoch/Fencing؛
- تطبیق Ledger/Source-to-Ledger در صورت کاربرد؛
- صحت Observability/Audit Evidence؛
- نتیجه RPO/RTO مصوب مالک و پذیرش Residual Risk.

بالا آمدن Database اثبات Recovery دامنه نیست. Restore فاقد State هویت/Tombstone نباید Ingress را باز کند. Authority قدیمی بازیابی‌شده باید از نوشتن Fenced شود.

### ۷.۳ سناریوهای لازم Restore

Restore پیش/پس از Event Commitشده؛ Backup ناقص و شکاف WAL؛ Backup قدیمی پس از انقضای Tombstone؛ پیام Broker دیررس پس از Restore؛ ازدست‌رفتن KMS/Key Service؛ Key لغوشده/چرخیده؛ Credential تسخیرشده در Backup؛ مهاجرت Tenant؛ Failback با بازگشت Primary قدیمی؛ Outbox منتشرشده پیش از Checkpoint با اثر Receiver نامعلوم.

**Evidence خروج:** افق/راهبرد چرخه عمر مصوب؛ رویه Clean-room Restore؛ Oracleهای Reconciliation؛ اثبات Isolation؛ گزارش Restore در سطح Domain. Retention/RPO/RTO عددی تا Evidence مالک باز می‌ماند.

## ۸. قرارداد Oracle، Evidence و نتیجه — رابط A21-F06/A21-F08

A22 استقلال Oracle را ادعا نمی‌کند؛ A24 Trust Boundary را ارزیابی می‌کند. هر Test Record باید Assertion/Property؛ نسخه/پیاده‌سازی Oracle و Query/Algorithm دقیق؛ منبع داده/Consistency؛ وابستگی‌های مشترک با System Under Test؛ Credential/Admin/Clock/Failure Domain؛ مسیر Evidence خام/Hash/منبع Timestamp/Custody؛ کنترل کامل‌بودن و Blind Spotها را مشخص کند.

وضعیت آزمون:
- PASS: همه Assertionهای لازم ارزیابی، Evidence کامل و Integrity آن بررسی شده و در Scope اعلام‌شده History ممنوع مشاهده نشده است.
- FAIL: حداقل یک Assertion لازم به‌طور اثبات‌پذیر نقض شده است.
- INCONCLUSIVE: Evidence/Oracle/Fault Schedule ناقص، ناسازگار یا مبهم است؛ استنباط PASS ممنوع.
- NOT_RUN: اجرا نشده است.
- BLOCKED: پیش‌شرط، تصمیم مالک، مجوز یا محیط مفقود است.

Log مفقود، Oracle خراب، Clock راستی‌آزمایی‌نشده یا Fault Injection غایب نباید PASS شود. نتایج Performance، Availability، Correctness و Recovery جدا گزارش شوند. تعداد تکرار، مدت و Threshold به اهداف Workload/Risk مصوب مالک نیاز دارد.

## ۹. ایزولاسیون مالی و Production — A21-F09

تحقیق/طراحی A20/A22 هیچ اجازه‌ای برای اتصال به یا تغییر سامانه مالی واقعی صادر نمی‌کند.

هر Fixture آزمون آینده، فقط با مجوز جداگانه، باید ساختگی، ایزوله، غیرقابل Settlement و ناتوان از آغاز Payment واقعی، Wallet Transfer، تغییر موجودی Partner، Withdrawal، Prize، Player Transaction یا Posting به Ledger تولید باشد. Evidence ایزولاسیون باید هویت Environment/Account/Project و Network Topology؛ نبود Credential/Trust Path تولیدی؛ Egress با پیش‌فرض Deny و Allowlist صریح؛ نبود داده شخصی واقعی؛ شناسه و Namespace دفترکل ساختگی؛ اثبات عدم دسترسی به Endpointهای Payment/Provider؛ و Log نبود اثر مالی واقعی را شامل شود.

A20-27 فقط Assertion خالص Model/Fixture است، مگر مجوز کتبی جداگانه مالک و Gateهای مرتبط وجود داشته باشد. A22 چنین مجوزی نیست.

## ۱۰. حداقل معنای Test Record ماشین‌خوان

JSON، YAML یا سامانه مدیریت آزمون قابل انتخاب است، اما Record باید این معنا را داشته باشد:

    test_record:
      test_id: REQUIRED
      specification_version: REQUIRED
      trace_ids: [REQUIRED]
      scenario_id: REQUIRED
      candidate:
        product: OPEN_UNTIL_SELECTED
        version_edition: REQUIRED_AT_EXECUTION
        topology_config_hash: REQUIRED_AT_EXECUTION
      environment:
        isolation_proof: REQUIRED
        synthetic_data_only: true
        production_connectivity: PROVEN_ABSENT
      preconditions: REQUIRED
      fault_schedule:
        seed: REQUIRED
        ordered_steps: REQUIRED
      assertions:
        - invariant_id: REQUIRED
          expected: REQUIRED
          oracle_id: REQUIRED
          observed: REQUIRED
          result: PASS | FAIL | INCONCLUSIVE
      evidence:
        artifacts: REQUIRED
        integrity_hashes: REQUIRED
        clock_source: REQUIRED
        custody: REQUIRED
      run:
        started_at: REQUIRED
        ended_at: REQUIRED
        executor: REQUIRED
        reviewer: REQUIRED
      overall_result: PASS | FAIL | INCONCLUSIVE | NOT_RUN | BLOCKED
      deviations: []
      residual_risk: REQUIRED
      owner_approval_ref: REQUIRED_WHEN_REQUIRED

Record نهایی باید تغییرناپذیر یا دارای تاریخچه اصلاح Append-only باشد. Overall PASS فقط وقتی معتبر است که تمام Assertionهای اجباری قبول و هیچ فیلد/Evidence لازم مفقود نباشد. Test نمی‌تواند استقلال خودش را خوداظهاری کند.

## ۱۱. ماتریس اصلاح A22

| یافته A21 | کنترل A22 | Evidence لازم برای بستن | وضعیت |
|---|---|---|---|
| F02 Identity/Dedup | §4 | تصویب OD، قرارداد نسخه‌دار، Vector و تست Migration | OPEN |
| F03 UNKNOWN Commit | §5 | State Machine، اثبات Linearization/Isolation و History رقابت | OPEN |
| F04 External Effects | §6 | قرارداد مقصدها و تست مرز کامل | OPEN |
| F05 Retention/Restore | §7 | افق مصوب، چرخه عمر و Evidence Clean-room Restore | OPEN |
| F06 Oracle Trust | §8 + A24 | ماتریس Trust Boundary، Negative Control و Corroboration | OPEN |
| A21-F07 Traceability | §3 | ماتریس دوطرفه کامل و بررسی Orphan | OPEN |
| A21-F08 Result Contract | §8 و §10 | Schema، طبقه‌بندی قطعی و Record کامل | OPEN |
| F09 Financial Boundary | §9 | اثبات Isolation و مجوز محدود | OPEN |
| F10 Recovery Controls | §7.2–7.3 | Evidence صحت Restore و تطبیق Domain | OPEN |

A22 پاسخ در سطح Specification است، نه Evidence پیاده‌سازی/اثربخشی کنترل. یافته‌ها فقط پس از بازبینی و پذیرش Evidence خروج توسط Approver مجاز بسته می‌شوند.

## ۱۲. موانع تصمیم مالک و Evidence

موارد زیر تا زمان ارائه و راستی‌آزمایی توسط مالک پاسخ‌گو OPEN می‌مانند:
- OD-01..OD-04: Source Identity، Namespace، Canonicalization و Fingerprint.
- OD-05..OD-07: Atomic Acceptance و Cardinality مربوط به Receipt/WorkItem.
- OD-08..OD-10: چرخه عمر Replay/Tombstone، Quarantine و Revocation.
- OD-11: UNKNOWN Outcome و قرارداد Client.
- OD-12: سیاست Retention/Independence شواهد.
- C-01..C-16: شخصیت حقوقی، حوزه قضایی، داده/Residency، پردازش، Retention، Custody کلید، Availability، Recovery، Latency، Workload، عملیات، Provider، هزینه، Portability و Audit Evidence.
- G1..G9: هیچ Gate بدون Evidence مصوب عبور نمی‌کند.

هیچ مقدار مثالی در A20/A22 نباید به Default یا تصمیم مالک ارتقا یابد.

## ۱۳. مبنای تحقیق

- RFC 9110 §9.2.2 — معنای Idempotent و Retry ایمن: https://www.rfc-editor.org/rfc/rfc9110.html
- Google Cloud Spanner — UNKNOWN Commit و خطر اثر جانبی تکراری: https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once
- AWS Prescriptive Guidance — Transactional Outbox، تحویل تکراری و Ordering: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- AWS Builders' Library — Timeout، Retry، Backoff، Jitter و تشدید Overload: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- PostgreSQL Transaction Isolation: https://www.postgresql.org/docs/current/transaction-iso.html
- PostgreSQL Constraints و Unique Constraints: https://www.postgresql.org/docs/current/ddl-constraints.html
- محدودیت‌های PostgreSQL pg_verifybackup: https://www.postgresql.org/docs/current/app-pgverifybackup.html
- NIST SP 800-53A Rev. 5 — برنامه‌ریزی ارزیابی و روش‌های Evidence: https://csrc.nist.gov/pubs/sp/800/53/a/r5/final
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html

این منابع ملاحظات طراحی پروتکل را پشتیبانی می‌کنند؛ صحت Lottorito را اثبات نمی‌کنند و تصمیم مالک را حل نمی‌کنند.

## ۱۴. وضعیت نهایی

- A22: اصلاحیه پیشنهادی Specification؛ صرفاً تحقیق.
- A21-F02 تا F10 در سطح ساختار مشخصات پاسخ داده شده‌اند؛ همگی تا Evidence مستقل از Implementation و بازبینی مجاز OPEN می‌مانند.
- کار Assurance مربوط به A21-F01/F06/F08/F13 همچنان نیازمند A24 است؛ هیچ ادعای استقلالی وجود ندارد.
- A20-01 تا A20-28: DESIGNED / NOT RUN.
- OD-01 تا OD-12 باز؛ C-01 تا C-16 باز؛ G1 تا G9 تست‌نشده/قبول‌نشده.
- ADR-002 پیشنهادی؛ A11-F01 تا F08 باز؛ A12 انجام‌نشده/غیرقابل ارزیابی.
- R0 مسدود؛ R1 صرفاً تحقیق؛ R2 شروع‌نشده؛ R3 غیرمجاز؛ A4 تصویب‌نشده.
- هیچ Runtime/Harness، انتخاب Candidate، اتصال Partner، عملیات مالی، دسترسی Production، Merge یا Deploy مجاز نیست.

**نتیجه:** A22 قراردادهای مفقود و تعهدات اثبات را صریح می‌کند و اختیار مالک را حفظ می‌کند؛ ادعا نمی‌کند سامانه اکنون این الزامات را برآورده کرده است.
