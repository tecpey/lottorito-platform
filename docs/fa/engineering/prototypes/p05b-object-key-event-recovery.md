# P-05B — بازیابی Object، کلید و رویداد

**شناسه سند:** LOT-PROT-P05B-001 | **نسخه:** ۰.۵.۰ | **وضعیت:** Integration ترکیبی ساختگی P-05A/P-05B روی Head کد اجرایی 146a9bc635e3b03db568c423fb0958b62bc31c7b موفق شد؛ بازیابی Production تصویب نشده است

## اعتبار و مرز

P-05B آزمایش PITR دیتابیس در P-05A را با بازیابی مستقل بایت‌های Object، بازیابی کلید آزمایشی Envelope و بازپخش مرتب و Idempotent رویدادها تکمیل می‌کند. این فقط آزمایش ایزوله و دورریختنی CI است. هیچ Object Store، KMS/HSM، Broker، دیتابیس، Cloud Provider یا معماری Production را انتخاب نمی‌کند. Custody، خروج کلید Production، Replay زنده Provider، وجه واقعی، داده Production، Merge یا Deploy را مجاز نمی‌کند.

## مبنای تحقیق

- راهنمای صحت Object در AWS S3: Checksum در Upload/Download بررسی شود؛ ETag برای همه Objectها Checksum کامل نیست، به‌ویژه در Multipart.
- راهنمای صحت Google Cloud Storage: Checksum روی کل بایت‌های دریافت‌شده محاسبه و با مقدار مرجع قابل اعتماد مقایسه شود؛ Range Read به رسیدگی ویژه نیاز دارد.
- استاندارد NIST SP 800-57 Part 1 Rev. 5: کلیدهای رمزگذاری داده برای مدت بازیابی لازم محافظت و نگهداری شوند؛ DEK آرشیوشده با مواد مستقل محافظت‌کننده از کلید Wrap شود. Rev. 6 فقط پیش‌نویس عمومی اولیه است و مرجع نهایی فرض نمی‌شود.
- راهنمای Transactional Outbox و پردازش رویداد AWS: در تحویل At-least-once، Duplicate قابل انتظار است؛ Consumer باید Idempotent باشد و ترتیب لازم را حفظ کند.
- LOT-FIN-POST-001، LOT-EVENT-001 و LOT-QA-001: هویت تغییرناپذیر Economic Effect، جداسازی Tenant، توازن Ledger و تطبیق Source-to-Ledger.

## آزمایش

### بایت Object و صحت

۱. یک Payload باینری ساختگی بسازید و اندازه بایت و SHA-256 آن را در Manifest و ردیف ارجاع Object در PostgreSQL بازیابی‌شده ثبت کنید.
۲. Payload را با DEK تصادفی ۲۵۶ بیتی و AES-256-GCM رمز کنید؛ داده همراه (AAD) به Tenant، Object و نسخه فرمت مقید باشد.
۳. DEK را با KEK ساختگی مستقل ۲۵۶ بیتی و AES-256-GCM Wrap کنید؛ AAD به Key ID و Object ID مقید باشد.
۴. Payload/Manifest/Envelope و مواد بازیابی کلید را در دو مسیر Backup دورریختنی و مستقل نگهداری و نسخه‌های فعال را حذف کنید.
۵. هر دو مجموعه را مستقل Restore کنید، احراز اصالت/رمزگشایی را انجام دهید، SHA-256 کل Plaintext را دوباره محاسبه و با مرجع دیتابیس و تعداد بایت مورد انتظار مقایسه کنید.
۶. اثبات کنید نبود کلید، خرابی Ciphertext و خرابی DEK بسته‌بندی‌شده Fail-closed می‌شوند. تأیید کنید Plaintext در Backup مربوط به Object ذخیره نشده است.

فایل KEK خام ساختگی فقط Fixture مربوط به CI است؛ الگوی Custody Production، اتصال KMS/HSM، Split-Knowledge، مراسم کلید یا طراحی مجوز بازیابی محسوب نمی‌شود.

### بازپخش رویداد و ناورداهای مالی

