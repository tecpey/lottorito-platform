# مستندات فارسی Lottorito

**شناسه سند:** LOT-DOC-INDEX-FA-001 | **نسخه:** ۲.۴.۰ | **وضعیت:** فهرست مرجع و در حال نگهداری

این پوشه مرجع رسمی مستندات فارسی Lottorito است. مستندات انگلیسی در docs/en/ نیز به همان اندازه معتبرند.

## جهت‌گیری محصول

جهت‌گیری راهبردی Lottorito ساخت زیرساختی جهانی، ماژولار، API-first و چندمستاجری با دو خانواده محصول مستقل و قابل‌استفاده جداگانه است:

۱. **زیرساخت Affiliate و Agent** — برنامه‌های همکاری با شرکا، شبکه‌های افیلیت و ایجنت، رهگیری کمپین، انتساب، سیاست کمیسیون، سوابق مالی، تطبیق و گزارش عملیاتی.
۲. **زیرساخت Lottery** — اتصال مستقل از ارائه‌دهنده و قابلیت‌های چرخه عمر برای کاتالوگ، بلیت، نتیجه، اعتبارسنجی، مطالبه، جایزه و تسویه؛ مشروط به دروازه‌های جداگانه محصول، حقوقی، ارائه‌دهنده و پیاده‌سازی.

زیرساخت مشترک می‌تواند شامل هویت و دسترسی، مدیریت Tenant، قرارداد API، Adapter شریک، پردازش رویداد، دفترکل و کنترل مالی، اعلان، ممیزی، گزارش و عملیات باشد. این متن جهت‌گیری راهبردی است، نه اثبات پیاده‌سازی یا مجوز انتشار.

## پوشش و بلوغ مستندات

LOT-PROD-001 و LOT-ARCH-001 پیش‌نویس‌های اولیه و عمدتاً Affiliateمحورند؛ PRD کامل بین‌محصولی یا معماری مصوب نیستند. LOT-LOTTERY-001 و LOT-LOTINT-001 پیشنهادهای کشف‌اند، نه اثبات سازگاری Provider یا مجوز راه‌اندازی. LOT-DOM-001، LOT-TEN-001 و LOT-EVENT-001 قراردادهای معماری پیشنهادی‌اند، نه Schema فیزیکی یا سرویس پیاده‌سازی‌شده.

LOT-FIN-POST-001 کنترل‌های پیشنهادی ثبت مالی و تطبیق را تعریف می‌کند؛ سیاست حسابداری یا مجوز نگهداری/پرداخت وجه نیست. LOT-SEC-TM-001 مدل تهدید پیشنهادی است، نه تست نفوذ یا گواهی امنیت. LOT-API-001 خط مبنای پیشنهادی قرارداد API است، نه API پیاده‌سازی یا منتشرشده. LOT-QA-001 سناریوهای کیفی قابل‌اندازه‌گیری و دروازه‌های انتشار پیشنهادی را تعریف می‌کند؛ آستانه‌ها تا زمان تصویب تعیین‌نشده‌اند. LOT-TECH-ADR-001 چارچوب پیشنهادی تصمیم فناوری، استقرار، قابلیت اطمینان، Observability و چرخه داده است؛ هیچ Stack یا Vendor تصویب نشده است. LOT-PROVIDER-EVAL-001 فرایند پیشنهادی مشترک شواهد، RFI، Due Diligence و تأیید Provider را تعریف می‌کند؛ هیچ Providerی انتخاب نشده است.

## نقشه مستندات

