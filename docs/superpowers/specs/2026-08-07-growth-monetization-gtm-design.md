# Growth, Monetization & GTM Design

**Date:** 2026-08-07
**Status:** Approved for planning
**Companion artifacts:** `docs/growth/notion-tasks.csv` (Notion-importable task DB), `docs/growth/strategy-page.md` (strategy overview)

> **SUPERSEDED 2026-08-12 — Affiliate pivot:** the affiliate-link monetization and server-published challenge feed (Tier-1 items 1-2, §6 P0/P1) were **removed** after evaluation. The product pivoted to **sponsor-first monetization**: flat-fee/CPA sponsored quests with real rewards delivered via voucher API (blueprint §8.2). See the updated `docs/growth/strategy-page.md` and `docs/growth/notion-tasks.csv` (dated from 2026-08-12). The GTM, content-engine, and community-first sections remain valid.

---

## 1. Context & Constraints

**Product:** Emerge — identity-first habit engine (archetypes, world-building gamification, AI coach, tribes/challenges, creator blueprints). Released on Android + web (Paystack, NGN pricing) with RevenueCat (iOS/Android).

**Current monetization:** RevenueCat premium subs ($4.99/mo, $39.99/yr, $99.99 lifetime) + AdMob banners/interstitials for free users. Gates: 5 habits, 1 club, 3 coach asks/day.

**Verified current state (from code):**
- Momentum system exists (0-100 score, decay, `momentum_bar` widget, `MomentumService`).
- Share capability exists (`share_plus` in recap, timeline, creator profile).
- Recap hub is a Spotify-Wrapped-style swipeable card widget (`spotify_wrapped_recap.dart`), NOT a video/vertical export.
- Challenge affiliate fields exist in the model only (`affiliateUrl`, `affiliateNetwork` incl. cj/impact/shareASale/amazon/direct, `commissionRate`, `isSponsored`, sponsorship dates, sponsor logos) + `affiliate_link_clicked` analytics event. **No UI wiring.**
- Creator routes + blueprint builder exist.

**Founder constraints:**
- Pre-launch traction (<50 users).
- Bootstrapped — zero marketing budget.
- 5-15 hrs/week available for marketing/content.
- Existing distribution asset: dev/tech network (Product Hunt, X/indie-hacker, HN, LinkedIn).
- Dual-track market (Nigeria/Africa + global), Nigeria as beachhead (Paystack/NGN infra).

**Strategy chosen:** Approach A (Traffic First, content-led GTM) as backbone + Approach C (Partner-led, B2B2C) in parallel + community-first distribution (engage existing high-intent communities before/while building owned channels).

---

## 2. Positioning & Core Message

**Core idea:**
> "Emerge turns habit tracking into *becoming your future self* — your avatar and world physically grow as your habits do."

**Message pillars:**

| Pillar | Message | Where it lands |
|---|---|---|
| Identity | "Every habit completed is a vote for who you're becoming." | Reddit/forums — philosophical hook |
| Visual proof | "Watch your discipline grow into a world." | TikTok/IG — time-lapse hook |
| Forgiving | "Never miss twice. One miss is a slip, not a fall." | Community posts — differentiator vs streak-anxiety apps |
| Partner | "Sponsored habit challenges your audience will actually finish." | Brand/coach outreach (C-track) |

**Anti-comparison:** "Habitica is an RPG, Forest plants a tree, others just count days. Emerge builds *your* identity — the world is you, not a game."

**Community voice rule:** In communities, behave as a practitioner sharing what works, never an advertiser. 10:1 value-to-mention ratio; the 1 mention framed as "I built this, free to try."

---

## 3. Revenue Streams (beyond subscriptions + ads)

### Tier 1 — Ship now (prove mechanic, test willingness-to-pay)

1. **Affiliate reward on challenge completion.** Finish existing plumbing: completing a sponsored challenge shows "You earned: 20% off [sponsor]" → opens `affiliateUrl` → fires `affiliate_link_clicked`. Also render sponsor on challenge detail. Start with direct networks (pitch brands) + Jumia Affiliate (NG) / Amazon Associates (global). Revenue ≈ $0 until traffic; real value is a C-track pitch asset.
2. **The Emerge Method guide.** Identity-first habit-building ebook. Source material: blueprint + market research. Sell via Paystack (₦) + Gumroad/Stripe ($). Price $9-15 / ₦5-7k. This is the Tier-1 willingness-to-pay test.

