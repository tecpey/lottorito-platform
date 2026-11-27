# وضعیت واقعی پروژه و نقطه ادامه کار

**شناسه:** LOT-OPS-001 | **نسخه:** ۲.۰.۰ | **وضعیت:** خط مبنای تأییدشده و در حال نگهداری | **بازبینی:** ۲۰۲۶-۱۱-۲۷

## وضعیت تأییدشده مخزن
- مخزن tecpey/lottorito-platform؛ شاخه پیش‌فرض main؛ سطح دسترسی Public طبق تصمیم مالک.
- در تاریخ ۲۰۲۶-۱۱-۲۴، PRهای ۱۹ تا ۲۵ و ۲۷ تا ۳۴ به‌صورت تغییرات مستنداتی Open/Draft هستند. زنجیره موردنظر چنین است: ۱۹ ← ۲۰ ← ۲۱ ← ۲۲ ← ۲۳ ← ۲۴ ← ۲۵ ← ۲۷ ← ۲۸ ← ۲۹ ← ۳۰ ← ۳۱ ← ۳۲ ← ۳۳ ← ۳۴. PR شماره ۲۶ یک شاخه مستقل Open/Draft بر مبنای main است و با فایل‌های حاکمیتی مشترک هم‌پوشانی دارد؛ پیش از ادغام باید با زنجیره اصلی تطبیق داده شود. هیچ‌یک از PRهای این زنجیره Merge نشده‌اند.
- PR شماره ۲۵ شش Commit از آخرین Head مربوط به PR شماره ۲۴ عقب است؛ PRهای ۲۷ تا ۳۴ این ancestry قدیمی را به ارث می‌برند. PR شماره ۲۸ پیشنهادهای B2B2C، IAM و داشبورد، PR شماره ۲۹ LOT-WALLET-001، PR شماره ۳۰ LOT-PAYMENT-001، PR شماره ۳۱ LOT-PAYOUT-001، PR شماره ۳۲ LOT-B2C-PRD-001 و PR شماره ۳۳ LOT-API-PLATFORM-001 را بر مبنای زنجیره قبلی اضافه می‌کنند؛ PR شماره ۳۴ LOT-AFFILIATE-API-001 را بر مبنای #۳۳ اضافه می‌کند. پیش از بررسی Merge، زنجیره بالادستی باید همگام و CI دوباره اجرا شود. این Snapshot تاریخ‌دار است؛ Metadata زنده PR مرجع نهایی است.
- کار مخزن همچنان مستندات‌محور است. برنامه اجرایی، Schema فیزیکی، اتصال Provider، Sandbox، ثبت مالی، پرداخت یا Deploy عملیاتی تأیید نشده است.
- فایل scripts/check_docs.py و Workflow با مسیر .github/workflows/docs-governance.yml برای کنترل ساختاری جفت فایل‌های دوزبانه/شناسه‌ها، عنوان سطح اول، Metadata نسخه/وضعیت و لینک‌های محلی اضافه شده‌اند. اجرای اول تفاوت معتبر پسوند EN/FA در شناسه دو فهرست را آشکار کرد؛ نرمال‌سازی اضافه شد و Workflow حاکمیت مستندات روی Head شماره 78e47168e67b14ccc2be9df7ceae79fbf56eb59e با موفقیت گذشت (Run شماره 45345429559). این نتیجه فقط ساختار و لینک‌های محلی را اعتبارسنجی می‌کند، نه هم‌ارزی معنایی ترجمه.
- Workflow حاکمیت مستندات روی Head شماره 71b527be77f8df03cb179c378a020c58716c4e7c موفق شده است (Run شماره 45347911477): تعداد ۲۱ جفت Markdown و ۴۷ لینک محلی، همراه با کنترل عنوان و Metadata نسخه/وضعیت، بررسی شدند. این اعتبارسنجی ساختاری است؛ هم‌ارزی معنایی فارسی و انگلیسی همچنان به بازبینی انسانی نیاز دارد.

