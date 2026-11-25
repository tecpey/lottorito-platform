# P-03D — اتصال Provider Inbox به ثبت مالی محصول‌محور و Outbox

**شناسه سند:** LOT-PROT-P03D-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** Prototype یکپارچه‌سازی ساختگی؛ اعتبارسنجی CI در انتظار اجرا | **تاریخ بازبینی:** ۲۰۲۶-۱۱-۲۵

## هدف

P-03D شکاف ورودی باقی‌مانده در P-03 را می‌بندد و رویداد احرازشده Provider را به مرز ثبت مالی P-02 و پل Outbox تراکنشی P-03C متصل می‌کند. این آزمایش بر Ancestry فعلی P-02/P-03C ساخته شده است، نه شاخه قدیمی P-02 که PR شماره ۴۱ بر مبنای آن ایجاد شده بود.

آزمایش باید اثبات کند پذیرش پایدار Provider، یک اثر مالی Idempotent، سند/سطرهای/Outbox تغییرناپذیر و وضعیت اولیه Delivery در P-03C همگی با هم Commit یا Rollback می‌شوند.

## محدوده

- پیکربندی مورداعتماد سمت سرور، Provider و Tenant و Product را به هم متصل می‌کند. فیلدهای Payload درخواست هرگز Tenant، Product یا حساب دفترکل را انتخاب نمی‌کنند.
- هویت Session دیتابیس هم Tenant و هم Product را تعیین می‌کند. RLS از توابع مبتنی بر `session_user` استفاده می‌کند؛ به Custom GUC قابل‌کنترل توسط Caller اعتماد نمی‌شود.
- HMAC-SHA-256 روی بایت‌های دقیق Raw Request، شناسه و Timestamp امضاشده، مقایسه Constant-time، پنجره تازگی محدود و چرخش کلید فعلی/قبلی را بررسی می‌کند. این فقط Adapter ساختگی به سبک Standard Webhooks است، نه پروتکل عمومی همه Providerها.
- شناسه Provider Event همراه SHA-256 بدنه خام، مبنای Duplicate/Conflict در Inbox است. شناسه یکسان و Hash یکسان Idempotent است؛ شناسه یکسان با بدنه متفاوت، مدرک تعارض تغییرناپذیر ایجاد می‌کند و رویداد پذیرفته‌شده را بازنویسی نمی‌کند.
- پاسخ شبیه‌سازی‌شده HTTP 202 فقط پس از Commit تراکنش Inbox با Scope Tenant/Product برگردانده می‌شود.
- نگاشت Provider Event از پیکربندی مورداعتماد انجام می‌شود. Payload Provider نمی‌تواند شناسه حساب، جهت Debit/Credit یا Policy ثبت مالی را تعیین کند.
- Lease محدود Worker و Fencing Token از پردازش هم‌زمان و Worker منقضی‌شده محافظت می‌کنند.
- Worker، تابع `post_journal` در P-02 را روی همان Connection/Transactionای فراخوانی می‌کند که Inbox را Processed می‌کند. P-02 سند، سطرها و Ledger Outbox تغییرناپذیر را درج می‌کند؛ Trigger مربوط به P-03C وضعیت Delivery را در همان تراکنش می‌سازد.
- شکست پیش از Commit باید تکمیل Inbox، سند، سطرها، Outbox و وضعیت Delivery را Rollback کند. وضعیت Retry/Dead-letter/Quarantine پس از Rollback و با Fencing جداگانه ثبت می‌شود.
- Product ID در ردیف‌های دفترکل P-02 و ردیف‌های Delivery/Consumer در P-03C ثبت و با RLS اعمال می‌شود. یک Role ساختگی برای Product دوم اثبات می‌کند داده Affiliate & Agent و Lottery یک Tenant برای یکدیگر قابل مشاهده نیست.
- Reconciliation رویدادهای موردانتظار مستقل را با وضعیت Inbox، سند، Outbox و Delivery مقایسه می‌کند.

## مرز تراکنش

