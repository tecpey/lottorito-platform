# P-10F — چارچوب آمادگی عملیاتی، راستی‌آزمایی و پذیرش انتشار

**شناسه سند:** LOT-PROT-P10F-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیشنهاد حاکمیت و Verification مستقل از منبع؛ فاقد مجوز انتشار | **بازبینی:** ۲۰۲۶-۱۱-۲۶

## ۱. هدف و مرز اطمینان

P-10F مشخص می‌کند Lottorito چگونه از معماری پیشنهادی و طراحی به شواهد پیاده‌سازی، راستی‌آزمایی کنترل‌شده در محیط‌ها و صرفاً پس از تأیید صریح به انتشار Production می‌رسد. این سند مدل مشترک Evidence، کاتالوگ کنترل، Gateهای Verification، رکورد تصمیم انتشار، فرایند Exception، مدل مالکیت و چرخه اطمینان پس از انتشار را ارائه می‌کند.

هدف جلوگیری از یک خطای رایج در اطمینان‌بخشی است: تلقی سند، Unit Test موفق، CI سبز، PR ادغام‌شده، سرویس در حال اجرا یا اظهارنظر Vendor به‌عنوان اثبات آمادگی Production. هرکدام ادعایی متفاوت و محدود را اثبات می‌کنند.

این چارچوب مستقل از منبع است؛ ممیزی پیاده‌سازی، نظر حقوقی، Certification امنیتی، تأیید حسابداری، دستورالعمل Deploy یا مجوز دسترسی Production نیست. برای این سند هیچ سرویس زنده، تنظیم Production، Credential، داده مشتری/بازیکن/پرداخت، دیتابیس منبع، زیرساخت، Pipeline انتشار یا Evidence عملیاتی بررسی نشده است. صرف درج یک کنترل در این سند به معنی پیاده‌سازی یا اثربخشی آن نیست.

P-10F حاکم بر اطمینان‌بخشی P-10A تا P-10E و کارهای پیاده‌سازی بعدی است. این سند PRهای قبلی را تأیید یا Merge نمی‌کند، مجوز Migration، نگهداری یا جابه‌جایی وجه، فعال‌سازی Lottery/Gaming یا دسترسی Production صادر نمی‌کند.

## ۲. اصول بنیادین اطمینان‌بخشی

۱. **Evidence محدود به ادعا:** هر ادعا دقیقاً Component، Version، Environment، دامنه Tenant، کلاس داده، بازه زمانی و شرط تهدید/خرابی را مشخص کند.
۲. **شواهد به‌جای ادعا:** اظهار Owner زمینه است، نه اثبات فنی. نتیجه Test فقط در محدوده و شرایط اعلام‌شده همان تست معتبر است.
۳. **تفکیک محیط:** شواهد Local، CI، تست موقت، Staging، Pre-production و Production مجزا هستند. نتیجه یک محیط را بی‌صدا به محیط دیگر تعمیم ندهید.
۴. **هویت و منشأ:** Evidence در صورت کاربرد Subject، Source Commit، Build، Artifact Digest، Workflow/Run، Environment و Collector را مشخص کند.
۵. **تازگی و حساسیت به تغییر:** پس از تغییر مرتبط در Code، Dependency، Config، Schema، Provider، Identity، Threat یا Infrastructure ممکن است Evidence منقضی یا کهنه شود.
۶. **اهمیت شواهد منفی:** Deny دسترسی، جداسازی Cross-tenant، رد Replay، Rollback، فقدان Key، حالت Degraded و تست مسیر شکست، Evidence درجه‌یک هستند.
۷. **بازبینی مستقل:** کنترل‌های مالی، Tenant Isolation، امنیت و بازیابی با اثر بالا به بازبینی مستقل از پیاده‌ساز نیاز دارند.
۸. **بدون Exception پنهان:** کنترل Fail، Missing، Flaky، Skipped یا Inconclusive، PASS نیست. Exception باید صریح، محدود، زمان‌دار و دارای Owner باشد.
۹. **قابلیت بازتولید:** بازبین مجاز دیگر باید بتواند Evidence را پیدا، تفسیر و در صورت ایمن‌بودن بازتولید کند.
۱۰. **بدون بزرگ‌نمایی اطمینان:** CI را Verification Production، طراحی را پیاده‌سازی، Scan را Penetration Test یا Checklist را Certification معرفی نکنید.

## ۳. طبقه‌بندی Evidence و سطوح اطمینان

### ۳.۱ کلاس‌های Evidence

