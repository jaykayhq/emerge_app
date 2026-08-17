import { FieldValue } from "firebase-admin/firestore";

/**
 * Password reset email task — sends the branded reset email instead of
 * Firebase Auth's default template.
 *
 * For every request doc in `email_requests` of type `password_reset` that
 * has not been emailed within the cooldown:
 *   1. Generate the reset link via the Admin SDK with handleCodeInApp:true
 *      and a custom URL (RESET_URL) — the link points straight back at the
 *      app's /reset-password route with the oobCode, so the user lands in
 *      the branded screen (no Firebase hosted page).
 *   2. Send a branded SMTP email with the link.
 *   3. Mark sentAt (idempotency marker).
 */
export const RESET_COOLDOWN_MS = 60 * 1000; // 60s between sends per email
export const RESET_PAGE_SIZE = 100;
export const RESET_MAX_PAGES = 100;

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
// Real app destination — emerge.app is a parked domain (no app there).
const DEFAULT_RESET_URL = "https://tradeflash-l2966.web.app/reset-password";

function buildResetHtml(url) {
  return `
    <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#0A0A1A;color:#F5F0E8;padding:32px 16px;text-align:center">
      <h1 style="color:#2DD4BF;">Reset your Emerge password</h1>
      <p style="font-size:16px;line-height:1.6;">
        Tap the button below to choose a new password. This link expires
        shortly.
      </p>
      <a href="${url}" style="display:inline-block;margin-top:20px;padding:14px 28px;border-radius:12px;background:#2DD4BF;color:#0A0A1A;font-weight:bold;text-decoration:none">
        Reset my password
      </a>
      <p style="font-size:12px;color:#8B8B8B;margin-top:28px;">
        You received this email because someone requested a password reset
        for this address. If that wasn't you, you can safely ignore it.
      </p>
    </div>`;
}

export async function runResetTask(db, auth, { send, dryRun, now = Date.now() }) {
  const cooldownCutoff = new Date(now - RESET_COOLDOWN_MS);
  let lastDoc;
  let sent = 0;

  for (let page = 0; page < RESET_MAX_PAGES; page++) {
    let query = db
      .collection("email_requests")
      .where("type", "==", "password_reset")
      .limit(RESET_PAGE_SIZE);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snap = await query.get();
    if (snap.empty) {
      break;
    }

    const batch = db.batch();
    let changed = 0;
    // Per-email cooldown: the latest send timestamp for each email across
    // EVERY doc in the page (a fresh request doc has no marker of its own,
    // so it must look at siblings for the same email).
    const latestSendByEmail = new Map();
    for (const doc of snap.docs) {
      const data = doc.data();
      const email = typeof data.email === "string" ? data.email : "";
      const sendMillis = Math.max(
        toMillis(data.sentAt),
        toMillis(data.lastSentAt),
      );
      if (!email) continue;
      const prev = latestSendByEmail.get(email) ?? 0;
      if (sendMillis > prev) latestSendByEmail.set(email, sendMillis);
    }
    for (const doc of snap.docs) {
      const data = doc.data();
      if (data.type !== "password_reset") {
        continue;
      }
      const email = typeof data.email === "string" ? data.email : "";
      if (!email || !EMAIL_RE.test(email)) {
        console.warn(`[reset] skipping ${doc.id}: no valid email`);
        continue;
      }
      if (data.sentAt != null) {
        continue; // already emailed — idempotent
      }
      const latestSendMillis = latestSendByEmail.get(email) ?? 0;
      if (latestSendMillis !== 0 && latestSendMillis > cooldownCutoff.getTime()) {
        continue; // this email was emailed within the cooldown
      }
      if (dryRun) {
        console.log(`[reset][dry-run] would email ${email} (${doc.id})`);
        sent++;
        continue;
      }

      try {
        // handleCodeInApp keeps the oobCode in the URL → the app's
        // /reset-password route applies it and returns the user to the app.
        const link = await auth.generatePasswordResetLink(email, {
          handleCodeInApp: true,
          url: process.env.RESET_URL ?? DEFAULT_RESET_URL,
        });
        await send({
          to: email,
          subject: "Reset your Emerge password",
          html: buildResetHtml(link),
        });
        const marker = {
          sentAt: FieldValue.serverTimestamp(),
          // Per-email cooldown anchor so a repeat request within 60s is
          // skipped even if it lands as a new doc.
          lastSentAt: FieldValue.serverTimestamp(),
        };
        batch.set(db.collection("email_requests").doc(doc.id), marker, { merge: true });
        changed++;
        sent++;
      } catch (err) {
        console.error(`[reset] failed for ${doc.id}:`, err);
      }
    }
    if (changed > 0 && !dryRun) {
      try {
        await batch.commit();
      } catch (err) {
        console.error(`[reset] page ${page + 1} commit failed:`, err);
        throw err;
      }
    }
    console.log(`[reset] page ${page + 1}: ${changed} emails sent`);
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < RESET_PAGE_SIZE) {
      break;
    }
  }
  console.log(`[reset] done: ${sent} total`);
  return sent;
}

function toMillis(value) {
  if (value instanceof Date) return value.getTime();
  const ts = value;
  return ts?.toMillis?.() ?? 0;
}
