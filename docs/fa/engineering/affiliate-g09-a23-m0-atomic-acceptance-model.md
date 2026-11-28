# G09-A23-M0 — مدل رسمی پذیرش اتمیک

**شناسه:** LOT-AFFILIATE-G09-A23-M0-001  
**نسخه:** ۰.۱.۱  
**وضعیت:** مدل محدود اجراشده با TLC؛ بازبینی مستقل و Refinement به Candidate انجام نشده است  
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

نتایج زیر در Run شماره ۶، روی Head دقیق `2ec0350e476e6ec3b90ce241bfedbe53a50799af` مشاهده شدند:

| پیکربندی | نتیجه واقعی TLC | جست‌وجوی ثبت‌شده |
|---|---|---|
| Baseline | بدون نقض Invariant؛ State-space کامل شد | ۸۷ Generated، ۵۲ Distinct، صفر در Queue، عمق ۷ |
| Partial Commit | نقض `PairAtomicity` در عمق ۳ | ۷ Generated، ۷ Distinct؛ پس از Counterexample متوقف شد |
| Duplicate Pair | نقض `AtMostOneReceipt` در عمق ۵ | ۳۴ Generated، ۲۴ Distinct؛ پس از Counterexample متوقف شد |
| Early Ack | نقض `AcceptedAckSoundness` در عمق ۳ | ۷ Generated، ۷ Distinct؛ پس از Counterexample متوقف شد |

هر سه Negative Control دقیقاً Oracle پیش‌بینی‌شده را فعال کردند. شمارش Mutantها State-space کامل نیست؛ TLC پس از یافتن Counterexample متوقف شد.

## ۶. Toolchain Pin و شواهد اجرای واقعی

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

Runner نسخه Java، Hash JAR، SHA-256 مدل و Configها، خروجی کامل هر Run و Metadata هر State Store را نگه می‌دارد. یک Worker، Seed ثابت و Metadata Directory مستقل برای هر پیکربندی استفاده می‌شود.

