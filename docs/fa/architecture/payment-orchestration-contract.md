# قرارداد ارکستراسیون پرداخت و Adapter ارائه‌دهنده

**شناسه سند:** LOT-PAYMENT-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** قرارداد پیشنهادی؛ نیازمند بازبینی مالک، مالی، حقوقی، امنیت و عملیات

## ۱. هدف، محدوده و اعتبار

این سند مرز ارکستراسیون مستقل از Provider را برای دریافت/وصول وجه از مشتری و Refundهای مرتبط با پرداخت، در مواردی که از نظر حقوقی و عملیاتی تصویب شده باشند، تعریف می‌کند. این سند هدف پرداخت در LOT-PLATFORM-001 را تفکیک می‌کند و باید همراه LOT-WALLET-001، LOT-FIN-POST-001، LOT-PROVIDER-EVAL-001 و LOT-IAM-TENANT-001 خوانده شود.

مالک دستور داده است که Lottorito اتصال به پرداخت ایرانی و بین‌المللی را برای Tenant اختصاصی First-Party B2C و Tenantهای B2B واجد شرایط هدف بگیرد. این الزام محصول است، نه شاهد دسترس‌پذیری یا تصویب Provider، Gateway، حساب پذیرندگی، رابطه Acquiring، مجوز، شخصیت حقوقی، حوزه قضایی، حساب بانکی یا جریان پرداخت. هیچ Providerی انتخاب نشده و Runtime پرداخت یا عملیات پول واقعی ادعا نمی‌شود.

این قرارداد برداشت مشتری، پرداخت کمیسیون Affiliate، پرداخت جایزه، پرداخت خزانه یا انتقال خروجی عمومی را تعریف نمی‌کند. این موارد متعلق به دامنه مستقل و دارای حاکمیت Payout (LOT-PAYOUT-001) هستند. پاسخ Gateway پرداخت، ثبت دفترکل یا اثبات Settlement نیست.

## ۲. اصول طراحی و مرزهای سخت

۱. هسته مستقل از Provider است؛ پروتکل، وضعیت و معنای Payload اختصاصی Provider فقط داخل Adapter نسخه‌بندی‌شده باقی می‌ماند.
۲. Payment Intent، تلاش Provider، Authorization/Capture، Refund، ثبت دفترکل و Settlement واقعیت‌های جداگانه با شناسه‌های مرتبط‌اند.
۳. هر Intent به Tenant، Product Instance، شخصیت حقوقی/زمینه Merchant، حوزه قضایی، مشتری، ارز و هدف پرداخت Scope می‌شود.
۴. Credential، Routing Policy، تراکنش، Settlement، کارمزد یا تطبیق بین Tenantها تجمیع نمی‌شود.
۵. مبلغ با Decimal دقیق/واحد خرد و Registry کنترل‌شده ارز نگهداری می‌شود؛ Binary Floating Point ممنوع است.
۶. Redirect مشتری و ادعای Browser/Mobile غیرقابل‌اعتماد است. نتیجه با شواهد احرازشده Server-to-Server و تطبیق تأیید می‌شود.
۷. Callback تکراری، Replay، دیررس، خارج از ترتیب یا متناقض نباید اثر اقتصادی دوم ایجاد کند.
۸. Timeout مبهم، نتیجه نامعلوم است نه شکست. Retry یا Routing به Provider دیگر به‌صورت کورکورانه ممنوع است.
۹. Authorization/Capture پرداخت به‌معنای Credit کیف پول مشتری نیست؛ Credit فقط پس از شواهد و دروازه Policy از مرز Posting کنترل‌شده انجام می‌شود.
۱۰. هیچ Provider یا بازاری پیش از تأیید حقوقی، تجاری، امنیت، مالی، عملیاتی و مالک برای واحد تصمیم دقیق فعال نمی‌شود.

## ۳. نقش Provider و طبقه‌بندی روش پرداخت

هر طرف مقابل بر اساس نقش واقعی قراردادی و فنی طبقه‌بندی شود؛ عنوان بازاریابی مانند «Gateway» کافی نیست.

