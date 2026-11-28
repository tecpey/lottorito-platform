# ADRهای فناوری، استقرار و قابلیت اطمینان

**شناسه سند:** LOT-TECH-ADR-001 | **نسخه:** ۰.۲.۰ | **وضعیت:** چارچوب تصمیم‌گیری پیشنهادی؛ هیچ Stack یا Provider تصویب نشده | **تاریخ بازبینی:** ۲۰۲۶-۱۱-۲۴

## ۱. هدف و مرجع اختیار

این سند انتخاب فناوری را به تصمیم‌های صریح و مبتنی بر شواهد تبدیل می‌کند. گزینه‌های پیشنهادی، جایگزین‌ها، معیارهای تصمیم، آزمایش‌های لازم و دروازه‌های تأیید را ثبت می‌کند. این سند تصمیم خرید، تعهد به Cloud، تصویب معماری یا ادعای پیاده‌سازی فناوری نیست.

همه ADRهای زیر **پیشنهادی** هستند. هر ADR فقط پس از تأیید دقیق محدوده توسط مالک و مراجع مرتبط امنیت، مالی، حقوقی یا عملیات به وضعیت **پذیرفته‌شده** می‌رسد. موفقیت Prototype شاهد فنی است، نه مجوز تصویب.

## ۲. قیود غیرقابل‌مذاکره

۱. جهت‌گیری محصول جهانی است؛ فعال‌سازی بازار و محل داده به بررسی حوزه قضایی وابسته می‌ماند.
۲. Affiliate & Agent و Lottery باید دامنه‌های محصولی مستقل و جداگانه قابل استقرار/استفاده باشند.
۳. Context احرازشده Tenant باید در تمام مرزهای داده و Job منتقل و اعمال شود.
۴. سوابق مالی باید Append-only، دوطرفه، Idempotent و قابل تطبیق باشند؛ موجودی قابل‌تغییر منبع حقیقت نیست.
۵. رفتار اختصاصی Provider پشت Adapter و قرارداد نسخه‌بندی‌شده باقی بماند.
۶. API-first نباید مدل دامنه داخلی را مجبور به تقلید از یک شریک کند.
۷. مستندات فارسی و انگلیسی باید از نظر معنا هم‌راستا بمانند.
۸. بدون نیاز اندازه‌گیری‌شده، Microservice، کلاستر Kubernetes، دیتابیس توزیع‌شده، Event Streaming یا Workflow Engine زودهنگام ایجاد نشود.
۹. قابلیت عملیات، بازیابی، امنیت، قابلیت انتقال و هزینه کل مالکیت معیارهای اصلی انتخاب باشند.
۱۰. Secret، Credential و داده شخصی/مشتری وارد Source Control، Log یا Prompt ایجنت‌ها نشود.

## ۳. ADR-001 — معماری برنامه

**وضعیت:** پیشنهادی. **پرسش:** اولین برش‌های محصولی آماده Production باید روی چه توپولوژی اجرا شوند؟

| گزینه | نقاط قوت | هزینه‌ها و ریسک‌ها | ارزیابی فعلی |
|---|---|---|---|
| Modular Monolith | تراکنش ساده، Debug محلی، سربار عملیاتی کم، مرز دامنه روشن | جلوگیری از Coupling نیازمند انضباط است؛ مقیاس‌دهی مستقل محدودتر | فرضیه ترجیحی شروع |
| Microservices از روز اول | استقرار/مقیاس‌دهی مستقل و آزادی فناوری | تراکنش توزیع‌شده، خطاهای شبکه، سربار Observability و عملیات | با شواهد فعلی مقیاس/تیم توجیه نشده |
| Serverless/Function-first | مدیریت زیرساخت کمتر و مقیاس جهشی | محدودیت Runtime، وابستگی فروشنده، پیچیدگی تراکنش/Workflow و پیش‌بینی‌ناپذیری هزینه در بار پایدار | گزینه مخصوص برخی Workloadها، نه پیش‌فرض |

**جهت پیشنهادی:** با Modular Monolith و Processهای Worker با قابلیت استقرار مستقل شروع شود و هسته برنامه مشترک، روشن و نسخه‌بندی‌شده باشد. مرزهای Bounded Context با API ماژول، قواعد مالکیت و تست وابستگی enforce شوند. Affiliate و Lottery باید از نظر Entitlement/Configuration و بسته‌بندی استقرار قابل تفکیک باشند؛ وابستگی داده‌ای بین دو محصول نباید استفاده مستقل را ناممکن کند.

