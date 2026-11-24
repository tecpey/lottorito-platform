# قرارداد قابلیت‌های API دامنه Affiliate و Agent

**شناسه سند:** LOT-AFFILIATE-API-001 | **نسخه:** ۰.۱.۰ | **وضعیت:** قرارداد پیشنهادی API دامنه؛ نیازمند بازبینی مالک، محصول، مالی، حقوقی، امنیت و شریک

## ۱. هدف و اعتبار

این سند اولین فهرست قابلیت‌های API دامنه محصول برای زیرساخت Affiliate و Agent در Lottorito را تعریف می‌کند. قواعد مشترک API (LOT-API-001 و LOT-API-PLATFORM-001) را به قراردادی مستقل از Provider و ایزوله در سطح Tenant برای مدیریت Program، عملیات Affiliate/Agent، انتساب Referral، دریافت رویداد شریک، شفافیت کمیسیون و گزارش تبدیل می‌کند.

Affiliate & Agent در توالی موردنظر مالک، اولویت نخست تحویل است. این سند شریک را انتخاب یا تأیید نمی‌کند، نرخ تجاری کمیسیون تعیین نمی‌کند، شخصیت حقوقی یا بازار را تصویب نمی‌کند، نگهداری/پرداخت وجه را مجاز نمی‌کند و وجود Endpoint یا اتصال را اثبات نمی‌کند. LOT-INT-001 همچنان پیش‌نویسی مختصر است؛ اسناد API واقعی شریک، Sandbox، Credential، معنای Event و نگاشت فیلدها باید پیش از پیاده‌سازی Adapter دریافت و راستی‌آزمایی شوند.

این قرارداد مرز قابلیت API است، نه Schema دیتابیس. سرویس‌های دامنه مالک وضعیت و ناورداهای خود هستند. API Gateway، SDK، Adapter شریک و Dashboard نباید مستقل از دامنه، حقیقت مالی Canonical را محاسبه یا تغییر دهند.

## ۲. مرز محصول و مخاطبان API

دامنه Affiliate از Programهای مستقل B2B و شبکه‌های Affiliate/Agent پشتیبانی می‌کند. مخاطبان:
- مالک Tenant و مدیر مجاز Program.
- نقش‌های عملیات و انطباق Tenant.
- اعضای Affiliate/Agent در محدوده مجاز سازمان و سلسله‌مراتب خود.
- سامانه شریک/اپراتور بیرونی تأییدشده برای ارسال Event منبع یا درخواست گزارش مجاز.
- B2C اختصاصی Lottorito فقط در صورت تعریف جداگانه Entitlement مشتری برای Referral/Loyalty.

APIهای Affiliate به‌طور خودکار مجوز Lottery، Sportsbook، Casino، Live Casino، E-Gaming، نگهداری Wallet، اجرای Payment، تأیید Payout یا دسترسی بین Tenantها نمی‌دهند. کمیسیون Affiliate وجه نقد Wallet مشتری نیست. مشتری، Agent، Tenant، شخصیت حقوقی و شریک هویت‌ها و Scopeهای مالکیت جداگانه‌اند.

مخاطبان API باید تفکیک شوند:
۱. API مدیریت Tenant: پیکربندی Program، عضویت و گزارش مجاز.
۲. API Self-service Affiliate/Agent: پروفایل خود، لینک‌ها، شبکه محدود و صورت‌حساب.
۳. API دریافت Event شریک: رویدادهای منبع با احراز هویت Server-to-server.
۴. API داخلی دامنه: عملیات فقط با Workload Identity بین Bounded Contextها.
۵. API Control Plane پلتفرم: مدیریت Application، Entitlement، Credential و Webhook طبق LOT-API-PLATFORM-001.

## ۳. مالکیت دامنه و مرز Source of Truth

