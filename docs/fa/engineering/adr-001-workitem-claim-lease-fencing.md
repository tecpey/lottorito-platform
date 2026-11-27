# ADR-001 — پروتکل Claim، Lease و Fencing برای WorkItem پایدار

**شناسه سند:** LOT-AFFILIATE-G09-ADR-001  
**شناسه تصمیم:** LOT-AFFILIATE-G09-ADR-001  
**یافته‌های مرتبط:** A7-F01؛ A8-F01، A8-F04، A8-F06، A8-F10  
**وضعیت:** پیشنهادی — نیازمند تصویب مالک و بازبینی مستقل  
**نسخه:** 0.1.0  
**تاریخ:** ۲۰۲۶-۱۱-۲۸  
**دامنه:** فقط چرخه عمر WorkItem در Ingress مصنوعی Affiliate؛ بدون اثر جانبی خارجی یا اثر مالی.

## ۱. زمینه و مسئله

ممکن است Worker متوقف شود، اتصال خود را از دست بدهد، از Lease عبور کند یا پس از آنکه Worker دیگری همان WorkItem را به‌درستی بازپس گرفته است، همچنان اجرا شود. انقضای Lease به‌تنهایی یک Process متوقف‌شده را باطل نمی‌کند. تصور محلی Worker درباره مالکیت Lease نیز مرجع معتبر نیست.

پروتکل باید مانع تغییر وضعیت پایدار WorkItem توسط Worker قدیمی پس از معتبر شدن Claim جدید شود. همچنین باید رقابت انقضای Lease با انتقال وضعیت را دقیق تعریف کند و ادعا نکند که Token می‌تواند سامانه خارجی‌ای را که آن را اعتبارسنجی نمی‌کند، Fence کند.

این ADR یک پیشنهاد تصمیم مستقل از فناوری است. هیچ Database، Queue، Lock Service، IAM Provider، Schema، مدت Lease، Timeout، تعداد Retry یا توپولوژی استقرار انتخاب نمی‌کند.

## ۲. تصمیم پیشنهادی

پذیرش **Claim Generation پایدار و مختص هر WorkItem همراه با انتقال‌های شرطی و متکی بر زمان مرجع Persistence** پیشنهاد می‌شود؛ مشروط به تصویب مالک و بازبین مستقل درباره تصمیم‌های باز بخش ۱۱.

رکورد پایدار WorkItem مرجع وضعیت Claim است. پیام Queue فقط یک Wake-up Hint است و هرگز مالکیت ایجاد نمی‌کند.

## ۳. اصطلاحات و هویت

- **WorkItem Identity:** شناسه تغییرناپذیر متصل به یک Tenant و Installation در تمام طول عمر خود.
- **Claim Generation:** عدد صحیحی که فقط برای یک WorkItem تغییرناپذیر، اکیداً افزایشی است.
- **Claim Token:** Token غیرشفاف متصل به WorkItem Identity، Tenant/Installation، Generation و Owner؛ به‌تنهایی Credential قابل استفاده نیست.
- **Claim Owner:** هویت Principal احراز‌شده Worker، نه رشته‌ای که Caller ارسال کند.
- **Lease Expiry:** Timestamp مرجع Persistence که پس از آن Claim جدید می‌تواند برای Reclaim اقدام کند.
- **Linearization Point:** Mutation پایدار و Guardشده‌ای که Claim یا انتقال وضعیت را در برابر Claimهای رقیب سریال می‌کند.
- **Worker قدیمی:** Processی که Owner/Generation/Token آن دیگر با مرجع پایدار WorkItem تطبیق ندارد یا Lease آن در نقطه Linearization انتقال معتبر نبوده است.

هویت Event منبع، Idempotency Key درخواست HTTP و Economic-effect Identity مستقل باقی می‌مانند. این ADR آن‌ها را بازتعریف نمی‌کند.

## ۴. State و Invariantهای پیشنهادی

