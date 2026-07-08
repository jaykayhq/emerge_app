import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/presentation/screens/social_contacts_screen.dart';

Widget buildTest() {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const SocialContactsScreen(),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('SocialContactsScreen renders permission gate initially',
      (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Header is shown.
    expect(find.text('FIND FROM CONTACTS'), findsOneWidget);
    // Permission rationale is shown.
    expect(
      find.textContaining('Find people you know from your address book'),
      findsOneWidget,
    );
  });
}
