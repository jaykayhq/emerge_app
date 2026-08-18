import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/social/presentation/screens/all_tribes_screen.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/domain/services/tribe_membership_service.dart';
import 'package:emerge_app/features/social/data/services/tribe_stats_service.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';

class MockTribeMembershipService extends Mock
    implements TribeMembershipService {}

class MockTribeStatsService extends Mock implements TribeStatsService {}

void main() {
  final emptyUser = const AuthUser(id: '', email: '');

  testWidgets('AllTribesScreen renders loading skeleton initially', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allArchetypeClubsProvider.overrideWith((ref) => const Stream.empty()),
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(emptyUser),
          ),
          verifiedCreatorsStreamProvider.overrideWith(
            (ref) => Stream.value(const <CreatorProfile>[]),
          ),
        ],
        child: const MaterialApp(home: AllTribesScreen()),
      ),
    );

    await tester.pump();
    expect(find.byType(EmergeLoadingSkeleton), findsOneWidget);
  });

  testWidgets('AllTribesScreen renders tribe list', (tester) async {
    final tribes = [
      Tribe(
        id: '1',
        name: 'Morning Warriors',
        description: 'Early risers unite',
        imageUrl: '',
        memberCount: 100,
        ownerId: '',
        tags: [],
        levelRequirement: 0,
        rank: 1,
        totalXp: 5000,
        archetypeId: 'athlete',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allArchetypeClubsProvider.overrideWith((ref) => Stream.value(tribes)),
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(emptyUser),
          ),
          verifiedCreatorsStreamProvider.overrideWith(
            (ref) => Stream.value(const <CreatorProfile>[]),
          ),
          cachedTribeStatsProvider('1').overrideWith((ref) {
            return Stream.value(
              TribeStats(
                memberCount: 100,
                totalXp: 5000,
                totalHabitsCompleted: 50,
                totalChallengesCompleted: 10,
              ),
            );
          }),
          tribeMembershipServiceProvider.overrideWithValue(
            MockTribeMembershipService(),
          ),
          tribeStatsServiceProvider.overrideWithValue(MockTribeStatsService()),
        ],
        child: const MaterialApp(home: AllTribesScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('MORNING WARRIORS'), findsOneWidget);
  });

  testWidgets('AllTribesScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allArchetypeClubsProvider.overrideWith(
            (ref) => Stream.value(<Tribe>[]),
          ),
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(emptyUser),
          ),
          verifiedCreatorsStreamProvider.overrideWith(
            (ref) => Stream.value(const <CreatorProfile>[]),
          ),
        ],
        child: const MaterialApp(home: AllTribesScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('No tribes available'), findsOneWidget);
  });

  testWidgets(
    'AllTribesScreen renders the CREATORS section with creator cards',
    (tester) async {
      const creator = CreatorProfile(
        userId: 'creator_test',
        displayName: 'Test Creator',
        isVerifiedCreator: true,
        blueprintCount: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allArchetypeClubsProvider.overrideWith(
              (ref) => Stream.value(<Tribe>[]),
            ),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(emptyUser),
            ),
            verifiedCreatorsStreamProvider.overrideWith(
              (ref) => Stream.value(const [creator]),
            ),
          ],
          child: const MaterialApp(home: AllTribesScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('CREATORS'), findsOneWidget);
      expect(find.text('Test Creator'), findsOneWidget);
      expect(find.text('2 blueprints'), findsOneWidget);
    },
  );

  testWidgets(
    'AllTribesScreen shows the creators empty state when no creators exist',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allArchetypeClubsProvider.overrideWith(
              (ref) => Stream.value(<Tribe>[]),
            ),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(emptyUser),
            ),
            verifiedCreatorsStreamProvider.overrideWith(
              (ref) => Stream.value(const <CreatorProfile>[]),
            ),
          ],
          child: const MaterialApp(home: AllTribesScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Creators are coming'), findsOneWidget);
    },
  );
}
