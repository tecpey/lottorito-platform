# G09-A17 — پرونده تحقیق و پیشنهاد تصمیم‌های مالک برای ADR-002

**شناسه سند:** LOT-AFFILIATE-G09-A17-001  
**نسخه:** ۰.۱.۰  
**تاریخ:** ۲۰۲۶-۱۱-۲۸  
**وضعیت:** صرفاً تحقیق و پیشنهاد — بدون تصمیم مالک، تأیید مستقل، انتخاب Candidate یا مجوز Runtime  
**خط مبنا:** PR شماره ۷۶؛ Head بررسی‌شده `019b5edaeaf8e21f3d3a2b45335ebb4f849c6091`  
**اسناد مرتبط:** ADR-002 نسخه ۰.۳.۰؛ G09-A11 تا A16؛ LOT-EVENT-001؛ LOT-API-001؛ LOT-TECH-ADR-001؛ LOT-QA-001؛ LOT-PROT-001  
**اختیار:** تحلیل مشورتی. پیشنهادهای زیر Default، سیاست، تصویب یا مجوز پیاده‌سازی نیستند.

## ۱. تعیین تکلیف مدیریتی

این پرونده دوازده تصمیم باز مالک در G09-A15 را بر اساس مستندات فنی اولیه، پژوهش معتبر سیستم‌های توزیع‌شده و روش‌های مهندسی مبتنی بر تحلیل خرابی بررسی می‌کند.

**نتیجه محوری:** مانع ADR-002 نبود یک دیتابیس ترجیحی نیست. مانع اصلی، تعریف‌نشدن معنای خرابی و ریسک از سوی مالک و نبود شواهد اختصاصی Candidate است که نشان دهد مرجع Persistence در شرایط هم‌زمانی، Commit مبهم، Failover، Restore و Writer قدیمی، پروتکل را واقعاً اعمال می‌کند.

پیش از تعیین Failure Model و میزان تحمل زیان، نباید دیتابیس، Queue، توپولوژی Cloud یا مقدار عددی RPO/RTO انتخاب شود. برای سازگارکردن Invariant با محصول دلخواه، نباید خود Invariant تضعیف شود. مستندات فروشنده منبع فرضیه‌اند؛ شواهد پذیرش باید از تست واقعی روی Engine دورریختنی/ایزوله و مشاهده مستقل به دست آید.

### ترتیب کاری پیشنهادی

۱. تثبیت معنای منطقی هویت و API (OD-01، OD-02، OD-03، OD-11).  
۲. دریافت تصمیم‌های ریسک مالک و قیود چرخه عمر داده (OD-04، OD-08، OD-12).  
۳. تعریف تعهدات اثبات مرجعیت، تراکنش و یکپارچگی جفت (OD-05، OD-06، OD-07).  
۴. تعریف معنای Quarantine و چرخه عمر Installation (OD-09، OD-10).  
۵. فقط پس از تصویب موارد بالا یا Deferred رسمی همراه با پذیرش اثر آن، ارزیابی Candidateهای مشخص (R1)، طراحی Harness مصنوعی (R2) و درخواست مجوز مستقل برای اجرای اثبات ایزوله (R3).

این ترتیب وابستگی است؛ مجوز عبور از بازبینی مستقل A12 یا Gateهای A4 نیست.

## ۲. وضعیت تصمیم و مدل اختیار

تمام OD-01 تا OD-12 تا زمانی که مرجع پاسخ‌گوی آن‌ها Artifact تصمیم را ثبت نکرده باشد **OPEN** می‌مانند. نقش‌های نام‌برده‌شده در A15 حوزه مسئولیت‌اند، نه افراد منصوب‌شده. صرفاً به‌دلیل کوچک‌بودن تیم فعلی، هیچ شخصی صاحب اختیار حقوقی، مالی، SRE، امنیت یا شریک فرض نمی‌شود.

برای هر تصمیم ثبت شود:
- مالک تصمیم و مراجع مشورت‌شونده؛
- پرسش دقیق و محدوده؛
- گزینه انتخابی و گزینه‌های ردشده؛
- شواهد و فرض‌ها؛
- تاریخ اثر، نسخه و محرک بازبینی؛
- ریسک باقیمانده و Failure Modeهای پذیرفته‌شده؛
- اسناد ADR، API، تست و عملیات وابسته.

اگر مرجع پاسخ‌گو در دسترس نیست، مورد با وضعیت **DEFERRED / BLOCKED**، اثر و شرط بازگشایی ثبت شود. با سکوت یا حذف تصمیم، پیشنهاد را به Default تبدیل نکنید.

## ۳. یافته‌های مشترک حاصل از تحقیق

### ۳.۱ Timeout به معنای Abort نیست

وقتی Client پاسخ Commit را از دست می‌دهد، نمی‌تواند نتیجه بگیرد تراکنش Commit شده یا نشده است. Google Spanner وضعیت Commit با نتیجه UNKNOWN را صریحاً مستند کرده و Read بعدی را توصیه می‌کند؛ اما تضمین‌های تراکنشی آن مخصوص همان محصول است و نباید به Candidate دیگر تعمیم داده شود. راهنمای AWS درباره APIهای Idempotent توضیح می‌دهد که شناسه درخواست صریح، اتصال معنایی آن به درخواست و ثبت اتمیک Token همراه با تغییرات، ابهام Retry را کاهش می‌دهد. [R1][R2]

