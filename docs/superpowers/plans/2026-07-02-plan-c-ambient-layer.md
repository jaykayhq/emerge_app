# Habitual Engagement — Plan C: Ambient Layer

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Emerge reachable without opening the app — add a home screen widget (2×2 and 4×2) for one-tap habit completion via Drift offline-first sync, add inline notification action buttons (Complete / Snooze), and rebuild the Tribe tab as a Pulse Feed of identity-aligned content.

**Architecture:** The home widget is a Flutter `home_widget` package integration reading from Drift. Notifications gain `Complete` and `Snooze` action buttons via FCM + `flutter_local_notifications`. The Pulse Feed is a new Riverpod-powered sliver that replaces `TribeLobbyScreen`, backed by a `PulseFeedCard` Firestore collection.

**Tech Stack:** Flutter, Dart, Riverpod 3, Drift, `home_widget ^0.5.0`, `flutter_local_notifications ^18`, Firestore, fpdart `Either`

**Prerequisite:** Plan A must be complete. `HabitCompletionService` and `CompletionSource` must exist.

---

## Context You Must Read First

- `lib/features/social/presentation/screens/tribe_lobby_screen.dart` — read it in full; this is being rebuilt as `PulseFeedScreen`.
- `lib/core/services/notification_service.dart` — find where `FlutterLocalNotificationsPlugin.show()` is called. Notification action buttons are added here.
- `lib/core/router/router.dart` — find the `/social` branch. The `TribeLobbyScreen` route is being replaced with `PulseFeedScreen`.
- `pubspec.yaml` — check if `home_widget` and `flutter_local_notifications` are already listed. Add them if not.
- `android/app/src/main/AndroidManifest.xml` — you will need to add a widget receiver here.
- `ios/Runner/Info.plist` — you will need to add a widget extension entry (iOS widget extensions are out of scope for this plan — Android only).

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| CREATE | `lib/features/widget/habit_widget_service.dart` | Reads today's habits from Drift, writes to home_widget SharedPreferences |
| CREATE | `android/app/src/main/res/xml/habit_widget_info.xml` | Android widget metadata (2×2) |
| CREATE | `android/app/src/main/res/layout/habit_widget_layout.xml` | Android widget XML layout |
| CREATE | `android/app/src/main/java/.../HabitWidgetProvider.kt` | Android `AppWidgetProvider` glue |
| CREATE | `lib/features/pulse_feed/domain/models/pulse_feed_card.dart` | Data model |
| CREATE | `lib/features/pulse_feed/data/repositories/pulse_feed_repository.dart` | Firestore read |
| CREATE | `lib/features/pulse_feed/presentation/providers/pulse_feed_providers.dart` | Riverpod provider |
| CREATE | `lib/features/pulse_feed/presentation/screens/pulse_feed_screen.dart` | New Tribe tab screen |
| CREATE | `lib/features/pulse_feed/presentation/widgets/pulse_card_widget.dart` | Individual card |
| MODIFY | `lib/core/services/notification_service.dart` | Add Complete / Snooze action buttons |
| MODIFY | `lib/core/router/router.dart` | Replace TribeLobbyScreen with PulseFeedScreen |
| MODIFY | `pubspec.yaml` | Add home_widget, flutter_local_notifications |
| MODIFY | `android/app/src/main/AndroidManifest.xml` | Register widget receiver |
| CREATE | `test/features/pulse_feed/data/repositories/pulse_feed_repository_test.dart` | Unit tests |
| CREATE | `test/features/widget/habit_widget_service_test.dart` | Unit tests |

---

## Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1.1: Check and add packages**

Open `pubspec.yaml`. In the `dependencies:` section, add if not already present:

```yaml
dependencies:
  home_widget: ^0.5.0
  flutter_local_notifications: ^18.0.0
  workmanager: ^0.5.2   # for background widget refresh on Android
```

- [ ] **Step 1.2: Install**

```bash
flutter pub get
```

Expected: No version conflicts. If there are conflicts, check existing `flutter_local_notifications` version in `pubspec.lock` and pin to that version instead.

