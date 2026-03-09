# Dynamic Social Features Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform static social features (Clubs, Challenges, Partners, Leaderboards) into fully dynamic, real-time experiences using frontend-driven Firestore updates.

**Architecture:** Frontend-first Firestore writes (no Cloud Functions), real-time StreamProvider for all live data, denormalized writes in transactions for consistency, identity-first design reinforcing user's archetype.

**Tech Stack:** Flutter 3.x, Dart, Firestore (cloud_firestore 4.x), Riverpod 3.x, flutter_animate, go_router

---

## Task 1: Create ClubActivityService - Foundation for Club Activity Logging

**Files:**
- Create: `lib/features/social/domain/services/club_activity_service.dart`
- Test: `test/features/social/domain/services/club_activity_service_test.dart`

**Step 1: Write the failing test**

Create test file:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late FirebaseFirestore firestore;
  late ClubActivityService service;

  setUp(() {
    firestore = MockFirestore();
    service = ClubActivityService(firestore);
  });

  group('ClubActivityService.logHabitCompletion', () {
    test('writes activity to tribe activity subcollection', () async {
      // Test implementation
      final result = service.logHabitCompletion(
        userId: 'user123',
        userName: 'Test User',
        habitId: 'habit123',
        habitTitle: 'Morning Meditation',
        archetypeId: 'creator',
        streakDay: 5,
      );

      await expectLater(result, completes);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/domain/services/club_activity_service_test.dart`
Expected: FAIL with "ClubActivityService not found"

**Step 3: Write minimal implementation**

Create `lib/features/social/domain/services/club_activity_service.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for logging user activities to their archetype club
/// All writes happen from frontend - no Cloud Functions
class ClubActivityService {
  final FirebaseFirestore _firestore;

  ClubActivityService(this._firestore);

  /// Get the club ID for a given archetype
  String _getClubIdForArchetype(String archetypeId) {
    // Clubs are named: {archetype}_club
    return '${archetypeId}_club';
  }

  /// Log a habit completion to the club activity feed
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
        'archetype': archetypeId,
      }, SetOptions(merge: true));
    });
  }

  /// Log a level up to the club activity feed
  Future<void> logLevelUp({
    required String userId,
    required String userName,
    required String archetypeId,
    required int newLevel,
    required int totalXp,
  }) async {
    final clubId = _getClubIdForArchetype(archetypeId);

    await _firestore
        .collection('tribes')
        .doc(clubId)
        .collection('activity')
        .add({
      'type': 'level_up',
      'userId': userId,
      'userName': userName,
      'newLevel': newLevel,
      'totalXp': totalXp,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Log challenge completion to the club activity feed
  Future<void> logChallengeComplete({
    required String userId,
    required String userName,
    required String archetypeId,
    required String challengeId,
    required String challengeTitle,
    required int xpReward,
  }) async {
    final clubId = _getClubIdForArchetype(archetypeId);

    await _firestore
        .collection('tribes')
        .doc(clubId)
        .collection('activity')
        .add({
      'type': 'challenge_complete',
      'userId': userId,
      'userName': userName,
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'xpReward': xpReward,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/domain/services/club_activity_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/social/domain/services/club_activity_service.dart
git add test/features/social/domain/services/club_activity_service_test.dart
git commit -m "feat(social): add ClubActivityService for real-time club activity logging"
```

---

## Task 2: Create ClubActivityService Provider

**Files:**
- Create: `lib/features/social/presentation/providers/club_activity_provider.dart`

**Step 1: Create the provider file**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for ClubActivityService
final clubActivityServiceProvider = Provider<ClubActivityService>((ref) {
  return ClubActivityService(FirebaseFirestore.instance);
});

/// Stream provider for club activity feed
/// Returns real-time activity for a specific club
final clubActivityProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, clubId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('tribes')
      .doc(clubId)
      .collection('activity')
      .orderBy('timestamp', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

/// Stream provider for club contributors (leaderboard)
/// Returns real-time top contributors for a specific club
final clubContributorsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, clubId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('tribes')
      .doc(clubId)
      .collection('contributors')
      .orderBy('contributionCount', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});
```

**Step 2: Commit**

```bash
git add lib/features/social/presentation/providers/club_activity_provider.dart
git commit -m "feat(social): add club activity stream providers"
```

---

## Task 3: Integrate ClubActivityService into Habit Completion

**Files:**
- Modify: `lib/features/habits/data/repositories/firestore_habit_repository.dart`
- Modify: `lib/features/habits/data/repositories/firestore_habit_repository.dart:285-310`

**Step 1: Add ClubActivityService dependency**

At the top of the file, add import:
```dart
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
```

**Step 2: Modify the class to accept ClubActivityService**

Update the class:
```dart
class FirestoreHabitRepository implements HabitRepository {
  final FirebaseFirestore _firestore;
  final ClubActivityService? _clubActivityService; // Optional for testing

  FirestoreHabitRepository(
    this._firestore, [
    this._clubActivityService,
  ]);
```

**Step 3: Update the provider to pass ClubActivityService**

Modify `lib/features/habits/presentation/providers/habit_providers.dart`:
```dart
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final clubActivityService = ref.watch(clubActivityServiceProvider);
  return FirestoreHabitRepository(firestore, clubActivityService);
});
```

**Step 4: Call activity service on habit completion**

In `completeHabit` method, after the transaction succeeds (around line 309), add:

```dart
// Log activity to club if service is available
if (completionData != null && _clubActivityService != null) {
  final uid = completionData['userId'] as String;
  final habitTitle = completionData['habitTitle'] as String? ?? 'Habit';
  final streakDay = completionData['streakDay'] as int? ?? 1;

  // Get user's archetype from user doc (cached or fetch)
  try {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final archetype = userDoc.data()?['archetype'] ?? 'creator';

    await _clubActivityService!.logHabitCompletion(
      userId: uid,
      userName: userDoc.data()?['displayName'] ?? 'User',
      habitId: habitId,
      habitTitle: habitTitle,
      archetypeId: archetype,
      streakDay: streakDay,
    );
  } catch (e) {
    // Don't fail habit completion if activity logging fails
    AppLogger.w('Failed to log club activity: $e');
  }
}
```

**Step 5: Commit**

```bash
git add lib/features/habits/data/repositories/firestore_habit_repository.dart
git add lib/features/habits/presentation/providers/habit_providers.dart
git commit -m "feat(habits): integrate club activity logging on habit completion"
```

---

## Task 4: Wire CommunityScreen to Real-Time Data

**Files:**
- Modify: `lib/features/social/presentation/screens/community_screen.dart:365-423`

**Step 1: Replace hardcoded contributors section**

Find `_ContributorsSection` class and replace with:

```dart
class _ContributorsSection extends ConsumerWidget {
  const _ContributorsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userStatsStreamProvider);

    return profileAsync.when(
      data: (profile) {
        final clubId = '${profile.archetype.name}_club';
        final contributorsAsync = ref.watch(clubContributorsProvider(clubId));

        return contributorsAsync.when(
          data: (contributors) {
            if (contributors.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Top Contributors',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'View All >',
                      style: TextStyle(fontSize: 12, color: EmergeColors.teal),
                    ),
                  ],
                ),
                const Gap(16),

                // Contributors row
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: contributors.length,
                    itemBuilder: (context, index) {
                      final c = contributors[index];
                      return Transform.translate(
                        offset: Offset(index == 0 ? 0 : -index * 15.0, 0),
                        child: _ContributorAvatar(
                          name: c['userName'] ?? 'User',
                          xp: c['contributionCount'] ?? 0,
                          isOnline: false, // TODO: Add online status
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(color: EmergeColors.teal)),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

**Step 2: Update _ContributorAvatar to accept XP**

Modify the widget:
```dart
class _ContributorAvatar extends StatelessWidget {
  final String name;
  final int xp;
  final bool isOnline;

  const _ContributorAvatar({
    required this.name,
    required this.xp,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    EmergeColors.violet.withValues(alpha: 0.6),
                    EmergeColors.teal.withValues(alpha: 0.4),
                  ],
                ),
                border: Border.all(color: EmergeColors.background, width: 3),
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: EmergeColors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: EmergeColors.background,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Gap(4),
        Text(
          '+$xp XP',
          style: TextStyle(
            fontSize: 9,
            color: EmergeColors.teal,
          ),
        ),
      ],
    );
  }
}
```

**Step 3: Replace hardcoded activity section**

Find `_ActivitySection` class and replace with:

```dart
class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userStatsStreamProvider);

    return profileAsync.when(
      data: (profile) {
        final clubId = '${profile.archetype.name}_club';
        final activityAsync = ref.watch(clubActivityProvider(clubId));

        return activityAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Gap(16),

                ...activities.take(10).map((activity) {
                  return _ActivityTile(activity: activity);
                }),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(color: EmergeColors.teal)),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final type = activity['type'] as String?;
    final icon = _getIconForType(type);
    final text = _getTextForActivity(activity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const Gap(12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          if (activity['timestamp'] != null)
            Text(
              _formatTime(activity['timestamp']),
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryDark.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  String _getIconForType(String? type) {
    switch (type) {
      case 'habit_complete':
        return '✅';
      case 'level_up':
        return '🎖️';
      case 'challenge_complete':
        return '🏆';
      default:
        return '📌';
    }
  }

  String _getTextForActivity(Map<String, dynamic> activity) {
    final type = activity['type'] as String?;
    final userName = activity['userName'] as String? ?? 'Someone';

    switch (type) {
      case 'habit_complete':
        final habitTitle = activity['habitTitle'] as String? ?? 'a habit';
        final streakDay = activity['streakDay'] as int? ?? 1;
        return '$userName completed $habitTitle (Day $streakDay)';
      case 'level_up':
        final level = activity['newLevel'] as int? ?? 1;
        return '$userName reached Level $level!';
      case 'challenge_complete':
        final title = activity['challengeTitle'] as String? ?? 'a challenge';
        return '$userName completed $title';
      default:
        return '$userName did something amazing';
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final now = DateTime.now();
      final time = timestamp.toDate();
      final diff = now.difference(time);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return '';
  }
}
```

**Step 4: Commit**

```bash
git add lib/features/social/presentation/screens/community_screen.dart
git commit -m "feat(social): wire CommunityScreen to real-time club data"
```

---

## Task 5: Add Stream Methods to FriendRepository

**Files:**
- Modify: `lib/features/social/data/repositories/friend_repository.dart`
- Modify: `lib/features/social/data/repositories/friend_repository.dart:189-204`

**Step 1: Add stream methods to interface**

Update the abstract class:
```dart
abstract class FriendRepository {
  Future<List<Friend>> getFriends(String userId);
  Future<void> addFriend(String userId, String friendId);
  Future<void> removeFriend(String userId, String friendId);
  Future<void> sendPartnerRequest(...);

  // NEW: Stream methods
  Stream<List<PartnerRequest>> watchPendingRequests(String userId);
  Stream<List<Friend>> watchOnlinePartners(String userId);
}
```

**Step 2: Implement stream methods in FirestoreFriendRepository**

Add at the end of the class:
```dart
@override
Stream<List<PartnerRequest>> watchPendingRequests(String userId) {
  return _firestore
      .collection('partner_requests')
      .where('recipientId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return PartnerRequest(
        id: doc.id,
        senderId: data['senderId'] as String,
        senderName: data['senderName'] as String? ?? 'Unknown',
        senderArchetype: data['senderArchetype'] as String? ?? 'creator',
        senderLevel: data['senderLevel'] as int? ?? 1,
        status: _parseRequestStatus(data['status'] as String? ?? 'pending'),
        createdAt: data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    }).toList();
  });
}

@override
Stream<List<Friend>> watchOnlinePartners(String userId) {
  return _firestore
      .collection('users')
      .doc(userId)
      .collection('friends')
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Friend.fromMap(data);
    }).toList();
  });
}