## خط مبنای مستندات
شاخه docs/agent-ready-foundation-v1 مراجع دوزبانه پیشنهادی زیر را دارد:
- LOT-AGENT-001: راهنمای عملیاتی کم‌Context برای ایجنت‌ها.
- LOT-ADR-REG-001: دفتر مرجع اختیار تصمیم و تصمیم‌های حل‌نشده.
- LOT-LOTTERY-001 و LOT-LOTINT-001: PRD کشف Lottery و قرارداد چرخه عمر مستقل از Provider.
- LOT-DOM-001، LOT-TEN-001 و LOT-EVENT-001: مدل دامنه، جداسازی Tenant و قرارداد رویداد canonical.
- LOT-FIN-POST-001: ثبت مالی، مالکیت حساب، معنای وضعیت‌های موجودی و تطبیق پیشنهادی.
- LOT-SEC-TM-001: مدل تهدید سامانه و ماتریس حداقل راستی‌آزمایی امنیت.
- LOT-API-001: قرارداد پیشنهادی Resource، مجوزدهی، خطا، Pagination، Idempotency و Webhook.
- LOT-TECH-ADR-001: چارچوب پیشنهادی تصمیم فناوری، استقرار، قابلیت اطمینان، Observability و چرخه داده؛ بدون تصویب Stack/Provider.
- LOT-QA-001: سناریوهای کیفی قابل‌اندازه‌گیری، ناورداهای سراسری، راهبرد شواهد و دروازه انتشار پیشنهادی؛ آستانه‌های عددی تعیین‌نشده‌اند.
- LOT-PROT-001: برنامه پیشنهادی هشت Prototype همراه معیار Pass/Fail و قالب شواهد؛ اجرای هیچ Prototype تأیید نشده است.
- LOT-I18N-001: هدف عرضه ۱۲زبانه به دستور مالک (فهرست ده‌زبانه پیشنهادی) با دروازه کیفیت برابر محصول/محتوا/پشتیبانی؛ پیاده‌سازی Locale تأیید نشده است.
- LOT-COMMS-001: معماری پیشنهادی Live Chat و ارتباط چندزبانه با مشتری؛ Provider/Runtime تأیید نشده است.
- LOT-GROWTH-001: گردش پیشنهادی محتوای چندزبانه، SEO/GEO/AEO و اتوماسیون کانال؛ اتصال انتشار تأیید نشده است.
- LOT-NOTIF-001: معماری پیشنهادی اعلان هوشمند تحت Policy؛ Runtime/Provider اعلان تأیید نشده است. Source اعلان TecPey به‌عنوان مرجع بررسی شد: ایجاد تحت Policy، Outbox تراکنشی، محافظت Replay و ایمنی متن Runtime الگوهای مفیدی‌اند؛ Pilot آن با محدودیت in-app، فقط fa/en، تک‌مستاجری و شمارش صرفاً تحویل‌شده برای Lottorito آماده نیست.
- LOT-PROVIDER-EVAL-001: استاندارد پیشنهادی بین‌محصولی برای ارزیابی Provider، شواهد، RFI، دروازه‌های سخت، تست کنترل‌شده و ثبت تأیید؛ هیچ Providerی با آن انتخاب یا تأیید نشده است.

اسناد مالی، امنیت، API و فناوری/استقرار پیشنهادند؛ سیاست مصوب یا کنترل پیاده‌سازی‌شده نیستند. LOT-TECH-ADR-001 معماری، دیتابیس، صف/Workflow، میزبانی، Observability، بازیابی، امنیت و معیارهای Residency را مقایسه می‌کند. این سند هیچ Stack یا Vendor را تصویب نمی‌کند.

- **LOT-PLATFORM-001:** معماری پیشنهادی یکپارچه B2B2C شامل Tenant اختصاصی B2C، Operator، White-Label، Affiliate/Agent، داشبوردهای نقش‌محور، Wallet/Ledger، واریز/برداشت، Adapter پرداخت، Chat/Widget، امنیت و بسته‌های کاری؛ هیچ‌کدام به‌عنوان Runtime پیاده‌سازی‌شده تأیید نشده‌اند.

- **LOT-IAM-TENANT-001:** قرارداد پیشنهادی Tenant/هویت/Membership/مجوزدهی با ۱۷ بخش، ماتریس دسترسی نقش/Workspace، چرخه عمر، اصول جداسازی و ۱۲ سناریوی تهدید/تست؛ نه سرویس IAM یا جداسازی Tenant پیاده‌سازی‌شده.

