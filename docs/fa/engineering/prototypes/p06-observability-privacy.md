# P-06 — مشاهده‌پذیری سرتاسری و حریم خصوصی

**شناسه سند:** LOT-PROT-P06-001 | **نسخه:** ۰.۲.۰ | **وضعیت:** Integration ساختگی P-06 و Documentation Governance روی Head PR با شناسه 9f30a2966ce77aca8a7df6acf8e803733bd723dd موفق شدند؛ تصویب Instrumentation/حریم خصوصی Production از این نتیجه برداشت نمی‌شود

## اعتبار و مرز

P-06 بررسی می‌کند آیا یک رویداد ساختگی Affiliate & Agent از ورودی Partner تا احراز اصالت، Inbox، Attribution، ارزیابی کمیسیون، Outbox، Worker، ثبت دفترکل و تطبیق، قابل بازسازی است؛ بدون اینکه Telemetry به دفترکل دوم تبدیل شود یا Secret و داده شخصی غیرضروری افشا شود.

این آزمایش از Fixture دورریختنی دفترکل P-02 در PostgreSQL 18.7 برای ثبت یک Journal واقعیِ ساختگی و متوازن استفاده می‌کند. سپس Fixture سیاست Telemetry مبتنی بر PostgreSQL را با شناسه‌های سازگار با W3C Trace Context، Spanهای به‌سبک OpenTelemetry، Log ساختاریافته، Metric با برچسب محدود، مالکیت Alert، RLS محدود به Tenant و دروازه دسترسی Forensic ممیزی‌شده اضافه می‌کند.

این کار لایه Instrumentation پیاده‌سازی‌شده در برنامه، OpenTelemetry Collector مستقرشده، SIEM، سرویس Alerting، گواهی حریم خصوصی یا ممیزی امنیت Production نیست. هیچ داده واقعی کاربر، شریک، مالی یا Credential استفاده نمی‌شود.

## مبنای تحقیق

- استاندارد W3C Trace Context انتشار traceparent/tracestate را یکپارچه می‌کند و استفاده از این فیلدها برای اطلاعات قابل‌شناسایی شخصی یا حساس را صریحاً ممنوع می‌داند.
- راهنمای Context Propagation در OpenTelemetry هشدار می‌دهد که Credential، API Key یا PII در Baggage قرار نگیرد؛ Semantic Convention مربوط به Messaging انتشار Message Creation Context را برای ارتباط کار Producer و Consumer توصیه می‌کند.
- OWASP Logging Cheat Sheet حذف یا Mask کردن Access Token، شناسه Session، گذرواژه، Connection String دیتابیس، کلید رمزنگاری، داده کارت پرداخت و PII غیرضروری را توصیه می‌کند؛ همچنین اعتبارسنجی، Encoding امن، تشخیص دست‌کاری و محدودیت دسترسی لازم است.
- راهنمای Instrumentation در Prometheus نسبت به Label با Cardinality بالا مانند User ID و Email هشدار می‌دهد؛ هر مجموعه یکتای Label یک Time Series دیگر ایجاد می‌کند.
- OpenTelemetry Collector امکان Transform/Filter Telemetry را دارد، اما Redaction Processor در نسخه Contrib بلوغ ترکیبی دارد (برای Log/Metric آلفا و برای Trace بتا طبق وضعیت مرجع). بنابراین Redaction در Collector دفاع تکمیلی است، نه مرز اصلی حریم خصوصی برنامه.
- NIST SP 800-92 راهنمای منتشرشده مدیریت Log است؛ راهنمای برنامه‌ریزی SP 800-92 Rev. 1 در فرایند بازنگری/پیش‌نویس است و به‌عنوان کنترل نهایی و الزام‌آور تلقی نمی‌شود.

## آزمایش ساختگی

### ۱. Trace سرتاسری و اتصال به دفترکل

۱. Schema موجود دفترکل P-02 را در دیتابیس دورریختنی PostgreSQL 18.7 اعمال کنید.
۲. یک Journal متوازن USD را از طریق تابع واقعی ثبت P-02 و با Role اجرایی Tenant A ثبت کنید.
۳. Trace ID و Span ID تصادفی با قالب W3C بسازید؛ زنجیره Parent را میان ورودی Partner، احراز اصالت، ذخیره Inbox، Attribution، محاسبه کمیسیون، انتشار Outbox، مصرف Worker، ثبت Ledger و Reconciliation ایجاد کنید.
۴. همان Trace Context را از مرز ناهمزمان Producer/Consumer عبور دهید. شناسه Tenant/User، Credential یا PII در traceparent، tracestate یا baggage قرار نگیرد.
۵. ارجاع‌های مبهم HMAC برای Tenant، Actor، Source Event، Economic Effect و Journal را در Spanهای محدود به دسترسی قرار دهید. Mapping شناسه خام به ارجاع مبهم در جدول Forensic محدودشده نگهداری شود.
۶. بررسی کنید ارجاع Source Event در سراسر Trace، ارجاع Economic Effect از مرحله احراز شرایط به بعد و ارجاع واقعی Journal مربوط به P-02 در Spanهای Ledger و Reconciliation حاضر باشند.