RequestStatus _parseRequestStatus(String status) {
  switch (status) {
    case 'pending':
      return RequestStatus.pending;
    case 'accepted':
      return RequestStatus.accepted;
    case 'rejected':
      return RequestStatus.rejected;
    default:
      return RequestStatus.pending;
  }
}
```

**Step 3: Commit**

```bash
git add lib/features/social/data/repositories/friend_repository.dart
git commit -m "feat(social): add stream methods for partner requests and online status"
```

---

## Task 6: Add Stream Providers for Friends

**Files:**
- Create: `lib/features/social/presentation/providers/friend_stream_provider.dart`

**Step 1: Create the stream provider file**

```dart
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/data/repositories/friend_repository.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream provider for pending partner requests
final pendingPartnerRequestsProvider =
    StreamProvider.autoDispose<List<PartnerRequest>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) return const Stream.empty();

  final repo = ref.watch(friendRepositoryProvider);
  return repo.watchPendingRequests(user.id);
});

/// Stream provider for online partners
final onlinePartnersProvider =
    StreamProvider.autoDispose<List<Friend>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) return const Stream.empty();

  final repo = ref.watch(friendRepositoryProvider);
  return repo.watchOnlinePartners(user.id);
});
```

**Step 2: Export from barrel file**

Add to `lib/features/social/presentation/providers/social_providers.dart`:
```dart
export 'friend_stream_provider.dart';
```

**Step 3: Commit**

```bash
git add lib/features/social/presentation/providers/friend_stream_provider.dart
git add lib/features/social/presentation/providers/social_providers.dart
git commit -m "feat(social): add stream providers for partner requests and online friends"
```

---

## Task 7: Wire FriendsScreen to Real-Time Data

**Files:**
- Modify: `lib/features/social/presentation/screens/friends_screen.dart:130-170`

**Step 1: Replace static sections with provider-based widgets**

Find the sliver sections and replace:

```dart
// Active Partners Section
SliverToBoxAdapter(
  child: _OnlinePartnersSection(),
),