مدل منطقی WorkItem حداقل شامل موارد زیر است:
- شناسه تغییرناپذیر WorkItem، Tenant و Installation؛
- Lifecycle State؛
- Claim Generation؛
- هویت Claim Owner؛
- مرجع/مقدار Claim Token؛
- Lease Expiry؛
- Metadata تلاش لازم برای Policy مصوب Retry؛
- Metadata نسخه/Audit برای بازسازی انتقال‌ها.

این‌ها فیلدهای منطقی‌اند، نه Schema فیزیکی مصوب.

Invariantهای الزامی:

۱. هویت WorkItem هرگز به Tenant، Installation یا Job منطقی دیگری تخصیص داده نمی‌شود.  
۲. هر Claim جدید موفق دقیقاً یک‌بار Generation را افزایش می‌دهد.  
۳. Generation برای همان WorkItem هرگز کاهش، Wrap، Reset یا Reuse نمی‌شود.  
۴. Owner و Token به‌صورت اتمیک همراه Generation و Lease تغییر می‌کنند.  
۵. هر Heartbeat، Completion، Retry Scheduling، Parking یا Cancellation مشروط به State مورد انتظار، Binding تغییرناپذیر Identity، Owner، Generation/Token و Lifecycle Version مربوط است.  
۶. شکست Guard باید صفر ردیف WorkItem محافظت‌شده را تغییر دهد.  
۷. Delivery، ترتیب یا Acknowledgement صف مالکیت یا Completion پایدار را تعیین نمی‌کند.  
۸. هیچ انتقال Worker در این دامنه مجاز به فراخوانی یا Mutation در Wallet، Ledger، Payment، Settlement، Payout، Commission یا سرویس Economic Effect نیست.  
۹. در Transaction کوتاه انتقال پایدار، Network I/O یا اثر جانبی خارجی انجام نمی‌شود.  
۱۰. نتیجه نامعلوم Transaction از وضعیت پایدار مرجع Reconcile می‌شود و هرگز به‌صورت خودکار Rollback فرض نمی‌شود.

## ۵. پروتکل Claim

Claimant یک Wake-up Hint از Queue دریافت می‌کند یا از طریق Scheduler مصوب کار واجد شرایط را کشف می‌کند. سپس با هویت Principal مربوط به Worker احراز هویت می‌شود و از Persistence مرجع درخواست Claim یک WorkItem مشخص را می‌کند.

عملیات Claim باید یک Transaction پایدار و سریال‌شده باشد:
۱. WorkItem Identity تغییرناپذیر و Binding مربوط به Tenant/Installation از داده پایدار مورد اعتماد resolve شود.  
۲. سازوکار سریال‌سازی همان WorkItem اخذ شود (برای مثال Row-level Lock یا Atomic Compare-and-set معادل؛ هیچ Database انتخاب نشده است).  
۳. Eligibility بر اساس زمان مرجع Persistence و State پایدار ارزیابی شود.  
۴. اگر State برابر READY است، یا طبق Policy چرخه عمر مصوب CLAIMED با Lease منقضی‌شده است، Generation دقیقاً یک‌بار افزایش یابد.  
۵. Owner احراز‌شده، Claim Token جدید، Lease Expiry و State=CLAIMED در همان Transaction تنظیم شوند.  
۶. پیش از اعلام مالکیت به Worker، Commit انجام شود.

اگر Claimant دیگری برنده شود، Claimant بازنده Token دریافت نمی‌کند و نباید کاری انجام دهد. پیام‌های تکراری یا خارج از ترتیب Queue فقط باعث بررسی مجدد Eligibility می‌شوند.

تمدید Lease، Claim جدید نیست و Generation را افزایش نمی‌دهد. Reclaim، Claim جدید است و باید Generation را افزایش دهد.

## ۶. پروتکل انتقال محافظت‌شده و رقابت انقضای Lease