- [ ] **Step 1.3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add home_widget, flutter_local_notifications, workmanager deps"
```

---

## Task 2: Notification inline actions (Complete / Snooze)

**Files:**
- Modify: `lib/core/services/notification_service.dart`

### Background
Currently, habit reminders are scheduled via `flutter_local_notifications`. Tapping the notification opens the app. We are adding two **action buttons** directly on the notification:
- **Complete** — marks the habit done via `HabitCompletionService`, no app open required
- **Snooze 1h** — reschedules the notification for 1 hour later

Action buttons on notifications work through `onDidReceiveBackgroundNotificationResponse` (Android) and `onDidReceiveNotificationResponse` (foreground). The handler calls `HabitCompletionService.markComplete()` directly.

- [ ] **Step 2.1: Write test for action handling**

```dart
// test/core/services/notification_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/habits/data/services/habit_completion_service.dart';
import 'package:emerge_app/features/habits/domain/models/completion_result.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

class MockHabitCompletionService extends Mock implements HabitCompletionService {}

void main() {
  late MockHabitCompletionService mockService;

  setUp(() {
    mockService = MockHabitCompletionService();
  });

  test('handleNotificationAction calls markComplete with notification source on Complete', () async {
    when(() => mockService.markComplete(
      any(),
      source: CompletionSource.notification,
    )).thenAnswer((_) async => CompletionResult(
      habitId: 'h1',
      xpEarned: 25,
      newStreakState: HabitStreakState.building,
      newMomentumScore: 50,
      newWorldHealthDelta: 2,
    ));

    await NotificationActionHandler.handle(
      actionId: 'complete',
      habitId: 'h1',
      completionService: mockService,
    );

    verify(() => mockService.markComplete(
      'h1',
      source: CompletionSource.notification,
    )).called(1);
  });
}
```

- [ ] **Step 2.2: Run — expect compile error**

```bash
flutter test test/core/services/notification_service_test.dart
```

- [ ] **Step 2.3: Create `NotificationActionHandler`**

Add this class to `lib/core/services/notification_service.dart` (or create a new file `lib/core/services/notification_action_handler.dart` if the existing file is large):

```dart
// Add to lib/core/services/notification_service.dart

import 'package:emerge_app/features/habits/data/services/habit_completion_service.dart';
import 'package:emerge_app/features/habits/domain/models/completion_result.dart';

/// Action IDs used in notification action buttons.
/// These strings must match the actionId registered with flutter_local_notifications.
class NotificationActionIds {
  static const complete = 'complete';
  static const snooze1h = 'snooze_1h';
}

class NotificationActionHandler {
  /// Called from both foreground and background notification response handlers.
  static Future<void> handle({
    required String actionId,
    required String habitId,
    required HabitCompletionService completionService,
  }) async {
    switch (actionId) {
      case NotificationActionIds.complete:
        await completionService.markComplete(
          habitId,
          source: CompletionSource.notification,
        );
        break;
      case NotificationActionIds.snooze1h:
        // Reschedule for 1 hour from now
        // (The actual rescheduling happens in NotificationService._reschedule)
        await NotificationService.instance.snoozeHabit(habitId);
        break;
    }
  }
}
```

- [ ] **Step 2.4: Add action buttons to scheduled notifications**

Find the method in `lib/core/services/notification_service.dart` that calls `flutterLocalNotificationsPlugin.zonedSchedule()` (or `.show()`). Modify the `AndroidNotificationDetails` to include action buttons.

```dart
// BEFORE (approximate):
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'habit_reminders',
  'Habit Reminders',
  importance: Importance.high,
  priority: Priority.high,
);

// AFTER:
final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'habit_reminders',
  'Habit Reminders',
  importance: Importance.high,
  priority: Priority.high,
  actions: [
    const AndroidNotificationAction(
      NotificationActionIds.complete,  // actionId
      'Complete ✓',
      showsUserInterface: false,       // handle silently
      cancelNotification: true,        // dismiss after tapping
    ),
    const AndroidNotificationAction(
      NotificationActionIds.snooze1h,
      'Snooze 1h',
      showsUserInterface: false,
      cancelNotification: true,
    ),
  ],
);
```

- [ ] **Step 2.5: Register background handler**

In `main.dart` (or wherever `FlutterLocalNotificationsPlugin.initialize()` is called), add:

```dart
// This MUST be a top-level function (not inside a class or async main).
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // This runs in a background isolate — no Flutter widgets available.
  // We can only call Dart code that doesn't need BuildContext.
  if (response.actionId != null && response.payload != null) {
    // payload = habitId (set when scheduling the notification)
    // We queue the action to be processed when the app next opens,
    // using SharedPreferences as a simple queue.
    SharedPreferences.getInstance().then((prefs) {
      final queue = prefs.getStringList('pending_notification_actions') ?? [];
      queue.add('${response.actionId}:${response.payload}');
      prefs.setStringList('pending_notification_actions', queue);
    });
  }
}

