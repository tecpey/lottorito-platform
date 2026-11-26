# P-10D — معماری امنیت، جداسازی Tenant، حریم خصوصی و حاکمیت

**شناسه سند:** LOT-PROT-P10D-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیشنهاد معماری امنیتی مستقل از منبع؛ نه ارزیابی پیاده‌سازی و نه گواهی انطباق | **بازبینی:** ۲۰۲۶-۱۱-۲۶

## ۱. هدف و مرز اطمینان

این سند کنترل‌های امنیتی و حاکمیتی موردنیاز برای پلتفرم چندمستاجری آینده Lottorito و هر مهاجرت احتمالی داده را تعریف می‌کند. دامنه آن مدیران پلتفرم، مدیران Tenant، اپراتورهای White-label، Affiliate/Agent، مشتریان B2C، پشتیبانی، توسعه‌دهندگان، CI/CD، Workloadهای برنامه، Workerها، Adapterهای پرداخت/Provider و هویت‌های مهاجرت را شامل می‌شود.

این سند خط مبنای معماری است، نه مدرک وجود یا موفقیت کنترل‌ها در Repository، Staging یا Production فعلی. هیچ Endpoint عملیاتی، Credential، داده مشتری/بازیکن/پرداخت، فهرست Tenant، شخصیت حقوقی، قرارداد Provider، حوزه قضایی، KMS ابری یا پیکربندی مستقر IAM/RLS بررسی نشده است. ادعای Penetration Test، ارزیابی اثر حریم خصوصی، نظر حقوقی، Certification یا گواهی انطباق وجود ندارد. از دسته محصول به‌تنهایی شمول قانون یا مقررات خاص استنباط نمی‌شود.

## ۲. اصول امنیتی

۱. Zero Trust مبتنی بر Resource: موقعیت شبکه، داخلی‌بودن، مالکیت یا Authentication قبلی اعتماد ضمنی ایجاد نمی‌کند.
۲. Deny by Default و Least Privilege: نبود Policy منطبق یعنی Deny؛ Grant به Action، Object، Tenant، Product، Environment و زمان محدود است.
۳. جداسازی سرتاسری Tenant: Scope معتبر در API، سرویس، دیتابیس، Cache، Queue، Object Storage، Search، Analytics، Export، Log، Backup و ابزار پشتیبانی اعمال شود.
۴. تفکیک Authentication از Authorization: هویت به‌تنهایی مجوز نیست.
۵. مرز اعتماد صریح: Scope پلتفرم، Tenant، Product/Domain، User، شخصیت حقوقی/مالی، Environment و Provider مستقل باشند.
۶. Fail Closed برای عملیات محافظت‌شده: هویت مفقود، Context نامعتبر، خطای Policy، Entitlement کهنه یا نبود Audit الزامی نباید به Allow ضمنی تبدیل شود.
۷. کنترل قابل‌اثبات: هر کنترل به تست منفی، Evidence، Owner و فرآیند Exception نیاز دارد.
۸. حداقل‌سازی داده و دامنه خسارت.
۹. تفکیک وظایف توسعه، تأیید، انتشار، مجوز مالی و ممیزی.
۱۰. حفظ پاسخگویی مالی Immutable؛ دسترسی ممتاز نباید تاریخچه حسابداری ثبت‌شده را بی‌صدا بازنویسی کند.

## ۳. دامنه‌های اعتماد و مدل Principal

