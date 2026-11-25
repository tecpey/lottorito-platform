# P-09 — یکپارچه‌سازی قرارداد و بازیابی بین Prototypeها

**شناسه سند:** LOT-PROT-P09-001 | **نسخه:** ۰.۶.۰ | **وضعیت:** قرارداد پیشنهادی بین Prototypeها؛ P-09A و Correlation محصول‌محور P-09B در CI ساختگی موفق شدند؛ بدون تصویب Production

**وضعیت:** خط مبنای قرارداد پیشنهادی؛ پیاده‌سازی کامل و تصویب مالک همچنان باز است.  
**مبنای بررسی:** شاخه `integration/p03d-p04-p08-candidate` با Head برابر `c7f9ffa1f499fbd34d260b2aa6d3122d32e1ac7f`.  
**شاخه اجرا:** `spike/p09-cross-prototype-contract-recovery`.  
**ایمنی:** فقط Fixture ساختگی؛ بدون Merge، تغییر Main، اتصال Production، Migration مخرب یا Deploy.

## ۱. مسئله

P-02/P-03D برای هویت مالی و Provider از محدوده Tenant/Product استفاده می‌کنند، اما کلیدهای Replay در P-05B و Ledger ساده‌شده آن، بعد Product را ندارند. کلید Correlation در P-06 فقط Tenant/Source Event است و مقدار `platform` را کنار نام محصولات قرار می‌دهد. P-07B قرارداد Producer/Consumer را مجازسنجی می‌کند، اما هویت Source Event در P-03D و Trace Context در P-06 را حمل نمی‌کند. نام Artifact، Metadata و بررسی Provenance در P-08 نیز به Affiliate & Agent محدود و Hard-code شده است.

موفقیت Workflowهای جداگانه روی یک Commit مشترک فقط اجرای همان مجموعه تست‌های تعریف‌شده را اثبات می‌کند؛ اثبات‌کننده هویت Canonical، مسیر Recovery مشترک یا Pipeline مستقل از محصول نیست.

## ۲. ADR-009 — تفکیک Product Scope از Platform Scope

### تصمیم پیشنهادی

۱. شناسه‌های Canonical محصولات فعلی دقیقاً `affiliate_agent` و `lottery` هستند.  
۲. مقدار `shared` محصول نیست؛ یک مقدار Legacy/مبهم است و نباید بی‌صدا به شناسه دیگری ترجمه شود.  
۳. `platform` نوع Scope است، نه شناسه محصول. شناسه پایدار آن `lottorito` است.  
۴. هر Event باید Scope تفکیک‌شده و صریح داشته باشد:
   - محصول: `{ "kind": "product", "id": "affiliate_agent" | "lottery" }`
   - پلتفرم: `{ "kind": "platform", "id": "lottorito" }`
۵. Economic Effect و Journal فقط به یک Product تعلق دارند. Event با Scope پلتفرم نمی‌تواند Journal مالی ثبت کند.  
۶. هویت Source Event در محدوده Tenant برابر Tuple زیر است: `(tenant_id, scope_kind, scope_id, source_event_id)`. UUID به‌تنهایی هویت سراسری و یکتا نیست.  
۷. هویت Economic Effect و Journal به‌ترتیب `(tenant_id, product_id, economic_effect_id)` و `(tenant_id, product_id, journal_id)` است.  
۸. هویت Correlation شامل `(tenant_id, scope_kind, scope_id, source_event_id, trace_id)` است. Trace ID استاندارد W3C کار توزیع‌شده را هم‌بسته می‌کند؛ جایگزین هویت تجاری یا مجوزدهی نیست.

### منطق تصمیم

Affiliate & Agent و Lottery باید مستقل قابل‌استفاده باشند. قابلیت‌های Platform زیرساخت مشترک با مالکیت صریح‌اند، نه محصول سوم مشتری‌محور. یکی‌گرفتن `shared`، `platform` و Product باعث ابهام در یکتایی، مجوزدهی، Telemetry و Provenance Artifact می‌شود. Scope صریح مانع برخورد UUID یکسان در دو محصول و Correlation ناخواسته بین آن‌هاست.

### گزینه‌های بررسی‌شده

