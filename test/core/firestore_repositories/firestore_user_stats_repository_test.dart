import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/firestore_repositories/firestore_user_stats_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class FakeDocumentReference extends Fake
    implements DocumentReference<Object?> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late FirestoreUserStatsRepository repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue(FakeDocumentReference());
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    repository = FirestoreUserStatsRepository(firestore: mockFirestore);
  });

  group('saveUserStats', () {
    test('should write profile to user_stats and users collections', () async {
      final profile = UserProfile(uid: 'user123', displayName: 'Test User');
      final mockUserStatsCollection = MockCollectionReference();
      final mockUsersCollection = MockCollectionReference();
      final mockUserStatsDoc = MockDocumentReference();
      final mockUsersDoc = MockDocumentReference();

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockUserStatsCollection);
      when(() => mockFirestore.collection('users'))
          .thenReturn(mockUsersCollection);
      when(() => mockUserStatsCollection.doc(profile.uid))
          .thenReturn(mockUserStatsDoc);
      when(() => mockUsersCollection.doc(profile.uid))
          .thenReturn(mockUsersDoc);
      when(() => mockUserStatsDoc.set(any())).thenAnswer((_) async {});
      when(() => mockUsersDoc.set(any(), any())).thenAnswer((_) async {});

      await repository.saveUserStats(profile);

      verify(() => mockFirestore.collection('user_stats')).called(1);
      verify(() => mockFirestore.collection('users')).called(1);
      verify(() => mockUserStatsCollection.doc(profile.uid)).called(1);
      verify(() => mockUsersCollection.doc(profile.uid)).called(1);
      verify(() => mockUserStatsDoc.set(any())).called(1);
      verify(() => mockUsersDoc.set(any(), any())).called(1);
    });

    test('should throw when Firestore fails', () async {
      final profile = UserProfile(uid: 'user123');
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc(profile.uid)).thenReturn(mockDoc);
      when(() => mockDoc.set(any())).thenThrow(Exception('Write failed'));

      expect(
        () => repository.saveUserStats(profile),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('syncUserIdentity', () {
    test('should delegate to saveUserStats', () async {
      final profile = UserProfile(uid: 'user123');
      final mockUserStatsCollection = MockCollectionReference();
      final mockUsersCollection = MockCollectionReference();
      final mockUserStatsDoc = MockDocumentReference();
      final mockUsersDoc = MockDocumentReference();

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockUserStatsCollection);
      when(() => mockFirestore.collection('users'))
          .thenReturn(mockUsersCollection);
      when(() => mockUserStatsCollection.doc(profile.uid))
          .thenReturn(mockUserStatsDoc);
      when(() => mockUsersCollection.doc(profile.uid))
          .thenReturn(mockUsersDoc);
      when(() => mockUserStatsDoc.set(any())).thenAnswer((_) async {});
      when(() => mockUsersDoc.set(any(), any())).thenAnswer((_) async {});

      await repository.syncUserIdentity(profile);

      verify(() => mockUserStatsDoc.set(any())).called(1);
      verify(() => mockUsersDoc.set(any(), any())).called(1);
    });
  });

  group('getUserStats', () {
    test('should return UserProfile from document data', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockSnapshot = MockDocumentSnapshot();
      final now = DateTime(2025, 6, 1);

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('user123')).thenReturn(mockDoc);
      when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.data()).thenReturn({
        'uid': 'user123',
        'displayName': 'Test User',
        'archetype': 'scholar',
        'identityVotes': <String, int>{},
        'avatarStats': {
          'strengthXp': 0,
          'intellectXp': 0,
          'vitalityXp': 0,
          'creativityXp': 0,
          'focusXp': 0,
          'spiritXp': 0,
          'challengeXp': 0,
          'level': 1,
          'streak': 0,
          'momentumScore': 0,
          'attributeXp': <String, int>{},
        },
        'worldState': {
          'cityLevel': 1,
          'forestLevel': 1,
          'entropy': 0.0,
          'worldAge': 0,
          'zones': <String, dynamic>{},
          'unlockedBuildings': <String>[],
          'buildingPlacements': <Map<String, dynamic>>[],
          'unlockedLandPlots': <String>[],
          'totalBuildingsConstructed': 0,
          'lastActiveDate': Timestamp.fromDate(now),
          'worldTheme': 'sanctuary',
          'seasonalState': 'spring',
          'claimedNodes': <String>[],
          'activeNodes': <String>[],
          'highestCompletedNodeLevel': 0,
          'activeEntropyEffects': <String>[],
        },
        'onboardingProgress': 0,
        'skippedOnboardingSteps': <String>[],
        'settings': <String, dynamic>{
          'notificationsEnabled': true,
          'healthKitConnected': false,
          'screenTimeConnected': false,
          'soundsEnabled': true,
          'hapticsEnabled': true,
          'habitReminders': true,
          'streakWarnings': true,
          'aiInsights': true,
          'communityUpdates': false,
          'rewardsUpdates': true,
          'archetypeNudges': true,
          'doNotDisturb': false,
        },
        'hasEmerged': false,
        'momentumScore': 0.5,
      });

      final result = await repository.getUserStats('user123');

      expect(result.uid, 'user123');
      expect(result.displayName, 'Test User');
      expect(result.archetype, UserArchetype.scholar);
    });

    test('should return default UserProfile when document does not exist',
        () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockSnapshot = MockDocumentSnapshot();

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('user123')).thenReturn(mockDoc);
      when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.data()).thenReturn(null);

      final result = await repository.getUserStats('user123');

      expect(result.uid, 'user123');
      expect(result.displayName, isNull);
    });
  });

  group('watchUserStats', () {
    test('should stream UserProfile from document snapshots', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final streamController =
          StreamController<DocumentSnapshot<Map<String, dynamic>>>();
      final now = DateTime(2025, 6, 1);

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('user123')).thenReturn(mockDoc);
      when(() => mockDoc.snapshots())
          .thenAnswer((_) => streamController.stream);

      // Create first snapshot
      final mockSnapshot1 = MockDocumentSnapshot();
      when(() => mockSnapshot1.data()).thenReturn({
        'uid': 'user123',
        'displayName': 'Initial',
        'archetype': 'stoic',
        'identityVotes': <String, int>{},
        'avatarStats': {
          'strengthXp': 0,
          'intellectXp': 0,
          'vitalityXp': 0,
          'creativityXp': 0,
          'focusXp': 0,
          'spiritXp': 0,
          'challengeXp': 0,
          'level': 1,
          'streak': 0,
          'momentumScore': 0,
          'attributeXp': <String, int>{},
        },
        'worldState': {
          'cityLevel': 1,
          'forestLevel': 1,
          'entropy': 0.0,
          'worldAge': 0,
          'zones': <String, dynamic>{},
          'unlockedBuildings': <String>[],
          'buildingPlacements': <Map<String, dynamic>>[],
          'unlockedLandPlots': <String>[],
          'totalBuildingsConstructed': 0,
          'lastActiveDate': Timestamp.fromDate(now),
          'worldTheme': 'sanctuary',
          'seasonalState': 'spring',
          'claimedNodes': <String>[],
          'activeNodes': <String>[],
          'highestCompletedNodeLevel': 0,
          'activeEntropyEffects': <String>[],
        },
        'onboardingProgress': 0,
        'skippedOnboardingSteps': <String>[],
        'settings': <String, dynamic>{
          'notificationsEnabled': true,
          'healthKitConnected': false,
          'screenTimeConnected': false,
          'soundsEnabled': true,
          'hapticsEnabled': true,
          'habitReminders': true,
          'streakWarnings': true,
          'aiInsights': true,
          'communityUpdates': false,
          'rewardsUpdates': true,
          'archetypeNudges': true,
          'doNotDisturb': false,
        },
        'hasEmerged': false,
        'momentumScore': 0.5,
      });

      final stream = repository.watchUserStats('user123');
      streamController.add(mockSnapshot1);

      await expectLater(
        stream,
        emits(predicate<UserProfile>((profile) {
          return profile.uid == 'user123' &&
              profile.displayName == 'Initial' &&
              profile.archetype == UserArchetype.stoic;
        })),
      );

      await streamController.close();
    });

    test('should return default profile when document has no data', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final streamController =
          StreamController<DocumentSnapshot<Map<String, dynamic>>>();
      final mockSnapshot = MockDocumentSnapshot();

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('user123')).thenReturn(mockDoc);
      when(() => mockDoc.snapshots())
          .thenAnswer((_) => streamController.stream);
      when(() => mockSnapshot.data()).thenReturn(null);

      final stream = repository.watchUserStats('user123');
      streamController.add(mockSnapshot);

      await expectLater(
        stream,
        emits(predicate<UserProfile>((profile) {
          return profile.uid == 'user123' && profile.displayName == null;
        })),
      );

      await streamController.close();
    });
  });

  group('updateWorldHealth', () {
    test('should update worldState.entropy and updatedAt', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();

      when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
      when(() => mockCollection.doc('user123')).thenReturn(mockDoc);
      when(() => mockDoc.update(any())).thenAnswer((_) async {});

      await repository.updateWorldHealth('user123', 75);

      verify(() => mockDoc.update(any())).called(1);
    });
  });

  group('updateStreak', () {
    test('should update avatarStats.streak and updatedAt', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('user123')).thenReturn(mockDoc);
      when(() => mockDoc.update(any())).thenAnswer((_) async {});

      await repository.updateStreak('user123', 5);

      verify(() => mockDoc.update(any())).called(1);
    });
  });

  group('recap methods', () {
    test('getLatestRecap returns latest recap sorted by endDate', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockRecapsCollection = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('user123')).thenReturn(mockDoc);
      when(() => mockDoc.collection('recaps')).thenReturn(mockRecapsCollection);
      when(() => mockRecapsCollection.orderBy('endDate', descending: true))
          .thenReturn(mockQuery);
      when(() => mockQuery.limit(1)).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.data()).thenReturn({
        'id': 'recap1',
        'endDate': '2025-06-15',
        'summary': 'Great week!',
      });

      final result = await repository.getLatestRecap('user123');

      expect(result, isNotNull);
      expect(result!['id'], 'recap1');
    });

    test('getLatestRecap returns null when no recaps exist', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockRecapsCollection = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('user123')).thenReturn(mockDoc);
      when(() => mockDoc.collection('recaps')).thenReturn(mockRecapsCollection);
      when(() => mockRecapsCollection.orderBy('endDate', descending: true))
          .thenReturn(mockQuery);
      when(() => mockQuery.limit(1)).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([]);

      final result = await repository.getLatestRecap('user123');

      expect(result, isNull);
    });

    test('getRecap returns specific recap document', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockRecapsCollection = MockCollectionReference();
      final mockRecapDoc = MockDocumentReference();
      final mockRecapSnapshot = MockDocumentSnapshot();

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('user123')).thenReturn(mockDoc);
      when(() => mockDoc.collection('recaps')).thenReturn(mockRecapsCollection);
      when(() => mockRecapsCollection.doc('recap1')).thenReturn(mockRecapDoc);
      when(() => mockRecapDoc.get()).thenAnswer((_) async => mockRecapSnapshot);
      when(() => mockRecapSnapshot.data()).thenReturn({
        'id': 'recap1',
        'summary': 'My recap',
      });

      final result = await repository.getRecap('user123', 'recap1');

      expect(result, isNotNull);
      expect(result!['id'], 'recap1');
    });

    test('getRecaps returns list of recaps with limit', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockRecapsCollection = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockDoc2 = MockQueryDocumentSnapshot();

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('user123')).thenReturn(mockDoc);
      when(() => mockDoc.collection('recaps')).thenReturn(mockRecapsCollection);
      when(() => mockRecapsCollection.orderBy('endDate', descending: true))
          .thenReturn(mockQuery);
      when(() => mockQuery.limit(5)).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(() => mockDoc1.data()).thenReturn({'id': 'recap1'});
      when(() => mockDoc2.data()).thenReturn({'id': 'recap2'});

      final result = await repository.getRecaps('user123', limit: 5);

      expect(result.length, 2);
      expect(result[0]['id'], 'recap1');
      expect(result[1]['id'], 'recap2');
    });

    test('saveRecap writes recap data to subcollection', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockRecapsCollection = MockCollectionReference();
      final mockRecapDoc = MockDocumentReference();
      final recapData = {
        'id': 'recap1',
        'summary': 'My recap',
        'endDate': '2025-06-15',
      };

      when(() => mockFirestore.collection('user_stats'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('user123')).thenReturn(mockDoc);
      when(() => mockDoc.collection('recaps')).thenReturn(mockRecapsCollection);
      when(() => mockRecapsCollection.doc('recap1')).thenReturn(mockRecapDoc);
      when(() => mockRecapDoc.set(any())).thenAnswer((_) async {});

      await repository.saveRecap('user123', recapData);

      verify(() => mockRecapsCollection.doc('recap1')).called(1);
      verify(() => mockRecapDoc.set(recapData)).called(1);
    });
  });
}
