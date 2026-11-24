# Multilingual Growth, Content Automation and Search Architecture

**Document ID:** LOT-GROWTH-001 | **Version:** 1.0.0 | **Status:** Proposed operating model; no channel integration or publishing automation verified

## 1. Purpose

Create one governed growth/content operating system for Lottorito that can research, plan, draft, review, localize, approve, distribute and measure content across owned, earned and paid channels. It serves both platform-level communication and separately permissioned Affiliate and Lottery product campaigns.

SEO = Search Engine Optimization; GEO = Generative Engine Optimization (visibility and accurate representation in AI answer/search systems); AEO = Answer Engine Optimization (clear, structured answers for answer engines). Local SEO and geographic targeting are separate capabilities and must not be confused with GEO.

## 2. Channel scope

Potential channel adapters, enabled only after platform and market approval:
- Owned: public website, landing pages, product/help center, blog, email, in-app surfaces and notification center.
- Social/community: YouTube, Instagram, TikTok, Facebook, LinkedIn, X and regionally relevant networks.
- Messaging: WhatsApp, Telegram, LINE, WeChat and other channels only where lawful, supported and consented.
- Paid media: search, social and display advertising platforms, with platform-specific policy, audience and creative approvals.
- Partner/affiliate distribution: approved partner portals, campaign links and agent-provided channels under contractual rules.

Each channel is an adapter with capability discovery, credential isolation, rate limits, content format constraints, delivery receipts, error handling and revocation. No channel is assumed connected or available. Do not scrape or automate a platform in violation of its terms.

## 3. Content operating lifecycle

Suggested lifecycle:
1. Research brief: audience, product, locale, objective, channel, market/jurisdiction, evidence sources, freshness and prohibited claims.
2. Content plan: campaign, editorial calendar, funnel stage, owner, budget authority and measurement plan.
3. Draft: human or AI-assisted source content, with structured facts and citations.
4. Fact and policy review: source verification, product owner, legal/compliance, responsible-use and advertising checks where relevant.
5. Localization: translation/adaptation for all required locales, native review and locale-specific examples/terminology.
6. SEO/GEO/AEO optimization: search intent, entities, answer summary, schema, citations, canonical/hreflang, internal links and technical checks.
7. Creative adaptation: channel-specific copy, image/video aspect ratio, captions, alt text, subtitles and accessibility.
8. Approval: named accountable reviewer and versioned approval; paid campaigns require budget and platform authorization.
9. Scheduling and publishing: idempotent jobs, per-channel throttling, preview and final URL/asset verification.
10. Measurement and refresh: qualified traffic, conversions, assisted attribution, engagement, brand/entity visibility, content decay and corrections.

No generated content should auto-publish solely because an AI score is high. Financial, legal, Lottery, promotional, responsible-use and partner claims require designated human approval. Public corrections and takedowns must propagate to derived translations and scheduled channel assets.

## 4. SEO / GEO / AEO content model

Every indexable content item should have:
- stable content ID, content type, owner, source language and locale variants;
- primary audience, intent, funnel stage, product and approved market;
- canonical URL, locale URL, hreflang peers, robots/indexability state and sitemap eligibility;
- title, meta description, headings, summary, answer-first section and key facts;
- named entities, topic taxonomy, keywords and search-intent mapping;
- authoritative source list, citation spans, publication/review dates and freshness policy;
- structured data type and validated JSON-LD where appropriate;
- internal links, related content and approved calls to action;
- image/video metadata, alt text, captions, transcript and rights/consent evidence;
- translation completeness, native reviewer, version and approval state;
- correction history, expiry/review date and performance metrics.

**SEO:** crawlability, indexation, page experience, information architecture, internal linking, localized metadata, schema correctness and intent satisfaction.

**GEO:** make entities, authorship, provenance, dates, claims and source citations explicit and consistent so AI systems can interpret the platform accurately. Monitor representation and citations where measurable; never promise inclusion or ranking in an AI answer.

