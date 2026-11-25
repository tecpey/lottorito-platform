# برنامه Prototype معماری و تولید شواهد Lottorito

**شناسه سند:** LOT-PROT-001 | **نسخه:** ۱.۱۴.۰ | **وضعیت:** برنامه آزمایش پیشنهادی؛ اجرا و انتخاب فناوری تصویب نشده است

## ۱. هدف و اعتبار

این برنامه هشت آزمایش الزامی LOT-TECH-ADR-001 را عملیاتی می‌کند و هرکدام را به سناریوهای قابل‌اندازه‌گیری LOT-QA-001 متصل می‌سازد. هدف آن مشخص‌کردن شواهد لازم پیش از انتخاب Stack، توپولوژی دیتابیس، Runtime، موتور Queue/Workflow، مدل میزبانی یا الگوی استقرار است.

این سند برنامه است، نه شاهد اجرای Prototype. هیچ فناوری کاندید در اینجا انتخاب یا تصویب نمی‌شود. مالک و مراجع ذی‌صلاح دامنه باید پیش از اجرا، محدوده آزمایش، نحوه نگهداری داده حساس و هر استثنای پذیرش را تأیید کنند.

## ۲. ورودی‌ها و کنترل‌های الزامی

پیش از شروع هر آزمایش:
- تصمیمی را که آزمایش پشتیبانی می‌کند، گزینه‌های مورد مقایسه و مالک پاسخ‌گوی تصمیم مشخص کنید.
- فرضیه دقیق را ثبت کنید؛ فناوری ترجیحی را نتیجه از پیش تعیین‌شده معرفی نکنید.
- از داده ساختگی و زیرساخت ایزوله غیر Production استفاده کنید. داده واقعی بازیکن/مشتری/ایجنت، خروجی Production، وجه واقعی، Credential عملیاتی یا Secret واقعی شریک ممنوع است.
- نسخه‌ها، تنظیمات، توپولوژی، پروفایل بار، تزریق خطا، فرمان تست و پاک‌سازی محیط را مستند کنید.
- رفتار مورد انتظار و قواعد Pass/Fail را پیش از اجرا تعریف کنید.
- محدودیت، فرض، هزینه، بار عملیاتی و قابلیت انتقال را نیز ثبت کنید؛ فقط موفقیت مسیر عادی کافی نیست.
- بدون مجوز صریح، Endpoint عمومی ایجاد نکنید و با شریک/Provider تماس نگیرید.

وضعیت هر Prototype می‌تواند **Pass، Fail، Inconclusive یا Not run** باشد. Pass فقط به‌معنای موفقیت آزمایش تعریف‌شده در محیط ثبت‌شده است؛ آمادگی Production یا تأیید حقوقی/انطباق را ثابت نمی‌کند.

## ۳. فهرست آزمایش‌ها

| شناسه | Prototype | تصمیم اصلی مورد پشتیبانی | ویژگی‌های کیفی |
|---|---|---|---|
| P-01 | مرز Tenant و انتشار Context | اجرای جداسازی در Request، دیتابیس و کار غیرهمزمان | QA-01، QA-02، QA-09، QA-12 |
| P-02 | تراکنش مالی و تطبیق | مرز تراکنش، دقت مبلغ، دفترکل و هم‌زمانی | QA-03، QA-04، QA-07، QA-12 |
| P-03 | خرابی Provider و تحویل رویداد | طراحی Adapter، Inbox/Outbox، Retry، Replay و تطبیق | QA-04، QA-06، QA-07، QA-11 |
| P-04 | تکامل Schema و سازگاری | روش Migration و هم‌زیستی نسخه برنامه/Worker | QA-05، QA-14، QA-15 |
| P-05 | Backup، Restore و بازیابی | روش پشتیبان، وابستگی‌های بازیابی و امکان عملیات | QA-07، QA-08، QA-12 |
| P-06 | Observability سرتاسری و حریم خصوصی | معماری Telemetry، هم‌بستگی و کنترل داده حساس | QA-09، QA-10، QA-12 |
| P-07 | ترکیب مستقل محصولات | استقلال Bounded Context و بسته‌بندی Affiliate و Lottery | QA-01، QA-02، QA-13، QA-14، QA-15 |
| P-08 | استقرار، Health Gate و Rollback | ارتقای Artifact، تزریق Secret، انتشار و ایمنی بازگشت | QA-06، QA-08، QA-09، QA-12، QA-14 |

## ۴. مشخصات تفصیلی Prototypeها

### P-01 — مرز Tenant و انتشار Context

**پرسش:** آیا Context مربوط به Tenant از عضویت احراز‌شده استخراج و در همه مسیرهای دسترسی به داده منتشر و اعمال می‌شود، بدون آنکه به شناسه Tenant ارسالی از سوی Caller اعتماد شود؟

**حداقل Fixture:** دو Tenant ساختگی، کاربران و API Clientهای جدا، Principal اپراتور/پشتیبانی با دسترسی محدود و صریح، رکوردهایی با Natural Key یکسان در هر دو Tenant و یک Job غیرهمزمان برای هر Tenant.

**آزمایش‌ها:**
۱. کاربر را احراز هویت و عضویت Tenant را در سمت سرور Resolve کنید؛ Override کردن Context از طریق پارامتر، Header و شناسه Resource را امتحان کنید.
۲. از مسیر API و Service داخلی، رکورد را بخوانید/تغییر دهید؛ ارجاع Object بین دو Tenant را آزمایش کنید.
۳. Job را Enqueue، Retry، Schedule و Replay کنید؛ Context باید احراز‌شده، برای Job تغییرناپذیر و هنگام اجرا دوباره مجوزدهی شود.
۴. Database، Cache Key، Object Storage، Search، Export و Reporting را با شناسه‌های برخوردکننده آزمایش کنید.
۵. عضویت و Credential را در حالی لغو کنید که Session/Job باز است؛ رفتار Context قدیمی را بررسی کنید.
۶. دسترسی Support/Break-glass را با علت، Scope، انقضا و Audit صریح آزمایش کنید.

