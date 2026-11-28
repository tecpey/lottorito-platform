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


## G09-A9 / ADR-001 — 2026-11-28
- سند دوزبانه LOT-AFFILIATE-G09-ADR-001 افزوده شد؛ پروتکل پیشنهادی Claim Generation پایدار برای هر WorkItem و انتقال Guardشده را تعریف می‌کند. رقابت Linearization هنگام انقضای Lease، کنترل Owner/Token احراز‌شده، ممنوعیت احیای Lease، محدودیت مرز Transaction، Reconciliation نتیجه نامعلوم Commit و Fencing در Restore/Recovery را پوشش می‌دهد.
- تمایز معنایی اصلی صریح شد: انقضای Lease فقط کار را واجد شرایط Reclaim می‌کند؛ نخستین انتقال پایدار Guardشده و سریال‌شده برنده است. انتقالی که در زمان اعتبار Lease Linearize شود، پیش از Reclaim بعدی مرتب می‌شود؛ پس از انقضا یا تغییر Generation، Worker قدیمی باید صفر Row محافظت‌شده را تغییر دهد. این قاعده به اثبات Semantics مربوط به Lock/Time/Failover در Persistence Engine آینده وابسته است و هنوز تصویب نشده.
- هشت Subcase مربوط به A8 به اسناد ردیابی A7 در هر دو زبان اضافه شد و به والدهای A4 متصل شد. تعداد Canonical در A4 همچنان ۴۷ است؛ نتایج والد و Subcase باید جداگانه گزارش شوند. همه Subcaseها NOT RUN/BLOCKED هستند.
- ADR-001 پیشنهادی است. تصمیم‌های مالک درباره زمان مرجع/Failover، Semantics Serialization در Persistence، اتمام ظرفیت Generation، مرجع Recovery Incarnation، Policy چرخه عمر و محدودیت Transaction/Worker باز هستند. هیچ DB/Queue/Vendor یا مقدار عددی انتخاب نشده.
- بازبینی مستقل همچنان لازم است. F01 تا F10 در A7 و F01 تا F12 در A8 باز هستند. هر هشت Gate در A4 تصویب نشده‌اند؛ پیاده‌سازی/اجرای Runtime/Harness/Database/Queue/IAM مسدود است. هیچ مجوز شریک، عملیات مالی، Merge یا Deploy صادر نشده است.


## G09-A10 / ADR-002 — پذیرش اتمیک و تطبیق نتیجه نامعلوم Commit (2026-11-28)
- سند دوزبانه LOT-AFFILIATE-G09-ADR-002 افزوده شد. این سند دقیقاً یک جفت پایدار InboxReceipt + WorkItem را در یک تراکنش اتمیک پیشنهاد می‌کند؛ پاسخ موفق فقط پس از Commit تأییدشده؛ UNKNOWN به‌عنوان وضعیت مستقل؛ تطبیق معتبر با هویت پایدار Event؛ Fail-closed هنگام عدم دسترسی به مرجع؛ قرنطینه Conflict و جفت ناقص؛ و مرز جداگانه و مشروط DeliveryOutbox.
- ماتریس ۱۷ موردی Crash/Concurrency/Failover (C01 تا C17)، الزامات Oracle/Evidence مستقل، گزینه‌های ردشده و تصمیم‌های باز مالک ثبت شد. همه موارد NOT RUN هستند. هیچ DB، Isolation Level، Queue، Vendor، Schema، Quota، مقدار Retention یا توپولوژی انتخاب نشده است.
- LDR-055 در هر دو دفتر تصمیم ثبت شد. ADR-002 پیشنهادی است؛ تصویب مالک و بازبینی واقعاً مستقل در انتظارند. A7-F01 تا F10 و A8-F01 تا F12 باز هستند؛ هر هشت Gate مربوط به A4 تصویب نشده‌اند. مجوز Runtime، شریک، مالی، Merge یا Deploy صادر نشده است.
- Head زنده PR #76 پیش از این Update برابر 3112f7e4db83c27c223a054db497665619df5164 بود. Workflowهای همان Head در صف بودند؛ CI باید روی Head نهایی دوباره بررسی شود. شکست قبلی Documentation Governance ناشی از نبود فیلد پایدار Document ID در دو نسخه ADR-001 بود؛ هر دو فایل اصلاح شده‌اند و این اصلاح باید در CI مربوط به Head نهایی تأیید شود.


