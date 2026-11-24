# پلتفرم API و تجربه توسعه‌دهندگان

**شناسه سند:** LOT-API-PLATFORM-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** قرارداد پیشنهادی پلتفرم؛ نیازمند بازبینی مالک، معماری، امنیت، مالی، حقوقی و عملیات

## ۱. هدف، مرجع و ارتباط با قراردادهای موجود

این سند لایه پلتفرمی لازم را تعریف می‌کند تا قابلیت‌های Lottorito به‌شکل APIهای تحت حاکمیت، قابل‌کشف، عملیاتی و قابل‌بسته‌بندی تجاری برای اپلیکیشن اختصاصی، Tenantهای B2B بیرونی، اپراتورهای White-Label، شرکای تأییدشده و تیم‌های داخلی محصول عرضه شوند.

این سند اسناد زیر را گسترش می‌دهد و جایگزین آن‌ها نیست:
- **LOT-API-001:** قرارداد Resourceمحور API، مخاطبان احراز هویت، Context Tenant/محصول، خطا، Pagination، Idempotency، Rate Limit، امضای Webhook، نسخه‌بندی، Observability، OpenAPI و تست قرارداد.
- **LOT-EVENT-001:** Envelope رویداد Canonical و معنای تحویل رویداد.
- **LOT-IAM-TENANT-001:** مدل Principal، Tenant، Membership و مجوزدهی.
- **LOT-PROVIDER-EVAL-001:** نقش Provider، شواهد، Due Diligence و فرایند تأیید.
- قراردادهای دامنه از جمله LOT-WALLET-001، LOT-PAYMENT-001، LOT-PAYOUT-001، LOT-CHAT-WIDGET-001 و قراردادهای اختصاصی محصولات.

API Platform صفحه کنترل و توانمندسازی است، نه مسیر دورزدن سرویس دامنه. مالک حقیقت محصول، موجودی Wallet، وضعیت پرداخت، محاسبه کمیسیون، نتیجه Lottery، پیام Chat یا وضعیت Provider نیست. هر دامنه مالک معتبر ناورداها و انتقال وضعیت خودش باقی می‌ماند.

این قرارداد هدف پیشنهادی است. هیچ API Gateway، Developer Portal، SDK، Sandbox، API Key، OAuth Client، Endpoint عمومی، صورتحساب مصرف، Provider یا Runtime به‌عنوان پیاده‌سازی‌شده یا تصویب‌شده ادعا نمی‌شود.

## ۲. اهداف، خارج از محدوده و مخاطبان محصول

اهداف:
۱. تجربه Integration یکپارچه و نسخه‌بندی‌شده برای دامنه‌های محصول مستقل.
۲. کشف و Onboarding Self-service همراه دروازه تأیید انسانی صریح برای قابلیت‌های حساس.
۳. جداسازی قوی Tenant، محیط، اپلیکیشن، Credential و Entitlement محصول.
۴. تست تکرارپذیر Sandbox با داده ساختگی و Fixture قطعی.
۵. تحویل قابل‌اتکای Event/Webhook همراه Replay، Observability و شواهد پشتیبانی.
۶. SDK و مثال تولیدشده از قراردادهای Canonical بازبینی‌شده.
۷. Metering، Quota و Entitlement تجاری شفاف که Policy مالی یا امنیتی را بی‌صدا تغییر ندهند.

مخاطبان و تجربه‌های مستقل:
- **اپ First-Party B2C:** Integration سمت سرور زیر Tenant اختصاصی؛ مرورگر/موبایل Credential ممتاز شریک را دریافت نمی‌کند.
- **توسعه‌دهندگان Tenantهای B2B:** مدیران Tenant و توسعه‌دهندگان متصل‌کننده ماژول‌های واجد شرایط Lottorito به سامانه خود.
- **اپراتورهای White-Label:** اپلیکیشن‌های محدود و تجربه برندشده، با حفظ قابلیت ردیابی مالکیت، منشأ سرویس و Audit لوتوریتو.
- **شرکای Affiliate/Agent:** Credential محدود و Scope دامنه‌ای؛ بدون دسترسی ضمنی به Lottery یا APIهای بازی آینده.
- **شرکای Lottery و دامنه‌های آینده:** صلاحیت محصول و حقوقی مستقل و Adapter اختصاصی Provider پشت قرارداد Canonical لوتوریتو.
- **تیم‌های داخلی محصول:** Workload Identity و قراردادهای سرویس‌به‌سرویس؛ بدون استفاده مجدد از Credential انسانی یا شریک بیرونی.
- **عملیات/امنیت/مالی پلتفرم:** Workspaceهای کنترل‌پلین تحت حاکمیت، نه Credentialهای API مشتری.

