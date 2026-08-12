/**
 * seedCreatorAccount — one-off bootstrap for the default creator account (SP-E
 * D2, option a). Guarded by ADMIN_SECRET; credentials and the guard secret
 * live in function secrets (CREATOR_EMAIL / CREATOR_PASSWORD / ADMIN_SECRET)
 * and are delivered out-of-band.
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
import { generateCode } from "./creator_invites";

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
  // Fail closed: ADMIN_SECRET must be mounted (secrets list below). Without
  // this guard the old `!==` comparison passed when the header AND the env
  // var were both undefined, letting anyone bootstrap the creator account.
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

    await auth.setCustomUserClaims(uid, { role: "creator", admin: true });

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

    // One ready invite code so the default creator can immediately onboard
    // others. Reuses the invite-code generator (crypto-secure randomInt, no
    // ambiguous chars) instead of Math.random.
    const code = generateCode();
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
  {
    secrets: ["CREATOR_EMAIL", "CREATOR_PASSWORD", "ADMIN_SECRET"],
    // Public HTTP so the ADMIN_SECRET header guard is reachable; the
    // handler fails closed (403/500) without the correct secret.
    invoker: "public",
  },
  seedCreatorAccountHandler
);
