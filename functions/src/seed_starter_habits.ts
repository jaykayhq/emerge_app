/**
 * seed_starter_habits
 *
 * Mirrors the in-app `StarterHabitBlueprint` and `Interest` catalogs into
 * Firestore so a server-side `createStarterPack` Cloud Function can
 * validate against an authoritative server copy instead of trusting the
 * client's `identityTags` payload.
 *
 * Source of truth on the client: `lib/features/onboarding/domain/models/`
 *   - starter_habit_blueprint.dart (~30 entries)
 *   - interest.dart (~24 entries across 6 categories)
 *
 * Source of truth on the server: this file. The two MUST be kept in sync
 * by hand. The script writes both collections in a single batch, so
 * clients reading either after a successful seed are guaranteed to see
 * consistent data.
 *
 * Run with: `firebase functions:shell` or as a one-shot
 *           `curl -X POST <fnUrl> -H "Authorization: Bearer $ADMIN_SECRET"`
 */
import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

// =============================================================================
// CURATED STARTER HABIT BLUEPRINTS
// Mirror of lib/features/onboarding/domain/models/starter_habit_blueprint.dart
// Categories: movement | learning | creativity | mindfulness | faith | nutrition
// Attributes: strength | intellect | vitality | creativity | focus | spirit
// Archetypes: athlete | scholar | creator | stoic | zealot | none
// =============================================================================
interface BlueprintEntry {
  id: string;
  title: string;
  shortCue: string;
  attribute: string;
  archetype: string;
  interestCategories: string[];
  clubTags: string[];
  sourceAttribution: string;
}