| نقش | مسئولیت | محور Due Diligence |
|---|---|---|
| Gateway/پردازشگر فنی | اتصال Checkout/API و مسیریابی پیام | معنای API، دسترس‌پذیری، امنیت، پردازش داده، Retry |
| PSP/Payment Facilitator | Onboarding پذیرنده، پذیرش پرداخت و/یا خدمات Sub-merchant | شخصیت حقوقی، زنجیره Acquiring، جریان وجه، ذخیره/Reserve، کسب‌وکار ممنوع |
| Acquirer/بانک پذیرنده | رابطه پذیرندگی و Settlement | صلاحیت Merchant، حساب تسویه، Chargeback و قواعد Scheme |
| Aggregator | دسترسی به چند روش/Provider پرداخت | هویت Provider زیربنایی، شفافیت Routing، مسئولیت و Portability |
| بانک/Open Banking Provider | آغاز پرداخت حساب‌محور یا دسترسی اطلاعات حساب در صورت مجاز بودن | مجوز، رضایت، احراز قوی، لغو و دسترسی داده |
| شبکه/روش پرداخت محلی | ریل داخلی، پرداخت فوری، QR، حواله یا روش محلی | حوزه قضایی، ارز، قطعیت Settlement، برگشت و ساعات عملیاتی |
| روش کارت/Wallet بین‌المللی | پذیرش کارت یا Wallet از زنجیره مجاز | قواعد Scheme، Tokenization، 3DS/SCA در صورت کاربرد و مسئولیت PCI |

هر روش پرداخت به‌صورت جداگانه بر اساس Tenant، شخصیت حقوقی، حوزه قضایی، ارز، صلاحیت مشتری، محصول، بازه مبلغ و Policy ریسک پیکربندی می‌شود. «ایرانی» و «بین‌المللی» نیاز بازار/جغرافیا هستند، نه دسته‌های قابل‌جایگزینی Provider. این سند هیچ فهرست Provider یا ادعای سازگاری را تصویب نمی‌کند.

## ۴. واحد تصمیم، زمینه Merchant و جداسازی Tenant

ارزیابی Provider از واحد تصمیم LOT-PROVIDER-EVAL-001 استفاده می‌کند: محصول/دامنه، نقش فروشنده، شخصیت حقوقی طرف قرارداد، حوزه قضایی، مدل عملیاتی، Tenant/Deployment، هدف پرداخت، ارز و مدل جریان وجوه.

برای هر پیکربندی پرداخت فعال، موارد زیر نگهداری شوند:
- tenant_id، product_instance_id و زمینه Brand/Application؛
- شخصیت حقوقی پاسخ‌گو و شناسه Merchant/Sub-merchant؛
- شخصیت حقوقی Provider، نقش، قرارداد و محدوده خدمت مصوب؛
- حوزه قضایی، صلاحیت مشتری و روش پرداخت مجاز؛
- ارز/واحد پشتیبانی‌شده، دقت، محدودیت مبلغ و جدول کارمزد؛
- مقصد Settlement، مالکیت ذی‌نفع و ارز تسویه؛
- مرجع Credential، محیط، وضعیت چرخش و Scope دسترسی؛
- نسخه Routing Policy، Policy ریسک و تاریخ اثر.

مدیر Tenant فقط تنظیماتی را تغییر می‌دهد که صریحاً به او Delegated شده‌اند. تغییر شخصیت حقوقی، مالکیت Merchant، مقصد Settlement، Credential Provider، روش تنظیم‌گری‌شده و Routing به مجوز و تأیید جداگانه نیاز دارد. Secret بر اساس Tenant، حساب Provider، محیط و هدف ایزوله است؛ هرگز به Browser/Mobile افشا یا از Master Credential مشترک استفاده نشود.

## ۵. اشیای اصلی دامنه

