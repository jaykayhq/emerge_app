# Emerge Validation Gates — Design Spec

**Date**: 2026-08-10
**Source**: Full validation pipeline (5 specialist agents → skeptic → 2 rebuttals → production code audit)
**Verdict**: Conditional GO on Nigeria-first wedge, gated on three falsification tests.

---

## 1. Overview

The pipeline concluded that Emerge's Nigeria-first, identity-first habit engine has a genuinely unclaimed wedge, but its monetization assumptions rest on three testable pillars:

1. **Nigerian willingness-to-pay** — the load-bearing claim, currently unmeasured.
2. **Creator-led growth** — the only distribution engine that survives the "paid UA is unprofitable" verdict; supply side unproven.
3. **AI cost governance** — a production code audit found the margin model's precondition (quota on all AI surfaces) is violated today.

Each gate has a **pass threshold**, a **kill threshold**, and a **defined measurement window**. All three are designed as *falsification tests* — they must be capable of killing the direction.

---

## 2. Gate 1 — Nigerian WTP Pricing Probe

### Goal
Bound the real install→paid conversion and retention for Nigerian users at naira price points. No pricing decision is valid on category benchmarks alone.

### Design

**Primary test: hard-gate paywall A/B.** Rotate three monthly price points server-side via Paystack's subscription API:

| Cell | Monthly | Annual |
|------|---------|--------|
| A | ₦1,500 | ₦9,000 |
| B | ₦2,500 | ₦15,000 |
| C | ₦4,000 | ₦24,000 |

- Server-side assignment (Remote Config `ng_paywall_cell`), stable per device, logged to Analytics with the cohort.
- **Friction controls:** offer bank-transfer/USSD alongside card (Paystack supports recurring direct debit); publish one price point via iOS IAP (₦2,500) to measure store-vs-web channel differences.

**Secondary test: stated-vs-revealed WTP.** Van Westendorp price ladder + a ₦500 refundable "reserve your spot" deposit on the web landing page, to filter survey optimism before ad spend.

### Metrics
- Install → paywall-view conversion
- Paywall-view → paid conversion (per cell)
- D30 and D90 retention of paid subscribers (per cell)
- Web vs store channel conversion delta

### Pass threshold
≥1–2% of *activated* installs convert at the ₦2,500 cell AND ≥30% D30 retention. If ₦4,000 converts ≥0.7× the ₦2,500 rate, the price ceiling is higher than assumed.

### Kill threshold
<0.5% conversion at ₦2,500 across a 4-week window → the wedge's economic pillar fails; pivot.

### Window
4 weeks minimum; re-test quarterly (uLesson precedent: prices halved under inflation — expect elasticity spikes with headline inflation). Prefer annual billing (₦15,000/yr) to lock revenue against churn.

---

## 3. Gate 2 — Creator-Challenge Pilot

### Goal
Validate that "verified creators as coaches" — the unclaimed differentiator AND the only viable growth engine — has real supply and converts audiences.

### Design

- Recruit **5 vetting-verified micro-creators** (10K–50K followers; fitness/discipline/self-improvement niches on Instagram, TikTok, WhatsApp Status).
- Each runs a **14-day paid habit challenge** priced at ₦2,500, launched in-app with a **WhatsApp mirror** (creators monetize inside WhatsApp groups today — Emerge must wrap around that economics, not displace it).
- Revenue-share or flat ₦30K–₦80K/month guarantee per creator (modest share of a micro-creator's income; Launchpad.ng shows ₦100K–₦500K/mo is normal).
- Vetting = certifications, live body of work, follower-quality screen.

### Metrics
- Creator recruitment rate (5 signups within N weeks)
- Follower → challenge-view → purchaser conversion per creator
- Challenge completion rate
- Post-challenge retention (did the user keep using Emerge?)

### Pass threshold
≥0.5–1% of *reachable* followers purchase per creator.

### Kill threshold
<0.3% follower→purchaser conversion → creator supply exists but doesn't move users → growth engine fails; must find another distribution channel before scaling.

### Window
6–8 weeks from first creator signed.

---

## 4. Gate 3 — AI Cost Governance

### Goal
Close the production quota gap so the ~80% variable margin model holds. Not a test — a prerequisite found broken by code audit.

### Finding (verified in repo)
- `CoachAskQuota` (3/day free, unlimited premium) gates ONLY the narrator *ask* path.
- `CompanionEngine.triggerEvent` — `lib/features/companion/presentation/providers/companion_providers.dart:113` — calls `groqService.getCompanionMessage` with **no quota check**; fires on dailyCheckIn, levelUp, streakBreak, onFireState, weeklyRecap, longAbsence, userInitiated.
- `LlmNarratorLineResolver` — `lib/features/narrator/presentation/providers/narrator_providers.dart:81` — calls `groqService.fillNarratorSlots` on auto-triggers with **no quota check**.

### Design
1. **Server-side quotas** covering ALL surfaces (companion, narrator slots, coach asks) — client-side caps alone are bypassable and are currently the only enforcement.
2. **Model routing**: cheap/auto surfaces → 8B-class; only explicit premium asks → 70B-class.
3. **Premium usage caps**: "unlimited" AI for premium is a margin destroyer at 50 calls/day; cap at a high-but-bounded number.
4. **Caching**: per-archetype + per-trigger cached outputs (the hardcoded fallback map is a precedent).
5. **Fallback**: Gemini Flash fallback for Groq rate-limit/vendor resilience.
6. **Billing visibility**: surface AI cost per user in the admin analytics; alert on >X calls/user/day.

### Verification
- Code-level: no unquota'd `GroqAiService` call sites remain (grep audit).
- Runtime: 30-day spend snapshot from Firebase billing console before/after, per-surface cost attribution.

### Kill consideration
If capped+8B-routed AI still cannot hold margin at projected usage → AI surfaces must be cut back or made strictly premium-only.

---

## 5. Relationship Between Gates

- Gates 1 and 2 are **parallel** — both must pass for GO.
- Gate 3 is a **prerequisite** that lands regardless of 1–2 (it is the difference between a healthy and an unbounded cost line).
- The three gates collectively answer: *does the Nigerian segment pay, can creators deliver users, and can the cost model survive the users once they come?*

## 6. Deliverables

- Paywall A/B implementation (Remote Config cell + Analytics events + Paystack subscription variants)
- Creator recruitment brief + challenge template + WhatsApp-mirror flow
- AI governance implementation (server-side quotas, model routing, caps, caching, fallback)
- 30-day spend snapshot methodology (Firebase billing + per-surface attribution)

## 7. Non-Goals

- No full app redesign; no graph database adoption (pipeline verdict: lens only, revisit at 1M+ MAU with dense topology AND a speced graph feature); no Sweatcoin-style affiliate program (needs ~10M users).