هر انتقال محافظت‌شده (Heartbeat، Completion، زمان‌بندی Retry، Parking و Cancellation در صورت مجاز بودن Worker) باید Transaction کوتاهی باشد که با تمام Predicateهای مرتبط Guard شده است:
- WorkItem ID دقیق و Binding تغییرناپذیر Tenant/Installation؛
- State فعلی مورد انتظار؛
- Owner احراز‌شده؛
- Claim Generation جاری؛
- Claim Token جاری؛
- معتبر بودن Lease در نقطه Linearization انتقال؛
- شرط Lifecycle/Version مورد انتظار در صورت الزام Policy مصوب.

Guard و Mutation باید در برابر Reclaim رقیب سریال شوند. Conditional Update یا Lock-and-check فقط زمانی پذیرفتنی است که Semantics مربوط به Isolation/Locking آن مستند و آزموده شود.

**قاعده پیشنهادی رقابت انقضای Lease:** انقضا، WorkItem را واجد شرایط Reclaim می‌کند؛ اما Process را به‌صورت ناهمگام متوقف نمی‌کند. نخستین انتقال پایدار سریال‌شده برنده است:
- اگر Worker قدیمی درحالی‌که Lease هنوز معتبر است به نقطه Serialization برسد و Mutation Guardشده موفق شود، انتقال آن پیش از Reclaim بعدی مرتب می‌شود. Lock/Serialization باید مانع اعطای Generation جدید به‌صورت هم‌زمان شود. Transaction باید کوتاه و فاقد Network I/O خارجی باشد.
- اگر هنگام رسیدن Worker قدیمی به انتقال Guardشده، Lease منقضی شده باشد، Guard شکست می‌خورد و صفر ردیف محافظت‌شده تغییر می‌کند.
- اگر Claimant جدید قبلاً Generation را افزایش داده باشد، تمام انتقال‌های Generation قدیمی بدون توجه به ساعت یا تصور محلی Worker رد می‌شوند.
- اگر Database به دلیل Failover، ناپیوستگی Clock یا وضعیت بازیابی نامعلوم نتواند ترتیب/زمان قابل اتکا تعیین کند، Claimها و انتقال‌های محافظت‌شده تا احراز Recovery Fence بخش ۹ Fail Closed می‌شوند.

این قاعده یک نقطه Linearization واحد تعریف می‌کند و به ساعت محلی Worker یا توالی مبهم «بررسی سپس اقدام» تکیه نمی‌کند.

Heartbeat پس از انقضای Lease رد می‌شود. Worker نمی‌تواند Lease منقضی‌شده را احیا کند. Worker باید پیش از انقضا تمدید کند. Completion پس از انقضا رد می‌شود، مگر اینکه پیش از انقضا و طبق قاعده فوق با موفقیت Linearize شده باشد.

## ۷. ماتریس انتقال State

| عملیات | پیش‌شرط لازم | اثر بر Generation | رفتار هنگام شکست |
|---|---|---|---|
| Claim اولیه | READY و واجد شرایط | یک‌بار افزایش | مالکیتی اعطا نمی‌شود |
| Reclaim | CLAIMED و Lease منقضی طبق Policy مصوب | یک‌بار افزایش | مرجع موجود تا تعیین برنده سریال‌شده باقی می‌ماند |
| Heartbeat | CLAIMED؛ تطابق Owner/Token/Generation؛ Lease معتبر در Linearization | بدون افزایش | صفر تغییر؛ Lease منقضی احیا نمی‌شود |
| Complete | CLAIMED؛ تطابق Owner/Token/Generation؛ Lease معتبر در Linearization | بدون افزایش | صفر تغییر؛ Completion قدیمی رد می‌شود |
| زمان‌بندی Retry | CLAIMED؛ تطابق Owner/Token/Generation؛ Lease معتبر در Linearization | بدون افزایش | صفر تغییر |
| Park | CLAIMED؛ تطابق Owner/Token/Generation؛ Lease معتبر یا مسیر اپراتوری جداگانه مجاز | بدون افزایش | صفر تغییر |
| Cancel/Revoke | Policy صریح چرخه عمر/مالک؛ Version-conditioned | طبق Policy؛ Token بی‌صدا Reuse نمی‌شود | Conflict یا Park؛ بدون Overwrite کور |