| کلاس | چه چیزی را می‌تواند اثبات کند | به‌تنهایی چه چیزی را اثبات نمی‌کند |
|---|---|---|
| Design Evidence (D) | معماری موردنظر، Threat Model، نیازمندی، ADR و طراحی کنترل | وجود Code یا عملکرد کنترل |
| Implementation Evidence (I) | Code، Schema، Config، IaC، Policy و Review متصل به Version دقیق | رفتار Runtime یا Deploy در Production |
| Automated Verification (T) | نتیجه تست/ابزار مشخص در Environment و Scope اعلام‌شده | مسیرهای تست‌نشده، هم‌ارزی Production یا نبود همه نقص‌ها |
| Environment Verification (E) | رفتار مشاهده‌شده در Environment کنترل‌شده و نام‌برده | محیط‌های دیگر یا Versionهای آینده |
| Production Operational Evidence (P) | Telemetry، Deploy Record، Access Review و Restore/Incident در Production و بازه مشخص | صحت همیشگی یا رفتار آینده |
| Independent Assurance (A) | بازبینی، ممیزی یا ارزیابی مستقل با روش و یافته‌های مشخص | Certification فراتر از Scope صریح |

یک Evidence ممکن است در چند کلاس قرار گیرد، اما هر Claim باید ادعا و منبع دقیق را تعیین کند. Screenshot بدون منشأ، Log کپی‌شده بدون Run ID، Dashboard قابل‌تغییر یا گفته شفاهی، Evidence ضعیف است و جایگزین رکورد مرجع نیست.

### ۳.۲ وضعیت بلوغ اطمینان

این برچسب‌ها برای هر Control استفاده شوند، نه به‌عنوان Badge واحد کل پلتفرم:

- **DRAFTED:** نیازمندی یا طراحی وجود دارد؛ بازبینی مستقل نشده است.
- **DESIGN-REVIEWED:** طراحی بازبین نام‌دار داشته و یافته‌ها رفع یا ثبت شده‌اند.
- **IMPLEMENTED:** Code/Configuration در Version مشخص وجود دارد؛ اثربخشی Runtime هنوز اثبات نشده است.
- **TEST-VERIFIED:** تست‌های لازم در Environment غیرProduction نام‌برده با Evidence نگهداری‌شده موفق بوده‌اند.
- **STAGING-VERIFIED:** کنترل در شرایط نماینده Staging/Pre-production موفق بوده و محدودیت هم‌ارزی با Production ثبت شده است.
- **PRODUCTION-OBSERVED:** رفتار کنترل در بازه مشخص Production با Telemetry و Owner مشاهده شده است.
- **INDEPENDENTLY-ASSESSED:** بازبین مستقل واجد صلاحیت Scope دقیق را ارزیابی کرده است.
- **EXCEPTION:** انحراف تأییدشده و دارای انقضا وجود دارد؛ این وضعیت PASS نیست.
- **BLOCKED / NOT-ASSESSED:** پیش‌نیاز مفقود است یا Evidence معتبر وجود ندارد.

هیچ Control به‌صورت خودکار از یک وضعیت به وضعیت بالاتر ارتقا نمی‌یابد. Commit، Dependency، Configuration، مرز Tenant، Provider، جریان داده یا Incident مهم ممکن است Evidence قبلی را بی‌اعتبار کند.

## ۴. Schema رکورد Evidence

هر Evidence مهم باید در Evidence Register کنترل‌شده و دارای محدودیت دسترسی ذخیره شود. فیلدهای حداقلی:

| فیلد | الزام |
|---|---|
| Evidence ID | شناسه یکتای تغییرناپذیر |
| Control / Requirement IDs | یک یا چند شناسه پایدار کنترل |
| Claim | ادعای دقیق مورد پشتیبانی |
| Class و Maturity | D/I/T/E/P/A و وضعیت کنترل |
| Subject | سرویس، Component، Dataset، Workflow یا فرایند |
| Version identity | Commit SHA، Artifact Digest، نسخه Schema/Config/IaC |
| Environment | Local، CI، Test، Staging، Pre-production یا Production |
| Scope | Tenant/Product/Legal Entity/Region/Data Class در صورت کاربرد |
| Method | Test، Inspection، Query، Review، Observation یا Exercise |
| Result | PASS، FAIL، PARTIAL، NOT_RUN، INCONCLUSIVE، EXPIRED |
| Timestamp | زمان UTC، بازه جمع‌آوری و منشأ ساعت |
| Collector / Owner | Actor، ابزار و Owner پاسخ‌گوی کنترل |
| Source reference | URL تغییرناپذیر Run، Artifact، Report، Log یا Ticket |
| Integrity | Digest/Signature یا هویت منبع قابل‌اعتماد در صورت امکان |
| Limitations | استثناها، فرض‌ها، Sampling و Blind Spotهای شناخته‌شده |
| Retention / Access | نگهداری Evidence و مشاهده‌کنندگان مجاز |
| Reviewer / Decision | بازبین مستقل، تاریخ و تصمیم |
| Expiry / Invalidation | تاریخ انقضا یا محرک‌های بی‌اعتباری |

