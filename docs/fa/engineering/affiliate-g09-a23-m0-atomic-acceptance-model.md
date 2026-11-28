# G09-A23-M0 — مدل رسمی پذیرش اتمیک

**شناسه:** LOT-AFFILIATE-G09-A23-M0-001  
**نسخه:** ۰.۱.۰  
**وضعیت:** مدل اولیه پیشنهادی؛ اجرای TLC و بازبینی مستقل انجام نشده است  
**مدل:** `formal/G09M0AtomicAcceptance.tla`  
**پیکربندی مبنا:** `formal/G09M0AtomicAcceptance.cfg`  
**مبنای هنجاری:** ADR-002 §§۲، ۴، ۵، ۶ و ۷؛ A22 §۵؛ A23 §§۳، ۴، ۵ و ۷

## ۱. هدف و دامنه

M0 نخستین مدل محدود از خانواده مدل‌های A23 است. هدف آن بررسی قرارداد حداقلی پذیرش برای **یک Source Identity و یک Semantic Fingerprint ثابت** در حضور دو Caller هم‌زمان است:

1. Receipt و WorkItem یا هر دو Commit شوند یا هیچ‌کدام؛
2. برای Identity مدل‌شده بیش از یک Receipt یا WorkItem ساخته نشود؛
3. پاسخ ACCEPTED فقط پس از Commit جفت پایدار صادر شود؛
4. گم‌شدن پاسخ پس از Commit به UNKNOWN منجر شود، نه فرض شکست؛
5. Caller دوم با همان Identity/Fingerprint به نتیجه Duplicate تأییدشده برسد، نه پذیرش دوم.

M0 تصمیم‌های باز مالک، Tuple نهایی Identity، Fingerprint، Tenant/Installation، Durability/RPO، Isolation Level، Database، Queue یا Wire Status را تعیین نمی‌کند.

## ۲. انتزاع و فرض‌ها

| موضوع | انتزاع M0 |
|---|---|
| Callerها | دقیقاً دو Actor نمادین: callerA و callerB |
| Source Identity | یک Identity ثابت و مشترک میان Callerها |
| Semantic Fingerprint | یک Fingerprint ثابت و یکسان؛ Conflict در M0 خارج از دامنه است |
| Receipt / WorkItem | شمارنده Cardinality مستقل؛ هرکدام در بازه ۰ تا ۲ برای آشکارسازی Mutant |
| مرجع Commit | یک مرجع منطقی؛ Commit موفق یک Transition اتمیک است |
| هم‌زمانی | Interleaving گام‌های اتمیک؛ دو Begin می‌توانند پیش از Commit رخ دهند |
| Crash | قبل از Transition Commit یا بعد از Commit و پیش از Ack |
| Retry/UNKNOWN بدون رکورد | به M1 موکول شده است |
| Tenant، Authority Epoch، Worker و اثر خارجی | خارج از M0 |

**نکته انتزاعی مهم:** Transition اتمیک `CommitAcceptance` فرض می‌کند مرجع Persistence جفت را به‌صورت یک عملیات منطقی Commit می‌کند. این مدل به‌تنهایی ثابت نمی‌کند Candidate واقعی دو Write را در یک Transaction قرار داده، Cardinality را در لحظه Commit enforce کرده یا پس از Failover دوام می‌آورد. آن‌ها به Refinement و Evidence اجرایی بعدی نیاز دارند.

## ۳. متغیرها و Transitionها

- `receiptCount` و `workItemCount`: تعداد رکوردهای منطقی برای Identity واحد.
- `receiptOwner`: Caller برنده پذیرش اولیه.
- `txState[c]`: حالت تلاش هر Caller.
- `callerOutcome[c]`: نتیجه‌ای که Caller واقعاً مشاهده می‌کند.

Transitionهای اصلی:

- `BeginIngress`: آغاز تلاش، بدون Acceptance.
- `CommitAcceptance`: افزایش اتمیک هر دو Cardinality از صفر به یک.
- `ConfirmDuplicate`: تأیید Duplicate برای Caller دیگر، بدون Write جدید.
- `AbortBeforeCommit`: Abort قطعی و شناخته‌شده پیش از Commit.
- `CrashBeforeCommit`: Crash پیش از نقطه Commit؛ Caller نتیجه را UNKNOWN می‌بیند.
- `LoseCommitAck`: Commit انجام شده، اما Ack گم می‌شود و Caller UNKNOWN می‌بیند.
- `ReconcileUnknown`: اگر جفت پایدار در مدل موجود باشد، نتیجه موجود بازیابی می‌شود.

Crash درون Commit به‌صورت دو سوی نقطه Linearization انتزاع شده است: یا Crash پیش از Transition اتمیک رخ می‌دهد، یا Commit انجام شده و پاسخ پس از آن گم می‌شود. وضعیت نیمه‌Commit در مسیر سالم مدل مجاز نیست.

## ۴. Invariantهای بررسی‌شونده

| شناسه مدل | Invariant | معنای مورد انتظار |
|---|---|---|
| TypeOK | دامنه متغیرها | State در دامنه تعریف‌شده باقی بماند |
| PairAtomicity | `receiptCount = workItemCount` | جفت ناقص وجود نداشته باشد |
| AtMostOneReceipt | `receiptCount <= 1` | حداکثر یک Receipt |
| AtMostOneWorkItem | `workItemCount <= 1` | حداکثر یک WorkItem |
| ReceiptOwnerConsistency | سازگاری Owner | Owner فقط در حضور Receipt تعریف شود |
| CommittedRequiresPair | Commit مستلزم جفت | تلاش Commitشده بدون جفت نباشد |
| AcceptedAckSoundness | صداقت Ack | ACCEPTED فقط برای جفت Commitشده و Caller برنده |
| DuplicateAckSoundness | صداقت Duplicate | Duplicate فقط با جفت موجود و Owner دیگر |
| UnknownIsNotTerminalSuccess | حفظ UNKNOWN | UNKNOWN به موفقیت قطعی تبدیل نشود |