- **Payment Intent:** درخواست Canonical برای دریافت مبلغ مشخص از مشتری مشخص، برای سفارش/هدف، Tenant و محصول معین.
- **Payment Attempt:** یک ارسال به یک Provider/روش. یک Intent فقط تحت قواعد کنترل‌شده Retry/Failover می‌تواند چند Attempt داشته باشد.
- **Provider Session:** نشست کوتاه‌عمر Redirect، Hosted Checkout، QR، Deeplink یا Tokenized که Adapter ایجاد می‌کند.
- **Authorization:** تأیید Provider/Acquirer برای مجاز بودن مبلغ، در روش‌های پشتیبانی‌کننده.
- **Capture/Collection:** درخواست/تأیید دریافت وجه در سمت Provider، برای مبلغ مجازشده یا پرداخت مستقیم.
- **Refund:** درخواست مستقل و دارای شناسه برای بازگرداندن تمام/بخشی از پرداخت Captureشده؛ با Debit کیف پول یا Payout یکی نیست.
- **Provider Event:** اعلان وضعیت خارجی با احراز/راستی‌آزمایی و مرجع شواهد خام و تفسیر نرمال‌شده.
- **Settlement Batch/Line:** شواهد Provider/بانک درباره تسویه وجه، کارمزد، Reserve، Chargeback و مبلغ خالص.
- **Reconciliation Case:** رکورد پایدار تطبیق/استثنا میان Intent، Attempt، رویداد Provider، دفترکل و Settlement خارجی.
- **Payment Method Configuration:** Policy نسخه‌بندی‌شده Tenant/شخصیت حقوقی/روش و مرجع Credential.

شناسه‌ها و روابط تغییرناپذیر ذخیره شوند. Intent و Attempt را در یک سطر/State ادغام نکنید و شناسه Provider را به‌عنوان شناسه قابل‌اعتماد جهانی نپذیرید.

## ۶. چرخه عمر Intent و Attempt پرداخت

وضعیت‌های پیشنهادی Intent:
- created
- requires_customer_action
- processing
- authorized
- captured
- partially_refunded
- refunded
- failed
- cancelled
- expired
- disputed
- unknown_outcome
- reconciliation_required

وضعیت‌های پیشنهادی Attempt:
- created
- submitted
- pending
- requires_action
- authorized
- captured
- declined
- failed
- timed_out
- unknown
- reversed

این‌ها وضعیت‌های نرمال‌شده نامزدند؛ Adapter وضعیت اختصاصی Provider را بدون حذف Status/Code اصلی، زمان رویداد، زمان مشاهده یا مرجع شواهد نگاشت می‌کند. انتقال وضعیت Guarded و در موارد مقتضی Monotonic است؛ اما شواهد معتبر دیررس ممکن است انتقال اصلاحی/تطبیقی صریح لازم داشته باشند. از صفحه موفقیت Browser، Capture را استنباط نکنید.

Intent پرداخت را نمی‌توان بی‌صدا برای مشتری، مبلغ، ارز، Tenant، سفارش یا شخصیت حقوقی دیگری استفاده کرد. تغییر مبلغ نیازمند Cancel/Expire و Intent جدید است، مگر Amendment صریح و ممیزی‌شده پشتیبانی شود.

## ۷. Checkout و تجربه مشتری

الگوهای تعامل مختص روش پرداخت مانند Hosted Checkout، Redirect، فیلدهای کنترل‌شده Embedded، QR، Deeplink، دستور پرداخت بانکی یا رضایت Recurring Tokenized فقط پس از بازبینی حقوقی/امنیتی پشتیبانی شوند.

برای کاهش مواجهه، ورود اطلاعات حساس کارت/حساب را به صفحه میزبانی‌شده Provider واگذار کنید. PAN کامل، CVV، PIN، رمز بانکداری اینترنتی یا Secret احراز Provider ذخیره نشود. Tokenization خودبه‌خود تعهدات PCI یا انطباق دیگر را حذف نمی‌کند؛ Scope باید با Acquirer/Provider و ارزیاب واجد صلاحیت تعیین شود.

