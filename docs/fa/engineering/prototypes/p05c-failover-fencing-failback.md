# P-05C — Failover، Writer Fencing و Failback

**شناسه سند:** LOT-PROT-P05C-001 | **نسخه:** ۰.۳.۰ | **وضعیت:** CI ساختگی روی Head نهایی PR با شناسه 194c565c1471474a1d908efb3dfda89035d9d4cc موفق شد؛ HA در Production تصویب نشده است

## اعتبار و مرز

P-05C یک آزمایش دورریختنی PostgreSQL 18.7 است که چرخه Replication فیزیکی دو گره، Gate ارتقای مبتنی بر توقف فرایند، Primitive محلی Compare-and-Swap برای Writer Epoch، رد Writer قدیمی/Lease منقضی، Timeline Rewind و Failback کنترل‌شده را بررسی می‌کند. این آزمایش طراحی HA برای Production، پیاده‌سازی Quorum/DCS، سامانه Hardware Fencing یا انتخاب فروشنده نیست. هیچ داده Production، Credential واقعی، وجه، منبع Cloud یا سامانه مشتری استفاده نمی‌شود.

## مبنای تحقیق

- راهنمای Failover در PostgreSQL 18 می‌گوید پس از ارتقای Standby باید از بازگشت Primary قدیمی به‌عنوان Writer جلوگیری شود؛ در غیر این صورت هر دو گره ممکن است خود را Primary بدانند و Timelineهای واگرا بسازند. این راهنما به Fencing خارجی از نوع STONITH و استفاده از pg_rewind برای بازگرداندن Primary قبلی اشاره می‌کند.
- مستندات pg_rewind در PostgreSQL 18 به Target با Shutdown تمیز، تاریخچه مشترک Cluster، Checksum یا wal_log_hints، فعال‌بودن full_page_writes و WAL تا نقطه واگرایی نیاز دارند. پس از Rewind، Target باید WAL را Replay کند و به‌عنوان Standby پیکربندی شود.
- مستندات Patroni نمونه‌ای از Leader Lock مبتنی بر Lease و Watchdog را برای زمانی نشان می‌دهند که HA Controller نتواند پس از ازدست‌دادن Leader Lock، PostgreSQL را به‌طور قابل اتکا متوقف کند.
- مستندات etcd تراکنش‌های اتمیک Compare-and-Swap، Revision، Lease و عملیات Linearizable را شرح می‌دهند؛ جریان Watch به‌تنهایی Linearizable نیست.

این منابع فقط مبنای آزمایش‌اند. PostgreSQL، Patroni، etcd یا هیچ DCS/Watchdog مشخصی برای Lottorito انتخاب نشده است.

## آزمایش ساختگی

### ۱. Replication فیزیکی دو گره

- دو Cluster مستقل PostgreSQL 18 با Data Checksum، wal_log_hints=on، full_page_writes=on، wal_level=replica و نگهداری WAL کافی برای Fixture کوچک بسازید.
- Primary را ایجاد کنید، Control Table و Event ساختگی را Seed کنید، یک pg_basebackup فیزیکی بگیرید و Standby را با Streaming Replication بالا بیاورید.
- تأیید کنید Standby در Recovery است و Event پایه را دریافت کرده است.

### ۲. Gate ارتقا و Failover

- زمانی که فرایند Primary قبلی هنوز فعال است، Promotion را امتحان کنید. Harness محلی باید آن را رد کند.
- Standby را متوقف کنید، یک Event ساختگی و صریحاً علامت‌گذاری‌شده را روی Primary Commit کنید که Standby امکان دریافت آن را ندارد، سپس فرایند Primary را به‌صورت تمیز متوقف کنید (شبیه‌سازی Process Fence محلی).
- Standby را بدون Primary قبلی Restart کنید، Read-only/Recovery بودن آن را بررسی و سپس Promote کنید.
- Writer Epoch را از ۱ به ۲ افزایش دهید و گره Promoteشده را Active Writer تعیین کنید.
- ثابت کنید Tail قدیمی Primary که Commit شده اما Replicate نشده بود، پس از Promotion وجود ندارد. این شاهد عمدیِ ریسک ازدست‌رفتن داده در Replication غیرهم‌زمان است، نه ادعای RPO صفر.

### ۳. Epoch Fencing و هم‌زمانی

یک ردیف Control محلی در دیتابیس، current_epoch، active_writer و lease_until ساختگی را نگهداری می‌کند. تابع ثبت Effect این ردیف را Lock می‌کند و هویت Writer، Epoch و اعتبار Lease را در همان تراکنش Insert اثر بررسی می‌کند.