Secret، Credential خام، ابزار پرداخت، داده شخصی غیرضروری یا رکورد Production بدون محدودیت را وارد Evidence Register نکنید. Evidence حداقلی، Redacted، قابل‌بازتولید و دارای کنترل دسترسی ترجیح دارد. Retention و انتقال برون‌مرزی نیازمند بازبینی Privacy/حقوقی است.

### ۴.۱ آزمون کیفیت Evidence

پیش از پذیرش Evidence بپرسید:
- آیا اصیل و قابل انتساب به منبع معتبر است؟
- آیا به Source/Build/Artifact/Config دقیق مورد بررسی متصل است؟
- آیا برای بازتولید Claim به‌اندازه کافی کامل است؟
- آیا Test Oracle معنادار است و مسیر منفی را پوشش می‌دهد؟
- آیا Environment برای این Claim نماینده است؟
- آیا نسبت به تغییرات مرتبط به‌روز است؟
- آیا محدودیت‌ها و موارد Fail/Skip افشا شده‌اند؟
- آیا بازبین مستقل می‌تواند به نتیجه مشابه برسد؟

وضعیت سبز بدون Run ID پایدار، Commit دقیق و Scope تست معنادار برای Evidence حیاتی انتشار کافی نیست.

## ۵. کاتالوگ کنترل و Crosswalk

Control Register نسخه‌بندی‌شده ایجاد شود. هر کنترل شامل Stable ID، Risk Statement، Requirement، Scope، Owner، Reviewer، مرجع پیاده‌سازی، روش Verification، نتیجه موردانتظار، Evidence ID، Maturity، Exception، Expiry و Change Trigger باشد.

خانواده‌های پیشنهادی کنترل:

| خانواده | پوشش الزامی | مرجع |
|---|---|---|
| محصول و نیازمندی | Scope مصوب، Journey، معیار پذیرش و Non-goal | Product Requirements و Traceability |
| معماری و داده | مرز سرویس، مرجع داده، Schema، Event Contract و Consistency | P-10C و ADR |
| Identity و Authorization | Authentication، MFA، Session، Workload Identity و Least Privilege | P-10D و OWASP ASVS 5.0 |
| Tenant Isolation | Tenant Context، RLS/Grant و مرز Object/API/Cache/Queue/Search/Export | P-10D و تست منفی جداسازی |
| صحت مالی | Journal Invariant، Idempotency، Reconciliation، Reversal و Period Close | سیاست ثبت مالی و کنترل‌های بازیابی P-10E |
| Provider Integration | Contract، Signature، Replay، Timeout/Unknown Outcome، Rate Limit و Versioning | Adapter Contract و Evidence ارائه‌دهنده |
| Privacy و حقوقی | Data Inventory، Purpose، Minimization، Retention، Deletion و Jurisdiction | ارزیابی حقوقی/Privacy مصوب |
| امنیت Application | Threat Model، Secure Coding، SAST/DAST/Dependency Review و ASVS | OWASP ASVS 5.0 و NIST SSDF |
| زنجیره تأمین | Build حفاظت‌شده، Dependency Provenance، Artifact Integrity، Signing و Deployment Identity | SLSA و کنترل‌های پلتفرم |
| Reliability و DR | SLO، Backup/Restore، Failover، RTO/RPO و Recovery Test | P-10E |
| عملیات | Monitoring، Alerting، On-call، Runbook، Incident و Capacity | روش‌های SRE |
| UX و Accessibility | Usability مسیر حیاتی، Localization، RTL/LTR، Keyboard و Screen Reader | استاندارد Accessibility مصوب محصول |
| مستندات و پشتیبانی | سازگاری دوزبانه، راهنمای Operator، Escalation پشتیبانی و محدودیت‌ها | Documentation Governance |

Crosswalk چارچوب‌ها Mapping است، نه ادعای Compliance کلی. Version دقیق و Requirementهای قابل‌اعمال استفاده شود. OWASP ASVS 5.0.0 کاتالوگ Requirementهای Verification است؛ زیرمجموعه/Profile متناسب با ریسک انتخاب و توجیه شود، تصمیم N/A ثبت گردد و Fail/Exception گزارش شود. ادعای Certification از OWASP نکنید.

## ۶. راهبرد Verification و لایه‌های تست

### ۶.۱ هرم Verification