| حوزه | سند | کاربرد |
|---|---|---|
| محصول | [چشم‌انداز و PRD](product/vision-and-prd.md) | پیش‌نویس اولیه نیازمندی‌های Affiliate |
| محصول | [PRD محصول Lottery](product/lottery-prd.md) | خط مبنای پیشنهادی کشف Lottery |
| محصول | [واژه‌نامه](product/glossary.md) | اصطلاحات مشترک دامنه |
| معماری | [معماری کلان](architecture/system-architecture.md) | پیشنهاد اولیه معماری |
| معماری | [مدل دامنه و ERD منطقی](architecture/domain-model-and-erd.md) | مالکیت و روابط منطقی پیشنهادی؛ نه Schema فیزیکی |
| معماری | [مدل جداسازی Tenant](architecture/tenant-isolation-model.md) | هویت، انتشار Context و کنترل جداسازی پیشنهادی |
| معماری | [ADR فناوری، استقرار و قابلیت اطمینان](architecture/technology-deployment-adrs.md) | LOT-TECH-ADR-001؛ چارچوب تصمیم پیشنهادی، بدون تصویب Stack یا Provider |
| معماری | [ویژگی‌های کیفی معماری](architecture/quality-attributes.md) | LOT-QA-001؛ سناریوهای کیفی و دروازه انتشار پیشنهادی، آستانه‌ها تعیین‌نشده |
| کمیسیون | [موتور کمیسیون](commission/commission-engine.md) | مفاهیم کمیسیون و سیاست‌های باز |
| مالی | [کیف پول و دفترکل](finance/wallet-and-ledger.md) | اصول اولیه دفترکل و نگاشت‌های باز |
| مالی | [مدل ثبت مالی و تطبیق](finance/financial-posting-and-reconciliation.md) | LOT-FIN-POST-001؛ کنترل ثبت، وضعیت‌ها و تطبیق پیشنهادی |
| مالی | [قرارداد دامنه Wallet و معنای موجودی](finance/wallet-domain-contract.md) | LOT-WALLET-001؛ مالکیت، کلاس‌های Wallet، واحدهای نوع‌دار، Projection موجودی، Hold، انتقال و مرز دفترکل؛ بدون تصویب Custody/پرداخت/برداشت |
| مالی | [قرارداد Payout، برداشت و پرداخت خروجی](finance/payout-withdrawal-contract.md) | LOT-PAYOUT-001؛ برداشت مشتری، پرداخت کمیسیون/جایزه، Verification ذی‌نفع، تأییدها، Hold، اجرای Provider و تطبیق پیشنهادی؛ بدون مجوز پرداخت |
| شرکا | [قرارداد یکپارچه‌سازی Affiliate](partners/integration-contract.md) | LOT-INT-001؛ مرز اولیه Event/Adapter شریک؛ API و Sandbox واقعی شریک راستی‌آزمایی نشده |
| شرکا | [قرارداد قابلیت API دامنه Affiliate و Agent](partners/affiliate-agent-api-contract.md) | LOT-AFFILIATE-API-001؛ فهرست پیشنهادی API برای Program، Membership، سلسله‌مراتب، Campaign، Referral، Attribution، Event شریک، کمیسیون و گزارش |
| شرکا | [قرارداد ارائه‌دهنده Lottery](partners/lottery-provider-contract.md) | چرخه عمر پیشنهادی مستقل از Provider |
| شرکا | [استاندارد ارزیابی Provider](partners/provider-evaluation-standard.md) | LOT-PROVIDER-EVAL-001؛ شواهد، RFI، دروازه‌های سخت و فرایند تصمیم بین‌محصولی پیشنهادی |
| امنیت | [خط مبنای امنیت](security/security-baseline.md) | نیازمندی‌های اولیه امنیت |
| امنیت | [مدل تهدید](security/threat-model.md) | LOT-SEC-TM-001؛ مرز اعتماد، سوءاستفاده و کنترل‌های پیشنهادی |
| مهندسی | [مشخصات منابع API](engineering/api-resource-specification.md) | LOT-API-001؛ قرارداد API، احراز هویت، خطا، صفحه‌بندی و Webhook |
| مهندسی | [پلتفرم API و تجربه توسعه‌دهندگان](engineering/api-platform-and-developer-experience.md) | LOT-API-PLATFORM-001؛ Control/Data Plane، ثبت App، کاتالوگ Entitlement، Credential، Webhook، SDK، Developer Portal، Sandbox، Metering و حاکمیت چرخه عمر پیشنهادی |
| مهندسی | [قرارداد رویداد canonical](engineering/canonical-event-contract.md) | LOT-EVENT-001؛ پاکت و معنای تحویل رویداد پیشنهادی |
| مهندسی | [قرارداد Wire API افیلیت](engineering/affiliate-api-wire-contract.md) | LOT-AFFILIATE-WIRE-001؛ پروفایل پیشنهادی OpenAPI/AsyncAPI و ورودی CloudEvents؛ بدون تصویب Endpoint یا نگاشت شریک |
| مهندسی | [بازبینی امنیتی قرارداد Wire افیلیت](engineering/affiliate-wire-security-review.md) | LOT-AFFILIATE-SEC-001؛ بازبینی تهدیدمحور قرارداد، یافته‌ها و دروازه‌های پیش از پیاده‌سازی/Production |
| معماری | [استاندارد بومی‌سازی جهانی](architecture/global-localization-standard.md) | LOT-I18N-001؛ ۱۲ زبان عرضه و دروازه کیفیت برابر |
| معماری | [Live Chat و ارتباط با مشتری](architecture/live-chat-and-communications.md) | LOT-COMMS-001؛ پشتیبانی چندزبانه و تحویل به انسان |
| معماری | [معماری یکپارچه پلتفرم B2B2C چندمستاجری](architecture/unified-b2b2c-platform-architecture.md) | LOT-PLATFORM-001؛ تجربه‌های B2B/B2C/White-Label، Tenant، هویت، داشبورد، Wallet، پرداخت، Chat، امنیت و نقشه راه پیشنهادی |
| معماری | [قرارداد ارکستراسیون پرداخت و Adapter Provider](architecture/payment-orchestration-contract.md) | LOT-PAYMENT-001؛ Intent/Attempt مستقل از Provider، Adapter، Callback، Routing، Refund، Settlement و Reconciliation پیشنهادی؛ بدون انتخاب Provider |
| محصول | [طرح داشبوردها و محیط‌های کاری مبتنی بر نقش](product/role-based-dashboards-blueprint.md) | LOT-DASH-001؛ جزئیات Workspaceهای Platform، Tenant، White-Label، Affiliate/Agent، پشتیبانی، مالی، انطباق و B2C همراه گردش‌ها، KPI و تست پذیرش |
| محصول | [PRD اپلیکیشن اختصاصی First-Party B2C](product/first-party-b2c-app-prd.md) | LOT-B2C-PRD-001؛ Tenant اختصاصی B2C، گردش مشتری، ترکیب ماژول‌های واجد شرایط، Wallet/Payment/Payout، Chat، پشتیبانی، بومی‌سازی و دروازه انتشار |
| معماری | [مدل Tenant، هویت، عضویت و مجوزدهی](architecture/tenant-identity-authorization-model.md) | LOT-IAM-TENANT-001؛ چرخه عمر Tenant، مدل Principal/Membership، RBAC/ABAC، ماتریس دسترسی داشبورد، جداسازی و تست‌های پذیرش امنیتی |
| معماری | [ماژول چت قابل‌تعبیه](architecture/embeddable-chat-module.md) | LOT-CHAT-WIDGET-001؛ Widget مشترک داخلی و بیرونی، صدور امن Session و قرارداد API |
| معماری | [افق دامنه‌های آینده بازی و راهبرد Provider](architecture/future-gaming-domains-and-provider-strategy.md) | LOT-GAMING-STRATEGY-001؛ طبقه‌بندی Sportsbook، Live Casino و E-Gaming، بررسی Provider و دروازه‌های قانونی |
| معماری | [اتوماسیون رشد و محتوا](architecture/growth-content-automation.md) | LOT-GROWTH-001؛ SEO/GEO/AEO چندزبانه و گردش کانال |
| معماری | [اعلان هوشمند](architecture/smart-notifications.md) | LOT-NOTIF-001؛ Inbox و تحویل تحت Policy |
| مهندسی | [برنامه Prototype معماری و شواهد](engineering/architecture-prototype-plan.md) | LOT-PROT-001؛ هشت آزمایش الزامی و شواهد پذیرش |
| مهندسی | [راهنمای عملیاتی ایجنت‌ها](engineering/agent-operating-manual.md) | مسیریابی کم‌هزینه و تحویل کار |
| مهندسی | [دفتر ثبت تصمیم‌ها](engineering/decision-register.md) | دستور مالک، پیشنهاد و تصمیم باز |
| مهندسی | [وضعیت پروژه](engineering/project-status.md) | وضعیت تأییدشده و نقطه ادامه |
| مهندسی | [نقشه راه](engineering/roadmap.md) | توالی پیشنهادی و دروازه‌های تحویل |