### ۲. کنترل حریم خصوصی و تزریق Log

- Canary ساختگی برای Access Token، API Key، Session Cookie، Password، Database URL، Email، Phone و Card PAN ایجاد کنید. این مقادیر در Payload منبعِ درون حافظه و پیام Exception ساختگی قرار گیرند.
- فقط فیلدهای ساختاریافته Allowlistشده، Event Name محدود، Message Code امن، ارجاع‌های Pseudonymous و نوع Exception/Error Code ثبت شوند. متن خام Exception یا Payload خام در Telemetry ذخیره نشود.
- Event Type حاوی CR/LF و Canary ارسال کنید. فقط Event اعتبارسنجی ناموفق با نام محدود و Reason Code ثبت شود.
- Baggage حاوی Email، API Key و Tenant ID ارائه کنید؛ به‌جای انتشار، حذف شود.
- Span، Log، Metric، Alert و Privileged Audit را برای تمام Canaryها، شناسه‌های خام و نام فیلدهای ممنوع اسکن کنید.

### ۳. Scope مربوط به Tenant و دسترسی Forensic

- Span و Log با ارجاع Tenant مشتق‌شده از HMAC ذخیره و Row-Level Security با استفاده از Mapping نقش دیتابیس احرازشده به Tenant اعمال شود؛ نه فیلد Tenant ارسالی Caller.
- ثابت کنید Tenant A Trace و Log خودش را می‌خواند و Tenant B هیچ ردیفی نمی‌بیند. Telemetry Reader به Raw Correlation Map دسترسی ندارد.
- Forensic Reader باید پیش از خواندن View مربوط به Mapping خام به مبهم، Reason Code تأییدشده را ثبت کند؛ آن هم در همان Session دیتابیس. Actor Ref، Action، Target Trace، Reason و Outcome در جدول Privileged Audit فقط‌افزودنی ثبت شوند.
- UPDATE/DELETE روی Audit رد شود.

### ۴. سلامت Metric و Alert

- ۵۰۰ هویت Tenant ساختگی ایجاد کنید، اما Metricها را فقط با ابعاد محدود Operation، Outcome، Product Domain و Reason Code تجمیع کنید.
- ثابت کنید Schema مربوط به Metric ستون Tenant/User/Event/Actor/Journal ID ندارد و تعداد Series متمایز محدود می‌ماند.
- Alert برای انباشت Queue، شکاف Reconciliation، قطعی Provider، نقض Invariant دفترکل و رد Authorization ایجاد کنید. هر Alert باید Severity، Owner Team و شناسه پایدار Runbook داشته باشد.

## معیارهای پذیرش

- P06-LEDGER: یک Journal واقعی P-02 ثبت و در Trace ارجاع شود.
- P06-TRACE: نه Span یک Trace معتبر سازگار با W3C و زنجیره Parent کامل تشکیل دهند.
- P06-CORRELATION: ارجاع Source Event، Economic Effect و Journal در Spanهای مورد انتظار سازگار باشند.
- P06-ASYNC: Spanهای Producer/Outbox و Worker ارتباط Trace را حفظ کنند.
- P06-PRIVACY: هیچ Canary مربوط به Secret/PII، شناسه خام Tenant/User یا فیلد ممنوع در Telemetry نباشد.
- P06-BAGGAGE: Baggage حساس حذف شود.
- P06-INJECTION: ورودی CR/LF در Event Name به Event اعتبارسنجی ناموفق با نام محدود تبدیل شود.
- P06-TENANT: RLS فقط Span/Log مربوط به Tenant احرازشده را برگرداند.
- P06-FORENSIC: Mapping خام تا ثبت دسترسی دارای Reason در دسترس نباشد؛ دسترسی ممیزی شود.
- P06-AUDIT: Privileged Audit در برابر UPDATE/DELETE مقاوم باشد.
- P06-CARDINALITY: ۵۰۰ Tenant ساختگی تعداد Metric Series را فراتر از مجموعه Label محدود افزایش ندهند.
- P06-ALERTS: هر پنج کلاس Alert دارای Severity، Owner و Runbook باشند.

