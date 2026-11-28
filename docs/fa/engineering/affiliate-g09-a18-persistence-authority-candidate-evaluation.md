# G09-A18 — ارزیابی معماری Candidateهای Persistence و Authority

**شناسه سند:** LOT-AFFILIATE-G09-A18-001  
**نسخه:** ۰.۱.۰ | **تاریخ:** ۲۰۲۶-۱۱-۲۸  
**وضعیت:** صرفاً تحقیق و پیشنهاد مشروط — بدون تصمیم مالک، انتخاب Candidate، مجوز Runtime یا تأیید مستقل  
**مبنای بررسی:** PR #76، روی Head با شناسه `d51304467a97d25a69bfcb18e2b0dc7d69ef176b`  
**مرتبط:** ADR-002 v0.3.0؛ اسناد G09-A11 تا A17؛ LOT-EVENT-001؛ LOT-API-001؛ LOT-QA-001  
**مرجعیت:** تحلیل معماری مشورتی؛ هیچ Candidateای تصویب یا انتخاب نشده است.

## ۱. تعیین تکلیف اجرایی

پرسش Persistence این نیست که «بهترین دیتابیس کدام است؟» پرسش واقعی این است که آیا یک Deployment مشخص می‌تواند پروتکل پذیرش ADR-002 را تحت Failure Model مستندشده اثبات کند یا نه: درخواست‌های تکراری هم‌زمان، گم‌شدن پاسخ Commit، Crash فرایند، خرابی Primary، بازگشت Primary قدیمی، تأخیر Replica، Restore و Repair اپراتوری.

**هیچ Candidateای صرفاً با مستندات محصول قبول نمی‌شود.** تضمین‌های محصول ورودی طراحی Proof هستند؛ پذیرش فقط با تست واقعی، نسخه و پیکربندی تثبیت‌شده، Fault Injection و Oracleهای مستقل در نقاط واقعی Enforcement امکان‌پذیر است.

### پیشنهاد مشروط

۱. ADR-002 همچنان مستقل از فناوری باقی بماند.  
۲. Shortlist مرحله R1 بر این خانواده‌ها بنا شود:
- **خانواده P:** PostgreSQL تک‌نویسنده با HA مهندسی‌شده، Durability هم‌زمان در صورت الزام RPO مصوب و Fencing مستقل و قابل‌اثبات.
- **خانواده D:** یک پیاده‌سازی Distributed SQL (CockroachDB یا YugabyteDB؛ هرکدام جداگانه ارزیابی شوند و معادل یکدیگر فرض نشوند).
- **خانواده M:** Distributed SQL مدیریت‌شده مانند Google Cloud Spanner، فقط اگر الزامات حوزه قضایی، Data Residency، دسترسی منطقه‌ای، وابستگی Cloud، هزینه و Latency قابل‌قبول باشند.
۳. Managed PostgreSQL یک Sub-candidate مستقل است؛ نباید فرض کرد نگرانی‌های Failover در PostgreSQL عمومی با واژه Managed حذف می‌شوند. معنای واقعی Failover، Synchronous Commit، Backup و Fencing باید برای همان سرویس/Region/Tier مستند شود.
۴. Queue، Cache، Lock Service یا Middleware با ادعای «Exactly Once» را به‌عنوان Source of Truth دوم اضافه نکنیم. مرجع پذیرش همان Transaction دیتابیس است؛ پردازش ناهم‌زمان باید از وضعیت Commit‌شده مشتق شود (Transactional Outbox یا معادل آن).
۵. تا زمانی که تصمیم‌های ریسک OD-04/OD-08/OD-12 و محدودیت‌های Deployment روشن نشده‌اند، برنده یا امتیاز عددی تعیین نشود.

**وضعیت فعلی:** خانواده‌های Candidate برای گردآوری شواهد شناسایی شده‌اند؛ Qualification در R1 هنوز اجرا نشده است. طراحی Harness در R2 شروع نشده و اجرای Runtime در R3 مجاز نیست.