خارج از محدوده: جایگزینی APIهای Canonical دامنه؛ افشای Schema دیتابیس یا Payload بومی Provider به‌عنوان قرارداد عمومی؛ اعطای دسترسی بین Tenantها؛ ارائه RPC عمومی بدون محدودیت؛ امکان ساخت مجوز توسط مشتری؛ یا اعلام دسترس‌پذیری محصولات تنظیم‌گری‌شده آینده.

## ۳. معماری منطقی پلتفرم و Planeها

پلتفرم به دو Plane همکار تقسیم شود.

**Control Plane**
- ثبت Developer Organization، Tenant و Application.
- Entitlement محصول، راه‌اندازی محیط و تأیید Integration.
- ثبت OAuth Client، چرخه عمر Credential و Scope.
- تنظیم Endpoint/Subscription مربوط به Webhook و چرخه کلید امضا.
- کاتالوگ API، انتشار مشخصات قرارداد و چرخه نسخه.
- Fixtureهای Sandbox، هویت آزمایشی و کنترل Reset.
- Metering مصرف، Policy سهمیه، Audit، پشتیبانی و سلامت Integration.

**Data Plane**
- API Edge/Gateway و احراز هویت درخواست.
- حل Context Tenant/محصول و اعمال Policy.
- مسیریابی Domain API و مجوزدهی سرویس‌به‌سرویس.
- انتشار Event، تحویل Webhook و وضعیت Job غیرهم‌زمان.
- Rate Limit، اعتبارسنجی Payload، Correlation و Telemetry.

Control Plane، Data Plane را پیکربندی و مشاهده می‌کند، اما منبع حقیقت دامنه نمی‌شود. Policy در Gateway دفاع چندلایه است؛ هر سرویس دامنه باید مجوزدهی و ناورداهای کسب‌وکار را مستقل اعمال کند. Route در Gateway یا مدخل Catalog اثبات پیاده‌سازی Capability نیست.

مسیر منطقی Request:

`Client → API Edge → Authentication → Tenant/Product Policy → Domain API → Domain-owned state`

برای رویداد Async:

`Domain transaction → transactional outbox → canonical event → subscription dispatcher → signed delivery → consumer inbox`

Transactional Outbox/Inbox و قرارداد Event تحت حاکمیت LOT-EVENT-001 هستند؛ تلاش تحویل با اثر اقتصادی یکی نیست.

## ۴. مدل Tenant، Organization، Application و Environment

سلسله‌مراتب پیشنهادی Control Plane:
- حساب Platform و اپراتورهای Platform.
- Tenant و زمینه حقوقی/عملیاتی آن.
- Developer Organization یا تیم Integration مرتبط با Tenant.
- Application با هدف و مالک مشخص Integration.
- Environment: Sandbox، Staging در صورت تصویب و Production.
- OAuth Client / Machine Identity متصل به یک Application و Environment.
- Entitlement محصول و Scopeهای صریح.
- Endpoint و Event Subscription مربوط به Webhook.

یک Tenant می‌تواند چند Application داشته باشد؛ هر Application می‌تواند Client جدا برای هر محیط داشته باشد. Credential هرگز بین Tenant، محصول، Application یا Environment مشترک نباشد. Credential Sandbox به Production دسترسی ندارد و Credential Production به Sandbox. Brand مربوط به White-Label Metadata نمایشی است، نه Principal امنیتی یا جایگزین Tenant.

اپلیکیشن اختصاصی B2C به‌عنوان Application زیر Tenant اختصاصی خودش ثبت می‌شود و همان قواعد قرارداد، تأیید و Audit یک Integration بیرونی را رعایت می‌کند. این اپ Credential سراسری Platform یا دورزننده مجوز دریافت نمی‌کند.

Membership جاری Principal و اتصال تأییدشده Application به Tenant، Context را تعیین می‌کنند. Tenant/Product ID ارسالی Client فقط در صورت پشتیبانی صریح Selector است و باید سمت سرور بررسی شود. Context مفقود، مبهم، قدیمی یا متعارض رد می‌شود.

