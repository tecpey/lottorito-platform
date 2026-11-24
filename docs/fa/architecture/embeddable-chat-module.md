# معماری ماژول چت قابل‌تعبیه

**شناسه سند:** LOT-CHAT-WIDGET-001 | **نسخه:** ۱.۱.۰ | **وضعیت:** قرارداد محصول و معماری پیشنهادی؛ هیچ Runtime، Widget، SDK، API یا Provider تأیید نشده است

## ۱. هدف و مرز محصول

Chat در Lottorito باید ماژولی مستقل و قابل‌استفاده مجدد باشد، نه قطعه‌ای از رابط کاربری که به یک اپلیکیشن خاص وابسته است. یک پلتفرم مکالمه واحد و تحت حاکمیت مشترک باید سه کاربرد را پشتیبانی کند: ۱) استفاده داخلی در تجربه‌های اپراتور، Affiliate/Agent و مشتری Lottorito؛ ۲) تعبیه در وب‌سایت پلتفرم‌های دیگر و در آینده اپلیکیشن‌های موبایل؛ ۳) عرضه مستقل با API مستند، ابزار توسعه‌دهنده، کنترل چرخه عمر و مرز پشتیبانی روشن.

پلتفرم میزبان مالک رابطه با مشتری و گردش‌کار تجاری خود است؛ Lottorito مالک قرارداد سرویس چت و کنترل‌های سمت پلتفرم است. Affiliate & Agent و Lottery باید مستقل از هم Chat را فعال کنند. برند میزبان نباید مالکیت، ممیزی‌پذیری یا ردیابی فنی Lottorito را حذف کند.

این سند LOT-COMMS-001 را گسترش می‌دهد؛ انتخاب Vendor، تصویب قیمت/SLA، مجوز پردازش داده در حوزه قضایی یا ادعای پیاده‌سازی نیست.

## ۲. سطوح محصول و شیوه ارائه

یک دامنه مکالمه و هسته Policy پشت چند سطح ارائه قرار گیرد:

- رابط داخلی Lottorito با همان قرارداد عمومی و قواعد مجوزدهی مشتریان بیرونی؛ بدون مسیر ممتاز برای First-party.
- Widget وب میزبانی‌شده: روش پیش‌فرض Embed، ترجیحاً iframe جدا از مبدأ و Cross-origin که با Bootstrap Script کوچک و نسخه‌بندی‌شده بارگذاری می‌شود؛ این روش برخورد CSS/DOM و دسترسی صفحه میزبان را محدود می‌کند.
- Web SDK/Component: Wrapper سبک توسعه‌دهنده روی قرارداد Widget؛ بدون موتور مکالمه دوم یا دورزدن Session.
- SDK بومی موبایل: قابلیت آینده و خارج از نسخه نخست Widget وب، با استفاده از همان قرارداد Session و پیام.
- Headless API: برای پلتفرمی که رابط خودش را می‌سازد اما از سرویس مکالمه، مسیریابی و تحویل Lottorito استفاده می‌کند.

اجرای JavaScript دلخواه شخص ثالث در صفحه میزبان پیش‌فرض نباشد. Web Component مرز امنیتی نیست. Embed پیش‌فرض باید Sandbox و Cross-origin بماند؛ هر کاهش محدودیت Sandbox نیازمند Threat Review جداگانه برای همان قابلیت است.

## ۳. معماری منطقی و مرز اعتماد

این اجزا از هم جدا باشند: ۱) سرویس دامنه چت برای مکالمه، شرکت‌کننده، پیام، تغییر وضعیت، تخصیص و ممیزی؛ ۲) سرویس پیکربندی Widget برای Installation، Originهای مجاز، Locale، Theme، قابلیت‌ها و نسخه تنظیمات؛ ۳) Control Plane یکپارچه‌سازی برای API Clientهای Tenant-scoped، اعتبارنامه، Scope، چرخش، لغو، سهمیه و Webhook؛ ۴) Session Broker برای تبدیل Assertion معتبر Backend میزبان یا Bootstrap ناشناس مجاز به Session کوتاه‌عمر و محدود؛ ۵) Realtime Gateway با WebSocket احراز‌شده و جایگزین SSE/HTTPS Polling و بازیابی مبتنی بر Cursor؛ ۶) پنل Agent و مسیریابی؛ ۷) قرنطینه/اسکن/تحویل پیوست؛ ۸) ممیزی، Policy و تحلیل عملیاتی حافظ حریم خصوصی.