## ۲. Invariantهای تثبیت‌شده و محدوده

هر Candidate باید تمام موارد زیر را بدون اتکا به رفتار Best-effort برنامه حفظ کند:

- هر Source-event identity مصوب حداکثر به یک جفت پذیرفته‌شده InboxReceipt + WorkItem نگاشت شود.
- جفت اتمیک باشد: هر دو Durable یا هیچ‌کدام Durable نباشند.
- Success Acknowledgement فقط پس از تحقق شرط Durability/Commit مصوب صادر شود.
- پاسخ گم‌شده تا زمان Reconciliation مرجع، UNKNOWN باقی بماند.
- همان Identity با Binding تغییرکرده و غیرقابل‌تغییر، Conflict است نه Replay.
- Writer، Worker، Repair Process یا Primary قدیمی پس از انتقال Authority نتواند State محافظت‌شده را تغییر دهد.
- Restore نتواند Identity مصرف‌شده را احیا کند یا Epoch مرجعیت را به شکلی عقب ببرد که پذیرش تکراری ممکن شود.
- Queue Delivery، Cache، Log، Replica با Consistency ضعیف‌تر و State سمت Client مرجع اثبات نبودن رکورد نیستند.
- پذیرش Ingress مستقیماً Wallet، Ledger، Settlement، Payment یا Payout را تغییر نمی‌دهد.

این ارزیابی فقط لایه Persistence و Authority را پوشش می‌دهد؛ Transport شریک، محصول Queue، Provider استقرار، Schema، Parser، فرمول کمیسیون یا Runtime مالی را انتخاب نمی‌کند.

## ۳. خانواده‌های Candidate

### P — PostgreSQL تک‌نویسنده با HA مهندسی‌شده

**ساختار:** یک Primary قابل‌نوشتن؛ یک یا چند Standby؛ Replication Mode صریح؛ Promotion Controller مشخص؛ مکانیزم Fencing قابل‌اعمال؛ Backup/PITR و Restore آزموده‌شده.

**نقاط قوت**
- تراکنش‌های Relational بالغ، Constraintها، Unique Index، Foreign Key، Locking و اکوسیستم عملیاتی گسترده.
- جفت InboxReceipt + WorkItem در یک Transaction دیتابیس Commit می‌شود.
- Topology تک‌نویسنده برای Authority محدود پذیرش، از نظر مفهومی ساده و قابل‌فهم است.
- گزینه‌های متنوع میزبانی و عملیات می‌توانند وابستگی به یک پلتفرم را کاهش دهند.

**ریسک‌ها و تعهدات اثبات**
- PostgreSQL به‌تنهایی سیستم کامل تشخیص خرابی، HA و Promotion را فراهم نمی‌کند. مستندات رسمی هشدار می‌دهند پس از Promotion شدن Standby، باید Primary قدیمی از نوشتن بازداشته شود؛ در غیر این صورت هر دو Node ممکن است خود را Primary بدانند.
- Replication ناهم‌زمان می‌تواند Transactionهایی را که روی Primary تأیید شده‌اند هنگام Failover از دست بدهد. Replication هم‌زمان Latency و Availability را تغییر می‌دهد؛ رفتار دقیق `synchronous_commit`، Quorum مربوط به Standby و Policy مربوط به Failover باید تست شود، نه اینکه از واژه «Synchronous» نتیجه‌گیری شود.
- Witness یا Heartbeat به‌تنهایی Fencing نیست؛ مگر اینکه منبع واقعی Write، Authority قدیمی را رد کند.
- برنامه باید قطع اتصال حین Commit را UNKNOWN بداند و با Identity پایدار Reconcile کند؛ نه اینکه کورکورانه Replay کند.
- Restore موفق دیتابیس همچنان ممکن است ناامن باشد اگر Epochهای Authority خارجی، Tombstoneهای Idempotency، Revocation اعتبارنامه یا وضعیت Outbox ناسازگار Restore شوند.

