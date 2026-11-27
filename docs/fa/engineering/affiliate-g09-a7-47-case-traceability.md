# G09-A7 افیلیت — نقشه ردیابی ۴۷ سناریو و بستن تصمیم‌ها

**شناسه سند:** LOT-AFFILIATE-G09-A7-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** پیشنهادی؛ صرفاً طراحی؛ تمام سناریوها NOT RUN | **تاریخ:** ۲۰۲۶-۱۱-۲۷

## ۱. هدف و سطح اختیار

این Artifact به یافته A6-F01 پاسخ می‌دهد و قرارداد بستن Caseها برای A6-F02 تا F10 را فراهم می‌کند. هر شناسه پایدار A4 به Fixture، Stimulus قطعی، انتظار پروتکل/مجوزدهی، Assertionهای Persistence و مالی، Oracle مستقل، Evidence و وضعیت متصل شده است.

این سند کد اجرایی، Harness، اثبات Runtime، ADR فناوری، گواهی امنیتی یا مجوز اجرا نیست. همه Caseها NOT RUN هستند و Caseهای وابسته به Policy علاوه بر آن BLOCKED هستند. هیچ Runtime، دیتابیس، Queue، IAM، KMS/HSM، فروشنده، Schema فیزیکی یا سقف عددی منابع انتخاب نشده است.

## ۲. قرارداد طراحی هنجاری

### ۲.۱ جفت اتمیک الزامی و Outbox انتشار اختیاری

حداقل جفت پذیرش پایدار **InboxReceipt + WorkItem** است:
- InboxReceipt رکورد تغییرناپذیر هویت Event پذیرفته‌شده، Binding معتبر Installation، نسخه پروفایل Fingerprint، منشأ Schema، زمان پذیرش و مرجع Correlation است.
- WorkItem دقیقاً یک رکورد پایدار کار پردازشی است که مالک آن دامنه Ingress/Processing افیلیت است و به Receipt پیوند دارد.

هر دو رکورد در یک تراکنش Persistence با هم Commit می‌شوند یا هیچ‌کدام Commit نمی‌شوند. ACK پذیرش فقط پس از اطمینان از موفقیت Commit مجاز است. اگر نتیجه Commit برای Caller نامعلوم باشد، پیش از Retry وضعیت پایدار با هویت Event منبع مصوب تطبیق داده شود؛ ایجاد کورکورانه Pair دوم ممنوع است.

**DeliveryOutbox معادل WorkItem نیست.** اگر بعداً برای انتشار اعلان بیدارباش لازم شد، رکوردی جداگانه و مشروط با مالک مشخص و مرز اتمیک مستقل خواهد بود. این رکورد نباید WorkItem را اختیاری کند. تحویل Queue منبع وضعیت معتبر نیست. پیاده‌سازی فیزیکی نیازمند ADR است.

### ۲.۲ Namespaceهای هویت

سه هویت جدا هستند: ۱) هویت Event منبع که Tuple کاندید آن Tenant معتبر + Installation معتبر + Source Namespace مصوب + Event ID است؛ ۲) کلید Idempotency درخواست HTTP؛ ۳) هویت اثر اقتصادی در Command مالی مستقل و دارای مجوز در آینده. Tuple هویت منبع تا تعیین دامنه در LOT-EVENT-001 و دریافت قرارداد واقعی شریک تصویب نشده است. Payload نمی‌تواند اختیار Tenant یا Installation را تعیین کند.

Fingerprint فقط پس از Parse سخت‌گیرانه و تحت پروفایل نسخه‌بندی‌شده و مصوب محاسبه می‌شود. RFC 8785 فقط جزء کاندید Canonicalization است، نه Policy کامل Ingress.

### ۲.۳ Fixtureهای ساختگی

- F-IAM: Issuer ساختگی، نسخه Key، Credential معتبر/منقضی/لغوشده/ناشناخته و Binding Installation؛ بدون Secret واقعی.
- F-TEN: Tenant-A/B، Installation-A/B، Principal و Membership فعال/معلق که سمت سرور Seed می‌شوند.
- F-EVT: رجیستری محلی Event، نسخه‌های تغییرناپذیر Schema و Variantهای قطعی Event/Payload.
- F-DB: کاندید Persistence دورریختنی پس از A4-GATE-03؛ Connectionهای مستقل و Observer فقط‌خواندنی.
- F-WRK: دو Worker مستقل، ساعت قطعی، Lease/Generation و Fault Hook پس از A4-GATE-04.
- F-OBS: Canary ساختگی Secret/PII، Telemetry پاک‌سازی‌شده و Observer فقط‌خواندنی Evidence.
- F-NET: Egress پیش‌فرض Deny، مشاهده DNS/Connection و Namespace ایزوله.
- F-FIN: Fixture اثبات نبود Credential، Grant، Service Binding و Route مالی؛ نیازمند تأیید Finance/Security.
- F-LOAD: بار ساختگی Tenant و سقف مصوب؛ این سند مقدار عددی نمی‌سازد.
- F-DATA: طبقه‌بندی داده ساختگی و Policy مصوب Retention/Deletion/Backup/Evidence؛ پیش از A4-GATE-05 در دسترس نیست.

### ۲.۴ Assertionهای مشترک و توقف فوری

برای Event پذیرفته‌شده: دقیقاً یک InboxReceipt و یک WorkItem مرتبط؛ تغییرناپذیری هویت/Fingerprint/منشأ Schema؛ عدم ACK پیش از Commit؛ استخراج مجوز Tenant/Installation از Binding سمت سرور؛ صفر اتصال/فراخوانی/نوشتن/رکورد اثر اقتصادی در Wallet/Ledger/Payment/Settlement/Payout؛ عدم حضور Secret یا Payload ممنوع در Log/Trace/Metric/Evidence.

برای Event ردشده یا Conflict: Pair جدید و Mutation جزئی ایجاد نشود؛ مگر Case صریحاً Receipt قبلاً Commitشده را بررسی کند.

توقف فوری در صورت افشای بین Tenantها، Mutation غیرمجاز، Pair تکراری، Write از Worker قدیمی، دسترسی/تلاش مالی، Fetch یا DNS خارجی Schema، افشای Secret، دستکاری Evidence یا رشد نامحدود منابع. Evidence شکست پیش از Cleanup/Retry حفظ شود.

