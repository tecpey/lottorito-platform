# P-07A — مرزبندی محصولات و جداسازی وابستگی‌ها

**شناسه سند:** LOT-PROT-P07A-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیاده‌سازی قرارداد معماری ساختگی؛ اعتبارسنجی CI در انتظار اجرا؛ بدون ادعای Runtime محصول یا تصویب معماری Production

## ۱. هدف و اعتبار

P-07A نخستین بخش از سه بخش مستقل و قابل‌بازبینی P-07 است:

- **P-07A — مرزبندی و جداسازی وابستگی‌ها:** تعیین مالکیت و اعمال سیاست جهت‌دار Dependency.
- **P-07B — استقلال Build، Runtime، Migration و Configuration:** اثبات اینکه هر محصول بدون نیاز به محصول دیگر Build، پیکربندی، اجرا، غیرفعال و Migration می‌شود.
- **P-07C — قرارداد رویداد و جداسازی امنیتی:** اثبات اینکه دسترسی به داده و Event بین محصولات به‌صورت پیش‌فرض رد می‌شود و فقط از طریق قرارداد صریح، نسخه‌بندی‌شده و مجاز فعال خواهد شد.

P-07A ادعا نمی‌کند که Lottorito هم‌اکنون برنامه اجرایی محصول دارد. خط مبنای مخزن همچنان مستندات به‌همراه Prototypeهای ساختگی و ایزوله است. این بخش یک Manifest معماری صریح و Validator با رفتار Fail-closed را اعتبارسنجی می‌کند؛ در P-07B باید Artifact و رفتار Runtime واقعی محصولات آزموده شوند.

## ۲. فرضیه

Affiliate & Agent و Lottery می‌توانند به‌عنوان Bounded Contextهای مستقل تکامل یابند. هر دو مجازند از قابلیت‌های مشترک پلتفرم از طریق Contractهای پایدار استفاده کنند؛ اما هیچ‌کدام نباید Domain یا Implementation محصول دیگر را Import کند و Implementationهای پلتفرم نیز نباید به جزئیات داخلی محصولات وابسته باشند.

هدف، **پلتفرمی ماژولار با مرزهای قابل‌اعمال و قابل‌آزمون** است؛ نه تعهد زودهنگام به Microservices، دیتابیس‌های جداگانه، Framework مشخص یا توپولوژی استقرار خاص.

## ۳. مدل مالکیت

| قابلیت | مسئولیت تحت مالکیت پلتفرم | مسئولیت تحت مالکیت محصول |
|---|---|---|
| Identity | Principalهای canonical و قراردادهای احراز هویت | توسعه‌های پروفایل مختص محصول |
| Tenant | هویت Tenant، سازمان و عضویت | رکوردها و رفتار فعال‌سازی مختص محصول |
| Authorization | ارزیابی و اعمال Policy | واژگان مجوزها و قواعد کسب‌وکار محصول |
| Finance | قابلیت‌های Ledger/Posting و سوابق مالی تغییرناپذیر | قصد اقتصادی، محاسبات کمیسیون/جایزه و سیاست محصول |
| Notifications | زیرساخت تحویل و Adapterهای Provider | Trigger، شرایط احراز و محتوای محصول |
| Audit | مخزن محافظت‌شده Audit و کنترل دسترسی | معنای رویداد کسب‌وکار و Context قابل انتساب |
| Events | زیرساخت Envelope، مسیریابی و تحویل | معنای Event و Schema تحت مالکیت تولیدکننده |

در حوزه Finance، قابلیت مشترک Posting به‌هیچ‌وجه به معنی **موجودی مشترک** نیست. هر محصول قصد اقتصادی، Policy و انتساب حسابداری مستقل خود را حفظ می‌کند. هیچ فرمول کمیسیون، تعریف NGR، بدهی جایزه، تبدیل ارز یا قاعده تهاتر بین محصولات در این آزمایش تصویب نمی‌شود.

مقادیر مالکیت در فایل architecture.json، مالک منطقی پاسخ‌گو در مدل ساختگی هستند؛ نه انتساب به افراد مشخص یا تصمیم درباره ساختار نیروی انسانی.

## ۴. سیاست Dependency

۱. Domain هر محصول فقط می‌تواند به Moduleهای Domain متعلق به همان محصول وابسته باشد.