مرزهای اعتماد: Backend میزبان ↔ Control Plane لوتاریتو؛ مرورگر میزبان ↔ مبدأ Widget؛ Widget ↔ APIهای Session/Realtime؛ چت ↔ دایرکتوری Identity/Tenant؛ چت ↔ اعلان، دانش، AI و Agent. هر مرز به احراز هویت، مجوزدهی، اعتبارسنجی، Rate Limit و Observability صریح نیاز دارد.

## ۴. مدل Tenant، Installation و هویت

سلسله‌مراتب پیشنهادی: Tenant به‌عنوان مرز قراردادی/داده؛ Product Entitlement برای فعال‌سازی مستقل Chat؛ Application و محیط ثبت‌شده؛ Widget Installation نام‌گذاری‌شده؛ Conversation؛ و Participant.

هر Tenant می‌تواند چند Application و Installation داشته باشد. محیط Test و Production جدا باشند. شناسه Tenant، Product، Principal، صف، نقش Agent یا Scope که Client ارسال می‌کند هرگز مجوز ایجاد نمی‌کند؛ سرور آن‌ها را از اعتبارنامه Integration و Session احراز‌شده استخراج می‌کند.

هویت بازدیدکننده ناشناس باید opaque و محدود به Installation باشد. اتصال مکالمه ناشناس به حساب احراز‌شده فقط با جریان صریح، مجاز و قابل ممیزی سمت سرور انجام شود. صرف تطبیق ایمیل، تلفن، IP یا اثرانگشت مرورگر نباید باعث ادغام سوابق شود.

## ۵. نصب امن و صدور Session

۱. مدیر Tenant یک Installation می‌سازد و Originهای دقیق مجاز را ثبت می‌کند. Wildcard پیش‌فرض ممنوع است؛ localhost فقط با استثنای صریح محیط توسعه مجاز است.
۲. Backend میزبان Server-to-server با اعتبارنامه Integration محدود به Tenant احراز هویت می‌کند. OAuth 2.0 Client Credentials با احراز هویت نامتقارن Client گزینه‌ای برای ارزیابی است، نه انتخاب مصوب.
۳. Backend میزبان برای Principal تأییدشده یا بازدیدکننده ناشناس Session درخواست می‌کند و فقط Claimهای مجاز و کلید Idempotency یکتا را می‌فرستد.
۴. Lottorito Entitlement، وضعیت Installation، سیاست Origin، Scope، نگاشت Principal و Rate Limit را اعتبارسنجی می‌کند.
۵. Lottorito Token کوتاه‌عمر و مقید به Audience و Installation صادر می‌کند؛ Token از Backend مورد اعتماد میزبان به مرورگر می‌رسد و Secret بلندعمر هرگز به کد مرورگر نمی‌رود.
۶. Widget از Session استفاده می‌کند و به APIهای Realtime متصل می‌شود. تمدید صریح است و اثر لغو باید در بازه‌ای تعریف‌شده و آزموده‌شده رخ دهد.

ناورداهای امنیتی:
- Client Secret، کلید امضا، Credential ارائه‌دهنده یا API Token بلندعمر هرگز در HTML، Bundle مرورگر، باینری موبایل یا Repository عمومی قرار نگیرد.
- Session Token کوتاه‌عمر، محدود از نظر Scope و مقید به Audience/Installation و تا حد امکان غیرقابل‌انتقال باشد؛ انقضا، چرخش، لغو و Clock Skew تعریف شوند.
- Origin/Host دقیق به‌عنوان دفاع تکمیلی اعتبارسنجی شوند، نه جایگزین احراز هویت رمزنگاری‌شده. CORS مجوزدهی نیست.
- Bootstrap در برابر CSRF، Replay، Confused Deputy و جایگزینی Principal بین Tenantها محافظت شود.
- نگهداری Secret، امضای نامتقارن، چرخش کلید و لغو اضطراری ممیزی شوند.
- postMessage به Target Origin دقیق، Schema سخت‌گیرانه، نوع پیام Allowlist‌شده و اعتبارسنجی Origin نیاز دارد؛ برای پیام حساس از Target Origin ستاره‌ای استفاده نشود.
- CSP، iframe sandbox، frame-ancestors، connect-src، referrer policy و رفتار Navigation تعریف شوند.
- فیلد مخفی یا شناسه/Claim ارسالی Client برای Tenant، User، Product، Locale و صف مجوز محسوب نشود.