UX مشتری باید مبلغ، ارز، هویت Payee/Merchant، کارمزد، روش، انقضا، شرایط Refund و گام بعدی را روشن کند. صفحات بومی‌سازی‌شده باید دسترس‌پذیر و سازگار با RTL/LTR باشند. Return URL فقط وضعیت موقت نشان می‌دهد؛ سرور پیش از نمایش Paid/Credited، وضعیت معتبر Provider را دریافت یا استعلام می‌کند. از Open Redirect و دستکاری Return URL جلوگیری شود.

## ۸. قرارداد Adapter ارائه‌دهنده

هر Adapter یک Interface نسخه‌بندی‌شده با قابلیت‌های صریح پیاده‌سازی می‌کند:
- ایجاد/آغاز نشست پرداخت؛
- دریافت/استعلام وضعیت با مرجع پایدار Provider؛
- Authorization/Capture در صورت پشتیبانی؛
- Cancel/Void در صورت پشتیبانی؛
- درخواست Refund و استعلام Refund؛
- راستی‌آزمایی امضای Webhook/اصالت و بازه Replay؛
- نرمال‌سازی رویداد با حفظ مرجع شواهد خام؛
- دریافت گزارش Settlement یا پشتیبانی از ورود کنترل‌شده آن؛
- نگاشت خطا، قابلیت Retry، Scope Idempotency و Rate Limit؛
- ارائه Metadata قابلیت/نسخه و Health.

Adapter مالک موجودی Wallet، محاسبه کمیسیون، Entitlement مشتری، مجوز Tenant یا دفترکل Canonical نیست. SDK و Payload اختصاصی Provider پشت Anti-corruption Mapping ایزوله می‌شوند. نبود قابلیت باید صریح باشد؛ عملیات پشتیبانی‌نشده با توالی ناامن شبیه‌سازی نشود.

## ۹. Idempotency، Callback و نتیجه مبهم

برای هر اثر اقتصادی، Platform Operation ID و Idempotency Key پایدار ایجاد کنید. Retry همان Intent به همان Provider از Scope Idempotency ثابت Provider در صورت پشتیبانی استفاده می‌کند. Hash درخواست نرمال‌شده، حساب Provider، شناسه Intent/Attempt، اولین ارسال، پاسخ، شناسه رویداد و نتیجه Conflict ذخیره شوند.

پردازش Webhook:
۱. دریافت در Endpoint پایدار، محدود از نظر اندازه و Durable.
۲. اعتبارسنجی Signature/Authentication، Timestamp/بازه Replay و اتصال به حساب Provider.
۳. ذخیره امن شواهد خام پیش از Acknowledge، در حد امکان عملیاتی.
۴. Deduplicate شناسه Delivery و مستقل از آن، Deduplicate اثر اقتصادی.
۵. Resolve کردن Tenant/حساب Provider از پیکربندی معتبر، نه tenant_id ارسالی Callback.
۶. استعلام وضعیت Provider در صورت ناقص، متناقض یا غیرقطعی بودن Callback.
۷. نرمال‌سازی و اعمال انتقال وضعیت Guarded.
۸. آغاز Posting فقط پس از تحقق شواهد و Policy لازم.
۹. ارسال ناهنجاری‌ها به Quarantine و Reconciliation.

Timeout پس از Submit تا زمان حل با Status Query یا شواهد Settlement، unknown_outcome است. صرف دیررس بودن پاسخ، مجوز Attempt دوم یا تغییر Provider نیست. Failover فقط زمانی مجاز است که عدم پذیرش قطعی باشد و قرارداد Provider/روش، Retry امن را اجازه دهد.

## ۱۰. Routing، تاب‌آوری و Failover Provider

Routing Policy نسخه‌بندی‌شده و برای Context تصمیم قطعی است. ابعاد نامزد شامل Tenant، شخصیت حقوقی، حوزه قضایی، ارز، روش، مبلغ، محصول، صلاحیت مشتری، قابلیت Provider، دسترس‌پذیری، ریسک و هزینه است.

