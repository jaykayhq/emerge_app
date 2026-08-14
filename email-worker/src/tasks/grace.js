import admin from "firebase-admin";

/**
 * Verification grace-period lock — ported verbatim from
 * functions/src/email_verification.ts (enforceEmailGracePeriodInternal).
 *
 * Email delivery itself is Firebase Auth's native link flow (the client's
 * sendEmailVerification() mails the click-to-verify link); this task only
 * enforces the daily lock: accounts whose email is still unverified 7 days
 * after emailVerificationSentAt get users/{uid}.emailLockedAt (the router
 * then blocks non-auth surfaces), and verified accounts get stale locks
 * cleared. The authoritative check is Firebase Auth's emailVerified flag.
 */
export const GRACE_PERIOD_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
export const GRACE_PAGE_SIZE = 400;
export const GRACE_MAX_PAGES = 100;
export const AUTH_CHUNK_SIZE = 20;

async function getVerifiedMap(candidates, getUser) {
  const result = new Map();
  for (let i = 0; i < candidates.length; i += AUTH_CHUNK_SIZE) {
    const chunk = candidates.slice(i, i + AUTH_CHUNK_SIZE);
    const records = await Promise.all(
      chunk.map((c) =>
        getUser(c.id).then(
          (u) => ({ id: c.id, verified: u.emailVerified }),
          () => null, // deleted/missing user — skip
        ),
      ),
    );
    records.forEach((r) => {
      if (r != null) {
        result.set(r.id, r.verified);
      }
    });
  }
  return result;
}

export async function runGraceTask(db, auth, { dryRun }) {
  const getUser = (uid) => auth.getUser(uid);
  const cutoff = new Date(Date.now() - GRACE_PERIOD_MS);
  let lastDoc;
  let updated = 0;

  for (let page = 0; page < GRACE_MAX_PAGES; page++) {
    let query = db
      .collection("users")
      .where("emailVerificationSentAt", "<=", cutoff)
      .limit(GRACE_PAGE_SIZE);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snap = await query.get();
    if (snap.empty) {
      break;
    }

    const candidates = snap.docs.map((doc) => ({
      id: doc.id,
      emailLockedAt: doc.data().emailLockedAt,
    }));
    const verifiedMap = await getVerifiedMap(candidates, getUser);

    const batch = db.batch();
    let changed = 0;
    for (const doc of snap.docs) {
      const id = doc.id;
      const verified = verifiedMap.get(id);
      if (verified == null) {
        continue; // auth record missing — leave as-is
      }
      const locked =
        candidates.find((c) => c.id === id)?.emailLockedAt != null;
      if (verified) {
        if (locked) {
          if (dryRun) {
            console.log(`[grace][dry-run] would clear lock for ${id}`);
            changed++;
            continue;
          }
          batch.set(
            db.collection("users").doc(id),
            { emailLockedAt: admin.firestore.FieldValue.delete() },
            { merge: true },
          );
          changed++;
        }
      } else if (!locked) {
        if (dryRun) {
          console.log(`[grace][dry-run] would lock ${id}`);
          changed++;
          continue;
        }
        batch.set(
          db.collection("users").doc(id),
          { emailLockedAt: admin.firestore.FieldValue.serverTimestamp() },
          { merge: true },
        );
        changed++;
      }
    }
    if (changed > 0 && !dryRun) {
      await batch.commit();
    }
    console.log(`[grace] page ${page + 1}: ${changed} updated`);
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < GRACE_PAGE_SIZE) {
      break;
    }
  }
  console.log(`[grace] done: ${updated} total`);
  return updated;
}