**نتیجه برای Lottorito:** UNKNOWN باید وضعیت مستقل بماند؛ Retry با همان هویت انجام شود؛ رقابت با تلاش اولیه در حال اجرا حل شود؛ و Read منفی با Consistency ضعیف، دلیل Abort تلقی نشود.

### ۳.۲ نام Isolation جای اثبات Schedule را نمی‌گیرد

در PostgreSQL با سطح Read Committed، هر Command Snapshot مربوط به شروع همان Command را می‌بیند و دو SELECT متوالی در یک Transaction ممکن است وضعیت‌های Commitشده متفاوتی مشاهده کنند. PostgreSQL همچنین توضیح می‌دهد Unique Constraint یکتایی کلید را اعمال می‌کند و Foreign Key ارجاع را تضمین می‌کند؛ اما Foreign Key یک‌طرفه به‌تنهایی ثابت نمی‌کند که هر Parent دقیقاً یک Child اجباری دارد. [R3][R4]

**نتیجه برای Lottorito:** تاریخچه قابل مشاهده عملیات و طراحی واقعی Constraint/Transaction باید اثبات شود. عبارت‌هایی مانند «از Transaction استفاده می‌کنیم»، «Serializable است» یا «Upsert داریم» به‌تنهایی اثبات کامل نیستند.

### ۳.۳ Lease یا Epoch فقط وقتی Fencing است که منبع آن را اعمال کند

راهنمای Failover در PostgreSQL صریحاً هشدار می‌دهد که پس از Promotion باید به Primary قدیمی اطلاع داده شود که دیگر Primary نیست؛ در غیر این صورت هر دو ممکن است خود را Primary بدانند. این وضعیت Split-Brain ایجاد می‌کند. STONITH یکی از راه‌های جلوگیری از آن است. مقاله Chubby گوگل برای شناخت طراحی Lock Service مفید است، اما Lock Service به‌صورت خودکار نوشتن روی منبع ذخیره‌سازی مستقل را Fence نمی‌کند. [R5][R6]

**نتیجه برای Lottorito:** رد Writer قدیمی باید در تمام مرزهای نوشتن حفاظت‌شده، از جمله Ingress، Worker، Repair، مسیرهای Admin و Migration اثبات شود. Epochای که فقط در همان State قابل Rollback ذخیره شده باشد کافی نیست.

### ۳.۴ مفهوم Exactly-Once باید به اجزای مستقل شکسته شود

تعریف Idempotent در HTTP درباره اثر موردنظر درخواست روی سرور است، نه تضمین جادویی Exactly-Once برای تحویل شبکه. راهنمای Transactional Outbox آمازون هشدار می‌دهد پیام تکراری پایین‌دست ممکن است رخ دهد و Consumer باید Idempotent باشد. [R7][R8]

**نتیجه برای Lottorito:** Deduplication رویداد منبع، Replay کلید درخواست، یکتایی جفت پذیرش، انتشار Outbox و هویت اثر اقتصادی آینده باید جداگانه تعریف شوند. ادعای Exactly-Once برای کل زنجیره مجاز نیست.

### ۳.۵ Canonicalization یک پروتکل نسخه‌بندی‌شده است، نه میان‌بُر Hash

RFC 8785 یا JCS ورودی سازگار با I-JSON می‌خواهد، نام Property تکراری را نمی‌پذیرد، نمایش اعداد را محدود می‌کند و داده Unicode را طبق قواعد خود بدون تغییر حفظ می‌کند. این RFC اطلاع‌رسان است و Lottorito را ملزم به انتخاب JCS نمی‌کند. [R9]

**نتیجه برای Lottorito:** JSON مبهم باید پیش از تبدیل به Object معمولی رد شود؛ پروفایل Fingerprint فقط پس از تعریف Vectorهای چندزبانه و رفتار Migration انتخاب و نسخه‌بندی شود.

### ۳.۶ منشأ و یکپارچگی شواهد اهمیت دارد

NIST SP 800-204D اقدامات امنیت زنجیره تأمین نرم‌افزار در CI/CD، از جمله Provenance و Attestation را تشریح می‌کند. روش پژوهشی Jepsen سیستم واقعی را در برابر ادعاهای Consistency مستندشده می‌آزماید، نه اینکه مستندات را خودِ اثبات بداند. [R10][R11]

**نتیجه برای Lottorito:** SHA منبع، نسخه و تنظیمات Candidate، Schedule خرابی قطعی، مشاهده Oracle مستقل و Disposition امضاشده حفظ شود. CI فقط کنترل‌های پیکربندی‌شده را اعتبارسنجی می‌کند و Oracle مستقل Durability دیتابیس نیست.

## ۴. تحلیل و پیشنهاد OD-01 تا OD-12

پیشنهادها عمداً مشروط هستند. این‌ها مواضع پیشنهادی برای بررسی‌اند، نه سیاست تصویب‌شده.

### OD-01 — Namespace منبع و محدوده هویت تغییرناپذیر Event

**پرسش:** چه کسی Namespace منبع را تعریف می‌کند و کدام Tuple یک Event را بدون Collision یا افشای بین Tenantها شناسایی می‌کند؟

**موضع پیشنهادی:** از هویت ترکیبی مقید به Tenant و Installation استفاده شود؛ به‌صورت موقت:
`(trusted_tenant_id, trusted_installation_id, approved_source_namespace, source_event_id)`.

