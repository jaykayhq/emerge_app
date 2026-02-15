import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SilhouetteEvolutionState', () {
    group('phaseFromLevel', () {
      test('returns phantom for levels 1-5', () {
        expect(
          SilhouetteEvolutionState.phaseFromLevel(1),
          EvolutionPhase.phantom,
        );
        expect(
          SilhouetteEvolutionState.phaseFromLevel(5),
          EvolutionPhase.phantom,
        );
      });

      test('returns construct for levels 6-15', () {
        expect(
          SilhouetteEvolutionState.phaseFromLevel(6),
          EvolutionPhase.construct,
        );
        expect(
          SilhouetteEvolutionState.phaseFromLevel(15),
          EvolutionPhase.construct,
        );
      });

      test('returns incarnate for levels 16-30', () {
        expect(
          SilhouetteEvolutionState.phaseFromLevel(16),
          EvolutionPhase.incarnate,
        );
        expect(
          SilhouetteEvolutionState.phaseFromLevel(30),
          EvolutionPhase.incarnate,
        );
      });

      test('returns radiant for levels 31-49', () {
        expect(
          SilhouetteEvolutionState.phaseFromLevel(31),
          EvolutionPhase.radiant,
        );
        expect(
          SilhouetteEvolutionState.phaseFromLevel(49),
          EvolutionPhase.radiant,
        );
      });

      test('returns ascended for levels 50+', () {
        expect(
          SilhouetteEvolutionState.phaseFromLevel(50),
          EvolutionPhase.ascended,
        );
        expect(
          SilhouetteEvolutionState.phaseFromLevel(100),
          EvolutionPhase.ascended,
        );
      });
    });

    group('progressInPhase', () {
      test('returns correct progress for phantom phase (levels 1-5)', () {
        // Level 1 is 0%, Level 5 is 80% (need to hit level 6 for 100%)
        expect(SilhouetteEvolutionState.progressInPhase(1), closeTo(0.0, 0.01));
        expect(SilhouetteEvolutionState.progressInPhase(3), closeTo(0.4, 0.01));
        expect(SilhouetteEvolutionState.progressInPhase(5), closeTo(0.8, 0.01));
      });

      test('returns correct progress for construct phase (levels 6-15)', () {
        // Level 6 is start (0%), level 15 is 90%
        expect(SilhouetteEvolutionState.progressInPhase(6), closeTo(0.0, 0.01));
        expect(
          SilhouetteEvolutionState.progressInPhase(10),
          closeTo(0.4, 0.01),
        );
        expect(
          SilhouetteEvolutionState.progressInPhase(15),
          closeTo(0.9, 0.01),
        );
      });

      test('returns correct progress for incarnate phase (levels 16-30)', () {
        expect(
          SilhouetteEvolutionState.progressInPhase(16),
          closeTo(0.0, 0.01),
        );
        expect(
          SilhouetteEvolutionState.progressInPhase(23),
          closeTo(0.467, 0.01),
        );
        expect(
          SilhouetteEvolutionState.progressInPhase(30),
          closeTo(0.933, 0.01),
        );
      });

      test('returns 1.0 for ascended phase', () {
        expect(SilhouetteEvolutionState.progressInPhase(51), 1.0);
        expect(SilhouetteEvolutionState.progressInPhase(100), 1.0);
      });
    });

    group('fromUserStats', () {
      test('creates state with correct phase and progress', () {
        final state = SilhouetteEvolutionState.fromUserStats(
          level: 25,
          currentStreak: 7,
          daysMissed: 0,
          habitVotes: {'cardio': 100, 'mindfulness': 50},
        );

        expect(state.phase, EvolutionPhase.incarnate);
        expect(state.level, 25);
        expect(state.currentStreak, 7);
        expect(state.entropyLevel, 0.0);
      });

      test('calculates entropy based on days missed', () {
        final lowEntropy = SilhouetteEvolutionState.fromUserStats(
          level: 10,
          currentStreak: 5,
          daysMissed: 0,
          habitVotes: {},
        );
        expect(lowEntropy.entropyLevel, 0.0);

        final midEntropy = SilhouetteEvolutionState.fromUserStats(
          level: 10,
          currentStreak: 0,
          daysMissed: 2,
          habitVotes: {},
        );
        expect(midEntropy.entropyLevel, closeTo(0.667, 0.01));

        final maxEntropy = SilhouetteEvolutionState.fromUserStats(
          level: 10,
          currentStreak: 0,
          daysMissed: 5,
          habitVotes: {},
        );
        expect(maxEntropy.entropyLevel, 1.0); // Capped at 1.0
      });

      test('unlocks artifacts based on habit votes', () {
        // Hermes Wings requires 50 cardio votes
        final stateWithArtifact = SilhouetteEvolutionState.fromUserStats(
          level: 20,
          currentStreak: 14,
          daysMissed: 0,
          habitVotes: {'cardio': 55}, // Above 50 threshold
        );

        expect(stateWithArtifact.unlockedArtifacts, isNotEmpty);
        expect(
          stateWithArtifact.unlockedArtifacts.any(
            (a) => a.id == 'hermes_wings',
          ),
          isTrue,
        );

        // Without enough votes, no artifact
        final stateWithoutArtifact = SilhouetteEvolutionState.fromUserStats(
          level: 20,
          currentStreak: 14,
          daysMissed: 0,
          habitVotes: {'cardio': 30}, // Below 50 threshold
        );

        expect(
          stateWithoutArtifact.unlockedArtifacts.any(
            (a) => a.id == 'hermes_wings',
          ),
          isFalse,
        );
      });
    });
  });

  group('BodyArtifact', () {
    test('all predefined artifacts have valid properties', () {
      expect(BodyArtifact.all.length, 9);

      for (final artifact in BodyArtifact.all) {
        expect(artifact.id, isNotEmpty);
        expect(artifact.name, isNotEmpty);
        expect(artifact.requiredVotes, greaterThan(0));
      }
    });

    test('artifacts cover all expected categories', () {
      final categoryNames = BodyArtifact.all
          .map((a) => a.category.name)
          .toSet();

      expect(categoryNames, contains('cardio'));
      expect(categoryNames, contains('strength'));
      expect(categoryNames, contains('mindfulness'));
      expect(categoryNames, contains('creativity'));
      expect(categoryNames, contains('hydration'));
    });

    test('artifacts cover all bodyZones', () {
      final zones = BodyArtifact.all.map((a) => a.zone).toSet();

      expect(zones.length, greaterThanOrEqualTo(4)); // At least 4 zones covered
    });
  });

  group('EvolutionPhase', () {
    test('enum has correct number of phases', () {
      expect(EvolutionPhase.values.length, 5);
    });

    test('phases are in correct order', () {
      expect(EvolutionPhase.phantom.index, 0);
      expect(EvolutionPhase.construct.index, 1);
      expect(EvolutionPhase.incarnate.index, 2);
      expect(EvolutionPhase.radiant.index, 3);
      expect(EvolutionPhase.ascended.index, 4);
    });
  });
}