| دامنه | نمونه | اختیار پیش‌فرض |
|---|---|---|
| Control Plane پلتفرم | Provisioning Tenant، تنظیمات سراسری، امنیت | فقط Grant صریح در Scope پلتفرم |
| Tenant Plane | کاربران، تنظیمات و گزارش Tenant | یک Tenant تأییدشده و Productهای مجاز |
| Product/Domain Plane | Affiliate، Chat، Wallet، Marketplace و Gaming آینده | Action و Object در Scope همان Domain |
| Financial/Legal-Entity Plane | Ledger، کمیسیون، تسویه و دستور پرداخت | نقش محدود Finance و Dual Control برای عملیات حساس |
| User/Customer Plane | حساب B2C، پروفایل، Wallet و مکالمه پشتیبانی | منابع خود کاربر و دسترسی Delegated مجاز |
| Workload Plane | API، Worker، Scheduler، Adapter و Migration Job | Workload Identity با Audience و Scope صریح |
| Human Operator Plane | Support، SRE، DBA، Security و Developer | فرد نام‌دار، JIT، تأییدشده و Auditشده |
| External Provider Plane | Provider پرداخت، Gaming و Identity | هویت مستقل هر Provider؛ بدون اختیار پلتفرم |

Platform Admin به‌صورت خودکار Tenant Business Operator یا Finance Approver نیست. Tenant Admin نیز Platform Admin نیست. Support Impersonation نقش عادی نیست و نباید بی‌صدا اختیار مشتری را به ارث ببرد.

هر درخواست محافظت‌شده باید از Context تأییدشده سمت سرور استفاده کند که حسب مورد شامل نوع و شناسه ثابت Subject؛ Actor و Actor نمایندگی‌شده؛ سطح Authentication و زمان MFA/Re-authentication؛ Workload Identity، Issuer، Audience و Environment؛ عضویت جاری Tenant؛ Tenant انتخابی و اعتبارسنجی آن؛ Scope محصول/دامنه و شخصیت حقوقی؛ Resource و Action؛ Purpose و طبقه داده؛ مالکیت/Relationship؛ نسخه Policy؛ Request/Trace ID و زمان است.

Tenant ID، Role، Header، Object ID و JWT Claim ارسالی Client ورودی برای اعتبارسنجی‌اند، نه مدرک اختیار. فراخواننده نباید بتواند Tenant، Role، Product، وضعیت Finance یا شخصیت حقوقی خود را تعیین کند. عضویت و Revocation در Sessionهای طولانی و Jobهای با تأخیر، در صورت ریسک ناشی از مجوز کهنه، دوباره بررسی شود.

## ۴. معماری Authorization

### ۴.۱ مدل ترکیبی

از RBAC برای وظایف کلی، ABAC برای Context (Tenant، Product، شخصیت حقوقی، Environment، طبقه داده، وضعیت تراکنش، ریسک و زمان) و Relationship/Object Check برای مالکیت، دسترسی Delegated، Support و سلسله‌مراتب Affiliate در صورت نیاز استفاده شود. RBAC به‌تنهایی برای سلسله‌مراتب چندمستاجری بیش از حد کلی است. Grant به شکل Tupleهای Scopeدار مدل شود: Subject + Action + Resource/Domain + Tenant/Product/Legal-entity Scope + Constraint + اعتبار زمانی + Approver/Evidence.

### ۴.۲ تصمیم و اعمال Policy

تفکیک مفهومی PAP، PIP، PDP و PEP به‌کار گرفته شود. حتی در صورت PDP متمرکز، PEP باید در هر مرز Resource تصمیم را اعمال کند. Check در Gateway به‌تنهایی کافی نیست. قطعی، Timeout، پاسخ نامعتبر یا نسخه Policy ناشناخته باید برای عملیات محافظت‌شده به Deny منجر شود. Cache تصمیم باید به Subject، Action، Object، Tenant، Attribute مرتبط و نسخه Policy مقید باشد؛ Revocation باید Cache را باطل کند یا عمر مجوز کهنه را محدود سازد.

### ۴.۳ کنترل الزامی در هر عملیات محافظت‌شده

- هویت احراز شده و Credential منقضی یا لغو نشده باشد؛
- Audience و Environment مربوط به Session/Workload صحیح باشد؛
- عضویت جاری Tenant یا Grant صریح Cross-tenant معتبر باشد؛
- Scope محصول/دامنه و شخصیت حقوقی با Resource منطبق باشد؛
- مالکیت/Relationship مربوط به Object معتبر باشد؛
- Action با وضعیت فعلی Resource مجاز باشد؛
- برای اقدام حساس Step-up Authentication، Approval یا Dual Control انجام شود؛
- Field/Export در محدوده مجوز طبقه‌بندی داده باشد؛
- الزام Audit قابل انجام باشد.