۱. امضا و تازگی را روی بایت‌های دقیق Raw بررسی کن.
۲. Installation مورداعتماد را Resolve کن و تطبیق Role دیتابیس با همان Tenant/Product را اثبات کن.
۳. رکورد پایدار Inbox را Commit کن؛ فقط پس از آن پاسخ شبیه‌سازی‌شده 202 بده.
۴. ردیف Inbox را با `FOR UPDATE SKIP LOCKED`، Lease محدود و Fencing Token جدید Claim کن.
۵. در یک تراکنش پردازش: Claim را اعتبارسنجی کن، Event canonical را با Account Mapping مورداعتماد نگاشت کن، `post_journal` در P-02 را فراخوانی کن، Inbox را Processed کن و Commit کن.
۶. Trigger پس از Insert در P-03C، وضعیت Delivery را از Ledger Outbox تغییرناپذیر در همان تراکنش می‌سازد.
۷. تراکنش شکست‌خورده به‌طور کامل Rollback می‌شود؛ سپس Inbox هنوز Claimشده با Fencing معتبر به Retry/Dead-letter/Quarantine منتقل می‌شود.

قرارداد تحویل همچنان At-least-once است. هویت اثر مالی Idempotent و Inbox مصرف‌کننده از اثر تکراری محافظت می‌کنند؛ این آزمایش ادعای تحویل شبکه‌ای Exactly-once ندارد.

## مرز Product و هویت

Role Map ساختگی P-02 اکنون هر Role از نوع Database LOGIN را به Tenant و Product متصل می‌کند. فیلد Product دفترکل با RLS و تابع Posting بررسی می‌شود و حساب انتخاب‌شده باید متعلق به Product جاری باشد. وضعیت Delivery و Inbox/Effects مصرف‌کننده در P-03C نیز همین بُعد Product را نگه می‌دارند.

برای سازگاری محافظه‌کارانه، برخی Constraintهای یکتایی موجود P-02 همچنان در سطح Tenant هستند، نه Product. این محدودیت سخت‌گیرانه‌تر است؛ ممکن است استفاده مستقل از یک شناسه در دو Product را رد کند، اما دسترسی بین Productها را مجاز نمی‌کند. معنای کلیدهای مرکب و کاملاً Product-scoped نیازمند بازبینی بعدی است؛ این Prototype هیچ Schema عملیاتی را تصویب نمی‌کند.

## ماتریس پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| P03D-01 | امضای معتبر Raw Body | Commit پایدار Inbox پیش از پاسخ شبیه‌سازی‌شده 202 |
| P03D-02 | دستکاری Raw Body | رد؛ بدون ردیف Inbox |
| P03D-03 | Timestamp قدیمی/آینده | رد |
| P03D-04 | چرخش کلید فعلی/قبلی | فقط کلیدهای پیکربندی‌شده پذیرفته شوند |
| P03D-05 | شناسه Event و بدنه یکسان | Duplicate به‌شکل Idempotent |
| P03D-06 | شناسه یکسان با بدنه متفاوت | Conflict تغییرناپذیر؛ حفظ رکورد اصلی |
| P03D-07 | Tenant/Product ارسالی Caller | نادیده گرفته شود؛ Installation و هویت دیتابیس مرجع باشند |
| P03D-08 | RLS Tenant/Product | عدم مشاهده Inbox سایر Tenantها و Productها |
| P03D-09 | پردازش موفق | یک Journal، یک Outbox Event و یک Delivery State |
| P03D-10 | شکست پیش از Commit | Rollback همه آثار Posting/Outbox و باقی‌ماندن Inbox در وضعیت Retry |
| P03D-11 | Duplicate پس از پردازش | بدون Journal یا Outbox دوم |
| P03D-12 | انقضای Lease | Claim با Token جدید؛ Fencing Worker قدیمی |
| P03D-13 | اتمام Retry | انتقال به Dead-letter |
| P03D-14 | Event بدون Mapping | Quarantine؛ بدون Posting |
| P03D-15 | Account Mapping محصولی | Posting Lottery نتواند از حساب Affiliate & Agent استفاده کند |
| P03D-16 | تغییر مستقیم Ledger | رد Role عملیاتی |
| P03D-17 | Reconciliation | رویداد مفقود آشکار و مسیر کامل از فهرست استثنا خارج شود |
| P03D-18 | هویت دیتابیس بدون Mapping | رد امن Posting |