۱. Source Event و Inbox را با Tenant، Consumer، Source Event ID، Economic Effect ID، Aggregate ID و Sequence ذخیره کنید.
۲. ابتدا Sequence شماره ۲ را تحویل دهید، سپس Sequence شماره ۱، Sequence شماره ۲ را تکرار و یک Source Event ID متفاوت با Economic Effect ID قبلاً مصرف‌شده ارسال کنید.
۳. Replay Cursor را ملزم کنید در شکاف Sequence متوقف بماند؛ پس از رسیدن Sequence شماره ۱، ابتدا ۱ و سپس ۲ پردازش شود.
۴. پس از آنکه تابع Replay، Journal، Lineها، وضعیت Inbox و Cursor را نوشته اما پیش از Commit تراکنش، خطا تزریق کنید. Rollback کامل تراکنش را اثبات کنید.
۵. رویدادهای Pending را Retry کنید؛ دقیقاً دو Journal، دو اثر متوازن، دو Inbox پردازش‌شده، Cursor روی Sequence شماره ۲ و برابری مجموع Source با مجموع Cash در Ledger را اثبات کنید.
۶. ثابت کنید Replay مجدد No-op است و خواندن/نوشتن Inbox بین Tenantها رد می‌شود.

این آزمایش Atomicity تراکنش دیتابیس را برای Fixture حاضر اثبات می‌کند، نه تحویل Exactly-once بین سامانه‌های مستقل را. تطبیق Provider خارجی و دوام Broker خارج از محدوده‌اند.

## معیارهای پذیرش

- P05B-OBJECT: تعداد بایت و SHA-256 Plaintext بازیابی‌شده با مرجع قابل اعتماد دیتابیس برابر باشد.
- P05B-OBJECT-NEGATIVE: Ciphertext تغییرکرده پیش از پذیرش Plaintext رد شود.
- P05B-KEY: مواد بازیابی ساختگی و مستقل Restore شده، DEK را باز و Object را احراز اصالت کنند.
- P05B-KEY-NEGATIVE: نبود کلید بازیابی و تغییر DEK بسته‌بندی‌شده Fail-closed شوند.
- P05B-TENANT: Tenant B نتواند Metadata مربوط به Object متعلق به Tenant A را بخواند.
- P05B-INBOX: Source Event تکراری و Economic Effect ID تکراری به یک Inbox Record تقلیل یابند.
- P05B-ORDER: Sequence شماره ۲ تا زمان نبود Sequence شماره ۱ جلو نرود؛ ترتیب پردازش ۱ سپس ۲ باشد.
- P05B-ATOMICITY: خطای تزریق‌شده تراکنش، هیچ Journal، وضعیت Inbox پردازش‌شده یا پیشروی Cursor باقی نگذارد.
- P05B-REPLAY: Retry برای هر Economic Effect دقیقاً یک Journal بسازد؛ Replay بعدی هیچ اثر تازه‌ای نسازد.
- P05B-LEDGER: همه Journalها متوازن و مجموع Source Event با مجموع Cash در Ledger تطبیق داشته باشد.
- P05B-TENANT-EVENT: خواندن/نوشتن Inbox بین Tenantها رد شود.
- همه Assertionها در همان Job دورریختنی و روی PostgreSQL بازیابی‌شده توسط P-05A اجرا شوند.

## شواهد نهایی CI