استخراج ماژول به سرویس مستقل فقط وقتی انجام شود که ADR مکتوب محرک‌های قابل‌اندازه‌گیری مانند مقیاس‌دهی مستقل، مهار خطا، چرخه انتشار، مرز حقوقی/داده‌ای، مالکیت تیم یا نیاز فناوری را اثبات کند. استخراج نیازمند قرارداد API/Event، مالکیت داده و برنامه Migration/Rollback است.

**شواهد پذیرش:** نبود Cycle وابستگی ممنوع؛ مالک و قرارداد هر دامنه؛ اتمیک بودن ثبت مالی در مرز دیتابیس مرجع؛ Build/Test مستقل Affiliate-only و Lottery-only؛ اثبات مهار خطا و Rollback.

## ۴. ADR-002 — منبع حقیقت و دیتابیس

**وضعیت:** پیشنهادی. **پرسش:** کدام زیرساخت ذخیره‌سازی از صحت مالی و جداسازی Tenant بهتر محافظت می‌کند؟

| گزینه | مزایا | ریسک‌ها و بده‌بستان‌ها |
|---|---|---|
| PostgreSQL به‌عنوان مخزن تراکنشی اصلی | تراکنش بالغ، Constraint، Index، JSON، RLS، اکوسیستم Backup | نیازمند طراحی دقیق Schema، Connection، Migration، Vacuum و Failover |
| Distributed SQL | سازگاری چندمنطقه‌ای و گزینه‌های مقیاس افقی | پیچیدگی عملیاتی/مالی بیشتر؛ نیاز اثبات نشده |
| چند دیتابیس از ابتدا برای هر Service | جداسازی فنی قوی | عملیات تکراری و پیچیدگی سازگاری/گزارش پیش از اثبات مرزها |
| Document DB به‌عنوان مخزن مالی اصلی | انعطاف ساختار و الگوهای افقی | وابستگی بیشتر Integrity مالی و تطبیق به منطق برنامه |

**جهت پیشنهادی:** PostgreSQL به‌عنوان System of Record اولیه برای هویت/عضویت، داده عملیاتی Tenant، رویداد نرمال‌شده شریک و ژورنال مالی استفاده شود؛ مشروط به Prototype و بازبینی عملیاتی. برای Invariantها از Constraint رابطه‌ای و Transaction استفاده شود. JSON مرز Payload خام/یکپارچه‌سازی باشد، نه جایگزین داده مالی Typed و قابل‌پرس‌وجو.

RLS می‌تواند دفاع تکمیلی باشد؛ اما جایگزین Authorization برنامه، Repositoryهای Tenant-aware، Role دیتابیس با حداقل دسترسی یا تست منفی Cross-tenant نیست. مالک جدول، Superuser و Role دارای مجوز Bypass RLS باید صریح مدیریت شوند؛ Role دقیق مورد استفاده برنامه بررسی شود.

**قواعد داده:**
- پول به‌صورت Integer در کوچک‌ترین واحد یا Decimal دقیق با دقت مختص هر ارز ذخیره شود؛ هرگز Binary Floating Point استفاده نشود.
- Currency Code همراه هر مبلغ ذخیره شود؛ ارز از Locale Tenant استنباط نشود.
- Payload خام تحت کنترل Retention/Privacy حفظ و از رکورد Canonical جدا باشد.
- Journal Entry تغییرناپذیر و Reversal مرتبط داشته باشد؛ اصلاح تاریخچه را بازنویسی نکند.
- ابعاد Tenant، Product، Legal Entity، Currency و Account در صورت نیاز LOT-FIN-POST-001 صریح باشند.
- Migration در بازه استقرار Backward-compatible باشد یا برنامه Expand/Migrate/Contract داشته باشد.
- طبقه‌بندی داده، Retention، حذف/ناشناس‌سازی، Export و Residency پیش از Production تعریف شوند.

**شواهد پذیرش:** تست هم‌زمانی برای اثر اقتصادی تکراری؛ تست RLS و Authorization برنامه از جمله Connection Pool و Reset Context؛ تمرین Backup Restore و Point-in-time Recovery؛ روش Migration Rollback/Forward-repair؛ تست بار با توزیع واقعی Tenant و الگوی نوشتن مالی.