## G09-A11 — بازبینی خصمانه طراحی ADR-002 (2026-11-28)
- سند دوزبانه LOT-AFFILIATE-G09-A11-001 برای ADR-002 نسخه ۰.۱.۰ / Head بازبینی‌شده 985cfee7ce233e6297b7de2d5d2339d8484b843e افزوده شد.
- هشت یافته ثبت شد: A11-F01 Durability Commit در Failover (بحرانی)؛ F02 Epoch مرجعیت و Fencing در برابر Split-brain (بحرانی)؛ F03 Race بین Read منفی و Commit درحال‌اجرا (بحرانی)؛ F04 Cardinality و Constraint رابطه جفت (زیاد)؛ F05 وابستگی به Fingerprint Profile/Version (زیاد)؛ F06 Idempotency محدود به Retention (بحرانی)؛ F07 دامنه Quarantine و DoS (زیاد)؛ F08 تفکیک معنای پذیرش از اجرای کار (زیاد).
- نه Subcase خصمانه پیشنهادی زیر Parentهای A4/A8 ثبت شد؛ ۴۷ شناسه Canonical در A4 تغییر نکردند. تمام Subcaseها NOT RUN هستند.
- این سند Self-review در همان جریان است و تأیید مستقل نیست. LDR-056 در هر دو Decision Register ثبت شد. ADR-002 پیشنهادی باقی می‌ماند؛ یافته‌های A7/A8 باز هستند؛ هر هشت Gate A4 تصویب‌نشده‌اند. هیچ مجوز Runtime، Database، Queue، Partner، عملیات مالی، Merge یا Deploy صادر نشده است.
- منابع تحقیق شامل راهنمای رسمی Google Spanner درباره Unknown Commit و مستندات PostgreSQL درباره HA، Replication و Durability در WAL است. هیچ Provider/فناوری انتخاب نشده است.


## G09-A12 — یکپارچه‌سازی ADR-002 نسخه ۰.۳.۰ (2026-11-28)
- موانع طراحی A11 در ADR-002 دوزبانه نسخه ۰.۳.۰ یکپارچه شدند: Authority Epoch تک‌نویسنده و Fencing Primary قدیمی؛ Durability/RPO مربوط به Commit تأییدشده؛ Dedup/Tombstone مربوط به Source Event محدود به Replay Horizon؛ Quarantine مرحله‌ای و منع Claim توسط Worker؛ و Semantics پاسخ صرفاً Acceptance.
- یافته‌های A11-F01 تا F08 در سند بازبینی دوزبانه تطبیق داده شدند. این Crosswalk همان تدوین‌گر است، نه بستن مستقل یافته‌ها. هر هشت یافته تا تصمیم مالک، بازبینی مستقل و شواهد Candidate باز هستند.
- A7 دوزبانه با ۹ Subcase مربوط به A11 و چهار Subcase تکمیلی A10 توسعه یافت؛ ۴۷ شناسه Canonical در A4 تغییر نکرده‌اند. تمام Subcaseهای افزوده NOT RUN/BLOCKED هستند.
- ADR-002 همچنان PROPOSED است. هیچ فناوری، Authority Service، Database، Queue، Runtime، شریک، عملیات مالی، Merge یا Deploy مجاز نشده است. هر هشت Gate مربوط به A4 تصویب‌نشده‌اند.
- پس از این Commitها CI دقیق Head باید دوباره بررسی شود؛ موفقیت Workflow قبلی به Head جدید منتقل نمی‌شود.

- همگام‌سازی تکمیلی: ADR-002 نسخه ۰.۳.۰ اکنون الزامات Authority Epoch، Durability/RPO، Retention Replay، Quarantine و Semantics پاسخ را در بر دارد؛ مراجع PostgreSQL درباره HA/Failover/WAL صرفاً شواهد مقایسه‌ای‌اند. هر دو نسخه A7 فارسی/انگلیسی دقیقاً ۴۷ شناسه Canonical A4 و ۲۱ Subcase توسعه‌ای یکتا دارند (۸ مورد قبلی + ۹ مورد A11 + ۴ مورد A10)؛ README هر دو زبان به سند A11 پیوند دارد. تمام موارد توسعه‌ای NOT RUN/BLOCKED باقی می‌مانند.

- اصلاح دقت ارجاع والد در A7: مورد A11-DUR-02b اکنون در هر دو زبان به‌طور صریح به A4-DUR-02 و A4-IDEM-02 متصل است؛ مجموعه Canonical چهل‌وهفت‌گانه و تعداد ۲۱ Subcase توسعه‌ای تغییری نکرده است.


