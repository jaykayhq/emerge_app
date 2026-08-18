import { FieldValue } from "firebase-admin/firestore";

/**
 * Password reset email task — sends the branded reset email instead of
 * Firebase Auth's default template.
 *
 * For every request doc in `email_requests` of type `password_reset` that
 * has not been emailed yet (sentAt absent/null), was requested within the
 * last 24h, and whose address was not emailed within the cooldown:
 *   1. Generate the reset link via the Admin SDK with handleCodeInApp:true
 *      and a custom URL (RESET_URL) — the link points straight back at the
 *      app's /reset-password route with the oobCode, so the user lands in
 *      the branded screen (no Firebase hosted page).
 *   2. Send a branded SMTP email with the link.
 *   3. Mark sentAt (idempotency marker).
 *
 * Stale requests (older than 24h, never emailed) are garbage-collected at the
 * end of the run so they don't crowd out fresh requests in the scan window.
 *
 * DELIVERY SEMANTICS: at-least-once. A crash between send() and the sentAt
 * commit can re-deliver on the next sweep, and overlapping runs can race on
 * the same doc. Recipients may occasionally see a duplicate reset email; the
 * per-email cooldown (15min) bounds the blast radius, and once a doc carries
 * sentAt it is never scanned again.
 */
export const RESET_COOLDOWN_MS = 15 * 60 * 1000; // 15min between sends per email
export const RESET_MAX_AGE_MS = 24 * 60 * 60 * 1000; // expired oob codes after 24h
export const RESET_PAGE_SIZE = 100;
export const RESET_MAX_PAGES = 100;
// Hard ceiling per sweep. The queue is anonymously writable (forgot-password
// is a signed-out flow), so this bounds a burst of forged requests: the run
// stops emailing once the cap is hit and the remainder is deferred to the
// next cooldown-bound sweep.
export const RESET_MAX_EMAILS_PER_RUN = 500;
// Stale (aged-out, never-emailed) docs are GC'd each run, capped so cleanup
// can never dominate a sweep over the 10k-doc scan window.
export const RESET_GC_BATCH = 500;

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
  const staleAfter = now - RESET_MAX_AGE_MS;
  let lastDoc;
  let sent = 0;
  // Per-email cooldown: checked against the WHOLE queue (one query per
  // unique email per RUN), so a recently sent sibling request suppresses a
  // newly created one even when the sibling was marked by a previous run.
  const checkedEmail = new Set();
  // Every email this run actually emailed (dry-run counts too) — a single
  // page can hold N duplicate docs for one address, and the batch markers
  // for the in-page duplicates are not yet visible to the cooldown query, so
  // this set is what prevents N emails going to the same address in one run.
  const sentThisRun = new Set();

  for (let page = 0; page < RESET_MAX_PAGES; page++) {
    let query = db
      .collection("email_requests")
      .where("type", "==", "password_reset")
      .where("sentAt", "==", null) // only un-emailed records — the sweep
      // stops rescanning dead (already-sent) ones
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
    let capped = false;
    for (const doc of snap.docs) {
      if (sent >= RESET_MAX_EMAILS_PER_RUN) {
        console.warn(
          `[reset] hit per-run cap of ${RESET_MAX_EMAILS_PER_RUN}; ` +
            "deferring the rest to the next sweep");
        capped = true;
        break;
      }
      const data = doc.data();
      if (data.type !== "password_reset") {
        continue;
      }
      const email = typeof data.email === "string" ? data.email : "";
      if (!email || !EMAIL_RE.test(email)) {
        console.warn(`[reset] skipping ${doc.id}: no valid email`);
        continue;
      }
      // Expired request: the oobCode it would carry is long gone, and stale
      // docs are just noise after worker downtime (GC'd at run end).
      const requestedMillis = toMillis(data.requestedAt);
      if (requestedMillis !== 0 && requestedMillis < staleAfter) {
        console.warn(`[reset] skipping ${doc.id}: request older than 24h`);
        continue;
      }
      if (data.sentAt != null) {
        continue; // already emailed — idempotent
      }
      if (sentThisRun.has(email)) {
        console.log(`[reset] skipping ${doc.id}: ${email} already emailed this run`);
        continue;
      }
      if (!checkedEmail.has(email)) {
        checkedEmail.add(email);
        const recentSend = await db
          .collection("email_requests")
          .where("email", "==", email)
          .where("sentAt", ">=", cooldownCutoff)
          .limit(1)
          .get();
        if (!recentSend.empty) {
          console.log(`[reset] skipping ${doc.id}: ${email} sent within cooldown`);
          continue;
        }
      }
      if (dryRun) {
        console.log(`[reset][dry-run] would email ${email} (${doc.id})`);
        sentThisRun.add(email);
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
          // Per-email cooldown anchor so a repeat request within 15min is
          // skipped even if it lands as a new doc.
          lastSentAt: FieldValue.serverTimestamp(),
        };
        batch.set(db.collection("email_requests").doc(doc.id), marker, { merge: true });
        changed++;
        sent++;
        sentThisRun.add(email);
      } catch (err) {
        // USER_NOT_FOUND: the address has no Auth record (random/typo'd
        // address). Fail quietly per-doc — never abort the run.
        if (err?.code === "auth/user-not-found") {
          console.warn(`[reset] skipping ${doc.id}: no Auth user for ${email}`);
          continue;
        }
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
    if (capped) {
      break; // batch for this page already committed above — stop here
    }
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < RESET_PAGE_SIZE) {
      break;
    }
  }

  await gcStaleRequests(db, dryRun, staleAfter);
  console.log(`[reset] done: ${sent} total`);
  return sent;
}

/**
 * Deletes stale (older than RESET_MAX_AGE_MS, never-emailed) request docs so
 * they can't crowd out fresh requests in the scan window. Dry-run only
 * reports; never mutates. Capped per run so cleanup can't dominate a sweep.
 */
async function gcStaleRequests(db, dryRun, staleAfter) {
  const cutoff = new Date(staleAfter);
  if (dryRun) {
    const snap = await db
      .collection("email_requests")
      .where("sentAt", "==", null)
      .where("requestedAt", "<", cutoff)
      .limit(RESET_GC_BATCH)
      .get();
    for (const d of snap.docs) {
      console.log(`[reset][dry-run] would delete stale request ${d.id}`);
    }
    if (snap.docs.length > 0) {
      console.log(`[reset] gc: ${snap.docs.length} stale requests (dry-run)`);
    }
    return snap.docs.length;
  }

  let deleted = 0;
  while (deleted < RESET_GC_BATCH) {
    const snap = await db
      .collection("email_requests")
      .where("sentAt", "==", null)
      .where("requestedAt", "<", cutoff)
      .limit(Math.min(RESET_PAGE_SIZE, RESET_GC_BATCH - deleted))
      .get();
    if (snap.empty) {
      break;
    }
    const batch = db.batch();
    for (const d of snap.docs) {
      batch.delete(d.ref);
    }
    await batch.commit();
    deleted += snap.docs.length;
    if (snap.docs.length < RESET_PAGE_SIZE) {
      break;
    }
  }
  if (deleted > 0) {
    console.log(`[reset] gc: ${deleted} stale requests removed`);
  }
  return deleted;
}

function toMillis(value) {
  if (value instanceof Date) return value.getTime();
  const ts = value;
  return ts?.toMillis?.() ?? 0;
}
