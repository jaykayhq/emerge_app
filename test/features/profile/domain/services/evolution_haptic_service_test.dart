import 'package:emerge_app/features/profile/domain/services/evolution_haptic_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EvolutionHapticService service;

  setUp(() {
    service = EvolutionHapticService();
  });

  group('EvolutionHapticService', () {
    group('sync methods', () {
      test('breathPulse does not throw', () {
        expect(() => service.breathPulse(), returnsNormally);
      });

      test('compressionStart does not throw', () {
        expect(() => service.compressionStart(), returnsNormally);
      });

      test('flashImpact does not throw', () {
        expect(() => service.flashImpact(), returnsNormally);
      });

      test('habitVoteRegistered does not throw', () {
        expect(() => service.habitVoteRegistered(), returnsNormally);
      });

      test('silhouetteTap does not throw', () {
        expect(() => service.silhouetteTap(), returnsNormally);
      });
    });

    group('async methods', () {
      test('expansionRumble completes without error', () async {
        await expectLater(service.expansionRumble(), completes);
      });

      test('evolutionComplete completes without error', () async {
        await expectLater(service.evolutionComplete(), completes);
      });

      test('artifactUnlock completes without error', () async {
        await expectLater(service.artifactUnlock(), completes);
      });

      test('entropyWarning completes without error', () async {
        await expectLater(service.entropyWarning(), completes);
      });

      test('streakMilestone completes without error', () async {
        await expectLater(service.streakMilestone(), completes);
      });

      test('runEvolutionSequence completes without error', () async {
        await expectLater(
          service.runEvolutionSequence(
            compressionDuration: const Duration(milliseconds: 10),
            flashDuration: const Duration(milliseconds: 10),
            expansionDuration: const Duration(milliseconds: 10),
          ),
          completes,
        );
      });
    });
  });
}
