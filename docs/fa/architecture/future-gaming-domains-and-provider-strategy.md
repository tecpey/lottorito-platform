# افق دامنه‌های آینده بازی و راهبرد انتخاب Provider

**شناسه سند:** LOT-GAMING-STRATEGY-001 | **نسخه:** ۱.۰.۰ | **وضعیت:** افق محصول آینده به دستور مالک و خط مبنای تحقیق؛ هیچ محصول، Provider، مجوز، API یا راه‌اندازی تصویب نشده است

## ۱. هدف و اعتبار سند

مالک دستور داده است Lottorito برای قابلیت‌های آینده Sportsbook، Live Casino و E-Gaming حرفه‌ای برنامه‌ریزی کند؛ این قابلیت‌ها باید با Providerهای معتبر متصل شوند و از نظر کیفیت، استانداردهای بین‌المللی بالایی داشته باشند. این سند این جهت‌گیری را به چارچوب مشخص محصول و بررسی موشکافانه Provider تبدیل می‌کند.

توالی راهبردی پذیرفته‌شده همچنان چنین است: ابتدا Affiliate، سپس Lottery و پس از آن دامنه‌های مستقل Sportsbook/Betting، Casino/Live Casino و E-Gaming که هرکدام جداگانه اعتبارسنجی می‌شوند. این‌ها افق آینده‌اند، نه محدوده MVP فعلی، مجوز پیاده‌سازی، مجوز اپراتوری، قرارداد تأمین‌کننده یا اجازه ارائه قمار در هر بازار.

Lottorito باید پلتفرمی جهانی، ماژولار، API-first و چندمستاجری برای B2B باشد. هر دامنه باید مستقل از نظر استفاده، Entitlement، قرارداد، پیکربندی، عملیات، ممیزی و بسته تجاری قابل عرضه باشد. استقلال از Provider یک قید طراحی است: منطق اختصاصی هر Provider پشت Adapter نسخه‌بندی‌شده می‌ماند. این تحقیق هیچ Providerی را انتخاب نمی‌کند.

## ۲. طبقه‌بندی محصول؛ دامنه‌های متفاوت را یکی نکنیم

نام‌گذاری دامنه‌ها باید دقیق باشد. اصطلاح «E-Gaming» در بازار مبهم است و نباید به سرویس همه‌چیز تبدیل شود.

۱. **Sportsbook / Event Wagering:** شرط‌بندی با ضریب ثابت پیش از مسابقه و حین مسابقه، Bet Slip، پذیرش شرط، Trading/Risk، Cash-out در صورت پشتیبانی، تسویه، Void/Regrade، یکپارچگی رویداد و حقوق داده ورزشی. شرط‌بندی Esports یک دسته محتوایی با حاکمیت مستقل در دامنه Event Wagering است و با بازی کازینویی یکسان نیست.
۲. **Live Casino:** بازی‌های میزی با دیلر واقعی ویدئویی و Showها؛ شامل دسترس‌پذیری Studio/Table، Streaming، چرخه Round، اصلاح خطای دیلر و شواهد تاریخچه بازی.
۳. **RNG Casino / محتوای E-Gaming:** Slot، بازی میزی RNG، Video Poker، Bingo، بازی Crash/Instant و Jackpot. هر مکانیزم و خانواده محتوا ممکن است Certification، دسترس‌پذیری بازار و الزامات Responsible Gambling متفاوتی داشته باشد.
۴. **Poker و بازی‌های Peer-to-peer:** در صورت پیگیری، دامنه آینده مستقل؛ شبکه نقدینگی مشترک، Matchmaking، Tournament، Rake، تبانی/تقلب و کنترل یکپارچگی بازی با کازینوی بانکی تفاوت جدی دارد.
۵. **Skill/Social Games:** طبقه‌بندی و تحلیل حقوقی مستقل لازم دارد؛ برچسب «Social»، «Free-to-play» یا Skill به‌تنهایی به‌معنای خارج‌بودن از مقررات نیست.

Product Registry باید هر مورد را Bounded Context و Entitlement جداگانه ثبت کند. ممکن است یک Provider چند دامنه را تأمین کند، اما این موضوع نباید چرخه عمر، ریسک، دفترکل، مجوزها یا تصمیم انتشار آن‌ها را ادغام کند.

## ۳. معماری هدف

