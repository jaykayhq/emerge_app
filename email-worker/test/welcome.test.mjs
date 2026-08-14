import { test } from "node:test";
import assert from "node:assert/strict";
import { runWelcomeTask, WELCOME_LOOKBACK_MS } from "../src/tasks/welcome.js";
import { makeFakeDb, makeSender } from "./helpers/fake_db.mjs";

const now = Date.now();
const recent = () => new Date(now - 1000);
const old = () => new Date(now - WELCOME_LOOKBACK_MS - 1000);

test("welcome sends + marks valid recent users", async () => {
  const { db, writes } = makeFakeDb([
    { id: "u1", data: { email: "a@b.com", displayName: "Ada", createdAt: recent() } },
  ]);
  const sender = makeSender();

  const count = await runWelcomeTask(db, { send: sender.send, dryRun: false });

  assert.equal(count, 1);
  assert.equal(sender.sent.length, 1);
  assert.equal(sender.sent[0].to, "a@b.com");
  assert.ok(writes.some((w) => w.op === "set" && w.path === "users/u1"));
});

test("welcome skips users already marked and invalid emails", async () => {
  const { db, writes } = makeFakeDb([
    { id: "u1", data: { email: "a@b.com", welcomeEmailSentAt: { toMillis: () => 1 }, createdAt: recent() } },
    { id: "u2", data: { email: "not-an-email", createdAt: recent() } },
  ]);
  const sender = makeSender();

  const count = await runWelcomeTask(db, { send: sender.send, dryRun: false });

  assert.equal(count, 0);
  assert.equal(sender.sent.length, 0);
  assert.equal(writes.length, 0);
});

test("welcome skips system/seed and admin docs", async () => {
  const { db, writes } = makeFakeDb([
    { id: "u1", data: { email: "sys@emerge.app", creatorUserId: "system", createdAt: recent() } },
    { id: "u2", data: { email: "admin@emerge.app", isAdmin: true, createdAt: recent() } },
  ]);
  const sender = makeSender();

  const count = await runWelcomeTask(db, { send: sender.send, dryRun: false });

  assert.equal(count, 0);
  assert.equal(writes.length, 0);
});

test("welcome excludes accounts created before the lookback window", async () => {
  const { db, writes } = makeFakeDb([
    { id: "old", data: { email: "old@b.com", createdAt: old() } },
  ]);
  const sender = makeSender();

  const count = await runWelcomeTask(db, { send: sender.send, dryRun: false });

  assert.equal(count, 0);
  assert.equal(writes.length, 0);
});

test("welcome dry-run never sends or writes", async () => {
  const { db, writes } = makeFakeDb([
    { id: "u1", data: { email: "a@b.com", createdAt: recent() } },
  ]);
  const sender = makeSender();

  const count = await runWelcomeTask(db, { send: sender.send, dryRun: true });

  assert.equal(count, 1); // counted as intended
  assert.equal(sender.sent.length, 0);
  assert.equal(writes.length, 0);
});
