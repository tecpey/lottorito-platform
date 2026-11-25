# وضعیت واقعی پروژه و نقطه ادامه کار

**شناسه:** LOT-OPS-001 | **نسخه:** ۱.۴۲.۰ | **وضعیت:** خط مبنای تأییدشده و در حال نگهداری | **بازبینی:** ۲۰۲۶-۱۱-۲۵

## وضعیت تأییدشده مخزن

## اعتبارسنجی اولیه P-07B — ۲۰۲۶-۱۱-۲۵

- P-07B با PR شماره [۵۷](https://github.com/tecpey/lottorito-platform/pull/57) به‌صورت Draft باز است و روی P-07A PR شماره ۵۶ قرار دارد. Merge نشده است.
- Head دقیق اعتبارسنجی‌شده P-07B: `9c3bfee387c9f989a556da9cdce2a1616f31c382`.
- Integration مربوط به P-07B با شناسه [45570214926](https://github.com/tecpey/lottorito-platform/actions/runs/45570055150) روی Head دقیق PR موفق شد؛ اعتبارسنجی JSON Registry، بررسی Syntax پایتون و هر ۳۳ تست موفق بودند. اجرای Push با شناسه [45570037120](https://github.com/tecpey/lottorito-platform/actions/runs/45570037120) نیز موفق شد.
- Documentation Governance با شناسه [45570214958](https://github.com/tecpey/lottorito-platform/actions/runs/45570055148) روی همان Head PR موفق شد.
- Fixture مالکیت و مجوزهای سطح عملیات برای قابلیت‌های مشترک Identity، Tenant، Finance، Notifications و Audit را اثبات می‌کند؛ همچنین جداسازی منابع متعلق به محصول، بررسی مستقل Service-to-Tenant Scope و Product Entitlement، تصمیم‌های Deny-by-Default/Fail-Closed، تطبیق هویت Producer و Source، قرارداد صریح Consumer، بررسی پروفایل CloudEvents و dataschema، طبقه‌بندی رویداد، رد کلید/Extension حساس و حذف Credential از Audit را آزمایش می‌کند.
- رویداد بین Affiliate و Lottery صرفاً آزمایشی و ساختگی است. هیچ یکپارچگی Production تصویب نشده است. Tokenهای ثابت، Registryهای JSON، توابع محلی PDP/PEP و فهرست Audit در حافظه کنترل Production نیستند.
- هویت رمزنگاری‌شده، OAuth/OIDC، پروتکل AuthZEN، Event Broker، تضمین تحویل/Replay، دیتابیس/RLS، جداسازی واقعی Tenant، Audit تغییرناپذیر، Merge یا Deploy اثبات/انجام نشده‌اند.

## اعتبارسنجی اولیه P-07A — ۲۰۲۶-۱۱-۲۵

- P-07A با PR شماره [۵۶](https://github.com/tecpey/lottorito-platform/pull/56) به‌صورت Draft باز است و روی P-06 PR شماره ۵۵ قرار دارد. Merge نشده است. PR شماره ۵۵ و زنجیره قبلی P-04/P-05 نیز Merge نشده‌اند.
- Head دقیق اعتبارسنجی‌شده P-07A: `6e57296b88a1394d25d282f50ad0f02c410811fe`.
- Integration مربوط به P-07A با شناسه [45569492121](https://github.com/tecpey/lottorito-platform/actions/runs/45569336694) روی همین Head دقیق PR موفق شد. بررسی Syntax پایتون موفق بود و هر ۱۱ تست قبول شدند.
- Documentation Governance با شناسه [45569492139](https://github.com/tecpey/lottorito-platform/actions/runs/45569336699) نیز روی همان Head PR موفق شد.
- Fixture ساختگی، Artifactهای Affiliate & Agent و Lottery را مستقل Build کرد و در فرایندهای تازه اجرا کرد. هر Artifact فقط شامل Entry Point محصول منتخب، Port ساختگی پلتفرم مشترک، Manifest و Runner بود. تست‌های منفی Import مستقیم، Package-qualified، نسبی و Dynamic محصول خواهر را رد کردند؛ Manifest وابستگی محصولی را رد کرد؛ پوشه خروجی قدیمی/غیرخالی رد شد؛ انتساب Audit ساختگی در محدوده محصول باقی ماند.
- این نتیجه فقط ترکیب، Build و Runtime در Fixture مربوط به P-07A را اثبات می‌کند. مسیرهای واقعی Referral/Commission در Affiliate، جریان‌های Ticket/Draw/Prize در Lottery، مجوزدهی قابلیت‌های مشترک، Tenant RLS، Event Contract، غیرفعال‌سازی محصول، Migration/Deployment مستقل یا آمادگی Production اثبات نشده‌اند. Portهای هویت/Tenant/Audit مشترک، Stub ساختگی هستند.
- P-07 اکنون صریحاً به P-07A (جداسازی محصول)، P-07B (پلتفرم مشترک و مرزهای اعتماد) و P-07C (چرخه عمر مستقل) تقسیم شده است. P-07B و P-07C هنوز پیاده‌سازی نشده‌اند.
- هیچ Merge، Deploy، داده Production، Credential واقعی یا وجه واقعی استفاده نشد. هیچ معماری Production یا توپولوژی Microservice/Database تصویب نشده است.

## به‌روزرسانی نهایی اعتبارسنجی P-06 — ۲۰۲۶-۱۱-۲۵

- P-06 PR شماره ۵۵ همچنان باز، Draft و Mergeنشده است و روی P-05C PR شماره ۵۴ قرار دارد. PRهای P-05C شماره ۵۴، P-05B شماره ۵۳، P-05A شماره ۵۲ و P-04 شماره ۵۱ نیز باز، Draft و Mergeنشده هستند.
- Integration مربوط به P-06 با شناسه [45535315659](https://github.com/tecpey/lottorito-platform/actions/runs/45535315659) و Documentation Governance با شناسه [45535315503](https://github.com/tecpey/lottorito-platform/actions/runs/45535315503) روی Head PR با شناسه 9f30a2966ce77aca8a7df6acf8e803733bd723dd موفق شدند.
- اجرا یک Journal متوازن واقعی و ساختگی P-02 ثبت و آن را از طریق نه Span از Ingress شریک تا Reconciliation متصل کرد. ۵۰۰ ارجاع یکتای Tenant ساختگی تولید شد، در حالی که فقط چهار Metric Series محدود باقی ماند.
- نبود Secret/PII Canary، فیلتر Baggage حساس، نرمال‌سازی Event Name حاوی CR/LF، RLS مربوط به Tenant، دسترسی ممیزی‌شده به Mapping Forensic، Least Privilege، Audit فقط‌افزودنی، Cardinality محدود Metric و Assertionهای Owner/Severity/Runbook مربوط به Alert همگی موفق شدند.
- یک Assertion اولیه Harness خروجی Boolean متنی PostgreSQL یعنی false را با شکل نمایشی psql یعنی f مقایسه می‌کرد؛ مقایسه اصلاح شد و Integration نهایی PR موفق شد.
- این نتیجه همچنان Fixture سیاست/Schema است، نه اتصال سرتاسری OpenTelemetry SDK/Collector به برنامه یا مجوزدهی Telemetry در Production. Retention، Encryption، Residency، Sampling، تحویل Alert، تصویب حقوقی/حریم خصوصی یا آمادگی Production اثبات نشده‌اند. Telemetry دفترکل نیست.
- هیچ Merge، Deploy، داده Production، Credential زنده یا وجه واقعی استفاده نشد.



## آخرین به‌روزرسانی نقطه ادامه — ۲۰۲۶-۱۱-۲۵ (P-06)

- P-06 در PR شماره ۵۵ به‌صورت Draft و روی P-05C PR شماره ۵۴ Stacked شده است. باز و Mergeنشده است. PRهای P-05C شماره ۵۴، P-05B شماره ۵۳، P-05A شماره ۵۲ و P-04 شماره ۵۱ نیز باز، Draft و Mergeنشده هستند.
- P-06 از Schema موجود دفترکل P-02 استفاده می‌کند و یک Journal ساختگی واقعی و متوازن را با Role اجرایی Tenant A ثبت می‌کند. نه Span مرتبط و سازگار با W3C Trace Context، Ingress شریک، احراز اصالت، Inbox، Attribution، کمیسیون، Outbox، Worker، Ledger و Reconciliation را به هم متصل می‌کنند.
- این آزمایش ارجاع‌های مبهم HMAC، RLS محدود به Tenant برای Span/Log، دسترسی Forensic ممیزی‌شده به Mapping خام، Privileged Audit فقط‌افزودنی، اسکن Secret/PII Canary، خنثی‌سازی Log Injection از نوع CR/LF، رد Baggage حساس، Metric محدود روی ۵۰۰ Tenant ساختگی و بررسی Owner/Severity/Runbook برای Alert را اضافه می‌کند.
- CI اولیه P-06 یک اشکال Assertion در Harness را آشکار کرد: خروجی تبدیل Boolean به Text در PostgreSQL برابر "false" است، نه شکل نمایشی psql یعنی "f". Assertion اصلاح شد. Integration و Documentation Governance روی Head نهایی مستندات باید پیش از بستن فاز موفق شوند.
- Harness، OpenTelemetry SDK/Collector را متصل نمی‌کند و Retention، Encryption، Residency، Sampling، تحویل Alert، انطباق حقوقی/حریم خصوصی یا مجوزدهی Production را اثبات نمی‌کند. Telemetry دفترکل نیست.
- هیچ داده Production، Credential واقعی، وجه واقعی، Merge یا Deploy استفاده نمی‌شود. هیچ Instrumentation یا فروشنده Production تصویب نشده است.



## به‌روزرسانی نهایی اعتبارسنجی P-05C — ۲۰۲۶-۱۱-۲۵

- P-05C PR شماره ۵۴ همچنان باز، Draft و Mergeنشده است و روی P-05B PR شماره ۵۳ قرار دارد. PRهای P-05B شماره ۵۳، P-05A شماره ۵۲ و P-04 شماره ۵۱ نیز باز، Draft و Mergeنشده هستند.
- Integration مربوط به P-05C با شناسه [45533992674](https://github.com/tecpey/lottorito-platform/actions/runs/45533992674)، Integration بازگشتی P-05B با شناسه [45533992779](https://github.com/tecpey/lottorito-platform/actions/runs/45533992779) و Documentation Governance با شناسه [45533992863](https://github.com/tecpey/lottorito-platform/actions/runs/45533992863) روی Head PR با شناسه 194c565c1471474a1d908efb3dfda89035d9d4cc موفق شدند.
- P-05C دو Timeline واقعاً واگرا را اثبات کرد. pg_rewind در Rejoin پس از Failover، ۳۵ مگابایت و در Failback کنترل‌شده، ۶۷ مگابایت کپی کرد. هر دو Tail ساختگیِ عمداً Replicateنشده پس از Promotion گره دریافت‌کننده غایب بودند؛ Epoch نهایی شماره ۴ و Active Writer برابر Node A روی هر دو گره تأیید شد.
- P-05C همچنان Fencing در Production، رفتار Quorum، ایمنی در Network Partition، Watchdog، Failover منطقه‌ای یا RPO/RTO را اثبات نمی‌کند. توقف فرایند، شبیه‌سازی Local CI و مرجع Epoch/Lease یک ردیف دیتابیس Replicateشده است، نه DCS مستقل مبتنی بر Consensus. RPO/RTO همچنان TBD هستند.
- هیچ Merge، Deploy، داده Production، Credential زنده یا وجه واقعی استفاده نشد. PRها تا تأیید صریح مالک برای اقدام بعدی Draft باقی می‌مانند.



## آخرین به‌روزرسانی نقطه ادامه — ۲۰۲۶-۱۱-۲۵ (اجرای P-05C)

- P-05C همچنان PR شماره ۵۴، باز و Draft است و روی P-05B PR شماره ۵۳ قرار دارد؛ Merge نشده است. PR شماره ۵۳ روی شماره ۵۲ و PR شماره ۵۲ روی شماره ۵۱ Stacked شده‌اند. هیچ‌یک از PRهای این زنجیره بازیابی Merge نشده‌اند.
- Integration اجرایی P-05C در اجرای شاخه با شناسه [45533778752](https://github.com/tecpey/lottorito-platform/actions/runs/45533778752) روی Head کد اجرایی 4884a3c38d2da8ea9ab9961dc095eb0ddd469f4d موفق شد.
- آزمایش دو Cluster PostgreSQL 18.7، Physical Streaming Replication، رد Promotion در زمان فعال بودن Primary قدیمی، Process Fencing محلی، Epoch از ۱ به ۲، رد Writer قدیمی، رد Lease منقضی و Compare-and-Swap هم‌زمان Epoch شماره ۳ با دقیقاً یک برنده را اجرا کرد.
- pg_rewind واقعی اول ۳۵ مگابایت کپی کرد و Primary قبلی را به‌عنوان Standby فقط‌خواندنی برگرداند؛ Tail اول که عمداً Replicate نشده بود غایب بود.
- Failback کنترل‌شده یک Tail ساختگی دوم و Replicateنشده ایجاد کرد، گره بازگشته را Promote کرد و pg_rewind واقعی دوم با کپی ۶۷ مگابایت انجام شد. Tail دوم غایب، Marker مربوط به Failback حاضر و Epoch شماره ۴/Active Writer برابر Node A روی هر دو گره تأیید شد.
- Integration روی Head نهایی PR و Documentation Governance برای Commit نهایی مستندات هنوز باید بررسی شوند تا P-05C بسته اعلام شود. این آزمایش اثبات Fencing در Production نیست: توقف فرایند فقط شبیه‌سازی Local CI است و ردیف Epoch، DCS مستقل با Quorum نیست. هر دو Tail عمداً Replicateنشده، ریسک فقدان داده در Replication غیرهم‌زمان را نشان می‌دهند؛ RPO/RTO همچنان TBD هستند.
- هیچ داده Production، Credential واقعی، وجه واقعی، منبع Cloud، Merge یا Deploy استفاده نشد. هیچ فروشنده HA، توپولوژی یا آمادگی Production تصویب نشده است.



## آخرین به‌روزرسانی نقطه ادامه — ۲۰۲۶-۱۱-۲۵ (P-05C)

- P-05C با PR شماره ۵۴ به‌صورت Draft باز شده و روی P-05B PR شماره ۵۳ Stacked است. هنوز Merge نشده است. PRهای P-05B شماره ۵۳، P-05A شماره ۵۲ و P-04 شماره ۵۱ نیز باز، Draft و Mergeنشده هستند.
- آزمایش ساختگی جدید دو Cluster PostgreSQL 18.7 ایجاد می‌کند و Physical Streaming Replication، رد Promotion در زمان فعال بودن Primary قدیمی، Process Fencing محلی، رد نوشتن با Epoch/Lease نامعتبر، رقابت Compare-and-Swap برای Promotion، pg_rewind و Switchover کنترل‌شده به گره اولیه را می‌آزماید.
- Fixture عمداً یک Event ساختگی را هنگامی که Standby قطع است روی Primary قدیمی Commit می‌کند و سپس بدون آن Event Failover می‌کند. نبود آن Event مورد انتظار است و پنجره فقدان داده در Replication غیرهم‌زمان را نشان می‌دهد؛ این Assertion به معنی RPO صفر نیست.
- P-05C صریحاً اثبات Fencing در Production نیست: توقف فرایند فقط شبیه‌سازی Local CI است و وضعیت Epoch/Lease داده برنامه‌ای Replicateشده PostgreSQL است، نه DCS مستقل با Quorum. Primary قدیمیِ جداافتاده از شبکه، بدون Fencing خارجی همچنان ممکن است نوشتن محلی بپذیرد.
- اعتبارسنجی CI روی Head فعلی P-05C در انتظار است. هیچ داده Production، Credential زنده، وجه، منبع Cloud، Merge یا Deploy استفاده نمی‌شود. RPO/RTO همچنان TBD است.
- معیارهای Pass در P-05C شامل یک گره Writable، رد Writer قدیمی و Lease منقضی، دقیقاً یک Claimant برنده Epoch، Rewind/Join گره Primary قبلی، Failback کنترل‌شده و توپولوژی نهایی تک-Writer است. هر شکست پیش از اعلام تکمیل فاز، بررسی ریشه‌ای و اصلاح خواهد شد.



## آخرین به‌روزرسانی نقطه ادامه — ۲۰۲۶-۱۱-۲۵ (آزمون‌های منفی P-05A و P-05B)
- مسیر مثبت PITR اکنون پیش از Assertionهای مالی/RLS نوشتنی، تا بازگشت `pg_is_in_recovery()` به مقدار `false` صبر می‌کند. این اصلاح Race در CI را برطرف کرد: `pg_ctl` زمانی Ready شده بود که PostgreSQL هنوز فقط اتصال Read-only در حالت Recovery می‌پذیرفت؛ آن اجرای قبلی به‌عنوان موفقیت RLS شمرده نشد. آزمون WAL مفقود نیز هر راه‌اندازی Writable پیش از Target درخواستی را رد می‌کند.

- P-05B همچنان PR شماره ۵۳، باز، Draft و Mergeنشده است و روی PR شماره ۵۲ مربوط به P-05A قرار دارد؛ P-05A نیز روی PR شماره ۵۱ مربوط به P-04، باز، Draft و Mergeنشده است. Head اعتبارسنجی‌شده کد اجرایی آزمون‌های بازیابی ترکیبی 146a9bc635e3b03db568c423fb0958b62bc31c7b است. پیش از اتکا به Head فعلی مستندات، Metadata زنده PR را دوباره دریافت کن.
- Integration نهایی ترکیبی P-05A/P-05B با شناسه [45532825694](https://github.com/tecpey/lottorito-platform/actions/runs/45532825694) و Documentation Governance با شناسه [45532825916](https://github.com/tecpey/lottorito-platform/actions/runs/45532825916) روی Head کد اجرایی 146a9bc635e3b03db568c423fb0958b62bc31c7b موفق شدند.
- مسیر مثبت P-05A شامل Backup فیزیکی PostgreSQL 18.7، Verification و رد Manifest دست‌کاری‌شده، Restore Point نام‌گذاری‌شده، Assertionهای قبل/بعد Target، RLS مربوط به Tenant و تطبیق مالی Source/Ledger موفق شد.
- آزمون‌های منفی P-05A موفق شدند: Staging ناقص Restore توسط pg_verifybackup و راه‌اندازی PostgreSQL رد شد؛ Segment دقیق WAL هدف از کپی‌های ایزوله Archive و Base Backup حذف شد و سرور بازیابی در Target درخواستی Ready نشد. Segment مفقود در Recovery Log پیدا شد. این فقط آزمایش ساختگی Staging ناقص/WAL مفقود است، نه قطع فرایند Restore زنده Production.
- P-05B یک Object ساختگی ۴٬۴۰۹ بایتی را بازیابی کرد و SHA-256 برابر 2db4a9b021abba0ce01480ceda665284f023310ce909c0b0b9bcb084f771eaca را با مرجع PostgreSQL بازیابی‌شده تطبیق داد. نبود کلید، Ciphertext خراب و DEK بسته‌بندی‌شده خراب Fail-closed شدند. Replay مرتب، ادغام Duplicate، توقف در شکاف Sequence، Rollback/Retry اتمیک، دقیقاً دو اثر متوازن، No-op بودن Replay، تطبیق Source-to-Ledger و جداسازی Tenant موفق شدند.
- موارد اثبات‌نشده: KMS/HSM و Custody/Rotation کلید Production، بازیابی Object Store/Broker/Provider خارجی، نگهداری Immutable/Off-site، بازیابی منطقه‌ای، رفتار هم‌زمانی بالا، RPO/RTO و Failover/Writer Fencing/Failback در P-05C. RPO/RTO همچنان TBD است؛ هیچ داده Production، Secret زنده، وجه واقعی، Merge یا Deploy استفاده نشد.
- آزمایش پیشنهادی بعدی P-05C است: Writer Epoch Fencing صریح، انقضای Lease، رد Writer قدیمی، Fault Injection برای Split-brain، Promotion کنترل‌شده و Failback. این کار باید ساختگی بماند و بدون تأیید مالک/متخصص دامنه، RPO/RTO یا انتخاب فروشنده Production را تعریف نکند.
- این به‌روزرسانی در صورت تعارض، اظهارات قدیمی‌تر P-04/P-05 در ادامه را جایگزین می‌کند؛ موارد قدیمی‌تر Snapshot تاریخی باقی می‌مانند. بدون تأیید صریح مالک Merge یا Deploy انجام نشود.



## به‌روزرسانی نقطه ادامه — ۲۰۲۶-۱۱-۲۵

- PR شماره ۵۱ مربوط به P-04 همچنان باز، Draft و Mergeنشده است؛ Head آن d143c213a4c3cedcf64fcbe2edb17f21ad2b3a85 است. اجرای Integration با شناسه [45523886859](https://github.com/tecpey/lottorito-platform/actions/runs/45523886859) و Documentation Governance با شناسه [45523886920](https://github.com/tecpey/lottorito-platform/actions/runs/45523886920) موفق شدند.
- PR شماره ۵۲ مربوط به P-05A باز، Draft و Mergeنشده و روی P-04 قرار دارد؛ Head آن f2303a647aefd5bd8d48ba9d2e1830c881f60041 است. اجرای Integration با شناسه [45524388676](https://github.com/tecpey/lottorito-platform/actions/runs/45524388676) و Documentation Governance با شناسه [45524388734](https://github.com/tecpey/lottorito-platform/actions/runs/45524388734) موفق شدند.
- P-05A از Container دورریختنی PostgreSQL 18.7 استفاده کرد. تست Physical Base Backup، pg_verifybackup، رد Manifest دست‌کاری‌شده، WAL آرشیوشده، PITR نام‌گذاری‌شده با Assertion قبل/بعد از Target، جداسازی خواندن/نوشتن Tenant با RLS و تطبیق ساختگی Journal/Source را بررسی کرد. زمان مشاهده‌شده Backup به‌همراه Verification در CI برابر ۱۲ تا ۱۳ ثانیه (اجرای نهایی روی Head فعلی: ۱۳ ثانیه) و راه‌اندازی Restore برابر ۱ ثانیه بود؛ این‌ها هدف عملیاتی RPO/RTO نیستند.
- P-05A هنوز آزمون منفی WAL مفقود/Restore قطع‌شده، بازیابی بایت Object/کلید، Replay رویداد، بازیابی منطقه‌ای، Failover، Split-brain Fencing یا Failback را پوشش نمی‌دهد. P-05B/P-05C اجرا نشده‌اند. RPO/RTO همچنان TBD است؛ هیچ داده، Credential یا وجه Production استفاده و هیچ Deploy یا Merge انجام نشده است.
- موارد قدیمی‌تر وضعیت پروژه در ادامه، Snapshotهای تاریخی هستند؛ این به‌روزرسانی در صورت تعارض، وضعیت P-04/P-05 را جایگزین می‌کند. پیش از هر تصمیم Merge، Metadata زنده PR و Runها دوباره دریافت شود.

## به‌روزرسانی نقطه ادامه — ۲۰۲۶-۱۱-۲۵ (P-05B)

- PR شماره ۵۳ مربوط به P-05B باز، Draft و Mergeنشده است و به‌صورت Stacked روی PR شماره ۵۲ مربوط به P-05A قرار دارد. شاخه پس از Head آزموده‌شده کد اجرایی، Commitهای دوزبانه صرفاً مستنداتی و شواهدی بیشتری دارد؛ برای SHA فعلی، Metadata زنده PR/شاخه دریافت شود. Head اعتبارسنجی‌شده فعلی شاخه `e4820884194ecf1ab3acd539d77145904f14ab73` است؛ اجرای Integration ترکیبی P-05A و P-05B با شناسه [45526975173](https://github.com/tecpey/lottorito-platform/actions/runs/45526975173) و Documentation Governance با شناسه [45526975222](https://github.com/tecpey/lottorito-platform/actions/runs/45526975222) روی همان Head موفق شدند.
- آخرین اجرای موفق Integration ترکیبی P-05A/P-05B در Pull Request با شناسه [45526975173](https://github.com/tecpey/lottorito-platform/actions/runs/45526975173) و Documentation Governance با شناسه [45526975222](https://github.com/tecpey/lottorito-platform/actions/runs/45526975222) روی Head اعتبارسنجی‌شده شاخه ثبت شده است.
- Job یکپارچه CI دورریختنی ابتدا Base Backup، بررسی Manifest، PITR نام‌گذاری‌شده، RLS و Assertionهای مالی PostgreSQL 18.7 در P-05A را دوباره اجرا کرد و سپس P-05B را روی دیتابیس بازیابی‌شده اجرا کرد. بازیابی Object، ۴٬۴۰۹ بایت را برگرداند و SHA-256 برابر `2db4a9b021abba0ce01480ceda665284f023310ce909c0b0b9bcb084f771eaca` را با مرجع دیتابیس تطبیق داد. نبود کلید، Ciphertext خراب و DEK بسته‌بندی‌شده خراب رد شدند؛ جداسازی Object بین Tenantها موفق بود.
- Replay رویداد، Sequence شماره ۲ را پیش از ۱ تحویل داد، شکاف Sequence، تحویل تکراری Source Event و Economic Effect ID تکراری را آزمود، پیش از Commit خطای تراکنش تزریق کرد، Rollback کامل Journal/Inbox/Cursor را بررسی کرد، دو اثر متوازن را Retry و مجموع Source را با Cash در Ledger تطبیق داد، No-op بودن Replay بعدی را اثبات و خواندن/نوشتن Inbox بین Tenantها را رد کرد.
- آزمون‌های منفی WAL مفقود/Restore قطع‌شده در P-05A همچنان باز هستند. KMS/HSM زنده، Custody/Rotation کلید Production، بازیابی Object Store/Broker/Provider خارجی، بازیابی منطقه‌ای و Failover/Fencing/Failback در P-05C هنوز آزموده نشده‌اند. RPO/RTO همچنان TBD است. هیچ داده Production، Credential زنده، Provider، وجه واقعی، Merge یا Deploy استفاده نشد.
- این به‌روزرسانی در صورت تعارض، اظهارات قدیمی‌تر وضعیت P-05 در ادامه را جایگزین می‌کند؛ موارد قدیمی‌تر Snapshotهای تاریخی باقی می‌مانند. پیش از هر تصمیم Merge، Metadata زنده PR و Runها دوباره دریافت شود.

- مخزن tecpey/lottorito-platform؛ شاخه پیش‌فرض main؛ سطح دسترسی Public طبق تصمیم مالک.
- در تاریخ ۲۰۲۶-۱۱-۲۴، PRهای ۱۹ تا ۲۵، ۲۷ تا ۳۶، ۳۹، ۴۲، ۴۵ و ۴۶ به‌صورت تغییرات Open/Draft هستند. PR شماره ۴۵ نسخه بازسازی‌شده آزمایش Credential/Pool هر Tenant بر مبنای آخرین Head مربوط به PR شماره ۴۲ است؛ PR شماره ۴۳ بدون Merge بسته شده است. PR شماره ۴۲ برای جداسازی Data Planeهای ثانویه روی PR شماره ۳۹ قرار دارد؛ PR شماره ۳۹ برای Support روی PR شماره ۳۶ قرار دارد. PR شماره ۳۷ پس از انشعاب تاریخچه شاخه Support به‌عنوان مورد جایگزین‌شده بسته شد؛ PR شماره ۳۹ از آخرین Head مربوط به PR شماره ۳۶ دوباره ساخته شده و آزمایش فعال Support است. زنجیره مستندات/محصول موردنظر چنین است: ۱۹ ← ۲۰ ← ۲۱ ← ۲۲ ← ۲۳ ← ۲۴ ← ۲۵ ← ۲۷ ← ۲۸ ← ۲۹ ← ۳۰ ← ۳۱ ← ۳۲ ← ۳۳ ← ۳۴ ← ۳۵ ← ۳۶ ← ۳۹ ← ۴۲ ← ۴۵ ← ۴۶. PR شماره ۲۶ یک شاخه مستقل Open/Draft بر مبنای main است و با فایل‌های حاکمیتی مشترک هم‌پوشانی دارد؛ پیش از ادغام باید با زنجیره اصلی تطبیق داده شود. هیچ‌یک از PRهای این زنجیره Merge نشده‌اند.
- PR شماره ۲۵ شش Commit از آخرین Head مربوط به PR شماره ۲۴ عقب است؛ PRهای ۲۷ تا ۳۵ این ancestry قدیمی را به ارث می‌برند. PR شماره ۲۸ پیشنهادهای B2B2C، IAM و داشبورد، PR شماره ۲۹ LOT-WALLET-001، PR شماره ۳۰ LOT-PAYMENT-001، PR شماره ۳۱ LOT-PAYOUT-001، PR شماره ۳۲ LOT-B2C-PRD-001 و PR شماره ۳۳ LOT-API-PLATFORM-001 را بر مبنای زنجیره قبلی اضافه می‌کنند؛ PR شماره ۳۴ LOT-AFFILIATE-API-001 را بر مبنای #۳۳ و PR شماره ۳۵ LOT-CUSTOMER-PILOT-001 را بر مبنای #۳۴ اضافه می‌کند؛ PR شماره ۳۵ محدوده مشتری RaidenBet را به دو ماژول Advanced Affiliate & Agent و Live Chat Widget محدود می‌کند. پیش از بررسی Merge، زنجیره بالادستی باید همگام و CI دوباره اجرا شود. این Snapshot تاریخ‌دار است؛ Metadata زنده PR مرجع نهایی است.
- هیچ برنامه Runtime عملیاتی، Schema/Migration فیزیکی Production، اتصال Provider، Certification سندباکس، محاسبه کمیسیون، ثبت مالی/پرداخت با پول واقعی، تست نفوذ یا Deploy Production تأیید نشده است. P-01/P-02/P-03 آزمایش‌های ساختگی‌اند و فقط شواهد CI مشخص‌شده در ادامه را دارند؛ این‌ها قابلیت Production نیستند. P-04 تا زمان CI تأییدنشده باقی می‌ماند.
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


## به‌روزرسانی آخرین نقطه ادامه — ۲۰۲۶-۱۱-۲۴

زنجیره فنی تأییدشده فعلی P-01 PR شماره ۴۵ ← P-02 PR شماره ۴۶ ← P-03 PR شماره ۵۰ است. همه Draft، باز و Mergeنشده‌اند. اجرای P-01 با شناسه [45425284220](https://github.com/tecpey/lottorito-platform/actions/runs/45425284220) تعداد ۴۰ تست موفق؛ اجرای P-02 با شناسه [45466918625](https://github.com/tecpey/lottorito-platform/actions/runs/45466918625) تعداد ۲۵ تست موفق؛ و اجرای P-03 با شناسه [45469172124](https://github.com/tecpey/lottorito-platform/actions/runs/45469172124) تعداد ۱۰ تست موفق داشته است. Documentation Governance با شناسه [45469171778](https://github.com/tecpey/lottorito-platform/actions/runs/45469171778) روی Head مربوط به P-03 یعنی 45b37700cb2b9ad633158ba8d5f00b8c7f0553d5 موفق بوده است. P-04 به‌صورت PR شماره ۵۱ در وضعیت Draft روی شاخه spike/p04-schema-evolution و روی P-03 قرار دارد. اجرای Integration با شناسه [45471750215](https://github.com/tecpey/lottorito-platform/actions/runs/45471750215) روی Head کد 15c536e5be2f61b1805191f5977a46b17eaf1971، ۷ تست موفق، صفر شکست و صفر Skip داشته است؛ Documentation Governance با شناسه [45471750133](https://github.com/tecpey/lottorito-platform/actions/runs/45471750133) نیز روی همان Head موفق بوده است. PR همچنان باز، Mergeنشده و فقط آزمایش ساختگی است. بدون تأیید صریح مالک، Merge، Deploy، Migration مخرب Contract یا تغییر main انجام نشود. PRهای ۴۸ و ۴۹ همچنان کارهای جداگانه Export/Pool در P-01 هستند و پیش از ادغام به تطبیق Ancestry و CI نیاز دارند.
