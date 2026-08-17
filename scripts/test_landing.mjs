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