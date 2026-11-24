# P-02 — نمونه دفترکل مالی و تطبیق

**شناسه سند:** LOT-PROT-P02-001 | **نسخه:** ۰.۲.۰ | **وضعیت:** Prototype موقت؛ شواهد CI در انتظار | **تاریخ بازبینی:** ۲۰۲۶-۱۱-۲۴

## هدف و مرز تصمیم

P-02 یک آزمایش با داده‌های ساختگی برای زیرساخت ثبت مالی موردنیاز عملیات Affiliate/Agent است. این آزمایش مبالغ دقیق، ثبت دوطرفه، مرزهای Tenant/Product/Currency، Idempotency، تغییرناپذیری، برگشت سند، Outbox اتمیک و Reconciliation را بررسی می‌کند.

این آزمایش محصول Wallet، درگاه پرداخت، سرویس Payout، قابلیت نمایش موجودی مشتری یا تصویب هیچ سیاست تجاری کمیسیون نیست. مبلغ Source Event به‌عنوان ورودی ساختگی و از پیش محاسبه‌شده از سیستم بالادستی تأمین می‌شود. هیچ تعریف NGR، نرخ کمیسیون، قانون احراز شرایط، عمق شبکه، نرخ FX، اعتبار Agent یا قاعده تسویه در اینجا ساخته یا تصویب نمی‌شود.

## برش آزمایشی پیاده‌سازی‌شده

- PostgreSQL 18.7 با Role اختصاصی ledger_runtime که NOSUPERUSER و NOBYPASSRLS است و مالک جدول‌ها نیست.
- محدوده Tenant و Product در Account، Source Event، Journal، Effect، Entry و Outbox نگهداری می‌شود؛ RLS هر دو Context مربوط به Tenant و Product را که در سطح تراکنش تنظیم شده‌اند الزامی می‌کند.
- Registry ارز، تعداد رقم اعشار مجاز را نگهداری می‌کند؛ Fixture از USD با ۲ رقم، USDT با ۶ رقم و BTC با ۸ رقم استفاده می‌کند.
- مبالغ از NUMERIC(38,18) دقیق PostgreSQL استفاده می‌کنند و مرز Node فقط Decimal String می‌پذیرد. برای مبالغ از محاسبات Floating-point در JavaScript استفاده نمی‌شود.
- هر Journal باید حداقل دو Entry داشته باشد و مجموع Debit/Credit را برای هر Currency به‌صورت مستقل متعادل کند تا بتواند از draft به posted منتقل شود.
- Foreign Key مرکب Account/Currency مانع ثبت Entry دلاری در Account تتر می‌شود.
- Scale مجاز ارز در لحظه درج Source Event و Ledger Entry در دیتابیس کنترل می‌شود؛ Foreign Key مرکب Account/Currency مانع جایگزینی ارز می‌شود.
- Journal و Entryهای Posted تغییرناپذیرند. اصلاح با Journal برگشتی جدید انجام می‌شود که Entryهای آن باید دقیقاً معکوس اصل باشند؛ Constraint یکتا از برگشت کامل دوم جلوگیری می‌کند.
- Economic Effect هم با هویت پایدار اثر تجاری و هم با Idempotency Key محافظت می‌شود. Request Fingerprint مانع استفاده مجدد از Key با Payload مالی متفاوت است.
- تحویل هم‌زمان یک اثر تکراری با Unique Constraint دیتابیس Serialize می‌شود؛ فقط یک Journal/Effect/Outbox باید ثبت نهایی شود.
- Journal، Economic Effect، Entryها و Outbox Event در یک تراکنش PostgreSQL نوشته می‌شوند. Deferred Constraint Trigger در زمان Commit الزام می‌کند Effect و Outbox فقط به Journal ثبت‌شده اشاره کنند. وجود Source Event نیز در همان تراکنش و محدوده Tenant/Product بررسی می‌شود.
- Reconciliation، انتظار ثبت‌شده مستقل Source Event را با Entryهای Posted حساب Affiliate Payable مقایسه می‌کند و Posting مفقود یا نامنطبق را گزارش می‌دهد.
- مانده حساب‌ها از Ledger Entryهای Posted محاسبه می‌شود؛ هیچ ستون Mutable برای Balance به‌عنوان منبع حقیقت وجود ندارد.
- تست‌های ساختگی، RLS مربوط به Tenant و Product، دقت Decimal، Idempotency تکراری/هم‌زمان، Journal نامتعادل، دقت اعشار ارز، توازن مستقل ارزها، تغییرناپذیری، Reversal و انحراف Reconciliation را پوشش می‌دهند.