const STARTER_HABIT_BLUEPRINTS: BlueprintEntry[] = [
  // ATHLETE — 6 entries
  {
    id: "athlete.squats.10",
    title: "10 squats",
    shortCue: "After breakfast",
    attribute: "vitality",
    archetype: "athlete",
    interestCategories: ["movement"],
    clubTags: ["fitness", "morning"],
    sourceAttribution: "happytrainers.com — 10-minute beginner routine",
  },
  {
    id: "athlete.plank.60s",
    title: "60-second plank",
    shortCue: "After waking up",
    attribute: "vitality",
    archetype: "athlete",
    interestCategories: ["movement"],
    clubTags: ["fitness", "morning"],
    sourceAttribution: "happytrainers.com — 10-minute beginner routine",
  },
  {
    id: "athlete.walk.10min",
    title: "10-minute walk outside",
    shortCue: "After lunch",
    attribute: "vitality",
    archetype: "athlete",
    interestCategories: ["movement", "mindfulness"],
    clubTags: ["fitness", "walking"],
    sourceAttribution: "Mayo Clinic 5-step fitness program",
  },
  {
    id: "athlete.warmup.breath",
    title: "5 slow breaths before training",
    shortCue: "Before workout",
    attribute: "focus",
    archetype: "athlete",
    interestCategories: ["mindfulness", "movement"],
    clubTags: ["fitness"],
    sourceAttribution: "happytrainers.com warm-up guide",
  },
  {
    id: "athlete.hydration.glass",
    title: "Drink one glass of water",
    shortCue: "After waking up",
    attribute: "vitality",
    archetype: "athlete",
    interestCategories: ["nutrition", "movement"],
    clubTags: ["fitness", "wellness"],
    sourceAttribution: "CDC hydration guidance",
  },
  {
    id: "athlete.mobility.flow",
    title: "5-minute mobility flow",
    shortCue: "After waking up",
    attribute: "vitality",
    archetype: "athlete",
    interestCategories: ["movement", "mindfulness"],
    clubTags: ["fitness", "morning", "mobility"],
    sourceAttribution: "happytrainers.com — beginner bodyweight",
  },

  // SCHOLAR — 6 entries
  {
    id: "scholar.read.2pages",
    title: "Read 2 pages",
    shortCue: "Before bed",
    attribute: "intellect",
    archetype: "scholar",
    interestCategories: ["learning"],
    clubTags: ["reading", "night-owl", "learning"],
    sourceAttribution: "James Clear 2-minute rule (Atomic Habits)",
  },
  {
    id: "scholar.focus.10min",
    title: "10-minute focus sprint",
    shortCue: "After coffee",
    attribute: "focus",
    archetype: "scholar",
    interestCategories: ["learning"],
    clubTags: ["productivity", "focus", "deep-work"],
    sourceAttribution: "Cal Newport — Deep Work",
  },
  {
    id: "scholar.question.1",
    title: "Write down one question",
    shortCue: "After waking up",
    attribute: "intellect",
    archetype: "scholar",
    interestCategories: ["learning", "creativity"],
    clubTags: ["productivity", "curiosity"],
    sourceAttribution: "Sönke Ahrens — How to Take Smart Notes",
  },
  {
    id: "scholar.review.notes",
    title: "Review yesterday's notes for 2 minutes",
    shortCue: "Before bed",
    attribute: "intellect",
    archetype: "scholar",
    interestCategories: ["learning"],
    clubTags: ["reading", "night-owl", "study"],
    sourceAttribution: "Cal Newport / Andy Matuschak — spaced review",
  },
  {
    id: "scholar.vocab.5min",
    title: "5 minutes of language practice",
    shortCue: "After work",
    attribute: "intellect",
    archetype: "scholar",
    interestCategories: ["learning"],
    clubTags: ["language", "learning"],
    sourceAttribution: "Language learner community — micro-session norm",
  },
  {
    id: "scholar.curiosity.1",
    title: "Spend 5 minutes on one curiosity",
    shortCue: "After lunch",
    attribute: "intellect",
    archetype: "scholar",
    interestCategories: ["learning"],
    clubTags: ["curiosity", "learning"],
    sourceAttribution: "James Clear — daily curiosity ritual",
  },

  // CREATOR — 6 entries
  {
    id: "creator.write.1sentence",
    title: "Write 1 sentence",
    shortCue: "After coffee",
    attribute: "creativity",
    archetype: "creator",
    interestCategories: ["creativity"],
    clubTags: ["writing", "morning"],
    sourceAttribution: "The Write Practice — keystone habits for writers",
  },
  {
    id: "creator.read.10min",
    title: "Read for 10 minutes",
    shortCue: "Before bed",
    attribute: "creativity",
    archetype: "creator",
    interestCategories: ["creativity", "learning"],
    clubTags: ["reading", "night-owl"],
    sourceAttribution: "The Write Practice — keystone habits for writers",
  },
  {
    id: "creator.brainstorm.3bad",
    title: "Brainstorm 3 bad ideas for 5 minutes",
    shortCue: "After lunch",
    attribute: "creativity",
    archetype: "creator",
    interestCategories: ["creativity"],
    clubTags: ["creativity"],
    sourceAttribution: "James Clear — daily brainstorming ritual",
  },
  {
    id: "creator.capture.idea",
    title: "Capture today's creative idea",
    shortCue: "After waking up",
    attribute: "creativity",
    archetype: "creator",
    interestCategories: ["creativity"],
    clubTags: ["writing", "morning"],
    sourceAttribution: "Anna Yang — daily creator routine",
  },
  {
    id: "creator.sketch.30s",
    title: "Sketch one rough shape",
    shortCue: "After work",
    attribute: "creativity",
    archetype: "creator",
    interestCategories: ["creativity"],
    clubTags: ["art", "creativity"],
    sourceAttribution: "See Jane Write — sketch a day for 30s",
  },
  {
    id: "creator.pomodoro.25",
    title: "25-minute Pomodoro on one project",
    shortCue: "After coffee",
    attribute: "focus",
    archetype: "creator",
    interestCategories: ["creativity", "learning"],
    clubTags: ["writing", "productivity", "deep-work"],
    sourceAttribution: "MasterClass — Pomodoro for writers",
  },

  // STOIC — 6 entries
  {
    id: "stoic.journal.2min",
    title: "2-minute morning journal",
    shortCue: "After waking up",
    attribute: "focus",
    archetype: "stoic",
    interestCategories: ["mindfulness", "learning"],
    clubTags: ["morning", "stoic"],
    sourceAttribution: "Marcus Aurelius — Meditations morning practice",
  },
  {
    id: "stoic.meditations.read",
    title: "Read one Meditations passage",
    shortCue: "Before bed",
    attribute: "intellect",
    archetype: "stoic",
    interestCategories: ["mindfulness", "learning"],
    clubTags: ["reading", "night-owl", "stoic"],
    sourceAttribution: "Daily Stoic — morning routine",
  },
  {
    id: "stoic.evening.examine",
    title: "60-second evening reflection",
    shortCue: "Before bed",
    attribute: "focus",
    archetype: "stoic",
    interestCategories: ["mindfulness"],
    clubTags: ["night-owl", "stoic"],
    sourceAttribution: "Seneca — evening examination (5-Minute Journal format)",
  },
  {
    id: "stoic.breath.pre",
    title: "60-second box breath",
    shortCue: "Before a hard conversation",
    attribute: "focus",
    archetype: "stoic",
    interestCategories: ["mindfulness"],
    clubTags: ["stoic", "breathwork"],
    sourceAttribution: "Stoic preparatory practice — pre-action pause",
  },
  {
    id: "stoic.dichotomy.1",
    title: "Note one thing you control today",
    shortCue: "After waking up",
    attribute: "focus",
    archetype: "stoic",
    interestCategories: ["mindfulness"],
    clubTags: ["morning", "stoic"],
    sourceAttribution: "Epictetus — dichotomy of control",
  },
  {
    id: "stoic.virtue.1",
    title: "Pick one virtue to practice today",
    shortCue: "After waking up",
    attribute: "spirit",
    archetype: "stoic",
    interestCategories: ["mindfulness", "faith"],
    clubTags: ["stoic"],
    sourceAttribution: "Marcus Aurelius — Meditations 2.1",
  },

  // ZEALOT — 6 entries
  {
    id: "zealot.prayer.2min",
    title: "2-minute morning prayer",
    shortCue: "After waking up",
    attribute: "spirit",
    archetype: "zealot",
    interestCategories: ["faith", "mindfulness"],
    clubTags: ["morning", "prayer", "faith"],
    sourceAttribution: "FaithTime — 7-day prayer micro-plan Day 1-2",
  },
  {
    id: "zealot.scripture.passage",
    title: "Read one short Scripture passage",
    shortCue: "After waking up",
    attribute: "spirit",
    archetype: "zealot",
    interestCategories: ["faith"],
    clubTags: ["morning", "scripture", "reading"],
    sourceAttribution: "FaithTime — Bible study methods",
  },
  {
    id: "zealot.gratitude.1",
    title: "Write one sentence of gratitude",
    shortCue: "Before bed",
    attribute: "spirit",
    archetype: "zealot",
    interestCategories: ["faith", "mindfulness"],
    clubTags: ["night-owl", "devotional"],
    sourceAttribution: "Five Ways to Practice Your Faith Daily",
  },
  {
    id: "zealot.listening.1min",
    title: "One minute of quiet listening",
    shortCue: "After work",
    attribute: "spirit",
    archetype: "zealot",
    interestCategories: ["faith", "mindfulness"],
    clubTags: ["devotional", "prayer"],
    sourceAttribution: "FaithTime — Day 3-4 prayer step",
  },
  {
    id: "zealot.share.1prayer",
    title: "Share one prayer request with a friend",
    shortCue: "After waking up",
    attribute: "spirit",
    archetype: "zealot",
    interestCategories: ["faith"],
    clubTags: ["community", "prayer"],
    sourceAttribution: "FaithTime — Day 5-7 community step",
  },
  {
    id: "zealot.devotional.1",
    title: "Read a one-paragraph devotional",
    shortCue: "Before bed",
    attribute: "spirit",
    archetype: "zealot",
    interestCategories: ["faith"],
    clubTags: ["night-owl", "devotional"],
    sourceAttribution: "FaithTime — daily devotional benefits",
  },
];

