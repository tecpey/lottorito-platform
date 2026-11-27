# G09-A3 افیلیت — بسته تصمیم‌های امنیتی و برنامه اثبات Runtime ساختگی

**شناسه سند:** LOT-AFFILIATE-G09-A3-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیشنهادی؛ بدون تصویب امنیتی، فناوری یا تولید | **تاریخ:** ۲۰۲۶-۱۱-۲۷

## ۱. هدف و مرجع اختیار تصمیم

این بسته، LOT-AFFILIATE-SEC-ACC-001 را به رکوردهای تصمیم و برنامه اثبات بازتولیدپذیر و ایزوله تبدیل می‌کند. این صرفاً سند طراحی است و هیچ ارائه‌دهنده هویت، پروفایل توکن، پایگاه داده، صف، KMS، بستر استقرار، شریک، فرمول تجاری یا حوزه قضایی را انتخاب نمی‌کند.

**قاعده اختیار:** یک تصمیم فقط زمانی Accepted می‌شود که مالک پاسخ‌گو و بازبینان لازم، دامنه دقیق آن را صریحاً تأیید کنند و دفتر تصمیم‌ها نام تأییدکنندگان، تاریخ، دلیل و شواهد را ثبت کند. تا آن زمان تمام مقادیر زیر Proposed، Open یا TBD باقی می‌مانند. این بسته به‌تنهایی مجوز پیاده‌سازی نیست.

## ۲. دفتر تصمیم‌های G09-A3

