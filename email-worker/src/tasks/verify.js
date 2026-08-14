import { FieldValue } from "firebase-admin/firestore";

/**
 * Verification email task — replaces Firebase Auth's default verification
 * email. Triggered near-real-time by the GitHub dispatch webhook (and the
 * 5-minute cron as fallback).
 *
 * For every user who requested verification (`users/{uid}.verificationRequestedAt`
 * set by the app after signup) and has not been emailed within the cooldown:
 *   1. Generate the click-to-verify link via the Admin SDK with
 *      handleCodeInApp:true and a custom URL (VERIFICATION_URL) — the link
 *      points straight back at the app's /verify-email route with the oobCode,
 *      so the user returns to the app after clicking (no Firebase hosted page).
 *   2. Send a branded SMTP email with the link.
 *   3. Mark verificationEmailSentAt (cooldown) and — only on the first send —
 *      emailVerificationSentAt (the 7-day grace-clock anchor used by the
 *      grace task; the client no longer writes it).
 */
export const VERIFY_COOLDOWN_MS = 60 * 1000; // 60s between sends
export const VERIFY_PAGE_SIZE = 100;
export const VERIFY_MAX_PAGES = 100;

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
// Real app destinations — emerge.app is a parked domain (no app there).
const DEFAULT_VERIFICATION_URL_WEB = "https://tradeflash-l2966.web.app/verify-email";
const DEFAULT_VERIFICATION_URL_APP = "emergeapp://verify-email";

/**
 * Platform-aware link base: web users get the web app route; mobile users
 * get the app's custom scheme so the link opens the installed app directly
 * (Android intent-filter / iOS URL scheme). Env-overridable:
 *   VERIFICATION_URL_WEB / VERIFICATION_URL_APP.
 */
export function verificationBaseUrl(platform, env = process.env) {
  const isMobile =
    platform === "android" || platform === "ios";
  return isMobile
    ? (env.VERIFICATION_URL_APP ?? DEFAULT_VERIFICATION_URL_APP)
    : (env.VERIFICATION_URL_WEB ?? DEFAULT_VERIFICATION_URL_WEB);
}

function buildVerificationHtml(url) {
  return `
    <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#0A0A1A;color:#F5F0E8;padding:32px 16px;text-align:center">
      <h1 style="color:#2DD4BF;">Confirm your Emerge email</h1>
      <p style="font-size:16px;line-height:1.6;">
        Tap the button below to verify your email and jump straight back into
        the app.
      </p>
      <a href="${url}" style="display:inline-block;margin-top:20px;padding:14px 28px;border-radius:12px;background:#2DD4BF;color:#0A0A1A;font-weight:bold;text-decoration:none">
        Verify my email
      </a>
      <p style="font-size:12px;color:#8B8B8B;margin-top:28px;">
        If the button does not work, copy this link into your browser:<br/>
        ${url}
      </p>
    </div>`;
}

export async function runVerifyTask(db, auth, { send, dryRun, now = Date.now() }) {
  const cooldownCutoff = new Date(now - VERIFY_COOLDOWN_MS);
  let lastDoc;
  let sent = 0;

  for (let page = 0; page < VERIFY_MAX_PAGES; page++) {
    let query = db
      .collection("users")
      .where("verificationRequestedAt", ">", new Date(0))
      .limit(VERIFY_PAGE_SIZE);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snap = await query.get();
    if (snap.empty) {
      break;
    }

    const batch = db.batch();
    let changed = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      const email = typeof data.email === "string" ? data.email : "";
      if (!email || !EMAIL_RE.test(email)) {
        console.warn(`[verify] skipping ${doc.id}: no valid email`);
        continue;
      }
      const lastSentAt = data.verificationEmailSentAt;
      const lastSentMillis = toMillis(lastSentAt);
      if (lastSentMillis !== 0 && lastSentMillis > cooldownCutoff.getTime()) {
        continue; // within cooldown — no spam on repeated requests
      }
      if (dryRun) {
        console.log(`[verify][dry-run] would email ${email} (${doc.id})`);
        sent++;
        continue;
      }

      try {
        // handleCodeInApp keeps the oobCode in the URL → the app's
        // /verify-email route processes it and returns the user to the app.
        // Web and mobile get different link bases (see verificationBaseUrl).
        const link = await auth.generateEmailVerificationLink(email, {
          handleCodeInApp: true,
          url: verificationBaseUrl(
            typeof data.platform === "string" ? data.platform : "web",
          ),
        });
        await send({
          to: email,
          subject: "Verify your Emerge email",
          html: buildVerificationHtml(link),
        });
        const marker = {
          verificationEmailSentAt: FieldValue.serverTimestamp(),
        };
        // Only the first send starts the 7-day grace clock — re-sends must
        // not keep pushing the lock deadline out forever.
        if (data.emailVerificationSentAt == null) {
          marker.emailVerificationSentAt = FieldValue.serverTimestamp();
        }
        batch.set(db.collection("users").doc(doc.id), marker, { merge: true });
        changed++;
        sent++;
      } catch (err) {
        console.error(`[verify] failed for ${doc.id}:`, err);
      }
    }
    if (changed > 0 && !dryRun) {
      try {
        await batch.commit();
      } catch (err) {
        console.error(`[verify] page ${page + 1} commit failed:`, err);
        throw err;
      }
    }
    console.log(`[verify] page ${page + 1}: ${changed} emails sent`);
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < VERIFY_PAGE_SIZE) {
      break;
    }
  }
  console.log(`[verify] done: ${sent} total`);
  return sent;
}

function toMillis(value) {
  if (value instanceof Date) return value.getTime();
  const ts = value;
  return ts?.toMillis?.() ?? 0;
}