## ایمنی و محدودیت‌ها

- Harness شناسه‌های Trace سازگار با W3C و رکوردهای Span به سبک OTel می‌سازد، اما OpenTelemetry SDK را به برنامه Lottorito متصل نمی‌کند و OTLP را به Collector/Exporter واقعی نمی‌فرستد.
- کلید HMAC فقط مواد موقت CI است. Custody، Rotation، سازگاری Pseudonym میان سرویس‌ها و حاکمیت Re-identification همچنان باز هستند.
- RLS و Role Mapping در PostgreSQL اثبات ساختگی کنترل دسترسی است، نه طراحی کامل مجوزدهی پلتفرم Telemetry.
- رمزنگاری ذخیره‌سازی Log/Trace، چرخه Retention/Deletion، Data Residency بین‌منطقه‌ای، Sampling، Hardening Collector، کنترل Export، SLOهای Production، ارسال Alert، Paging یا Runbook واقعی پیاده‌سازی نمی‌شوند.
- Owner/Runbook مربوط به Alert فقط به‌عنوان Metadata بررسی می‌شود؛ Routing واقعی Alert انجام نمی‌شود.
- Log، Span، Metric و Audit دفترکل نیستند و هرگز نباید برای محاسبه موجودی یا مجازکردن انتقال مالی استفاده شوند.
- RPO/RTO، مبنای قانونی، الزامات حریم خصوصی هر حوزه قضایی و سیاست دسترسی Telemetry در Production نیازمند تصمیم مالک/امنیت/حقوقی هستند.



## شواهد نهایی CI

- Integration مربوط به P-06 با شناسه [45535315659](https://github.com/tecpey/lottorito-platform/actions/runs/45535315659) و Documentation Governance با شناسه [45535315503](https://github.com/tecpey/lottorito-platform/actions/runs/45535315503) روی Head PR با شناسه `9f30a2966ce77aca8a7df6acf8e803733bd723dd` موفق شدند.
- نه Span مرتبط، Journal واقعی P-02 را از Ingress شریک تا Reconciliation متصل کردند. اجرا ۵۰۰ ارجاع یکتای Tenant ساختگی تولید کرد، در حالی که فقط چهار Metric Series باقی ماند.
- همه Assertionها موفق شدند: Journal مربوط به P-02، Parent Chain سازگار با W3C، ارتباط Trace ناهمزمان، نبود Secret/PII Canary، فیلتر Baggage، نرمال‌سازی Log Injection، RLS مربوط به Tenant، دسترسی Forensic ممیزی‌شده، Least Privilege، Audit فقط‌افزودنی، Cardinality محدود و Owner/Severity/Runbook مربوط به Alert.
- اجرای اولیه Harness فقط به‌دلیل مقایسه متن Boolean در PostgreSQL با مقدار اشتباه شکست خورد: خروجی `false` با شکل نمایشی psql یعنی `f` مقایسه شده بود؛ Assertion اصلاح شد و اجرای نهایی PR موفق شد.

## منابع

- https://www.w3.org/TR/trace-context/
- https://opentelemetry.io/docs/concepts/context-propagation/
- https://opentelemetry.io/docs/specs/semconv/messaging/messaging-spans/
- https://opentelemetry.io/docs/collector/transforming-telemetry/
- https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/redactionprocessor
- https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- https://prometheus.io/docs/practices/instrumentation/
- https://prometheus.io/docs/practices/naming/
- https://csrc.nist.gov/pubs/sp/800/92/final
- https://csrc.nist.gov/Projects/log-management

## الحاقیه P-09B — Correlation آگاه از Scope (۲۰۲۶-۱۱-۲۵)

ادامه P-09 کلید Correlation ساختگی را از `(tenant_id, source_event_id)` به `(tenant_id, scope_kind, scope_id, source_event_id)` گسترش می‌دهد. Session و Grant دسترسی Forensic نیز به همین Tuple به‌علاوه `trace_id` مقید می‌شوند؛ View مربوطه تمام ابعاد را تطبیق می‌دهد، نه فقط Trace ID را. Runner مربوط به P-06 یک UUID یکسان Tenant/Source Event را برای Affiliate و Lottery ثبت می‌کند و اثبات می‌کند Grant مربوط به Affiliate فقط ردیف Affiliate را برمی‌گرداند و Grant مستقل Lottery فقط ردیف Lottery را. Workflow مربوط به P-06 روی Candidate فعلی P-09 دروازه پذیرش است؛ این همچنان Fixture ساختگی است، نه مجوزدهی Telemetry در Production.