## ۶. قرارداد API، SDK و سازگاری

گروه منابع API نسخه‌بندی‌شده و مستقل از Provider باید Installation/Configuration؛ صدور و لغو Session؛ Conversation/Participant/Message؛ Cursor خواندن، Typing/Presence و تأیید تحویل؛ Attachment/مجوز دانلود؛ عملیات ممتاز Agent؛ Webhook/تحویل/Replay؛ و Health/Usage/Quota را پوشش دهد.

الزامات: Versioning و مهلت Deprecation روشن؛ خطاهای پایدار، Correlation ID، Pagination و Payload محدود؛ Idempotency Key برای Mutation قابل Retry؛ استفاده مجدد از کلید با Payload canonical متفاوت باید Conflict دهد؛ انتقال At-least-once همراه Deduplication و بدون وعده Exactly-once شبکه؛ Sequence/Cursor یکنواخت و بازیابی پس از Reconnect؛ Webhook امضاشده با Timestamp، Delivery ID، پنجره Replay، چرخش کلید، Retry و Dead-letter؛ Scopeهای حداقلی و جدا برای هر عملیات. SDKها Wrapper سبک‌اند و منطق تجاری ممتاز یا Credential ندارند.

## ۷. ناورداهای پیام و مکالمه

هر پیام دارای Tenant، Conversation، Sender، Visibility، زمان ایجاد، Message ID و Sequence تغییرناپذیر است. پیام مشتری، یادداشت فقط Agent، رویداد سیستم و پیشنهاد AI انواع جدا با Visibility اعمال‌شده در سرورند. Host بدون سیاست و مجوز صریح Tenant به مکالمه Installation دیگر دسترسی ندارد. Retry مرورگر پیام تکراری نمی‌سازد. Realtime اعلان وضعیت پایدار است، نه منبع حقیقت؛ Client با Cursor، Timeline canonical را بازیابی می‌کند. تغییر مالکیت/شرکت‌کننده Audit می‌شود. متن چت هرگز مجوز تغییر مالکیت حساب، تصویب مالی، پرداخت، دورزدن KYC/AML یا تغییر محدودیت استفاده مسئولانه نیست.

## ۸. تجربه Embed، دسترس‌پذیری و بومی‌سازی

چیدمان Responsive دسکتاپ/موبایل، صفحه‌کلید، Screen Reader، Focus Management، Reduced Motion، کنتراست بالا و اعلان وضعیت دسترس‌پذیر لازم است. Widget نباید Focus صفحه میزبان را گرفتار کند و رفتار باز/بسته‌شدن باید قطعی باشد.

تمام ۱۲ Locale در LOT-I18N-001، شامل RTL/LTR، Timestamp محلی، قواعد جمع، جهت ورودی و متن چندخطی ترکیبی پشتیبانی شوند. ترتیب Locale مستند باشد: سیاست Installation، ترجیح کاربر احراز‌شده، انتخاب صریح کاربر و سپس Hint مرورگر. Hint مرورگر انتخاب صریح را بی‌صدا Override نکند. زبان جایگزین پیش از آغاز مکالمه اعلام شود.

Theme فقط از Design Tokenهای اعتبارسنجی‌شده مانند رنگ، مقیاس تایپوگرافی، Radius، فاصله، محل Launcher و حالت روشن/تاریک تشکیل شود. CSS/HTML/Script دلخواه پذیرفته نشود. در صورت الزام قرارداد، نشانه انتساب/مالکیت Lottorito حفظ شود؛ White-label Entitlement جداگانه و نیازمند تصویب است، نه گزینه ضمنی Widget.

## ۹. حریم خصوصی، حاکمیت داده و پیوست