۲. Application و Adapter هر محصول می‌توانند به Moduleهای همان محصول و Moduleهای منتشرشده از نوع platform contract وابسته باشند.

۳. Moduleهای محصول مجاز نیستند مستقیماً به Implementation قابلیت‌های پلتفرم وابسته شوند.

۴. Moduleهای Affiliate نباید به Moduleهای Lottery وابسته باشند و برعکس.

۵. Platform Contractها باید Declaration مستقل و بدون Dependency باشند.

۶. Platform Implementationها می‌توانند به Contractها و Implementationهای پلتفرم وابسته باشند، اما هرگز به Moduleهای محصول وابسته نمی‌شوند.

۷. Dependency ناشناخته، Owner مفقود، شناسه Module تکراری و چرخه Dependency باید Fail-closed شوند.

۸. هر قابلیت مشترک باید یک مالک پلتفرم، Module قرارداد، Module پیاده‌سازی، مالک داده، مالک Policy هر محصول، مصرف‌کنندگان هر دو محصول، Tenant Scope و دسترسی پیش‌فرض Deny داشته باشد.

این Graph یک مدل منطقی از Dependency است؛ هنوز Import Graph یک برنامه Production نیست. Workspace اجرایی قابل‌راستی‌آزمایی برای اسکن وجود ندارد. اگر Workspace محصول در آینده ایجاد شود، P-07B باید این قواعد را به Graph واقعی Build و Package متصل کند.

## ۵. Fixture اجرایی و سناریوها

Manifest ساختگی برای هر محصول سه لایه domain، application و adapter، هفت Platform Contract، هفت Platform Implementation و هفت قابلیت مشترک تعریف می‌کند.

Validator فقط از Standard Library پایتون استفاده می‌کند. مجموعه تست موارد زیر را پوشش می‌دهد:

- Graph مرجع معتبر.
- Dependency به Module ناشناخته.
- Import از Affiliate به Lottery و از Lottery به Affiliate.
- دورزدن Contract و وابستگی مستقیم محصول به Platform Implementation.
- وابستگی Platform به Product.
- وابستگی Platform Contract به Implementation.
- چرخه Dependency و شناسه Module تکراری.
- Owner مفقود و طبقه‌بندی مالکیت نامعتبر.
- قابلیت مشترک با دسترسی پیش‌فرض مجاز یا بدون Tenant Scope.
- Implementation متعلق به Platform Capability دیگر.
- جداسازی مالکیت Ledger پلتفرم از Policy اقتصادی محصول در Finance.

## ۶. معیارهای پذیرش

| شناسه | نتیجه الزامی |
|---|---|
| P07A-01 | Graph مرجع بدون خطا اعتبارسنجی شود. |
| P07A-02 | Dependency بین دو محصول در هر دو جهت رد شود. |
| P07A-03 | دورزدن Contract و وابستگی Product به Platform Implementation رد شود. |
| P07A-04 | وابستگی Platform به Product رد شود. |
| P07A-05 | Node ناشناخته، شناسه تکراری، Owner مفقود و Cycle رد شوند. |
| P07A-06 | هر هفت قابلیت مشترک دارای Owner، Contract، Implementation، Data Owner و مالک Policy محصولات باشند. |
| P07A-07 | دسترسی قابلیت مشترک به‌صورت پیش‌فرض Deny باشد و Tenant Scope الزامی داشته باشد. |
| P07A-08 | مالکیت Ledger در پلتفرم از Policy اقتصادی هر محصول جدا باشد و هیچ Pooling ضمنی موجودی بین محصولات وجود نداشته باشد. |
| P07A-09 | CI هم Validator Manifest و هم تست‌های مثبت و خصمانه را اجرا کند. |
| P07A-10 | سند فارسی و انگلیسی از نظر قواعد، تفکیک مالکیت و شناسه‌های پذیرش هم‌معنا باشند. |

صرفاً اجرای موفق خود Validator به معنی Pass نیست. CI باید Baseline مثبت و تمام سناریوهای منفی اجباری را اجرا کند. مجموعه تست باید صفر شکست و صفر Skip گزارش کند.

## ۷. مدل تهدید و شکست