Retry که WorkItem را به READY برمی‌گرداند Generation را Reset نمی‌کند. Claim بعدی از آخرین Generation پایدار افزایش می‌یابد.

## ۸. مدت Transaction، کار خارجی و Retry

- آماده‌سازی CPU-bound می‌تواند خارج از Transaction انتقال محافظت‌شده انجام شود.
- Network I/O، فراخوانی Partner، ایمیل، Webhook Publication، فراخوانی مالی و محاسبات بدون حد، داخل Transaction مربوط به Claim/Finalization ممنوع‌اند.
- Transaction اعتبارسنجی و Mutation WorkItem باید تحت Policy عملیاتی مصوب مالک محدود و کوتاه باشد. در این ADR عدد Timeout تعیین نمی‌شود.
- اگر Abort تراکنش قطعی باشد، Worker می‌تواند State را دوباره بخواند و State Machine مصوب را دنبال کند.
- اگر نتیجه Commit نامعلوم باشد، Worker باید از Store مرجع Primary/دارای تضمین Consistency با WorkItem ID + Generation + Owner/Token و State مورد انتظار Reconcile کند. تکرار کور انتقال غیر Idempotent ممنوع است.
- طبقه‌بندی Retry، Backoff، Jitter، Retry Budget و Parking نهایی به Policy/ADR جداگانه نیاز دارند. Retry نباید Overload را تشدید کند.

## ۹. چرخه عمر Generation، Restore و Disaster Recovery

Generation باید نمایش/دامنه‌ای با حداکثر مشخص و رفتار Fail-closed هنگام اتمام ظرفیت داشته باشد. Wraparound، Reset، Reuse، انتقال Tenant یا بازیافت WorkItem ID ممنوع است.

Database Restore یا Point-in-time Recovery می‌تواند Generation پایدار را به عقب برگرداند، درحالی‌که Processهای قدیمی هنوز فعال‌اند. Counterی که فقط در Database بازیابی‌شده نگهداری می‌شود به‌تنهایی اثبات نمی‌کند Tokenهای قدیمی باطل شده‌اند.

**Recovery Fence پیشنهادی:**
۱. پیش از Restore/Failoverی که ممکن است Claim State را عقب ببرد، Ingress و پذیرش Worker متوقف شوند.  
۲. ثابت شود تمام Processها و Credentialهای قدیمی Worker خاتمه/لغو شده‌اند یا از دسترسی به مرجع بازیابی‌شده ایزوله‌اند.  
۳. Recovery Incarnation/Epoch جدید با سازوکاری مستقل و خارج از داده WorkItem بازیابی‌شده برقرار شود.  
۴. Claim/Tokenهای جدید به آن Incarnation متصل شوند.  
۵. رد شدن Identity/Token قدیمی و سلامت Clock/Consistency بررسی شود.  
۶. فقط پس از Attestation مالک پاسخ‌گو، Claim دوباره فعال شود.

اگر پلتفرم نتواند Incarnation غیرقابل استفاده مجدد ایجاد کند یا Fence شدن Workerهای قدیمی را اثبات کند، سامانه متوقف می‌ماند. سازوکار و مالک Incarnation هنوز تعیین نشده و Provider انتخاب نشده است.

## ۱۰. چرخه عمر Tenant و Installation

Guard مربوط به Claim/Transition باید Binding تغییرناپذیر Tenant و Installation را شامل شود. مالک باید جداگانه تصمیم بگیرد آیا Receipt پذیرفته‌شده قبلی پس از Suspension/Revocation نصب همچنان قابل پردازش است یا خیر.