- Tenant و Installation از تنظیمات سمت سرور و Context احراز هویت‌شده استخراج شوند، نه از ادعای Payload.
- Registry مربوط به Source Namespace به قرارداد Partner/Integration مصوب متصل باشد.
- Source Event ID یک مقدار Opaque و محدود به Namespace باشد؛ یکتایی جهانی آن فرض نشود.
- هویت Event از Idempotency-Key درخواست و هویت اثر اقتصادی آینده جدا بماند.
- Event Type، Schema/Profile و Bindingهای تغییرناپذیر در Fingerprint نسخه‌بندی‌شده و مقایسه Conflict لحاظ شوند، نه اینکه جایگزین تصادفی کلید هویت شوند.
- Collision بین Tenantها نباید موجب Lookup بین Tenantها یا افشای وجود رکورد شود.

**گزینه‌های ردشده:** یکتایی جهانی event_id بدون مرجع Namespace؛ استفاده از Hash بدنه به‌عنوان هویت؛ محدوده صرفاً Tenant در شرایط وجود چند Installation مستقل.

**شواهد لازم:** قرارداد منبع؛ سیاست Collision؛ تست یک ID در دو Tenant؛ تست یک ID در دو Installation؛ Vector تکرار و Conflict در Scope یکسان.

**مسئولان:** محصول/دامنه، مالک Partner، امنیت. **مسدودکننده:** PO-01/02/05؛ S01/S02/S22.

### OD-02 — Scope، Binding و Retention کلید Idempotency درخواست

**پرسش:** کدام درخواست‌ها Namespace کلید مشترک دارند، کلید به کدام محتوا متصل است و این Binding چه مدت حفظ می‌شود؟

**موضع پیشنهادی:** کلید درخواست به Tenant، Installation/Client Principal احراز هویت‌شده و Operation مربوط به API (با احتساب Version در صورت تفاوت معنا) محدود شود. هر کلید به Fingerprint نسخه‌بندی‌شده درخواست و نتیجه/Reference پایدار متصل شود. استفاده مجدد از همان کلید با قصد متفاوت باید Conflict قطعی ایجاد کند، نه Replay پاسخ نامرتبط.

- ذخیره و Retention کلید درخواست از Deduplication رویداد منبع جدا باشد.
- پس از Timeout/UNKNOWN، Client همان کلید و همان هویت منبع را استفاده کند.
- رفتار Late Arrival و Retention بر اساس قرارداد واقعی Retry شریک و نیاز عملیاتی/حقوقی تعیین شود؛ TTL جهانی اختراع نشود.
- اگر کلید درخواست زودتر از شواهد هویت Event منقضی شد، Deduplication منبع همچنان باید از پذیرش دوم جلوگیری کند.

**گزینه‌های ردشده:** کلید با Scope جهانی؛ تطبیق صرفاً بر اساس کلید بدون Binding بدنه؛ استخراج هویت فقط از بدنه؛ پذیرش خاموش همان کلید با بدنه متفاوت.

**شواهد لازم:** کلید/درخواست یکسان؛ کلید یکسان/درخواست متفاوت؛ کلیدهای متفاوت/رویداد منبع یکسان؛ Duplicate هم‌زمان؛ تست Late Arrival و انقضا.

**مسئولان:** API/Platform، امنیت، حریم خصوصی. **مسدودکننده:** PO-02/05؛ S01/S02/S05/S11/S23.

### OD-03 — Parser، سیاست Member تکراری، Fingerprint و Migration

**پرسش:** دقیقاً کدام Byte یا نمایش معنایی مقایسه می‌شود و معنا چگونه بدون تفسیر مجدد Eventهای تاریخی تغییر می‌کند؟

**موضع پیشنهادی:**
۱. نام Member تکراری JSON در مرز Parser خام، پیش از تبدیل به Map/Object که ممکن است شواهد را حذف کند، رد شود.  
۲. Unicode نامعتبر و محدودیت دقت/دامنه عددی تعریف شود.  
۳. مشخص شود Fingerprint بر اساس Byte خام است یا Envelope معنایی نرمال‌شده. پروفایل معنایی نسخه‌بندی‌شده فقط وقتی ترجیح دارد که قواعد نرمال‌سازی صریح و چندزبانه آزموده شده باشند.  
۴. RFC 8785 JCS به‌عنوان یکی از Candidateها بررسی شود، نه انتخاب خودکار. در صورت انتخاب، قیود I-JSON، حفظ Code Pointهای Unicode طبق استاندارد و مدیریت Integer/Decimal با دقت بالا رعایت شود.  
۵. نسخه پروفایل Fingerprint در Receipt پذیرفته‌شده ذخیره شود. Fingerprint تاریخی بدون پروتکل Migration صریح با الگوریتم جدید دوباره محاسبه نشود.  
۶. Golden Vector برای تمام زبان‌های Producer/Consumer پشتیبانی‌شده نگهداری شود.

**گزینه‌های ردشده:** JSON.parse معمولی و سپس Hash؛ Unicode Normalization ضمنی؛ Canonicalization بدون Version؛ تبدیل مقادیر مالی/Integer بزرگ به Floating Point.

**شواهد لازم:** Fixture خام Member تکراری؛ Vectorهای مرزی Unicode؛ مرز عددی؛ Corpus چندزبانه Canonicalization؛ تست Mixed-Version و Migration.

**مسئولان:** معماری، امنیت، Integration. **مسدودکننده:** PO-05؛ S02/S11.

### OD-04 — Failure Model و وعده Durability برای Commit تأییدشده

**پرسش:** پذیرش تأییدشده باید از کدام خرابی‌ها جان سالم به در ببرد و RPO/RTO قابل قبول برای هر کلاس چیست؟

