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
- [G09-A17 افیلیت — پرونده تحقیق و پیشنهاد تصمیم‌های مالک ADR-002](engineering/affiliate-g09-a17-adr002-owner-decision-research.md) — تحلیل مبتنی بر شواهد OD-01 تا OD-12، پیشنهادهای مشروط، گزینه‌های ردشده، شواهد اثبات، وابستگی تصمیم‌ها و Hard Gateهای Candidate؛ بدون اتخاذ تصمیم مالک یا انتخاب فناوری.

- [G09-A18 افیلیت — ارزیابی معماری Candidateهای Persistence و Authority](engineering/affiliate-g09-a18-persistence-authority-candidate-evaluation.md) — مقایسه پژوهشی PostgreSQL HA مهندسی‌شده، Managed PostgreSQL HA، Distributed SQL، Spanner مشروط و تفکیک Authority/Outbox؛ تعریف Hard Gateهای G1 تا G7 و برنامه شواهد R1؛ بدون انتخاب Candidate یا مجوز Runtime.
- [G09-A19 افیلیت — ماتریس محدودیت‌های استقرار و احراز صلاحیت Candidateها](engineering/affiliate-g09-a19-deployment-constraints-candidate-qualification.md) — احراز صلاحیت مبتنی بر محدودیت: ورودی‌های مالک C-01 تا C-16، Inventory کامل Data-flow/Location، Hard Gateهای G1 تا G9، اهداف بازیابی مبتنی بر BIA و اندازه‌گیری بازتولیدپذیر؛ بدون انتخاب Provider، Region یا Database.


## G09-A20 افیلیت — اخذ شواهد و احراز صلاحیت خصمانه

- [G09-A20 — نظام اخذ شواهد و طراحی احراز صلاحیت خصمانه](engineering/affiliate-g09-a20-constraint-evidence-adversarial-qualification.md) — ماتریس Evidence برای C-01 تا C-16، Inventory کامل Data-flow، ناورداها و Oracleهای مستقل، ۲۸ طراحی آزمون خصمانه، Gateهای ایمنی اجرا و Manifest بازتولیدپذیری؛ همه Caseها NOT RUN، بدون احراز صلاحیت Candidate یا مجوز Runtime.


## G09-A21 افیلیت — بازبینی خصمانه تضمین کیفیت

- [G09-A21 — بازبینی خصمانه تضمین کیفیت سند G09-A20](engineering/affiliate-g09-a21-adversarial-assurance-review.md) — خودبازبینی داخلی و نه Assurance مستقل؛ شامل ۱۳ یافته باز (P0:1، P1:9، P2:3)، شکاف‌های Traceability و مسیر اصلاح کنترل‌شده A22 تا A24. A20 صرفاً تحقیق/طراحی آزمون است؛ بدون مجوز Runtime.


## G09-A22 افیلیت — اصلاح مشخصات A20

- [G09-A22 — اصلاح مشخصات A20](engineering/affiliate-g09-a22-a20-specification-remediation.md) — Identity/Canonicalization وابسته به تصمیم، پروتکل UNKNOWN Commit، تضمین Receiver خارجی، چرخه عمر Retention/Restore، Traceability، معنای نتایج آزمون و مرز مالی صرفاً ساختگی/ایزوله. صرفاً تحقیق؛ بدون مجوز Runtime.