## ماتریس پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P02-LEDGER-01 | ثبت Accrual دوخطی کمیسیون | Journal ثبت‌شده؛ Debit و Credit برابر؛ یک Outbox Event |
| P02-LEDGER-02 | Replay همان اثر تجاری | Journal قبلی برگردانده شود؛ Effect یا Outbox تکراری ایجاد نشود |
| P02-LEDGER-03 | تحویل هم‌زمان یک Effect | دقیقاً یک Journal/Effect Commit شود |
| P02-LEDGER-04 | استفاده مجدد از Identity/Key با Fingerprint متفاوت | Conflict؛ بدون Journal اضافه |
| P02-LEDGER-05 | تلاش برای ثبت Journal نامتعادل | Posting رد و تمام Writeها Rollback شوند |
| P02-LEDGER-06 | ثبت مبلغ با اعشار بیشتر از Scale ارز | دیتابیس مبلغ را رد کند |
| P02-LEDGER-07 | خنثی‌کردن Debit دلاری با Credit تتر | رد شود؛ Currencyها قابل Net کردن نیستند |
| P02-LEDGER-08 | تغییر/حذف Journal یا Entry ثبت‌شده | رد شود؛ اصلاح فقط با Reversal |
| P02-LEDGER-09 | برگشت Journal ثبت‌شده | Journal معکوس جدید؛ اصل بدون تغییر باقی بماند |
| P02-LEDGER-10 | برگشت دوباره همان Journal | Reversal دوم رد شود |
| P02-LEDGER-11 | تطبیق Posting مفقود یا تکراری | Source Event مفقود/نامنطبق آشکار شود |
| P02-LEDGER-12 | تغییر/حذف Source Event یا Economic Effect | رد شود |
| P02-LEDGER-13 | درج مستقیم Journal با وضعیت Posted | رد شود؛ گذار Draft به Posted الزامی است |
| P02-LEDGER-14 | خواندن Ledger متعلق به Tenant/Product دیگر | RLS هیچ ردیف بیگانه‌ای برنگرداند |
| P02-LEDGER-15 | محاسبه Decimal دقیق و ثبت مقدار Token | Decimal String بدون تبدیل Floating-point در JavaScript حفظ شود |
| P02-LEDGER-16 | بررسی Role اجرایی و Query بدون Tenant/Product Context | Runtime مالک جدول و BYPASSRLS نباشد؛ Context غایب هیچ ردیفی برنگرداند |
| P02-LEDGER-17 | اتصال Entry دلاری به Account تتر | Foreign Key مرکب Account/Currency جایگزینی ارز را رد کند |
| P02-LEDGER-18 | ثبت Event خارج از محدوده Source Event همان Tenant/Product | Posting پیش از ساخت Journal رد شود |
| P02-LEDGER-19 | Commit کردن Effect/Outbox متصل به Journal در وضعیت Draft | Deferred Constraint در زمان Commit تراکنش را رد کند |

## اجرای محلی و بازتولیدپذیری

