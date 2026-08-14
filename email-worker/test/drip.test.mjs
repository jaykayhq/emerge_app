import { test } from "node:test";
import assert from "node:assert/strict";
import { runDripTask } from "../src/tasks/drip.js";
import { makeFakeDb, makeSender } from "./helpers/fake_db.mjs";

const now = Date.now();
const days = (n) => new Date(now - n * 24 * 60 * 60 * 1000);

function eligible(overrides = {}) {
  return {
    id: "u1",
    data: {
      email: "a@b.com",
      createdAt: days(5), // >= 3 days old
      lastActivity: days(1), // active within 7d
      ...overrides,
    },
  };
}

test("drip sends + marks eligible users", async () => {
  const { db, writes } = makeFakeDb([eligible()]);
  const sender = makeSender();

  const count = await runDripTask(db, { send: sender.send, dryRun: false });

  assert.equal(count, 1);
  assert.equal(sender.sent[0].to, "a@b.com");
  assert.ok(writes.some((w) => w.op === "set" && w.path === "users/u1"));
});

test("drip skips users already dripped", async () => {
  const { db, writes } = makeFakeDb([
    eligible({ reengagementEmailSentAt: { toMillis: () => 1 } }),
  ]);
  const sender = makeSender();

  const count = await runDripTask(db, { send: sender.send, dryRun: false });

  assert.equal(count, 0);
  assert.equal(writes.length, 0);
});

test("drip skips churned users (last activity older than 7 days)", async () => {
  const { db, writes } = makeFakeDb([
    eligible({ lastActivity: days(10) }),
    eligible({ id: "u2", lastActivity: undefined }),
  ]);
  const sender = makeSender();

  const count = await runDripTask(db, { send: sender.send, dryRun: false });

  assert.equal(count, 0);
  assert.equal(writes.length, 0);
});

test("drip does not mark users whose send failed", async () => {
  const { db, writes } = makeFakeDb([eligible()]);
  const sender = makeSender({ failFor: new Set(["a@b.com"]) });

  const count = await runDripTask(db, { send: sender.send, dryRun: false });

  assert.equal(count, 0);
  assert.equal(writes.length, 0); // no marker → retried next run
});