نقش Controller/Processor، هدف، مبنای قانونی، محل داده، نگهداری، حذف، Export و Legal Hold برای هر بازار/قرارداد پیش از فعال‌سازی تعریف شود. Claim میزبان و Transcript حداقلی باشند. Export و حذف Tenant-scoped همراه شواهد ممیزی فراهم شود. داده در انتقال و ذخیره رمزگذاری شود؛ در صورت اقتضای ریسک، مرز کلید و دسترسی ممتاز بر اساس Tenant/طبقه داده جدا شود. Credential و مقادیر حساس از Log، Trace، Analytics و Promptهای AI حذف شوند.

پیوست تا پایان اسکن/اعتبارسنجی در قرنطینه بماند. محدودیت حجم/نوع، Content Sniffing، اسکن بدافزار، Object Storage خصوصی و مجوز دانلود کوتاه‌عمر اعمال شود. استفاده از Transcript برای آموزش مدل یا تحلیل بین Tenantها بدون مبنای حقوقی مستند، اطلاع/رضایت مناسب و تصویب صریح ممنوع است. کنترل Abuse، Spam، Rate، Concurrency، Quota و Denial-of-Service به تفکیک Installation و Tenant تعریف شود.

## ۱۰. عملیات و آمادگی تجاری

Control Plane سلامت Installation، وضعیت Credential، Originهای مجاز، Usage/Quota، خطاهای Webhook، نسخه Configuration و تاریخچه Audit را نمایش دهد. Sandbox/Test از Production جدا باشد و هویت آزمایشی امن و راهنمای تکرارپذیر Integration ارائه شود.

مدیریت خرابی منطقه‌ای، Reconnect/Backoff همراه Jitter، صف محدود، Backpressure، ثبت پایدار پیام، جداسازی پیوست، Retry/تطبیق Webhook و لغو اضطراری لازم است. SLO، محدودیت پیام، نگهداری، قیمت، سطح پشتیبانی و SLA تا زمان شواهد بارکاری و تصویب مالک/تجاری تعیین‌نشده‌اند. تا پیش از تعریف Onboarding، مالک پشتیبانی، شرایط پردازش داده، بازبینی امنیت، Metering و سیاست نسخه/Deprecation، دسترس‌پذیری برای پلتفرم ثالث وعده داده نشود.

## ۱۱. سناریوهای پذیرش خصمانه

تست شود: جایگزینی شناسه Tenant/Installation/Conversation/Principal/Attachment بین درخواست‌ها؛ Replay توکن منقضی/لغوشده یا با Audience اشتباه؛ Origin ثبت‌نشده، Wildcard، زیردامنه مخرب و Origin تهی؛ جعل postMessage و Payload خراب؛ نشت Secret در Source مرورگر/Log/Referrer/Telemetry؛ Replay و دستکاری Body/Signature/Timestamp در Webhook و چرخش کلید؛ درخواست هم‌زمان تکراری پیام و Conflict در Payload تغییرکرده؛ بازیابی Cursor پس از Reconnect بدون فقدان/تکرار؛ دسترسی مشتری به یادداشت داخلی/داده پنهان AI/پیوست Tenant دیگر؛ فایل بیش‌ازحد، خراب، Polyglot و بدافزار آزمایشی؛ مصرف Quota و Flood اتصال بدون اثر بر Tenant دیگر؛ صفحه‌کلید، Screen Reader، RTL/LTR، موبایل، Zoom و Reduced Motion در تمام Localeهای انتشار.

## ۱۲. دروازه انتشار و تصمیم‌های باز

دروازه Pilot: تصویب محدوده پردازش داده/حوزه قضایی؛ بازبینی Threat Model؛ اثبات امنیت Session/Origin؛ تست جداسازی Tenant؛ اثبات Idempotency پیام و Reconnect؛ Pipeline پیوست؛ QA دسترس‌پذیری/بومی‌سازی؛ مستندات Integration؛ مالک عملیاتی و Runbook لغو/بازگشت.