| قابلیت | مالک معتبر | مسئولیت API Affiliate |
|---|---|---|
| Tenant، Principal، Membership، Role | دامنه Identity/Tenant | حل و اعمال Context مجاز؛ عدم تکثیر حقیقت هویت |
| Program و شرایط تجاری | دامنه Affiliate / قرارداد مصوب | پیکربندی نسخه‌بندی‌شده و Read Model |
| پروفایل Affiliate/Agent و سلسله‌مراتب | دامنه Affiliate | عملیات محدود پروفایل و رابطه |
| Click/Referral Tracking | دامنه Attribution | صدور لینک/Token و نمایش نتیجه قابل‌انتساب |
| فعالیت شریک | Adapter شریک + دریافت Event Canonical | احراز، اعتبارسنجی، نرمال‌سازی، Deduplicate و ردیابی واقعیت منبع |
| محاسبه کمیسیون | دامنه Commission | درخواست/مشاهده محاسبه و توضیح؛ بدون محاسبه مجدد در Client |
| موجودی Wallet و دفترکل | دامنه Finance/Wallet | فقط Read View مجاز از مسیر قرارداد Wallet |
| Payment و Settlement | دامنه‌های Payment/Finance | ارجاع به واقعیت پرداخت تأییدشده؛ عدم استنتاج از Redirect یا ادعای شریک |
| Payout و Beneficiary | دامنه Payout | ارجاع به وضعیت مصوب از قرارداد Payout؛ بدون پرداخت مستقیم |
| Chat و Notification | دامنه ارتباط | پیوند به پشتیبانی/ترجیحات؛ بدون تغییر وضعیت دامنه |

Event شریک یک ادعای منبع است، نه خودکار یک واقعیت مالی تأییدشده. ثبت‌نام، واریز، برداشت، فعالیت واجد شرایط یا اصلاح NGR باید پیش از استفاده پایین‌دستی با قرارداد شریک، نگاشت Tenant، Provenance، هویت Idempotency، ارز و قاعده تجاری قابل‌اعمال اعتبارسنجی شود.

## ۴. فهرست Resource و سطح پیشنهادی API

مسیرهای زیر نمونه پیشنهادی بر اساس قرارداد مشترک /v1 هستند؛ Endpoint منتشرشده یا فهرست نهایی URL نیستند. Schema، فیلد، Filter، Scope و انتقال وضعیت دقیق نیازمند بازبینی مالک دامنه است.

| خانواده Resource | عملیات پیشنهادی | مخاطب | مرز |
|---|---|---|---|
| Programها | GET/POST /v1/affiliate/programs؛ GET/PATCH /v1/affiliate/programs/{program_id} | مدیر Tenant | ایجاد/ویرایش نیازمند Scope مدیر، تاریخ اعتبار و Audit |
| نسخه Program | GET/POST /v1/affiliate/programs/{program_id}/versions | مدیر Tenant/مالی | نسخه منتشرشده Immutable؛ تغییر با نسخه جدید و تاریخ‌دار |
| Membership | GET/POST /v1/affiliate/memberships؛ GET/PATCH /v1/affiliate/memberships/{membership_id} | مدیر Tenant/Agent | دعوت، وضعیت و Role محدود به Tenant؛ بدون انتخاب مجوز توسط Client |
| پروفایل Affiliate | GET/PATCH /v1/affiliate/me؛ GET /v1/affiliate/affiliates/{affiliate_id} | Affiliate/Agent/مدیر | Self-service فقط رکورد خود؛ مشاهده مدیریتی نیازمند مجوز Scopeدار |
| سلسله‌مراتب Agent | GET /v1/affiliate/network؛ GET /v1/affiliate/network/{node_id}/children | Agent/مدیر | فقط Descendant و فیلدهای مجاز؛ عمق/صفحه محدود |
| Campaign | GET/POST /v1/affiliate/campaigns؛ GET/PATCH /v1/affiliate/campaigns/{campaign_id} | مدیر Tenant/Agent | Approval، وضعیت، تاریخ و کانال مجاز تحت Policy |
| Referral Link | GET/POST /v1/affiliate/referral-links؛ GET /v1/affiliate/referral-links/{link_id} | Affiliate/Agent | شناسه Opaque؛ Revocation و Expiry |
| Attribution | GET /v1/affiliate/attributions؛ GET /v1/affiliate/attributions/{attribution_id} | Affiliate/مدیر | توضیح وضعیت/منبع؛ بدون PII دیگران |
| دریافت Event شریک | POST /v1/partner-events/affiliate یا ورودی اختصاصی شریک | سامانه شریک تأییدشده | Machine Identity، Schema، Signature، Idempotency و Adapter مستقل |
| Activity | GET /v1/affiliate/activity؛ GET /v1/affiliate/activity/{activity_id} | Affiliate/مدیر | واقعیت نرمال‌شده با Provenance و وضعیت Pending/Verified/Rejected |
| خلاصه کمیسیون | GET /v1/affiliate/commissions/summary؛ GET /v1/affiliate/commissions/{commission_id} | Affiliate/مدیر | خروجی و توضیح محاسبه؛ نه موجودی قابل‌تغییر |
| صورت‌حساب کمیسیون | GET /v1/affiliate/statements؛ GET /v1/affiliate/statements/{statement_id} | Affiliate/مالی | دوره، ارز، نسخه قانون، وضعیت و تعدیلات |
| Calculation Run | POST /v1/affiliate/calculation-runs؛ GET /v1/affiliate/calculation-runs/{run_id} | مالی/عملیات مجاز | Async، Idempotent و تحت Approval؛ بدون فرمول سمت Client |
| تعدیلات | GET/POST /v1/affiliate/adjustments | مالی/انطباق | فقط پیشنهاد تعدیل؛ Maker-checker و دروازه دفترکل |
| گزارش | GET /v1/affiliate/reports/... | مدیر Tenant/Agent | گزارش از پیش تعریف‌شده و محدود؛ Export Async، محدود و Auditشده |

