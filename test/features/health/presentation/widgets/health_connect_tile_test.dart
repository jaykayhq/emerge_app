import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:emerge_app/features/health/presentation/widgets/health_connect_tile.dart';

void main() {
  testWidgets('HealthConnectTile renders disconnected state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HealthConnectTile(isConnected: false, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Connect Health Data'), findsOneWidget);
    expect(find.text('Not Connected'), findsOneWidget);
  });

  testWidgets('HealthConnectTile renders connected state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HealthConnectTile(isConnected: true, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('HealthConnectTile fires onTap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HealthConnectTile(
            isConnected: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Connect Health Data'));
    expect(tapped, isTrue);
  });
}
