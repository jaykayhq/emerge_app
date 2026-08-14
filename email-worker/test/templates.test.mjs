import { test } from "node:test";
import assert from "node:assert/strict";
import { buildWelcomeHtml, buildReengagementHtml } from "../src/templates.js";

test("welcome html includes the display name and CTA", () => {
  const html = buildWelcomeHtml("Ada");
  assert.ok(html.includes("Welcome to Emerge, Ada."));
  assert.ok(html.includes("https://emerge.app/timeline"));
});

test("reengagement html includes the name and a nudge", () => {
  const html = buildReengagementHtml("Ada");
  assert.ok(html.includes("We miss you, Ada."));
  assert.ok(html.includes("https://emerge.app/timeline"));
});

test("handles a missing name gracefully", () => {
  assert.ok(buildWelcomeHtml(undefined).includes("Welcome to Emerge, friend."));
  assert.ok(buildReengagementHtml(undefined).includes("We miss you, friend."));
});

test("escapes special characters in the display name", () => {
  const html = buildWelcomeHtml('<b>Ada</b> & "Co"');
  assert.ok(html.includes("&lt;b&gt;Ada&lt;/b&gt; &amp; &quot;Co&quot;"));
  assert.ok(!html.includes("<b>Ada</b>"));
});