از /me فقط برای نمایش Scopeشده Membership فعلی Principal احرازشده استفاده شود. شناسه Affiliate ارسالی کاربر جایگزین مجوزدهی نیست. از مسیرهای بسیار تو‌در‌تو و Endpoint گراف عمومی بدون محدودیت پرهیز شود.

## ۵. معنای Program، Membership و سلسله‌مراتب

Program به Tenant، هدف محصول، توافق شریک، دوره اعتبار، ارز و نسخه Immutable متصل است. وضعیت‌های draft، review، approved، active، suspended و retired مستقل‌اند. نسخه منتشرشده درجا ویرایش نمی‌شود؛ اصلاح نسخه جدید می‌سازد و Reference محاسبات قبلی را حفظ می‌کند.

Membership از پروفایل Affiliate جداست. یک Principal ممکن است چند Membership داشته باشد، اما هر Membership یک Tenant، سازمان، صلاحیت Program و محدوده Role دارد. پذیرش دعوت، فعال‌سازی، تعلیق، خاتمه و بازفعال‌سازی به انتقال وضعیت صریح و Audit نیاز دارند.

سلسله‌مراتب یک گراف رابطه‌ای است، نه میانبر مجوزدهی. Agent فقط Node و فیلدهایی را می‌بیند که Policy مشاهده Program اجازه می‌دهد. عمق L1 تا L10 که ابتدا مطرح شده تصویب نشده است؛ حداکثر عمق، Cycle، تغییر والد، تاریخ اعتبار، Attribution تاریخی و تخصیص کمیسیون باز هستند. از Cycle و Re-parenting غیرمجاز جلوگیری شود. دوره‌های تاریخی باید Snapshot سلسله‌مراتب/Attribution استفاده‌شده در زمان محاسبه را حفظ کنند.

## ۶. Referral Link، رهگیری و Attribution

ایجاد Referral Link به Tenant، Program، Membership مربوط به Affiliate، Campaign، مقصد مجاز و Policy انقضا/ابطال متصل است. شناسه لینک Opaque و مقاوم در برابر Enumeration باشد. PII، نرخ کمیسیون، Secret Tenant یا هویت معتبر در URL قرار نگیرد.

Eventهای Tracking ممکن است Impression، Click، Landing، Registration و Qualified Conversion را شامل شوند؛ مشروط به Consent، حریم خصوصی، Fraud و قواعد حوزه قضایی. Click ثبت‌نام نیست؛ ثبت‌نام Deposit نیست؛ Deposit فعالیت واجد شرایط نیست؛ فعالیت واجد شرایط نیز خودکار کمیسیون پرداختنی نیست.

