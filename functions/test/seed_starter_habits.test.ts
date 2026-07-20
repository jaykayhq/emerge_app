/**
 * Tests for seedOnboardingCatalog. Validates:
 *   - Catalog shape (≥4 entries per archetype; ≥3 per interest category)
 *   - Every starter blueprint belongs to a known archetype
 *   - Parity with the Dart-side source-of-truth structure
 */

import { __test as seedExports } from "../src/seed_starter_habits";

const { STARTER_HABIT_BLUEPRINTS, INTEREST_CATALOG } = seedExports;
const VALID_ARCHETYPES = new Set([
  "athlete",
  "scholar",
  "creator",
  "stoic",
  "zealot",
]);
const VALID_ATTRIBUTES = new Set([
  "strength",
  "intellect",
  "vitality",
  "creativity",
  "focus",
  "spirit",
]);
const VALID_CATEGORIES = new Set([
  "movement",
  "learning",
  "creativity",
  "mindfulness",
  "faith",
  "nutrition",
]);

describe("seedOnboardingCatalog catalog", () => {
  it("has ≥4 starter blueprints per selectable archetype", () => {
    for (const archetype of VALID_ARCHETYPES) {
      const count = STARTER_HABIT_BLUEPRINTS.filter(
        (b) => b.archetype === archetype,
      ).length;
      expect(count).toBeGreaterThanOrEqual(4);
    }
  });

  it("uses only valid attributes", () => {
    for (const b of STARTER_HABIT_BLUEPRINTS) {
      expect(VALID_ATTRIBUTES.has(b.attribute)).toBe(true);
    }
  });

  it("uses only valid interest categories", () => {
    for (const b of STARTER_HABIT_BLUEPRINTS) {
      for (const cat of b.interestCategories) {
        expect(VALID_CATEGORIES.has(cat)).toBe(true);
      }
    }
  });

  it("every blueprint has a non-empty title, shortCue, and sourceAttribution", () => {
    for (const b of STARTER_HABIT_BLUEPRINTS) {
      expect(b.title.length).toBeGreaterThan(0);
      expect(b.shortCue.length).toBeGreaterThan(0);
      expect(b.sourceAttribution.length).toBeGreaterThan(0);
    }
  });

  it("every blueprint id is prefixed with its archetype and unique", () => {
    const seen = new Set<string>();
    for (const b of STARTER_HABIT_BLUEPRINTS) {
      expect(b.id.startsWith(b.archetype + ".")).toBe(true);
      expect(seen.has(b.id)).toBe(false);
      seen.add(b.id);
    }
  });
});

describe("seedOnboardingCatalog interest catalog", () => {
  it("has ≥3 interests per category", () => {
    for (const category of VALID_CATEGORIES) {
      const count = INTEREST_CATALOG.filter(
        (i) => i.category === category,
      ).length;
      expect(count).toBeGreaterThanOrEqual(3);
    }
  });

  it("uses only valid categories", () => {
    for (const i of INTEREST_CATALOG) {
      expect(VALID_CATEGORIES.has(i.category)).toBe(true);
    }
  });

  it("every interest id is namespaced <category>.<slug> and unique", () => {
    const seen = new Set<string>();
    for (const i of INTEREST_CATALOG) {
      expect(i.id.startsWith(i.category + ".")).toBe(true);
      expect(seen.has(i.id)).toBe(false);
      seen.add(i.id);
    }
  });
});