## کنترل خودکار مستندات

Validator ساختاری در [scripts/check_docs.py](../../scripts/check_docs.py) جفت‌بودن مسیرهای Markdown، شناسه‌های پایدار و یکتا، عنوان سطح اول، Metadata نسخه/وضعیت و لینک‌های محلی نسبی را بررسی می‌کند. GitHub Actions آن را از طریق [Workflow حاکمیت مستندات](../../.github/workflows/docs-governance.yml) اجرا می‌کند. این کنترل‌ها هم‌ارزی معنایی ترجمه را اثبات نمی‌کنند؛ بازبینی انسانی همچنان الزامی است. Workflow در شاخه کاری اضافه شده است؛ پیش از تلقی موفق، نتیجه اجرای آن بررسی شود.

## انضباط شواهد و وضعیت

مخزن همچنان مستندات‌محور است. وجود سند یا طراحی، پیاده‌سازی را اثبات نمی‌کند. بدون شواهد مخزن و تست، کد برنامه، Schema دیتابیس، اتصال Provider، تأیید Sandbox، پردازش مالی، پرداخت، CI خودکار یا Deploy عملیاتی را تکمیل‌شده معرفی نکنید.

از وضعیت‌های صریح **Proposed / پیشنهادی**، **Implemented / پیاده‌سازی‌شده**، **Verified / راستی‌آزمایی‌شده** و **Blocked / مسدود** استفاده کنید. ادعای Verified باید رفتار، تست/شاهد، Commit و محیط را مشخص کند.