## G09-A12 — بسته بازبینی مستقل ADR-002 (۲۰۲۶-۱۱-۲۸)
- سند دوزبانه LOT-AFFILIATE-G09-A12-001 افزوده شد. بسته شامل معیار استقلال/صلاحیت، پروتکل تثبیت ورودی‌ها، Scheduleهای بازسازی خصمانه، ماتریس Evidence برای A11-F01 تا F08، موجودی Extensionهای A7 و الزامات Oracle مستقل است.
- این بسته خودِ بازبینی مستقل نیست. هنوز بازبینی‌کننده‌ای تعیین یا تأییدیه‌ای امضا نشده است؛ A11-F01 تا F08 باز، تمام Extensionهای A7 در وضعیت NOT RUN/BLOCKED، ADR-002 در وضعیت PROPOSED و هر هشت Gate مربوط به A4 تصویب‌نشده‌اند.
- شماره‌گذاری تکراری بخش ADR-002 و جمله تکراری فارسی در A7 اصلاح شد. این اصلاحات صرفاً ویرایشی‌اند و هیچ یافته طراحی را نمی‌بندند.
- CI باید پس از آخرین Commitهای متوالی روی Head دقیق دوباره بررسی شود. هیچ فناوری، Runtime، شریک، عملیات مالی، Merge یا Deploy مجاز نیست.


## G09-A13 — بازبینی اطمینان‌بخشی اعتبارسنجی قرارداد (۲۰۲۶-۱۱-۲۸)
- هر دو Workflow روی Head دقیق منبع `e88c6b6fac04b451926a8137ca68571f19e18fa8` با SUCCESS تکمیل شدند: Documentation Governance #1014 و Affiliate Contract Validation #151. مراحل Job اجرای OpenAPI lint، AsyncAPI CLI validation و Fixtureهای نماینده Ajv را تأیید می‌کنند.
- سند دوزبانه LOT-AFFILIATE-G09-A13-001 به‌عنوان بازبینی اطمینان‌بخشی همان نویسنده اضافه شد؛ این بازبینی مستقل نیست. یافته‌های A13-F01 تا F06 باز هستند: Assertion دقیق Scheme/Scope هر Operation، انطباق Extensionهای CloudEvents و مرز Allowlist نصب، توصیف Dialect در AsyncAPI، بازتولیدپذیری وابستگی‌های Transitive، هم‌ترازی پاسخ 202/503/UNKNOWN با ADR-002 و کامل‌بودن پوشش Fixtureها.
- اسناد فعلی قرارداد و امنیت از قبل بازبودن Allowlist و معنای Scope در Runtime را تصریح کرده‌اند؛ این بازبینی ادعای پیاده‌سازی آن‌ها را ندارد. ADR-002 همچنان PROPOSED، A11-F01 تا F08 باز، A7 صرفاً طراحی و هر هشت Gate مربوط به A4 تصویب‌نشده‌اند.
- بسته پیشنهادی بعدی G09-A14 سخت‌سازی Validator قرارداد و هم‌ترازی وضعیت پاسخ است. هیچ پیاده‌سازی Runtime، انتخاب فناوری، اتصال شریک، عملیات مالی، Merge یا Deploy مجاز نیست.


## G09-A14 — سخت‌سازی اعتبارسنجی قرارداد (۲۰۲۶-۱۱-۲۸)
- سند دوزبانه LOT-AFFILIATE-G09-A14-001 و Manifest ماشینی `contracts/validation/affiliate-contract-validation-manifest.v1.json` اضافه شدند.
- نامزد Validator اکنون Scheme و `x-required-scopes` دقیق هر Operation را با Manifest تطبیق می‌دهد و هفت Mutation منفی دارد؛ نام/نوع عمومی Extensionهای CloudEvents و Semantics مربوط به Unicode در Stringها را کنترل می‌کند؛ توصیف پیش‌فرض AsyncAPI 3.0 Schema Object را اصلاح و Subset سازگار با Draft 07 در Ajv را Guard می‌کند؛ تمام ۱۱ Schema Root فعلی و ۵۳ Fixture مثبت/منفی را فهرست می‌کند.
- متن پاسخ‌های Wire مربوط به 202/503 به Persistence اتمیک و شرط Durability تصویب‌شده مالک مشروط شده است؛ UNKNOWN صریحاً نه پذیرش قطعی و نه رد قطعی است. نگاشت دقیق HTTP/Error برای UNKNOWN، Failure Model، RPO و تصمیم‌های Promotion/Recovery باز هستند.
- Manifestهای نسخه‌دقیق جداگانه برای `.github/contract-tools` و `.github/schema-tools` اضافه شدند؛ جداسازی Dependency Graph مانع Collision نسخه‌های Transitive مربوط به CLI/Ajv می‌شود. CI هر دو Lockfile را موقتاً تولید می‌کند و Job دارای مجوز محدود فقط همین فایل‌ها را Commit می‌کند؛ پس از آن باید مسیر موقت حذف شود. هر دو Lockfile مستقل (`.github/contract-tools/package-lock.json` و `.github/schema-tools/package-lock.json`) Commit شده‌اند؛ Bootstrap/Artifact/Job نوشتن موقت حذف شده و اکنون `npm ci` سخت‌گیرانه اجباری است. A13-F04 فقط تا موفقیت `npm ci` روی Head نهایی دقیق باز می‌ماند.
- A14 در وضعیت IN PROGRESS است. تطبیق ایستای منبع، ۵۳ شناسه یکتای Fixture در اسکریپت را با ۵۳ شناسه Manifest برابر یافت؛ این نتیجه اجرای Node/Ajv نیست. CI روی Head دقیق فعلی A14 باید پس از آخرین Commitهای متوالی بررسی شود.
- A13-F02 برای Allowlistهای Runtime مختص Installation جزئاً باز است؛ A13-F05 برای تصمیم مالک و Proof اختصاصی Candidate باز است. ADR-002 همچنان PROPOSED؛ A11-F01 تا F08 باز؛ A7/A8 صرفاً طراحی و NOT RUN؛ هر هشت Gate مربوط به A4 تصویب‌نشده‌اند. بدون مجوز Runtime، انتخاب Persistence، اتصال شریک، عملیات مالی، Merge یا Deploy.