### ۲.۵ کاتالوگ Oracle مستقل

O-API: کلاس پاسخ/Problem Code از مرز Client. O-DB: مشاهده مستقل و فقط‌خواندنی Persistence. O-TX: مدرک Native تراکنش/Constraint/Lock دیتابیس، فقط پس از ADR. O-IAM: Audit مستقل Issuer/Verifier/Key ساختگی. O-WRK: Audit Generation Worker به‌همراه مشاهده مستقل State پایدار. O-NET: شمارنده Network Policy و Telemetry DNS/Connection. O-FIN: اسکن مستقل Credential/Grant/Service Binding/Route و Sentinel تلاش. O-OBS: Canary Scan در Log/Trace/Metric/Error/Evidence. O-LOAD: Workload Driver و Telemetry منابع/عدالت Tenant. O-DATA: تأیید مستقل Deletion/Backup/Restore و Audit دسترسی Evidence. O-SCHEMA: Digest Schema Pin‌شده و بردار Parser.

مسیر Evidence: run-id/case-id/oracle-id/artifact. Manifest هر Run باید Commit دقیق، نسخه A4/A5/A7، نسخه Harness، Fixture Seed، نسخه Policy/ADR، محیط، نسخه ابزار، زمان، نتیجه Case، Digest Artifact و Reviewer را ثبت کند. Credential خام و Payload نامحدود شبیه Production ممنوع است.

## ۳. Manifest ردیابی‌پذیری و پذیرش ۴۷ سناریو

ردیف‌ها قرارداد طراحی‌اند، نه تست پیاده‌سازی‌شده یا PASSشده. انتظار پاسخ به‌صورت کلاس پاسخ پایدار تعریف شده و HTTP Code در موارد قرارداد باز جعل نمی‌شود.

