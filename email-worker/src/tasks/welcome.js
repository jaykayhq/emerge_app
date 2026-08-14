import { FieldValue } from "firebase-admin/firestore";
import { buildWelcomeHtml } from "../templates.js";

/**
 * Cron equivalent of the old `sendWelcomeEmail` Firestore trigger: find
 * accounts created in the last [WELCOME_LOOKBACK_MS] that have no
 * `welcomeEmailSentAt` marker, send one branded welcome email, and mark
 * them. The lookback prevents a retroactive welcome blast to pre-existing
 * accounts on the first run (the trigger never backfilled).
 */
export const WELCOME_LOOKBACK_MS = 7 * 24 * 60 * 60 * 1000;
export const WELCOME_PAGE_SIZE = 100;
export const WELCOME_MAX_PAGES = 100;

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function runWelcomeTask(db, { send, dryRun }) {
  const since = new Date(Date.now() - WELCOME_LOOKBACK_MS);
  let lastDoc;
  let sent = 0;

  for (let page = 0; page < WELCOME_MAX_PAGES; page++) {
    let query = db
      .collection("users")
      .where("createdAt", ">=", since)
      .limit(WELCOME_PAGE_SIZE);
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
      // Skip seed/system docs and admin accounts (same guard as the trigger).
      if (data.creatorUserId === "system" || data.isAdmin === true) {
        continue;
      }
      if (data.welcomeEmailSentAt != null) {
        continue; // already welcomed (idempotent marker)
      }
      const email = typeof data.email === "string" ? data.email : "";
      if (!email || !EMAIL_RE.test(email)) {
        console.warn(`[welcome] skipping ${doc.id}: no valid email`);
        continue;
      }

      if (dryRun) {
        console.log(`[welcome][dry-run] would send to ${email} (${doc.id})`);
        sent++;
        continue;
      }
      try {
        await send({
          to: email,
          subject: "Welcome to Emerge — your journey starts now",
          html: buildWelcomeHtml(
            typeof data.displayName === "string" ? data.displayName : undefined,
          ),
        });
        batch.set(
          db.collection("users").doc(doc.id),
          { welcomeEmailSentAt: FieldValue.serverTimestamp() },
          { merge: true },
        );
        changed++;
        sent++;
      } catch (err) {
        console.error(`[welcome] failed for ${doc.id}:`, err);
      }
    }
    if (changed > 0 && !dryRun) {
      try {
        await batch.commit();
      } catch (err) {
        console.error(`[welcome] page ${page + 1} commit failed:`, err);
        throw err;
      }
    }
    console.log(`[welcome] page ${page + 1}: ${changed} emails sent`);
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < WELCOME_PAGE_SIZE) {
      break;
    }
  }
  console.log(`[welcome] done: ${sent} total`);
  return sent;
}