- آخرین Integration ترکیبی P-05A/P-05B با شناسه [45532825694](https://github.com/tecpey/lottorito-platform/actions/runs/45532825694) و Documentation Governance با شناسه [45532825916](https://github.com/tecpey/lottorito-platform/actions/runs/45532825916) روی Head کد اجرایی `146a9bc635e3b03db568c423fb0958b62bc31c7b` موفق شدند.
- Gate پایان Recovery در P-05A موفق شد (`pg_is_in_recovery() = false`)؛ راه‌اندازی با WAL مفقود Fail-closed شد؛ Staging ناقص Restore نیز توسط Manifest Verification و راه‌اندازی سرور رد شد.

- Integration نهایی ترکیبی P-05A/P-05B با شناسه [45532382323](https://github.com/tecpey/lottorito-platform/actions/runs/45532382323) و Documentation Governance با شناسه [45532382310](https://github.com/tecpey/lottorito-platform/actions/runs/45532382310)، هر دو روی Head شاخه `0a6b8f992161cd9f9d760698b1c9d0c8e30867a9` موفق شدند.
- همان اجرای ترکیبی دو آزمون منفی P-05A را نیز بست: Staging ناقص Restore توسط Manifest Verification و راه‌اندازی سرور رد شد؛ Segment هدف WAL مفقود مانع Ready شدن بازیابی در Restore Point درخواستی شد و در Recovery Log شناسایی شد.


- اجرای Integration ترکیبی P-05A و P-05B در Pull Request با شناسه [45526975173](https://github.com/tecpey/lottorito-platform/actions/runs/45526975173) روی Head اعتبارسنجی‌شده شاخه e4820884194ecf1ab3acd539d77145904f14ab73 موفق شد.
- اجرای Documentation Governance با شناسه [45526975222](https://github.com/tecpey/lottorito-platform/actions/runs/45526975222) روی همان Head موفق شد.
- Payload بازیابی‌شده ۴٬۴۰۹ بایت بود؛ SHA-256 آن `2db4a9b021abba0ce01480ceda665284f023310ce909c0b0b9bcb084f771eaca` با مرجع Object در PostgreSQL بازیابی‌شده تطبیق داشت.
- Assertionهای Object/Key موفق بودند: بازیابی از Backupهای مستقل، Fail-closed در نبود کلید، رد Ciphertext تغییرکرده، رد DEK بسته‌بندی‌شده تغییرکرده و جداسازی مرجع Object بین Tenantها.
- Assertionهای Event موفق بودند: تحویل نامرتب (ابتدا ۲ سپس ۱)، تقلیل Duplicate تحویل/Economic Effect، توقف در شکاف Sequence، Rollback تراکنش قطع‌شده، Retry با دقیقاً دو اثر، توازن Ledger، تطبیق Source-to-Ledger، No-op بودن Replay بعدی و جداسازی Inbox بین Tenantها.
- همان Job یکپارچه پیش از P-05B، Backup Verification/PITR در P-05A و Assertionهای مالی/RLS آن را نیز دوباره اجرا کرد. مسیر مثبت P-05A پیش از Assertionهای نوشتنی صریحاً منتظر `pg_is_in_recovery() = false` ماند. Job آزمون‌های منفی WAL مفقود و Staging ناقص Restore را نیز دوباره اجرا کرد. PostgreSQL 18.7 در Container دورریختنی استفاده شد؛ هیچ ادعای RPO/RTO عملیاتی مطرح نیست.

## ایمنی، محدودیت‌ها و کارهای باز

از KMS/HSM زنده، Cloud Object Storage، Broker خارجی، Provider، Credential واقعی، داده مشتری/بازیکن یا وجه واقعی استفاده نمی‌شود. AES-GCM فقط Primitive آزمایشی است، نه تصمیم مصوب فناوری پلتفرم. این آزمایش Rotation/Revocation کلید، افشای کلید، Custody چندبخشی، قطعی KMS، IAM Policy، Object Versioning/Immutability، Retention/Legal Hold، Object بزرگ/Multipart، Replication منطقه‌ای، Replay Broker خارجی، تطبیق Provider، Saga بین سرویس‌ها، هم‌زمانی بالا، بار Production، هدف RPO/RTO یا انطباق را نمی‌آزماید. آزمون‌های منفی WAL مفقود و Staging ناقص Restore در P-05A اکنون در Workflow ترکیبی موفق‌اند؛ این نتیجه فقط Assertionهای Fail-closed ساختگی شرح‌داده‌شده در گزارش P-05A را اثبات می‌کند. Failover/Fencing/Failback در P-05C خارج از این کار است.

RPO/RTO طبق LOT-QA-001 همچنان TBD است. زمان CI فقط مشاهده آزمایش است. موفقیت آزمایش ساختگی به معنی آمادگی Production یا تصویب فناوری/فروشنده نیست.

## منابع

- https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity-upload.html
- https://docs.cloud.google.com/storage/docs/data-validation
- https://docs.cloud.google.com/storage/docs/object-versioning
- https://nvlpubs.nist.gov/nistpubs/specialpublications/nist.sp.800-57pt1r5.pdf
- https://csrc.nist.gov/pubs/sp/800/57/pt1/r6/ipd
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html

## P-09J — هویت بازیابی با Scope محصول (۲۰۲۶-۱۱-۲۵)

اکنون `product_id` در کلیدهای Primary/Unique مربوط به Inbox و Replay Cursor در P-05B حضور دارد. همان Tenant، Consumer، UUID رویداد مبدأ، UUID اثر اقتصادی و UUID Aggregate به‌صورت مستقل برای Affiliate & Agent و Lottery مقداردهی می‌شوند. هویت محصول در Lookup رویداد مبدأ، ایجاد Journal/Line، به‌روزرسانی وضعیت Inbox و به‌روزرسانی Cursor حمل می‌شود؛ Role Map و RLS آزمایشی نیز هم Tenant و هم Product را محدود می‌کنند.

تابع Replay ردیف Cursor دارای Scope محصول را با `FOR UPDATE` قفل می‌کند. دو Worker هم‌زمان روی Cursor مربوط به Affiliate در مجموع دقیقاً دو اثر را پردازش می‌کنند؛ در همان زمان Worker مربوط به همان Aggregate در Lottery، Cursor مستقل خود را جلو می‌برد. تست‌ها همچنین توقف در شکاف Sequence، Rollback پس از وقفه تزریق‌شده، Retry/No-op، توازن Journal، تطبیق Source-to-Ledger به تفکیک محصول و رد RLS بین Tenant/Product را بررسی می‌کنند.

روی Source-code Head با شناسه `dfaa8120340cc6b4b80450dbf0e5755b21111080`، [اجرای P-05 Recovery با شناسه 45662750801](https://github.com/tecpey/lottorito-platform/actions/runs/45662750801) موفق شد. مرحله رویداد P-05B نشانگرهای `product_scope_event_identity=PASS`، `product_scope_replay_cursor_isolation=PASS`، `concurrent_replay_cursor_serialization=PASS`، `interrupted_replay_rollback=PASS`، `ledger_reconciliation=PASS` و `P05B_RESULT=PASS` را ثبت کرد. همان اجرا، آزمون‌های PITR/بازیابی ناقص P-05A و بازیابی فیزیکی و Replay در P-09E را نیز با موفقیت گذراند. این موارد همچنان Fixtureهای ساختگی و دورریختنی هستند، نه طراحی بازیابی Production. تست Canonical Token در P-02 مقدار جدید `shared` را رد می‌کند؛ ردیف‌های Legacy همچنان باید بدون تخصیص خودکار، شناسایی و قرنطینه شوند.

Inbox محصول‌محور همچنین یکتایی هر رویداد را در محدوده `(tenant, product, consumer, aggregate, sequence)` تضمین می‌کند تا دو اثر متفاوت نتوانند برای یک جایگاه Sequence رقابت کنند. Assertionهای RLS علاوه بر Inbox، جدول‌های Source Event، Journal و Line را نیز پوشش می‌دهند.

## اعتبارسنجی بازیابی P-09K روی Head دقیق (۲۰۲۶-۱۱-۲۶)

[Workflow شماره 45863298629](https://github.com/tecpey/lottorito-platform/actions/runs/45863298629) روی Head دقیق `75fd23701d4e28f047f8ebb73ea0b684bb144c7a` موفق شد: `P05A_RESULT=PASS`، `P09E_RESULT=PASS`، `P05B_OBJECT_KEY_RESULT=PASS`، `P05B_EVENT_RESULT=PASS`، `P05B_RESULT=PASS` و `P05A_NEGATIVE_RESULT=PASS`. این شواهد مربوط به Restore فیزیکی و بازیابی ساختگی است و گواهی Production یا تأیید KMS/HSM محسوب نمی‌شود.

## اعتبارسنجی نهایی بازیابی P-09L (۲۰۲۶-۱۱-۲۶)

روی Head دقیق کد `7cb0598a163f40e53a4412a44b476b0404685b75`، [Workflow شماره 45864973907](https://github.com/tecpey/lottorito-platform/actions/runs/45864973907) تمام Markerهای بازیابی را با موفقیت گذراند: `P05A_RESULT`، `P09E_RESULT`، `P05B_OBJECT_KEY_RESULT`، `P05B_EVENT_RESULT`، `P05B_RESULT` و `P05A_NEGATIVE_RESULT`. [Workflow مربوط به P-05C با شماره 45864973943](https://github.com/tecpey/lottorito-platform/actions/runs/45864973943) نیز `P05C_RESULT=PASS` را ثبت کرد. این‌ها صرفاً شواهد ساختگی‌اند و گواهی Production یا KMS/HSM نیستند.
