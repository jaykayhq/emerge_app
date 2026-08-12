import 'package:cloud_functions/cloud_functions.dart';
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
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_invite_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_invite_dialog.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}
class _MockSyncEngine extends Mock implements EnhancedSyncEngine {}
class _MockSocialActivityService extends Mock implements SocialActivityService {}

class FakeChallengeRepository extends DriftChallengeRepository {
  FakeChallengeRepository()
      : super(
          _MockAppDatabase(),
          LocalGameLoopEngine(),
          _MockSyncEngine(),
          _MockSocialActivityService(),
        );
}

class _MockFunctions extends Mock implements FirebaseFunctions {}
class _MockCallable extends Mock implements HttpsCallable {}
class _MockResult extends Mock implements HttpsCallableResult {}

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

  Widget createTest({
    required _MockFunctions functions,
    required FakeChallengeRepository repo,
  }) {
    return ProviderScope(
      overrides: [
        firebaseFunctionsProvider.overrideWithValue(functions),
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
        creatorAuthoredChallengesProvider.overrideWith(
          (ref, uid) => Stream.value(<Challenge>[]),
        ),
        challengeRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: Scaffold(body: CreatorInviteDialog())),
    );
  }

  testWidgets('invite creators generates and shows a copyable code',
      (tester) async {
    final functions = _MockFunctions();
    final callable = _MockCallable();
    final result = _MockResult();
    when(() => functions.httpsCallable('generateCreatorInviteCode'))
        .thenReturn(callable);
    when(() => callable.call(any())).thenAnswer((_) async => result);
    when(() => result.data).thenReturn({'code': 'ABC12345'});

    await tester.pumpWidget(
      createTest(functions: functions, repo: FakeChallengeRepository()),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // No auto-generation on open (codes are single-use quota).
    expect(find.text('GENERATE INVITE CODE'), findsOneWidget);
    expect(find.text('ABC12345'), findsNothing);

    await tester.tap(find.text('GENERATE INVITE CODE'));
    await tester.pumpAndSettle();

    expect(find.text('ABC12345'), findsOneWidget);
    expect(find.text('COPY CODE'), findsOneWidget);
    verify(() => functions.httpsCallable('generateCreatorInviteCode')).called(1);
  });

  testWidgets('invite generation failure surfaces the error, not a code',
      (tester) async {
    final functions = _MockFunctions();
    final callable = _MockCallable();
    when(() => functions.httpsCallable('generateCreatorInviteCode'))
        .thenReturn(callable);
    when(() => callable.call(any()))
        .thenThrow(FirebaseFunctionsException(
      code: 'permission-denied',
      message: 'No invite slots left',
    ));

    await tester.pumpWidget(
      createTest(functions: functions, repo: FakeChallengeRepository()),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('GENERATE INVITE CODE'));
    await tester.pumpAndSettle();

    expect(find.textContaining('admin creator'), findsOneWidget);
    expect(find.text('COPY CODE'), findsNothing);
  });

  testWidgets('resource-exhausted surfaces the outstanding-code cap message',
      (tester) async {
    final functions = _MockFunctions();
    final callable = _MockCallable();
    when(() => functions.httpsCallable('generateCreatorInviteCode'))
        .thenReturn(callable);
    when(() => callable.call(any()))
        .thenThrow(FirebaseFunctionsException(
      code: 'resource-exhausted',
      message: 'Limit reached',
    ));

    await tester.pumpWidget(
      createTest(functions: functions, repo: FakeChallengeRepository()),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('GENERATE INVITE CODE'));
    await tester.pumpAndSettle();

    expect(find.textContaining('10 outstanding'), findsOneWidget);
    expect(find.text('COPY CODE'), findsNothing);
  });
}
