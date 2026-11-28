# G09-A19 — ماتریس محدودیت‌های استقرار و احراز صلاحیت Candidateها

**شناسه سند:** LOT-AFFILIATE-G09-A19-001  
**نسخه:** 1.0.0

**شناسه پرونده:** `LOT-AFFILIATE-G09-A19-001`  
**تاریخ:** ۲۰۲۶-۱۱-۲۸  
**وضعیت:** تحقیق و کشف محدودیت‌ها — بدون تصمیم استقرار یا انتخاب فناوری  
**سند والد:** G09-A18 — ارزیابی معماری Candidateهای Persistence و Authority  
**دامنه:** مرز پذیرش رویداد مالی Affiliate، Idempotency، ثبت Ledger، Inbox/Outbox، شواهد و بازیابی.

## ۱. تعیین تکلیف مدیریتی

G09-A19 خانواده‌های Candidate در G09-A18 را به یک فرایند احراز صلاحیت مبتنی بر محدودیت تبدیل می‌کند. این سند **هیچ Cloud، Region، Database، Topology، سرویس Managed، حوزه قضایی، RPO/RTO عددی، دوره نگهداری یا بودجه‌ای را انتخاب نمی‌کند.**

**تصمیم فعلی: هیچ Candidateای احراز صلاحیت نشده است.** امتیازدهی Candidateها تا زمان دریافت محدودیت‌های الزامی و شواهد به‌تعویق می‌افتد. هیچ امتیاز وزنی نباید شکست در Gate حقوقی، Residency، امنیت، صحت مالی یا بازیابی را جبران کند.

سؤال اول «بهترین دیتابیس کدام است؟» نیست؛ سؤال این است: «کدام Footprint استقرار، برای کلاس‌های داده و تضمین‌های خرابی مشخص، از نظر حقوقی، قراردادی، عملیاتی و فنی مجاز است؟» فقط پس از پاسخ مستند به این سؤال می‌توان محصولات دیتابیس را منصفانه مقایسه کرد.

## ۲. دامنه و موارد خارج از دامنه

داخل دامنه:
- پذیرش authoritative رویداد شریک خارجی؛
- هویت رویداد، Idempotency و Cardinality مربوط به Receipt/WorkItem؛
- Journal مالی و وضعیت Commission؛
- Inbox/Outbox، Replay، Quarantine و شواهد Audit؛
- Backup، Restore، Failover، Fencing و وابستگی‌های Credential/Key؛
- مکان داده و Metadata در کل زنجیره سرویس.

خارج از دامنه:
- انتخاب کشور میزبانی یا Provider تولیدی؛
- نتیجه‌گیری حقوقی درباره هر مشتری، Operator، کشور یا مجوز Gaming؛
- تعیین Availability، RPO، RTO، Retention یا Latency عددی؛
- تأیید Vendor، قرارداد تجاری، DPA یا انتقال برون‌مرزی؛
- Proof مربوط به Runtime، Migration تولید، اتصال واقعی شریک، عملیات مالی، Merge یا مجوز Deploy.

## ۳. اصول حاکم

۱. **ابتدا محدودیت، سپس امتیازدهی.** محدودیت سخت Pass/Fail است. مدل امتیازدهی فقط میان Candidateهایی به‌کار می‌رود که تمام Hard Gateهای مرتبط را پاس کرده‌اند.

۲. **مکان داده یک ویژگی کل سیستم است.** فقط ردیف‌های Database مطرح نیستند. Application Compute، Queue، Cache، Object Storage، Backup، Snapshot، Log، Trace، Metric، Support Bundle، Control-plane Metadata، Identity، KMS/HSM، CDN/WAF، Email/SMS، Analytics، Fraud Tooling، CI Artifact و دسترسی تیم پشتیبانی Vendor هم باید بررسی شوند.

۳. **Residency فقط محل ذخیره‌سازی نیست.** محل Storage، محل Processing، دسترسی Remote، انتقال بعدی، دسترسی Support، Telemetry، Subprocessor، کنترل Encryption Key و تعهد حذف داده را جداگانه بررسی کنید. بررسی حقوقی باید برای حوزه قضایی مشخص انجام شود؛ صفحات بازاریابی Provider مشاوره حقوقی نیستند.

