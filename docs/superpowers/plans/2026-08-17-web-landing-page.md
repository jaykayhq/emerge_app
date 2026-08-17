# Web Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a static, SEO-able marketing landing page at `/` of the Firebase Hosting site (nebula background, custom cursor, animated phone mockup, Play Store + browser access, FAQ) with the Flutter app untouched.

**Architecture:** A pure static site (`web-landing/`) copied into `build/web/` after each Flutter web build. `firebase.json` gains an exact-match `/` → `landing.html` rewrite **before** the `**` → Flutter `index.html` catch-all. CI (both hosting workflows) copies + smoke-tests it. No Dart changes anywhere.

**Tech Stack:** Vanilla HTML/CSS/JS (no frameworks, no npm deps), Google Fonts (Spline Sans CDN with system fallback), Node `node:test` for the landing smoke test, Firebase Hosting emulator for rewrite verification.

**Spec:** `docs/superpowers/specs/2026-08-17-web-landing-page-design.md` (read it first).

**Execution notes:**
- Do NOT run the full Flutter test suite — it's slow. Only `dart analyze` (expected 0 issues; no Dart changes) and the focused `node --test` smoke test.
- Deploy preview can be checked locally with the Firebase Hosting emulator; a live channel deploy requires `firebase` auth (user action, not CI).

---

## File Structure

| File | Responsibility |
|---|---|
| `web-landing/landing.html` | The full static page — semantic HTML, all section copy, links |
| `web-landing/styles.css` | Nebula background, glassmorphism, layout, phone-mockup animations, responsive, reduced-motion |
| `web-landing/script.js` | Custom cursor (dot + trailing ring) + scripted "timeline in action" phone loop |
| `scripts/test_landing.mjs` | `node:test` smoke test asserting structure + links of the landing page |
| `scripts/build_landing.sh` | Copies `web-landing/*` → `build/web/` after the Flutter web build |
| `firebase.json` | Hosting rewrites (`/` → landing) + no-cache headers for landing assets |
| `.github/workflows/firebase-hosting-merge.yml` | CI: build landing + run smoke test after `flutter build web --release` |
| `.github/workflows/firebase-hosting-pull-request.yml` | Same for PR previews |

---

### Task 1: Write the smoke test (red)

**Files:**
- Create: `scripts/test_landing.mjs`

- [ ] **Step 1: Create `scripts/test_landing.mjs`**

```js
// scripts/test_landing.mjs
//
// Smoke test for the static landing page (web-landing/). Asserts the
// structural contract the page must keep: section anchors, the two access
// CTAs (Play Store + browser), legal links MATCHING THE APP (extracted from
// welcome_screen.dart, the single source of truth), FAQ markup, and that the
// CSS/JS assets are wired up.
//
// Run: node --test scripts/test_landing.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

const html = readFileSync(join(root, "web-landing", "landing.html"), "utf8");
const appWelcome = readFileSync(
  join(root, "lib", "features", "onboarding", "presentation", "screens", "welcome_screen.dart"),
  "utf8",
);

// Canonical legal links come from the app itself, so this test can never
// drift from what the app actually links to.
const legalLinks = [...appWelcome.matchAll(/https:\/\/docs\.google\.com\/[^\s"'`]+/g)].map((m) => m[0]);

const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.emerge.emerge_app";

test("landing page exists and has full head", () => {
  assert.ok(html.includes("<title>"), "missing <title>");
  assert.ok(html.includes('name="description"'), "missing meta description");
  assert.ok(/<h1[^>]*>/.test(html), "missing <h1>");
});

test("all four section anchors exist", () => {
  for (const id of ["features", "how-it-works", "access", "faq"]) {
    assert.ok(html.includes(`id="${id}"`), `missing section id="${id}"`);
  }
});

test("nav links target the sections and login", () => {
  for (const href of ["#features", "#how-it-works", "#access", "#faq"]) {
    assert.ok(html.includes(`href="${href}"`), `missing nav link ${href}`);
  }
  assert.ok(html.includes(`href="/login"`), "missing /login link");
});

test("Play Store CTA links to the real listing", () => {
  assert.ok(html.includes(PLAY_STORE_URL), "Play Store CTA missing");
});

test("browser CTA boots the Flutter app at /signup", () => {
  assert.ok(html.includes(`href="/signup"`), "browser CTA must point at /signup");
});

test("FAQ is native <details> and has at least 5 items", () => {
  const details = html.match(/<details/g) ?? [];
  assert.ok(details.length >= 5, `expected >= 5 <details>, got ${details.length}`);
  const summaries = html.match(/<summary/g) ?? [];
  assert.equal(summaries.length, details.length, "every <details> needs a <summary>");
});

test("legal links match the app's welcome screen", () => {
  assert.equal(legalLinks.length, 2, `expected exactly 2 legal links in welcome_screen.dart, got ${legalLinks.length}`);
  for (const url of legalLinks) {
    assert.ok(html.includes(url), `missing legal link ${url}`);
  }
});