**موضع پیشنهادی:** مالک پیش از هر وعده عددی Durability، ماتریس Failure Class را تصویب کند. حداقل این موارد جدا شوند: Crash پردازش، از دست‌رفتن Host، خرابی Storage، از دست‌رفتن Availability Zone، از دست‌رفتن Region، خطای اپراتور، فساد منطقی داده و Restore/PITR. برای هرکدام جداگانه تعریف شود:
- شرط Durability پیش از Acknowledgement؛
- مقدار زیان مجاز داده تأییدشده (RPO)؛
- هدف بازیابی سرویس (RTO)؛
- قاعده Promotion و انتخاب Recovery Point؛
- رفتار هنگام نامعلوم‌بودن خود تأیید Durability.

اگر وعده برای یک Failure Class، زیان صفر داده تأییدشده است، Candidate نباید پیش از تحقق شرط Durability مستند همان کلاس، Acknowledgement بدهد. اگر زیان محدود پذیرفته می‌شود، مالک باید آن را صریحاً بپذیرد و پیامد آن را برای کارهای قبلاً تأییدشده تعیین کند. از برچسب «Synchronous» مقدار RPO صفر استنباط نشود.

**گزینه‌های ردشده:** برچسب مبهم HA؛ کپی RPO/RTO از Tier فروشنده؛ تلقی Backup به‌عنوان Replication هم‌زمان.

**شواهد لازم:** معنای Write/Flush/Replication در Candidate؛ تزریق فقدان بلافاصله پس از Acknowledgement؛ تمرین Promotion و Restore؛ مقایسه هویت‌های تأییدشده؛ هزینه و بار عملیاتی.

**مسئولان:** مالک محصول، SRE/Data Platform، مالی/ریسک. **مسدودکننده:** PO-03؛ S08؛ A11-F01.

### OD-05 — ریشه مرجعیت Single-Writer و Fencing

**پرسش:** کدام مرجع حق تغییر دامنه پذیرش را صادر می‌کند و Writer قدیمی پس از Failover یا Restore چگونه از نوشتن منع می‌شود؟

**موضع پیشنهادی:** Authority Incarnation/Epoch یکنواخت و افزایشی فقط بخشی از طراحی کامل Fencing باشد. مرز Persistence حفاظت‌شده باید Epoch قدیمی یا Credential قدیمی Writer را رد کند. خود ریشه مرجعیت نباید تحت همان Partition/Restore که قرار است کنترل کند، Fork یا Rollback شود.

- ریشه Authority و Failure Model خودش صریحاً مشخص شود.
- پیش از مجازشدن Write پس از Promotion، Writer قدیمی در Storage/Network/Compute یا مرز منبعی مستقل Fence شود.
- Epoch فعال در همه مسیرهای نوشتن حفاظت‌شده بررسی شود؛ مسیرهای Admin، Repair، Migration و Background هم شامل‌اند.
- Persistence Authority Epoch از WorkItem Claim Generation جدا باشد.
- پس از Restore، Ingress و Worker متوقف بمانند تا Writerها و Credentialهای قدیمی Fence و Incarnation بازیابی‌شده دوباره برقرار شود.
- Queue Lease یا Advisory Lock اثبات Storage Fencing نیست.

**گزینه‌های ردشده:** شمارنده Epoch داخل دیتابیسی که همراه خود دیتابیس Rollback می‌شود؛ انتخاب Primary صرفاً با Heartbeat؛ انقضای Lease بدون Enforcement در سمت منبع.

**شواهد لازم:** Scheduleهای Partition، Promotion، بازگشت Primary قدیمی، Rollback در Restore و تلاش Write با Credential قدیمی؛ مدرک مستقیم رد Write در منبع حفاظت‌شده.

**مسئولان:** Platform/SRE، امنیت. **مسدودکننده:** PO-04؛ S09/S10؛ A11-F02.

### OD-06 — Isolation، Serialization و داوری Transaction در حال اجرا

**پرسش:** کدام Primitive هم‌زمانی باعث می‌شود پذیرش‌های هم‌زمان و Reconciliation ناشی از UNKNOWN به یک نتیجه همگرا شوند؟

**موضع پیشنهادی:** برای هویت کامل Event منبع، اثبات Candidate-specific یک نقطه Serialization الزامی باشد. Mechanism می‌تواند Unique Constraint همراه Transaction، Serializable Transaction، Lock صریح، Compare-and-Swap یا Primitive دیگری باشد؛ اما رفتار کامل آن هنگام Insert هم‌زمان، مشاهده Conflict، Abort، Failover و Retry باید اثبات شود.

- Retry باید با تلاش اولیه در حال اجرا داوری کند؛ نه اینکه فقط Read منفی بزند و فرض کند تلاش اولیه پایان یافته است.
- Receipt و WorkItem باید اتمیک Commit شوند.
- Reconciliation باید Cardinality و Linkage هر دو عضو جفت را در یک Snapshot سازگار یا Query اتمیک بررسی کند.
- حالت Consistency دقیق برای Read مثبت و منفی مشخص شود.
- Serializable سراسری الزامی نشود اگر Primitive محدودتر و اثبات‌شده Invariant را تأمین می‌کند؛ اما Isolation ضعیف‌تر نیز بدون شواهد Schedule پذیرفته نشود.

**گزینه‌های ردشده:** Read-then-insert در Application؛ Upsert کور؛ دو Transaction جدا برای Receipt/WorkItem؛ دو Read مستقل با Snapshot نامشخص.

