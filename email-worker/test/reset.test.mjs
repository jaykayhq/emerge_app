import { test } from "node:test";
import assert from "node:assert/strict";
import { runResetTask, RESET_COOLDOWN_MS } from "../src/tasks/reset.js";
import { makeFakeDb, makeSender } from "./helpers/fake_db.mjs";

const now = Date.now();
const requestedAt = { toMillis: () => now - 60_000 };
const sentRecently = { toMillis: () => now - 5_000 };

function makeAuth() {
  return {
    async generatePasswordResetLink(email, opts) {
      return `${opts.url}?oobCode=RESET-${email}`;
    },
  };
}

test("reset sends a branded link to the app's reset-password route", async () => {
  const { db, writes } = makeFakeDb([
    {
      id: "r1",
      data: { email: "a@b.com", type: "password_reset", requestedAt },
    },
  ]);
  const sender = makeSender();

  const count = await runResetTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 1);
  assert.equal(sender.sent[0].to, "a@b.com");
  assert.ok(
    sender.sent[0].html.includes("https://tradeflash-l2966.web.app/reset-password?oobCode="),
  );
  const marker = writes.find((w) => w.op === "set" && w.path === "email_requests/r1");
  assert.equal(marker.data.sentAt.constructor.name, "ServerTimestampTransform");
});

test("reset skips requests already sent (idempotent marker)", async () => {
  const { db, writes } = makeFakeDb([
    {
      id: "r1",
      data: { email: "a@b.com", type: "password_reset", requestedAt, sentAt: sentRecently },
    },
  ]);
  const sender = makeSender();

  const count = await runResetTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 0);
  assert.equal(sender.sent.length, 0);
  assert.equal(writes.length, 0);
});

test("reset skips requests within the per-email cooldown", async () => {
  const { db, writes } = makeFakeDb([
    {
      id: "r1",
      data: { email: "a@b.com", type: "password_reset", requestedAt },
    },
    {
      id: "r2",
      data: { email: "a@b.com", type: "password_reset", requestedAt, sentAt: sentRecently },
    },
  ]);
  const sender = makeSender();

  const count = await runResetTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 0, "cooldown suppresses the duplicate request");
  assert.equal(sender.sent.length, 0);
  assert.equal(writes.length, 0);
});

test("reset skips invalid emails and non-reset request types", async () => {
  const { db, writes } = makeFakeDb([
    { id: "r1", data: { email: "not-an-email", type: "password_reset", requestedAt } },
    { id: "r2", data: { email: "b@b.com", type: "welcome", requestedAt } },
  ]);
  const sender = makeSender();

  const count = await runResetTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 0);
  assert.equal(sender.sent.length, 0);
  assert.equal(writes.length, 0);
});

test("reset does not mark requests whose send failed", async () => {
  const { db, writes } = makeFakeDb([
    {
      id: "r1",
      data: { email: "a@b.com", type: "password_reset", requestedAt },
    },
  ]);
  const sender = makeSender({ failFor: new Set(["a@b.com"]) });

  const count = await runResetTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 0);
  assert.equal(writes.length, 0);
});

test("reset dry-run never sends or writes", async () => {
  const { db, writes } = makeFakeDb([
    {
      id: "r1",
      data: { email: "a@b.com", type: "password_reset", requestedAt },
    },
  ]);
  const sender = makeSender();

  const count = await runResetTask(db, makeAuth(), {
    send: sender.send,
    dryRun: true,
    now,
  });

  assert.equal(count, 1);
  assert.equal(sender.sent.length, 0);
  assert.equal(writes.length, 0);
});

test("RESET_COOLDOWN_MS is 60 seconds", () => {
  assert.equal(RESET_COOLDOWN_MS, 60 * 1000);
});