## همگام‌سازی دوزبانه

هر تغییر معنادار در docs/fa/ باید در همان شاخه و Pull Request همراه با نسخه انگلیسی هم‌معنا در docs/en/ انجام شود. هم‌ارزی فرمول، مبلغ، محدودیت، وضعیت، مثال، معیار پذیرش و الزام امنیتی را بررسی کنید؛ وجود هر دو فایل کافی نیست.

## حاکمیت مشارکت

پیش از مشارکت، [AGENTS.md](../../AGENTS.md) را بخوانید. از شاخه کاری و Pull Request استفاده کنید. بدون مجوز صریح مالک، Merge، Deploy، تغییر تنظیمات مخزن یا عملیات مخرب انجام ندهید.

## پذیرش امنیتی افیلیت

- [مشخصات پذیرش امنیتی و مرز Runtime افیلیت](engineering/affiliate-security-acceptance-runtime-boundary.md) — LOT-AFFILIATE-SEC-ACC-001؛ ماتریس پیشنهادی پذیرش Runtime، مرز اعتماد، Idempotency، Persistence، حفاظت داده و Gateهای انتشار؛ بدون پیاده‌سازی Runtime یا تأیید Production.


## تصمیم‌های امنیتی و اثبات Runtime افیلیت G09-A3

- [بسته تصمیم‌های G09-A3 و برنامه اثبات Runtime ساختگی](engineering/affiliate-g09-a3-decision-and-runtime-proof.md) — LOT-AFFILIATE-G09-A3-001؛ رکوردهای تصمیم پیشنهادی برای IAM، رجیستری Installation/Event، Idempotency/Fingerprint، حاکمیت منابع، چرخه داده، Audit و مرز اثر مالی، به‌همراه برنامه اثبات Runtime ایزوله و ساختگی. هیچ تصمیمی تصویب نشده و ادعای پیاده‌سازی Runtime وجود ندارد.


## معماری اثبات Runtime افیلیت G09-A4

- [معماری اثبات Runtime و طراحی تست‌های خصمانه G09-A4](engineering/affiliate-g09-a4-runtime-proof-architecture.md) — LOT-AFFILIATE-G09-A4-001؛ Harness ایزوله پیشنهادی، مرزهای اعتماد، ناورداهای Persistence، ۴۷ سناریوی خصمانه، Oracleهای مستقل تست، الزامات شواهد و Gateهای توقف. هیچ پیاده‌سازی Runtime یا انتخاب فناوری تصویب نشده است.