| شناسه پایدار A4 | Fixture و Stimulus قطعی | انتظار پروتکل/مجوزدهی | Assertionهای Persistence/مالی | Oracle مستقل و Evidence | وضعیت |
|---|---|---|---|---|---|
| A4-IAM-01 | F-IAM/F-DB؛ Credential حذف، خراب و Scheme پشتیبانی‌نشده. | رد پیش از Principal؛ بدون Fallback ناشناس. | بدون Pair؛ بدون دسترسی مالی. | O-IAM/O-API/O-DB؛ تصمیم Verifier، پاسخ و State Diff. | NOT RUN |
| A4-IAM-02 | F-IAM؛ Credential منقضی ارسال شود. | رد؛ Installation resolve نشود. | بدون Pair جدید؛ بدون دسترسی مالی. | O-IAM/O-API/O-DB؛ تصمیم انقضا و State Diff. | NOT RUN |
| A4-IAM-03 | F-IAM؛ Credential لغو، Cache/Verifier قدیمی نگه داشته شود و پس از مرز Revocation مصوب درخواست ارسال شود. | اجرای SLA سازگاری Revocation مصوب مالک؛ SLA باز است. | پس از مرز Pair ایجاد نشود؛ اختیار قدیمی رد شود. | O-IAM/O-API/O-DB؛ زمان Revocation، نسخه Cache و State Diff. | BLOCKED — POLICY |
| A4-IAM-04 | F-IAM؛ Signature معتبر با Issuer/Audience/Profile اشتباه. | رد؛ بدون Fallback Trust Profile. | بدون Pair و دسترسی مالی. | O-IAM/O-API/O-DB؛ تصمیم Issuer/Audience. | NOT RUN |
| A4-IAM-05 | F-IAM/F-TEN؛ Credential مربوط به Installation-A برای B ارائه شود. | رد Binding؛ Caller قادر به انتخاب Installation نیست. | بدون Receipt/Work برای B و Read بین Installationها. | O-IAM/O-API/O-DB؛ Snapshot Binding و Audit. | NOT RUN |
| A4-IAM-06 | F-IAM؛ Rotation، Key بازنشسته/ناشناخته و Key Reference خراب. | فقط بازه Rotation مصوب پذیرفته؛ Key بازنشسته/ناشناخته رد؛ بدون Fallback. | برای Key ردشده Pair نباشد؛ Secret افشا نشود. | O-IAM/O-API/O-OBS؛ تصمیم Key Version و Canary Scan. | BLOCKED — KEY POLICY |
| A4-AUTH-01 | F-TEN؛ Tenant-A شناسه Tenant را در Path/Query/Header/Body به B تغییر دهد. | Tenant سمت سرور ثابت؛ وجود Object در B افشا نشود. | بدون Read/Write در B یا Pair غیرمجاز. | O-API/O-DB؛ Trace هر بردار و State مربوط به B. | NOT RUN |
| A4-AUTH-02 | F-TEN؛ Tenant-A به Event/Installation/Object ID متعلق به B ارجاع دهد. | رد Object-level با رفتار ضد Enumeration. | داده B برنگردد/تغییر نکند؛ Pair غیرمجاز نسازد. | O-API/O-DB؛ ماتریس دسترسی Object و State Diff. | NOT RUN |
| A4-AUTH-03 | F-TEN؛ مدیر Tenant عملیات مختص Platform را فراخوانی کند. | رد Function-level؛ بدون ارتقای اختیار. | بدون Mutation ممتاز یا دسترسی مالی. | O-API/O-DB؛ تصمیم Capability و State Diff. | NOT RUN |
| A4-AUTH-04 | F-TEN؛ Mass Assignment فیلد tenantId/status/commission/role/createdAt. | فیلد محافظت‌شده طبق قرارداد Pinشده رد/نادیده؛ Client مرجع نیست. | ستون محافظت‌شده تغییر نکند؛ بدون Mutation نقش/اقتصادی. | O-API/O-DB؛ Snapshot قبل/بعد. | NOT RUN |
| A4-AUTH-05 | F-TEN/F-OBS؛ Canary فیلد داخلی، Payload خام، Credential و Metadata Tenant دیگر در Response. | Allowlist پاسخ فیلدهای حساس/داخلی/بین Tenant را حذف کند. | بدون Mutation؛ Canary در Response/Telemetry نباشد. | O-API/O-OBS/O-DB؛ Response Diff و Canary Scan. | NOT RUN |
| A4-AUTH-06 | F-TEN/F-WRK؛ Receipt/Work را Commit و پیش از بررسی Worker، Membership/Installation را در Barrier معلق کن. | پیروی از Policy مصوب مالک: لغو/پارک/پردازش با اختیار پذیرش/رد؛ Policy باز است. | State مطابق برنده Race مصوب؛ بدون پردازش غیرمجاز. | O-WRK/O-DB/O-API؛ Barrier، Lifecycle Audit و Row Version. | BLOCKED — POLICY |
| A4-AUTH-07 | F-TEN/F-WRK؛ Tenant/Installation/Privilege جعلی در Payload صف/Job. | Worker اختیار را از Receipt/Binding معتبر بگیرد؛ Payload اختیار نمی‌دهد. | بدون کار بین Tenantها یا Binding جعلی؛ بدون دسترسی مالی. | O-WRK/O-DB/O-FIN؛ Digest پیام، Binding و State Diff. | NOT RUN |
| A4-IDEM-01 | F-EVT/F-DB؛ Replay ترتیبی همان Event/Payload پس از Commit. | Replay به Outcome اصلی پایدار ارجاع دهد. | دقیقاً یک Receipt و WorkItem؛ اصل تغییرناپذیر. | O-API/O-DB؛ پاسخ‌ها و Cardinality. | NOT RUN |
| A4-IDEM-02 | F-EVT/F-DB؛ N اتصال مستقل با Barrier روی هویت/Fingerprint یکسان. | یک برنده؛ بقیه Duplicate قطعی. | دقیقاً یک Pair؛ بدون Row ناقص. | O-TX/O-DB/O-API؛ Barrier، Trace تراکنش و Cardinality. | BLOCKED — DB ADR |
| A4-IDEM-03 | F-EVT/F-DB؛ همان هویت منبع با Payload/Fingerprint معنایی متفاوت. | Conflict پایدار؛ اصل Overwrite نشود. | Original تغییرناپذیر؛ WorkItem دوم ممنوع. | O-DB/O-TX/O-API؛ Fingerprint و Trace Conflict. | BLOCKED — FINGERPRINT ADR |
| A4-IDEM-04 | F-TEN/F-EVT؛ Event ID یکسان در Source/Installation/Tenantهای مختلف. | طبق Namespace مصوب؛ بدون Collision سراسری یا Dedup بین Tenantها. | بدون ارتباط Row بین Tenantها؛ یکتایی مطابق قرارداد. | O-DB/O-API/O-TX؛ ماتریس Tuple و نتیجه Uniqueness. | BLOCKED — LOT-EVENT-001 |
| A4-IDEM-05 | F-EVT؛ ترتیب کلید/Whitespace JSON را با حفظ محتوای معنایی طبق Profile تغییر بده. | مطابق Fingerprint Profile Pinشده؛ Parse سخت‌گیرانه مقدم است. | یک هویت؛ Fingerprint قطعی؛ Work دوم ممنوع. | O-SCHEMA/O-DB/O-API؛ Digest خام/Canonical و نسخه Profile. | BLOCKED — FINGERPRINT ADR |
| A4-IDEM-06 | F-EVT؛ Member تکراری، UTF-8 خراب، Number خارج Profile و ابهام Parser. | رد پیش از Canonicalization؛ رفتار Last-Key-Wins ممنوع. | Pair پذیرفته‌شده یا Payload نرمال‌شده اتلافی نباشد. | O-SCHEMA/O-API/O-DB؛ بردار بایت، Diagnostic و State Diff. | BLOCKED — PARSER POLICY |
| A4-IDEM-07 | F-EVT؛ Unicode Normalization، Escape و Surrogate Edge. | مطابق Profile Pinشده؛ بدون Unicode Normalization ضمنی. | Fingerprint بین پیاده‌سازی‌ها قطعی؛ بدون Collision پنهان. | O-SCHEMA/O-DB؛ بردار چندزبانه و Profile Digest. | BLOCKED — FINGERPRINT ADR |
| A4-IDEM-08 | F-EVT؛ Request Idempotency Key را با حفظ Event عوض کن و همان Key را برای Event دیگر به‌کار ببر. | Request Key نتواند Dedup Event را دور بزند یا Eventها را ادغام کند. | هویت منبع مرجع؛ بدون Pair تکراری/Merge ناخواسته. | O-API/O-DB/O-TX؛ ماتریس Request-Key/Event-ID. | BLOCKED — API POLICY |
| A4-PARSE-01 | F-EVT/F-NET؛ Source/Type/Extension/Schema ناشناخته. | Fail Closed؛ بدون Remote Schema Lookup. | بدون Pair؛ صفر DNS/Egress و دسترسی مالی. | O-SCHEMA/O-NET/O-DB؛ تصمیم Registry و شمارنده شبکه. | NOT RUN |
| A4-PARSE-02 | F-NET؛ Schema URL از نوع http(s)/file/loopback/link-local/private/redirect/DNS rebinding. | داده بی‌اثر غیرقابل‌اعتماد یا رد؛ هرگز Resolve/Fetch نشود. | بدون Pair؛ صفر تلاش DNS/HTTP/Socket. | O-NET/O-API/O-DB؛ شمارنده DNS/Firewall و بردارها. | NOT RUN |
| A4-PARSE-03 | F-EVT/F-LOAD؛ Nesting عمیق، String/Array بزرگ و Number آسیب‌زا. | رد محدودشده پیش از مصرف نامحدود منابع. | بدون Pair ناقص؛ مصرف در پروفایل مصوب. | O-LOAD/O-SCHEMA/O-DB؛ بردار، Telemetry منابع و State. | BLOCKED — A4-GATE-06 |
| A4-PARSE-04 | F-EVT/F-LOAD؛ Content-Type ناسازگار، Compression Expansion و Encoding پشتیبانی‌نشده. | رد یا Decode محدود طبق Policy؛ سقف Wire و پس از Decompression. | بدون Pair ناقص/Parser Bypass؛ بدون دسترسی مالی. | O-LOAD/O-API/O-DB؛ بایت Encoded/Expanded و پاسخ. | BLOCKED — PARSER/RESOURCE POLICY |
| A4-PARSE-05 | F-EVT؛ Extension تکراری/ناشناخته و تعارض هویت Envelope/Payload. | ابهام رد؛ Payload نتواند Envelope Canonical را بازنویسی کند. | بدون Pair یا تغییر Tenant/Source. | O-SCHEMA/O-API/O-DB؛ مقایسه Envelope و State Diff. | BLOCKED — EVENT CONTRACT |
| A4-PARSE-06 | F-EVT؛ Schema محلی را پس از پذیرش تغییر بده و Replay کن. | منشأ Schema/Version زمان پذیرش تغییرناپذیر بماند. | Digest/Version اصلی حفظ؛ بدون Resolve متغیر یا Work جدید. | O-SCHEMA/O-DB؛ Registry History، Receipt و Replay Trace. | NOT RUN |
| A4-RES-01 | F-LOAD؛ Body دقیقاً در سقف Byte مصوب و یک Byte بیشتر. | مرز قطعی؛ مقدار فقط از Quota مصوب. | بالاتر از حد بدون Pair؛ در مرز حداکثر یک Pair. | O-LOAD/O-API/O-DB؛ Byte Count، Policy Version و State. | BLOCKED — A4-GATE-06 |
| A4-RES-02 | F-LOAD/F-TEN؛ Tenant-A را Burst کن و هم‌زمان بار پایه Tenant-B را اجرا کن. | Fairness/Backpressure طبق Quota مصوب؛ ظرفیت رزرو‌شده مصرف نشود. | بدون Starvation بین Tenantها یا کار تکراری. | O-LOAD/O-DB؛ Latency/Rejection/Queue به تفکیک Tenant. | BLOCKED — A4-GATE-06 |
| A4-RES-03 | F-LOAD/F-DB/F-WRK؛ DB Pool و Worker Slot را با هم‌زمانی ساختگی محدود اشباع کن. | Reject/Queue محدود؛ بدون Connection Leak/Retry Storm/Starvation. | ناورداهای پایدار حفظ؛ بدون Pair تکراری. | O-LOAD/O-TX/O-DB؛ Pool/Queue Telemetry و Connection Census. | BLOCKED — DB/QUEUE ADR + GATE |
| A4-RES-04 | F-IAM/F-LOAD/F-OBS؛ Credential نامعتبر و درخواست Parser خراب را تکرار کن. | Abuse Control کار را محدود؛ خطا جزئیات حساس ندهد. | بدون Pair برای درخواست ردشده؛ بدون Canary Leak. | O-LOAD/O-IAM/O-OBS؛ Rate Counter، پاسخ و Scan. | BLOCKED — A4-GATE-06 |
| A4-RES-05 | F-WRK/F-LOAD؛ شکست Transient تکراری و Poison Event کنار کار Tenant سالم. | Retry Budget/Backoff/Parking طبق Policy؛ Poison سایر Tenantها را مسدود نکند. | بدون Pair تکراری؛ تلاش محدود؛ Tenant دیگر پیشرفت کند. | O-WRK/O-LOAD/O-DB؛ Attempt History، Queue Age و پیشرفت Tenant. | BLOCKED — RETRY POLICY/GATE |
| A4-DUR-01 | F-DB؛ Crash پیش از Transaction، پس از Insert Receipt، پس از Insert WorkItem و پیش از Commit. | ACK فقط پس از Commit قطعی؛ Abort با خطای امن. | پیش از Commit هیچ Row باقی نماند؛ پس از Commit هر دو باشند. | O-TX/O-DB/O-API؛ Fault Point، Trace و Cardinality. | BLOCKED — DB ADR |
| A4-DUR-02 | F-DB؛ Pair را Commit، پاسخ را پیش از مشاهده Client حذف و همان Event را Retry کن. | تطبیق با Outcome اصلی؛ ایجاد کورکورانه ممنوع. | دقیقاً یک Pair؛ Correlation اصلی حفظ. | O-TX/O-DB/O-API؛ مدرک Commit، Drop Marker و Retry Trace. | BLOCKED — DB ADR |
| A4-DUR-03 | F-DB؛ Race کلید یکتا، Deadlock و Serialization Abort در Transactionهای مستقل. | یک برنده؛ Retry فقط در مرز امن کل Transaction. | دقیقاً یک Pair؛ Transaction Abortشده Row ناقص نگذارد. | O-TX/O-DB؛ مدرک Conflict/Deadlock/Serialization موتور. | BLOCKED — DB ADR |
| A4-DUR-04 | F-WRK/F-DB؛ Crash Worker پیش از Claim، پس از Claim، حین کار و پیش از Commit تکمیل. | Recovery از State پایدار؛ بدون Terminal Success کاذب؛ Retry محدود. | Work قابل‌بازیابی یا پس از تکمیل پایدار Terminal؛ بدون اثر تکراری. | O-WRK/O-DB/O-TX؛ Crash Point، State History و Claim Audit. | BLOCKED — DB/WORKER ADR |
| A4-DUR-05 | F-WRK/F-DB؛ W1 در Generation n، انقضای Lease، W2 در n+1، سپس Resume W1 و تلاش تمام Transitionها. | تمام Writeهای W1 قدیمی رد؛ صفر Row تغییر کند. | State/Terminal و Audit Owner متعلق به W2 تغییر نکند. | O-WRK/O-DB/O-TX؛ Timeline نسل و Affected-Row هر Write. | BLOCKED — DB/WORKER ADR |
| A4-DUR-06 | F-WRK/F-DB؛ اعلان Queue تکراری/خارج از ترتیب، حتی پس از Terminal. | Queue فقط Hint؛ DB مرجع Claim/Transition. | یک Pair؛ بدون Regression یا Terminal تکراری. | O-WRK/O-DB؛ توالی اعلان و State History. | BLOCKED — QUEUE/WORKER ADR |
| A4-DUR-07 | F-WRK/F-TEN؛ Job Reference خراب، Tenant/Install ناسازگار، Installation مفقود یا Payload داخلی خراب. | Fail Closed/Park طبق Policy؛ بدون Confused Deputy. | بدون Mutation بین Tenantها، دسترسی مالی یا Receipt جعلی. | O-WRK/O-DB/O-FIN؛ Payload Digest، Binding و State Diff. | BLOCKED — WORKER POLICY |
| A4-DUR-08 | F-DB/F-WRK؛ Snapshot مرز Commit/عدم Commit، Restart/Restore و تطبیق Worker. | Recovery مرز Commit را حفظ؛ کار Commitشده قابل‌بازیابی و Pair Commitنشده غایب. | دقیقاً یک Pair Commitشده؛ بدون Orphan/Duplicate/اثر مالی. | O-TX/O-DB/O-WRK؛ Snapshot Digest، Recovery Log و Reconciliation. | BLOCKED — DB/RESTORE ADR |
| A4-DATA-01 | F-OBS؛ Canary Secret/PII و اجرای Success/Error/Exception/Retry. | Error/Telemetry پاک‌سازی؛ بدون Echo Payload خام. | Canary در Log/Trace/Metric/Evidence نباشد. | O-OBS/O-API؛ Canary Scan و Telemetry Digest. | NOT RUN |
| A4-DATA-02 | F-TEN/F-OBS؛ درخواست ردشده بین Tenantها و بررسی Response/Audit. | بدون افشای وجود Object؛ Audit فقط Actor/Tenant/Correlation لازم. | بدون Read/Write در B؛ بدون Secret/Payload خام در Audit. | O-API/O-DB/O-OBS؛ Response Diff، Audit و Canary Scan. | NOT RUN |
| A4-DATA-03 | F-OBS؛ Principal غیرمجاز برای Read/Export Evidence/Audit تلاش کند. | رد و Audit؛ فقط Role کم‌اختیار مصوب مجاز. | بدون افشا یا Mutation Evidence. | O-API/O-DB/O-OBS؛ تصمیم دسترسی و Audit Trail. | BLOCKED — A4-GATE-05 |
| A4-DATA-04 | F-DATA؛ Retention Expiry، Deletion، Backup، Legal Hold و Restore ساختگی. | مطابق Policy مصوب مالک/حقوقی؛ Policy فعلاً موجود نیست. | حذف/Restore/انقضا قابل‌اثبات؛ بدون مدت حدسی. | O-DATA/O-DB؛ Policy Version، مدرک حذف و Restore Diff. | BLOCKED — POLICY |
| A4-FIN-01 | F-FIN/F-NET؛ مسیر Ingress/Worker و Probe برای DB Grant، Secret، Service Binding، DNS و Route. | هیچ Principal/Credential/Route/Binding/Endpoint مالی قابل‌دسترسی نباشد. | صفر اتصال/Query/Call/Write مالی و Economic Effect. | O-FIN/O-NET/O-DB؛ Permission Inventory، Route Scan و Sentinel. | BLOCKED — A4-GATE-07 |
| A4-FIN-02 | F-FIN؛ اجرای Duplicate/Conflict/Retry/Exception/Replay با Sentinel مالی. | تمام مسیرها خارج از Finance؛ هر تلاش مالی باعث Fail شود. | صفر Mutation در Wallet/Ledger/Payment/Settlement/Payout و اثر اقتصادی. | O-FIN/O-DB/O-NET؛ شمارنده مسیر و Snapshot مالی. | BLOCKED — A4-GATE-07 |
| A4-FIN-03 | F-FIN/F-EVT؛ Commission/Amount/Currency/Beneficiary/Payout جعلی. | داده غیرقابل‌اعتماد؛ بدون Command محاسبه/تأیید/ثبت. | بدون رکورد/اتصال/فراخوانی مالی؛ بدون اختیار مبتنی بر Payload. | O-FIN/O-API/O-DB؛ Trace فیلدها و گزارش Sentinel. | BLOCKED — A4-GATE-07 |

