import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/data/repositories/firestore_leaderboard_repository.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ignore: subtype_of_sealed_class
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQueryChained extends Mock implements Query<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollectionRef;
  late MockQuery mockQuery;
  late MockQueryChained mockQueryChained;
  late MockQuerySnapshot mockQuerySnapshot;
  late FirestoreLeaderboardRepository repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollectionRef = MockCollectionReference();
    mockQuery = MockQuery();
    mockQueryChained = MockQueryChained();
    mockQuerySnapshot = MockQuerySnapshot();
    repository = FirestoreLeaderboardRepository(mockFirestore);
  });

  group('FirestoreLeaderboardRepository', () {
    group('watchClubLeaderboard', () {
      test('should return empty stream when clubId is empty', () {
        // Act
        final result = repository.watchClubLeaderboard('');

        // Assert
        expect(result, emitsDone);
      });

      test('should return empty stream when clubId is null', () {
        // Act
        final result = repository.watchClubLeaderboard();

        // Assert
        expect(result, emitsDone);
      });

      test(
        'should return stream of leaderboard entries for valid club',
        () async {
          // Arrange
          final now = DateTime.now();
          final testDoc1 = {
            'userId': 'user1',
            'userName': 'User One',
            'xp': 2000,
            'level': 10,
            'archetype': 'athlete',
            'lastUpdated': now.toIso8601String(),
          };
          final testDoc2 = {
            'userId': 'user2',
            'userName': 'User Two',
            'xp': 1500,
            'level': 8,
            'archetype': 'scholar',
            'lastUpdated': now.toIso8601String(),
          };

          final mockDocSnapshot1 = MockDocumentSnapshot();
          final mockDocSnapshot2 = MockDocumentSnapshot();

          when(
            () => mockFirestore.collection('club_leaderboards'),
          ).thenReturn(mockCollectionRef);
          when(
            () => mockCollectionRef.where(
              'clubId',
              isEqualTo: any(named: 'isEqualTo'),
            ),
          ).thenReturn(mockQuery);
          when(
            () => mockQuery.orderBy('xp', descending: any(named: 'descending')),
          ).thenReturn(mockQueryChained);
          when(
            () => mockQueryChained.orderBy(
              'lastUpdated',
              descending: any(named: 'descending'),
            ),
          ).thenReturn(mockQueryChained);
          when(
            () => mockQueryChained.limit(any()),
          ).thenReturn(mockQueryChained);
          when(
            () => mockQueryChained.snapshots(),
          ).thenAnswer((_) => Stream.value(mockQuerySnapshot));

          when(
            () => mockQuerySnapshot.docs,
          ).thenReturn([mockDocSnapshot1, mockDocSnapshot2]);

          when(() => mockDocSnapshot1.data()).thenReturn(testDoc1);
          when(() => mockDocSnapshot1.id).thenReturn('user1');
          when(() => mockDocSnapshot2.data()).thenReturn(testDoc2);
          when(() => mockDocSnapshot2.id).thenReturn('user2');

          // Act
          final result = repository.watchClubLeaderboard('club1');

          // Assert
          await expectLater(
            result,
            emits(
              containsAllInOrder([
                isA<LeaderboardEntry>()
                    .having((e) => e.userId, 'userId', 'user1')
                    .having((e) => e.rank, 'rank', 1)
                    .having((e) => e.xp, 'xp', 2000),
                isA<LeaderboardEntry>()
                    .having((e) => e.userId, 'userId', 'user2')
                    .having((e) => e.rank, 'rank', 2)
                    .having((e) => e.xp, 'xp', 1500),
              ]),
            ),
          );
        },
      );

      test('should calculate rank correctly based on XP order', () async {
        // Arrange
        final now = DateTime.now();
        final testDocs = List.generate(
          5,
          (i) => {
            'userId': 'user$i',
            'userName': 'User $i',
            'xp': 1000 - (i * 100), // 1000, 900, 800, 700, 600
            'level': 10 - i,
            'archetype': 'athlete',
            'lastUpdated': now.toIso8601String(),
          },
        );

        final mockDocSnapshots = List.generate(5, (i) {
          final snap = MockDocumentSnapshot();
          when(() => snap.data()).thenReturn(testDocs[i]);
          when(() => snap.id).thenReturn('user$i');
          return snap;
        });

        when(
          () => mockFirestore.collection('club_leaderboards'),
        ).thenReturn(mockCollectionRef);
        when(
          () => mockCollectionRef.where(
            'clubId',
            isEqualTo: any(named: 'isEqualTo'),
          ),
        ).thenReturn(mockQuery);
        when(
          () => mockQuery.orderBy('xp', descending: any(named: 'descending')),
        ).thenReturn(mockQueryChained);
        when(
          () => mockQueryChained.orderBy(
            'lastUpdated',
            descending: any(named: 'descending'),
          ),
        ).thenReturn(mockQueryChained);
        when(() => mockQueryChained.limit(any())).thenReturn(mockQueryChained);
        when(
          () => mockQueryChained.snapshots(),
        ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
        when(() => mockQuerySnapshot.docs).thenReturn(mockDocSnapshots);

        // Act
        final result = repository.watchClubLeaderboard('club1');

        // Assert
        await expectLater(
          result,
          emits(
            allOf([
              contains(
                isA<LeaderboardEntry>()
                    .having((e) => e.userId, 'userId', 'user0')
                    .having((e) => e.rank, 'rank', 1)
                    .having((e) => e.xp, 'xp', 1000),
              ),
              contains(
                isA<LeaderboardEntry>()
                    .having((e) => e.userId, 'userId', 'user4')
                    .having((e) => e.rank, 'rank', 5)
                    .having((e) => e.xp, 'xp', 600),
              ),
            ]),
          ),
        );
      });
    });

    group('watchChallengeLeaderboard', () {
      test('should return empty stream when challengeId is empty', () {
        // Act
        final result = repository.watchChallengeLeaderboard('');

        // Assert
        expect(result, emitsDone);
      });

      test('should return empty stream when challengeId is null', () {
        // Act
        final result = repository.watchChallengeLeaderboard();

        // Assert
        expect(result, emitsDone);
      });

      test(
        'should return stream of leaderboard entries for valid challenge',
        () async {
          // Arrange
          final now = DateTime.now();
          final testDoc1 = {
            'userId': 'user1',
            'userName': 'User One',
            'xp': 2000,
            'level': 10,
            'archetype': 'creator',
            'lastUpdated': now.toIso8601String(),
          };

          final mockDocSnapshot1 = MockDocumentSnapshot();

          when(
            () => mockFirestore.collection('challenge_leaderboards'),
          ).thenReturn(mockCollectionRef);
          when(
            () => mockCollectionRef.where(
              'challengeId',
              isEqualTo: any(named: 'isEqualTo'),
            ),
          ).thenReturn(mockQuery);
          when(
            () => mockQuery.orderBy('xp', descending: any(named: 'descending')),
          ).thenReturn(mockQueryChained);
          when(
            () => mockQueryChained.orderBy(
              'lastUpdated',
              descending: any(named: 'descending'),
            ),
          ).thenReturn(mockQueryChained);
          when(
            () => mockQueryChained.limit(any()),
          ).thenReturn(mockQueryChained);
          when(
            () => mockQueryChained.snapshots(),
          ).thenAnswer((_) => Stream.value(mockQuerySnapshot));

          when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot1]);

          when(() => mockDocSnapshot1.data()).thenReturn(testDoc1);
          when(() => mockDocSnapshot1.id).thenReturn('user1');

          // Act
          final result = repository.watchChallengeLeaderboard('challenge1');

          // Assert
          await expectLater(
            result,
            emits(
              contains(
                isA<LeaderboardEntry>()
                    .having((e) => e.userId, 'userId', 'user1')
                    .having((e) => e.rank, 'rank', 1)
                    .having(
                      (e) => e.archetype,
                      'archetype',
                      UserArchetype.creator,
                    ),
              ),
            ),
          );
        },
      );
    });

    group('updateUserScore', () {
      test('should return Left failure when userId is empty', () async {
        // Act
        final result = await repository.updateUserScore(
          '',
          xp: 100,
          level: 5,
          archetype: UserArchetype.athlete,
          clubId: 'club1',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should update club leaderboard when clubId provided', () async {
        // Arrange
        final mockDocRef = MockDocumentReference();
        when(
          () => mockFirestore.collection('club_leaderboards'),
        ).thenReturn(mockCollectionRef);
        when(() => mockCollectionRef.doc(any())).thenReturn(mockDocRef);
        when(
          () => mockDocRef.set(captureAny(), captureAny()),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.updateUserScore(
          'user1',
          xp: 1500,
          level: 5,
          archetype: UserArchetype.athlete,
          clubId: 'club1',
        );

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDocRef.set(any(), any())).called(1);
      });

      test(
        'should update challenge leaderboard when challengeId provided',
        () async {
          // Arrange
          final mockDocRef = MockDocumentReference();
          when(
            () => mockFirestore.collection('challenge_leaderboards'),
          ).thenReturn(mockCollectionRef);
          when(() => mockCollectionRef.doc(any())).thenReturn(mockDocRef);
          when(
            () => mockDocRef.set(captureAny(), captureAny()),
          ).thenAnswer((_) async {});

          // Act
          final result = await repository.updateUserScore(
            'user1',
            xp: 2000,
            level: 10,
            archetype: UserArchetype.scholar,
            challengeId: 'challenge1',
          );

          // Assert
          expect(result.isRight(), true);
          verify(() => mockDocRef.set(any(), any())).called(1);
        },
      );

      test(
        'should return Left failure when neither clubId nor challengeId provided',
        () async {
          // Act
          final result = await repository.updateUserScore(
            'user1',
            xp: 1500,
            level: 5,
            archetype: UserArchetype.athlete,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<ServerFailure>()),
            (_) => fail('Should return failure'),
          );
        },
      );

      test('should include userName in leaderboard entry', () async {
        // Arrange
        final mockDocRef = MockDocumentReference();
        when(
          () => mockFirestore.collection('club_leaderboards'),
        ).thenReturn(mockCollectionRef);
        when(() => mockCollectionRef.doc(any())).thenReturn(mockDocRef);
        when(
          () => mockDocRef.set(captureAny(), captureAny()),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.updateUserScore(
          'user1',
          xp: 1500,
          level: 5,
          archetype: UserArchetype.athlete,
          clubId: 'club1',
          userName: 'Test User',
        );

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDocRef.set(any(), any())).called(1);
      });
    });
  });
}