## ۵. ADR-003 — کار غیرهمزمان، صف و ارکستراسیون Workflow

**وضعیت:** پیشنهادی. **پرسش:** Callback شریک، Attribution، محاسبه کمیسیون، تطبیق و فرایندهای طولانی چگونه قابل‌اعتماد اجرا شوند؟

**مرحله A — Transactional Outbox + Worker:** شروع با Outbox که در همان تراکنش تغییر کسب‌وکار نوشته می‌شود و Worker مستقل که Job را ایمن Claim می‌کند. Retry محدود با Exponential Backoff و Jitter، سقف تلاش، وضعیت Dead-letter/Quarantine، Replay اپراتوری و Handlerهای Idempotent لازم‌اند. این روش سربار زیرساخت را کم و قصد تحویل را پایدار می‌کند.

**مرحله B — Broker مستقل:** فقط وقتی Broker اضافه شود که Throughput، Fan-out، جداسازی Consumer، Backlog، Ordering یا نیاز عملیاتی اندازه‌گیری‌شده آن را توجیه کند. محصولات Managed Queue/Broker بر اساس معنای Delivery، دامنه Ordering، Retention، Replay، Dead-letter، دسترس‌پذیری منطقه‌ای، هزینه و Portability مقایسه شوند.

**مرحله C — Durable Workflow Engine:** وقتی فرایندها طولانی، چندسیستمی، نیازمند دخالت انسانی، Timer، Compensation یا Resume هستند، Temporal یا گزینه معادل ارزیابی شود. Durable Workflow نیاز به Idempotency فعالیت خارجی، Deduplication کسب‌وکاری یا Reconciliation را حذف نمی‌کند.

**معناهای اجباری:**
- مگر قرارداد Provider خلاف آن را اثبات کند، تحویل At-least-once فرض شود؛ Consumer باید Idempotent باشد.
- Exactly-once Economic Effect یک Invariant برنامه است، نه ادعای تبلیغاتی Broker.
- Delivery Attempt ID، Source Event ID، Economic Effect ID و Journal Entry ID جدا باشند.
- Transactional Inbox/Outbox، Unique Constraint و وضعیت پردازش صریح استفاده شوند.
- فقط خطای موقت Retry شود؛ خطای اعتبارسنجی، مجوزدهی و خطای دائمی کسب‌وکار Quarantine شود.
- Callback خارجی هرگز مستقیماً موجودی را تغییر ندهد.
- Replay شواهد منبع و نسخه قانون اصلی را حفظ کند و ثبت تکراری نسازد.

**آزمایش پذیرش:** Crash Worker پیش/پس از Commit، Callback تکراری و خارج از ترتیب، Timeout Provider پس از موفقیت عملیات سمت مقابل، Poison Message، قطعی Queue، Retry Storm و Replay اپراتوری شبیه‌سازی شود. یک اثر اقتصادی و Audit Trail کامل اثبات شود.

## ۶. ADR-004 — Runtime، میزبانی و توپولوژی استقرار

**وضعیت:** پیشنهادی. **پرسش:** کدام مدل عملیاتی ریسک را کم و امکان توسعه جهانی را حفظ می‌کند؟

گزینه‌ها:
- Managed Container Platform/Runtime: عملیات Cluster کمتر؛ Lock-in، کنترل شبکه، دسترس‌پذیری Region، Job، اتصال خصوصی و Observability بررسی شود.
- Managed Kubernetes: کنترل ارکستراسیون و Portability؛ اما چرخه عمر Cluster، Upgrade، RBAC، شبکه، Policy، ظرفیت و پاسخ رخداد مسئولیت پلتفرم است.
- Virtual Machine خودمدیریت‌شده: کنترل مستقیم و گاهی عملیات اولیه ساده‌تر؛ اما Patch، Failover، Scale، Secret، Deploy و Recovery مسئولیت مالک می‌ماند.
- Function/Serverless: مناسب Handler محدود و Workload جهشی؛ محدودیت اجرا، Cold Start، شبکه، Observability و کار طولانی بررسی شود.

