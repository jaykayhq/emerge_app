import { test } from "node:test";
import assert from "node:assert/strict";
import { runGraceTask, GRACE_PERIOD_MS } from "../src/tasks/grace.js";
import { makeFakeDb, makeFakeAuth } from "./helpers/fake_db.mjs";

const now = Date.now();
const past = () => new Date(now - GRACE_PERIOD_MS - 1000);
const sentAt = { toMillis: () => past().getTime() };

test("locks unverified users past the grace period", async () => {
  const { db, writes } = makeFakeDb([
    { id: "u1", data: { emailVerificationSentAt: sentAt } },
  ]);
  const auth = makeFakeAuth({ u1: false });

  await runGraceTask(db, auth, { dryRun: false });

  const lock = writes.find((w) => w.op === "set" && w.path === "users/u1");
  assert.ok(lock, "expected a lock write");
  assert.equal(lock.data.emailLockedAt.constructor.name, "ServerTimestampTransform");
});

test("does not lock verified users (authoritative auth flag)", async () => {
  const { db, writes } = makeFakeDb([
    { id: "u1", data: { emailVerificationSentAt: sentAt } },
  ]);
  const auth = makeFakeAuth({ u1: true });

  await runGraceTask(db, auth, { dryRun: false });

  assert.equal(writes.length, 0);
});

test("clears a stale lock for a user who verified after being locked", async () => {
  const { db, writes } = makeFakeDb([
    { id: "u1", data: { emailVerificationSentAt: sentAt, emailLockedAt: sentAt } },
  ]);
  const auth = makeFakeAuth({ u1: true });

  await runGraceTask(db, auth, { dryRun: false });

  const clear = writes.find((w) => w.op === "set" && w.path === "users/u1");
  assert.ok(clear, "expected a clear write");
  assert.equal(clear.data.emailLockedAt.constructor.name, "DeleteTransform");
});

test("skips candidates whose auth record is missing", async () => {
  const { db, writes } = makeFakeDb([
    { id: "ghost", data: { emailVerificationSentAt: sentAt } },
  ]);
  const auth = makeFakeAuth({}); // no records → getUser rejects

  await runGraceTask(db, auth, { dryRun: false });

  assert.equal(writes.length, 0);
});

test("grace dry-run never writes", async () => {
  const { db, writes } = makeFakeDb([
    { id: "u1", data: { emailVerificationSentAt: sentAt } },
  ]);
  const auth = makeFakeAuth({ u1: false });

  await runGraceTask(db, auth, { dryRun: true });

  assert.equal(writes.length, 0);
});