### Tier 2 — Next 90 days (as installs pass ~500)

3. Consumable cosmetics IAP — world themes, avatar nameplates/titles (`rewardTitleId`/`rewardNameplateId` exist). One-time purchases, not subs.
4. Sponsored challenges (C-track) — flat fee or affiliate commission per themed challenge.
5. Premium blueprint marketplace — 70/30 revenue split on creator blueprints (creator routes exist).
6. Event/season passes — one-time paid entry to special challenges.

### Tier 3 — Later (1,000+ users or proven demand)

7. 1:1 coaching / habit-system design sessions (services cash, authority building).
8. Referral rewards — premium-days-for-invites.
9. B2B/corporate wellness (requires case-study numbers).

### Guardrail

Do NOT add more ad surfaces during the growth phase. Ad revenue at this scale is pennies and interstitials hurt the retention that drives everything else. Keep ads as-is (free tier only).

---

## 4. Community-First Distribution Map

### Global (high-intent communities)

| Community | Engagement rules |
|---|---|
| Reddit: r/selfimprovement, r/getdisciplined, r/DecidingToBeBetter, r/Stoicism, r/ADHD, r/BettermentBookClub | Answer-first. r/getdisciplined + r/DecidingToBeBetter tolerate text posts; r/productivity bans self-promo. Mention app only when it is the natural answer |
| X/Twitter #buildinpublic, indie-hacker circle | Existing asset — 1 build-in-public post/week |
| Facebook Groups: Atomic Habits groups, 5AM Club, adulting-with-ADHD | Join 3-5; contribute regularly; groups welcome "what worked for you" prompts |
| Quora: habit/psychology questions | Evergreen, SEO, high intent — 1 deep answer/week |
| Discord: productivity/deep-work/study servers | 2-3 committed servers, value-first |

### Nigeria / Africa (beachhead)

| Community | Why |
|---|---|
| WhatsApp groups + Status | #1 channel in Nigeria. Campus accountability, church growth, fitness circles. Paystack/₦ fits |
| Facebook Groups (Nigerian/African self-improvement + productivity) | Larger than Reddit locally; group owners love free value |
| LinkedIn (Nigerian young professionals) | "Identity-first habits for career growth" resonates |
| TikTok Nigeria | Content-led (owned channels), not comment-led |

### Engagement playbook

1. 30 min/day in 2-3 communities — answer with substance, never pitch in comments.
2. 10:1 rule — ten pure-value interactions per one mention.
3. Weekly case-study post where allowed — real user momentum data → story.
4. Repurpose one insight → 4 surfaces: Reddit post + X thread + Quora answer + LinkedIn post.
5. Measure engagement per community (replies, upvotes, DMs); double down only on the 2-3 that engage.

### Weekly time budget (~8-10 of 5-15 hrs)

- 2h community engagement (Reddit + WhatsApp/FB)
- 3-4h content production (1 hero piece)
- 1-2h repurposing/cross-posting
- 1h build-in-public (X/LinkedIn)
- 1h C-track outreach (1 brand OR community-coach pitch/week)
- 1h The Emerge Method guide progress

---

## 5. Content Engine + Owned Channels

**Core insight:** the app is a content factory (recap hub, avatar/world evolution, momentum visuals). Production = recording + packaging.

### Four reusable templates

| Template | Content | Why |
|---|---|---|
| Time-lapse | World/avatar growth over N days + on-screen stats | "Satisfying content" niche; screen-record + auto-captions |
| The Vote | Completion moment + identity overlay ("You just voted for Writer") | Blueprint signature line, meme-able |
| Never Miss Twice | Recovery mechanic visual (fog/weeds clearing) | Emotionally distinct vs streak-anxiety apps |
| Myth vs Identity | Text-overlay "Track habits" vs "Become someone" | Authority positioning, founder-voiced |

### Pipeline (1 session/week → 12+ posts/month)