- **LOT-DASH-001:** طرح پیشنهادی Workspaceهای نقش‌محور با ۱۲ بخش، تجربه‌های تفصیلی Platform/Tenant/White-Label/Affiliate/پشتیبانی/مالی/انطباق/B2C، حاکمیت KPI و ۱۲ تست پذیرش؛ هیچ پیاده‌سازی داشبوردی ادعا نمی‌شود.
- **LOT-WALLET-001:** قرارداد پیشنهادی دامنه Wallet شامل مالکیت/کلاس‌ها، واحدهای نوع‌دار، Projection موجودی، Hold، انتقال، مرز دفترکل، مجوزدهی و ۱۵ سناریوی تست خصمانه؛ Custody، Stored Value، پرداخت، انتقال، برداشت یا Runtime کیف پول را تصویب نمی‌کند.
- **LOT-PAYMENT-001:** قرارداد پیشنهادی ارکستراسیون پرداخت مستقل از Provider شامل Intent/Attempt، جداسازی Merchant و Tenant، Adapter، اعتماد Webhook، Idempotency، Routing، Refund، Settlement و Reconciliation؛ هیچ Provider، حساب Merchant، مجوز، Runtime پرداخت یا جریان پول واقعی تصویب نشده است.
- **LOT-PAYOUT-001:** قرارداد پیشنهادی پرداخت خروجی که برداشت مشتری، پرداخت کمیسیون Affiliate/Agent، پرداخت جایزه Lottery و حرکت خزانه را جدا می‌کند؛ Verification ذی‌نفع، Reservation، Maker-checker، اجرای Provider، نتیجه مبهم، Return و Reconciliation را پوشش می‌دهد؛ Custody، بانکداری، Runtime پرداخت خروجی یا پرداخت پول واقعی تصویب نشده است.
- **LOT-B2C-PRD-001:** نیازمندی‌های محصول پیشنهادی برای Tenant اختصاصی First-Party B2C با مصرف ماژول‌های مشترک تأییدشده از طریق قراردادهای یکسان؛ شامل گردش مشتری، Gateهای Entitlement/حوزه قضایی، Wallet، Payment، Payout، Chat، پشتیبانی، اعلان، بومی‌سازی، حریم خصوصی، دسترس‌پذیری و ۲۰ سناریوی پذیرش. هیچ Launch یا Runtime اپ B2C ادعا نمی‌شود.
- **LOT-API-PLATFORM-001:** قرارداد پیشنهادی API Platform و تجربه توسعه‌دهنده که LOT-API-001/LOT-EVENT-001 را با Control/Data Plane، ثبت App/Client، کاتالوگ Entitlement، چرخه Credential، Webhook Subscription، تولید SDK، Developer Portal، Sandbox ایزوله، Metering/Quota و حاکمیت چرخه عمر گسترش می‌دهد. هیچ Gateway، Portal، SDK، Sandbox یا دسترسی API Production ادعا نمی‌شود.
- **LOT-AFFILIATE-API-001:** فهرست قابلیت API پیشنهادی و مستقل از Provider برای Program، Membership، سلسله‌مراتب، Campaign، Referral Link، Attribution، دریافت Event شریک، Statement کمیسیون و گزارش Affiliate/Agent. تغییرات مالی در دامنه Wallet/Ledger/Payment/Payout باقی می‌مانند؛ هیچ شریک، فرمول تجاری، Endpoint یا اتصالی تصویب نشده است.
- **LOT-AFFILIATE-SEC-001:** بازبینی تهدیدمحور پیشنهادی قرارداد Wire. یافته‌های با شدت بالا/متوسط درباره BOLA، Trust توکن و جداسازی Principal انسانی/ماشینی، معنای Scope سفارشی، هویت/Fingerprint رویداد، Allowlist مربوط به Extension/Schema، SSRF، سقف منابع، حداقل‌سازی داده، خطا و Audit را ثبت می‌کند. این سند بازبینی طراحی است، نه تست نفوذ یا تأیید امنیت Production.

- **LOT-AFFILIATE-WIRE-001:** توسعه پیشنهادی در سطح Wire برای LOT-AFFILIATE-API-001 / LOT-API-001 / LOT-EVENT-001. دو قرارداد OpenAPI مستقل برای مدیریت Affiliate و ورودی رویداد شریک، به‌علاوه پروفایل رویداد Canonical مستقل از Transport اضافه شده‌اند. روی Head شماره `5877746173cbc83e715a7134426d2c086c0181b8` از PR شماره ۷۶، Documentation Governance با Run ID `46054085669` (شماره ۹۳۰) و Affiliate Contract Validation با Run ID `46054085685` (شماره ۳۲) هر دو موفق شده‌اند. اجرای دوم، هر دو سند OpenAPI با Redocly 2.83.0، سند AsyncAPI 3.0.0 با AsyncAPI CLI 6.2.2 و ۳۱ Assertion مثبت/منفی Schema با Ajv 8.17.1 و دو Instance مستقل 2020-12 و Draft 07 را اعتبارسنجی کرده است. این شواهد فقط سند و نمونه Schema را می‌سنجند، نه Runtime را. PR همچنان Draft است؛ هیچ Endpoint، Provider، نگاشت شریک، پروفایل OAuth یا Deploy عملیاتی تصویب نشده است.