// In FlutterLocalNotificationsPlugin.initialize() call, add:
await flutterLocalNotificationsPlugin.initialize(
  const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  ),
  onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  onDidReceiveNotificationResponse: (response) {
    // Foreground: handle directly
    if (response.actionId != null && response.payload != null) {
      // Use a GetIt / provider ref stored in a service locator to get
      // HabitCompletionService — or post to an event stream.
      // For now, queue it the same way as background:
      SharedPreferences.getInstance().then((prefs) {
        final queue = prefs.getStringList('pending_notification_actions') ?? [];
        queue.add('${response.actionId}:${response.payload}');
        prefs.setStringList('pending_notification_actions', queue);
      });
    }
  },
);
```

> **Note:** Drain the `pending_notification_actions` queue in `Timeline`'s `initState` via `HabitCompletionService`. Check the queue on every app open.

- [ ] **Step 2.6: Drain queue in Timeline**

In `lib/features/timeline/presentation/screens/timeline_screen.dart`, in `initState` (after `super.initState()`):

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _drainNotificationQueue());
}

Future<void> _drainNotificationQueue() async {
  final prefs = await SharedPreferences.getInstance();
  final queue = prefs.getStringList('pending_notification_actions') ?? [];
  if (queue.isEmpty) return;
  await prefs.setStringList('pending_notification_actions', []);

  final service = ref.read(habitCompletionServiceProvider);
  for (final entry in queue) {
    final parts = entry.split(':');
    if (parts.length == 2) {
      final actionId = parts[0];
      final habitId = parts[1];
      await NotificationActionHandler.handle(
        actionId: actionId,
        habitId: habitId,
        completionService: service,
      );
    }
  }
  // Invalidate habits provider so Timeline refreshes
  ref.invalidate(todayHabitsProvider);
}
```

- [ ] **Step 2.7: Run test — expect green**

```bash
flutter test test/core/services/notification_service_test.dart
```

- [ ] **Step 2.8: Commit**

```bash
git add lib/core/services/notification_service.dart
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git add test/core/services/notification_service_test.dart
git commit -m "feat(notifications): add Complete and Snooze inline action buttons"
```

---

## Task 3: `PulseFeedCard` model

**Files:**
- Create: `lib/features/pulse_feed/domain/models/pulse_feed_card.dart`
- Test: `test/features/pulse_feed/domain/models/pulse_feed_card_test.dart`

### Background
The Pulse Feed replaces the Tribe Lobby tab. It shows a vertical scroll of cards. Each card is one of three types:
- `identityVote` — a completed habit shown as an identity statement ("You showed up as a writer today.")
- `tribeActivity` — someone in the user's tribe completed a habit
- `weeklyInsight` — a Narrator-generated observation surfaced as a card

Cards are read from Firestore (`pulse_feed_cards/{userId}`) and filtered client-side by type. They are generated by a scheduled Cloud Function (out of scope for this plan — treat the collection as already populated with test data).

- [ ] **Step 3.1: Write failing test**

```dart
// test/features/pulse_feed/domain/models/pulse_feed_card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';

void main() {
  test('PulseFeedCard parses identityVote type from string', () {
    final card = PulseFeedCard(
      id: 'c1',
      type: PulseFeedCardType.identityVote,
      headline: 'The writer in you showed up.',
      subtext: '3rd time this week.',
      createdAt: DateTime(2026, 7, 2),
      habitId: 'h1',
    );
    expect(card.type, PulseFeedCardType.identityVote);
    expect(card.headline, 'The writer in you showed up.');
    expect(card.tribeUserId, isNull);
  });

  test('PulseFeedCard.fromJson parses Firestore document', () {
    final json = {
      'id': 'c2',
      'type': 'tribeActivity',
      'headline': 'Alex completed Morning Run.',
      'subtext': '12-day streak',
      'createdAt': DateTime(2026, 7, 2).millisecondsSinceEpoch,
      'tribeUserId': 'user-alex',
    };
    final card = PulseFeedCard.fromJson(json);
    expect(card.type, PulseFeedCardType.tribeActivity);
    expect(card.tribeUserId, 'user-alex');
    expect(card.habitId, isNull);
  });
}
```