۴. **Residency و Resilience ممکن است تعارض داشته باشند.** Replication هم‌زمان بین Regionها ممکن است تحمل خرابی را بهتر کند، اما با الزام نگهداری داده در یک کشور ناسازگار باشد. Read Replica، Witness، Backup یا Telemetry نیز ممکن است پرسش مکانی مستقلی ایجاد کند.

۵. **ادعای Provider معادل Proof استقرار نیست.** Service-specific Terms، دسترس‌پذیری Region/Service، پیکربندی Topology، شواهد کنترلی، نتایج تست و تعهدات قراردادی لازم است.

۶. **Unknown به معنی Pass نیست.** موارد نامعلوم باید OPEN / NOT EVIDENCED ثبت شوند؛ نه اینکه با فرض خوش‌بینانه منطبق تلقی شوند.

۷. **صحت مالی بر Availability مقدم است.** در وضعیت عدم قطعیت، پذیرش authoritative جدید باید Fail-closed شود؛ نه اینکه رویدادی تأیید شود که ممکن است بعداً ناپدید یا دوباره ثبت شود.

## ۴. رجیستر محدودیت‌ها — ورودی‌های الزامی مالک

هر ردیف باید دارای مقدار، منبع، مالک پاسخ‌گو، تاریخ، دامنه و لینک Evidence باشد. هیچ مقداری از روی حدس تکمیل نمی‌شود.

| شناسه | حوزه محدودیت | سؤال یا مدرک الزامی | نوع Gate |
|---|---|---|---|
| C-01 | شخصیت حقوقی قراردادی | کدام شخصیت حقوقی اپراتور Lottorito است و هر Tenant/Provider با کدام شخصیت حقوقی قرارداد می‌بندد؟ | سخت |
| C-02 | حوزه قضایی مشتری/اپراتور | شخصیت‌های حقوقی، کشورهای فعالیت، مجوزها و تعهدات قراردادی اولین Tenant دقیقاً چیست؟ از Pilot پیشنهادی نتیجه‌گیری نکنیم. | سخت |
| C-03 | موضوع داده و طبقه‌بندی | چه اشخاص و کلاس‌های داده‌ای پردازش می‌شوند: هویت Partner، شناسه Player، سوابق مالی/Commission، Credential، محتوای Support و Telemetry؟ طبقه‌بندی و حداقل‌سازی لازم است. | سخت |
| C-04 | مرز Residency | برای هر کلاس داده، کدام کشور/Region مجاز، الزامی، ممنوع یا مشروط به انتقال است؟ | سخت |
| C-05 | مرز Processing و Access | آیا Remote Support، دسترسی Admin، Subprocessor، پردازش Control-plane یا Telemetry خارج از Region ذخیره‌سازی مجاز است؟ تحت چه کنترل‌هایی؟ | سخت |
| C-06 | نگهداری و حذف | Retention، Legal Hold، Deletion، انقضای Backup و محدودیت‌های Ledger تغییرناپذیر چیست؟ تعارض تعهدات چگونه حل می‌شود؟ | سخت |
| C-07 | مالکیت و کنترل Key | چه کسی کنترل Encryption Key، محل Key، Rotation، Revocation، Recovery و Break-glass را دارد؟ Provider-managed Key پذیرفتنی است؟ | سخت |
| C-08 | هدف Availability | کدام سرویس‌های قابل‌مشاهده برای کاربر و داخلی نیازمند Availability هستند و باید در برابر کدام دامنه خرابی دوام بیاورند؟ | تصویب کسب‌وکار |
| C-09 | RPO/RTO | تحلیل اثر کسب‌وکار باید Data Loss و Recovery Time قابل‌تحمل را برای هر قابلیت جداگانه تعیین کند، نه یک عدد کلی. | تصویب کسب‌وکار |
| C-10 | Latency | p50/p95/p99 موردنیاز برای پذیرش رویداد، Commit دفترکل، خواندن و Workflow اپراتور چیست؟ بار کاری و جغرافیای مبنا کدام است؟ | هدف قابل‌اندازه‌گیری |
| C-11 | دامنه بار | نرخ معمول و اوج رویداد، مدت Burst، تعداد Tenant، اندازه Event، رشد Retention، Writerهای هم‌زمان و Replay Backlog چقدر است؟ | هدف قابل‌اندازه‌گیری |
| C-12 | عملیات | چه کسی می‌تواند Operate، Patch، Failover، Restore و Incident را مدیریت کند؟ ساعات پوشش، Escalation، مهارت، Runbook و تفکیک وظایف چیست؟ | Gate عملیاتی سخت |
| C-13 | محدودیت Provider | Providerهای مجاز، مالکیت Account، دسترس‌پذیری Region، استثناهای Service، محدودیت تحریم/Export و Procurement چیست؟ | سخت |
| C-14 | سقف هزینه | بازه بودجه و مالک هزینه Compute، Storage، Replica، Network Egress، Backup، Observability، Support و DR Drill چیست؟ | تصویب مالک |
| C-15 | خروج و Portability | فرمت Export، قابلیت Restore، Portability، مهلت Migration، خروج از Vendor، شواهد حذف داده و فهرست وابستگی‌ها چیست؟ | سخت |
| C-16 | Audit و Evidence | کلاس‌های Log، Immutability، بازبینی دسترسی، Retention، خروجی Evidence و سطح Assurance مستقل موردنیاز چیست؟ | سخت |

