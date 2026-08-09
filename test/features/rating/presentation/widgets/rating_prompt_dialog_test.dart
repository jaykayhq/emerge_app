import 'package:emerge_app/features/rating/presentation/widgets/rating_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders stars and Not now', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showRatingPromptDialog(
            context,
            onRating: (_) {},
            onNotNow: () {},
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('How is Emerge going?'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsWidgets);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('tapping a star routes the rating', (tester) async {
    int? selected;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showRatingPromptDialog(
            context,
            onRating: (r) => selected = r,
            onNotNow: () {},
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pumpAndSettle();
    expect(selected, isNotNull);
  });

  testWidgets('tapping Not now invokes onNotNow', (tester) async {
    var notNow = false;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showRatingPromptDialog(
            context,
            onRating: (_) {},
            onNotNow: () => notNow = true,
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(notNow, isTrue);
  });
}