## موارد تأییدنشده
هیچ پیاده‌سازی برنامه، Schema/Migration فیزیکی، اتصال API Provider، Certification سندباکس، محاسبه/ثبت مالی، پرداخت، تست نفوذ یا Deploy عملیاتی تأیید نشده است. Documentation Governance CI وجود دارد و روی برخی Headهای PR کنترل ساختاری موفق داشته است؛ این کنترل هم‌ارزی معنایی فارسی/انگلیسی، رفتار Runtime، صلاحیت قانونی یا امنیت را اثبات نمی‌کند.

## قواعد ادامه کار
۱. AGENTS.md و این سند را بخوان.
۲. نسخه فارسی و انگلیسی اسناد canonical مرتبط را بخوان.
۳. پیش از تغییر، Head جاری PR، فایل‌های تغییرکرده، ancestry شاخه، وضعیت‌ها و درخت مخزن را بررسی کن.
۴. پیش از ساخت فایل یا Issue، کار موجود را جست‌وجو کن.
۵. پیشنهاد، دستور مالک، تصمیم، پیاده‌سازی و شواهد را از هم جدا نگه دار.
۶. هر دو زبان را در یک تغییر به‌روزرسانی و لینک، شناسه، هم‌ارزی و محدوده را اعتبارسنجی کن.
۷. بدون مجوز صریح مالک Merge، Deploy، تغییر تنظیمات یا عملیات مخرب انجام نده.

## توالی بعدی
۱. بازبینی LOT-QA-001 با ذی‌نفعان محصول، مهندسی/SRE، امنیت، مالی، حقوقی/حریم خصوصی و مالک؛ تعریف پروفایل بار و تصویب آستانه فقط با تأیید مالک پاسخ‌گو.
۲. بازبینی خط مبنای مالی، مدل تهدید و API با مالک و متخصصان دامنه.
۳. بازبینی LOT-TECH-ADR-001 و LOT-PROT-001؛ تصویب محدوده آزمایش و مالکان پاسخ‌گو و سپس اجرای P-01 تا P-08 در محیط ایزوله و با داده ساختگی، پیش از پذیرش انتخاب فناوری.
۴. توسعه کنترل مستندات برای اعتبارسنجی Metadata و بازبینی انسانی هم‌ارزی معنایی؛ CI فعلی فقط جفت مسیر، شناسه و لینک محلی را بررسی می‌کند.
۵. بازبینی و تصویب سبد ۱۲زبانه و گونه‌های Locale؛ سپس تعریف پوشش بازبین بومی و دروازه‌های کیفیت.
۶. بازبینی Policyهای Live Chat، اتوماسیون محتوا/کانال و اعلان هوشمند؛ ارزیابی Provider و قراردادهای اتصال بدون فعال‌سازی کمپین.
۷. LOT-PROVIDER-EVAL-001 با مالک پاسخ‌گو و بازبینان حقوقی/انطباق، امنیت، مالی، محصول و مهندسی بازبینی و تصویب شود؛ وزن‌های پیشنهادی پیش از هر خرید الزام‌آور تأیید شوند.
۸. استاندارد ابتدا برای یک واحد تصمیم مشخص پایلوت Affiliate و یک واحد تحقیق مستقل Lottery اعمال شود؛ پیش از RFI یا تست، حوزه قضایی و مدل عملیاتی روشن شود.
۹. LOT-GAMING-STRATEGY-001 به‌عنوان افق آینده بازبینی شود؛ RFIهای Sportsbook، Live Casino و RNG/E-Gaming فقط پس از اولویت‌های Affiliate و Lottery و با دروازه‌های مستقل حوزه قضایی، Provider، مالی، امنیت و Certification اجرا شوند.
۱۰. تکمیل معماری بین‌محصولی و دروازه‌های انتشار اختصاصی هر محصول.
۱۱. جهت Wallet در LOT-WALLET-001 تفکیک شود؛ پیش از هر پیاده‌سازی، مالکیت، کلاس واحد، نگاشت حسابداری و رفتار حقوقی روشن شود.
۱۲. ارکستراسیون پرداخت (LOT-PAYMENT-001) و کنترل برداشت/پرداخت خروجی (LOT-PAYOUT-001) به‌عنوان دامنه‌های مستقل و مستقل از Provider مشخص شوند؛ Credit کیف پول، مجوز پرداخت، Settlement و Payout در یک State Machine ادغام نشوند.
۱۳. صلاحیت پرداخت هر محصول و کنترل خزانه/تأمین از طریق LOT-PAYOUT-001 مشخص شود؛ برداشت یا پرداخت خروجی پیش از تأیید حوزه قضایی، بدهی، Provider، ذی‌نفع و منبع وجه فعال نشود.
۱۴. LOT-B2C-PRD-001 با مالک/محصول/حقوقی/مالی/امنیت/حریم خصوصی/دسترس‌پذیری/عملیات بازبینی شود؛ Tenant اختصاصی، ماژول‌های واجد شرایط مرحله‌ای و گردش‌های مشتری پیش از پیاده‌سازی تصویب شوند.
۱۵. LOT-API-PLATFORM-001 با معماری/امنیت/مالی/حقوقی/عملیات بازبینی شود؛ مخاطبان API، مدل App/Credential، Sandbox، Webhook و دروازه چرخه عمر پیش از ساخت Developer Portal یا انتشار API تصویب شوند.
۱۶. LOT-AFFILIATE-API-001 با قرارداد و Sandbox واقعی شریک پایلوت تطبیق داده شود؛ Allowlist محدود Event/Resource و معنای Attribution/Commission پیش از پیاده‌سازی Adapter یا ارائه API Production تصویب شود.
۱۷. فقط پس از تصمیم‌ها، ایجاد اسکلت پلتفرم و پیاده‌سازی Vertical Sliceهای مستقل همراه تست.
۱۸. دروازه‌های LOT-AFFILIATE-SEC-001 پیش از پیاده‌سازی برنامه تکمیل شوند: تصمیم درباره Trust احراز هویت و Enforcement مربوط به Scope، Parse سخت‌گیرانه JSON و Fingerprinting، Allowlist رویداد/Schema ثبت‌شده، سقف منابع، Retention و Audit. تست‌های Cross-tenant، Scope، Duplicate هم‌زمان، Conflict و مرزهای سوءاستفاده اضافه شوند.
۱۹. Allowlist دقیق Resource/Event با مستندات مصوب شریک و شواهد Sandbox مجاز تطبیق داده شود؛ فقط پس از آن Vertical Slice اجرایی Affiliate برنامه‌ریزی شود.