const SliverToBoxAdapter(child: Gap(24)),

// Partner Requests Section
SliverToBoxAdapter(
  child: _PartnerRequestsSection(),
),
```

**Step 2: Add the widget implementations**

Add these widget classes at the end of the file:

```dart
class _OnlinePartnersSection extends ConsumerWidget {
  const _OnlinePartnersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlinePartnersAsync = ref.watch(onlinePartnersProvider);

    return onlinePartnersAsync.when(
      data: (partners) {
        if (partners.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Online Now (${partners.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Gap(12),
            SizedBox(
              height: 70,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: partners.length,
                itemBuilder: (context, index) {
                  final partner = partners[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _OnlinePartnerAvatar(partner: partner),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 70,
        child: Center(child: CircularProgressIndicator(color: EmergeColors.teal)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _OnlinePartnerAvatar extends StatelessWidget {
  final Friend partner;

  const _OnlinePartnerAvatar({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    EmergeColors.teal.withValues(alpha: 0.6),
                    EmergeColors.violet.withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  partner.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: EmergeColors.teal,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
          ],
        ),
        const Gap(4),
        Text(
          partner.name,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PartnerRequestsSection extends ConsumerWidget {
  const _PartnerRequestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingPartnerRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Pending Requests (${requests.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Gap(12),
            ...requests.map((request) => _PartnerRequestCard(request: request)),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: EmergeColors.teal)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PartnerRequestCard extends ConsumerWidget {
  final PartnerRequest request;

  const _PartnerRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getArchetypeColor(request.senderArchetype).withValues(alpha: 0.3),
            ),
            child: Center(
              child: Text(
                request.senderName[0].toUpperCase(),
                style: TextStyle(
                  color: _getArchetypeColor(request.senderArchetype),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.senderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Level ${request.senderLevel} ${request.senderArchetype}',
                  style: TextStyle(
                    color: _getArchetypeColor(request.senderArchetype),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _acceptRequest(context, ref, request.id),
            icon: const Icon(Icons.check_circle, color: EmergeColors.teal),
          ),
          IconButton(
            onPressed: () => _rejectRequest(context, ref, request.id),
            icon: const Icon(Icons.cancel, color: EmergeColors.coral),
          ),
        ],
      ),
    );
  }

  Color _getArchetypeColor(String archetype) {
    switch (archetype.toLowerCase()) {
      case 'athlete':
        return const Color(0xFFFF5252);
      case 'scholar':
        return const Color(0xFF7C3AED);
      case 'creator':
        return const Color(0xFFFFD700);
      case 'stoic':
        return const Color(0xFF26A69A);
      default:
        return Colors.grey;
    }
  }

  Future<void> _acceptRequest(BuildContext context, WidgetRef ref, String requestId) async {
    try {
      await ref.read(friendRepositoryProvider).acceptPartnerRequest(requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partner request accepted!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(BuildContext context, WidgetRef ref, String requestId) async {
    try {
      await ref.read(friendRepositoryProvider).rejectPartnerRequest(requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partner request rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e')),
        );
      }
    }
  }
}
```

**Step 3: Commit**

```bash
git add lib/features/social/presentation/screens/friends_screen.dart
git commit -m "feat(social): wire FriendsScreen to real-time partner requests and online status"
```

---

## Task 8: Create LeaderboardRepository

**Files:**
- Create: `lib/features/social/data/repositories/leaderboard_repository.dart`
- Create: `lib/features/social/domain/repositories/leaderboard_repository.dart`

**Step 1: Create domain interface**

Create `lib/features/social/domain/repositories/leaderboard_repository.dart`:
```dart
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';

abstract class LeaderboardRepository {
  /// Watch club leaderboard stream
  Stream<List<LeaderboardEntry>> watchClubLeaderboard(
    String clubId, {
    int limit = 10,
  });

  /// Watch challenge leaderboard stream
  Stream<List<LeaderboardEntry>> watchChallengeLeaderboard(
    String challengeId, {
    int limit = 10,
  });

  /// Update user's score on leaderboard
  Future<void> updateUserScore({
    required String userId,
    required String clubId,
    required int newXp,
    required String userName,
    required int level,
    required String archetype,
  });
}
```

**Step 2: Create entity**

Create `lib/features/social/domain/entities/leaderboard_entry.dart`:
```dart
class LeaderboardEntry {
  final String userId;
  final String userName;
  final int xp;
  final int level;
  final String archetype;
  final int rank;
  final DateTime lastUpdated;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.xp,
    required this.level,
    required this.archetype,
    required this.lastUpdated,
  }) : rank = 0; // Will be calculated

  LeaderboardEntry withRank(int rank) {
    return LeaderboardEntry(
      userId: userId,
      userName: userName,
      xp: xp,
      level: level,
      archetype: archetype,
      lastUpdated: lastUpdated,
    )..rank = rank;
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] as String,
      userName: map['userName'] as String? ?? 'Anonymous',
      xp: map['xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      archetype: map['archetype'] as String? ?? 'creator',
      lastUpdated: map['lastUpdated'] is Timestamp
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'xp': xp,
      'level': level,
      'archetype': archetype,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
```

**Step 3: Create Firestore implementation**

Create `lib/features/social/data/repositories/leaderboard_repository.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';

class FirestoreLeaderboardRepository implements LeaderboardRepository {
  final FirebaseFirestore _firestore;

  FirestoreLeaderboardRepository(this._firestore);

  @override
  Stream<List<LeaderboardEntry>> watchClubLeaderboard(
    String clubId, {
    int limit = 10,
  }) {
    return _firestore
        .collection('leaderboards')
        .doc(clubId)
        .collection('entries')
        .orderBy('xp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs.map((doc) {
        final data = doc.data();
        data['userId'] = doc.id;
        return LeaderboardEntry.fromMap(data);
      }).toList();

      // Add ranks
      return entries.asMap().entries.map((entry) {
        return entry.value.withRank(entry.key + 1);
      }).toList();
    });
  }

  @override
  Stream<List<LeaderboardEntry>> watchChallengeLeaderboard(
    String challengeId, {
    int limit = 10,
  }) {
    return _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('participants')
        .orderBy('xp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs.map((doc) {
        final data = doc.data();
        data['userId'] = doc.id;
        return LeaderboardEntry.fromMap(data);
      }).toList();

      return entries.asMap().entries.map((entry) {
        return entry.value.withRank(entry.key + 1);
      }).toList();
    });
  }

  @override
  Future<void> updateUserScore({
    required String userId,
    required String clubId,
    required int newXp,
    required String userName,
    required int level,
    required String archetype,
  }) async {
    try {
      await _firestore
          .collection('leaderboards')
          .doc(clubId)
          .collection('entries')
          .doc(userId)
          .set({
            'userId': userId,
            'userName': userName,
            'xp': newXp,
            'level': level,
            'archetype': archetype,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e, s) {
      AppLogger.e('Failed to update leaderboard score', e, s);
      rethrow;
    }
  }
}
```

**Step 4: Add provider**

Create `lib/features/social/presentation/providers/leaderboard_provider.dart`:
```dart
import 'package:emerge_app/features/social/data/repositories/leaderboard_repository.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return FirestoreLeaderboardRepository(FirebaseFirestore.instance);
});

/// Club leaderboard stream provider
final clubLeaderboardProvider =
    StreamProvider.family<List<LeaderboardEntry>, String>((ref, clubId) {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.watchClubLeaderboard(clubId);
});

/// Challenge leaderboard stream provider
final challengeLeaderboardProvider =
    StreamProvider.family<List<LeaderboardEntry>, String>((ref, challengeId) {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.watchChallengeLeaderboard(challengeId);
});
```

**Step 5: Commit**

```bash
git add lib/features/social/domain/entities/leaderboard_entry.dart
git add lib/features/social/domain/repositories/leaderboard_repository.dart
git add lib/features/social/data/repositories/leaderboard_repository.dart
git add lib/features/social/presentation/providers/leaderboard_provider.dart
git commit -m "feat(social): add leaderboard repository and providers"
```

---

## Task 9: Integrate Leaderboard Updates into XP Flow

**Files:**
- Modify: `lib/features/gamification/data/repositories/firestore_gamification_repository.dart:120-195`

**Step 1: Add LeaderboardRepository dependency**

Add import:
```dart
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
```

**Step 2: Update constructor**

```dart
class FirestoreGamificationRepository implements GamificationRepository {
  final FirebaseFirestore _firestore;
  final LeaderboardRepository? _leaderboardRepository;

  FirestoreGamificationRepository(
    this._firestore, [
    this._leaderboardRepository,
  ]);
```

**Step 3: Update addXp method to write to leaderboard**

After the XP update in the transaction, add:

```dart
// Update leaderboard if repository is available
if (_leaderboardRepository != null && attributeName != null) {
  // Get user data for leaderboard
  final userDoc = await _firestore.collection('users').doc(userId).get();
  final userData = userDoc.data();

  if (userData != null) {
    final clubId = '${userData['archetype'] ?? 'creator'}_club';

    try {
      await _leaderboardRepository!.updateUserScore(
        userId: userId,
        clubId: clubId,
        newXp: totalXp,
        userName: userData['displayName'] ?? 'User',
        level: avatarStats['level'] ?? 1,
        archetype: userData['archetype'] ?? 'creator',
      );
    } catch (e) {
      // Don't fail XP update if leaderboard fails
      AppLogger.w('Failed to update leaderboard: $e');
    }
  }
}
```

**Step 4: Commit**

```bash
git add lib/features/gamification/data/repositories/firestore_gamification_repository.dart
git commit -m "feat(gamification): integrate leaderboard updates on XP gain"
```

---

## Task 10: Create Global Activity Service

**Files:**
- Create: `lib/features/social/domain/services/global_activity_service.dart`
- Create: `lib/features/social/domain/entities/activity.dart`

**Step 1: Create activity entity**

Create `lib/features/social/domain/entities/activity.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  habitComplete,
  levelUp,
  challengeComplete,
  challengeJoin,
  streakMilestone,
  nodeClaim,
}

class Activity {
  final String id;
  final ActivityType type;
  final String userId;
  final String userName;
  final String archetypeId;
  final String clubId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    required this.archetypeId,
    required this.clubId,
    required this.data,
    required this.timestamp,
  });

  factory Activity.fromMap(Map<String, dynamic> map, String id) {
    return Activity(
      id: id,
      type: _parseType(map['type'] as String? ?? ''),
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      archetypeId: map['archetypeId'] as String,
      clubId: map['clubId'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'archetypeId': archetypeId,
      'clubId': clubId,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static ActivityType _parseType(String type) {
    return ActivityType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => ActivityType.habitComplete,
    );
  }
}
```

**Step 2: Create global activity service**

Create `lib/features/social/domain/services/global_activity_service.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/domain/entities/activity.dart';

/// Centralized service for logging all user activities
/// Writes to both global activities collection and club-specific activity feeds
class GlobalActivityService {
  final FirebaseFirestore _firestore;

  GlobalActivityService(this._firestore);

  /// Get club ID from archetype
  String _getClubId(String archetypeId) {
    return '${archetypeId}_club';
  }

  /// Write activity to both global and club collections
  Future<void> _logActivity(Activity activity) async {
    try {
      await _firestore.runTransaction((tx) async {
        // Write to global activities
        final globalRef = _firestore.collection('activities').doc();
        tx.set(globalRef, activity.toMap());

        // Write to club activity
        final clubRef = _firestore
            .collection('tribes')
            .doc(activity.clubId)
            .collection('activity')
            .doc();
        tx.set(clubRef, activity.toMap());
      });
    } catch (e, s) {
      AppLogger.e('Failed to log activity', e, s);
      rethrow;
    }
  }

  /// Log habit completion
  Future<void> logHabitComplete({
    required String userId,
    required String userName,
    required String archetypeId,
    required String habitId,
    required String habitTitle,
    required int streakDay,
    required String attribute,
  }) async {
    final activity = Activity(
      id: '', // Generated by Firestore
      type: ActivityType.habitComplete,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'habitId': habitId,
        'habitTitle': habitTitle,
        'streakDay': streakDay,
        'attribute': attribute,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }

  /// Log level up
  Future<void> logLevelUp({
    required String userId,
    required String userName,
    required String archetypeId,
    required int newLevel,
    required int totalXp,
  }) async {
    final activity = Activity(
      id: '',
      type: ActivityType.levelUp,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'newLevel': newLevel,
        'totalXp': totalXp,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }

  /// Log challenge completion
  Future<void> logChallengeComplete({
    required String userId,
    required String userName,
    required String archetypeId,
    required String challengeId,
    required String challengeTitle,
    required int xpReward,
  }) async {
    final activity = Activity(
      id: '',
      type: ActivityType.challengeComplete,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'challengeId': challengeId,
        'challengeTitle': challengeTitle,
        'xpReward': xpReward,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }

  /// Log challenge join
  Future<void> logChallengeJoin({
    required String userId,
    required String userName,
    required String archetypeId,
    required String challengeId,
    required String challengeTitle,
  }) async {
    final activity = Activity(
      id: '',
      type: ActivityType.challengeJoin,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'challengeId': challengeId,
        'challengeTitle': challengeTitle,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }

  /// Log streak milestone
  Future<void> logStreakMilestone({
    required String userId,
    required String userName,
    required String archetypeId,
    required int streakCount,
  }) async {
    final activity = Activity(
      id: '',
      type: ActivityType.streakMilestone,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'streakCount': streakCount,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }

  /// Log node claim
  Future<void> logNodeClaim({
    required String userId,
    required String userName,
    required String archetypeId,
    required String nodeId,
    required String nodeTitle,
    required String biome,
  }) async {
    final activity = Activity(
      id: '',
      type: ActivityType.nodeClaim,
      userId: userId,
      userName: userName,
      archetypeId: archetypeId,
      clubId: _getClubId(archetypeId),
      data: {
        'nodeId': nodeId,
        'nodeTitle': nodeTitle,
        'biome': biome,
      },
      timestamp: DateTime.now(),
    );

    await _logActivity(activity);
  }
}
```

**Step 3: Create provider**

Create `lib/features/social/presentation/providers/global_activity_provider.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/entities/activity.dart';
import 'package:emerge_app/features/social/domain/services/global_activity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final globalActivityServiceProvider = Provider<GlobalActivityService>((ref) {
  return GlobalActivityService(FirebaseFirestore.instance);
});

/// Global activity feed stream
final globalActivityProvider =
    StreamProvider.autoDispose<List<Activity>>((ref) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('activities')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) =>
          Activity.fromMap(doc.data(), doc.id)).toList());
});

/// Club-specific activity feed stream
final clubActivityFeedProvider =
    StreamProvider.family<List<Activity>, String>((ref, clubId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('activities')
      .where('clubId', isEqualTo: clubId)
      .orderBy('timestamp', descending: true)
      .limit(30)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) =>
          Activity.fromMap(doc.data(), doc.id)).toList());
});
```

**Step 4: Commit**

```bash
git add lib/features/social/domain/entities/activity.dart
git add lib/features/social/domain/services/global_activity_service.dart
git add lib/features/social/presentation/providers/global_activity_provider.dart
git commit -m "feat(social): add global activity service for centralized activity logging"
```

---

## Task 11: Integrate GlobalActivityService into Key Events

**Files:**
- Modify: `lib/features/habits/data/repositories/firestore_habit_repository.dart:285-320`
- Modify: `lib/features/gamification/data/repositories/firestore_gamification_repository.dart`

**Step 1: Add GlobalActivityService to HabitRepository**

Add import and dependency:
```dart
import 'package:emerge_app/features/social/domain/services/global_activity_service.dart';

class FirestoreHabitRepository implements HabitRepository {
  final FirebaseFirestore _firestore;
  final ClubActivityService? _clubActivityService;
  final GlobalActivityService? _globalActivityService;

  FirestoreHabitRepository(
    this._firestore, [
    this._clubActivityService,
    this._globalActivityService,
  ]);
```

**Step 2: Log to global activity on habit completion**

In `completeHabit` method, after existing activity logging:
```dart
// Log to global activity feed
if (_globalActivityService != null && completionData != null) {
  final uid = completionData['userId'] as String;
  final habitTitle = completionData['habitTitle'] as String? ?? 'Habit';
  final streakDay = completionData['streakDay'] as int? ?? 1;
  final attribute = completionData['attribute'] as String? ?? 'vitality';

  try {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data();

    await _globalActivityService!.logHabitComplete(
      userId: uid,
      userName: userData?['displayName'] ?? 'User',
      archetypeId: userData?['archetype'] ?? 'creator',
      habitId: habitId,
      habitTitle: habitTitle,
      streakDay: streakDay,
      attribute: attribute,
    );
  } catch (e) {
    AppLogger.w('Failed to log global activity: $e');
  }
}
```

**Step 3: Update provider**

Update `habit_providers.dart`:
```dart
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final clubActivityService = ref.watch(clubActivityServiceProvider);
  final globalActivityService = ref.watch(globalActivityServiceProvider);
  return FirestoreHabitRepository(
    firestore,
    clubActivityService,
    globalActivityService,
  );
});
```

**Step 4: Commit**

```bash
git add lib/features/habits/data/repositories/firestore_habit_repository.dart
git add lib/features/habits/presentation/providers/habit_providers.dart
git commit -m "feat(social): integrate global activity logging on habit completion"
```

---

## Task 12: Challenge Progress Validation and Completion

**Files:**
- Modify: `lib/features/social/data/repositories/challenge_repository.dart:114-137`

**Step 1: Add validation to updateProgress**

Replace the existing `updateProgress` method:
```dart
@override
Future<void> updateProgress(
  String userId,
  String challengeId,
  int progress,
) async {
  final userChallengeRef = _firestore
      .collection('users')
      .doc(userId)
      .collection('challenges')
      .doc(challengeId);

  await _firestore.runTransaction((tx) async {
    final snapshot = await tx.get(userChallengeRef);
    if (!snapshot.exists) {
      throw Exception('Challenge not found for user');
    }

    final data = snapshot.data()!;
    final totalDays = data['totalDays'] as int? ?? 30;
    final currentDay = data['currentDay'] as int? ?? 0;

    // Validate progress
    if (progress > totalDays) {
      throw Exception('Cannot exceed total days ($totalDays)');
    }

    // Only allow incrementing by 1 day at a time
    if (progress != currentDay + 1 && progress != currentDay) {
      throw Exception('Can only progress one day at a time');
    }

    final isNewDay = progress > currentDay;
    final isComplete = progress == totalDays;

    tx.update(userChallengeRef, {
      'currentDay': progress,
      if (isComplete) 'status': ChallengeStatus.completed.name,
      if (isComplete) 'completedAt': FieldValue.serverTimestamp(),
    });

    // Update global challenge participant count if completed
    if (isComplete && isNewDay) {
      final globalRef = _firestore.collection('challenges').doc(challengeId);
      tx.set(globalRef, {
        'completersCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
  });
}
```

**Step 2: Add completion with XP reward method**

Add to the repository:
```dart
/// Complete a challenge and award XP
Future<void> completeChallengeWithReward(
  String userId,
  String challengeId,
) async {
  final userChallengeRef = _firestore
      .collection('users')
      .doc(userId)
      .collection('challenges')
      .doc(challengeId);

  await _firestore.runTransaction((tx) async {
    final snapshot = await tx.get(userChallengeRef);
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final xpReward = data['xpReward'] as int? ?? 100;

    // Mark as completed
    tx.update(userChallengeRef, {
      'status': ChallengeStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Award XP (this would integrate with gamification service)
    // For now, just log - XP will be awarded by caller
  });
}
```

**Step 3: Commit**

```bash
git add lib/features/social/data/repositories/challenge_repository.dart
git commit -m "feat(social): add challenge progress validation and completion handling"
```

---

## Task 13: Wire ChallengesScreen to Real Data

**Files:**
- Modify: `lib/features/social/presentation/screens/challenges_screen.dart:26-100`

**Step 1: Replace filter logic with provider-based data**

Find the filter section and replace with:
```dart
Widget build(BuildContext context) {
  final challengesAsync = ref.watch(archetypeChallengesProvider);
  final weeklySpotlightAsync = ref.watch(weeklySpotlightProvider);
  final userChallengesAsync = ref.watch(userChallengesProvider);

  return Scaffold(
    backgroundColor: EmergeColors.background,
    body: challengesAsync.when(
      data: (challenges) {
        final filteredChallenges = _applyFilter(challenges, _selectedFilter);

        return CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildFilterChips(),
            SliverToBoxAdapter(
              child: weeklySpotlightAsync.when(
                data: (spotlight) => spotlight != null
                    ? _WeeklySpotlightCard(challenge: spotlight)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(
              child: _QuestsList(
                challenges: filteredChallenges,
                userChallenges: userChallengesAsync.value ?? [],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: EmergeColors.teal),
      ),
      error: (e, _) => Center(
        child: Text('Error loading challenges: $e'),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showCreateSoloDialog(context),
      backgroundColor: EmergeColors.teal,
      child: const Icon(Icons.add),
    ),
  );
}
```

**Step 2: Create _QuestsList widget**

Add to the file:
```dart
class _QuestsList extends StatelessWidget {
  final List<Challenge> challenges;
  final List<Challenge> userChallenges;

  const _QuestsList({
    required this.challenges,
    required this.userChallenges,
  });

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No challenges available for your archetype',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final challenge = challenges[index];
          final userChallenge = userChallenges.firstWhere(
            (c) => c.id == challenge.id,
            orElse: () => challenge,
          );
          return _ChallengeCard(challenge: userChallenge);
        },
        childCount: challenges.length,
      ),
    );
  }
}
```

**Step 3: Update _ChallengeCard to handle progress**

Replace the card widget with:
```dart
class _ChallengeCard extends ConsumerWidget {
  final Challenge challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = challenge.currentDay;
    final total = challenge.totalDays;
    final isCompleted = challenge.status == ChallengeStatus.completed;
    final progressPercent = total > 0 ? progress / total : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EmergeColors.glassWhite,
            EmergeColors.glassWhite.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (challenge.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    challenge.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: EmergeColors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.emoji_events, color: EmergeColors.teal),
                    ),
                  ),
                ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      challenge.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      isCompleted ? Colors.green : EmergeColors.teal,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const Gap(12),
              Text(
                'Day $progress/$total',
                style: TextStyle(
                  color: isCompleted ? Colors.green : EmergeColors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isCompleted && progress < total) ...[
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _checkIn(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmergeColors.teal,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('CHECK IN'),
              ),
            ),
          ],
          if (isCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const Gap(4),
                  Text(
                    'Completed! +${challenge.xpReward} XP',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkIn(BuildContext context, WidgetRef ref) async {
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) return;

      final repo = ref.read(challengeRepositoryProvider);
      final newProgress = challenge.currentDay + 1;

      await repo.updateProgress(user.id, challenge.id, newProgress);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Day $newProgress complete!'),
            backgroundColor: EmergeColors.teal,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check in: $e'),
            backgroundColor: EmergeColors.coral,
          ),
        );
      }
    }
  }
}
```

**Step 4: Commit**

```bash
git add lib/features/social/presentation/screens/challenges_screen.dart
git commit -m "feat(social): wire ChallengesScreen to real-time challenge data with progress tracking"
```

---

## Task 14: Level Immersive Screen - Challenge Quests Integration

**Files:**
- Modify: `lib/features/world_map/presentation/screens/level_immersive_screen.dart:400-506`

**Step 1: Add challenge provider dependency**

Add import at top:
```dart
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
```

**Step 2: Replace _buildHabitSection with challenge quests**

Replace the entire `_buildHabitSection` method:
```dart
Widget _buildHabitSection(BuildContext context, UserProfile profile) {
  final challengesAsync = ref.watch(userChallengesProvider);

  return challengesAsync.when(
    data: (challenges) {
      // Filter challenges matching this node's attributes
      final attributeNames = node.targetedAttributes.map((a) => a.name).toList();
      final relevantChallenges = challenges.where((c) {
        // Check if any challenge step matches node attributes
        return c.steps.any((step) =>
            attributeNames.any((attr) =>
                step.description.toLowerCase().contains(attr.toLowerCase())));
      }).toList();

      if (relevantChallenges.isEmpty) {
        return _EmptyMissionsState(
          onAddChallenge: () => _showAddChallengeDialog(context),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE QUESTS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...relevantChallenges.take(3).map((challenge) =>
              _ChallengeQuestCard(
                challenge: challenge,
                config: config,
                onCheckIn: () => _checkInChallenge(context, ref, challenge),
              )),
        ],
      );
    },
    loading: () => const SizedBox(
      height: 100,
      child: Center(child: CircularProgressIndicator(color: config.primaryColor)),
    ),
    error: (_, __) => _EmptyMissionsState(
      onAddChallenge: () => _showAddChallengeDialog(context),
    ),
  );
}
```

**Step 3: Add _EmptyMissionsState widget**

```dart
Widget _EmptyMissionsState({VoidCallback? onAddChallenge}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: Column(
      children: [
        Icon(
          Icons.quest_logo_outlined,
          size: 32,
          color: config.primaryColor.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'No active quests for this node',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        if (onAddChallenge != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAddChallenge,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Solo Quest'),
            style: TextButton.styleFrom(
              foregroundColor: config.primaryColor,
            ),
          ),
        ],
      ],
    ),
  );
}
```

**Step 4: Add _ChallengeQuestCard widget**

```dart
Widget _ChallengeQuestCard({
  required Challenge challenge,
  required ArchetypeMapConfig config,
  required VoidCallback onCheckIn,
}) {
  final progress = challenge.currentDay;
  final total = challenge.totalDays;
  final progressPercent = total > 0 ? progress / total : 0.0;

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: config.primaryColor.withValues(alpha: 0.3),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: config.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.military_tech,
                color: config.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Day $progress of $total',
                    style: TextStyle(
                      color: config.primaryColor.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (progress < total)
              ElevatedButton(
                onPressed: onCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.primaryColor.withValues(alpha: 0.2),
                  foregroundColor: config.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('CHECK IN', style: TextStyle(fontSize: 11)),
              )
            else
              Icon(
                Icons.check_circle,
                color: Colors.green.withValues(alpha: 0.8),
                size: 24,
              ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercent,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(config.primaryColor),
            minHeight: 4,
          ),
        ),
      ],
    ),
  );
}
```

**Step 5: Add _checkInChallenge method**

```dart
Future<void> _checkInChallenge(
  BuildContext context,
  WidgetRef ref,
  Challenge challenge,
) async {
  try {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    final repo = ref.read(challengeRepositoryProvider);
    final newProgress = challenge.currentDay + 1;

    await repo.updateProgress(user.id, challenge.id, newProgress);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quest progress: Day $newProgress'),
          backgroundColor: config.primaryColor,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update quest: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Step 6: Commit**

```bash
git add lib/features/world_map/presentation/screens/level_immersive_screen.dart
git commit -m "feat(world): replace static missions with dynamic challenge quests in Level Immersive screen"
```

---

## Task 15: World Health Calculator Service

**Files:**
- Create: `lib/features/world_map/domain/services/world_health_service.dart`

**Step 1: Create world health service**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

/// Service for calculating dynamic world health based on user activity
class WorldHealthService {
  final FirebaseFirestore _firestore;

  WorldHealthService(this._firestore);

  /// Calculate world health (0.0 to 1.0) based on:
  /// - Habit completion rate over last 7 days
  /// - Decay penalty for missed days
  /// - Recovery bonus for current streak
  Future<double> calculateWorldHealth(String userId) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Get habit completions for last 7 days
      final activitiesSnapshot = await _firestore
          .collection('user_activity')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .where('type', isEqualTo: 'habit_completion')
          .get();

      // Count unique days with activity
      final activeDays = <int>{};
      for (final doc in activitiesSnapshot.docs) {
        final date = (doc.data()['date'] as Timestamp).toDate();
        activeDays.add(DateTime(date.year, date.month, date.day).millisecondsSinceEpoch);
      }

      // Base health: percentage of days active in last 7 days
      final baseHealth = activeDays.length / 7.0;

      // Get user stats for streak info
      final userStatsDoc = await _firestore.collection('user_stats').doc(userId).get();
      if (!userStatsDoc.exists) return baseHealth.clamp(0.0, 1.0);

      final avatarStats = userStatsDoc.data()?['avatarStats'] as Map<String, dynamic>? ?? {};
      final streak = avatarStats['streak'] as int? ?? 0;

      // Calculate last activity date for decay
      DateTime? lastActivityDate;
      if (activitiesSnapshot.docs.isNotEmpty) {
        final lastDoc = activitiesSnapshot.docs
            .reduce((a, b) => a.data()['date'].compareTo(b.data()['date']) > 0 ? a : b);
        lastActivityDate = (lastDoc.data()['date'] as Timestamp).toDate();
      }

      // Decay penalty: 10% per day since last activity (max 50%)
      double decayPenalty = 0.0;
      if (lastActivityDate != null) {
        final daysSince = now.difference(lastActivityDate).inDays;
        decayPenalty = (daysSince * 0.1).clamp(0.0, 0.5);
      }

      // Recovery bonus: 2% per streak day (max 20%)
      final streakBonus = (streak * 0.02).clamp(0.0, 0.2);

      // Calculate final health
      final health = (baseHealth - decayPenalty + streakBonus).clamp(0.0, 1.0);

      AppLogger.i('World health for $userId: $health (base: $baseHealth, decay: $decayPenalty, streak: $streakBonus)');

      return health;
    } catch (e, s) {
      AppLogger.e('Failed to calculate world health', e, s);
      return 0.5; // Return neutral health on error
    }
  }

  /// Get cached health score or calculate fresh
  Future<double> getWorldHealth(String userId) async {
    // Try to get cached health from user_stats
    final userStatsDoc = await _firestore.collection('user_stats').doc(userId).get();

    if (userStatsDoc.exists) {
      final worldState = userStatsDoc.data()?['worldState'] as Map<String, dynamic>? ?? {};
      final cachedHealth = worldState['cachedHealth'] as double?;
      final lastCalculated = worldState['healthCalculatedAt'] as Timestamp?;

      if (cachedHealth != null && lastCalculated != null) {
        final age = DateTime.now().difference(lastCalculated.toDate());
        // Use cache if less than 1 hour old
        if (age.inMinutes < 60) {
          return cachedHealth;
        }
      }
    }

    // Calculate fresh
    final health = await calculateWorldHealth(userId);

    // Update cache
    await _firestore.collection('user_stats').doc(userId).set({
      'worldState': {
        'cachedHealth': health,
        'healthCalculatedAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));

    return health;
  }
}
```

**Step 2: Create provider**

Create `lib/features/world_map/presentation/providers/world_health_provider.dart`:
```dart
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/world_map/domain/services/world_health_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final worldHealthServiceProvider = Provider<WorldHealthService>((ref) {
  return WorldHealthService(ref.watch(firestoreProvider));
});

final worldHealthProvider = FutureProvider.family<double, String>((ref, userId) {
  final service = ref.watch(worldHealthServiceProvider);
  return service.getWorldHealth(userId);
});

/// Stream provider that auto-refreshes world health
final worldHealthStreamProvider = StreamProvider.family<double, String>((ref, userId) {
  // Create a stream that emits periodically
  return Stream.periodic(const Duration(minutes: 5), (_) => userId)
      .asyncMap((_) => ref.read(worldHealthServiceProvider).getWorldHealth(userId));
});
```

**Step 3: Commit**

```bash
git add lib/features/world_map/domain/services/world_health_service.dart
git add lib/features/world_map/presentation/providers/world_health_provider.dart
git commit -m "feat(world): add dynamic world health calculator service"
```

---

## Task 16: Integrate World Health into Level Immersive Screen

**Files:**
- Modify: `lib/features/world_map/presentation/screens/level_immersive_screen.dart:703-706`

**Step 1: Replace static _calculateWorldHealth with provider**

Replace the method:
```dart
double _calculateWorldHealth(UserProfile profile) {
  // Use the world health provider for dynamic calculation
  final healthAsync = ref.watch(worldHealthStreamProvider(profile.id));

  return healthAsync.value ?? profile.worldState.worldHealth.clamp(0.0, 1.0);
}
```

**Step 2: Update imports**

Add at top:
```dart
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
```

**Step 3: Commit**

```bash
git add lib/features/world_map/presentation/screens/level_immersive_screen.dart
git commit -m "feat(world): integrate dynamic world health into Level Immersive screen"
```

---

## Task 17: Online Presence Service

**Files:**
- Create: `lib/core/services/online_presence_service.dart`

**Step 1: Create online presence service**

```dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

/// Service for tracking user online presence via heartbeat
/// Sends heartbeat every 2 minutes to maintain online status
class OnlinePresenceService {
  final FirebaseFirestore _firestore;
  Timer? _heartbeatTimer;
  String? _currentUserId;

  OnlinePresenceService(this._firestore);

  /// Start heartbeat for a user
  void startHeartbeat(String userId) {
    if (_currentUserId == userId && _heartbeatTimer != null) {
      return; // Already running for this user
    }

    stopHeartbeat();
    _currentUserId = userId;

    // Set online immediately
    _updateOnlineStatus(userId, true);

    // Send heartbeat every 2 minutes
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_currentUserId != null) {
        _updateOnlineStatus(_currentUserId!, true);
      }
    });

    AppLogger.i('Started heartbeat for user: $userId');
  }

  /// Stop heartbeat and set offline
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_currentUserId != null) {
      _updateOnlineStatus(_currentUserId!, false);
      AppLogger.i('Stopped heartbeat for user: $_currentUserId');
      _currentUserId = null;
    }
  }

  /// Update online status in Firestore
  void _updateOnlineStatus(String userId, bool isOnline) {
    try {
      _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.w('Failed to update online status: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    stopHeartbeat();
  }
}
```

**Step 2: Create provider**

Create `lib/core/presentation/providers/online_presence_provider.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/services/online_presence_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onlinePresenceServiceProvider = Provider<OnlinePresenceService>((ref) {
  final service = OnlinePresenceService(FirebaseFirestore.instance);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
```

**Step 3: Integrate into main.dart**

Modify `lib/main.dart` to start heartbeat on auth:
```dart
// In the build method where auth state is listened
ref.listen<auth.User?>(authStateChangesProvider, (previous, next) {
  if (next != null) {
    // Start heartbeat
    ref.read(onlinePresenceServiceProvider).startHeartbeat(next.uid);
  } else {
    // Stop heartbeat
    ref.read(onlinePresenceServiceProvider).stopHeartbeat();
  }
});
```

**Step 4: Commit**

```bash
git add lib/core/services/online_presence_service.dart
git add lib/core/presentation/providers/online_presence_provider.dart
git add lib/main.dart
git commit -m "feat(core): add online presence heartbeat service"
```

---

## Task 18: Notification Service for Social Interactions

**Files:**
- Create: `lib/core/services/notification_service.dart`
- Create: `lib/core/domain/entities/app_notification.dart`

**Step 1: Create notification entity**

Create `lib/core/domain/entities/app_notification.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  partnerRequest,
  requestAccepted,
  requestRejected,
  contractBreach,
  contractCreated,
  clubMilestone,
  challengeAvailable,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      type: _parseType(map['type'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      data: map['data'] as Map<String, dynamic>?,
      read: map['read'] as bool? ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  static NotificationType _parseType(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => NotificationType.partnerRequest,
    );
  }
}
```

**Step 2: Create notification service**

Create `lib/core/services/notification_service.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  final Ref? _ref;

  NotificationService(this._firestore, [this._ref]);

  /// Send a notification to a user
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': type.name,
        'title': title,
        'body': body,
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.i('Notification sent to $userId: $title');
    } catch (e, s) {
      AppLogger.e('Failed to send notification', e, s);
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e, s) {
      AppLogger.e('Failed to mark notification as read', e, s);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e, s) {
      AppLogger.e('Failed to mark all as read', e, s);
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e, s) {
      AppLogger.e('Failed to delete notification', e, s);
    }
  }

  /// Get unread count stream
  Stream<int> unreadCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
```

**Step 3: Create provider**

Create `lib/core/presentation/providers/notification_provider.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FirebaseFirestore.instance, ref);
});