**شواهد لازم:** S01/S03/S04/S05/S06/S07؛ Trace تراکنش Database؛ Barrier قطعی؛ Read مرجع؛ اثبات داوری Unique و معنای Conflict.

**مسئولان:** Data Platform، معماری. **مسدودکننده:** PO-01/02/04؛ A11-F03.

### OD-07 — Cardinality، Linkage، Repair و Quarantine جفت

**پرسش:** دقیقاً یک Receipt و دقیقاً یک WorkItem چگونه اعمال می‌شود و چه کسی مجاز به Repair نقض Invariant است؟

**موضع پیشنهادی:** یکتایی Source Identity، برابری Tenant/Installation، Referential Integrity از WorkItem به Receipt و حداکثر یک WorkItem برای هر Receipt در مرز Persistence اعمال شود. کامل‌بودن اجباری جفت جداگانه اثبات شود؛ Foreign Key یک‌طرفه ثابت نمی‌کند هر Receipt حتماً WorkItem دارد. اگر Engine انتخابی نتواند Invariant را به‌شکل Declarative بیان کند، Mechanism تراکنشی/Capability مصوب و رفتار آن پس از Restore مستند و آزموده شود.

جفت ناقص یا Link شکسته، نقض Invariant است:
- Retry خودکار و Worker Pickup در Scope آسیب‌دیده متوقف شود؛
- شواهد حفظ شوند؛
- محدودترین Scope امن Quarantine شود؛
- Repair فقط از مسیر عملیات ممیزی‌شده و دارای مجوز مستقل انجام شود؛
- در Retry عادی، نیمه مفقود به‌صورت حدسی ساخته نشود.

**گزینه‌های ردشده:** بررسی صرفاً Application؛ «Repair در نهایت»؛ Retry خودکاری که حدس می‌زند کدام نیمه مفقود است؛ Quarantine گسترده Tenant با یک Event غیرقابل‌اعتماد.

**شواهد لازم:** تلاش برای Commit هر حالت ناقص؛ چند WorkItem برای یک Receipt؛ Link بین Tenantها؛ Repair هم‌زمان؛ بررسی Restore و Audit.

**مسئولان:** Data Platform، دامنه، امنیت. **مسدودکننده:** PO-01/06؛ S01/S03/S04/S12؛ A11-F04.

### OD-08 — Replay Horizon، Tombstone، Backup/Restore، حذف و Legal Hold

**پرسش:** سیستم تا چه زمانی باید Event منبع قدیمی را تشخیص دهد و این مدرک هویتی چگونه از حذف، Backup و Offboarding جان سالم به در ببرد؟

**موضع پیشنهادی:** Replay Horizon از قرارداد Retry/Replay امضاشده منبع، بازه اختلاف، نیاز بازیابی عملیاتی و الزامات حقوقی/حریم خصوصی قابل‌اعمال استخراج شود. حداقل Tombstone غیرحساس لازم برای جلوگیری از پذیرش دوم، دست‌کم در طول Horizon مصوب و با احتساب اثر Backup/Restore و Offboarding نگهداری شود.

- Retention رویداد منبع و کلید درخواست جدا تعریف شود.
- رفتار Replay پیش از Horizon، در مرز آن و پس از آن مشخص شود.
- تعیین شود Restore چگونه ممکن است داده قدیمی را برگرداند یا Tombstone جدیدتر را حذف کند؛ پیش از Resume نوشتن، این واگرایی چگونه تطبیق داده می‌شود.
- Payload/PII نگهداری‌شده به حداقل برسد؛ Tombstone هویتی نباید به آرشیو نامحدود Payload تبدیل شود.
- Legal Hold، حذف و استثناهای Retention نیازمند مرجع حقوقی/حریم خصوصی مربوطه‌اند.

**گزینه‌های ردشده:** TTL دلخواه ۳۰/۹۰/۳۶۵ روز؛ حذف Dedupe State در حالی‌که Replay منبع نامحدود پذیرفته شده؛ نگهداری نامحدود بدون مبنای حقوقی؛ فرض حذف امن تمام شواهد Replay در Offboarding.

**شواهد لازم:** تست Replay مرزی؛ Restore از Backup/PITR؛ Offboarding Tenant؛ جریان حذف و Legal Hold؛ اثبات اینکه Restore هویت مصرف‌شده را دوباره قابل پذیرش نمی‌کند.

**مسئولان:** حقوقی/حریم خصوصی، امنیت، عملیات، مالک. **مسدودکننده:** PO-05؛ S11؛ A11-F06.

### OD-09 — اختیار، دامنه، انقضا، بازبینی و بازیابی Quarantine

**پرسش:** چه کسی، بر اساس کدام مدرک و در چه Scopeی می‌تواند Quarantine کند و سرویس چگونه امن بازمی‌گردد؟

**موضع پیشنهادی:** Containment مرحله‌ای باشد: ابتدا هویت Event؛ سپس Installation/Source Partition فقط در صورت وجود شواهد Compromise گسترده‌تر؛ و Tenant-wide تنها در صورت ضرورت و مجوز. Authority احراز هویت‌شده، Reason Code، Evidence Reference، Audit تغییرناپذیر، Expiry/Review و مجوز صریح Recovery الزامی باشند.