- [G09-A5 افیلیت — آمادگی اثبات Runtime و نقشه اجرایی پیاده‌سازی](engineering/affiliate-g09-a5-runtime-proof-readiness.md) — مدل منطقی Persistence، اتمیک‌بودن، Fencing مربوط به Worker، Fixture، تزریق خطا و نقشه تست اجرایی؛ بدون مجوز Runtime.


## راستی‌آزمایی طراحی G09-A6 افیلیت

- [G09-A6 افیلیت — راستی‌آزمایی طراحی و بستن شکاف‌های اثبات](engineering/affiliate-g09-a6-design-verification.md) — LOT-AFFILIATE-G09-A6-001؛ بازبینی مستقل اسناد A4/A5، ردیابی ۴۷ سناریو، ده یافته و موانع اثبات Runtime. صرفاً قبولی مشروط طراحی؛ بدون مجوز Runtime.


## G09-A7 افیلیت — ردیابی ۴۷ سناریو

- [G09-A7 افیلیت — نقشه ردیابی ۴۷ سناریو و بستن تصمیم‌ها](engineering/affiliate-g09-a7-47-case-traceability.md) — LOT-AFFILIATE-G09-A7-001؛ ۴۷ Case مستقل A4، Fixture ساختگی، Assertionهای پروتکل/Persistence/امنیت/عدم اثر مالی، Oracle مستقل، قرارداد Evidence، برنامه‌های قطعی Race و دفتر بستن F01 تا F10. صرفاً طراحی؛ تمام Caseها NOT RUN و Runtime مسدود است.

- [وابسته G09-A8 — راستی‌آزمایی و چالش خصمانه](engineering/affiliate-g09-a8-independent-verification.md) — خودبازبینی طراحی؛ بازبینی مستقل در انتظار؛ بدون مجوز Runtime.

- [ADR-001 افیلیت — پروتکل Claim، Lease و Fencing پایدار WorkItem](engineering/adr-001-workitem-claim-lease-fencing.md) — پروتکل زمانی پیشنهادی؛ تصویب مالک و بازبینی مستقل در انتظار؛ بدون مجوز Runtime.


## رکوردهای تصمیم Affiliate G09

- [ADR-001 افیلیت — پروتکل Claim، Lease و Fencing پایدار WorkItem](engineering/adr-001-workitem-claim-lease-fencing.md) — پروتکل زمانی پیشنهادی؛ تصویب مالک و بازبینی مستقل در انتظار.
- [ADR-002 افیلیت — پذیرش اتمیک Ingress و تطبیق نتیجه نامعلوم Commit](engineering/adr-002-atomic-ingress-acceptance-reconciliation.md) — جفت اتمیک InboxReceipt + WorkItem، تطبیق Commit نامعلوم، ماتریس Crash و تصمیم‌های باز مالک؛ بدون مجوز Runtime.


- [Affiliate G09-A11 — بازبینی خصمانه طراحی ADR-002](engineering/affiliate-g09-a11-adr002-adversarial-review.md) — خودبازبینی در همان جریان؛ هشت یافته مهم و نه Subcase پیشنهادی NOT RUN؛ بازبینی مستقل در انتظار؛ بدون مجوز Runtime.

- [G09-A12 افیلیت — بسته بازبینی مستقل ADR-002](engineering/affiliate-g09-a12-adr002-independent-review-package.md) — پروتکل چالش و ماتریس شواهد برای بازبین مستقل؛ بازبینی مستقل هنوز انجام نشده؛ تمام یافته‌های A11 باز هستند؛ بدون مجوز Runtime.

- [G09-A13 افیلیت — بازبینی اطمینان‌بخشی اعتبارسنجی قرارداد](engineering/affiliate-g09-a13-contract-validation-assurance-review.md) — بازبینی همان نویسنده درباره دامنه CI، Assertionهای امنیت/Scope، Dialect در AsyncAPI، بازتولیدپذیری Dependency، محدودیت Extension و معنای پاسخ UNKNOWN؛ یافته‌ها باز هستند.