**جهت پیشنهادی:** Kubernetes پیش‌فرض نباشد. برای اولین Pilot عملیاتی، گزینه Managed Container/Runtime با استقرار کوچک VM/Container و خودکارسازی مناسب مقایسه شود. ساده‌ترین گزینه‌ای انتخاب شود که Availability، شبکه خصوصی، رمزنگاری، Residency، Backup، Rollback، زمان‌بندی Worker و پاسخ رخداد را پوشش دهد.

محیط‌ها و Credentialهای Development، Test، Staging و Production جدا باشند. داده Production به محیط پایین‌تر کپی نشود؛ از Fixture مصنوعی یا داده غیرقابل‌بازگشت استفاده شود. Artifact تغییرناپذیر بر اساس Digest، Rollout مرحله‌ای، Health/Readiness Check و Rollback تست‌شده به‌کار رود. Infrastructure as Code پیش‌نیاز بلوغ زیرساخت تکرارپذیر Production است.

**دروازه Region/Residency:** هیچ Cloud Region یا Vendor انتخاب نشده است. پیش از انتخاب، شخصیت حقوقی قراردادی، محل مشتری/Agent، دسته داده، مبنای حقوقی، محدودیت انتقال برون‌مرزی، Subprocessor، Retention/Deletion، رمزنگاری و کنترل Key، دسترسی Support و Region بازیابی بحران مشخص شود. جهانی بودن محصول به‌معنای Replication نامحدود فرامرزی نیست.

## ۷. ADR-005 — Observability و شواهد عملیاتی

**وضعیت:** پیشنهادی. Instrumentation مستقل از Vendor بر پایه OpenTelemetry برای Trace، Metric و Log و با Semantic Convention مشترک استفاده شود؛ Backend/Vendor بعداً انتخاب می‌شود.

سیگنال‌های حداقلی:
- نرخ Request، Percentileهای Latency، Error Rate و Saturation.
- سن/عمق Queue، تعداد Retry، Dead-letter و عقب‌ماندگی Worker.
- پذیرش/رد Callback، خطای Signature، Latency و اختلاف Reconciliation.
- تعداد Posting/Reversal، نقض Invariant و تلاش Journal نامتوازن.
- رد Authorization در محدوده Tenant و الگوهای دسترسی مشکوک.
- عمر آخرین Backup، زمان آخرین Restore Test، نسخه Deploy و سلامت Dependency.

Token، Secret، جزئیات کامل پرداخت، داده شخصی کامل یا Payload نامحدود Provider وارد Telemetry نشود. شناسه Tenant/مشتری با Cardinality بالا Label Metric نباشد؛ از Correlation ID کنترل‌شده و Trace با دسترسی محدود استفاده شود. Log جایگزین Ledger یا Audit Journal نیست.

SLO/SLI پس از شناخت Workload و اهمیت کسب‌وکار تعیین شوند. هر Alert باید مالک، Runbook قابل‌اقدام و Severity داشته باشد؛ برای هر Retry موقت Alert صادر نشود.

## ۸. ADR-006 — Availability، Backup و بازیابی بحران

**وضعیت:** پیشنهادی؛ اهداف عددی باز هستند.

پیش از تعیین اثر کسب‌وکار و تعهد قراردادی، RPO/RTO عددی تعیین نشود. برای هر قابلیت حیاتی ثبت شود: اهمیت سرویس و حداکثر قطعی قابل‌تحمل؛ RPO/RTO مصوب مالک؛ تناوب Backup، Retention، رمزنگاری و کنترل دسترسی؛ Point-in-time Recovery؛ سیاست Replication بین Regionها در صورت مجاز بودن حقوقی؛ تناوب Restore Test و اپراتور پاسخ‌گو؛ ترتیب بازیابی و وابستگی‌ها (Identity، DB، Key، Queue و Adapter شریک)؛ روش Reconciliation رویدادهای دریافتی در زمان قطعی و پنجره Replay Provider.

Backup تا زمانی که Restore واقعی تمرین نشده Verified نیست. Replication معادل Backup نیست. DR تا زمان تست Failover/Failback و تطبیق مالی کامل نیست.

## ۹. ADR-007 — امنیت، Secret و زنجیره تأمین نرم‌افزار

