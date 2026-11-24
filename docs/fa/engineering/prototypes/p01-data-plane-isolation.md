# جداسازی Tenant در Data Planeهای ثانویه در P-01

**شناسه سند:** LOT-PROT-P01-DATA-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** Prototype ساختگی؛ تأیید CI در انتظار

## هدف

گسترش LOT-PROT-P01-001 فراتر از جدول‌های اصلی PostgreSQL برای آزمایش مرزهای Tenant در Data Planeهای ثانویه؛ مرزهایی که معمولاً در Cache، Object Storage، Search و Reporting از قلم می‌افتند.

این آزمایش از داده ساختگی، Adapterهای In-memory محلی برای Cache/Object Storage/Search و PostgreSQL RLS برای Reporting استفاده می‌کند. اتصال به Redis، ذخیره‌ساز S3-compatible، OpenSearch، Elasticsearch یا Data Warehouse عملیاتی در آن وجود ندارد.

## قراردادهای پیاده‌سازی‌شده

- **Cache:** هر Key از UUID معتبر Tenant که سمت سرور Resolve شده، Namespace امن و یک Segment امن Logical Key ساخته می‌شود. Adapter، شناسه Tenant ارسالی Caller را نمی‌پذیرد.
- **Object Storage:** تمام Object Keyها زیر Prefix مربوط به tenants/{tenantId}/{namespace}/{objectId} قرار می‌گیرند؛ Separator مسیر، Segmentهای Traversal، Separator کدگذاری‌شده و کاراکترهای ناامن پیش از دسترسی به Backend رد می‌شوند.
- **Search:** Adapter فیلتر تغییرناپذیر Tenant را از Context مورداعتماد تزریق می‌کند؛ Caller فقط Query String محدودشده ارائه می‌دهد. Adapter واقعی Provider باید این فیلتر را به فیلتر اجباری Backend تبدیل کند، نه یک Hint برای امتیازدهی.
- **Reporting:** ردیف‌های گزارش هویت ترکیبی محدود به Tenant دارند و Policyهای مستقل PostgreSQL RLS روی خود جدول Reporting اعمال می‌شوند. مدل Shared-GUC و مدل session_user مستقل برای هر Tenant، جدا از جدول‌های منبع آزمایش می‌شوند.

## سناریوهای پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P01-DATA-01 | Logical Cache Key یکسان برای Tenant A و B وجود دارد | Key و Valueها جدا باقی بمانند |
| P01-DATA-02 | Namespace/Key دارای Traversal یا ورودی Path کدگذاری‌شده است | پیش از دسترسی به Backend رد شود |
| P01-DATA-03 | Object ID یکسان در دو Tenant وجود دارد | هر Tenant فقط Object دارای Prefix خودش را بگیرد |
| P01-DATA-04 | Namespace/ID مربوط به Object دارای Path Traversal است | پیش از Backend رد شود |
| P01-DATA-05 | عبارت Search یکسان به سندهای دو Tenant می‌رسد | فقط نتیجه Tenant مورداعتماد بازگردد |
| P01-DATA-06 | Caller تلاش می‌کند Tenant را در ورودی Search Override کند | رد شود؛ فیلتر Tenant از سمت سرور باقی بماند |
| P01-DATA-07 | Report ID/Key یکسان در دو Tenant وجود دارد | هویت ترکیبی و RLS فقط ردیف Tenant جاری را برگردانند |
| P01-DATA-08 | Query گزارش بدون Tenant Context اجرا می‌شود | Default-deny هیچ ردیفی برنگرداند |
| P01-DATA-09 | Role مشترک برنامه، Tenant دیگری را فیلتر می‌کند | RLS هیچ ردیف بین‌مستاجری برنگرداند |
| P01-DATA-10 | Role دیتابیسی LOGIN یک Tenant، گزارش Tenant دیگر را می‌خواند | RLS متصل به هویت دیتابیس هیچ ردیفی برنگرداند |

## محدودیت‌های امنیتی و عملیاتی

- Adapterهای In-memory فقط قرارداد Adapter و ساخت Key را اثبات می‌کنند؛ ACLهای Redis، رفتار Cluster/Keyspace، سیاست IAM در S3، Versioning، CDN، Alias/Filter در OpenSearch، چرخه عمر Index، Row-Level Security در Warehouse یا جداسازی Export را اثبات نمی‌کنند.
- اعمال فیلتر Search به Adapter واقعی هر Provider وابسته است؛ Backendی که فیلتر را نادیده بگیرد، مرز جداسازی را بی‌اعتبار می‌کند.
- Cache Invalidation، انقضای TTL، Stampede Protection، Distributed Lock، چرخه عمر Object، انقضای Signed URL، CDN Cache، Reindex کردن Search، Extractهای تحلیلی و تحویل Export/Download هنوز آزمایش نشده‌اند.
- محدودیت اعتماد custom-GUC در Role مشترک app_runtime مطابق LOT-PROT-P01-001 همچنان وجود دارد. مدل session_user مستقل برای هر Tenant در این آزمایش قوی‌تر است، اما Credential Broker و مقیاس‌پذیری Connection Pool هنوز باز هستند.

## وضعیت شواهد

کد و سناریوها در یک Draft PR پشته‌شده پیاده‌سازی شده‌اند. CI، اجرای محلی، رفتار Provider واقعی، عملکرد و بازیابی خطا تا زمان ثبت شواهد مشاهده‌شده تأییدنشده‌اند. هیچ آمادگی Production یا انتخاب Provider ادعا نمی‌شود.
