import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:emerge_app/features/profile/presentation/widgets/evolving_silhouette_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EvolvingSilhouetteWidget', () {
    late SilhouetteEvolutionState testState;

    setUp(() {
      testState = SilhouetteEvolutionState.fromUserStats(
        level: 1,
        currentStreak: 0,
        daysMissed: 0,
        habitVotes: {},
      );
    });

    testWidgets('renders without error for phantom phase', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolvingSilhouetteWidget(
              evolutionState: testState,
              archetype: UserArchetype.athlete,
            ),
          ),
        ),
      );

      expect(find.byType(EvolvingSilhouetteWidget), findsOneWidget);
    });

    testWidgets('renders without error for construct phase', (tester) async {
      final constructState = SilhouetteEvolutionState.fromUserStats(
        level: 10,
        currentStreak: 5,
        daysMissed: 0,
        habitVotes: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolvingSilhouetteWidget(
              evolutionState: constructState,
              archetype: UserArchetype.creator,
            ),
          ),
        ),
      );

      expect(find.byType(EvolvingSilhouetteWidget), findsOneWidget);
      expect(constructState.phase, EvolutionPhase.construct);
    });

    testWidgets('renders without error for incarnate phase', (tester) async {
      final incarnateState = SilhouetteEvolutionState.fromUserStats(
        level: 20,
        currentStreak: 10,
        daysMissed: 0,
        habitVotes: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolvingSilhouetteWidget(
              evolutionState: incarnateState,
              archetype: UserArchetype.scholar,
            ),
          ),
        ),
      );

      expect(find.byType(EvolvingSilhouetteWidget), findsOneWidget);
      expect(incarnateState.phase, EvolutionPhase.incarnate);
    });

    testWidgets('renders without error for radiant phase', (tester) async {
      final radiantState = SilhouetteEvolutionState.fromUserStats(
        level: 40,
        currentStreak: 30,
        daysMissed: 0,
        habitVotes: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolvingSilhouetteWidget(
              evolutionState: radiantState,
              archetype: UserArchetype.stoic,
            ),
          ),
        ),
      );

      expect(find.byType(EvolvingSilhouetteWidget), findsOneWidget);
      expect(radiantState.phase, EvolutionPhase.radiant);
    });

    testWidgets('renders without error for ascended phase', (tester) async {
      final ascendedState = SilhouetteEvolutionState.fromUserStats(
        level: 55,
        currentStreak: 60,
        daysMissed: 0,
        habitVotes: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolvingSilhouetteWidget(
              evolutionState: ascendedState,
              archetype: UserArchetype.athlete,
            ),
          ),
        ),
      );

      expect(find.byType(EvolvingSilhouetteWidget), findsOneWidget);
      expect(ascendedState.phase, EvolutionPhase.ascended);
    });

    testWidgets('shows decay effects when days missed', (tester) async {
      final decayState = SilhouetteEvolutionState.fromUserStats(
        level: 10,
        currentStreak: 0,
        daysMissed: 2,
        habitVotes: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolvingSilhouetteWidget(
              evolutionState: decayState,
              archetype: UserArchetype.creator,
            ),
          ),
        ),
      );

      expect(find.byType(EvolvingSilhouetteWidget), findsOneWidget);
      expect(decayState.entropyLevel, greaterThan(0));
    });

    testWidgets('handles artifact display correctly', (tester) async {
      final stateWithArtifacts = SilhouetteEvolutionState.fromUserStats(
        level: 20,
        currentStreak: 10,
        daysMissed: 0,
        habitVotes: {
          'cardio': 60, // Unlocks Hermes Wings
          'mindfulness': 35, // Unlocks Halo
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolvingSilhouetteWidget(
              evolutionState: stateWithArtifacts,
              archetype: UserArchetype.athlete,
            ),
          ),
        ),
      );

      expect(find.byType(EvolvingSilhouetteWidget), findsOneWidget);
      expect(stateWithArtifacts.unlockedArtifacts.length, greaterThan(0));
    });

    testWidgets('rebuilds when state changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolvingSilhouetteWidget(
              evolutionState: testState,
              archetype: UserArchetype.scholar,
            ),
          ),
        ),
      );

      // Pump a new state
      final newState = SilhouetteEvolutionState.fromUserStats(
        level: 15,
        currentStreak: 7,
        daysMissed: 0,
        habitVotes: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolvingSilhouetteWidget(
              evolutionState: newState,
              archetype: UserArchetype.scholar,
            ),
          ),
        ),
      );

      expect(find.byType(EvolvingSilhouetteWidget), findsOneWidget);
    });

    testWidgets('respects custom size parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolvingSilhouetteWidget(
              evolutionState: testState,
              archetype: UserArchetype.stoic,
              size: 400,
            ),
          ),
        ),
      );

      expect(find.byType(EvolvingSilhouetteWidget), findsOneWidget);
    });

    testWidgets('triggers tap callback when provided', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolvingSilhouetteWidget(
              evolutionState: testState,
              archetype: UserArchetype.athlete,
              onEvolutionTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EvolvingSilhouetteWidget));
      await tester.pump();

      // Verify callback was triggered
      expect(tapped, isTrue);
    });
  });

  group('SilhouetteEvolutionState Widget Integration', () {
    test('phase progress display updates correctly', () {
      final state = SilhouetteEvolutionState.fromUserStats(
        level: 8,
        currentStreak: 3,
        daysMissed: 0,
        habitVotes: {},
      );

      // Progress in construct phase (6-15)
      expect(state.phase, EvolutionPhase.construct);
      expect(state.phaseProgress, closeTo(0.2, 0.05)); // (8-6) / 10 = 0.2
    });

    test('entropy affects visual state', () {
      final decayState = SilhouetteEvolutionState.fromUserStats(
        level: 10,
        currentStreak: 0,
        daysMissed: 3,
        habitVotes: {},
      );

      // Full entropy after 3 days missed
      expect(decayState.entropyLevel, 1.0);

      final partialDecay = SilhouetteEvolutionState.fromUserStats(
        level: 10,
        currentStreak: 0,
        daysMissed: 1,
        habitVotes: {},
      );

      // Partial entropy
      expect(partialDecay.entropyLevel, closeTo(0.33, 0.05));
    });
  });
}
