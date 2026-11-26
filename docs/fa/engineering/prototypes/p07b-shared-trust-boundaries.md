# P-07B — مالکیت پلتفرم مشترک و مرزهای اعتماد

**شناسه سند:** LOT-PROT-P07B-001 | **نسخه:** ۰.۲.۰ | **وضعیت:** Fixture ساختگی در CI روی Head شماره 42083a2 اعتبارسنجی شده است

## پرسش تصمیم

آیا قابلیت‌های مشترک پلتفرم می‌توانند تحت مالکیت صریح و مجوزهای حداقلی قرار بگیرند، به‌طوری‌که دسترسی مستقیم بین محصولات و مصرف رویداد بدون قرارداد، به‌صورت پیش‌فرض رد شود؟

P-07B دومین زیرمرحله اجرایی P-07 است:
- P-07A: ترکیب مستقل محصولات در Build و Runtime.
- **P-07B: مالکیت قابلیت‌های مشترک، مجوزدهی آگاه از Tenant و مرزهای اعتماد رویداد.**
- P-07C: چرخه عمر مستقل محصولات، پیکربندی، Migration و عملیات.

## طراحی مبتنی بر تحقیق

این Fixture میان Policy Decision Point (PDP) و Policy Enforcement Point (PEP) تفکیک ایجاد می‌کند. تصمیم بر اساس هویت سرویس، محدوده دسترسی سرویس به Tenant، Entitlement محصول در Tenant، مالک قابلیت، عملیات درخواستی و مجوز صریح مصرف‌کننده گرفته می‌شود. هویت ناشناخته، سیاست در دسترس‌نبودنی، قابلیت ناشناخته و مجوز ناموجود همگی Fail-Closed هستند.

این مدل آزمایشی با الهام از ABAC و بر اساس NIST SP 800-162/800-205 طراحی شده است. پروتکل OpenID AuthZEN پیاده‌سازی نشده و هیچ Vendor مجوزدهی انتخاب نشده است. مدل اعمال مجوز از راهنمای OWASP پیروی می‌کند: Deny by Default، حداقل دسترسی، اعمال سمت سرور در محل عملیات محافظت‌شده و ثبت تصمیم‌ها.

رویدادها از Envelope استاندارد CloudEvents 1.0 شامل id، source، specversion و type استفاده می‌کنند و Attribute استاندارد dataschema را نیز دارند. Fixture دو Extension محدود tenantid و classification اضافه می‌کند. مصرف‌کننده باید با قرارداد صریح Producer/Type/Schema منطبق باشد، در فهرست مصرف‌کنندگان مجاز قرار داشته باشد و برای Tenant رویداد هم Entitlement و هم Service Scope معتبر داشته باشد. Envelope معتبر CloudEvents به‌تنهایی مجوز دسترسی ایجاد نمی‌کند.

## مدل مالکیت و دسترسی

| قابلیت | مالک | Affiliate & Agent | Lottery |
|---|---|---|---|
| Identity | Platform Identity | resolve_subject | resolve_subject |
| Tenant | Platform Tenant | resolve_membership | resolve_membership |
| Finance | Platform Finance | post_journal | رد |
| Notifications | Platform Notifications | request_delivery | request_delivery |
| Audit | Platform Audit | append_event | append_event |
| Affiliate network | Affiliate & Agent | فقط منبع متعلق به خودش | رد |
| Lottery domain | Lottery | رد | فقط منبع متعلق به خودش |

Fixture مربوط به Tenant سه وضعیت ساختگی دارد:
- tenant-alpha: محصول Affiliate & Agent فعال و Lottery غیرفعال است.
- tenant-beta: هر دو محصول فعال‌اند و هر دو هویت سرویس برای آن Tenant محدوده دسترسی دارند.
- tenant-gamma: Entitlement هر دو محصول فعال است، اما هیچ‌یک از هویت‌های سرویس برای این Tenant محدوده دسترسی ندارد.

این طراحی عمداً Entitlement محصول را از مجوز دسترسی سرویس به Tenant جدا می‌کند. فعال‌بودن یک محصول برای Tenant به معنی دسترسی خودکار تمام هویت‌های سرویس به آن Tenant نیست.

## قرارداد رویداد بین محصولات

