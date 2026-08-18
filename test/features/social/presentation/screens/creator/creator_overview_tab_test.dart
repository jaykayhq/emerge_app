import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_overview_tab.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';

Widget _buildTest({bool isAdmin = true}) {
  return ProviderScope(
    overrides: [
      isAdminUserProvider.overrideWith((ref) async => isAdmin),
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(
          const UserProfile(
            uid: 'test-uid',
            displayName: 'Test Creator',
            archetype: UserArchetype.creator,
          ),
        ),
      ),
      allBlueprintsStreamProvider.overrideWith((ref) => Stream.value([])),
      creatorProfileProvider.overrideWith((ref, uid) => Stream.value(null)),
    ],
    child: const MaterialApp(home: CreatorOverviewTab()),
  );
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('CreatorOverviewTab renders with welcome message', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Creator Hub'), findsOneWidget);
    expect(find.textContaining('Welcome back'), findsOneWidget);
  });

  testWidgets('overview shows the Invite Creators entry', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Invite Creators'),
      200,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Invite Creators'), findsOneWidget);
  });

  testWidgets('overview hides Invite Creators from non-admin creators', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTest(isAdmin: false));
    await tester.pumpAndSettle();

    expect(find.text('Invite Creators'), findsNothing);
  });
}
