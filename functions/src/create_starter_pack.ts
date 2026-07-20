/**
 * createStarterPack (callable)
 *
 * Server-authoritative variant of the client's `HabitRepository.createStarterPack`.
 * Validates the requested blueprint ids against the curated
 * `starter_habit_blueprints` collection and writes three (or fewer)
 * habits in a single Firestore batched transaction.
 *
 * Why this exists:
 *   - The client-side path writes habits directly with `identityTags`
 *     that include `'onboarding'` (which the free-tier count bypass trusts).
 *     A compromised client could otherwise stamp any new habit with that
 *     tag. Server-side authoring lets us reject unknown blueprints and
 *     strip privileged tags.
 *   - The curated catalog (mirror of the Dart-side
 *     `StarterHabitBlueprint.catalog`) is the authoritative whitelist of
 *     what's allowed in a starter pack.
 *
 * Auth: caller must be the user who will own the new habits.
 *
 * Inputs:
 *   - blueprintIds: string[]  (1..3 ids from starter_habit_blueprints)
 *
 * Outputs:
 *   - createdHabitIds: string[]  (ids of the newly written habits, in the
 *     same order as the input blueprintIds)
 *   - attribute: string         (the most common attribute across the
 *     created habits; used for stat XP routing)
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const ALLOWED_MAX_PER_PACK = 3;
const ALLOWED_MIN_PER_PACK = 1;

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

interface StarterPackRequest {
  blueprintIds: string[];
}

interface StarterPackResponse {
  ok: true;
  createdHabitIds: string[];
  attribute: string;
}

interface BlueprintSnapshot {
  id: string;
  title: string;
  shortCue: string;
  attribute: string;
  archetype: string;
}

export const createStarterPack = onCall<StarterPackRequest>(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to create a starter pack.");
  }
  const data = request.data;
  if (!data || !Array.isArray(data.blueprintIds)) {
    throw new HttpsError(
      "invalid-argument",
      "blueprintIds: string[] is required.",
    );
  }
  if (
    data.blueprintIds.length < ALLOWED_MIN_PER_PACK ||
    data.blueprintIds.length > ALLOWED_MAX_PER_PACK
  ) {
    throw new HttpsError(
      "invalid-argument",
      `A starter pack must contain ${ALLOWED_MIN_PER_PACK}-${ALLOWED_MAX_PER_PACK} blueprints.`,
    );
  }
  // Reject duplicates so the user can't hammer the same id twice.
  if (new Set(data.blueprintIds).size !== data.blueprintIds.length) {
    throw new HttpsError("invalid-argument", "Duplicate blueprint ids.");
  }
  for (const id of data.blueprintIds) {
    if (typeof id !== "string" || id.length === 0 || id.length > 100) {
      throw new HttpsError(
        "invalid-argument",
        "Each blueprint id must be a non-empty string ≤100 chars.",
      );
    }
    // Blueprints are namespaced "<archetype>.<slug>"; reject free-form
    // ids that don't fit the pattern.
    if (!/^[a-z]+\.[a-z0-9_.-]+$/.test(id)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid blueprint id format: ${id}`,
      );
    }
  }

  const uid = request.auth.uid;
  const now = admin.firestore.FieldValue.serverTimestamp();

  // 1. Load all requested blueprints (single round-trip, multi-get).
  const refs = data.blueprintIds.map((id) =>
    db.collection("starter_habit_blueprints").doc(id),
  );
  const snaps = await db.getAll(...refs);
  const found: BlueprintSnapshot[] = [];
  for (let i = 0; i < data.blueprintIds.length; i++) {
    const id = data.blueprintIds[i];
    const snap = snaps[i];
    if (!snap.exists) {
      throw new HttpsError(
        "not-found",
        `Blueprint '${id}' is not in the curated catalog.`,
      );
    }
    const blueprint = snap.data() as BlueprintSnapshot;
    if (blueprint.id !== id) {
      // Defensive: should never happen because we used the id as the doc id.
      throw new HttpsError("internal", `Blueprint id mismatch on '${id}'.`);
    }
    found.push(blueprint);
  }

  // 2. Build the habit records. Only stamp 'onboarding' on tags we own;
  //    never trust a client-provided `identityTags` field.
  const createdIds: string[] = [];
  const attributes: string[] = [];
  for (const blueprint of found) {
    const habitId = `${blueprint.id}_${uid}_${Date.now()}_${createdIds.length}`;
    createdIds.push(habitId);
    attributes.push(blueprint.attribute);
    const habitRecord = {
      id: habitId,
      userId: uid,
      title: blueprint.title,
      cue: blueprint.shortCue,
      routine: "",
      reward: "",
      frequency: "daily",
      difficulty: "easy",
      attribute: blueprint.attribute,
      impact: "positive",
      identityTags: ["onboarding", `blueprint:${blueprint.id}`],
      isArchived: false,
      contractActive: false,
      order: 0,
      timerDurationMinutes: 2,
      momentumScore: 0,
      consecutiveMisses: 0,
      currentStreak: 0,
      longestStreak: 0,
      integrationType: "none",
      createdAt: now,
      updatedAt: now,
    };

    // 3. Single batched write per call (capped at ALLOWED_MAX_PER_PACK).
    await db.collection("habits").doc(habitId).set(habitRecord);
  }

  // 4. Pick the "headline" attribute (most common across the pack) for
  //    downstream XP routing. Ties go to the first.
  const counts = new Map<string, number>();
  for (const attr of attributes) counts.set(attr, (counts.get(attr) ?? 0) + 1);
  let bestAttribute = attributes[0];
  let bestCount = 0;
  for (const [attr, count] of counts) {
    if (count > bestCount) {
      bestAttribute = attr;
      bestCount = count;
    }
  }

  const response: StarterPackResponse = {
    ok: true,
    createdHabitIds: createdIds,
    attribute: bestAttribute,
  };
  return response;
});

// Exported for unit tests only.
export const __test = {
  ALLOWED_MAX_PER_PACK,
  ALLOWED_MIN_PER_PACK,
};