test("styles and script are wired up", () => {
  assert.ok(html.includes('href="styles.css"'), "styles.css not referenced");
  assert.ok(html.includes('src="script.js"'), "script.js not referenced");
  assert.ok(html.includes('id="phone-mockup"'), "phone mockup element missing");
});
```

- [ ] **Step 2: Run it to verify it fails (red)**

Run: `node --test scripts/test_landing.mjs`
Expected: FAIL — `ENOENT: no such file or directory ... web-landing/landing.html`. This is the "file doesn't exist yet" red; the content assertions turn red in Task 2 if the markup is incomplete.

- [ ] **Step 3: Commit**

```bash
git add scripts/test_landing.mjs
git commit -m "test(web-landing): smoke test for the static landing page"
```

---

### Task 2: Full landing page markup (green)

**Files:**
- Create: `web-landing/landing.html`

- [ ] **Step 1: Create `web-landing/landing.html` with the complete content below**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Emerge — Who do you wish to become?</title>
  <meta name="description" content="Emerge is an identity-first habit engine. Forge your identity, build your habits, and watch your world grow. Get it on Google Play or use it in your browser.">
  <meta name="theme-color" content="#0A0A1A">
  <meta property="og:type" content="website">
  <meta property="og:title" content="Emerge — Identity-First Habit Engine">
  <meta property="og:description" content="Who do you wish to become? Forge your identity. Build your habits.">
  <meta property="og:image" content="icons/Icon-512.png">
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <!-- App's font: Spline Sans (bundled in the app, served from CDN for the static page). -->
  <link href="https://fonts.googleapis.com/css2?family=Spline+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <a class="skip-link" href="#main">Skip to content</a>

  <!-- Custom cursor layers (hidden until script.js activates them on mouse move). -->
  <div class="cursor-dot" aria-hidden="true"></div>
  <div class="cursor-ring" aria-hidden="true"></div>

  <!-- Drifting CSS star field. -->
  <div class="stars" aria-hidden="true"></div>

  <header class="nav">
    <a class="brand" href="#top">EMERGE</a>
    <nav class="nav-links" aria-label="On this page">
      <a href="#features">Features</a>
      <a href="#how-it-works">How it works</a>
      <a href="#faq">FAQ</a>
      <a href="#access">Get the app</a>
    </nav>
    <a class="nav-login" href="/login">Log in</a>
  </header>

  <main id="main">
    <!-- ============ HERO ============ -->
    <section class="hero" id="top">
      <div class="hero-copy">
        <p class="eyebrow">An identity-first habit engine</p>
        <h1>Who do you wish to become?</h1>
        <p class="sub">Forge Your Identity. Build Your Habits.</p>
        <div class="hero-ctas">
          <a class="btn btn-primary" href="https://play.google.com/store/apps/details?id=com.emerge.emerge_app">
            Get it on Google Play
          </a>
          <a class="btn btn-ghost" href="/signup">Continue in Browser →</a>
        </div>
      </div>

      <!-- Phone mockup: script.js loops a scripted "timeline in action". -->
      <div class="phone" id="phone-mockup" aria-hidden="true">
        <div class="phone-notch" aria-hidden="true"></div>
        <div class="phone-screen">
          <div class="screen-top">
            <span class="screen-day">Day 37</span>
            <span class="screen-streak">🔥 37</span>
          </div>

          <div class="habit-list">
            <div class="habit-card">
              <span class="h-icon" aria-hidden="true">🏃</span>
              <div class="h-body">
                <span class="h-name">Morning run</span>
                <div class="h-bar"><span class="h-fill"></span></div>
              </div>
              <span class="h-check" aria-hidden="true"></span>
            </div>
            <div class="habit-card">
              <span class="h-icon" aria-hidden="true">📖</span>
              <div class="h-body">
                <span class="h-name">Read 20 pages</span>
                <div class="h-bar"><span class="h-fill"></span></div>
              </div>
              <span class="h-check" aria-hidden="true"></span>
            </div>
            <div class="habit-card">
              <span class="h-icon" aria-hidden="true">✍️</span>
              <div class="h-body">
                <span class="h-name">Deep work</span>
                <div class="h-bar"><span class="h-fill"></span></div>
              </div>
              <span class="h-check" aria-hidden="true"></span>
            </div>
            <div class="habit-card">
              <span class="h-icon" aria-hidden="true">🧘</span>
              <div class="h-body">
                <span class="h-name">Evening reflection</span>
                <div class="h-bar"><span class="h-fill"></span></div>
              </div>
              <span class="h-check" aria-hidden="true"></span>
            </div>
          </div>

          <div class="xp-row">
            <span>Explorer · Lv 12</span>
            <div class="xp-bar"><span class="xp-fill"></span></div>
            <span class="xp-num">960 / 1,400 XP</span>
          </div>

          <div class="mini-world">
            <span class="world-dot" aria-hidden="true"></span>
            Your world
          </div>

          <div class="level-toast" aria-hidden="true">LEVEL UP — EXPLORER</div>
        </div>
      </div>
    </section>

    <!-- ============ WHAT IS EMERGE ============ -->
    <section class="what glass">
      <p class="eyebrow">The idea</p>
      <h2>Not a to-do list. A becoming.</h2>
      <p>
        Emerge is an <strong>identity-first habit engine</strong> — you choose
        who you want to become, and the app turns that into habits, streaks,
        and a world that literally grows with you. It doesn't just track what
        you do; it shapes who you are.
      </p>
    </section>

    <!-- ============ FEATURES ============ -->
    <section id="features">
      <h2>Everything you need to become</h2>
      <div class="card-grid">
        <article class="card glass">
          <span class="card-icon" aria-hidden="true">✦</span>
          <h3>Identity Studio</h3>
          <p>Pick your archetype and shape your avatar around who you're becoming, not just what you're doing.</p>
        </article>
        <article class="card glass">
          <span class="card-icon" aria-hidden="true">◎</span>
          <h3>Habit engine</h3>
          <p>Daily habits with streaks, XP, and a timeline command center built for one-tap completions.</p>
        </article>
        <article class="card glass">
          <span class="card-icon" aria-hidden="true">◈</span>
          <h3>World Map</h3>
          <p>A living world that grows as your attributes level up — Strength, Vitality, Focus, Creativity, Spirit, and Intellect.</p>
        </article>
        <article class="card glass">
          <span class="card-icon" aria-hidden="true">∞</span>
          <h3>Timeline</h3>
          <p>Your daily command center: see everything at a glance, complete in seconds, stay in flow.</p>
        </article>
        <article class="card glass">
          <span class="card-icon" aria-hidden="true">▲</span>
          <h3>Tribes & challenges</h3>
          <p>Team up with your crew, take on challenges, and climb leaderboards together.</p>
        </article>
        <article class="card glass">
          <span class="card-icon" aria-hidden="true">◒</span>
          <h3>AI Narrator</h3>
          <p>An ambient coach that recaps your day and nudges you forward — never nagging, always present.</p>
        </article>
      </div>
    </section>

    <!-- ============ HOW IT WORKS ============ -->
    <section id="how-it-works">
      <h2>How it works</h2>
      <div class="steps">
        <div class="step glass">
          <span class="step-num">1</span>
          <h3>Forge your identity</h3>
          <p>Take the archetype first step and define who you're becoming.</p>
        </div>
        <div class="step glass">
          <span class="step-num">2</span>
          <h3>Build the habits</h3>
          <p>Attach 2–3 daily habits with time slots and reminders that fit your life.</p>
        </div>
        <div class="step glass">
          <span class="step-num">3</span>
          <h3>Watch your world grow</h3>
          <p>Earn XP, level your attributes, and grow your world — and your crew.</p>
        </div>
      </div>
    </section>

    <!-- ============ ACCESS ============ -->
    <section id="access">
      <h2>Emerge on every device</h2>
      <div class="access-grid">
        <article class="access-card glass">
          <h3>📱 Android</h3>
          <p>Carry your journey everywhere. Take habits, streaks, and your world with you.</p>
          <a class="btn btn-primary" href="https://play.google.com/store/apps/details?id=com.emerge.emerge_app">
            Get it on Google Play
          </a>
        </article>
        <article class="access-card glass">
          <h3>🌐 Browser</h3>
          <p>Open it in any browser — no install. Same journey, same account, anywhere.</p>
          <a class="btn btn-ghost" href="/signup">Continue in Browser</a>
        </article>
      </div>
      <p class="access-note">Same account on both. Your progress syncs automatically.</p>
    </section>

    <!-- ============ FAQ ============ -->
    <section id="faq">
      <h2>Frequently asked questions</h2>
      <div class="faq-list">
        <details>
          <summary>What is Emerge?</summary>
          <p>An identity-first habit engine: you don't just track habits — you become who you're building toward. Your world grows as your attributes level up, making progress visible and real.</p>
        </details>
        <details>
          <summary>Is it free?</summary>
          <p>Free to start. An optional subscription unlocks additional Premium features — see the in-app subscription screen for the current details.</p>
        </details>
        <details>
          <summary>Where can I use it?</summary>
          <p>On Android via Google Play, and in any browser at this site. Your progress syncs across devices automatically.</p>
        </details>
        <details>
          <summary>Do I need an account?</summary>
          <p>Yes — a login keeps your data and world synced across devices. Sign in with Google or email in under a minute.</p>
        </details>
        <details>
          <summary>What are archetypes?</summary>
          <p>Six identity styles — Explorer, Athlete, Scholar, Creator, Stoic, and Zealot. Each one themes your world and guides the habit choices that fit who you're becoming.</p>
        </details>
        <details>
          <summary>What about my privacy?</summary>
          <p>Your habits and identity data are yours. For details, see our Privacy Policy in the footer.</p>
        </details>
      </div>
    </section>
  </main>

  <footer>
    <div class="footer-brand">
      <span class="brand">EMERGE</span>
      <p>Forge Your Identity. Build Your Habits.</p>
    </div>
    <div class="footer-links">
      <a href="TERMS_URL">Terms of Service</a>
      <a href="PRIVACY_URL">Privacy Policy</a>
    </div>
    <p class="footer-copy">© 2026 Emerge</p>
  </footer>

  <script src="script.js"></script>
</body>
</html>
```

