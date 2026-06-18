import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/presentation/screens/social_screen.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/domain/models/challenge_bundle.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';

class MockCompanionRepository extends Mock implements CompanionRepository {}

class _MockChallengeBundle extends ChallengeBundle {
  @override
  Future<ChallengeBundleData> build() async => ChallengeBundleData.empty();
}

Widget _buildTest() {
  final mockCompanionRepo = MockCompanionRepository();
  when(() => mockCompanionRepo.hasVisited(any())).thenReturn(true);

  return ProviderScope(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
      userStatsStreamProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
      allArchetypeClubsProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
      allBlueprintsStreamProvider.overrideWith(
        (ref) => Stream.value([]),
      ),
      challengeBundleProvider.overrideWith(() => _MockChallengeBundle()),
      companionRepositoryProvider.overrideWithValue(mockCompanionRepo),
    ],
    child: const MaterialApp(home: SocialScreen()),
  );
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('SocialScreen renders with tab bar', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SocialScreen), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('TRIBE'), findsOneWidget);
    expect(find.text('CHALLENGES'), findsOneWidget);
    expect(find.text('DISCOVER'), findsOneWidget);
  });
}