این آزمایش Metadata مربوط به Dependency را ورودی غیرقابل‌اعتماد فرض می‌کند و روابط ناشناخته یا نامعتبر را رد می‌کند. این تست سوءاستفاده معماری را پوشش می‌دهد، نه Authorization در Runtime را. Dependency Graph به‌تنهایی نمی‌تواند RLS دیتابیس، منشأ Tenant Context، مجوز API، اصالت Event، نگهداری Secret یا جداسازی Deployment را اثبات کند؛ این موارد به P-07B/P-07C و شواهد قبلی P-01/P-03/P-06 تعلق دارند.

دسترسی بین محصولات در نهایت باید در سمت دریافت‌کننده مجاز شود. نام Event، Tenant ID، قرارگرفتن در شبکه داخلی یا داشتن Credential مشترک پلتفرم به‌تنهایی مجوز دسترسی نیست. هر Grant بین‌محصولی باید محصول مبدأ، قابلیت مقصد، Action، Tenant Scope، Contract/Version و Context ممیزی را مشخص کند. این مرز در P-07C آزموده خواهد شد.

## ۸. مبنای پژوهش و منطق طراحی

- **Bounded Context و Context Map در DDD:** مرزها باید از مدل کسب‌وکار و روابط صریح آن استخراج شوند، نه از پوشه‌بندی فنی دلخواه. [راهنمای Microsoft درباره مرز مدل دامنه](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/architect-microservice-container-applications/identify-microservice-domain-model-boundaries) و [Bounded Context از Martin Fowler](https://martinfowler.com/bliki/BoundedContext.html).
- **Modular Monolith و جداسازی Domain:** پیش از استخراج سرویس‌ها، جزئیات داخلی دامنه پشت API عمومی بمانند و مالکیت داده روشن باشد. [راهنمای GitLab درباره جداسازی لایه Domain](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/modular_monolith/domain_layer/).
- **قواعد خودکار Dependency:** وابستگی‌های مجاز و ممنوع به‌صورت قانون قابل‌اعمال در CI تعریف شوند. [Nx Enforce Module Boundaries](https://nx.dev/docs/features/enforce-module-boundaries).
- **امنیت Tenant:** Tenant Context از هویت تأییدشده استخراج شود، منابع مشترک طبقه‌بندی شوند و Consumer رویداد مجوز را دوباره بررسی کند. [راهنمای OWASP برای امنیت برنامه‌های چندمستاجری](https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Application_Security_Cheat_Sheet.html).
- **جداسازی SaaS:** مدل‌های Pool، Silo یا Bridge بر اساس قابلیت و ریسک انتخاب شوند؛ استقلال محصول الزاماً به معنی یک Deployment فیزیکی برای هر Tenant نیست. [AWS SaaS Lens](https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/silo-pool-and-bridge-models.html).
- **هم‌کنش‌پذیری Event:** CloudEvents می‌تواند در تدوین Envelope مربوط به P-07C بررسی شود، اما در این مرحله هیچ استاندارد Event یا Broker انتخاب نمی‌شود. [CloudEvents](https://cloudevents.io/).

## ۹. موارد خارج از محدوده و تصمیم‌های باز

- هیچ برنامه Production، Import Graph، Package Manager، Framework یا Deployment Unit ادعا نمی‌شود.
- هیچ تفکیک Microservice، دیتابیس جداگانه برای هر محصول، Broker، Cloud Vendor یا توپولوژی جداسازی Tenant انتخاب نشده است.
- هیچ Provider واقعی Lottery، شریک، مشتری، داده کاربر، Secret یا وجه واقعی استفاده نمی‌شود.
- هیچ قاعده تجاری کمیسیون، NGR، جایزه، Wallet، Payout، FX یا تسویه بین محصولات تصویب نمی‌شود.
- هیچ گواهی Production، حقوقی، مقرراتی، حریم خصوصی یا امنیتی صادر نمی‌شود.
- P-07B و P-07C تا زمان تدوین Scope، Fixture و شواهد پذیرش مستقل خود اجراشده محسوب نمی‌شوند.

## ۱۰. دروازه تکمیل

P-07A فقط زمانی تکمیل است که Integration و Documentation Governance روی Head دقیق PR موفق باشند، سناریوهای منفی در خروجی CI قابل مشاهده باشند، هم‌ارزی معنایی نسخه‌های فارسی و انگلیسی بازبینی شود و محدودیت‌های شناخته‌شده صریح باقی بمانند. موفقیت P-07A به معنی موفقیت کل P-07 یا مجوز Merge و Deploy نیست.
