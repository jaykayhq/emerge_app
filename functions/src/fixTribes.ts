import * as admin from "firebase-admin";

const PROJECT_ID = "tradeflash-l2966";

admin.initializeApp({
  projectId: PROJECT_ID,
});
const db = admin.firestore();

const clubMap: Record<string, string> = {
  athlete: 'morning_warriors',
  scholar: 'deep_work_society',
  stoic: 'mindful_masters',
  creator: 'creative_collective',
  zealot: 'lunar_seekers',
  mystic: 'lunar_seekers',
};

async function fixTribes(): Promise<void> {
  console.log("Starting tribe cleanup...");
  
  // 1. Reset official club member lists and counts
  const officialClubs = Object.values(clubMap);
  for (const clubId of officialClubs) {
    const docRef = db.collection("tribes").doc(clubId);
    try {
      await docRef.update({
        members: [],
        memberCount: 0,
      });
    } catch (e) {
      console.log(`Tribe ${clubId} not found, skipping reset.`);
    }
  }

  // 2. Scan all user profiles
  const usersSnapshot = await db.collection("users").get();
  let updatedCount = 0;

  for (const doc of usersSnapshot.docs) {
    const userData = doc.data();
    const archetype = userData.archetype;
    const userId = doc.id;

    if (archetype && archetype !== "none") {
      const clubId = clubMap[archetype.toLowerCase()] || `${archetype}_club`;
      
      const tribeRef = db.collection('tribes').doc(clubId);
      const tribeDoc = await tribeRef.get();

      if (tribeDoc.exists) {
        // Add member logic
        await tribeRef.update({
          members: admin.firestore.FieldValue.arrayUnion(userId),
          memberCount: admin.firestore.FieldValue.increment(1)
        });

        // Add user-tribe doc
        const userTribeRef = db.collection('users').doc(userId).collection('tribes').doc(clubId);
        await userTribeRef.set({ joinedAt: admin.firestore.FieldValue.serverTimestamp() });

        updatedCount++;
      }
    }
  }

  console.log(`✓ Tribe cleanup finished. Added ${updatedCount} users to their official clubs.`);
  process.exit(0);
}

fixTribes().catch(console.error);