| شناسه | موضوع تصمیم | جهت پیشنهادی (تصویب‌نشده) | شواهد و بازبینان لازم | وضعیت فعلی |
|---|---|---|---|---|
| A3-IAM-01 | طبقه‌بندی Principal | تفکیک کاربر انسانی، برنامه تفویض‌شده، کلاینت ماشینی شریک، Workload پلتفرم و Principal دسترسی اضطراری؛ عنوان Role به‌تنهایی منشأ اختیار نیست | مدل تهدید، تطبیق با LOT-IAM-TENANT-001 و سناریوهای سوءاستفاده؛ مالک، معماری، IAM/امنیت، حریم خصوصی | Proposed |
| A3-IAM-02 | ارزیابی مجوز | رد پیش‌فرض؛ Capability به‌علاوه عضویت/Binding مستأجر، Entitlement محصول و Policy شیء/منبع؛ ارزیابی سمت سرور در هر درخواست و بازبینی مجدد هنگام اجرای Worker | ماتریس کامل Operation به Capability، تست BOLA و الزام سازگاری ابطال؛ مالک، معماری، امنیت، محصول | Proposed |
| A3-IAM-03 | پروفایل و چرخه Credential | اعتبارنامه‌های مستقل برای Management و Ingress؛ در صورت پشتیبانی اعتبار کوتاه‌مدت؛ وضعیت‌های صدور، فعال‌سازی، چرخش، ابطال، انقضا و Audit صریح | الزامات Issuer/Audience/Client Binding، نگهداری کلید، پاسخ به افشا، SLA ابطال و Runbook؛ مالک، IAM/امنیت، SRE، حقوقی/حریم خصوصی | Open |
| A3-REG-01 | مالکیت Installation Registry | شناسه Installation تغییرناپذیر تحت کنترل پلتفرم، با Binding نسخه‌دار Tenant/Product/Environment و تاریخچه تأیید | مالکیت و RACI، چرخه عمر/State Machine، مهاجرت و خروج؛ مالک، معماری، امنیت، عملیات | Proposed |
| A3-REG-02 | Event/Schema Registry | Allowlist برای Source Namespace، Event Type، Extension و نسخه Schema تغییرناپذیر؛ Resolve محلی/Pinned؛ رد پیش‌فرض | کنترل تغییر Registry، سیاست سازگاری، منشأ Schema و بازبینی؛ مالک دامنه، شریک فقط پس از مجوز، امنیت | Proposed |
| A3-IDEM-01 | هویت Source Event | کلید یکتای پایدار: Tenant + Product + Installation + Source + ID؛ مستقل از کلید Retry درخواست HTTP و هویت Economic Effect | تحلیل برخورد، اثبات Unique Constraint پایگاه داده و معنای Replay؛ معماری، داده، امنیت، مالی | Proposed |
| A3-IDEM-02 | پروفایل Fingerprint | ارزیابی Parse سخت‌گیرانه JSON، رد Member تکراری، RFC 8785 JCS و SHA-256؛ نگهداری جداگانه Digest بایت خام و نسخه‌بندی پروفایل | بازبینی مستقل پیاده‌سازی، بررسی استاندارد، بردارهای Cross-language، موارد مرزی عدد/Unicode و راهبرد مهاجرت؛ معماری، امنیت | Proposed؛ تصویب نشده |
| A3-IDEM-03 | معنای Conflict و هم‌زمانی | هویت یکسان و Fingerprint یکسان به یک Receipt/Job پایدار منتهی شود؛ هویت یکسان با Fingerprint متفاوت Conflict یکپارچگی است؛ رقابت با Transaction/Constraint پایگاه داده حل شود | تست Race با Isolation واقعی، تست Retry/گم‌شدن پاسخ و رفتار Quarantine/Audit؛ داده، امنیت، SRE | Proposed |
| A3-RES-01 | سقف منابع | تعیین Limit در سطح درخواست، Parser، Installation، Tenant و کل سرویس؛ Quota مستأجر از Hard Ceiling سراسری بالاتر نرود | مدل بار، Benchmark/Load Test، مدل سوءاستفاده، ظرفیت/هزینه و آستانه Alert؛ محصول، امنیت، SRE، مالک | Open؛ اعداد TBD |
| A3-DATA-01 | طبقه‌بندی و حداقل‌سازی داده | طبقه‌بندی جداگانه Envelope، Payload خام، Event نرمال‌شده، شناسه‌ها، Fingerprint و Metadata عملیاتی؛ گردآوری حداقل فیلد لازم | هدف/مبنای قانونی، نقشه جریان داده، مدل تهدید، حوزه قضایی و قرارداد شریک؛ حریم خصوصی/حقوقی، امنیت، محصول | Open |
| A3-DATA-02 | Retention، حذف و Backup | برنامه نگهداری و حذف برای هر کلاس داده؛ تعیین Legal Hold، انقضای Backup، رفتار Restore و بقای Digest پس از حذف Payload | قانون/قرارداد قابل‌اعمال، تست Restore، شواهد حذف و ارزیابی بازشناسایی؛ حقوقی/حریم خصوصی، امنیت، SRE، مالک | Open؛ مدت‌ها TBD |
| A3-DATA-03 | رمزنگاری و حاکمیت کلید | رمزنگاری در انتقال و ذخیره؛ جداسازی کلید و دسترسی کنترل‌شده؛ انتخاب KMS/HSM همچنان تصمیم فناوری است | مالکیت کلید، چرخش/ابطال، ثبت دسترسی، بازیابی و بازبینی تهدید؛ امنیت، SRE، مالک | Proposed؛ Provider نامشخص |
| A3-AUD-01 | شواهد Audit | رکوردهای Append-only و کنترل‌شده برای تغییر Credential/Installation/Allowlist/Policy، نتایج Event، Replay، انتقال‌های Worker و دسترسی ممتاز | فهرست Audit مبتنی بر تهدید، مقاومت در برابر دستکاری، دسترسی/نگهداری و Runbook رخداد؛ امنیت، عملیات، حقوقی/حریم خصوصی | Proposed |
| A3-FIN-01 | مرز Economic Effect | Ingress فقط Receipt منبع و کار پایدار را ثبت کند؛ هیچ تغییری در Wallet/Ledger/Payment/Settlement/Payout ندهد؛ اثر کمیسیون احتمالی آینده نیازمند Command، مجوز و Effect Key مستقل است | تطبیق LOT-FIN-POST-001، اثبات صفر نوشتن، مالکیت مالی Effect Identity و Reconciliation؛ مالی، امنیت، معماری، مالک | قید پیشنهادی؛ مجوز ثبت مالی وجود ندارد |

### ۲.۱ الگوی ثبت تصمیم

هر تصمیمی که به Accepted تغییر می‌کند باید این موارد را ثبت کند: شناسه پایدار؛ دامنه و استثناهای دقیق؛ مالک تصمیم؛ بازبینان لازم؛ وضعیت؛ تاریخ؛ مسئله/زمینه؛ گزینه‌های بررسی‌شده؛ گزینه منتخب و دلیل؛ اثر امنیتی/حریم خصوصی/مستأجر/مالی؛ پیامد عملیاتی؛ مهاجرت/بازگشت؛ پیوند شواهد؛ و محرک بازبینی مجدد. سکوت، موفقیت Workflow مستندات یا تست ساختگی به معنی تصویب نیست.

