/**
 * Firebase Admin SDK Seeding Script
 * 
 * Seeds Firestore with initial data for tribes and challenges.
 * Uses Admin SDK which bypasses security rules.
 * 
 * Usage: npm run seed
 * 
 * Prerequisites:
 * 1. Set GOOGLE_APPLICATION_CREDENTIALS to service account key path
 * 2. Or run: gcloud auth application-default login
 */

import * as admin from "firebase-admin";

const PROJECT_ID = "tradeflash-l2966";

admin.initializeApp({
  projectId: PROJECT_ID,
});
const db = admin.firestore();

// ============================================================================
// TRIBES DATA
// ============================================================================
const tribes = [
  {
    id: "tribe_meditation_guild",
    name: "Meditation Guild",
    description:
      "A sanctuary for mindfulness practitioners. Build your daily meditation habit with like-minded souls seeking inner peace.",
    imageUrl:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuCQPv10oFu2sDwJG5HnbqYGpxbA0wnzkC6vDlQDKULU6jqd1GFbAvaHlVR8HP5FFbKR_csCaRnpfWctY_KWyR2M1ncSIaVW8yWh3FvINl5K1powi1_HlOHAdAb70KYF1Zh17eHisSvHT7K9zpZ0cKwQM8R59grDPZrlwAwNoWvxJHM6s6Hh9KaFhsxOLvyRPLwbBAQmGzjp2zSF306Ho62WsKQR1Hk5Ym5Xjqyx8XMPXH__xq3jmOHuKvKiBVEfaZO5_BgmfJhgQuo",
    memberCount: 0,
    ownerId: "admin",
    tags: ["Meditation", "Mindfulness", "Mental Health"],
    levelRequirement: 1,
    rank: 1,
    totalXp: 0,
    members: [],
  },
  {
    id: "tribe_5am_writers",
    name: "5 AM Writers",
    description:
      "Early risers who write before the world wakes. Build a consistent writing practice and become the Writer you aspire to be.",
    imageUrl:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuClgA57GDCz5sdk2ZI7AfSAhkSv7hUoB_Wp-Tpa7zqU-A4H5UePzeWr9LE-xfPLVIA2BRUV6pfaZqqoRd29PuxlnRtuIfQPcO3YOCNI9LyL8GGugh3z_M99nsW62fAhd23x9IwcXZMazbVh3E2rVfFtwriLMAPGcAunjMZlwhRb7kiLAcDNR6P8IfadiZf0IwqQ_V-wbAHN3UhB3hHkmExRjo7uAWRE69oQhKcn3ez2YCynQ7Q7rhEsAIVE0sU7-YYjf1srOVEo-pk",
    memberCount: 0,
    ownerId: "admin",
    tags: ["Writing", "Creativity", "Morning Routine"],
    levelRequirement: 1,
    rank: 2,
    totalXp: 0,
    members: [],
  },
  {
    id: "tribe_fitness_guilds",
    name: "Fitness Guilds",
    description:
      "Building physical vitality, endurance, and strength together. Every workout is a vote for your identity as an Athlete.",
    imageUrl:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuAcblAAnG3M4wmuLF9ZQ8PcI3vpkkp-Tsb9lPuwS3R9yyoz9p-9RzXs7SEnt-xumWZXp5M6ezwTrS7kdGjT_J5wxc5FJSVdFWFo8C_X_BEw89X-ADBiEMfX5WwTw3BgEvC5lPrczPdMpAiA5khGBQKAw-Wjspg94vy1I0Vomf6HklnNjg7NdPFWfylP5gxFDLqP-mV8MM8ch2D_j95CEZ03Cb48pHa87E9BV68ZUDoQQRHgsDfefC_MYIFgE28uPzaRJFxSreS0tZk",
    memberCount: 0,
    ownerId: "admin",
    tags: ["Fitness", "Strength", "Vitality"],
    levelRequirement: 1,
    rank: 3,
    totalXp: 0,
    members: [],
  },
  {
    id: "tribe_plant_based_parents",
    name: "Plant-Based Parents",
    description:
      "Parents building healthy eating habits for themselves and their families. Share recipes, tips, and support.",
    imageUrl:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuCL4J9tsC-b5pwJGqxpGob7_-OkXHHv9dtL8P0XxMsL7FdqL9VnQzh8sU5wduI8XNiXnbz1PCsCCBXJzRqSyZPKm4cG4YXA24-a3ipyODG4a31uLncKAJkuVo3f70_-r3k4uYdgeSduK7Q5olfcgWpyA7gwbOFkyzDFtw1vKhBTu2wp-FiouVWnFKbOnTe2iE5K0xKdu-9SLaGNAYnn19aFnbJAxDMiGa_7sbQWynEOkHn3FS0h0ttwuAeV_uKEN3S5FbtrqIrbnh8",
    memberCount: 0,
    ownerId: "admin",
    tags: ["Nutrition", "Family", "Health"],
    levelRequirement: 1,
    rank: 4,
    totalXp: 0,
    members: [],
  },
];