- Payload غیرقابل‌اعتماد نباید به‌تنهایی Quarantine گسترده ایجاد کند.
- اختیار اضطراری و بازبینی پس از حادثه تعریف شود.
- Quarantine و Worker Claim از یک نقطه Serialization اثبات‌شده عبور کنند.
- Tenantها و Productهای نامرتبط قابل‌استفاده بمانند.
- مشخص شود Quarantine کدام مورد را متوقف می‌کند: Ingress، Claim، Execution یا همه؛ این‌ها کنترل‌های جدا هستند.

**گزینه‌های ردشده:** یک Flag سراسری؛ Quarantine نامحدود؛ اقدام اپراتور بدون Evidence/Reason؛ بررسی Best-effort سمت Worker خارج از Transaction Claim.

**شواهد لازم:** S12 و تست Blast Radius؛ رد Claim قدیمی؛ Audit انقضا/بازیابی؛ عدم تداخل بین Tenantها.

**مسئولان:** امنیت، عملیات، مالک دامنه. **مسدودکننده:** PO-06؛ S12؛ A11-F07.

### OD-10 — تعلیق/لغو Installation و Receiptهای قبلاً پذیرفته‌شده

**پرسش:** با تعلیق یا لغو Installation، برای Eventهای جدید و Eventهای پذیرفته‌شده قبلی چه اتفاقی می‌افتد؟

**موضع پیشنهادی:** نقطه Linearization لغو تعریف و موارد زیر جدا شوند:
- Ingress جدید پس از لغو؛
- Ingress در حال اجرا هنگام لغو؛
- کار پذیرفته‌شده اما Claim‌نشده؛
- کار Claim‌شده/در حال اجرا؛
- کار Quarantineشده یا دارای Legal Hold.

پیشنهاد محافظه‌کارانه اولیه: پس از نقطه مرجع لغو، Ingress جدید رد شود؛ تاریخچه پذیرفته‌شده حفظ شود؛ Receipt پذیرفته‌شده بی‌صدا حذف یا Rebind نشود؛ و ادامه، توقف یا لغو کار پذیرفته‌شده اما پردازش‌نشده طبق Policy ممیزی‌شده و صریح تعیین شود. پاسخ ممکن است برای Compromise، Offboarding داوطلبانه و تعلیق حقوقی متفاوت باشد.

**گزینه‌های ردشده:** تلقی بازگشتی همه Eventهای پذیرفته‌شده به‌عنوان هرگز پذیرفته‌نشده؛ ادامه کار Credential قدیمی؛ لغو یا پردازش ضمنی بدون Policy.

**شواهد لازم:** Schedule رقابت Revocation با Ingress و Claim؛ انتشار لغو Credential؛ حفظ سوابق تاریخی؛ Transitionهای دارای Reason Code.

**مسئولان:** محصول/دامنه، امنیت، مالک Partner. **مسدودکننده:** PO-06؛ S12؛ A11-F07.

### OD-11 — پاسخ عمومی UNKNOWN/Unavailable و راهنمای Retry

**پرسش:** وقتی Commit یا Reconciliation نامطمئن است، Caller از پاسخ Wire چه چیزی را می‌تواند با اطمینان استنباط کند؟

**موضع پیشنهادی:** نتیجه کسب‌وکار از HTTP Status جدا شود و راهنمای Retry به‌صورت Machine-readable باشد.

- پاسخ موفق (برای نمونه 202) فقط پس از تأیید پذیرش پایدار تحت قرارداد Durability مصوب OD-04 صادر شود.
- برای UNKNOWN یا در دسترس‌نبودن Reconciliation مرجع، پاسخ غیرموفق با Outcome ماشینی صریح مانند `acceptance_outcome_unknown` یا `acceptance_reconciliation_unavailable` برگردد. 503 گزینه‌ای معقول برای Unavailability گذراست، مشروط به بازبینی API/Partner؛ اما نباید معنای Abort قطعی بدهد.
- به Caller گفته شود با **همان Source Identity و همان Idempotency-Key** Retry کند. برای خروج از ابهام، هرگز هویت/کلید جدید درخواست نشود.
- برای عدم تطابق اثبات‌شده هویت/Fingerprint، Conflict برگردد؛ پاسخ قبلی نامرتبط Replay نشود.
- Topology داخلی، خطای Database، وجود Tenant یا کنترل امنیتی افشا نشود.
- مشخص شود Caller چه زمانی و چگونه می‌تواند Resource وضعیت پذیرش پایدار را Query کند.

**گزینه‌های ردشده:** 202 برای UNKNOWN؛ 4xx با معنای کاذب «درخواست اعمال نشده»؛ 500 عمومی بدون قرارداد Retry؛ تغییر Key هنگام Retry.

**شواهد لازم:** ماتریس پاسخ OpenAPI/AsyncAPI؛ تست قرارداد؛ سازگاری Retry در Client؛ Schedule گم‌شدن پاسخ و عدم دسترسی Authority؛ تست افشای بین Tenantها.

**مسئولان:** API/Platform، مالک، مالک Partner. **مسدودکننده:** PO-02/07؛ A11-F08 و هم‌راستایی پاسخ API.

### OD-12 — Retention، دسترسی، یکپارچگی شواهد و اختیار بازبینی مستقل

**پرسش:** چه شواهدی نگهداری می‌شود، چه کسی به آن دسترسی دارد، یکپارچگی آن چگونه اثبات می‌شود و چه کسی می‌تواند Disposition مستقل صادر کند؟