## ۵. کاتالوگ API، بسته‌بندی محصول و Entitlement

Catalog بر اساس دامنه محصول و Capability سازمان‌دهی می‌شود، نه Microservice داخلی یا جدول دیتابیس. هر مدخل باید این موارد را مشخص کند:
- شناسه پایدار API/Capability و دامنه مالک.
- هدف کسب‌وکار و مخاطب مجاز.
- وضعیت دسترس‌پذیری: planned، preview، active، deprecated، sunset یا unavailable.
- Entitlement لازم Tenant/محصول و صلاحیت حوزه قضایی/عملیاتی.
- OAuth Scopeهای لازم و شرایط مجوزدهی Object-level.
- دسترس‌پذیری محیط و طبقه‌بندی داده.
- نسخه API، لینک Schema، مثال و Changelog.
- کلاس Rate/Usage و رفتار Sync/Async.
- نوع Eventهای Webhook و معنای Retention/Replay.
- مالک پشتیبانی، مسیر Escalation و محدودیت‌های شناخته‌شده.

Packageهای محصول می‌توانند Capabilityها را Bundle کنند، اما Entitlement باید صریح و مستقل از هم قابل‌لغو باشد. بسته‌بندی تجاری نمی‌تواند صلاحیت حقوقی، مشتری، Policy امنیتی، وضعیت دامنه یا دسترس‌پذیری Provider را Override کند. Entitlement مربوط به Affiliate به‌طور خودکار Lottery، Wallet، Payment، Payout، Chat یا API بازی آینده را فعال نمی‌کند. هر Capability دروازه و وابستگی مستقل دارد.

Catalog عمومی نباید Capability تنظیم‌گری‌شده برنامه‌ریزی‌شده یا غیرمجاز از نظر حقوقی را Active تبلیغ کند. دسترسی Preview دعوت‌محور، محدود به Scope، زمان‌دار و صریحاً غیرProduction است، مگر جداگانه تصویب شود.

## ۶. هویت، OAuth و چرخه عمر Credential

احراز هویت و مجوزدهی از LOT-API-001 و LOT-IAM-TENANT-001 پیروی می‌کنند. مدل زیر گزینه پیشنهادی برای ارزیابی است، نه پروفایل OAuth مصوب:
- Integrationهای Server-to-server از Machine Identity محدود و Access Token کوتاه‌عمر استفاده می‌کنند.
- OAuth 2.0 Client Credentials همراه احراز هویت نامتقارن Client (برای نمونه private-key JWT یا mutual TLS) قابل ارزیابی است.
- Authorization Code همراه PKCE برای Integrationهای Delegated کاربرمحور، در صورت نیاز به Consent و تفویض هویت، قابل ارزیابی است.
- اپ Browser/Mobile نباید Client Secret یا API Key بلندعمر Platform را در خود جای دهد.
- API Key در صورت استفاده برای شناسایی محدود یا سازگاری Legacy، جایگزین مجوزدهی Scopeدار و قابل‌لغو نیست.

رکورد Credential به Tenant، Application، Environment، Client Identity، Audience مجاز، Scopeها، Actor ایجادکننده، مالک، انقضا و وضعیت متصل است. چرخه عمر شامل صدور، نمایش/تحویل امن یک‌باره، Rotation، دوره هم‌پوشانی، Revocation، غیرفعال‌سازی اضطراری، انقضا و Audit است. Secret فقط به شکل Verifier/Material محافظت‌شده متناسب با سازوکار منتخب ذخیره می‌شود؛ مقدار خام Secret پس از صدور دوباره قابل بازیابی نیست.

Least Privilege، عمر کوتاه Token، محدودیت Audience و Scope و بررسی سمت سرور Membership/Entitlement لازم است. نام Scope جایگزین مالکیت Object یا بررسی Policy کسب‌وکار نیست. عملیات ممتاز مالی، هویت، Payout، Beneficiary، مدیریت Tenant و مدیریت کلید به احراز هویت/تأیید قوی‌تر و Audit تغییرناپذیر نیاز دارند.

## ۷. Webhook Subscription، تحویل و Replay

