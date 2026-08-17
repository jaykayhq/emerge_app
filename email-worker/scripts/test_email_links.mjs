/**
 * test_email_links.mjs — end-to-end proof that the verification and
 * password-reset links the email worker sends ACTUALLY work.
 *
 * Runs against the Firebase Auth EMULATOR ONLY (never production). It drives
 * the exact same Admin SDK calls the worker uses (generateEmailVerificationLink
 * / generatePasswordResetLink with handleCodeInApp:true + the app URLs), then
 * redeems the oobCodes the way the Flutter app does, asserting:
 *
 *   1. Verification: oobCode from the link → emailVerified flips to true
 *   2. Reset: oobCode from the link → password actually changes (sign-in with
 *      the new password succeeds)
 *
 * Usage (from email-worker/):
 *   firebase emulators:start --only auth &
 *   FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
 *     FIREBASE_SERVICE_ACCOUNT=../scripts/service-account-key.json \
 *     node scripts/test_email_links.mjs
 *
 * Refuses to run without the emulator host — this must never touch production.
 */

import { initializeApp, cert } from "firebase-admin";
import { getAuth } from "firebase-admin/auth";
import fs from "node:fs";

const EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST;
if (!EMULATOR_HOST) {
  console.error(
    "Refusing to run: FIREBASE_AUTH_EMULATOR_HOST must be set (e.g. localhost:9099).",
  );
  console.error("This script is emulator-only and must never touch production.");
  process.exit(1);
}

const keyPath = process.env.FIREBASE_SERVICE_ACCOUNT || "../scripts/service-account-key.json";
const serviceAccount = JSON.parse(fs.readFileSync(keyPath, "utf8"));
const app = initializeApp({
  credential: cert(serviceAccount),
  projectId: serviceAccount.project_id,
});
const auth = getAuth(app);

// The emulator accepts any API key; the fake one is what it echoes in
// generated action links. Real calls go through the app with a real key.
const REST = `http://${EMULATOR_HOST}/identitytoolkit.googleapis.com/v1`;
const API_KEY = "fake-api-key";
const VERIFY_URL = "https://tradeflash-l2966.web.app/verify-email";
const RESET_URL = "https://tradeflash-l2966.web.app/reset-password";

function rest(path) {
  return `${REST}/${path}?key=${API_KEY}`;
}

let failures = 0;
function check(label, ok, detail = "") {
  console.log(`${ok ? "✅" : "❌"} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures++;
}

function extractOobCode(link) {
  const m = /[?&]oobCode=([^&]+)/.exec(link);
  return m ? decodeURIComponent(m[1]) : null;
}

async function signIn(email, password) {
  const res = await fetch(rest("accounts:signInWithPassword"), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(body.error?.message ?? `signIn failed (${res.status})`);
  return body;
}

const email = `linktest-${Date.now()}@example.com`;
const password = "OriginalPass123!";
const newPassword = "NewPass456!";
let uid;

console.log(`=== Email link E2E (emulator ${EMULATOR_HOST}) ===\n`);

try {
  // ── 0. Create the test user (emailVerified: false) ──
  const user = await auth.createUser({ email, password, emailVerified: false });
  uid = user.uid;
  console.log(`Created test user: ${email} (${uid})\n`);

  // ══ 1. VERIFICATION LINK ══
  console.log("── Verification link ──");
  const verifyLink = await auth.generateEmailVerificationLink(email, {
    handleCodeInApp: true,
    url: VERIFY_URL,
  });
  console.log(`  link: ${verifyLink}`);
  const verifyCode = extractOobCode(verifyLink);
  check("link carries an oobCode", !!verifyCode, verifyCode ?? "missing");

  // Redeem like the app does: FirebaseAuth.applyActionCode(oobCode) calls
  // accounts:update with just the oobCode.
  const redeemRes = await fetch(rest("accounts:update"), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ oobCode: verifyCode }),
  });
  const redeemBody = await redeemRes.json();
  check("verification oobCode redeems (accounts:update 200)", redeemRes.ok, redeemBody.error?.message);

  const afterVerify = await auth.getUser(uid);
  check("emailVerified flips to true after redemption", afterVerify.emailVerified === true);

  // ══ 2. PASSWORD RESET LINK ══
  console.log("\n── Password reset link ──");
  const resetLink = await auth.generatePasswordResetLink(email, {
    handleCodeInApp: true,
    url: RESET_URL,
  });
  console.log(`  link: ${resetLink}`);
  const resetCode = extractOobCode(resetLink);
  check("link carries an oobCode", !!resetCode, resetCode ?? "missing");

  // Redeem like the app does: FirebaseAuth.confirmPasswordReset(oobCode,
  // newPassword) calls accounts:resetPassword with both.
  const resetRes = await fetch(rest("accounts:resetPassword"), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ oobCode: resetCode, newPassword }),
  });
  const resetBody = await resetRes.json();
  check("reset oobCode redeems (accounts:resetPassword 200)", resetRes.ok, resetBody.error?.message);

  // Prove the password actually changed: old fails, new works.
  let oldRejected = false;
  try {
    await signIn(email, password);
  } catch (e) {
    oldRejected = true;
  }
  check("old password rejected after reset", oldRejected);

  const newSignIn = await signIn(email, newPassword);
  check("sign-in with NEW password succeeds", !!newSignIn.idToken);

  console.log(`\n=== ${failures === 0 ? "ALL LINK TESTS PASSED" : `${failures} FAILURES`} ===`);
} catch (err) {
  console.error(`\n💥 UNCAUGHT ERROR: ${err.message}`);
  console.error(err.stack?.split("\n").slice(0, 4).join("\n"));
  failures++;
} finally {
  if (uid) {
    try {
      await auth.deleteUser(uid);
      console.log(`Cleaned up test user ${uid}`);
    } catch (e) {
      console.log(`Cleanup skipped: ${e.message}`);
    }
  }
  console.log(`EXIT_CODE=${failures === 0 ? 0 : 1}`);
  process.exit(failures === 0 ? 0 : 1);
}