### نقطه کنترل Lockfile در G09-A14
- هر دو Lockfile مجزا در نوک Branch ثبت شده‌اند: contract-tools شامل ۱٬۴۰۹ رکورد Package و schema-tools شامل ۷ رکورد Package، هر دو با lockfileVersion 3. سازوکار موقت Bootstrap/Artifact/Write-back حذف شده و Workflow اکنون برای هر دو Prefix از `npm ci` سخت‌گیرانه استفاده می‌کند. اعتبارسنجی نهایی روی Head دقیق در انتظار است.

### تأیید نهایی G09-A14 روی Head دقیق — ۲۰۲۶-۱۱-۲۸
- Head دقیق `3a008718ab9cf40a551441e3a195f73874788f26` تأیید شد: Documentation Governance #1057 با SUCCESS (`46070895494`) و Affiliate Contract Validation #227 با SUCCESS (`46070891292`).
- هر دو نصب سخت‌گیرانه `npm ci` از Lockfileهای مجزای ثبت‌شده با Node 24.11.1/npm 11.6.2 موفق شدند. Redocly OpenAPI، AsyncAPI CLI 6.2.2 و اعتبارسنجی Payload با Node/Ajv موفق شدند: ۶۶ Assertion، ۱۱ Schema Root و ۵۳ Fixture مثبت/منفی.
- A13-F01/F03/F04/F06 در محدوده قرارداد/CI تأیید شدند. A13-F02 برای Proof مربوط به Allowlist نصب در Runtime جزئاً باز است؛ A13-F05 تا تصمیم مالک و Proof اختصاصی Durability/UNKNOWN باز می‌ماند. هشدارهای غیرمسدودکننده: نبود Metadata مربوط به `info.license` و پیشنهاد AsyncAPI CLI برای بررسی نسخه 3.1.0؛ هیچ License یا Migration مربوط به Dialect استنباط نمی‌شود.
- ADR-002 همچنان PROPOSED؛ A11-F01 تا F08 باز؛ A7/A8 صرفاً طراحی و NOT RUN؛ تمام Gateهای A4 تصویب‌نشده؛ بازبینی مستقل باقی است. بدون مجوز Runtime، انتخاب Persistence/Queue، اتصال شریک، عملیات مالی، Merge یا Deploy.


## G09-A15 — آمادگی اثبات Persistence برای ADR-002 (۲۰۲۶-۱۱-۲۸)
- سند دوزبانه LOT-AFFILIATE-G09-A15-001 با هفت تعهد اثبات مستقل از Candidate، ۱۲ تصمیم مالک، ۱۲ Schedule ساختگی، الزامات Manifest شواهد مستقل، Gateهای مرحله‌ای آمادگی و شرایط توقف اضافه شد.
- خط مبنای بررسی: Head مربوط به PR شماره ۷۶ برابر با `736390f86ab425a8c273dcf254cc5974e9eb55ae`؛ Affiliate Contract Validation شماره ۲۳۵ و Documentation Governance شماره ۱۰۶۲ هر دو روی همان Head دقیق SUCCESS شدند. این نتایج به Commitهای مستنداتی بعدی A15 منتقل نمی‌شوند و رفتار Persistence/Runtime را اثبات نمی‌کنند.
- بسته A12 همچنان روش بازبینی مستقل است؛ در رکورد PR بررسی‌شده، Review مستقل ثبت‌شده‌ای در GitHub وجود نداشت. A15 بازبینی مستقل نیست. A11-F01 تا F08 باز؛ ADR-002 در وضعیت PROPOSED؛ تمام Gateهای A4 تصویب‌نشده؛ S01 تا S12 در وضعیت NOT RUN هستند.
- Allowlist مختص Installation در Runtime مربوط به A13-F02 و تصمیم/Proof مالک و Candidate مربوط به A13-F05 باز هستند. هیچ Persistence/Queue/Vendor انتخاب نشده؛ هیچ Runtime/Harness اجرا، شریک متصل، عملیات مالی، Merge یا Deploy مجاز نیست. CI روی Head نهایی پس از Commitهای مستنداتی A15 باید بررسی شود.