Policy انتساب باید Touchpoint واجد شرایط، Window، اولویت، مدل First/Last/Multi-touch، ترافیک مستقیم، Self-referral، هویت بین دستگاه، تغییر معرف، Conversion تکراری، Fraud، لغو Consent و رسیدگی اختلاف را تعریف کند. این سند هیچ مدل Attribution را انتخاب نمی‌کند.

تصمیم Attribution، نسخه Rule، شواهد منبع، Timestamp، وضعیت، Actor/Reason Override و هویت Conversion مرتبط ذخیره شوند. Override دستی نیازمند مجوز و Audit تغییرناپذیر است. Conversion گزارش‌شده توسط Client نمی‌تواند مستقیماً کمیسیون پرداختنی ایجاد کند.

## ۷. دریافت Event شریک و قرارداد Adapter

Integration شریک از Adapter و Credential اختصاصی طبق LOT-INT-001، LOT-API-001 و LOT-API-PLATFORM-001 استفاده می‌کند. Adapter Payload اختصاصی Provider را به واقعیت Canonical ترجمه می‌کند؛ صلاحیت تجاری را تعیین یا سطر دفترکل ثبت نمی‌کند.

خط لوله دریافت:
۱. احراز هویت شریک و بررسی Signature/mTLS یا سازوکار مصوب.
۲. اعمال اتصال Tenant، Partner، Product و Environment.
۳. اعتبارسنجی نسخه Schema، اندازه Payload، Timestamp، ارز و شناسه‌های ضروری.
۴. حفظ شواهد خام رمزگذاری‌شده طبق Retention و ثبت Provenance/Hash.
۵. نرمال‌سازی ID خارجی، نوع Event، مبلغ، ارز، Timezone و وضعیت بدون حذف مقادیر اصلی.
۶. Deduplicate با هویت پایدار Event منبع و Economic Effect؛ Delivery ID هویت اثر نیست.
۷. قرنطینه Event ناشناخته، خراب، متعارض، دیررس یا پشتیبانی‌نشده.
۸. انتشار Event Canonical از مسیر Inbox/Outbox پایدار فقط پس از پذیرش.
۹. تطبیق با گزارش/صورت‌حساب مستقل شریک و ثبت Exception.

انواع احتمالی Event: Registration، Deposit، Withdrawal، Qualified Activity، NGR Adjustment، Reversal، Account Restriction و Status Change. این‌ها صرفاً گزینه‌اند؛ وجود، معنا، فیلد لازم، قابلیت برگشت و ترتیب باید از قرارداد واقعی شریک راستی‌آزمایی شوند. اجزای NGR یا فعالیت واجد شرایط را از یک فیلد مبلغ عمومی استنباط نکنید.

## ۸. مرز API محاسبه کمیسیون و امور مالی

دامنه Commission مالک نسخه‌بندی Rule، محاسبه و توضیح است. ورودی‌ها شامل واقعیت واجد شرایط تأییدشده، توافق Program/Partner، Snapshot مؤثر سلسله‌مراتب و Attribution، ارز، استثناها، تعدیلات و نسخه Policy هستند. API وضعیت محاسبه و توضیح بازتولیدپذیر را ارائه می‌کند، نه محاسبه مجدد سمت Client.

CPA، Revenue Share و Hybrid مدل‌های مفهومی‌اند. هیچ فرمول جهانی NGR، نرخ ۲۰ تا ۴۰ درصد، سهم شبکه، عمق L1 تا L10، حداقل، سقف، Negative Carryover، ارتقای ماهانه یا اعتبار Agent تصویب نشده است. هر قاعده تجاری به توافق مصوب، تاریخ اعتبار، نسخه و پذیرش مالی/حقوقی نیاز دارد.

وضعیت‌های محاسبه باید requested، queued، processing، completed، completed_with_exceptions، failed، reviewed و approved را تفکیک کنند. تکمیل به‌معنای payable، posted، settled یا withdrawable نیست.

