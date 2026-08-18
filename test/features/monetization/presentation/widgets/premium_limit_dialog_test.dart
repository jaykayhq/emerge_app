import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_limit_dialog.dart';

GoRouter _router(Widget home) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const Scaffold(body: Text('PAYWALL')),
      ),
    ],
  );
}

void main() {
  testWidgets('habit limit shows aspiration copy + CTA', (tester) async {
    final home = Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showPremiumLimitDialog(
            context,
            limitType: PremiumLimitType.habit,
          ),
          child: const Text('Show'),
        ),
      ),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router(home)));
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text("You've reached 5 habits"), findsOneWidget);
    expect(find.text("SHOW ME WHAT I'M MISSING"), findsOneWidget);
    expect(find.text('Stay focused for now'), findsOneWidget);
  });

  testWidgets('club limit shows club copy', (tester) async {
    final home = Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () =>
              showPremiumLimitDialog(context, limitType: PremiumLimitType.club),
          child: const Text('Show'),
        ),
      ),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router(home)));
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text("You've joined 1 club"), findsOneWidget);
  });

  testWidgets('CTA routes to paywall', (tester) async {
    final home = Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showPremiumLimitDialog(
            context,
            limitType: PremiumLimitType.habit,
          ),
          child: const Text('Show'),
        ),
      ),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router(home)));
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    await tester.tap(find.text("SHOW ME WHAT I'M MISSING"));
    await tester.pumpAndSettle();

    expect(find.text('PAYWALL'), findsOneWidget);
  });
}
