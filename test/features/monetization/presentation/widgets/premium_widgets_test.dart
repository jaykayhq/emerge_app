import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_badge.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_theme_preview.dart';

void main() {
  testWidgets('PremiumBadge renders a star and animates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: PremiumBadge(size: 24))),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.star), findsOneWidget);
    // Let a couple of animation frames elapse without throwing.
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('PremiumBadge with showShimmer=false still renders', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: PremiumBadge(size: 24, showShimmer: false)),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('PremiumThemePreview shows locked preview and reveals on tap', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: PremiumThemePreview(
              themeName: 'Cosmic Void',
              description: 'A deep-space theme for premium users.',
            ),
          ),
        ),
        GoRoute(
          path: '/paywall',
          builder: (context, state) => const Scaffold(body: Text('PAYWALL')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('Cosmic Void'), findsOneWidget);
    expect(find.text('Tap to preview'), findsOneWidget);

    await tester.tap(find.text('Tap to preview'));
    await tester.pumpAndSettle();

    expect(find.text('A deep-space theme for premium users.'), findsOneWidget);
    expect(find.text('Unlock Premium'), findsOneWidget);

    await tester.tap(find.text('Unlock Premium'));
    await tester.pumpAndSettle();
    expect(find.text('PAYWALL'), findsOneWidget);
  });
}
