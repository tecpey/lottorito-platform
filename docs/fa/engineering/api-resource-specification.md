# مشخصات منابع و قرارداد API در Lottorito

**شناسه سند:** LOT-API-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** خط مبنای پیشنهادی؛ نیازمند بازبینی معماری و مالک

## ۱. هدف و محدوده
قراردادهای مشترک API برای محصولات مستقل Affiliate & Agent و Lottery تعریف می‌شود. این پیشنهاد مستقل از Provider است؛ API پیاده‌سازی‌شده، قرارداد OpenAPI منتشرشده، تعهد سازگاری یا مجوز ارائه Endpoint نیست. API عمومی، Tenant، شریک و داخلی مخاطبان جداگانه‌اند و نباید Credential یا فرض اعتماد مشترک داشته باشند.

## ۲. اصول طراحی
از API منبع‌محور HTTP، اسم دامنه‌ای صریح، JSON روی HTTPS برای Request/Response استاندارد، معنای پایدار، نسخه‌بندی روشن، سازگاری رو به عقب و مهلت حذف استفاده کنید. Context محصول/Tenant از مجوزدهی احرازشده استخراج شود، نه پارامتر دلخواه. اعتبارسنجی، خطا، Pagination، Idempotency، Rate Limit، Observability و Audit یکدست باشند. نام جدول دیتابیس یا Payload Provider قرارداد عمومی canonical نیست. تغییر افزایشی ترجیح دارد؛ تغییر ناسازگار به نسخه Major جدید و برنامه مهاجرت نیاز دارد.

## ۳. قرارداد Resource و URL
الگوی پیشنهادی: /v1/{resource-collection}/{resource-id}. مسیر تو‌در‌تو رابطه واقعی مالکیت/چرخه عمر را نشان دهد، نه Join دیتابیس؛ از تو‌در‌تویی عمیق پرهیز شود.

از نام جمع برای Collection، حروف کوچک و kebab-case، شناسه Opaque، Timestamp استاندارد ISO 8601 با Offset صریح (UTC Z برای تبادل ماشینی ترجیح دارد)، کد ISO 4217 و Decimal دقیق یا واحد خرد صحیح با Metadata توان اعشاری استفاده کنید. اعتبار و امتیاز غیرفیاتی به نوع واحد صریح نیاز دارند. Secret، داده شخصی، مجوز قابل‌تغییر یا هویت معتبر Tenant در URL قرار نگیرد.

## ۴. مخاطبان و احراز هویت
- API کاربر: Session احرازشده یا Token تفویض‌شده OAuth/OIDC.
- مدیریت Tenant: Principal محدود به Tenant با Scope مدیریتی صریح.
- API شریک: هویت Integration اختصاصی هر شریک، Scope محدود، جداسازی محیط و Credential قابل‌ابطال.
- سرویس داخلی: Workload Identity و Credential کوتاه‌عمر؛ بدون Master Token ثابت و مشترک.
- Webhook: پیام امضاشده با کنترل Replay؛ اصالت آن جایگزین مجوزدهی عملیات حاصل نیست.

احراز هویت هویت را اثبات می‌کند؛ مجوزدهی باید جداگانه عضویت، Entitlement محصول، مالکیت شیء، Scope عملیات و وضعیت سیاست را بررسی کند.

## ۵. Context Tenant و محصول
عضویت را از Session معتبر، Claim اعتبارسنجی‌شده با Membership جاری یا رکورد اتصال ماشینی حل کنید. Header/پارامتر Tenant فقط در صورت پشتیبانی صریح Selector است و باید با Principal تطبیق یابد. هر درخواست به دامنه محصول متصل و از نظر Entitlement بررسی شود. Context مفقود، مبهم یا متعارض رد شود؛ Tenant پیش‌فرض بی‌صدا انتخاب نشود. Context از سرویس تا Transaction، Event، Queue، Log و Export منتقل شود. Credential شریک از مرز Tenant/محصول عبور نکند.

