import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/social/presentation/screens/challenges_screen.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/domain/models/challenge_bundle.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';

class MockCompanionRepository extends Mock implements CompanionRepository {}

class _MockChallengeBundle extends ChallengeBundle {
  @override
  Future<ChallengeBundleData> build() async => ChallengeBundleData.empty();
}

void main() {
  late MockCompanionRepository mockCompanionRepo;

  setUp(() {
    mockCompanionRepo = MockCompanionRepository();
    when(() => mockCompanionRepo.hasVisited(any())).thenReturn(true);
  });

  Future<void> setScreenSize(tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildTest() {
    return ProviderScope(
      overrides: [
        challengeBundleProvider.overrideWith(() => _MockChallengeBundle()),
        companionRepositoryProvider.overrideWithValue(mockCompanionRepo),
      ],
      child: const MaterialApp(home: ChallengesScreen(showAppBar: false)),
    );
  }

  testWidgets('ChallengesScreen renders with empty bundle', (tester) async {
    await setScreenSize(tester);
    await tester.pumpWidget(buildTest());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Weekly Spotlight'), findsOneWidget);
    expect(find.text('Daily Quest'), findsOneWidget);
    expect(find.text('Solo Quests'), findsOneWidget);
    expect(find.text('For Your Path'), findsOneWidget);
  });
}