یک قرارداد صریح و **صرفاً آزمایشی** اجازه می‌دهد سیگنال ساختگی Affiliate & Agent توسط Lottery مصرف شود:
- محصول تولیدکننده: affiliate_agent.
- محصول مصرف‌کننده: lottery.
- نوع رویداد: com.lottorito.p07b.demo.signal.v1.
- URI اسکیمـا: urn:lottorito:schema:affiliate.demo.signal:1.
- طبقه‌بندی: دقیقاً internal.
- فیلد اجباری Payload: reference.
- Payload فاقد داده کسب‌وکار، مالی یا شخصی است.

این قرارداد فرضی فقط برای آزمایش مسیر مجاز مثبت وجود دارد. این قرارداد هیچ یکپارچگی Production بین Affiliate و Lottery را تصویب یا القا نمی‌کند. نبود قرارداد به معنی رد است.

## آزمایش‌ها و معیارهای قبولی

| شناسه | آزمایش | معیار Pass |
|---|---|---|
| P07B-01 | مجوز قابلیت مشترک | هر محصول فقط عملیات صریحاً مجاز قابلیت‌های پلتفرم را اجرا کند |
| P07B-02 | مالکیت قابلیت | مالک ناشناخته و قابلیت متعلق به محصول خواهر رد شود |
| P07B-03 | جداسازی منابع محصول | محصول نتواند مستقیماً به منبع متعلق به محصول خواهر دسترسی پیدا کند |
| P07B-04 | مجوز Tenant | هم محدوده دسترسی سرویس و هم Entitlement محصول لازم باشند |
| P07B-05 | Default Deny و Fail-Closed | هویت، قابلیت، عملیات ناشناخته یا سیاست در دسترس‌نبودنی رد شود |
| P07B-06 | اتصال اصالت Producer | Source رویداد با محصول هویت سرویس احراز‌شده تطبیق داشته باشد |
| P07B-07 | قرارداد صریح رویداد | نبود قرارداد یا مصرف‌کننده غیرمجاز رد شود؛ قرارداد آزمایشی فقط مصرف‌کننده نام‌برده را بپذیرد |
| P07B-08 | Schema و Classification | پروفایل CloudEvents، dataschema دقیق، فیلدهای اجباری و طبقه‌بندی قرارداد اعمال شوند |
| P07B-09 | حداقل‌سازی داده | کلیدهای حساس Payload و Extensionهای ثبت‌نشده رد شوند |
| P07B-10 | سلامت Audit | سوابق مجوزدهی فقط Metadata تصمیم را ثبت کنند، نه Credential یا محتوای Payload را |

CI در مسیر .github/workflows/p07b-shared-trust-boundaries.yml تعریف شده است. Pass فقط زمانی ثبت می‌شود که Integration و Documentation Governance روی Head دقیق PR کامل شده باشند.

## روش بازتولید

از ریشه مخزن:

~~~bash
python3 -m json.tool prototypes/p07-shared-trust-boundaries/registry/capabilities.json
python3 -m json.tool prototypes/p07-shared-trust-boundaries/registry/tenant-entitlements.json
python3 -m json.tool prototypes/p07-shared-trust-boundaries/registry/event-contracts.json
python3 -m compileall -q prototypes/p07-shared-trust-boundaries
python3 -m unittest discover -s prototypes/p07-shared-trust-boundaries/tests -v
~~~

## محدودیت‌های صریح

- فقط Fixture ساختگی است. Tokenهای سرویس، Credentialهای ثابت آزمایشی‌اند؛ احراز هویت رمزنگاری‌شده، OAuth/OIDC، Claim امضاشده، چرخش کلید یا Identity Provider Production وجود ندارد.
- PDP/PEP توابع محلی Python هستند، نه سرویس مجوزدهی مستقرشده. AuthZEN فقط مرجع طراحی است و پیاده‌سازی نشده است.
- Registry قابلیت و Entitlement، فایل JSON ثابت است و سیستم مدیریت سیاست مبتنی بر دیتابیس نیست.
- Event Dispatcher یک Broker نیست و تضمین تحویل، Retry، ترتیب، Replay Protection، Idempotency، رمزنگاری، امضا یا جداسازی مصرف‌کننده در Transport واقعی را اثبات نمی‌کند.
- اعتبارسنج CloudEvents محدود به پروفایل Fixture است و آزمون کامل انطباق CloudEvents یا JSON Schema نیست.
- بررسی کلیدهای حساس، Denylist آزمایشی است؛ DLP، طبقه‌بندی معنایی یا اثبات کشف تمام PII/Secretها نیست.
- فهرست Audit ساختگی، Immutable یا Tamper-evident نیست.
- PostgreSQL RLS، Database Grants، Object Storage، Cache، Search Index یا جداسازی داده واقعی بین Tenantها اثبات نشده است.
- رویداد آزمایشی Affiliate به Lottery مجوز یکپارچگی Production ایجاد نمی‌کند و مرز MVP را تغییر نمی‌دهد. Ticketing، Draw و Prize لاتاری همچنان خارج از محدوده‌اند.
- هیچ Vendor، موتور مجوزدهی، Event Broker، تفکیک Microservice، توپولوژی Database یا سیاست Production تصویب نشده است. Merge و Deploy انجام نمی‌شود.