## ۳. اثبات Runtime ساختگی — دامنه و مرز اعتماد

### ۳.۱ اثبات مجاز

فقط یک محیط ایزوله و دورریختنی با Tenantهای ساختگی A/B، Principalهای تولیدشده، Installationهای مصنوعی، Fixtureهای ساختگی Event و Credential غیرتولیدی بسازید. تست احراز هویت با Stub یا Issuer محلی تحت کنترل فقط پس از مستندسازی صریح پروفایل تست مجاز است. این اثبات نباید به شریک واقعی، Endpoint تولید، URL خارجی Schema، Provider پرداخت، Wallet یا Ledger متصل شود.

هدف اثبات: رویداد ساختگی احراز هویت‌شده ← Binding مورداعتماد Installation ← Parse سخت‌گیرانه و اعتبارسنجی Registry ← ثبت اتمیک Inbox Receipt و Job/Outbox پایدار در یک Transaction ← Deduplication/Conflict قطعی ← Claim/Retry/Recovery در Worker ← نتیجه نهایی پردازش صریح.

### ۳.۲ رفتارهای ممنوع

- استفاده از Payload یا Credential واقعی مشتری/بازیکن/شریک.
- Endpoint عمومی Ingress، Callback شریک خارجی یا Fetch کردن Schema خارجی.
- پایگاه داده Production، داده Staging مشترک، Payment Rail، موجودی Wallet یا نوشتن Ledger.
- فرض فرمول کمیسیون، Qualification، Payout یا هر Economic Effect.
- Load Test نامحدود، سرویس پولی، چرخش Secret یا تغییر تنظیمات مخزن/استقرار.
- ادعای آمادگی Production بر اساس Pass محلی یا Synthetic.

### ۳.۳ اجزای Harness

۱. **Fixture Generator:** شناسه‌های قطعی Tenant/Principal/Installation و CloudEvents ساختگی؛ Seed ثابت در هر اجرا ثبت شود.
۲. **Identity Test Double:** Issuer/Audience/Client/Credential با وضعیت صریح؛ پشتیبانی از Credential مفقود، نادرست، منقضی، باطل و چرخانده‌شده. این IAM تولیدی نیست.
۳. **Installation و Schema Registry:** Fixtureهای محلی تغییرناپذیر؛ تغییرات Registry نسخه‌دار و Audit شوند؛ ارجاع Schema فقط به Artifact محلی Pinشده Resolve شود.
۴. **Ingress تحت آزمون:** همان مسیر Authorization، Parser، Validation، Persistence و Error موردنظر Runtime؛ پیکربندی تست باید آشکارا از Production جدا باشد.
۵. **موتور واقعی Persistence تراکنشی:** فقط پس از اجازه تصمیم فناوری از پایگاه داده کاندید منتخب استفاده شود. Map حافظه‌ای یا Repository Mock نمی‌تواند Atomicity، Unique Constraint، Isolation یا Crash Recovery را اثبات کند.
۶. **Job/Outbox پایدار:** همراه Inbox در همان Transaction ذخیره شود؛ اعلان Queue می‌تواند تأخیر یا تکرار داشته باشد و منبع حقیقت نیست.
۷. **Worker Harness:** ساعت قابل‌کنترل، انقضای Lease، Fencing Token، تزریق Crash و زمان‌بند Retry.
۸. **محافظ Egress شبکه:** خروجی شبکه به‌صورت پیش‌فرض مسدود؛ برای URL/Schema کنترل‌شده توسط Payload، صفر تلاش DNS/HTTP اثبات شود.
۹. **Fault Injector:** شکست قبل از Write، بین Writeها، قبل از Commit، بعد از Commit/قبل از پاسخ، هنگام Claim، حین پردازش دامنه و پس از انقضای Lease.
۱۰. **Evidence Collector:** Log پاک‌سازی‌شده، Snapshot پایگاه داده، Trace تراکنش، گزارش تست، SHA کامیت، نسخه Fixture، نسخه ابزار/محیط و Run ID. Secret یا Payload حساس خام جمع‌آوری نشود.