**کنترل شمارش:** IAM برابر ۶ + AUTH برابر ۷ + IDEM برابر ۸ + PARSE برابر ۶ + RES برابر ۵ + DUR برابر ۸ + DATA برابر ۴ + FIN برابر ۳ = **۴۷**. شناسه‌ها از Catalogue مرجع A4 برداشته شده‌اند؛ شماره‌گذاری مجدد ممنوع است.

## ۴. برنامه‌های قطعی هم‌زمانی و بازیابی

این برنامه‌ها انتزاعی‌اند و فقط پس از تصویب A4-GATE-03/04 و ADRهای Persistence/Worker اجرایی می‌شوند.

### S1 — Ingress هم‌زمان با Event تکراری (A4-IDEM-02)
۱. برای هویت E هیچ Receipt/Work وجود نداشته باشد. ۲. N تراکنش/Connection مستقل آغاز و پیش از تصمیم Uniqueness متوقف شوند. ۳. همه از یک Barrier آزاد شوند. ۴. Transactionها Commit یا Conflict موتور را دریافت کنند. ۵. پاسخ هر Caller با هویت معتبر E تطبیق داده شود. ۶. Observer مستقل Persistence و Trace را بررسی کند.

قبولی: دقیقاً یک InboxReceipt و WorkItem مرتبط؛ یک برنده Commit؛ بدون Orphan؛ نتیجه Duplicate/Conflict قطعی برای بازندگان؛ بدون پاسخ پذیرش پیش از Commit. N پارامتر تست مصوب است و این سند آن را تعیین نمی‌کند.

