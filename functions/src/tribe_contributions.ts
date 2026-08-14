import * as admin from "firebase-admin";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

/**
 * Maintains `tribes/{tribeId}.totalXp` in near-real-time from contributor
 * records (`tribes/{tribeId}/contributors/{memberId}.totalXpContributed`).
 *
 * The client writes contributor records with server-side increments; the
 * trigger applies the delta between the before/after snapshots to the
 * tribe doc inside a transaction. The daily recalcTribes pass reconciles
 * from the same contributor records, so the two mechanisms can never
 * disagree for long. (Recalc writes are idempotent; trigger deltas are
 * applied atomically. At-least-once duplicate deliveries are healed by the
 * next recalc — acceptable at current scale, documented in
 * docs/backend-engineering-research-2026-08-13.md.)
 */
export async function maintainTribeXpInternal(
  db: admin.firestore.Firestore,
  params: { tribeId: string; memberId: string },
  beforeData: Record<string, unknown> | undefined,
  afterData: Record<string, unknown> | undefined,
): Promise<void> {
  if (!beforeData && !afterData) return;

  const beforeXp = typeof beforeData?.totalXpContributed === "number" ? beforeData.totalXpContributed : 0;
  const afterXp = typeof afterData?.totalXpContributed === "number" ? afterData.totalXpContributed : 0;
  const delta = afterXp - beforeXp;
  if (delta === 0) return;

  const tribeRef = db.collection("tribes").doc(params.tribeId);

  await db.runTransaction(async (t) => {
    const tribeSnap = await t.get(tribeRef);
    if (!tribeSnap.exists) return;
    const currentXp =
      typeof tribeSnap.data()?.totalXp === "number" ? tribeSnap.data()?.totalXp : 0;
    t.update(tribeRef, {
      totalXp: Math.max(0, currentXp + delta),
    });
  });
}

export const maintainTribeXp = onDocumentWritten(
  "tribes/{tribeId}/contributors/{memberId}",
  async (event) => {
    await maintainTribeXpInternal(
      admin.firestore(),
      event.params as { tribeId: string; memberId: string },
      event.data?.before?.data(),
      event.data?.after?.data(),
    );
  },
);