- [ ] **Step 1.5: Put the real legal URLs into the two footer anchors**

The two footer anchor `href`s are marked `TERMS_URL` / `PRIVACY_URL`. Replace them with the app's exact URLs — pull them from the source of truth:

Run: `grep -ohE "https://docs\.google\.com/document/[^\"']+" lib/features/onboarding/presentation/screens/welcome_screen.dart | sort -u`

Expected output: exactly two lines, each starting `https://docs.google.com/document/...` and ending `/pub`. Those two lines ARE the URLs — replace the `TERMS_URL` and `PRIVACY_URL` markers in the footer above with them, verbatim (no hand-typing).

> The smoke test (Task 1) extracts the very same two URLs from `welcome_screen.dart` and asserts they exist in `landing.html` — so if you paste wrong bytes, the test fails red. Paste the exact grep output, nothing else. Do NOT type them by hand.

- [ ] **Step 2: Run the smoke test to verify it passes (green)**

Run: `node --test scripts/test_landing.mjs`
Expected: PASS — `tests 8, pass 8, fail 0`.

If the "legal links" test fails: your two `href` values differ from the grep output — fix them and re-run.

- [ ] **Step 3: Commit**

```bash
git add web-landing/landing.html
git commit -m "feat(web-landing): full landing page markup — hero, features, FAQ, access"
```

---

### Task 3: Landing page styles (nebula, glass, responsive)

**Files:**
- Create: `web-landing/styles.css`

- [ ] **Step 1: Create `web-landing/styles.css`**

