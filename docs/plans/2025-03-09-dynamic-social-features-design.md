# Dynamic Social Features — Production Design Document

**Date**: 2025-03-09
**Status**: Approved
**Timeline**: 8 weeks
**Goal**: Transform static social features into fully dynamic, real-time experiences

---

## Executive Summary

The Emerge app has a well-designed architecture with clean separation of concerns, but the social features (Clubs, Challenges, Partners) are largely static with hardcoded data. This design outlines how to make these features production-ready using frontend-driven Firestore updates (no Cloud Functions) and real-time streams.

---

## Architecture Principles

1. **Frontend-First**: All writes happen from the Flutter app — no Cloud Functions for social features
2. **Real-Time Streams**: Use `StreamProvider` for all live data (activities, requests, leaderboards)
3. **Denormalized Writes**: Write to multiple locations in a single transaction for data consistency
4. **Identity-First**: Every action reinforces the user's chosen identity (archetype)

---

## Section 1: Clubs (Archetype-Based) — Real-Time Data

### Data Flow
```
User completes habit (frontend)
    ↓
FirestoreTransaction:
  1. Update habit streak
  2. Add activity entry to tribes/{clubId}/activity
  3. Update user's contributor stats in tribes/{clubId}/contributors/{userId}
    ↓
Real-time listeners automatically refresh UI
```

### New Service: `ClubActivityService`

```dart
class ClubActivityService {
  final FirebaseFirestore _firestore;

  Future<void> logHabitCompletion({
    required String userId,
    required String userName,
    required String habitId,
    required String habitTitle,
    required String archetypeId,
    required int streakDay,
  }) async {
    final clubId = _getClubIdForArchetype(archetypeId);

    await _firestore.runTransaction((tx) async {
      // Write to club activity
      final activityRef = _firestore
          .collection('tribes')
          .doc(clubId)
          .collection('activity')
          .doc();
      tx.set(activityRef, {
        'type': 'habit_complete',
        'userId': userId,
        'userName': userName,
        'habitId': habitId,
        'habitTitle': habitTitle,
        'streakDay': streakDay,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update contributor stats
      final contributorRef = _firestore
          .collection('tribes')
          .doc(clubId)
          .collection('contributors')
          .doc(userId);
      tx.set(contributorRef, {
        'userId': userId,
        'userName': userName,
        'lastActivity': FieldValue.serverTimestamp(),
        'contributionCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    });
  }
}
```

### Firestore Structure
```javascript
tribes/{archetype_club_id}/
  ├── contributors/{userId}
  │   ├── userId: string
  │   ├── userName: string
  │   ├── xp: number
  │   ├── level: number
  │   ├── lastActivity: timestamp
  │   └── contributionCount: number
  └── activity/{activityId}
      ├── type: 'habit_complete' | 'level_up' | 'challenge_complete'
      ├── userId: string
      ├── userName: string
      ├── description: string
      ├── timestamp: timestamp
      └── xp: number
```

---

## Section 2: Challenges — Firestore-Sync & Progress Tracking

### Data Flow
```
User opens Challenges Screen
    ↓
Fetch archetype challenges from ChallengeCatalog (local, fast)
    ↓
Fetch user's active challenges from users/{userId}/challenges (Firestore)
    ↓
On join/create: Write to Firestore
    ↓
On progress update: Update currentDay in user's challenge doc
    ↓
Real-time UI updates via StreamProvider
```

### Key Changes to `FirestoreChallengeRepository`

1. **Seed Global Challenges** (one-time script):
   - Migrate `ChallengeCatalog._templates` → `challenges` collection

