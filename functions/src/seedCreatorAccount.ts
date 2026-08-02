/**
 * seedCreatorAccount — one-off bootstrap for the default creator account (SP-E
 * D2, option a). Guarded by ADMIN_SECRET; credentials live in function
 * secrets (CREATOR_EMAIL / CREATOR_PASSWORD) and are delivered out-of-band.
 *
 * Creates (or repairs) the creator auth user, sets the `role: creator` claim,
 * writes a verified creator_profiles doc with onboarding marked complete (so
 * the dashboard is reachable immediately), and issues one ready invite code.
 *
 * Exported-but-commented in index.ts by default (seedReviewerAccount
 * precedent); enable explicitly when bootstrapping.
 */
import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

function getRequiredEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Required environment variable ${name} is not set.`);
  return value;
}

export async function seedCreatorAccountHandler(
  req: { headers: Record<string, string | string[] | undefined> },
  res: { status(code: number): { json(body: unknown): void } }
): Promise<void> {
  const rawHeader = req.headers.authorization;
  const header = Array.isArray(rawHeader) ? rawHeader[0] : rawHeader;
  const adminSecret = header?.replace("Bearer ", "");
  if (adminSecret !== process.env.ADMIN_SECRET) {
    res.status(403).json({ error: "Unauthorized" });
    return;
  }
  try {
    const email = getRequiredEnvVar("CREATOR_EMAIL");
    const password = getRequiredEnvVar("CREATOR_PASSWORD");
    const displayName = process.env.CREATOR_DISPLAY_NAME || "Emerge Founder";

    const auth = admin.auth();
    const db = admin.firestore();

    let uid: string;
    try {
      const existing = await auth.getUserByEmail(email);
      uid = existing.uid;
      await auth.updateUser(uid, { password, displayName, emailVerified: true });
    } catch (err: unknown) {
      if ((err as { code?: string }).code === "auth/user-not-found") {
        const newUser = await auth.createUser({
          email, password, displayName, emailVerified: true,
        });
        uid = newUser.uid;
      } else {
        throw err;
      }
    }

    await auth.setCustomUserClaims(uid, { role: "creator" });

    await db.collection("creator_profiles").doc(uid).set({
      userId: uid,
      ownerId: uid,
      role: "creator",
      displayName,
      isVerifiedCreator: true,
      bio: "",
      specialityTags: [],
      blueprintCount: 0,
      creatorOnboardingProgress: 3,          // onboarding complete → dashboard reachable
      creatorOnboardingCompletedAt: admin.firestore.Timestamp.now(),
      archetype: "creator",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // One ready invite code so the default creator can immediately onboard others.
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let code = "";
    for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
    await db.collection("creator_invite_codes").doc(code).set({
      creatorUid: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      redeemedBy: null,
    });

    res.status(200).json({ ok: true, uid, inviteCode: code });
  } catch (error) {
    console.error("seedCreatorAccount failed:", error);
    res.status(500).json({ error: "Seeding failed" });
  }
}

/** HTTP trigger. Export is commented out in index.ts by default (seedReviewerAccount precedent). */
export const seedCreatorAccount = onRequest(
  { secrets: ["CREATOR_EMAIL", "CREATOR_PASSWORD"] },
  seedCreatorAccountHandler
);