// =============================================================================
// CURATED INTEREST CATALOG
// Mirror of lib/features/onboarding/domain/models/interest.dart
// =============================================================================
interface InterestEntry {
  id: string;
  label: string;
  category: string;
  displayName: string;
}

const INTEREST_CATALOG: InterestEntry[] = [
  // Movement
  { id: "movement.walking",   label: "Walking",                category: "movement", displayName: "Movement" },
  { id: "movement.running",   label: "Running",                category: "movement", displayName: "Movement" },
  { id: "movement.strength",  label: "Strength Training",      category: "movement", displayName: "Movement" },
  { id: "movement.yoga",      label: "Yoga & Mobility",        category: "movement", displayName: "Movement" },
  { id: "movement.outdoors",  label: "Outdoor Adventure",      category: "movement", displayName: "Movement" },
  // Learning
  { id: "learning.reading",   label: "Reading",                category: "learning", displayName: "Learning" },
  { id: "learning.languages", label: "Languages",              category: "learning", displayName: "Learning" },
  { id: "learning.skills",    label: "New Skills",             category: "learning", displayName: "Learning" },
  { id: "learning.focus",     label: "Deep Focus",             category: "learning", displayName: "Learning" },
  { id: "learning.curiosity", label: "Curiosity & Discovery",  category: "learning", displayName: "Learning" },
  // Creativity
  { id: "creativity.writing", label: "Writing",                category: "creativity", displayName: "Creativity" },
  { id: "creativity.art",     label: "Visual Art",             category: "creativity", displayName: "Creativity" },
  { id: "creativity.music",   label: "Music",                  category: "creativity", displayName: "Creativity" },
  { id: "creativity.making",  label: "Building & Making",      category: "creativity", displayName: "Creativity" },
  // Mindfulness
  { id: "mindfulness.meditation",  label: "Meditation",       category: "mindfulness", displayName: "Mindfulness" },
  { id: "mindfulness.journaling",  label: "Journaling",       category: "mindfulness", displayName: "Mindfulness" },
  { id: "mindfulness.breathwork",  label: "Breathwork",       category: "mindfulness", displayName: "Mindfulness" },
  // Faith
  { id: "faith.prayer",        label: "Prayer",                category: "faith", displayName: "Faith" },
  { id: "faith.scripture",     label: "Scripture Reading",     category: "faith", displayName: "Faith" },
  { id: "faith.devotional",    label: "Daily Devotional",      category: "faith", displayName: "Faith" },
  { id: "faith.community",     label: "Faith Community",       category: "faith", displayName: "Faith" },
  // Nutrition
  { id: "nutrition.hydration",   label: "Hydration",           category: "nutrition", displayName: "Nutrition" },
  { id: "nutrition.cooking",     label: "Home Cooking",        category: "nutrition", displayName: "Nutrition" },
  { id: "nutrition.wholefoods",  label: "Whole Foods",         category: "nutrition", displayName: "Nutrition" },
];

