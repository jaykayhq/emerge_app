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

  group('SilhouetteEvolutionState.shouldEvolve', () {
    test('returns true when phase index increases (phantom→construct)', () {
      final previous = SilhouetteEvolutionState(
        phase: EvolutionPhase.phantom,
        level: 1,
      );
      final current = SilhouetteEvolutionState(
        phase: EvolutionPhase.construct,
        level: 6,
      );

      expect(current.shouldEvolve(previous), isTrue);
    });

    test('returns false when same phase', () {
      final previous = SilhouetteEvolutionState(
        phase: EvolutionPhase.phantom,
        level: 1,
      );
      final current = SilhouetteEvolutionState(
        phase: EvolutionPhase.phantom,
        level: 3,
      );

      expect(current.shouldEvolve(previous), isFalse);
    });

    test('returns false when lower phase (construct→phantom)', () {
      final previous = SilhouetteEvolutionState(
        phase: EvolutionPhase.construct,
        level: 6,
      );
      final current = SilhouetteEvolutionState(
        phase: EvolutionPhase.phantom,
        level: 1,
      );

      expect(current.shouldEvolve(previous), isFalse);
    });
  });

  group('SilhouetteEvolutionState.phaseName', () {
    test('returns correct name for each of the 5 phases', () {
      expect(
        SilhouetteEvolutionState(phase: EvolutionPhase.phantom, level: 1)
            .phaseName,
        'The Phantom',
      );
      expect(
        SilhouetteEvolutionState(phase: EvolutionPhase.construct, level: 6)
            .phaseName,
        'The Construct',
      );
      expect(
        SilhouetteEvolutionState(phase: EvolutionPhase.incarnate, level: 16)
            .phaseName,
        'The Incarnate',
      );
      expect(
        SilhouetteEvolutionState(phase: EvolutionPhase.radiant, level: 31)
            .phaseName,
        'The Radiant',
      );
      expect(
        SilhouetteEvolutionState(phase: EvolutionPhase.ascended, level: 50)
            .phaseName,
        'The Ascended',
      );
    });
  });

  group('SilhouetteEvolutionState.phaseDescription', () {
    test('returns correct description for each of the 5 phases', () {
      expect(
        SilhouetteEvolutionState(phase: EvolutionPhase.phantom, level: 1)
            .phaseDescription,
        'I am potential, but undefined.',
      );
      expect(
        SilhouetteEvolutionState(phase: EvolutionPhase.construct, level: 6)
            .phaseDescription,
        'I am building the framework.',
      );
      expect(
        SilhouetteEvolutionState(phase: EvolutionPhase.incarnate, level: 16)
            .phaseDescription,
        'I am here. I am consistent.',
      );
      expect(
        SilhouetteEvolutionState(phase: EvolutionPhase.radiant, level: 31)
            .phaseDescription,
        'I am powerful. My habits are fueling me.',
      );
      expect(
        SilhouetteEvolutionState(phase: EvolutionPhase.ascended, level: 50)
            .phaseDescription,
        'I have transcended. The habit is my identity.',
      );
    });
  });

  group('SilhouetteEvolutionState.copyWith', () {
    test('overrides each field', () {
      final original = SilhouetteEvolutionState(
        phase: EvolutionPhase.phantom,
        level: 1,
      );

      final modified = original.copyWith(
        phase: EvolutionPhase.ascended,
        level: 50,
        phaseProgress: 0.5,
        unlockedArtifacts: [BodyArtifact.halo],
        entropyLevel: 0.3,
        currentStreak: 10,
        daysMissed: 2,
      );

      expect(modified.phase, EvolutionPhase.ascended);
      expect(modified.level, 50);
      expect(modified.phaseProgress, 0.5);
      expect(modified.unlockedArtifacts, [BodyArtifact.halo]);
      expect(modified.entropyLevel, 0.3);
      expect(modified.currentStreak, 10);
      expect(modified.daysMissed, 2);
    });

    test('without arguments returns same values', () {
      final original = SilhouetteEvolutionState(
        phase: EvolutionPhase.incarnate,
        level: 20,
        phaseProgress: 0.5,
        unlockedArtifacts: [BodyArtifact.halo],
        entropyLevel: 0.1,
        currentStreak: 5,
        daysMissed: 1,
      );

      final copied = original.copyWith();

      expect(copied.phase, original.phase);
      expect(copied.level, original.level);
      expect(copied.phaseProgress, original.phaseProgress);
      expect(copied.unlockedArtifacts, original.unlockedArtifacts);
      expect(copied.entropyLevel, original.entropyLevel);
      expect(copied.currentStreak, original.currentStreak);
      expect(copied.daysMissed, original.daysMissed);
    });
  });

  group('SilhouetteEvolutionState default constructor', () {
    test('phaseProgress defaults to 0.0', () {
      final state = SilhouetteEvolutionState(
        phase: EvolutionPhase.phantom,
        level: 1,
      );

      expect(state.phaseProgress, 0.0);
    });

    test('unlockedArtifacts defaults to empty list', () {
      final state = SilhouetteEvolutionState(
        phase: EvolutionPhase.phantom,
        level: 1,
      );

      expect(state.unlockedArtifacts, isEmpty);
    });

    test('entropyLevel defaults to 0.0', () {
      final state = SilhouetteEvolutionState(
        phase: EvolutionPhase.phantom,
        level: 1,
      );

      expect(state.entropyLevel, 0.0);
    });

    test('currentStreak defaults to 0', () {
      final state = SilhouetteEvolutionState(
        phase: EvolutionPhase.phantom,
        level: 1,
      );

      expect(state.currentStreak, 0);
    });

    test('daysMissed defaults to 0', () {
      final state = SilhouetteEvolutionState(
        phase: EvolutionPhase.phantom,
        level: 1,
      );

      expect(state.daysMissed, 0);
    });
  });
}