صورت‌حساب‌ها در صورت پشتیبانی باید estimated، pending، approved، payable، reserved، paid/settled، reversed و disputed را جدا کنند. بدون معنای صریح واحد/وضعیت، آن‌ها را در یک عدد کل ادغام نکنید.

تغییرات Wallet، Ledger، Payment و Payout در دامنه‌های خود باقی می‌مانند. APIهای Affiliate می‌توانند Reference/Read Model مجاز برگردانند، اما نباید:
- موجودی Wallet Agent را تعیین یا ویرایش کنند؛
- Journal دفترکل را مستقیم بسازند؛
- از Redirect مرورگر Deposit را Paid اعلام کنند؛
- صرفاً بر اساس Callback شریک کمیسیون را Paid کنند؛
- Beneficiary را تغییر دهند یا Payout را تأیید کنند؛
- ارزش را بین حساب مشتری، Agent، Promotion، جایزه یا خزانه منتقل کنند.

هر درخواست Payout آینده باید از گردش Eligibility، Reservation، Approval، اجرای Provider و Reconciliation در LOT-PAYOUT-001 استفاده کند.

## ۹. Scopeهای مجوزدهی و مشاهده داده

خانواده Scopeهای پیشنهادی (نام نهایی نیازمند بازبینی):
- affiliate.programs.read / affiliate.programs.manage
- affiliate.memberships.read / affiliate.memberships.manage
- affiliate.profile.read / affiliate.profile.write
- affiliate.network.read
- affiliate.campaigns.read / affiliate.campaigns.manage
- affiliate.links.read / affiliate.links.manage
- affiliate.attributions.read؛ affiliate.activity.read
- affiliate.commissions.read
- affiliate.calculations.request / affiliate.calculations.review
- affiliate.adjustments.propose / affiliate.adjustments.approve
- affiliate.reports.read / affiliate.reports.export
- partner.affiliate-events.write

Scope لازم است اما کافی نیست. هر Request همچنین Tenant، Application، Membership جاری، Role، دید سلسله‌مراتبی، مالکیت Object، Entitlement محصول، حوزه قضایی و وضعیت Resource را بررسی می‌کند. مجوز Read، Propose، Approve و Execute جدا باشد. در موارد Maker-checker، هیچ Actor نباید تعدیل مالی ممتاز خودش را تأیید کند.

کمینه‌سازی PII بر List، Search، Export و Payloadهای Webhook اعمال می‌شود. Self-service Affiliate هیچ سند هویتی، اطلاعات تماس، یادداشت خصوصی، Risk Flag یا فعالیت کامل مشتریان اعضای دیگر را برنمی‌گرداند، مگر هدف تجاری/حقوقی جداگانه‌ای تصویب شده باشد.

## ۱۰. Pagination، Filter، Export و Reporting

از Cursor Pagination، ترتیب قطعی و اندازه صفحه محدود استفاده شود. پیش از Filter/Pagination مجوز Scope شود. Filterها Allowlist داشته و با بازه زمانی، وضعیت و تعداد Resource محدود شوند. پیمایش نامحدود سلسله‌مراتب یا Query Expression دلخواه افشا نشود.

Export به Job غیرهم‌زمان با Scope، هدف، درخواست‌کننده، انقضا، Format، حد ردیف/اندازه و Audit نیاز دارد. URL دانلود کوتاه‌عمر و محدود به Object است. Export باید PII را Minimize کند و به‌طور پیش‌فرض Credential، Secret Provider یا Risk Annotation داخلی را شامل نشود.

گزارش باید Timezone، شمول دوره، ارز، واحد، وضعیت‌های شامل‌شده، نسخه Attribution/Rule و تازگی را تعریف کند. جمع خلاصه باید با سطرهای جزئیات طبق قواعد گردکردن/Filter مستند سازگار باشد. Report یک Read Model است، نه Posting مالی یا اثبات Settlement خارجی.

## ۱۱. Idempotency، هم‌زمانی و مدیریت خطا