فقط از دیتابیس محلی و دورریختنی استفاده کنید. اسکریپت Setup اشیای Fixture مربوط به P-02 را حذف و دوباره ایجاد می‌کند؛ هرگز آن را به دیتابیس مشترک، Staging یا Production متصل نکنید.

    cd prototypes/p02-financial-ledger
    docker compose up -d
    export ADMIN_DATABASE_URL='postgres://postgres:p02-admin-only-not-for-production@127.0.0.1:55433/lottorito_p02'
    export RUNTIME_DATABASE_URL='postgres://ledger_runtime:p02-runtime-not-for-production@127.0.0.1:55433/lottorito_p02'
    npm ci --ignore-scripts --no-audit --no-fund
    npm test
    docker compose down -v

تمام Credentialها و داده‌های این آزمایش ساختگی هستند و نباید در جای دیگری استفاده شوند.

## محدودیت‌های امنیتی و حسابداری

- P-02 برای RLS از الگوی Role مشترک و Custom GUC استفاده می‌کند. در P-01 نشان داده شد Role مشترک برنامه در صورت تسخیر می‌تواند GUC را تغییر دهد؛ بنابراین این Prototype اثبات جداسازی در برابر مهاجم نیست.
- این Prototype هنوز Workflow حاکمیت Chart of Accounts، وجوه Pending/Available/Held، قفل جلوگیری از Overdraft، Serialize کردن Account در بار هم‌زمان بالا، تجمیع چند Ledger، تبدیل FX، مالیات، سیاست Rounding، Chargeback، تسویه Payout یا Reconciliation با بانک/Provider خارجی را مدل نمی‌کند.
- Reconciliation فعلی مقایسه Source Event ساختگی است، نه اتصال به صورت‌حساب بانک یا Partner.
- Outbox به‌صورت اتمیک ذخیره می‌شود، اما Broker خارجی، Retry ناشر، Dead-letter Queue یا Deployment مصرف‌کننده انتخاب نشده است.
- هیچ ادعایی درباره Load، Failover، Backup/Restore، Disaster Recovery، Penetration Test، بازبینی حقوقی/حسابداری یا آمادگی Production وجود ندارد.
- P-02 تا زمان تحقیق و آزمایش مرزهای باقی‌مانده همچنان جزئی است.

## منابع تحقیق

- PostgreSQL 18 — [Numeric Types](https://www.postgresql.org/docs/18/datatype-numeric.html)، [Constraints](https://www.postgresql.org/docs/18/ddl-constraints.html)، [CREATE TRIGGER و Deferred Constraint Trigger](https://www.postgresql.org/docs/18/sql-createtrigger.html)، [INSERT / ON CONFLICT](https://www.postgresql.org/docs/18/sql-insert.html)، [Transaction Isolation](https://www.postgresql.org/docs/18/transaction-iso.html) و [Serialization Failure Handling](https://www.postgresql.org/docs/18/mvcc-serialization-failure-handling.html).
- AWS Prescriptive Guidance — [الگوی Transactional Outbox](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html)، شامل نوشتن اتمیک Database/Outbox و Idempotency برای تحویل At-least-once.
- Modern Treasury — [Ledger Guarantees](https://docs.moderntreasury.com/ledgers/docs/ledgers-guarantees)، [Ledger Transaction Overview](https://docs.moderntreasury.com/ledgers/docs/ledger-transactions-overview) و [Transaction Status and Balances](https://docs.moderntreasury.com/ledgers/docs/transaction-status-and-balances). این‌ها منابع مرجع طراحی صنعتی هستند، نه توصیه یا انتخاب Vendor.
- Martin Fowler — [Patterns for Accounting](https://martinfowler.com/eaaDev/AccountingNarrative.html) و [Accounting Transaction](https://martinfowler.com/eaaDev/AccountingTransaction.html)؛ منبع دوم صراحتاً پیش‌نویس تاریخی است و صرفاً برای مفاهیم بنیادی استفاده شده است.

## جایگاه در زنجیره تغییرات

این PR بر شاخه P-01 با نام spike/p01-tenant-isolation قرار می‌گیرد. PR شماره ۳۶ را Merge نمی‌کند، شاخه main را تغییر نمی‌دهد، Deploy انجام نمی‌دهد و به RaidenBet یا هیچ Payment Provider متصل نمی‌شود.
