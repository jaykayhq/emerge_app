import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_config.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvatarConfig', () {
    test('constructor with archetype and evolvedState', () {
      const config = AvatarConfig(
        archetype: UserArchetype.athlete,
        evolvedState: EvolutionPhase.incarnate,
      );

      expect(config.archetype, UserArchetype.athlete);
      expect(config.evolvedState, EvolutionPhase.incarnate);
    });

    test('constructor uses EvolutionPhase.phantom as default evolvedState', () {
      const config = AvatarConfig(archetype: UserArchetype.creator);

      expect(config.archetype, UserArchetype.creator);
      expect(config.evolvedState, EvolutionPhase.phantom);
    });

    test('defaultForArchetype factory creates correct config', () {
      final config = AvatarConfig.defaultForArchetype(UserArchetype.scholar);

      expect(config.archetype, UserArchetype.scholar);
      expect(config.evolvedState, EvolutionPhase.phantom);
    });

    test('fromUserStats factory creates config with correct phase based on level', () {
      final config = AvatarConfig.fromUserStats(
        archetype: UserArchetype.stoic,
        level: 10,
      );

      expect(config.archetype, UserArchetype.stoic);
      expect(config.evolvedState, EvolutionPhase.construct);

      final highLevel = AvatarConfig.fromUserStats(
        archetype: UserArchetype.zealot,
        level: 60,
      );
      expect(highLevel.evolvedState, EvolutionPhase.ascended);
    });

    test('showEvolvedOverlay is false for phantom, true for other phases', () {
      const phantom = AvatarConfig(
        archetype: UserArchetype.athlete,
        evolvedState: EvolutionPhase.phantom,
      );
      const construct = AvatarConfig(
        archetype: UserArchetype.athlete,
        evolvedState: EvolutionPhase.construct,
      );
      const incarnate = AvatarConfig(
        archetype: UserArchetype.athlete,
        evolvedState: EvolutionPhase.incarnate,
      );
      const radiant = AvatarConfig(
        archetype: UserArchetype.athlete,
        evolvedState: EvolutionPhase.radiant,
      );
      const ascended = AvatarConfig(
        archetype: UserArchetype.athlete,
        evolvedState: EvolutionPhase.ascended,
      );

      expect(phantom.showEvolvedOverlay, isFalse);
      expect(construct.showEvolvedOverlay, isTrue);
      expect(incarnate.showEvolvedOverlay, isTrue);
      expect(radiant.showEvolvedOverlay, isTrue);
      expect(ascended.showEvolvedOverlay, isTrue);
    });

    test('copyWith overrides individual fields', () {
      const original = AvatarConfig(
        archetype: UserArchetype.athlete,
        evolvedState: EvolutionPhase.phantom,
      );

      final changedArchetype = original.copyWith(archetype: UserArchetype.creator);
      expect(changedArchetype.archetype, UserArchetype.creator);
      expect(changedArchetype.evolvedState, EvolutionPhase.phantom);

      final changedPhase = original.copyWith(evolvedState: EvolutionPhase.radiant);
      expect(changedPhase.archetype, UserArchetype.athlete);
      expect(changedPhase.evolvedState, EvolutionPhase.radiant);
    });

    test('Equality operator and hashCode', () {
      const a = AvatarConfig(archetype: UserArchetype.scholar, evolvedState: EvolutionPhase.construct);
      const b = AvatarConfig(archetype: UserArchetype.scholar, evolvedState: EvolutionPhase.construct);
      const c = AvatarConfig(archetype: UserArchetype.scholar, evolvedState: EvolutionPhase.phantom);
      const d = AvatarConfig(archetype: UserArchetype.stoic, evolvedState: EvolutionPhase.construct);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
      expect(a.hashCode, b.hashCode);
    });
  });
}
