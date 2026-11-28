# G09-A23-M1 — مدل داوری Commit نامعلوم و Retry هم‌زمان

**شناسه سند:** LOT-AFFILIATE-G09-A23-M1-001  
**نسخه:** ۰.۱.۶  
**وضعیت:** مدل محدود با TLC اجرا شده؛ بازبینی مستقل و Refinement به Candidate همچنان باز  
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

- PostgreSQL مستند می‌کند که هنگام درج کلید Unique متعارض با Transaction هنوز Commitنشده، درج‌کننده باید منتظر تعیین تکلیف Transaction بماند؛ اگر آن Transaction Rollback شود، Conflict وجود ندارد و اگر Commit شود، نقض یکتایی رخ می‌دهد. این رفتار به‌عنوان اصل طراحی مهم است، اما نسخه PostgreSQL و پیاده‌سازی Candidate هنوز انتخاب/تأیید نشده‌اند. [PostgreSQL — Index Uniqueness Checks](https://www.postgresql.org/docs/current/index-unique-checks.html).
- مستندات PostgreSQL برای `INSERT ... ON CONFLICT` نیز توضیح می‌دهند که نتیجه یک Transaction هم‌زمان ممکن است در Snapshot عادی قابل مشاهده نباشد، اما مسیر Unique Conflict باید آن Transaction را تعیین تکلیف کند. این یک مثال DB-specific است، نه مجوز انتخاب نسخه یا دستور SQL برای Lottorito. [PostgreSQL — INSERT](https://www.postgresql.org/docs/current/sql-insert.html).
- Google Spanner صریحاً Unknown Commit Status را توضیح می‌دهد: Timeout ممکن است قبل یا بعد از Commit رخ دهد؛ Retry بدون Deduplication می‌تواند عملیات تجاری را دوباره اجرا کند. [Spanner — Unknown Commit Status](https://docs.cloud.google.com/spanner/docs/queues/queues-at-most-once).
- AWS Builders’ Library بر حفظ شناسه درخواست و پارامترهای اولیه برای Idempotency تأکید دارد؛ تکرار همان شناسه با Intent متفاوت باید به‌صورت mismatch تشخیص داده شود. [Making retries safe with idempotent APIs](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).

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

## ۸. آخرین شواهد اجرای قابل‌بازتولید

**آخرین PR head:** `a6831c4be9bb904efe0ccf7809e5179db26661a1`
**Synthetic merge commit اجراشده:** `fe42d58c84388ba3f2bc3b4b503e5eb220f1d52b` (Base: `f032065f47fe85de2aabf8d47565a57af6af3ae9`)
**GitHub Actions Run:** [46172262017 — G09 M1 Unknown Commit Arbitration](https://github.com/tecpey/lottorito-platform/actions/runs/46172262017) — PASS
**Artifact:** [g09-a23-m1-tlc-46172262017-1](https://github.com/tecpey/lottorito-platform/actions/runs/46172262017/artifacts/15273828706)
**Artifact ZIP SHA-256:** `97a5d879f4ddfba8ddb133c25232ce3ec34985c4d1609bd9c7c990eaadc29fd7`

Toolchain: TLA+ Tools v1.7.4 / TLC 2.19؛ JAR SHA-256 `936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88`؛ Eclipse Temurin 17.0.21.1؛ Ubuntu 24.04؛ BFS، یک Worker، Seed=1، fp=0، Heap برابر 1 GiB. Checkout و Upload Artifact با SHA ثابت و `persist-credentials: false`.

| Case | نتیجه TLC | Generated / Distinct | Depth |
|---|---|---:|---:|
| Baseline — fingerprint یکسان | بدون نقض | 25 / 19 | 8 |
| Baseline — fingerprint متفاوت | بدون نقض | 25 / 19 | 8 |
| Unsafe retry در زمان in-flight | `NoRetryCommitWhileOriginalInflight` نقض شد | 18 / 14 | 6 |
| Double commit | `ReceiptCardinality` نقض شد | 25 / 19 | 7 |
| Premature conflict | `ConflictSoundness` نقض شد | 14 / 12 | 5 |

Documentation Governance Run [46172262013](https://github.com/tecpey/lottorito-platform/actions/runs/46172262013) و Affiliate Contract Validation Run [46172262015](https://github.com/tecpey/lottorito-platform/actions/runs/46172262015) نیز روی همین Head موفق شدند.

**مرز تفسیر:** این شواهد فقط مدل محدود M1 و فرض‌هایش را بررسی می‌کند؛ رفتار واقعی دیتابیس، تعریف definitive abort در Adapter، Candidate refinement، Jepsen/History checking، Simulation و Runtime هنوز اثبات نشده‌اند. Run روی Synthetic merge انجام شده است.

## ۹. محدودیت‌ها و گام بعدی

- M1 هنوز مدل Database خاص یا تضمین Lock/Unique Index واقعی نیست؛ این‌ها در Refinement و آزمون Candidate بررسی می‌شوند.
- مدل، «مرجع قطعی Abort» را به‌صورت یک State انتزاع می‌کند؛ اثبات اینکه Adapter واقعی چه پاسخ‌هایی را می‌تواند به‌عنوان Abort قطعی طبقه‌بندی کند، هنوز باز است.
- M1 وضعیت UNKNOWN بدون Receipt را در حضور Transaction فعال حل‌شده فرض نمی‌کند؛ فقط انتظار/عدم پذیرش مجدد را مدل می‌کند.
- M2 باید Authority Epoch، Promotion و Writer قدیمی را پوشش دهد.
- Jepsen/History Checker و تست DB واقعی هنوز اجرا نشده‌اند.

**وضعیت شواهد:** دو Baseline بدون نقض خاتمه یافتند و سه Negative Control Counterexampleهای مورد انتظار را تولید کردند. این شواهد به Bounds مدل محدود است؛ بازبینی مستقل و Refinement به Candidate انجام نشده‌اند. هیچ Candidate، Runtime، Partner، عملیات مالی، Production، Merge یا Deploy از این سند مجاز نمی‌شود.