**نکته حیاتی پیکربندی PostgreSQL:** مقدار `synchronous_commit=on` به‌تنهایی به معنی تأیید Commit توسط Standby راه‌دور نیست. اگر `synchronous_standby_names` خالی باشد، Commit فقط منتظر Flush محلی WAL می‌ماند. با تعریف Standby هم‌زمان، مقدار `on` منتظر Flush پایدار WAL در Standby است؛ `remote_write` فقط منتظر Write در سیستم‌عامل Standby می‌ماند؛ و `remote_apply` علاوه بر Durability منتظر Replay/Apply نیز می‌ماند. این حالت‌ها از نظر Latency و Visibility متفاوت‌اند. مقدار دقیق و Quorum مربوط به Standby هم‌زمان باید برای Role تراکنشی منتخب Pin و Verify شود. عبارت کلی «Sync Replication فعال است» Evidence کافی نیست. [R12][R13]

**شرایط رد Candidate**
- Promotion بدون اثبات Fencing برای Writeهای Primary قدیمی ممکن باشد؛
- RPO انتخاب‌شده اجازه از دست رفتن Receipt تأییدشده توسط API را بدهد؛
- شرط واقعی Acknowledgement مربوط به Commit مستند یا آزموده نشده باشد؛
- Restore بتواند Identity مصرف‌شده یا Writer قدیمی را دوباره فعال کند؛
- اپراتورها نتوانند مستقلاً مشخص کنند در هر مقطع کدام Node مرجع بوده است.

**ارزیابی:** Candidate پایه‌ای قوی است، اگر مدل تک‌نویسنده/تک‌Region کافی باشد و تیم توان عملیات و تست کل محدوده HA را داشته باشد. اما «به‌صورت پیش‌فرض امن» نیست؛ Fencing و Durability الزام اصلی محصول‌اند.

### P-M — Managed PostgreSQL HA (زیرگروه مستقل)

**ساختار:** Primary/Standby مدیریت‌شده توسط Provider، Failover Endpoint و Backup/PITR با رفتار Replication و Promotion مخصوص همان سرویس.

**نقاط قوت**
- می‌تواند میزان عملیات مستقیم خوشه دیتابیس توسط پروژه را کاهش دهد.
- ممکن است HA منطقه‌ای، Backup و Telemetry عملیاتی مستند ارائه کند.
- مدل تراکنشی و اکوسیستم PostgreSQL را حفظ می‌کند.

**ریسک‌ها و تعهدات اثبات**
- عبارت Managed HA مشخص نمی‌کند که Commitهای تأییدشده به برنامه در تمام انواع Failover حفظ می‌شوند یا خیر.
- پروژه ممکن است STONITH در سطح Host را کنترل نکند؛ پس باید تضمین Provider درباره Fencing، Endpoint Routing، Sessionهای قدیمی و ایزوله‌سازی Primary سابق را به‌دست آورد.
- Service Tier، Region، رفتار Maintenance، Triggerهای Failover، Promotion Replica، معنای Restore و محدودیت PITR وابسته به محصول‌اند.
- Backup/Restore Provider ممکن است State مربوط به Identity/Epoch خارجی را که در جای دیگری نگهداری شده حفظ نکند.
- Data Residency، محدودیت‌های تحریم/صادرات، الزامات داده مالی و شرایط قراردادی نیازمند بررسی مالک/حقوقی است؛ در این سند مناسب‌بودن هیچ Providerای فرض نشده است.

**ارزیابی:** فقط سرویس، Region، Tier و پیکربندی دقیق بررسی شود. فرض‌های PostgreSQL عمومی را به آن تعمیم ندهیم و ادبیات بازاریابی Provider را اثبات پروتکل پذیرش تلقی نکنیم.