### تأیید CI روی Head دقیق G09-A15 — ۲۰۲۶-۱۱-۲۸
- روی Head دقیق `5543d7ab24ec263fd0d71c40c157309a72d925c2`، هر دو Workflow موفق شدند: Documentation Governance شماره ۱۰۶۷ (Run: `46104632406`) و Affiliate Contract Validation شماره ۲۴۲ (Run: `46104632398`).
- Documentation Governance ساختار دوزبانه و Linkهای محلی را اعتبارسنجی کرد. Affiliate Contract Validation نصب Toolchain قفل‌شده، اعتبارسنجی OpenAPI، اعتبارسنجی AsyncAPI و Fixtureهای Payload را کامل کرد.
- مقایسه دستی مجموعه شناسه‌ها، تطابق موجودی نسخه‌های فارسی/انگلیسی را برای PO-01 تا PO-07، OD-01 تا OD-12، S01 تا S12 و A11-F01 تا F08 تأیید کرد. این فقط تطابق ساختاری شناسه‌هاست و جای ممیزی معنایی ترجمه را نمی‌گیرد.
- این نتایج فقط به Head دقیق بالا مربوط‌اند. هر Commit بعدی نیازمند بررسی مجدد CI روی Head دقیق خودش است. هیچ Proof مربوط به Runtime/Persistence اجرا نشده؛ A11-F01 تا F08 باز، ADR-002 در وضعیت PROPOSED، S01 تا S12 در وضعیت NOT RUN و تمام Gateهای A4 تصویب‌نشده‌اند.


## G09-A16 — پرونده بازبینی خصمانه معماری (۲۰۲۶-۱۱-۲۸)
- سند دوزبانه LOT-AFFILIATE-G09-A16-001 بر مبنای Head ثابت‌شده PR شماره ۷۶ برابر با `8e9a880c14000bd158f66ae2001c02669ed4cc6b` اضافه شد.
- A16 شامل ده چالش میان‌برشی تدوین‌کننده، دوازده خانواده Schedule قطعی، الزامات Freeze Source/کنترل تغییر، اظهارنامه استقلال و صلاحیت بازبین، الزامات Oracle/Evidence مستقل و قالب Disposition امضاشده است.
- منابع تحقیق شامل راهنماهای AWS Builders' Library/Well-Architected درباره Retry و Idempotency، مستندات PostgreSQL درباره WAL/Synchronous Replication/Failover، تحلیل Fencing Token، روش History Checking در Jepsen، RFC 8785 و RFC 7493 هستند. این منابع برای بازبینی‌اند و فناوری انتخاب نمی‌کنند.
- A16 تأیید مستقل نیست. A11-F01 تا F08 باز؛ ADR-002 در وضعیت PROPOSED؛ Extensionهای A7/A8 در وضعیت NOT RUN/BLOCKED؛ تمام Gateهای A4 تصویب‌نشده‌اند. هیچ Proof مربوط به Candidate/Runtime/Harness، اتصال شریک، عملیات مالی، Merge یا Deploy مجاز نیست. CI باید روی Head دقیق پس از A16 بررسی شود.


## G09-A17 — تطبیق بازبینی مستقل (۲۰۲۶-۱۱-۲۸)
- PR شماره ۷۶ از Draft به Ready for review تغییر وضعیت داده است؛ همچنان OPEN و ادغام‌نشده است. در آخرین بررسی GitHub مقدار `mergeable=true` گزارش کرد. این صرفاً مشاهده قابلیت ادغام در پلتفرم است.
- Review شماره 6095766449 از `xrayman6zfm-ux` با وضعیت `APPROVED` در زمان `2026-11-28T04:19:55Z` ثبت شده و به Commit دقیق `b547d3976c97e6068ace6747dbf72f3a6fb9828f` اشاره می‌کند. متن Review خالی است و Inline Review Thread مشاهده نشد. این یک شاهد معتبر تأیید در سطح پلتفرم است.
- الزامات بازبینی محتوایی A12 (اظهارنامه استقلال/صلاحیت/تعارض، فهرست Artifactها، بازسازی پروتکل، تحلیل خصمانه و Disposition جداگانه A11) در Artifactهای قابل مشاهده GitHub مستند نشده‌اند. این محدودیت شواهد است، نه ادعای نبود تحلیل خارج از GitHub.
- سند دوزبانه LOT-AFFILIATE-G09-A17-001 و LDR-062 اضافه شدند. A17 تأیید را بدون استنباط بسته‌شدن فنی ثبت می‌کند. A11-F01 تا F08 و OD-01 تا OD-12 باز؛ ADR-002 همچنان PROPOSED؛ تمام Gateهای A4 تصویب‌نشده‌اند.
- هیچ Proof مربوط به Runtime/Persistence، انتخاب Candidate، اتصال شریک، عملیات مالی، Merge یا Deploy مجاز نیست. شاخه پیگیری A17 از Head دقیق PR شماره ۷۶ ساخته شده؛ تغییرات A17 نیازمند CI و بازبینی مستقل روی Head دقیق خود هستند.


