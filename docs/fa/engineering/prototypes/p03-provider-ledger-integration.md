# P-03D — اتصال Provider Inbox به ثبت مالی محصول‌محور و Outbox

**شناسه سند:** LOT-PROT-P03D-001 | **نسخه:** ۰.۳.۰ | **وضعیت:** Prototype یکپارچه‌سازی ساختگی؛ ۲۵ تست P-03D و ۱۵ تست P-03C موفق؛ بدون ادعای Production | **تاریخ بازبینی:** ۲۰۲۶-۱۱-۲۵

## هدف

P-03D شکاف ورودی باقی‌مانده در P-03 را می‌بندد و رویداد احرازشده Provider را به مرز ثبت مالی P-02 و پل Outbox تراکنشی P-03C متصل می‌کند. این آزمایش بر Ancestry فعلی P-02/P-03C ساخته شده است، نه شاخه قدیمی P-02 که PR شماره ۴۱ بر مبنای آن ایجاد شده بود.

آزمایش باید اثبات کند پذیرش پایدار Provider، یک اثر مالی Idempotent، سند/سطرهای/Outbox تغییرناپذیر و وضعیت اولیه Delivery در P-03C همگی با هم Commit یا Rollback می‌شوند.

## محدوده

- پیکربندی مورداعتماد سمت سرور، Provider و Tenant و Product را به هم متصل می‌کند. فیلدهای Payload درخواست هرگز Tenant، Product یا حساب دفترکل را انتخاب نمی‌کنند.
- هویت Session دیتابیس هم Tenant و هم Product را تعیین می‌کند. RLS از توابع مبتنی بر `session_user` استفاده می‌کند؛ به Custom GUC قابل‌کنترل توسط Caller اعتماد نمی‌شود.
- HMAC-SHA-256 روی بایت‌های دقیق Raw Request، شناسه و Timestamp امضاشده، مقایسه Constant-time، Base64 Canonical، پنجره تازگی محدود، محدودیت اندازه Header/Body و چرخش کلید فعلی/قبلی را بررسی می‌کند. این فقط Adapter ساختگی به سبک Standard Webhooks است، نه پروتکل عمومی همه Providerها.
- شناسه Provider Event همراه SHA-256 بدنه خام، مبنای Duplicate/Conflict در Inbox است. شناسه یکسان و Hash یکسان Idempotent است؛ شناسه یکسان با بدنه متفاوت، مدرک تعارض تغییرناپذیر ایجاد می‌کند و رویداد پذیرفته‌شده را بازنویسی نمی‌کند.
- پاسخ شبیه‌سازی‌شده HTTP 202 فقط پس از Commit تراکنش Inbox با Scope Tenant/Product برگردانده می‌شود.
- نگاشت Provider Event از پیکربندی مورداعتماد انجام می‌شود. Payload Provider نمی‌تواند شناسه حساب، جهت Debit/Credit یا Policy ثبت مالی را تعیین کند.
- Lease محدود Worker و Fencing Token از پردازش هم‌زمان و Worker منقضی‌شده محافظت می‌کنند؛ Constraintهای دیتابیس Markerهای پردازش و سقف Attempt را سازگار نگه می‌دارند.
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
| P03D-19 | وضعیت Processed ناقص یا Attempt Count بیش از حد | رد در سطح Constraint دیتابیس |

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

Head دقیق فعلی PR که اعتبارسنجی شد: `14d69ec5be1a9285049c1f88529f375782f2de51`.

