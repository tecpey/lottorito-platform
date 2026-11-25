# P-07C — چرخه عمر مستقل محصول، انتشار و ردیابی White-label

**شناسه سند:** LOT-PROT-P07C-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیاده‌سازی ساختگی؛ اعتبارسنجی CI در انتظار اجرا

## پرسش تصمیم

آیا هر محصول می‌تواند برای هر Tenant به‌صورت مستقل فعال/غیرفعال، پیکربندی، Migration، ارتقا و Rollback شود، در حالی که قابلیت‌های مشترک پلتفرم، داده و Ledger موجود و قابلیت ردیابی Tenant/Operator حفظ شوند؟

P-07C سومین زیرمرحله اجرایی P-07 است:
- P-07A: جداسازی Build و Runtime محصولات.
- P-07B: مالکیت قابلیت‌های مشترک و مرزهای اعتماد.
- **P-07C: چرخه عمر مستقل، پیکربندی، Migration، عملیات انتشار و ردیابی White-label.**

## طراحی مبتنی بر تحقیق

Fixture، فعال‌بودن محصول برای Tenant، پیکربندی محصول، چرخه عمر Schema و ارتقای Release را انتقال‌های وضعیت مستقل در نظر می‌گیرد. خاموش‌کردن یک محصول نباید قابلیت‌های مشترک Identity، Tenant، Finance، Notifications یا Audit را غیرفعال کند و نباید داده محصول یا تاریخچه Ledger را حذف کند.

پیکربندی بر اساس Tenant و محصول Namespace مستقل دارد. مقدار Secret پذیرفته نمی‌شود و فقط Reference غیرمحرمانه Secret مجاز است. مالکیت Migration صریح است. Migration هر محصول فقط Schema متعلق به همان محصول را تغییر می‌دهد؛ Migration پلتفرم مشترک به نقش Platform Migration نیاز دارد. Migration از نوع Expand فقط زمانی مجاز است که Release فعال Schema مقصد را پشتیبانی کند. Migration از نوع Contract علاوه بر آن، به فعال‌بودن Release جدید تعیین‌شده و بازنشستگی هر Rollback Pointer ناسازگار نیاز دارد. بازنشستگی Pointer باعث حذف Artifact قدیمی یا داده نمی‌شود.

ارتقای Release، شناسه محصول، محیط Staging، سازگاری Schema، Digest فایل و رکورد ساختگی با ساختار in-toto/SLSA را بررسی می‌کند. Promotion با Compare-and-Swap نسبت به Release فعال مورد انتظار انجام می‌شود. Rollback فقط Pointer انتشار همان محصول را تغییر می‌دهد و اگر Release مقصد Schema فعلی را نخواند رد می‌شود.

این روش از راهنمای چرخه عمر و جداسازی Tenant در SaaS، الگوی Expand/Contract و SLSA Provenance الهام گرفته است. هیچ سامانه Deployment، توپولوژی دیتابیس، Secret Manager یا Verifier زنجیره تأمین Production انتخاب نشده است.

## Fixture ساختگی Tenant و محصولات

- tenant-alpha تحت مدیریت operator-alpha و brand-alpha است. Affiliate & Agent فعال و Lottery غیرفعال است؛ اما Configuration، Release Pointer، نسخه Schema، تعداد رکوردها و شمارنده Ledger مربوط به Lottery باقی می‌مانند.
- tenant-beta تحت مدیریت operator-beta و brand-beta است. هر دو محصول فعال‌اند.
- Schema پیکربندی هر محصول مستقل است. تنظیمات دارای Secret فقط Reference با پیشوند secret:// می‌پذیرند.
- Schemaهای متعلق به محصولات به‌صورت منطقی با Namespaceهای affiliate_agent و lottery مشخص شده‌اند؛ Schema پلتفرم متعلق به پلتفرم مشترک است.
- تمام محیط‌ها فقط Staging هستند. این Fixture امکان Production Deployment ندارد.

## ایمنی Expand/Contract و Rollback

توالی Migration در Affiliate عمداً مرحله‌بندی شده است:
1. اجرای affiliate-expand-v2 در حالی که affiliate-v1 نسخه‌های Schema شماره ۱ و ۲ را پشتیبانی می‌کند.
2. رد affiliate-contract-v3 تا زمانی که affiliate-v1 نسخه فعال است.
3. ارتقای affiliate-v2 که Schema شماره ۳ را پشتیبانی می‌کند.
4. رد Contract تا وقتی affiliate-v1 هنوز Rollback Target است؛ زیرا Schema شماره ۳ را نمی‌تواند بخواند.
5. بازنشستگی صریح Rollback Pointer قدیمی با Compare-and-Swap و تأیید مشخص. Artifact قدیمی در Registry باقی می‌ماند.
6. اجرای Contract Migration. پس از آن Rollback به Release بازنشسته‌شده در دسترس نیست.

به این ترتیب از بین رفتن مسیر Rollback قدیمی صریح و کنترل‌شده است و انقباض ناسازگار Schema به‌صورت پنهانی مجاز نمی‌شود.

## Fixture مربوط به Release Provenance

هر Release ساختگی شامل موارد زیر است:
- شناسه محصول، نسخه، محیط Staging و وضعیت Validated؛
- SHA-256 Artifact Digest و Source Revision؛
- رکوردی با ساختار in-toto Statement v1 و Predicate Type مربوط به SLSA Provenance، Digest موضوع، Source Revision و Builder ID؛
- نسخه‌های Schema پشتیبانی‌شده.

Fixture فقط سازگاری فیلدها را بررسی می‌کند. امضا، Builder مورد اعتماد، Transparency Log، SBOM یا انطباق واقعی با SLSA را اعتبارسنجی نمی‌کند.

