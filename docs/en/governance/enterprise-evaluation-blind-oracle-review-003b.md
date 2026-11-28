# LOT-EVAL-RDM-003B — Blind Independent Oracle Review Packet

**Document ID:** LOT-EVAL-RDM-003B-001  
**Version:** 0.1.0  
**Date:** 2026-11-28  
**Status:** SUPERSEDED — blind external-review protocol not used; see author-led second-pass review report  
**Parent:** LOT-EVAL-001 v0.3.0  
**Related:** LOT-EVAL-AVT-001 v0.2.0; LOT-EVAL-RDM-003A v0.1.0; LOT-EVAL-RDM-001; LOT-EVAL-RDM-002  
**Review mode:** Blind, independent expected-outcome derivation; no implementation inspection

## 1. Historical purpose and supersession

This packet was originally drafted for a blind external reviewer. The project owner has since directed that the authoring AI conduct the adversarial reviews directly because no second person is available.

The blind protocol is therefore **not being executed**. The authoring AI has prior access to RDM-003A, RDM-001, their expected outputs and prior findings; it cannot truthfully claim a blind oracle derivation, second-person independence or formal IV&V. This packet is retained as historical design evidence only and must not be used as an active external-review gate.

The active review record is [LOT-EVAL-RDM-003B Author-led adversarial second-pass review](enterprise-evaluation-author-led-second-pass-review-003b.md). It records the actual findings, limitations and correction sequence. The 35 decision-table rows were also found not to have their condition inputs in this packet/worksheet; this gap is recorded as AR-02.

The reviewer must not receive or inspect, before freezing their oracle:
- LOT-EVAL-RDM-003A rule descriptions, decision-table outputs, ambiguity dispositions or rule-to-test conclusions;
- LOT-EVAL-RDM-001 source code, expected outputs, test logs or mutation results;
- LOT-EVAL-RDM-002 findings or the author's model/oracle comparisons;
- any author-prepared answer key or completed worksheet.

The reviewer may receive this packet, the frozen parent standard, the frozen AVT matrix **only through its case identifiers and input/attack descriptions**, and the blank worksheet. If access to the full AVT matrix would reveal its expected-oracle column, provide the reviewer a redacted input-only extract instead.

## 2. Frozen source baseline

The source snapshot is anchored to repository commit:

`4443ef5336935310f034419d72967dec3d86a21a`

Repository: `tecpey/lottorito-platform`  
Branch at freeze: `docs/enterprise-evaluation-standard-v1`

The following Git blob SHAs identify the exact source files used to assemble this packet. A reviewer must verify each file at the frozen commit, not at a moving branch head.

| Source | Path | Frozen blob SHA |
|---|---|---|
| Parent standard EN | `docs/en/governance/enterprise-evaluation-standard.md` | `8bed42544e29f25abcf191e1bb38463e3e553d03` |
| Parent standard FA | `docs/fa/governance/enterprise-evaluation-standard.md` | `0bc75b12c02022d3a302f122b11ac79d0bb00aa8` |
| AVT matrix EN | `docs/en/governance/enterprise-evaluation-adversarial-test-matrix-001.md` | `319b4e713d1be54207bdbfadd19b3eb32ce773a7` |
| AVT matrix FA | `docs/fa/governance/enterprise-evaluation-adversarial-test-matrix-001.md` | `52ba728e37f667429b0ac552f9683ad6491df239` |

**Freeze rule:** if any source blob differs, stop. Create a new packet version and re-baseline; do not silently substitute a later file. The RDM-003A catalogue and all author-derived outputs are excluded from the reviewer bundle and must not be disclosed before the independent oracle is frozen.



**Blindness limitation:** this is a controlled-disclosure protocol, not a technical access-control boundary. The repository is public, so a reviewer with unrestricted repository access could independently browse excluded artifacts. The coordinator must therefore deliver a curated/offline reviewer bundle, obtain a prior-access declaration, and avoid directing the reviewer to the full repository during the blind pass. If prior exposure cannot be ruled out, record the exercise as an independent challenge (not blind oracle derivation) and disclose that limitation.

## 3. Reviewer competence and independence declaration