/// Stream provider for unread notifications
final unreadNotificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) return const Stream.empty();

  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('users')
      .doc(user.id)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) =>
          AppNotification.fromMap(doc.data(), doc.id)).toList());
});

/// Unread count provider
final unreadCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(unreadNotificationsProvider);
  return notificationsAsync.value?.length ?? 0;
});
```

**Step 4: Commit**

```bash
git add lib/core/domain/entities/app_notification.dart
git add lib/core/services/notification_service.dart
git add lib/core/presentation/providers/notification_provider.dart
git commit -m "feat(core): add notification service for social interactions"
```

---

## Task 19: Firestore Indexes Update

**Files:**
- Modify: `firestore.indexes.json`

**Step 1: Add required indexes**

Add these indexes to the file:
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
      "collectionGroup": "activities",
      "queryScope": "COLLECTION",
      "fields": [
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
      "collectionGroup": "leaderboards",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "clubId", "order": "ASCENDING"},
        {"fieldPath": "xp", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "read", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    }
  ]
}
```

**Step 2: Deploy indexes**

Run: `firebase deploy --only firestore:indexes`

**Step 3: Commit**

```bash
git add firestore.indexes.json
git commit -m "chore(firestore): add indexes for social features queries"
```

---

## Task 20: Final Polish - Error Boundaries and Loading States

