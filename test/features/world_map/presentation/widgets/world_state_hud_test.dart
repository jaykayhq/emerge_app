import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_state_hud.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Happy path
  // ---------------------------------------------------------------------------
  testWidgets('WorldStateHUD displays vitality and entropy from providers',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldHealthStreamProvider.overrideWith((_) => Stream.value(0.8)),
          worldEntropyStreamProvider.overrideWith((_) => Stream.value(0.2)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WorldStateHUD()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VITALITY'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('ENTROPY'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Boundary values
  // ---------------------------------------------------------------------------
  testWidgets('WorldStateHUD shows 0% and 100% at boundary values',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldHealthStreamProvider.overrideWith((_) => Stream.value(1.0)),
          worldEntropyStreamProvider.overrideWith((_) => Stream.value(0.0)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WorldStateHUD()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------
  testWidgets('WorldStateHUD shows loading indicator while streams are pending',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Stream.empty() never emits — keeps provider in AsyncLoading state.
          worldHealthStreamProvider.overrideWith((_) => const Stream.empty()),
          worldEntropyStreamProvider.overrideWith((_) => const Stream.empty()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WorldStateHUD()),
        ),
      ),
    );

    // Single frame after first build — streams have not emitted yet.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // No percentages should be visible in loading state.
    expect(find.textContaining('%'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------
  testWidgets('WorldStateHUD shows dashes and does not crash on stream error',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldHealthStreamProvider.overrideWith(
              (_) => Stream.error(Exception('health error'))),
          worldEntropyStreamProvider.overrideWith(
              (_) => Stream.error(Exception('entropy error'))),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WorldStateHUD()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Error state shows dashes, never percentages.
    expect(find.text('--'), findsWidgets);
    expect(find.textContaining('%'), findsNothing);
  });
}
