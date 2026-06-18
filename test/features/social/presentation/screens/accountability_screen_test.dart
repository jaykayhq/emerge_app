import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/accountability_screen.dart';

void main() {
  testWidgets('AccountabilityScreen renders all sections', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(home: AccountabilityScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Accountability'), findsOneWidget);
    expect(find.text('Active Commitments'), findsOneWidget);
    expect(find.text('Pending Requests'), findsOneWidget);
    expect(find.text('Your Partners'), findsOneWidget);
    expect(find.text('30 Day Meditation Streak'), findsOneWidget);
    expect(find.text('Race to 5k Steps'), findsOneWidget);
  });
}
