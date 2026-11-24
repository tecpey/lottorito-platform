# Grant دانلود Export متصل به Tenant در P-01

**شناسه سند:** LOT-PROT-P01-EXPORT-001 | **نسخه:** ۰.۸.۰ | **وضعیت:** Prototype ساختگی؛ ۳۸ تست CI موفق؛ سرویس تحویل تأییدنشده

## هدف

آزمایش مرز مجوزدهی میان Export تکمیل‌شده یک Tenant و عملیات بعدی دانلود آن. وجود یک ردیف Export محدود به Tenant کافی نیست؛ اعتبار دانلود باید به Subject احرازشده متصل باشد، منقضی شود، در برابر Replay مقاوم باشد و پس از لغو Export قابل استفاده نباشد.

این آزمایش از داده ساختگی PostgreSQL 18.7 و Prototype موجود Node.js 26 استفاده می‌کند. Endpoint دانلود HTTP یا اتصال به Provider ذخیره‌سازی شیء در آن پیاده‌سازی نشده است.

## قرارداد پیاده‌سازی‌شده

- هویت Export ترکیبی است: `(tenant_id, export_id)`؛ دیتابیس Prefix دقیق Tenant و یک Segment امن نام فایل را اعمال می‌کند و Traversal، Separator کدگذاری‌شده و Prefix متعلق به Tenant دیگر را رد می‌کند.
- هنگام صدور و Redeem، فعال‌بودن Membership همان Subject در Tenant با قفل ردیف `FOR SHARE` دوباره بررسی می‌شود.
- صدور Grant به Tenant Resolve‌شده در سمت سرور، Subject احرازشده، Export ایجادشده توسط همان Subject و وضعیت `ready` نیاز دارد.
- Token دارای ۲۵۶ بیت تصادفی رمزنگاری‌شده و امن است و فقط یک‌بار برگردانده می‌شود. PostgreSQL فقط Hash از نوع SHA-256 را ذخیره می‌کند و هرگز Raw Token را نگه نمی‌دارد.
- Grant به Tenant، Subject و Export متصل است؛ زمان انقضا با ساعت PostgreSQL محاسبه می‌شود.
- TTL به بازه ۶۰ تا ۶۰۰ ثانیه محدود است؛ مقدار پیش‌فرض ۳۰۰ ثانیه است.
- صدور Grant و Redeem، عضویت فعال Tenant را در همان Transaction محدود به Tenant دوباره بررسی می‌کنند و قفل Membership از نوع `FOR SHARE` می‌گیرند تا با لغو Membership Serialize شوند.
- هنگام Redeem، ردیف Grant و Export قفل می‌شوند؛ Tenant/Subject/Hash/Expiry/Revocation/Export Status بررسی و سپس `consumed_at` به‌صورت اتمیک ثبت می‌شود.
- Redeem موفق فقط Object Key داخلی و Checksum را به لایه مورداعتماد سرور برمی‌گرداند؛ URL عمومی یا Credential ذخیره‌سازی برگردانده نمی‌شود.
- RLS محدود به Tenant و Foreign Key ترکیبی، ردیف‌های Export و Grant را مستقل از هم محافظت می‌کنند.

