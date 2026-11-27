# G09-A12 — بسته بازبینی مستقل ADR-002

**شناسه سند:** LOT-AFFILIATE-G09-A12-001  
**نسخه:** ۰.۱.۰  
**تاریخ:** ۲۰۲۶-۱۱-۲۸  
**وضعیت:** بسته بازبینی آماده شده — بازبینی مستقل انجام نشده است  
**اسناد مرتبط:** LOT-AFFILIATE-G09-ADR-002 نسخه ۰.۳.۰؛ LOT-AFFILIATE-G09-A11-001؛ LOT-AFFILIATE-G09-A7-001؛ LOT-AFFILIATE-G09-A4-001؛ LOT-AFFILIATE-G09-A8-001  
**اختیار:** صرفاً آماده‌سازی بازبینی؛ بدون تصمیم مالک، مجوز Runtime، انتخاب فناوری، Merge یا Deploy.

## ۱. هدف و مرز بازبینی

این بسته، طراحی فعلی ADR-002 را برای بازبینی توسط فردی آماده می‌کند که نویسنده ADR، خودبازبینی A11 یا این بسته نبوده است. این سند خودِ بازبینی مستقل نیست و هیچ یافته‌ای را نمی‌بندد.

دامنه بازبینی فقط قرارداد منطقی پذیرش Ingress مصنوعی Affiliate و تطبیق نتیجه نامعلوم Commit است. نباید از آن تأیید Database، Queue، سرویس مرجعیت، توپولوژی، شریک، گردش مالی یا عملیات Production استنباط شود.

بازبین باید Artifactهای اصلی را در یک Commit SHA ثابت بررسی و پروتکل را مستقلاً بازسازی کند. اتکا به توضیح شفاهی، خلاصه‌های این بسته یا نتیجه‌گیری‌های قبلی همان نویسنده کافی نیست.

## ۲. استقلال و صلاحیت لازم بازبین

بازبین باید:
- نویسنده ADR-002، A11، A7 یا این بسته نباشد و در تدوین اسناد مورد بررسی مشارکت مؤثر نداشته باشد؛
- تعارض‌های استخدامی، مالی، سازمانی و تحویل مرتبط را افشا کند؛
- در Persistence تراکنشی/هم‌زمانی و تحلیل شکست سیستم‌های توزیع‌شده تجربه عملی کافی داشته باشد؛
- توانایی لازم برای چالش جداسازی Tenant، Fencing، Recovery، Replay و تمامیت Evidence را داشته باشد؛ در صورت ناکافی بودن تخصص، متخصص دوم اضافه شود؛
- به Commit دقیق اسناد با دسترسی فقط‌خواندنی دسترسی داشته باشد.

اگر استقلال یا صلاحیت قابل احراز نیست، نتیجه **NOT ASSESSABLE** ثبت شود؛ جلسه همتایان یا مرور شفاهی به‌عنوان بازبینی مستقل نام‌گذاری نشود.

## ۳. مجموعه ورودی ثابت‌شده بازبینی

در آغاز بازبینی، مخزن، PR، Base SHA، Head SHA، زمان، هویت/نقش بازبین، اظهارنامه تعارض و SHA-256 یا Blob SHA هر Artifact ثبت شود.

حداقل اسناد:
۱. ADR-002 نسخه ۰.۳.۰ به فارسی و انگلیسی.
۲. بازبینی خصمانه G09-A11 به هر دو زبان، شامل Crosswalk تعیین تکلیف.
۳. ردیابی ۴۷ سناریوی G09-A7 به هر دو زبان، شامل تمام Subcaseها.
۴. معماری اثبات Runtime در G09-A4 و هشت Gate تصویب.
۵. بازبینی خصمانه G09-A8 و در موارد مرتبط با Worker/Recovery، سند G09-ADR-001.
۶. LOT-EVENT-001، قرارداد Wire و مرز پذیرش امنیتی برای هویت، Schema و معنای پاسخ.
۷. هر دو Decision Register و اسناد Project Status.

تغییر SHA منبع، دامنه بازبینی دقیق همان Head را باطل می‌کند. بازبین باید مشخص کند تغییر صرفاً ویرایشی، معنایی یا مرتبط با ایمنی است و بخش‌های متأثر را دوباره بررسی کند.

## ۴. روش بازبینی — بازسازی خصمانه