Webhook Subscription یک Resource در Control Plane است. مدیر Tenant یک Endpoint HTTPS ثبت، مالکیت Endpoint را با Challenge تأیید، فقط Event Typeهای دارای Entitlement را برای محیط مربوط انتخاب و Policy تحویل را در محدوده مجاز پیکربندی می‌کند.

هر Subscription به Tenant، Application، Environment، Endpoint، Allowlist رویداد، نسخه کلید امضا، وضعیت، Actor ایجادکننده و Policy تحویل متصل است. Filter بین Tenantها یا Wildcard برای خانواده رویداد حساس مجاز نیست.

معنای تحویل:
- تحویل At-least-once؛ مصرف‌کننده با هویت پایدار Event Deduplicate می‌کند.
- Delivery ID معرف تلاش است؛ Event ID معرف رویداد Canonical است؛ هیچ‌کدام به‌تنهایی مجوز Posting اقتصادی نیستند.
- بایت‌های Canonical مستندشده امضا شوند و Key ID، Timestamp، Event ID و Delivery ID را شامل شوند.
- مصرف‌کننده پیش از پردازش Signature و Timestamp را بررسی، در Inbox پایدار ثبت و سپس دریافت پایدار را ACK می‌کند.
- Retry با Exponential Backoff محدود و Jitter؛ پاسخ‌های Retryable و Permanent طبقه‌بندی شوند.
- تاریخچه تحویل، تعداد تلاش، Retry بعدی، کلاس آخرین پاسخ و وضعیت Dead-letter بدون افشای Secret یا Eventهای Tenant دیگر نمایش داده شود.
- Replay دستی عملیاتی محدود و Auditشده است و نباید Event اقتصادی جدید بسازد.
- Pause، غیرفعال‌سازی Endpoint، Rotation کلید با هم‌پوشانی و Revocation اضطراری پشتیبانی شوند.

HTTP Response موفق به‌معنای پذیرفته‌شدن تحویل است، نه پردازش موفق کسب‌وکار یا Settlement. فرستنده نمی‌تواند Exactly-once در شبکه را تضمین کند. مصرف‌کننده باید Duplicate، تأخیر، جابه‌جایی ترتیب و Event متعارض را مطابق قرارداد دامنه مدیریت کند.

## ۸. SDK، تولید کد و نمونه Integration

SDKها Clientهای Typed و سبک‌اند که از OpenAPI و Schema رویداد بازبینی‌شده تولید می‌شوند. نباید منطق ممتاز کسب‌وکار، Secret تعبیه‌شده، Override پنهان Policy یا دسترسی مستقیم به Database/Provider داشته باشند.

مجموعه زبان اولیه باید بر اساس تقاضای تأییدشده شریک و توان نگهداری تیم انتخاب شود. فهرست کوتاه پیشنهادی برای ارزیابی: TypeScript/JavaScript، Python، Java و PHP؛ این فهرست تعهد عرضه نیست. زبان‌های بعدی از جمله Go، .NET، Swift و Kotlin نیازمند تقاضا و مالک نگهداری‌اند.

هر نسخه SDK باید منتشر کند:
- سازگاری Major API و Semantic Version خود SDK.
- نسخه‌های Runtime/Language پشتیبانی‌شده و Policy وابستگی.
- مدل‌های Typed درخواست/پاسخ و Helperهای Pagination.
- رفتار Retry امن و سازگار با Idempotency و Retry-After.
- دسترسی به Correlation/Request ID و Error Type ساختاریافته.
- Helper بررسی امضای Webhook با Default امن.
- مثال‌های احراز هویت، Context Tenant، عملیات Async و مصرف Event.
- Changelog، راهنمای Migration، اعلان Deprecation و کانال گزارش امنیتی.

کد تولیدشده باید تکرارپذیر، بازبینی‌شده و قابل‌ردیابی به Commit دقیق قرارداد Canonical باشد. SDK ناسازگار بی‌صدا بازتولید و منتشر نشود. Sample Appها از داده ساختگی و تنظیمات محلی امن استفاده می‌کنند؛ بدون Credential واقعی یا رکورد مشتری Production.

## ۹. Developer Portal، مستندات و Onboarding

Developer Portal سطح مخصوص توسعه‌دهنده بیرونی از Control Plane است، نه داشبورد Platform Admin.

