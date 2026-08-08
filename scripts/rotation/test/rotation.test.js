"use strict";

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { computeRotation } = require("../lib/rotation");

const NOW = new Date("2026-08-10T00:00:00Z"); // a Monday

const template = (id, overrides = {}) => ({
  id,
  title: `Quest ${id}`,
  description: "d",
  category: "fitness",
  archetypeId: "athlete",
  totalDays: 30,
  xpReward: 1000,
  reward: "Exclusive reward",
  imageUrl: "https://img.example/fallback.jpg",
  rewardDescription: "20% off",
  partnerId: "nike",
  steps: [{ day: 1, title: "Start", description: "Go", isCompleted: false }],
  ...overrides,
});

const partner = (id, overrides = {}) => ({
  id,
  name: "Nike",
  logoUrl: "https://img.example/nike.jpg",
  category: "fitness",
  network: "direct",
  commissionRate: 0.1,
  affiliateUrl: "https://partner.example/reward",
  ...overrides,
});

const existing = (id, overrides = {}) => ({
  id,
  title: "Old",
  status: "featured",
  participants: 5,
  sponsorshipEndDate: "2099-01-01T00:00:00Z",
  ...overrides,
});

test("expires challenges whose sponsorship window has ended", () => {
  const plan = computeRotation({
    templates: [],
    existing: [
      existing("a", { sponsorshipEndDate: "2020-01-01T00:00:00Z" }),
      existing("b", { status: "completed", sponsorshipEndDate: "2020-01-01T00:00:00Z" }),
      existing("c", {}),
    ],
    partners: [],
    config: { enabled: true, featuredLimit: 3, imagePool: [] },
    now: NOW,
  });
  assert.deepEqual(plan.updates.filter((u) => u.update.status === "completed").map((u) => u.id), ["a"]);
});

test("upserts templates that do not exist yet, with partner affiliate fields", () => {
  const plan = computeRotation({
    templates: [template("q1")],
    existing: [],
    partners: [partner("nike")],
    config: { enabled: true, featuredLimit: 1, imagePool: [] },
    now: NOW,
  });
  assert.equal(plan.upserts.length, 1);
  const doc = plan.upserts[0].challenge;
  assert.equal(doc.id, "q1");
  assert.equal(doc.status, "featured");
  assert.equal(doc.isSponsored, true);
  assert.equal(doc.affiliateUrl, "https://partner.example/reward");
  assert.equal(doc.sponsor, "Nike");
  assert.equal(doc.affiliateNetwork, "direct");
  assert.equal(doc.imageUrl, "https://img.example/fallback.jpg");
});

test("honours featuredLimit; excess templates stay active", () => {
  const plan = computeRotation({
    templates: [template("q1"), template("q2"), template("q3")],
    existing: [],
    partners: [],
    config: { enabled: true, featuredLimit: 2, imagePool: [] },
    now: NOW,
  });
  assert.equal(plan.upserts.length, 3);
  assert.deepEqual(plan.upserts.map((u) => u.challenge.status), ["featured", "featured", "active"]);
});

test("rotates imageUrl per week from the image pool", () => {
  const pool = ["https://img.example/1.jpg", "https://img.example/2.jpg"];
  const monday = new Date("2026-08-10T00:00:00Z");
  const nextMonday = new Date("2026-08-17T00:00:00Z");
  const planA = computeRotation({
    templates: [template("q1", { imageUrl: "" })],
    existing: [],
    partners: [],
    config: { enabled: true, featuredLimit: 1, imagePool: pool },
    now: monday,
  });
  const planB = computeRotation({
    templates: [template("q1", { imageUrl: "" })],
    existing: [],
    partners: [],
    config: { enabled: true, featuredLimit: 1, imagePool: pool },
    now: nextMonday,
  });
  assert.equal(planA.upserts[0].challenge.imageUrl, "https://img.example/2.jpg");
  assert.equal(planB.upserts[0].challenge.imageUrl, "https://img.example/1.jpg");
});

test("prefers an explicit template imageUrl over the pool", () => {
  const plan = computeRotation({
    templates: [template("q1", { imageUrl: "https://img.example/uploaded.jpg" })],
    existing: [],
    partners: [],
    config: { enabled: true, featuredLimit: 1, imagePool: ["https://img.example/1.jpg"] },
    now: NOW,
  });
  assert.equal(plan.upserts[0].challenge.imageUrl, "https://img.example/uploaded.jpg");
});

test("skips writes when an existing doc is already up to date", () => {
  const same = existing("q1", {
    status: "featured",
    imageUrl: "https://img.example/fallback.jpg",
    affiliateUrl: "",
  });
  const plan = computeRotation({
    templates: [template("q1")],
    existing: [same],
    partners: [],
    config: { enabled: true, featuredLimit: 1, imagePool: [] },
    now: NOW,
  });
  assert.equal(plan.updates.length, 0);
  assert.equal(plan.upserts.length, 0);
});

test("disabled config produces no operations", () => {
  const plan = computeRotation({
    templates: [template("q1")],
    existing: [],
    partners: [],
    config: { enabled: false, featuredLimit: 1, imagePool: [] },
    now: NOW,
  });
  assert.equal(plan.upserts.length, 0);
  assert.equal(plan.updates.length, 0);
  assert.equal(plan.notifyIds.length, 0);
});