### S2 — نتیجه نامعلوم Commit (A4-DUR-02)
۱. Pair مربوط به E Commit شود. ۲. پاسخ پس از Commit و پیش از مشاهده Client حذف شود. ۳. Client با هویت Event و قرارداد Retry مصوب دوباره تلاش کند. ۴. Ingress پیش از Create وضعیت پایدار را تطبیق دهد. ۵. Observer مستقل Cardinality و Provenance را بررسی کند.

قبولی: Retry به Pair اصلی برسد؛ بدون Retry کور، Pair دوم یا Fingerprint تغییرکرده. Timeout به‌تنهایی اثبات Rollback نیست.

### S3 — Fencing Worker قدیمی (A4-DUR-05)
۱. W1 در Generation=n، J را اتمیک Claim و متوقف کند. ۲. Lease با ساعت قطعی منقضی شود. ۳. W2 در n+1، J را Claim و State را جلو ببرد. ۴. W1 را Resume کن و Heartbeat/Success/Retry/Failure/Audit Owner را با نسل n امتحان کن. ۵. نتیجه هر Write و تاریخچه Row/Audit را مستقل بررسی کن.

قبولی: هر Write تغییردهنده از W1 قدیمی صفر Row را تغییر دهد و نتواند State، Terminal، Owner فعلی یا Audit Ownership معتبر را تغییر دهد. انقضای Lease بدون Generation جدید Fencing نیست.

