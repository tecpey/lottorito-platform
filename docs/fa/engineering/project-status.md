# وضعیت واقعی پروژه و نقطه ادامه کار

**شناسه:** LOT-OPS-001 | **نسخه:** ۱.۲۵.۰ | **وضعیت:** خط مبنای تأییدشده و در حال نگهداری | **بازبینی:** ۲۰۲۶-۱۱-۲۴

## وضعیت تأییدشده مخزن
- مخزن tecpey/lottorito-platform؛ شاخه پیش‌فرض main؛ سطح دسترسی Public طبق تصمیم مالک.
- در تاریخ ۲۰۲۶-۱۱-۲۴، PRهای ۱۹ تا ۲۵، ۲۷ تا ۳۶، ۳۹، ۴۲، ۴۵ و ۴۶ به‌صورت تغییرات Open/Draft هستند. PR شماره ۴۵ نسخه بازسازی‌شده آزمایش Credential/Pool هر Tenant بر مبنای آخرین Head مربوط به PR شماره ۴۲ است؛ PR شماره ۴۳ بدون Merge بسته شده است. PR شماره ۴۲ برای جداسازی Data Planeهای ثانویه روی PR شماره ۳۹ قرار دارد؛ PR شماره ۳۹ برای Support روی PR شماره ۳۶ قرار دارد. PR شماره ۳۷ پس از انشعاب تاریخچه شاخه Support به‌عنوان مورد جایگزین‌شده بسته شد؛ PR شماره ۳۹ از آخرین Head مربوط به PR شماره ۳۶ دوباره ساخته شده و آزمایش فعال Support است. زنجیره مستندات/محصول موردنظر چنین است: ۱۹ ← ۲۰ ← ۲۱ ← ۲۲ ← ۲۳ ← ۲۴ ← ۲۵ ← ۲۷ ← ۲۸ ← ۲۹ ← ۳۰ ← ۳۱ ← ۳۲ ← ۳۳ ← ۳۴ ← ۳۵ ← ۳۶ ← ۳۹ ← ۴۲ ← ۴۵ ← ۴۶. PR شماره ۲۶ یک شاخه مستقل Open/Draft بر مبنای main است و با فایل‌های حاکمیتی مشترک هم‌پوشانی دارد؛ پیش از ادغام باید با زنجیره اصلی تطبیق داده شود. هیچ‌یک از PRهای این زنجیره Merge نشده‌اند.
- PR شماره ۲۵ شش Commit از آخرین Head مربوط به PR شماره ۲۴ عقب است؛ PRهای ۲۷ تا ۳۵ این ancestry قدیمی را به ارث می‌برند. PR شماره ۲۸ پیشنهادهای B2B2C، IAM و داشبورد، PR شماره ۲۹ LOT-WALLET-001، PR شماره ۳۰ LOT-PAYMENT-001، PR شماره ۳۱ LOT-PAYOUT-001، PR شماره ۳۲ LOT-B2C-PRD-001 و PR شماره ۳۳ LOT-API-PLATFORM-001 را بر مبنای زنجیره قبلی اضافه می‌کنند؛ PR شماره ۳۴ LOT-AFFILIATE-API-001 را بر مبنای #۳۳ و PR شماره ۳۵ LOT-CUSTOMER-PILOT-001 را بر مبنای #۳۴ اضافه می‌کند؛ PR شماره ۳۵ محدوده مشتری RaidenBet را به دو ماژول Advanced Affiliate & Agent و Live Chat Widget محدود می‌کند. پیش از بررسی Merge، زنجیره بالادستی باید همگام و CI دوباره اجرا شود. این Snapshot تاریخ‌دار است؛ Metadata زنده PR مرجع نهایی است.
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
- **LOT-CUSTOMER-PILOT-001:** محدوده مشتری اولیه RaidenBet به دستور مالک و برنامه پیشنهادی تحویل/پذیرش Advanced Affiliate & Agent به‌همراه Live Chat Widget؛ بازبینی مشتری پیش از اتصال کنترل‌شده API را تعریف می‌کند و قرارداد، API مشتری، Sandbox، پیاده‌سازی یا تأیید Production را اثبات نمی‌کند.
- **LOT-AFFILIATE-API-001:** فهرست قابلیت API پیشنهادی و مستقل از Provider برای Program، Membership، سلسله‌مراتب، Campaign، Referral Link، Attribution، دریافت Event شریک، Statement کمیسیون و گزارش Affiliate/Agent. تغییرات مالی در دامنه Wallet/Ledger/Payment/Payout باقی می‌مانند؛ هیچ شریک، فرمول تجاری، Endpoint یا اتصالی تصویب نشده است.

