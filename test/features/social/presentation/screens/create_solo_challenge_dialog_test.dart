import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/create_solo_challenge_dialog.dart';

void main() {
  testWidgets('CreateSoloChallengeDialog renders form elements', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: CreateSoloChallengeDialog()),
      ),
    );
    await tester.pump();

    expect(find.text('SOLO CHALLENGE'), findsOneWidget);
    expect(find.text('FORGE CHALLENGE'), findsOneWidget);
  });
}