```css
/* web-landing/styles.css — Emerge landing page.
   Follows docs/design.md §2: cosmic void, purple nebula, green accent #2BEE79,
   glassmorphism, Spline Sans. Static page, so everything below is hand-rolled. */

:root {
  --void: #0A0A1A;
  --purple: #1A0A2A;
  --mid: #2A1A3A;
  --green: #2BEE79;
  --green-bright: #4ADE80;
  --ink: #F4F3FF;
  --glass: rgba(255, 255, 255, 0.08);
  --glass-border: rgba(255, 255, 255, 0.12);
  --radius-card: 22px;
}

* { box-sizing: border-box; }

html { scroll-behavior: smooth; }

body {
  margin: 0;
  min-height: 100vh;
  overflow-x: hidden;
  color: var(--ink);
  font-family: "Spline Sans", -apple-system, BlinkMacSystemFont, "Segoe UI",
    Roboto, Helvetica, Arial, sans-serif;
  background-color: var(--void);
  /* Nebula: layered radial gradients over near-black. */
  background-image:
    radial-gradient(52rem 40rem at 12% -8%, rgba(122, 40, 140, 0.22), transparent 62%),
    radial-gradient(46rem 38rem at 108% 6%, rgba(52, 10, 200, 0.16), transparent 62%),
    radial-gradient(50rem 44rem at 50% 118%, rgba(43, 238, 121, 0.07), transparent 60%),
    radial-gradient(30rem 28rem at 86% 44%, rgba(42, 26, 58, 0.85), transparent 65%);
  background-attachment: fixed;
}

/* ---- Star field (pure CSS, drifts slowly) ---- */
.stars {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  background-image:
    radial-gradient(1px 1px at 25px 35px, rgba(255, 255, 255, 0.5), transparent),
    radial-gradient(1px 1px at 115px 85px, rgba(255, 255, 255, 0.35), transparent),
    radial-gradient(1.2px 1.2px at 220px 180px, rgba(255, 255, 255, 0.6), transparent),
    radial-gradient(1px 1px at 340px 60px, rgba(255, 255, 255, 0.35), transparent),
    radial-gradient(1.4px 1.4px at 452px 300px, rgba(255, 255, 255, 0.5), transparent),
    radial-gradient(1px 1px at 560px 160px, rgba(255, 255, 255, 0.4), transparent),
    radial-gradient(1.2px 1.2px at 700px 400px, rgba(255, 255, 255, 0.5), transparent),
    radial-gradient(1px 1px at 120px 520px, rgba(255, 255, 255, 0.35), transparent),
    radial-gradient(1.4px 1.4px at 320px 640px, rgba(255, 255, 255, 0.45), transparent),
    radial-gradient(1px 1px at 500px 720px, rgba(255, 255, 255, 0.4), transparent),
    radial-gradient(1.2px 1.2px at 720px 560px, rgba(255, 255, 255, 0.5), transparent);
  background-size: 760px 760px;
  animation: star-drift 90s linear infinite;
}

@keyframes star-drift {
  from { background-position: 0 0; }
  to   { background-position: -760px 760px; }
}

/* ---- Global helpers ---- */
.skip-link {
  position: absolute;
  left: -9999px;
  top: 0;
  z-index: 100;
  padding: 10px 16px;
  background: var(--green);
  color: #04210f;
  border-radius: 0 0 10px 0;
  font-weight: 700;
}
.skip-link:focus { left: 0; }

.glass {
  background: var(--glass);
  border: 1px solid var(--glass-border);
  border-radius: var(--radius-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

header, main, footer { position: relative; z-index: 1; }

main {
  max-width: 1120px;
  margin: 0 auto;
  padding: 0 24px 96px;
}

section { padding: 84px 0 0; }

h1, h2, h3 { margin: 0; line-height: 1.15; }

h1 {
  font-size: clamp(2.6rem, 6vw, 4.6rem);
  font-weight: 700;
  letter-spacing: -0.02em;
}

h2 {
  font-size: clamp(1.7rem, 3.4vw, 2.5rem);
  font-weight: 600;
  letter-spacing: -0.01em;
  margin-bottom: 20px;
}

h3 { font-size: 1.15rem; font-weight: 600; margin-bottom: 8px; }

p { line-height: 1.6; color: rgba(255, 255, 255, 0.72); }

.eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.24em;
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--green);
  margin: 0 0 14px;
}

/* ---- Nav ---- */
.nav {
  position: sticky;
  top: 0;
  z-index: 50;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  padding: 16px clamp(24px, 5vw, 56px);
  background: rgba(10, 10, 26, 0.72);
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
}

.brand {
  font-weight: 700;
  letter-spacing: 0.32em;
  font-size: 0.95rem;
  color: #fff;
  text-decoration: none;
}

.nav-links {
  display: flex;
  gap: 28px;
  margin-left: auto;
}
.nav-links a {
  color: rgba(255, 255, 255, 0.72);
  text-decoration: none;
  font-size: 0.92rem;
  transition: color 0.2s;
}
.nav-links a:hover { color: var(--green); }

.nav-login {
  color: #fff;
  text-decoration: none;
  font-size: 0.92rem;
  font-weight: 600;
  padding: 9px 18px;
  border: 1px solid var(--glass-border);
  border-radius: 999px;
  background: var(--glass);
  transition: border-color 0.2s, background 0.2s;
}
.nav-login:hover { border-color: var(--green); background: rgba(43, 238, 121, 0.1); }

/* ---- Buttons ---- */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px 28px;
  border-radius: 999px;
  font-weight: 600;
  font-size: 1rem;
  letter-spacing: 0.02em;
  text-decoration: none;
  cursor: pointer;
  transition: transform 0.18s ease, box-shadow 0.18s ease, background 0.18s ease;
}
.btn:active { transform: translateY(0); }

.btn-primary {
  background: linear-gradient(135deg, var(--green), var(--green-bright));
  color: #04210f;
  box-shadow: 0 10px 28px rgba(43, 238, 121, 0.35);
}
.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 14px 34px rgba(43, 238, 121, 0.45);
}

.btn-ghost {
  color: #fff;
  border: 1px solid rgba(255, 255, 255, 0.28);
  background: rgba(255, 255, 255, 0.06);
}
.btn-ghost:hover {
  transform: translateY(-2px);
  border-color: var(--green);
  background: rgba(43, 238, 121, 0.08);
}

a:focus-visible, summary:focus-visible, button:focus-visible {
  outline: 2px solid var(--green);
  outline-offset: 3px;
}

/* ---- Hero ---- */
.hero {
  display: grid;
  grid-template-columns: 1.05fr 0.95fr;
  align-items: center;
  gap: 56px;
  min-height: calc(100vh - 72px);
  padding-top: 0;
}

.hero-copy .sub {
  font-size: 1.25rem;
  color: rgba(255, 255, 255, 0.65);
  margin: 18px 0 30px;
}

.hero-ctas { display: flex; flex-wrap: wrap; gap: 14px; }

/* ---- Phone mockup (scripted in script.js) ---- */
.phone {
  width: 288px;
  aspect-ratio: 9 / 19;
  margin: 0 auto;
  padding: 10px;
  border-radius: 46px;
  background: #0d0d1a;
  border: 1px solid rgba(255, 255, 255, 0.14);
  box-shadow: 0 44px 90px rgba(0, 0, 0, 0.55), 0 0 0 1px rgba(0, 0, 0, 0.6);
}

.phone-screen {
  position: relative;
  height: 100%;
  border-radius: 36px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 14px 12px 16px;
  /* Cosmic screen, same family as the app. */
  background: radial-gradient(130% 90% at 50% 0%, var(--purple) 0%, var(--void) 62%);
}

.phone-notch {
  position: absolute;
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
  width: 74px;
  height: 16px;
  border-radius: 10px;
  background: #05050c;
  z-index: 2;
}

.screen-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.55);
  padding-top: 6px;
}
.screen-day { font-weight: 700; color: #fff; letter-spacing: 0.06em; }
.screen-streak { color: var(--green); font-weight: 600; }

.habit-list { display: flex; flex-direction: column; gap: 8px; }

.habit-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.08);
}
.h-icon { font-size: 0.95rem; }
.h-body { flex: 1; min-width: 0; }
.h-name {
  display: block;
  font-size: 12px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.85);
  transition: color 0.3s;
}
.h-bar {
  height: 4px;
  margin-top: 6px;
  border-radius: 2px;
  background: rgba(255, 255, 255, 0.12);
  overflow: hidden;
}
.h-fill {
  display: block;
  height: 100%;
  width: 0;
  border-radius: 2px;
  background: linear-gradient(90deg, var(--green), var(--green-bright));
  transition: width 1s cubic-bezier(0.22, 1, 0.36, 1);
}
.h-check {
  width: 18px;
  height: 18px;
  flex: none;
  border-radius: 50%;
  border: 1.5px solid rgba(255, 255, 255, 0.25);
  display: grid;
  place-items: center;
  color: #04210f;
  font-size: 10px;
  font-weight: 700;
  transition: background 0.3s, border-color 0.3s;
}

/* Completed state (script.js toggles .done). */
.habit-card.done .h-fill { width: 100%; }
.habit-card.done .h-name { color: rgba(255, 255, 255, 0.42); text-decoration: line-through; }
.habit-card.done .h-check { background: var(--green); border-color: var(--green); }
.habit-card.done .h-check::after { content: "✓"; }

.xp-row { display: flex; flex-direction: column; gap: 6px; margin-top: auto; font-size: 10px; color: rgba(255, 255, 255, 0.6); }
.xp-row span { display: flex; justify-content: space-between; }
.xp-bar { height: 6px; border-radius: 3px; background: rgba(255, 255, 255, 0.12); overflow: hidden; }
.xp-fill {
  display: block;
  height: 100%;
  width: 0;
  border-radius: 3px;
  background: linear-gradient(90deg, var(--green), var(--green-bright));
  transition: width 1.2s cubic-bezier(0.22, 1, 0.36, 1);
}

.mini-world {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 10px;
  color: rgba(255, 255, 255, 0.55);
}
.world-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--green);
  box-shadow: 0 0 12px rgba(43, 238, 121, 0.95);
  animation: world-pulse 2.2s ease-out infinite;
}
@keyframes world-pulse {
  0%   { box-shadow: 0 0 0 0 rgba(43, 238, 121, 0.5); }
  70%  { box-shadow: 0 0 0 9px rgba(43, 238, 121, 0); }
  100% { box-shadow: 0 0 0 0 rgba(43, 238, 121, 0); }
}

.level-toast {
  position: absolute;
  left: 50%;
  top: 40%;
  transform: translateX(-50%);
  padding: 8px 16px;
  border-radius: 999px;
  background: rgba(43, 238, 121, 0.16);
  border: 1px solid rgba(43, 238, 121, 0.5);
  color: var(--green);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.08em;
  opacity: 0;
  transition: opacity 0.35s ease;
  white-space: nowrap;
}
.level-toast.visible { opacity: 1; }

/* ---- What / cards ---- */
.what { padding: 40px 40px 44px; margin-top: 84px; }
.what p { max-width: 46em; font-size: 1.08rem; }

.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.card {
  padding: 28px;
  transition: transform 0.2s ease, border-color 0.2s ease;
}
.card:hover { transform: translateY(-6px); border-color: rgba(43, 238, 121, 0.35); }

.card-icon {
  display: grid;
  place-items: center;
  width: 46px;
  height: 46px;
  margin-bottom: 16px;
  border-radius: 14px;
  background: rgba(43, 238, 121, 0.12);
  color: var(--green);
  font-size: 1.3rem;
}

/* ---- Steps ---- */
.steps {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 20px;
}

.step { padding: 30px 28px; position: relative; }

.step-num {
  position: absolute;
  top: 22px;
  right: 24px;
  font-size: 2.6rem;
  font-weight: 700;
  color: transparent;
  -webkit-text-stroke: 1px rgba(43, 238, 121, 0.5);
}

/* ---- Access ---- */
.access-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.access-card { padding: 34px 32px; display: flex; flex-direction: column; gap: 10px; }
.access-card h3 { font-size: 1.35rem; }
.access-card .btn { align-self: flex-start; margin-top: 8px; }

.access-note {
  text-align: center;
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.55);
  margin-top: 18px;
}

/* ---- FAQ ---- */
.faq-list { max-width: 760px; display: flex; flex-direction: column; gap: 10px; }

details {
  border: 1px solid var(--glass-border);
  border-radius: 16px;
  background: var(--glass);
  padding: 0 22px;
}
details[open] { border-color: rgba(43, 238, 121, 0.35); }

summary {
  cursor: pointer;
  list-style: none;
  padding: 18px 34px 18px 0;
  font-weight: 600;
  position: relative;
}
summary::-webkit-details-marker { display: none; }
summary::after {
  content: "+";
  position: absolute;
  right: 2px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--green);
  font-weight: 700;
  font-size: 1.2rem;
}
details[open] summary::after { content: "–"; }

details p { margin: 0 0 18px; padding-right: 8px; }

/* ---- Footer ---- */
footer {
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  padding: 48px clamp(24px, 5vw, 56px) 56px;
  display: flex;
  flex-wrap: wrap;
  gap: 24px 48px;
  align-items: center;
  justify-content: space-between;
}
.footer-brand p { margin: 8px 0 0; font-size: 0.9rem; color: rgba(255, 255, 255, 0.5); }
.footer-links { display: flex; gap: 26px; }
.footer-links a {
  color: rgba(255, 255, 255, 0.65);
  text-decoration: underline;
  text-underline-offset: 4px;
  font-size: 0.92rem;
}
.footer-links a:hover { color: var(--green); }
.footer-copy { font-size: 0.85rem; color: rgba(255, 255, 255, 0.4); margin: 0; }

/* ---- Custom cursor (dot + trailing ring) ---- */
.cursor-dot,
.cursor-ring {
  position: fixed;
  top: 0;
  left: 0;
  pointer-events: none;
  opacity: 0;
}
.cursor-dot {
  z-index: 9999;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--green);
  box-shadow: 0 0 12px rgba(43, 238, 121, 0.8);
  transform: translate(-50%, -50%);
  transition: opacity 0.2s;
}
.cursor-ring {
  z-index: 9998;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: 1.5px solid rgba(43, 238, 121, 0.7);
  transform: translate(-50%, -50%);
  transition: width 0.16s ease, height 0.16s ease, border-color 0.16s ease, opacity 0.2s;
}
.cursor-ring.is-hover {
  width: 46px;
  height: 46px;
  border-color: rgba(43, 238, 121, 0.95);
}
.cursor-visible .cursor-dot,
.cursor-visible .cursor-ring { opacity: 1; }

/* Touch: the cursor layer never appears. */
@media (pointer: coarse) {
  .cursor-dot, .cursor-ring { display: none; }
}

/* ---- Responsive ---- */
@media (max-width: 1100px) {
  .hero {
    grid-template-columns: 1fr;
    text-align: center;
    gap: 40px;
    padding-top: 64px;
  }
  .hero-ctas { justify-content: center; }
  .access-grid { grid-template-columns: 1fr; }
}

@media (max-width: 700px) {
  .nav-links { display: none; }
  .hero { min-height: auto; }
  h1 { font-size: 2.2rem; }
  .card-grid { grid-template-columns: 1fr; }
  .steps { grid-template-columns: 1fr; }
  .what { padding: 28px 22px 32px; }
  footer { flex-direction: column; align-items: flex-start; gap: 16px; }
}

/* ---- Reduced motion: calm static state ---- */
@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  *,
  *::before,
  *::after {
    animation-duration: 0.001s !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.001s !important;
  }
  .cursor-ring { display: none; }
}
```