- [G09-A14 افیلیت — سخت‌سازی اعتبارسنجی قرارداد و هم‌ترازی وضعیت پاسخ](engineering/affiliate-g09-a14-contract-validation-hardening.md) — Manifest دقیق Security/Scope، Profile مربوط به CloudEvents، Guard مربوط به Dialect در AsyncAPI، Lockfileهای بازتولیدپذیر و پوشش ۱۱ Root/۵۳ Fixture؛ سخت‌سازی فنی روی Head دقیق `736390f86ab425a8c273dcf254cc5974e9eb55ae` تأیید شده؛ تصمیم‌های مالک و اثبات Runtime همچنان باز هستند.

- [G09-A15 افیلیت — آمادگی اثبات Persistence و ماتریس تصمیم‌های مالک ADR-002](engineering/affiliate-g09-a15-persistence-proof-readiness.md) — تعهدات اثبات مستقل از Candidate، ۱۲ تصمیم مالک، ۱۲ Schedule قطعی، قرارداد Evidence مستقل و Gateهای مرحله‌ای؛ بدون انتخاب Candidate و بدون اجرای اثبات Runtime.

- [G09-A16 افیلیت — بازبینی خصمانه معماری ADR-002 و پرونده بازبین مستقل](engineering/affiliate-g09-a16-adversarial-architecture-review.md) — فرابازبینی نویسنده با ده چالش میان‌برشی، دوازده خانواده Schedule قطعی، قرارداد Oracle مستقل و پروتکل تحویل به بازبین؛ نه تأیید مستقل است و نه Proof مربوط به Runtime.


- [G09-A17 افیلیت — تطبیق بازبینی مستقل و بستن شکاف شواهد](engineering/affiliate-g09-a17-review-reconciliation.md) — رویداد APPROVED در GitHub را به SHA دقیق بررسی‌شده متصل می‌کند، تأیید پلتفرم را از شواهد بازبینی محتوایی A12 جدا می‌سازد و یافته‌های A11/تصمیم‌های مالک را تا دریافت Disposition تکمیلی باز نگه می‌دارد.


## حاکمیت جامع ارزیابی و انتخاب

- [استاندارد جامع ارزیابی و انتخاب محصول، فناوری و تأمین‌کننده](governance/enterprise-evaluation-standard.md) — LOT-EVAL-001؛ استاندارد مادر پیشنهادی برای چارچوب تصمیم، سطوح ریسک، شواهد، Gateهای غیرقابل‌جبران، امتیازدهی منصفانه، هزینه کل، پایلوت کنترل‌شده، تصویب، پایش و خروج. این سند بر پروفایل‌های تخصصی Provider/Technology/دامنه حاکم است و هیچ گزینه‌ای را انتخاب نمی‌کند.


- [LOT-EVAL-A18-001 — گزارش بازبینی خصمانه نویسنده و ثبت اصلاحات](governance/enterprise-evaluation-adversarial-review-a18.md) — ۱۲ یافته اولیه A18 و یافته‌های تکمیلی REV-01 تا REV-14، اصلاحات پیشنهادی نسخه ۰.۳.۰ و تفکیک بازبینی مالک از تضمین مستقل را ثبت می‌کند.

- [LOT-EVAL-OWNER-REVIEW-001 — دفتر بازبینی و تعیین تکلیف مالک](governance/enterprise-evaluation-owner-review-001.md) — یافته‌های REV-01 تا REV-14، وضعیت‌های Disposition مالک، دستور واگذاری اجرای اصلاحات فنی و اصل عدم‌معادل‌بودن اجرا با پذیرش ریسک را ثبت می‌کند.

- [LOT-EVAL-AVT-001 — ماتریس آزمون پذیرش خصمانه](governance/enterprise-evaluation-adversarial-test-matrix-001.md) — ۲۱ بردار آزمون خصمانه طراحی‌شده برای REV-01/03/04/12/14؛ اجرای آزمون، تعیین تکلیف مالک و تضمین مستقل همچنان در انتظار است.

- [استاندارد ارزیابی Provider، بررسی موشکافانه و RFI](partners/provider-evaluation-standard.md) — LOT-PROVIDER-EVAL-001 نسخه ۰.۲.۰؛ معنای شواهد و امتیازدهی آن تابع استاندارد مادر LOT-EVAL-001 است.
- [ADRهای فناوری، استقرار و قابلیت اطمینان](architecture/technology-deployment-adrs.md) — LOT-TECH-ADR-001 نسخه ۰.۲.۰؛ وزن‌های فناوری پیشنهادی و تابع Rubric استاندارد مادر.
- [مدل تهدید امنیتی Lottorito](security/threat-model.md) — LOT-SEC-TM-001 نسخه ۰.۲.۰؛ ارزیابی ریسک باقیمانده با ارجاع به لنگرهای احتمال/اثر استاندارد مادر.