// ============================================================================
// CHALLENGES DATA
// ============================================================================
const challenges = [
  {
    id: "challenge_30_day_running",
    title: "30-Day Running Streak",
    description:
      "Build a consistent running habit. Complete 30 days of running to earn your Runner badge.",
    imageUrl:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuDOh_utD3m3xlwj_lio5W-29cxexZgkN2h28IwWvfeMCbW6mFb2mf4R2hxpgLTqZoyjc5GMat3j2885Y_ZNMHxjHP5Hz45ARtDAD14ZRPtB--_peel9PvIq9NIzXOrbCu4gZhcVHfPUY9oWKFi0xMk-yHoab6iZFuFu44jBOcp7V_17aH8Dt4g7ZoqIAk6nMY9ghnlJdUPFrttCNe6ZocpOvxgxtDCXy_6w062COFol-Ehw2GgYkzVp2cG9yRW9VOtrN8mscbeIY0o",
    reward: "Runner Badge + 750 XP",
    participants: 0,
    totalDays: 30,
    currentDay: 0,
    status: "active",
    xpReward: 750,
    isFeatured: true,
    isTeamChallenge: false,
    category: "Fitness",
    steps: [
      { day: 1, title: "First Run", description: "Complete your first run", isCompleted: false },
      { day: 10, title: "10-Day Milestone", description: "Building momentum!", isCompleted: false },
      { day: 20, title: "20-Day Milestone", description: "Almost there!", isCompleted: false },
      { day: 30, title: "Runner Identity", description: "You ARE a runner now!", isCompleted: false },
    ],
  },
  {
    id: "challenge_21_day_meditation",
    title: "21-Day Meditation Quest",
    description:
      "Build a meditation practice. 21 days of daily meditation to unlock inner peace.",
    imageUrl:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuCodTUg4WyK3YvCqWVf4ApHDNFGSNFSqtJE_GxnttuProcXtP9wjNwWcMyJGUOIbB5HIh5CdNswcArwjXOUKsYtPrEyMeenKVR7cU56R7YEtIxrvSSjqQyGJeHW8-7r0ECmPbjEAn3344G2BB5Ti74Z6Uti3uPfy0sZaMd33pwrpVY9_pUsms407N66K9opRXoMHYC_yuvD31j0t1J2yuOTO1bCKmwgw7Roe9LnzveZVGHZtzb6gFSDlVtEnDOQsGgHsQkyeQFEpRg",
    reward: "Mindful Master Badge + 500 XP",
    participants: 0,
    totalDays: 21,
    currentDay: 0,
    status: "active",
    xpReward: 500,
    isFeatured: true,
    isTeamChallenge: false,
    category: "Mindfulness",
    steps: [
      { day: 1, title: "Begin", description: "5 minutes of breathing", isCompleted: false },
      { day: 7, title: "Week 1", description: "Increase to 10 minutes", isCompleted: false },
      { day: 14, title: "Halfway", description: "Try unguided meditation", isCompleted: false },
      { day: 21, title: "Mindful Master", description: "Practice established!", isCompleted: false },
    ],
  },
  {
    id: "challenge_reading_chain",
    title: "30-Day Reading Chain",
    description:
      "Build a consistent reading habit. Read every day for 30 days.",
    imageUrl:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuAlYY5nIOTy52ymmpwrZBmawmFk9qQyO48K1Jf9NjS_2OAswlnFmRKDbc8tyINedp5K8UMtwNEdv0YmhvOez54Rp8B_zfIcRBFnu9pLscU6ax3o2M9Ny6ILlG_V3qu-VyOYlCdRhaF0fuLefQdl7PnSCSV_vaNKcrpA_ykmv1kPzJKYRSdnwMWpL3T8w0AaW-KGNejNGwSB9ruiJm3VytwssiajjMqtqgvHt4wKu-hEGMWEyp-M9hZw0bnPTxgOpJFIN-eWN5pjUsE",
    reward: "Scholar Badge + 600 XP",
    participants: 0,
    totalDays: 30,
    currentDay: 0,
    status: "active",
    xpReward: 600,
    isFeatured: true,
    isTeamChallenge: false,
    category: "Learning",
    steps: [
      { day: 1, title: "Open the Book", description: "Read your first 10 pages", isCompleted: false },
      { day: 10, title: "100 Pages", description: "Making progress!", isCompleted: false },
      { day: 20, title: "200 Pages", description: "Habit is sticking", isCompleted: false },
      { day: 30, title: "Scholar Status", description: "300 pages conquered!", isCompleted: false },
    ],
  },
  {
    id: "challenge_deep_work",
    title: "14-Day Deep Work Sprint",
    description:
      "Master focused, distraction-free work. Complete 2-hour deep work blocks daily.",
    imageUrl: "https://images.unsplash.com/photo-1497032628192-86f99bcd76bc?w=400",
    reward: "Focus Master Badge + 500 XP",
    participants: 0,
    totalDays: 14,
    currentDay: 0,
    status: "active",
    xpReward: 500,
    isFeatured: true,
    isTeamChallenge: false,
    category: "Productivity",
    steps: [
      { day: 1, title: "No Distractions", description: "First 2-hour block", isCompleted: false },
      { day: 7, title: "Week 1 Done", description: "14 hours of deep work!", isCompleted: false },
      { day: 14, title: "Focus Master", description: "28 hours achieved!", isCompleted: false },
    ],
  },
];

// ============================================================================
// SEEDING FUNCTIONS
// ============================================================================

async function seedTribes(): Promise<void> {
  console.log("Seeding tribes...");
  const batch = db.batch();

  for (const tribe of tribes) {
    const docRef = db.collection("tribes").doc(tribe.id);
    batch.set(docRef, {
      ...tribe,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  console.log(`✓ Seeded ${tribes.length} tribes`);
}

async function seedChallenges(): Promise<void> {
  console.log("Seeding challenges...");
  const batch = db.batch();

  for (const challenge of challenges) {
    const docRef = db.collection("challenges").doc(challenge.id);
    batch.set(docRef, {
      ...challenge,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  console.log(`✓ Seeded ${challenges.length} challenges`);
}

async function seedAll(): Promise<void> {
  console.log("=".repeat(60));
  console.log("Firebase Admin SDK - Seeding Firestore");
  console.log("=".repeat(60));

  try {
    await seedTribes();
    await seedChallenges();

    console.log("=".repeat(60));
    console.log("✓ All seed data created successfully!");
    console.log("=".repeat(60));
  } catch (error) {
    console.error("✗ Seeding failed:", error);
    process.exit(1);
  }

  process.exit(0);
}

// Run seeding
seedAll();
