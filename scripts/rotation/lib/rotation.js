"use strict";

/**
 * Pure rotation decisions. No Firestore/admin imports — all inputs and outputs
 * are plain objects so the logic is unit-testable.
 */

const VISIBLE_STATUSES = new Set(["featured", "active"]);
const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

/** Whole weeks since epoch — the deterministic image-rotation bucket. */
function weekIndex(now) {
  return Math.floor(now.getTime() / WEEK_MS);
}

/** Challenge ids whose sponsorship window has ended and are still visible. */
function computeExpiredIds(challenges, now) {
  return challenges
    .filter((c) => VISIBLE_STATUSES.has(c.status))
    .filter((c) => {
      if (!c.sponsorshipEndDate) return false;
      const end = new Date(c.sponsorshipEndDate);
      return !Number.isNaN(end.getTime()) && end <= now;
    })
    .map((c) => c.id);
}

function pickImage(template, imagePool, week, index) {
  // A template-resolved image (e.g. a local polli file uploaded to Storage by
  // the driver) takes priority; the pool only rotates when no image is set.
  if (template.imageUrl) return template.imageUrl;
  if (imagePool.length > 0) return imagePool[(week + index) % imagePool.length];
  return "";
}

/**
 * Computes the rotation plan.
 *
 * @param {object} opts
 * @param {Array<object>} opts.templates  curated template pool
 * @param {Array<object>} opts.existing   existing `challenges` docs (id + data)
 * @param {Array<object>} opts.partners   `affiliatePartners` docs (id + data)
 * @param {object} opts.config            { featuredLimit, imagePool, enabled }
 * @param {Date} opts.now
 * @returns {{upserts: Array<{challenge: object}>, updates: Array<{id: string, update: object}>, notifyIds: string[]}}
 */
function computeRotation({ templates, existing, partners, config, now }) {
  const upserts = [];
  const updates = [];
  const notifyIds = [];

  if (!config.enabled) return { upserts, updates, notifyIds };

  const expired = new Set(computeExpiredIds(existing, now));
  const existingById = new Map(existing.map((c) => [c.id, c]));
  const featuredLimit = Math.max(1, config.featuredLimit ?? 3);
  const imagePool = config.imagePool ?? [];
  const week = weekIndex(now);

  for (const id of expired) {
    updates.push({ id, update: { status: "completed" } });
  }

  templates.forEach((template, index) => {
    const partner = partners.find((p) => p.id === template.partnerId);
    const isFeatured = index < featuredLimit;
    const imageUrl = pickImage(template, imagePool, week, index);

    const doc = {
      title: template.title,
      description: template.description,
      imageUrl,
      category: template.category,
      archetypeId: template.archetypeId,
      totalDays: template.totalDays,
      currentDay: 0,
      daysLeft: template.totalDays,
      participants: existingById.get(template.id)?.participants ?? 0,
      status: isFeatured ? "featured" : "active",
      xpReward: template.xpReward,
      reward: template.reward,
      isFeatured,
      isTeamChallenge: false,
      buddyValidationRequired: false,
      sponsor: partner?.name ?? template.sponsor,
      sponsorLogoUrl: partner?.logoUrl ?? template.sponsorLogoUrl ?? "",
      isSponsored: Boolean(partner),
      affiliateUrl: partner?.affiliateUrl ?? template.affiliateUrl ?? "",
      rewardDescription: template.rewardDescription ?? template.reward,
      affiliatePartnerId: partner?.id ?? template.partnerId ?? null,
      affiliateNetwork: partner?.network ?? template.affiliateNetwork ?? "none",
      commissionRate: partner?.commissionRate ?? template.commissionRate ?? null,
      sponsorshipStartDate: now.toISOString(),
      sponsorshipEndDate: new Date(
        now.getTime() + template.totalDays * 24 * 60 * 60 * 1000
      ).toISOString(),
      steps: template.steps,
    };

    const existingDoc = existingById.get(template.id);
    if (
      existingDoc &&
      existingDoc.status === doc.status &&
      existingDoc.imageUrl === doc.imageUrl &&
      existingDoc.affiliateUrl === doc.affiliateUrl
    ) {
      // No visible change — skip the write entirely (billing/cost).
      return;
    }
    if (existingDoc) {
      doc.participants = existingDoc.participants ?? doc.participants;
      updates.push({ id: template.id, update: doc });
      if (isFeatured && existingDoc.status !== "featured") notifyIds.push(template.id);
    } else {
      upserts.push({ challenge: { id: template.id, ...doc } });
      if (isFeatured) notifyIds.push(template.id);
    }
  });

  return { upserts, updates, notifyIds };
}

module.exports = { computeRotation, computeExpiredIds, weekIndex };
