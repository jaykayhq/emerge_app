import { test } from "node:test";
import assert from "node:assert/strict";
import {
  runResetTask,
  RESET_COOLDOWN_MS,
  RESET_MAX_EMAILS_PER_RUN,
} from "../src/tasks/reset.js";
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

test("RESET_COOLDOWN_MS is 15 minutes", () => {
  assert.equal(RESET_COOLDOWN_MS, 15 * 60 * 1000);
});

test("reset skips requests older than 24h (expired oob codes)", async () => {
  const { db, writes } = makeFakeDb([
    {
      id: "r1",
      data: {
        email: "a@b.com",
        type: "password_reset",
        requestedAt: { toMillis: () => now - 25 * 60 * 60 * 1000 },
      },
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
  // The expired request is never emailed, and the run garbage-collects the
  // stale sentAt==null doc instead of leaving it to crowd the scan window.
  assert.equal(writes.length, 1);
  assert.equal(writes[0].op, "delete");
  assert.equal(writes[0].path, "email_requests/r1");
});

test("reset fails quietly when the Auth user does not exist", async () => {
  const { db, writes } = makeFakeDb([
    {
      id: "r1",
      data: { email: "ghost@nowhere.com", type: "password_reset", requestedAt },
    },
  ]);
  const sender = makeSender();
  const auth = {
    async generatePasswordResetLink(email) {
      const err = new Error("There is no user record corresponding to this identifier.");
      err.code = "auth/user-not-found";
      throw err;
    },
  };

  const count = await runResetTask(db, auth, {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 0, "unknown addresses are skipped, not counted");
  assert.equal(sender.sent.length, 0);
  assert.equal(writes.length, 0, "no marker written for a skipped address");
});

test("reset enforces the per-run email cap against forged bursts", async () => {
  const docs = Array.from({ length: 550 }, (_, i) => ({
    id: `r${String(i).padStart(5, "0")}`,
    data: { email: `user${i}@b.com`, type: "password_reset", requestedAt },
  }));
  const { db, writes } = makeFakeDb(docs);
  const sender = makeSender();

  const count = await runResetTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(RESET_MAX_EMAILS_PER_RUN, 500);
  assert.equal(count, RESET_MAX_EMAILS_PER_RUN, "caps at the per-run limit");
  assert.equal(sender.sent.length, RESET_MAX_EMAILS_PER_RUN);
  assert.equal(new Set(sender.sent.map((s) => s.to)).size, RESET_MAX_EMAILS_PER_RUN);
  assert.equal(writes.length, RESET_MAX_EMAILS_PER_RUN, "markers written for capped sends");
});

test("reset commits every sent marker when the cap is hit mid-page", async () => {
  // 502 sendable docs + 8 expired docs. Page 1 carries 92 sendable + 8
  // expired (the mix inside one page), pages 2-5 carry 400 sendable, and
  // page 6 carries the last 10 sendable — the cap of 500 is crossed when
  // the 500th sendable doc in page 6 is processed, so the run must commit
  // that page's pending markers before stopping.
  const docs = [];
  const idForEmail = new Map();
  let s = 0;
  const push = (sendable, expiry) => {
    const id = `r${String(docs.length).padStart(5, "0")}`;
    if (sendable) {
      const email = `user${s++}@b.com`;
      idForEmail.set(email, id);
      docs.push({ id, data: { email, type: "password_reset", requestedAt } });
    } else {
      docs.push({
        id,
        data: {
          email: `expired${docs.length}@b.com`,
          type: "password_reset",
          requestedAt: { toMillis: () => now - 25 * 60 * 60 * 1000 },
        },
      });
    }
  };
  for (let i = 0; i < 92; i++) push(true);
  for (let i = 0; i < 8; i++) push(false);
  for (let i = 0; i < 400; i++) push(true);
  for (let i = 0; i < 10; i++) push(true);
  assert.equal(s, 502, "502 sendable docs seeded");

  const { db, writes, committedRefs } = makeFakeDb(docs);
  const sender = makeSender();

  const count = await runResetTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, RESET_MAX_EMAILS_PER_RUN);
  assert.equal(sender.sent.length, RESET_MAX_EMAILS_PER_RUN);
  assert.equal(new Set(sender.sent.map((m) => m.to)).size, RESET_MAX_EMAILS_PER_RUN);
  const committedMarkers = committedRefs.filter((r) => r.op === "set");
  const committed = new Set(committedMarkers.map((r) => r.path));
  assert.equal(
    committedMarkers.length,
    RESET_MAX_EMAILS_PER_RUN,
    "every capped send's marker was committed, none dropped at the cap",
  );
  for (let i = 0; i < RESET_MAX_EMAILS_PER_RUN; i++) {
    const email = `user${i}@b.com`;
    assert.ok(
      committed.has(`email_requests/${idForEmail.get(email)}`),
      `marker committed for emailed address ${email}`,
    );
  }
});

test("reset sends exactly one email per address per run for duplicate docs", async () => {
  const docs = Array.from({ length: 20 }, (_, i) => ({
    id: `dup${i}`,
    data: { email: "dup@b.com", type: "password_reset", requestedAt },
  }));
  const { db, writes, committedRefs } = makeFakeDb(docs);
  const sender = makeSender();

  const count = await runResetTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 1, "one send for 20 duplicate docs for one address");
  assert.equal(sender.sent.length, 1);
  assert.equal(sender.sent[0].to, "dup@b.com");
  assert.equal(writes.length, 1, "single marker written");
  assert.equal(committedRefs.length, 1);
  assert.equal(committedRefs[0].path, "email_requests/dup0");
});

test("reset garbage-collects stale un-emailed requests (never emailed again)", async () => {
  const docs = [
    {
      id: "stale1",
      data: {
        email: "stale1@b.com",
        type: "password_reset",
        requestedAt: { toMillis: () => now - 26 * 60 * 60 * 1000 },
      },
    },
    {
      id: "stale2",
      data: {
        email: "stale2@b.com",
        type: "password_reset",
        requestedAt: { toMillis: () => now - 30 * 60 * 60 * 1000 },
      },
    },
    {
      id: "fresh",
      data: { email: "fresh@b.com", type: "password_reset", requestedAt },
    },
  ];
  const { db, writes, committedRefs } = makeFakeDb(docs);
  const sender = makeSender();

  const count = await runResetTask(db, makeAuth(), {
    send: sender.send,
    dryRun: false,
    now,
  });

  assert.equal(count, 1, "only the fresh request is emailed");
  assert.equal(sender.sent.length, 1);
  assert.equal(sender.sent[0].to, "fresh@b.com");
  const deleted = committedRefs.filter(
    (r) =>
      r.op === "delete" &&
      (r.path === "email_requests/stale1" || r.path === "email_requests/stale2"),
  );
  assert.equal(deleted.length, 2, "both stale docs deleted");
  assert.ok(
    committedRefs.some((r) => r.path === "email_requests/fresh"),
    "fresh marker committed",
  );
  assert.ok(
    writes.every((w) => w.path !== "email_requests/stale1" || w.op === "delete"),
    "stale docs are deleted, not marked",
  );
});

test("reset dry-run never deletes stale requests", async () => {
  const { db, writes, committedRefs } = makeFakeDb([
    {
      id: "stale1",
      data: {
        email: "stale1@b.com",
        type: "password_reset",
        requestedAt: { toMillis: () => now - 26 * 60 * 60 * 1000 },
      },
    },
  ]);
  const sender = makeSender();

  const count = await runResetTask(db, makeAuth(), {
    send: sender.send,
    dryRun: true,
    now,
  });

  assert.equal(count, 0, "stale doc is neither emailed nor counted");
  assert.equal(sender.sent.length, 0);
  assert.equal(writes.length, 0, "dry-run performs no writes or deletes");
  assert.equal(committedRefs.length, 0);
});