**وضعیت:** پیشنهادی.
- از Secret Store مدیریت‌شده یا سازوکار Secret استقرار با کنترل سخت استفاده شود؛ Secret در Git، Image، Log یا Context ایجنت ذخیره نشود.
- هویت انسانی، هویت Workload و Credential شریک جدا باشند؛ Least Privilege، Rotation و Revocation اعمال شود.
- در صورت پشتیبانی Artifact امضا/اعتبارسنجی شود؛ Dependencyها Pin، آسیب‌پذیری‌ها Scan، SBOM تولید و منشأ Release محافظت شود.
- SLA اصلاح Patch بر اساس شدت و Exposure تعریف شود؛ استثنا تاریخ انقضا و کنترل جبرانی داشته باشد.
- TLS در انتقال و Encryption at Rest؛ مالکیت Key، Rotation، Recovery و Audit دسترسی مستند شوند.
- دیتابیس و مدیریت Queue در شبکه خصوصی باشند و عمومی نشوند.
- پیش از انتشار API بیرونی، Threat Model و ریسک‌های OWASP API بازبینی شوند.

## ۱۰. ADR-008 — چرخه عمر داده، Privacy و Residency

**وضعیت:** پیشنهادی؛ نیازمند بررسی حوزه قضایی.

پیش از Production، Data Inventory ساخته شود. برای هر کلاس داده هدف، مبنای قانونی/قراردادی، نقش Controller/Processor، منبع جمع‌آوری، مالک Tenant/Product، حساسیت، Region ذخیره‌سازی، گیرنده/Subprocessor، مدت Retention، روش Deletion/Anonymization، فرایند Export/Access و الزام Audit ثبت شود.

داده عملیاتی، مالی، امنیتی، پشتیبانی و خام Provider تفکیک شوند. تعارض احتمالی بین نگهداری سوابق مالی و تعهد حذف داده باید با بررسی حقوقی/حسابداری واجد صلاحیت حل شود؛ بدون سیاست مصوب وعده حذف یا نگهداری نامحدود ندهید.

## ۱۱. ماتریس تصمیم و امتیازدهی

این بخش مکمل تخصصی فناوری است؛ معنای امتیازدهی استاندارد مادر در بخش‌های ۸.۳ و ۱۷.۱۰ LOT-EVAL-001 الزام‌آور است. وزن‌های پیشنهادی فقط نقطه شروع‌اند، نه اولویت مصوب یا Default فعال. استفاده از آن‌ها فقط با تصمیم صریح مالک برای واحد تصمیم فناوری مشخص، پس از تعیین کاربردپذیری و حذف دوباره‌شماری با Gateهای اجباری مجاز است.

| معیار | وزن پیشنهادی |
|---|---:|
| یکپارچگی مالی و صحت تراکنش | ۲۰٪ |
| جداسازی Tenant و کنترل امنیت | ۱۵٪ |
| سادگی عملیات و توان تیم | ۱۵٪ |
| قابلیت اطمینان، Backup و بازیابی | ۱۵٪ |
| تناسب Integration/API و Event | ۱۰٪ |
| تناسب Region جهانی و Residency داده | ۱۰٪ |
| انتقال‌پذیری و راهبرد خروج | ۵٪ |
| هزینه کل مالکیت در مقیاس پیش‌بینی‌شده | ۱۰٪ |

فقط وقتی از Rubric قابلیت ۰ تا ۵ استاندارد مادر استفاده کنید که شواهد برای کل معیار اتمی کافی باشد؛ در غیر این صورت NS ثبت کنید. مدرک مفقود/ناکافی NS است، هرگز صفر نیست. صفر به شواهد کافی نیاز دارد که غیبت یا غیرقابل‌قبول‌بودن قابلیت را نشان دهد. شواهد جزئی نمی‌تواند معیار مرکب را قبول کند؛ آن را به زیرمعیارهای اتمی تقسیم کنید. N/A به توجیه و تصویب قبلی نیاز دارد، نمی‌تواند Gate اجباری را حذف کند و باید نرمال‌سازی وزن مؤثر شفاف باشد. اگر معیار بااهمیتی NS باشد، امتیاز تجمیعی قطعی منتشر نکنید. اطمینان از امتیاز جداست و در آن ضرب نمی‌شود.

