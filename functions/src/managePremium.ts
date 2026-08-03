/**
 * managePremium — pause or cancel a user's premium entitlement.
 *
 * Web premium is a one-time Paystack charge (no recurring billing to stop),
 * so "cancel" is a grant revocation: clears `users/{uid}.isPremium`, the
 * web-only `premium_since` tenure marker, and the `activeEntitlements`
 * custom claim (merge-safe — never clobbers other claims, mirroring
 * setUserRole.ts). "pause" defers revocation by writing a
 * 30-day `premiumEndsAt` window; the client's `computePremiumState` treats a
 * paused doc as premium until that date.
 *
 * Firestore rules already forbid client writes to `isPremium`, so this
 * callable is the only revocation path. Paystack refunds stay manual.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const VALID_ACTIONS = ["pause", "cancel"] as const;
type ManagePremiumAction = (typeof VALID_ACTIONS)[number];

interface ManagePremiumRequest {
  action: ManagePremiumAction;
}

const PAUSE_DURATION_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

export const managePremium = onCall<ManagePremiumRequest>(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const data = request.data;
  const action = data?.action;
  if (!action || !VALID_ACTIONS.includes(action)) {
    throw new HttpsError(
      "invalid-argument",
      `action must be one of: ${VALID_ACTIONS.join(", ")}.`
    );
  }

  const uid = request.auth.uid;
  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);
  const now = admin.firestore.FieldValue.serverTimestamp();

  if (action === "cancel") {
    await userRef.set(
      {
        isPremium: false,
        subscriptionStatus: "cancelled",
        cancelledAt: now,
        // premium_since is a web-only tenure marker (manage_premium_screen
        // reads it); clear it on cancel so the field never lies about tenure.
        premium_since: admin.firestore.FieldValue.delete(),
      },
      { merge: true }
    );

    // Merge-safe claims rewrite: drop only the premium entitlement.
    const userRecord = await admin.auth().getUser(uid);
    const existingClaims = userRecord.customClaims ?? {};
    const entitlements = Array.isArray(existingClaims.activeEntitlements)
      ? (existingClaims.activeEntitlements as string[]).filter(
          (e) => e !== "premium"
        )
      : [];
    await admin.auth().setCustomUserClaims(uid, {
      ...existingClaims,
      activeEntitlements: entitlements,
    });

    return { ok: true, action: "cancel", premium: false };
  }

  await userRef.set(
    {
      subscriptionStatus: "paused",
      premiumEndsAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + PAUSE_DURATION_MS)
      ),
    },
    { merge: true }
  );

  return { ok: true, action: "pause", premium: true };
});