Deny-by-default و Enforcement یکنواخت سمت سرور الزامی است. مخفی‌کردن UI، شناسه غیرقابل‌حدس، مبهم‌بودن Route و Gateway-only Check کنترل Authorization نیستند.

## ۵. جداسازی Tenant و Product

هر Resource متعلق به Tenant باید مرز مالکیت قابل‌اعمال داشته باشد؛ با tenant_id، Schema/Database جدا، Storage Policy یا سازوکار قابل‌اثبات دیگر. Scope محصول/دامنه و شخصیت حقوقی ابعاد جداگانه‌اند؛ tenant_id را برای همه مفاهیم بیش‌بارگذاری نکنید. داده را Platform-global، Tenant-owned، User-owned، Product-owned یا Intentionally shared طبقه‌بندی کنید.

هویت‌های Legacy با مقدار shared، Null، Unknown، Conflicted، Orphaned و Duplicate Scope Canonical نیستند و تا داوری مالک مسئول همراه شواهد قرنطینه می‌مانند. shared را خودکار Affiliate، Lottery، Platform-global یا محصول دیگری تفسیر نکنید.

کنترل‌های هر Data Plane:

- **HTTP/API:** استخراج Tenant از هویت و عضویت تأییدشده؛ مجوزسنجی هر Object/Action؛ رد IDOR بین Tenantها.
- **Service-to-service:** احراز Workload Identity و محدودکردن Audience، Tenant Set، Product، Environment و Action. شبکه داخلی مجوز نیست.
- **Database:** در Shared-table از Runtime Role غیرمالک، Grant حداقلی و RLS به‌عنوان دفاع در عمق استفاده شود. همه Tableهای Tenant-owned Inventory و تست شوند. Owner جدول معمولاً RLS را دور می‌زند؛ Superuser و BYPASSRLS همیشه عبور می‌کنند. FORCE RLS رفتار Owner را تغییر می‌دهد ولی Superuser/BYPASSRLS را خنثی نمی‌کند. هویت Migration/Admin از Role سرویس‌دهنده درخواست جدا باشد.
- **Connection Pool:** Context Tenant در سطح Transaction و در هر تراکنش تنظیم شود. وضعیت Session بین درخواست‌های Poolشده نشت نکند. Reuse پس از Success، Exception، Rollback، Timeout و Cancellation تست شود.
- **RLS Policy:** USING و WITH CHECK برای SELECT/INSERT/UPDATE/DELETE آگاهانه تعریف شود؛ Read/Write، Context مفقود، Null، Role Inheritance و ترکیب Policyها تست شوند. RLS همه عملیات را پوشش نمی‌دهد؛ TRUNCATE تحت Row Policy نیست و Grant سطح Table جداگانه محدود شود.
- **View/Function:** مالکیت SECURITY DEFINER، search_path، Grant و رفتار Scope ردیف بررسی شود؛ Function ممتاز دورزننده کنترل افشا نشود.
- **Cache:** Tenant تأییدشده و ابعاد مجوز/Policy در Key قرار گیرد؛ Collision و مجوز کهنه جلوگیری شود.
- **Queue/Event:** Jobها Global، Tenant-scoped یا صریحاً Cross-tenant طبقه‌بندی شوند. Producer احراز، Metadata از نظر Integrity محافظت و در Consumer دوباره Authorization شود؛ Idempotency، Retry، DLQ و Ordering نیز Scopeدار باشند. فیلد tenant_id در پیام مدرک مجوز نیست.
- **Object Storage/File:** مالکیت در Authorization و Storage Policy اعمال شود؛ Prefix به‌تنهایی مرز امنیتی نیست. Signed URL فقط برای Object/Action دقیق و عمر کوتاه لازم صادر شود؛ Version، Replica و Backup نیز لحاظ شوند.
- **Search/Analytics/Export:** Filter Tenant/Product در Query و Materialization اعمال شود؛ Export و گزارش زمان‌بندی‌شده اعتبارسنجی و نشت Aggregate بین Tenantها کنترل شود.
- **Backup/Restore:** دسترسی Backup دسترسی ممتاز بین Scopeهاست؛ محدود، رمزنگاری، Audit و بازیابی Tenant بدون Overwrite داده زنده یا افشای دیگران تست شود.
- **Support/Admin:** انتخاب Tenant صریح و دوباره مجازسنجی شود؛ Bypass سراسری پنهان ممنوع. دسترسی Support زمان‌دار، Purpose-bound و Auditشده باشد.