- Writer A با Epoch شماره ۱ پس از آنکه Node B مالک Epoch شماره ۲ شد، رد شود.
- پس از انقضای Lease ساختگی، نوشتن رد شود.
- دو Promotion Claimant با یک Expected Epoch با هم رقابت کنند. Conditional Update اتمیک باید Epoch بعدی را دقیقاً به یک Claimant بدهد و Claimant دیگر هیچ Token دریافت نکند.
- فقط Effect متعلق به Writer جاری و Epoch جاری پذیرفته شود.

این بخش فقط Primitive بررسی Epoch در سطح تراکنش را نشان می‌دهد. ردیف مذکور داده برنامه‌ای Replicateشده است، نه DCS مستقل با Quorum یا مرجع خارجی Fencing. این Primitive به‌تنهایی نمی‌تواند جلوی پذیرش نوشتن محلی توسط Primary قدیمیِ جداافتاده از شبکه را بگیرد.

### ۴. Rewind و Failback کنترل‌شده

- Primary قبلیِ متوقف‌شده را با pg_rewind --write-recovery-conf به Node ارتقایافته Rewind کنید.
- آن را به‌عنوان Standby دوباره Join کنید و ثابت کنید Read-only می‌ماند، Event مربوط به Node ارتقایافته را دریافت می‌کند و Tail واگرای Replicateنشده را دیگر ندارد.
- منتظر بمانید Standby موقعیت WAL فعلی Primary جدید را Replay کند.
- منتظر بمانید Standby بازگشته Catch up شود، آن را متوقف کنید، یک Tail ساختگی دوم و صریحاً Replicateنشده روی Primary جاری بسازید، سپس Primary جاری را متوقف و گره بازگشته را Promote کنید. نبود Tail دوم را بررسی کنید، Writer Epoch را به ۴ افزایش دهید و Marker مربوط به Failback را بنویسید.
- روی Timeline واگرای دوم pg_rewind اجرا کنید؛ Primary قبلی را به‌عنوان Standby دوباره Join و حضور Marker مربوط به Failback و غیبت Tail دوم را بررسی کنید.
- دقیقاً یک Primary قابل نوشتن، یک Standby فقط‌خواندنی، Epoch شماره ۴ و Active Writer برابر Node A روی هر دو گره، و مشاهده Marker مربوط به Failback را بررسی کنید.

## معیارهای پذیرش

- P05C-REPLICATION: Event پایه به Standby برسد؛ Standby مقدار pg_is_in_recovery() = true گزارش کند.
- P05C-PROMOTION-GATE: تا وقتی فرایند Primary قبلی فعال است، Promotion رد شود.
- P05C-PROCESS-FENCE: فرایند Primary قبلی پیش از Promotion متوقف شده باشد.
- P05C-FAILOVER: Standby Promote و Writable شود؛ Epoch از ۱ به ۲ افزایش یابد.
- P05C-STALE-WRITER: هویت/Epoch مربوط به Writer قدیمی رد شود.
- P05C-LEASE: Lease منقضی‌شده نوشتن را رد کند.
- P05C-CAS: دو Claimant هم‌زمان دقیقاً یک برنده برای Epoch شماره ۳ داشته باشند.
- P05C-REWIND: Primary قبلی Rewind و در حالت Recovery دوباره Join شود؛ Event مربوط به Primary ارتقایافته حاضر و Tail عمداً Replicateنشده غایب باشد.
- P05C-READONLY: Standby Rewindشده نوشتن را رد کند.
- P05C-FAILBACK: Switchover کنترل‌شده نقش Primary را به Node A برگرداند؛ Epoch به ۴ برسد؛ Tail واگرای دوم با اجرای واقعی pg_rewind حذف و Primary قبلی به‌عنوان Standby Join شود.
- P05C-SINGLE-WRITER: پس از Failback دقیقاً یک گره Writable و گره دیگر در Recovery باقی بماند.

## ایمنی و محدودیت‌ها