از ارزان‌ترین تستی استفاده کنید که نقص را قابل‌اعتماد تشخیص می‌دهد و سپس برای تعاملات و ریسک عملیاتی تست سطح بالاتر اضافه کنید:
۱. Static Check، Formatting، Type، Lint، Secret Scanning و Policy-as-code.
۲. Unit Test برای Ruleهای قطعی دامنه و Invariantها.
۳. Component/Contract Test برای API، Event، Provider و Schema Compatibility.
۴. Integration Test با Dependency واقعیِ پشتیبانی‌شده یا جایگزین ایزوله وفادار.
۵. End-to-end برای Journeyهای حیاتی کاربر و Operator.
۶. Security Test: ماتریس Authorization، Tenant Isolation، Abuse Case، ASVS Mapping، SAST/DAST و بازبینی دستی هدفمند.
۷. Resilience Test: Timeout، Retry، Event تکراری/خارج از ترتیب، Crash Worker، اختلال جزئی، Restore و Failover در محیط ایزوله مجاز.
۸. Performance/Capacity Test با Workload Model و حدود ایمن مستند.
۹. پذیرش Staging/Pre-production و Verification انتشار کنترل‌شده.
۱۰. مشاهده Production، تحلیل Canary و کنترل‌های پس از انتشار پس از اخذ مجوز جداگانه.

Mock برای Contract قطعی مفید است، اما سازگاری Provider واقعی، رفتار رمزنگاری، Semantics دیتابیس یا تاب‌آوری Production را اثبات نمی‌کند. Integration حیاتی به Evidence Contract از Sandbox واقعی Provider یا محیطی با مجوز مستقل نیاز دارد.

### ۶.۲ ویژگی‌های الزامی هر Test

هر Test Suite باید این موارد را مشخص کند:
- Scope و Requirementهای پوشش‌داده‌شده؛
- Preconditions، Fixtureها و Synthetic بودن داده؛
- Setup و Cleanup قطعی؛
- Outcome موردانتظار و Assertion/Oracle؛
- مسیر شکست و Caseهای منفی؛
- فرض‌های Isolation و Concurrency؛
- ماتریس Version و Dependency پشتیبانی‌شده؛
- Timeout، Retry و سیاست Flake؛
- Report/Run ID و Artifactها؛
- موارد خارج از پوشش شناخته‌شده.

Test Flaky نباید بارها اجرا شود تا سبز شود و سپس PASS نامیده شود. Flakiness را ثبت کنید، Failure اولیه را نگه دارید، Root Cause را مشخص کنید و Quarantine را با Owner و Expiry صریح انجام دهید. Test حیاتی انتشار که Quarantine شده، Gate را Fail می‌کند مگر Exception مصوب صریحاً آن را مجاز کرده باشد.

## ۷. Gateهای انتشار

همه Gateها برای Scope انتشار به‌صورت هم‌زمان لازم‌اند؛ یک Gate اجباری Fail یا Missing، پیشروی را متوقف می‌کند. فقط با فرایند Exception می‌توان انحراف را بررسی کرد؛ ممنوعیت‌های قانونی، مالی، امنیتی و ایمنی Tenant با تصمیم غیررسمی Product قابل‌چشم‌پوشی نیستند.

### Gate G0 — Scope و اختیار
- Scope محصول، کاربران هدف، دامنه Tenant/Product/Legal Entity و Non-goalها تصویب شده‌اند.
- Owner پاسخ‌گو و مرجع تصمیم نام‌دار وجود دارد.
- طبقه‌بندی داده، مبنای Privacy/حقوقی و مسئولیت Provider مشخص است.
- دسترسی Production و عملیات اجرایی مجوز صریح دارند.

### Gate G1 — بازبینی Design و Threat
- Architecture و ADRها در برابر نیازمندی جاری بازبینی شده‌اند.
- Threat Model، Trust Boundary، Abuse Case و Data Flow بررسی شده‌اند.
- Invariant مالی، Tenant Isolation، Recovery و Failure Mode مشخص‌اند.
- ریسک طراحی High Severity حل‌نشده مانع پیشروی است.

### Gate G2 — پیاده‌سازی و سلامت Supply Chain
- Commit دقیق، Code Review، Branch Protection و Required Checkها ثبت شده‌اند.
- Dependency، Secret، License و سیاست Vulnerability ارزیابی شده‌اند.
- Build Provenance/Artifact Digest و Deployment Identity در صورت پشتیبانی ثبت شده‌اند.
- تغییر Schema/Config/IaC بازبینی شده و در صورت امکان Rollback‌پذیر است و برنامه Rollout/Rollback مصوب دارد.

### Gate G3 — Verification خودکار و مستقل
- لایه‌های تست لازم روی Candidate دقیق موفق شده‌اند.
- Security Verification به Requirementهای ASVS و Risk Profile منتخب متصل است.
- تست منفی Tenant Isolation مسیرهای Cross-tenant در API، DB، Cache، Queue، Storage، Search و Export را در صورت کاربرد پوشش می‌دهد.
- تست مالی Idempotency، Journal متوازن، Replay، Reversal، Reconciliation و Outcome خارجی نامعلوم را پوشش می‌دهد.
- یافته Critical حل یا رسماً Block شده و Reviewer مستقل کنترل‌های مهم را تأیید کرده است.