**Artifact الزامی قبل از امتیازدهی:** یک Constraint Decision Record تصویب‌شده شامل C-01 تا C-16 با توجیه صریح `NOT APPLICABLE` در موارد مرتبط. تحقیق واقعیت‌ها می‌تواند تفویض شود، اما تأیید حقوقی و تجاری بر عهده انسان‌های پاسخ‌گوی مجاز است.

## ۵. فهرست جریان داده و مکان‌یابی

برای هر جریان داده و سرویس یک ردیف بسازید. همه‌چیز را در عبارت «Database» خلاصه نکنید.

| Plane / مؤلفه | داده‌هایی که باید بررسی شوند | پرسش مکان | Evidence موردنیاز |
|---|---|---|---|
| API / Application Compute | Request Body، Auth Context، Memory، فایل موقت | Region اجرا، Failover و Debug Dump | Topology استقرار، Terms سرویس، خروجی Config |
| Primary Database | Event Canonical، Receipt، WorkItem، Ledger، Tenant Metadata | Primary، Replica، محل Quorum/Witness | Topology دقیق، Config Replication، Terms سرویس |
| Queue / Broker | Payload رویداد، Offset، Delivery Metadata | Broker، Replica، DLQ و Control Plane | نقشه Region، Retention و Config Replication |
| Cache / Redis | Token، Lock، Dedupe Hint، State موقت | Node، Replica، Snapshot و Persistence | Config و طبقه‌بندی داده؛ نباید Authority مالی یگانه باشد |
| Object Storage | Backup، Export، Evidence و Attachment | Region Bucket، Replication، Versioning | Bucket Policy، Replication Rule، Lifecycle |
| Backup / DR | Base Backup، WAL، Snapshot و Replica | مقصد Copy، Vault و محیط Restore | Restore Test، Immutability، Expiry و Access Log |
| KMS / HSM | Key Material، Metadata و Wrapping Key | Region کلید، Replica، Control Plane و Recovery | Key Policy، Audit Log و Recovery Procedure |
| Observability | Log، Trace، Metric و Payload خطا | Collector، Vendor SaaS و Support Export | Redaction، Terms مکان داده و Retention |
| Identity / Secrets | هویت User/Admin، API Key و Secret | Region مربوط به IdP، Support Access و Backup | DPA/Terms، MFA، RBAC و Break-glass Log |
| Edge / CDN / WAF | IP، Request Metadata و محتوای Cache | Edge Processing، Log Export و Origin | Data Map فروشنده، Cache و Logging Policy |
| CI/CD / Artifact | Schema، Fixture، داده تست، Secret و Build Artifact | Region Runner و Retention Artifact | Fixture پاک‌سازی‌شده، Secret Scanning و Retention |
| Support / Subprocessor | Ticket، Screen Share و Diagnostic Bundle | محل دسترسی انسان و Subprocessor | مدل قراردادی دسترسی و Audit Trail |