**Files:**
- Modify: All modified screens
- Create: `lib/core/presentation/widgets/error_boundary.dart`

**Step 1: Create error boundary widget**

Create `lib/core/presentation/widgets/error_boundary.dart`:
```dart
import 'package:flutter/material.dart';

class ErrorBoundary extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final Widget? child;

  const ErrorBoundary({
    required this.error,
    this.onRetry,
    this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return child ??
        Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        );
  }
}
```

**Step 2: Create loading skeleton widget**

Create `lib/core/presentation/widgets/loading_skeleton.dart`:
```dart
import 'package:flutter/material.dart';

class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double width;

  const LoadingSkeleton({
    this.height = 20,
    this.width = double.infinity,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const shimmerLoader(),
    );
  }
}

class shimmerLoader extends StatelessWidget {
  const shimmerLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
```

**Step 3: Commit**

```bash
git add lib/core/presentation/widgets/error_boundary.dart
git add lib/core/presentation/widgets/loading_skeleton.dart
git commit -m "feat(core): add error boundary and loading skeleton widgets"
```

---

## Summary

This implementation plan covers all the work needed to make Emerge's social features fully dynamic and production-ready:

1. ✅ ClubActivityService for real-time club activity logging
2. ✅ Stream providers for clubs, contributors, and activity feeds
3. ✅ Integration with habit completion flow
4. ✅ Friend repository stream methods for pending requests
5. ✅ Real-time partner requests and online status
6. ✅ Leaderboard repository and providers
7. ✅ Global activity service for centralized logging
8. ✅ Challenge progress validation and completion
9. ✅ Challenge quests in Level Immersive screen
10. ✅ Dynamic world health calculator
11. ✅ Online presence heartbeat service
12. ✅ Notification service for social interactions
13. ✅ Firestore indexes for all queries
14. ✅ Error boundaries and loading states

All features use frontend-driven Firestore writes (no Cloud Functions), real-time streams for live updates, and follow TDD principles with bite-sized tasks.

**Total Estimated Time**: 8 weeks (following the phased approach from the design document)