## استاندارد جامع ارزیابی — ۲۰۲۶-۱۱-۲۸

- سند دوزبانه LOT-EVAL-001 در مسیرهای `docs/en/governance/enterprise-evaluation-standard.md` و `docs/fa/governance/enterprise-evaluation-standard.md` اضافه شد.
- LOT-EVAL-001 استاندارد مادر پیشنهادی برای تصمیم‌های محصول، فناوری، تأمین‌کننده، یکپارچه‌سازی، داده/مدل و مدل عملیاتی است. این سند عمق متناسب با ریسک T0 تا T3، کلاس/تازگی شواهد مبتنی بر ادعا، گردش‌کار اجباری، Gateهای غیرقابل‌جبران، Rubric تثبیت‌شده پیش از امتیازدهی، TCO/برگشت‌پذیری چرخه عمر، شواهد پایلوت کنترل‌شده، پرونده تصمیم، وضعیت‌های صریح، محرک‌های ارزیابی مجدد و تقدم پروفایل تخصصی را تعریف می‌کند.
- اسناد LOT-PROVIDER-EVAL-001 و LOT-TECH-ADR-001 عمداً به‌عنوان اسناد تخصصی حفظ شده‌اند. این سند هیچ‌کدام را بی‌صدا جایگزین یا تصویب نمی‌کند، وزن الزام‌آور امتیازدهی تعیین نمی‌کند، گزینه‌ای انتخاب نمی‌کند، محدوده حقوقی/حوزه قضایی را تأیید نمی‌کند و مجوز خرید، پیاده‌سازی، داده Production، اتصال شریک، فعالیت مالی یا راه‌اندازی صادر نمی‌کند.
- منابع پژوهش شامل ISO 31000:2018، ISO/IEC 25010:2023، NIST SP 800-161 Rev.1 Update 1، NIST SP 1326 (2026)، NIST SP 1305، OWASP SAMM و FinOps Framework است. این منابع طراحی ارزیابی را پشتیبانی می‌کنند؛ Lottorito یا هیچ گزینه‌ای را Certification نمی‌کنند.
- نخستین کاربرد به‌صورت ارزیابی بازنگرانه محدود و غیرProduction پیشنهاد شده است؛ انتخاب واحد تصمیم بر عهده مالک پاسخ‌گو پس از بازبینی است. استاندارد تا زمان بازبینی مالک و متخصصان در وضعیت PROPOSED باقی می‌ماند.


## سخت‌سازی خصمانه LOT-EVAL-001 — ۲۰۲۶-۱۱-۲۸

- گزارش بازبینی خصمانه نویسنده LOT-EVAL-A18-001 به فارسی و انگلیسی اضافه شد. این گزارش ۱۲ یافته شامل ۱ بحرانی، ۱۰ زیاد و ۱ متوسط ثبت می‌کند و صریحاً ادعای تضمین مستقل ندارد.
- نسخه پیشنهادی LOT-EVAL-001 از ۰.۱.۰ به ۰.۲.۰ ارتقا یافت و بخش الزام‌آور دوزبانه ۱۷ را درباره سطح ریسک در برابر رتبه ریسک، ریسک ذاتی/باقیمانده، منشأ چندبُعدی شواهد، کفایت شواهد در برابر امتیاز قابلیت، NS در برابر صفر، امتیازدهی نرمال‌شده، کنترل اختلاف ارزیابان، TCO چرخه عمر، Due Diligence تأمین‌کننده، ارزیابی DATA/MODEL، سناریوهای کیفیت ISO/IEC 25010، پروتکل پایلوت، تفکیک تصویب‌ها و تقدم اسناد تخصصی اضافه کرد.
- کارت‌های امتیاز پیشنهادی LOT-PROVIDER-EVAL-001 و LOT-TECH-ADR-001 تطبیق داده شدند: وزن‌های آن‌ها تا زمان تصویب صریح برای یک واحد تصمیم مشخص و تطبیق با Rubric مادر، صرفاً پیشنهادی باقی می‌مانند.
- A18 بازبینی نویسنده است؛ بازبینی مستقل، تصمیم مالک درباره ریسک‌پذیری، تأیید متخصصان و CI روی SHA دقیق در انتظارند. LOT-EVAL-001 همچنان PROPOSED است. هیچ Candidate، Provider، فناوری، حوزه قضایی، خرید، داده Production، اتصال شریک، فعالیت مالی، Merge یا Deploy مجاز نشده است.


