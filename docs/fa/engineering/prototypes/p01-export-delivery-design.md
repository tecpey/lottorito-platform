# مطالعه طراحی تحویل امن Export در P-01

**شناسه سند:** LOT-PROT-P01-DELIVERY-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیشنهاد مبتنی بر تحقیق؛ هیچ معماری تحویل یا Provider تصویب نشده است

## ۱. زمینه تصمیم

PR شماره ۴۴ یک Primitive مجوزدهی ساختگی را اثبات می‌کند: می‌توان Grant یک‌بارمصرف، زمان‌دار و متصل به Tenant و Subject را صادر و به‌صورت Atomic Redeem کرد. این PR عمداً بایت‌های فایل را Stream نمی‌کند و به Object Storage واقعی متصل نیست.

آزمایش بعدی باید فاصله میان Redeem موفق Grant و تحویل قابل‌اعتماد فایل را حل کند. نباید فرض شود URL امضاشده Provider نیز به‌خاطر یک‌بارمصرف بودن Grant، خودش یک‌بارمصرف است.

## ۲. شواهد منابع اولیه

- مستند رسمی Amazon S3 می‌گوید Presigned URL تا زمان انقضا می‌تواند چند بار استفاده شود و یک Bearer Capability است؛ هر فردی که URL را در اختیار داشته باشد می‌تواند عملیات امضاشده را اجرا کند. S3 انقضا را هنگام شروع درخواست بررسی می‌کند؛ انتقالی که آغاز شده می‌تواند پس از انقضا ادامه یابد، اما درخواست Restart‌شده ممکن است رد شود. انقضای Credential موقت یا لغو آن می‌تواند اعتبار URL را زودتر تمام کند. منبع: [AWS — Download and upload objects with presigned URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html).
- OWASP برای دانلود امن، Content-Disposition: attachment، نوع application/octet-stream برای محتوای ناشناخته/باینری و هدر X-Content-Type-Options: nosniff را توصیه می‌کند. منبع: [OWASP HTTP Headers Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html).
- راهنمای OWASP درباره Path Traversal توصیه می‌کند ورودی کاربر در مسیر فایل استفاده نشود و شناسه‌های تولیدشده سمت سرور به مسیر ذخیره‌شده نگاشت شوند. منبع: [OWASP Path Traversal Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Path_Traversal_Prevention_Cheat_Sheet.html).
- مستند Node.js 26، pipeline را برای مدیریت Backpressure و خطاهای Stream معرفی می‌کند و پشتیبانی از لغو با AbortSignal را توضیح می‌دهد. منبع: [Node.js v26 Stream API](https://nodejs.org/api/stream.html).

## ۳. گزینه‌های تحویل

| گزینه | ویژگی امنیتی | هزینه عملیاتی | توصیه فعلی |
|---|---|---|---|
| Streaming Proxy از طریق برنامه | در هر درخواست می‌توان Subject، Tenant، Membership، Session و وضعیت Export را دوباره بررسی کرد؛ URL مربوط به Provider از سرور خارج نمی‌شود | بار Egress، اتصال و Streaming بر عهده برنامه است؛ Backpressure، لغو، Range و Retry باید پیاده‌سازی شوند | گزینه کاندید ترجیحی برای Exportهای حساس مالی و Affiliate |
| URL امضاشده کوتاه‌عمر Provider | ترافیک Storage از برنامه عبور نمی‌کند؛ Provider می‌تواند مجوز سطح Object و انقضای کوتاه اعمال کند | URL تا زمان انقضا یک Bearer Capability قابل Replay است؛ لغو وابسته به Provider و سیاست Credential است؛ احتمال افشای Query String وجود دارد | گزینه مشروط برای فایل‌های بزرگ، فقط پس از اثبات Guardrailهای Provider |
| URL عمومی یا نیمه‌عمومی Object | مجوزدهی در هر درخواست ضعیف یا غایب است | ساده، اما ناسازگار با تضمین خصوصی بودن Exportهای Tenant | رد می‌شود |

**نکته مهم:** ترکیب Grant یک‌بارمصرف با Presigned URL، دسترسی End-to-End یک‌بارمصرف ایجاد نمی‌کند. Grant فقط یک‌بار مصرف می‌شود؛ URL حاصل تا انقضای Provider قابل Replay است. این تفاوت باید در مستندات محصول و امنیت صریح باشد.

## ۴. جهت پیشنهادی آزمایش

ابتدا یک Adapter مستقل از Provider برای Streaming از طریق برنامه با منبع Object ساختگی In-memory بسازیم. تا پیش از عبور قرارداد Adapter و Threat Model از Gateهای پذیرش، Provider واقعی متصل نشود.

### ۴.۱ چرخه عمر Session

هنگام Redeem شدن Grant یک رکورد مستقل download_sessions ساخته شود:

created → active → completed

وضعیت‌های استثنایی:

- failed_retryable: Retry محدود تا زمانی که Lease و مجوز معتبر باشند
- revoked: Membership کاربر، وضعیت Export یا کنترل مدیریتی Session را نامعتبر کرده است
- expired: TTL مربوط به Session تمام شده است
- failed_terminal: سقف Retry تمام شده یا بررسی Integrity شکست خورده است

Grant پس از ایجاد Session مصرف‌شده باقی می‌ماند. Session یک قابلیت تحویل کوتاه‌عمر و مجزا است که به tenant_id، subject_id و export_id متصل می‌شود و نباید به URL قابل‌استفاده مجدد در سطح کل Tenant تبدیل شود.

### ۴.۲ کنترل‌های الزامی

۱. پیش از شروع هر Transfer یا درخواست Range، Membership، اتصال Subject، آماده بودن Export و وضعیت Session دوباره بررسی شود.

۲. فقط Hash مربوط به Secret نشست ذخیره شود. Secretهای Grant/Session نباید در Query String، Log، Analytics، Referrer یا پیام خطا قرار بگیرند.

۳. Bucket/Container خصوصی بماند. Adapter ذخیره‌سازی، Object Key مشتق‌شده از رکورد Export را از سرور دریافت کند؛ Client نباید Object Key یا مسیر فایل ارسال کند.

۴. قرارداد Provider-neutral به نام openReadStream یک Readable Stream و Metadata مورداعتماد شامل Size، Content Type، Version/ETag و Checksum در صورت پشتیبانی برگرداند.

۵. از Node.js stream.pipeline با لغو متصل به قطع Client/Abort درخواست استفاده شود. Backpressure رعایت شود؛ کل فایل در حافظه برنامه Buffer نشود.

۶. معنای Range دقیق تعریف شود: Byte Rangeها اعتبارسنجی شوند، پاسخ‌های صحیح 206/416 و Content-Range برگردند، Version فایل ثابت بماند و Resume به‌اشتباه از Object دیگری نخواند.

۷. Headerهای امن استفاده شوند: Content-Disposition: attachment با مدیریت نام فایل سازگار با RFC 6266، نوع محتوای تأییدشده یا application/octet-stream، هدر X-Content-Type-Options: nosniff و Cache خصوصی/بدون ذخیره.

۸. رویدادهای Append-only برای ایجاد Session، شروع Transfer، تکمیل، قطع، Retry، لغو و شکست Integrity ثبت شوند. Token خام، URL امضاشده یا Object Key حساس در Log ذخیره نشود.

۹. Size فایل و Checksum مورداعتماد بررسی شوند. نباید فرض کرد ETag در S3 همیشه Checksum از نوع SHA-256 است؛ به‌ویژه برای Objectهای Multipart.

۱۰. TTL نشست، تعداد Retry، تعداد Transfer هم‌زمان برای هر Subject/Tenant، حداکثر Size، مدت Stream و Egress کل Tenant محدود شوند.

### ۴.۳ الزام Retry و Idempotency

طراحی باید گم‌شدن پاسخ HTTP پس از Redeem شدن Grant و قطع Client در میانه انتقال را صریحاً حل کند. Prototype اولیه باید یک Session با Retry/Range Resume محدود را با چرخش Credential نشست جدید و احرازشده متصل به Idempotency Key مقایسه کند.

Grant مصرف‌شده را بی‌صدا دوباره فعال نکنید. Retry باید به همان Subject و Tenant احرازشده متصل بماند و نباید دانلودهای موازی نامحدود بسازد.

## ۵. سناریوهای پذیرش آزمایش بعدی

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P01-DELIVERY-01 | Session معتبر Stream را آغاز می‌کند | فقط Export متصل به همان Session ارسال شود |
| P01-DELIVERY-02 | Subject یا Tenant متفاوت است | پیش از دسترسی به Object رد شود |
| P01-DELIVERY-03 | Membership/Export/Session پس از ایجاد Session لغو می‌شود | Transfer یا درخواست Range بعدی رد شود |
| P01-DELIVERY-04 | Client وسط Stream قطع می‌شود | Stream بالادستی لغو و منابع آزاد شوند |
| P01-DELIVERY-05 | Client کند است | Backpressure حافظه را محدود کند؛ فایل کامل Buffer نشود |
| P01-DELIVERY-06 | Range معتبر برای Resume می‌آید | همان Version تغییرناپذیر Object و Byte Range صحیح برگردد |
| P01-DELIVERY-07 | Range نامعتبر یا خارج از محدوده است | 416 قطعی یا سیاست مستند؛ بدون خواندن Object دیگر |
| P01-DELIVERY-08 | پس از خطای موقت Retry انجام می‌شود | فقط Retry محدود در همان Session مجاز باشد |
| P01-DELIVERY-09 | Session تکمیل شده یا سقف Retry تمام شده است | Replay رد شود |
| P01-DELIVERY-10 | نام فایل یا MIME Type ناامن است | Headerهای Attachment امن و nosniff اعمال شوند |
| P01-DELIVERY-11 | Object در Storage موجود نیست یا Checksum مغایر است | تکمیل موفق ثبت نشود؛ شکست Integrity در Audit ثبت شود |
| P01-DELIVERY-12 | Adapter جایگزین URL امضاشده Provider را فعال می‌کند | Replay تا انقضا صریحاً نمایش و Guard شود؛ هرگز یک‌بارمصرف توصیف نشود |

## ۶. تصمیم‌های باز

- حداکثر حجم Export، مدت Stream، پشتیبانی Range و سقف Retry.
- تفاوت سیاست دانلود برای Operatorهای B2B، Agentها و مشتریان B2C.
- الزامات Data Residency، رمزنگاری در حالت سکون، Malware Scanning و Retention/Deletion.
- پشتیبانی Provider واقعی از Checksum قابل‌اعتماد، Object Versioning و کنترل‌های Revocation.
- بودجه Egress و ظرفیت برای Proxy Streaming در برابر URL امضاشده.
- الزامات نگهداری Audit، دسترسی Support و Incident Response.

## ۷. مرز محدوده

این سند صرفاً مطالعه طراحی است. HTTP Endpoint، Storage Adapter، جدول Session، URL امضاشده، Worker مربوط به Stream یا اتصال Provider را پیاده‌سازی نمی‌کند. هیچ Provider ذخیره‌سازی، Cloud Account، Bucket Policy، کلید Production یا معماری تحویل تصویب نشده است.