### D — Distributed SQL (ارزیابی جداگانه CockroachDB و YugabyteDB)

**ساختار:** دیتابیس توزیع‌شده با رابط SQL، داده Replicated، رفتار Consensus/Quorum و هماهنگی تراکنش توزیع‌شده. هر محصول و نسخه باید مستقلاً ارزیابی شود.

**نقاط قوت**
- Replication و مدیریت خرابی Node/Zone در معماری دیتابیس تعبیه شده‌اند، نه اینکه صرفاً با Controller خارجی Primary/Standby ساخته شوند.
- Transaction توزیع‌شده و گزینه‌های Serializable Isolation می‌توانند تعهدات Consistency بین Nodeها را صریح‌تر کنند.
- زمانی جذاب است که Availability چند Zone یا چند Region نیاز واقعی باشد، نه فقط هدفی فرضی برای آینده.

**ریسک‌ها و تعهدات اثبات**
- Distributed SQL نیاز به Retry تراکنش را حذف نمی‌کند. خطاهای Serialization/Transaction Retry باید با Loop صحیح مدیریت شوند که کل بدنه Transaction را به‌صورت ایمن دوباره اجرا کند؛ Side Effect خارجی نباید داخل Transaction قابل Retry رخ دهد.
- CockroachDB و YugabyteDB در پیاده‌سازی Transaction، جزئیات Isolation، سطح Retry، رفتار DDL، ابزارهای عملیاتی و Topology تفاوت دارند؛ برای Qualification یک دسته قابل‌جایگزینی نیستند.
- Quorum بین Regionها می‌تواند Latency نوشتن را بالا ببرد و Availability را به دسترسی Quorum وابسته کند.
- طراحی Schema، توزیع Key، Hotspot، گستره Transaction و Contention می‌توانند Latency و پایداری عملیات را به‌شدت تغییر دهند.
- Consensus داخلی دیتابیس به‌صورت خودکار Queue، Cache، Object Store، Payment API یا Side Effect مستقل Worker را Fencing نمی‌کند.
- سازگاری Driver یا Syntax با PostgreSQL اثبات‌کننده یکسانی Semantics، Extensionها، Migration یا Failure Handling نیست.
- بررسی نسخه‌محور Constraintها، Unique-key، Transactional DDL، Backup/Restore، Changefeed، Retry سمت Client و چرخه پشتیبانی ضروری است.

**ارزیابی:** تنها وقتی یک پیاده‌سازی را Qualify کنیم که نیاز واقعی چند Zone/Region پیچیدگی Distributed System را توجیه کند و تیم توان عملیات Failure Modeهای آن را داشته باشد. صرفاً به‌دلیل «Replica بیشتر» سراغ Distributed SQL نرویم.

### M — Google Cloud Spanner (Candidate مشروط Distributed SQL مدیریت‌شده)

**ساختار:** دیتابیس Relational توزیع‌شده مدیریت‌شده با Serializable Transaction و External Consistency به‌صورت پیش‌فرض، Configurationهای Replication و مدیریت Quorum/Replica توسط Provider.

**نقاط قوت**
- مستندات رسمی، Serializable Transaction و External Consistency را شرح می‌دهند؛ اثر تراکنش‌ها با ترتیب قابل مشاهده Commit در زمان واقعی سازگار است.
- Topologyهای Regional و Multi-region دارای چیدمان صریح Quorum و Replica هستند.
- مسئولیت مستقیم پروژه برای عملیات Nodeهای دیتابیس و Consensus را کاهش می‌دهد.

