import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 91 chars → typing takes 2600 ms at the default 35 cps, so the script is
/// still mid-typing after a short pump and finished after pump(seconds: 3).
const longScript =
    'First step: look around and find the highlighted section, then press '
    'the button when ready.';

Widget wrap(NarratorGuideCard card) {
  return MaterialApp(
    home: Scaffold(body: Center(child: card)),
  );
}

void main() {
  testWidgets('advance is disabled until the script finishes typing', (
    tester,
  ) async {
    var advances = 0;
    await tester.pumpWidget(
      wrap(
        NarratorGuideCard(
          script: longScript,
          stepIndex: 0,
          stepCount: 2,
          onAdvance: () => advances++,
          onSkip: () {},
        ),
      ),
    );
    await tester.pump(); // typing starts
    await tester.pump(const Duration(milliseconds: 300)); // still mid-script

    // The card's advance button is the only Semantics with button:true AND a
    // label (the skip IconButton also exposes button:true, but no label).
    final advanceButton = find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          w.properties.button == true &&
          w.properties.label == 'Next',
    );
    expect(tester.widget<Semantics>(advanceButton).properties.enabled, isFalse);

    // Let the 2.6 s script finish typing.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(); // rebuild after onComplete
    expect(tester.widget<Semantics>(advanceButton).properties.enabled, isTrue);
  });

  testWidgets('skip fires onSkip', (tester) async {
    var skips = 0;
    await tester.pumpWidget(
      wrap(
        NarratorGuideCard(
          script: 'Short script.',
          stepIndex: 0,
          stepCount: 1,
          onAdvance: () {},
          onSkip: () => skips++,
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(skips, 1);
  });
}