- [ ] **Step 3.2: Run — expect compile error**

```bash
flutter test test/features/pulse_feed/domain/models/pulse_feed_card_test.dart
```

- [ ] **Step 3.3: Create `PulseFeedCard`**

```dart
// lib/features/pulse_feed/domain/models/pulse_feed_card.dart

enum PulseFeedCardType {
  identityVote,
  tribeActivity,
  weeklyInsight,
}

class PulseFeedCard {
  final String id;
  final PulseFeedCardType type;
  final String headline;
  final String subtext;
  final DateTime createdAt;
  final String? habitId;
  final String? tribeUserId;

  const PulseFeedCard({
    required this.id,
    required this.type,
    required this.headline,
    required this.subtext,
    required this.createdAt,
    this.habitId,
    this.tribeUserId,
  });

  factory PulseFeedCard.fromJson(Map<String, dynamic> json) {
    return PulseFeedCard(
      id: json['id'] as String,
      type: PulseFeedCardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PulseFeedCardType.identityVote,
      ),
      headline: json['headline'] as String,
      subtext: json['subtext'] as String? ?? '',
      createdAt: json['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : (json['createdAt'] as DateTime? ?? DateTime.now()),
      habitId: json['habitId'] as String?,
      tribeUserId: json['tribeUserId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'headline': headline,
    'subtext': subtext,
    'createdAt': createdAt.millisecondsSinceEpoch,
    if (habitId != null) 'habitId': habitId,
    if (tribeUserId != null) 'tribeUserId': tribeUserId,
  };
}
```

- [ ] **Step 3.4: Run — expect green**

```bash
flutter test test/features/pulse_feed/domain/models/pulse_feed_card_test.dart
```

- [ ] **Step 3.5: Commit**

```bash
git add lib/features/pulse_feed/domain/models/pulse_feed_card.dart
git add test/features/pulse_feed/domain/models/pulse_feed_card_test.dart
git commit -m "feat(pulse-feed): add PulseFeedCard model"
```

---

## Task 4: Pulse Feed repository

**Files:**
- Create: `lib/features/pulse_feed/data/repositories/pulse_feed_repository.dart`
- Test: `test/features/pulse_feed/data/repositories/pulse_feed_repository_test.dart`

- [ ] **Step 4.1: Write failing test**

```dart
// test/features/pulse_feed/data/repositories/pulse_feed_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:emerge_app/features/pulse_feed/data/repositories/pulse_feed_repository.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late PulseFeedRepository sut;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    sut = PulseFeedRepository(firestore: fakeFirestore);
  });

  test('getPulseFeed returns empty list when no cards exist', () async {
    final cards = await sut.getPulseFeed(userId: 'user-1');
    expect(cards, isEmpty);
  });

  test('getPulseFeed returns cards sorted newest first', () async {
    // Seed Firestore with 2 cards
    await fakeFirestore
        .collection('pulse_feed_cards')
        .doc('user-1')
        .collection('cards')
        .doc('c1')
        .set({
      'id': 'c1',
      'type': 'identityVote',
      'headline': 'The writer in you showed up.',
      'subtext': '',
      'createdAt': DateTime(2026, 7, 1).millisecondsSinceEpoch,
    });

    await fakeFirestore
        .collection('pulse_feed_cards')
        .doc('user-1')
        .collection('cards')
        .doc('c2')
        .set({
      'id': 'c2',
      'type': 'tribeActivity',
      'headline': 'Alex completed a habit.',
      'subtext': '',
      'createdAt': DateTime(2026, 7, 2).millisecondsSinceEpoch,
    });

    final cards = await sut.getPulseFeed(userId: 'user-1');
    expect(cards.length, 2);
    // Newest first
    expect(cards[0].id, 'c2');
    expect(cards[1].id, 'c1');
  });

  test('getPulseFeed limits to 30 cards', () async {
    // Seed 35 cards
    for (var i = 0; i < 35; i++) {
      await fakeFirestore
          .collection('pulse_feed_cards')
          .doc('user-1')
          .collection('cards')
          .doc('c$i')
          .set({
        'id': 'c$i',
        'type': 'identityVote',
        'headline': 'Headline $i',
        'subtext': '',
        'createdAt': DateTime(2026, 7, 2)
            .add(Duration(minutes: i))
            .millisecondsSinceEpoch,
      });
    }
    final cards = await sut.getPulseFeed(userId: 'user-1');
    expect(cards.length, 30);
  });
}
```