## تصمیم‌های موردنیاز مالک
شخصیت حقوقی و مدل عملیاتی؛ حوزه قضایی اولیه؛ Provider و منبع حقیقت؛ اعتبار نمونه ۱۰۰ دلاری Agent؛ کمیسیون/NGR و پیشرفت شبکه؛ نگاشت حساب و تأمین/نگهداری وجه؛ مجوز پرداخت؛ انتخاب فناوری و استقرار؛ محل و مدت نگهداری داده؛ فایل رسمی لوگو.

## انضباط شواهد
این سند خلاصه بازبینی مخزن است، نه ممیزی بیرونی. پیش از اتکا به Head SHA یا وضعیت CI، Metadata و وضعیت Commit جاری را دوباره دریافت کن.

## آخرین شواهد PR شماره ۷۶ و نقطه ادامه G09-A3

- PR شماره ۷۶ همچنان Open/Draft است؛ Base برابر `docs/affiliate-api-capability-contract-v1` و شاخه Head برابر `docs/g09-affiliate-api-wire-contract-v1` است. Merge یا Deploy انجام نشود.
- Head دقیق PR راستی‌آزمایی‌شده: `59414d2cc7544fed187e41e9c823e1d453c41a3a`.
- Documentation Governance، Run ID برابر `46054529199`، شماره ۹۳۹: **PASS**.
- Affiliate Contract Validation، Run ID برابر `46054529202`، شماره ۴۸: **PASS**؛ Job شماره `140693686036` با موفقیت تکمیل شد.
- Run شماره ۴۸، Redocly 2.83.0 را اجرا کرد (هر دو سند OpenAPI معتبر؛ یک Warning غیرمسدودکننده License برای هر سند)، AsyncAPI CLI 6.2.2 (سند AsyncAPI 3.0.0 معتبر؛ پیشنهاد Informational برای نسخه 3.1.0) و **۴۶ Assertion مثبت/منفی Payload و مرز امنیتی** با Ajv 8.17.1 / ajv-formats 3.0.1.
- ۴۶ Assertion شامل مرز ProgramPage در ۱۰۰/۱۰۱ و کنترل قراردادی جدایی Bearer Schemeهای Management/Ingress و وجود Scope Metadata پیشنهادی و غیرخالی برای تمام Operationهای محافظت‌شده است.
- خود CI تصریح می‌کند که Authorization زمان اجرا، Tenant Binding، اتمیک بودن Inbox/Job، Deduplication، اثر Ledger یا Allowlist Provider را تست نمی‌کند. این موارد در Runtime همچنان NOT TESTED هستند.
- سند دوزبانه LOT-AFFILIATE-SEC-ACC-001 اضافه شد؛ مشخصات پیشنهادی پذیرش امنیتی و مرز Runtime شامل مرز Principal/Authorization، جریان Ingress مورداعتماد، Idempotency/Fingerprint، حاکمیت Event/Schema، حفاظت منابع، ناورداهای Persistence/Worker، Privacy/Audit، ماتریس تست Runtime و چهار Gate انتشار. این سند پیاده‌سازی یا تأیید امنیتی نیست.
- Checkout مربوط به Workflow از Merge Ref شماره `ad0cd3237e0dbe94cb4a49f257cba0ac00bd167d` استفاده کرده که Head تست‌شده PR را با Base ترکیب می‌کند. Head خود PR همان Commit دقیق بالاست.
- اعلان‌های غیرمسدودکننده ابزارها: Warningهای License در Redocly؛ توصیه Informational نسخه جدیدتر AsyncAPI؛ هشدارهای Deprecation برخی Dependencyهای npm؛ و هشدار Deprecation مربوط به Node 20 در Actionهای Pinشده GitHub. این موارد را بدون ارزیابی جداگانه، نه Failure اعتبارسنجی و نه ریسک قطعی Production تلقی نکنید.