- [ ] **Step 2: Verify the smoke test still passes + visual check**

Run: `node --test scripts/test_landing.mjs`
Expected: PASS — `tests 8, pass 8, fail 0`.

Visual check (optional but recommended): `python3 -m http.server 8000 --directory web-landing` → open `http://localhost:8000/` — hero, glass cards, footer render; nebula + stars visible.

- [ ] **Step 3: Commit**

```bash
git add web-landing/styles.css
git commit -m "style(landing): nebula background, glassmorphism, custom-cursor styles, responsive"
```

---

### Task 4: Landing page script (custom cursor + phone loop)

**Files:**
- Create: `web-landing/script.js`

- [ ] **Step 1: Create `web-landing/script.js`**

```js
/* web-landing/script.js — tiny, dependency-free page behavior.
 *
 * 1. Custom cursor: 6px green dot at the pointer + a trailing ring that lags
 *    behind (rAF lerp). Native cursor is kept visible for usability;
 *    touch devices and reduced-motion get no overlay.
 * 2. Phone mockup: a scripted ~12s loop of the Timeline "in action" —
 *    habit cards complete one-by-one, streak ticks 37→40, XP fills,
 *    level-up toast appears, then the loop resets. */

(function () {
  "use strict";

  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ── 1. Custom cursor ─────────────────────────────────────────────── */
  const finePointer = window.matchMedia("(pointer: fine)").matches;
  const dot = document.querySelector(".cursor-dot");
  const ring = document.querySelector(".cursor-ring");

  if (finePointer && dot && ring) {
    let mx = -100, my = -100, rx = -100, ry = -100, raf = null;

    const place = (el, x, y) => {
      el.style.transform = `translate3d(${x}px, ${y}px, 0) translate(-50%, -50%)`;
    };

    window.addEventListener(
      "mousemove",
      (e) => {
        mx = e.clientX;
        my = e.clientY;
        place(dot, mx, my);
        if (!document.body.classList.contains("cursor-visible")) {
          document.body.classList.add("cursor-visible");
        }
        if (raf === null) raf = requestAnimationFrame(loop);
      },
      { passive: true },
    );

    function loop() {
      // Reduced motion: keep the dot, drop the trailing animation entirely.
      if (reduced) {
        raf = null;
        return;
      }
      rx += (mx - rx) * 0.22;
      ry += (my - ry) * 0.22;
      place(ring, rx, ry);
      raf = requestAnimationFrame(loop);
    }

    document.querySelectorAll("a, button, summary").forEach((el) => {
      el.addEventListener("mouseenter", () => ring.classList.add("is-hover"));
      el.addEventListener("mouseleave", () => ring.classList.remove("is-hover"));
    });
  }

  /* ── 2. Phone mockup timeline loop ─────────────────────────────────── */
  const phone = document.getElementById("phone-mockup");
  if (phone) {
    const cards = phone.querySelectorAll(".habit-card");
    const streak = phone.querySelector(".screen-streak");
    const xpFill = phone.querySelector(".xp-fill");
    const xpNum = phone.querySelector(".xp-num");
    const toast = phone.querySelector(".level-toast");
    const XP_TEXT = ["960", "1,070", "1,190", "1,400"];

    // phase: 0 = fresh day, 1..3 = first N cards completed. 3 is the
    // "level up" beat (full XP + toast), then it resets to 0.
    const apply = (phase) => {
      cards.forEach((card, i) => card.classList.toggle("done", i < phase));
      if (streak) streak.textContent = `🔥 ${37 + Math.min(phase, 3)}`;
      if (xpFill) xpFill.style.width = `${25 + phase * 25}%`;
      if (xpNum) xpNum.textContent = `${XP_TEXT[phase]} / 1,400 XP`;
      if (toast) toast.classList.toggle("visible", phase === 3);
    };

    if (reduced) {
      // Static, composed frame: one habit done, sensible resting state.
      apply(1);
      return;
    }

    let phase = 0;
    const WAIT = [2400, 2400, 2600, 4400]; // ms per phase → ~12s loop

    const tick = () => {
      apply(phase);
      const wait = WAIT[phase];
      phase = (phase + 1) % 4;
      setTimeout(tick, wait);
    };
    tick();
  }
})();
```

