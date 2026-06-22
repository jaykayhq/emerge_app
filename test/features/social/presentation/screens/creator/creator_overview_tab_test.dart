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

Widget _buildTest() {
  return ProviderScope(
    overrides: [
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(
          const UserProfile(
            uid: 'test-uid',
            displayName: 'Test Creator',
            archetype: UserArchetype.creator,
          ),
        ),
      ),
      allBlueprintsStreamProvider.overrideWith(
        (ref) => Stream.value([]),
      ),
      creatorProfileProvider.overrideWith(
        (ref, uid) => Stream.value(null),
      ),
    ],
    child: const MaterialApp(home: CreatorOverviewTab()),
  );
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('CreatorOverviewTab renders with welcome message',
      (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Creator Hub'), findsOneWidget);
    expect(find.textContaining('Welcome back'), findsOneWidget);
  });
}
