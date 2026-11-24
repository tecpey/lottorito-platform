# Global Launch Localization and Language Quality Standard

**Document ID:** LOT-I18N-001 | **Version:** 1.0.0 | **Status:** Owner-directed target; language portfolio proposed from public evidence; release implementation not verified

## 1. Purpose and authority

Lottorito is a global platform from inception. The owner has directed that launch planning target ten major global languages plus Persian and Turkish: **12 launch languages total**, with equivalent product, content and support quality. This is a product requirement, not a statement that all translations or locale-specific operations already exist.

The ten-language shortlist below is an evidence-informed proposal using online-user reach and digital content presence. It is not a market-entry, legal-availability or revenue forecast. The final market activation sequence remains subject to owner, commercial, legal and operational review.

## 2. Proposed launch language portfolio

| # | Language | Initial locale tag | Script / direction | Localization note |
|---:|---|---|---|---|
| 1 | English | en | Latin / LTR | Global English baseline; avoid assuming one country's legal or financial terminology |
| 2 | Chinese | zh-Hans | Simplified Han / LTR | Simplified Chinese baseline; Traditional Chinese (zh-Hant) is a future separately reviewed locale |
| 3 | Spanish | es | Latin / LTR | Neutral international Spanish baseline; regional vocabulary and legal copy need market review |
| 4 | Hindi | hi | Devanagari / LTR | Hindi (India) baseline; number/date/currency formats must be locale-aware |
| 5 | Russian | ru | Cyrillic / LTR | Russian baseline; market availability and sanctions/export controls are separate legal gates |
| 6 | Arabic | ar | Arabic / RTL | Modern Standard Arabic baseline; native RTL, bidirectional text and localized numerals tested |
| 7 | French | fr | Latin / LTR | International French baseline; regional variants can be added by market |
| 8 | Portuguese | pt-BR | Latin / LTR | Brazilian Portuguese baseline; European Portuguese (pt-PT) is a future separately reviewed locale |
| 9 | Japanese | ja | Japanese scripts / LTR | Japanese baseline; typography, line breaking and formality reviewed by native specialists |
| 10 | German | de | Latin / LTR | Standard German baseline; compound words, legal wording and text expansion tested |
| 11 | Persian | fa | Persian-Arabic / RTL | Explicit owner-requested language; Persian typography, calendar and numerals need native QA |
| 12 | Turkish | tr | Latin / LTR | Explicit owner-requested language; Turkish casing, dotted/dotless I and locale collation tested |

**Counting rule:** the first ten are the proposed global-reach portfolio; Persian and Turkish are additional owner-directed launch languages. Locale tags identify initial content variants, not permission to serve a country or accept a transaction there.

## 3. Evidence and selection rationale

The Observatory of Linguistic and Cultural Diversity on the Internet (OBDILCI), July 2025 V6, reports internet-user shares for English, Chinese Macro, Spanish, Hindi, Russian, Arabic, French, Portuguese, Japanese and Standard German. Its model combines connected speakers and online-content indicators and states a confidence interval of ±20%. This is a useful multilingual reach signal, not a precise count of addressable customers.

W3Techs' 24 November 2026 website-content survey shows a different distribution: English 49.5%, Spanish 6.0%, German 5.9%, Japanese 4.9%, French 4.6%, Portuguese 4.2%, Russian 3.4%, while Arabic, Hindi and Chinese are much less represented in its classified website sample. W3Techs explicitly measures website content language, not total speakers or customer demand. The difference is why Lottorito should not select launch languages from a single web-content ranking.

Selection therefore balances:
- connected user reach and multilingual Internet presence;
- online content and discoverability opportunity;
- commercially relevant language communities across multiple regions;
- explicit owner requirement for Persian and Turkish;
- operational feasibility of native review, customer support and legal localization.

The ten-language shortlist is proposed for launch planning. It must be revisited using actual acquisition, conversion, support and partner data after launch.

## 4. Equal quality means measurable parity

All 12 languages must share the same release scope and quality gates. A language must not be marked launch-ready merely because its navigation strings are translated.

For each release, parity covers:
- onboarding, authentication, account, agent and customer journeys;
- Affiliate & Agent and Lottery product terminology, subject to separate product entitlements and legal activation;
- financial labels, amounts, fees, commissions, status names, dates and disclosures;
- help center, FAQs, policies, support macros and live-chat flows;
- transactional, security, service and marketing notifications;
- public landing pages, product pages, articles, metadata, structured data and canonical/hreflang relationships;
- campaign copy and channel-specific creative, where the channel and market are approved;
- error states, empty states, validation, emails, PDFs and downloadable artifacts.