Shared Table با RLS، Schema جدا، Database جدا یا Hybrid فقط پس از ارزیابی حساسیت، تعهدات حقوقی/قراردادی، Blast Radius، ظرفیت عملیات، جزئیات Restore، هزینه و مقیاس انتخاب شود. راهبرد برتر واحدی وجود ندارد.

## ۶. هویت انسانی، Session و دسترسی ممتاز

- حساب انسانی یکتا و نام‌دار؛ حساب Administrator مشترک ممنوع.
- چرخه عمر متمرکز Joiner/Mover/Leaver، لغو سریع و بازبینی دوره‌ای.
- MFA برای عملیات ممتاز و حساس؛ انتخاب عامل با Threat Model، تجربه کاربری، دسترس‌پذیری محلی و ریسک Recovery.
- Step-up/Re-authentication برای تغییر Credential/MFA/Recovery، مقصد پرداخت، اقدام مالی پرارزش، Export حساس، اعطای Role و Support ممتاز.
- Inactivity Timeout، عمر مطلق Session، رفتار Session هم‌زمان، Rotation/Reuse Detection برای Refresh Token، انتشار Revocation و فهرست Session/Device بر اساس ریسک تعریف شود.
- Cookie/Session امن و CSRF Protection برای تغییر وضعیت مبتنی بر Cookie.
- دسترسی ممتاز JIT، زمان‌دار، مقید به Ticket/Purpose و حداقل‌دسترسی؛ دسترسی حساس Production نیازمند تأیید مستقل.
- Break-glass استثنایی است: Credential جدا، Scope محدود، عمر کوتاه، Alert فوری، Reason/Ticket، Audit کامل، بازبینی پس از رخداد و تست دوره‌ای.
- Support Impersonation صریح، موجه، قابل‌مشاهده، محدود و کامل Auditشده؛ پیش‌فرض Read-only. عملیات پرخطر ممنوع یا نیازمند تأیید جداگانه.

## ۷. Workload Identity، API Credential و Integration

برای هر Service، Worker، Scheduler، Migration Job و Integration خارجی هویت مستقل تعریف شود؛ Secret سراسری مشترک ممنوع. Credential کوتاه‌عمر و Audience-bound و Federation بومی در صورت پشتیبانی ترجیح دارد. Secret ثابت اجتناب‌ناپذیر باید Scope، Storage، Monitoring، Rotation و Revocation داشته باشد.

Credential به Environment، Tenant Set، Product، Audience، Action مجاز، Expiry و Owner مقید باشد. Credential ورودی و خروجی جدا باشد. پاسخ Provider نباید Role پلتفرم اعطا یا مالکیت Tenant را تغییر دهد.

برای Webhook، در صورت پشتیبانی Signature روی Raw Payload دقیق و Context امنیتی، Timestamp و Replay Window بررسی شود. برای MAC/Signature در صورت کاربرد Constant-time Comparison، Deduplication و رد Replay/پیام کهنه لازم است. API Key، Session کاربر نیست؛ تا حد امکان فقط Verifier/Hash نگهداری، Secret یک‌بار نمایش و Rotation/Revocation پشتیبانی شود؛ Secret Log نشود.

