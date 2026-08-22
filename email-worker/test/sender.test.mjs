import test from "node:test";
import assert from "node:assert/strict";
import { resolveFrom } from "../src/sender.js";

test("resolveFrom uses EMAIL_FROM when set", () => {
  assert.equal(
    resolveFrom({ EMAIL_FROM: "Emerge <no-reply@emerge.app>" }),
    "Emerge <no-reply@emerge.app>",
  );
});

test("resolveFrom falls back to the authenticated SMTP user (Gmail) so mail is DKIM-signed", () => {
  assert.equal(
    resolveFrom({ SMTP_USER: "joe@gmail.com" }),
    "Emerge <joe@gmail.com>",
  );
});

test("resolveFrom treats an empty EMAIL_FROM (unset secret) as unset", () => {
  assert.equal(
    resolveFrom({ EMAIL_FROM: "", SMTP_USER: "joe@gmail.com" }),
    "Emerge <joe@gmail.com>",
  );
});

test("resolveFrom falls back to the owner Gmail only with no SMTP user", () => {
  assert.equal(resolveFrom({}), "Emerge <joeukpai55@gmail.com>");
});
