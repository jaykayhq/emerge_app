import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

// Helper to access Firestore
const getDb = () => {
  if (admin.apps.length === 0) {
    admin.initializeApp();
  }
  return admin.firestore();
};

const TEMPLATES = [
  // ATHLETE ARCHETYPE
  {
    title: "30-Day Running Streak",
    description: "Run at least 1 mile every day for 30 days.",
    category: "athlete",
    xpReward: 500,
    affiliateLink: "https://nike.com?ref=emerge",
    sponsorName: "Nike Running",
    requirements: {
      type: "habit_completion", habitType: "exercise", days: 30
    },
    priority: 1,
    used: false,
  },
  {
    title: "10K Steps for 7 Days",
    description: "Hit 10,000 steps every day for a week.",
    category: "athlete",
    xpReward: 150,
    affiliateLink: "https://fitbit.com?ref=emerge",
    sponsorName: "Fitbit",
    requirements: {
      type: "steps", count: 10000, days: 7
    },
    priority: 2,
    used: false,
  },
  {
    title: "Cold Plunge Challenge",
    description: "Take a 2-minute cold shower or plunge daily.",
    category: "athlete",
    xpReward: 200,
    affiliateLink: "https://wimhofmethod.com?ref=emerge",
    sponsorName: "Wim Hof",
    requirements: {
      type: "habit_completion", habitType: "cold_exposure", days: 21
    },
    priority: 3,
    used: false,
  },
  {
    title: "HIIT 21-Day Transform",
    description: "Complete a HIIT workout 5 times a week.",
    category: "athlete",
    xpReward: 300,
    affiliateLink: "https://aaptiv.com?ref=emerge",
    sponsorName: "Aaptiv",
    requirements: {
      type: "habit_completion", habitType: "exercise", days: 21
    },
    priority: 4,
    used: false,
  },
  {
    title: "Morning Mobility Week",
    description: "10 minutes of stretching every morning.",
    category: "athlete",
    xpReward: 100,
    affiliateLink: "https://pliability.com?ref=emerge",
    sponsorName: "Pliability",
    requirements: {
      type: "habit_completion", habitType: "mobility", days: 7
    },
    priority: 5,
    used: false,
  },

  // STOIC ARCHETYPE
  {
    title: "30-Day Meditation Streak",
    description: "Meditate for 10 minutes daily.",
    category: "stoic",
    xpReward: 500,
    affiliateLink: "https://headspace.com?ref=emerge",
    sponsorName: "Headspace",
    requirements: {
      type: "habit_completion", habitType: "meditation", days: 30
    },
    priority: 6,
    used: false,
  },
  {
    title: "Journaling for 21 Days",
    description: "Write at least 1 entry per day.",
    category: "stoic",
    xpReward: 300,
    affiliateLink: "https://dayoneapp.com?ref=emerge",
    sponsorName: "Day One",
    requirements: {
      type: "habit_completion", habitType: "journaling", days: 21
    },
    priority: 7,
    used: false,
  },
  {
    title: "Digital Detox Weekend",
    description: "Reduce screen time to under 2 hour/day.",
    category: "stoic",
    xpReward: 150,
    affiliateLink: "https://opal.so?ref=emerge",
    sponsorName: "Opal",
    requirements: {
      type: "screen_time", limit: 120, days: 2
    },
    priority: 8,
    used: false,
  },
  {
    title: "Gratitude 14-Day Practice",
    description: "List 3 things you are grateful for daily.",
    category: "stoic",
    xpReward: 200,
    affiliateLink: "https://stoicapp.com?ref=emerge",
    sponsorName: "Stoic",
    requirements: {
      type: "habit_completion", habitType: "gratitude", days: 14
    },
    priority: 9,
    used: false,
  },
  {
    title: "Cold Exposure 7-Day",
    description: "Face the cold daily for resilience.",
    category: "stoic",
    xpReward: 100,
    affiliateLink: "https://wimhofmethod.com?ref=emerge",
    sponsorName: "Wim Hof",
    requirements: {
      type: "habit_completion", habitType: "cold", days: 7
    },
    priority: 10,
    used: false,
  },

  // SCHOLAR ARCHETYPE
  {
    title: "Read 7 Books in 30 Days",
    description: "Read (or listen) to 7 books.",
    category: "scholar",
    xpReward: 500,
    affiliateLink: "https://kindle.amazon.com?ref=emerge",
    sponsorName: "Kindle",
    requirements: {
      type: "habit_completion", habitType: "reading", count: 7
    },
    priority: 11,
    used: false,
  },
  {
    title: "100 Pages a Week",
    description: "Read 100 pages every week.",
    category: "scholar",
    xpReward: 200,
    affiliateLink: "https://blinkist.com?ref=emerge",
    sponsorName: "Blinkist",
    requirements: {
      type: "habit_completion", habitType: "reading", pages: 100
    },
    priority: 12,
    used: false,
  },
  {
    title: "Language Learning Streak",
    description: "Practice a language for 14 days.",
    category: "scholar",
    xpReward: 300,
    affiliateLink: "https://duolingo.com?ref=emerge",
    sponsorName: "Duolingo",
    requirements: {
      type: "habit_completion", habitType: "learning", days: 14
    },
    priority: 13,
    used: false,
  },
  {
    title: "Write 30,000 Words",
    description: "Write daily to reach 30k words.",
    category: "scholar",
    xpReward: 500,
    affiliateLink: "https://ulysses.app?ref=emerge",
    sponsorName: "Ulysses",
    requirements: {
      type: "habit_completion", habitType: "writing", words: 30000
    },
    priority: 14,
    used: false,
  },
  {
    title: "Deep Work 90-Min Blocks",
    description: "Complete 3 deep work sessions per week.",
    category: "scholar",
    xpReward: 250,
    affiliateLink: "https://centered.app?ref=emerge",
    sponsorName: "Centered",
    requirements: {
      type: "habit_completion", habitType: "focus", sessions: 3
    },
    priority: 15,
    used: false,
  },

  // CREATOR ARCHETYPE
  {
    title: "Create Every Day 30",
    description: "Ship one creative artifact daily.",
    category: "creator",
    xpReward: 500,
    affiliateLink: "https://skillshare.com?ref=emerge",
    sponsorName: "Skillshare",
    requirements: {
      type: "habit_completion", habitType: "creation", days: 30
    },
    priority: 16,
    used: false,
  },
  {
    title: "Music Practice 21 Days",
    description: "Practice your instrument daily.",
    category: "creator",
    xpReward: 300,
    affiliateLink: "https://yousician.com?ref=emerge",
    sponsorName: "Yousician",
    requirements: {
      type: "habit_completion", habitType: "practice", days: 21
    },
    priority: 17,
    used: false,
  },
  {
    title: "Code 100 Days",
    description: "Code for at least 30 mins daily.",
    category: "creator",
    xpReward: 1000,
    affiliateLink: "https://codecademy.com?ref=emerge",
    sponsorName: "Codecademy",
    requirements: {
      type: "habit_completion", habitType: "coding", days: 100
    },
    priority: 18,
    used: false,
  },
  {
    title: "Photography Daily",
    description: "Take one photo every day.",
    category: "creator",
    xpReward: 200,
    affiliateLink: "https://adobe.com?ref=emerge",
    sponsorName: "Adobe",
    requirements: {
      type: "habit_completion", habitType: "photography", days: 30
    },
    priority: 19,
    used: false,
  },
  {
    title: "Ship Something",
    description: "Launch a project or post.",
    category: "creator",
    xpReward: 100,
    affiliateLink: "https://producthunt.com?ref=emerge",
    sponsorName: "Product Hunt",
    requirements: {
      type: "habit_completion", habitType: "ship", count: 1
    },
    priority: 20,
    used: false,
  },
];

/**
 * HTTP Trigger: Seeds challenge templates into Firestore.
 * REQUIRES ADMIN AUTHENTICATION
 */
export const seedChallengeTemplates = functions.https.onRequest(
  async (req, res) => {
    // Verify admin authentication via header
    const authHeader = req.get("authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).send("Unauthorized: Missing or invalid Bearer token");
      return;
    }

    const authToken = authHeader.split(" ")[1];
    if (!authToken || authToken !== process.env.ADMIN_SECRET) {
      res.status(403).send("Forbidden: Invalid admin token");
      return;
    }

    const db = getDb();
    const batch = db.batch();

    try {
      for (const template of TEMPLATES) {
        const ref = db.collection("challengeTemplates").doc(); // Auto-ID
        batch.set(ref, {
          ...template,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      res.status(200).send(`Seeded ${TEMPLATES.length} templates.`);
    } catch (error) {
      console.error("Error seeding templates:", error);
      res.status(500).send("Error seeding templates");
    }
  });