دروازه عرضه عمومی: ارزیابی مستقل امنیت متناسب با ریسک؛ آزمون چرخش کلید و پاسخ حادثه؛ مدل پشتیبانی/SLA؛ سیاست Metering/Billing؛ شواهد Export/حذف؛ سیاست سازگاری و Deprecation API؛ قرارداد Onboarding شریک؛ شواهد ظرفیت و بازیابی.

تصمیم‌های باز: روش احراز هویت، دامنه iframe، Hosting منطقه‌ای/محل داده، نسخه API، انواع پیوست، نگهداری هویت ناشناس، زبان SDK، بسته‌بندی تجاری و سطح پشتیبانی. فقط پس از شواهد و بازبینی مالک نهایی شوند.

## ۱۳. اسناد مرتبط

LOT-COMMS-001؛ LOT-API-001؛ LOT-TEN-001؛ LOT-SEC-TM-001؛ LOT-I18N-001؛ LOT-NOTIF-001؛ LOT-QA-001؛ LOT-TECH-ADR-001.

**یادآوری وضعیت:** فقط معماری و قرارداد پذیرش پیشنهادی است. هیچ Widget، SDK، API، جریان Credential، Provider، گواهی امنیت یا سرویس Production راستی‌آزمایی نشده است.


## ۱۴. پروفایل امنیت مرورگر و دروازه‌های پذیرش اختصاصی Embed

کنترل‌های زیر مرز اعتماد مرورگر را دقیق‌تر می‌کنند و پیش از تأیید پیاده‌سازی الزامی‌اند. این موارد پروتکل احراز هویت یا توپولوژی میزبانی را انتخاب نمی‌کنند.

### ۱۴.۱. مدیریت Session و Token

- Widget مرورگر باید یک Public Client تلقی شود. هیچ Client Secret، کلید امضا، Refresh Token یا اعتبارنامه Integration بلندمدتی نباید به آن تحویل شود.
- Sessionهای Widget فقط از نوع Access، با حداقل Scope مکالمه/Installation، Audience صریح، انقضای کوتاه، شناسه یکتای Session و امکان لغو سمت سرور صادر شوند. تا حد امکان Token در حافظه موقت Frame ایزوله نگهداری شود؛ Bearer Token هرگز در URL، Query، Fragment، ذخیره‌سازی پایدار مرورگر، Referrer، Analytics یا Log قرار نگیرد.
- تمدید Session باید از Backend مورداعتماد میزبان و Session Broker عبور کند. مرورگر نباید بتواند صرفاً با Replay درخواست Bootstrap قبلی، Session جدید بسازد.
- هر Bootstrap به Nonce غیرقابل‌حدس و یک‌بارمصرف، Installation، Origin موردانتظار، هویت Principal/ناشناس، انقضا و Idempotency Key متصل شود. Nonce باید به‌صورت اتمیک مصرف شود؛ Replay، Claim ناسازگار و Retry با Payload تغییرکرده رد شود.
- حداکثر زمان انتشار لغو Session را برای Sessionها، اتصال‌های فعال WebSocket و مجوزهای دانلود پیوست تعریف و تست کنید.

### ۱۴.۲. Origin، Framing و حریم خصوصی مرورگر

- Originهای ثبت‌شده را Canonicalize کرده و Scheme، Hostname و Port را دقیقاً مقایسه کنید. تطبیق Wildcard مبتنی بر Prefix/Suffix، Port غیرمنتظره، Origin مبهم/Null در جریان احراز‌شده و سردرگمی Origin ناشی از Redirect یا دامنه‌های بین‌المللی را رد کنید.
- Origin و CORS فقط کنترل دفاع در عمق سمت مرورگرند؛ آن‌ها Backend میزبان را احراز هویت نمی‌کنند و به Tenant، Installation یا Principal مجوز نمی‌دهند.
- هر دو سمت سیاست Framing را تعریف کنید: Allowlist مربوط به frame-src میزبان و سیاست frame-ancestors مربوط به Widget. در صورت امکان عملیاتی، این سیاست‌ها به Installation نیز محدود شوند.
- حداقل پروفایل sandbox برای iframe و Permissions Policy را مشخص کنید. هر کاهش محدودیت نیازمند Threat Review مستند است؛ Flagهای Sandbox را به شکلی ترکیب نکنید که جداسازی موردنظر Origin/Process از بین برود.
- عملکرد اصلی Chat نباید به Third-party Cookie یا ذخیره‌سازی Cross-site غیرپارتیشن‌بندی‌شده وابسته باشد. رفتار در حالت مسدودبودن Third-party Cookie یا Partition شدن Storage را تعریف و تست کنید. هر مسیر جایگزین باید هویت سمت سرور و کنترل CSRF و Origin را حفظ کند و نباید احراز هویت را بی‌صدا تضعیف کند.