قابلیت‌های پیشنهادی:
- ثبت Organization و Application با تأیید مالکیت.
- اتصال Tenant و مشاهده Entitlementها، بدون افشای کنترل‌های داخلی.
- Catalog API، مرجع تعاملی و دانلود OpenAPI/Event Schema.
- Quickstart، راهنمای معماری، آموزش Authentication و مثال اجرایی.
- مدیریت Environment/Client و Rotation/Revocation Credential.
- ثبت/تأیید Webhook Endpoint، Subscription و Log تحویل.
- داده آزمایشی Sandbox، Fixture، اجرای سناریو و کنترل Reset.
- Usage API، Quota، خلاصه Latency/Error و اطلاعیه رخداد.
- Changelog نسخه، تقویم Deprecation/Sunset و راهنمای Migration.
- Support Ticket، عیب‌یابی Integration و Status Page.

مراحل Onboarding:
۱. کشف Capability و بررسی دسترس‌پذیری محصول/حوزه قضایی.
۲. ثبت Organization و Application؛ تأیید مالکیت و مدیر مجاز.
۳. درخواست حداقل Entitlement محصول و Scope.
۴. تکمیل بازبینی حقوقی، حریم خصوصی، امنیت و تجاری موردنیاز.
۵. Provision کردن Credentialهای Sandbox ایزوله و Fixture ساختگی.
۶. اجرای تست پذیرش قرارداد، امنیت، Webhook و دامنه.
۷. درخواست فعال‌سازی Production؛ در صورت نیاز ریسک، تأیید Maker-checker.
۸. صدور Credentialهای Production، پایش ترافیک اولیه و حفظ مسیر Rollback/Revocation.

Self-service نباید قابلیت تنظیم‌گری‌شده، مالی، هویتی، Payout، داده حساس یا Provider را خودکار تأیید کند. وضعیت Approval و نیازمندی‌های باقی‌مانده باید صریح باشند.

## ۱۰. Sandbox، Fixtureهای تست و جداسازی محیط

Sandbox محیط Integration قطعی است، نه آینه‌ای حاوی داده مشتری Production. باید از Principal، Tenant، Wallet، ابزار پرداخت، پاسخ Provider و Event Fixture ساختگی استفاده کند. Balance/Credit آزمایشی غیرنقدی است و به Production قابل‌انتقال نیست.

رفتار Sandbox باید سناریوهای زیر را پشتیبانی کند:
- موفقیت، خطای اعتبارسنجی، رد، Duplicate، Timeout، نتیجه Unknown، Callback تأخیری، Event خارج از ترتیب و Provider غیرقابل‌دسترس.
- Replay در Idempotency و Conflict برای همان Key با Payload متفاوت.
- بررسی Signature Webhook، Retry، Replay و Rotation کلید.
- جداسازی Tenant/Object و رد Entitlement.
- شبیه‌سازی Authorization پرداخت، شکست، Refund و Settlement بدون وجه واقعی.
- صلاحیت Payout، Hold، Approval، نتیجه نامعلوم Provider و Return بدون پرداخت واقعی.
- انقضای Session چت، Reconnect، پیام تکراری و تست قرنطینه پیوست.
- Reset قطعی همراه نسخه Fixture و آثار جانبی مستند.

Sandbox و Production از Credential، کلید رمزنگاری، Data Store/Partition، Queue، Endpointهای Webhook، Rate Limit و پیکربندی Provider جدا هستند. هیچ Fixture آزمایشی نباید ارزش Ledger واقعی بسازد، Payment/Payout واقعی ایجاد کند یا با مشتری واقعی تماس بگیرد. Staging نیز جداگانه حاکمیت می‌شود و نباید جایگزین غیررسمی Production باشد.

## ۱۱. Metering، Quota، قیمت‌گذاری و کنترل تجاری

Metering باید شفاف، Auditپذیر و از Enforcement امنیتی جدا باشد. ابعاد پیشنهادی شامل تعداد Request، واحد وزنی عملیات، تحویل Webhook، اتصال هم‌زمان، حجم پیام، Storage/Egress و مصرف Job Async است. رویداد مصرف مرجع، پنجره Aggregation، Timezone، فرایند اصلاح و مسیر اعتراض باید پیش از صورتحساب تعریف شوند.