### S4 — ماتریس Crash جفت اتمیک (A4-DUR-01)
قطع Process/Connection پیش از Transaction، پس از Insert Receipt، پس از Insert WorkItem، پیش از Commit، بلافاصله پس از Commit و پس از Commit اما پیش از ACK تزریق شود. نتیجه واقعی Engine مستقل ثبت شود.

قبولی: پیش از Commit موفق، پس از Recovery هیچ Row دیده نشود؛ پس از Commit هر دو دیده شوند؛ برای Pair Commitنشده ACK صادر نشود. Log برنامه به‌تنهایی Oracle نیست.

### S5 — Race چرخه عمر Tenant (A4-AUTH-06)
پس از پذیرش اتمیک و پیش از مجوز Worker، Barrier ایجاد کن؛ وضعیت Membership/Installation را تغییر بده و Worker را آزاد کن. فقط پس از تصویب Policy چرخه عمر و مرز سازگاری توسط مالک اجرا شود.

قبولی: رفتار دقیقاً با Policy و SLA مصوب منطبق و در تمام Replicaهای Worker یکسان باشد.

## ۵. دفتر بستن یافته‌های A6

ثبت تصمیم در سند به‌معنای تصویب آن نیست؛ مالک پاسخ‌گو و Evidence همچنان لازم‌اند.

| یافته | تصمیم/Artifact لازم | نقش پاسخ‌گو | مدرک بستن | وضعیت فعلی |
|---|---|---|---|---|
| F01 | این Manifest ۴۷ ردیفی، Schema نسخه‌بندی‌شده Test Case، Lint شناسه پایدار و Oracle/Evidence هر Case. | QA، معماری، امنیت | اعتبارسنجی ۴۷/۴۷، فیلدهای لازم، شناسه یکتا، Parity معنایی دوزبانه و حفظ NOT RUN. | ARTIFACT ADDED؛ بازبینی مستقل در انتظار |
| F02 | تصویب Pair الزامی InboxReceipt + WorkItem؛ مالکیت/مرز انتشار DeliveryOutbox اختیاری؛ همسان‌سازی اصطلاحات A4/A5/API. | معماری دامنه، داده/پلتفرم، مالک | Decision Record و بررسی سازگاری اسناد؛ بدون Schema فیزیکی. | PROPOSED |
| F03 | ADR Persistence، برنامه تراکنش، تطبیق Commit نامعلوم و Retry امن. | داده/پلتفرم، معماری، SRE، QA | مستندات Engine کاندید، Race قطعی و برنامه Trace مستقل. | BLOCKED — ADR |
| F04 | ADR Claim/Fencing Worker برای Generation، Lease، Owner و همه Transitionهای مشروط. | معماری، داده/پلتفرم، SRE، QA | اثبات مستقل صفر Row تغییرکرده در تمام Transitionهای Worker قدیمی روی Engine واقعی. | BLOCKED — ADR |
| F05 | تصمیم Namespace در LOT-EVENT-001؛ Parser سخت‌گیرانه؛ Profile/Version Fingerprint و بردار چندزبانه. | دامنه Event، Integration شریک، امنیت، مالک | قرارداد واقعی شریک در صورت دسترسی؛ Policy مصوب؛ بردار قطعی و Conflict Semantics. | BLOCKED — CONTRACT/POLICY |
| F06 | معنای تعلیق Membership/Installation؛ اختیار زمان پذیرش در برابر اجرا؛ SLA لغو و برنده Race. | IAM/دامنه، امنیت، مالک محصول | جدول Transition صریح، مرز سازگاری، SLA و Audit. | BLOCKED — OWNER POLICY |
| F07 | ماتریس عدم دسترسی مالی در Grant، Credential/Secret، Service Graph، Network/DNS، اختیار Queue و Telemetry. | مالی، امنیت، پلتفرم/SRE، معماری | Probe منفی مستقل؛ صفر مسیر/تلاش Mutation؛ Attestation ثبت‌شده. | BLOCKED — A4-GATE-07 |
| F08 | پروفایل بار، توزیع Tenant، هدف Fairness، Limit، Retry Budget، اشباع/بازیابی و Stop Threshold. | SRE، امنیت، محصول، مالک | پروفایل عددی مصوب، Metric و برنامه تکرارپذیر بار/توقف. | BLOCKED — A4-GATE-06 |
| F09 | استقلال Oracle هر Case، Provenance شواهد، Policy صحت/دسترسی/انقضای Artifact. | QA، امنیت، SRE، حریم خصوصی/حقوقی | منبع/مرز اعتماد Oracle در هر ردیف؛ اعتبارسنجی زنجیره Evidence و Tamper Detection. | PARTIAL — MATRIX IN MANIFEST; POLICY OPEN |
| F10 | طبقه‌بندی داده، Retention/Deletion، Backup، Legal Hold، Restore و Evidence Expiry. | حریم خصوصی/حقوقی، امنیت، عملیات، مالک | Policy چرخه عمر مصوب و برنامه پذیرش Synthetic حذف/بازیابی. | BLOCKED — A4-GATE-05 |

### چک‌لیست پذیرش F01
- دقیقاً ۴۷ شناسه Canonical یکتا؛ بدون شناسه مفقود، اضافه یا شماره‌گذاری مجدد.
- هر ردیف Fixture، Stimulus، نتیجه پروتکل، نتیجه مجوزدهی، Assertion پایدار، عدم اثر مالی، Oracle مستقل، Evidence و Status داشته باشد.
- Case وابسته به Policy مانع دقیق را نشان دهد؛ مقدار حدسی ممنوع.
- واژگان Status فقط: NOT RUN، BLOCKED — reason، PASS، FAIL، INCONCLUSIVE. فقط Run مجاز با Evidence حفظ‌شده می‌تواند PASS/FAIL شود.
- نسخه Manifest و Commit منبع در Run Manifest آینده Pin شود.
- Lint در CI برای شناسه تکراری/ناشناخته، فیلد ناقص یا ارتقای تصادفی Status Fail شود.