هویت Migration برای Inventory پیش‌فرض Read-only است. هویت Read و Write جدا باشند و هویت Write تا تصویب برنامه مشخص مهاجرت در دسترس نباشد.

## ۸. مدیریت Secret، رمزنگاری و حاکمیت کلید

### ۸.۱ چرخه عمر Secret

از Secret Manager اختصاصی یا سازوکار محافظت‌شده معادل استفاده شود؛ نه Source Code، Config ساده، Ticket، Chat، CI Log یا Laptop توسعه‌دهنده به‌عنوان مخزن مشترک. Owner، Purpose، Consumer، Environment، نوع، ایجاد، دسترسی، Rotation، Revocation، Expiry، Recovery و حذف هر Secret ثبت شود.

دسترسی حداقلی در سطح Secret/Version؛ Provisioning/Rotation خودکار در حد امکان؛ تمرین Revocation اضطراری؛ جداسازی Secret بین Environment، Tenant/Provider و Workload متناسب با ریسک. Plaintext Secret، Token، Private Key، Password، Recovery Code یا Connection String در Log ممنوع. Repository History، Artifact و Log اسکن شوند. Credential افشاشده پیش از تصمیم درباره بازنویسی History لغو/چرخانده شود. Credential پرارزش و بلندمدت در CI/CD نگهداری نشود و Workflow غیرقابل‌اعتماد Pull Request به Secret انتشار Production دسترسی نداشته باشد.

### ۸.۲ رمزنگاری و مدیریت کلید

الزامات رمزنگاری حین انتقال و در حالت سکون بر اساس طبقه داده و Threat Model تعریف شود. در صورت دسترس‌پذیری و توجیه، KMS/HSM مدیریت‌شده ترجیح دارد؛ Provider، Region، Owner، Purpose، Rotation، Access Policy، Backup/Recovery و Destroy مستند شود.

Envelope Encryption برای Field حساس یا داده Tenant-scoped بررسی شود. کلید جدا برای هر Tenant می‌تواند Isolation و Cryptographic Erasure را تقویت کند اما پیچیدگی Lifecycle، Backup، Recovery و عملیات را افزایش می‌دهد؛ بدون Risk Assessment الزام پیش‌فرض نباشد. Data Encryption Key از Key Encryption Key جدا و KEK به‌صورت Plaintext کنار Ciphertext ذخیره نشود.

Rotation باید Decrypt نسخه‌دار در دوره گذار، Re-encryption، Audit و Recovery را پشتیبانی کند. نابودی کلید برگشت‌ناپذیر است و Retention/Legal Hold و Backup را رعایت کند. قطعی KMS، رد دسترسی، Rotation، Revoked Key، Restore با نسخه تاریخی و Offboarding Tenant تست شود. Password با الگوریتم Adaptive مناسب Hash شود؛ برای بازیابی بعدی Encrypt یا Log نشود.

## ۹. Audit، Logging و Evidence

برای اقدام ممتاز، امنیتی، مالی و بین-Scope ثبت شود: Event ID تغییرناپذیر؛ Timestamp و منبع زمان معتبر؛ Actor، Subject، Workload/Client و زنجیره Delegation؛ Scope تأییدشده Tenant/Product/Legal-entity؛ Action، مرجع Resource، Decision و Policy Version/Reason؛ سطح Authentication و Approval/Ticket؛ Request/Trace ID، Source و Outcome؛ مرجع یا Digest Before/After در صورت توجیه (نه Payload حساس خام)؛ نسخه Schema و Metadata Integrity.

از Storage الحاقی یا Tamper-evident، Writer/Reader محدود، Retention محافظت‌شده و پایش مستقل استفاده شود. Hash Chaining/Signing دستکاری را آشکار می‌کند اما به‌تنهایی مانع حذف Privileged نیست؛ در صورت نیاز با مدیریت مستقل، WORM یا نسخه مستقل ترکیب شود. Tenant Admin نباید Audit سراسری بگیرد. Denied Cross-tenant و تغییر Privilege ثبت شود؛ PII حداقلی و Secret، Payment Credential، Auth Token و Body غیرضروری خارج از Log بماند.

