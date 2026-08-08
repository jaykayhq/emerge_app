/**
 * Email verification code system (SP sub-project 1). Server-authoritative,
 * mirroring creator_invites.ts: codes are hashed + salted at rest in a
 * functions-only collection, single-use, 10-minute TTL, rate-limited resends.
 * On success the Admin SDK sets Firebase Auth's native emailVerified flag
 * (the router's source of truth) and mirrors it to users/{uid}.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { randomInt } from "node:crypto";
import * as crypto from "node:crypto";
import { sendEmail } from "./email";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

export const EMAIL_CODE_LENGTH = 6;
export const EMAIL_CODE_TTL_MS = 10 * 60 * 1000; // 10 minutes
export const MAX_ATTEMPTS = 5;
export const RESEND_HOUR_LIMIT = 5;
export const RESEND_DAY_LIMIT = 20;
export const GRACE_PERIOD_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
export const HOUR_MS = 60 * 60 * 1000;
export const DAY_MS = 24 * 60 * 60 * 1000;

export function generateEmailCode(): string {
  let code = "";
  for (let i = 0; i < EMAIL_CODE_LENGTH; i++) {
    code += String(randomInt(0, 10));
  }
  return code;
}

export function hashCode(code: string, salt: string): string {
  return crypto.createHash("sha256").update(salt + code).digest("hex");
}

/** Test seam: deterministic hash so offline tests can reproduce it. */
export function hashCodeForTest(code: string, salt: string): string {
  return hashCode(code, salt);
}

export function makeSalt(): string {
  return crypto.randomBytes(16).toString("hex");
}

export function emailCodeExpiryMs(value: unknown): number {
  if (value instanceof Date) return value.getTime();
  const ts = value as { toMillis?: () => number } | undefined;
  return ts?.toMillis?.() ?? 0;
}

export const sendEmailVerificationCode = onCall(
  { secrets: ["RESEND_API_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }
    const uid = request.auth.uid;
    const userRecord = await admin.auth().getUser(uid);
    if (userRecord.emailVerified) {
      throw new HttpsError("already-exists", "Email is already verified.");
    }

    const ref = db.collection("email_verifications").doc(uid);
    const nowMs = Date.now();
    const existing = await ref.get();

    if (existing.exists) {
      const data = existing.data()!;
      const resendCount = (data.resendCount as number) ?? 0;
      const lastSent = emailCodeExpiryMs(
        (data.lastSentAt as { toMillis?: () => number } | Date | undefined)
      );
      if (resendCount >= RESEND_DAY_LIMIT) {
        throw new HttpsError(
          "resource-exhausted",
          "Daily resend limit reached."
        );
      }
      if (resendCount >= RESEND_HOUR_LIMIT && nowMs - lastSent < HOUR_MS) {
        throw new HttpsError(
          "resource-exhausted",
          "Too many codes sent recently. Try again later."
        );
      }
    }

    const code = generateEmailCode();
    const salt = makeSalt();
    await ref.set({
      codeHash: hashCode(code, salt),
      codeSalt: salt,
      expiresAt: new Date(nowMs + EMAIL_CODE_TTL_MS),
      attempts: 0,
      resendCount:
        (existing.exists ? (existing.data()?.resendCount as number) ?? 0 : 0) +
        1,
      lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    try {
      await sendEmail({
        to: userRecord.email!,
        subject: "Your Emerge verification code",
        html: `<p>Your Emerge verification code is:</p>
               <h2>${code}</h2>
               <p>It expires in 10 minutes. If you didn't request this,
               ignore this email.</p>`,
      });
    } catch (err) {
      await ref.delete();
      console.error(
        `[sendEmailVerificationCode] Resend failed for ${uid}:`,
        err
      );
      throw new HttpsError(
        "internal",
        "Failed to send the verification email. Please try again."
      );
    }

    return { ok: true, expiresInSeconds: EMAIL_CODE_TTL_MS / 1000 };
  }
);

export const verifyEmailCode = onCall(
  { secrets: ["RESEND_API_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }
    const uid = request.auth.uid;
    const data = request.data ?? {};
    const code = typeof data.code === "string" ? data.code.trim() : "";
    if (!/^\d{6}$/.test(code)) {
      throw new HttpsError(
        "invalid-argument",
        "Verification code must be 6 digits."
      );
    }

    const ref = db.collection("email_verifications").doc(uid);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError(
        "not-found",
        "No verification code found. Request a new one."
      );
    }
    const doc = snap.data()!;
    if (emailCodeExpiryMs(doc.expiresAt) < Date.now()) {
      throw new HttpsError(
        "failed-precondition",
        "This code has expired. Request a new one."
      );
    }
    if (((doc.attempts as number) ?? 0) >= MAX_ATTEMPTS) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many failed attempts. Request a new code."
      );
    }

    const salt = (doc.codeSalt as string) ?? "";
    const expected = (doc.codeHash as string) ?? "";
    const actual = hashCode(code, salt);
    const ok =
      expected.length === actual.length &&
      crypto.timingSafeEqual(
        Buffer.from(expected, "hex"),
        Buffer.from(actual, "hex")
      );

    if (!ok) {
      // Merge-set preserves the code doc while bumping the attempt counter.
      await ref.set(
        { attempts: ((doc.attempts as number) ?? 0) + 1 },
        { merge: true }
      );
      throw new HttpsError(
        "invalid-argument",
        "Incorrect code. Please try again."
      );
    }

    // Consume the code (single-use) and set the Auth flag + Firestore mirror.
    await admin.auth().updateUser(uid, { emailVerified: true });
    await db.collection("users").doc(uid).set(
      {
        emailVerified: true,
        emailLockedAt: admin.firestore.FieldValue.delete(),
      },
      { merge: true }
    );
    await ref.delete();

    // Fire-and-forget welcome email — never blocks verification success.
    try {
      const userRecord = await admin.auth().getUser(uid);
      await sendEmail({
        to: userRecord.email!,
        subject: "Welcome to Emerge — you're verified",
        html:
          "<p>Your email is verified. Welcome aboard — " +
          "your journey begins now.</p>",
      });
    } catch (err) {
      console.error(`[verifyEmailCode] welcome email failed for ${uid}:`, err);
    }

    return { ok: true };
  }
);

/** Testable body of the scheduled lock; wrapped by onSchedule below. */
export async function enforceEmailGracePeriodInternal(
  database: typeof db,
  nowMs: number
): Promise<void> {
  const cutoff = new Date(nowMs - GRACE_PERIOD_MS);
  const snap = await database
    .collection("users")
    .where("createdAt", "<=", cutoff)
    .get();
  const batch = admin.firestore().batch();
  let changed = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.emailVerified !== true && data.emailLockedAt == null) {
      batch.set(
        database.collection("users").doc(doc.id),
        { emailLockedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );
      changed++;
    }
  }
  if (changed > 0) {
    await batch.commit();
  }
}

export const enforceEmailGracePeriod = onSchedule("0 4 * * *", async () => {
  console.log("Enforcing email verification grace period");
  await enforceEmailGracePeriodInternal(db, Date.now());
});