### ۱۴.۳. پیام‌رسانی بین Frameها و Realtime

- هر دریافت‌کننده postMessage باید event.origin دقیق، event.source موردانتظار، Schema نسخه‌بندی‌شده و سخت‌گیرانه، نوع پیام مجاز و اندازه محدود Payload را بررسی کند. همیشه Target Origin دقیق استفاده شود؛ برای پیام حساس هرگز از Wildcard استفاده نکنید.
- Bearer Token، اعتبارنامه Integration، داده خصوصی مکالمه یا فرمان ممتاز از طریق postMessage منتقل نشود. خود Frame باید هر عملیات را مستقلاً مجوزدهی کند.
- Handshake مربوط به WebSocket باید با Session مربوط به Widget احراز هویت شود و Origin موردانتظار نیز به‌عنوان کنترل تکمیلی مرورگر بررسی شود. اعتبارسنجی Origin به‌تنهایی احراز هویت نیست. مجوز هر Subscription، مکالمه و عملیات پیام باید دوباره بررسی شود.
- محدودیت اتصال و اندازه پیام، سهمیه هر Installation و Tenant، Backpressure، انقضای اتصال بیکار، Jitter در اتصال مجدد و رفتار لغو برای Socketهای فعال تعریف شود.

### ۱۴.۴. ماتریس پذیرش خصمانه تکمیل‌شده

علاوه بر بخش ۱۱، تست انتشار باید این موارد را پوشش دهد: XSS در صفحه میزبان و دست‌کاری Bootstrap/CDN؛ Clickjacking و UI Redress؛ Session Fixation و Replay کردن Nonce در Bootstrap؛ Originهای Null/مبهم و Subdomain مخرب؛ Unicode/Punycode و نرمال‌سازی Port؛ دورزدن سیاست Frame؛ postMessage جعلی از Source نادرست؛ مسدودشدن Third-party Cookie و Partition شدن Storage؛ جعل Origin در WebSocket و اتصال مجدد با Session لغوشده؛ تصاحب هویت ناشناس؛ فایل فشرده مخرب و Polyglot؛ و Flood پیام/اتصال بدون اثر بر Tenantهای دیگر.

### ۱۴.۵. پروفایل استانداردها

اگر OAuth 2.0 برای هر جریان قابل‌دسترسی از مرورگر انتخاب شد، پروفایل پیاده‌سازی باید با راهنمای امنیتی جاری IETF، از جمله RFC 9700 و RFC 10017 (OAuth 2.0 for Browser-Based Applications، اوت ۲۰۲۶) بازبینی شود. هرجا مدل تهدید و استقرار اجازه می‌دهد، الگوی Session با واسطه Backend ترجیح داده شود. هر جایگزین باید ریسک افشای Token، اثر XSS، دفاع CSRF، ذخیره‌سازی مرورگر، تمدید/چرخش و مصالحه‌های لغو را مستند کند. این استانداردها راهنمای طراحی‌اند و پیاده‌سازی را گواهی نمی‌کنند.

مراجع:
- [RFC 9700 — بهترین رویه امنیت OAuth 2.0](https://www.rfc-editor.org/rfc/rfc9700.html)
- [RFC 10017 — OAuth 2.0 برای برنامه‌های مبتنی بر مرورگر](https://www.rfc-editor.org/rfc/rfc10017.html)
- [راهنمای امنیت HTML5 از OWASP](https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html)

**محدودیت انتشار:** LOT-CHAT-WIDGET-001 تا زمانی که این کنترل‌ها در قراردادهای مشخص API/Session منعکس نشوند و تست‌های خصمانه مرورگر، جداسازی Tenant و یکپارچه‌سازی را نگذرانند، در وضعیت Proposed باقی می‌ماند.
