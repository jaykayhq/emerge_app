import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_primary_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: child),
      );

  testWidgets('renders label as UPPERCASE', (tester) async {
    await tester.pumpWidget(
      wrap(
        EmergePrimaryButton(label: 'click me', onPressed: () {}),
      ),
    );

    expect(find.text('CLICK ME'), findsOneWidget);
    expect(find.text('click me'), findsNothing);
  });

  testWidgets('shows CircularProgressIndicator and hides label when isLoading',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        EmergePrimaryButton(
          label: 'loading button',
          onPressed: () {},
          isLoading: true,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('LOADING BUTTON'), findsNothing);
  });

  testWidgets('onPressed null produces non-interactive button (opacity 0.55)',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const EmergePrimaryButton(label: 'disabled', onPressed: null),
      ),
    );

    final opacityWidget = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(EmergePrimaryButton),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacityWidget.opacity, 0.55);

    // Tapping should not throw; onTap is wired to null on the InkWell.
    await tester.tap(find.byType(EmergePrimaryButton));
    await tester.pump();
  });

  testWidgets('onPressed provided makes the button interactive', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        EmergePrimaryButton(label: 'tap', onPressed: () => taps++),
      ),
    );

    final opacityWidget = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(EmergePrimaryButton),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacityWidget.opacity, 1.0);

    await tester.tap(find.byType(EmergePrimaryButton));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('leadingIcon and trailingIcon render when provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        const EmergePrimaryButton(
          label: 'with icons',
          onPressed: noopFn,
          leadingIcon: Icons.bolt,
          trailingIcon: Icons.arrow_forward,
        ),
      ),
    );

    expect(find.byIcon(Icons.bolt), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text('WITH ICONS'), findsOneWidget);
  });

  testWidgets('fullWidth=true wraps in SizedBox(width=double.infinity)',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const EmergePrimaryButton(
          label: 'full width',
          onPressed: noopFn,
        ),
      ),
    );

    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(EmergePrimaryButton),
        matching: find.byType(SizedBox),
      ),
    );
    expect(sizedBox.width, double.infinity);
  });

  testWidgets('fullWidth=false does not constrain SizedBox width',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const EmergePrimaryButton(
          label: 'auto width',
          onPressed: noopFn,
          fullWidth: false,
        ),
      ),
    );

    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(EmergePrimaryButton),
        matching: find.byType(SizedBox),
      ),
    );
    expect(sizedBox.width, isNull);
  });
}

void noopFn() {}
