"use strict";

/**
 * Rotation driver: reads config + partners + existing challenges from
 * Firestore, uploads local images to Storage, computes the plan with the pure
 * logic in lib/rotation.js, applies it with batched writes, and pushes an FCM
 * topic notification for newly featured challenges.
 *
 * Run:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json \
 *     node scripts/rotation/index.js
 */
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");
const { computeRotation, weekIndex } = require("./lib/rotation");
const { TEMPLATES } = require("./templates");

/**
 * Uploads a template's local image (from scripts/rotation/images/) to the
 * Firebase Storage bucket and returns the public URL, or null when the file is
 * missing (caller falls back to template.imageUrl / the image pool).
 */
async function resolveTemplateImage(template, week) {
  if (!template.imageFile) return null;
  const local = path.join(__dirname, "images", template.imageFile);
  if (!fs.existsSync(local)) {
    console.log(`Image missing for ${template.id}: ${local} — using fallback`);
    return null;
  }
  const bucket = admin.storage().bucket();
  const ext = path.extname(local);
  const dest = bucket.file(`challenges/images/${template.id}/${week}${ext}`);
  await dest.save(fs.readFileSync(local), {
    contentType: ext === ".png" ? "image/png" : "image/jpeg",
    metadata: { cacheControl: "public, max-age=31536000, immutable" },
  });
  return dest.publicUrl();
}

async function main() {
  if (admin.apps.length === 0) {
    admin.initializeApp();
  }
  const db = admin.firestore();
  const now = new Date();
  const week = weekIndex(now);

  const configDoc = await db
    .collection("config")
    .doc("challengeRotation")
    .get()
    .catch(() => null);
  const config = configDoc?.exists
    ? configDoc.data()
    : { enabled: true, featuredLimit: 3, imagePool: [] };

  const partnersSnap = await db
    .collection("affiliatePartners")
    .get()
    .catch(() => null);
  const partners =
    partnersSnap?.docs.map((d) => ({ id: d.id, ...d.data() })) ?? [];

  // Resolve local polli images first so they take priority in the rotation.
  const templates = [];
  for (const t of TEMPLATES) {
    const uploaded = await resolveTemplateImage(t, week);
    templates.push(uploaded ? { ...t, imageUrl: uploaded } : t);
  }

  const existingSnap = await db.collection("challenges").get();
  const existing = existingSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

  const plan = computeRotation({
    templates,
    existing,
    partners,
    config,
    now,
  });

  const toTimestamp = (iso) =>
    admin.firestore.Timestamp.fromDate(new Date(iso));

  for (const { challenge } of plan.upserts) {
    const { id, sponsorshipStartDate, sponsorshipEndDate, ...rest } = challenge;
    await db.collection("challenges").doc(id).set({
      ...rest,
      sponsorshipStartDate: toTimestamp(sponsorshipStartDate),
      sponsorshipEndDate: toTimestamp(sponsorshipEndDate),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  const batch = db.batch();
  for (const { id, update } of plan.updates) {
    const { sponsorshipStartDate, sponsorshipEndDate, ...rest } = update;
    batch.update(db.collection("challenges").doc(id), {
      ...rest,
      ...(sponsorshipStartDate
        ? { sponsorshipStartDate: toTimestamp(sponsorshipStartDate) }
        : {}),
      ...(sponsorshipEndDate
        ? { sponsorshipEndDate: toTimestamp(sponsorshipEndDate) }
        : {}),
    });
  }
  if (plan.updates.length > 0) await batch.commit();

  for (const id of plan.notifyIds) {
    const t = TEMPLATES.find((x) => x.id === id);
    if (t) {
      await admin.messaging().send({
        notification: { title: "New featured challenge", body: t.title },
        data: { challengeId: id, type: "challenge_rotation" },
        topic: "all_users",
      });
    }
  }

  await db.collection("analytics").add({
    event: "challenge_rotation_completed",
    upserts: plan.upserts.length,
    updates: plan.updates.length,
    notified: plan.notifyIds.length,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(
    `Rotation done: ${plan.upserts.length} upserts, ${plan.updates.length} updates, ${plan.notifyIds.length} notified`
  );
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