اعمال Quota:
- Limit بر اساس Tenant، Application، Credential، Route، محصول و هزینه عملیات.
- Headerهای Rate Limit و Retry-After مستندشده در صورت کاربرد.
- Fair-use Budget و Burst Control برای حفاظت از ظرفیت مشترک.
- جداسازی Limit سخت ایمنی از Limit نرم تجاری.
- هشدار و نمایش Usage پیش از اتمام قابل‌پیش‌بینی.
- Event مالی/امنیتی حساس به‌دلیل Quota نباید بی‌صدا حذف شود؛ از صف پایدار، رد صریح یا Backpressure کنترل‌شده همراه Alert استفاده شود.
- اتمام Quota نباید مصرف Tenant دیگر را افشا کند.

قیمت، واحد صورتحساب، پلن رایگان، Overage، Grace Period، سطح پشتیبانی و مالیات تصمیم‌های تجاری باز هستند. Metering صورتحساب را نمی‌توان صرفاً از Log درخواست استنباط کرد و نباید Entry دفترکل یا موجودی دامنه را تغییر دهد. این سند هیچ قیمت یا SLA را تصویب نمی‌کند.

## ۱۲. قابلیت اطمینان، Observability و عملیات پشتیبانی

برای هر Capability API، مالک، Criticality، نقشه وابستگی، Timeout، Retry Policy، بودجه هم‌زمانی، رفتار Idempotency، حالت Degradation، گزارش وضعیت و شواهد Recovery تعریف شود.

Telemetry لازم:
- Request/Correlation/Trace ID، شناسه مستعار Tenant/Application، نسخه API، Route Template، نتیجه، Latency و تصمیم Quota.
- عدم ثبت Access Token، Client Secret، اطلاعات کامل پرداخت، مدرک هویتی خام، Transcript چت یا Body حساس درخواست در Telemetry عادی.
- Dashboardهای هر Tenant/Application با مجوز سخت‌گیرانه و Aggregation امن.
- وضعیت تحویل Webhook، عمق صف Retry، تعداد Dead-letter و سلامت Endpoint.
- میزان استفاده از نسخه SDK/API و مواجهه با Deprecation.
- Audit تغییر Credential، Entitlement، Subscription، Quota و فعال‌سازی Production.

مدل Support باید Severity، مالک پاسخ، کنترل دسترسی Support، گردآوری شواهد، Escalation به Provider و ارتباط رخداد را تعریف کند. کارکنان Support دسترسی موقت، هدف‌محور و حداقلی می‌گیرند؛ دسترسی اضطراری ثبت و بازبینی می‌شود. Status Page باید رخداد API Edge، سرویس دامنه و Provider بیرونی را از هم تفکیک کند.

SLO عددی، RTO/RPO، Quota، ساعات پشتیبانی و هدف زمان پاسخ تا زمان وجود شواهد بارکاری و تصویب مالک پاسخ‌گو تعیین‌نشده‌اند.

## ۱۳. حاکمیت چرخه عمر API و SDK

قرارداد Canonical منبع حقیقت بازبینی‌شده است. خط لوله انتشار پیشنهادی:
۱. مالک دامنه تغییر قرارداد را با معنای پایدار Resource/Event ایجاد می‌کند.
۲. بازبینان امنیت، Tenant، حریم خصوصی و مالی اثر تغییر را بررسی می‌کنند.
۳. OpenAPI و Schema رویداد اعتبارسنجی و مثال‌ها قابل‌اجرا یا Schema-checked می‌شوند.
۴. تحلیل خودکار سازگاری، تغییر ناسازگار و پرریسک را شناسایی می‌کند.
۵. تست قرارداد مصرف‌کننده/Provider و سناریوهای Sandbox می‌گذرد.
۶. SDK و مستندات از Revision ثابت قرارداد تولید می‌شوند.
۷. Release Note، Migration Guide و پنجره Deprecation منتشر می‌شود.
۸. انتشار Production قابل‌مشاهده، برگشت‌پذیر و برای Capability مربوط تأییدشده است.

تغییر ناسازگار به Major API جدید، برنامه Migration و پنجره پشتیبانی موازی نیاز دارد. تغییر افزایشی نیز باید سازگاری Client سخت‌گیر و معنای امنیتی را رعایت کند. واحدها، معنای Enum، Defaulting، مجوزدهی، فرض ترتیب Event یا معنای مالی هرگز بی‌صدا تغییر نکند.