Coverage، Retention، حذف/Legal Hold، Export و Access Review برای هر Log Class تعریف شود. Security Audit، Financial Ledger و Application Diagnostics اسناد متفاوت‌اند و جایگزین هم نیستند.

## ۱۰. حریم خصوصی و حاکمیت داده

پیش از جمع‌آوری یا مهاجرت داده شخصی مستند شود:
- Data Inventory و طبقه‌بندی؛
- هدف و ضرورت هر Field و فعالیت پردازش؛
- نقش Controller/Processor/Tenant و مسئولیت قراردادی طبق نظر حقوقی؛
- دسته اشخاص داده و حوزه قضایی مرتبط؛
- مبنای قانونی/اختیار پردازش، Transparency/Notice و Consent در صورت کاربرد؛
- Retention، حذف، Legal Hold و انقضای Backup؛
- دسترسی، اصلاح، Export/Portability و حذف در صورت کاربرد؛
- انتقال برون‌مرزی، Subprocessor، Residency و وابستگی Provider؛
- مسئولیت و زمان‌بندی اطلاع‌رسانی رخداد طبق تعیین حقوقی.

بدون واقعیت و بازبینی حقوقی/Compliance واجد صلاحیت، حوزه قضایی انتخاب یا ادعای انطباق GDPR/PCI DSS/مجوز Gaming مطرح نشود. داده کارت با Tokenization یا Hosted Component مناسب Provider تا حد ممکن کاهش یابد؛ Scope واقعی PCI نیازمند ارزیابی واجد صلاحیت است. داده احراز هویت حساس یا Full Card Credential ذخیره نشود مگر صریحاً مجاز و Scopeشده باشد.

حذف طبق سیاست مصوب به Store مشتق، Cache، Search، Export و Provider منتشر شود؛ با رعایت Legal Hold، سوابق مالی Immutable و Retention Backup. درخواست حذف مجوز نابودی سوابقی نیست که باید قانوناً نگهداری شوند؛ فقط حداقل لازم باقی بماند و دسترسی محدود شود.

## ۱۱. Threat Model و سناریوهای سوءاستفاده

برای هر Domain و Integration یک Threat Model زنده نگهداری شود و STRIDE به‌همراه Abuse Case بررسی گردد:

| تهدید | کنترل و تست لازم |
|---|---|
| IDOR بین Tenantها / تزریق Tenant Context | Membership تأییدشده، Object Check، RLS/Data Boundary و تست منفی همه Routeها |
| Privilege Escalation / ابهام Role | Grant Scopeدار، Deny-by-default، تفکیک وظایف، Approval و Audit تغییر مجوز |
| سرقت Service/API Key | Workload Identity یکتا، عمر کوتاه، Audience/Scope محدود، Revocation و تست Blast Radius |
| Replay/جعل Queue یا Webhook | Signature، Replay Window، Deduplication، Producer Auth و Consumer Re-authorization |
| نشت Cache/Storage/Search | Key/Policy Scopeدار، مجوز Object دقیق و تست Isolation/Deletion |
| سوءاستفاده Insider/Support | JIT، Purpose-bound، Dual Control، Impersonation قابل‌مشاهده و Audit مستقل |
| دورزدن RLS / نشت Pool | ممیزی Role/Owner، منع BYPASSRLS، Context تراکنشی و تست Pool Reuse |
| افشای Secret/Key | Secret Manager، Rotation/Revocation، KMS Policy و تمرین Incident/Recovery |
| دستکاری Audit / انکار اقدام | Append-only/Tamper Evidence، نسخه مستقل، Admin محدود و Integrity Check |
| Retention بیش از حد / انتقال غیرمجاز | Data Inventory، Purpose/Retention، Residency Review و تست حذف |
| Noisy Neighbor / Exhaustion | Quota هر Tenant، کنترل Concurrency/Queue، سقف سراسری و پایش Abuse |
| سوءاستفاده Migration Identity | Read-only پیش‌فرض، پنجره مصوب، Role محدود، Query Limit و بازبینی مستقل |

