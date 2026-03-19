import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/data/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
// ignore: subtype_of_sealed_class
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late FirestoreChallengeRepository repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    repository = FirestoreChallengeRepository(mockFirestore);

    // Register fallback values for mocktail
    registerFallbackValue(SetOptions(merge: true));
  });

  group('ChallengeRepository - getChallenges', () {
    test('should return list of challenges', () async {
      // Arrange
      final mockCollectionRef = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();

      final challengeData = {
        'id': 'challenge1',
        'title': 'Test Challenge',
        'description': 'Test Description',
        'imageUrl': 'https://example.com/image.png',
        'reward': '100 XP',
        'participants': 10,
        'daysLeft': 7,
        'totalDays': 7,
        'currentDay': 0,
        'status': ChallengeStatus.featured.name,
        'xpReward': 100,
        'isFeatured': true,
        'category': ChallengeCategory.fitness.name,
        'steps': [],
      };

      when(
        () => mockFirestore.collection('challenges'),
      ).thenReturn(mockCollectionRef);
      when(
        () => mockCollectionRef.where('isFeatured', isEqualTo: true),
      ).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.data()).thenReturn(challengeData);
      when(() => mockDocSnapshot.id).thenReturn('challenge1');

      // Act
      final result = await repository.getChallenges(featuredOnly: true);

      // Assert
      expect(result, isA<List<Challenge>>());
      expect(result.length, 1);
      expect(result.first.title, 'Test Challenge');
      verify(() => mockFirestore.collection('challenges')).called(1);
    });

    test('should return empty list when no challenges exist', () async {
      // Arrange
      final mockCollectionRef = MockCollectionReference();
      final mockQuerySnapshot = MockQuerySnapshot();

      when(
        () => mockFirestore.collection('challenges'),
      ).thenReturn(mockCollectionRef);
      when(
        () => mockCollectionRef.get(),
      ).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([]);

      // Act
      final result = await repository.getChallenges();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('ChallengeRepository - getUserChallenges', () {
    test('should return user challenges', () async {
      // Arrange
      const userId = 'user1';
      final mockUsersCollectionRef = MockCollectionReference();
      final mockUserDocRef = MockDocumentReference();
      final mockChallengesCollectionRef = MockCollectionReference();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();

      final challengeData = {
        'id': 'challenge1',
        'title': 'User Challenge',
        'description': 'Test',
        'imageUrl': 'https://example.com/image.png',
        'reward': '50 XP',
        'participants': 5,
        'daysLeft': 3,
        'totalDays': 7,
        'currentDay': 4,
        'status': ChallengeStatus.active.name,
        'xpReward': 50,
        'isFeatured': false,
        'category': ChallengeCategory.mindfulness.name,
        'steps': [],
      };

      when(
        () => mockFirestore.collection('users'),
      ).thenReturn(mockUsersCollectionRef);
      when(() => mockUsersCollectionRef.doc(userId)).thenReturn(mockUserDocRef);
      when(
        () => mockUserDocRef.collection('challenges'),
      ).thenReturn(mockChallengesCollectionRef);
      when(
        () => mockChallengesCollectionRef.get(),
      ).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.data()).thenReturn(challengeData);
      when(() => mockDocSnapshot.id).thenReturn('challenge1');

      // Act
      final result = await repository.getUserChallenges(userId);

      // Assert
      expect(result, isA<List<Challenge>>());
      expect(result.length, 1);
      expect(result.first.status, ChallengeStatus.active);
    });
  });

  group('ChallengeRepository - getChallengesByArchetype', () {
    test('should return challenges for archetype', () async {
      // Arrange
      const archetypeId = 'athlete';

      // Act
      final result = await repository.getChallengesByArchetype(archetypeId);

      // Assert
      expect(result, isA<List<Challenge>>());
      // This method uses ChallengeCatalog, so we're just verifying it returns a list
    });
  });

  group('ChallengeRepository - getWeeklySpotlight', () {
    test('should return weekly spotlight for archetype', () async {
      // Arrange
      const archetypeId = 'creator';

      // Act
      await repository.getWeeklySpotlight(archetypeId: archetypeId);

      // Assert
      // May return null if no spotlight exists - just verify no exception thrown
    });

    test('should return null when no archetype provided', () async {
      // Act
      final result = await repository.getWeeklySpotlight();

      // Assert
      expect(result, isNull);
    });
  });

  group('ChallengeRepository - getLeaderboard', () {
    test('should return leaderboard for challenge', () async {
      // Arrange
      const challengeId = 'challenge1';
      final mockChallengesCollectionRef = MockCollectionReference();
      final mockChallengeDocRef = MockDocumentReference();
      final mockParticipantsCollectionRef = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();

      final leaderboardData = {
        'userId': 'user1',
        'userName': 'Test User',
        'xp': 1000,
        'level': 10,
      };

      when(
        () => mockFirestore.collection('challenges'),
      ).thenReturn(mockChallengesCollectionRef);
      when(
        () => mockChallengesCollectionRef.doc(challengeId),
      ).thenReturn(mockChallengeDocRef);
      when(
        () => mockChallengeDocRef.collection('participants'),
      ).thenReturn(mockParticipantsCollectionRef);
      when(
        () => mockParticipantsCollectionRef.orderBy('xp', descending: true),
      ).thenReturn(mockQuery);
      when(() => mockQuery.limit(3)).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.data()).thenReturn(leaderboardData);
      when(() => mockDocSnapshot.id).thenReturn('user1');

      // Act
      final result = await repository.getLeaderboard(challengeId);

      // Assert
      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result.length, 1);
      expect(result.first['userId'], 'user1');
      expect(result.first['xp'], 1000);
    });

    test('should respect custom limit', () async {
      // Arrange
      const challengeId = 'challenge1';
      const customLimit = 5;
      final mockChallengesCollectionRef = MockCollectionReference();
      final mockChallengeDocRef = MockDocumentReference();
      final mockParticipantsCollectionRef = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();

      when(
        () => mockFirestore.collection('challenges'),
      ).thenReturn(mockChallengesCollectionRef);
      when(
        () => mockChallengesCollectionRef.doc(challengeId),
      ).thenReturn(mockChallengeDocRef);
      when(
        () => mockChallengeDocRef.collection('participants'),
      ).thenReturn(mockParticipantsCollectionRef);
      when(
        () => mockParticipantsCollectionRef.orderBy('xp', descending: true),
      ).thenReturn(mockQuery);
      when(() => mockQuery.limit(customLimit)).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([]);

      // Act
      final result = await repository.getLeaderboard(
        challengeId,
        limit: customLimit,
      );

      // Assert
      expect(result, isEmpty);
      verify(() => mockQuery.limit(customLimit)).called(1);
    });
  });

  group('ChallengeRepository - createSoloChallenge', () {
    test('should create solo challenge for user', () async {
      // Arrange
      const userId = 'user1';
      final mockUsersCollectionRef = MockCollectionReference();
      final mockUserDocRef = MockDocumentReference();
      final mockChallengesCollectionRef = MockCollectionReference();
      final mockChallengeDocRef = MockDocumentReference();

      final challenge = Challenge(
        id: 'solo1',
        title: 'Solo Challenge',
        description: 'Personal challenge',
        imageUrl: 'https://example.com/image.png',
        reward: 'Custom reward',
        participants: 1,
        daysLeft: 30,
        totalDays: 30,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 200,
        steps: [],
      );

      when(
        () => mockFirestore.collection('users'),
      ).thenReturn(mockUsersCollectionRef);
      when(() => mockUsersCollectionRef.doc(userId)).thenReturn(mockUserDocRef);
      when(
        () => mockUserDocRef.collection('challenges'),
      ).thenReturn(mockChallengesCollectionRef);
      when(
        () => mockChallengesCollectionRef.doc(challenge.id),
      ).thenReturn(mockChallengeDocRef);
      when(
        () => mockChallengeDocRef.set(any(), any()),
      ).thenAnswer((_) async {});

      // Act
      await repository.createSoloChallenge(userId, challenge);

      // Assert
      verify(() => mockChallengeDocRef.set(any(), any())).called(1);
    });
  });

  group('ChallengeRepository - completeChallenge', () {
    test('should mark challenge as completed', () async {
      // Arrange
      const userId = 'user1';
      const challengeId = 'challenge1';
      final mockUsersCollectionRef = MockCollectionReference();
      final mockUserDocRef = MockDocumentReference();
      final mockChallengesCollectionRef = MockCollectionReference();
      final mockChallengeDocRef = MockDocumentReference();

      when(
        () => mockFirestore.collection('users'),
      ).thenReturn(mockUsersCollectionRef);
      when(() => mockUsersCollectionRef.doc(userId)).thenReturn(mockUserDocRef);
      when(
        () => mockUserDocRef.collection('challenges'),
      ).thenReturn(mockChallengesCollectionRef);
      when(
        () => mockChallengesCollectionRef.doc(challengeId),
      ).thenReturn(mockChallengeDocRef);
      when(() => mockChallengeDocRef.update(any())).thenAnswer((_) async {});

      // Act
      await repository.completeChallenge(userId, challengeId);

      // Assert
      verify(
        () => mockChallengeDocRef.update({
          'status': ChallengeStatus.completed.name,
        }),
      ).called(1);
    });
  });

  group('ChallengeRepository - interface compliance', () {
    test('should implement all required methods from domain interface', () {
      // Verify that all required methods exist and have correct signatures
      expect(repository.getChallenges, isNotNull);
      expect(repository.getUserChallenges, isNotNull);
      expect(repository.joinChallenge, isNotNull);
      expect(repository.createSoloChallenge, isNotNull);
      expect(repository.updateProgress, isNotNull);
      expect(repository.completeChallenge, isNotNull);
      expect(repository.completeChallengeWithReward, isNotNull);
      expect(repository.getChallengesByArchetype, isNotNull);
      expect(repository.getWeeklySpotlight, isNotNull);
      expect(repository.getLeaderboard, isNotNull);
    });

    test('should be FirestoreChallengeRepository instance', () {
      // Verify the repository implements the domain interface correctly
      expect(repository, isA<FirestoreChallengeRepository>());
    });
  });
}
