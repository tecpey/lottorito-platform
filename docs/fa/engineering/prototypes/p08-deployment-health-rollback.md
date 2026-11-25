# P-08 — استقرار، دروازه سلامت و ایمنی Rollback

**شناسه سند:** LOT-PROT-P08-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیاده‌سازی کنترل استقرار ساختگی؛ شواهد CI در PR شماره ۵۹ پیگیری می‌شود؛ بدون تصویب پلتفرم استقرار یا انتشار Production

## ۱. پرسش تصمیم و مرزبندی

آیا Lottorito می‌تواند یک Artifact تغییرناپذیر را در محیط‌های غیرProduction و ایزوله ارتقا دهد، Secret را فقط در Runtime تزریق کند، هنگام شکست دروازه سلامت API یا Worker جلوی فعال‌سازی را بگیرد و در وضعیت‌های سازگار و ناسازگار Schema، بدون تغییر وضعیت مالی، به‌صورت ایمن بازیابی شود؟

P-08 هشتمین آزمایش الزامی در LOT-PROT-001 است. این مرحله پس از P-07C قرار می‌گیرد و از مفاهیم چرخه عمر محصول و سازگاری Schema آن استفاده می‌کند. این آزمایش عمداً Kubernetes، پلتفرم Managed Container، مدل VM، Registry، Secret Manager، Vendor استقرار یا توپولوژی زیرساخت را انتخاب نمی‌کند. مخزن فعلی برنامه Production یا Runtime قابل‌استقرار محصول ندارد؛ بنابراین Fixture اجرایی از یک Python zipapp مستقل از Vendor و مدل کنترل استقرار In-memory استفاده می‌کند.

فقط محیط‌های Fixture با نام‌های test و staging مجازند. محیط production در کد رد می‌شود. هیچ Endpoint عمومی، منبع Cloud، مشتری واقعی، Secret واقعی، تراکنش مالی یا داده Production استفاده نمی‌شود.

## ۲. طراحی مبتنی بر پژوهش

- **هویت Artifact:** یک Archive قطعی ساخته می‌شود، SHA-256 آن محاسبه و دقیقاً همان بایت‌ها ارتقا داده می‌شوند. تنظیمات محیط و Secretهای Runtime داخل Artifact قرار نمی‌گیرند.
- **Provenance:** یک رکورد جداگانه و هم‌شکل با in-toto Statement v1 و URI مربوط به Predicate استاندارد SLSA یعنی https://slsa.dev/provenance/v1 ساخته می‌شود. Digest واقعی Artifact در Subject ثبت می‌شود و Source Revision، هویت Builder، Build Type و Digest فایل Entry Point بررسی می‌شوند. مشخصات فعلی SLSA نسخه ۱.۲ است. این Fixture فقط سازگاری فیلدها را بررسی می‌کند؛ امضای رمزنگاری‌شده تولید یا اعتبارسنجی نمی‌کند، Builder قابل‌اعتماد را اثبات نمی‌کند و ادعای انطباق SLSA ندارد.
- **جداسازی Secret:** مرحله Build هیچ Secret برنامه‌ای دریافت نمی‌کند. یک Secret ساختگی فقط از طریق تابع تزریق مخصوص تست به فرایند Runtime جدید داده می‌شود و Process فرزند فقط Environment مجازشده را دریافت می‌کند، نه متغیرهای محیطی میزبان/CI را. Artifact، Provenance جداگانه و خروجی ثبت‌شده فرایند از نظر مقدار Canary یکتا بررسی می‌شوند. این روش Secret Scanner عمومی یا Secret Manager عملیاتی نیست.
- **معنای Health:** تکمیل Startup، زنده‌بودن Process، آمادگی API و آمادگی Worker سیگنال‌های جداگانه‌اند. Liveness به سلامت Process وابسته است، نه در دسترس‌بودن Dependencyهای پایین‌دستی؛ Readiness به تکمیل Startup و سلامت تمام Dependencyهای طبقه‌بندی‌شده به‌عنوان Critical نیاز دارد. فعال‌سازی Worker نیز دروازه Readiness مستقل دارد. مقادیر Health غیرBoolean به‌صورت Fail-closed رد می‌شوند و Drift در Pointer نسخه اجزای سرویس، انتقال چرخه عمر را متوقف می‌کند. این جداسازی از تبدیل قطعی یک اختلال Dependency به چرخه Restart غیرضروری جلوگیری می‌کند.
- **Rollout ایمن:** Candidate ابتدا برای API آماده می‌شود، درحالی‌که Traffic بسته است. پیش از فعال‌سازی Traffic API یا پردازش Worker، Worker نیز باید آماده باشد. اگر Gate مربوط به Worker پس از آماده‌سازی API شکست بخورد، Pointer ناقص API به وضعیت قبلی برگردانده می‌شود.
- **بازیابی آگاه از Schema:** فقط زمانی می‌توان Artifact قدیمی را Rollback کرد که قادر به خواندن Schema فعلی باشد. انتقال Schema فقط زمانی مجاز است که Release فعال و هر Rollback Target باقی‌مانده، هر دو از Schema مقصد پشتیبانی کنند. Contract تا زمانی که Rollback Target ناسازگار باقی مانده باشد متوقف می‌شود. خود بازنشستگی نیز به Approval متصل به Environment و Digest دقیق، تأییدکننده مستقل با نقش Release Approver و تأیید صریح Schema مقصد نیاز دارد. پس از بازنشستگی Target، Rollback ناسازگار رد می‌شود و باید از Forward Repair سازگار با Schema استفاده کرد.
- **تفکیک وظایف:** Approval به Digest دقیق Artifact و Environment متصل است. تأییدکننده باید نقش Release Approver داشته باشد و با درخواست‌دهنده و اجراکننده Deploy متفاوت باشد. ارتقا در Test/Staging قابل ممیزی است؛ Production مقصد مجاز نیست.

