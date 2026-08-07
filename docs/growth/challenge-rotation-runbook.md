# Emerge — Challenge Rotation Runbook (agent-executable)

**Purpose:** Update the server-published challenges in Firestore: rotate featured/active challenges, swap their images, and refresh their affiliate links — on demand or on a schedule. No app release needed.

**How to use:** Paste this file's path to an agent ("Execute `docs/growth/challenge-rotation-runbook.md`") or follow it yourself. It is self-contained: if the `scripts/rotation/` files do not exist yet, the agent creates them from Step 0, then runs the rotation.

**Related:** implementation plan `docs/superpowers/plans/2026-08-07-server-challenge-feed-and-cron-rotation.md` (optional reading; not required to run this runbook).

---

## 0. Ensure the rotation scripts exist

If `scripts/rotation/index.js` already exists, skip to Step 1. Otherwise create these four files exactly:

### 0a. `scripts/rotation/package.json`

```json
{
  "name": "emerge-challenge-rotation",
  "private": true,
  "version": "1.0.0",
  "description": "Rotate server-published challenges in Firestore",
  "main": "index.js",
  "scripts": {
    "test": "node --test scripts/rotation/test/"
  },
  "dependencies": {
    "firebase-admin": "^13.10.0"
  }
}
```

Then run: `npm --prefix scripts/rotation install` (creates node_modules + lockfile).

### 0b. `scripts/rotation/lib/rotation.js`

```js
"use strict";

/**
 * Pure rotation decisions. No Firestore/admin imports — all inputs and outputs
 * are plain objects so the logic is unit-testable.
 */

const VISIBLE_STATUSES = new Set(["featured", "active"]);
const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

/** Whole weeks since epoch — the deterministic image-rotation bucket. */
function weekIndex(now) {
  return Math.floor(now.getTime() / WEEK_MS);
}

/** Challenge ids whose sponsorship window has ended and are still visible. */
function computeExpiredIds(challenges, now) {
  return challenges
    .filter((c) => VISIBLE_STATUSES.has(c.status))
    .filter((c) => {
      if (!c.sponsorshipEndDate) return false;
      const end = new Date(c.sponsorshipEndDate);
      return !Number.isNaN(end.getTime()) && end <= now;
    })
    .map((c) => c.id);
}

function pickImage(template, imagePool, week, index) {
  // A template-resolved image (e.g. a local polli file uploaded to Storage by
  // the driver) takes priority; the pool only rotates when no image is set.
  if (template.imageUrl) return template.imageUrl;
  if (imagePool.length > 0) return imagePool[(week + index) % imagePool.length];
  return "";
}

/**
 * Computes the rotation plan.
 *
 * @param {object} opts
 * @param {Array<object>} opts.templates  curated template pool
 * @param {Array<object>} opts.existing   existing `challenges` docs (id + data)
 * @param {Array<object>} opts.partners   `affiliatePartners` docs (id + data)
 * @param {object} opts.config            { featuredLimit, imagePool, enabled }
 * @param {Date} opts.now
 * @returns {{upserts: Array<{challenge: object}>, updates: Array<{id: string, update: object}>, notifyIds: string[]}}
 */
function computeRotation({ templates, existing, partners, config, now }) {
  const upserts = [];
  const updates = [];
  const notifyIds = [];

  if (!config.enabled) return { upserts, updates, notifyIds };

  const expired = new Set(computeExpiredIds(existing, now));
  const existingById = new Map(existing.map((c) => [c.id, c]));
  const featuredLimit = Math.max(1, config.featuredLimit ?? 3);
  const imagePool = config.imagePool ?? [];
  const week = weekIndex(now);

  for (const id of expired) {
    updates.push({ id, update: { status: "completed" } });
  }

  templates.forEach((template, index) => {
    const partner = partners.find((p) => p.id === template.partnerId);
    const isFeatured = index < featuredLimit;
    const imageUrl = pickImage(template, imagePool, week, index);

    const doc = {
      title: template.title,
      description: template.description,
      imageUrl,
      category: template.category,
      archetypeId: template.archetypeId,
      totalDays: template.totalDays,
      currentDay: 0,
      daysLeft: template.totalDays,
      participants: existingById.get(template.id)?.participants ?? 0,
      status: isFeatured ? "featured" : "active",
      xpReward: template.xpReward,
      reward: template.reward,
      isFeatured,
      isTeamChallenge: false,
      buddyValidationRequired: false,
      sponsor: partner?.name ?? template.sponsor,
      sponsorLogoUrl: partner?.logoUrl ?? template.sponsorLogoUrl ?? "",
      isSponsored: Boolean(partner),
      affiliateUrl: partner?.affiliateUrl ?? template.affiliateUrl ?? "",
      rewardDescription: template.rewardDescription ?? template.reward,
      affiliatePartnerId: partner?.id ?? template.partnerId ?? null,
      affiliateNetwork: partner?.network ?? template.affiliateNetwork ?? "none",
      commissionRate: partner?.commissionRate ?? template.commissionRate ?? null,
      sponsorshipStartDate: now.toISOString(),
      sponsorshipEndDate: new Date(
        now.getTime() + template.totalDays * 24 * 60 * 60 * 1000
      ).toISOString(),
      steps: template.steps,
    };

    const existingDoc = existingById.get(template.id);
    if (
      existingDoc &&
      existingDoc.status === doc.status &&
      existingDoc.imageUrl === doc.imageUrl &&
      existingDoc.affiliateUrl === doc.affiliateUrl
    ) {
      // No visible change — skip the write entirely (billing/cost).
      return;
    }
    if (existingDoc) {
      doc.participants = existingDoc.participants ?? doc.participants;
      updates.push({ id: template.id, update: doc });
      if (isFeatured && existingDoc.status !== "featured") notifyIds.push(template.id);
    } else {
      upserts.push({ challenge: { id: template.id, ...doc } });
      if (isFeatured) notifyIds.push(template.id);
    }
  });

  return { upserts, updates, notifyIds };
}

module.exports = { computeRotation, computeExpiredIds, weekIndex };
```