**ریسک‌ها و تعهدات اثبات**
- تضمین تراکنشی قوی، UNKNOWN شدن نتیجه Commit در سطح برنامه را حذف نمی‌کند؛ Client همچنان به Reconciliation مبتنی بر Identity نیاز دارد.
- انتخاب Region محل داده، Latency، Availability، هزینه و Residency را تعیین می‌کند. Configuration چندمنطقه‌ای در مقایسه با Regional، Trade-off متفاوتی در Quorum و Write Latency دارد.
- وابستگی به Cloud Provider، دسترسی سرویس در Regionهای مجاز حقوقی، مدل Billing، Capacity Planning، امکان خروج و Exit Strategy باید بررسی شوند.
- رفتار Retry کتابخانه Client باید تست شود و Callbackهای Transaction نباید Side Effect غیرتراکنشی داشته باشند.
- تضمین Spanner فقط روی داده مدیریت‌شده خود Spanner اعمال می‌شود؛ نه خودکار روی سیستم خارجی یا Consumerهای ناهم‌زمان.

**ارزیابی:** از نظر فنی جذاب است، اگر زیرساخت Google Cloud، Region/Residency، هزینه و مدل عملیات قابل‌قبول باشند. بدون این اطلاعات، توصیه پیش‌فرض این پروژه نیست.

### X — معماری تفکیک‌شده Authority و پردازش ناهم‌زمان

این یک الگوی معماری است، نه Candidate دیتابیس.

**ساختار لازم**
- دیتابیس تراکنشی منتخب، تنها مرجع Identity پذیرش، جفت Receipt/WorkItem و State Transition باشد.
- در صورت نیاز به انتشار Downstream، Outbox یا معادل آن در همان Transaction Commit شود.
- پیام Queue فقط Hint برای بیدارکردن/تحویل باشد؛ Consumer باید Work مرجع را از دیتابیس دوباره بخواند و Claim کند.
- Cache مرجع Acceptance، Dedupe، Authority یا Repair نباشد.
- Lock Service یا Lease می‌تواند هماهنگی کند؛ اما Fencing نیست مگر تمام Resourceهای محافظت‌شده Authority Token یکنواخت و افزایشی را اعتبارسنجی کرده و Token قدیمی را رد کنند.
- هر Economic Effect آینده، Identity دامنه‌ای و مرز Authorization مستقل داشته باشد.

**ارزیابی:** این الگو با P، P-M، D و M سازگار است و جداسازی منطقی پیشنهادی مستقل از انتخاب دیتابیس است. نباید آن را «Exactly Once» معرفی کرد.

## ۴. ماتریس مقایسه تصمیم

| بُعد | P: PostgreSQL HA | P-M: Managed PG | D: Distributed SQL | M: Spanner |
|---|---|---|---|---|
| اتمیک‌بودن Receipt + WorkItem | Transaction بومی یک DB | بومی؛ وابسته به سرویس | Distributed ACID Transaction | Read-write Transaction |
| مدل Primary/Authority | Promotion تک‌نویسنده صریح | Provider-managed؛ نیازمند اثبات | مدل Leader/Consensus توزیع‌شده | مدل Leader/Quorum مدیریت‌شده |
| حفاظت Primary قدیمی | باید مهندسی و اثبات شود | باید تضمین دقیق سرویس دریافت شود | Authority داخلی DB؛ Side Effect خارجی همچنان Fencing می‌خواهد | Authority داخلی DB؛ Side Effect خارجی همچنان Fencing می‌خواهد |
| ابهام Commit | Reconciliation در برنامه لازم | لازم | لازم؛ Retry Error نیز مهم است | Reconciliation برای UNKNOWN لازم |
| Latency نوشتن بین Regionها | وابسته به محل Standby هم‌زمان | وابسته به Topology سرویس | وابسته به Quorum/Topology | وابسته به Quorum/Leader Region |
| بار عملیات | در Self-managed بالاترین | عملیات DB کمتر، وابستگی به Provider | عملیات تخصصی Distributed DB | عملیات DB کمتر، وابستگی قوی‌تر به Provider |
| Portability | عموماً قوی‌تر | متوسط؛ ویژگی‌های Provider وابستگی می‌آورند | وابستگی به محصول در SQL/Operations | وابستگی بالای Cloud |
| شواهد لازم | HA Controller + Storage + Fencing + Restore | رفتار دقیق Service/Tier/Region | محصول/نسخه/Topology/Retry دقیق | Configuration/Client/Region/Restore دقیق |
| Qualification فعلی | NOT TESTED | NOT TESTED | NOT TESTED | NOT TESTED |

