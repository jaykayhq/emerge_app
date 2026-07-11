import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_state_hud.dart';

void main() {
  testWidgets('WorldStateHUD displays vitality and entropy from providers', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.8)),
          worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.2)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WorldStateHUD(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('VITALITY'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);

    expect(find.text('ENTROPY'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
  });
}
