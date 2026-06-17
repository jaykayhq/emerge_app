import 'package:emerge_app/core/domain/entities/cue.dart';
import 'package:emerge_app/core/services/cue_engine.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/presentation/providers/cue_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCueEngine extends Mock implements CueEngine {}

ProviderContainer _makeContainer(CueEngine engine) {
  return ProviderContainer(
    overrides: [
      cueEngineProvider.overrideWithValue(engine),
    ],
  );
}

void main() {
  late MockCueEngine mockEngine;

  setUp(() {
    mockEngine = MockCueEngine();
  });

  group('cueNotifierProvider', () {
    test('calls engine.initialize on initialize', () async {
      when(() => mockEngine.initialize(archetype: any(named: 'archetype')))
          .thenAnswer((_) async => {});

      final container = _makeContainer(mockEngine);
      await container.read(cueNotifierProvider.notifier).initialize(UserArchetype.athlete);
      verify(() => mockEngine.initialize(archetype: UserArchetype.athlete)).called(1);
      container.dispose();
    });

    test('calls engine methods for markActionTaken', () {
      when(() => mockEngine.markActionTaken('cue-1', timeToAction: any(named: 'timeToAction')))
          .thenReturn(null);

      final container = _makeContainer(mockEngine);
      container.read(cueNotifierProvider.notifier).markActionTaken('cue-1');
      verify(() => mockEngine.markActionTaken('cue-1', timeToAction: any(named: 'timeToAction'))).called(1);
      container.dispose();
    });

    test('calls engine.markDismissed', () {
      when(() => mockEngine.markDismissed('cue-1')).thenReturn(null);

      final container = _makeContainer(mockEngine);
      container.read(cueNotifierProvider.notifier).markDismissed('cue-1');
      verify(() => mockEngine.markDismissed('cue-1')).called(1);
      container.dispose();
    });
  });

  group('cueMetricsProvider', () {
    test('returns metrics from engine', () {
      when(() => mockEngine.getMetrics('cue-1')).thenReturn(
        const CueEngagementMetrics(cueId: 'cue-1', conversions: 1),
      );

      final container = _makeContainer(mockEngine);
      final result = container.read(cueMetricsProvider('cue-1'));
      expect(result, isNotNull);
      expect(result!.conversions, 1);
      container.dispose();
    });

    test('returns null for unknown cueId', () {
      when(() => mockEngine.getMetrics('unknown')).thenReturn(null);

      final container = _makeContainer(mockEngine);
      final result = container.read(cueMetricsProvider('unknown'));
      expect(result, isNull);
      container.dispose();
    });
  });

  group('cuePerformanceProvider', () {
    test('returns performance map from engine', () {
      when(() => mockEngine.getOverallPerformance()).thenReturn({'rate': 0.8});

      final container = _makeContainer(mockEngine);
      final result = container.read(cuePerformanceProvider);
      expect(result['rate'], 0.8);
      container.dispose();
    });
  });
}
