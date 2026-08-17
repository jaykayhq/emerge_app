# Web Landing Page — Design Spec

**Date:** 2026-08-17
**Status:** Approved (brainstorming)
**Applies to:** emerge_app (Flutter) + Firebase Hosting
**Single source of truth:** `docs/design.md` (visual identity, §2)

---

## 1. Goal

A marketing landing page served at the **root of the Firebase Hosting site** (`https://tradeflash-l2966.web.app/`) that:

- Shows **only on web** — it lives at `/`, which native app builds never hit.
- Sells Emerge to logged-out and anonymous web visitors (hero, feature pitch, FAQ).
- Offers **two access paths**: Google Play (Android app) or the web app (browser).
- Loads fast and is SEO-friendly (real HTML at `/`, crawlable copy).

The Flutter app is **unchanged**: no Dart, router, or auth changes. The landing page is a static HTML/CSS/JS site that coexists with the app via a single hosting rewrite.

---

## 2. Architecture & placement

### 2.1 File layout (new, no build tooling)

```
web-landing/
├── landing.html    # full static page (semantic HTML only)
├── styles.css       # nebula background, glassmorphism, layout, animations
└── script.js        # custom cursor, phone-mockup timeline loop
```

No frameworks, no npm, no external JS. The only external resource is the Spline Sans font via Google Fonts CDN, with a system font fallback stack if the CDN fails.

### 2.2 Hosting rewrite

`firebase.json` → `hosting.rewrites` gains an exact-match `/` rule **before** the existing catch-all:

```json
"rewrites": [
  { "source": "/", "destination": "/landing.html" },
  { "source": "/app-ads.txt", "destination": "/app-ads.txt" },
  { "source": "**", "destination": "/index.html" }
]
```

Result:

| URL | Served |
|---|---|
| `/` | `landing.html` (marketing page) |
| `/signup`, `/login`, `/welcome`, `/timeline`, `/splash`, deep links (`/blueprint/:id`, `/creators/:id`, `/verify-email`, …) | Flutter `index.html` (unchanged) |

The router's existing `decideRedirect` logic continues to gate app entry: signed-in users who enter via the landing CTAs are sent to `/timeline`; signed-out first-timers get the existing welcome flow. No Dart changes.

### 2.3 Deploy pipeline

New `scripts/build_landing.sh`:

- `mkdir -p build/web`
- Copy `web-landing/*` → `build/web/` (landing.html, styles.css, script.js)
- Must run **after** `flutter build web --release` (which wipes `build/web`) and **before** `firebase deploy`.

CI: add two steps to both `.github/workflows/firebase-hosting-merge.yml` and `firebase-hosting-pull-request.yml`, immediately after the existing `flutter build web --release` step:

1. `bash scripts/build_landing.sh`
2. `node scripts/test_landing.mjs` (see §5.1)

This keeps the Flutter app's `index.html` untouched and makes preview channels render the landing too.

---

## 3. Page content (top → bottom)

Sections and copy below; anchor ids: `#features`, `#how-it-works`, `#access`, `#faq`.

### 3.1 Nav

- EMERGE wordmark (Spline Sans, tracked out).
- Anchors: Features · How it works · FAQ · Get the app (scrolls to `#access`).
- Right: "Log in" → `/login`.

### 3.2 Hero (with animated phone mockup)