سرویس‌های مشترک Lottorito از موتورهای دامنه‌ای مستقل بمانند:

- **خدمات مشترک پلتفرم:** Tenant/Identity/Access، نگاشت هویت حساب بازیکن، Policy صلاحیت محصول و حوزه قضایی، Control Plane بازی مسئولانه، Primitiveهای مالی و دفترکل تغییرناپذیر، Event/Audit، Registry ارائه‌دهندگان، Vault اعتبارنامه، Observability، پشتیبانی، بومی‌سازی و گزارش.
- **دامنه Sportsbook:** کاتالوگ Event/Market، Snapshot ضریب، وضعیت بازار، Bet Slip، تصمیم پذیرش، چرخه Bet، اتصال Trading/Risk، تسویه و اصلاح.
- **دامنه Live Casino:** کاتالوگ Studio/Table/Game، Session آغاز بازی، تحویل Streaming، چرخه Round، اصلاح دیلر، تاریخچه بازی و تطبیق Round.
- **دامنه RNG/E-Gaming:** کاتالوگ محتوا، دسترس‌پذیری مجاز در هر حوزه قضایی، Game Launch، چرخه Round/Bet/Win/Rollback، سهم/پرداخت Jackpot و گزارش Provider.
- **لایه Adapter ارائه‌دهنده:** احراز هویت اختصاصی Provider، Schema، پروتکل Wallet، Callback، نگاشت وضعیت، محدودیت، Retry، ترجمه خطا، سلامت و تطبیق. هسته دامنه مستقیماً Endpoint ارائه‌دهنده را فراخوانی نمی‌کند.
- **سطوح اپراتور و Tenant:** پنل اپراتور، تجربه بازیکن، ابزار پشتیبانی/ریسک و APIهای اتصال شریک؛ همگی با Entitlement صریح و Scope حداقلی.

نباید یک انتزاع عمومی به نام «تراکنش بازی» بسازیم که تفاوت شرط ورزشی، Round میز زنده، Spin اسلات و Hand پوکر را حذف کند. Primitive مشترک قابل استفاده است، اما State Machine و معنای مالی هر دامنه باید صریح بماند.

## ۴. مدل‌های عرضه Provider

فروشندگان را بر اساس مدل ارائه ارزیابی کنیم، نه برچسب تبلیغاتی:

- **Turnkey / پشته مدیریت‌شده اپراتور:** تأمین‌کننده ممکن است PAM، Sportsbook/Casino، Trading، پرداخت یا خدمات عملیاتی ارائه کند. اتصال سریع‌تر می‌تواند قفل‌شدگی Vendor را بالا ببرد و مالکیت هویت بازیکن، موجودی، سوابق قانونی و رابطه مشتری را مبهم کند.
- **پلتفرم ماژولار / موتور دامنه:** Lottorito کنترل بیشتری بر تجربه اپراتور دارد و موتورهای جداگانه و سرویس‌ها را متصل می‌کند؛ در عوض به Orchestration، تطبیق و توان عملیاتی قوی‌تری نیاز دارد.
- **استودیوی محتوای مستقیم:** اتصال مستقیم به یک استودیو یا تأمین‌کننده دیلر زنده؛ احتمالاً شفافیت تجاری/کنترلی بیشتری دارد، اما قرارداد، Certification، Wallet Integration و تطبیق مستمر بیشتری ایجاد می‌کند.
- **Aggregator محتوا:** یک اتصال و قرارداد می‌تواند چند استودیو را عرضه کند. مجوز استودیوهای زیرمجموعه، دسترس‌پذیری دقیق هر عنوان در هر حوزه قضایی، زنجیره Subcontractor، حقوق داده، مسئولیت Certification، معنای Wallet، هزینه و قابلیت خروج/انتقال باید بررسی شود. «یک API» تعهد هر بازی و هر بازار را حذف نمی‌کند.
- **تأمین‌کننده Data/Odds/Integrity:** Feed و Trading به‌تنهایی موتور کامل Sportsbook نیستند. حقوق رسمی داده، Latency، پوشش بازار، اختیار تسویه، پایش یکپارچگی و مسئولیت قراردادی باید بررسی شود.

Lottorito باید امکان اتصال هم‌زمان مستقیم به Providerها و Aggregatorها را حفظ کند. Aggregator نباید تنها منبع حقیقت حرکت Wallet، محدودیت بازیکن، Round بازی یا صورت‌حساب مالی باشد.