**موضع پیشنهادی:** برای هر Proof Run یک Evidence Manifest مقاوم در برابر دست‌کاری الزامی باشد که شامل SHA منبع/Hash Artifact، نسخه و تنظیمات Candidate، Topology، نسخه Harness و Fixture، Fault Schedule، منبع ساعت، هویت‌های مصنوعی، Authority/Read Mode، Metadata تراکنش و Acknowledgement، اثبات رسیدن به نقطه Fault، مشاهدات Oracleهای مستقل، نتیجه مورد انتظار/واقعی، انحراف‌ها و Disposition امضاشده Reviewer باشد.

- Log عملیاتی از مشاهده مستقل Persistence جدا باشد.
- Payload و داده شخصی به حداقل لازم محدود شود؛ Retention طبق برنامه مصوب باشد.
- دسترسی Least-Privilege، ثبت دسترسی، بررسی یکپارچگی و Export کنترل‌شده اعمال شود.
- Retention تغییرناپذیر، Legal Hold، حذف و دسترسی Reviewer تعریف شوند.
- Reviewer باید از نویسندگان طراحی مستقل باشد و صلاحیت/تعارض منافع خود را افشا کند. اگر استقلال احراز نشد، Disposition برابر NOT ASSESSABLE است.
- CI Artifact و Green Check شواهد کمکی Provenance هستند، نه مدرک مستقل صحت Database.

**گزینه‌های ردشده:** Screenshot به‌عنوان تنها مدرک؛ Log قابل‌تغییر بدون Hash؛ نام‌گذاری Self-review به‌عنوان Independent؛ Retention شواهد بدون کنترل حریم خصوصی/دسترسی.

**شواهد لازم:** Schema شواهد و Manifest نمونه؛ تست کنترل دسترسی؛ بررسی Hash/Signature؛ تست Retention/Deletion؛ Review مستقل امضاشده و Finding-by-Finding.

**مسئولان:** امنیت، حقوقی/حریم خصوصی، QA، مالک. **مسدودکننده:** همه POها و R0 تا R4.

## ۵. اولویت و وابستگی تصمیم‌ها

| اولویت | تصمیم‌ها | دلیل تقدم | شرط خروج |
|---|---|---|---|
| P0 — معنای هویت/API | OD-01، OD-02، OD-03، OD-11 | تعریف اینکه Event/Request یکسان چیست و Caller چه کاری می‌تواند امن انجام دهد | پیشنهاد نسخه‌بندی‌شده Source Identity، چرخه Key، Fingerprint و قرارداد پاسخ |
| P0 — مرجع ریسک | OD-04، OD-08، OD-12 | Durability و Retention را مهندس یا Vendor نمی‌تواند به‌جای مالک حدس بزند | سیاست Failure/Lifecycle/Evidence مصوب یا تعویق مستند همراه اثر |
| P1 — صحت Persistence | OD-05، OD-06، OD-07 | Candidate باید Authority، Serialization و Pair Integrity را اثبات کند | مدل Authority/Fencing و معیارهای اثبات مستقل از Candidate |
| P1 — Containment چرخه عمر | OD-09، OD-10 | جلوگیری از Race ناامن Quarantine و Revocation | State Machineهای مجاز و معنای Race قطعی |
| P2 — ارزیابی Candidate | R1 | فقط اکنون می‌توان Candidateها را با نیاز ثابت مقایسه کرد | پرونده معنای Candidate با شواهد برای هر PO |
| P2 — طراحی اثبات | R2 | Harness باید قرارداد مصوب را بیازماید، نه هدف متغیر را | Schedule قطعی، Oracle مستقل و Evidence Manifest |
| P3 — اجرای ایزوله | R3 | نیازمند مجوز کتبی مستقل است | Candidate مصوب، محیط مصنوعی ایزوله و محدوده تست امضاشده |

برچسب‌های P0/P1 پیشنهاد ترتیب اجرا هستند و شدت یافته‌های A11 را تغییر نمی‌دهند.

## ۶. چارچوب ارزیابی Candidate — فعلاً بدون رتبه‌بندی Vendor

هنگامی که R1 مجاز شد، هر Candidate با یک برگه شواهد یکسان ارزیابی شود؛ اما Hard Gateهایی حفظ شوند که امتیاز بالای سایر ابعاد نمی‌تواند شکست آن‌ها را جبران کند.

**Hard Gateها (شکست = رد Candidate یا بازطراحی قرارداد):**
- Transaction پذیرش اتمیک و یکتایی Source Identity؛
- معنای Read مرجع مثبت/منفی و داوری تلاش در حال اجرا؛
- معنای مستند Acknowledgement Commit و رفتار Recovery Point؛
- Fencing تک‌نویسنده در Promotion، بازگشت Writer قدیمی و Restore؛
- اعمال Cardinality/Linkage جفت؛
- Backup/Restore بدون تخریب Dedupe و Authority Safety؛
- جداسازی Tenant و محدودیت Capabilityهای تغییر؛
- قابلیت تست مستقل و دسترسی به شواهد عملیاتی.

**ابعاد مقایسه‌ای (فقط پس از عبور از Hard Gate):**
- معنای Transaction/Consistency و رفتار Contention؛
- توپولوژی Failure Domain و پیچیدگی Recovery؛
- بلوغ عملیات، Observability و ایمنی Upgrade؛
- Backup/PITR و تمرین Restore؛
- Latency/Throughput تحت بار مصنوعی نماینده؛
- تناسب Region و Data Residency؛
- Portability و Exit Strategy؛
- هزینه کل مالکیت، نیروی انسانی و بار عملیات ۲۴/۷؛
- اکوسیستم، ابزارها و پیچیدگی Integration.