Policy Deprecation باید اعلان، جایگزین، حداقل پنجره پشتیبانی، تاریخ Sunset، گزارش مصرف، فرایند استثنا و تأیید غیرفعال‌سازی نهایی را تعریف کند. غیرفعال‌سازی اضطراری امنیتی ممکن است سریع‌تر باشد اما به حاکمیت رخداد و ارتباط با مشتری نیاز دارد. نسخه API، SDK، Schema Webhook و Adapter Provider محورهای مستقل‌اند.

## ۱۴. کنترل‌های امنیت، حریم خصوصی و انطباق

- Control Plane و Data Plane جداگانه Threat Model شوند؛ از جمله Confused Deputy، سرقت Credential، جایگزینی Tenant، ارتقای مجوز، SSRF در Webhook، سوءاستفاده Endpoint و Supply-chain compromise.
- Endpointهای Webhook در برابر SSRF، DNS Rebinding، آدرس‌های Private/Link-local/Metadata و Redirect ناامن اعتبارسنجی شوند؛ Resolution هنگام اتصال دوباره بررسی و Egress Control اعمال شود.
- Credential با مدیریت کلید KMS/HSM-backed در صورت تصویب محافظت شود؛ Custody، Rotation، دسترسی و Recovery مستند شود. معماری به‌تنهایی Certification نیست.
- اتصال Tenant/Application/Environment روی هر Lookup مربوط به Credential و Resource اعمال شود.
- برای عملیات Control Plane در مرورگر CSRF Protection؛ Cookie امن، CSP و Step-up Authentication برای تغییرات حساس.
- Data Minimization، Retention، Deletion/Export، Residency و قرارداد Processor بر اساس حوزه قضایی.
- Secret و داده شخصی/حساس از Log، Trace، مثال، Fixture SDK و گزارش عمومی Issue خارج بماند.
- Inventory وابستگی، SBOM، Artifact امضاشده و فرایند افشای/رسیدگی آسیب‌پذیری برای SDK و Portal نگهداری شود.
- قابلیت تنظیم‌گری‌شده/پرداخت/Payout به دروازه‌های مستقل شخصیت حقوقی، حوزه قضایی، مجوز، Provider، مالی و استفاده مسئولانه نیاز دارد.

## ۱۵. سناریوهای پذیرش و دروازه انتشار

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| API-PLAT-01 | B2C اختصاصی Application ثبت می‌کند | اتصال به Tenant اختصاصی؛ همان کنترل Integration بیرونی؛ بدون Master Credential پلتفرم |
| API-PLAT-02 | Credential در Tenant/Environment دیگر استفاده می‌شود | رد؛ بدون نشت داده بین Scope |
| API-PLAT-03 | اپ API محصول بدون Entitlement درخواست می‌کند | رد در Edge و سرویس دامنه |
| API-PLAT-04 | Partner Secret در Bundle مرورگر وجود دارد | Build/Security Scan انتشار را متوقف می‌کند |
| API-PLAT-05 | Token دارای Audience اشتباه یا Membership منقضی است | پس از بررسی Context سمت سرور رد می‌شود |
| API-PLAT-06 | Rotation Credential انجام می‌شود | هم‌پوشانی، انقضا و Revocation قابل ممیزی؛ Credential قدیمی از کار می‌افتد |
| API-PLAT-07 | Webhook Endpoint به Metadata/شبکه خصوصی اشاره می‌کند | ثبت یا تحویل با کنترل SSRF مسدود می‌شود |
| API-PLAT-08 | Webhook تکراری/خارج از ترتیب تحویل می‌شود | Inbox مصرف‌کننده Deduplicate می‌کند؛ معنای دامنه صحیح می‌ماند |
| API-PLAT-09 | Replay دستی Webhook درخواست می‌شود | Replay مجاز و Auditشده؛ بدون اثر اقتصادی جدید |
| API-PLAT-10 | کلید Webhook حین Retry عوض می‌شود | هر دو کلید معتبر فقط در پنجره هم‌پوشانی مصوب کار می‌کنند |
| API-PLAT-11 | SDK عملیات مالی Timeoutشده را Retry می‌کند | همان Idempotency Key؛ فقط یک اثر اقتصادی |
| API-PLAT-12 | OpenAPI تغییر ناسازگار دارد | CI انتشار را مسدود یا Major جدید و Migration Plan را الزام می‌کند |
| API-PLAT-13 | Fixture پرداخت/Payout در Sandbox اجرا می‌شود | فقط ساختگی؛ بدون وجه، مشتری یا اثر Provider واقعی |
| API-PLAT-14 | Credential Sandbox به Production درخواست می‌زند | رد؛ مرز اعتماد و ذخیره‌سازی جدا |
| API-PLAT-15 | Tenant از Quota عبور می‌کند | پاسخ/Backpressure محدود به همان Tenant؛ بدون سیگنال بین‌مستاجری |
| API-PLAT-16 | حجم Event مالی/امنیتی از Quota عادی بیشتر می‌شود | پردازش پایدار کنترل‌شده یا Alert/رد صریح؛ هرگز حذف بی‌صدا |
| API-PLAT-17 | توسعه‌دهنده SDK تولیدشده را دانلود می‌کند | قابل‌ردیابی به Revision قرارداد بازبینی‌شده و Major سازگار API |
| API-PLAT-18 | Support یک Integration را بررسی می‌کند | دسترسی موقت هدف‌محور؛ Payload حساس Mask و Audit می‌شود |
| API-PLAT-19 | API منسوخ می‌شود | مصرف‌کننده اعلان، گزارش مصرف، جایگزین و مسیر Sunset می‌گیرد |
| API-PLAT-20 | محصول تنظیم‌گری‌شده مجوز قانونی ندارد | Catalog و Runtime با وجود Route فنی، Production Entitlement را رد می‌کنند |