A language release must meet the same acceptance tests, severity thresholds and content completeness requirements. Missing or stale critical content blocks that locale's release; it must not silently fall back to English for financial, legal, safety, consent or purchase-critical information. A controlled language-unavailable state is safer than a misleading mixed-language flow.

## 5. Localization engineering requirements

- Store stable message keys and versioned translations; never use translated strings as identifiers.
- Separate language, locale, timezone, calendar, currency, country/jurisdiction and number-format settings. They are not interchangeable.
- Use locale-aware formatting for dates, numbers, currencies, plural rules, sorting and casing.
- Support RTL and mixed-direction content, including embedded IDs, URLs, amounts, account references and Latin product names.
- Test layout mirroring deliberately; do not blindly reverse icons, charts, timelines or directional symbols.
- Avoid text embedded in images. Where unavoidable, create separately reviewed locale assets.
- Support font coverage, line wrapping, text expansion, Japanese line breaking, Arabic shaping and Persian joining.
- Keep language choice persistent across sessions and devices through the account preference; allow a user override without changing legal country or account currency.
- Maintain explicit source-language, translation version, reviewer, approval date and freshness metadata for every content item.
- Expose missing/stale translation dashboards and prevent publication of incomplete critical journeys.
- Use Unicode normalization and safe handling of confusables in identity-sensitive fields; never normalize identifiers in a way that changes account identity.

## 6. Translation and editorial governance

AI may draft, translate and suggest terminology. It cannot be the sole approver for legal, financial, responsible-use, identity/security, consent or lottery-related content.

Each language requires:
1. a maintained glossary and style guide;
2. native or demonstrably fluent reviewer ownership;
3. domain review for financial, product and legal terms;
4. source-to-target traceability and versioning;
5. linguistic QA plus functional UI QA;
6. correction workflow with severity, owner and publication hold;
7. periodic review of stale content and terminology drift.

Translation memory may accelerate work, but must not propagate an incorrect translation merely because it was previously approved. Machine-generated content must be clearly distinguished in editorial workflow and reviewed before publication.

## 7. Search and discoverability by locale

- Use stable locale-prefixed URLs and a deliberate default-language policy.
- Publish reciprocal hreflang annotations only for equivalent, available pages; include x-default where appropriate.
- Keep canonical URLs correct per content relationship; never canonicalize every translation to the English page.
- Localize title, description, headings, image alt text, Open Graph, social metadata and structured data.
- Ensure translated pages are indexable only when they provide complete, useful, non-duplicative localized value.
- Generate XML sitemaps by locale and content type; exclude drafts, blocked jurisdictions and incomplete translations.
- Do not promise rankings or AI citations; measure search visibility and qualified outcomes by locale.

## 8. Acceptance and release gates

A locale can be marked **Ready** only when:
- all in-scope critical journeys are available and tested in that language;
- 100% of release-critical strings and required policy/financial/security content have approved translations;
- no unresolved critical or high-severity linguistic, legal or functional defect remains;
- RTL/LTR, accessibility, responsive layout and locale formatting tests pass;
- help/support coverage and escalation ownership exist for the locale;
- metadata, canonical/hreflang and sitemap checks pass for published pages;
- language-specific consent, channel and jurisdiction restrictions are respected.

Numerical quality sampling targets and defect thresholds must be approved by the accountable product owner and language leads; do not invent a score that masks critical defects.

## 9. Boundaries

Language availability is not jurisdiction approval. A translated Lottery, affiliate, promotional or payment page must not be exposed in a market until the product, provider, licensing, advertising, consumer-protection, privacy, sanctions and payment rules for that market are reviewed and approved. Locale selection must not imply that every product is lawful or available in every country.

## 10. Related documents

- LOT-GROWTH-001 — multilingual content, SEO/GEO/AEO and channel automation.
- LOT-COMMS-001 — live chat and customer communications.
- LOT-NOTIF-001 — smart notification policy and delivery.
- LOT-QA-001 — measurable quality attributes.
- LOT-API-001 — API conventions.
- LOT-OPS-001 — verified project status.

**Status reminder:** 12-language launch target is owner-directed. The ten-language shortlist and initial locale tags are proposed. No localization implementation or market authorization is claimed.