- توقف فرایند فقط شبیه‌سازی Local CI برای Fence است؛ Fencing سخت‌افزاری/خاموش‌کردن Host، ایزوله‌سازی Instance ابری، Storage Fencing، Watchdog یا اثبات مقاومت در برابر Network Partition نیست.
- ردیف Epoch/Lease وضعیت برنامه‌ای در PostgreSQL محلی است، نه سامانه Consensus. هیچ etcd/Consul/Kubernetes DCS یا Patroni Controller اجرا نمی‌شود.
- آزمایش عمداً دو Event ساختگی را از دست می‌دهد؛ یکی در Failover و دیگری در Failback، که هر دو هنگام قطع بودن Standby دریافت‌کننده Commit شده‌اند. این موضوع پنجره فقدان داده در Replication غیرهم‌زمان را نشان می‌دهد و RPO عملیاتی را تعیین نمی‌کند.
- از دست‌رفتن Quorum، Writerهای هم‌زمان در Partition، Crash کنترلر، خرابی Watchdog، Split-brain در Storage، Failover چندمنطقه‌ای، Fencing سمت Provider، بار تراکنش هم‌زمان، ترافیک واقعی یا RTO Production آزمایش نمی‌شوند.
- پیش‌نیازهای pg_rewind و محدودیت‌های نگهداری WAL فقط با Clusterهای کوچک ساختگی آزمایش می‌شوند. شکست حین Rewind می‌تواند Target را غیرقابل استفاده کند و ممکن است Backup کامل تازه لازم باشد.
- RPO/RTO طبق LOT-QA-001 همچنان TBD هستند. موفقیت این آزمایش به معنی تصویب فناوری HA، توپولوژی، Provider، Runbook عملیاتی یا Rollout Production نیست.



## شواهد نهایی CI

- Integration مربوط به P-05C در PR با شناسه [45533992674](https://github.com/tecpey/lottorito-platform/actions/runs/45533992674)، Integration بازگشتی P-05B با شناسه [45533992779](https://github.com/tecpey/lottorito-platform/actions/runs/45533992779) و Documentation Governance با شناسه [45533992863](https://github.com/tecpey/lottorito-platform/actions/runs/45533992863) روی Head شماره `194c565c1471474a1d908efb3dfda89035d9d4cc` موفق شدند.
- pg_rewind اول واگرایی روی Timeline شماره ۱ را پیدا کرد و ۳۵ مگابایت کپی کرد. pg_rewind دوم واگرایی روی Timeline شماره ۲ را پیدا کرد و ۶۷ مگابایت کپی کرد؛ این موضوع مسیر Failback واقعاً واگرا را تأیید می‌کند، نه Rewind بدون تغییر را.
- Assertionهای نهایی PR موفق شدند: Physical Standby، Promotion Gate، Process Fence، افزایش Epoch، رد Writer قدیمی و Lease منقضی، دقیقاً یک Claimant هم‌زمان، حذف هر دو Tail واگرا، هر دو چرخه Rewind/Join، Read-only بودن Standby، Failback کنترل‌شده و Epoch نهایی شماره ۴ با Active Writer برابر Node A.

- Integration ایزوله P-05C با شناسه [45533778752](https://github.com/tecpey/lottorito-platform/actions/runs/45533778752) روی Head کد اجرایی `4884a3c38d2da8ea9ab9961dc095eb0ddd469f4d` موفق شد.
- آزمون دو Timeline واگرای واقعی و دو عملیات pg_rewind را کامل کرد. Rewind دوم ۶۷ مگابایت کپی کرد و ثابت کرد مسیر Failback کنترل‌شده صرفاً Rewind بدون تغییر نبوده است.
- Assertionهای Physical Standby، رد Promotion در زمان فعال بودن Primary قدیمی، Process Fence، Epoch از ۱ به ۲، رد Writer قدیمی و Lease منقضی، یک برنده CAS برای Epoch شماره ۳، حذف Tail واگرای اول، Read-only بودن Standby بازگشته، حذف Tail واگرای دوم، Rewind واقعی دوم و Epoch نهایی ۴ با Active Writer برابر Node A موفق شدند.
- همه نتایج فقط شواهد CI ساختگی هستند؛ Fencing در Production، رفتار Quorum و RPO/RTO همچنان اثبات نشده‌اند.

## منابع

- https://www.postgresql.org/docs/18/warm-standby-failover.html
- https://www.postgresql.org/docs/18/app-pgrewind.html
- https://www.postgresql.org/docs/18/hot-standby.html
- https://www.postgresql.org/docs/18/functions-admin.html
- https://patroni.readthedocs.io/en/latest/watchdog.html
- https://patroni.readthedocs.io/en/latest/dynamic_configuration.html
- https://patroni.readthedocs.io/en/latest/faq.html
- https://etcd.io/docs/v3.5/learning/api_guarantees/
- https://etcd.io/docs/v3.5/learning/api/