- **تعریف `shared` به‌عنوان Product:** رد؛ مالکیت زیرساخت را با مرز محصول اشتباه می‌گیرد.
- **تعریف `platform` به‌عنوان Alias برای `shared`:** رد؛ داده تاریخی ناسازگار را پنهان می‌کند و مسئله هویت را حل نمی‌کند.
- **کلید UUID صرفاً در سطح Tenant:** رد؛ Source ID ممکن است در یک Tenant بین چند محصول تکرار شود.
- **استنتاج Product از Payload یا Consumer:** رد؛ هویت باید از Context مورد اعتماد Producer/Installation و Contract معتبر حاصل شود.

### سازگاری و مهاجرت

Schemaهای فعلی P-02/P-03D آزمایش هستند، نه مقصد Migration Production. در P-02 هنوز مقدار Legacy `shared` مجاز است و چند Primary/Unique Key فقط Tenant را پوشش می‌دهند؛ P-03D در کلید Inbox مربوط به Provider صریح‌تر است. در این Slice نخست P-09 هیچ تغییر مخرب Schema انجام نمی‌شود.

پیش از Migration باید تمام ردیف‌ها و Producerهای موجود Inventory شوند. Product Scope باید از Database Role/Installation مورد اعتماد استخراج و با Source Record تطبیق داده شود. ردیف‌های مبهم `shared` برای تصمیم مالک و Reconciliation قرنطینه می‌شوند؛ نگاشت انبوه و حدسی به Affiliate، Lottery یا Platform ممنوع است. Schema مقصد باید Composite FK و Unique Constraintهایی با همان ابعاد Scope داشته باشد.

## ۳. Event Envelope استاندارد

خط مبنای ماشین‌خوان در `prototypes/p09-contract-recovery/contract.json` قرار دارد. Eventها از Context Attributeهای CloudEvents 1.0 همراه با `tenantid`، `scope`، `sourceeventid` و `schemaversion` عدد صحیح مثبت استفاده می‌کنند. `sourceeventid` هویت پایدار Source تجاری است و با `id` در CloudEvents (هویت Envelope/Delivery) تفاوت دارد. `dataschema` Schema Payload را مشخص می‌کند. W3C `traceparent` جداگانه Propagate می‌شود.

Event مالی باید Product Scope داشته باشد. Event پلتفرمی می‌تواند Platform Scope داشته باشد، اما نباید به‌عنوان فرمان ثبت Ledger استفاده شود. Tenant، Scope محصول/پلتفرم، Provider Installation، Schema و مجوز باید از Context مورد اعتماد اعتبارسنجی شوند؛ مقادیر Payload غیرقابل‌اعتماد مرجع اختیار نیستند.

## ۴. نقشه انطباق بین Prototypeها

| Prototype | وضعیت فعلی | هدف P-09 / شکاف |
|---|---|---|
| P-02 | برخی Identity و Unique Constraintها فقط Tenant را دارند؛ `shared` مجاز است | هویت مرکب Tenant/Product؛ Economic Effect و Journal فقط Product |
| P-03D | Provider Inbox شامل Tenant + Product + Provider + Provider Event است | حفظ این مرز و نگاشت به Tupleهای Canonical |
| P-05B | Inbox و Replay Cursor بعد Product ندارند و به Fixture ساده‌شده Ledger می‌نویسد | Replay همان Recordهای P-02/P-03D پس از Restore؛ Inbox/Cursor محصول‌محور |
| P-06 | کلید `correlation_map` برابر Tenant + Source Event است؛ Product Domain شامل `platform` است | افزودن Scope Kind/ID به کلید Correlation؛ نگاشت Platform به Platform Scope |
| P-07B | Productهای Producer/Consumer و Schema Version بررسی می‌شوند؛ هویت Canonical Source و Trace Mapping وجود ندارد | اتصال مجوز Event به Envelope، هویت Source و Trace Context |
| P-08 | Build و Verifier به Affiliate & Agent محدودند | Product ورودی صریح و Allow-list شده Build و بخشی از Artifact Metadata/Provenance باشد |

## ۵. توالی اجرای P-09