## آزمایش‌ها و معیارهای قبولی

| شناسه | آزمایش | معیار Pass |
|---|---|---|
| P07C-01 | فعال‌سازی/غیرفعال‌سازی مستقل | غیرفعال‌کردن یک محصول، وضعیت محصول خواهر را تغییر ندهد |
| P07C-02 | حفظ وضعیت | رکوردها، شمارنده Ledger، پیکربندی، Release و Schema پس از Disable/Enable حفظ شوند |
| P07C-03 | تداوم پلتفرم مشترک | Identity، Tenant، Finance، Notifications و Audit فعال بمانند |
| P07C-04 | محدودیت محصول غیرفعال | عملیات جدید و تغییر Configuration هنگام Disable رد شوند |
| P07C-05 | جداسازی Configuration | کلیدها و نسخه‌های Config مستقل باشند؛ دسترسی محصول خواهر و Tenant دیگر رد شود |
| P07C-06 | انضباط Secret Reference | Secret خام رد شود؛ فقط Reference پذیرفته و هرگز در Audit ثبت نشود |
| P07C-07 | مالکیت Migration | Runner یک محصول نتواند Migration محصول خواهر یا پلتفرم را اجرا کند |
| P07C-08 | جداسازی Schema | Migration یک محصول فقط Schema منطقی خودش را تغییر دهد |
| P07C-09 | ایمنی Expand/Contract | Contract تا فعال‌شدن Release جدید و بازنشستگی صریح Rollback Target ناسازگار رد شود |
| P07C-10 | یکپارچگی Release | شناسه محصول، Digest، Source Revision، فیلدهای Provenance و سازگاری Schema بررسی شوند |
| P07C-11 | Promotion/Rollback مستقل | ارتقا و بازگشت فقط محصول منتخب را تغییر دهد و Compare-and-Swap منقضی را رد کند |
| P07C-12 | ردیابی White-label | Tenant، Operator، Brand، محصول، Release، نسخه Config، نسخه Schema و Correlation ID بدون افشای Secret مرتبط بمانند |

CI در مسیر .github/workflows/p07c-independent-lifecycle.yml تعریف شده است. Pass فقط پس از تکمیل Integration و Documentation Governance روی Head دقیق PR ثبت می‌شود.

## روش بازتولید

از ریشه مخزن:

~~~bash
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/products.json
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/config-schemas.json
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/tenant-state.json
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/releases.json
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/migrations.json
python3 -m json.tool prototypes/p07-independent-lifecycle/registry/actors.json
python3 -m compileall -q prototypes/p07-independent-lifecycle
python3 -m unittest discover -s prototypes/p07-independent-lifecycle/tests -v
~~~

## محدودیت‌های صریح

- فقط وضعیت ساختگی در حافظه است. Provisioning واقعی Tenant، سرویس فعال‌سازی محصول، Migration دیتابیس، Release Orchestration، Container Deployment یا Rollback واقعی اجرا نمی‌شود.
- مالکیت منطقی Schema آزمایش می‌شود؛ جداسازی فیزیکی Database/Schema و PostgreSQL RLS اثبات نشده‌اند.
- Actorها و Tokenهای Fixture، Credential ثابت آزمایشی‌اند و هویت یا مجوزدهی Production نیستند.
- اعتبارسنجی Configuration محدود به Schema کوچک Fixture است. مقادیر secret:// فقط Reference هستند؛ KMS، Vault، چرخش Secret یا دریافت Secret پیاده‌سازی نشده است.
- تست Migration، دیکشنری‌های Python را تغییر می‌دهد. ایمنی SQL Migration، Transactional DDL، Backup/Restore، Zero-downtime Deployment یا سازگاری واقعی Expand/Contract اثبات نمی‌شود.
- بررسی Provenance فقط چند فیلد در رکورد ساختگی با ساختار in-toto/SLSA را اعتبارسنجی می‌کند. امضای رمزنگاری‌شده، Builder مورد اعتماد، سطح SLSA، Attestation، SBOM یا یکپارچگی زنجیره تأمین اثبات نشده است.
- Promotion و Rollback فقط انتقال وضعیت Metadata در Fixture مربوط به Staging هستند، نه عملیات Deployment Production.
- بازنشستگی Rollback Pointer، Artifact یا داده را حذف نمی‌کند. Migration مخرب خودکار یا حذف داده وجود ندارد.
- White-label فقط ردیابی Metadata است. Portal واقعی Operator، دامنه اختصاصی، Billing، Payment، سرویس Branding یا داده مشتری وجود ندارد.
- Audit List در حافظه است و Immutable یا Tamper-evident نیست.
- Lottery همچنان در محدوده آینده است؛ هیچ Ticketing، Draw، Prize یا Payout پیاده‌سازی نشده است.
- هیچ Merge، Deploy، Credential واقعی، داده Production یا وجه واقعی استفاده نمی‌شود.

## مراجع تحقیق

- AWS، [SaaS Lens — جداسازی Tenant و راهنمای عملیات](https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/saas-lens.html).
- Martin Fowler، [Parallel Change / Expand-Contract](https://martinfowler.com/bliki/ParallelChange.html).
- AWS Prescriptive Guidance، [راهبردهای Migration دیتابیس](https://docs.aws.amazon.com/prescriptive-guidance/latest/strategy-database-migration/welcome.html).
- SLSA، [مشخصات Provenance نسخه ۱](https://slsa.dev/spec/v1.1/provenance).
- in-toto، [چارچوب Attestation](https://github.com/in-toto/attestation).