## ۶. قرارداد Request و Response
برای Body JSON، Content-Type مربوط لازم است. UTF-8، طول، عمق، حدود عددی، Enum و فیلد ناشناخته طبق سیاست Schema اعتبارسنجی شوند. POST برای ایجاد/عملیات، GET برای خواندن امن، PATCH برای تغییر جزئی، PUT فقط برای جایگزینی کامل و DELETE فقط با معنای امن و قانونی استفاده شود. برای کار Async پایدار 202 Accepted همراه Resource وضعیت یا Callback برگردد. نمایش Resource پایدار باشد. برای تغییر حساس به هم‌زمانی ETag/Version استفاده و Write قدیمی رد شود.

## ۷. مدل خطا
Envelope ماشین‌خوان پایدار با Code، پیام انسانی قابل‌بومی‌سازی، Request/Correlation ID و جزئیات امن فیلد استفاده شود. Stack Trace، SQL، Secret Provider، Hostname داخلی یا وجود Resource در Tenant دیگر افشا نشود. Statusهای پیشنهادی: 400 درخواست خراب؛ 401 احرازنشده؛ 403 غیرمجاز؛ 404 غایب یا عمداً پنهان؛ 409 تعارض وضعیت/Idempotency؛ 412 شکست پیش‌شرط؛ 422 ورودی تجاری نامعتبر؛ 429 محدودیت نرخ؛ 500 خطای داخلی؛ 502/503/504 شکست کنترل‌شده وابستگی.

## ۸. Pagination، Filter و Sort
برای Collection بزرگ/متغیر Cursor Pagination ترجیح دارد. data و next_cursor برگردند؛ has_more فقط در صورت مفید بودن. تعداد دقیق کل پیش‌فرض تضمین نشود. حداکثر اندازه صفحه و Allowlist محدود Filter/Sort اعمال شود. ترتیب قطعی با Tie-breaker یکتا لازم است. پیش از Pagination بر اساس Tenant، محصول، مجوز و سطح مشاهده Scope کنید. Export محدود یا Async، مجاز و ممیزی‌شده باشد. عملگر Filter و شمول بازه زمانی مستند شود.

## ۹. Idempotency و هم‌زمانی
عملیات غیرIdempotent کلید Idempotency-Key با Scope، مدت نگهداری و اتصال به Payload مستندشده بگیرند. Scope کلید شامل Tenant، Principal/Integration، عملیات و Resource باشد. کلید، Hash نرمال درخواست، مرجع نتیجه و وضعیت ذخیره شود. کلید و Payload یکسان نتیجه اصلی/وضعیت فعلی را بدهد؛ Payload متفاوت Conflict است. Duplicate هم‌زمان به یک اثر واحد همگرا شود. Idempotency API جایگزین Source Event/Economic Effect در امور مالی نیست. برای Optimistic Concurrency از ETag/If-Match یا Version استفاده شود.

## ۱۰. Rate Limit و حفاظت منابع
سهمیه چندلایه بر اساس Tenant، Principal کاربر/سرویس، Credential، IP/ریسک، Route و هزینه عملیات اعمال شود. Burst، سهمیه پایدار، Header، راهنمای Retry و Fair-use تعریف شوند. گزارش پرهزینه، پیمایش گراف، Export و Fan-out Provider بودجه مستقل و پردازش Async می‌خواهند. رفتار Rate Limit نباید فعالیت Tenant دیگر را افشا کند.

## ۱۱. قرارداد Webhook
تحویل را حداقل یک‌بار فرض کنید، مگر قرارداد Provider خلاف آن را اثبات کند؛ مصرف‌کننده باید Idempotent باشد.

Headerهای پیشنهادی: X-Lottorito-Event-Id، X-Lottorito-Delivery-Id، X-Lottorito-Key-Id، X-Lottorito-Timestamp، X-Lottorito-Signature و Content-Type.

