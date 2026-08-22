/**
 * Notification-push worker entry.
 *
 * Bridges `users/{uid}/notifications/{id}` docs with `pushSent == false`
 * to FCM pushes. Respects UserSettings (master/community/DND) via the pure
 * `shouldPush` gate so disabled users are never pushed. Marks each doc
 * `pushSent: true` after a successful send (or a deliberate suppression)
 * so the job is idempotent and each notification is pushed at most once.
 *
 * Intended to run as a scheduled GitHub Action every ~5 minutes (see
 * `.github/workflows/notification-push.yml`). It is also the backstop for
 * any FCM delivery that the mobile app cannot schedule itself while
 * backgrounded/killed.
 *
 * Run locally:
 *   FIREBASE_SERVICE_ACCOUNT=path/to/service-account.json node index.js --dry-run
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json node index.js
 * In GitHub Actions the workflow passes FIREBASE_SERVICE_ACCOUNT_JSON inline.
 */
import { cert, initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { readFileSync } from 'node:fs';
import { shouldPush, buildFcmMessage } from './push.js';

const PROJECT_ID = 'tradeflash-l2966';

function initDb() {
  const inline = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const path = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (inline) {
    initializeApp({ projectId: PROJECT_ID, credential: cert(JSON.parse(inline)) });
  } else if (path) {
    initializeApp({ projectId: PROJECT_ID, credential: cert(JSON.parse(readFileSync(path, 'utf8'))) });
  } else {
    initializeApp({ projectId: PROJECT_ID });
  }
  return getFirestore();
}

async function run({ dryRun = false } = {}) {
  const db = initDb();
  const messaging = getMessaging();
  const snap = await db.collectionGroup('notifications').where('pushSent', '==', false).limit(500).get();
  console.log(`Found ${snap.size} notifications with pushSent==false`);
  let sent = 0, suppressed = 0, skipped = 0, failed = 0;
  for (const doc of snap.docs) {
    const notifData = doc.data();
    const userId = doc.ref.parent.parent?.id;
    if (!userId) { skipped++; continue; }
    const userSnap = await db.collection('users').doc(userId).get();
    const userData = userSnap.data() ?? null;
    const fcmToken = userData?.fcmToken ?? null;

    if (!shouldPush(notifData, userData, new Date())) {
      if (!dryRun) await doc.ref.set({ pushSent: true, pushSuppressed: true, pushSuppressedAt: FieldValue.serverTimestamp() }, { merge: true });
      suppressed++;
      continue;
    }
    if (!fcmToken) {
      if (!dryRun) await doc.ref.set({ pushSent: true, pushSkippedNoToken: true }, { merge: true });
      skipped++;
      continue;
    }
    const message = buildFcmMessage(notifData, fcmToken);
    if (dryRun) {
      console.log(`[dry-run] would push ${doc.id} → ${userId}: ${notifData.title}`);
      continue;
    }
    try {
      await messaging.send(message);
      await doc.ref.set({ pushSent: true, pushSentAt: FieldValue.serverTimestamp() }, { merge: true });
      sent++;
    } catch (e) {
      console.error(`Failed to push ${doc.id} for ${userId}:`, e.message ?? e);
      // Mark as sent with error to avoid infinite retry loop; a future run
      // could clear pushSent on demand if retry is desired.
      await doc.ref.set({ pushSent: true, pushError: String(e.message ?? e), pushErrorAt: FieldValue.serverTimestamp() }, { merge: true });
      failed++;
    }
  }
  console.log(`Done — sent=${sent} suppressed=${suppressed} skipped=${skipped} failed=${failed}`);
  return { sent, suppressed, skipped, failed, total: snap.size };
}

const dryRun = process.argv.includes('--dry-run');
run({ dryRun }).catch((e) => { console.error(e); process.exit(1); });