## اصلاحات تکمیلی LOT-EVAL-001 — ۲۰۲۶-۱۱-۲۸

- LOT-EVAL-001 اکنون نسخه پیشنهادی ۰.۳.۰ است. بخش‌های ۸.۳ و ۱۷.۱۰ Rubric کامل قابلیت؛ جداسازی وضعیت شواهد از امتیاز؛ معنای صریح NS/Partial/N/A؛ برخورد با زیرمعیار اتمی؛ لنگرهای اطمینان؛ مرز تست مصنوعی و Tier عملیاتی؛ محدودیت افق ریسک و ماتریس ترتیبی؛ سوگیری پیش‌بینی/گروه مرجع TCO و ارزش تغییر مسیر؛ و معیارهای تضمین رسمی را اضافه می‌کنند.
- بازبینی خصمانه تکمیلی REV-01 تا REV-14 در A18 ثبت شده است. REV-11 صریحاً یافته ماهوی نیست: دو فرمول وقتی مجموع وزن‌های قابل‌اعمال ۱۰۰ باشد معادل‌اند.
- دستور مالک در ۲۰۲۶-۱۱-۲۸ اعمال اصلاحات فنی/مستندیِ پشتیبانی‌شده با شواهد را در Artifactهای مرتبط مجاز می‌کند. این دستور اجرایی است، نه پذیرش موردبه‌مورد یافته‌ها یا تصویب ریسک باقیمانده. تمام Dispositionهای مالک برای REVها همچنان PENDING هستند.
- بازبینی به رهبری مالک، چالش تخصصی و تضمین مستقل نقش‌های جداگانه‌اند. هیچ تضمین مستقلی ادعا یا ثبت نشده است. LOT-EVAL-001 همچنان PROPOSED و تصویب‌نشده است.
- استاندارد، A18، دفتر بازبینی مالک و سوابق تصمیم فارسی/انگلیسی همگام شده‌اند. Documentation Governance باید روی Head نهایی دقیق بررسی شود؛ برای Commitهای جدید ادعای موفقیت CI نداریم.
- هیچ Candidate، تأمین‌کننده، فناوری، حوزه قضایی، خرید، قرارداد، داده Production، اتصال شریک، فعالیت مالی، Merge یا Deploy مجاز نشده است.


## هم‌ترازی بین‌سندی LOT-EVAL — ۲۰۲۶-۱۱-۲۸

- پروفایل Provider یعنی LOT-PROVIDER-EVAL-001 به نسخه پیشنهادی ۰.۲.۰ ارتقا یافت: اعتبار مرجع از استقلال جداست؛ وزن‌های تخصصی Provider همچنان پیشنهادند؛ معنای امتیاز قابلیت، NS، Partial، N/A، اطمینان و Gateهای سخت از LOT-EVAL-001 نسخه ۰.۳.۰ به ارث می‌رسد.
- ADR فناوری یعنی LOT-TECH-ADR-001 به نسخه پیشنهادی ۰.۲.۰ ارتقا یافت: عبارت محلی محدود به امتیاز ۱ تا ۵ با مدل شواهد ۰ تا ۵/NS/N/A استاندارد مادر جایگزین شد؛ وزن‌های پیشنهادی فناوری همچنان تصویب نشده‌اند.
- مدل تهدید امنیتی یعنی LOT-SEC-TM-001 به نسخه پیشنهادی ۰.۲.۰ ارتقا یافت: برچسب‌های High/Critical برای ریسک باقیمانده اکنون نیازمند سناریوی مستند، افق، زوج خام احتمال/اثر، ابعاد اثر، عدم‌قطعیت، شواهد کنترل و مرجع پذیرش نام‌دارند و به لنگرهای ریسک استاندارد مادر ارجاع می‌دهند.
- راهبرد Provider حوزه‌های Gaming همچنان از LOT-PROVIDER-EVAL-001 به‌عنوان فرایند مشترک ارزیابی تأمین‌کننده استفاده می‌کند؛ هیچ Provider یا بازاری در Gaming انتخاب نشده است.
- کاتالوگ دوزبانه ویژگی‌های کیفی معماری اکنون روشن می‌کند نتیجه سناریوی QA به محدوده/پیکربندی/بار کاری/دوره آزموده‌شده محدود است و معنای شواهد و تصمیم را از LOT-EVAL-001 می‌گیرد؛ وضعیت QA به‌تنهایی تضمین Production یا امتیاز Provider نیست.
- در یک دور تکمیلی سازگاری استاندارد مادر، بخش ۴ تنها جدول مرجع محرک Tier است و سطح‌بندی را بر اساس واحد تصمیم و مجوز دقیق انجام می‌دهد؛ تست مصنوعی محدود بر اساس محدوده واقعی خودش سطح می‌گیرد و خودکار T3 نیست. تصمیم هویتی با اثر بالا که بتواند دسترسی به وجوه مشتری/فعالیت ممتاز را به‌طور مهم تغییر دهد یا آسیب شدید ایجاد کند، محرک صریح T3 است. بخش ۵.۱ اعتبار مرجع، استقلال، مستقیم‌بودن، محدوده، تازگی، تکرارپذیری و محدودیت‌ها را به‌عنوان ویژگی‌های جدا ثبت می‌کند، نه یک کلاس شواهد مخلوط. بخش ۵.۲ لنگرهای صریح اطمینان را هم‌راستا با بخش ۱۷.۱۰.۲ تعریف می‌کند. همین اصلاحات در نسخه فارسی اعمال شده‌اند.
- A18 اکنون REV-01 تا REV-14 را به بخش‌های اصلاحی نسخه ۰.۳.۰ نگاشت می‌کند. Gate بعدی، بازبینی موردبه‌مورد مالک و چالش تخصصی در موارد لازم است؛ تضمین مستقل فعالیتی جدا و وابسته به ریسک/نوع ادعاست و مترادف بازبینی مالک نیست.
- دفتر بازبینی مالک اکنون برای REV-01 تا REV-14 ستون جداگانه وضعیت اجرای مستندی دارد. تغییرات اعمال‌شده از Disposition مالک جدا ثبت شده‌اند؛ آزمون‌های پذیرش ماهوی و تمام Dispositionهای مالک همچنان در انتظارند. REV-11 به‌عنوان مورد غیرماهوی ثبت شده و مثال معادل‌بودن فرمول حفظ شده است.
- این‌ها صرفاً اصلاحات سازگاری مستندات‌اند. هیچ وزن Provider، فناوری، کنترل امنیتی، ریسک باقیمانده، تأمین‌کننده، حوزه قضایی، خرید، Production، فعالیت مالی، Merge یا Deploy تصویب نشده است.