- **P-09A — خط مبنای Contract:** مدل Scope، Tupleهای هویت، Envelope، Validator بدون Dependency خارجی و تست‌های مثبت/منفی. این PR نخستین Slice را پیاده می‌کند.
- **P-09B — Correlation در P-06:** کلید Correlation محصول/پلتفرم‌محور؛ تست برخورد UUID یکسان Source در Affiliate و Lottery و منع خواندن بین Scopeها.
- **P-09C — Artifactهای Product-aware در P-08:** Build پارامتری Affiliate و Lottery، اتصال Product به Metadata/Provenance، تست Compatibility و Promotion/Rollback.
- **P-09D — نگاشت Event Contract در P-07B:** اتصال Producer Contract، مجوز Consumer، هویت Canonical Source، Schema Version و W3C Trace Context.
- **P-09E — اتصال Recovery روی Recordهای مشترک:** Restore/Replay همان Schema و Recordهای P-02/P-03D؛ اثبات Rollback اتمیک، Idempotency، Reconciliation و جداسازی Product. ترتیب Aggregate در قرارداد فعلی P-03D تعریف نشده و باید جداگانه تصمیم‌گیری شود.
- **P-09F — مجموعه یکپارچه Failure/Concurrency:** Candidate ایزوله، Delivery تکراری، Sequence Gap، Product ID متعارض، قطع Replay، شکست Restore، Correlation قدیمی، دستکاری Artifact و Rollback.

## ۶. دروازه‌های پذیرش

- UUID یکسان Source Event در Affiliate و Lottery برای یک Tenant، دو Identity متمایز باقی بماند.
- `shared` به‌عنوان Product پذیرفته نشود؛ Platform Scope نتواند Economic Effect یا Journal مالی بسازد.
- Event Envelope به Tenant، Scope، Source Identity، Schema و Context مربوط به CloudEvents نیاز داشته باشد.
- Lookup در P-06 نتواند Source Event محصول دیگر را افشا کند یا به‌صورت مبهم resolve کند.
- P-07B Eventی را که Producer Identity، Tenant، Scope، Schema یا Trace Contract ناسازگار دارد مجاز نکند.
- P-08 بتواند Artifact جداگانه Affiliate و Lottery بسازد و Verify کند؛ Provenance باید Product انتخاب‌شده و Digest دقیق Artifact را مقید کند.
- P-05 Recovery همان Recordهای Ledger/Outbox/Provider Inbox را بازیابی و Replay کند، نه مدل حسابداری موازی.
- تست‌های مثبت، منفی، هم‌زمانی و Failure Injection روی SHA نهایی Candidate موفق شوند؛ هیچ Check ردشده/Skipشده Pass محسوب نشود.
- اسناد فارسی و انگلیسی در یک تغییر به‌روز و از نظر معنایی بازبینی شوند.

## ۷. خارج از محدوده

هیچ Provider واقعی، KMS/HSM Production، Broker، Object Store، داده مشتری، Database Production، جابه‌جایی پول، سیاست حسابداری، تعهد RPO/RTO، Deploy Production یا مجوز Release در این کار نیست. هیچ PR Merge نمی‌شود و Ref شاخه Main تغییر نمی‌کند.

## P-09B — Correlation محصول‌محور در Observability

پیاده‌سازی P-06 اکنون از Tuple استاندارد Tenant/Scope/Source Event برای یکتایی Correlation، Grant دسترسی Forensic و فیلتر View استفاده می‌کند. یک سناریوی خصمانه قطعی، UUID یکسان Source Event و Trace ID را برای Affiliate و Lottery در یک Tenant تکرار می‌کند؛ Grant ممیزی‌شده هر محصول باید دقیقاً فقط ردیف خودش را نمایش دهد. این تغییر ابهام Correlation صرفاً Tenantمحور را در Slice ساختگی P-06 می‌بندد. بااین‌حال هنوز P-05 Recovery، مجوزدهی Event در P-07B یا Provenance Artifact در P-08 را منطبق نمی‌کند؛ آن‌ها Sliceهای مستقل بعدی P-09 هستند.


### شواهد پذیرش P-09B

