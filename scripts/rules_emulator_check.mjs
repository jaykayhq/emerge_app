#!/usr/bin/env node
/**
 * Emulator rules-matrix check for the SP-H rules package (firestore.rules).
 *
 * Signs up two users against the Auth emulator, sets alice's role:'creator'
 * claim + verified creator_profiles doc and seeds a tribe/challenge via the
 * admin SDK (which bypasses rules), then drives the Firestore emulator's REST
 * API and asserts status codes for the full matrix:
 *
 *   no authorized read/write denied, no unauthorized write allowed.
 *
 * Usage: node scripts/rules_emulator_check.mjs   (emulators must be running)
 *
 *   firebase emulators:start --only firestore,auth
 *   # Firestore on 127.0.0.1:8080, Auth on 127.0.0.1:9099 (firebase.json)
 *
 * Exit codes: 0 all rows pass; 1 one or more rows FAIL; 2 emulators unreachable.
 *
 * No new npm deps: global fetch + the admin SDK from functions/node_modules.
 */
import { fileURLToPath } from "node:url";

const AUTH_HOST = "http://127.0.0.1:9099";
const FS_HOST = "http://127.0.0.1:8080";
const PROJECT_ID = "tradeflash-l2966";
const KEY = "?key=fake";
const AUTH = `${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts`;
const TOKEN = `${AUTH_HOST}/securetoken.googleapis.com/v1/token`;
const FS = `${FS_HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const TIMEOUT_MS = 15000;

// --- emulator reachability (before any SDK import, for a clean error) -------
async function reachable(url) {
  try {
    await fetch(url, { method: "GET", signal: AbortSignal.timeout(3000) });
    return true;
  } catch {
    return false;
  }
}

if (!(await reachable(`${AUTH_HOST}/`))) {
  console.error(`ERROR: Cannot reach the Auth emulator at ${AUTH_HOST}.`);
  console.error(
    "Start the emulators first, e.g.: firebase emulators:start --only firestore,auth",
  );
  process.exit(2);
}
if (!(await reachable(`${FS}/blueprints/__probe__`))) {
  console.error(`ERROR: Cannot reach the Firestore emulator at ${FS_HOST}.`);
  console.error(
    "Start the emulators first, e.g.: firebase emulators:start --only firestore,auth",
  );
  process.exit(2);
}

// --- admin SDK (functions/node_modules; env vars must precede the import) ----
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
const admin = (
  await import(fileURLToPath(new URL("../functions/node_modules/firebase-admin/lib/index.js", import.meta.url)))
).default;
if (admin.apps.length === 0) admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

// --- helpers -----------------------------------------------------------------
async function signUp(email) {
  const r = await fetch(`${AUTH}:signUp${KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "pass1234", returnSecureToken: true }),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  const j = await r.json();
  if (j.idToken) {
    return { idToken: j.idToken, refreshToken: j.refreshToken, uid: j.localId, email };
  }
  // Idempotent re-run against a still-running emulator: the account already
  // exists, so sign in with the same credentials instead of failing.
  if (j.error?.message === "EMAIL_EXISTS") {
    const s = await fetch(`${AUTH}:signInWithPassword${KEY}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password: "pass1234", returnSecureToken: true }),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    const sj = await s.json();
    if (!sj.idToken) {
      throw new Error(`signIn after EMAIL_EXISTS failed for ${email}: ${JSON.stringify(sj)}`);
    }
    return { idToken: sj.idToken, refreshToken: sj.refreshToken, uid: sj.localId, email };
  }
  throw new Error(`signUp failed for ${email}: ${JSON.stringify(j)}`);
}

// Mint a fresh ID token after setCustomUserClaims. The token returned by
// signUp was minted BEFORE the claim existed and does not carry it; a token
// minted after (refresh or re-sign-in) does. Fall back to re-sign-in if the
// refresh endpoint is unavailable.
async function tokenWithClaims(account) {
  const r = await fetch(`${TOKEN}${KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      grant_type: "refresh_token",
      refresh_token: account.refreshToken,
    }),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  const j = await r.json();
  if (j.id_token) return j.id_token;
  const s = await fetch(`${AUTH}:signInWithPassword${KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: account.email, password: "pass1234", returnSecureToken: true }),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  const sj = await s.json();
  if (!sj.idToken) throw new Error(`token refresh failed: ${JSON.stringify(sj)}`);
  return sj.idToken;
}

async function call(method, token, path, body) {
  const r = await fetch(`${FS}/${path}`, {
    method,
    headers: token
      ? { Authorization: `Bearer ${token}`, "Content-Type": "application/json" }
      : { "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  return r.status;
}

// Build a Firestore document {fields: {...}} REST body with typed values.
// Numbers/bools/strings get their primitive values; arrays become arrayValues;
// Date becomes a timestampValue (the emulator parses RFC 3339).
function value(v) {
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === "number") return { integerValue: String(v) };
  if (typeof v === "boolean") return { booleanValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(value) } };
  if (v === null) return { nullValue: null };
  return { stringValue: String(v) };
}
const doc = (fields) => ({
  fields: Object.fromEntries(Object.entries(fields).map(([k, v]) => [k, value(v)])),
});

const results = [];
function check(name, got, want) {
  const ok = got === want;
  results.push(`${ok ? "PASS" : "FAIL"}  ${name} (got ${got}, want ${want})`);
}

// --- setup: cleanup (idempotent re-runs) + seed + claims ---------------------
// Deterministic doc ids from a previous run would flip rows 5b/6/7b/10b from
// create-allow to update-deny (owner uid changes every run), so delete them
// first via the admin SDK (which bypasses rules).
const CLEANUP = [
  "creator_profiles/creator_demo",
  "blueprints/alice_bp",
  "blueprints/bob_bp",
  "blueprints/morning_9",
  "challenges/c_alice",
  "challenges/c_bob",
  "tribes/alice_creator_tribe",
  "tribes/bob_creator_tribe",
  "posts/p1",
  "creator_invite_codes/ABCD2345",
  "invite_codes/ABC123",
];
for (const p of CLEANUP) {
  await db.doc(p).delete().catch(() => {});
}

const alice = await signUp("alice@test.dev");
const bob = await signUp("bob@test.dev");
console.log(`[setup] alice uid ${alice.uid}, bob uid ${bob.uid}`);

await admin.auth().setCustomUserClaims(alice.uid, { role: "creator" });
alice.idToken = await tokenWithClaims(alice);
console.log("[setup] alice role:creator claim set + token refreshed");

// Verified creator profile — needed by isVerifiedCreator() (role claim + doc).
await db.collection("creator_profiles").doc(alice.uid).set({
  userId: alice.uid,
  ownerId: alice.uid,
  role: "creator",
  isVerifiedCreator: true,
});
// Official tribe (memberCount 10, members []) + a catalog challenge.
await db.collection("tribes").doc("morning_warriors").set({
  name: "Morning Warriors",
  archetypeId: "athlete",
  type: "official",
  memberCount: 10,
  members: [],
  totalXp: 0,
  lastStatsSync: admin.firestore.FieldValue.serverTimestamp(),
});
await db.collection("challenges").doc("c1").set({ title: "t", status: "active" });

// 10a creates an immutable habit_completions doc; a leftover from a previous
// run would flip the check from create-allow to update-deny, so delete it.
await db.doc(`users/${alice.uid}/habit_completions/c1`).delete().catch(() => {});

const A = alice.idToken;
const B = bob.idToken;

// --- matrix ------------------------------------------------------------------
// 1: blueprints — public read; writes only for admins / verified creators / 'system' seed
check("1a  unauthenticated read blueprints", await call("GET", null, "blueprints/x", null), 404); // allowed but doc missing -> NOT 401/403
check("1b  unauthenticated write blueprints", await call("PATCH", null, "blueprints/x", doc({ creatorUserId: "alice" })), 403);

// 2: users — owner-only read; isValidUser blocks premium spoofing
check("2a  users owner read (missing doc)", await call("GET", A, `users/${alice.uid}`, null), 404); // allowed but missing -> NOT 403
check("2b  users other read", await call("GET", B, `users/${alice.uid}`, null), 403);
check("2c  users isPremium write", await call("PATCH", A, `users/${alice.uid}`, doc({ isPremium: true })), 403);

// 3: user_stats — isValidStats denies premium fields (SP-H-1)
check("3   user_stats isPremium write", await call("PATCH", A, `user_stats/${alice.uid}`, doc({ isPremium: true })), 403);

// 4: creator_profiles — create only by admin; owners may update non-privileged
// fields. The 'creator_' system-seed carve-out was deleted (SP-D) — a normal
// user can no longer create creator_profiles/creator_demo.
check("4a  creator_profiles create by normal user", await call("PATCH", B, "creator_profiles/bob_uid", doc({ userId: "bob_uid", ownerId: "bob_uid" })), 403);
check("4b  creator_ prefix create by normal user", await call("PATCH", B, "creator_profiles/creator_demo", doc({ userId: "creator_demo" })), 403);
check("4c  creator_profiles flip isVerifiedCreator", await call("PATCH", A, `creator_profiles/${alice.uid}`, doc({ isVerifiedCreator: false })), 403);

// 5: blueprints — verified-creator + 'system' catalog carve-out (SP-H-1)
check("5a  blueprints non-verified write", await call("PATCH", B, "blueprints/bob_bp", doc({ creatorUserId: bob.uid })), 403);
check("5b  blueprints verified creator write", await call("PATCH", A, "blueprints/alice_bp", doc({ creatorUserId: alice.uid })), 200);
check("5c  blueprints system catalog seed by normal user", await call("PATCH", B, "blueprints/morning_9", doc({ creatorUserId: "system" })), 200);

// 6: challenges — verified creators may add their own (createdBy == uid)
check("6   challenges verified creator write", await call("PATCH", A, "challenges/c_alice", doc({ createdBy: alice.uid })), 200);
check("6b  challenges non-verified write", await call("PATCH", B, "challenges/c_bob", doc({ createdBy: bob.uid })), 403);

// 7: tribes — creator-type creation gated on verified creators
check("7a  tribe creator type by non-verified", await call("PATCH", B, "tribes/bob_creator_tribe", doc({ name: "B", type: "creator" })), 403);
check("7b  tribe creator type by verified", await call("PATCH", A, "tribes/alice_creator_tribe", doc({ name: "A", type: "creator", members: [], memberCount: 1 })), 200);

// 8: tribes — aggregate membership writes: keys, ±1 delta, caller == added member
const TRIBE = "tribes/morning_warriors";
// name/archetypeId/type repeat the seed values (never affected keys); totalXp: 0
// is included so the row holds under both PATCH merge and full-replace semantics.
const tribeBody = (memberCount, members, totalXp) =>
  doc({ name: "Morning Warriors", archetypeId: "athlete", type: "official", memberCount, members, lastStatsSync: new Date(), totalXp });
check("8a  tribe memberCount +1 (caller added)", await call("PATCH", B, TRIBE, tribeBody(11, [bob.uid], 0)), 200);
check("8b  tribe memberCount +5", await call("PATCH", B, TRIBE, tribeBody(16, [bob.uid], 0)), 403);
check("8c  tribe totalXp-only update", await call("PATCH", B, TRIBE, tribeBody(11, [bob.uid], 999999)), 403);
// SP-G exact-caller fix: +1 delta whose ADDED member is not the caller (alice
// is already a member and tries to add bob) must be denied.
await db.doc(TRIBE).set({
  name: "Morning Warriors",
  archetypeId: "athlete",
  type: "official",
  memberCount: 11,
  members: [alice.uid],
  totalXp: 0,
  lastStatsSync: admin.firestore.FieldValue.serverTimestamp(),
});
check("8d  tribe memberCount +1 but added member != caller", await call("PATCH", A, TRIBE, tribeBody(12, [alice.uid, bob.uid], 0)), 403);

// 9: invite codes — functions-only (admin SDK), clients always denied
check("9a  creator_invite_codes deny", await call("PATCH", A, "creator_invite_codes/ABCD2345", doc({ creatorUid: alice.uid })), 403);
check("9b  invite_codes deny", await call("PATCH", A, "invite_codes/ABC123", doc({ userId: alice.uid })), 403);

// 10: habit_completions (immutable log) + posts — the rateLimited guard is
// removed (SP-H-2), so a valid post with a timestamp createdAt now succeeds.
check("10a habit_completions create", await call("PATCH", A, `users/${alice.uid}/habit_completions/c1`, doc({ userId: alice.uid })), 200);
check("10b posts create", await call("PATCH", A, "posts/p1", doc({ content: "hi", userId: alice.uid, createdAt: new Date() })), 200);

// 11: club_leaderboards — self entries (entryId prefix uid_)
check("11  club_leaderboards self write", await call("PATCH", A, `club_leaderboards/${alice.uid}_morning_warriors`, doc({ userId: alice.uid, clubId: "morning_warriors", xp: 10 })), 200);

// --- summary -----------------------------------------------------------------
console.log(results.join("\n"));
const failed = results.filter((r) => r.startsWith("FAIL"));
if (failed.length) {
  console.error(`\n${failed.length} of ${results.length} matrix rows FAILED`);
  process.exit(1);
}
console.log(`\nALL ${results.length} RULES MATRIX CHECKS PASSED`);