بازبین باید مستقل از نو، State Machine و نقاط Happens-before/Linearization موارد زیر را ترسیم کند:
- پذیرش اولیه، ایجاد Receipt/WorkItem و پاسخ؛
- هویت تکراری و متعارض Event منبع؛
- Ingress هم‌زمان با هویت یکسان؛
- گم‌شدن پاسخ Commit و نتیجه نامعلوم؛
- رقابت Reconciliation با تراکنش اولیه درحال‌اجرا؛
- خرابی Primary، Promotion، بازگشت Primary قدیمی و Restore؛
- رقابت Quarantine با Claim توسط Worker؛
- Replay پس از انقضای Retention، Restore نسخه پشتیبان و Offboarding Tenant.

برای هر مسیر، مرجعی که اختیار تصمیم دارد، نقطه Serialization دقیق Persistence، مرز Enforcement، Evidence مستقل و نتیجه Fail-closed مشخص شود. گزاره متنی بدون مکانیزم قابل اعمال و Oracle ابطال‌پذیر کافی نیست.

به‌جای تأیید مسیر عادی، ضدنمونه بسازید. حداقل Scheduleهایی برای تولید (الف) دو جفت پذیرفته‌شده، (ب) ازدست‌رفتن جفت تأییدشده پس از Promotion، (ج) Write هم‌زمان از دو Primary، (د) تشخیص کاذب جفت ناقص، (هـ) Claim توسط Worker قدیمی پس از Quarantine، (و) پذیرش Replay پس از حذف Evidence Dedup و (ز) افشای وجود رکورد بین Tenantها را بررسی کنید.

## ۵. ماتریس بازبینی هر یافته

| یافته | پاسخ ADR-002 که باید بررسی شود | چالش مستقل و Evidence لازم برای بستن | وضعیت فعلی |
|---|---|---|---|
| A11-F01 — Durability/RPO مربوط به Commit تأییدشده | بخش‌های ۱۶.۴ و ۱۷.۲ | کلاس‌های خرابی پشتیبانی‌شده، Flush محلی، نقطه Acknowledgement Replication/Consensus، صلاحیت Promotion و انتخاب Recovery Point را تعریف کنید؛ Failover/Restore اجباری را بیازمایید؛ ثابت کنید Success/اجرای Worker از مرز Durability اعلام‌شده فراتر نمی‌رود. | OPEN |
| A11-F02 — Authority Epoch / Split-brain | بخش‌های ۱۷.۱ و ۱۷.۷ | ریشه مرجعیت را مشخص کنید و توضیح دهید چرا در Partition، Promotion و Restore Fork یا Rollback نمی‌شود. رد Epoch قدیمی را در تمام مسیرهای Write و در Enforcement Pointی که Writer قدیمی قادر به دورزدنش نیست اثبات کنید؛ بازگشت Primary قدیمی را بیازمایید. | OPEN |
| A11-F03 — Read منفی در برابر Commit درحال‌اجرا | بخش‌های ۱۶.۳، ۶ و ۷ | Schedule قطعی Commit اولیه/Retry و Promotion بسازید. Arbitration با همان کلید، پایان/Serialization تراکنش، Snapshot سازگار Reconciliation و دقیقاً یک برنده را اثبات کنید. Snapshot منفی به‌تنهایی اثبات Abort نیست. | OPEN |
| A11-F04 — Cardinality و Linkage جفت | بخش‌های ۴، ۱۶.۵ و ۱۷.۷ | یکتایی Receipt، حداکثر یک WorkItem برای هر Receipt، الزام Reference معتبر، تطابق دقیق Tenant/Installation و Enforcement در Commit/Capability در برابر حذف عمدی یک Write را اثبات کنید. حالت ناقص/خراب/Restore را بیازمایید. | OPEN |
| A11-F05 — نسخه‌بندی Fingerprint | بخش‌های ۳ و ۱۶.۶ | ابهام Parser، اعضای تکراری JSON، هم‌ارزی عددی/Unicode، تغییر Schema/Extension، مهاجرت نسخه Canonicalization و Vectorهای چندزبانه را به چالش بکشید. عدم استفاده مجدد بی‌صدای از Acceptance را اثبات کنید. | OPEN |
| A11-F06 — Idempotency محدود به Retention | بخش‌های ۳، ۱۲ و ۱۷.۳ | Replay Horizon را از قرارداد واقعی منبع و Policy حقوقی/حریم خصوصی تعیین کنید؛ Tombstone، Backup، Restore، Offboarding و Replay دیرهنگام را لحاظ کنید. دقیقاً مشخص کنید تضمین Dedup چه زمانی پایان می‌یابد. | OPEN |
| A11-F07 — دامنه Quarantine و DoS | بخش‌های ۴، ۱۶.۷ و ۱۷.۴ | ثابت کنید ورودی غیرقابل‌اعتماد نمی‌تواند به‌تنهایی Quarantine سراسری Tenant ایجاد کند؛ Scope مرحله‌ای، مجوز، Audit، انقضا/بازیابی، انصاف برای Tenantهای دیگر و Linearization رقابت Quarantine/Claim را بیازمایید. | OPEN |
| A11-F08 — تفکیک Accepted از Executed | بخش‌های ۱، ۵، ۸ و ۱۷.۵ | پاسخ Wire و منابع Status باید پذیرش پایدار را از Claim، Processing، Qualification و ثبت مالی جدا کنند؛ Duplicate همان Reference پایدار را برگرداند؛ WorkItem دوم یا افشای جزئیات داخلی امنیتی رخ ندهد. | OPEN |

