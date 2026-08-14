import * as admin from "firebase-admin";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

/**
 * Maintains `tribes/{tribeId}.members` and `.memberCount` from membership
 * subcollection docs (`users/{userId}/tribes/{tribeId}`).
 *
 * Why a server trigger instead of client writes:
 *  - The old client path wrote members/memberCount directly, which the
 *    security rules legitimately deny for seeded official clubs (they had
 *    no `members` array), for locally-seeded clubs not yet on Firestore
 *    (create-vs-update), and on dead-letter replays (double-apply) — the
 *    observed 102/103/129/145 dead-letter symptom.
 *  - Counts are DERIVED: `memberCount = members.length`, so replays are
 *    idempotent (array membership is the single source of truth, matching
 *    the daily recalcTribes semantics).
 *  - Switching tribes = leave(old) + join(new): each membership doc
 *    triggers the decrement/increment on the correct tribe, while
 *    contributor docs (XP history) intentionally survive a leave.
 */
export async function maintainTribeMembershipInternal(
  db: admin.firestore.Firestore,
  params: { userId: string; tribeId: string },
  beforeData: Record<string, unknown> | undefined,
  afterData: Record<string, unknown> | undefined,
): Promise<void> {
  if (!beforeData && !afterData) return;

  const isJoin = afterData !== undefined && beforeData === undefined;
  const isLeave = beforeData !== undefined && afterData === undefined;
  // Membership doc updates (e.g. membershipType) never change the count.
  if (!isJoin && !isLeave) return;

  const { userId, tribeId } = params;
  const tribeRef = db.collection("tribes").doc(tribeId);

  await db.runTransaction(async (t) => {
    const tribeSnap = await t.get(tribeRef);
    if (!tribeSnap.exists) {
      // Locally-seeded club not yet on Firestore (or creator tribe mid
      // creation). The daily recalc backfills official clubs; creator
      // tribes are created server-side — nothing to maintain here.
      console.warn(
        `maintainTribeMembership: tribe ${tribeId} missing; skipping ${isJoin ? "join" : "leave"}`,
      );
      return;
    }

    const data = tribeSnap.data() ?? {};
    const members: string[] = Array.isArray(data.members) ? data.members : [];
    const next = isLeave
      ? members.filter((m) => m !== userId)
      : members.includes(userId)
        ? members
        : [...members, userId];

    // Idempotency: a replayed event that changes nothing performs no write,
    // so memberCount can never drift from the array on retries.
    if (next.length === members.length) return;

    t.update(tribeRef, {
      members: next,
      memberCount: next.length,
    });
  });
}

export const maintainTribeMembership = onDocumentWritten(
  "users/{userId}/tribes/{tribeId}",
  async (event) => {
    await maintainTribeMembershipInternal(
      admin.firestore(),
      event.params as { userId: string; tribeId: string },
      event.data?.before?.data(),
      event.data?.after?.data(),
    );
  },
);