**AEO:** provide concise direct answers, clear question headings, definitions, comparison tables where useful, FAQ/help content, and machine-readable structured data that matches visible page content. Structured data must never invent ratings, prices, availability, legal status or product features.

## 5. Editorial integrity and safety

- Maintain a claim registry for product capabilities, provider relationships, odds/results, fees, commissions, licensing and availability; every claim has an owner, evidence and expiry/review date.
- Never publish unsupported claims such as “guaranteed winnings”, guaranteed income, risk-free returns, universal legal availability or unverified provider integration.
- Lottery and gambling-related content requires jurisdiction-specific legal, advertising, age, responsible-use and platform-policy approval before targeting or publication.
- Paid targeting must respect age restrictions, market restrictions, platform policies, consent and suppression lists.
- Do not infer sensitive traits or build sensitive audience segments from chat, financial or behavioral data.
- Respect copyright, creator rights, image/video licenses, consent and disclosure requirements for sponsored/affiliate content.
- Keep an auditable record of prompts, source material, model/tool versions, edits, reviewers, approvals, publication IDs and takedowns, subject to privacy and retention policy.

## 6. Multilingual content parity

All 12 locales in LOT-I18N-001 are in scope. Each campaign defines whether all 12 are required; launch-critical platform and product information defaults to all 12. No locale should receive a materially reduced or misleading offer, missing disclosure or lower factual standard.

Native reviewers must check meaning, tone, cultural suitability, product terminology, numbers, dates, currency, legal disclosures, call-to-action behavior and platform-specific character limits. AI translation is a draft, not approval. Region-specific adaptations must not silently change commercial terms or product rules.

## 7. Automation architecture

Proposed components:
- research/source registry with trust level, source URL, capture time and freshness;
- content brief and editorial calendar;
- versioned content repository and asset library;
- AI orchestration with task-specific prompts, model provenance, cost controls and evaluation;
- translation workflow and glossary/translation memory;
- fact-check and policy review queues;
- SEO/GEO/AEO validation pipeline;
- channel adapters and scheduler;
- publication receipt store, retry/dead-letter handling and takedown propagation;
- analytics/attribution with consent-aware identity resolution;
- audit log and role-based approval.

Use event-driven jobs with idempotency, retries, bounded concurrency, tenant/product context and per-channel rate limits. A retry must not create duplicate posts, spend or messages. Separate organic publishing from paid spend; budget changes and campaign activation require explicit authorization. Secrets stay in a dedicated secret manager, never in prompts or content records.

## 8. Measurement

Measure by locale, product, market, channel and campaign:
- content completeness and review freshness;
- crawl/index coverage and technical SEO errors;
- qualified organic sessions and conversions;
- answer visibility/citations where measurement is available;
- entity consistency and factual correction rate;
- social reach, engagement, referral quality and sentiment with platform caveats;
- campaign spend, attributed outcomes and incremental lift where defensible;
- translation defects, takedown latency and policy violations.

Avoid optimizing only for impressions, AI-generated traffic estimates or vanity engagement. Attribution windows, consent, cross-device limitations and platform reporting differences must be documented.

## 9. Release gates

A channel/locale campaign is ready only when:
- market and channel are approved;
- claims and source evidence are reviewed;
- all required locale variants pass native and domain review;
- SEO/GEO/AEO metadata and structured data pass validation;
- creative rights, accessibility and platform constraints are checked;
- audience, consent, age, suppression and budget controls are applied;
- publication schedule, idempotency, failure handling and takedown path are tested;
- accountable owner and post-publication monitoring are assigned.

## 10. Related documents

LOT-I18N-001; LOT-COMMS-001; LOT-NOTIF-001; LOT-SEC-TM-001; LOT-API-001; LOT-QA-001; LOT-OPS-001.

**Status reminder:** proposed operating architecture only. No social, messaging, ad-platform connector, content automation or publication has been implemented or authorized by this document.