**معیار Pass:**
- تمام تلاش‌های Read/Write بین Tenantها رد شوند و هیچ اثر جانبی نداشته باشند.
- Context Tenant از ورودی غیرقابل‌اعتماد قابل ارتقا یا تغییر نباشد.
- هر عملیات غیرهمزمان و زمان‌بندی‌شده هویت Tenant و Workload قابل انتساب داشته باشد.
- لغو دسترسی و دسترسی ممتاز پشتیبانی مطابق Policy مستند عمل کند.
- هر مرز واقعی Storage/Cache/Search/Reporting در Prototype آزمون شود؛ مرزهای آزمون‌نشده به‌عنوان Gap ثبت شوند.

**شواهد:** ماتریس تست به تفکیک مرز، Trace درخواست/Job، نتیجه مجوزدهی، شواهد Policy دیتابیس در صورت کاربرد، خروجی تست منفی و فهرست مسیرهای آزمون‌نشده.

**یادداشت وضعیت آزمایش P-01 (۲۰۲۶-۱۱-۲۴):** PR شماره ۳۶ تعداد ۲۰ تست یکپارچه‌سازی ساختگی را با موفقیت گذرانده است. PR تکمیلی شماره ۳۹، Grant پشتیبانی محدود، زمان‌دار و فقط‌خواندنی و Audit فقط‌افزودنی را اضافه می‌کند؛ آخرین اجرای CI با شناسه 45418177150 روی Head با شناسه d2e9fc81a17036e5d6e63c07ee1e64fa055a24eb تعداد ۲۶ تست را با موفقیت گذرانده است. این فقط شواهد جزئی است: حداقل‌سازی Metadata پشتیبانی، هویت/MFA عملیاتی، آزمون فشار Race و Failure در سطح Endpoint، Credential Broker، Cache/Storage/Search/Reporting، بار و Recovery همچنان باز هستند. هیچ فناوری یا معماری Production تصویب نشده است.

**وضعیت آزمایش Data Plane ثانویه در P-01 (۲۰۲۶-۱۱-۲۴):** یک Prototype تکمیلی، Cache Key مشتق از Tenant، Object Key دارای Prefix Tenant، فیلتر Search تزریق‌شده از سمت سرور و جدول Reporting با RLS مستقل اضافه می‌کند. Cache/Object/Search فقط از Adapterهای In-memory استفاده می‌کنند؛ رفتار Provider واقعی Redis/S3/OpenSearch/Warehouse صریحاً تأییدنشده است. مجموعه تست Data Plane در اجرای CI با شناسه 45419828256 روی Head کد 02850c6374dd295ec0df6ba42addf266a2d8a977 تعداد ۳۰ تست موفق داشته است. رفتار Provider واقعی همچنان تأییدنشده است.

