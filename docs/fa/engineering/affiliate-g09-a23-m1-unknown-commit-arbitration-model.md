# G09-A23-M1 — مدل داوری Commit نامعلوم و Retry هم‌زمان

**شناسه سند:** LOT-AFFILIATE-G09-A23-M1-001  
**نسخه:** ۰.۱.۰  
**وضعیت:** مدل اولیه پیشنهادی؛ اجرای TLC و بازبینی مستقل در انتظار CI  
**مدل:** `formal/G09M1UnknownCommitArbitration.tla`  
**پیکربندی‌ها:** دو Baseline و سه Negative Control در `formal/G09M1*.cfg`  
**مبنای هنجاری:** ADR-002، A22 و A23؛ M0

## ۱. مسئله‌ای که M1 جدا می‌کند

M0 نشان داد پس از Commit، گم‌شدن Ack باید به UNKNOWN منجر شود. M1 Race خطرناک‌تر را مدل می‌کند: Caller اول هنوز ممکن است در Database در حال اجرای Transaction باشد، ولی Caller به‌علت Timeout نتیجه را UNKNOWN دیده و Caller دوم Retry را آغاز کند.

**Read که Receipt را نمی‌بیند، اثبات نمی‌کند Transaction اول Abort شده است.** این دو گزاره باید در مدل از هم جدا بمانند:

- `receiptCount = 0`: در Snapshot مشاهده‌شده Receipt قابل‌مشاهده‌ای وجود ندارد؛
- `originalStatus = "aborted"`: مرجع Transaction به‌صورت قطعی پایان Abort را اعلام کرده است.

تنها گزاره دوم اجازه می‌دهد Retry به‌عنوان تلاش جدید برای پذیرش Commit شود.

## ۲. شواهد مرجع و مرز کاربرد

