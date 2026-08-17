import { test } from "node:test";
import assert from "node:assert/strict";
import { runVerifyTask, verificationBaseUrl } from "../src/tasks/verify.js";
import { makeFakeDb, makeSender } from "./helpers/fake_db.mjs";

const now = Date.now();
// Signup/resend markers are server timestamps from the app; the worker's
// sends are server timestamps too. 10 minutes apart exercises the real
// 5-minute cron cadence: an answered request must stay answered across runs.
const requestedLongAgo = { toMillis: () => now - 10 * 60_000 };
const requestedFresh = { toMillis: () => now - 1_000 };
const sentEarlier = { toMillis: () => now - 30_000 };
const sentLater = { toMillis: () => now - 5 * 60_000 };

function makeAuth() {
  return {
    async generateEmailVerificationLink(email, opts) {
      return `${opts.url}?oobCode=CODE-${email}`;
    },
  };
}

test("verificationBaseUrl differentiates web and mobile users", () => {
  const env = {};
  assert.equal(
    verificationBaseUrl("web", env),
    "https://tradeflash-l2966.web.app/verify-email",
  );
  assert.equal(verificationBaseUrl(undefined, env), "https://tradeflash-l2966.web.app/verify-email");
  assert.equal(verificationBaseUrl("android", env), "emergeapp://verify-email");
  assert.equal(verificationBaseUrl("ios", env), "emergeapp://verify-email");
  assert.equal(verificationBaseUrl("other", env), "https://tradeflash-l2966.web.app/verify-email");
  // Env overrides win.
  assert.equal(
    verificationBaseUrl("android", { VERIFICATION_URL_APP: "myapp://verify" }),
    "myapp://verify",
  );
});

test("verify sends a web link to web users", async () => {
  const { db, writes } = makeFakeDb([
    {
      id: "u1",
      data: { email: "a@b.com", platform: "web", verificationRequestedAt: requestedLongAgo },
    },
  ]);
  const sender = makeSender();

  const count = await runVerifyTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 1);
  assert.ok(sender.sent[0].html.includes("https://tradeflash-l2966.web.app/verify-email?oobCode="));
  const marker = writes.find((w) => w.op === "set" && w.path === "users/u1");
  assert.equal(marker.data.verificationEmailSentAt.constructor.name, "ServerTimestampTransform");
  assert.equal(marker.data.emailVerificationSentAt.constructor.name, "ServerTimestampTransform");
});

test("verify sends a custom-scheme deep link to mobile users", async () => {
  const { db } = makeFakeDb([
    {
      id: "u1",
      data: { email: "a@b.com", platform: "android", verificationRequestedAt: requestedLongAgo },
    },
  ]);
  const sender = makeSender();

  const count = await runVerifyTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 1);
  assert.ok(sender.sent[0].html.includes("emergeapp://verify-email?oobCode="));
});

test("verify sends again when the user issues a NEW request after a previous send", async () => {
  // The app writes a fresh verificationRequestedAt on every resend click —
  // that newer timestamp is the "command" that must trigger exactly one more
  // email. The grace anchor must NOT be reset on the resend.
  const { db, writes } = makeFakeDb([
    {
      id: "u1",
      data: {
        email: "a@b.com",
        verificationRequestedAt: requestedFresh,
        verificationEmailSentAt: sentEarlier,
        emailVerificationSentAt: sentEarlier, // already on the 7-day clock
      },
    },
  ]);
  const sender = makeSender();

  const count = await runVerifyTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 1, "a fresh request after a previous send must be emailed once");
  assert.equal(sender.sent.length, 1);
  const marker = writes.find((w) => w.op === "set" && w.path === "users/u1");
  assert.equal(marker.data.emailVerificationSentAt, undefined, "grace anchor untouched on resend");
  assert.equal(marker.data.verificationEmailSentAt.constructor.name, "ServerTimestampTransform");
});

test("verify does NOT re-send an already-answered request", async () => {
  // The regression: verificationRequestedAt is a sticky marker (set once at
  // signup). Once the worker has emailed it (verificationEmailSentAt set
  // AFTER the request), no further cron run may email again — otherwise the
  // 5-minute schedule spams every unverified user forever.
  const { db, writes } = makeFakeDb([
    {
      id: "u1",
      data: {
        email: "a@b.com",
        verificationRequestedAt: requestedLongAgo,
        verificationEmailSentAt: sentLater,
      },
    },
  ]);
  const sender = makeSender();

  const count = await runVerifyTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 0);
  assert.equal(sender.sent.length, 0, "no email for an already-answered request");
  assert.equal(writes.length, 0);
});

test("verify skips users who never requested verification", async () => {
  const { db, writes } = makeFakeDb([
    { id: "u1", data: { email: "a@b.com" } }, // no verificationRequestedAt
  ]);
  const sender = makeSender();

  const count = await runVerifyTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 0);
  assert.equal(writes.length, 0);
});

test("verify does not mark users whose send failed", async () => {
  const { db, writes } = makeFakeDb([
    { id: "u1", data: { email: "a@b.com", verificationRequestedAt: requestedLongAgo } },
  ]);
  const sender = makeSender({ failFor: new Set(["a@b.com"]) });

  const count = await runVerifyTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 0);
  assert.equal(writes.length, 0);
});

test("verify dry-run never sends or writes", async () => {
  const { db, writes } = makeFakeDb([
    { id: "u1", data: { email: "a@b.com", verificationRequestedAt: requestedLongAgo } },
  ]);
  const sender = makeSender();

  const count = await runVerifyTask(db, makeAuth(), {
    send: sender.send,
    dryRun: true,
    now,
  });

  assert.equal(count, 1);
  assert.equal(sender.sent.length, 0);
  assert.equal(writes.length, 0);
});
