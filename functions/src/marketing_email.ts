/**
 * Marketing email flow (SP sub-project 3).
 *
 * sendWelcomeEmail: onDocumentCreated trigger on users/{uid} — one branded
 * welcome email per account. Fire-and-forget: failures are logged, never
 * thrown, so email can never break account creation.
 *
 * enforceReengagementDrip: daily scheduled job that nudges users who signed
 * up >= 3 days ago, are still active (lastActivity within 7d), and haven't
 * been dripped yet. Idempotent via users/{uid}.reengagementEmailSentAt.
 */
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { sendEmail } from "./email";
import { buildWelcomeHtml, buildReengagementHtml } from "./email_templates";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const sendWelcomeEmail = onDocumentCreated(
  { document: "users/{uid}", secrets: ["RESEND_API_KEY"] },
  async (event) => {
    const data = event.data?.data() ?? {};
    const uid = event.params.uid;
    const email = typeof data.email === "string" ? data.email : "";

    // Skip seed/system docs and admin accounts. Defensive: no current
    // users/{uid} writer produces these — keep the guard anyway.
    if (data.creatorUserId === "system" || data.isAdmin === true) {
      return;
    }
    if (!email || !EMAIL_RE.test(email)) {
      console.warn(`[welcome] skipping ${uid}: no valid email`);
      return;
    }

    try {
      await sendEmail({
        to: email,
        subject: "Welcome to Emerge — your journey starts now",
        html: buildWelcomeHtml(
          typeof data.displayName === "string" ? data.displayName : undefined
        ),
      });
    } catch (err) {
      console.error(`[welcome] failed for ${uid}:`, err);
    }
  }
);

// Drip parameters.
export const DRIP_SINCE_MS = 3 * 24 * 60 * 60 * 1000; // signed up >= 3 days ago
export const DRIP_ACTIVE_WINDOW_MS = 7 * 24 * 60 * 60 * 1000; // active 7d
// Page size small enough that a page of sequential sends commits within the
// function timeout even if several sends stall (10s axios timeout each).
export const DRIP_PAGE_SIZE = 100;
export const DRIP_MAX_PAGES = 100;

function toMillis(value: unknown): number {
  if (value instanceof Date) return value.getTime();
  const ts = value as { toMillis?: () => number } | undefined;
  return ts?.toMillis?.() ?? 0;
}

/** Testable body; wrapped by onSchedule. */
export async function enforceReengagementDripInternal(
  database: typeof db,
  nowMs: number
): Promise<void> {
  const since = new Date(nowMs - DRIP_SINCE_MS);
  let lastDoc: admin.firestore.QueryDocumentSnapshot | undefined;
  for (let page = 0; page < DRIP_MAX_PAGES; page++) {
    let query = database
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
    const batch = database.batch();
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
      if (lastActive === 0 || nowMs - lastActive > DRIP_ACTIVE_WINDOW_MS) {
        continue; // never active, or churned out of the window
      }
      try {
        await sendEmail({
          to: email,
          subject: "We miss you — your identity is still building",
          html: buildReengagementHtml(
            typeof data.displayName === "string" ? data.displayName : undefined
          ),
        });
        batch.set(
          database.collection("users").doc(doc.id),
          {
            reengagementEmailSentAt:
              admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        changed++;
      } catch (err) {
        console.error(`[drip] failed for ${doc.id}:`, err);
      }
    }
    if (changed > 0) {
      try {
        await batch.commit();
      } catch (err) {
        console.error(`[drip] page ${page + 1} commit failed:`, err);
        throw err; // rethrow so Cloud Scheduler retries — no data loss
      }
    }
    console.log(`[drip] page ${page + 1}: ${changed} emails sent`);
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < DRIP_PAGE_SIZE) {
      break;
    }
  }
}

export const enforceReengagementDrip = onSchedule(
  {
    schedule: "0 6 * * *",
    timeoutSeconds: 540,
    secrets: ["RESEND_API_KEY"],
  },
  async () => {
    console.log("Running re-engagement drip");
    await enforceReengagementDripInternal(db, Date.now());
  }
);
