import admin from "firebase-admin";
import { buildReengagementHtml } from "../templates.js";

/**
 * Daily re-engagement drip — ported verbatim from
 * functions/src/marketing_email.ts (enforceReengagementDripInternal).
 * Nudges users who signed up >= 3 days ago, are still active
 * (lastActivity within 7d), and haven't been dripped yet. Idempotent via
 * users/{uid}.reengagementEmailSentAt.
 */
export const DRIP_SINCE_MS = 3 * 24 * 60 * 60 * 1000; // signed up >= 3 days ago
export const DRIP_ACTIVE_WINDOW_MS = 7 * 24 * 60 * 60 * 1000; // active 7d
export const DRIP_PAGE_SIZE = 100;
export const DRIP_MAX_PAGES = 100;

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function toMillis(value) {
  if (value instanceof Date) return value.getTime();
  const ts = value;
  return ts?.toMillis?.() ?? 0;
}

export async function runDripTask(db, { send, dryRun }) {
  const since = new Date(Date.now() - DRIP_SINCE_MS);
  let lastDoc;
  let sent = 0;

  for (let page = 0; page < DRIP_MAX_PAGES; page++) {
    let query = db
      .collection("users")
      .where("createdAt", "<=", since)
      .limit(DRIP_PAGE_SIZE);
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
      if (data.reengagementEmailSentAt != null) {
        continue; // already dripped
      }
      const email = typeof data.email === "string" ? data.email : "";
      if (!email || !EMAIL_RE.test(email)) {
        continue;
      }
      const lastActive = toMillis(data.lastActivity);
      if (lastActive === 0 || Date.now() - lastActive > DRIP_ACTIVE_WINDOW_MS) {
        continue; // never active, or churned out of the window
      }

      if (dryRun) {
        console.log(`[drip][dry-run] would send to ${email} (${doc.id})`);
        sent++;
        continue;
      }
      try {
        await send({
          to: email,
          subject: "We miss you — your identity is still building",
          html: buildReengagementHtml(
            typeof data.displayName === "string" ? data.displayName : undefined,
          ),
        });
        batch.set(
          db.collection("users").doc(doc.id),
          {
            reengagementEmailSentAt:
              admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        changed++;
        sent++;
      } catch (err) {
        console.error(`[drip] failed for ${doc.id}:`, err);
      }
    }
    if (changed > 0 && !dryRun) {
      try {
        await batch.commit();
      } catch (err) {
        console.error(`[drip] page ${page + 1} commit failed:`, err);
        throw err;
      }
    }
    console.log(`[drip] page ${page + 1}: ${changed} emails sent`);
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < DRIP_PAGE_SIZE) {
      break;
    }
  }
  console.log(`[drip] done: ${sent} total`);
  return sent;
}
