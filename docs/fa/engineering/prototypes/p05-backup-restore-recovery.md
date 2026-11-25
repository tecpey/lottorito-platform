# P-05A — نسخه پشتیبان PostgreSQL، PITR و صحت مالی

**شناسه سند:** LOT-PROT-P05-001 | **نسخه:** ۰.۲.۰ | **وضعیت:** آزمایش ساختگی CI موفق؛ بازیابی Production تصویب نشده است

## اعتبار و مرز تصمیم

این فقط یک آزمایش ساختگی و دورریختنی است. PostgreSQL را به‌عنوان دیتابیس Production Lottorito تصویب نمی‌کند، Provider پشتیبان‌گیری انتخاب نمی‌کند، دسترسی به Backup عملیاتی را مجاز نمی‌کند و RPO/RTO تعیین نمی‌کند. محدوده آن فقط P-05A است؛ بازیابی بایت Object/کلید و Failover/Fencing آزمایش‌های مستقل P-05B/P-05C هستند.

## مبنای تحقیق

- مستندات PostgreSQL 18 درباره Physical Base Backup، آرشیو پیوسته WAL و PITR.
- راهنمای pg_verifybackup در PostgreSQL 18: بررسی Manifest جایگزین Restore واقعی نیست.
- راهنمای یکپارچگی داده Google SRE: اطمینان از بازیابی به تمرین End-to-End نیاز دارد.
- راهنمای بازیابی و آزمون آن در Google Cloud و AWS Well-Architected.
- Invariantهای دفترکل دوطرفه تغییرناپذیر، Idempotency اثر اقتصادی و Reconciliation در LOT-FIN-POST-001؛ ویژگی‌های QA-01/03/04/07/08 در LOT-QA-001.

## آزمایش

یک Container دورریختنی PostgreSQL 18.7، آرشیو WAL را پیش از Base Backup فعال می‌کند. دو هویت Tenant ساختگی، Fixture سند مالی متوازن، مجموع کنترلی Source Event و Metadata ارجاع Object ساخته می‌شوند. تست Physical Base Backup می‌گیرد، Manifest را بررسی می‌کند، یک کپی را برای آزمون Fail-closed خراب می‌کند، Restore Point نام‌گذاری‌شده می‌سازد، نشانگر حادثه پس از Target را Commit می‌کند، WAL لازم را آرشیو و Backup را در Data Directory دوم و ایزوله تا همان نقطه بازیابی می‌کند.

دیتابیس بازیابی‌شده واقعاً راه‌اندازی و از نظر موارد زیر بررسی می‌شود:
- مرز دقیق PITR: داده پیش از Target حاضر و نشانگر پس از Target غایب؛
- توازن Journal و تطبیق مجموع کنترلی Source Event تا Ledger؛
- یکتایی شناسه‌های Economic Effect؛
- سلامت Metadata ارجاع Object (نه بازیابی بایت Object)؛
- RLS مربوط به Tenant با هویت Login دیتابیس مستقل؛
- ثبت زمان Backup، صحت‌سنجی، آرشیو WAL و Restore.

## شناسه‌های پذیرش

- P05-BACKUP: Physical Base Backup و Manifest ساخته شود؛ pg_verifybackup موفق باشد.
- P05-TAMPER: کپی Manifest خراب‌شده رد شود.
- P05-WAL: Segment لازم WAL برای Restore Point نام‌گذاری‌شده آرشیو شود.
- P05-PITR: بازیابی به Restore Point نام‌گذاری‌شده برسد؛ نشانگر بعد از Target غایب باشد.
- P05-LEDGER: همه Journalهای Fixture تراز و مجموع Source/Ledger تطبیق داشته باشند.
- P05-IDEMPOTENCY: شناسه Economic Effect یکتا باقی بماند.
- P05-TENANT: RLS بازیابی‌شده برای هر دو هویت Tenant خواندن بین Tenantها را رد کند.
- P05-OBJECT-REF: Metadata ارجاع Object ساختگی معتبر بماند؛ بایت Payload خارج از P-05A است.
- P05-TIMING: زمان Backup/Verification/Restore و Recovery Point حاصل ثبت شود، بدون ادعای انطباق با هدف.

## ایمنی و محدودیت‌ها

هیچ داده Production، Credential، Secret شریک، وجه واقعی یا Endpoint زنده‌ای استفاده نمی‌شود. هیچ Cloud Resource یا سرویس خارجی ساخته نمی‌شود. تست از Storage دورریختنی Container و گذرواژه‌های ساختگی استفاده می‌کند. نگهداری Off-site/Immutable، رمزنگاری/مالکیت کلید، بازیابی بایت Object، بازیابی Application/Worker، Replay رویداد، تطبیق Provider، بازیابی منطقه‌ای، Failover، Split-brain Fencing، Failback، Throughput در مقیاس Production یا آمادگی حقوقی/انطباق اثبات نمی‌شوند. این موارد به P-05B/P-05C و بازبینی بعدی نیاز دارند. RPO/RTO تا تأیید مالک/متخصص دامنه TBD هستند.

## منابع

- https://www.postgresql.org/docs/18/continuous-archiving.html
- https://www.postgresql.org/docs/18/app-pgbasebackup.html
- https://www.postgresql.org/docs/18/app-pgverifybackup.html
- https://www.postgresql.org/docs/18/app-pgrewind.html
- https://sre.google/sre-book/data-integrity/
- https://docs.cloud.google.com/architecture/framework/reliability/perform-testing-for-recovery-from-data-loss
- https://docs.aws.amazon.com/wellarchitected/latest/framework/rel_planning_for_recovery_disaster_recovery.html

## شواهد

- Integration: [اجرای 45524388676](https://github.com/tecpey/lottorito-platform/actions/runs/45524388676) روی Head با شناسه f2303a647aefd5bd8d48ba9d2e1830c881f60041 موفق شد.
- Documentation Governance: [اجرای 45524388734](https://github.com/tecpey/lottorito-platform/actions/runs/45524388734) روی همان Head موفق شد.
- PostgreSQL 18.7؛ Backup و Verification در مجموع ۱۲ تا ۱۳ ثانیه (اجرای نهایی روی Head فعلی: ۱۳ ثانیه)؛ راه‌اندازی دیتابیس بازیابی‌شده ۱ ثانیه در Runner دورریختنی GitHub. این‌ها مشاهدات آزمایش‌اند، نه هدف RTO عملیاتی.
- تست، Verification و رد Manifest دست‌کاری‌شده، وجود WAL آرشیوشده، Log نقطه بازیابی نام‌گذاری‌شده، حضور نشانگر پیش از Target و نبود نشانگر پس از Target، خواندن محدود به Tenant و رد Insert بین Tenantها، توازن Journal، تطبیق مجموع Source-to-Ledger، یکتایی Economic Effect و فرمت معتبر Hash ارجاع Object را بررسی کرد.
- آزمون منفی WAL مفقود و Restore قطع‌شده همچنان باز هستند. بازیابی بایت Object/کلید و Failover/Fencing/Failback در P-05B/P-05C هستند و هنوز اجرا نشده‌اند.
- موفقیت ساختگی به‌معنای آمادگی Production، تصمیم فناوری یا تصویب RPO/RTO نیست.