- [ ] **Step 4.2: Run — expect compile error**

```bash
flutter test test/features/pulse_feed/data/repositories/pulse_feed_repository_test.dart
```

- [ ] **Step 4.3: Create `PulseFeedRepository`**

```dart
// lib/features/pulse_feed/data/repositories/pulse_feed_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';

class PulseFeedRepository {
  final FirebaseFirestore firestore;
  const PulseFeedRepository({required this.firestore});

  Future<List<PulseFeedCard>> getPulseFeed({required String userId}) async {
    final snapshot = await firestore
        .collection('pulse_feed_cards')
        .doc(userId)
        .collection('cards')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();

    return snapshot.docs
        .map((doc) => PulseFeedCard.fromJson({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
  }

  Stream<List<PulseFeedCard>> watchPulseFeed({required String userId}) {
    return firestore
        .collection('pulse_feed_cards')
        .doc(userId)
        .collection('cards')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PulseFeedCard.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }
}
```

- [ ] **Step 4.4: Run — expect green**

```bash
flutter test test/features/pulse_feed/data/repositories/pulse_feed_repository_test.dart
```

- [ ] **Step 4.5: Commit**

```bash
git add lib/features/pulse_feed/data/repositories/pulse_feed_repository.dart
git add test/features/pulse_feed/data/repositories/pulse_feed_repository_test.dart
git commit -m "feat(pulse-feed): add PulseFeedRepository with Firestore queries"
```

---

## Task 5: Pulse Feed Riverpod provider

**Files:**
- Create: `lib/features/pulse_feed/presentation/providers/pulse_feed_providers.dart`

- [ ] **Step 5.1: Create providers**

```dart
// lib/features/pulse_feed/presentation/providers/pulse_feed_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/pulse_feed/data/repositories/pulse_feed_repository.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';

part 'pulse_feed_providers.g.dart';

@Riverpod(keepAlive: true)
PulseFeedRepository pulseFeedRepository(Ref ref) {
  return PulseFeedRepository(firestore: FirebaseFirestore.instance);
}

/// Watches the pulse feed in real-time.
/// Auto-disposes when the feed tab is not visible.
@riverpod
Stream<List<PulseFeedCard>> pulseFeed(Ref ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (userId.isEmpty) return Stream.value([]);
  return ref
      .watch(pulseFeedRepositoryProvider)
      .watchPulseFeed(userId: userId);
}
```

- [ ] **Step 5.2: Regenerate**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5.3: Commit**

```bash
git add lib/features/pulse_feed/presentation/providers/
git commit -m "feat(pulse-feed): add Riverpod providers"
```

---

## Task 6: `PulseCardWidget` UI component

**Files:**
- Create: `lib/features/pulse_feed/presentation/widgets/pulse_card_widget.dart`

- [ ] **Step 6.1: Create `PulseCardWidget`**

```dart
// lib/features/pulse_feed/presentation/widgets/pulse_card_widget.dart
import 'package:flutter/material.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';

class PulseCardWidget extends StatelessWidget {
  final PulseFeedCard card;

  const PulseCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _borderColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _badgeLabel,
              style: TextStyle(
                color: _borderColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Headline
          Text(
            card.headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),

          // Subtext
          if (card.subtext.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              card.subtext,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],

          // Timestamp
          const SizedBox(height: 10),
          Text(
            _timeAgo(card.createdAt),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color get _borderColor {
    switch (card.type) {
      case PulseFeedCardType.identityVote:
        return const Color(0xFF4ECDC4); // teal
      case PulseFeedCardType.tribeActivity:
        return const Color(0xFFFFD166); // amber
      case PulseFeedCardType.weeklyInsight:
        return const Color(0xFFB388FF); // purple
    }
  }

  String get _badgeLabel {
    switch (card.type) {
      case PulseFeedCardType.identityVote:
        return 'IDENTITY VOTE';
      case PulseFeedCardType.tribeActivity:
        return 'TRIBE';
      case PulseFeedCardType.weeklyInsight:
        return 'INSIGHT';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
```

- [ ] **Step 6.2: Commit**