یک ردیف Data-flow کامل نیست مگر اینکه Source، Destination، Purpose، Data Class، مرز Tenant، محل Storage/Processing/Access، Encryption Boundary، Retention، مسیر Deletion، Subprocessor، Owner و Evidence را مشخص کند.

## ۶. خانواده‌های Candidate — احراز صلاحیت مشروط، نه رتبه‌بندی

| خانواده Candidate | نقاط قوت بالقوه | محدودیت‌ها و Failure Modeهای مهم | حداقل Evidence لازم |
|---|---|---|---|
| PostgreSQL HA مهندسی‌شده (Self-managed) | Semantics رابطه‌ای شناخته‌شده؛ طراحی صریح WAL/Replication/Failover؛ انعطاف استقرار | مسئولیت Fencing، Orchestration، Backup/Restore، Patch، Monitoring و Quorum بر عهده تیم است؛ Promotion ناهم‌زمان در طراحی غلط می‌تواند داده تأییدشده را از دست بدهد | Topology بازتولیدپذیر؛ تنظیم Sync و Standby Quorum؛ اثبات STONITH/Fencing؛ Split-brain Test؛ PITR/Restore Drill؛ Latency و برنامه On-call/Patch |
| Managed PostgreSQL HA | کاهش عملیات زیرساخت؛ قابلیت‌های Provider برای Patch/Failover | ممکن است HA فقط در سطح Zone باشد؛ Semantics مربوط به Failover، تأیید Replication، Backup Region، Read Replica و Control Plane وابسته به Service است | SKU/Region/Service دقیق؛ Contract/SLA؛ Semantics مربوط به Sync Commit؛ Failover؛ مکان Backup؛ Restore Proof؛ Support Access و Data Location Terms |
| CockroachDB (Edition و Topology مشخص) | Distributed SQL، تراکنش Serializable، Replication خودکار و کنترل‌های Locality/Survival | Quorum بین Regionها می‌تواند Write Latency را بالا ببرد؛ Retry بخشی از قرارداد Application است؛ Region Survivability نیازمند Topology و Config مشخص است؛ پشتیبانی Edition/Region متفاوت است | Release/Edition دقیق؛ Topology و Locality؛ Survival Goal؛ تست Retry تراکنش؛ Failure-domain Test؛ مکان Region/Metadata؛ Terms و Cost |
| YugabyteDB (محصول/Deployment مشخص) | PostgreSQL-compatible API؛ Raft Replication؛ گزینه Self-managed و Managed؛ قابلیت Geo-partitioning | Replication هم‌زمان پیش‌فرض بین Regionها می‌تواند همه داده را در Regionها کپی کند؛ Geo-partitioning و xCluster Semantics متفاوت دارند؛ Operations و Compatibility باید Verify شوند | Product/Version دقیق؛ RF و Topology؛ نقشه Geo-partition؛ جهت/Consistency مربوط به xCluster؛ Failure Test؛ Restore؛ PostgreSQL Compatibility و مدل عملیات |
| Google Cloud Spanner (Configuration مشخص) | Distributed SQL مدیریت‌شده؛ Serializable/External Consistency؛ Topologyهای Regional و Multi-region | Configurationهای مکانی محدودند؛ Quorum چندمنطقه‌ای ممکن است کشورها/Regionها را درگیر کند؛ Geo-partitioning استثناهای مستند Metadata/Statistics دارد؛ Lock-in و Cost | Instance Configuration دقیق؛ انطباق Location؛ Data-residency Terms؛ Caveatهای Geo-partition؛ تست Transaction و UNKNOWN Commit؛ Export/Exit؛ Region Failure و Cost |
| تفکیک Authority از Durable Store و Outbox | مرز پذیرش authoritative رویداد را شفاف می‌کند؛ امکان جداسازی Event Identity/Fencing از پردازش پایین‌دستی | اجزای بیشتر؛ نباید دو Authority مستقل یا پذیرش مالی غیراتمیک بسازد؛ Atomicity و Reconciliation بین Storeها دشوار می‌شود | مدل رسمی Authority؛ یک Source of Truth با Linearizability برای Identity؛ مرز Commit تراکنش؛ Reconciliation Proof؛ نبود Dual-write Gap؛ تست Recovery و سازگاری Restore |