- محدودیت‌های سخت حقوقی، قراردادی، صلاحیت مشتری و امنیت پیش از امتیازدهی/ترجیح Routing اعمال می‌شوند.
- دسترس‌پذیری Provider از Health Signal و نتیجه تأییدشده مشاهده می‌شود؛ به Provider تأییدنشده Route نکنید.
- Circuit Breaker، Timeout محدود، Backoff و جداسازی Queue از Platform محافظت می‌کنند.
- فقط با Idempotency پایدار و معنای Retry پشتیبانی‌شده Retry کنید.
- Payment مبهم را کورکورانه به Provider دوم Failover نکنید.
- Provider منتخب، گزینه‌های بررسی‌شده، نسخه Policy و دلیل هر تصمیم Routing ثبت شود.
- Override دستی Routing ممتاز، زمان‌محدود، مستدل و Audit‌شده است.

بهینه‌سازی Routing نباید تحریم، محدودیت Merchant Category، جغرافیا، سقف تراکنش، قواعد استفاده مسئولانه یا شرایط Provider را دور بزند.

## ۱۱. کارمزد، FX، Settlement و مرز حسابداری

این موارد جدا نگه داشته شوند:
- مبلغ و ارز مشتری؛
- مبلغ/ارز ارائه‌شده به Provider؛
- کارمزد Provider، Scheme، مالیات و کسورات دیگر؛
- مبلغ ناخالص Captureشده؛
- مبلغ خالص Settlement؛
- Reserve، Hold چرخشی، Chargeback و Refund؛
- ارز/تاریخ تسویه و مرجع بانک؛
- نرخ FX، منبع، زمان، Spread، کارمزد و گردکردن.

IRR/IRT، USD یا ارز دیگر بی‌صدا تبدیل نشوند. Alias و شیوه نمایش ارز به Registry کنترل‌شده و قواعد تبدیل صریح نیاز دارند؛ واحد Canonical داخلی و واحد درخواستی Provider جداگانه ثبت شوند.

Capture موفق اثبات Settlement بانکی نیست. صورت‌حساب Provider و در صورت کاربرد، صورت‌حساب مستقل بانک با سوابق Payment و Ledger Canonical تطبیق داده می‌شوند. Credit کیف پول یا ثبت مطالبات/بدهی Merchant فقط از مسیر LOT-FIN-POST-001 با نگاشت حساب و شواهد مصوب انجام می‌شود. از Redirect مرورگر یا Callback تأییدنشده Posting نکنید.

## ۱۲. Refund، اختلاف و معکوس‌سازی

Refund به پرداخت Captureشده اصلی متصل است و به مبلغ Captureشده/قابل‌استرداد، Policy Provider، محدودیت زمانی، روش و قانون محدود می‌شود. Refund جزئی و چندگانه نباید از مبلغ واجد شرایط بیشتر شود. درخواست Refund، پذیرش Provider، Settlement بازپرداخت و اثر حسابداری/Wallet مشتری وضعیت‌های جدا هستند.

Refund، Debit دلخواه Wallet، برداشت یا Payout نیست. اگر Provider امکان بازگشت به منبع اصلی را ندارد، مسیر جایگزین نیازمند تأیید صریح حقوقی، مالی، تقلب و مالک همراه با احراز ذی‌نفع است. Chargeback/Dispute به حفظ شواهد، مهلت، Reason Code، مسئولیت موقت/نهایی و Reconciliation نیاز دارد. Reverse دفترکل اثبات بازگشت وجه خارجی نیست.

## ۱۳. امنیت، حریم خصوصی و انطباق

- TLS و کانال Server-to-Server احرازشده؛ Signature Verification و Replay Protection برای Webhook.
- Secret در Vault/KMS مصوب، محدود به Tenant/حساب/محیط، با Least Privilege و Rotation.
- PAN/اطلاعات کامل کارت/حساب، CVV، رمز، Token یا داده شخصی غیرضروری ذخیره یا Log نشود.
- اعتبارسنجی سخت Schema، محدودیت اندازه Request، Rate Limit، کنترل Bot/Abuse و تشخیص ناهنجاری.
- حفاظت SSRF/Open Redirect برای URLهای Provider، Redirect و مقصد Callback.
- Encryption، Access Log، Retention، Deletion/Legal Hold و Data Residency بر اساس حوزه قضایی.
- Scope مربوط به PCI DSS، قواعد Scheme، 3DS/SCA، حریم خصوصی، AML/تحریم، افشای مصرف‌کننده و مجوز پرداخت محلی بر اساس مدل عملیاتی واقعی بررسی شود.
- Sub-processorهای Provider، انتقال داده، اعلان رخداد، حق Audit، تداوم کسب‌وکار و شرایط Exit/Export پیش از Production بازبینی شوند.
- بازار تنظیم‌گری‌شده از یک تنظیم Global عمومی فعال نمی‌شود؛ هر حوزه قضایی و شخصیت حقوقی دروازه مستقل دارد.