```bash
git add lib/features/pulse_feed/presentation/widgets/pulse_card_widget.dart
git commit -m "feat(pulse-feed): add PulseCardWidget"
```

---

## Task 7: `PulseFeedScreen` (replaces Tribe Lobby)

**Files:**
- Create: `lib/features/pulse_feed/presentation/screens/pulse_feed_screen.dart`
- Modify: `lib/core/router/router.dart`

- [ ] **Step 7.1: Create `PulseFeedScreen`**

```dart
// lib/features/pulse_feed/presentation/screens/pulse_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/pulse_feed/presentation/providers/pulse_feed_providers.dart';
import 'package:emerge_app/features/pulse_feed/presentation/widgets/pulse_card_widget.dart';

class PulseFeedScreen extends ConsumerWidget {
  const PulseFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(pulseFeedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PULSE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your tribe. Your identity. In motion.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Feed cards
          feedAsync.when(
            data: (cards) {
              if (cards.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_outlined,
                          color: Colors.white.withValues(alpha: 0.25),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Complete your first habit\nto see your identity pulse.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, index) => PulseCardWidget(card: cards[index]),
                  childCount: cards.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4ECDC4),
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Could not load pulse feed.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7.2: Replace `TribeLobbyScreen` route with `PulseFeedScreen` in router**

In `lib/core/router/router.dart`, find the `StatefulShellBranch` for the Social tab (now branch index 2 after Plan A). Replace the `TribeLobbyScreen()` route with `PulseFeedScreen()`:

```dart
// BEFORE:
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/social',
      builder: (_, __) => const TribeLobbyScreen(),
      // ... child routes
    ),
  ],
),

// AFTER:
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/social',
      builder: (_, __) => const PulseFeedScreen(),
      // Keep any child routes that are still needed (e.g., /social/tribe, /social/friends)
      // Check what sub-routes TribeLobbyScreen had and keep them intact
    ),
  ],
),
```

Add import at top:
```dart
import 'package:emerge_app/features/pulse_feed/presentation/screens/pulse_feed_screen.dart';
```

- [ ] **Step 7.3: Run and verify**

```bash
flutter run
```

- [ ] Tab 2 (Tribe/Pulse) now shows the Pulse Feed scroll
- [ ] Empty state shows when no cards exist
- [ ] Cards render with correct type badge colors (teal, amber, purple)

```bash
dart analyze lib/features/pulse_feed/
```
Expected: 0 errors.

- [ ] **Step 7.4: Commit**

```bash
git add lib/features/pulse_feed/presentation/screens/pulse_feed_screen.dart
git add lib/core/router/router.dart
git commit -m "feat(pulse-feed): add PulseFeedScreen, replace TribeLobbyScreen in router"
```

---

## Task 8: Home screen widget (Android)

**Files:**
- Create: `lib/features/widget/habit_widget_service.dart`
- Create: `android/app/src/main/res/xml/habit_widget_info.xml`
- Create: `android/app/src/main/res/layout/habit_widget_layout.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Test: `test/features/widget/habit_widget_service_test.dart`

### Background
The home widget shows today's top 3 incomplete habits and a progress ring. Tapping a habit fires a `home_widget` callback that calls `HabitCompletionService` and refreshes the widget. The widget reads from Drift (offline-first — no Firestore during widget interaction).

`home_widget` uses a method channel to pass data to the native widget via `SharedPreferences`. The native widget reads those shared preferences and renders via XML layout.

- [ ] **Step 8.1: Write test for `HabitWidgetService`**