این ماتریس کیفی است. تا زمانی که مالک اولویت ریسک، حوزه قضایی و محدودیت‌های عملیات را تصویب نکرده، امتیاز وزنی عددی قابل دفاع نیست.

## ۵. Hard Gateهای پیش از ورود هر Candidate به Shortlist

هیچ Candidateای Qualify نشده است مگر تمام Gateهای زیر دارای مالک شواهد، روش تست دقیق، Oracle مستقل و Pass/Fail Rule باشند.

### G1 — جفت اتمیک و Uniqueness
- درخواست‌های هم‌زمان با Identity یکسان دقیقاً یک Receipt و یک WorkItem بسازند.
- Identity یکسان با Binding غیرقابل‌تغییر متفاوت، Conflict قطعی ایجاد کند.
- پس از Commit، Abort یا Crash هیچ Receipt یا WorkItem یتیم مشاهده نشود.
- Constraint و منطق Transaction زیر Concurrency واقعی اثبات شوند، نه فقط Unit Test ترتیبی.

### G2 — Acknowledgement مربوط به Commit و UNKNOWN
- Success API پس از Durability Acknowledgement صریح و مصوب صادر شود.
- Fault Injection قبل از Commit، حین Commit، پس از Commit و پیش از Response وضعیت‌های KNOWN_ABORTED، KNOWN_COMMITTED و UNKNOWN را درست تفکیک کند.
- Retry با همان Identity به جفت قبلی Reconcile شود و رکورد تکراری نسازد.
- Read قدیمی یا ضعیف از Replica به‌عنوان اثبات نبودن رکورد استفاده نشود.

### G3 — Failover و Fencing
- Primary قدیمی حین و پس از Promotion متوقف، ایزوله و مجدداً فعال شود.
- تلاش Write با Connection، Credential، DNS Endpoint و Worker قدیمی انجام شود.
- رد شدن در مرز واقعی Storage اثبات شود، نه فقط Load Balancer یا Application Router.
- اگر Authority با Epoch/Term نمایش داده می‌شود، اثبات شود Restore آن را Rollback یا دور نمی‌زند.

### G4 — Backup، Restore و Disaster Recovery
- از Snapshotهای قبل و بعد از Acceptance، Tombstoneهای Dedupe، Revocation و تغییر Authority بازیابی انجام شود.
- پس از Restore هیچ Identity مصرف‌شده‌ای دوباره قابل‌پذیرش نباشد.
- State دیتابیس با Outbox، Worker، Credential، Audit Record و Authority خارجی تطبیق داده شود.
- RPO/RTO به‌عنوان نتیجه اندازه‌گیری‌شده Topology منتخب اثبات شوند، نه هدف بازاریابی.

### G5 — جداسازی Tenant و مرز Privilege
- Lookup، Uniqueness Conflict، Repair، Replay و Metadata Query بین Tenantها وجود رکورد را افشا نکنند.
- نقش‌های Application، Worker، Repair و Operator دارای Capabilityهای جدا و Least-Privilege باشند.
- Bypassهای مدیریتی Audit شوند و نتوانند Constraintهای Immutable Identity را دور بزنند.

### G6 — بازیابی عملیاتی
- Runbookها Promotion، Failback، Rejoin، Backup Verification، Restore، Quorum Degraded، Credential Revocation و Manual Repair را پوشش دهند.
- Observability، Node/Term مرجع، Replication State، Transaction Outcome، Retry و Reconciliation Metrics را نشان دهد.
- اپراتور دوم بتواند بدون اتکا به حافظه فرایند اولیه، رویدادها را از شواهد نگهداری‌شده بازسازی کند.