**وضعیت آزمایش Credential/Pool برای Tenant در P-01 (۲۰۲۶-۱۱-۲۴):** یک Prototype تکمیلی، Resolve اعتبارنامه سمت سرور، ادغام ساخت Poolهای هم‌زمان، سقف سراسری Pool و سقف Connection هر Pool، رزرو Lease، Eviction فقط از Poolهای Idle با LRU/TTL، تخلیه هنگام لغو، Shutdown تکرارپذیر و بررسی ثابت هویت دیتابیس پیش از انتشار Pool را اضافه می‌کند. Roleهای ساختگی PostgreSQL از نوع LOGIN مسیر هویت‌محور را در CI با [۴۰ تست موفق، صفر شکست و صفر Skip](https://github.com/tecpey/lottorito-platform/actions/runs/45424792886) روی Head `153fc8974c9c620acd8d509afdea0341669e5c` اعتبارسنجی کردند؛ Documentation Governance نیز با شناسه [45424793114](https://github.com/tecpey/lottorito-platform/actions/runs/45424793114) موفق شد. Vault/KMS، چرخش Credential، Quota سراسری Fleet، PgBouncer، سیاست TLS، Failover و مقیاس همچنان تأییدنشده‌اند. هیچ توپولوژی تصویب نشده است.

### P-02 — تراکنش مالی و تطبیق

**پرسش:** آیا یک رویداد تجاری هم‌زمان و Retryشده دقیقاً یک اثر اقتصادی معتبر و یک سند متوازن و تغییرناپذیر ایجاد می‌کند؟

**حداقل Fixture:** حساب‌های ساختگی در دو Tenant و حداقل دو ارز، ورودی نمونه کمیسیون نسخه‌بندی‌شده، ساعت تست کنترل‌شده، تحویل تکراری Source Event و Workerهای هم‌زمان. هیچ وجه واقعی یا موجودی قابل برداشت استفاده نشود.

**اولین برش اجرایی P-02 (۲۰۲۶-۱۱-۲۴):** یک Prototype ساختگی مستقل، مرز ثبت SECURITY DEFINER محدود به Tenant، رکوردهای تغییرناپذیر Journal/Line/Request/Outbox، مبلغ صحیح دقیق NUMERIC(38,0)، کنترل توازن به‌تفکیک ارز، Idempotency دو‌سطحی محدود به Tenant (`idempotency_key` برای Retry درخواست و `effect_id` برای اثر مالی منطقی)، همگرایی Duplicate هم‌زمان و Transactional Outbox در یک Statement را پیاده‌سازی می‌کند. تست‌ها Rollback هنگام شکست Outbox، دقت ۳۸ رقمی، توازن چندارزی، جداسازی حساب Tenant، دو Request Key برای یک Effect، رد محتوای متفاوت و چند Effect مجاز از یک Source Event را بررسی می‌کنند. مجموعه توسعه‌یافته CI با ۲۵ تست، صفر شکست و صفر Skip در اجرای [45465421133](https://github.com/tecpey/lottorito-platform/actions/runs/45465421133) روی Head کد `f4e8551c2297b9a4fd0771f66c3f9e7a91dbe7a0` موفق شد؛ اجرای Documentation Governance با شناسه [45465421155](https://github.com/tecpey/lottorito-platform/actions/runs/45465421155) نیز موفق بود. Schema نهایی Effect مالی تغییرناپذیر را از Aliasهای تغییرناپذیر Request Key جدا می‌کند، استفاده مجدد Alias برای Effect دیگر را رد می‌کند و شناسه Effect را در Transactional Outbox منتشر می‌کند. محاسبه کمیسیون، Reversal، Hold/Balance و تطبیق بیرونی هنوز پیاده‌سازی نشده‌اند.


**آزمایش‌ها:**
۱. ثبت Debit/Credit متوازن با دقت دقیق ارز؛ رد Scale نامعتبر، عدم تطابق ارز و سند نامتوازن.
۲. ارسال هم‌زمان Source Event یکسان از چند Worker؛ زمان‌بندی تراکنش و توقف Process را تغییر دهید.
۳. هویت Source Event، Economic Effect و Journal Entry را جدا کنید؛ Source Eventهای متمایز با اثر اقتصادی مشترک یا چندگانه مجاز را نیز آزمایش کنید.
۴. تلاش برای تغییر/حذف سند ثبت‌شده؛ الزام Reverse/Adjustment مرتبط را اثبات کنید.
۵. Pending/Available/Held را از دفترکل و Holdها مشتق کنید؛ صورت‌حساب را مستقل مقایسه کنید.
۶. شکست جزئی پیش از Commit، پس از Commit و پیش از Acknowledgement و هنگام انتشار Downstream را شبیه‌سازی کنید.
۷. مجموع منبع، خروجی محاسبه، دفترکل و موجودی مشتق‌شده را تطبیق دهید.

**معیار Pass:**
- هر سند ثبت‌شده به تفکیک ارز متوازن و تغییرناپذیر باشد.
- Economic Effect با Identity یکسان در تحویل هم‌زمان یا Replay دوباره ثبت نشود.
- Posting تأییدشده از Failureهای آزمایش‌شده جان سالم به‌در ببرد؛ Retry همان نتیجه قبلی را بازگرداند، نه اثر جدید.
- Reverse/Adjustment زنجیره ردیابی را حفظ کند و تاریخچه را بازنویسی نکند.
- مالکیت Tenant/Product/Account اعمال شود؛ هیچ تجمیع ضمنی بین Tenant یا Product وجود نداشته باشد.
- تطبیق مستقل مغایرت‌های تزریق‌شده را کشف کند.

**شواهد:** Trace تراکنش، Fixture دفترکل، خروجی تست هم‌زمانی/Replay، بررسی Invariant، گزارش تطبیق و مستند رفتار Isolation/Locking.

### P-03 — خرابی Provider و تحویل رویداد

**پرسش:** آیا پلتفرم می‌تواند رویدادهای At-least-once، تأخیردار، با ترتیب متفاوت و ناقص را بدون فقدان بی‌صدا یا اثر اقتصادی تکراری تحمل کند؟

**حداقل Fixture:** شبیه‌ساز محلی Provider با Latency، Timeout، Rate Limit، Callback تکراری، تحویل خارج از ترتیب، Signature نامعتبر، نسخه‌های Schema، پاسخ ناقص و مغایرت تسویه قابل تنظیم.

**آزمایش‌ها:**
۱. رویداد معتبر، تکراری، تأخیردار و خارج از ترتیب را از مرز Adapter تحویل دهید.
۲. Process را بین دریافت رویداد، ثبت پایدار Inbox، پردازش دامنه و Acknowledgement متوقف کنید.
۳. بین تراکنش دامنه و انتشار Outbox شکست ایجاد و Dispatcher را Retry کنید.
۴. قطعی Provider، Rate Limit، Payload خراب و Schema Drift را شبیه‌سازی کنید.
۵. Retry محدود، Backoff، Circuit Breaker، Dead Letter و Replay کنترل‌شده را آزمایش کنید.
۶. Statement/Result ارائه‌دهنده را با Event و سوابق مالی داخلی مقایسه و مغایرت تزریق کنید.

**معیار Pass:**
- Acknowledgement فقط پس از پذیرش پایدار رویداد مطابق قرارداد انجام شود.
- تحویل تکراری اثر اقتصادی تکراری ایجاد نکند.
- رویداد غیرقابل‌پردازش قابل مشاهده و بازیابی باشد؛ Drop بی‌صدا وجود نداشته باشد.
- Retry و Replay محدود، قابل مشاهده و ایمن باشند؛ Poison Message مانع پردازش Tenantهای دیگر نشود.
- ترجمه اختصاصی Provider داخل Adapter بماند و Event canonical منشأ خود را حفظ کند.
- تطبیق، رکوردهای مفقود، تکراری، دیررس و نامنطبق را شناسایی کند.

**شواهد:** تنظیمات Simulator، Timeline تحویل، سوابق Inbox/Outbox، تاریخچه Retry/Dead Letter، استثناهای تطبیق و پیش‌نویس Runbook بازیابی.

### P-04 — تکامل Schema و سازگاری

**پرسش:** آیا ساختار داده می‌تواند تغییر کند، در حالی که نسخه‌های پشتیبانی‌شده برنامه و Worker هم‌زمان کار می‌کنند و داده از دست نمی‌رود یا قفل ناایمن طولانی ایجاد نمی‌شود؟

**حداقل Fixture:** دیتابیس ساختگی با داده نماینده Tenant، Event، Ledger و Reporting؛ دو نسخه برنامه و دو نسخه Worker.

**آزمایش‌ها:**
۱. تغییر Expand/Migrate/Contract را در حالی اجرا کنید که نسخه قدیم و جدید هم‌زمان فعال‌اند.
۲. Backfill را به Batchهای قابل ادامه اجرا کنید؛ آن را متوقف و دوباره ادامه دهید.
۳. Reader و Writer قدیم/جدید را روی Schema انتقالی آزمایش کنید.
۴. ساخت Index/Constraint، مدت Lock و شکست Migration را بررسی کنید.
۵. Forward Repair و راهبرد Rollback/Roll-forward را آزمایش کنید؛ بازگشت کد را از تبدیل داده غیرقابل‌برگشت جدا کنید.
۶. اجرای Idempotent Migration و ترتیب Deploy برای Workerها را بررسی کنید.

**معیار Pass:**
- هیچ رکورد تجاری/مالی Commitشده‌ای از دست نرود یا بی‌صدا معنای دیگری پیدا نکند.
- نسخه‌های پشتیبانی‌شده در پنجره سازگاری مستند بتوانند هم‌زیستی کنند.
- Backfill قابل ادامه، مشاهده و تکرار ایمن باشد.
- Constraintها پیش از حذف مسیر قدیمی اعمال شوند.
- بازیابی شکست مستند و آزموده باشد؛ تغییر مخرب نیازمند تأیید صریح است.
- یکپارچگی داده و مالکیت Tenant قبل و بعد Migration قبول شوند.

**شواهد:** Migration Script، Checksum/Count قبل و بعد، مشاهده Lock/Latency، ماتریس سازگاری، بازیابی اجرای متوقف‌شده و گزارش Rollback/Roll-forward.

### P-05 — پشتیبان‌گیری، بازیابی و تداوم

**پرسش:** آیا می‌توان از یک Cluster ساختگی مشابه Lottorito نسخه پشتیبان گرفت، صحت آن را بررسی کرد، تا نقطه بازیابی نام‌گذاری‌شده بازگرداند و حفظ جداسازی Tenant و Invariantهای مالی را اثبات کرد؟

**مرز تصمیم:** P-05 سه برش مستقل با پذیرش جداگانه دارد. P-05A نسخه فیزیکی پایه، پیوستگی آرشیو WAL، PITR، صحت‌سنجی Restore و تطبیق مالی ساختگی را اثبات می‌کند. P-05B جداگانه بازیابی بایت Object، کلید/تنظیمات و Replay رویداد را می‌آزماید. P-05C جداگانه Failover، Writer Fencing، جلوگیری از Split-brain و Failback را بررسی می‌کند. موفقیت P-05A به‌معنای موفقیت P-05B یا P-05C نیست.

**Fixture حداقلی:** Cluster دورریختنی PostgreSQL 18.7، دو Tenant ساختگی با هویت Login مستقل، رکورد رویداد مبدأ، Fixture اسناد مالی متوازن، Metadata ارجاع Object و نشانگر حادثه پس از Restore Point. Backup عملیاتی، وجه واقعی، Credential زنده، Secret شریک یا داده مشتری/بازیکن ممنوع است.

**آزمایش‌های P-05A:**
۱. پیش از Base Backup آرشیو WAL را فعال و با pg_basebackup نسخه فیزیکی و Manifest بسازید.
۲. pg_verifybackup را اجرا کنید؛ یک کپی از Manifest را عمداً دست‌کاری و رد شدن آن را اثبات کنید.
۳. Restore Point نام‌گذاری‌شده بسازید، داده مالی/رویداد ساختگی پس از آن Commit کنید، تعویض WAL را اجباری و آرشیو Segment لازم را تأیید کنید.
۴. Backup را در Data Directory دوم و ایزوله Restore کنید؛ restore_command، recovery.signal و Recovery Target نام‌گذاری‌شده را تنظیم کنید و پس از رسیدن به Target آن را Promote کنید.
۵. وجود داده پیش از Target و نبود داده پس از Target را اثبات و Log و زمان Restore را ثبت کنید.
۶. توازن Journal، مجموع کنترلی Source Event تا Ledger، یکتایی Economic Effect و سلامت Metadata ارجاع Object را دوباره محاسبه کنید.
۷. با Login دیتابیس مستقل هر Tenant متصل شوید و ثابت کنید RLS پس از Restore نیز مانع خواندن بین Tenantها می‌شود.
۸. خرابی WAL مفقود، Manifest نامعتبر، Restore قطع‌شده و آرشیو غیرقابل‌دسترس را ثبت کنید؛ هیچ سناریویی بی‌صدا Skip نشود.

**معیار پذیرش P-05A:** موفقیت Base Backup و pg_verifybackup؛ رد کپی خراب‌شده؛ مرز دقیق PITR؛ راه‌اندازی Cluster بازیابی‌شده و پذیرش اتصال احرازشده؛ صفر Journal نامتوازن، Economic Effect تکراری، اختلاف توضیح‌نداده‌شده Source-to-Ledger یا ارجاع ساختگی خراب به Object؛ صفر مشاهده بین Tenantها؛ بررسی صریح پیوستگی WAL؛ ثبت نسخه‌ها، زمان‌ها، فرمان‌ها و شواهد CI.

**P-05B (خارج از این برش):** بازیابی Payload از شبیه‌ساز ایزوله Object Storage؛ بررسی Content Hash؛ بازیابی Key/Envelope ساختگی با سلسله‌مراتب مستقل و صرفاً آزمایشی؛ Replay رویداد با Idempotency مربوط به Inbox/Economic Effect و تطبیق منبع/Provider. وجود ردیف ارجاع Object در دیتابیس اثبات بازیابی بایت‌های فایل نیست. کلید Production هرگز در Backup دیتابیس یا Fixture مربوط به CI قرار نگیرد.

**P-05C (خارج از این برش):** انشعاب Timeline بین Primary/Standby ساختگی، Promotion، Writer Fencing مبتنی بر Epoch، رد نوشتن Primary قدیمی، اتصال مجدد آگاه از Timeline و Failback. pg_rewind فقط ابزار نامزد است؛ دسترسی WAL، پیش‌نیاز Checksum یا wal_log_hints، Shutdown تمیز، Replay WAL پس از Rewind و مسیر جایگزین شکست باید آزمون شوند. شکست Rewind ممکن است مقصد را غیرقابل‌استفاده کند و به Base Backup تازه نیاز داشته باشد.

**مرجع RPO/RTO:** اهداف عددی در LOT-QA-001 همچنان TBD هستند و به تأیید مالک/متخصص دامنه نیاز دارند. RPO، RTO و نرخ Restore مشاهده‌شده را گزارش کنید، بدون ادعای انطباق با هدف مصوب. مثال‌های Provider ابری تعهد Lottorito نیستند.

**شواهد:** Manifest و خروجی صحت‌سنجی Backup، نتیجه تست منفی دست‌کاری، فهرست WAL آرشیوشده، LSN/Timeline نقطه بازیابی، Log و زمان Restore، Assertions قبل/بعد از Target، نتایج جداسازی Tenant، گزارش Ledger/Reconciliation، نسخه دقیق نرم‌افزار، Runbook و محدودیت‌ها.

**وضعیت:** مسیر مثبت PITR و آزمون‌های منفی بازیابی P-05A در CI ساختگی ترکیبی روی Head کد اجرایی `146a9bc635e3b03db568c423fb0958b62bc31c7b` موفق شدند. Integration با شناسه [45532825694](https://github.com/tecpey/lottorito-platform/actions/runs/45532825694) و Documentation Governance با شناسه [45532825916](https://github.com/tecpey/lottorito-platform/actions/runs/45532825916) روی همان Head موفق بودند. PostgreSQL 18.7 استفاده شد. مسیر مثبت پیش از Assertionهای نوشتنی صریحاً منتظر `pg_is_in_recovery() = false` ماند؛ Ready شدن توسط `pg_ctl` به‌تنهایی پایان Recovery محسوب نشد. مسیر منفی، Staging ناقص Restore را با `pg_verifybackup` و راه‌اندازی سرور رد کرد و Segment دقیق WAL هدف را از کپی‌های ایزوله حذف کرد؛ راه‌اندازی Recovery پیش از Target درخواستی Fail-closed شد و Segment مفقود در Log شناسایی شد. بازیابی بایت Object/کلید و Replay مرتب و Idempotent در P-05B نیز در همان Job موفق شدند. Failover/Fencing/Failback در P-05C هنوز اجرا نشده است. این نتیجه آمادگی Production، تعهد RPO/RTO یا تصویب فناوری نیست.


### P-05B — بازیابی Object، کلید و رویداد

**پرسش:** پس از بازیابی دیتابیس در P-05A، آیا پلتفرم می‌تواند بایت‌های دقیق Object و مواد مستقل کلید لازم برای رمزگشایی را بازیابی کند و سپس رویدادهای Pending را بدون فقدان یا تکرار اثر اقتصادی Replay کند؟

**Fixture ساختگی:** یک Object باینری متعلق به Tenant A، مرجع SHA-256 ثبت‌شده در دیتابیس بازیابی‌شده، Payload رمز‌شده با AES-256-GCM و DEK تصادفی، DEK بسته‌بندی‌شده مستقل و KEK بازیابی ساختگی در مجموعه Backup جداگانه؛ Inbox محدود به Tenant، Cursor توالی Aggregate و دو Source Event ساختگی مستقل. بدون Cloud، KMS/HSM زنده، Broker، Provider، Secret Production یا داده واقعی.

**آزمایش‌ها:**
۱. کل Payload را با AES-256-GCM و AAD مقید به Tenant/Object/Version رمز کنید؛ DEK را با KEK مستقل و AAD مقید به هویت Key/Object Wrap کنید.
۲. بایت Object/Manifest/Envelope و مواد بازیابی کلید ساختگی را مستقل Backup کنید؛ نسخه فعال را حذف کنید؛ هر دو مجموعه را Restore و تعداد بایت و SHA-256 کامل Plaintext را با مرجع قابل اعتماد PostgreSQL مقایسه کنید.
۳. خطای نبود کلید، Ciphertext تغییرکرده و DEK بسته‌بندی‌شده تغییرکرده تزریق کنید؛ همه مسیرها باید Fail-closed باشند. نبود Plaintext در Backup مربوط به Object را بررسی کنید.
۴. ابتدا Sequence شماره ۲ را تحویل دهید، سپس ۱، Sequence شماره ۲ را تکرار و Event ID متفاوت با Economic Effect ID تکراری ارسال کنید. شکاف Sequence باید Cursor را متوقف و هویت‌های تکراری باید ادغام شوند.
۵. پیش از Commit تراکنش و پس از نوشتن‌های تابع Replay خطا تزریق کنید؛ Rollback کامل Journal، Line، وضعیت Inbox و Cursor را اثبات کنید. Retry باید دقیقاً یک Journal متوازن برای هر Effect، Cursor صحیح، تطبیق Source-to-Ledger و Replay بعدی بدون اثر داشته باشد.
۶. ثابت کنید Tenant B نمی‌تواند Metadata مربوط به Object/Inbox متعلق به Tenant A را بخواند و نمی‌تواند ردیف Inbox بین Tenantها بنویسد.

**معیار Pass:** تطبیق دقیق بایت/Hash Object؛ رد کلید یا Object خراب/مفقود؛ اعمال جداسازی Tenant؛ Deduplication شناسه Event و Economic Effect؛ جلوگیری از عبور از شکاف Sequence؛ Rollback کامل Replay قطع‌شده؛ Retry با دقیقاً دو اثر و بدون Duplicate؛ توازن Journal؛ تطبیق مجموع Source و Ledger؛ و No-op بودن Replay دوم.

**محدودیت Custody کلید:** فایل خام KEK صرفاً مواد بازیابی ساختگی CI است. این فایل طراحی Production برای KMS/HSM، توصیه به Export کلید ریشه، Split-Knowledge، مراسم کلید یا مدل مجوزدهی نیست. AES-GCM Primitive آزمایشی است، نه استاندارد منتخب پلتفرم.

**اثبات‌نشده:** قطعی/Rotation/Revocation/Compromise در KMS/HSM، IAM و کنترل دوگانه، نگهداری Immutable/Versioned Object، Legal Hold، فایل بزرگ/Multipart، Replication منطقه‌ای، دوام Broker خارجی، تطبیق Provider، Saga بین سرویس‌ها، هم‌زمانی بالا، Throughput Production، RPO/RTO یا انطباق. آزمون‌های منفی WAL مفقود و Staging ناقص Restore در P-05A فقط در Fixture ساختگی CI موفق شده‌اند؛ Orchestration بازیابی Production و کنترل پذیرش نتیجه بازیابی هنوز اثبات نشده‌اند. مسیر مثبت اکنون بررسی‌های نوشتنی را به `pg_is_in_recovery() = false` مشروط می‌کند. Failover/Fencing/Failback در P-05C مستقل است.

**منابع:** صحت Checksum در AWS S3؛ اعتبارسنجی داده و Versioning در Google Cloud Storage؛ NIST SP 800-57 Part 1 Rev. 5 (Rev. 6 هنوز پیش‌نویس است)؛ راهنمای Transactional Outbox و تحویل At-least-once در AWS.

**وضعیت:** CI ساختگی P-05B روی Head اعتبارسنجی‌شده شاخه با شناسه e4820884194ecf1ab3acd539d77145904f14ab73 موفق شد. اجرای Integration ترکیبی P-05A/P-05B در Pull Request با شناسه [45526975173](https://github.com/tecpey/lottorito-platform/actions/runs/45526975173) و Documentation Governance با شناسه [45526975222](https://github.com/tecpey/lottorito-platform/actions/runs/45526975222) موفق شدند. Object بازیابی‌شده ۴٬۴۰۹ بایتی با مرجع SHA-256 دیتابیس تطبیق داشت؛ حالت‌های کلید/Object مفقود یا خراب Fail-closed شدند؛ Assertionهای Duplicate/ترتیب Replay، قطع تراکنش و Retry، تطبیق Ledger و جداسازی Tenant موفق شدند. هیچ فناوری، فروشنده، آمادگی Production، RPO/RTO یا مجوز انتشار تصویب نشده است.

### P-05C — Failover، Writer Fencing و Failback

**پرسش:** آیا Prototype بازیابی می‌تواند Promotion کنترل‌شده Primary به Standby را نشان دهد، Writer قدیمی را رد کند، فقط یک گره Writable نگه دارد، Primary قبلی را Rewind کند و Failback کنترل‌شده را کامل سازد؟

**توپولوژی ساختگی:** دو Cluster مستقل PostgreSQL 18.7 در یک Container دورریختنی؛ Physical Streaming Replication؛ Data Checksum و wal_log_hints؛ یک ردیف محلی Writer Epoch/Lease؛ بدون DCS خارجی، Cluster اجماع، Watchdog، Cloud Instance یا زیرساخت Production.

**آزمایش‌ها:**
۱. یک Event پایه Seed و Streaming Standby اثبات شود.
۲. Gate محلی Promotion تا زمانی که فرایند Primary قبلی فعال است، Promotion را رد کند. Standby متوقف شود، یک Tail ساختگی و عمداً Replicateنشده روی Primary قدیمی Commit و سپس Primary قدیمی پیش از Promotion متوقف شود.
۳. Standby راه‌اندازی و Promote شود؛ Epoch از ۱ به ۲ افزایش یابد. هویت/Epoch مربوط به Writer قدیمی و Lease منقضی‌شده Fail-closed شوند.
۴. دو Promotion Claimant با Expected Epoch شماره ۲ رقابت کنند؛ دقیقاً یک Compare-and-Swap اتمیک باید برنده Epoch شماره ۳ شود و دیگری هیچ Token دریافت نکند.
۵. Primary قبلی متوقف‌شده با pg_rewind Rewind و به‌عنوان Standby فقط‌خواندنی دوباره Join شود؛ Event مربوط به Primary ارتقایافته حاضر و Tail قدیمیِ عمداً Replicateنشده غایب باشد.
۶. پس از Replay، Switchover کنترل‌شده به Node اولیه انجام شود، Epoch از ۳ به ۴ برسد، Marker مربوط به Failback نوشته شود، گره دیگر Rewind و به‌عنوان Standby Join شود.
۷. پس از Failback، دقیقاً یک Primary قابل نوشتن، یک Standby فقط‌خواندنی و وضعیت سازگار Epoch/Active Writer اثبات شود.

**معیار Pass:** رد Promotion تا زمان فعال بودن Primary قدیمی؛ توقف فرایند قدیمی پیش از Promotion؛ موفقیت Promotion Standby؛ رد Token قدیمی و Lease منقضی؛ برنده شدن دقیقاً یک Claimant هم‌زمان Epoch؛ موفقیت Rewind و Join؛ غیبت Tail واگرای Replicateنشده؛ Read-only بودن Primary قبلی پس از Join؛ موفقیت Failback کنترل‌شده و Rewind دوم؛ و دقیقاً یک Writer در توپولوژی نهایی.

**محدودیت‌های حیاتی:** توقف فرایند فقط شبیه‌سازی Local CI برای Fence است، نه STONITH، Fencing میزبان/Storage یا Watchdog. ردیف Writer Epoch داده برنامه‌ای Replicateشده است، نه DCS مستقل با Quorum؛ نمی‌تواند جلوی Primary قدیمیِ جداافتاده از شبکه را برای پذیرش نوشتن محلی بگیرد. آزمایش عمداً یک Event ساختگی Commitشده اما Replicateنشده را از دست می‌دهد تا پنجره فقدان داده در Replication غیرهم‌زمان آشکار شود. Network Partition واقعی، از دست‌رفتن Quorum، Primaryهای زنده هم‌زمان، قطعی DCS، خرابی Watchdog، Failover منطقه‌ای، ترافیک Production، RPO یا RTO آزموده نمی‌شوند.

**منابع:** Failover، Hot Standby و pg_rewind در PostgreSQL 18؛ راهنمای Lease/Watchdog در Patroni؛ تراکنش اتمیک، Lease و Linearizability در etcd.

**وضعیت:** پیاده‌سازی در PR شماره ۵۴ مربوط به P-05C قرار دارد و روی PR شماره ۵۳ مربوط به P-05B Stacked شده است. اعتبارسنجی CI در انتظار است. هیچ فناوری HA، فروشنده، توپولوژی، RPO/RTO یا آمادگی Production تصویب نشده است.

### P-06 — Observability سرتاسری و حریم خصوصی

**پرسش:** آیا اپراتور می‌تواند یک رویداد ساختگی شریک را از Ingress تا Attribution، تصمیم کمیسیون و ارجاع Journal ردیابی کند، در حالی که Secret و داده شخصی/مالی غیرضروری وارد Telemetry نشود؟

**حداقل Fixture:** هویت Tenant و Event ساختگی، Credential تولیدشده، داده شخصی Fake و Secret Canary کنترل‌شده.

**آزمایش‌ها:**
۱. Event را از Ingress، Validation، Inbox، پردازش دامنه، Outbox، Worker تا ارجاع Ledger Trace کنید.
۲. Request، Actor، Tenant، Product، Source Event، Economic Effect و Journal Entry را مرتبط کنید.
۳. Log، Trace، Metric، Exception، Dashboard و Alert Payload را برای Secret Canary و فیلد حساس بررسی کنید.
۴. شناسه‌های پرکاردینالیتی و Labelهای Tenant/Customer را در Metric آزمایش کنید.
۵. Authorization Denial، قطعی Provider، Backlog صف، مغایرت Reconciliation و نقض Ledger Invariant ایجاد کنید.
۶. رویدادهای Audit ممتاز و دسترسی به Telemetry را بررسی کنید.

**معیار Pass:**
- مسیر حیاتی از Telemetry مجاز بازسازی شود، بدون اینکه Log به‌عنوان Ledger تلقی شود.
- Correlation در مرزهای هم‌زمان و غیرهمزمان سازگار باشد.
- Secret Canary و فیلدهای ممنوع در Telemetry ظاهر نشوند.
- Metricها از Cardinality نامحدود Tenant/Customer پرهیز کنند؛ شناسه‌های تفصیلی کنترل دسترسی داشته باشند.
- Alert دارای مالک، شدت، Runbook قابل اقدام و نویز کنترل‌شده باشد.
- دسترسی Telemetry و اقدامات ممتاز قابل ممیزی باشند.

**شواهد:** Trace پالایش‌شده، فهرست Metric/Label، Policy فیلد Log، اسکن Secret Canary، نگاشت Alert/Runbook و Audit دسترسی.

### P-07 — ترکیب مستقل محصولات

**پرسش:** آیا Affiliate & Agent و Lottery می‌توانند مستقل Build، پیکربندی، Deploy و Operate شوند و فقط قابلیت‌های مشترک با مالکیت صریح را به اشتراک بگذارند؟

**حداقل Fixture:** پیکربندی ساختگی محصولات، Entitlementهای مستقل Tenant/Product، Domain Event و Adapterهای Mock؛ بدون Provider زنده Lottery یا شریک واقعی.

**آزمایش‌ها:**
۱. ترکیب Affiliate-only را بدون وابستگی Runtime به Lottery Build و اجرا کنید.
۲. ترکیب Lottery-only را بدون وابستگی Runtime به Affiliate Build و اجرا کنید.
۳. یک محصول را غیرفعال و حفظ مسیرهای حیاتی اعلام‌شده محصول دیگر را بررسی کنید.
۴. Identity، Tenant، Finance، Notification و Audit را به‌عنوان قابلیت مشترک با مالکیت و مرز مجوزدهی صریح آزمایش کنید.
۵. دسترسی داده و مصرف Event بین دو محصول را بدون قرارداد/Entitlement صریح امتحان کنید.
۶. Migration، Configuration، Artifact استقرار و عملیات پشتیبانی را از نظر Coupling ناخواسته مقایسه کنید.

**معیار Pass:**
- مسیر اصلی اعلام‌شده هر محصول بدون نصب یا فعال‌سازی محصول دیگر کار کند.
- قابلیت مشترک Interface، مالکیت، Permission و Lifecycle صریح داشته باشد.
- دسترسی بین‌محصولی به‌صورت پیش‌فرض رد و فقط با قرارداد صریح فعال شود.
- Migration/Configuration هر محصول به فعال‌سازی محصول نامرتبط وابسته نباشد.
- غیرفعال‌کردن یک محصول داده یا عملیات محصول دیگر را خراب نکند.
- White-label هویت مالکیت Lottorito، Audit و ردیابی فنی را حذف نکند.

**شواهد:** گزارش Build/Run جداگانه، Dependency Graph، ماتریس Configuration، تست منفی مجوزدهی، فهرست Migration و چک‌لیست عملیات مستقل.

### P-08 — استقرار، Health Gate و Rollback

**پرسش:** آیا Artifact تغییرناپذیر با تزریق کنترل‌شده Secret، بررسی سلامت و مسیر Rollback/Roll-forward آزموده‌شده به‌صورت ایمن ارتقا می‌یابد؟

**حداقل Fixture:** محیط‌های غیرProduction، داده ساختگی، Secret تولیدشده، Artifact Build تغییرناپذیر و حداقل دو نسخه برنامه.

**آزمایش‌ها:**
۱. یک‌بار Build و همان Artifact Digest را در محیط‌های Test و Stagingمانند ارتقا دهید.
۲. Secret را در Runtime تزریق و Artifact، Log و Metadata Build را از نظر افشا اسکن کنید.
۳. Readiness/Liveness و Health وابستگی‌ها را پیش از فعال‌سازی Traffic یا Worker آزمایش کنید.
۴. Rollout ناموفق، Worker ناسالم، Migration ناسازگار و Deploy جزئی را شبیه‌سازی کنید.
۵. کد برنامه را با حفظ سازگاری داده Rollback و در صورت ناایمن‌بودن Rollback، Forward Repair را آزمایش کنید.
۶. Audit استقرار، Approval، منشأ Artifact و تفکیک وظایف را بررسی کنید.

**معیار Pass:**
- Artifact ارتقایافته تغییرناپذیر و Digest آن قابل ردیابی باشد.
- هیچ Credential در Source، Artifact، Image Metadata، Log یا خروجی تست ظاهر نشود.
- در صورت شکست Health Gate حیاتی، فعال‌سازی Traffic/Worker متوقف شود.
- رویه Rollback/Forward آزموده شود و وضعیت مالی یا Tenant را خراب نکند.
- Deploy قابل انتساب و ممیزی باشد؛ ارتقای Production همچنان نیازمند تأیید است.
- هیچ Exposure عمومی یا Deploy عملیاتی بخشی از این آزمایش نباشد.

**شواهد:** Artifact Digest، Manifest استقرار، Secret Scan، Timeline Health Check، Transcript شکست/Rollback، Audit و Runbook اپراتور.

## ۵. قواعد پذیرش مشترک Prototypeها

تمام Prototypeها باید:
- از داده ساختگی ایزوله و Credential غیرProduction استفاده کنند.
- مسیر مورد انتظار و مسیر خصمانه/خرابی را آزمایش کنند.
- فرمان قابل تکرار، تنظیمات و نسخه دقیق نرم‌افزار را ثبت کنند.
- حداقل یک تست منفی برای مجوزدهی، یکپارچگی یا شکست ایمن داشته باشند.
- محدودیت و مرزهای آزمون‌نشده را صریح گزارش کنند.
- نتیجه Prototype را بدون به‌روزرسانی ADR به تصمیم مالک تبدیل نکنند.

Prototype فقط زمانی **Pass** است که تمام معیارهای اجباری محدوده اعلام‌شده قبول شوند. موفقیت جزئی **Inconclusive** یا **Fail** است، نه «تقریباً آماده Production». هر استثنا به مالک پاسخ‌گو، کنترل جبرانی، تاریخ انقضا و تصمیم ثبت‌شده نیاز دارد.

## ۶. ترتیب اجرا و وابستگی‌ها

۱. P-01 جداسازی Tenant: پیش از مسیرهای داده مشترک، فرض‌های Context و Isolation تثبیت شود.
۲. P-02 تراکنش مالی: ناورداهای Posting و Idempotency Identity مشخص شود.
۳. P-03 تحویل Event/خرابی Provider: بر مبنای ناورداهای Event و Finance ساخته شود.
۴. P-04 تکامل Schema: ساختارهای نماینده دامنه، Event و Ledger آزمایش شوند.
۵. P-05 بازیابی: زیرساخت Stateful بازیابی و تطبیق شود.
۶. P-06 Observability/Privacy: مسیر حیاتی و سناریوهای خرابی Instrument و بررسی شوند.
۷. P-07 استقلال محصولات: استقلال Bounded Context و Packaging تأیید شود.
۸. P-08 استقرار/Rollback: معماری کاندید به‌صورت ایمن ارتقا و بازیابی شود.

در صورت نیاز وابستگی‌ها، ترتیب قابل تنظیم است؛ اما هر هشت Prototype الزامی می‌مانند مگر اینکه مالک معافیت صریح ثبت کند.

## ۷. قالب گزارش آزمایش

برای هر P-0x موارد زیر ثبت شود:
- تصمیم و مالک پاسخ‌گو:
- فرضیه و گزینه‌ها:
- Candidate/Version/Configuration:
- محیط و توپولوژی:
- پروفایل داده ساختگی:
- شناسه سناریوها در LOT-QA-001:
- فرمان‌ها و رویه اجرا:
- نتیجه مورد انتظار و آستانه توافق‌شده:
- نتیجه واقعی و لینک شواهد خام:
- Pass / Fail / Inconclusive / Not run:
- حالت‌های خرابی و محدودیت‌ها:
- هزینه و بار عملیاتی:
- اثر امنیت/حریم خصوصی/حقوقی:
- پیشنهاد و سطح اطمینان:
- تصمیم موردنیاز / به‌روزرسانی ADR:
- بازبین، تاریخ و انقضای استثنا:

## ۸. دروازه تکمیل

مرحله Prototype فقط زمانی تکمیل است که هر هشت آزمایش گزارش تکرارپذیر داشته باشند، ناورداهای اجباری قبول شده یا استثنای صریح مورد تأیید مالک داشته باشند، ریسک و Trade-off ثبت شده باشد و ADRهای فناوری مرتبط با شواهد به‌روزرسانی شوند. این امر به‌تنهایی Stack، آمادگی Production، فعال‌سازی بازار، Merge یا Deploy را تصویب نمی‌کند.

## ۹. اسناد مرتبط

- LOT-QA-001 — ویژگی‌های کیفی معماری و دروازه انتشار.
- LOT-TECH-ADR-001 — چارچوب تصمیم فناوری، استقرار و قابلیت اطمینان.
- LOT-TEN-001 — مدل جداسازی Tenant.
- LOT-FIN-POST-001 — ثبت مالی و تطبیق.
- LOT-SEC-TM-001 — مدل تهدید.
- LOT-EVENT-001 — قرارداد رویداد canonical.
- LOT-OPS-001 — وضعیت تأییدشده پروژه.

**یادآوری وضعیت:** برنامه آزمایش همچنان پیشنهادی است. برش محدود P-01 برای HTTP/PostgreSQL RLS در PR شماره ۳۶، در اجرای CI با شناسه [45412556456](https://github.com/tecpey/lottorito-platform/actions/runs/45412556456) هر ۲۰ تست تعریف‌شده را با موفقیت و با Lockfile ثبت‌شده و GitHub Actions دارای SHA ثابت روی Head کد `f53caa4e801c9eeed94dfe706e03c6dfcf02a660` گذرانده است. این برش Jobهای Async Tenant-scoped، Outbox/Dispatch اتمیک، Claim هم‌زمان Dispatcher، Envelopeهای امضاشده Ed25519، بررسی مجدد Membership در Worker و مدل مقایسه‌ای LOGIN Role مستقل مبتنی بر `session_user` را در Records، Membership و Jobs پوشش می‌دهد و مالک SECURITY DEFINER، search_path ثابت و Shadowing در Temporary Schema را نیز آزمایش می‌کند؛ همچنین یک تست دو اتصالی اثبات می‌کند لغو Membership پشت تراکنش در حال اجرای `FOR SHARE` منتظر می‌ماند. این نتیجه به معنای قبولی کل P-01 نیست: Credential Broker امن، مقیاس Poolها، Cache/Object Storage/Search/Reporting، Support/Break-glass، بار و Recovery هنوز آزمایش نشده‌اند. محدودیت اعتماد GUC با Role مشترک نیز به‌صورت صریح نمایش داده شده است. هیچ تصویب فناوری ادعا نمی‌شود.


**وضعیت آزمایش P-04 (۲۰۲۶-۱۱-۲۴):** PR شماره ۵۱ در وضعیت Draft روی شاخه spike/p04-schema-evolution و بر مبنای Head مربوط به P-03 یعنی 45b37700cb2b9ad633158ba8d5f00b8c7f0553d5 ایجاد شده است. Candidate ساختگی PostgreSQL، سازگاری Writerهای v1/v2، Expand افزایشی، Backfill قابل ادامه و محدود به Tenant، Idempotency/Checksum Migration، شکست Lock Timeout، بازیابی Index Concurrent نامعتبر، اعتبارسنجی مرحله‌ای Constraint و تمرین غیرمخرب Contract را پوشش می‌دهد. Integration با شناسه 45471750215 روی Head کد 15c536e5be2f61b1805191f5977a46b17eaf1971 تعداد ۷ تست موفق داشته و Documentation Governance با شناسه 45471750133 روی همان Head موفق شده است. این همچنان آزمایش ساختگی است؛ هیچ Migration عملیاتی، ادعای Zero Downtime یا تصویب فناوری مطرح نیست.
