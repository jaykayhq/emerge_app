/**
 * Tests for the createStarterPack Cloud Function.
 *
 * Stubs the Admin Firestore client via jest.mock so these run in offline
 * mode (no service account or emulator required). Mirrors paystack.test.ts.
 */

jest.mock("firebase-admin", () => {
  // The mock factory closes over local Maps. We expose them through
  // helper methods on the firestore mock so tests can swap state.
  let catalog = new Map<string, unknown>();
  let habits = new Map<string, unknown>();
  (globalThis as any).__reset_onboarding_catalog = () => {
    catalog = new Map<string, unknown>();
    habits = new Map<string, unknown>();
  };
  (globalThis as any).__seed_onboarding_catalog = (id: string, data: unknown) => {
    catalog.set(id, data);
  };
  (globalThis as any).__get_onboarding_habits = () => habits;

  const makeBlueprintDocRef = (id: string) => ({
    id,
    get: async () => ({
      exists: catalog.has(id),
      id,
      data: () => catalog.get(id),
    }),
  });

  const firestoreMock: any = {
    collection: (name: string) => ({
      doc: (id: string) => {
        if (name === "starter_habit_blueprints") {
          return makeBlueprintDocRef(id);
        }
        if (name === "habits") {
          return {
            set: async (data: unknown) => {
              habits.set(id, { ...(data as object) });
              return Promise.resolve();
            },
          };
        }
        return makeBlueprintDocRef(id);
      },
    }),
    getAll: async (...refs: { id: string }[]) =>
      refs.map((ref) => {
        const data = catalog.get(ref.id) ?? null;
        return {
          exists: data !== null,
          id: ref.id,
          data: () => data,
        };
      }),
  };
  // Production code accesses these both via `admin.firestore.FieldValue`
  // (static, on the namespace) AND via the instance returned from
  // `admin.firestore()`. Mirror both with the same object.
  firestoreMock.FieldValue = { serverTimestamp: () => "SERVER_TIMESTAMP" };
  firestoreMock.Timestamp = { fromDate: (d: Date) => d };

  const firestoreCallable: any = (() => firestoreMock);
  // Make `admin.firestore.FieldValue` resolve to the same object.
  firestoreCallable.FieldValue = firestoreMock.FieldValue;
  firestoreCallable.Timestamp = firestoreMock.Timestamp;

  return {
    apps: [],
    initializeApp: () => undefined,
    firestore: firestoreCallable,
  };
});

// Loaded from `../lib/` to match the existing convention in index.test.ts.
// eslint-disable-next-line @typescript-eslint/no-require-imports, @typescript-eslint/no-var-requires
const { createStarterPack, __test } = require("../lib/create_starter_pack");

const wrappedRun = createStarterPack.run.bind(createStarterPack);
const AUTHED = { auth: { uid: "test_user_123" }, data: {} };

function resetCatalog() {
  (globalThis as any).__reset_onboarding_catalog();
}

function seed(id: string, data: Record<string, unknown>) {
  (globalThis as any).__seed_onboarding_catalog(id, data);
}

function getStoredHabits(): Map<string, Record<string, unknown>> {
  return (globalThis as any).__get_onboarding_habits();
}

const ATHLETE_SQUATS = {
  id: "athlete.squats.10",
  title: "10 squats",
  shortCue: "After breakfast",
  attribute: "vitality",
  archetype: "athlete",
  interestCategories: ["movement"],
  clubTags: ["fitness"],
  sourceAttribution: "happytrainers.com",
};

const ATHLETE_PLANK = {
  ...ATHLETE_SQUATS,
  id: "athlete.plank.60s",
  title: "60-second plank",
  shortCue: "After waking up",
};

const SCHOLAR_READ = {
  id: "scholar.read.2pages",
  title: "Read 2 pages",
  shortCue: "Before bed",
  attribute: "intellect",
  archetype: "scholar",
  interestCategories: ["learning"],
  clubTags: ["reading"],
  sourceAttribution: "James Clear",
};

describe("createStarterPack", () => {
  beforeEach(() => {
    resetCatalog();
  });

  it("rejects unauthenticated callers", async () => {
    await expect(
      wrappedRun({ auth: undefined, data: { blueprintIds: ["athlete.squats.10"] } }),
    ).rejects.toMatchObject({ code: "unauthenticated" });
  });

  it("rejects empty arrays", async () => {
    seed(ATHLETE_SQUATS.id, ATHLETE_SQUATS);
    await expect(
      wrappedRun({ ...AUTHED, data: { blueprintIds: [] } }),
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("rejects arrays larger than the per-pack cap", async () => {
    await expect(
      wrappedRun({
        ...AUTHED,
        data: {
          blueprintIds: [
            "athlete.squats.10",
            "athlete.plank.60s",
            "scholar.read.2pages",
            "athlete.squats.10",
          ],
        },
      }),
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("rejects ids that don't match the namespaced format", async () => {
    await expect(
      wrappedRun({
        ...AUTHED,
        data: { blueprintIds: ["drop table users;--"] },
      }),
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("rejects duplicate ids", async () => {
    seed(ATHLETE_SQUATS.id, ATHLETE_SQUATS);
    await expect(
      wrappedRun({
        ...AUTHED,
        data: { blueprintIds: ["athlete.squats.10", "athlete.squats.10"] },
      }),
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("rejects ids not in the curated catalog", async () => {
    await expect(
      wrappedRun({
        ...AUTHED,
        data: { blueprintIds: ["made.up.id"] },
      }),
    ).rejects.toMatchObject({ code: "not-found" });
  });

  it("writes a Habit doc per blueprint with restricted tags and "
    + "returns their ids", async () => {
      seed(ATHLETE_SQUATS.id, ATHLETE_SQUATS);
      seed(ATHLETE_PLANK.id, ATHLETE_PLANK);

      const res = await wrappedRun({
        ...AUTHED,
        data: {
          blueprintIds: ["athlete.squats.10", "athlete.plank.60s"],
        },
      });
      expect(res.ok).toBe(true);
      expect(res.createdHabitIds).toHaveLength(2);
      expect(res.attribute).toBe("vitality");

      const stored = getStoredHabits();
      expect(stored.size).toBe(2);
      for (const [, habit] of stored) {
        expect(habit.userId).toBe("test_user_123");
        expect(habit.difficulty).toBe("easy");
        // The only allowed tag values on a server-authored onboarding
        // habit: literal "onboarding" or "blueprint:<id>". Any other
        // prefix would be a privilege boundary violation.
        for (const tag of habit.identityTags as string[]) {
          expect(
            tag === "onboarding" || tag.startsWith("blueprint:"),
          ).toBe(true);
        }
      }
    });

  it("picks the headline attribute as the most common", async () => {
    seed(ATHLETE_SQUATS.id, ATHLETE_SQUATS);
    seed(ATHLETE_PLANK.id, ATHLETE_PLANK);
    seed(SCHOLAR_READ.id, SCHOLAR_READ);

    const res = await wrappedRun({
      ...AUTHED,
      data: {
        blueprintIds: [
          "scholar.read.2pages",
          "athlete.squats.10",
          "athlete.plank.60s",
        ],
      },
    });
    expect(res.attribute).toBe("vitality");
  });

  it("exposes the size limits via __test", () => {
    expect(__test.ALLOWED_MIN_PER_PACK).toBe(1);
    expect(__test.ALLOWED_MAX_PER_PACK).toBe(3);
  });
});
