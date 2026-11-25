# P-07A — ترکیب مستقل محصولات: جداسازی Build و Runtime

**شناسه سند:** LOT-PROT-P07A-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیاده‌سازی اولیه ساختگی؛ اعتبارسنجی CI در انتظار اجرا

## پرسش تصمیم

آیا Affiliate & Agent و Lottery می‌توانند هرکدام بدون بسته‌بندی، Import یا فعال‌سازی ماژول محصول دیگر Build و راه‌اندازی شوند؟

P-07A نخستین زیرمرحله از سه بخش اجرایی P-07 است:
- **P-07A:** جداسازی ترکیب، Build و Runtime محصولات.
- **P-07B:** مالکیت قابلیت‌های مشترک پلتفرم، مجوزدهی و مرزهای اعتماد بین محصولات.
- **P-07C:** چرخه عمر مستقل محصولات، پیکربندی، Migration و عملیات.

آزمایش مادر همچنان LOT-PROT-001 است. این زیرمرحله به معنی بسته‌شدن P-07 نیست.

## روش مبتنی بر تحقیق

این آزمایش از مرزهای قابلیت کسب‌وکار استفاده می‌کند، نه صرفاً لایه‌های فنی افقی. عمداً Microservices یا دیتابیس‌های جداگانه را از پیش تحمیل نمی‌کند: Bounded Context در DDD یک مرز دامنه است و الزاماً به معنی جداسازی Deployment نیست. یک Manifest صریح ترکیب محصول و بررسی وابستگی در زمان Build به‌عنوان Architectural Fitness Function استفاده می‌شود. سپس Artifact در فرایند Python تازه‌ای اجرا می‌شود که فقط ماژول محصول منتخب و Port ساختگی پلتفرم مشترک را در اختیار دارد.

این روش با راهنمای Microsoft درباره تحلیل دامنه و مرزبندی Bounded Context هم‌راستاست و در عین حال جداسازی Tenant را مسئله امنیتی مستقلی می‌داند (راهنمای OWASP Multi-Tenant Security). آزمون قراردادها و اثبات‌های قوی‌تر مجوزدهی به P-07B واگذار شده‌اند.

## Fixture ساختگی

- دو شناسه محصول: `affiliate_agent` و `lottery`.
- Portهای مشترک: Context ساختگی هویت، Context ساختگی Tenant و Audit Sink.
- قابلیت Smoke ترکیب متعلق به هر محصول.
- بدون وابستگی خارجی، دیتابیس، شبکه، Provider زنده، شریک، کاربر، Tenant واقعی یا داده مالی.
- Manifest هر محصول صفر بودن وابستگی به محصول دیگر را اعلام و وابستگی به محصول خواهر را صریحاً ممنوع می‌کند.

مرحله Build یک Artifact حداقلی با دقیقاً چهار فایل تولید می‌کند: `product.py`، `platform_core.py`، `manifest.json` و `run.py`. ماژول محصول دیگر کپی نمی‌شود. Entry Pointهای محصول از نظر Import مستقیم، Package-qualified و Dynamic بررسی می‌شوند.

## آزمایش‌ها و معیارهای قبولی

| شناسه | آزمایش | معیار Pass |
|---|---|---|
| P07A-01 | Build محصول Affiliate & Agent | Artifact فقط با Entry Point همین محصول و Portهای مشترک ساخته شود |
| P07A-02 | اجرای Affiliate & Agent | فرایند تازه راه‌اندازی شود و نتیجه Smoke متعلق به همان محصول را برگرداند |
| P07A-03 | Build محصول Lottery | Artifact فقط با Entry Point Lottery و Portهای مشترک ساخته شود |
| P07A-04 | اجرای Lottery | فرایند تازه راه‌اندازی شود و نتیجه Smoke متعلق به همان محصول را برگرداند |
| P07A-05 | اعمال محدودیت وابستگی | Import مستقیم و Dynamic محصول خواهر رد شود و Manifest هیچ وابستگی محصولی نداشته باشد |
| P07A-06 | بازرسی Artifact | هیچ ماژول یا Package متعلق به محصول خواهر در Artifact وجود نداشته باشد |
| P07A-07 | انتساب Port مشترک | خروجی Audit ساختگی، هویت محصول منتخب را حفظ کند |

هر شکست به معنی شکست P-07A است؛ Pass جزئی به‌عنوان موفقیت کل P-07 ثبت نمی‌شود.

## روش بازتولید

از ریشه مخزن:

```bash
python3 -m compileall -q prototypes/p07-product-composition
python3 -m unittest discover -s prototypes/p07-product-composition/tests -v
python3 prototypes/p07-product-composition/build.py affiliate_agent --out /tmp/lottorito-p07a-affiliate
python3 /tmp/lottorito-p07a-affiliate/run.py
python3 prototypes/p07-product-composition/build.py lottery --out /tmp/lottorito-p07a-lottery
python3 /tmp/lottorito-p07a-lottery/run.py
```

CI در مسیر `.github/workflows/p07a-product-composition.yml` تعریف شده است. نتیجه CI باید به Head دقیق PR متصل باشد تا بتوان Pass ثبت کرد.

## محدودیت‌های صریح

- این یک Harness ساختگی برای ترکیب محصولات است، نه برنامه Lottorito یا یک Package Production.
- عملیات Smoke فقط راه‌اندازی ماژول و ترکیب را اثبات می‌کند؛ هیچ جریان Referral/Commission در Affiliate یا Ticket/Draw/Prize در Lottery را پیاده‌سازی یا اثبات نمی‌کند.
- توابع هویت، Tenant و Audit مشترک، Stub هستند. احراز هویت، مجوزدهی، RLS، Ledger، Event Broker، مالکیت داده، رمزنگاری یا جداسازی Tenant اثبات نشده است.
- تحلیل Static Import محدود است و Scanner عمومی وابستگی‌های Python یا اثبات امنیت در برابر اجرای کد دلخواه نیست.
- Deployment مستقل، Migration، Rollback، چرخه عمر Configuration یا قابلیت ردیابی White-label اثبات نشده‌اند؛ این موارد متعلق به P-07C هستند.
- هیچ معماری Production، تفکیک Microservice، توپولوژی دیتابیس، Vendor یا فناوری تصویب نشده است.
- هیچ داده Production، Credential واقعی، وجه واقعی، Merge یا Deploy استفاده نمی‌شود.

## مراجع تحقیق

- Microsoft Learn، [تحلیل دامنه برای مدل‌سازی Microservices](https://learn.microsoft.com/en-us/azure/architecture/microservices/model/domain-analysis).
- Microsoft Learn، [طراحی Microservices با DDD تاکتیکی](https://learn.microsoft.com/en-us/azure/architecture/microservices/model/tactical-ddd).
- OWASP، [راهنمای امنیت چندمستاجری](https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html).
- AWS Well-Architected، [الگوهای معماری SaaS Lens](https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/software-and-architecture-patterns.html).
- Pact، [قراردادهای Consumer-Driven](https://docs.pact.io/).