وزن عددی منتشر نشود تا اولویت تجاری توسط مالک تصویب شود. ادعای Vendor، Reference Architecture و Benchmark تبلیغاتی جای اثبات را نمی‌گیرند.

## ۷. راهبرد تست خصمانه لازم

از Scheduleهای S01 تا S12 در A15 به‌عنوان حداقل مجموعه اثبات Persistence استفاده شود و این موارد افزوده شوند:
- تولید Property-based برای Same-key/Different-payload و مرز Tenant؛
- Historyهای هم‌زمانی قطعی و بررسی Linearizability/Serializability در موارد مرتبط؛
- Fault Injection در هر مرز Transaction و Acknowledgement؛
- Restore از Backupهای قبل و بعد از تغییر Tombstone/Epoch؛
- تلاش Write با Credential قدیمی و Primary قدیمی در مرز Enforcement واقعی؛
- Assertion منفی برای صفر Write، صفر Worker Claim و صفر Downstream Effect.

Oracle تست باید مستقل از مسیر Application باشد: Read مرجع Native در Candidate، Metadata تراکنش/Replication، شواهد شبکه و Fault کنترل‌شده و Traceهای جمع‌آوری‌شده مستقل. هیچ Oracle واحدی برای تمام ویژگی‌ها کافی نیست.

روش Jepsen الگوی مفیدی برای آزمودن سیستم واقعی در برابر ادعاهای Consistency است؛ اما استفاده از ابزار Jepsen الزام نیست؛ Property و شواهد لازم‌اند. [R10]

## ۸. مواردی که این پرونده تصمیم نمی‌گیرد

این پرونده:
- PostgreSQL، Spanner، CockroachDB، Queue، Cloud یا Topology انتخاب نمی‌کند؛
- RPO/RTO، Retention، تعداد Retry، Timeout یا تعداد Replica عددی تعیین نمی‌کند؛
- Parser Library، پیاده‌سازی JCS، Schema، مدل فیزیکی داده یا Deployment را تصویب نمی‌کند؛
- A11-F01 تا F08 یا Extensionهای A7/A8 را نمی‌بندد؛
- بازبینی مستقل A12 نیست؛
- اجرای R1/R2، اثبات Runtime در R3، اتصال Partner، پردازش مالی، Merge یا Deploy را مجاز نمی‌کند.

## ۹. اقدامات فوری بعدی

۱. OD-01 تا OD-12 به نقش‌های مالک پاسخ‌گو ارائه شوند؛ نام مرجع تصمیم فقط پس از تأیید واقعی ثبت شود.  
۲. تصمیم‌های P0 حل یا با اثر و شرط بازگشایی به‌طور رسمی Deferred شوند.  
۳. بازبینی مستقل A12 در مسیر جداگانه ادامه یابد؛ پرونده تصمیم جای امضای Reviewer نیست.  
۴. پس از بسته‌شدن P0/P1، قالب شواهد R1 مستقل از Candidate تهیه شود؛ سپس محصولات نام‌برده شوند.  
۵. ADR-002، قراردادهای API و A15 فقط بر اساس تصمیم‌های مصوب به‌روزرسانی شوند؛ جفت فارسی/انگلیسی حفظ و CI دقیقاً روی Head نهایی اجرا شود.

**تعیین تکلیف نهایی:** G09-A17 یک پرونده پیشنهاد مبتنی بر تحقیق است. تمام OD-01 تا OD-12 تا زمان تصمیم مجاز همچنان OPEN هستند. ADR-002 در وضعیت PROPOSED؛ A11-F01 تا F08 باز؛ R0 مسدود؛ R1/R2 شروع‌نشده؛ R3 غیرمجاز؛ و تمام Gateهای A4 تصویب‌نشده باقی می‌مانند.

## ۱۰. منابع اصلی تحقیق و مراجع فنی

- [R1] Google Cloud Spanner Commit API — نتیجه UNKNOWN و راهنمای Read بعدی: https://docs.cloud.google.com/workflows/docs/reference/googleapis/spanner/v1/projects.instances.databases.sessions/commit
- [R2] AWS Builders' Library — Making retries safe with idempotent APIs: https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- [R3] PostgreSQL — Transaction Isolation: https://www.postgresql.org/docs/current/transaction-iso.html
- [R4] PostgreSQL — Constraints (UNIQUE، PRIMARY KEY، FOREIGN KEY): https://www.postgresql.org/docs/current/ddl-constraints.html
- [R5] PostgreSQL — Failover و هشدار Fencing/STONITH: https://www.postgresql.org/docs/current/warm-standby-failover.html
- [R6] Mike Burrows، The Chubby Lock Service for Loosely-Coupled Distributed Systems، OSDI 2006: https://research.google/pubs/the-chubby-lock-service-for-loosely-coupled-distributed-systems/
- [R7] IETF RFC 9110 §9.2.2 — Idempotent Methods: https://www.rfc-editor.org/rfc/rfc9110.html
- [R8] AWS Prescriptive Guidance — Transactional Outbox Pattern: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html
- [R9] IETF RFC 8785 — JSON Canonicalization Scheme: https://www.rfc-editor.org/rfc/rfc8785.html
- [R10] Jepsen — Distributed Systems Safety Research و مدل‌های Consistency: https://jepsen.io/ و https://jepsen.io/consistency/models/linearizable
- [R11] NIST SP 800-204D (2024) — Software Supply Chain Security در DevSecOps CI/CD: https://csrc.nist.gov/pubs/sp/800/204/d/final