بازبین باید آزاد باشد یافته جدید اضافه کند. صرف وجود یک پاراگراف متناظر در ADR دلیل PASS نیست.

## ۶. پوشش ردیابی A7 که باید راستی‌آزمایی شود

Manifest در A7 باید دقیقاً ۴۷ شناسه Canonical مربوط به A4 را بدون شماره‌گذاری مجدد، حذف یا جایگزینی نگه دارد. Subcaseها تکمیلی‌اند و باید جدا از Parent گزارش شوند.

موجودی مورد انتظار Extensionها:
- ۸ Subcase مربوط به A8؛
- ۹ Subcase مربوط به A11؛
- ۴ Subcase تکمیلی A10؛
- در مجموع ۲۱ شناسه Extension یکتا، با تطابق دقیق مجموعه و Parent در فارسی و انگلیسی.

نگاشت تکمیلی ADR-002:
- C18 ← A11-DUR-02b؛
- C19 ← A11-DUR-08b؛
- C20 ← A10-DUR-02d؛
- C21 ← A10-DUR-02e؛
- C22 ← A10-AUTH-06b؛
- C23 ← A10-IDEM-08a.

هر نگاشت باید با فایل‌های فعلی A7 بررسی شود، نه فقط با این فهرست. هر Case باید Fixture ساختگی نسخه‌دار، Stimulus/Schedule قطعی، Assertion پروتکل و مجوز، Assertion مستقیم Persistence، Assertion عدم اثر مالی، Oracle مستقل، منشأ Evidence و وضعیت صریح NOT RUN/BLOCKED داشته باشد؛ مگر اینکه اجرای مجاز واقعاً انجام شده باشد. PASS والد نباید شکست یا اجرا‌نشدن Subcase را پنهان کند.

## ۷. چالش Oracle مستقل و Evidence

برای هر اثبات آتی مختص Candidate، Evidence مستقل زیر لازم است:
۱. مشاهده Client/API (نه Oracle مربوط به Commit).
۲. بررسی فقط‌خواندنی Persistence معتبر، با ثبت Consistency Mode و شناسه مرجع.
۳. Trace تراکنش/Constraint برای اثبات Atomicity و Arbitration با کلید یکسان.
۴. Query مستقیم Cardinality/Linkage در یک Snapshot سازگار.
۵. رکورد Fault-injection Controller که رسیدن به نقطه خرابی هدف را نشان دهد.
۶. Evidence مربوط به Authority Epoch/Fencing از Enforcement Boundary.
۷. Evidence عدم دسترسی مالی در Credential، Service Binding، Network/DNS، Queue و مسیرهای غیرمستقیم.
۸. Manifest تغییرناپذیر Evidence با Source SHA، شناسه Build/Config، زمان معتبر، Correlation ID و Integrity Hash.

Logهای خود سامانه Oracle مستقل نیستند. Dashboard، HTTP 202، CI سبز مستندات یا خواندن Replica بدون Consistency مستند، State پایدار را اثبات نمی‌کند.

## ۸. پرسش‌هایی که باید صریحاً باز بمانند