M0 فعلاً Liveness/Fairness را ادعا یا بررسی نمی‌کند. `CHECK_DEADLOCK FALSE` از تفسیر پایان طبیعی مدل محدود به‌عنوان نقض پیشرفت جلوگیری می‌کند؛ این گزینه هیچ ادعای Liveness ایجاد نمی‌کند.

## ۵. Negative Control و حساسیت Oracle

سه پیکربندی Mutant عمداً Transition ناسالم را فعال می‌کنند تا نشان دهند Invariantهای منتخب توان کشف نقض را دارند:

| پیکربندی | Mutation عمدی | نقض مورد انتظار |
|---|---|---|
| `G09M0MutantPartialCommit.cfg` | فقط Receipt Commit شود | PairAtomicity |
| `G09M0MutantDuplicatePair.cfg` | جفت دوم برای همان Identity ساخته شود | AtMostOneReceipt / AtMostOneWorkItem |
| `G09M0MutantEarlyAck.cfg` | Ack موفق پیش از Commit صادر شود | AcceptedAckSoundness |

این‌ها **انتظار طراحی** هستند، نه نتیجه اجراشده. تا اجرای TLC، Counterexample واقعی و تأیید حساسیت Oracle ثبت نشده است.

## ۶. Toolchain Pin و اجرای بازتولیدپذیر

Toolchain مبنای این مدل روی نسخه پایدار **TLA+ Tools v1.7.4 (TLC 2.19)** ثابت شده است؛ Java 11 یا جدیدتر لازم است. نسخه 1.8.0 که در زمان این بازبینی به‌صورت Pre-release/rolling منتشر شده، فعلاً وارد خط مبنا نمی‌شود. Hash مورد انتظار JAR:

`SHA-256: 936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88`

دریافت و اعتبارسنجی ابزار:

```bash
curl --fail --location --silent --show-error \
  https://github.com/tlaplus/tlaplus/releases/download/v1.7.4/tla2tools.jar \
  --output /tmp/tla2tools.jar
echo "936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88  /tmp/tla2tools.jar" | sha256sum --check -
```

اجرای چهار پیکربندی از ریشه Repository:

```bash
TLA2TOOLS_JAR=/tmp/tla2tools.jar \
TLC_OUT_DIR=/tmp/g09-m0-results \
bash scripts/formal/run_g09_m0.sh
```

Runner نسخه Java، Hash JAR، خروجی کامل هر Run و Metadata هر State Store را نگه می‌دارد. یک Worker، Seed ثابت و Metadata Directory مستقل برای هر پیکربندی استفاده می‌شود. Baseline باید با خروجی موفق TLC تمام شود؛ سه Mutant باید دقیقاً Invariant پیش‌بینی‌شده را نقض کنند. Exit Code غیرمنتظره، پیام متفاوت، Parser Error یا نبود Counterexample مورد انتظار، شکست Gate است.

برای هر Run باید Hash ماژول و Config، خروجی کامل TLC، State/Transition count، زمان/منابع، وضعیت پایان و Counterexampleها ذخیره شوند. اگر Mutant کشف نشود، Oracle یا Mutation باید بازبینی شود؛ آن را PASS تلقی نکنید.

## ۷. محدودیت‌ها و مسیر توسعه

M0 موارد زیر را اثبات نمی‌کند و عمداً به مدل‌های بعدی می‌سپارد:

- Arbitration تلاش اولیه In-flight در برابر Retry، Negative Read و UNKNOWN بدون رکورد: **M1**؛
- Authority Epoch، Split-brain، Promotion و بازگشت Writer قدیمی: **M2**؛
- Lease، Claim، Generation و Worker Fencing: **M3**؛
- Outbox، Consumer و اثر Receiver خارجی: **M4**؛
- Restore، Tombstone و Replay Horizon: **M5**؛
- Tenant/Principal و مرز مجوز: **M6**؛
- Liveness، Resource Pressure و Fairness: **M7**.

به‌ویژه، M0 فرض نمی‌کند مشاهده نبود رکورد، خاتمه Transaction اولیه را ثابت می‌کند. این Race موضوع اصلی M1 است. همچنین M0 مدل Tenant-isolation یا جلوگیری از افشای وجود Identity در Tenant دیگر نیست.

## ۸. وضعیت شواهد

- فایل TLA+ و Configها ثبت شده‌اند؛
- TLC در این گام اجرا نشده است؛
- Syntax/Type Check رسمی هنوز انجام نشده است؛
- State-space count و Counterexample واقعی وجود ندارد؛
- Negative Controlها فقط طراحی شده‌اند؛
- هیچ Candidate یا Runtime ارزیابی نشده است؛
- ADR-002 همچنان PROPOSED و A11-F01..F08 باز می‌مانند؛
- A20-01..A20-28 همچنان NOT RUN هستند.

**نتیجه:** M0 یک مدل اولیه قابل اجرا برای بررسی پذیرش اتمیک تعریف می‌کند؛ تا اجرای TLC و سپس Refinement به رفتار Candidate، هیچ ادعای صحت پیاده‌سازی یا Qualification مجاز نیست.