## LOT-EVAL-RDM-001 — مدل مرجع تصمیم‌گیری قطعی (۲۰۲۶-۱۱-۲۸)

- Harness مرجع Python ایزوله و صرفاً مبتنی بر کتابخانه استاندارد در مسیر `tools/lot_eval_rdm.py` اضافه شد؛ این کد از محصول Import نمی‌شود و فقط Fixtureهای ساختگیِ درون‌فایل را به‌کار می‌گیرد.
- اجرای محلی با Python نسخه ۳.۱۳.۵: دستور `python tools/lot_eval_rdm.py` — تعداد ۲۱ از ۲۱ بردار AVT با PASS؛ هر ۱۰ جهش مشخصات کشته شدند؛ ۲۱۰ ارزیابی جهش/بردار؛ بدون جهش باقی‌مانده. این نتیجه تزریق خطای سطح مشخصات به‌دست نویسنده است، نه امتیاز ابزار مستقل Mutation Testing یا تضمین مستقل.
- Harness به خط مبنای ثابت LOT-EVAL-001 نسخه ۰.۳.۰ / LOT-EVAL-AVT-001 نسخه ۰.۲.۰ در Commit `e7aed0892a0de212fc3fd7603a6976eee503a76f` نگاشت شده است. Documentation Governance شماره ۱۱۳۳ (شناسه `46118746808`) روی Head دقیق پیاده‌سازی `863fe0eb8f27e93e68dcd0f6275aaef377cf3c32` موفق شد: ۶۲ جفت دوزبانه/۱۶۰ Link محلی بررسی و گام Harness مرجع با موفقیت اجرا شد. هر Commit بعدی نیازمند اجرای تازه روی Head دقیق خودش است.
- توقف تفسیری: بخش ۸.۳ برخورد تجمیعی با NS غیرمهم را به‌طور کامل مشخص نمی‌کند؛ مدل بدون مرجع اختیار موقتِ جداگانه، به‌جای اختراع قاعده، خروجی UNRESOLVED می‌دهد. اختیار/بااهمیت‌بودن ورودی ساختگی‌اند و تأیید واقعی را اعتبارسنجی نمی‌کنند.
- پوشش به AVT-01 تا AVT-21 محدود است. اطمینان، TCO، تضمین رسمی، صلاحیت حقوقی و Disposition واقعی مالک خودکار نمی‌شوند. هیچ بازبین مستقلی Oracleها را مستقلاً بازسازی نکرده است.
- LOT-EVAL-001 همچنان PROPOSED و REV-01 تا REV-14 همچنان PENDING هستند. هیچ Candidate، خرید، اتصال Provider، داده Production، فعالیت مالی، Merge یا Deploy مجاز نشده است.