### ادامه کنترل‌شده
۱. LOT-AFFILIATE-SEC-ACC-001 را بازبینی و هر الزام را با LOT-API-PLATFORM-001، LOT-IAM-TENANT-001، LOT-EVENT-001، LOT-FIN-POST-001 و LOT-QA-001 تطبیق دهید.
۲. برگه تصمیم‌های مالک برای Identity، Capability، چرخه Installation، مالکیت Registry، ADR Fingerprint، Quota عددی، Retention/Audit و Economic-effect Identity کمیسیون تهیه کنید؛ مقادیر نامعلوم صریحاً TBD بمانند.
۳. برنامه اثبات Runtime ایزوله و فقط Synthetic و مرزهای Test Harness را تعریف کنید. تا زمان تصمیم‌های لازم و دریافت مستندات واقعی شریک و مجوز، Adapter عملیاتی، Credential واقعی شریک، Posting مالی یا درخواست Sandbox انجام نشود.
۴. پس از به‌روزرسانی Index و Status، حاکمیت مستندات دوزبانه دوباره اجرا و Head نهایی PR و تمام Workflowها را بررسی کنید.


## بسته تصمیم‌های G09-A3 و برنامه اثبات Runtime ساختگی — ۲۰۲۶-۱۱-۲۷

- سند دوزبانه LOT-AFFILIATE-G09-A3-001 در مسیرهای `docs/en/engineering/affiliate-g09-a3-decision-and-runtime-proof.md` و `docs/fa/engineering/affiliate-g09-a3-decision-and-runtime-proof.md` اضافه شد.
- این بسته ۱۵ مورد تصمیم صریح را در حوزه Principal/IAM، مجوزدهی، Credential، رجیستری Installation و Event/Schema، هویت رویداد، Fingerprinting، هم‌زمانی، سقف منابع، طبقه‌بندی/نگهداری/رمزنگاری داده، Audit و مرز عدم اثر مالی ثبت می‌کند. تمام موارد Proposed یا Open هستند و هیچ تأیید مالک مفروض نیست.
- مراحل اثبات ساختگی P0 تا P6 شامل ایزولاسیون Harness، مرز هویت/Tenant، Parse سخت‌گیرانه و Registry، Idempotency/Concurrency، Transaction/Crash Recovery، منابع/حریم خصوصی و اثبات صفر اثر مالی تعریف شدند.
- اثبات Runtime هنوز آغاز نشده است. شروع آن نیازمند تصویب صریح دامنه توسط مالک، تأیید ایزولاسیون توسط امنیت/عملیات و انتخاب کاندید Persistence دورریختنی با قیود تراکنشی واقعی است. ساخت Adapter شریک، Credential واقعی، فراخوانی Sandbox، ثبت مالی، Merge یا Deploy مجاز نیست.


## معماری اثبات Runtime و طراحی تست خصمانه G09-A4 — ۲۰۲۶-۱۱-۲۷