- [ ] **Step 2: Verify tests pass + manual behavior check**

Run: `node --test scripts/test_landing.mjs` → PASS (`tests 8, pass 8, fail 0`).

Manual: `python3 -m http.server 8000 --directory web-landing` (or open `web-landing/landing.html` directly) — move the mouse: green dot follows, ring lags then catches up, ring grows over links. Phone mockup: cards complete one-by-one, streak ticks 37→40, XP fills, toast appears at the end, then the loop resets. In browser devtools set `prefers-reduced-motion: reduce` → static composed frame, no ring.

- [ ] **Step 3: Commit**

```bash
git add web-landing/script.js
git commit -m "feat(landing): custom cursor + scripted timeline phone mockup"
```

---

### Task 5: Copy script for the deploy pipeline

**Files:**
- Create: `scripts/build_landing.sh`

- [ ] **Step 1: Create `scripts/build_landing.sh`**

```bash
#!/usr/bin/env bash
#
# Copy the static landing page (web-landing/) into the Flutter web build
# (build/web/). Runs AFTER `flutter build web --release` (which wipes
# build/web) and BEFORE `firebase deploy`, so the landing is never clobbered.
#
# Usage: bash scripts/build_landing.sh [dest_dir]   (default: build/web)
set -euo pipefail

DEST="${1:-build/web}"

if [[ ! -f web-landing/landing.html ]]; then
  echo "!! web-landing/landing.html not found — run from the repo root." >&2
  exit 1
fi

mkdir -p "$DEST"
cp web-landing/landing.html "$DEST/landing.html"
cp web-landing/styles.css "$DEST/styles.css"
cp web-landing/script.js "$DEST/script.js"

echo "Landing page copied to $DEST:"
ls -la "$DEST"/landing.html "$DEST"/styles.css "$DEST"/script.js
```