## سناریوهای پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P01-EXPORT-01 | مالک احرازشده برای Export آماده درخواست Grant می‌دهد | یک Token با Entropy بالا صادر شود |
| P01-EXPORT-02 | دیتابیس Grant تازه‌صادرشده را بررسی می‌کند | فقط Hash توکن ذخیره شده باشد |
| P01-EXPORT-03 | Subject دیگری تلاش به Redeem می‌کند | Grant برنگردد و مصرف نشود |
| P01-EXPORT-04 | Tenant دیگری تلاش به Redeem می‌کند | Grant برنگردد و مصرف نشود |
| P01-EXPORT-05 | مالک Grant معتبر را Redeem می‌کند | Object Key داخلی و Checksum فقط یک‌بار برگردد |
| P01-EXPORT-06 | همان Token دوباره استفاده می‌شود | Redeem رد شود |
| P01-EXPORT-07 | Grant طبق ساعت دیتابیس منقضی شده است | Redeem رد شود |
| P01-EXPORT-08 | Export پس از صدور Grant لغو می‌شود | Redeem رد شود |
| P01-EXPORT-09 | دو درخواست هم‌زمان یک Token را Redeem می‌کنند | دقیقاً یکی موفق شود |
| P01-EXPORT-10 | TTL خارج از بازه ۶۰ تا ۶۰۰ ثانیه یا Token نامعتبر است | درخواست Fail-closed شود |
| P01-EXPORT-11 | عضویت Tenant پس از صدور Grant لغو می‌شود | صدور Grant جدید و Redeem کردن Grant قبلی رد شود |
| P01-EXPORT-11 | Membership کاربر پس از صدور Grant لغو می‌شود | صدور Grant جدید و Redeem Grant قبلی رد شود |
| P01-EXPORT-12 | لغو Membership با Redeem در حال اجرا هم‌زمان می‌شود | قفل‌های FOR SHARE و FOR UPDATE عملیات را Serialize کنند؛ تراکنشی که زودتر قفل ردیف را می‌گیرد ترتیب مجوزدهی را تعیین کند |
| P01-EXPORT-13 | Object Key مربوط به Export دارای Traversal، Separator کدگذاری‌شده یا Prefix Tenant دیگر است | Constraint دیتابیس، ردیف را پیش از رسیدن به Adapter ذخیره‌سازی رد کند |

## مرزهای امنیتی و محدودیت‌ها

- این یک Primitive برای مجوزدهی دانلود است، نه سرویس کامل End-to-end. Endpoint استریم HTTP، Adapter ذخیره‌سازی شیء، Pre-signed URL در S3، CDN، اسکن بدافزار/محتوا، Range Request، Audit دانلود، Quota، Rate Limit یا چرخه عمر Retention پیاده‌سازی نشده‌اند.
- برنامه باید Subject را مستقل از Token احراز کند؛ Token به‌تنهایی اثبات هویت نیست. Membership فعال Tenant هنگام Redeem نیز دوباره بررسی می‌شود، نه فقط هنگام صدور Grant.
- Object Key باید در سمت سرور باقی بماند. به Bucket عمومی Redirect نکنید و Credential ذخیره‌سازی را افشا نکنید.
- اگر برنامه بعداً URL امضاشده Provider صادر کند، Expiry، معنای Revocation، پنجره Replay و Cache Header آن به Threat Model جداگانه نیاز دارد. URL Provider ممکن است پس از مصرف Grant دیتابیس همچنان قابل استفاده باشد.
- Redeem یک‌بارمصرف در صورت قطع اتصال Client پس از مصرف Token و پیش از دریافت فایل، مسئله Retry ایجاد می‌کند. جریان Production باید صریحاً بین Server Streaming، Delivery Lease کوتاه‌مدت یا طراحی Download Session با Idempotency انتخاب کند.
- محدودیت اعتماد custom-GUC در Role مشترک `app_runtime` که در LOT-PROT-P01-001 مستند شده، همچنان برقرار است. این آزمایش جداسازی در برابر Role دیتابیس برنامه‌ای که کاملاً Compromise شده باشد را اثبات نمی‌کند.
- هیچ آمادگی Production ادعا نمی‌شود.

## وضعیت شواهد

آخرین اجرای P-01 با شناسه [45427819046](https://github.com/tecpey/lottorito-platform/actions/runs/45427819046) روی Head کد `46d8e837ab1c3b5f54ad2b17d6119419020b52f8` تعداد ۳۷ تست موفق، صفر شکست و صفر Skip داشته است؛ از جمله Serialization قطعی لغو Membership با Redeem در حال اجرا در آزمایش دو اتصالی. سپس Constraint دیتابیس برای Object Key و تست‌های Traversal/Separator کدگذاری‌شده/Prefix Tenant دیگر اضافه شد؛ CI جدید در انتظار است. اجرای Documentation Governance با شناسه [45427818883](https://github.com/tecpey/lottorito-platform/actions/runs/45427818883) روی Head مستندات قبلی موفق شد. اجرای محلی و تحویل دانلود با Provider واقعی هنوز تأیید نشده‌اند.

کد، Schema و سناریوهای یکپارچه‌سازی ساختگی در یک Draft PR پشته‌شده پیاده‌سازی شده‌اند. تمام Fixtureها و Credentialها ساختگی‌اند.