### G7 — شواهد مستقل و تکرارپذیری
- Product Version، Configuration، Topology، Client Library و Infrastructure تثبیت و Pin شوند.
- Fault Scheduleهای قطعی، Raw Observation، Source SHA، Hash آرتیفکت تست و خروجی Oracle نگهداری شوند.
- سناریوهای حیاتی برای پوشش Race Window تکرار شوند؛ در صورت لزوم Property-based و Concurrency History به کار رود.
- Reviewer باید از نویسنده مستقل و دارای صلاحیت مرتبط در Database/Distributed Systems باشد.

هر Hard Gate شکست‌خورده یا غیرقابل‌مشاهده یعنی **NO-GO**، نه «Conditional Pass».

## ۶. برنامه Qualification Candidate (صرفاً R1)

R1 مرحله تحقیق و گردآوری شواهد است، نه مجوز اجرای Runtime Test.

۱. ابتدا محدودیت‌های Deployment ثبت شوند: Cloud/Provider قابل‌قبول، Regionهای مجاز، Data Residency، حوزه قضایی، محل شبکه، محدوده بار مورد انتظار، هدف Availability، محدوده بودجه، نیروی عملیات و الزامات Exit.  
۲. معماری و Failure Semantics دقیق Provider برای همان Service/Tier/Region دریافت شود.  
۳. پروفایل نسخه‌دار Candidate تهیه شود: نسخه دیتابیس، Driver، Topology، Replication Mode، Quorum، Failover Controller، Fencing، Backup/PITR، Restore و نقش‌های عملیاتی.  
۴. تمام Scheduleهای S01 تا S12 در A15 و Gateهای G1 تا G7 به مکانیزم مخصوص Candidate و نتیجه قابل مشاهده مستقل نگاشت شوند.  
۵. تضمین‌های غیرقابل‌تست یا مبهم برای Provider شناسایی شوند؛ این موارد ریسک باز هستند، نه PASS فرضی.  
۶. پس از تحقیق مستندی، یک Candidate PostgreSQL HA با یک Candidate Distributed SQL مقایسه شود. Spanner فقط در صورت سازگاری با محدودیت Cloud و حوزه قضایی اضافه شود.  
۷. Shortlist مبتنی بر Evidence و Register ریسک باقی‌مانده تهیه شود. امتیاز عددی فقط پس از تصویب وزن‌ها توسط مالک.

**خروجی R1:** پروفایل Candidateها و شکاف شواهد بازبینی‌شده؛ این سند هیچ Candidateای را انتخاب نمی‌کند.  
**R2:** طراحی Harness مصنوعی و دورریختنی فقط پس از R1 و تصویب A4.  
**R3:** اجرای Fault Test مربوط به Runtime فقط با مجوز صریح و جداگانه.

## ۷. پیشنهاد مقدماتی و وابستگی تصمیم‌ها

**پیشنهاد مقدماتی برای Iteration تحقیق بعدی:** PostgreSQL HA مهندسی‌شده را به‌عنوان Baseline Control نگه داریم و آن را با دقیقاً یک Candidate از خانواده Distributed SQL مقایسه کنیم؛ انتخاب Candidate دوم بعد از روشن‌شدن محدودیت‌های Deployment انجام شود. Spanner صرفاً Candidate مرجع مشروط باقی بماند، نه Finalist فرضی.

دلیل این ترتیب:
- مدل ساده‌تر تک‌نویسنده را در برابر مدل Consensus توزیع‌شده می‌سنجد، بدون تکثیر زودهنگام Candidateها.
- هزینه واقعی Fencing، Durability هم‌زمان و Restore در PostgreSQL را آشکار می‌کند.
- مشخص می‌کند Distributed SQL واقعاً مزیت ناشی از Requirement دارد یا صرفاً جذابیت نظری.
- از مقایسه نادرست PostgreSQL خودمدیریت‌شده با سرویس جهانی کاملاً مدیریت‌شده، پیش از روشن‌شدن حوزه قضایی، هزینه و محل داده جلوگیری می‌کند.

