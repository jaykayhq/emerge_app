import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/avatar/domain/models/evolution_data.dart';

void main() {
  group('EvolutionPhase', () {
    test('fromLevel maps levels correctly', () {
      expect(EvolutionPhase.fromLevel(1), EvolutionPhase.phantom);
      expect(EvolutionPhase.fromLevel(5), EvolutionPhase.phantom);
      expect(EvolutionPhase.fromLevel(6), EvolutionPhase.construct);
      expect(EvolutionPhase.fromLevel(15), EvolutionPhase.construct);
      expect(EvolutionPhase.fromLevel(16), EvolutionPhase.incarnate);
      expect(EvolutionPhase.fromLevel(30), EvolutionPhase.incarnate);
      expect(EvolutionPhase.fromLevel(31), EvolutionPhase.radiant);
      expect(EvolutionPhase.fromLevel(50), EvolutionPhase.radiant);
      expect(EvolutionPhase.fromLevel(51), EvolutionPhase.ascended);
      expect(EvolutionPhase.fromLevel(999), EvolutionPhase.ascended);
    });

    test('alpha returns correct opacity for phase', () {
      expect(EvolutionPhase.phantom.alpha, closeTo(0.3, 0.01));
      expect(EvolutionPhase.incarnate.alpha, closeTo(0.9, 0.01));
      expect(EvolutionPhase.ascended.alpha, closeTo(1.0, 0.01));
    });

    test('glowIntensity increases with phases', () {
      double previous = 0;
      for (final phase in EvolutionPhase.values) {
        expect(phase.glowIntensity, greaterThanOrEqualTo(previous));
        previous = phase.glowIntensity;
      }
    });

    test('hasCoreGlow true only from incarnate onward', () {
      expect(EvolutionPhase.phantom.hasCoreGlow, false);
      expect(EvolutionPhase.construct.hasCoreGlow, false);
      expect(EvolutionPhase.incarnate.hasCoreGlow, true);
      expect(EvolutionPhase.radiant.hasCoreGlow, true);
      expect(EvolutionPhase.ascended.hasCoreGlow, true);
    });

    test('hasKintsugi is true only for radiant and ascended', () {
      expect(EvolutionPhase.phantom.hasKintsugi, false);
      expect(EvolutionPhase.construct.hasKintsugi, false);
      expect(EvolutionPhase.incarnate.hasKintsugi, false);
      expect(EvolutionPhase.radiant.hasKintsugi, true);
      expect(EvolutionPhase.ascended.hasKintsugi, true);
    });

    test('hasSparkles is true only for ascended', () {
      expect(EvolutionPhase.phantom.hasSparkles, false);
      expect(EvolutionPhase.construct.hasSparkles, false);
      expect(EvolutionPhase.incarnate.hasSparkles, false);
      expect(EvolutionPhase.radiant.hasSparkles, false);
      expect(EvolutionPhase.ascended.hasSparkles, true);
    });
  });
}