- [ ] **Step 2: Make executable and verify**

Run: `chmod +x scripts/build_landing.sh && bash scripts/build_landing.sh /tmp/landing-out`
Expected: exit 0 + `ls` output showing the three copied files.

- [ ] **Step 3: Commit**

```bash
git add scripts/build_landing.sh
git commit -m "build(web): script to copy the landing page into build/web"
```

---

### Task 6: Hosting rewrite + cache headers in firebase.json

**Files:**
- Modify: `firebase.json` (hosting → rewrites + headers)

- [ ] **Step 1: Edit `firebase.json` — add the `/` rewrite**

In the `hosting` block, replace the current `rewrites` array (which starts with `app-ads.txt` then `**`):

```json
    "rewrites": [
      {
        "source": "/",
        "destination": "/landing.html"
      },
      {
        "source": "/app-ads.txt",
        "destination": "/app-ads.txt"
      },
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
```

**Ordering contract:** `/` and `/app-ads.txt` MUST remain before the `**` catch-all. Firebase picks the most-specific match, but explicit order documents intent for review.

- [ ] **Step 2: Add no-cache headers for the landing assets**

The existing `**/*.@(js|css|...)` rule hands out `Cache-Control: public, max-age=31536000, immutable`. Landing assets are NOT fingerprinted, so a redeploy would serve stale CSS/JS for a year. Add these two rules **above** that catch-all header rule (most-specific match wins, but keep intent visible):