## ۵. نقشه اولیه بازار برای RFI (بدون توصیه یا تأیید)

نام‌های زیر بر اساس مطالب عمومی دست‌اول شرکت‌ها، گزینه‌های تحقیق‌اند. این فهرست رتبه‌بندی، بررسی Certification، ادعای سازگاری API، توصیه تجاری یا اثبات دسترس‌پذیری در حوزه قضایی هدف نیست. پیش از خرید، شخصیت حقوقی دقیق طرف قرارداد/تأمین‌کننده و ثبت جاری نهاد ناظر بررسی شود.

### ۵.۱ Sportsbook و Event Wagering

- **Kambi:** راهکار Turnkey کامل Sportsbook همراه Trading/Risk و محصول جداگانه Odds Feed+ با API را معرفی می‌کند. برای RFI مقایسه مدل Sportsbook مدیریت‌شده با اتصال صرفاً Data گزینه مناسبی برای بررسی است. منبع: [Kambi](https://www.kambi.com/).
- **EveryMatrix / OddsMatrix:** پلتفرم ماژولار Sports/Casino با رویکرد API-first را معرفی می‌کند؛ OddsMatrix نیز Feed/API داده ورزشی شامل ضریب پیش/حین مسابقه، امتیاز، آمار و تسویه را منتشر کرده است. اطلاعیه ۲۰۲۴ آن می‌گوید پلتفرم OddsMatrix به GLI-33 گواهی شده؛ محدوده، نسخه و حوزه قضایی گواهی باید مستقیماً تأیید شود. منابع: [EveryMatrix](https://everymatrix.com/)، [OddsMatrix Data Services](https://omfeeds.everymatrix.com/)، [اطلاعیه Certification](https://everymatrix.com/news/gaming-laboratories-international-gli-delivers-gold-standard-certification-to-core-everymatrix-platform-products/).
- **Altenar:** گزینه‌های Sportsbook مدیریت‌شده و خودمدیریت، Trading/Risk شبانه‌روزی و اتصال API به PAM/Front-end موجود را معرفی می‌کند. وب‌سایت آن اطلاعات مشخصی درباره مجوز/ثبت منتشر می‌کند؛ شخصیت حقوقی و فعالیت مجاز در هر رجیستر هدف باید بررسی شود. منبع: [Altenar Sportsbook](https://altenar.com/services/sportsbook/).
- **OpenBet، Sportradar، Digitain و سایر Providerهای Enterprise:** برای RFI ساختاریافته نگه داشته شوند؛ صرف شهرت برند، تناسب یا شرایط API را اثبات نمی‌کند. پلتفرم، Trading، داده رسمی، تسویه و Integrity جداگانه بررسی شوند.

### ۵.۲ Live Casino

- **Evolution Group:** گزارش سالانه آن One Stop Shop را برای اتصال مجموعه Evolution، Ezugi و چند برند RNG توصیف می‌کند؛ صفحه راهکارها نیز محیط اختصاصی Live را معرفی کرده است. برای بررسی توزیع چندبرندی و Studio اختصاصی مرتبط است. منابع: [راهکارهای Evolution](https://www.evolution.com/about/solutions)، [گزارش سالانه ۲۰۲۵](https://www.evolution.com/wp-content/uploads/2026/04/Annual_Report_English_2026_04_01.pdf).
- **Playtech Live:** استودیوهای Live در چند منطقه و مجموعه بازی‌های میزی و Showهای دارای برند را معرفی می‌کند. منبع: [Playtech Live](https://www.playtech.com/products/live/).
- **Pragmatic Play Live:** همراه با مجموعه گسترده‌تر Slot/Content بررسی شود؛ اطلاعات عمومی شرکت از ارائه Slot، Live Casino و محتوای دیگر از طریق یک API سخن می‌گوید. API واقعی، مدل Wallet، کاتالوگ بازی و Entitlement بازار باید در RFI راستی‌آزمایی شوند. منبع: [Pragmatic Play](https://www.pragmaticplay.com/en/about-us/).

### ۵.۳ محتوای RNG / E-Gaming و Aggregation

- **EveryMatrix CasinoEngine:** گزینه‌ای برای مقایسه Aggregation چنداستودیویی و پلتفرم ماژولار؛ قرارداد مستقیم استودیوها، نگاشت بازی به بازار، گزارش و مدل Wallet بررسی شود.
- **Games Global:** مجموعه ۱۳۰۰+ بازی اختصاصی و بیش از ۴۰ استودیوی داخلی/شریک را معرفی می‌کند؛ از جمله Slot، بازی میزی، Video Bingo، Video Poker و Crash. منبع: [Games Global](https://www.gamesglobal.com/Company/About).
- **Relax Gaming:** خدمات Aggregation و برنامه توزیع Powered By Relax را معرفی می‌کند؛ پورتال تجاری Relax Vantage شامل دسترس‌پذیری بازی، تنظیمات، تحلیل و اطلاعات انطباق است. منابع: [Relax Vantage](https://www.relax-gaming.com/news/2024/08/relax-gaming-reveals-game-changing-business-portal-relax-vantage)، [گسترش Powered By Relax](https://www.relax-gaming.com/news/2026/01/relax-gaming-expands-powered-by-relax-platform-with-wicked-games-integration).
- **Pragmatic Play و Play'n GO:** گزینه‌های بررسی تأمین محتوای بازارهای تحت نظارت‌اند؛ ماتریس Certification و مجازبودن هر عنوان در هر حوزه قضایی لازم است، نه صرفاً ادعای سطح شرکت. منابع: [Pragmatic Play](https://www.pragmaticplay.com/en/about-us/)، [Play'n GO](https://www.playngo.com/).

### ۵.۴ تفسیر نقشه بازار

وب‌سایت Provider منبع دست‌اول برای آن چیزی است که شرکت ادعا می‌کند عرضه می‌کند؛ اما اثبات مستقل عملکرد، محدوده مجوز، کیفیت API یا تناسب تجاری نیست. صفحات بازاریابی جای مستند فنی جاری، تست Sandbox، بررسی رجیستر نهاد ناظر، بازبینی قرارداد و Reference اپراتورهای هم‌حوزه قضایی و هم‌مدل را نمی‌گیرند.

## ۶. کارت امتیاز Due Diligence ارائه‌دهنده

هیچ Providerی صرفاً به‌دلیل اندازه کاتالوگ، ارائه فروش یا Demo اولیه وارد مرحله انتخاب نمی‌شود. برای هر دسته شواهد لازم است:

۱. **شخصیت حقوقی و مجوز:** شخصیت‌های حقوقی دقیق طرف قرارداد و تأمین‌کننده؛ مجوزها/ثبت‌های جاری و فعالیت‌های مجاز؛ حوزه‌های قضایی و نوع محصول؛ مالکیت/کنترل؛ تحریم و سابقه اقدامات نظارتی؛ پیمانکاران فرعی و زنجیره استودیو.
۲. **مستندات فنی:** API/OpenAPI یا پروتکل جاری، نسخه Schema، Sandbox، حساب تست، Callback نمونه، نگهداری SDK، Changelog، سیاست Deprecation و پشتیبانی فنی نام‌دار.
۳. **مدل Wallet و تراکنش:** Seamless در برابر Transfer Wallet؛ مالکیت موجودی؛ معنای Debit/Credit/Rollback؛ شناسه Round/Bet؛ Idempotency؛ امضای Callback؛ ترتیب؛ Retry؛ نتیجه دیررس؛ خطای جزئی؛ موجودی منفی؛ صورت‌حساب تطبیق؛ سوابق کارمزد و مالیات.
۴. **داده و Integrity:** منبع و حقوق داده ورزشی؛ تضمین Timestamp/Latency؛ توقف Market؛ مرجع نتیجه؛ Certification مربوط به RNG/RTP؛ Hash نسخه Build بازی؛ تاریخچه Round ضد‌دستکاری؛ فرآیند اصلاح و اختلاف.
۵. **امنیت و حریم خصوصی:** چرخش/لغو Credential؛ mTLS یا درخواست امضاشده؛ نگهداری کلید؛ کنترل شبکه؛ افشای آسیب‌پذیری؛ خلاصه تست نفوذ؛ اعلان حادثه؛ محل داده، نگهداری، حذف و فهرست Subprocessor.
۶. **تناسب قانونی:** Allowlist بازی/Event به تفکیک بازار؛ محدوده و نسخه گواهی؛ وابستگی Geolocation؛ مسئولیت Age/Identity Verification؛ انتشار Self-exclusion و Limit؛ Export ممیزی؛ محدودیت تبلیغات و Affiliate.
۷. **قابلیت اطمینان و عملیات:** Uptime و سابقه Incident با شواهد مستقل؛ ظرفیت اوج رویداد؛ صدک‌های Latency؛ Failover منطقه‌ای؛ Status Page؛ RTO/RPO؛ پوشش پشتیبانی؛ Escalation و تست Disaster Recovery.
۸. **تجاری و خروج:** حداقل تعهد مالی، Revenue Share، هزینه ثابت، ارز/FX، مالیات، چرخه تسویه، Reserve، Chargeback، حق ممیزی، سقف مسئولیت، انحصار، قابلیت انتقال داده، کمک در خاتمه قرارداد و برنامه تداوم.
۹. **Reference و اثبات:** در صورت امکان حداقل دو Reference اپراتور مشابه؛ Contract Test مشاهده‌شده Sandbox؛ نمونه تطبیق؛ شواهد نهاد ناظر/Certification؛ ماتریس قابلیت امضاشده.

امتیازدهی وزنی فقط پس از عبور از دروازه‌های سخت حقوقی و امنیتی انجام شود. امتیاز کل بالا هرگز نباید نبود مجوز، یکپارچگی نامعلوم بازی، مدل ناامن Wallet یا نبود تأیید حوزه قضایی را جبران کند.

## ۷. ناورداهای اتصال Canonical

این‌ها ناورداهای پیشنهادی بین دامنه‌ای‌اند و قرارداد تفصیلی هر دامنه باید آن‌ها را دقیق‌تر کند:

- Callbackهای Provider احراز‌شده، محافظت‌شده در برابر Replay و نسخه‌بندی‌شده‌اند؛ Tenant از تنظیمات اتصال معتبر استخراج می‌شود، نه Tenant ID داخل Payload غیرقابل‌اعتماد.
- Intent و شناسه پایدار Idempotency پیش از Mutation بیرونی ذخیره شود. هنگام Timeout، نتیجه UNKNOWN است و پیش از Retry باید Query/Reconcile شود؛ ارسال کورکورانه Bet/Round دوم ممنوع است.
- Provider Event ID، Domain Transaction ID، Game Round/Bet ID و Economic Effect ID جدا باشند. Deduplication انتقال نباید اثرهای اقتصادی مستقل را حذف کند.
- شواهد Payload خام و امضاشده، Hash، Timestamp منبع/دریافت، نسخه Provider و نسخه نگاشت Canonical حفظ شوند.
- Win/Settlement دیررس، Rollback، Void، Regrade و اصلاح دیلر/بازی تغییر وضعیت صریح و ثبت مالی جبرانی‌اند، نه ویرایش مخرب تاریخچه.
- به‌روزرسانی Realtime ضریب/امتیاز/بازی حقیقت مالی نیست. Bet پذیرفته‌شده، Round و اثر اقتصادی در System of Record canonical ثبت شوند.
- تطبیق مستمر و در پایان صورت‌حساب انجام شود: Bet پذیرفته/ردشده، Bet باز/تسویه‌شده، Debit/Credit/Rollback هر Round، سهم/جایزه Jackpot، صورت‌حساب Provider و رکورد دفترکل.
- معنای Seamless Wallet یا Transfer Wallet یک Provider را معادل Provider دیگر فرض نکنیم. هر Adapter باید Contract Test اجرایی داشته باشد.
- تجمیع موجودی بین Tenant یا Product ممنوع است. هر Wallet بازیکن، اگر در آینده تصویب شد، باید مالک حقوقی، ارز، محدودیت محصول و ثبت دوطرفه تغییرناپذیر صریح داشته باشد.
- Chat، Attribution افیلیت، Promotion و Notification نمی‌توانند Eligibility، Self-exclusion، رضایت بازاریابی، Limit یا Cooling-off را Override کنند.

## ۸. طراحی مبتنی بر Responsible Gambling و مقررات

تأیید قانونی به حوزه قضایی و نوع فعالیت وابسته است. تأمین‌کننده نرم‌افزار B2B، استودیوی بازی، Aggregator، Provider پلتفرم و اپراتور B2C ممکن است تعهد مجوز متفاوتی داشته باشند. مجوز تأمین‌کننده به‌صورت خودکار به مشتری یا محصول در یک قلمرو اجازه فعالیت نمی‌دهد.

موضوعات حداقلی طراحی شامل احراز سن و هویت؛ تحریم/PEP و AML در صورت شمول؛ Geolocation و کنترل قلمرو ممنوع؛ Self-exclusion و طرح‌های چنداپراتوری در صورت الزام؛ Limit واریز/زیان/زمان؛ Reality Check و Time-out؛ Cooling-off؛ Affordability و Customer Interaction در صورت شمول؛ شکایت و حل اختلاف؛ انصاف بازی/ RNG و افشای RTP؛ یکپارچگی ورزشی و پایش شرط‌بندی مشکوک؛ محدودیت تبلیغات/Affiliate؛ نگهداری سوابق و دسترسی نهاد ناظر است.

در بریتانیا، Remote Gambling and Software Technical Standards (RTS) کمیسیون قمار برای دارندگان مجوز مرتبط اپراتوری و نرم‌افزاری اعمال می‌شود؛ کمیسیون اعلام کرده به‌روزرسانی RTS از ۳۰ اکتبر ۲۰۲۶ لازم‌الاجرا شده است. استاندارد فنی و امنیتی باید متناسب با نقش و مجوز واقعی بررسی شود. منبع: [راهنمای RTS کمیسیون قمار بریتانیا](https://www.gamblingcommission.gov.uk/licensees-and-businesses/guide/remote-gambling-and-software-technical-standards).

در مالت، MGA میان Critical Gaming Supply و مجوز B2B مربوط به Game Provider/Back-office تمایز می‌گذارد؛ اطلاعات عمومی آن Fixed-odds Betting را Type 2 و برخی فعالیت‌های Pool/P2P را Type 3 معرفی می‌کند. شخصیت حقوقی دقیق، نوع تأمین و گستره حوزه قضایی باید طبق چارچوب جاری MGA بررسی شود. منابع: [مجوز Game Provider و Back-office در MGA](https://www.mga.org.mt/licensee-hub/applications/b2b-licences/game-providers-and-back-office/)، [مجوز Back-office در MGA](https://www.mga.org.mt/licensee-hub/applications/b2b-licences/back-office/).

استانداردهای GLI مرجع فنی مفیدند، نه مجوز جهانی. GLI-19 به سامانه‌های Interactive Gaming و GLI-33 به سامانه‌های Event Wagering می‌پردازد. استانداردهای فنی منتشرشده GCGRA امارات هر دو را فهرست می‌کند و مسئولیت انطباق را بر عهده اپراتورها می‌داند. قواعد نهاد ناظر و نسخه‌های پذیرفته‌شده آن همیشه اولویت دارند. منابع: [استانداردهای فنی GCGRA](https://www.gcgra.gov.ae/en/legislation-compliance/legislation/technical-standards/)، [فهرست استانداردهای GLI](https://www.trisigma.com/gli-standards/).

این سند چک‌لیست معماری است، نه مشاوره حقوقی یا نظر درباره مجوز یک بازار. پیش از فعال‌سازی هر محصول یا بازار، وکیل متخصص و نهاد ناظر مربوط باید نظر دهند.

## ۹. دروازه انتشار و فعال‌سازی

هر دامنه آینده باید از دروازه‌های مستقل عبور کند:

- **G0 — کشف:** مالک محصول، سفر کاربر، طبقه‌بندی دامنه، مدل اپراتور هدف و فرضیه‌های بازار مستند شوند.
- **G1 — امکان‌سنجی حقوقی:** یادداشت حقوقی به تفکیک بازار، نقش اپراتور/تأمین‌کننده، مسیر مجوز، مکانیزم ممنوع و قواعد تبلیغات/Affiliate توسط مشاور مسئول و مالک تصویب شود.
- **G2 — Due Diligence Provider:** شخصیت حقوقی، مجوز، مستند فنی، Sandbox، شرایط تجاری، Reference و پردازش داده بازبینی شود.
- **G3 — اثبات معماری:** Threat Model، معنای Wallet، Idempotency، تسویه/اصلاح، جداسازی Tenant، ظرفیت، Observability و بازیابی در Prototype محیط ساختگی قبول شوند.
- **G4 — Certification و Integration:** Certification مستقل/نظارتی لازم، تأیید Provider، Contract Testهای Adapter، Allowlist کاتالوگ بازی/Event و شواهد تطبیق تکمیل شود.
- **G5 — پایلوت کنترل‌شده:** فقط در نهاد دارای مجوز و بازار تأییدشده؛ Cohort/Limit محدود؛ پایش عملیات، پاسخ حادثه، کنترل Responsible Gambling و Rollback آزموده شود.
- **G6 — عرضه عمومی:** شواهد ممیزی، پشتیبانی/SLA، تطبیق مالی، گزارش نظارتی، مدیریت تغییر و تأیید انتشار مالک کامل شود.

این سند هیچ‌یک از دروازه‌ها را به‌معنای طی‌شده تلقی نمی‌کند. هیچ فعالیت با پول واقعی، ثبت مشتری، Credential یا Sandbox Provider، عرضه بازار یا کمپین تبلیغاتی مجاز نشده است.

## ۱۰. Backlog تحقیق و ادامه کار

برای هر دامنه باید PRD، State Machine، قرارداد Canonical Provider، Threat Model، نگاشت داده/دفترکل، ماتریس حوزه قضایی، کارت امتیاز Provider و برنامه تست تکرارپذیر Sandbox مستقل تهیه شود.

توالی پیشنهادی:
۱. اولویت تحویل Affiliate حفظ و مبانی مستقل محصول/مالی/امنیت آن تکمیل شود.
۲. کشف Lottery و بررسی Provider آن به‌عنوان دامنه‌ای مستقل تکمیل شود.
۳. تحقیق RFI برای Sportsbook: مقایسه Kambi، EveryMatrix/OddsMatrix، Altenar و گزینه‌های Enterprise منتخب از نظر Trading مدیریت‌شده/خودمدیریت، حقوق داده، API، تسویه و پوشش حوزه قضایی.
۴. تحقیق RFI برای Live Casino: مقایسه Evolution، Playtech Live و Pragmatic Play Live از نظر Studio، دسترس‌پذیری بازار، Streaming، اصلاح Round، Wallet Integration و شواهد ممیزی.
۵. تحقیق RFI برای محتوای RNG/E-Gaming: مقایسه استودیوی مستقیم و Aggregator، شامل Games Global، Relax Gaming، EveryMatrix CasinoEngine، Pragmatic Play و Play'n GO.
۶. پیش از ساخت، تصمیم شود Poker، شرط‌بندی Esports، Crash/Instant و Skill/Social Games ماژول‌های مستقل‌اند یا زیرحوزه‌های دارای مجوز جداگانه.

هیچ Providerی انتخاب نشده است. تا پیش از بررسی مستند Provider، تست Sandbox، قرارداد و شواهد حقوقی، ادعای سازگاری API یا آمادگی راه‌اندازی عمومی ممنوع است.

## ۱۱. منابع

- Kambi — https://www.kambi.com/
- EveryMatrix — https://everymatrix.com/
- OddsMatrix Data Services — https://omfeeds.everymatrix.com/
- Altenar — https://altenar.com/services/sportsbook/
- Evolution solutions — https://www.evolution.com/about/solutions
- Evolution 2025 annual report — https://www.evolution.com/wp-content/uploads/2026/04/Annual_Report_English_2026_04_01.pdf
- Playtech Live — https://www.playtech.com/products/live/
- Pragmatic Play — https://www.pragmaticplay.com/en/about-us/
- Games Global — https://www.gamesglobal.com/Company/About
- Relax Gaming — https://www.relax-gaming.com/
- Play'n GO — https://www.playngo.com/
- UK Gambling Commission RTS — https://www.gamblingcommission.gov.uk/licensees-and-businesses/guide/remote-gambling-and-software-technical-standards
- Malta Gaming Authority B2B licensing — https://www.mga.org.mt/licensee-hub/applications/b2b-licences/game-providers-and-back-office/
- UAE GCGRA technical standards — https://www.gcgra.gov.ae/en/legislation-compliance/legislation/technical-standards/
- GLI standards catalogue — https://www.trisigma.com/gli-standards/

**یادآوری وضعیت:** فقط افق محصول آینده و خط مبنای تحقیق است. نام Providerها گزینه کشف‌اند، نه توصیه یا تأیید. هیچ API، Sandbox، قرارداد، Certification، مجوز، Runtime یا سرویس Production برای Lottorito راستی‌آزمایی نشده است.
