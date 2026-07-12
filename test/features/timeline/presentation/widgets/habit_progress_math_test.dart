import 'package:emerge_app/features/timeline/presentation/widgets/habit_progress_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('habitCardFillFraction', () {
    test('totalSeconds=0 returns 0 (no progress visible)', () {
      expect(habitCardFillFraction(remainingSeconds: 0, totalSeconds: 0), 0.0);
    });

    test('totalSeconds>0 and remainingSeconds=totalSeconds returns 0', () {
      expect(habitCardFillFraction(remainingSeconds: 120, totalSeconds: 120), 0.0);
    });

    test('remainingSeconds=0 returns 1 (fully filled)', () {
      expect(habitCardFillFraction(remainingSeconds: 0, totalSeconds: 120), 1.0);
    });

    test('halfway returns ~0.5', () {
      expect(habitCardFillFraction(remainingSeconds: 60, totalSeconds: 120), closeTo(0.5, 1e-9));
    });

    test('remainingSeconds > totalSeconds clamps to 0 (defensive)', () {
      expect(habitCardFillFraction(remainingSeconds: 200, totalSeconds: 120), 0.0);
    });

    test('negative remainingSeconds clamps to 1 (defensive)', () {
      expect(habitCardFillFraction(remainingSeconds: -5, totalSeconds: 120), 1.0);
    });

    test('progresses monotonically as remainingSeconds decreases', () {
      double prev = 0;
      for (int r = 120; r >= 0; r -= 30) {
        final f = habitCardFillFraction(remainingSeconds: r, totalSeconds: 120);
        expect(f, greaterThanOrEqualTo(prev));
        prev = f;
      }
    });
  });
}