```dart
// test/features/widget/habit_widget_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/widget/habit_widget_service.dart';
import 'package:emerge_app/features/habits/data/services/habit_completion_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/completion_result.dart';

class MockHabitCompletionService extends Mock implements HabitCompletionService {}

void main() {
  late MockHabitCompletionService mockService;
  late HabitWidgetService sut;

  setUp(() {
    mockService = MockHabitCompletionService();
    sut = HabitWidgetService(completionService: mockService);
  });

  test('buildWidgetData formats top 3 incomplete habits', () {
    final habits = [
      _habit('h1', 'Morning Run', completed: false),
      _habit('h2', 'Read 20 pages', completed: true),
      _habit('h3', 'Meditate', completed: false),
      _habit('h4', 'Journal', completed: false),
    ];

    final data = sut.buildWidgetData(habits);

    // Only incomplete habits, max 3
    expect(data.habits.length, 3);
    expect(data.habits.map((h) => h.title).contains('Read 20 pages'), isFalse);
    expect(data.completedCount, 1);
    expect(data.totalCount, 4);
  });

  test('buildWidgetData returns progressFraction as completed/total', () {
    final habits = [
      _habit('h1', 'A', completed: true),
      _habit('h2', 'B', completed: true),
      _habit('h3', 'C', completed: false),
    ];
    final data = sut.buildWidgetData(habits);
    expect(data.progressFraction, closeTo(2 / 3, 0.01));
  });
}

Habit _habit(String id, String title, {required bool completed}) {
  // Copy minimal Habit constructor. Adjust fields to match real Habit class.
  final now = DateTime.now();
  return Habit(
    id: id,
    userId: 'u1',
    title: title,
    momentumScore: 50,
    consecutiveMisses: 0,
    lastCompletedDate: completed ? now : null,
    // ... other required fields
  );
}
```

- [ ] **Step 8.2: Run — expect compile error**

```bash
flutter test test/features/widget/habit_widget_service_test.dart
```

- [ ] **Step 8.3: Create `WidgetHabitData` and `HabitWidgetService`**

```dart
// lib/features/widget/habit_widget_service.dart
import 'package:home_widget/home_widget.dart';
import 'package:emerge_app/features/habits/data/services/habit_completion_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/completion_result.dart';

class WidgetHabitItem {
  final String id;
  final String title;
  final bool isCompleted;
  const WidgetHabitItem({
    required this.id,
    required this.title,
    required this.isCompleted,
  });
}

class WidgetData {
  final List<WidgetHabitItem> habits; // max 3, incomplete first
  final int completedCount;
  final int totalCount;
  final double progressFraction; // 0.0–1.0

  const WidgetData({
    required this.habits,
    required this.completedCount,
    required this.totalCount,
    required this.progressFraction,
  });
}

class HabitWidgetService {
  final HabitCompletionService completionService;
  const HabitWidgetService({required this.completionService});

  WidgetData buildWidgetData(List<Habit> allHabits) {
    final now = DateTime.now();
    bool _isCompletedToday(Habit h) =>
        h.lastCompletedDate != null &&
        h.lastCompletedDate!.year == now.year &&
        h.lastCompletedDate!.month == now.month &&
        h.lastCompletedDate!.day == now.day;

    final completed = allHabits.where(_isCompletedToday).length;
    final incomplete = allHabits.where((h) => !_isCompletedToday(h)).toList();

    return WidgetData(
      habits: incomplete
          .take(3)
          .map((h) => WidgetHabitItem(
                id: h.id,
                title: h.title,
                isCompleted: false,
              ))
          .toList(),
      completedCount: completed,
      totalCount: allHabits.length,
      progressFraction:
          allHabits.isEmpty ? 0.0 : completed / allHabits.length,
    );
  }

  /// Writes widget data to home_widget SharedPreferences and triggers a UI refresh.
  Future<void> updateWidget(List<Habit> allHabits) async {
    final data = buildWidgetData(allHabits);

    await HomeWidget.saveWidgetData<int>(
      'completedCount',
      data.completedCount,
    );
    await HomeWidget.saveWidgetData<int>('totalCount', data.totalCount);
    await HomeWidget.saveWidgetData<double>(
      'progressFraction',
      data.progressFraction,
    );

    for (var i = 0; i < 3; i++) {
      if (i < data.habits.length) {
        await HomeWidget.saveWidgetData<String>(
          'habit_${i}_id',
          data.habits[i].id,
        );
        await HomeWidget.saveWidgetData<String>(
          'habit_${i}_title',
          data.habits[i].title,
        );
      } else {
        await HomeWidget.saveWidgetData<String>('habit_${i}_id', '');
        await HomeWidget.saveWidgetData<String>('habit_${i}_title', '');
      }
    }

    await HomeWidget.updateWidget(
      androidName: 'HabitWidgetProvider',
    );
  }

  /// Called when user taps a habit in the widget.
  /// [habitId] is passed from the native click intent.
  Future<void> handleWidgetTap(String habitId) async {
    await completionService.markComplete(
      habitId,
      source: CompletionSource.widget,
    );
  }
}
```

- [ ] **Step 8.4: Create Android widget XML**

