import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/data/services/tribe_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late TribeStatsService service;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockTribeCol;
  late MockCollectionReference mockStatsCol;
  late MockDocumentReference mockTribeDocRef;
  late MockDocumentSnapshot mockTribeSnapshot;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockTribeCol = MockCollectionReference();
    mockStatsCol = MockCollectionReference();
    mockTribeDocRef = MockDocumentReference();
    mockTribeSnapshot = MockDocumentSnapshot();

    service = TribeStatsService(firestore: mockFirestore);

    // Tribe collection: tribeDoc.get() returns tribe snapshot
    when(() => mockFirestore.collection('tribes')).thenReturn(mockTribeCol);
    when(() => mockTribeCol.doc(any())).thenReturn(mockTribeDocRef);
    when(() => mockTribeDocRef.get()).thenAnswer((_) async => mockTribeSnapshot);
    when(() => mockTribeSnapshot.exists).thenReturn(true);

    // User stats collection: returns a MockQuery
    when(() => mockFirestore.collection('user_stats')).thenReturn(mockStatsCol);
  });

  group('getTotalXp', () {
    test(
      'should not double-count attribute XP and top-level XP when both exist',
      () async {
        when(() => mockTribeSnapshot.data()).thenReturn({
          'members': ['user1', 'user2', 'user3'],
        });

        final mockQuery = MockQuery();
        final mockQuerySnapshot = MockQuerySnapshot();

        when(() => mockStatsCol.where(
          any(),
          whereIn: any(named: 'whereIn'),
        )).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer(
          (_) async => mockQuerySnapshot,
        );

        final mockDoc1 = MockQueryDocumentSnapshot();
        final mockDoc2 = MockQueryDocumentSnapshot();
        final mockDoc3 = MockQueryDocumentSnapshot();

        when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2, mockDoc3]);

        // Member 1: has avatarStats with individual attributes AND top-level currentXp
        when(() => mockDoc1.data()).thenReturn({
          'avatarStats': {
            'strengthXp': 100,
            'intellectXp': 200,
            'vitalityXp': 150,
            'creativityXp': 50,
            'focusXp': 75,
            'spiritXp': 25,
          },
          'currentXp': 600,
        });

        // Member 2: has avatarStats with only individual attributes (no total/currentXp)
        when(() => mockDoc2.data()).thenReturn({
          'avatarStats': {
            'strengthXp': 0,
            'intellectXp': 0,
            'vitalityXp': 0,
            'creativityXp': 300,
            'focusXp': 0,
            'spiritXp': 0,
          },
        });

        // Member 3: no avatarStats, relies on top-level totalXp
        when(() => mockDoc3.data()).thenReturn({
          'totalXp': 500,
        });

        final result = await service.getTotalXp('test-tribe');

        // Correct calculation:
        //   user1: 600 (avatarStats totalXp/currentXp → use that, don't sum attributes)
        //   user2: 300 (no totalXp/currentXp in avatarStats → sum attributes)
        //   user3: 500 (no avatarStats → use top-level totalXp)
        //   Total: 600 + 300 + 500 = 1400
        //
        // Double-count bug would give:
        //   user1: 600 (attributes) + 600 (currentXp) = 1200
        //   user2: 300 (attributes) + 0 = 300
        //   user3: 0 + 500 (totalXp) = 500
        //   Total: 1200 + 300 + 500 = 2000
        expect(result, 1400, reason: 'Must not double-count attribute XP and direct XP');
      },
    );
  });
}
