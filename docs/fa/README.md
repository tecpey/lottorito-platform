# مستندات فارسی Lottorito

**شناسه سند:** LOT-DOC-INDEX-FA-001 | **نسخه:** ۱.۷.۰ | **وضعیت:** فهرست مرجع و در حال نگهداری

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
| شرکا | [قرارداد یکپارچه‌سازی Affiliate](partners/integration-contract.md) | قرارداد اولیه رویداد شریک Affiliate |
| شرکا | [قرارداد ارائه‌دهنده Lottery](partners/lottery-provider-contract.md) | چرخه عمر پیشنهادی مستقل از Provider |
| شرکا | [استاندارد ارزیابی Provider](partners/provider-evaluation-standard.md) | LOT-PROVIDER-EVAL-001؛ شواهد، RFI، دروازه‌های سخت و فرایند تصمیم بین‌محصولی پیشنهادی |
| امنیت | [خط مبنای امنیت](security/security-baseline.md) | نیازمندی‌های اولیه امنیت |
| امنیت | [مدل تهدید](security/threat-model.md) | LOT-SEC-TM-001؛ مرز اعتماد، سوءاستفاده و کنترل‌های پیشنهادی |
| مهندسی | [مشخصات منابع API](engineering/api-resource-specification.md) | LOT-API-001؛ قرارداد API، احراز هویت، خطا، صفحه‌بندی و Webhook |
| مهندسی | [قرارداد رویداد canonical](engineering/canonical-event-contract.md) | پاکت و معنای تحویل رویداد پیشنهادی |
| معماری | [استاندارد بومی‌سازی جهانی](architecture/global-localization-standard.md) | LOT-I18N-001؛ ۱۲ زبان عرضه و دروازه کیفیت برابر |
| معماری | [Live Chat و ارتباط با مشتری](architecture/live-chat-and-communications.md) | LOT-COMMS-001؛ پشتیبانی چندزبانه و تحویل به انسان |
| معماری | [معماری یکپارچه پلتفرم B2B2C چندمستاجری](architecture/unified-b2b2c-platform-architecture.md) | LOT-PLATFORM-001؛ تجربه‌های B2B/B2C/White-Label، Tenant، هویت، داشبورد، Wallet، پرداخت، Chat، امنیت و نقشه راه پیشنهادی |
| محصول | [طرح داشبوردها و محیط‌های کاری مبتنی بر نقش](product/role-based-dashboards-blueprint.md) | LOT-DASH-001؛ جزئیات Workspaceهای Platform، Tenant، White-Label، Affiliate/Agent، پشتیبانی، مالی، انطباق و B2C همراه گردش‌ها، KPI و تست پذیرش |
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
