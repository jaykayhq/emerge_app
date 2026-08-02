import { aggregateTribeStats } from "../src/recalcTribes";

describe("aggregateTribeStats", () => {
  it("uses explicit membership over the archetype club", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map([["u1", "creative_collective"]]),
      archetypeMap: new Map([["u1", "athlete"]]),
      clubMap: { athlete: "morning_warriors" },
      userStatsXp: new Map([["u1", 100]]),
    });
    expect(out.get("creative_collective")?.members).toEqual(["u1"]);
    expect(out.get("creative_collective")?.totalXp).toBe(100);
    expect(out.has("morning_warriors")).toBe(false);
  });

  it("falls back to the official archetype club for users without explicit membership", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map(),
      archetypeMap: new Map([["u2", "stoic"]]),
      clubMap: { stoic: "mindful_masters" },
      userStatsXp: new Map([["u2", 42]]),
    });
    expect(out.get("mindful_masters")?.members).toEqual(["u2"]);
    expect(out.get("mindful_masters")?.totalXp).toBe(42);
  });

  it("drops users with no explicit membership and no official club (archetype none/unknown)", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map(),
      archetypeMap: new Map([["u3", "none"]]),
      clubMap: {},
      userStatsXp: new Map([["u3", 7]]),
    });
    expect(out.size).toBe(0);
  });

  it("aggregates XP per member directly, not by archetype bucket", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map([["a1", "creative_collective"], ["a2", "creative_collective"]]),
      archetypeMap: new Map([["a1", "athlete"], ["a2", "stoic"]]),
      clubMap: { athlete: "morning_warriors", stoic: "mindful_masters" },
      userStatsXp: new Map([["a1", 10], ["a2", 20]]),
    });
    expect(out.get("creative_collective")?.totalXp).toBe(30);
    expect(out.get("morning_warriors")).toBeUndefined();
    expect(out.get("mindful_masters")).toBeUndefined();
  });

  it("members without user_stats docs contribute 0 XP", () => {
    const out = aggregateTribeStats({
      membershipMap: new Map([["u5", "deep_work_society"]]),
      archetypeMap: new Map(),
      clubMap: {},
      userStatsXp: new Map(),
    });
    expect(out.get("deep_work_society")?.totalXp).toBe(0);
  });
});