- P-02 Ledger Posting: [اجرای ۱۳۵](https://github.com/tecpey/lottorito-platform/actions/runs/45619908420) — ۲۵ موفق، صفر شکست و صفر Skip.
- Integration ترکیبی P-03C/P-03D: [اجرای ۵۷](https://github.com/tecpey/lottorito-platform/actions/runs/45619908381) — تعداد ۱۵ تست موفق برای P-03C و ۲۲ تست موفق برای P-03D؛ در مجموع ۳۷ تست، صفر شکست و صفر Skip. تمام مراحل Setup، تست و Cleanup موفق بودند.
- Documentation Governance: [اجرای ۷۲۵](https://github.com/tecpey/lottorito-platform/actions/runs/45619908378) — موفق.

این نتیجه فقط ماتریس پذیرش ساختگی را روی Head شاخه ذکرشده راستی‌آزمایی می‌کند. PR شماره ۶۱ همچنان Draft و باز و وابسته به PR شماره ۶۰ است؛ هیچ Merge، اتصال Provider عملیاتی، Migration دیتابیس Production، تصویب فناوری یا Deploy از آن نتیجه نمی‌شود.

## Regression هم‌زمانی و Scopeهای مستقل در P-09F (۲۰۲۶-۱۱-۲۵)

روی Head کاندید 2b393cc8c41226a20333f34559ac6952883901a3، Workflow مربوط به P-03C/P-03D با شناسه [45637659485](https://github.com/tecpey/lottorito-platform/actions/runs/45637659485) موفق شد: P-03C با **۱۵ از ۱۵** و P-03D با **۲۵ از ۲۵** تست. سه تست افزوده‌شده Worker واقعی Provider با Node.js را روی PostgreSQL 18.7 اجرا می‌کنند: Claim و Process هم‌زمان Inbox با یک برنده؛ Fencing Token مربوط به Lease قدیمی/جدید در پردازش هم‌زمان؛ و پردازش مستقل Provider Event ID/Source Event UUID یکسان بین Affiliate، Lottery و Tenant دوم. هر Scope دقیقاً یک Journal، Outbox Event تغییرناپذیر و Delivery State ایجاد می‌کند و Reconciliation صفر است. این فقط شواهد یکپارچه‌سازی ساختگی است؛ ترتیب Aggregate و Replay Worker روی Cluster بازیابی‌شده P-09E همچنان باز هستند.


### P-09H — اعمال قرارداد Canonical (۲۰۲۶-۱۱-۲۵)

مسیر Ingress امضاشده اکنون CloudEvent استاندارد را فقط از Installation مورد اعتماد و Event Mapping تأییدشده می‌سازد. Tenant/Product از فیلدهای Payload ارسالی Provider پذیرفته نمی‌شوند. شناسه Provider به‌عنوان CloudEvents `id` حفظ می‌شود؛ UUID مستقل `sourceeventid` تولید و هم در Envelope و هم در Inbox ذخیره می‌شود و Trace Context جدید W3C نیز ساخته می‌شود. Schema Mapping ناشناخته و Timestamp غیرمنطبق با RFC 3339 پیش از ثبت در Inbox رد می‌شوند. Worker پیش از Posting، Envelope ذخیره‌شده و تطابق هویت Tenant/Product/Source Event را دوباره اعتبارسنجی می‌کند؛ Scope دست‌کاری‌شده پیش از ایجاد Journal/Outbox به قرنطینه می‌رود. این‌ها شواهد یکپارچه‌سازی ساختگی‌اند و پذیرش نهایی P-03D به CI روی Head نهایی وابسته است.


تست‌های Regression مربوط به Ingress در P-09H اکنون ثابت می‌کنند که `tenantid`، `scope`، `sourceeventid`، `traceparent`، `dataschema` و `schemaversion` ارسالی Provider نمی‌توانند Metadata مورد اعتماد را بازنویسی کنند؛ همچنین یک Provider Event ID یکسان می‌تواند مستقل از طریق Ingress امضاشده در Affiliate/Tenant-A، Lottery/Tenant-A و Affiliate/Tenant-B پذیرفته شود. هر سه ردیف Source Event UUID مستقل دارند. Workflow مربوط به P-03C/P-03D روی Head حاوی این کد به‌ترتیب موفقیت ۱۵ از ۱۵ و ۳۵ از ۳۵ تست را گزارش کرد؛ شمارش P-03D شامل هفت تست مستقیم انطباق قرارداد در Node.js نیز هست.


Runner تست P-03D اکنون مجموعه تست مستقیم انطباق Node.js برای Validator مشترک P-09 را نیز اجرا می‌کند. این تست‌ها حالت‌های معتبر و خصمانه Envelope را مستقل از تست‌های Ingress متصل به PostgreSQL بررسی می‌کنند تا تغییرات آینده Worker نتوانند بی‌صدا قواعد اصلی Validator را دور بزنند.

## P-09K — ارجاع حساب و Outbox با Scope محصول (۲۰۲۶-۱۱-۲۶)

در P-03D عمداً همان UUID حساب‌ها برای همان Tenant در Affiliate & Agent و Lottery دوباره استفاده می‌شود. کلید مرکب P-02 یعنی `(tenant_id, product_id, account_id)` این شناسه‌ها را مستقل نگه می‌دارد؛ تابع Posting و Foreign Keyهای حساب نیز Scope محصول را در تمام مسیر حفظ می‌کنند. Integration مربوط به Provider در Lottery باید با همین شناسه‌های تکرارشده با موفقیت Posting کند، بدون آنکه ردیف‌های حساب Affiliate را ببیند یا تغییر دهد. P-03D همچنین Unique Index تکراری Journal را که Primary Key مرکب P-02 از قبل تضمین می‌کند حذف کرده و مقدار Legacy یعنی `shared` را در وضعیت Inbox/Conflict/Expectation مربوط به Provider رد می‌کند. CI روی Head دقیق در انتظار اعتبارسنجی است.

**شواهد CI مربوط به P-09K:** [اجرای 45862006903](https://github.com/tecpey/lottorito-platform/actions/runs/45862006903) — موفق؛ P-03C برابر ۱۶ از ۱۶ و P-03D برابر ۳۵ از ۳۵ تست Integration. Posting مربوط به Lottery با استفاده عمدی از همان UUID حساب‌های Affiliate و در عین حال با هویت محصولی مستقل با موفقیت انجام می‌شود. Head دقیق کد: `75148b41220bb26adf0e8c01e05860a8fd83d7fa`.

## به‌روزرسانی اعتبارسنجی P-09K روی Head دقیق (۲۰۲۶-۱۱-۲۶)

کلیدهای محصول‌محور حساب، Journal و Outbox در P-02 از مسیر Ingress و Posting مربوط به Provider در P-03D نیز اعتبارسنجی شدند. [Workflow شماره 45863298594](https://github.com/tecpey/lottorito-platform/actions/runs/45863298594) روی Head دقیق `75fd23701d4e28f047f8ebb73ea0b684bb144c7a` تمام ۳۵ از ۳۵ تست Integration با PostgreSQL 18.7 و Node.js را گذراند؛ از جمله استفاده مجدد UUID حساب‌ها بین Affiliate و Lottery بدون خواندن یا نوشتن بین‌محصولی.

## اعتبارسنجی نهایی P-09L روی Head دقیق (۲۰۲۶-۱۱-۲۶)

Ingress و Posting مربوط به Provider در P-03D روی Head دقیق کد `7cb0598a163f40e53a4412a44b476b0404685b75` با موفقیت ۳۵ از ۳۵ تست را گذراند: [Workflow شماره 45864973911](https://github.com/tecpey/lottorito-platform/actions/runs/45864973911). این اجرا استفاده مجدد UUID حساب‌ها بین محصولات را در حالی پوشش می‌دهد که ارجاع‌های Journal/Account و وضعیت Provider Inbox همچنان محصول‌محور باقی می‌مانند.
