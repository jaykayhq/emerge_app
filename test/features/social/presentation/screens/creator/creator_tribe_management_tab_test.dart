import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_tribe_management_tab.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

Widget _buildTest() {
  return ProviderScope(
    overrides: [
      creatorProfileProvider.overrideWith(
        (ref, uid) => Stream.value(null),
      ),
      realTimeTribeStatsProvider.overrideWith(
        (ref, tribeId) => const Stream.empty(),
      ),
    ],
    child: const MaterialApp(home: CreatorTribeManagementTab()),
  );
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('CreatorTribeManagementTab renders no-tribe state',
      (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No Tribe Yet'), findsOneWidget);
    expect(
      find.text(
        'Publish a blueprint to automatically create your creator tribe.',
      ),
      findsOneWidget,
    );
  });
}