1. Record 1 hero video (screen capture or founder voice)
2. Cut 3 variants (TikTok / Reels / Shorts) — different hooks
3. Stills + quote card → X/LinkedIn
4. Underlying insight → community post (Reddit case study)

### Hook rules

First 1.5s shows the payoff. Trending audio on TikTok. Captions always on.

### Funnel

> Content → link-in-bio → archetype quiz / guide landing → app download → completion → shareable recap → user-generated content → next content

---

## 6. Product Reforms

### P0 — unlock the viral loop

1. **Branded 9:16 recap export.** MVP: render recap cards into branded vertical image(s)/slideshow users save → TikTok/IG/WhatsApp Status. Stretch: auto-playing slideshow. Feeds Time-lapse template + UGC loop.
2. **Archetype quiz landing page (web).** Quiz → result → email capture → download CTA. Built on existing archetype data; Firebase hosting (web + Paystack already run). Highest-leverage acquisition asset.

### P1 — monetization + retention

3. **Challenge affiliate reward card.** Completion → "You earned: 20% off [sponsor]" → `affiliateUrl` + `affiliate_link_clicked`. Sponsor on challenge detail card. ~2 days work (model done).
4. **Referral mechanism.** Invite link → premium days or cosmetic reward on both sides.
5. **First-7-days path.** Light week-1 guided loop (morning check-in → completion → recap) to protect Day-7 retention.

### P2 — explicitly deferred (do NOT build now)

Consumable cosmetics IAP, blueprint marketplace revenue split, premium blueprint packs, more ad surfaces. Wait for the 500-install mark or guide validation.

---

## 7. 90-Day Roadmap

### Phase 1 — Foundation (Weeks 1-4)

- W1: Positioning approved · guide outline · affiliate card + quiz page specs · social accounts + link-in-bio · join first 3 communities
- W2: Write guide ch. 1-3 · build affiliate reward card · hero #1 · daily community engagement
- W3: Write guide ch. 4-6 · build quiz landing page · hero #2 · build-in-public cadence
- W4: **Guide launches** (Paystack ₦ + Gumroad $) · quiz live + email capture · hero #3 · partner outreach batch 1 (5 brands)

### Phase 2 — Momentum (Weeks 5-9)

- W5: Engagement data → top 2 communities · guide excerpt shorts · recap 9:16 export MVP · outreach batch 2
- W6: Hero #4 · referral spec + build · guide v1.1 with real user story
- W7: PH prep (gallery, demo video, copy) · recap export ships · hero #5
- W8: **Product Hunt launch week** · referral ships · partner deal follow-ups
- W9: Post-PH retention push · guide sales review (→ blueprint packs decision) · week-1 guided loop ships

### Phase 3 — Scale (Weeks 10-13)

- W10: Expand to 2-3 new communities · hero #6 · first sponsored challenge live · second product decision
- W11: Micro-creator UGC outreach (2-3, 30-100k followers) · build second product if approved
- W12: Hero #7 + WhatsApp Status push (NG) · referral cross-promotion
- W13: 90-day review — metrics report + next-quarter double-down plan

### Recurring weekly cadence (~10 hrs)

1 hero piece (3-4h) → repurpose ×3 platforms (1-2h) → community engagement 30min/day (2.5h) → 1 build-in-public post (1h) → 1 partner outreach (0.5h) → guide/product progress (1h).

---

## 8. Metrics

| Metric | Target (90 days) |
|---|---|
| Installs | 0 → 1,000 |
| Day-7 retention | ≥20% (path to 40%) |
| The Emerge Method sales | first 20 |
| Affiliate clicks | 50+ · 1-2 sponsor deals |
| Community engagement | 2-3 communities at 10+ replies/post |
| Product Hunt | 100+ upvotes |
| Content | 12+ hero pieces × 3 platforms |

Review cadence: weekly (light), hard review at W13.

---

## 9. Deliverables

1. This spec.
2. `docs/growth/notion-tasks.csv` — Notion-importable task database (columns: ID, Area, Phase, Week, Task, Priority, Est hours, Status, Notes).
3. `docs/growth/strategy-page.md` — strategy overview page (paste into Notion).