## ۱۴. عملیات Observability و Reconciliation

تبدیل Intent به پرداخت، نتیجه Attempt، Latency/خطای Provider، نتیجه نامعلوم، تأخیر/شکست Signature در Webhook، رویداد تکراری، Refund، Chargeback، اختلاف Settlement، اختلاف کارمزد، توزیع Routing و پرونده حل‌نشده پایش شوند. ابعاد باید Tenant-safe باشند و از نشت داده حساس/High-cardinality جلوگیری شود.

تطبیق این موارد را مقایسه می‌کند:
- Intent/Attempt پلتفرم و مراجع Canonical Provider؛
- رویداد احرازشده Provider و Status Query؛
- صورت‌حساب تراکنش و Settlement Provider؛
- شواهد Settlement بانک/Acquirer در صورت کاربرد؛
- ثبت‌های Ledger، Refund، کارمزد، Reserve و Chargeback.

Batch صورت‌حساب تغییرناپذیر وارد شود؛ منبع، Schema، ارز، دوره و جمع کنترل اعتبارسنجی شوند؛ تطبیق با مراجع قطعی انجام شود؛ موارد مفقود، تکراری، دیررس، اختلاف مبلغ/ارز و کارمزد توضیح‌نداده‌شده طبقه‌بندی شوند؛ تعدیل از گردش مالی کنترل‌شده ثبت شود. اختلاف بااهمیت خودکار Write-off نشود. Operator، نسخه قاعده، شواهد، زمان و Sign-off نگهداری شوند.

## ۱۵. ماتریس پذیرش و تست خصمانه

| شناسه | سناریو | نتیجه/شواهد مورد انتظار |
|---|---|---|
| PAY-01 | مشتری مبلغ، ارز، Tenant یا Merchant را دستکاری می‌کند | رد سمت سرور؛ مقادیر Intent تغییرناپذیر و معتبر از Server |
| PAY-02 | Return مرورگر موفق است ولی Provider Pending/Failed می‌گوید | UI موقت می‌ماند؛ بدون Credit Wallet یا Posting |
| PAY-03 | Webhook تکراری/Replayشده | Dedup احرازشده؛ حداکثر یک اثر اقتصادی و یک Posting |
| PAY-04 | Signature نامعتبر یا Timestamp منقضی | رد/Quarantine؛ Alert و شواهد Audit |
| PAY-05 | Timeout Provider پس از Submit | unknown_outcome؛ Status Query/Reconciliation، بدون Retry/Failover کور |
| PAY-06 | Idempotency Key یکسان با Payload تغییرکرده | Conflict؛ بدون عملیات دوم Provider |
| PAY-07 | دو Provider برای یک روش تنظیم شده‌اند | Routing قطعی و واجد شرایط؛ Provider/Policy انتخابی ثبت می‌شود |
| PAY-08 | نتیجه Provider A مبهم است | همان پرداخت به Provider B ارسال نمی‌شود |
| PAY-09 | Tenant A از Credential مربوط به Tenant B استفاده می‌کند | Deny؛ بدون دسترسی متقاطع Secret/تراکنش |
| PAY-10 | Callback شناسه جعلی Tenant/حساب Provider می‌فرستد | Resolve از Mapping معتبر؛ عدم تطابق رد می‌شود |
| PAY-11 | Refund جزئی و تکراری | مجموع Refund از مبلغ Captureشده واجد شرایط بیشتر نمی‌شود |
| PAY-12 | مبلغ Settlement با Capture متفاوت است | Exception تطبیق؛ بدون تعدیل بی‌صدا |
| PAY-13 | Alias ارز IRR/IRT یا FX مبهم است | رد یا نیازمند Policy صریح واحد Canonical/Conversion |
| PAY-14 | Provider می‌گوید Captured ولی Settlement بانک موجود نیست | Capture و Settlement جدا؛ Workflow استثنا/عمر |
| PAY-15 | Credential Provider چرخش/افشا می‌شود | Rotation/Revocation محدود؛ بدون پرداخت تکراری ناشی از Downtime |
| PAY-16 | Provider تعلیق یا قرارداد منقضی می‌شود | Attempt جدید مسدود؛ عملیات در جریان و Refund طبق Runbook مصوب |

