import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:emerge_app/features/health/presentation/widgets/screen_time_tile.dart';

void main() {
  testWidgets('ScreenTimeTile renders disconnected state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ScreenTimeTile(isConnected: false, onTap: () {})),
      ),
    );

    expect(find.text('Connect Screen Time'), findsOneWidget);
    expect(find.text('Not Connected'), findsOneWidget);
  });

  testWidgets('ScreenTimeTile renders connected state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ScreenTimeTile(isConnected: true, onTap: () {})),
      ),
    );

    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('ScreenTimeTile fires onTap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScreenTimeTile(isConnected: false, onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.text('Connect Screen Time'));
    expect(tapped, isTrue);
  });
}