### Gate G4 — آمادگی Environment
- Configuration و Secret محیط کنترل و اعتبارسنجی شده‌اند.
- Observability، مسیر Alert، On-call و Incident Runbook تست شده‌اند.
- Backup/Restore و Recovery Precondition متناسب با ریسک سرویس Evidence جاری دارند.
- Capacity، Quota Provider، Rate Limit، وابستگی عملیاتی و Rollback/Containment بررسی شده‌اند.
- تفاوت Staging/Pre-production با Production مستند شده است.

### Gate G5 — مجوز انتشار
- Artifact Digest و Source Commit دقیق Pin شده‌اند.
- Change Record، Scope، Release Window، Blast Radius و Stop/Rollback Criteria تصویب شده‌اند.
- Release Authority و Operations Owner نام‌دار تأیید کرده‌اند.
- در صورت اثر بر حوزه آنان، تأیید Finance/Security/Privacy/Legal اخذ شده است.
- هیچ Blocker حل‌نشده یا Exception منقضی وجود ندارد.
- Deploy Production فقط از مسیر و Environment دارای مجوز صریح انجام می‌شود.

### Gate G6 — Verification پس از انتشار
- هویت Artifact مستقرشده، Health و Journeyهای حیاتی بررسی می‌شود.
- SLI/SLO، Error Rate، Latency، Queue Lag، Ledger Invariant، Outcomeهای Provider و سیگنال Tenant Isolation در صورت کاربرد پایش می‌شوند.
- Canary/Control یا Metrics قبل/بعد با Threshold ازپیش‌تعیین‌شده مقایسه می‌شوند.
- با Trigger، Rollout متوقف، Rollback یا Contain می‌شود؛ صرفاً سبز بودن Process مجوز ادامه نیست.
- Release پس از بازبینی Owner، بررسی Incident و ثبت Evidence بسته می‌شود.

هیچ Gateی با خود این سند Pass نمی‌شود. این Gateها چارچوبی هستند که باید برای پیاده‌سازی و ریسک واقعی مصداق‌سازی شوند.

## ۸. ماتریس پذیرش دامنه‌های پرریسک

| دامنه | حداقل اثبات پیش از انتشار کنترل‌شده | شرایط توقف اجباری |
|---|---|---|
| مرز Tenant | تست مثبت و منفی API، DB/RLS، Cache، Queue، Storage، Search، Export و Support | هر Read/Write بین Tenantها یا مالکیت مبهم حل‌نشده |
| Ledger | Posting متوازن، Effect ID یکتا، Semantics تغییرناپذیری/اصلاح، Replay و Reconciliation دوره | Journal نامتوازن، Effect مالی تکراری، Lineage مفقود یا Delta توضیح‌نداده |
| Payment/Provider | Signature معتبر Webhook، Replay Control، تطبیق Timeout/Unknown Outcome، Retry Idempotent و Contract Sandbox | Retry پرداخت نامعلوم به‌عنوان پرداخت جدید؛ پذیرش Signature نامعتبر؛ حرکت وجه تکراری |
| Identity/Access | MFA/Step-up در صورت نیاز، Revocation، انقضای Session، Least Privilege، Workload Identity و Audit Break-glass | Escalation دسترسی، باقی‌ماندن دسترسی پس از Revocation یا دسترسی اضطراری بدون Log |
| Affiliate Attribution/Commission | Policy نسخه‌بندی‌شده، Attribution قطعی، ردیابی Source-to-Posting، Period Lock/Reversal و Dispute Trace | Commission بی‌توضیح، تغییر Policy تاریخی بدون Version یا Event غیرIdempotent |
| Queue/Event Processing | Source بادوام، Retry محدود، Consumer Idempotent، قرارداد Ordering، مشاهده DLQ و Evidence Replay | فقدان Event مرجع، Retry Storm نامحدود یا Side Effect خارجی تکراری |
| Chat/Notification | Tenant Isolation، سیاست Persistence پیام، Delivery State، Failure Provider و Retention Test | افشای پیام بین Tenantها یا فقدان فراتر از هدف مصوب |
| Analytics/Reporting | Source Lineage، Freshness، Tenant Filter و Aggregate قابل‌بازتولید | اختلاف گزارش مالی یا نشت Tenant |
| Recovery/DR | Restore ایزوله، Integrity Check، بازیابی Key، Writer Fencing، RTO/RPO اندازه‌گیری‌شده و تأیید Owner | نبود Restore معتبر، Key مفقود، خطر Split-brain یا وضعیت مالی تطبیق‌نشده |
| Localization/Accessibility | Journeyهای حیاتی در Localeهای پشتیبانی‌شده، RTL/LTR، قالب عدد/ارز/تاریخ، Keyboard و Assistive Test | محتوای مالی/حقوقی گمراه‌کننده یا مسیر حیاتی غیرقابل‌استفاده |

