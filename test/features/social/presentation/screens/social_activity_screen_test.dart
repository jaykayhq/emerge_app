import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/presentation/providers/partner_activity_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/social_activity_screen.dart';

Widget buildTest({String? tribeId}) {
  return ProviderScope(
    overrides: [
      clubActivityProvider.overrideWith(
        (ref, arg) => Stream.value([
          {
            'id': 'e1',
            'type': 'habit_complete',
            'userName': 'Alex',
            'data': {'habitTitle': 'Cold Plunge'},
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          },
        ]),
      ),
      partnerActivityProvider.overrideWith(
        (ref) => Stream.value(<Map<String, dynamic>>[]),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => SocialActivityScreen(
              tribeId: tribeId ?? 'morning_warriors',
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('renders Tribe tab and Partners tab headers', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('TRIBE'), findsOneWidget);
    expect(find.text('PARTNERS'), findsOneWidget);
  });

  testWidgets('Tribe tab shows club activity entries', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Alex'), findsOneWidget);
    expect(find.textContaining('Cold Plunge'), findsOneWidget);
  });

  testWidgets('Partners tab empty state prompts to add partner', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final gestureDetector = tester.widget<GestureDetector>(
      find.ancestor(
        of: find.text('PARTNERS'),
        matching: find.byType(GestureDetector),
      ).first,
    );
    gestureDetector.onTap!();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Find a partner'), findsOneWidget);
  });
}