برای هر تهدید Trust Boundary، Asset، Entry Point، Data Flow، فرض، Mitigation، ریسک باقی‌مانده و Owner ثبت شود. پس از تغییر مهم Tenancy، Payment، Identity، Provider یا Data Flow بازبینی شود.

## ۱۲. راستی‌آزمایی امنیتی و Gateهای CI

از OWASP ASVS 5.0 به‌عنوان کاتالوگ Verification و با انتخاب متناسب با ریسک استفاده شود. ارجاع به ASVS به‌معنای Level یا Certification نیست. هر Requirement به محل پیاده‌سازی، تست خودکار، مدرک دستی، Owner و Exception نگاشت شود.

حداقل Verification:
- ماتریس Authorization برای هر Role × Action × Resource × Tenant/Product/Legal Entity؛
- تست Context مفقود، Null، نامعتبر، کهنه، لغوشده و جعلی؛
- Object-ID Substitution بین Tenantها در API، GraphQL، Search، Export و Support؛
- پوشش RLS برای تمام Tableهای Tenant-owned و CRUD، همراه Owner/BYPASSRLS/SECURITY DEFINER و بررسی مجوز TRUNCATE؛
- تست نشت Context در Pool پس از Commit، Rollback، Exception، Timeout و Cancellation؛
- تست Isolation برای Cache، Queue، DLQ، Worker زمان‌بندی‌شده، Signed URL و Search Index؛
- تست Audience/Scope/Revocation سرویس و Signature/Replay Provider؛
- تست MFA/Step-up، Session Rotation/Revocation، CSRF و Recovery؛
- Secret Scanning و جلوگیری از افشا در Log/Artifact؛
- کامل‌بودن Audit، محدودیت دسترسی، Integrity و Retention؛
- تست KMS، Rotation/Revocation کلید و Restore؛
- تست Retention/Deletion و انتشار درخواست Privacy؛
- تست Abuse/Rate Limit/Noisy Neighbor و Fail-closed هنگام قطعی PDP/IdP/Audit.

CI در صورت Bypass حیاتی Authorization، Cross-tenant Access، افشای Secret، افزایش Privilege بدون بازبینی، فقدان Audit الزامی یا شکست Regression امنیتی باید Release را متوقف کند. Exception نیازمند Owner نام‌دار، دلیل، کنترل جبرانی، انقضا، پذیرش ریسک و بازبینی است؛ Bypass دائمی و بدون سند ممنوع.

## ۱۳. پاسخ به رخداد و حاکمیت

فرآیند Incident شامل Detection، Triage، Containment، Eradication، Recovery، Communication، حفظ Evidence و Lessons Learned تعریف شود. Playbook برای Session/کاربر ربوده‌شده، API Key، Workload Identity، Provider Signing Secret، KMS Key، افشای Cross-tenant، Insider مخرب، RLS اشتباه، دستکاری Audit و رخداد Privacy نگهداری شود.

هر Playbook باید Decision Owner، پاسخ‌دهندگان فنی، تماس حقوقی/Privacy، مسیر Provider Escalation، محل Evidence، Revocation Credential، تصمیم ارتباط با Tenant/مشتری، اعتبارسنجی Recovery و بازبینی پس از رخداد را مشخص کند. مهلت قانونی اطلاع‌رسانی بدون حوزه قضایی و نظر حقوقی تعیین نشود.

Owner کنترل، Owner سیستم، Owner داده/Tenant، بازبین Security، بازبین Privacy/Legal، DBA/Platform Operator، Finance Approver و Release Authority نام‌گذاری شوند. دسترسی ممتاز، هویت سرویس، Integration Provider، Exception، Retention و Threat Model دوره‌ای و پس از تغییر مهم بازبینی شوند.