**Evidence اجراشده:** [GitHub Actions — G09 M0 Formal Model Run #11](https://github.com/tecpey/lottorito-platform/actions/runs/46170075939). نتیجه Job: SUCCESS. Toolchain: Eclipse Temurin OpenJDK 17.0.21.1؛ TLA+ Tools v1.7.4 / TLC 2.19؛ SHA-256 JAR همان Hash Pin بالا. Artifact: `g09-a23-m0-tlc-46170075939-1`؛ Digest: `sha256:c92d28c736ef367934a8823709ed9df11f81d9d131c4ce64b5df0420527e9e3b`.

SHA-256 ماژول و پیکربندی‌های اجراشده:

| فایل | SHA-256 |
|---|---|
| `G09M0AtomicAcceptance.tla` | `4740bc9d76c10ec76bf0bca00b5f829963b99365fef0a600a0886a2fe9cf2e6f` |
| `G09M0AtomicAcceptance.cfg` | `ad63aa16b0604b4c82d5f6c5e3435ccb5e6cd51a3fca994e303a3cd263132f7e` |
| `G09M0MutantPartialCommit.cfg` | `3fab9ce1b8d3b1b1bcdad8690d28db2e9254171cc5b962526df7ba82fefc7767` |
| `G09M0MutantDuplicatePair.cfg` | `7e24f26489c8e02c7798a298101d73efd71e49ca61ea383d5885aded91224f3a` |
| `G09M0MutantEarlyAck.cfg` | `975ecfbf8e14541311ada32e812413a918c6f8d759bfa3c9024258e7b5e39938` |

این نتیجه فقط به همین Module/Config/Toolchain/Bounds تعلق دارد؛ به پیاده‌سازی، Candidate، Durability یا رفتار Production تعمیم داده نمی‌شود.

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

## ۸. شواهد اجرای بازتولیدپذیر

**Run مبنای PR:** GitHub Actions Run `46170218651` — [G09 M0 Formal Model](https://github.com/tecpey/lottorito-platform/actions/runs/46170218651)  
**PR head:** `c9d2e2b7e3d80bf53a64e928df647bcd1cb20ebc`  
**Synthetic merge commit بررسی‌شده توسط pull_request runner:** `9a9aa076de9700717e4d41d14766d8414fdd2b5b`  
**Artifact:** [g09-a23-m0-tlc-46170218651-1](https://github.com/tecpey/lottorito-platform/actions/runs/46170218651/artifacts/15273631651)  
**Artifact ZIP SHA-256:** `0ae142aac63ca8bc9e9cdd1e802b98bdd8abf8e829045e3d99879ba92bd60d4d`

محیط و ابزار:
- TLA+ Tools release: `v1.7.4`
- TLC: `2.19`, revision `5a47802`, dated 2024-08-08
- TLA+ Tools JAR SHA-256: `936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88`
- Java: Eclipse Temurin `17.0.21.1+2`
- Runner: Ubuntu `24.04.5`, GitHub-hosted `ubuntu-24.04`
- TLC options: breadth-first search, one worker, seed 1, fp 0, 1 GiB heap.

نتایج:
| Case | نتیجه TLC | Stateهای تولیدشده / متمایز | عمق | نتیجه Oracle |
|---|---|---:|---:|---|
| Baseline | بدون نقض | 87 / 52 | 7 | مورد انتظار |
| Partial commit mutant | نقض `PairAtomicity` | 7 / 7 | 3 | کشف شد |
| Duplicate pair mutant | نقض `AtMostOneReceipt` | 34 / 24 | 5 | کشف شد |
| Early acknowledgement mutant | نقض `AcceptedAckSoundness` | 7 / 7 | 3 | کشف شد |

Hashهای فایل‌های مدل و Config که در Artifact `sha256-manifest.txt` ذخیره شده‌اند:
- TLA module: `4740bc9d76c10ec76bf0bca00b5f829963b99365fef0a600a0886a2fe9cf2e6f`
- Baseline config: `ad63aa16b0604b4c82d5f6c5e3435ccb5e6cd51a3fca994e303a3cd263132f7e`
- Partial-commit config: `3fab9ce1b8d3b1b1bcdad8690d28db2e9254171cc5b962526df7ba82fefc7767`
- Duplicate-pair config: `7e24f26489c8e02c7798a298101d73efd71e49ca61ea383d5885aded91224f3a`
- Early-ack config: `975ecfbf8e14541311ada32e812413a918c6f8d759bfa3c9024258e7b5e39938`

TLC parser و semantic processing ماژول را انجام داد و Invariantها را بررسی کرد؛ Type-system مستقل جداگانه اجرا نشده است. هر سه Mutant Counterexample واقعی و قابل‌بازتولید تولید کردند. Artifact شامل چهار لاگ TLC و Manifest هش‌هاست.

**مرز تفسیر:** GitHub Run به PR head فوق منتسب است، اما رویداد pull_request در Runner روی synthetic merge commit بالا اجرا شده است؛ این یک Integration Check روی ترکیب PR و base است، نه ادعای اجرای مستقیم روی branch tip به‌تنهایی.

بازبینی مستقل مدل و بررسی Refinement هنوز انجام نشده است؛
- هیچ Candidate یا Runtime ارزیابی نشده است؛
- ADR-002 همچنان PROPOSED و A11-F01..F08 باز می‌مانند؛
- A20-01..A20-28 همچنان NOT RUN هستند.

**نتیجه:** M0 در Bounds محدود خود با TLC بررسی شده و سه Mutation عمدی را با Oracleهای پیش‌بینی‌شده کشف کرده است. این نتیجه یک شاهد معتبر برای همان مدل محدود است، نه اثبات کلی پروتکل و نه Qualification پیاده‌سازی. بازبینی مستقل و Refinement به Candidate همچنان الزامی است.
