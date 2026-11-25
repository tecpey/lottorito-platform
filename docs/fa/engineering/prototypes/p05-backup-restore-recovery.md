# P-05A — نسخه پشتیبان PostgreSQL، PITR و صحت مالی

**شناسه سند:** LOT-PROT-P05-001 | **نسخه:** ۰.۷.۰ | **وضعیت:** آزمایش ساختگی CI موفق؛ بازیابی Production تصویب نشده است

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

## آزمون‌های منفی بازیابی (ادامه P-05A)

Workflow ترکیبی P-05 دو کنترل Fail-closed را علاوه بر مسیر مثبت PITR اضافه می‌کند:

۱. **Staging ناقص Restore:** یک کپی دورریختنی از Physical Backup ساخته و فایل ضروری `global/pg_control` حذف می‌شود؛ سپس انتظار می‌رود هم `pg_verifybackup` و هم راه‌اندازی PostgreSQL این Staging ناقص را رد کنند. این شبیه‌سازی Artifact ناقص/Restore ناتمام است؛ ادعا نمی‌کند که فرایند Restore زنده Production در میانه نوشتن Kill شده است.

۲. **WAL هدفِ مفقود:** از Base Backup و WAL Archive کپی‌های مستقل ساخته می‌شود؛ Segment دقیق WAL که Restore Target نام‌گذاری‌شده در آن قرار دارد، هم از Archive کپی‌شده و هم از `pg_wal` کپی‌شده حذف می‌شود و بازیابی هدفمند آزمایش می‌شود. بسته به WAL موجود، PostgreSQL ممکن است از راه‌اندازی بازبماند یا فقط به وضعیت بازیابی معتبرِ قدیمی‌تری برسد. در هر دو حالت، نتیجه نباید به‌عنوان بازیابی موفق تا Target نام‌گذاری‌شده پذیرفته شود، مگر اینکه نشانگر مورد انتظار پس از Target حاضر باشد. آزمون، Segment درخواست‌شده را در Log بررسی می‌کند و Fixture مثبت یا Archive اصلی را تغییر نمی‌دهد.

مسیر مثبت نیز پیش از اجرای Assertionهای مالی/RLS که به نوشتن نیاز دارند، تا زمانی Poll می‌کند که `pg_is_in_recovery()` مقدار `false` برگرداند. صرف Ready اعلام‌شدن توسط `pg_ctl` کافی نیست؛ چون ممکن است سرور در حالی اتصال Read-only بپذیرد که Recovery هنوز ادامه دارد. مسیر منفی WAL مفقود، Writable شدن سرور پیش از Target درخواستی را صریحاً رد می‌کند.

این تمایز مهم است: صرف اینکه سرور پس از تمام شدن WAL موجود Start شود، اثبات نمی‌کند که به Recovery Target درخواستی رسیده است. دروازه پذیرش بازیابی باید پیش از پذیرش ترافیک، Marker/Control State مورد انتظار کسب‌وکار را اعتبارسنجی کند. مستندات PostgreSQL تصریح می‌کنند که `restore_command` برای فایل غایب باید خروجی غیرصفر برگرداند و Recovery قطع‌شده قابل Restart است؛ `pg_verifybackup` فایل‌های مفقود را تشخیص می‌دهد اما جایگزین Restore واقعی و اعتبارسنجی محتوا نیست.

**وضعیت:** پیاده‌سازی آزمون‌های منفی به Workflow ترکیبی CI افزوده شده است؛ تا تکمیل Integration و Documentation Governance روی Head نهایی شاخه، اعتبارسنجی در انتظار است.

## ایمنی و محدودیت‌ها

هیچ داده Production، Credential، Secret شریک، وجه واقعی یا Endpoint زنده‌ای استفاده نمی‌شود. هیچ Cloud Resource یا سرویس خارجی ساخته نمی‌شود. تست از Storage دورریختنی Container و گذرواژه‌های ساختگی استفاده می‌کند. نگهداری Off-site/Immutable، رمزنگاری/مالکیت کلید، بازیابی بایت Object، بازیابی Application/Worker، Replay رویداد، تطبیق Provider، بازیابی منطقه‌ای، Failover، Split-brain Fencing، Failback، Throughput در مقیاس Production یا آمادگی حقوقی/انطباق اثبات نمی‌شوند. این موارد به P-05B/P-05C و بازبینی بعدی نیاز دارند. RPO/RTO تا تأیید مالک/متخصص دامنه TBD هستند.