- سند دوزبانه LOT-AFFILIATE-G09-A4-001 در مسیرهای `docs/en/engineering/affiliate-g09-a4-runtime-proof-architecture.md` و `docs/fa/engineering/affiliate-g09-a4-runtime-proof-architecture.md` اضافه شد.
- طراحی شامل Harness دورریختنی صرفاً ساختگی، هفت مرز اعتماد، هشت ناوردای Persistence و ۴۷ شناسه پایدار سناریوی خصمانه در حوزه هویت، مجوز Object/Function/Property، Idempotency/Canonicalization، Parser/Schema/SSRF، حاکمیت منابع، بازیابی Transaction/Worker، حریم خصوصی/Audit و عدم اثر مالی است.
- شش Oracle مستقل تست، بسته شواهد، هشت Gate تصویب مالک/بازبین، ترتیب اجرا، شدت و شرایط توقف فوری تعریف شدند. OWASP API Security Top 10 (2023)، RFC 8785، CloudEvents و مرجع مشروط PostgreSQL صرفاً منابع طراحی‌اند و تصویب فناوری/Provider محسوب نمی‌شوند.
- هیچ Harness یا Runtime ساخته یا اجرا نشده است. اجرای A4 تا تصویب صریح دامنه/ایزولاسیون، انتخاب کاندید DB/Queue دورریختنی، پروفایل هویت تستی، Policy داده/شواهد، سقف بار و تأیید مالی/امنیت درباره عدم دسترسی مالی BLOCKED است.
- ساخت Adapter شریک، Credential واقعی، درخواست Sandbox خارجی، محاسبه کمیسیون، ثبت مالی، Merge یا Deploy مجاز نیست.

## نقطه ادامه G09-A5 (۲۰۲۶-۱۱-۲۷)
- سند دوزبانه LOT-AFFILIATE-G09-A5-001 اضافه شد. این سند ۴۷ سناریوی پایدار A4 را به مدل مستقل از فناوری برای Persistence/Atomicity، پروتکل Fencing مبتنی بر Generation، Fixture هویت ساختگی، نگاشت تزریق خطا، قرارداد تست اجرایی، Oracleهای مستقل و توالی اجرای Gateشده تبدیل می‌کند.
- هیچ DB، Queue، ارائه‌دهنده IAM، Runtime، Quota، دوره Retention یا Schema فیزیکی انتخاب نشده است. A5 صرفاً نقشه طراحی است؛ هشت Gate در A4 همچنان لازم‌اند. پیاده‌سازی و اجرای Runtime تا تصویب صریح مسدود است.
- نقشه، هویت Event منبع، کلید Idempotency درخواست و هویت اثر اقتصادی را جدا می‌کند؛ یکتایی پایدار و ایجاد اتمیک Receipt+Work را لازم می‌داند؛ پیام Queue را صرفاً اعلان بیدارباش می‌شمارد؛ و Fencing Worker قدیمی و عدم دسترسی مالی را الزام می‌کند.


## راستی‌آزمایی طراحی G09-A6 — ۲۰۲۶-۱۱-۲۷
- سند دوزبانه LOT-AFFILIATE-G09-A6-001 اضافه شد. بازبینی تأیید می‌کند هر ۴۷ شناسه پایدار A4 در نگاشت گروهی A5 حضور دارند؛ اما نگاشت گروهی معادل پوشش اجرایی در سطح تک‌تک Caseها نیست.
- نتیجه: **قبولی مشروط طراحی با یافته‌های باز**. ده یافته F01 تا F10 ثبت شد. یافته‌های F01 تا F07 مانع تصویب طراحی Runtime هستند؛ F08 تا F10 باید پیش از پذیرش گروه تست مربوطه بسته شوند.
- شفاف‌سازی‌های کلیدی: جفت اتمیک الزامی InboxReceipt + WorkItem است؛ DeliveryOutbox جدا و مشروط است و نباید آن الزام را تضعیف کند؛ برنامه Race تراکنش و Commit نامعلوم؛ اثبات صفر نوشتن Worker قدیمی؛ تصویب پروفایل هویت/Fingerprint؛ Policy بازاعتبارسنجی چرخه عمر؛ اثبات دفاع چندلایه عدم دسترسی مالی؛ پروفایل قابل‌اندازه‌گیری منابع؛ استقلال Oracle برای هر Case؛ و تصویب Policy چرخه داده.
- روی Head دقیق بررسی‌شده `e6808bda79a65c84d0dfab6e8b07094014184910`، اجرای Affiliate Contract Validation با شناسه `46060385984` (شماره ۷۳) و Documentation Governance با شناسه `46060385973` (شماره ۹۵۶) هر دو با موفقیت تکمیل شدند. این نتایج صرفاً مربوط به Workflowهای مستندات/قراردادند، نه شواهد Runtime.
- PR #76 همچنان Open/Draft است. هر هشت Gate در A4 لازم‌اند. هیچ پیاده‌سازی یا اجرای Runtime، انتخاب فروشنده، Integration شریک، عملیات مالی، Merge یا Deploy مجاز نیست.
- گام کنترل‌شده بعدی: بستن F01 تا F10 در اسناد دوزبانه، افزودن Manifest چهل‌وهفت‌ردیفی Case/Oracle و سپس اجرای مجدد CI روی Head دقیق. Runtime همچنان BLOCKED است.