## محدوده مشتری اولیه به دستور مالک

- **RaidenBet مشتری اولیه** دقیقاً برای دو ماژول Advanced Affiliate & Agent و Live Chat Widget است. این توضیح مالک، عبارت تاریخی LDR-014 را که RaidenBet را صرفاً شریک احتمالی Affiliate می‌دانست، جایگزین می‌کند؛ مرجع فعلی LDR-045 است.
- مشتری فقط دو ماژول تأییدشده را دریافت می‌کند، نه کل پلتفرم Lottorito یا Lottery/Casino/Sportsbook/E-Gaming. اسکریپت موجود مشتری تحت کنترل خود او باقی می‌ماند و قرار است پس از بازبینی و تأیید صریح قرارداد تحویل توسط تیم فنی/پشتیبانی، از طریق API نسخه‌بندی‌شده و کنترل‌شده متصل شود.
- LOT-CUSTOMER-PILOT-001 محدوده مشتری و برنامه پیشنهادی بازبینی، بسته تحویل API/Widget، Sandbox، پذیرش و دروازه Production را ثبت می‌کند. API مشتری، شخصیت حقوقی، حوزه قضایی، Sandbox، Credential، قرارداد تجاری و سازگاری فنی هنوز راستی‌آزمایی نشده‌اند. دسترسی به دیتابیس/کد منبع فرض نشده است.
- این مورد دستور مالک و خط مبنای برنامه‌ریزی است؛ نه مدرک شرایط تجاری امضاشده، پیاده‌سازی، پذیرش مشتری یا مجوز Production.