مدل Health از تفکیک Startup، Liveness و Readiness در Probeهای Kubernetes الهام می‌گیرد، بدون آنکه Kubernetes را به‌عنوان پلتفرم استقرار انتخاب کند. اصول Release و Rollback از راهنمای Release Engineering و Canary در Google SRE الهام گرفته شده‌اند. فیلدهای Provenance از مدل SLSA v1.2 و in-toto پیروی می‌کنند؛ Fixture دارای فیلدهای مشابه، Attestation امضاشده نیست.

## ۳. Fixture اجرایی

فایل‌های مسیر prototypes/p08-deployment شامل موارد زیرند:

- build.py: ساخت zipapp قطعی با Timestampهای نرمال‌شده، Entryهای مرتب و File Mode ثابت؛ از بازنویسی خروجی موجود جلوگیری می‌کند.
- fixtures/v1، fixtures/v2 و fixtures/v3: نسخه‌های ساختگی برنامه با محدوده‌های پشتیبانی متفاوت برای Schema.
- src/pipeline.py: بررسی Digest Artifact، بررسی Provenance جداگانه، تزریق Secret در Runtime، Snapshotهای Health، مخزن In-memory با کلید Digest، Policy تأیید، Promotion مرحله‌ای، انتقال Schema و Guardهای Rollback/Forward Repair.
- tests/test_p08.py: تست‌های مثبت و خصمانه با استفاده از Standard Library پایتون.
- .github/workflows/p08-deployment-health-rollback.yml: اعتبارسنجی CI با Checkout دارای SHA ثابت، مقایسه بایت‌های Build تکراری و اجرای تست‌ها.

Artifact Store و Deployment Controller، Test Doubleهای In-memory هستند. zipapp یک فایل واقعی تولیدشده با Digest قابل‌بررسی است، اما Container Image نیست و روی زیرساختی Deploy نمی‌شود.

## ۴. معیارهای پذیرش