2. **Add Progress Validation**:
```dart
Future<void> updateChallengeProgress(
  String userId,
  String challengeId,
  int day,
) async {
  final userChallengeRef = _firestore
      .collection('users')
      .doc(userId)
      .collection('challenges')
      .doc(challengeId);

  await _firestore.runTransaction((tx) async {
    final snapshot = await tx.get(userChallengeRef);
    if (!snapshot.exists) throw Exception('Challenge not found');

    final data = snapshot.data()!;
    final totalDays = data['totalDays'] as int;
    final currentDay = data['currentDay'] as int? ?? 0;

    if (day > totalDays) {
      throw Exception('Cannot exceed total days');
    }

    final isNewDay = day > currentDay;
    final isComplete = day == totalDays;

    tx.update(userChallengeRef, {
      'currentDay': day,
      if (isComplete) 'status': ChallengeStatus.completed.name,
      if (isComplete) 'completedAt': FieldValue.serverTimestamp(),
    });

    // Award XP on completion
    if (isComplete && isNewDay) {
      // Fire XP award event
    }
  });
}
```

---

## Section 3: Partners (Friends) — Real-Time Requests

### Stream Providers to Add

```dart
// friend_provider.dart additions

final pendingPartnerRequestsProvider = StreamProvider.autoDispose<
    List<PartnerRequest>>((ref) {
  final userId = ref.watch(authStateChangesProvider).value?.id;
  if (userId == null) return const Stream.empty();
  final repo = ref.watch(friendRepositoryProvider);
  return repo.watchPendingRequests(userId);
});

final onlinePartnersProvider =
    StreamProvider.autoDispose<List<Friend>>((ref) {
  final userId = ref.watch(authStateChangesProvider).value?.id;
  if (userId == null) return const Stream.empty();
  final repo = ref.watch(friendRepositoryProvider);
  return repo.watchOnlinePartners(userId);
});
```

### Repository Methods to Add

```dart
// FirestoreFriendRepository additions

@override
Stream<List<PartnerRequest>> watchPendingRequests(String userId) {
  return _firestore
      .collection('partner_requests')
      .where('recipientId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PartnerRequest.fromMap(doc.data(), id: doc.id))
          .toList());
}

@override
Stream<List<Friend>> watchOnlinePartners(String userId) {
  return _firestore
      .collection('users')
      .doc(userId)
      .collection('friends')
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Friend.fromMap({...doc.data(), 'id': doc.id}))
          .toList());
}
```

---

## Section 4: Real-Time Leaderboards

### New Repository: `leaderboard_repository.dart`

```dart
abstract class LeaderboardRepository {
  Stream<List<LeaderboardEntry>> watchClubLeaderboard(
    String clubId, {
    int limit = 10,
  });
  Stream<List<LeaderboardEntry>> watchChallengeLeaderboard(
    String challengeId, {
    int limit = 10,
  });
  Future<void> updateUserScore(
    String userId,
    String clubId,
    int newXp,
    String userName,
    int level,
  );
}

class FirestoreLeaderboardRepository implements LeaderboardRepository {
  // Implementation with Firestore streams
}
```

### Firestore Structure
```javascript
leaderboards/{clubId}/
  entries/{userId}
    ├── userId: string
    ├── userName: string
    ├── xp: number
    ├── level: number
    ├── archetype: string
    └── lastUpdated: timestamp
```

---

## Section 5: Global Activity Feed

### Activity Types

| Type | Trigger | Data |
|------|---------|------|
| `habit_complete` | Habit marked done | habitId, habitTitle, streakDay, attribute |
| `level_up` | User levels up | newLevel, totalXp |
| `challenge_complete` | Challenge finished | challengeId, challengeTitle, xpReward |
| `challenge_join` | User joins challenge | challengeId, challengeTitle |
| `streak_milestone` | Streak hits 7, 30, 100 | streakCount |
| `node_claim` | World map node claimed | nodeId, nodeTitle, biome |

### Activity Service

```dart
class ActivityService {
  Future<void> logHabitComplete(Habit habit, int streakDay);
  Future<void> logLevelUp(String userId, int newLevel, String archetypeId);
  Future<void> logChallengeComplete(
      String challengeId, String title, int xp);
  Future<void> logNodeClaim(
      String nodeId, String nodeTitle, String biome);
  Future<void> logStreakMilestone(int streakCount);
}
```