## ادامه G09-A7 — ۲۰۲۶-۱۱-۲۷
- سند دوزبانه LOT-AFFILIATE-G09-A7-001 اضافه شد. Manifest در هر دو زبان شامل ۴۷ شناسه پایدار و یکتای A4 است (۶ IAM، ۷ AUTH، ۸ IDEM، ۶ PARSE، ۵ RES، ۸ DUR، ۴ DATA و ۳ FIN). خواندن خودکار مخزن، وجود ۴۷ ردیف و ۴۷ شناسه یکتا در هر فایل و ترتیب یکسان شناسه‌ها را تأیید کرد.
- هر ردیف Fixture، Stimulus قطعی، انتظار پروتکل/مجوزدهی، Assertionهای Persistence و عدم اثر مالی، Oracle/Evidence مستقل و وضعیت صریح NOT RUN یا BLOCKED مبتنی بر Policy/ADR دارد.
- پنج برنامه انتزاعی قطعی اضافه شد: Ingress تکراری هم‌زمان، نتیجه نامعلوم Commit، Fencing Worker قدیمی، ماتریس Crash جفت اتمیک و Race چرخه عمر Tenant. این‌ها قرارداد طراحی‌اند و تست اجراشده نیستند.
- جفت اتمیک پیشنهادی InboxReceipt + WorkItem است. DeliveryOutbox برای انتشار پایین‌دستی جدا و مشروط است و نمی‌تواند جای WorkItem را بگیرد. این شفاف‌سازی پیشنهادی است، نه Schema فیزیکی یا انتخاب فناوری مصوب.
- F01 آماده بازبینی مستقل است؛ F02 تا F10 تا زمان تصمیم مالک پاسخ‌گو، ADR و Evidence باز می‌مانند. هیچ Quota عددی، Retention، Vendor یا Runtime انتخاب نشده است.
- OWASP ASVS برای نگاشت آتی Requirementها روی نسخه پایدار 5.0.0 Pin شده است؛ محتوای Bleeding Edge بی‌صدا پذیرفته نمی‌شود. ادعای انطباق ASVS وجود ندارد.
- هیچ پیاده‌سازی/اجرای Runtime/Harness/DB/Queue، Integration شریک، عملیات مالی، Merge یا Deploy مجاز نیست. هر هشت Gate در A4 همچنان الزامی‌اند.


## ادامه G09-A8 — 2026-11-27
- سند دوزبانه LOT-AFFILIATE-G09-A8-001 افزوده شد. این سند **خودبازبینی خصمانه طراحی** است، نه تأیید مستقل؛ هیچ Runtime/زیرساختی اجرا یا بررسی عملیاتی نشده است.
- ۱۲ یافته جدید ثبت شد: اعتبار Lease در لحظه Mutation، Fence اثر جانبی بیرونی، منع کامل Capability مالی، Linearization چرخه عمر، استقلال Oracle، چرخه عمر Generation/Token، Reconciliation نتیجه نامعلوم Commit، منشأ/زمان/تمامیت Evidence، تعارض Retention و حذف، Interleavingهای مفقود، Amplification/Fairness منابع و هم‌ارزی معنایی دو زبان.
- هشت Subcase پیشنهادی زیر شناسه‌های اصلی A4 اضافه شد؛ ۴۷ شناسه اصلی تغییر نمی‌کنند و هیچ تستی اجرا نشده است.
- یافته‌های F01 تا F10 در A7 طبق وضعیت قبلی باز هستند. A7-F01 فقط آماده بازبینی واقعاً مستقل است و با A8 بسته نمی‌شود. A8-F01 تا A8-F12 باز هستند.
- A4-GATE-01 تا A4-GATE-08 تصویب نشده‌اند؛ اجرای Runtime/Harness/Database/Queue/IAM مسدود است. Integration شریک، عملیات مالی، Merge یا Deploy مجاز نیست.
- گام بعد: تعیین تکلیف توسط بازبین مستقل؛ حل پروتکل زمانی و اثبات منع Capability مالی؛ تکمیل ردیابی Subcaseها در A7 و ADRهای پاسخ‌گو؛ اعتبارسنجی Governance دوزبانه و CI روی Head دقیق.