دریافت Event شریک و عملیات تغییردهنده از Idempotency-Key Scopeدار، Hash Payload نرمال‌شده، Inbox پایدار و Economic-effect Identity استفاده می‌کنند. همان Key/Payload نتیجه قبلی یا وضعیت جاری را برمی‌گرداند؛ Key یکسان/Payload متفاوت Conflict است. Duplicate هم‌زمان به یک اثر پذیرفته‌شده همگرا می‌شود. Event دیررس و خارج از ترتیب از قواعد صریح دامنه پیروی می‌کند.

برای تغییر هم‌زمان Program، Campaign، Membership و Link از ETag/Version استفاده شود. Write قدیمی با شکست Precondition رد می‌شود. عملیات Async یک Resource وضعیت و Correlation ID برمی‌گردانند. خطاها از LOT-API-001 پیروی می‌کنند و وجود Resource در Tenant دیگر، Secret شریک یا جزئیات نگاشت داخلی را افشا نمی‌کنند.

## ۱۲. حریم خصوصی، امنیت، Fraud و Audit

- مجوزدهی Tenant و Object در سمت سرور برای هر Request و Background Job.
- Credential جدا بر اساس شخصیت حقوقی شریک، Tenant، Product، Application و Environment.
- اعتبارسنجی Signature، Timestamp، Replay، Schema و Provenance در Webhook.
- Rate Limit و تشخیص سوءاستفاده Credential، Click Fraud، Self-referral، Bot Traffic و الگوی غیرعادی Conversion.
- سیگنال IP/Device مدرک ریسک است، نه هویت قطعی یا تنها مبنای Attribution.
- اعمال Privacy/Consent و قواعد Cookie/Tracking بر اساس حوزه قضایی؛ پشتیبانی از استثنای Retention/حذف و Legal Hold.
- رمزگذاری داده حساس، محدودیت دسترسی Support و Mask کردن PII در Log/Export.
- Audit تغییرناپذیر برای انتشار Program/Rule، تغییر سلسله‌مراتب، Override دستی Attribution، تعدیل، تأیید، تغییر Credential و Export.
- Role، Tenant، Affiliate، نرخ کمیسیون یا وضعیت Payable ارائه‌شده توسط شریک هرگز مجوز پلتفرم یا قرارداد مصوب را Override نمی‌کند.

## ۱۳. سناریوهای پذیرش

| شناسه | سناریو | نتیجه مورد انتظار |
|---|---|---|
| AFF-API-01 | Agent پروفایل خود را می‌خواند | فقط فیلدهای Membership فعلی و مجاز برمی‌گردد |
| AFF-API-02 | Agent شناسه Affiliate دیگر را جایگزین می‌کند | رد یا پنهان‌سازی امن |
| AFF-API-03 | مدیر Tenant یک Program را مدیریت می‌کند | Tenant، Scope و Audit صحیح الزامی است |
| AFF-API-04 | Rule کمیسیون منتشرشده ویرایش می‌شود | رد؛ نسخه جدید لازم است |
| AFF-API-05 | والد سلسله‌مراتب تغییر می‌کند | کنترل Cycle/مجوز؛ حفظ Snapshot تاریخی |
| AFF-API-06 | Referral Link ایجاد می‌شود | اتصال به Tenant/Program/Campaign/Membership و قابلیت Revocation |
| AFF-API-07 | Click به‌عنوان Conversion گزارش می‌شود | بدون واقعیت Conversion تأییدشده کمیسیون واجد شرایط ایجاد نمی‌شود |
| AFF-API-08 | شریک Event تکراری با Delivery ID جدید می‌فرستد | فقط یک اثر اقتصادی Canonical |
| AFF-API-09 | Event شریک ارز ناشناخته یا مبلغ خراب دارد | قرنطینه/رد؛ هرگز تبدیل به صفر نمی‌شود |
| AFF-API-10 | Event شریک با هویت منبع قبلی تعارض دارد | Conflict برای Reconciliation حفظ می‌شود؛ بازنویسی بی‌صدا ممنوع |
| AFF-API-11 | Redirect مرورگر موفقیت Deposit را ادعا می‌کند | Credit مالی یا Posting کمیسیون انجام نمی‌شود |
| AFF-API-12 | محاسبه کمیسیون تکمیل می‌شود | به‌معنای Payable، Paid یا Withdrawable نیست |
| AFF-API-13 | Affiliate صورت‌حساب Agent دیگر را می‌خواهد | بر اساس Policy سلسله‌مراتب/Object رد می‌شود |
| AFF-API-14 | مالی تعدیل پیشنهاد می‌کند | Approval جدا و شواهد تغییرناپذیر لازم است |
| AFF-API-15 | Actor قصد تأیید خودش را دارد | در موارد Maker-checker رد می‌شود |
| AFF-API-16 | Report Export می‌شود | Scopeدار، Async، Auditشده، Minimize و Expire می‌شود |
| AFF-API-17 | Quota Tenant هنگام دریافت Event تمام می‌شود | پردازش پایدار کنترل‌شده یا رد صریح؛ بدون حذف بی‌صدای Event |
| AFF-API-18 | قرارداد API شریک تغییر می‌کند | تست سازگاری Adapter/Schema انتشار ناامن را متوقف می‌کند |

