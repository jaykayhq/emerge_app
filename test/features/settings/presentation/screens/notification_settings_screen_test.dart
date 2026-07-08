import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/settings/presentation/screens/notification_settings_screen.dart';

final testProfile = UserProfile(
  uid: 'test-uid',
  settings: const UserSettings(
    notificationsEnabled: true,
    habitReminders: true,
    streakWarnings: false,
    aiInsights: true,
  ),
);

Widget createTest() {
  return ProviderScope(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(testProfile),
      ),
      worldHealthStreamProvider.overrideWith(
        (ref) => Stream.value(0.5),
      ),
      worldEntropyStreamProvider.overrideWith(
        (ref) => Stream.value(0.0),
      ),
    ],
    child: const MaterialApp(
      home: NotificationSettingsScreen(),
    ),
  );
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('renders notification settings', (tester) async {
    await tester.pumpWidget(createTest());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Allow All Notifications'), findsOneWidget);
    expect(find.text('NOTIFICATION TYPES'), findsOneWidget);
    expect(find.text('Habit Reminders'), findsOneWidget);

    // Scroll to General Settings section
    await tester.drag(
      find.byType(ListView),
      const Offset(0, -500),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('GENERAL SETTINGS'), findsOneWidget);
    expect(find.text('Notification Sound'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
    expect(find.text('Do Not Disturb'), findsOneWidget);
  });
}