## مدل مرجع تصمیم‌گیری LOT-EVAL

- [LOT-EVAL-RDM-001 — مدل مرجع تصمیم‌گیری و آزمون‌گر خصمانه](governance/enterprise-evaluation-reference-decision-model-001.md) — Harness ایزوله مبتنی بر کتابخانه استاندارد Python برای AVT-01 تا AVT-21 و MUT-01 تا MUT-10؛ صرفاً Synthetic/غیرProduction؛ بازبینی مستقل و تعیین تکلیف مالک در انتظار.


## ممیزی خصمانه مدل مرجع LOT-EVAL

- [LOT-EVAL-RDM-002 — ممیزی خصمانه مدل مرجع و Oracleهای آزمون](governance/enterprise-evaluation-reference-model-adversarial-audit-002.md) — ممیزی خصمانه به‌دست نویسنده؛ ویژگی‌های آزموده‌نشده ماتریس را شناسایی و مسیر Oracle مستقل و راستی‌آزمایی چندلایه را تعریف می‌کند. یافته‌ها باز هستند.


- [LOT-EVAL-RDM-003A — کاتالوگ قواعد هنجاری و جدول‌های تصمیم](governance/enterprise-evaluation-decision-rule-catalogue-001.md) — تجزیه به‌دست نویسنده از LOT-EVAL-001 به قواعد اتمی، پنج جدول تصمیم، دفتر ابهام‌های حل‌نشده و ردیابی قاعده به آزمون؛ بازبینی Oracle مستقل و تعیین تکلیف مالک در انتظار.

- [LOT-EVAL-RDM-004 — راستی‌آزمایی کامل جدول‌های تصمیم](governance/enterprise-evaluation-full-decision-table-verification-004.md) — آزمون اجرایی ردیف‌محور برای هر ۳۶ ردیف جدول تصمیم، یازده آزمون Metamorphic و چهار جهش هدفمند مشخصات؛ CI دقیق شماره ۱۲۲۵ روی SHA کد `2e0eadfcc2bc6200af1410197dcbeaa563e8fed0` موفق شد؛ ابهام‌های سیاستی و قواعد خارج از پوشش همچنان باز هستند.


## پیش‌نویس تاریخی بازبینی کور LOT-EVAL-RDM-003B — منسوخ‌شده

- [بسته تاریخی بازبینی کور LOT-EVAL-RDM-003B](governance/enterprise-evaluation-blind-oracle-review-003b.md) — پیش‌نویس منسوخ‌شده؛ بازبینی کور انجام نشد و بسته ورودی ۳۵ ردیفی ناقص بود. به‌عنوان Gate فعال بازبینی استفاده نشود.
- [Worksheet تاریخی LOT-EVAL-RDM-003B](governance/enterprise-evaluation-blind-oracle-worksheet-003b.md) — قالب خالی منسوخ‌شده؛ عدد ۷۴ مورد سابقه تاریخی است و نباید به‌عنوان ۷۴ آزمون مستقل معرفی شود.


### اصلاح مسیر بازبینی RDM-003B

- [گزارش بازبینی خصمانه دومرحله‌ای نویسنده](governance/enterprise-evaluation-author-led-second-pass-review-003b.md) — سابقه فعال بازبینی. بسته کور و Worksheet خالی قبلی صرفاً اسناد تاریخی منسوخ‌شده‌اند؛ ادعای بازبین بیرونی یا Oracle کور وجود ندارد.


- تکمیل سخت‌سازی DT05: Oracle ردیف R5 فقدان زوج باقیمانده را مستقیم رد می‌کند؛ Schema ریسک ابعاد تکراری/ناشناخته و فیلدهای شواهد خالی را رد می‌کند؛ MT-11 اضافه شد. اجرای دقیق Head شماره ۱۲۳۱ روی `2e0eadfcc2bc6200af1410197dcbeaa563e8fed0` موفق شد.