هیچ خانواده‌ای صرفاً با نام محصول Pass نمی‌شود. احراز صلاحیت برای Product، Edition، Version، Region، Topology، Contract و Configuration دقیق انجام می‌شود.

## ۷. Hard Gateهای احراز صلاحیت

تمام Gateهای مرتبط دودویی هستند. شکست یا نبود Evidence، Candidate را مسدود می‌کند و مزیت امتیازی نمی‌تواند آن را جبران کند.

| Gate | شرط Pass | Evidence خصمانه الزامی |
|---|---|---|
| G1 — پذیرش حقوقی و Residency | تمام جریان‌های Storage، Processing، Remote Access، Telemetry، Backup، Key و Subprocessor با محدودیت‌های تصویب‌شده سازگار باشند | Data-flow/Location Inventory به‌همراه بررسی حقوقی/قراردادی؛ تست Region Restriction و استثناهای Service |
| G2 — مرز Tenant و Security | Tenant Isolation، Least Privilege، Encryption، Key Control، Support Access و Audit قابل‌اعمال باشند | تست خصمانه Cross-tenant؛ بازبینی دسترسی Privileged؛ شواهد Rotation/Revocation کلید و Break-glass |
| G3 — پذیرش authoritative یگانه | دقیقاً یک تصمیم authoritative برای Identity/Acceptance وجود داشته باشد؛ Split-brain یا Writer قدیمی نتواند Commit کند | Network Partition، Primary قدیمی، Process با تأخیر، انقضای Lease، Fencing Token و Failover Test |
| G4 — Semantics مربوط به Durability | API موفق فقط بعد از شرط دقیق Durable Commit پاسخ دهد؛ رویداد تأییدشده در خرابی‌های داخل Scope ناپدید نشود | Kill Primary/Standby، قطع شبکه، Storage Crash، Forced Promotion، مرز Commit-Ack و بررسی WAL/Quorum |
| G5 — صحت اتمیک مالی | Receipt، WorkItem و اثرات Journal متوازن، تحت Concurrency، Retry و Commit مبهم، Invariant و Uniqueness را حفظ کنند | Duplicate هم‌زمان، Key یکسان/Payload متفاوت، Crash در هر مرز Commit و Recovery نتیجه UNKNOWN |
| G6 — Recovery و Lifecycle | Backup/Restore، Identity، Tombstone، Journal، Revocation و Authority Epoch را سازگار حفظ کند؛ Retention/Deletion قابل‌اجرا باشد | Restore در محیط ایزوله؛ Replay رویداد قدیمی بعد از Restore؛ PITR، انقضای Backup، Offboarding Tenant و Key Loss/Recovery Drill |
| G7 — دوام عملیاتی | Operator مشخص، Patch/Upgrade Plan، Monitoring، Paging، Runbookهای Failover/Failback و Support Escalation وجود داشته باشد | Game Day با اپراتوری غیر از نویسنده؛ Restore/Failover در برابر هدف تصویب‌شده؛ Upgrade/Rollback Drill |
| G8 — Portability و Exit | داده، Schema، Evidence و وابستگی Key قابل Export/Recovery باشد؛ تعهدات خروج عملی باشند | Full Export/Restore Proof، Dependency Inventory، مسیر Deletion Certificate، Migration و Rollback Rehearsal |
| G9 — عملکرد و اقتصاد | SLOهای مختص Workload در بار عادی، افت کیفیت و Recovery پاس شوند؛ هزینه کل در سقف تصویب‌شده بماند | Load/Soak/Failure Test بازتولیدپذیر؛ p50/p95/p99؛ مدل هزینه Egress، Backup، Support، DR و رشد Storage |

**ترتیب Gateها:** G1 و G2 پیش‌غربالگری هستند. G3 تا G6 Gateهای صحت‌اند. G7 و G8 عملیاتی/خروجی‌اند. G9 فقط بعد از Pass شدن Gateهای قبلی ارزیابی می‌شود. هر Gate فقط با توجیه کتبی و تصویب Owner پاسخ‌گو می‌تواند NOT APPLICABLE شود.

## ۸. تحلیل اثر کسب‌وکار — RPO/RTO را اختراع نمی‌کنیم