## منابع

- https://www.postgresql.org/docs/18/continuous-archiving.html
- https://www.postgresql.org/docs/18/app-pgbasebackup.html
- https://www.postgresql.org/docs/18/app-pgverifybackup.html
- https://www.postgresql.org/docs/18/runtime-config-wal.html
- https://www.postgresql.org/docs/18/functions-admin.html
- https://www.postgresql.org/docs/18/app-pgrewind.html
- https://sre.google/sre-book/data-integrity/
- https://docs.cloud.google.com/architecture/framework/reliability/perform-testing-for-recovery-from-data-loss
- https://docs.aws.amazon.com/wellarchitected/latest/framework/rel_planning_for_recovery_disaster_recovery.html

## شواهد

- آخرین Integration ترکیبی با شناسه [45532825694](https://github.com/tecpey/lottorito-platform/actions/runs/45532825694) و Documentation Governance با شناسه [45532825916](https://github.com/tecpey/lottorito-platform/actions/runs/45532825916) روی Head کد اجرایی `146a9bc635e3b03db568c423fb0958b62bc31c7b` موفق شدند.
- مسیر مثبت PITR اکنون پیش از Assertionهای مالی/RLS نیازمند نوشتن، تا زمان بازگشت `pg_is_in_recovery() = false` صبر می‌کند (`pitr_recovery_complete=PASS`)؛ Ready شدن توسط `pg_ctl` به‌تنهایی پایان Recovery محسوب نمی‌شود.
- Assertionهای منفی نهایی: `incomplete_restore_manifest_rejected=PASS`، `incomplete_restore_server_start_rejected=PASS`، `missing_wal_startup_failed_closed=PASS`، `missing_wal_target_segment_absence_detected=PASS` و `P05A_NEGATIVE_RESULT=PASS`.

- Integration ترکیبی P-05A/P-05B: [اجرای 45532382323](https://github.com/tecpey/lottorito-platform/actions/runs/45532382323) روی Head نهایی شاخه `0a6b8f992161cd9f9d760698b1c9d0c8e30867a9` موفق شد.
- Documentation Governance: [اجرای 45532382310](https://github.com/tecpey/lottorito-platform/actions/runs/45532382310) روی همان Head موفق شد.
- Assertionهای منفی: `incomplete_restore_manifest_rejected=PASS`، `incomplete_restore_server_start_rejected=PASS`، `missing_wal_startup_not_ready=PASS`، `missing_wal_target_segment_absence_detected=PASS` و `P05A_NEGATIVE_RESULT=PASS`.

- Integration: [اجرای 45524388676](https://github.com/tecpey/lottorito-platform/actions/runs/45524388676) روی Head با شناسه f2303a647aefd5bd8d48ba9d2e1830c881f60041 موفق شد.
- Documentation Governance: [اجرای 45524388734](https://github.com/tecpey/lottorito-platform/actions/runs/45524388734) روی همان Head موفق شد.
- PostgreSQL 18.7؛ Backup و Verification در مجموع ۱۲ تا ۱۳ ثانیه (اجرای نهایی روی Head فعلی: ۱۳ ثانیه)؛ راه‌اندازی دیتابیس بازیابی‌شده ۱ ثانیه در Runner دورریختنی GitHub. این‌ها مشاهدات آزمایش‌اند، نه هدف RTO عملیاتی.
- تست، Verification و رد Manifest دست‌کاری‌شده، وجود WAL آرشیوشده، Log نقطه بازیابی نام‌گذاری‌شده، حضور نشانگر پیش از Target و نبود نشانگر پس از Target، خواندن محدود به Tenant و رد Insert بین Tenantها، توازن Journal، تطبیق مجموع Source-to-Ledger، یکتایی Economic Effect و فرمت معتبر Hash ارجاع Object را بررسی کرد.
- آزمون‌های منفی روی Head کد اجرایی ترکیبی `146a9bc635e3b03db568c423fb0958b62bc31c7b` موفق شدند: Staging ناقص Restore هم توسط `pg_verifybackup` و هم راه‌اندازی PostgreSQL رد شد؛ حذف Segment دقیق WAL هدف باعث شد راه‌اندازی Recovery پیش از Target نام‌گذاری‌شده به‌صورت Fail-closed متوقف شود. Log مربوط به WAL مفقود، نبود Segment هدف را ثبت کرد. بازیابی بایت Object/کلید در P-05B پوشش داده شده است؛ Failover/Fencing/Failback در P-05C همچنان اجرا نشده است.
- موفقیت ساختگی به‌معنای آمادگی Production، تصمیم فناوری یا تصویب RPO/RTO نیست.


## شواهد P-09E برای بازیابی Recordهای مشترک (۲۰۲۶-۱۱-۲۵)

Workflow مربوط به P-05 با شناسه [45635972222](https://github.com/tecpey/lottorito-platform/actions/runs/45635972222) روی Head کاندید 73d7d0daa46e6a019020fc25ace315836d270a6f موفق شد. علاوه بر PITR در P-05A، Fixture مربوط به Object/Key/Event در P-05B و آزمون‌های منفی P-05A، این اجرا P-09E را روی Schemaهای دقیق SQL در P-02/P-03C/P-03D و جدول‌های واقعی Provider Inbox، Ledger، Journal، Line، Outbox و Delivery State اجرا کرد. Backup فیزیکی pg_verifybackup را گذراند؛ Cluster بازیابی‌شده سه Inbox پذیرفته‌شده را Replay کرد و برای هر Scope دقیقاً یک Journal/Effect/Outbox/Delivery ساخت. تزریق خرابی، Rollback یکپارچه تراکنش Posting را اثبات کرد. برخورد Source ID یکسان بین Scopeهای Product و Tenant، Retry تکراری، RLS و Reconciliation در P-03D نیز موفق شدند. برای محدوده و محدودیت‌ها به سند یکپارچه‌سازی P-09 مراجعه کنید.

این آزمایش جایگزین Fixture ساده‌شده P-05B نیست و معماری Backup Production، نگهداری PITR، دوام Off-site، بازیابی Key/Object، ترتیب Aggregate، Fencing هم‌زمان، RPO/RTO یا آمادگی Production را اثبات نمی‌کند. Documentation Governance با شناسه [45635972312](https://github.com/tecpey/lottorito-platform/actions/runs/45635972312) روی همان Head موفق شد (۵۸ جفت دوزبانه و ۱۳۶ لینک محلی).

## تأیید مجدد P-09E روی Head دقیق (۲۰۲۶-۱۱-۲۵)

P-09E در Workflow مربوط به P-05 با شناسه [45637659268](https://github.com/tecpey/lottorito-platform/actions/runs/45637659268) روی 2b393cc8c41226a20333f34559ac6952883901a3 موفق شد. Backup فیزیکی، pg_verifybackup، Restore مستقل، Recordهای واقعی P-02/P-03C/P-03D، Rollback اتمیک در Failure تزریق‌شده، Replay روی Inbox، Idempotency، RLS Tenant/Product، توازن Journal، اتمیک‌بودن Delivery State در Outbox و صفر بودن استثناهای Reconciliation همگی PASS شدند. PITR در P-05A، P-05B و آزمون‌های منفی WAL/Restore ناقص نیز موفق شدند. Documentation Governance با شناسه [45637659297](https://github.com/tecpey/lottorito-platform/actions/runs/45637659297) روی همان Head موفق شد.


### P-09H — دروازه اعتبارسنجی قرارداد در Replay (۲۰۲۶-۱۱-۲۵)

Helper بازیابی P-05E اکنون پیش از فراخوانی Journal Posting، رویداد Canonical ذخیره‌شده را با ردیف Provider Inbox بازیابی‌شده تطبیق می‌دهد. نسخه/id/source/type در CloudEvents، Tenant، Product Scope، UUID مربوط به Source Event، نسخه Schema، ساختار traceparent و قابل‌تبدیل‌بودن Timestamp بررسی می‌شوند. Fixtureهای بازیابی اکنون Envelope کامل P-09 را دارند. هر مغایرت، تراکنش Replay را پیش از Commit شدن اثر مالی متوقف می‌کند. این همچنان یک Drill بازیابی ساختگی و موقت است، نه سرویس بازیابی Production.


در P-09H یک سناریوی منفی Replay افزوده شده است: Product Scope رویداد بازیابی‌شده دست‌کاری می‌شود، Helper باید Fail-Closed عمل کند، تراکنش Claim باید به وضعیت `accepted` برگردد و هیچ Financial Effectی ایجاد نشود. Workflow بازیابی پس از اصلاح Quoting مربوط به Shell/JSON در Fixture دوباره در حال اجراست؛ اجرای ناموفق قبلی که همین خطای Fixture را آشکار کرد، مدرک پذیرش محسوب نمی‌شود.