## CI و بازتولید

Workflow اختصاصی از PostgreSQL 18.7، Node.js 26.13.0، Lockfile ثبت‌شده npm و GitHub Actions دارای SHA ثابت استفاده می‌کند. Workflowهای P-02 و P-03C نیز دوباره اجرا می‌شوند؛ چون Schema/Functionهای آن‌ها در شاخه یکپارچه‌سازی توسعه یافته‌اند.

اجرای محلی فقط باید از دیتابیس موقت موجود در `compose.yaml` استفاده کند. اسکریپت Setup، Schema مربوط به P-02، SQL یکپارچه‌سازی P-03C و Schema مربوط به P-03D را به‌ترتیب اعمال می‌کند. این Setup نسبت به دیتابیس هدف مخرب است؛ هرگز آن را به دیتابیس مشترک، Staging یا Production متصل نکن.

## محدودیت‌های صریح

- فقط هویت، کلید امضا، رویداد Provider، Account Mapping و مبلغ ساختگی.
- بدون HTTP Server واقعی، API Gateway، WAF، قرارداد Provider، Sandbox شریک، انتقال شبکه خارجی، Broker، KMS/Secret Manager، mTLS، کنترل SSRF مقصد یا چرخش کلید عملیاتی.
- بدون قاعده واقعی Commission، NGR، سلسله‌مراتب Affiliate، بلیت Lottery، Payout، نگهداری وجه، FX، شناسایی درآمد یا حسابداری قانونی.
- فیلدهای Product و Role Mapping در P-02 آزمایشی‌اند. کلیدهای یکتای Tenant-wide فعلی محافظه‌کارانه باقی مانده‌اند؛ کلید مرکب Product-local و سیاست Migration فیزیکی نیازمند بازبینی مستقل‌اند.
- هیچ ادعایی درباره Load، Chaos، Failover، PITR، Disaster Recovery، تطبیق صورت‌حساب Provider یا آمادگی Production وجود ندارد.
- سبز شدن CI فقط همین سناریوهای ساختگی را اثبات می‌کند؛ به معنی تکمیل تمام معیارهای P-03 یا تصویب Provider، دیتابیس، Stack، Merge یا Deploy نیست.

## مبنای تحقیق