## ۱۴. معیارهای پذیرش و اقلام تحویل

طراحی P-10D فقط وقتی برای برنامه‌ریزی پیاده‌سازی آماده است که:
۱. دامنه اعتماد، Principal و مدل Authorization Scopeدار مستند باشد؛
۲. Roleها به Action/Resource/Scope صریح شکسته شده باشند؛
۳. مالکیت Tenant/Product/شخصیت حقوقی و قرنطینه shared حفظ شده باشد؛
۴. API، DB، Cache، Queue، Storage، Search، Analytics، Backup و Support طراحی Isolation قابل‌اعمال و تست منفی داشته باشند؛
۵. RLS Role، رفتار Owner/BYPASSRLS، Context در Pool و Function ممتاز پوشش داده شده باشد؛
۶. هویت انسانی/Workload/Migration و Lifecycle کلید/Secret Owner و مسیر Revocation داشته باشند؛
۷. قرارداد Audit، Data Inventory، Retention/Deletion و فرآیند بررسی انتقال برون‌مرزی تعریف شده باشد؛
۸. Threat Model، Abuse Case، ماتریس Verification و Incident Playbook Owner داشته باشند؛
۹. تصمیم حل‌نشده حقوقی، حوزه قضایی، Provider، KMS و عملیات صریحاً Blocker باشد؛
۱۰. Security، Privacy/Legal، Platform/DBA، Finance و مالکان محصول برنامه مختص منبع را بازبینی کنند.

خروجی‌های لازم پیش از پیاده‌سازی: Security Architecture ADR؛ ماتریس Role/Action/Scope؛ نمودار Data Flow و Trust Boundary؛ ماتریس Tenant Isolation؛ طراحی RLS/Database Role؛ Inventory هویت Workload و Secret/Key؛ Schema رویداد Audit؛ Register حریم خصوصی/Retention؛ Threat Model؛ Mapping راستی‌آزمایی ASVS؛ Incident Playbook؛ Exception Register و تأییدهای نام‌دار.

## ۱۵. موارد خارج از دامنه و وضعیت فعلی

این سند Authentication، Authorization، RLS، KMS، Audit Storage، Workflow حریم خصوصی یا CI Gate را پیاده‌سازی نمی‌کند. Vendor یا حوزه قضایی انتخاب نمی‌کند، انطباق را اثبات نمی‌کند، دسترسی Production را مجاز نمی‌کند، Migration را تصویب نمی‌کند و مجوز Privileged Access نمی‌دهد. هیچ سیستم Production بررسی نشده و هیچ Credential یا داده شخصی دسترسی نشده است.

P-10B همچنان پروتکل Inventory فقط‌خواندنیِ اجرا‌نشده و نیازمند Scope منبع و مجوز صریح مالک است. P-10C چارچوب مهاجرت مستقل از منبع است. P-10D فقط خط مبنای طراحی امنیت و حاکمیت مستقل از منبع است.

## ۱۶. منابع پژوهشی

- NIST SP 800-207، معماری Zero Trust: https://csrc.nist.gov/pubs/sp/800/207/final
- NIST SP 800-53 Rev. 5، کنترل‌های امنیت و حریم خصوصی (به‌روزرسانی 5.2.0): https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final
- OWASP ASVS 5.0.0: https://asvs.owasp.org/
- OWASP Authorization Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- OWASP Authorization Patterns: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Patterns_Cheat_Sheet.html
- OWASP Multi-Tenant Security: https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html
- OWASP Secrets Management: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- OWASP ASVS Session Management: https://github.com/OWASP/ASVS/blob/master/5.0/en/0x16-V7-Session-Management.md
- PostgreSQL Row Security Policies: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- PostgreSQL FORCE ROW LEVEL SECURITY: https://www.postgresql.org/docs/current/sql-altertable.html
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html

این منابع مبنای طراحی‌اند؛ به‌معنای پیاده‌سازی، Certification، شمول حقوقی یا ارزیابی امنیت محیط مستقر Lottorito نیستند.