این موارد دسته‌های پایه Evidence هستند، نه Test Case کامل یا اثبات وجود فعلی قابلیت‌ها.

## ۹. اطمینان امنیتی و Supply Chain

پروفایل توسعه امن مبتنی بر ریسک و هم‌راستا با NIST SSDF و Profile محدوده‌دار OWASP ASVS 5.0 انتخاب شود. هر Requirement قابل‌اعمال به Artifact پیاده‌سازی، Test یا Review مستقل متصل گردد. Exclusion و Compensating Control ثبت شود؛ فقط درصد امتیاز گزارش نکنید که شکست بحرانی را پنهان کند.

برای Build و Release Chain:
- Branchهای Source محافظت شوند؛ Workflowها بازبینی و Third-party Action/Dependency در صورت امکان به Version تغییرناپذیر و بررسی‌شده Pin شود؛
- CI Identity کم‌اختیار و کوتاه‌عمر باشد و Authority ساخت از Deploy جدا شود؛
- کد PR غیرقابل‌اعتماد Secret انتشار دریافت نکند؛
- Artifact Digest به Source Commit، Build Workflow و Builder Identity متصل شود؛
- Provenance و Artifact Identity هنگام Deploy Verify شوند؛
- SBOM/Dependency و تعیین تکلیف Vulnerability در صورت نیاز نگهداری شود؛
- Environment Approval و Credential انتشار Production محدود شود؛
- Release Record تغییرناپذیر یا دارای کنترل دسترسی حفظ شود.

سطوح SLSA تضمین‌های مشخص Provenance و Build Platform هستند، نه امنیت کلی Application یا بلوغ عملیاتی. تا وقتی تمام Requirementهای سطح و Track مربوط مستقل Verify نشده‌اند، ادعای سطح نکنید. Artifact امضاشده به‌تنهایی Source امن، Dependency سالم یا Runtime Configuration امن را اثبات نمی‌کند.

## ۱۰. Change، Rollback و Progressive Delivery

هر تغییر بر اساس Blast Radius طبقه‌بندی شود: فقط مستندات، Application کم‌ریسک، Data/Schema، Identity/Security، Financial/Ledger، Tenant Boundary، Provider Integration، Infrastructure، Cryptographic/Key یا Recovery Control. کلاس‌های پرریسک به Review قوی‌تر، Rollout مرحله‌ای، Rollback/Containment صریح و تأیید Owner دامنه نیاز دارند.

برای تغییر Database، در صورت تناسب از Expand/Migrate/Contract استفاده شود؛ سازگاری با Versionهای هم‌زمان اجراشونده، Lock، Duration، Backfill، Dual Read/Write و خطر Rollback بررسی شود. Rollback Schema لزوماً Rollback داده نیست. فرض نکنید Migration معکوس می‌تواند اثر مالی یا خارجی را امن Undo کند.

Progressive Delivery/Canary نیازمند:
- Population کنترل پایدار و Exposure محدود؛
- Metric موفقیت/Abort و مدت مشاهده ازپیش‌تعریف‌شده؛
- Candidate Artifact مشخص و یکتا؛
- کنترل Blast Radius آگاه از Tenant؛
- نبود Rollout هم‌زمانی که ارزیابی را آلوده کند؛
- توقف خودکار یا تصمیم انسانی هنگام نقض Threshold؛
- تصمیم Rollback/Forward-fix مبتنی بر داده و Side Effect، نه فقط وضعیت Deploy.

Rollback پس از Side Effect خارجی برگشت‌ناپذیر یا Transformation داده ممکن است ناامن باشد. در این شرایط از Forward Recovery، Compensating Action و Reconciliation تحت Runbook مصوب استفاده شود.

## ۱۱. Exception، پذیرش ریسک و سیاست توقف

رکورد Exception باید شامل این موارد باشد:
- Control ID و Evidence دقیق Fail/Missing؛
- Scope، Tenant/Product/Data متأثر و بازه Exposure؛
- سناریوی ریسک، منطق احتمال/اثر و Residual Risk؛
- Compensating Control و Monitoring؛
- Risk Owner پاسخ‌گو و Approver مستقل؛
- شروع، انقضا، تاریخ Review و معیار Closure؛
- تصمیم درباره اثر مشتری/قانون/Provider و Notification در صورت کاربرد.