Before work begins, the reviewer must record:
- relevant expertise in requirements analysis, software assurance/testing, risk/governance or the specific decision domains reviewed;
- prior involvement, if any, in authoring LOT-EVAL-001, AVT-001, RDM-001, RDM-002 or RDM-003A;
- employment, reporting, financial or other relationships that could impair objectivity;
- whether they had prior access to the author’s expected outcomes or implementation;
- any language limitation affecting interpretation of the English/Persian normative text.

A reviewer who authored the model or derived expected outputs cannot be represented as independent for this exercise. A peer reviewer may provide a useful alternate interpretation, but this packet alone does not establish formal independent assurance or NASA-style technical, managerial and financial independence.

## 4. Blind-review protocol

1. Verify the frozen commit and blob SHAs in §2.
2. Read the parent standard v0.3.0 and identify normative modal force: MUST, MUST NOT, MAY, conditional permission and scope limitations.
3. Derive each expected outcome from the parent clause(s) and the case input alone. Do not infer intent from implementation behavior.
4. For every case, state one of: deterministic outcome; conditional outcome with explicit conditions; unresolved/underspecified; infeasible input combination (with reason).
5. Cite exact parent section and quote only the minimum wording needed to explain the interpretation.
6. Record assumptions, missing facts, alternative plausible readings, confidence and the exact point at which a decision must stop/escalate.
7. For decision-table rows, classify the input combination as feasible, infeasible or unresolved before assigning an output.
8. Do not consult the RDM-003A catalogue or any model output until the worksheet is complete, signed and frozen.
9. Return the completed worksheet and evidence of the frozen file hash to the review coordinator. Preserve the original; corrections must be a new revision with a change note.
10. Only after the independent oracle is frozen may a separate reconciliation compare it with the author’s catalogue and executable model.

**No coaching:** the coordinator must not disclose the author’s likely answer, unresolved-issue list, model behavior or prior findings during the blind pass. Clarification questions must be answered by pointing to frozen normative source text, not by explaining the intended implementation.

## 5. Scope register — atomic rule IDs (IDs only)

For each rule ID below, the reviewer must independently identify the operative requirement, input facts, permissible outputs, stop conditions and source clause. The rule descriptions and author-derived interpretations are intentionally withheld.

| Rule ID | Parent clause reference |
|---|---|
| RDM-R01 | §§2.1, 4 |
| RDM-R02 | §§4, 17.10.3 |
| RDM-R03 | §§4, 17.10.3 |
| RDM-R04 | §7 |
| RDM-R05 | §7 |
| RDM-R06 | §§8.3, 17.10.1 |
| RDM-R07 | §8.3 |
| RDM-R08 | §§8.3, 17.10.1 |
| RDM-R09 | §§8.3, 17.10.1 |
| RDM-R10 | §8.3 |
| RDM-R11 | §§8.3, 17.10.1 |
| RDM-R12 | §§8.3, 17.10.1 |
| RDM-R13 | §§5.1, 17.10.2 |
| RDM-R14 | §§5.2, 17.10.2 |
| RDM-R15 | §17.10.4 |
| RDM-R16 | §17.10.4 |
| RDM-R17 | §17.10.6 |
| RDM-R18 | §§4, 7, 8.3, 17.10 |

## 6. Blind case register — inputs only, no answer key

The following cases identify attack conditions and synthetic inputs. They intentionally omit expected outputs and failure-oracle wording.

