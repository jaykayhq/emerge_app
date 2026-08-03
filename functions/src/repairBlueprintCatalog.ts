/**
 * repairBlueprintCatalog — one-off production data repair (SP-B legacy
 * cleanup). Guarded by ADMIN_SECRET (same secret as seedCreatorAccount).
 *
 * Fixes two stale-data states that break the client seeding:
 *  1. The 25 system-seed blueprint docs (`morning_1` … `learning_5`) are
 *     owned by legacy creator uids (e.g. `alex_hormozi`) instead of
 *     `system`. The blueprints update rule only lets the client backfill
 *     system-owned docs, so every login hits
 *     `[cloud_firestore/permission-denied]` in BlueprintRepository:Seeding
 *     failed. Re-owning them to `system` unblocks the in-app v3 backfill.
 *  2. Non-seed blueprint docs are v1-era creator blueprints that the
 *     blueprint-creator removal left behind; they are filtered from the UI
 *     but pollute the collection. They are purged here.
 *
 * Idempotent: re-running after the state is fixed is a no-op.
 * Exported-but-commented in index.ts by default; enable explicitly when
 * running the repair, then disable again.
 */
import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const SEED_ID_PATTERN =
  /^(morning|productivity|fitness|mindfulness|learning)_[0-9]+$/;

export async function repairBlueprintCatalogHandler(
  req: { headers: Record<string, string | string[] | undefined> },
  res: { status(code: number): { json(body: unknown): void } }
): Promise<void> {
  if (!process.env.ADMIN_SECRET) {
    res.status(500).json({ error: "ADMIN_SECRET is not configured." });
    return;
  }
  const rawHeader = req.headers.authorization;
  const header = Array.isArray(rawHeader) ? rawHeader[0] : rawHeader;
  const adminSecret = header?.replace("Bearer ", "");
  if (adminSecret !== process.env.ADMIN_SECRET) {
    res.status(403).json({ error: "Unauthorized" });
    return;
  }
  try {
    const db = admin.firestore();
    const blueprints = db.collection("blueprints");
    const docRefs = await blueprints.listDocuments();

    const batch = db.batch();
    let repaired = 0;
    let purged = 0;
    for (const docRef of docRefs) {
      if (SEED_ID_PATTERN.test(docRef.id)) {
        const snap = await docRef.get();
        if (snap.data()?.creatorUserId !== "system") {
          batch.update(docRef, { creatorUserId: "system" });
          repaired++;
        }
      } else {
        batch.delete(docRef);
        purged++;
      }
    }
    await batch.commit();
    res.status(200).json({ ok: true, repaired, purged });
  } catch (err: unknown) {
    console.error("repairBlueprintCatalog failed:", err);
    res.status(500).json({ error: "Repair failed" });
  }
}

export const repairBlueprintCatalog = onRequest(
  {
    invoker: "public",
    secrets: ["ADMIN_SECRET"],
  },
  repairBlueprintCatalogHandler
);