RPO و RTO باید برای هر قابلیت از تحلیل اثر کسب‌وکار استخراج شوند. NIST SP 800-34 برنامه‌ریزی تداوم را به تحلیل اثر، راهبرد بازیابی، برنامه و تمرین مرتبط می‌کند؛ ISO 22301 چارچوب مدیریت تداوم کسب‌وکار را ارائه می‌دهد. این‌ها روش هستند، نه اعداد آماده.

برای هرکدام هدف جداگانه تعریف شود:
- پذیرش authoritative رویداد؛
- Availability و Read Access مربوط به Commission/Ledger؛
- Partner Portal و Reporting؛
- Analytics غیر authoritative؛
- Support/Chat و Notification؛
- Evidence Archive و Audit Export.

برای هر قابلیت، حداکثر Downtime قابل‌تحمل، حداکثر Data Loss قابل‌تحمل، Dependencyها، راهکار دستی، رشد Backlog، پنجره Reconciliation، ترتیب Recovery و تصویب Business Owner ثبت شود. برای Ledger authoritative، «سرویس برگشت» کافی نیست؛ کسب‌وکار باید روش تطبیق رویدادهای پذیرفته‌شده و صورت‌حساب‌های مالی پس از بازیابی را نیز تصویب کند.

## ۹. پروتکل اندازه‌گیری

Benchmark بازاریابی Vendor مبنای مقایسه نیست. همان Workload سطح Application و همان Failure Schedule باید روی هر Candidate دقیق اجرا شود:
- توزیع یکسان Event/Tenant و اندازه Payload؛
- نرخ واقعی Duplicate/Retry و Hot-key Contention؛
- مرز Transaction یکسان و Invariant مربوط به Journal متوازن؛
- پروفایل Steady، Burst، Soak و Replay Backlog؛
- خرابی Node، Zone، Region، Network، Disk و Credential؛
- از دست رفتن پاسخ Commit و نتیجه UNKNOWN؛
- Backup Restore و Failover/Failback؛
- ثبت Latency در p50/p95/p99، Throughput، Error Rate، سن Backlog، مدت Recovery و اقدامات Operator؛
- مدل هزینه کامل شامل Replica، Network Egress، Backup، Observability، Support و DR Drill.

Artifact خام Run، Hash پیکربندی، نسخه نرم‌افزار، Topology، Seed، Script تست، فرض‌های Clock، Parser نتایج و Oracle مستقل ثبت شود. اجراها تکرار شوند و Variance و Confidence Interval منتشر شود. صحت و Performance را در یک میانگین واحد ادغام نکنید.

## ۱۰. روش تصمیم‌گیری پس از دریافت محدودیت‌ها

۱. C-01 تا C-16 و Data-flow Inventory تکمیل شود.  
۲. برای هر Footprint مجاز، تأیید حقوقی/قراردادی اخذ شود.  
۳. Candidateهایی که در Region مجاز قابل Deploy نیستند یا محدودیت جریان داده را رعایت نمی‌کنند حذف شوند.  
۴. Product، Edition، Release، Topology و Configuration دقیق Candidateهای باقی‌مانده Pin شوند.  
۵. برنامه Evidence مربوط به G1 تا G8 اجرا شود؛ هر Gate ناموفق یا نامعلوم مانع Qualification است.  
۶. مقایسه عملکرد و اقتصاد G9 فقط برای Candidateهای Pass‌شده انجام شود.  
۷. Decision Record شامل Evidence، اختلاف‌نظر، ریسک باقیمانده، تاریخ/شرط بازاعتبارسنجی و تصویب‌های پاسخ‌گو منتشر شود.  
۸. پس از تغییر مهم در Terms Provider، Region، Edition، Topology، مدل Key، Subprocessor، کلاس داده، Traffic Profile یا رژیم حقوقی، Qualification تکرار شود.

در این پرونده هیچ امتیاز وزنی عددی تعریف نشده است. اگر بعداً استفاده شد، وزن‌ها و Thresholdها باید پیش از مشاهده Benchmark تصویب شوند و شکست Hard Gate همچنان ردکننده باقی بماند.

## ۱۱. برنامه Evidence و معیار خروج R1

