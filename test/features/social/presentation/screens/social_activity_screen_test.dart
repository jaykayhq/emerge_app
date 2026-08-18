import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/presentation/providers/partner_activity_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/social_activity_screen.dart';

Widget buildTest({
  String? tribeId,
  Stream<List<Map<String, dynamic>>> Function()? partnerActivityStream,
}) {
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
        (ref) =>
            partnerActivityStream?.call() ??
            Stream.value(<Map<String, dynamic>>[]),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                SocialActivityScreen(tribeId: tribeId ?? 'morning_warriors'),
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

  testWidgets('Partners tab empty state prompts to add partner', (
    tester,
  ) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final gestureDetector = tester.widget<GestureDetector>(
      find
          .ancestor(
            of: find.text('PARTNERS'),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    gestureDetector.onTap!();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Find a partner'), findsOneWidget);
  });

  testWidgets(
    'Partners tab error state shows retry affordance and Retry re-subscribes',
    (tester) async {
      var subscribeCount = 0;
      await tester.pumpWidget(
        buildTest(
          partnerActivityStream: () {
            subscribeCount++;
            if (subscribeCount == 1) {
              // An Error (not Exception) so Riverpod's defaultRetry does not
              // auto-resubscribe the failed stream mid-test.
              return Stream<List<Map<String, dynamic>>>.error(
                StateError('permission-denied'),
              );
            }
            return Stream.value(<Map<String, dynamic>>[]);
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Switch to the Partners tab to start watching the provider.
      final gestureDetector = tester.widget<GestureDetector>(
        find
            .ancestor(
              of: find.text('PARTNERS'),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      gestureDetector.onTap!();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Error state renders the message plus a Retry affordance.
      expect(subscribeCount, 1);
      expect(find.text('Could not load partner activity.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tapping Retry invalidates the provider, re-subscribing the stream.
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(subscribeCount, 2);
      expect(find.text('No partner activity yet.'), findsOneWidget);
    },
  );
}