نمایش بایتی canonical از Timestamp، Key ID، Event ID و Raw Body با الگوریتم/نسخه مستند امضا شود. پیش از اعتماد به Claimهای Parse‌شده امضا را بررسی کنید؛ تحمل زمانی اعمال و Replay خارج از پنجره رد شود؛ شناسه Event/Economic Effect Deduplicate شود. چرخش کلید با هم‌پوشانی و فرایند ابطال انجام شود.

فقط پس از دریافت پایدار ACK بدهید. Retry با Exponential Backoff محدود و Jitter؛ تعداد تلاش، DLQ، مجوز Replay دستی و Observability تحویل تعریف شود. Delivery ID معرف تلاش تحویل است، نه اثر اقتصادی.

## ۱۲. نسخه‌بندی و چرخه عمر
نسخه Major در مسیر (/v1) باشد؛ فیلد افزایشی سازگار در همان Major مجاز است. معنای فیلد، واحد، Enum یا رفتار مجوزدهی بی‌صدا تغییر نکند. عملیات منسوخ علامت‌گذاری و پیش از حذف، راهنمای مهاجرت، تاریخ Sunset، پنجره سازگاری و جایگزین منتشر شود. Adapter Provider مستقل از API عمومی نسخه‌بندی شود. تست قرارداد مصرف‌کننده/Provider نگهداری شود؛ بدون اجرای تست ادعای سازگاری نکنید.

## ۱۳. Observability و Audit
هر درخواست Request/Correlation ID تولیدشده سرور داشته باشد. Trace Context با ایمنی بین سرویس/Job منتقل شود. Principal، Tenant، محصول، Route Template، نتیجه، Latency و تصمیم Rate Limit بدون Secret/Payload حساس ثبت شوند. تغییر مالی، مجوز، هویت و تنظیمات به Audit Event تغییرناپذیر با Actor، دلیل، هدف، تأیید و ارجاع قبل/بعد نیاز دارد.

## ۱۴. حاکمیت OpenAPI
قرارداد مصوب با OpenAPI 3.1 یا نسخه بالاترِ صریحاً پذیرفته‌شده نگهداری شود. Schema، مثال، خطای مشترک، احراز هویت/Scope، مجوز Tenant/محصول، Idempotency/Concurrency، Pagination/Rate Limit، امضای Webhook/Event و Metadata منسوخ‌شدن را پوشش دهد. Artifact فقط از قرارداد canonical بازبینی‌شده تولید شود. CI باید Syntax، تغییر ناسازگار، مثال و تطابق با پیاده‌سازی را بررسی کند. وجود فایل OpenAPI اثبات وجود Endpoint نیست.

## ۱۵. تست‌های قراردادی ضروری
احراز هویت/مجوز هر مخاطب؛ رد دسترسی بین Tenant/محصول؛ مجوز Object/Function؛ اعتبارسنجی و حدود؛ پایداری Cursor/ترتیب/Filter/حد صفحه؛ Replay و تعارض Payload و Duplicate هم‌زمان Idempotency؛ Optimistic Concurrency؛ امضا/Timestamp/Replay/Duplicate/چرخش Webhook؛ Rate Limit/Fair-use/Exhaustion؛ سازگاری و Deprecation؛ Redaction خطا و انتشار Correlation.

## ۱۶. تصمیم‌های باز
API Gateway و Hosting، پروفایل OAuth/OIDC، قالب/عمر Token، چرخه Credential شریک، مرز API عمومی/خصوصی، Tierهای Rate Limit، Workflow تولید OpenAPI، پنجره نگهداری/Retry Webhook، محل داده و فهرست Resourceهای نسخه اول نیازمند تأیید مالک و معماری‌اند.

این مشخصات ادعا نمی‌کند هیچ Endpointی پیاده‌سازی یا در دسترس است.