### 0c. `scripts/rotation/templates.js`

The curated pool. `imageFile` names a file in `scripts/rotation/images/` (Step 1). `partnerId` must match a doc id in the `affiliatePartners` Firestore collection. **`affiliateUrl`/partner `affiliateUrl` must be YOUR tagged affiliate links — a bare storefront URL pays nothing.**

```js
"use strict";

/**
 * Curated server-published challenge templates.
 *
 * The rotation driver upserts these into the `challenges` collection. To change
 * a challenge's title/reward/links, edit this file — no app release required.
 *
 * `imageFile` names a file in `scripts/rotation/images/` (generated with polli,
 * see Step 1). The driver uploads it to Firebase Storage each run and points
 * imageUrl at the public URL. If the file is absent, `imageUrl` is the fallback.
 *
 * `partnerId` must match a doc id in `affiliatePartners`; the driver copies the
 * partner's name/logo/network/commission/affiliateUrl over the template fields
 * when present. Prefer storing affiliateUrl on the partner doc so links update
 * without editing code.
 */
const TEMPLATES = [
  {
    id: "srv_morning_protocol",
    title: "The Morning Protocol",
    description:
      "14 days of a non-negotiable morning routine: hydrate, move, and set one intention before screens.",
    category: "productivity",
    archetypeId: "athlete",
    totalDays: 14,
    xpReward: 700,
    reward: "700 XP & Morning Warrior Emblem",
    rewardDescription: "15% off your first order",
    imageFile: "morning_protocol.jpg",
    imageUrl:
      "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800",
    partnerId: "headspace",
    affiliateNetwork: "direct",
    affiliateUrl: "https://example.com/reward/headspace", // REPLACE with your tagged link
    steps: [
      { day: 1, title: "Hydrate First", description: "500ml water before coffee.", isCompleted: false },
      { day: 7, title: "One Week In", description: "Your routine is taking shape.", isCompleted: false },
      { day: 14, title: "Protocol Locked", description: "Own your mornings.", isCompleted: false },
    ],
  },
  {
    id: "srv_read_20",
    title: "Read 20",
    description:
      "20 minutes of reading a day for 21 days. Become the reader you keep saying you will.",
    category: "learning",
    archetypeId: "scholar",
    totalDays: 21,
    xpReward: 900,
    reward: "900 XP & Reader's Quill",
    rewardDescription: "30 days free on us",
    imageFile: "read_20.jpg",
    imageUrl:
      "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800",
    partnerId: "audible",
    affiliateNetwork: "direct",
    affiliateUrl: "https://example.com/reward/audible", // REPLACE with your tagged link
    steps: [
      { day: 1, title: "Start Small", description: "20 minutes, one book.", isCompleted: false },
      { day: 10, title: "Halfway", description: "You are a reader now.", isCompleted: false },
      { day: 21, title: "Reader", description: "21 days of pages.", isCompleted: false },
    ],
  },
  {
    id: "srv_30_day_move",
    title: "30 Days of Movement",
    description:
      "Move your body every single day for 30 days. Walk, run, stretch — just move.",
    category: "fitness",
    archetypeId: "athlete",
    totalDays: 30,
    xpReward: 1200,
    reward: "1200 XP & Golden Running Shoes",
    rewardDescription: "20% off your next pair",
    imageFile: "movement_30.jpg",
    imageUrl:
      "https://images.unsplash.com/photo-1552664730-d307ca884978?w=800",
    partnerId: "nike",
    affiliateNetwork: "direct",
    affiliateUrl: "https://example.com/reward/nike", // REPLACE with your tagged link
    steps: [
      { day: 1, title: "Show Up", description: "10 minutes counts.", isCompleted: false },
      { day: 15, title: "Halfway", description: "Fifteen in a row.", isCompleted: false },
      { day: 30, title: "Movement Day 30", description: "You moved for a month.", isCompleted: false },
    ],
  },
];

module.exports = { TEMPLATES };
```