## ۴. مراحل اثبات و Gateهای پذیرش

| مرحله | آزمایش‌های لازم | شرط Pass | شرط توقف |
|---|---|---|---|
| P0 — ایزولاسیون Harness | Namespace/DB دورریختنی؛ Fixture ساختگی؛ منع Egress؛ نبود اتصال مالی/اعتبارنامه واقعی | Assertionهای ایزولاسیون موفق؛ صفر Egress خارجی؛ صفر اتصال مالی | هر Credential/داده واقعی، فراخوانی خارجی یا اتصال مالی |
| P1 — مرز هویت و Tenant | Credential مفقود/نادرست/منقضی/باطل؛ Issuer/Audience/Client نادرست؛ تلاش Tenant A برای B؛ ابطال Membership؛ دسترسی Object-level | رد پیش‌فرض؛ Tenant فقط از Installation مورداعتماد استخراج شود؛ بدون نشت داده یا وجود Cross-tenant | هر خواندن/نوشتن Cross-tenant یا Override مستأجر غیرقابل‌اعتماد |
| P2 — Parse و Registry | Member تکراری JSON؛ UTF-8 نامعتبر؛ Payload عمیق/بزرگ؛ Source/Type/Extension/Schema ناشناخته؛ ارجاع Schema راه‌دور/خصوصی/Redirect | رد سخت‌گیرانه و محدود؛ مقادیر ناشناخته Registry رد شوند؛ صفر Fetch خروجی | ابهام Parser، فرسودگی منابع یا هر Fetch URL Schema |
| P3 — Idempotency و Concurrency | Duplicate ترتیبی؛ N تحویل هم‌زمان یکسان؛ هویت یکسان/Fingerprint متفاوت؛ عدم تطابق Request-Key؛ گم‌شدن پاسخ و Retry | دقیقاً یک Receipt و Job پایدار برای یک هویت Source Event؛ Conflictها Quarantine شوند؛ Retry نتیجه پایدار قبلی را برگرداند | Receipt/Job تکراری، Overwrite خاموش یا اثر تجاری |
| P4 — Transaction و Recovery | شکست بین Inbox/Job؛ Rollback؛ Commit و سپس گم‌شدن ACK؛ Crash Worker قبل/بعد Claim؛ انقضای Lease و Worker قدیمی؛ اعلان Outbox تکراری | بدون ACK پیش از Commit؛ Transaction ناموفق هیچ‌یک را باقی نگذارد؛ Retry پس از Commit همان Receipt را بیابد؛ Fencing مانع Transition قدیمی شود | ACK بدون جفت پایدار، Job یتیم قابل‌اجرا، پردازش تکراری یا Overwrite قدیمی |
| P5 — منابع و حریم خصوصی | مرز N/N+1 پس از تصویب؛ جداسازی Quota مستأجر؛ Backpressure سراسری؛ Canaryهای Secret/PII ساختگی در Log/Error/Trace | رد محدود و قطعی؛ یک Tenant دیگران را از منابع محروم نکند؛ Canaryها Redact شوند؛ Audit قابل انتساب باشد | کار نامحدود، گرسنگی Cross-tenant یا نشت داده حساس در Log |
| P6 — عدم اثر مالی | Instrument تمام مجوزهای DB/جدول‌ها و Clientهای خروجی؛ ارسال Event پذیرفته، Duplicate، Conflict و خطای Worker | هیچ اتصال یا مسیر نوشتن Wallet/Ledger/Payment/Settlement/Payout فراخوانی نشود؛ هیچ Economic Effect ثبت نشود | هر تغییر مالی، انتقال وجه خارجی یا Qualification کمیسیون ضمنی |

**مهم:** «دقیقاً یک» در P3 فقط به یک Inbox Receipt و Job پایدار برای یک هویت Source Event اشاره دارد. این عبارت تحویل شبکه‌ای Exactly-once یا اثر خارجی Exactly-once را ادعا نمی‌کند. Economic Effect احتمالی آینده به طراحی و اثبات مستقل نیاز دارد.

## ۵. تکنیک‌های تست لازم