- Headline: **"Who do you wish to become?"** (matches the app's welcome screen copy for continuity).
- Subline: "Forge Your Identity. Build Your Habits."
- CTAs:
  - Primary: **Get it on Google Play** → `https://play.google.com/store/apps/details?id=com.emerge.emerge_app` (verified listing).
  - Secondary: **Continue in Browser** → `/signup` (Flutter app entry; router bounces signed-in users to `/timeline`).
- Right/aligned: **phone mockup** (§4.1) with the timeline "in action".

### 3.3 What is Emerge

One short paragraph + one memorable line: an identity-first habit engine — not a to-do list. You choose who you want to become; the app turns that into habits, streaks, and a world that grows with you.

### 3.4 Features (`#features`)

Six glass cards, each an icon + title + 1–2 line blurb, from real app capabilities:

1. **Identity Studio** — pick your archetype, shape your avatar and world around who you're becoming.
2. **Habit engine** — daily habits with streaks, XP, and progress that compounds.
3. **Timeline** — your daily command center: one-tap completions, inline reflections.
4. **World Map** — a living world that grows as your attributes level up (Strength, Vitality, Focus, Creativity, Spirit, Intellect).
5. **Tribes & challenges** — team up with your crew, join challenges, climb leaderboards.
6. **AI Narrator** — an ambient coach that recaps your day and nudges you forward.

(Attributes verified in `lib/features/habits/domain/entities/habit.dart:12`; archetypes verified in `docs/design.md` §2.1.3.)

### 3.5 How it works (`#how-it-works`)

Three steps:

1. **Forge your identity** — take the archetype first step, define who you're becoming.
2. **Build the habits** — attach 2–3 daily habits with time slots and reminders.
3. **Watch your world grow** — earn XP, level your attributes, grow your world and your crew.

### 3.6 Access (`#access`) — "Emerge on every device"

Two cards:

- 📱 **Android** — "Carry your journey everywhere." Button → Google Play.
- 🌐 **Browser** — "Open it in any browser. No install." Button → `/signup`.

Note under cards: "Same account on both. Your progress syncs automatically."

### 3.7 FAQ (`#faq`) — 6 native `<details>/<summary>` items

1. **What is Emerge?** — An identity-first habit engine: you don't just track habits, you become who you're building toward. Your world literally grows as your attributes level up.
2. **Is it free?** — Free to start. An optional subscription unlocks additional Premium features — see the in-app subscription screen for the current details.
3. **Where can I use it?** — Android via Google Play, plus any browser at the same URL. Your progress syncs across devices.
4. **Do I need an account?** — Yes — a login keeps your data and world synced across devices. Sign in with Google or email.
5. **What are archetypes?** — Six identity styles (Explorer, Athlete, Scholar, Creator, Stoic, Zealot). Each one themes your world and guides archetype-aligned habit choices.
6. **What about my privacy?** — Your habits and identity data are yours. See the Privacy Policy below for details.

`<details>` = keyboard-accessible, works without JS.

### 3.8 Footer

- EMERGE wordmark, tagline.
- Links: Terms of Service, Privacy Policy (same Google Doc URLs as `lib/features/onboarding/presentation/screens/welcome_screen.dart`).
- © 2026 Emerge.

---

## 4. Visual design (per `docs/design.md` §2)

- **Background — nebula**: stacked CSS `radial-gradient()` layers over `#0A0A1A` evoking `#1A0A2A` (purple center) and `#2A1A3A` mid-tone, plus a slow-drift star field (CSS-generated dots, subtle twinkle at 3–4s). The green accent **#2BEE79** is used only for CTAs/accents — never muted.
- **Glass**: cards use `rgba(255,255,255,0.08)` + 1px `rgba(255,255,255,0.12)` border, blur 12px, rounded 20–24px.
- **Type**: Spline Sans (Google Fonts), letter-spaced over lines; fallback `-apple-system`, `Segoe UI`, `Roboto`, sans-serif.
- **Buttons**: primary = gradient green `#2BEE79 → #4ADE80` pill; secondary = outlined glass pill with white text.
- **Custom cursor** (`script.js`): 6px green dot (`#2BEE79`) at the exact pointer + a 28px ring that lags behind with rAF-lerp easing; both `pointer-events: none`. Ring hidden on touch (`@media (pointer: coarse)`) and under `prefers-reduced-motion` (dot remains at pointer; native cursor always visible for usability).
- **Reduced motion**: all animations (mockup loop, twinkle, cursor ring) degrade to a static, calm state under `prefers-reduced-motion`.

### 4.1 Animated phone mockup (hero)

- CSS phone frame (rounded rect, dark bezel, punch-hole camera) with the app's dark cosmic background inside.
- Scripted 12s loop — pure CSS keyframes driven by a `script.js` timeline — simulating live use:
  - Habit cards animate in/complete (check + progress bar fills)
  - Streak counter ticks up, XP bar fills
  - A "Level Up — Explorer" toast
  - World-map dot pulse
- Reduced-motion: stops at a composed static frame (no looping).

---

## 5. Verification & testing

### 5.1 Smoke test — `scripts/test_landing.mjs`

Node script (same style as `email-worker` `node:test` tests) that reads `web-landing/landing.html` and asserts:

- All four section anchors exist and nav links target them (`#features`, `#how-it-works`, `#access`, `#faq`).
- Play Store CTA href contains `id=com.emerge.emerge_app`.
- Browser CTA href is `/signup`; nav "Log in" is `/login`.
- FAQ has at least 5 `<details>` items; each has a `<summary>`.
- Terms of Service and Privacy Policy links match the app's Google Doc URLs (same as `welcome_screen.dart`).
- `styles.css` and `script.js` are referenced.

Runs in CI after `build_landing.sh`, and locally: `node scripts/test_landing.mjs`.

### 5.2 Hosting-config check

- Local: `firebase emulators:exec --only hosting` then curl — `/` returns `landing.html`, `/timeline` and `/signup` still serve the Flutter `index.html` (grep `flutter_bootstrap`).
- Guardrail: the `/` rewrite must sit **before** the `**` catch-all in `firebase.json` (Firebase evaluates more-specific sources first, but ordering keeps intent explicit).
- Landing registers no service worker; the app's existing no-op service worker unregisters itself, so no stale-cache surprise.

### 5.3 Out of scope (explicitly deferred)

- No changes to any Dart/Flutter code.
- No analytics, email capture, or pricing on the page.
- No auth detection on the landing page (per decision: `/` shows for everyone; signed-in users click the app CTA once).
- The roadmap's archetype-quiz landing (`docs/superpowers/specs/2026-08-07-growth-monetization-gtm-design.md`) is a separate future project.
- No real app embed/demo route (future iframe option).

---

## 6. Risks & edge cases

| Risk | Mitigation |
|---|---|
| Rewrite catches app routes | `/` is exact-match; everything else keeps `**` → Flutter |
| Custom cursor blocks UI | dot/ring are `pointer-events: none`, always |
| Font flash/CDN failure | system fallback stack; page usable without font |
| `flutter build` wipes landing | copy runs **after** build in CI and deploy script |
| Landing cached as app | landing served with `no-cache` headers; no SW registration |
| Reduced-motion users | animations (mockup, cursor ring, twinkle) gated |
| Touch devices | cursor layer not attached (`pointer: coarse`) |

---

## 7. Implementation order (into the plan)

1. Scaffold `web-landing/` static files (semantic HTML, CSS nebula, cursor).
2. Write `scripts/build_landing.sh` + wire CI steps (both hosting workflows).
3. `styles.css` + `script.js`: nebula, glass cards, custom cursor, phone mockup loop, responsive breakpoints (~1100px / ~700px).
4. FAQ + sections copy + legal anchor URLs.
5. `firebase.json` rewrite + hosting emulator check (§5.2).
6. `scripts/test_landing.mjs` + CI step; run locally + confirm `dart analyze` still clean (no Dart changes).
7. Manual QA: local serve, preview channel, Play Store + web both reachable.

Verification protocol: run the smoke test, the hosting emulator curl checks, and a channel preview before declaring done.