| Case ID | Rule family | Input / attack presented to reviewer |
|---|---|---|
| AVT-01 | RDM-R06, R11, R12 | A required criterion has no supplied evidence. Assess one case where the criterion is material and one where it is asserted to be non-material. |
| AVT-02 | RDM-R06, R07 | The only evidence is a supplier assertion or demonstration; no independently verifiable artifact is supplied. |
| AVT-03 | RDM-R07 | Complete, current, scope-matched negative test evidence demonstrates that a required capability is absent or unacceptable. |
| AVT-04 | RDM-R07 | Complete, current evidence is offered against a criterion and threshold written before candidate review. |
| AVT-05 | RDM-R06, R13 | Evidence is expired, internally contradictory or outside the requested entity/version/environment. |
| AVT-06 | RDM-R01–R03 | An isolated synthetic experiment has no real users, funds, production access or partner connection; determine the effect of any independent tier trigger. |
| AVT-07 | RDM-R02, R04 | Requested operational permission enables material movement of customer funds, consequential ledger/commission posting or regulated-market access. |
| AVT-08 | RDM-R01, R02 | An identity decision can materially grant/remove access to customer funds or privileged activity, or cause severe harm. |
| AVT-09 | RDM-R01–R03 | Jurisdiction, scope or requested permission is unresolved and a higher tier may apply. |
| AVT-10 | RDM-R15 | The same risk scenario is assessed over two different time horizons. |
| AVT-11 | RDM-R15, R16 | Two scenarios share a likelihood band but have materially different impact dimensions. |
| AVT-12 | RDM-R16 | Compare scenario A with ordinal pair L1/I5 and scenario B with L5/I1. |
| AVT-13 | RDM-R15, R16 | A control is claimed to reduce residual risk, but no evidence of operation is supplied. |
| AVT-14 | RDM-R09, R10 | Candidate scores are already visible when an N/A request is submitted. |
| AVT-15 | RDM-R04, R05, R09 | A mandatory legal, security or financial gate is marked N/A; assess both gate-level applicability and a genuinely changed decision scope. |
| AVT-16 | RDM-R09, R10 | A preference criterion is genuinely inapplicable and approved before scoring; original weights total 100. |
| AVT-17 | RDM-R09, R10 | Applying an approved N/A changes relative candidate ranking; all candidates and the same criterion set are in scope. |
| AVT-18 | RDM-R06, R08 | A compound criterion has five atomic subcriteria; evidence supports only two. |
| AVT-19 | RDM-R06, R08, R11 | Four of five atoms are supported; the unsupported atom is material. |
| AVT-20 | RDM-R08, R13 | Evidence covers one version, region, tenant or population; the claim requests a wider scope. |
| AVT-21 | RDM-R08 | A compound criterion has a critical dependency that cannot be discarded during decomposition. |

## 7. Decision-table input challenge set

For each row below, derive the outcome independently. The table intentionally contains conditions only; the output column is reserved for the reviewer. Treat Unknown as a distinct input value, not as False. If a combination is infeasible, explain why rather than silently ignoring it.

### DT-01 — tier selection

| Row | T3 trigger | T2 trigger | T1 trigger | Higher tier plausibly unresolved | Bounded synthetic experiment |
|---|---|---|---|---|---|
| 01 | Yes | Any | Any | Any | Any |
| 02 | No | Yes | Any | Any | Any |
| 03 | No | No | Yes | No | Any |
| 04 | No | No | No | No | Yes or No |
| 05 | No/Unknown | Any | Any | Yes | Any |
| 06 | Unknown | Unknown | Unknown | Unknown | Unknown |

### DT-02 — mandatory-gate disposition

| Row | Applicability | Gate result | Control-owner rationale | Enforceable bounded restriction |
|---|---|---|---|---|
| 01 | Required | PASS | Not needed | Any |
| 02 | Required | FAIL | Any | Any |
| 03 | Required | Unknown / evidence absent | Any | Any |
| 04 | Genuinely not applicable after scope review | N/A | Present; pre-decision | Not required |
| 05 | Needed only for later operational permission | Conditional | Present | Yes |
| 06 | Required gate omitted from record | Missing | Absent | Any |
| 07 | Required gate marked N/A to improve eligibility | N/A | Invalid/absent | Any |

### DT-03 — evidence state and capability

| Row | Evidence sufficient for full atomic scope | Demonstrated capability | Freshness/scope/contradiction |
|---|---|---|---|
| 01 | No | Unknown / not demonstrated | Missing, stale, contradictory or out of scope |
| 02 | Yes | Absent / unacceptable | Current and scope-matched |
| 03 | Yes | Severe gap below minimum | Current and scope-matched |
| 04 | Yes | Partial capability with material limits | Current and scope-matched |
| 05 | Yes | Predefined threshold met | Current and scope-matched |
| 06 | Yes | Materially above requirement | Strong, current, reproducible |
| 07 | Yes | Exceptional repeatable performance | Strong/repeatable |
| 08 | Partial atomic coverage only | Parent compound criterion not fully evidenced | Some atoms unsupported |
| 09 | One scope only | Wider scope requested | Scope mismatch |

### DT-04 — N/A and aggregate publication

