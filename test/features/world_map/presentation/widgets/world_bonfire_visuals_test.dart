import 'package:emerge_app/features/world_map/presentation/widgets/world_bonfire_visuals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorldBonfireVisualState', () {
    test('keeps a small ember alive at zero health', () {
      final state = WorldBonfireVisualState.fromHealth(-1.0);

      expect(state.health, 0.0);
      expect(state.emberCount, 1);
      expect(state.flameScale, closeTo(0.48, 0.001));
      expect(state.glowOpacity, closeTo(0.10, 0.001));
    });

    test('grows the flame and increases embers with health', () {
      final low = WorldBonfireVisualState.fromHealth(0.2);
      final thriving = WorldBonfireVisualState.fromHealth(1.0);

      expect(thriving.health, 1.0);
      expect(thriving.flameScale, greaterThan(low.flameScale));
      expect(thriving.flameWidth, greaterThan(low.flameWidth));
      expect(thriving.glowOpacity, greaterThan(low.glowOpacity));
      expect(thriving.emberCount, 5);
    });

    test('uses neutral health for non-finite input', () {
      final state = WorldBonfireVisualState.fromHealth(double.nan);

      expect(state.health, 0.5);
      expect(state.emberCount, 3);
    });

    test('keeps the visible hearth bounds centered at every health level', () {
      for (final health in [0.0, 0.5, 1.0]) {
        final geometry = WorldBonfireGeometry.fromVisualState(
          visualState: WorldBonfireVisualState.fromHealth(health),
          size: 216,
        );

        expect(geometry.visibleBounds.center.dx, closeTo(108, 0.001));
        expect(geometry.visibleBounds.center.dy, closeTo(108, 0.001));
        expect(
          geometry.visibleBounds.width,
          greaterThanOrEqualTo(170 * geometry.unit),
        );
        expect(geometry.coreRect.top, lessThan(geometry.baseY));
        expect(geometry.coreRect.bottom, greaterThan(geometry.baseY));
      }
    });

    test('uses a larger responsive footprint for the centered hearth', () {
      expect(WorldBonfireGeometry.footprintFor(320), 200);
      expect(WorldBonfireGeometry.footprintFor(390), 224);
      expect(WorldBonfireGeometry.footprintFor(900), 224);
    });
  });
}