برای هر Policy که وضعیت جاری چرخه عمر را مقدم می‌داند، انتقال محافظت‌شده باید State/Version مرجع Lifecycle را اتمیک اعتبارسنجی کند یا در برابر تغییر آن سریال شود. الگوی جداگانه و محافظت‌نشده «خواندن وضعیت، سپس تغییر WorkItem» کافی نیست.

انتقال Tenant یا تخصیص مجدد Installation برای WorkItem موجود ممنوع است. Migration/Replay به Installation دیگر نیازمند Identity جدید، مجاز و Audit‌شده است.

## ۱۱. گزینه‌ها و تصمیم‌های باز مالک

| گزینه | مزیت | ریسک / دلیل انتخاب‌نشدن |
|---|---|---|
| فقط انقضای Lease | بازیابی ساده Claim رهاشده | Worker قدیمی متوقف‌شده را مهار نمی‌کند؛ به‌عنوان حفاظت کافی رد می‌شود |
| بررسی ساعت محلی Worker | پیاده‌سازی ساده | Clock Skew/Pause و Race بررسی-سپس-اقدام؛ به‌عنوان مرجع رد می‌شود |
| Visibility Timeout/Ack صف به‌عنوان مالکیت | جریان ساده مبتنی بر Queue | Queue مرجع پایدار کسب‌وکار نیست؛ Duplicate/Out-of-order و Ack loss باقی می‌مانند |
| Generation پایدار + Mutation شرطی Persistence | Generation قدیمی در مرجع معتبر رد می‌شود | به تعریف دقیق Serialization، Clock/Failover و Restore نیاز دارد؛ پیشنهاد می‌شود |
| Fencing Token خارجی که هر Resource پایین‌دستی بررسی کند | می‌تواند اثرهای فراتر از WorkItem را Fence کند | Capability پایین‌دستی در این دامنه وجود ندارد؛ طراحی آینده باید پذیرش Token توسط دریافت‌کننده را جداگانه اثبات کند |

تصمیم‌های لازم از مالک پیش از تصویب:
- مرجع زمان و Policy مربوط به Failover/Clock Discontinuity؛
- Semantics دقیق Serialization/Transaction Isolation پس از انتخاب Candidate پایگاه داده؛
- نمایش Claim Generation و رفتار اتمام ظرفیت؛
- مرجع Recovery Incarnation و مالک عملیاتی آن؛
- رفتار Suspension/Revocation نصب برای Receiptهای پذیرفته‌شده قبلی؛
- Policy محدودیت مدت Transaction و اجرای Worker؛
- مالک پاسخ‌گو، بازبین مستقل و مرجع پذیرش.

هیچ مقدار یا Providerی فرض نشده است.

## ۱۲. معیارهای پذیرش — طراحی و اثبات آتی

این ADR فقط در صورت تحقق موارد زیر قابل تصویب است:
۱. مالک پاسخ‌گو تمام تصمیم‌های بخش ۱۱ را تصویب کند یا تعویق موجهی ثبت کند که Invariantها را تضعیف نکند.  
۲. بازبینان مستقل معماری/امنیت/QA پروتکل زمانی و Test Schedule را تأیید کنند.  
۳. A7 زیرسناریوهای انقضا پیش از Reclaim، رقابت Heartbeat/Reclaim، Completion قدیمی پس از تغییر Generation، Restart، Restore همراه Worker قدیمی و رقابت Revocation/Commit را صریحاً شامل شود.  
۴. Semantics مربوط به Locking، Isolation، زمان و Failover در Candidate انتخاب‌شده مستند شود.  
۵. Oracle مستقل از کد Worker، Generation، Owner، State و صفر بودن Writeهای قدیمی را بررسی کند.  
۶. Commit Ambiguity و Reconciliation نتیجه قطعی و تکرارپذیر داشته باشند.  
۷. رویه Restore ثابت کند Worker/Identity قدیمی نمی‌تواند State بازیابی‌شده را تغییر دهد.  
۸. در برش تست هیچ Capability اثر جانبی خارجی یا مالی وجود نداشته باشد.  
۹. Evidence شامل Provenance، منبع Clock، Timeline تراکنش/Claim و Assertionهای منفی باشد.  
۱۰. پیش از آغاز هر Proof Runtime، هر هشت Gate در A4 تصویب شوند.