## ۶. قرارداد اندازه‌گیری حاکمیت منابع

در بررسی A4-GATE-06 باید سقف Wire و Decompression؛ حد عمق/Array/String/Numeric Parser؛ Admission در سطح Installation/Tenant؛ ظرفیت رزروشده کل؛ بودجه DB Connection و Worker؛ Queue Age/Depth؛ Retry Budget/Backoff/Jitter؛ Poison Handling؛ هدف Fairness؛ مدت و ترکیب Tenant تست؛ رفتار Warm/Cold؛ معیار اشباع/بازیابی و Stop Threshold تصویب شوند.

حداقل Throughput پذیرفته/ردشده، Latency در p50/p95/p99، CPU/Memory، هزینه Parser، اشغال/انتظار DB Pool، Lock/Conflict، Queue Depth/Age، Attempt به‌ازای Event، سهم سرویس Tenant، مدت Starvation و زمان Recovery اندازه‌گیری شود. مقدارها باید از SLO/Workload مصوب بیایند، نه حدس این سند.

## ۷. ماتریس تضمین عدم دسترسی مالی

| مسیر | اثبات منفی لازم | Evidence مستقل |
|---|---|---|
| Credential/Role دیتابیس | هیچ Credential یا Grant/Schema Visibility/Write Privilege به مخزن مالی نباشد. | Secret Inventory و بررسی مستقل DB Role/Grant. |
| توزیع Secret/Config | Secret مربوط به Wallet/Ledger/Payment/Payout Mount/Inject/قابل‌بازیابی نباشد. | Workload Identity/Config/Secret Mount Inventory و رد بازیابی Canary. |
| Dependency سرویس | Client/SDK/Binding/Command Path مستقیم یا غیرمستقیم مالی نباشد. | Dependency Graph/Runtime Binding و Sentinel تلاش. |
| Network/DNS | Route، Egress Exception یا Endpoint مالی قابل Resolve نباشد. | Network Policy، DNS Telemetry، Connection Probe و Deny Counter. |
| اختیار Queue/Message | Payload صف نتواند Mutation مالی یا اختیار Tenant بسازد. | Payload Schema/Consumer Map، تست Command جعلی و Worker Audit. |
| زیرساخت مشترک | Credential مشترک ممتاز یا Sidecar پل مالی نسازد. | Process/Container Identity، Sidecar، Service Mesh و Workload Policy. |
| Observability/Evidence | Secret مالی یا داده مالی مشتری از Log/Trace/Artifact نشت نکند. | Secret Canary Scan و Evidence Allowlist Audit. |

هر Probe منفی ناموفق، Endpoint مالی قابل‌دسترسی یا تلاش Mutation مالی، FAIL و STOP قطعی است. صرف مشاهده‌نشدن ترافیک اثبات نبود مسیر نیست.

## ۸. استانداردها و مراجع مهندسی

از Requirement پایدار و نسخه Pin‌شده استفاده شود؛ محتوای Bleeding Edge بی‌صدا دنبال نشود:
- OWASP ASVS نسخه **5.0.0 پایدار** به‌عنوان کاتالوگ راستی‌آزمایی امنیت Application. Security باید کنترل دقیق را با شناسه نسخه‌دار مانند v5.0.0-... نگاشت کند؛ این Manifest ادعای انطباق ASVS نیست.
- OWASP API Security Top 10 (2023) به‌عنوان طبقه‌بندی تهدید، نه گواهی.
- RFC 8785 به‌عنوان کاندید Canonicalization JSON؛ Parser سخت‌گیرانه، رد Member تکراری و Policy عددی/Unicode جداگانه تعیین شوند.
- CloudEvents 1.0.2 به‌عنوان معنای Envelope، نه قرارداد شریک یا تصمیم اعتماد.
- مستندات PostgreSQL درباره Isolation، Locking و INSERT/ON CONFLICT فقط در صورت انتخاب PostgreSQL؛ رفتار با نسخه انتخاب‌شده تطبیق داده شود.
- AWS Transactional Outbox مرجع الگو است، نه الزام AWS یا Queue.
- راهنمای Google SRE درباره Overload/Retry مرجع طراحی عملیات است؛ بودجه عددی به SLO و تصویب مالک نیاز دارد.
- NIST SP 800-204D مرجع DevSecOps و امنیت زنجیره تأمین نرم‌افزار برای Provenance و Pipeline Assurance است.

مراجع رسمی:
- https://asvs.owasp.org/
- https://github.com/OWASP/ASVS/releases
- https://owasp.org/API-Security/
- https://www.rfc-editor.org/rfc/rfc8785
- https://cloudevents.io/
- https://www.postgresql.org/docs/current/transaction-iso.html
- https://www.postgresql.org/docs/current/explicit-locking.html
- https://www.postgresql.org/docs/current/sql-insert.html
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- https://sre.google/sre-book/handling-overload/
- https://csrc.nist.gov/pubs/sp/800/204/d/final

## ۹. وضعیت Gate و انتشار

G09-A7 Manifest طراحی در سطح هر Case و مسیر پیشنهادی بستن تصمیم‌ها را فراهم می‌کند. ثبت F02 تا F10 در سند به‌معنای بسته‌شدن تصمیم‌های مالک/امنیت/معماری نیست. F01 آماده بازبینی مستقل است، نه پذیرش مستقل نهایی.

همچنان مسدود: تمام پیاده‌سازی/اجرای Runtime از جمله ساخت DB/Queue دورریختنی؛ Policy نهایی هویت Event/Parser/Fingerprint/چرخه عمر/Retention/منابع؛ انتخاب DB/Queue/IAM/KMS/HSM/فروشنده بدون ADR؛ Partner Adapter/Credential واقعی/Sandbox خارجی/Commission/ثبت مالی؛ Merge/Deploy/ادعای آمادگی Production.

پیش از پیشنهاد اثبات Runtime، هر هشت Gate A4 باید صریحاً توسط مالک پاسخ‌گو تصویب شوند، یافته‌های مرتبط A6 بسته شوند، ADR فناوری پذیرفته و Reviewerهای QA/Security/Finance/SRE تعیین شوند. تصویب باید ثبت شود و از CI قابل استنباط نیست.