بازبین نباید به‌جای مالک، پاسخ این پرسش‌ها را حدس بزند:
- کدام Source Namespace و Scope هویت Event مرجع است؟
- Scope، Binding Fingerprint و Retention مربوط به Request Idempotency-Key چیست؟
- Replay Horizon و Policy مربوط به Tombstone/Legal Hold/Deletion چیست؟
- Failure Model، RPO/RTO مربوط به Write تأییدشده و کلاس‌های Recovery چیست؟
- چه Authority Rootی تخصیص Epoch غیرقابل-Fork و Fencing قابل اعمال بیرونی را فراهم می‌کند؟
- قرارداد Consistency/Isolation/Serialization موردنیاز چیست؟
- Invariant دقیق جفت در مرز Commit/Capability چگونه اعمال می‌شود؟
- کدام پروفایل Fingerprint/Parser و Policy سازگاری/مهاجرت تصویب می‌شود؟
- چه کسی، در چه Scopeی، با چه فرایند Review/Expiry/Recovery حق Quarantine دارد؟
- حدود Retry/Resource برای Reconciliation و SLO عملیاتی چیست؟
- آیا DeliveryOutbox لازم است و مالک Atomicity/Lifecycle آن کیست؟
- قواعد Retention، حریم خصوصی، حذف، Backup و Legal Hold مربوط به Evidence چیست؟

پاسخ نامعلوم باید OPEN/BLOCKED بماند؛ عدد یا Default محتمل Vendor را جایگزین تصمیم مالک نکنید.

## ۹. رکورد نتیجه بازبینی مستقل

بازبین مستقل باید Disposition جداگانه و امضاشده‌ای تولید کند که شامل موارد زیر باشد:
- Repository/PR/Head SHA ثابت و Hash اسناد؛
- صلاحیت بازبین، اظهارنامه استقلال/تعارض و تاریخ بازبینی؛
- روش‌ها، ابزارها و Failure Scheduleهای بررسی‌شده؛
- نتیجه هر یافته: **ACCEPTED**، **ACCEPTED WITH CONDITIONS**، **REJECTED** یا **NOT ASSESSABLE**؛
- ضدنمونه دقیق، Reference شواهد و اصلاح لازم برای هر مورد غیرپذیرفته؛
- یافته‌های جدید و A4/A7 IDهای متأثر؛
- تصریح اینکه ADR-002 برای تصمیم مالک آماده است، هنوز به بازطراحی نیاز دارد یا قابل ارزیابی نیست.

نویسنده با ویرایش این بسته هیچ یافته‌ای را نمی‌بندد. بستن یافته به Disposition مستند و مبتنی بر Evidence بازبین مستقل و هر تصمیم لازم مالک پاسخ‌گو نیاز دارد. اگر تخصص یک حوزه مهم خارج از صلاحیت بازبین اصلی است، بازبین متخصص دوم لازم است.

## ۱۰. شرایط توقف و عدم صدور مجوز

اگر طراحی امکان Write در Split-brain، ازدست‌رفتن Commit تأییدشده خارج از RPO اعلام‌شده، ایجاد جفت تکراری، افشای بین Tenantها، Mutation توسط Worker قدیمی پس از Fencing، Replay نامحدود بدون تضمین صریح، Quarantine گسترده با ورودی غیرقابل‌اعتماد یا دسترسی مالی از Ingress را بدهد، بازبینی با نتیجه **REJECTED** یا **NOT ASSESSABLE** متوقف شود.

این بسته ADR-002 را تصویب نمی‌کند، A11-F01 تا F08 یا یافته‌های A7/A8 را نمی‌بندد، هیچ Gate از A4 را تصویب نمی‌کند، فناوری انتخاب نمی‌کند و مجوز اجرای Runtime/Harness، اتصال شریک، پردازش مالی، Merge یا Deploy صادر نمی‌کند.

## ۱۱. منابع مرجع

- PostgreSQL Transaction Isolation: https://www.postgresql.org/docs/current/transaction-iso.html
- PostgreSQL High Availability و Failover: https://www.postgresql.org/docs/current/high-availability.html
- PostgreSQL Synchronous Replication: https://www.postgresql.org/docs/current/warm-standby.html
- هشدارهای PostgreSQL درباره Failover و Fencing Primary قدیمی: https://www.postgresql.org/docs/current/warm-standby-failover.html
- پنجره Durability در PostgreSQL Asynchronous Commit: https://www.postgresql.org/docs/current/wal-async-commit.html
- PostgreSQL Constraints: https://www.postgresql.org/docs/current/ddl-constraints.html
- Google Cloud Spanner Unknown Commit Status: https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once
- AWS Transactional Outbox: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- RFC 8785 JSON Canonicalization Scheme: https://www.rfc-editor.org/rfc/rfc8785
- NIST SP 800-204D: https://csrc.nist.gov/pubs/sp/800/204/d/final

این منابع ورودی ارزیابی‌اند؛ نه انتخاب فناوری و نه Evidence پیاده‌سازی تضمین‌های مذکور در Lottorito.