Create `android/app/src/main/res/xml/habit_widget_info.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="110dp"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:maxResizeWidth="250dp"
    android:maxResizeHeight="110dp"
    android:targetCellWidthL="4"
    android:targetCellHeightL="2"
    android:updatePeriodMillis="0"
    android:widgetCategory="home_screen"
    android:resizeMode="horizontal|vertical"
    android:initialLayout="@layout/habit_widget_layout"
    android:description="@string/app_name" />
```

Create `android/app/src/main/res/layout/habit_widget_layout.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="12dp"
    android:background="@drawable/widget_background">

    <!-- Progress line -->
    <TextView
        android:id="@+id/widget_progress_text"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textColor="#FFFFFF"
        android:textSize="11sp"
        android:alpha="0.5"
        android:text="0 of 0 today" />

    <!-- Habit rows (3 max) -->
    <TextView
        android:id="@+id/widget_habit_0"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="#FFFFFF"
        android:textSize="13sp"
        android:paddingTop="6dp"
        android:text="" />

    <TextView
        android:id="@+id/widget_habit_1"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="#FFFFFF"
        android:textSize="13sp"
        android:paddingTop="4dp"
        android:text="" />

    <TextView
        android:id="@+id/widget_habit_2"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="#FFFFFF"
        android:textSize="13sp"
        android:paddingTop="4dp"
        android:text="" />

</LinearLayout>
```

> **Note:** If `@drawable/widget_background` does not exist, create `android/app/src/main/res/drawable/widget_background.xml` as a rounded rectangle shape drawable with background color `#1A1A2E`.

- [ ] **Step 8.5: Create `HabitWidgetProvider.kt`**

Find the Java/Kotlin source directory: `android/app/src/main/kotlin/<your/package/path>/`. Create `HabitWidgetProvider.kt` in the same package:

```kotlin
// android/app/src/main/kotlin/<your/package/path>/HabitWidgetProvider.kt
package <YOUR_PACKAGE_NAME_HERE> // copy from MainActivity.kt

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class HabitWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.habit_widget_layout)

            val completed = widgetData.getInt("completedCount", 0)
            val total = widgetData.getInt("totalCount", 0)
            views.setTextViewText(
                R.id.widget_progress_text,
                "$completed of $total today"
            )

            val habitIds = arrayOf("habit_0_title", "habit_1_title", "habit_2_title")
            val textViewIds = intArrayOf(
                R.id.widget_habit_0,
                R.id.widget_habit_1,
                R.id.widget_habit_2
            )
            for (i in 0..2) {
                val title = widgetData.getString(habitIds[i], "") ?: ""
                views.setTextViewText(textViewIds[i], if (title.isEmpty()) "" else "◯  $title")
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
```

- [ ] **Step 8.6: Register widget in `AndroidManifest.xml`**

In `android/app/src/main/AndroidManifest.xml`, inside `<application>`, add:

```xml
<receiver
    android:name=".HabitWidgetProvider"
    android:exported="false">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/habit_widget_info" />
</receiver>
```

- [ ] **Step 8.7: Run widget test — expect green**

```bash
flutter test test/features/widget/habit_widget_service_test.dart
```

- [ ] **Step 8.8: Run on device and verify**

```bash
flutter run
```

Long-press home screen → Widgets → find "Emerge" → add to home screen.
- [ ] Widget shows today's incomplete habits
- [ ] Progress text shows `X of Y today`

- [ ] **Step 8.9: Commit**

```bash
git add lib/features/widget/
git add android/app/src/main/res/xml/habit_widget_info.xml
git add android/app/src/main/res/layout/habit_widget_layout.xml
git add android/app/src/main/kotlin/
git add android/app/src/main/AndroidManifest.xml
git add test/features/widget/
git commit -m "feat(widget): add home screen widget (Android) with HabitWidgetService"
```

---

## Verification Checklist (Plan C Complete)

```bash
flutter test test/features/pulse_feed/
flutter test test/features/widget/
flutter test test/core/services/notification_service_test.dart
dart analyze lib/
```

Manual checks:
- [ ] Habit notification has "Complete ✓" and "Snooze 1h" buttons (test on a real Android device)
- [ ] Tapping "Complete ✓" on the notification marks the habit done — no app open needed
- [ ] Tab 2 shows Pulse Feed with card type badges in the correct colors
- [ ] Home screen widget shows up to 3 incomplete habits
- [ ] `flutter test` shows 0 failures