## مراجع تحقیق

- NIST، [SP 800-162 — راهنمای ABAC](https://csrc.nist.gov/pubs/sp/800/162/upd2/final).
- NIST، [SP 800-205 — ویژگی‌ها در سامانه‌های کنترل دسترسی](https://csrc.nist.gov/pubs/sp/800/205/final).
- OWASP، [Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html) و [Authorization Patterns](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Patterns_Cheat_Sheet.html).
- OpenID Foundation، [AuthZEN Authorization API 1.0](https://openid.net/wg/authzen/specifications/).
- CNCF، [CloudEvents Specification 1.0.2](https://github.com/cloudevents/spec/tree/v1.0.2).
- Pact، [Contract Testing](https://docs.pact.io/).


## شواهد CI

- Integration با شناسه [45570485750](https://github.com/tecpey/lottorito-platform/actions/runs/45570055150): موفق روی Head شماره 78c69234؛ هر ۳۳ تست قبول شدند.
- اجرای Push با شناسه [45570199339](https://github.com/tecpey/lottorito-platform/actions/runs/45570037120): موفق.
- Documentation Governance با شناسه [45570485718](https://github.com/tecpey/lottorito-platform/actions/runs/45570055148): روی همان Head PR موفق.
- PR شماره [۵۷](https://github.com/tecpey/lottorito-platform/pull/57) همچنان Draft، باز و Mergeنشده است.

## الحاقیه P-09D — هویت Canonical رویداد و Trace Context (۲۰۲۶-۱۱-۲۵)

P-07B اکنون Envelope محصول‌محور هم‌راستا با ADR-009 را الزامی می‌کند: هویت Canonical و UUID برای Tenant، `scope={kind: product, id: source_product}` صریح، UUID استاندارد `sourceeventid`، `schemaversion` عدد صحیح مثبت و W3C Trace Context با فیلد `traceparent`. Registry قرارداد، Source Scope، Schema Version و فیلدهای ضروری Envelope را مقید می‌کند. خروجی Dispatch، Tuple استاندارد Source Event و Trace ID را برای نگاشت به Correlation در P-06 ارائه می‌دهد. Fixtureهای Tenant ساختگی از Label به UUID تبدیل شدند تا نوع هویت Tenant در P-02/P-03D/P-06/P-07B یکسان باشد. CI مربوط به P-07B با شناسه [45631269584](https://github.com/tecpey/lottorito-platform/actions/runs/45631269584) با **۴۲ تست از ۴۲ تست** موفق شد. رویدادهای فعلی P-07B که از Product تولید می‌شوند، فعلاً فقط Product Scope می‌پذیرند؛ رویدادهای Platform-originated توسعه‌ای مستقل با حاکمیت جداگانه خواهند بود.


### P-09H — اعمال قرارداد مشترک (۲۰۲۶-۱۱-۲۵)

Dispatch رویداد در P-07B اکنون پس از احراز هویت Principal و بررسی Tenant/Product Scope و کنترل‌های دقیق Deny موجود، Validator استاندارد Python در P-09 را اجرا می‌کند. به این ترتیب، Reasonهای قبلی P-07B برای موارد Authorization موجود حفظ می‌شوند و در عین حال دروازه مشترک انطباق CloudEvents، URI-reference و RFC 3339 نیز افزوده می‌شود. Fixture رویداد ساختگی اکنون ویژگی الزامی `time` را دارد. سیاست Runtime همچنان صرفاً Prototype است.


در P-09H یک تست Regression برای رد Timestamp غیرمنطبق با RFC 3339 به Dispatch افزوده شده است. P-07B Reasonهای تثبیت‌شده Deny برای هویت Producer، Tenant، Product Scope، Source Event UUID، Schema Version و Trace Context را حفظ می‌کند؛ Validator مشترک پس از این کنترل‌ها، دروازه انطباق Time/URI را اضافه می‌کند. مجموعه تست فعلی P-07B روی آخرین Head حاوی کد، موفقیت ۴۳ از ۴۳ تست را گزارش کرده است.
