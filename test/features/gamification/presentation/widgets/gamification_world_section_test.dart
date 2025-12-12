import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/gamification_world_section.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/world_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GamificationWorldSection renders loading state initially',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GamificationWorldSection(),
          ),
        ),
      ),
    );

    // Should show loading initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('GamificationWorldSection renders WorldView when data is loaded',
      (tester) async {
    final mockUser = UserExtension(
      id: '1',
      email: 'test@test.com',
      worldState: const UserWorldState(),
      archetype: UserArchetype.creator,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsStreamProvider.overrideWith((ref) => Stream.value(mockUser)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GamificationWorldSection(),
          ),
        ),
      ),
    );

    // Pump to settle the stream
    await tester.pump();

    // Should show WorldView
    expect(find.byType(WorldView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
