import { test } from "node:test";
import assert from "node:assert/strict";
import { runVerifyTask, VERIFY_COOLDOWN_MS, verificationBaseUrl } from "../src/tasks/verify.js";
import { makeFakeDb, makeSender } from "./helpers/fake_db.mjs";

const now = Date.now();
const requestedAt = { toMillis: () => now - 60_000 };
const sentRecently = { toMillis: () => now - 5_000 };
const sentLongAgo = { toMillis: () => now - VERIFY_COOLDOWN_MS - 60_000 };

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
    "https://emerge.app/verify-email",
  );
  assert.equal(verificationBaseUrl(undefined, env), "https://emerge.app/verify-email");
  assert.equal(verificationBaseUrl("android", env), "emergeapp://verify-email");
  assert.equal(verificationBaseUrl("ios", env), "emergeapp://verify-email");
  assert.equal(verificationBaseUrl("other", env), "https://emerge.app/verify-email");
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
      data: { email: "a@b.com", platform: "web", verificationRequestedAt: requestedAt },
    },
  ]);
  const sender = makeSender();

  const count = await runVerifyTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 1);
  assert.ok(sender.sent[0].html.includes("https://emerge.app/verify-email?oobCode="));
  const marker = writes.find((w) => w.op === "set" && w.path === "users/u1");
  assert.equal(marker.data.verificationEmailSentAt.constructor.name, "ServerTimestampTransform");
  assert.equal(marker.data.emailVerificationSentAt.constructor.name, "ServerTimestampTransform");
});

test("verify sends a custom-scheme deep link to mobile users", async () => {
  const { db } = makeFakeDb([
    {
      id: "u1",
      data: { email: "a@b.com", platform: "android", verificationRequestedAt: requestedAt },
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

test("verify does not reset the grace anchor on resends", async () => {
  const { db, writes } = makeFakeDb([
    {
      id: "u1",
      data: {
        email: "a@b.com",
        verificationRequestedAt: requestedAt,
        emailVerificationSentAt: sentLongAgo, // already on the 7-day clock
      },
    },
  ]);
  const sender = makeSender();

  const count = await runVerifyTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 1);
  const marker = writes.find((w) => w.op === "set" && w.path === "users/u1");
  assert.equal(marker.data.emailVerificationSentAt, undefined, "grace anchor untouched");
  assert.equal(marker.data.verificationEmailSentAt.constructor.name, "ServerTimestampTransform");
});

test("verify skips users within the resend cooldown", async () => {
  const { db, writes } = makeFakeDb([
    {
      id: "u1",
      data: {
        email: "a@b.com",
        verificationRequestedAt: requestedAt,
        verificationEmailSentAt: sentRecently,
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
  assert.equal(sender.sent.length, 0);
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
    { id: "u1", data: { email: "a@b.com", verificationRequestedAt: requestedAt } },
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
    { id: "u1", data: { email: "a@b.com", verificationRequestedAt: requestedAt } },
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
