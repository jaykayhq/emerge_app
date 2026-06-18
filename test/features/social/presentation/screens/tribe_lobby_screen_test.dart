import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_lobby_screen.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';

Widget _buildTest() {
  return ProviderScope(
    overrides: [
      userStatsStreamProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
      allArchetypeClubsProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
    ],
    child: const MaterialApp(home: TribeLobbyScreen()),
  );
}

void main() {
  testWidgets('TribeLobbyScreen renders loading skeleton', (tester) async {
    // Suppress network image errors in test environment
    final errors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
    };
    addTearDown(() {
      FlutterError.onError = oldHandler;
    });

    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TribeLobbyScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    // Ensure the only errors are from network images
    expect(errors.length, greaterThanOrEqualTo(1));
    for (final error in errors) {
      expect(error.exception, isA<NetworkImageLoadException>());
    }
  });
}
