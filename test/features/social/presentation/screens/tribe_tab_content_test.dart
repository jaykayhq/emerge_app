import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_tab_content.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';

class MockCompanionRepository extends Mock implements CompanionRepository {}

Widget _buildTest() {
  final mockRepo = MockCompanionRepository();
  when(() => mockRepo.hasVisited(any())).thenReturn(true);

  return ProviderScope(
    overrides: [
      userStatsStreamProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
      allArchetypeClubsProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
      companionRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: const MaterialApp(home: TribeTabContent()),
  );
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('TribeTabContent renders loading state', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TribeTabContent), findsOneWidget);
    expect(find.byType(EmergeLoadingSkeleton), findsWidgets);
  });
}