- Workflow قرارداد P-09A با شناسه [45628562955](https://github.com/tecpey/lottorito-platform/actions/runs/45628562955) موفق شد؛ شامل اعتبارسنجی JSON، Compile و ۱۳ تست از ۱۳ تست.
- Correlation محصول‌محور P-06 با شناسه [45628562800](https://github.com/tecpey/lottorito-platform/actions/runs/45628562800) روی Head دقیق شاخه `109530985a00bd158866e45a8c11e3bb5f520f53` موفق شد.
- Documentation Governance با شناسه [45628562765](https://github.com/tecpey/lottorito-platform/actions/runs/45628562765) موفق شد (۵۸ جفت سند دوزبانه و ۱۳۶ لینک محلی).

Fixture مربوط به P-06 اکنون یکتایی محصول‌محور و فیلتر Forensic را برای UUIDهای یکسان Source Event اثبات می‌کند. P-05B، P-07B و P-08 همچنان دروازه‌های یکپارچه‌سازی باز هستند.

### شواهد پذیرش P-09C

Build/Provenance محصول‌محور و اعمال Product Scope در چرخه عمر P-08 در اجرای [45629980686](https://github.com/tecpey/lottorito-platform/actions/runs/45629980686) موفق شد: **۵۳ تست از ۵۳ تست**. Artifact هر دو Product به‌صورت مستقل ساخته می‌شود و هویت Product در Payload، Release Metadata و Provenance ثبت می‌گردد. Deployment Controller، Promotion و Rollback بین Scopeهای محصولی را رد می‌کند. این فقط Slice ساختگی P-08 را می‌بندد؛ Recovery در P-05B و هم‌ترازی Event Contract در P-07B همچنان باز هستند.

### شواهد پذیرش P-09D

P-07B اکنون Envelope محصول‌محور Canonical را اعتبارسنجی می‌کند: UUID مربوط به Tenant، Product Scope مقید به Producer، UUID مربوط به Source Event، Schema Version و W3C Traceparent. خروجی Dispatch دقیقاً Tuple هویت Source و Trace ID موردنیاز P-06 را برمی‌گرداند. CI با شناسه [45631269584](https://github.com/tecpey/lottorito-platform/actions/runs/45631269584) با **۴۲ تست از ۴۲ تست** موفق شد. Registry و Fixtureهای Tenant ساختگی اکنون از همان انواع هویتی قرارداد P-09 استفاده می‌کنند. Eventهای Platform-originated به‌طور ضمنی از طریق Service Identity محصولات پذیرفته نمی‌شوند.


### شواهد پذیرش P-09E

P-09E در Workflow بازیابی P-05 با شناسه [45635972222](https://github.com/tecpey/lottorito-platform/actions/runs/45635972222) روی Head دقیق Candidate برابر با 73d7d0daa46e6a019020fc25ace315836d270a6f موفق شد. اجرا، Schemaهای واقعی P-02، P-03C و P-03D را در Database مستقل و دورریختنی اعمال کرد، Backup فیزیکی گرفت، pg_verifybackup را با موفقیت گذراند، Cluster بازیابی‌شده مستقل را راه‌اندازی کرد، Rollback تراکنش Posting ناموفق را تزریق و تأیید کرد، سه رکورد پذیرفته‌شده P-03D Inbox را از طریق post_journal واقعی P-02 Replay کرد و Idempotent Retry، جداسازی RLS در سطح Tenant/Product پس از Restore، توازن Journalها، اتمیک‌بودن Delivery State در Outbox و صفر بودن استثناهای Reconciliation بین Provider و Ledger را بررسی کرد. یک Source Event UUID و Provider Event ID یکسان عمداً بین Affiliate/Lottery در یک Tenant و Affiliate در Tenant دوم تکرار شدند.

Documentation Governance با شناسه [45635972312](https://github.com/tecpey/lottorito-platform/actions/runs/45635972312) روی همان Head موفق شد (۵۸ جفت Markdown دوزبانه و ۱۳۶ لینک محلی). این نتیجه فقط Slice مربوط به Backup فیزیکی، Restore و Replay تراکنشی P-09E را می‌بندد. ترتیب Aggregate، Fencing هم‌زمان Lease منقضی‌شده، اجرای کامل Worker جاوااسکریپت Provider، معماری PITR عملیاتی، RPO/RTO و آمادگی Production را اثبات نمی‌کند؛ این موارد دروازه‌های مستقل بعدی هستند.

### تأیید مجدد P-09E روی Head دقیق

Workflow بازیابی P-05 با شناسه [45637659268](https://github.com/tecpey/lottorito-platform/actions/runs/45637659268) بار دیگر روی Head کاندید 2b393cc8c41226a20333f34559ac6952883901a3 موفق شد. Markerهای P-09E موفقیت Backup فیزیکی، pg_verifybackup، Restore مستقل، Schema و Recordهای واقعی P-02/P-03C/P-03D، Rollback تراکنش تزریق‌شده، Replay روی Provider Inbox، Idempotency اثر مالی، اتمیک‌بودن Delivery State در Outbox، RLS مربوط به Tenant/Product پس از Restore، جداسازی برخورد Source UUID یکسان و صفر بودن استثناهای Reconciliation را تأیید می‌کنند. PITR در P-05A، Fixture در P-05B و آزمون‌های منفی WAL نیز موفق شدند. Documentation Governance با شناسه [45637659297](https://github.com/tecpey/lottorito-platform/actions/runs/45637659297) روی همان Head موفق شد (۵۸ جفت Markdown دوزبانه و ۱۳۶ لینک محلی).


### Slice پذیرش هم‌زمانی و جداسازی Scope در P-09F

Workflow یکپارچه‌سازی P-03C/P-03D با شناسه [45637659485](https://github.com/tecpey/lottorito-platform/actions/runs/45637659485) روی 2b393cc8c41226a20333f34559ac6952883901a3 موفق شد: P-03C با **۱۵ از ۱۵** و P-03D با **۲۵ از ۲۵** تست، بدون شکست. سه تست با Worker واقعی Provider در Node.js 26 و PostgreSQL 18.7 اجرا شدند: ۱) رقابت دو Worker برای Claim یک Event فقط یک Lease صادر می‌کند و پردازش هم‌زمان به یک `processed` و یک `stale` با یک Journal/Outbox/Delivery می‌رسد؛ ۲) Lease منقضی‌شده تصاحب می‌شود و Token Worker قدیمی در رقابت با Worker جدید رد می‌شود؛ ۳) Provider Event ID و Source Event UUID یکسان بین Affiliate/Lottery در یک Tenant و Affiliate در Tenant دوم مستقل پردازش می‌شوند و برای هر Scope یک Journal/Outbox/Delivery و صفر استثنای Reconciliation داریم.

مستندات PostgreSQL، `FOR UPDATE SKIP LOCKED` را برای مصرف‌کننده‌های Queue مناسب می‌دانند، اما هشدار می‌دهند که نمای ناسازگار ایجاد می‌کند و برای Read عمومی مناسب نیست ([قفل‌گذاری SELECT](https://www.postgresql.org/docs/18/sql-select.html)، [قفل‌های سطح ردیف](https://www.postgresql.org/docs/18/explicit-locking.html)). Lease Token یک شرط Fencing در سطح Application است و جایگزین Row Lock نیست.

این نتیجه فقط نخستین Slice هم‌زمانی/جداسازی Scope در P-09F را می‌بندد. P-03D معنای Aggregate Sequence ندارد؛ اجرای مستقیم Node Worker روی Cluster بازیابی‌شده P-09E و Interleavingهای گسترده‌تر Failure همچنان باز هستند.


### اصلاح انطباق Validator در P-09A — ۲۰۲۶-۱۱-۲۵

در بازبینی مستقل Contract در برابر Validator مشخص شد که فایل `contract.json` وجود `traceparent` را اجباری تعریف کرده، اما تابع `validate_event()` حضور آن را کنترل نمی‌کرد. اکنون Validator این فیلد را الزامی می‌کند و ساختار نسخه ۰۰ استاندارد W3C Trace Context، حروف هگزادسیمال کوچک و غیرصفر بودن trace-id و parent-id را اعتبارسنجی می‌کند. Trace ID معتبر نیز در خروجی Event برگردانده می‌شود تا برای Correlation بعدی قابل استفاده باشد. شناسه Trace مستقل در Correlation نیز مقدار تماماً صفر را رد می‌کند.

پوشش Regression اکنون شامل traceparent مفقود، مقادیر دارای ساختار یا نسخه نامعتبر، trace-id/parent-id صفر و شناسه Correlation تماماً صفر است. انتظار می‌رود مجموعه تست P-09A شامل ۱۵ تست باشد؛ پذیرش نهایی منوط به موفقیت CI روی Head دقیق جدید PR است. این اصلاح هنوز اعتبارسنجی معنایی Timestamp با RFC 3339 یا URI-reference را اضافه نمی‌کند و Validator را به P-02 تا P-08 متصل نمی‌سازد.

مبنای تحقیق: [توصیه‌نامه W3C Trace Context](https://www.w3.org/TR/trace-context/) (ساختار traceparent نسخه ۰۰ و شناسه‌های صفر نامعتبر)؛ [مشخصات اصلی CloudEvents](https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md) (ویژگی‌های اصلی اجباری و مدل Extension Attribute).


### P-09G — انطباق معنایی رویداد (۲۰۲۶-۱۱-۲۵)

در P-09 اکنون `id` و `type` در CloudEvents باید رشته غیرخالی باشند؛ `source` و `dataschema` باید URI-reference غیرخالی مطابق RFC 3986 باشند؛ و `time` باید از نظر نحو RFC 3339 و محدوده تاریخ تقویمی، ساعت و Offset معتبر باشد. Extension Attributeهای CloudEvents همچنان مجازند. فیلدهای اختصاصی و الزامی Lottorito در `contract.json` تعریف شده‌اند.

نوع رویداد `ledger.journal.posted` صراحتاً فقط به Product Scope تعلق دارد: رویداد مالی با Scope از نوع `platform` رد می‌شود، درحالی‌که رویداد غیرمالی پلتفرم از نظر ساختاری معتبر می‌ماند. این فقط یک قاعده محدود است و به معنای تکمیل Registry تمام Event Typeها نیست؛ مجوزدهی وابسته به Producer همچنان در P-07B انجام می‌شود. اتصال Validator به مسیرهای واقعی Ingress و Dispatch دروازه مستقل P-09H است.


### P-09H — اعمال قرارداد در Ingress، Dispatch و Replay واقعی Prototypeها (۲۰۲۶-۱۱-۲۵)

اعتبارسنج Canonical اکنون پیاده‌سازی Node.js نیز در مسیر `prototypes/p09-contract-recovery/contract.mjs` دارد که از نظر شکل UUID، Scope، ویژگی‌های CloudEvents، نویسه‌های URI-reference مطابق RFC 3986، زمان RFC 3339، نسخه Schema و W3C Trace Context v00 با نسخه Python هم‌راستا شده است. Worker مربوط به Provider مستقیماً از همین پیاده‌سازی استفاده می‌کند تا مجموعه قانون سومی و مستقل ایجاد نشود.

در P-03D، Envelope استاندارد فقط با استفاده از اطلاعات Installation مورد اعتماد و Event Mapping تأییدشده ساخته می‌شود. پس از تأیید امضای Raw Body، Tenant و Product از Installation استخراج می‌شوند؛ شناسه رویداد Provider به‌عنوان CloudEvents `id` استفاده می‌شود؛ یک `sourceeventid` مستقل و Trace Context جدید تولید می‌شود؛ و UUID مربوط به Source Event هم در Envelope و هم در ردیف Inbox ذخیره می‌شود. فیلدهای Tenant/Product ارسالی Provider قادر به بازنویسی این مقادیر نیستند. نبود Schema Mapping یا زمان غیرمنطبق با RFC 3339 پیش از ثبت در Inbox رد می‌شود. پیش از ثبت Journal نیز Envelope ذخیره‌شده و تطابق هویت آن با Tenant/Product/Source Event دوباره اعتبارسنجی می‌شود؛ هویت خراب پیش از هر اثر اقتصادی به قرنطینه می‌رود.

در Dispatch مربوط به P-07B، Validator مشترک Python پس از کنترل‌های فعلی احراز هویت، Scope مربوط به Producer و کدهای دلیل Deny اجرا می‌شود. مسیر Recovery/Replay در P-05E نیز Envelope ذخیره‌شده را با ردیف Inbox تطبیق می‌دهد و در صورت مغایرت Tenant، Product، Provider Event، Source Event، Schema یا Trace از Posting جلوگیری می‌کند. Fixtureهای بازیابی ساختگی نیز اکنون Envelope کامل الزامی را دارند.

این تغییرات اتصال Prototypeهای ساختگی هستند و شواهد استقرار Production محسوب نمی‌شوند. پذیرش P-09H منوط به موفقیت ماتریس کامل CI روی Head نهایی PR است؛ اتصال زنده Providerها، نگهداری کلیدهای Production و سیم‌کشی Runtime محیط واقعی خارج از محدوده این مرحله‌اند.