| شناسه | نتیجه الزامی |
|---|---|
| P08-01 | ورودی یکسان Build باید Artifact بایت‌به‌بایت یکسان و SHA-256 یکسان تولید کند. |
| P08-02 | هر محتوای ازپیش‌موجود در پوشه خروجی Build باید به‌جای بازنویسی رد شود؛ دستکاری Artifact باید با بررسی Digest تشخیص داده شود. |
| P08-03 | Subject Digest، Source Revision، Product، Build Type، Builder و Entry Point Digest در Provenance جداگانه باید با Artifact و ورودی‌های Build تطبیق داشته باشند. |
| P08-04 | Canary Secret تزریق‌شده در Runtime نباید در بایت‌های Artifact، Provenance یا خروجی ثبت‌شده فرایند ظاهر شود؛ متغیرهای Secret محیط میزبان/CI نباید به Process فرزند منتقل شوند. |
| P08-05 | Startup، Liveness، API Readiness و Worker Readiness معنای مجزا داشته باشند؛ خرابی Dependency حیاتی Readiness را متوقف کند، بدون آنکه Liveness فرایند به‌اشتباه Fail شود؛ مقدار Health غیرBoolean Fail-closed شود و Drift در Pointer اجزای سرویس، Promotion/Rollback را متوقف کند. |
| P08-06 | همان Digest دقیق Artifact از Test به Staging ارتقا یابد؛ وضعیت قدیمی Compare-and-Swap در Promotion و Rollback رد شود. |
| P08-07 | Approval باید با Digest و Environment دقیق تطبیق داشته باشد؛ تفکیک Requester، Approver و Deployer اعمال و مقصد Production رد شود. |
| P08-08 | شکست API Readiness باید فعال‌سازی Candidate را متوقف کند؛ شکست Worker Readiness باید API Rollout ناقص را برگرداند و Traffic/Worker نسخه پایدار را فعال نگه دارد. |
| P08-09 | Rollback فقط زمانی پذیرفته شود که Artifact مقصد از Schema فعلی پشتیبانی کند. |
| P08-10 | Expand/Contract در صورت ناسازگاری Release فعال یا Rollback Target باقی‌مانده با Schema مقصد مسدود شود؛ بازنشستگی Rollback Target به تأیید دو نفر و تأیید صریح Schema مقصد نیاز داشته باشد؛ پس از بازنشستگی، Rollback ناایمن رد و Forward Repair سازگار موفق شود. |
| P08-11 | Promotion، Rollback و انتقال Schema باید Fingerprint وضعیت مالی ساختگی را حفظ کنند. |
| P08-12 | Audit مربوط به Promotion، Rollback، بازنشستگی Rollback Target و انتقال Schema باید هویت غیرخالی Actor را الزامی کند و Environment، Artifact Digest، Action، Outcome و Schema Version را بدون ثبت مقدار Secret Runtime ثبت کند. |
| P08-13 | CI باید مقایسه Build قطعی و تمام تست‌های مثبت/خصمانه را با صفر Skip اجرا کند. |
| P08-14 | اسناد فارسی و انگلیسی باید از نظر Scope، محدودیت‌ها، شناسه‌های پذیرش و قیود هم‌معنا باشند. |

اجرای موفق تست‌ها فقط رفتار Fixture را اثبات می‌کند. این نتیجه Rollout عملیاتی، Migration واقعی دیتابیس، انتشار بدون Downtime، SLO، مدیریت Secret Production یا ایمنی مالی زیر بار زنده را اثبات نمی‌کند.

## ۵. سناریوهای خرابی و بازیابی

۱. خرابی Artifact: پس از ایجاد Digest بایت‌ها تغییر داده شوند؛ Verification باید Artifact را رد کند.

۲. جایگزینی Provenance: Subject Digest، Source Revision یا Builder تغییر داده شود؛ Verification باید Fail شود.

۳. افشای Secret: از Canary ساختگی و یکتا استفاده شود؛ مقدار آن نباید در Archive، Provenance یا خروجی Runtime ظاهر شود.

۴. اختلال Dependency: خرابی Dependency حیاتی، Service را Not Ready کند، درحالی‌که Liveness Process سالم بماند.

۵. API ناسالم: Promotion یا هدایت Traffic انجام نشود.

۶. Worker ناسالم پس از Staging API: Pointer ناقص API برگردد؛ API/Worker و Traffic نسخه پایدار حفظ شوند.

۷. Pointer قدیمی یا Approval نامنطبق: Promotion بدون تغییر Release فعال رد شود.

۸. Rollback ناسازگار: اگر Artifact قدیمی Schema فعلی را نمی‌خواند، Rollback رد شود.

۹. Forward Repair: Artifact جدیدی که Schema فعلی را پشتیبانی می‌کند بتواند Release ناموفق را جایگزین کند، بدون آنکه Fingerprint وضعیت مالی تغییر کند.

۱۰. مقصد Production: حتی با Approval ظاهراً معتبر Fixture نیز رد شود.

## ۶. روش بازتولید

از ریشه مخزن:

~~~bash
REVISION="$(git rev-parse HEAD)"
python3 -m compileall -q prototypes/p08-deployment
python3 prototypes/p08-deployment/build.py v1 --out /tmp/p08-build-a --source-revision "$REVISION"
python3 prototypes/p08-deployment/build.py v1 --out /tmp/p08-build-b --source-revision "$REVISION"
cmp /tmp/p08-build-a/affiliate-agent-v1.pyz /tmp/p08-build-b/affiliate-agent-v1.pyz
python3 -m unittest discover -s prototypes/p08-deployment/tests -v
~~~

Workflow مربوط به CI: .github/workflows/p08-deployment-health-rollback.yml.

## ۷. محدودیت‌های امنیتی، عملیاتی و مالی

- Artifact Store یک Map در حافظه بر مبنای Digest است؛ OCI Registry تغییرناپذیر، WORM Store یا مخزن Artifact با مدیریت مستقل نیست.
- Provenance، Metadata ساختگی و بدون امضاست. Sigstore/Cosign، GitHub Artifact Attestation، Build Service قابل‌اعتماد، Transparency Log، SBOM، اسکن آسیب‌پذیری Dependency یا سطح SLSA بررسی نمی‌شود.
- Builder یک Process محلی Python است. خروجی قطعی، Build Hermetic، قابل‌بازتولید یا قابل‌اعتماد Production را اثبات نمی‌کند.
- Secret Runtime یک رشته ساختگی است که به Process فرزند داده می‌شود. Vault/KMS/Cloud Secret Store، Workload Identity Federation، Credential کوتاه‌عمر، Rotation، Revocation یا حفاظت Memory Dump پیاده‌سازی نشده است.
- بررسی Canary، تست رگرسیون محدود است؛ Secret Discovery جامع، DLP یا اثبات Redaction Log نیست.
- Health با Boolean قطعی نمایش داده می‌شود. HTTP Endpoint، Load Balancer، Service Mesh، Queue، Database، Dependency خارجی، SLO، تحویل Alert یا Worker واقعی اجرا نمی‌شود.
- Deployment State و Audit Record در حافظه هستند. Audit تغییرناپذیر، Tamper-evident یا مستقل نگهداری نمی‌شود.
- Migration فقط یک عدد صحیح ساختگی را تغییر می‌دهد. SQL، PostgreSQL DDL، رفتار Lock، Backup، Restore، Backfill داده یا تطبیق واقعی Ledger اجرا نمی‌شود.
- Fingerprint وضعیت مالی، یک Sentinel در Fixture است؛ Ledger یا اثبات حسابداری نیست.
- درصد Canary، Error Budget، آستانه Latency، RPO/RTO، مدت Rollout یا هدف Availability حدس زده نمی‌شود. این موارد به شواهد Workload و تصویب مالک پاسخ‌گو طبق LOT-QA-001 نیاز دارند.
- هیچ Deploy Production، Merge، تغییر تنظیمات مخزن یا عملیات مخرب انجام نمی‌شود.

## ۸. مراجع پژوهش

- SLSA، [Build Provenance نسخه ۱.۲](https://slsa.dev/spec/v1.2/build-provenance) و [الزامات Build](https://slsa.dev/spec/v1.2/build-requirements).
- in-toto، [چارچوب Attestation](https://github.com/in-toto/attestation).
- GitHub، [استفاده از Artifact Attestation](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations).
- Sigstore، [اعتبارسنجی امضای Cosign](https://docs.sigstore.dev/cosign/verifying/verify/).
- OWASP، [راهنمای مدیریت Secret](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html).
- Kubernetes، [Probeهای Liveness، Readiness و Startup](https://kubernetes.io/docs/concepts/workloads/pods/probes/).
- Google SRE Workbook، [انتشار Canary](https://sre.google/workbook/canarying-releases/).

## ۹. دروازه تکمیل

P-08 فقط زمانی تکمیل است که Head دقیق PR دارای Integration موفق و Documentation Governance موفق باشد، مقایسه Artifact قطعی قبول شود، تمام تست‌های مثبت و منفی با صفر Skip موفق باشند، هم‌ارزی معنایی نسخه فارسی و انگلیسی به‌صورت دستی بازبینی شود و محدودیت‌ها صریح باقی بمانند. موفقیت P-08 به‌تنهایی پلتفرم Production را انتخاب نمی‌کند، فناوری را تصویب نمی‌کند و مجوز Merge یا Deploy صادر نمی‌کند.