R1 تا زمان تحقق موارد زیر صرفاً تحقیقاتی باقی می‌ماند:
- C-01 تا C-16 دارای مقدار تصویب‌شده یا N/A مستدل باشند؛
- Data-flow/Location Inventory کامل موجود باشد؛
- Shortlist به محصول/Regionهایی محدود شود که مستندات رسمی به‌روز و دسترس‌پذیری قراردادی دارند؛
- Ownerهای Evidence و Test Planهای G1 تا G9 مشخص باشند؛
- فرض‌های حل‌نشده آشکار و دارای Owner/Deadline باشند.

**خروج R1 مجوز Harness مربوط به R2 یا Proof تولیدی R3 نیست.** مجوز جداگانه و تصویب Gateهای A4 همچنان الزامی است.

## ۱۲. وضعیت فعلی پروژه

- G09-A19: پرونده تحقیق؛ بدون تصمیم استقرار.
- خانواده‌های Candidate: UNSELECTED / NOT QUALIFIED.
- C-01 تا C-16: OPEN / OWNER INPUT REQUIRED.
- G1 تا G9: NOT TESTED / NOT PASSED.
- ADR-002: PROPOSED.
- OD-01 تا OD-12: OPEN.
- A11-F01 تا F08: OPEN.
- بازبینی مستقل A12: NOT PERFORMED.
- R0: BLOCKED؛ R1: صرفاً تحقیق؛ R2: NOT STARTED؛ R3: NOT AUTHORIZED.
- Gateهای A4: NOT APPROVED.
- هیچ Provider، کشور، Region، Topology، Database، RPO/RTO عددی، Retention یا Budget انتخاب نشده است.
- هیچ Runtime، Partner، عملیات مالی، Merge یا Deploy مجاز نشده است.

## ۱۳. منابع

**مستندات اولیه محصول و پلتفرم**
- PostgreSQL، High Availability، Load Balancing و Replication: https://www.postgresql.org/docs/current/high-availability.html
- PostgreSQL، Synchronous Replication و Failover: https://www.postgresql.org/docs/current/warm-standby.html
- AWS، Data Privacy FAQ — انتخاب Region توسط مشتری و استثناها: https://aws.amazon.com/compliance/data-privacy-faq/
- Google Cloud، Spanner Instance Configurations و محل Replica/Quorum: https://docs.cloud.google.com/spanner/docs/instance-configurations
- Google Cloud، Spanner Data Residency و Caveatهای Geo-partition: https://docs.cloud.google.com/spanner/docs/data-residency
- Google Cloud، Assured Workloads Data Residency و تمایز Service Data: https://docs.cloud.google.com/assured-workloads/docs/data-residency
- YugabyteDB، Replication و Fault Tolerance: https://docs.yugabyte.com/stable/architecture/docdb-replication/replication/
- YugabyteDB، Multi-region Deployment و حالت‌های Residency: https://docs.yugabyte.com/stable/explore/multi-region-deployments/
- YugabyteDB، Production Universe Planning و Topology: https://docs.yugabyte.com/stable/yugabyte-platform/create-deployments/create-universes-overview/
- CockroachDB، مبانی Transaction و Retry: https://www.cockroachlabs.com/docs/stable/developer-basics.html

**روش‌های تداوم و Assurance**
- NIST SP 800-34 Rev. 1، راهنمای Contingency Planning: https://csrc.nist.gov/pubs/sp/800/34/r1/upd1/final
- ISO 22301:2019، Business Continuity Management Systems: https://www.iso.org/standard/75106.html
- Jepsen، تحلیل‌های صحت سیستم‌های توزیع‌شده: https://jepsen.io/analyses

**محدودیت Evidence:** مستندات Provider رفتار محصول و تعهدات اعلام‌شده را توصیف می‌کنند؛ این‌ها احراز صلاحیت مستقل Deployment موردنظر Lottorito نیستند. تفسیر حقوقی، بررسی قرارداد، دسترس‌پذیری Region، رفتار SKU دقیق و تست بازتولیدپذیر همچنان لازم‌اند.

**تعیین تکلیف نهایی:** G09-A19 فقط فرایند کشف محدودیت و احراز صلاحیت را تعریف می‌کند. هیچ Candidate انتخاب یا Qualify نشده است.