### Firestore Structure
```javascript
activities/{globalActivityId}/
  ├── type: string
  ├── userId: string
  ├── userName: string
  ├── archetypeId: string
  ├── clubId: string
  ├── data: { ... }  // type-specific data
  └── timestamp: timestamp
```

---

## Section 6: Notifications & Online Status

### Online Presence Service

```dart
class OnlinePresenceService {
  Timer? _heartbeatTimer;

  void startHeartbeat(String userId) {
    _updateOnlineStatus(userId, true);

    _heartbeatTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _updateOnlineStatus(userId, true);
    });
  }

  void _updateOnlineStatus(String userId, bool isOnline) {
    _firestore.collection('users').doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
  }
}
```

### Notification Provider

```dart
final notificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final userId = ref.watch(authStateChangesProvider).value?.id;
  if (userId == null) return const Stream.empty();
  return _firestore
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => AppNotification.fromMap(doc.data())).toList());
});
```

---

## Section 7: Level Immersive Screen Fixes

### Challenge Quests Integration

Replace static "Today's Missions" with actual challenge quests:

```dart
Widget _buildHabitSection(BuildContext context, UserProfile profile) {
  final challengesAsync = ref.watch(userChallengesProvider);

  return challengesAsync.when(
    data: (challenges) {
      // Filter challenges matching node's attributes
      final relevantChallenges = challenges.where((c) =>
          c.steps.any((step) => _matchesNodeAttributes(step, node))).toList();

      if (relevantChallenges.isEmpty) {
        return _EmptyMissionsState();
      }

      return _ChallengeQuestsList(
          challenges: relevantChallenges, node: node);
    },
    loading: () => CircularProgressIndicator(),
    error: (_, __) => Text('Failed to load missions'),
  );
}
```

### Dynamic World Health Calculation

```dart
double _calculateWorldHealth(UserProfile profile) {
  // Get habit completion rate for last 7 days
  final completionsLast7Days = /* from user_activity */;
  final baseHealth = completionsLast7Days / 7.0;

  // Apply decay penalty for missed days
  final daysSinceLastActivity = /* calculate */;
  final decayPenalty = daysSinceLastActivity * 0.1;

  // Apply recovery bonus for current streak
  final streakBonus = profile.avatarStats.streak * 0.02;

  return (baseHealth - decayPenalty + streakBonus).clamp(0.0, 1.0);
}
```

---

## Implementation Timeline (8 Weeks)

| Phase | Duration | Focus |
|-------|----------|-------|
| 1 | Week 1-2 | Club Activity Service, Habit Repository integration, Clubs UI |
| 2 | Week 2-3 | Challenge seeding, progress validation, Challenges UI |
| 3 | Week 3-4 | Partner streams, notifications, online presence |
| 4 | Week 4-5 | Leaderboard repository, XP flow integration |
| 5 | Week 5-6 | Activity feed service, integration points |
| 6 | Week 6-7 | Level screen challenge quests, world health calculator |
| 7 | Week 7 | Visual progression, decay checker |
| 8 | Week 8 | Polish, testing, performance optimization |

---

## Firestore Indexes Required

Add to `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "activities",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "clubId", "order": "ASCENDING"},
        {"fieldPath": "timestamp", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "partner_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "recipientId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "tribes",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "type", "order": "ASCENDING"},
        {"fieldPath": "archetypeId", "order": "ASCENDING"}
      ]
    }
  ]
}
```

---

## Success Criteria

- [ ] All social features use real Firestore data (no hardcoded lists)
- [ ] UI updates in real-time when data changes
- [ ] Leaderboards reflect accurate rankings
- [ ] Activity feeds show actual user actions
- [ ] Partner requests and online status work end-to-end
- [ ] Challenge progress is tracked and persists
- [ ] Level screen shows actual challenge quests
- [ ] World health bar calculates from real data