## ۱۶. تصمیم‌های باز و دروازه فعال‌سازی بازار

۱. شخصیت حقوقی عملیاتی اولیه، Merchant of Record، مدل Acquiring و حوزه‌های قضایی هدف.
۲. صلاحیت بازار داخلی ایران و بازار بین‌المللی، اهداف پرداخت مجاز و محدودیت‌های فرامرزی.
۳. نقش دقیق Provider، شخصیت حقوقی، مجوز/ثبت، قرارداد، زنجیره Acquiring، بانک Settlement و جریان وجوه برای هر گزینه.
۴. اینکه نسخه نخست فقط Deposit/Collection ورودی می‌پذیرد یا Checkout خرید سایر محصولات را نیز پوشش می‌دهد.
۵. ارزهای پشتیبانی‌شده، مدیریت Canonical IRR/IRT، FX، کارمزد، ارز Settlement و رفتار مالیاتی.
۶. Policy Refund، Dispute، Chargeback، Reserve و قطعیت Settlement.
۷. احراز مشتری، AML/تحریم، تقلب، سقف، Velocity و Step-up Authentication.
۸. Data Residency، Scope PCI، 3DS/SCA، Tokenization و الزامات ارزیابی امنیت.
۹. Routing، Retry/Failover، اهداف Uptime/Latency، Escalation پشتیبانی و Exit/Portability.
۱۰. شروط Credit کیف پول و نگاشت Chart of Accounts مصوب مالی.
۱۱. نقش‌های عملیات پرداخت، مالکیت Reconciliation، Dual Control و پاسخ رخداد.

استاندارد LOT-PROVIDER-EVAL-001 برای هر واحد تصمیم دقیق Provider جداگانه اعمال شود. هیچ Providerی صرفاً بر اساس شهرت برند یا برچسب عمومی کشور انتخاب نمی‌شود. شواهد مستند از Provider و Registerهای رسمی مرتبط دریافت، قرارداد و جریان وجوه بررسی، Sandbox مجاز با داده ساختگی آزمایش و پیش از Production تأیید مالک/حقوقی/مالی/امنیت/عملیات اخذ شود.

## ۱۷. اسناد مرتبط و کنترل تغییر

- LOT-PLATFORM-001 — معماری یکپارچه پلتفرم B2B2C.
- LOT-WALLET-001 — قرارداد دامنه Wallet و معنای موجودی.
- LOT-FIN-POST-001 — ثبت مالی و تطبیق.
- LOT-PROVIDER-EVAL-001 — استاندارد ارزیابی Provider و RFI.
- LOT-IAM-TENANT-001 — هویت Tenant و مجوزدهی.
- LOT-API-001 — قرارداد Resource API و Webhook.
- LOT-PAYOUT-001 — قرارداد آینده Payout و برداشت (دامنه مستقل).

تغییر در اعتماد Provider، Routing، جریان وجوه، راستی‌آزمایی Callback، محرک Posting، رفتار Refund یا صلاحیت حوزه قضایی نیازمند به‌روزرسانی LDR، بازبینی Threat/Finance/Legal و تغییر هم‌زمان فارسی/انگلیسی است. این سند Proposed است؛ انتخاب Provider، Integration پرداخت، مجوز یا اجازه پردازش پول واقعی نیست.