Exception نباید بی‌صدا تمدید شود. Exception منقضی دوباره BLOCKED است. برای دور زدن افشای Cross-tenant شناخته‌شده، Journal نامتوازن، Outcome پرداخت Verifyنشده، نبود اختیار قانونی یا Custody ناامن Key از Exception استفاده نکنید. هر Incident مشکوک امنیتی، Privacy یا Integrity مالی باید Stop/Containment و حاکمیت Incident را فعال کند.

## ۱۲. مالکیت و حق تصمیم

برای هر Service و Control از RACI یا مدل معادل استفاده شود. نقش‌های حداقلی:
- Product Owner: Scope، Outcome کاربر، پذیرش و اثر کسب‌وکار.
- Service/Technical Owner: معماری، پیاده‌سازی و Operability.
- Data Owner: Classification، Lineage، Retention و نیاز بازیابی.
- Finance/Control Owner: Ledger Invariant، Reconciliation، Settlement و پذیرش مالی.
- Security Owner: Threat Model، Access، تعیین تکلیف Vulnerability و Security Gate.
- Privacy/Legal Owner: Jurisdiction، Purpose، Retention، Transfer و تعهد قانونی.
- Platform/SRE/DBA: Environment، Build/Deploy، Observability، Backup و Recovery.
- QA/Verification Owner: Test Strategy، Traceability، کیفیت Evidence و Challenge مستقل.
- Release Authority/Incident Commander: تصمیم Release/Stop و هماهنگی Incident.

در تیم کوچک یک نفر می‌تواند چند نقش داشته باشد، اما تأیید با اثر بالا نباید به Self-approval همان کنترلی تبدیل شود که فرد پیاده‌سازی کرده است. Reviewer مستقل یا Oversight جبرانی تعریف شود. نقش بی‌نام Blocker حل‌نشده است، نه تأیید ضمنی.

## ۱۳. Metrics و گزارش اطمینان

به تفکیک Control و Scope انتشار گزارش شود، نه یک امتیاز ترکیبی:
- Mandatory Controlهای Pass/Fail/Not-run/Expired؛
- تازگی Evidence و پوشش Traceability؛
- یافته‌های حل‌نشده به تفکیک Severity و Age؛
- Exception بر اساس Owner، Scope و Expiry؛
- Flakiness تست و Defectهای Escapeشده؛
- پوشش تست Tenant Isolation و Financial Invariant؛
- عمر Vulnerability و SLA رفع؛
- Provenance Artifact و Traceability Deploy؛
- عمر آخرین Recovery Test و RTO/RPO اندازه‌گیری‌شده در صورت تصویب؛
- Outcomeهای SLO و Incident پس از انتشار.

درصد Coverage توصیفی است، نه جایگزین وزن‌دهی ریسک. یک Failure بحرانی انتشار را متوقف می‌کند، حتی اگر ۹۹٪ Checkها موفق باشند. Evidence مفقود معادل Control موفق نیست.

## ۱۴. نقشه راه پیاده‌سازی و Deliverableها

خود P-10F چارچوب را ایجاد می‌کند. اجرای مختص Source فقط پس از عبور از Gateهای Inventory منبع و مجوز Owner انجام شود.

توالی پیشنهادی:
۱. تعیین Ownerهای نام‌دار کنترل و Scope مصوب محصول/سیستم.
۲. ساخت Inventory پیاده‌سازی از Repository/Environmentهای مجاز.
۳. تبدیل Requirementهای P-10A تا P-10E به Control ID پایدار و Traceability Matrix.
۴. انتخاب Profileهای ASVS/SSDF/SLSA و ثبت Applicability.
۵. ایجاد Evidence Register، Exception Register و قالب Release Decision.
۶. پیاده‌سازی Automation Verification با اتصال به Commit/Artifact دقیق.
۷. اعتبارسنجی Test Environment و Fixtureهای Synthetic؛ تفکیک Mock از Sandbox واقعی Provider.
۸. اجرای Verification ایزوله مختص دامنه، شامل تست منفی Tenant و مالی.
۹. اجرای Staging/Recovery Exercise مجاز و Review مستقل.
۱۰. اخذ تأیید Ownerهای دامنه پیش از بررسی هر Gate Production.

Deliverableهای لازم: Control Catalogue؛ Requirements-to-Control Traceability Matrix؛ Evidence Register؛ Test Strategy و Report؛ Security Verification Profile؛ سیاست Build Provenance/SBOM؛ بیانیه هم‌ارزی Environment؛ Release Checklist و Decision Record؛ Exception/Risk Register؛ RACI؛ برنامه Rollback/Containment؛ Post-release Observation Report.

## ۱۵. نقشه اطمینان P-10A تا P-10F