امتیاز وزنی بالا شکست/نامعلوم‌بودن کنترل اجباری، حداقل معیار حیاتی، ریسک باقیمانده غیرقابل‌قبول یا محدودیت قانونی را جبران نمی‌کند. امتیازهای خام، وضعیت شواهد، وزن‌ها، موارد حذف‌شده، وضعیت Gate، عدم‌قطعیت و اختلاف ارزیابان را حفظ کنید. در تصمیم‌های T2/T3 یا سایر تصمیم‌های بااهمیت، در صورت امکان پیش از توافق نهایی امتیازدهی مستقل انجام دهید و اگر ارزیاب دوم واجد صلاحیت موجود نیست، محدودیت را ثبت کنید.

## ۱۲. Prototypeها و دروازه‌های پذیرش

پیش از پذیرش انتخاب فناوری، آزمایش‌های کوچک و قابل‌تکرار اجرا شوند:
۱. مرز Tenant: انتقال Context احرازشده در HTTP، Worker، Task زمان‌بندی‌شده و DB؛ رد Cross-tenant اثبات شود.
۲. تراکنش مالی: پردازش هم‌زمان Event تکراری؛ یک اثر اقتصادی، Journal متوازن و Reversal مرتبط اثبات شود.
۳. خطای Provider: Timeout، Retry، Callback تکراری، Signature نامعتبر و اختلاف Reconciliation.
۴. تکامل Schema: Expand/Migrate/Contract بدون توقف و Rollback/Forward-repair.
۵. بازیابی: Restore نسخه پشتیبان در محیط ایزوله و تطبیق تعداد Journal/Event.
۶. Observability: Trace رویداد شریک از ورودی تا Attribution، تصمیم کمیسیون و ارجاع Journal بدون افشای Secret/PII.
۷. استقلال محصولات: Build/Run پیکربندی Affiliate-only و Lottery-only بدون وابستگی اعلام‌نشده بین دامنه‌ها.
۸. استقرار: Artifact تغییرناپذیر، Health Gate، Rollback و تزریق Secret بدون ثبت Credential در Log.

## ۱۳. تصمیم‌های باز مالک

شخصیت حقوقی/مدل اپراتوری/بازار اولیه؛ مسئولیت Controller/Processor و Residency داده؛ سطح Availability و RPO/RTO مصوب؛ تعداد Tenant/کاربر/حجم Event/فصل‌پذیری/نرخ تراکنش مالی؛ مرجع خرید Hosting/Vendor، بودجه و Lock-in قابل‌قبول؛ مالکیت Key، مدیریت Secret و مسئول رخداد؛ سیاست Retention/Deletion/Export/Audit؛ مرجع پذیرش فناوری و تأییدکنندگان کنترل‌های مالی/امنیتی.

## ۱۴. منابع مرجع

- [استاندارد مادر ارزیابی محصول، فناوری و تأمین‌کننده](../governance/enterprise-evaluation-standard.md) — LOT-EVAL-001؛ معنای شواهد و امتیازدهی در تصمیم‌های فناوری تابع استاندارد مادر است.

این منابع معیارهای تصمیم را پشتیبانی می‌کنند؛ Vendor انتخاب نمی‌کنند و پیاده‌سازی Lottorito را اثبات نمی‌کنند:
- PostgreSQL Row Security Policies: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- Kubernetes Production Environment: https://kubernetes.io/docs/setup/production-environment/
- Kubernetes setup و ملاحظات سرویس Managed: https://kubernetes.io/docs/setup/
- OpenTelemetry Semantic Conventions: https://opentelemetry.io/docs/concepts/semantic-conventions/
- Temporal Durable Execution: https://docs.temporal.io/durable-execution
- Temporal Idempotent Activities و مدیریت خطا: https://docs.temporal.io/best-practices/error-handling
- OWASP API Security Top 10: https://owasp.org/www-project-api-security/

## ۱۵. تاریخچه تغییر

۰.۲.۰ — هم‌ترازی ماتریس فناوری با Rubric شواهد/امتیاز LOT-EVAL-001 نسخه ۰.۳.۰؛ وزن‌ها همچنان پیشنهادی و همه ADRها در وضعیت PROPOSED باقی می‌مانند.

۰.۱.۰ — ایجاد چارچوب تصمیم فناوری، استقرار، قابلیت اطمینان و حاکمیت داده بر اساس شواهد. همه تصمیم‌ها پیشنهادی‌اند.