## ۱۰. محدودیت‌ها

این Artifact طراحی تست مستقل از فناوری است که از Catalogue مرجع A4 و یافته‌های A5/A6 استخراج شده است. اجرا نشده و رفتار هیچ DB، Queue، IAM، Network Policy، Worker یا مرز مالی را اثبات نمی‌کند. CI سبز مستندات فقط کنترل‌های پیکربندی‌شده مستندات/قرارداد را روی Commit دقیق اعتبارسنجی می‌کند.


## ۱۱. توسعه زیرسناریوهای خصمانه G09-A8/A9 — صرفاً طراحی

چهارده زیرسناریوی زیر، Caseهای پایدار A4 را توسعه می‌دهند؛ بدون تغییر تعداد یا شناسه‌های Canonical چهل‌وهفت‌گانه. این موارد افزوده‌های پیشنهادی برای ردیابی هستند، نه تست اجراشده. همه NOT RUN هستند و موارد وابسته به Policy/ADR علاوه بر آن مسدودند.

| شناسه Subcase | شناسه والد A4 | چالش قطعی | Assertion لازم | Oracle/Evidence مستقل | وضعیت |
|---|---|---|---|---|---|
| A8-DUR-05a | A4-DUR-05 | Lease منقضی می‌شود؛ Worker قدیمی پیش از افزایش Generation توسط Claimant جدید انتقال Guardشده را امتحان می‌کند. | Lease منقضی در نقطه Linearization Guard را رد کند؛ صفر تغییر در Row محافظت‌شده. | O-DB/O-TX/O-WRK؛ زمان مرجع، ترتیب Transaction و تعداد Row تغییرکرده. | BLOCKED — ADR-001 / SEMANTICS زمان و Lock پایگاه داده |
| A8-DUR-05b | A4-DUR-05 | Heartbeat با انقضا و Reclaim توسط Worker دوم رقابت می‌کند. | یک برنده سریال‌شده؛ Heartbeat نتواند Lease منقضی را احیا کند؛ Generation فقط برای Reclaim موفق افزایش یابد. | O-DB/O-TX/O-WRK؛ Barrier، Timeline نسل و مقادیر Lease. | BLOCKED — ADR-001 / SEMANTICS زمان و Lock پایگاه داده |
| A8-DUR-05c | A4-DUR-05 | Worker قدیمی پس از افزایش Generation و Restart فرایند، Completion را امتحان می‌کند. | Owner/Token/Generation قدیمی صفر Row محافظت‌شده را تغییر دهد؛ Regression وضعیت رخ ندهد. | O-DB/O-TX/O-WRK؛ تاریخچه Durable Row، تلاش Token قدیمی و تعداد Row تغییرکرده. | BLOCKED — ADR-001 / پروتکل Worker |
| A8-DUR-08a | A4-DUR-08 | داده پایدار Restore شود درحالی‌که ممکن است Worker/Process قدیمی هنوز زنده باشد. | Claimها تا Fence شدن Worker/Identity قدیمی و برقراری Recovery Incarnation غیرقابل استفاده مجدد متوقف بمانند. | O-WRK/O-IAM/O-DB/O-OBS؛ Attestation بازیابی، لغو Identity، Incarnation و شواهد رد Token قدیمی. | BLOCKED — ADR بازیابی/Restore |
| A8-AUTH-06a | A4-AUTH-06 | Suspension/Revocation بین Lifecycle Read و Worker Transition Commit شود. | Policy خطی‌شدن چرخه عمر که مالک تصویب کرده، به‌صورت اتمیک یا با Serialization مبتنی بر Version اجرا شود. | O-DB/O-TX/O-WRK/O-IAM؛ Lifecycle Version، Timeline سد هم‌زمانی و State Diff. | BLOCKED — Policy چرخه عمر مالک |
| A8-DUR-02a | A4-DUR-02 | نتیجه Commit نامعلوم است، Primary در دسترس نیست و Replica ممکن است قدیمی باشد. | عدم وجود یا پذیرش کاذب اعلام نشود؛ تا امکان Reconciliation معتبر، نتیجه Indeterminate باشد. | O-DB/O-TX/O-API؛ شواهد Consistency Primary/Replica، نتیجه Retry و Cardinality. | BLOCKED — ADR Persistence/Reconciliation |
| A8-FIN-01a | A4-FIN-01 | Capability مالی غیرمستقیم از Service Discovery، Workload Identity، Secret Mount یا Metadata Route امتحان شود. | در Enforcement Pointهای مستقل و قابل مشاهده رد شود؛ بدون Credential، اتصال، فراخوانی یا اثر مالی. | O-FIN/O-NET/O-OBS/O-DB؛ Inventory قابلیت، Probe ردشده و Secret Canary Scan. | BLOCKED — A4-GATE-07 / Attestation امنیت و مالی |
| A8-DATA-04a | A4-DATA-04 | حذف/انقضای Evidence با Backup/Restore و وضعیت Legal Hold رقابت کند. | نتیجه مطابق Policy مصوب چرخه عمر داده و به‌صورت مستقل در Primary، Backup و Evidence Store اثبات شود. | O-DATA/O-DB/O-OBS؛ نسخه Policy، شواهد حذف/بازیابی و Audit دسترسی. | BLOCKED — A4-GATE-05 / Policy چرخه عمر داده |

### ارجاع پروتکل زمانی

سند پیشنهادی LOT-AFFILIATE-G09-ADR-001، Claim Generation پایدار مختص WorkItem، Owner/Token احراز‌شده، انتقال Guardشده با مرجع Persistence، قاعده Linearization انقضای Lease و Recovery Fence را تعریف می‌کند. این ADR همچنان PROPOSED است و به تصویب مالک، بازبینی مستقل و تعیین Semantics پایگاه داده کاندید نیاز دارد. این سند Database انتخاب نمی‌کند و مجوز اجرای Runtime نیست.

Subcaseها به Case والد متصل‌اند و به تعداد Canonical چهل‌وهفت‌گانه اضافه نمی‌شوند. Runner آتی باید نتیجه والد و هر Subcase را جداگانه گزارش کند تا PASS والد، شکست یک Interleaving را پنهان نکند.
