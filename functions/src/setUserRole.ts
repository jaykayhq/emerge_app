/**
 * setUserRole — sets the canonical `role` custom claim on the authenticated
 * user's Firebase Auth token, and mirrors the role (plus optional creator
 * onboarding progress) to Firestore so the router has a deterministic
 * source of truth even when the claim is stale.
 *
 * Why a Cloud Function (not the client):
 *  - Firebase Auth custom claims can only be set via the Admin SDK.
 *  - Without a server-side guard, a client could self-promote to any role.
 *
 * Inputs (data):
 *  - role: "user" | "creator"                          (required)
 *  - creatorOnboardingProgress?: 0 | 1 | 2 | 3         (optional, creator only)
 *  - creatorOnboardingCompletedAt?: string (ISO)       (optional, creator only)
 *
 * Auth rules:
 *  - Caller must be authenticated.
 *  - targetUid defaults to request.auth.uid; admins can pass a different
 *    targetUid to migrate existing accounts.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const VALID_ROLES = ["user", "creator"] as const;
type Role = (typeof VALID_ROLES)[number];

interface SetUserRoleRequest {
  role: Role;
  creatorOnboardingProgress?: number;
  creatorOnboardingCompletedAt?: string;
  targetUid?: string;
}

export const setUserRole = onCall<SetUserRoleRequest>(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const data = request.data;
  if (!data || typeof data !== "object") {
    throw new HttpsError("invalid-argument", "Request body is required.");
  }

  const role = data.role;
  if (!role || !VALID_ROLES.includes(role)) {
    throw new HttpsError(
      "invalid-argument",
      `role must be one of: ${VALID_ROLES.join(", ")}.`,
    );
  }

  const callerUid = request.auth.uid;
  const targetUid = (data.targetUid ?? callerUid).trim();

  // Authorization: a user can only modify their own role. Admin tokens
  // (request.auth.token.admin === true) may target another uid for
  // migration scripts.
  const isAdmin = request.auth.token?.admin === true;
  if (targetUid !== callerUid && !isAdmin) {
    throw new HttpsError(
      "permission-denied",
      "You can only set the role on your own account.",
    );
  }

  // Optional creator onboarding progress validation.
  const creatorProgress = data.creatorOnboardingProgress;
  if (
    creatorProgress !== undefined &&
    (typeof creatorProgress !== "number" ||
      !Number.isInteger(creatorProgress) ||
      creatorProgress < 0 ||
      creatorProgress > 3)
  ) {
    throw new HttpsError(
      "invalid-argument",
      "creatorOnboardingProgress must be an integer between 0 and 3.",
    );
  }

  const db = admin.firestore();

  // 1. Set the custom claim. Merge with any existing claims so we don't
  //    clobber unrelated ones (e.g. rateLimitUntil).
  const userRecord = await admin.auth().getUser(targetUid);
  const existingClaims = userRecord.customClaims ?? {};
  const newClaims = {
    ...existingClaims,
    role,
  };
  await admin.auth().setCustomUserClaims(targetUid, newClaims);

  // 2. Mirror `role` to users/{uid} (for normal users) and to
  //    creator_profiles/{uid} (for creators). Both fields are written with
  //    a server timestamp so any race between claim propagation and the
  //    mirror read resolves deterministically (the mirror is always at
  //    least as fresh as the call).
  const now = admin.firestore.FieldValue.serverTimestamp();
  const mirror: Record<string, unknown> = {
    role,
    roleUpdatedAt: now,
  };

  // The user may exist in either collection (or both during a migration).
  // We always write to users/{uid} so the router has a single fallback.
  await db
    .collection("users")
    .doc(targetUid)
    .set(mirror, { merge: true });

  if (role === "creator") {
    const creatorMirror: Record<string, unknown> = {
      ...mirror,
      role,
    };
    if (creatorProgress !== undefined) {
      creatorMirror.creatorOnboardingProgress = creatorProgress;
    }
    if (data.creatorOnboardingCompletedAt) {
      const parsed = new Date(data.creatorOnboardingCompletedAt);
      if (Number.isNaN(parsed.getTime())) {
        throw new HttpsError(
          "invalid-argument",
          "creatorOnboardingCompletedAt must be a valid ISO timestamp.",
        );
      }
      creatorMirror.creatorOnboardingCompletedAt =
        admin.firestore.Timestamp.fromDate(parsed);
    }
    await db
      .collection("creator_profiles")
      .doc(targetUid)
      .set(creatorMirror, { merge: true });
  }

  return {
    ok: true,
    uid: targetUid,
    role,
    creatorOnboardingProgress: creatorProgress ?? null,
  };
});
