"use strict";

/**
 * Curated server-published challenge templates.
 *
 * The rotation driver upserts these into the `challenges` collection. To change
 * a challenge's title/reward/links, edit this file — no app release required.
 *
 * `imageFile` names a file in `scripts/rotation/images/` (generated with polli).
 * The driver uploads it to Firebase Storage each run and points imageUrl at the
 * public URL. If the file is absent, `imageUrl` is the fallback.
 *
 * `partnerId` must match a doc id in `affiliatePartners`; the driver copies the
 * partner's name/logo/network/commission/affiliateUrl over the template fields
 * when present. Prefer storing affiliateUrl on the partner doc so links update
 * without editing code.
 */
const TEMPLATES = [
  {
    id: "srv_morning_protocol",
    title: "The Morning Protocol",
    description:
      "14 days of a non-negotiable morning routine: hydrate, move, and set one intention before screens.",
    category: "productivity",
    archetypeId: "athlete",
    totalDays: 14,
    xpReward: 700,
    reward: "700 XP & Morning Warrior Emblem",
    rewardDescription: "15% off your first order",
    imageFile: "morning_protocol.jpg",
    imageUrl:
      "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800",
    partnerId: "headspace",
    affiliateNetwork: "direct",
    affiliateUrl: "https://example.com/reward/headspace", // REPLACE with your tagged link
    steps: [
      { day: 1, title: "Hydrate First", description: "500ml water before coffee.", isCompleted: false },
      { day: 7, title: "One Week In", description: "Your routine is taking shape.", isCompleted: false },
      { day: 14, title: "Protocol Locked", description: "Own your mornings.", isCompleted: false },
    ],
  },
  {
    id: "srv_read_20",
    title: "Read 20",
    description:
      "20 minutes of reading a day for 21 days. Become the reader you keep saying you will.",
    category: "learning",
    archetypeId: "scholar",
    totalDays: 21,
    xpReward: 900,
    reward: "900 XP & Reader's Quill",
    rewardDescription: "30 days free on us",
    imageFile: "read_20.jpg",
    imageUrl:
      "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800",
    partnerId: "audible",
    affiliateNetwork: "direct",
    affiliateUrl: "https://example.com/reward/audible", // REPLACE with your tagged link
    steps: [
      { day: 1, title: "Start Small", description: "20 minutes, one book.", isCompleted: false },
      { day: 10, title: "Halfway", description: "You are a reader now.", isCompleted: false },
      { day: 21, title: "Reader", description: "21 days of pages.", isCompleted: false },
    ],
  },
  {
    id: "srv_30_day_move",
    title: "30 Days of Movement",
    description:
      "Move your body every single day for 30 days. Walk, run, stretch — just move.",
    category: "fitness",
    archetypeId: "athlete",
    totalDays: 30,
    xpReward: 1200,
    reward: "1200 XP & Golden Running Shoes",
    rewardDescription: "20% off your next pair",
    imageFile: "movement_30.jpg",
    imageUrl:
      "https://images.unsplash.com/photo-1552664730-d307ca884978?w=800",
    partnerId: "nike",
    affiliateNetwork: "direct",
    affiliateUrl: "https://example.com/reward/nike", // REPLACE with your tagged link
    steps: [
      { day: 1, title: "Show Up", description: "10 minutes counts.", isCompleted: false },
      { day: 15, title: "Halfway", description: "Fifteen in a row.", isCompleted: false },
      { day: 30, title: "Movement Day 30", description: "You moved for a month.", isCompleted: false },
    ],
  },
];

module.exports = { TEMPLATES };