این‌ها معیارهای پذیرش آتی‌اند. هیچ تستی اجرا نشده و این ADR مجوز Runtime نیست.

## ۱۳. پیامدها

مزایا:
- مرجع Authority و نقطه Serialization را روشن می‌کند.
- Eligibility ناشی از Lease را از Fencing مالک قدیمی جدا می‌کند.
- مانع تبدیل ساعت محلی Worker و Queue Ack به مرجع اختیار می‌شود.
- Restore/Rollback را به‌عنوان مسئله مستقل Fencing آشکار می‌کند و فرض نمی‌کند Counter به‌تنهایی کافی است.

هزینه‌ها و محدودیت‌ها:
- به انتقال‌های پایدار و مرز Transaction دقیق نیاز دارد.
- عملیات Clock/Failover و Recovery Incarnation پیچیدگی عملیاتی اضافه می‌کنند.
- این پروتکل فقط مرز Persistence مربوط به WorkItem را محافظت می‌کند و اثر جانبی خارجی را Fence نمی‌کند.
- صحت نهایی همچنان به Semantics مستند و آزموده‌شده Persistence Engine انتخابی وابسته است.

## ۱۴. منابع

- Martin Kleppmann، «How to do distributed locking» — Fencing Token و ضرورت رد Token قدیمی توسط Resource محافظت‌شده: https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html
- مستندات PostgreSQL، Explicit Locking — صرفاً مرجع مفهومی Serialization با Row Lock؛ PostgreSQL انتخاب نشده است: https://www.postgresql.org/docs/current/explicit-locking.html
- مستندات PostgreSQL، Transaction Isolation — صرفاً مرجع Serialization و Retry؛ PostgreSQL انتخاب نشده است: https://www.postgresql.org/docs/current/transaction-iso.html
- تضمین‌های API در etcd — Lease Expiry، Revision و نتیجه نامعلوم عملیات به‌عنوان مفاهیم سیستم هماهنگ‌کننده؛ etcd انتخاب نشده است: https://etcd.io/docs/v3.4/learning/api_guarantees/
- AWS Builders’ Library، «Timeouts, retries, and backoff with jitter» — تشدید بار ناشی از Retry، Idempotency و Backoff: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/

منابع، پیشنهاد را پشتیبانی می‌کنند؛ انطباق محصول یا تصویب فناوری را اثبات نمی‌کنند.

### قید نمونه‌برداری زمان

مقایسه انقضای Lease باید **پس از اخذ نقطه Serialization مربوط به WorkItem** انجام شود، نه بر اساس Timestampی که پیش از انتظار احتمالی برای Lock گرفته شده است. Timestamp ابتدای Transaction لزوماً مناسب نیست: برای نمونه، مستندات PostgreSQL می‌گویند CURRENT_TIMESTAMP/now() زمان شروع Transaction را نشان می‌دهند، درحالی‌که clock_timestamp() زمان واقعی لحظه فراخوانی را برمی‌گرداند. این صرفاً هشدار درباره Semantics است و به‌معنای انتخاب PostgreSQL نیست. Candidate نهایی باید دقیقاً ثابت کند عبارت زمان نسبت به اخذ Lock، ارزیابی مجدد Update هم‌زمان و Commit چه زمانی ارزیابی می‌شود. اگر این موضوع قابل اثبات نباشد، پروتکل Lease روی آن Candidate قابل پذیرش نیست.