| Row | N/A before scores | Genuine inapplicability / prior approval | Mandatory gate | NS present | NS material |
|---|---|---|---|---|---|
| 01 | No | Any | Any | Any | Any |
| 02 | Yes | No | Any | Any | Any |
| 03 | Yes | Yes | Yes | Any | Any |
| 04 | Yes | Yes | No | No | – |
| 05 | Yes | Yes | No | Yes | Yes |
| 06 | Yes | Yes | No | Yes | No |
| 07 | Yes | Yes | No | Yes | Any |

### DT-05 — risk record completeness

| Row | Scenario | Horizon-specific likelihood rationale | Impact dimensions/rationale | Raw inherent/residual pair | Control operating evidence |
|---|---|---|---|---|---|
| 01 | Present | Present | Present | Both preserved | Present / N/A with rationale |
| 02 | Missing | Any | Any | Any | Any |
| 03 | Present | Missing or horizon-mismatched | Any | Any | Any |
| 04 | Present | Present | Missing | Any | Any |
| 05 | Present | Present | Present | Collapsed to L×I only | Any |
| 06 | Present | Present | Present | Preserved | Claimed control; no operation evidence |

## 8. Required reviewer worksheet fields

For every RDM rule, AVT case and decision-table row, record:

1. Reviewer case ID and worksheet revision.
2. Expected outcome, expressed as observable states/values (not merely “pass”).
3. Exact parent clause(s), subsection and source-language version used.
4. Modal force and whether the conclusion is direct, conditional, derived or unresolved.
5. Preconditions and input assumptions.
6. Feasibility classification for decision-table combinations.
7. Stop/escalation condition and the authority needed to resolve it.
8. Confidence: High / Medium / Low, with rationale.
9. Alternative plausible interpretation(s) and why rejected or retained.
10. Whether the Persian and English source texts appear semantically aligned; quote the exact disputed wording if not.
11. Reviewer name/role, competence statement, conflict declaration and prior-access declaration.
12. Date, signature/attestation and SHA-256 of the completed worksheet.

The separate worksheet template is maintained alongside this packet. Do not fill it using an answer inferred from this packet’s labels alone.

## 9. Acceptance and reconciliation gate

The blind oracle is considered **returned but not automatically accepted** only when:
- reviewer identity, competence, independence limitations and conflicts are recorded;
- all 18 rule IDs, 21 AVT cases and 35 decision-table rows have dispositions or explicitly justified exclusions;
- each deterministic outcome is source-cited;
- unresolved cases remain unresolved rather than being forced into a binary result;
- bilingual source discrepancies are recorded;
- the worksheet is frozen and hashed before the reviewer receives the author’s catalogue/model outputs.

After freeze, the author and reviewer may perform a discrepancy workshop. Each difference must be classified as: author error; reviewer error; source-text ambiguity; missing test input; infeasible case; bilingual mismatch; or policy/owner decision required. No difference may be resolved merely by preferring the current code.

**RDM-001 change gate:** no executable model changes are authorized by this packet. Model changes may be proposed only after the independent worksheet is frozen, discrepancies are classified, and owner decisions required for policy changes are recorded. This review does not approve LOT-EVAL-001 or REV-01…REV-14.

## 10. Research basis and limits

- ISO/IEC/IEEE 29119-1:2022 defines a test oracle as a source used to determine whether a test passes or fails and recognizes specifications and human experts as possible oracle sources: https://www.iso.org/obp/ui/
- NASA Software Engineering Handbook SWE-141 describes IV&V as objective examination and identifies technical, managerial and financial independence as distinct dimensions: https://swehb.nasa.gov/spaces/SWEHBVC/pages/50888971/SWE-141%2B-%2BSoftware+Independent+Verification+and+Validation
- NASA IV&V overview explains verification versus validation and the three independence dimensions: https://www.nasa.gov/ivv-overview/
- NASA-STD-8739.8B describes independent assessment across the lifecycle and the three independence parameters: https://swehb.nasa.gov/spaces/SITE/pages/119242809/NASA-STD-8739.8B

These sources inform the review design. They do not certify the reviewer, this packet, the parent standard or Lottorito. A single second reviewer can provide an independent technical perspective only to the extent their actual competence, prior involvement and independence are demonstrated; this is not automatically formal IV&V.

## 11. Non-authorization

LOT-EVAL-001 remains PROPOSED. No candidate, supplier, product, technology, jurisdiction, legal entity or operating model is selected. No procurement, partner integration, production data, financial activity, launch, merge or deployment is authorized. RaidenBet remains an unconfirmed proposed pilot lead.
