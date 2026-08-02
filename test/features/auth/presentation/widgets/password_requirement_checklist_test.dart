import 'package:emerge_app/features/auth/presentation/widgets/password_requirement_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(TextEditingController controller) {
  return MaterialApp(
    home: Scaffold(
      body: PasswordRequirementChecklist(passwordController: controller),
    ),
  );
}

void main() {
  testWidgets('hidden while the password field is empty', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));

    expect(find.byType(PasswordRequirementChecklist), findsOneWidget);
    expect(find.text('At least 12 characters'), findsNothing);
  });

  testWidgets('appears while typing and ticks items as rules pass',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    controller.text = 'abc';
    await tester.pump();

    expect(find.text('At least 12 characters'), findsOneWidget);
    expect(find.text('3 of 4 character types'), findsOneWidget);

    controller.text = 'Tr0ub4dor&3!';
    await tester.pump();

    // All rules pass -> collapses to a single success line.
    expect(find.text('Password looks good'), findsOneWidget);
    expect(find.text('At least 12 characters'), findsNothing);
  });

  testWidgets('hides again when the field is cleared', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    controller.text = 'abc';
    await tester.pump();
    expect(find.text('At least 12 characters'), findsOneWidget);

    controller.clear();
    await tester.pump();
    expect(find.text('At least 12 characters'), findsNothing);
  });
}