دروازه Pilot:
- تصویب مخاطب API، مالکیت، مدل Tenant/Application و فهرست اولیه Resource.
- تصویب پروفایل Authentication، مدیریت کلید، Scope و هدف زمانی Revocation.
- تکمیل Threat Review مربوط به SSRF/Webhook و تست جداسازی Tenant.
- اعتبارسنجی OpenAPI/Schema رویداد Canonical و گردش سازگاری.
- اثبات جداسازی Sandbox، Fixture قطعی و تضمین عدم استفاده از پول واقعی.
- تعیین مالک دامنه، Escalation پشتیبانی، Incident و Rollback.
- تکمیل بازبینی حریم خصوصی، حقوقی، تجاری و محل داده برای شخصیت‌های حقوقی/بازارهای دقیق.

عرضه عمومی علاوه بر این موارد به شواهد Load/Recovery، بازبینی مستقل امنیت متناسب با ریسک، کنترل Supply Chain SDK، مدل پشتیبانی، دقت Metering مصرف، مستندات مشتری و فعال‌سازی Production مصوب نیاز دارد.

## ۱۶. تصمیم‌های باز و اسناد مرتبط

تصمیم‌های باز:
- API Edge/Gateway و توپولوژی میزبانی Control Plane.
- پروفایل OAuth/OIDC، احراز هویت نامتقارن Client و قالب/عمر Token.
- مخاطب و فهرست Capability اولیه؛ مرز Public در برابر Partner/Private.
- تأیید Developer Organization و گردش Approval برای Production.
- ترتیب زبان SDK و مالک نگهداری بلندمدت.
- توپولوژی Sandbox، Policy Reset Fixture و دامنه شبیه‌سازی Provider.
- پنجره Retry/Retention Webhook، مجوز Replay و معماری Egress ضد SSRF.
- ابعاد Metering، قیمت، Free Tier، Overage و سطح Support.
- پنجره Deprecation API/SDK، SLO، RTO/RPO و Data Residency.
- مجموعه API پایلوت اولیه Affiliate و افشای جداگانه B2C/Wallet/Payment/Chat با Gateهای مستقل.

اسناد مرتبط: LOT-API-001، LOT-EVENT-001، LOT-IAM-TENANT-001، LOT-PROVIDER-EVAL-001، LOT-WALLET-001، LOT-PAYMENT-001، LOT-PAYOUT-001، LOT-B2C-PRD-001، LOT-CHAT-WIDGET-001، LOT-QA-001، LOT-SEC-TM-001 و LOT-TECH-ADR-001.

این سند Proposed است. API منتشر نمی‌کند، Credential صادر نمی‌کند، Provider تأیید نمی‌کند، قیمت تعیین نمی‌کند، دسترسی Production مجاز نمی‌سازد و Developer Portal، SDK، Sandbox یا API Gateway پیاده‌سازی نمی‌کند.