```json
      {
        "source": "landing.css",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache, no-store, must-revalidate"
          }
        ]
      },
      {
        "source": "landing.js",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache, no-store, must-revalidate"
          }
        ]
      },
```

Note: `landing.css` / `landing.js` literal sources beat the `**/*.@(js|css|...)` glob (most-specific match wins), so the never-expiring cache rule cannot apply to them.

- [ ] **Step 3: Validate the JSON**

Run: `python3 -m json.tool firebase.json > /dev/null && echo JSON_OK`
Expected: `JSON_OK`.

- [ ] **Step 4: Commit**

```bash
git add firebase.json
git commit -m "chore(hosting): serve landing page at /, no-cache its assets"
```

---

### Task 7: Verify rewrites with the hosting emulator

**Files:**
- None (verification only)

- [ ] **Step 1: Prepare a local Flutter build if needed**

The emulator serves `build/web/`. If `build/web/index.html` doesn't exist yet, run: `flutter build web --release` (or the faster `flutter build web` if a prior build dir exists). Then: `bash scripts/build_landing.sh`.

- [ ] **Step 2: Emulator run asserting all three URL behaviors**

Run:

```bash
firebase emulators:exec --only hosting '
  set -e
  echo "-- / should be the landing page --"
  curl -s http://localhost:5000/ | grep -q "Who do you wish to become?" && echo LANDING_OK
  curl -s http://localhost:5000/ | grep -q "flutter_bootstrap" && echo "!! / served the Flutter app" && exit 1 || true
  echo "-- /signup, /timeline should boot the Flutter app --"
  curl -s http://localhost:5000/signup   | grep -q "flutter_bootstrap" && echo APP_SIGNUP_OK
  curl -s http://localhost:5000/timeline | grep -q "flutter_bootstrap" && echo APP_TIMELINE_OK
  echo ALL_REWRITES_OK
'
```

Expected final line: `ALL_REWRITES_OK` (and `LANDING_OK` / `APP_SIGNUP_OK` / `APP_TIMELINE_OK`). If `flutter_bootstrap` is missing for app routes, you didn't build web (Task 7 Step 1).

- [ ] **Step 3: No commit (verification only)**

---

### Task 8: Wire the landing build + test into CI

**Files:**
- Modify: `.github/workflows/firebase-hosting-merge.yml`
- Modify: `.github/workflows/firebase-hosting-pull-request.yml`

- [ ] **Step 1: Edit both workflows — insert two steps after `Build web`**

In **both** files, change:

```yaml
      - name: Build web
        run: flutter build web --release

      - uses: FirebaseExtended/action-hosting-deploy@v0
```

to:

```yaml
      - name: Build web
        run: flutter build web --release

      - name: Build landing page
        run: bash scripts/build_landing.sh

      - name: Test landing page
        run: node --test scripts/test_landing.mjs

      - uses: FirebaseExtended/action-hosting-deploy@v0
```

(The ubuntu-latest runner ships Node — no extra setup needed.)

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/firebase-hosting-merge.yml .github/workflows/firebase-hosting-pull-request.yml
git commit -m "ci(hosting): copy + smoke-test landing page before every web deploy"
```

---

### Task 9: Final verification protocol

- [ ] **Step 1: Run every check fresh**

```bash
node --test scripts/test_landing.mjs
```

Expected: `# pass 8` / `pass 8`, `fail 0`.

```bash
dart analyze
```

Expected: `No issues found!` — no Dart changed, so this proves nothing regressed accidentally.

```bash
git status --short
```

Expected: only `web-landing/`, `scripts/test_landing.mjs`, `scripts/build_landing.sh`, `firebase.json`, `.github/workflows/*` files staged/new — **no `lib/` changes**, no `web/index.html` changes.

- [ ] **Step 2: Live-channel preview (user action, requires `firebase login`)**

```bash
bash scripts/build_landing.sh        # after any flutter build web --release
firebase hosting:channel:deploy preview-landing --expires 3d
```

Open the preview URL — confirm: `/` shows the landing (nebula, cursor dot + ring, phone loop), `/signup` boots the app, Play Store button exits to the store listing, FAQ opens/closes, "Log in" reaches `/login`. On a phone/emulator touch: native cursor only (no ring).

- [ ] **Step 3: Done — report evidence**

Report exact outputs from Step 1 commands (test counts, analyzer line), the channel preview URL, and screen-checked behaviors. Never claim done without these.

---

## Self-Review Summary

- **Spec coverage:** §2.1 files ✔ (Tasks 1–4), §2.2 rewrite ✔ (Task 6), §2.3 deploy ✔ (Tasks 5, 8), §3 content ✔ (Task 2, incl. §3.6 Play Store + browser access and §3.7 six FAQ items), §4 visual ✔ (Tasks 3–4, incl. §4.1 phone loop), §5.1 smoke ✔ (Tasks 1–2), §5.2 emulator ✔ (Task 7), §6 risks ✔ (no-cache headers Task 6; reduced motion Task 4; touch Task 3), §7 order ✔.
- **No placeholders:** every task carries complete code. The only "fill-in" is the two legal footer URLs — and it is deterministic: a `grep` command prints the exact strings, and the smoke test extracts the same strings from the app and fails red until both match (no drift possible).
- **Type/name consistency:** selectors asserted in the smoke test match markup — `id="phone-mockup"`, `id="features|how-it-works|access|faq"`, `styles.css`, `script.js`; `.done` / `.visible` toggles in `script.js` match CSS in `styles.css`; `.access-grid` matches markup in `landing.html`; rewrite path `/` → `landing.html` matches what `build_landing.sh` copies into `build/web/`.