### 0d. `scripts/rotation/index.js`

```js
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
```

### 0e. One-time storage rules (only needed if using local images)

The app renders challenge images from public URLs. If `storage.rules` does not already allow public reads for `challenges/`, replace it with:

```
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    match /challenges/{allPaths=**} {
      allow read: if true;
      allow write: if false;
    }
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

Deploy once: `firebase deploy --only storage` (the driver's Admin SDK bypasses rules; its service account needs `roles/storage.objectAdmin`).

---

## 1. Update the images (polli, in this workspace)

Generate a new image for any challenge and drop it into `scripts/rotation/images/` matching the template's `imageFile` name:

```bash
mkdir -p scripts/rotation/images
polli gen image "the morning protocol challenge, cosmic productivity aesthetic, deep space background, neon green accents, glassmorphism" --output scripts/rotation/images/morning_protocol.jpg
polli gen image "a scholar reading a glowing book, cosmic library, deep purple nebula" --output scripts/rotation/images/read_20.jpg
polli gen image "athlete running through a cosmic city at sunrise, energy, neon green trail" --output scripts/rotation/images/movement_30.jpg
```

- File must be `.jpg` or `.png` (content type is inferred from the extension).
- Missing files fall back to the template's `imageUrl` — the run still succeeds.
- Commit the images so they persist in the repo.

## 2. Update the affiliate links (this is how you get paid)

Put **your real tagged links** in the `affiliatePartners/{id}` Firestore docs under `affiliateUrl` — e.g. `amazon.com/dp/ASIN?tag=yourname-20`, your CJ/ShareASale tracking link, your Jumia publisher link, or a direct brand deal URL. The rotation copies them onto every challenge for that partner each run. Never use a bare storefront URL: without your tag, no purchase is attributed and you earn nothing.

(Alternatively, edit `affiliateUrl` directly in `scripts/rotation/templates.js`, but the partner-doc approach updates without code changes.)

**Payout reality:** networks pay commission on purchases attributed to your tag (Amazon/Jumia ~24h attribution, Impact/CJ/ShareASale ~30 days) on their schedule once you cross their minimum (Amazon $10, CJ/ShareASale ~$50). `direct` = you invoice brands yourself (Paystack for NGN). At current scale expect ≈$0 — the mechanic is the C-track pitch asset.

## 3. Configure rotation (optional)

Set the `config/challengeRotation` doc in Firestore to control behavior without code edits:

```json
{
  "enabled": true,
  "featuredLimit": 3,
  "imagePool": ["https://.../img1.jpg", "https://.../img2.jpg"]
}
```

`imagePool` is used only for templates with no local image. `enabled: false` makes the run a no-op.

## 4. Run the rotation

The script needs a Firebase Admin credential. Use a **non-committed** service account JSON (see security note) and run:

```bash
npm --prefix scripts/rotation install
GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json node scripts/rotation/index.js
```

Expected output: `Rotation done: N upserts, N updates, N notified`.

## 5. Verify

- Open Firebase Console → Firestore → `challenges`: the template docs should have fresh `status`, `imageUrl`, `affiliateUrl`, `sponsor`, `sponsorshipEndDate`.
- Open Storage → `challenges/images/<id>/<week>.jpg`: uploaded images present and publicly readable.
- In the app (after Part A ships), the feed shows the rotated challenges.

## 6. Commit changes

```bash
git add scripts/rotation/ storage.rules docs/growth/challenge-rotation-runbook.md
git commit -m "chore(rotation): refresh challenge content"
```

---

## Troubleshooting

- **403 on image upload:** the service account lacks Storage permission → grant `roles/storage.objectAdmin` in Google Cloud Console IAM.
- **`challenges` never changes:** check `config/challengeRotation.enabled` is `true` and that templates' fields actually differ from the existing docs (the script skips no-op writes).
- **Image not updating:** confirm the polli output filename matches the template's `imageFile` exactly.

## Security note

Never commit service-account JSONs. If `scripts/service-account-key.json` is tracked in git, remove it (`git rm --cached`) and rotate that key in Google Cloud — it is a live admin credential.