## آزمایش اجرایی جاری
- PR شماره ۳۶، [آزمایش جداسازی Tenant در P-01](https://github.com/tecpey/lottorito-platform/pull/36)، یک Draft باز است که مستقیماً روی PR شماره ۳۵ قرار گرفته است. شاخه: spike/p01-tenant-isolation. برای SHA معتبر، Metadata زنده PR را دوباره بخوانید.
- یک برش آزمایشی و دورریختنی با HTTP در Node.js و PostgreSQL RLS وجود دارد که شامل Tenantهای ساختگی، Principal آزمایشی با Context سمت سرور، Context تراکنش‌محور، Role اجرایی با حداقل مجوز و تست‌های یکپارچه‌سازی برای جعل Tenant، دسترسی بین Tenantها و استفاده مجدد از Connection Pool است.
- نسخه‌های کاندید آزمایش Node.js 26.13.0، PostgreSQL 18.7 و node-postgres 8.23.1 هستند؛ این نسخه‌ها ورودی آزمایش‌اند و تصمیم فناوری پذیرفته‌شده نیستند.
- اجرای GitHub Actions با شناسه [45412556456](https://github.com/tecpey/lottorito-platform/actions/runs/45412556456) روی Node.js 26.13.0 و PostgreSQL 18.7، با Lockfile ثبت‌شده و Actionهای Pin‌شده با SHA، موفق شد: ۲۰ تست موفق، صفر شکست و صفر تست Skip‌شده روی Head کد `f53caa4e801c9eeed94dfe706e03c6dfcf02a660`. علاوه بر تست‌های HTTP/RLS و Async Outbox/Dispatcher/Envelope امضاشده Ed25519، این برش Roleهای LOGIN مستقل Tenant متصل به `session_user` دیتابیس را برای Records، Membership و Jobs مقایسه می‌کند؛ جعل GUC، SET ROLE/SET SESSION AUTHORIZATION بین Tenantها، خواندن Identity Map و Write بین Tenantها در این مدل رد می‌شود. مالک NOLOGIN/غیر BYPASSRLS تابع SECURITY DEFINER و search_path ثابت نیز با تلاش Shadow کردن Temporary Schema بررسی شده‌اند؛ یک تست دو اتصالی Deterministic نیز اثبات می‌کند لغو Membership پشت قفل `FOR SHARE` درخواست در حال اجرا منتظر می‌ماند. اجرای محلی در این محیط انجام نشده است. تست Red-Team محدودیت اعتماد GUC در Role مشترک را صریحاً تأیید می‌کند؛ Credential Broker و مقیاس‌پذیری Poolهای مستقل هنوز آزمایش نشده‌اند.
- وضعیت کلی P-01 همچنان جزئی/نامعین است: PR شماره ۳۹ یک برش ساختگی برای Grant پشتیبانی فقط‌خواندنی و Audit فقط‌افزودنی اضافه می‌کند. آخرین اجرای CI با شناسه [45418177150](https://github.com/tecpey/lottorito-platform/actions/runs/45418177150) روی Head با شناسه `d2e9fc81a17036e5d6e63c07ee1e64fa055a24eb`، ۲۶ تست موفق داشته و Subject/Tenant/Scope/Expiry/Revocation، ثبت Audit رد، مجوزهای Role، منع دسترسی به Payload و Serialization قفل ردیف Grant را بررسی می‌کند. Credential Broker امن و مقیاس Poolهای مستقل، آزمون Race در سطح Endpoint و تزریق خطا، حداقل‌سازی Metadata پشتیبانی، رفتار Provider واقعی برای Cache/Object/Search/Warehouse، Cache Invalidation/TTL، CDN/Signed URL، تحویل Export، Credential Broker عملیاتی و مقیاس Pool در سطح Fleet، Race/Failure Injection در سطح Endpoint، حداقل‌سازی Metadata پشتیبانی، رفتار Provider واقعی Cache/Object/Search/Warehouse، Cache Invalidation/TTL، CDN/Signed URL، تحویل Export، Credential Rotation، PgBouncer، سیاست TLS، بار، Failover و Recovery هنوز آزمایش نشده‌اند.

## موارد تأییدنشده
هیچ برنامه Production، Schema/Migration فیزیکی Production، اتصال API Provider، Certification سندباکس، Ledger عملیاتی، محاسبه کمیسیون، پرداخت، تست نفوذ یا Deploy عملیاتی تأیید نشده است. برش اجرایی موقت P-01 در PR شماره ۳۶، ۲۰ تست CI موفق داشته است. PR تکمیلی Support شماره ۳۹ در اجرای [45418177150](https://github.com/tecpey/lottorito-platform/actions/runs/45418177150) روی Head کد `d2e9fc81a17036e5d6e63c07ee1e64fa055a24eb` تعداد ۲۶ تست موفق داشته است. PR شماره ۴۲ برای Data Planeهای ثانویه در اجرای [45422429667](https://github.com/tecpey/lottorito-platform/actions/runs/45422429667) روی Head با شناسه `82fda92768e2f57b987e5005d63fd56b3de10c91`، ۳۰ تست موفق، صفر شکست و صفر تست Skip‌شده داشته و قرارداد Cache/Object/Search و RLS گزارش‌گیری را بررسی می‌کند. اجرای Documentation Governance با شناسه [45422429766](https://github.com/tecpey/lottorito-platform/actions/runs/45422429766) نیز روی همین Head موفق بوده است. آزمایش تکمیلی Credential/Pool در PR شماره ۴۵ پس از بستن PR قدیمی شماره ۴۳ بدون Merge، بر مبنای آخرین Head مربوط به PR شماره ۴۲ بازسازی شد. اجرای Integration با شناسه [45424792886](https://github.com/tecpey/lottorito-platform/actions/runs/45424792886) روی Head کد `153fc8974c9c620acd8d509afdea0341669e5c` با ۴۰ تست موفق، صفر شکست و صفر Skip همراه بود؛ اجرای Documentation Governance با شناسه [45424793114](https://github.com/tecpey/lottorito-platform/actions/runs/45424793114) نیز موفق شد. PR همچنان Draft و Mergeنشده است. این‌ها آزمایش‌های ساختگی‌اند، نه نرم‌افزار Production؛ محدوده کامل P-01 همچنان جزئی/نامعین است. آزمایش ثبت Ledger در P-02 و PR شماره ۴۶ در اجرای [45466918625](https://github.com/tecpey/lottorito-platform/actions/runs/45466918625) روی Head کد `76d1f421ecdf8e921c7e8a116e2c23dcdaef4b7b` با ۲۵ تست موفق، صفر شکست و صفر Skip همراه بود؛ اجرای Documentation Governance با شناسه [45466918755](https://github.com/tecpey/lottorito-platform/actions/runs/45466918755) نیز موفق شد. Job مربوط به P-02 از PostgreSQL 18.7، Node.js 26.13.0 و `npm ci` با Lockfile ثبت‌شده استفاده کرد؛ Log اجرای CI موفقیت هر ۲۵ تست Integration نام‌گذاری‌شده را نشان می‌دهد. PR همچنان Draft، باز و Mergeنشده است. این برش ساختگی، Effect مالی تغییرناپذیر را از Aliasهای تغییرناپذیر Request Key جدا می‌کند، استفاده مجدد Alias پذیرفته‌شده برای Effect دیگر را رد می‌کند، effect_id را در Outbox منتشر می‌کند و همگرایی Duplicate هم‌زمان، Rollback محتوای ناسازگار، RLS و کنترل مالکیت/Search Path/مجوزهای SECURITY DEFINER را آزمایش می‌کند. P-02 همچنان فقط Invariantهای ثبت Journal ساختگی را آزمایش می‌کند و سیاست کمیسیون/NGR، Wallet، Reversal، پرداخت، تبدیل FX، تطبیق بیرونی یا صحت حسابداری Production را اثبات نمی‌کند. Documentation Governance CI وجود دارد و روی برخی Headهای PR کنترل ساختاری موفق داشته است؛ این کنترل هم‌ارزی معنایی فارسی/انگلیسی، رفتار Runtime، صلاحیت قانونی یا امنیت را اثبات نمی‌کند.

PR شماره ۵۰ مربوط به تحویل Outbox در P-03، به‌صورت Draft و روی PR شماره ۴۶ مربوط به P-02 قرار دارد. برش ساختگی فعلی، رویداد منبع تغییرناپذیر را از وضعیت تحویل تغییرپذیر جدا می‌کند؛ از توابع SECURITY DEFINER محدود به Tenant و FORCE RLS استفاده می‌کند؛ Claim را با SKIP LOCKED و Lease Token منقضی‌شونده انجام می‌دهد؛ تأیید Worker قدیمی را Fence می‌کند؛ Retry محدود و Dead-letter دارد؛ و Inbox تغییرناپذیر Consumer را با Deduplication اتمیک اثر ساختگی به‌کار می‌گیرد. معنای تحویل عمداً At-least-once و پنجره Crash بین Publish و Ack است؛ هیچ ادعای Exactly-once یا دوام Broker واقعی مطرح نیست. اجرای Integration در P-03 با شناسه [45468686909](https://github.com/tecpey/lottorito-platform/actions/runs/45468686909) روی Head کد `a52e8c248e4a2dbc7e9e88eeb6f71b96ec3f8b02`، ۱۰ تست موفق، صفر شکست و صفر Skip داشت؛ اجرای Documentation Governance با شناسه [45468686901](https://github.com/tecpey/lottorito-platform/actions/runs/45468686901) نیز روی همان Head موفق شد. Workflow از PostgreSQL 18.7، Node.js 26.13.0 و npm ci با Lockfile ثبت‌شده استفاده کرد. PR شماره ۵۰ همچنان Draft، باز و Mergeنشده است. Broker بیرونی، Provider، اختیار Relay سراسری بین Tenantها، Retention/Replay عملیاتی یا SLO Production تصویب نشده است.

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

## تصمیم‌های موردنیاز مالک
شخصیت حقوقی و مدل عملیاتی؛ حوزه قضایی اولیه؛ Provider و منبع حقیقت؛ اعتبار نمونه ۱۰۰ دلاری Agent؛ کمیسیون/NGR و پیشرفت شبکه؛ نگاشت حساب و تأمین/نگهداری وجه؛ مجوز پرداخت؛ انتخاب فناوری و استقرار؛ محل و مدت نگهداری داده؛ فایل رسمی لوگو.

## انضباط شواهد
این سند خلاصه بازبینی مخزن است، نه ممیزی بیرونی. پیش از اتکا به Head SHA یا وضعیت CI، Metadata و وضعیت Commit جاری را دوباره دریافت کن.


## ادامه P-03D — ۲۰۲۶-۱۱-۲۵

- سند LOT-PROT-001، آزمایش P-03D را قدم بعدی الزامی معرفی می‌کند: Provider Inbox به Posting Idempotent در P-02 و Outbox در P-03C. تا زمانی که این شکاف یکپارچه‌سازی P-03 باقی است، P-09 جدیدی اختراع نمی‌شود.
- PR شماره ۴۱ یک Fixture قدیمی Provider Event است که بر مبنای Base مربوط به P-02 با SHA `90cc45464c25c325befd35bd7af1c8a16c1f78d3` ساخته شده؛ خط فعلی P-02، Head مربوط به PR شماره ۴۶ یعنی `76d1f421ecdf8e921c7e8a116e2c23dcdaef4b7b` است و سپس PR شماره ۵۰ با Head `45b37700cb2b9ad633158ba8d5f00b8c7f0553d5` قرار دارد. PR شماره ۴۱ فقط ورودی تحقیق است؛ مدل Tenant/Product مبتنی بر GUC مشترک آن را بدون بازطراحی به مدل هویت Session فعلی Cherry-pick نکن.
- PR شماره ۶۰ برای P-03C بر مبنای Head مربوط به PR شماره ۵۰ یعنی `45b37700cb2b9ad633158ba8d5f00b8c7f0553d5` قرار دارد؛ اجرای Integration با شناسه [45576594884](https://github.com/tecpey/lottorito-platform/actions/runs/45576594884) تعداد ۱۵ تست موفق داشته و Documentation Governance با شناسه [45576594868](https://github.com/tecpey/lottorito-platform/actions/runs/45576594868) موفق شده است. PR همچنان Draft، باز و Mergeنشده است.
- PR شماره ۵۱ برای P-04 یک شاخه هم‌سطح PR شماره ۶۰ و روی همان Base مربوط به P-03 است، نه فرزند P-03C. بنابراین زنجیره P-04 تا P-08 بعداً به تطبیق Ancestry و اجرای مجدد تست نیاز دارد؛ فرض نکن CI مربوط به P-08 شامل P-03C است.
- شاخه `spike/p03d-provider-ledger-integration` بر مبنای Head مربوط به P-03C یعنی `32b34f4c7c67b12874cdf6a14a2788d9a2f4c6dc` ساخته شده است. دریافت امضاشده Provider Inbox، بررسی Installation مورداعتماد در برابر هویت دیتابیس، رکوردهای محصول‌محور در P-02/P-03C، Posting مالی و تکمیل Inbox و ایجاد Delivery State در یک تراکنش، Retry/Fencing/Quarantine و Reconciliation را اضافه می‌کند. پذیرش ساختگی روی Head مربوط به PR شماره ۶۱ با SHA `40d002a2af5875a6ead178604b90dc92aa678dc5` تأیید شد: P-02 برابر ۲۵/۲۵، P-03C برابر ۱۵/۱۵، P-03D برابر ۱۹/۱۹ و Documentation Governance همگی موفق بوده‌اند (اجراهای 45607187120، 45607186885 و 45607186745).
- برخی Constraintهای یکتایی P-02 همچنان Tenant-wide و محافظه‌کارانه/Fail-closed هستند، هرچند Product Attribution و RLS اضافه شده‌اند. معنای کامل کلیدهای مرکب و مستقل Product نیازمند بازبینی است. هیچ تصمیمی درباره Commission/NGR، Provider واقعی، Policy حساب، شخصیت حقوقی، Payout یا Schema عملیاتی گرفته نشده است.
- پذیرش ساختگی P-03D روی Head ذکرشده کامل است؛ اگر هر Commit بعدی کد یا مستندات را تغییر دهد، اعتبارسنجی باید دوباره اجرا شود. قدم بعدی: تطبیق Ancestry مربوط به PR شماره ۵۱ در P-04 و زنجیره P-04 تا P-08 با PR شماره ۶۰ در P-03C؛ سپس طراحی دروازه‌های Regression برای P-04 بدون Merge هیچ‌یک از شاخه‌ها. PR شماره ۶۱ همچنان Draft، باز و وابسته به PR شماره ۶۰ است. هیچ Merge، تغییر main یا Deploy مجاز نیست.


## تطبیق Ancestry مربوط به P-04 — ۲۰۲۶-۱۱-۲۵

- Head مربوط به PR شماره ۵۱ در P-04 یعنی `d143c213a4c3cedcf64fcbe2edb17f21ad2b3a85` بر مبنای Head مربوط به PR شماره ۵۰ در P-03 یعنی `45b37700cb2b9ad633158ba8d5f00b8c7f0553d5` است. PR شماره ۶۰ در P-03C و PR شماره ۶۱ در P-03D فرزندان جداگانه همان Base در P-03 هستند. بنابراین زنجیره اصلی P-04 تا P-08 پل P-03C/P-03D را در خود ندارد.
- پذیرش پیاده‌سازی P-03D در PR شماره ۶۱ روی Head کد `40d002a2af5875a6ead178604b90dc92aa678dc5` راستی‌آزمایی شد: P-02 برابر ۲۵/۲۵، P-03C برابر ۱۵/۱۵، P-03D برابر ۱۹/۱۹ و Documentation Governance موفق بوده‌اند. آخرین Head همگام‌شده با مستندات PR شماره ۶۱ برابر `11f2069b537d4cf74175fd7b628a331650c45f52` است.
- شاخه ادامه P-04 با نام `spike/p04-schema-evolution-p03d` از همان Head مربوط به PR شماره ۶۱ ایجاد شد. ده فایل اختصاصی Workflow، Prototype و گزارش دوزبانه P-04 منتقل شده‌اند؛ README، نقشه معماری و اسناد P-02/P-03D نیز بدون بازنویسی مستندات جدیدتر P-03D همگام شده‌اند.
- PR اصلی شماره ۵۱ به‌عنوان مرجع تاریخی بازبینی، باز و Draft باقی می‌ماند؛ نه Retarget شده و نه Merge. PR جایگزین P-04 و CI آن در انتظار ایجاد/اجرا هستند؛ تا زمانی که P-02، P-03C/P-03D، P-04 و Documentation Governance روی Head دقیق جدید موفق نشوند، P-04 روی زنجیره تطبیق‌یافته Verified تلقی نمی‌شود.
- پس از تأیید P-04، مراحل P-05A، P-05B، P-05C، P-06، P-07A، P-07B، P-07C و P-08 به‌ترتیب وابستگی روی زنجیره تطبیق‌یافته Replay شوند. محدودیت هر آزمایش حفظ و کل زنجیره Regression دوباره اجرا شود. هیچ Merge، تغییر main، Migration مخرب یا Deploy مجاز نیست.