## ۱۴. تصمیم‌های باز، وابستگی‌ها و دروازه انتشار

تصمیم‌های باز:
- Program اولیه Affiliate و شریک/شخصیت حقوقی دقیق پایلوت.
- API واقعی شریک، کاتالوگ Event، معنای فیلد، Signature/Authentication و شواهد Sandbox.
- مالکیت Program و نقش‌های مدیر.
- مدل Attribution، مبنای Consent، Policy Fraud و پنجره اختلاف.
- عمق سلسله‌مراتب، Re-parenting، Snapshot تاریخی و Policy مشاهده.
- مدل کمیسیون تجاری، تعریف NGR، نرخ، سقف، Negative Carryover، ارز و گردکردن.
- کلاس Wallet Agent، تأمین، رفتار حسابداری و Policy اعتبار تبلیغاتی.
- صلاحیت Payout، ذی‌نفع، شخصیت حقوقی، حوزه قضایی و Rail پرداخت.
- Retention، Residency، فیلدهای PII و مجوز گزارش.
- API Scope، Schema Resource، Limit، زبان SDK و Support/SLA.

وابستگی‌ها: LOT-API-001؛ LOT-API-PLATFORM-001؛ LOT-EVENT-001؛ LOT-IAM-TENANT-001؛ LOT-INT-001؛ LOT-COM-001؛ LOT-WALLET-001؛ LOT-FIN-POST-001؛ LOT-PAYMENT-001؛ LOT-PAYOUT-001؛ LOT-PROVIDER-EVAL-001؛ LOT-QA-001؛ LOT-SEC-TM-001.

دروازه‌های انتشار پایلوت:
۱. دریافت قرارداد واقعی شریک، شخصیت حقوقی، حوزه قضایی، مستندات API و Sandbox مجاز.
۲. نگاشت هر Event/Field بیرونی به Schema Canonical همراه Provenance و Policy فیلد ناشناخته.
۳. تصویب نسخه Ruleهای Attribution و Commission؛ فرمول تجاری حل‌نشده غیرفعال بماند.
۴. اثبات جداسازی Tenant/Affiliate، دریافت Duplicate/هم‌زمان و رفتار Reconciliation با داده ساختگی.
۵. نمایش بازتولیدپذیری Statement و تفکیک محاسبه، ثبت دفترکل، Payment و Payout.
۶. تکمیل بازبینی امنیت، حریم خصوصی، Fraud، حقوقی، مالی و عملیات.
۷. تصویب Allowlist محدود Resource/Event و صدور مستقل Credentialهای Production.

این سند Proposed است. شریک انتخاب نمی‌کند، نرخ کمیسیون را تصویب نمی‌کند، Endpoint منتشر نمی‌کند، Adapter پیاده‌سازی نمی‌کند، Wallet ایجاد نمی‌کند، پرداخت واقعی انجام نمی‌دهد و Payout را مجاز نمی‌کند.