// =============================================================================
// HTTP TRIGGER
// Auth via ADMIN_SECRET (matches seed_templates.ts pattern).
// =============================================================================
export const seedOnboardingCatalog = onRequest({
  memory: "256MiB",
  invoker: "public",
}, async (req, res) => {
  // Admin-auth guard. Same shape as the rest of the seed family.
  const authHeader = req.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    res.status(401).send("Unauthorized: missing Bearer token");
    return;
  }
  const token = authHeader.split(" ")[1];
  if (token !== process.env.ADMIN_SECRET) {
    res.status(403).send("Forbidden: invalid admin token");
    return;
  }
  if (req.method !== "POST" && req.method !== "PUT") {
    res.status(405).send("Method not allowed");
    return;
  }

  try {
    const batch = db.batch();

    for (const blueprint of STARTER_HABIT_BLUEPRINTS) {
      const ref = db.collection("starter_habit_blueprints").doc(blueprint.id);
      batch.set(ref, {
        ...blueprint,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    for (const interest of INTEREST_CATALOG) {
      const ref = db.collection("interest_catalog").doc(interest.id);
      batch.set(ref, {
        ...interest,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    res.status(200).json({
      ok: true,
      starter_habit_blueprints: STARTER_HABIT_BLUEPRINTS.length,
      interest_catalog: INTEREST_CATALOG.length,
    });
  } catch (err: unknown) {
    console.error("seedOnboardingCatalog failed:", err);
    res.status(500).send("Seeding failed");
  }
});

// Exported for unit tests; not callable on its own.
export const __test = {
  STARTER_HABIT_BLUEPRINTS,
  INTEREST_CATALOG,
};