| فاز | پرسش اصلی اطمینان | مرز Evidence فعلی |
|---|---|---|
| P-10A | آیا آمادگی مهاجرت حاکمیت و مرحله‌بندی دارد؟ | مستندات و پروتکل؛ Migration انجام نشده |
| P-10B | آیا Inventory منبع ایمن و مجاز است؟ | فقط پروتکل Read-only؛ اجرا نشده |
| P-10C | آیا معماری مهاجرت مستقل از منبع و کنترل‌شده است؟ | طراحی معماری؛ Source/Target تصویب نشده |
| P-10D | آیا کنترل‌های امنیت و حاکمیت Tenant طراحی شده‌اند؟ | طراحی معماری؛ Verification پیاده‌سازی انجام نشده |
| P-10E | آیا کنترل‌های Reliability و Recovery طراحی شده‌اند؟ | طراحی معماری؛ Backup/Restore یا DR زنده تست نشده |
| P-10F | ادعای پیاده‌سازی و انتشار چگونه Evidence می‌شود و پذیرش می‌گیرد؟ | چارچوب اطمینان؛ پیاده‌سازی Control یا Gate Production تأیید نشده |

P-10F Blockerهای پیاده‌سازی فازهای قبل را نمی‌بندد؛ روش بستن آن‌ها با Evidence آینده را تعریف می‌کند.

## ۱۶. معیارهای پذیرش

P-10F زمانی آماده استفاده به‌عنوان خط مبنای اطمینان پروژه است که:
۱. نسخه فارسی و انگلیسی از نظر ساختاری هم‌راستا و از نظر معنا بازبینی شده باشند.
۲. طبقه‌بندی Evidence، Design، Implementation، Test، Environment، Production و Independent Assessment را تفکیک کند.
۳. وضعیت Control با مجوز انتشار اشتباه نشود.
۴. رکورد Evidence، Claim را به Version، Environment، Scope، Method و Reviewer دقیق متصل کند.
۵. Gate انتشار معنای صریح Pass/Fail/Block/Exception داشته باشد.
۶. کنترل‌های پرریسک Tenant، Ledger، Payment، Identity، Queue و Recovery شرط توقف مختص دامنه داشته باشند.
۷. Exception و Risk Acceptance نیازمند Scope، Owner، Expiry و Compensating Control باشند.
۸. RACI از Self-approval بدون بازبینی برای کنترل‌های با اثر بالا جلوگیری کند.
۹. چارچوب‌های امنیت و Supply Chain بدون ادعای بی‌پشتوانه Compliance/Certification Mapping شوند.
۱۰. هیچ عبارتی بدون Evidence، پیاده‌سازی زنده، آمادگی Production یا مجوز انتشار را القا نکند.

## ۱۷. موارد خارج از دامنه و وضعیت فعلی

این سند Lottorito را Production-ready اعلام نمی‌کند، چارچوبی را Certification نمی‌کند، Release را تصویب نمی‌کند، Vendor انتخاب نمی‌کند، مجوز Production صادر نمی‌کند، Test اجرا نمی‌کند، Infrastructure را Scan نمی‌کند، داده زنده مشتری را بررسی نمی‌کند، Compliance حقوقی را تأیید نمی‌کند، Provider پرداخت را Validate نمی‌کند، عملیات مالی را تصویب نمی‌کند، PR را Merge یا Software را Deploy نمی‌کند.

کار فعلی همچنان معماری مستندات و حاکمیت است. بلوغ همه پیاده‌سازی‌ها Verifyنشده است، مگر اینکه Evidence دقیق جداگانه بررسی و پذیرفته شود. P-10F روش Verification آینده است، نه نتیجه Verification انجام‌شده.

## ۱۸. منابع پژوهشی

- NIST SP 800-218، چارچوب توسعه امن نرم‌افزار (SSDF) 1.1: https://csrc.nist.gov/pubs/sp/800/218/final
- OWASP Application Security Verification Standard 5.0.0: https://asvs.owasp.org/
- راهنمای Assessment و Certification در OWASP ASVS: https://github.com/OWASP/ASVS/blob/master/5.0/en/0x04-Assessment_and_Certification.md
- SLSA Build Track Basics 1.2: https://slsa.dev/spec/v1.2/build-track-basics
- SLSA Build Provenance: https://slsa.dev/spec/v1.2/build-provenance
- Google SRE Workbook، Canarying Releases: https://sre.google/workbook/canarying-releases/
- Google SRE Workbook، Release Engineering: https://sre.google/workbook/release-engineering/
- NIST Cybersecurity Framework 2.0: https://www.nist.gov/cyberframework

این منابع فقط مبنای چارچوب اطمینان هستند و Compliance، Certification، پیاده‌سازی واقعی Lottorito یا آمادگی Production را اثبات نمی‌کنند.