- PostgreSQL مستند می‌کند که هنگام درج کلید Unique متعارض با Transaction هنوز Commitنشده، درج‌کننده باید منتظر تعیین تکلیف Transaction بماند؛ اگر آن Transaction Rollback شود، Conflict وجود ندارد و اگر Commit شود، نقض یکتایی رخ می‌دهد. این رفتار به‌عنوان اصل طراحی مهم است، اما نسخه PostgreSQL و پیاده‌سازی Candidate هنوز انتخاب/تأیید نشده‌اند. [PostgreSQL — Index Uniqueness Checks](https://www.postgresql.org/docs/current/index-unique-checks.html). <Cite refs={["turn809426search4"]}/>
- مستندات PostgreSQL برای `INSERT ... ON CONFLICT` نیز توضیح می‌دهند که نتیجه یک Transaction هم‌زمان ممکن است در Snapshot عادی قابل مشاهده نباشد، اما مسیر Unique Conflict باید آن Transaction را تعیین تکلیف کند. این یک مثال DB-specific است، نه مجوز انتخاب نسخه یا دستور SQL برای Lottorito. [PostgreSQL — INSERT](https://www.postgresql.org/docs/current/sql-insert.html). <Cite refs={["turn809426search1","turn809426search3"]}/>
- Google Spanner صریحاً Unknown Commit Status را توضیح می‌دهد: Timeout ممکن است قبل یا بعد از Commit رخ دهد؛ Retry بدون Deduplication می‌تواند عملیات تجاری را دوباره اجرا کند. [Spanner — Unknown Commit Status](https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once). <Cite refs={["turn809426search0","turn809426search2"]}/>
- AWS Builders’ Library بر حفظ شناسه درخواست و پارامترهای اولیه برای Idempotency تأکید دارد؛ تکرار همان شناسه با Intent متفاوت باید به‌صورت mismatch تشخیص داده شود. [Making retries safe with idempotent APIs](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/). <Cite refs={["turn809426search15"]}/>

این منابع مبنای فرضیه و طراحی‌اند؛ هیچ‌کدام به‌تنهایی Candidate یا معماری نهایی را انتخاب نمی‌کنند.

## ۳. دامنه و انتزاع

M1 یک Source Identity ثابت، یک تلاش اصلی، یک Retry و یک مرجع Commit را مدل می‌کند. پارامتر `SameFingerprint` دو حالت Baseline را می‌سازد:

1. همان Identity با همان Fingerprint: Retry پس از Commit اصلی باید Duplicate تأییدشده شود؛
2. همان Identity با Fingerprint متفاوت: Retry پس از Commit اصلی باید Conflict تأییدشده شود.

اگر Transaction اصلی به‌صورت قطعی Abort شود و Receipt ایجاد نشده باشد، Retry می‌تواند با Fingerprint خودش تنها Receipt را Commit کند؛ حتی اگر Fingerprint آن با تلاش اصلی متفاوت باشد، چون تلاش اصلی هرگز Canonical نشده است.

M1 Tenant، Installation، Source Epoch، چند Identity، Lease/Worker، Outbox، Receiver خارجی، Retention و Restore را مدل نمی‌کند.

## ۴. متغیرهای کلیدی

- `originalStatus`: `not_started | inflight | committed | aborted`
- `originalOutcome`: نتیجه‌ای که Caller اول مشاهده می‌کند؛ Timeout و Commit دو State مستقل‌اند.
- `retryStatus` و `retryOutcome`: وضعیت اجرای Retry و پاسخ مشاهده‌شده آن.
- `receiptCount`: تعداد Receiptهای ثبت‌شده برای Identity؛ بازه ۰ تا ۲ تا Mutant بتواند Duplicate را آشکار کند.
- `receiptOwner` و `receiptFingerprints`: مالک و Fingerprintهای Receiptهای ثبت‌شده.
- `retryObservedAbsent`: فقط مشاهده عدم وجود Receipt؛ نه مدرک Abort.
- `retryCommittedWhileOriginalInflight`: ثبت وقوع Commit غیرمجاز Retry در حالی که تلاش اصلی هنوز In-flight بوده است.

## ۵. Transitionهای اصلی

- `StartOriginal` و `TimeoutOriginal`: شروع تلاش اصلی و تبدیل Timeout مشاهده‌شده به UNKNOWN، بدون تغییر وضعیت واقعی Transaction.
- `StartRetry`: آغاز Retry پس از UNKNOWN؛ تلاش اصلی ممکن است هنوز In-flight یا قبلاً Commitشده باشد.
- `ObserveAbsent`: مشاهده نبود Receipt؛ Retry به `retry_wait` می‌رود و حق Commit نمی‌گیرد.
- `CommitOriginal` / `AbortOriginal`: تعیین تکلیف قطعی Transaction اصلی.
- `LoseOriginalAck`: Commit انجام شده، ولی Caller پاسخ را UNKNOWN می‌بیند.
- `ObserveCommitted`: پس از Commit اصلی، Fingerprint برابر به Duplicate و Fingerprint متفاوت به Conflict تبدیل می‌شود.
- `CommitRetryAfterConfirmedAbort`: تنها مسیر سالمی که Retry را پس از Abort قطعی اصلی به پذیرش می‌رساند.
- `AckRetry`: Ack فقط پس از Commit Receipt توسط Retry صادر می‌شود.

## ۶. Invariantها و هدف آزمون

| Invariant | قرارداد |
|---|---|
| `TypeOK` | دامنه Stateها معتبر بماند |
| `ReceiptShape` | Cardinality، Owner و Fingerprintها با هم سازگار باشند |
| `ReceiptCardinality` | برای Identity بیش از یک Receipt ثبت نشود |
| `OriginalAckSoundness` | Ack اصلی فقط با Receipt اصلی Commitشده معتبر است |
| `RetryAckSoundness` | Retry فقط پس از Abort قطعی تلاش اصلی می‌تواند ACCEPTED شود |
| `DuplicateSoundness` | Duplicate فقط پس از Commit Canonical با Fingerprint برابر مجاز است |
| `ConflictSoundness` | Conflict فقط پس از Commit Canonical با Fingerprint متفاوت مجاز است |
| `NoRetryCommitWhileOriginalInflight` | Retry در زمان In-flight بودن تلاش اصلی Commit نشود |
| `NoTerminalRetryResolutionWhileOriginalInflight` | تا وقتی تلاش اصلی In-flight است، Retry به Accepted/Duplicate/Conflict قطعی نرسد |

M1 ادعای Liveness یا زمان محدود برای Resolve کردن UNKNOWN ندارد. `retry_wait` می‌تواند تا دریافت نتیجه قطعی مرجع Commit باقی بماند.

## ۷. Negative Controlها

| Config | خرابی تزریق‌شده | نقض مورد انتظار |
|---|---|---|
| `G09M1MutantUnsafeRetry.cfg` | Retry، مشاهده Absence را اشتباهاً مجوز Commit می‌داند | `NoRetryCommitWhileOriginalInflight` |
| `G09M1MutantDoubleCommit.cfg` | همان Retry ناامن، سپس Commit تلاش اصلی | `ReceiptCardinality` |
| `G09M1MutantPrematureConflict.cfg` | Fingerprint متفاوت پیش از Canonical Commit به Conflict تبدیل می‌شود | `ConflictSoundness` |

دو Baseline جداگانه همان Fingerprint و Fingerprint متفاوت را بررسی می‌کنند. Negative Controlها باید Oracle را حساس نشان دهند؛ اگر نقض مورد انتظار کشف نشود، M1 قابل‌قبول نیست.

## ۸. محدودیت‌ها و گام بعدی

- M1 هنوز مدل Database خاص یا تضمین Lock/Unique Index واقعی نیست؛ این‌ها در Refinement و آزمون Candidate بررسی می‌شوند.
- مدل، «مرجع قطعی Abort» را به‌صورت یک State انتزاع می‌کند؛ اثبات اینکه Adapter واقعی چه پاسخ‌هایی را می‌تواند به‌عنوان Abort قطعی طبقه‌بندی کند، هنوز باز است.
- M1 وضعیت UNKNOWN بدون Receipt را در حضور Transaction فعال حل‌شده فرض نمی‌کند؛ فقط انتظار/عدم پذیرش مجدد را مدل می‌کند.
- M2 باید Authority Epoch، Promotion و Writer قدیمی را پوشش دهد.
- Jepsen/History Checker و تست DB واقعی هنوز اجرا نشده‌اند.

**وضعیت شواهد:** مدل و Configها تألیف شده‌اند؛ تا پایان CI و بررسی لاگ‌ها هیچ PASS یا Counterexample ادعا نمی‌شود. هیچ Candidate، Runtime، Partner، عملیات مالی، Production، Merge یا Deploy از این سند مجاز نمی‌شود.