- OWASP — [Webhook Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Webhook_Security_Cheat_Sheet.html).
- Standard Webhooks — [مشخصات امضای Webhook](https://github.com/standard-webhooks/standard-webhooks/blob/main/spec/standard-webhooks.md).
- IETF — [RFC 9421 HTTP Message Signatures](https://www.rfc-editor.org/rfc/rfc9421.html)؛ این Prototype ادعای انطباق با RFC 9421 ندارد.
- CloudEvents — [مشخصات Core](https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md).
- AWS Prescriptive Guidance — [الگوی Transactional Outbox](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html).
- PostgreSQL 18 — [Row Security Policies](https://www.postgresql.org/docs/18/ddl-rowsecurity.html) و [SELECT Locking Clause](https://www.postgresql.org/docs/18/sql-select.html).

## شاخه و اختیار

این یک شاخه آزمایشی Draft بر مبنای Head مربوط به PR شماره ۶۰ در P-03C یعنی `32b34f4c7c67b12874cdf6a14a2788d9a2f4c6dc` است. PR شماره ۴۱ یک Fixture قدیمی Provider Delivery بر مبنای شاخه قدیمی P-02 است؛ منطق Raw-body Verification و Duplicate/Conflict آن فقط ورودی تحقیق است و نباید بدون مدل هویت Session و Product Scope فعلی Cherry-pick شود. هیچ PRی Merge نشده و هیچ Deploy یا عملیات مخرب Production مجاز نیست.


## تحلیل شکست CI و دور اصلاحی — ۲۰۲۶-۱۱-۲۵

اولین اجرای CI ترکیبی، پیش از رسیدن به فایل تست اختصاصی P-03D، سه مشکل در Setup و قراردادها را آشکار کرد:

۱. Assertion امنیتی P-02 به‌جای جدول خصوصی نگاشت هویت، Helper از نوع SECURITY DEFINER را Query می‌کرد. اکنون تست، منع SELECT مستقیم از `private.tenant_role_map` را بررسی می‌کند که همان شیء محافظت‌شده است؛ Helper برای Policyهای RLS و مرزهای مورداعتماد SECURITY DEFINER در دسترس باقی می‌ماند.
۲. P-03C ایندکس یکتای مرکب روی `ledger_outbox(tenant_id, product_id, event_id)` را پس از تعریف Foreign Keyهایی می‌ساخت که به آن ارجاع می‌دهند. اکنون ایندکس پیش از جدول‌های ارجاع‌دهنده ساخته می‌شود.
۳. Schema مربوط به P-03D دارای CHECK ناقص برای شناسه Provider Event و انتهای تکراری SQL بود. Schema اکنون یک تعریف کامل دارد، Constraint شناسه از نظر نحوی کامل است و مجوز CREATE برای Role بدون LOGIN مربوط به Provider فقط هنگام تنظیم مالکیت اعطا و بلافاصله پس گرفته می‌شود.

مسیر Secret متنی نیز اکنون حداقل طول ۱۲۸ بیت را مانند ورودی‌های Buffer و `whsec_` اعمال می‌کند؛ یک تست Regression برای Secret کوتاه اضافه شده است.

**وضعیت اعتبارسنجی:** پذیرش ساختگی روی Head دقیق و اجراهای CI زیر راستی‌آزمایی شده است.

## نتیجه تأییدشده CI ساختگی — ۲۰۲۶-۱۱-۲۵

Head دقیق PR که اعتبارسنجی شد: `40d002a2af5875a6ead178604b90dc92aa678dc5`.

- P-02 Ledger Posting: [اجرای ۱۱۴](https://github.com/tecpey/lottorito-platform/actions/runs/45607187120) — ۲۵ موفق، صفر شکست و صفر Skip.
- Integration ترکیبی P-03C/P-03D: [اجرای ۳۱](https://github.com/tecpey/lottorito-platform/actions/runs/45607186885) — تعداد ۱۵ تست موفق برای P-03C و ۱۹ تست موفق برای P-03D؛ در مجموع ۳۴ تست، صفر شکست و صفر Skip. تمام مراحل Setup، تست و Cleanup موفق بودند.
- Documentation Governance: [اجرای ۷۰۲](https://github.com/tecpey/lottorito-platform/actions/runs/45607186745) — موفق.

این نتیجه فقط ماتریس پذیرش ساختگی را روی Head شاخه ذکرشده راستی‌آزمایی می‌کند. PR شماره ۶۱ همچنان Draft و باز و وابسته به PR شماره ۶۰ است؛ هیچ Merge، اتصال Provider عملیاتی، Migration دیتابیس Production، تصویب فناوری یا Deploy از آن نتیجه نمی‌شود.



## تحویل به زنجیره پایین‌دستی — ۲۰۲۶-۱۱-۲۵

PR شماره ۵۱ در P-04 شاخه‌ای هم‌سطح P-03C/P-03D بود، نه فرزند آن‌ها. فایل‌های اختصاصی P-04 به شاخه `spike/p04-schema-evolution-p03d` منتقل می‌شوند که بر مبنای Head همگام‌شده با مستندات PR شماره ۶۱ در P-03D یعنی `11f2069b537d4cf74175fd7b628a331650c45f52` ساخته شده است. P-04 مستقل از Schemaهای P-02/P-03 است، اما شاخه جدید باید پیش از پذیرش، Workflowهای P-02، P-03C/P-03D و P-04 را با هم دوباره اجرا کند. PR شماره ۵۱ به‌عنوان مرجع اصلی بازبینی دست‌نخورده باقی می‌ماند؛ هیچ Merge یا Retarget مجاز نیست.


## نتیجه Regression پایین‌دستی P-04 — ۲۰۲۶-۱۱-۲۵

ادامه P-04 اکنون از طریق PR شماره ۶۲ روی این شاخه P-03D قرار گرفته است. روی Head کد PR شماره ۶۲ با SHA `dca0762678ed45da122ba109276c54ce61ac0846`، اجرای ترکیبی P-03C/P-03D با شناسه [45608274098](https://github.com/tecpey/lottorito-platform/actions/runs/45608274098) تعداد ۱۵ تست P-03C و ۱۹ تست P-03D را گذراند (در مجموع ۳۴ تست؛ صفر شکست و صفر Skip). اجرای P-02 با شناسه [45608274029](https://github.com/tecpey/lottorito-platform/actions/runs/45608274029) تعداد ۲۵ تست، اجرای P-04 با شناسه [45608274118](https://github.com/tecpey/lottorito-platform/actions/runs/45608274118) تعداد ۷ تست را گذراند و Documentation Governance با شناسه [45608274060](https://github.com/tecpey/lottorito-platform/actions/runs/45608274060) موفق شد. این نتیجه Regression روی شاخه جدید را تأیید می‌کند؛ Prototype ساختگی را به آمادگی Production ارتقا نمی‌دهد.


## دروازه Regression پایین‌دستی P-05A — ۲۰۲۶-۱۱-۲۵

P-05A روی PR تطبیق‌یافته شماره ۶۲ در P-04 بازپخش می‌شود که فرزند این شاخه P-03D است. Workflow ترکیبی ۳۴ تستی P-03C/P-03D باید روی Head جایگزین P-05A دوباره اجرا شود تا حضور پل Ledger/Outbox/Provider اثبات شود. Fixture بازیابی دیتابیس در P-05A مستقل و ساختگی است و جایگزین پذیرش Provider Event یا Posting دفترکل نیست.


## نتیجه Regression تطبیق‌یافته P-05A — ۲۰۲۶-۱۱-۲۵

Regression ترکیبی P-03C/P-03D روی Head کد جایگزین P-05A با SHA 76650b0c799e2f2a5b2f3ae4831bb55d3a3811a6 موفق شد: [اجرای 45609220468](https://github.com/tecpey/lottorito-platform/actions/runs/45609220468)، P-03C برابر ۱۵/۱۵ و P-03D برابر ۱۹/۱۹؛ صفر شکست و صفر Skip. P-05A جایگزین یا تغییردهنده یکپارچه‌سازی Provider-to-Ledger نیست.


## دروازه Regression پایین‌دستی P-05B — ۲۰۲۶-۱۱-۲۵

Replay رویداد در P-05B یک Projection ساختگی برای بازیابی است، نه جایگزین Provider Inbox در P-03D یا وضعیت Delivery در P-03C. مجموعه ۳۴ تست P-03C/P-03D باید روی Head جایگزین P-05B دوباره اجرا شود تا پل Provider-to-Ledger و جداسازی Tenant/Product حفظ شوند.


## دروازه Regression پایین‌دستی P-05B — ۲۰۲۶-۱۱-۲۵

Replay رویداد در P-05B یک Projection ساختگی برای بازیابی است، نه جایگزین Provider Inbox در P-03D یا وضعیت Delivery در P-03C. مجموعه ۳۴ تست P-03C/P-03D باید روی Head جایگزین P-05B دوباره اجرا شود تا پل Provider-to-Ledger و جداسازی Tenant/Product حفظ شوند.


## نتیجه Regression تطبیق‌یافته P-05B — ۲۰۲۶-۱۱-۲۵

P-03C/P-03D روی Head مربوط به PR شماره ۶۴ با SHA bbad5969fc3c952ebafdaed3c8d2306dbd018ad4 موفق شدند: [اجرای 45611209613](https://github.com/tecpey/lottorito-platform/actions/runs/45611209613)، ۱۵ + ۱۹ تست موفق، بدون شکست و Skip. Replay بازیابی P-05B جایگزین Provider Inbox یا Delivery State نمی‌شود.


## دروازه Regression پایین‌دستی P-05C — ۲۰۲۶-۱۱-۲۵

P-05C یک آزمایش Failover مستقل و ساختگی PostgreSQL دوگرهی است. مجموعه ۳۴ تست P-03C/P-03D روی Head جایگزین دوباره اجرا شود تا پل Provider-to-Ledger و مرزهای Tenant/Product حفظ شوند؛ هیچ Provider واقعی یا اتصال Failover عملیاتی اضافه نمی‌شود.
