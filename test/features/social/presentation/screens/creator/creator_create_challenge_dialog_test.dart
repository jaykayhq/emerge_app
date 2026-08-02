import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/drift_challenge_repository.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_tribe_management_tab.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}
class _MockSyncEngine extends Mock implements EnhancedSyncEngine {}

class FakeChallengeRepository extends DriftChallengeRepository {
  FakeChallengeRepository()
      : super(_MockAppDatabase(), LocalGameLoopEngine(), _MockSyncEngine());

  final List<Challenge> created = [];

  @override
  Future<String> createCatalogChallenge(Challenge challenge) async {
    created.add(challenge);
    return 'challenge-1';
  }
}

class FakeMultiFactorPlatform extends MultiFactorPlatform {
  FakeMultiFactorPlatform(super.auth);
}

class FakeUserPlatform extends UserPlatform {
  FakeUserPlatform(FirebaseAuthPlatform auth, {required String uid})
      : super(
          auth,
          FakeMultiFactorPlatform(auth),
          InternalUserDetails(
            userInfo: InternalUserInfo(
              uid: uid,
              isAnonymous: false,
              isEmailVerified: true,
            ),
            providerData: const [],
          ),
        );
}

class FakeAuthPlatform extends FirebaseAuthPlatform {
  FakeAuthPlatform({this.user});
  UserPlatform? user;

  @override
  UserPlatform? get currentUser => user;

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    String? languageCode,
    InternalUserDetails? currentUser,
  }) =>
      this;
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  setUp(() {
    final platform = FakeAuthPlatform();
    platform.user = FakeUserPlatform(platform, uid: 'uid-1');
    FirebaseAuthPlatform.instance = platform;
  });

  Widget createTest(FakeChallengeRepository repo) {
    return ProviderScope(
      overrides: [
        creatorProfileProvider.overrideWith(
          (ref, uid) => Stream.value(
            const CreatorProfile(userId: 'uid-1', tribeId: 'tribe-1'),
          ),
        ),
        realTimeTribeStatsProvider.overrideWith(
          (ref, tribeId) => Stream.value(
            TribeStats(
              memberCount: 1,
              totalXp: 0,
              totalHabitsCompleted: 0,
              totalChallengesCompleted: 0,
            ),
          ),
        ),
        challengeRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: CreatorTribeManagementTab()),
    );
  }

  testWidgets('create challenge dialog submits a catalog challenge',
      (tester) async {
    final repo = FakeChallengeRepository();
    await tester.pumpWidget(createTest(repo));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Create Challenge'));
    await tester.pumpAndSettle();

    // Dialog is open with title/description/category/day fields.
    expect(find.text('Launch a Tribe Challenge'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Challenge title'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Description (optional)'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Challenge title'),
      '30 Days of Discipline',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Description (optional)'),
      'Ship one small thing daily.',
    );
    await tester.tap(find.text('Publish Challenge'));
    await tester.pumpAndSettle();

    expect(repo.created, hasLength(1));
    final created = repo.created.single;
    expect(created.createdBy, 'uid-1');
    expect(created.title, '30 Days of Discipline');
    expect(created.status, ChallengeStatus.active);
    expect(created.totalDays, 7);
    expect(find.text('Challenge published to your tribe! 🏆'), findsOneWidget);
  });
}