- Property-based و Mutation Testing برای Parser، Canonicalization، Allowlist Schema و Policy مجوزدهی.
- Golden Vectorهای Cross-language برای Canonicalization، شامل Unicode، کاراکترهای Escapeشده، مرز Integer/Decimal، Exponent، منفی صفر، ترتیب Memberهای Object و کلید تکراری. مقادیر خارج از پروفایل انتخابی رد شوند، نه اینکه بی‌صدا Coerce شوند.
- تست Race پایگاه داده با Connection/Process مستقل و رفتار Isolation/Unique Constraint واقعی کاندید منتخب.
- Fault Injection در تمام مرزهای Transaction و Worker؛ بررسی هم‌زمان وضعیت DB و پاسخ قابل مشاهده.
- تست زمان‌محور برای انقضا/ابطال Credential، Lease، Retry و انتقال Retention.
- Assertion منفی برای شبکه خروجی، نشت Secret/PII و تمام جدول‌ها/Clientهای مالی ممنوع.
- بازبینی مستقل خود Test Harness؛ Harnessای که فرض‌های پیاده‌سازی را تکرار می‌کند ممکن است اعتماد کاذب بسازد.

## ۶. بسته شواهد هر اجرا

این موارد ثبت شوند: شناسه و مرحله اثبات؛ SHA دقیق Source؛ وضعیت Clean/Dirty؛ شرح ایزولاسیون محیط؛ نسخه DB/Queue/Runtime؛ نسخه و Seed تولید Fixture؛ فرمان تست و نتیجه کامل؛ تعداد تست‌ها؛ تست‌های شکست‌خورده/Skipشده؛ نقطه Fault Injection؛ Assertionهای قبل/بعد؛ Artifactهای پاک‌سازی‌شده و Checksum؛ Telemetry خروجی شبکه؛ Telemetry دسترسی/نوشتن مالی؛ بازبین و تاریخ بازبینی.

واژگان وضعیت شواهد: PASS، FAIL، PENDING، BLOCKED، NOT TESTED. هر PASS فقط به تست، محیط و SHA مشخص تعلق دارد و به SHA یا محیط دیگر منتقل نمی‌شود.

## ۷. معیار خروج و تحویل

خروج طراحی G09-A3 مستلزم تعیین مالک و بازبین صریح برای تمام رکوردهای تصمیم است؛ هر مقدار حل‌نشده باید TBD بماند و هیچ تصمیم امنیتی لازم برای پیاده‌سازی نباید به‌صورت ضمنی Default شود. اثبات Synthetic فقط پس از تصویب دامنه محدود توسط مالک، انتخاب کاندید Persistence دورریختنی توسط معماری و تأیید کنترل‌های ایزولاسیون/Fault Injection توسط امنیت و عملیات آغاز می‌شود.

Sandbox شریک Gate بعدی است و مستلزم مستندات رسمی شریک، مجوز کتبی، داده تست ساختگی و پروفایل Credential مصوب است. Production نیز Gateهای مستقل حقوقی/حوزه قضایی، حریم خصوصی، ارزیابی امنیت، آمادگی عملیات، Policy مالی و تأیید صریح مالک را لازم دارد.

## ۸. پرسش‌های باز مسدودکننده تصویب

۱. کدام افراد/نقش‌های پاسخ‌گو تصمیم‌های IAM، امنیت، داده، منابع و مرز مالی را تصویب می‌کنند؟
۲. کدام Issuer هویت و پروفایل Client Authentication با پلتفرم و مدل عملیاتی واقعی سازگار است؟
۳. مالک ایجاد، تأیید، تعلیق، چرخش و Offboarding مربوط به Installation کیست؟
۴. چه کسی مجاز به ثبت Source، Type، Extension و Schema است و SLA بازبینی/سازگاری چیست؟
۵. کدام کاندید DB/Queue برای اثبات تراکنشی دورریختنی مجاز است؟
۶. چه مدل باری و چه سطح سرویس، سقف عددی منابع را تعیین می‌کند؟
۷. کدام حوزه قضایی، قرارداد شریک و هدف پردازش، طبقه‌بندی/نگهداری/حذف داده را تعیین می‌کنند؟
۸. کدام مرجع مالی مالک Economic-effect Identity و سیاست Reconciliation آینده است؟

تا زمان پاسخ و تصویب، تصمیم‌های مربوطه Open/TBD باقی می‌مانند. ساخت Adapter شریک، Credential واقعی، Endpoint تولید، ثبت مالی یا Deploy مجاز نیست.