این پیشنهاد **تصمیم فناوری نیست**. OD-04 (تحمل از دست‌رفتن داده)، OD-05 (Authority/Fencing)، OD-08 (Retention و چرخه Restore)، OD-12 (نگهداری Evidence) و محدودیت‌های Deployment/حوزه قضایی همچنان وابستگی‌های باز هستند.

## ۸. مواردی که تصمیم نمی‌گیرند و شرایط توقف

این سند:
- PostgreSQL، CockroachDB، YugabyteDB، Spanner، Managed Service، Cloud، Queue یا Topology انتخاب نمی‌کند؛
- RPO/RTO، Retention، تعداد Replica، Timeout، تعداد Retry، Availability Target یا Budget را تصویب نمی‌کند؛
- ادعا نمی‌کند سرویس Vendor خاصی در Deployment مالک در دسترس یا از نظر حقوقی مناسب است؛
- یافته‌های A11 را نمی‌بندد و بازبینی مستقل A12 را انجام نمی‌دهد؛
- تغییر Schema، Runtime Code، اجرای Harness، اتصال Partner، پردازش مالی، Merge یا Deploy را مجاز نمی‌کند.

**توقف:** اگر Failure Model مصوب، حوزه قضایی، Data Residency، Recovery Objective یا مدل Authority نامعلوم است، Candidate انتخاب نشود. اگر Candidate شواهد کافی برای اثبات یک Hard Gate ارائه نمی‌کند، صرف‌نظر از SLA تبلیغ‌شده برای این کاربرد رد شود.

## ۹. منابع تحقیق

- PostgreSQL، High Availability, Load Balancing, and Replication: https://www.postgresql.org/docs/current/high-availability.html
- PostgreSQL، Failover و هشدار Primary قدیمی/STONITH: https://www.postgresql.org/docs/current/warm-standby-failover.html
- PostgreSQL، Synchronous Replication و Trade-offهای Performance/Availability: https://www.postgresql.org/docs/current/warm-standby.html
- CockroachDB، Developer Basics (تراکنش Serializable و Retry Error): https://www.cockroachlabs.com/docs/stable/developer-basics.html
- YugabyteDB، Transactions و پشتیبانی ACID: https://docs.yugabyte.com/stable/explore/transactions/
- YugabyteDB، Transaction Isolation Levels: https://docs.yugabyte.com/stable/architecture/transactions/isolation-levels/
- Google Cloud Spanner، Transactions Overview: https://docs.cloud.google.com/spanner/docs/transactions
- Google Cloud Spanner، TrueTime و External Consistency: https://docs.cloud.google.com/spanner/docs/true-time-external-consistency
- Google Cloud Spanner، Regional، Dual-region و Multi-region Configurations: https://docs.cloud.google.com/spanner/docs/instance-configurations
- Jepsen، تحلیل‌های منتشرشده سیستم‌های توزیع‌شده: https://jepsen.io/analyses
- AWS، Transactional Outbox Pattern: https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html

**تعیین تکلیف نهایی:** G09-A18 یک پرونده تحقیق مقایسه‌ای با پیشنهاد مشروط برای گام بعدی است. تمام خانواده‌های Candidate در وضعیت UNSELECTED / NOT QUALIFIED هستند. ADR-002 همچنان PROPOSED؛ OD-01 تا OD-12 باز؛ یافته‌های A11 باز؛ بازبینی مستقل A12 انجام‌نشده؛ R0 مسدود؛ R1 صرفاً تحقیق؛ R2 شروع‌نشده؛ R3 غیرمجاز؛ و Gateهای A4 تصویب‌نشده باقی می‌مانند.
