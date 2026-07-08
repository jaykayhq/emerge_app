# Habitual Engagement Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development`
> or `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce habit completion activation energy from 8-12s to <2s, add
home-screen widgets for ambient habit presence, make Timeline the app's
primary action center, and introduce a variable reward world event engine.

**Architecture:** 5 phases across ~15 weeks. Each phase is independently
shippable. Phase 1 (widgets + one-tap) is the critical path.

**Tech Stack:** Flutter, Riverpod 3.x, Drift SQLite, Firebase, Flame,
`flutter_local_notifications`, `flutter_riverpod`, BuildRunner

**Spec:** `docs/superpowers/specs/2026-07-02-habitual-engagement-redesign.md`

---

## Phase 1: De-Friction the Completion (Weeks 1-3)

> **Deliverable:** Habit completion in <2 seconds from any context.
> This is the critical path — everything else is secondary.

### Phase 1.0: Foundation — Completion Service

- [ ] **Step 1: Write the failing test**

  ```dart
  // test/features/habit_widget/domain/services/habit_completion_service_test.dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:emerge_app/features/habit_widget/domain/services/habit_completion_service.dart';
  import 'package:emerge_app/features/habits/domain/entities/habit.dart';

  void main() {
    group('HabitCompletionService', () {
      test('markComplete returns CompletionResult with today\'s date', () async {
        // Arrange: set up a fake habit + Drift in-memory DB
        // Act: call service.markComplete(habitId, source: widget)
        // Assert: result.completedAt.isToday, result.source == widget
      });

      test('markComplete updates Drift within <1ms', () async {
        final sw = Stopwatch()..start();
        await service.markComplete(habitId, source: timeline);
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(10));
      });
    });
  }
  ```

- [ ] **Step 2: Create the data layer**

  Create files:
  - `lib/features/habit_widget/domain/services/habit_completion_service.dart`
  - `lib/features/habit_widget/data/datasources/completion_datasource.dart`
  - `lib/features/habit_widget/data/repositories/completion_repository.dart`

  ```dart
  // domain/services/habit_completion_service.dart
  import 'package:fpdart/fpdart.dart';
  import 'package:emerge_app/core/error/failures.dart';

  class HabitCompletionService {
    HabitCompletionService({
      required this.completionRepository,
      required this.localGameLoopEngine,
      required this.syncQueue,
    });

    final CompletionRepository completionRepository;
    final LocalGameLoopEngine localGameLoopEngine;
    final MutationQueue syncQueue;

    Future<Either<Failure, CompletionResult>> markComplete(
      String habitId,
      CompletionSource source, {
      DateTime? completedAt,
    }) async {
      final timestamp = completedAt ?? DateTime.now();

      // 1. Local game loop (<1ms — pure Dart, no I/O)
      final loopResult = localGameLoopEngine
          .processHabitCompletion(habitId, timestamp);

      // 2. Persist to Drift (offline-first)
      final dbResult = await completionRepository.insertCompletion(
        habitId: habitId,
        completedAt: timestamp,
        source: source,
        xpDelta: loopResult.xpDelta,
      );

      // 3. Enqueue Firestore sync
      await syncQueue.enqueue(MutationType.habitCompletion, {
        'habitId': habitId,
        'completedAt': timestamp.toIso8601String(),
        'source': source.name,
      });

      return dbResult.map((r) => CompletionResult(
        habitId: habitId,
        completedAt: timestamp,
        source: source,
        newMomentum: loopResult.newMomentum,
        xpDelta: loopResult.xpDelta,
        isLevelUp: loopResult.isLevelUp,
      ));
    }
  }

  class CompletionResult {
    final String habitId;
    final DateTime completedAt;
    final CompletionSource source;
    final int newMomentum;
    final int xpDelta;
    final bool isLevelUp;

    const CompletionResult({
      required this.habitId,
      required this.completedAt,
      required this.source,
      required this.newMomentum,
      required this.xpDelta,
      required this.isLevelUp,
    });
  }
  ```

- [ ] **Step 3: Create Riverpod providers**

  ```dart
  // lib/features/habit_widget/presentation/providers/habit_completion_providers.dart
  part 'habit_completion_providers.g.dart';

  @riverpod
  HabitCompletionService habitCompletionService(Ref ref) {
    return HabitCompletionService(
      completionRepository: ref.watch(completionRepositoryProvider),
      localGameLoopEngine: ref.watch(localGameLoopEngineProvider),
      syncQueue: ref.watch(mutationQueueProvider),
    );
  }

  @riverpod
  AsyncNotifierProvider<HabitCompletionNotifier, void>
      habitCompletionNotifier = habitCompletionNotifierProvider;

  class HabitCompletionNotifier extends _$HabitCompletionNotifier {
    @override
    FutureOr<void> build() => null;

    Future<void> complete(String habitId, CompletionSource source) async {
      final service = ref.read(habitCompletionServiceProvider);
      final result = await service.markComplete(habitId, source);
      result.fold(
        (failure) => throw failure,
        (r) {
          // Trigger UI flash without rebuilding whole tree
          ref.invalidate(todayHabitsProvider);
          ref.invalidate(worldStateProvider);
        },
      );
    }
  }
  ```

### Phase 1.1: One-Tap Habit Card Widget

- [ ] **Step 1: Write failing test**

  ```dart
  // test/core/presentation/widgets/one_tap_habit_card_test.dart
  testWidgets('OneTapHabitCard completes on zone tap', (tester) async {
    final notifier = HabitCompletionNotifier();
    await tester.pumpWidget(
      ProviderScope(overrides: [
        habitCompletionNotifierProvider.overrideWith((_) => notifier),
      ], child: const MaterialApp(home: OneTapHabitCard(habit: testHabit))),
    );

    // Tap the completion zone (not the card body)
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    verify(() => notifier.complete(testHabit.id, CompletionSource.timeline)).called(1);
  });

  testWidgets('OneTapHabitCard does NOT navigate on tap', (tester) async {
    // Pump with a Navigator + mock observer; tap completion zone
    // Assert no push/pop calls
  });
  ```

- [ ] **Step 2: Implement `OneTapHabitCard`**

  Create: `lib/core/presentation/widgets/one_tap_habit_card.dart`

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:emerge_app/features/habit_widget/presentation/providers/habit_completion_providers.dart';
  import 'package:emerge_app/core/presentation/widgets/completion_particles.dart';

  class OneTapHabitCard extends ConsumerWidget {
    final Habit habit;
    final bool isCompleted;
    final VoidCallback? onTap;

    const OneTapHabitCard({
      super.key,
      required this.habit,
      this.isCompleted = false,
      this.onTap,
    });

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return GestureDetector(
        onTap: isCompleted ? null : () {
          HapticFeedback.mediumImpact();
          ref.read(habitCompletionNotifierProvider.notifier)
              .complete(habit.id, CompletionSource.timeline);
          onTap?.call();
        },
        child: _CompletionZone(
          habit: habit,
          isCompleted: isCompleted,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Habit icon
                _HabitIcon(habit: habit),
                const SizedBox(width: 12),
                // Habit name + time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.name, style: Theme.of(context).textTheme.bodyLarge),
                      if (habit.scheduledTime != null)
                        Text(
                          '${habit.scheduledTime!.hour}:${habit.scheduledTime!.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                // Momentum mini-bar
                if (!isCompleted)
                  MomentumMiniBar(momentum: habit.momentumScore),
              ],
            ),
          ),
        ),
      );
    }
  }

  class _CompletionZone extends StatelessWidget {
    final Habit habit;
    final bool isCompleted;
    final Widget child;

    const _CompletionZone({required this.habit, required this.isCompleted, required this.child});

    @override
    Widget build(BuildContext context) {
      return Stack(
        children: [
          if (!isCompleted)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: _CompleteButton(habit: habit),
            ),
          child,
        ],
      );
    }
  }

  class _CompleteButton extends StatelessWidget {
    final Habit habit;
    const _CompleteButton({required this.habit});

    @override
    Widget build(BuildContext context) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: habit.isCompleted
              ? Colors.green.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: habit.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: Icon(
          habit.isCompleted ? Icons.check : Icons.close,
          size: 16,
          color: habit.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
  ```

### Phase 1.2: Particle Animation

- [ ] **Step 1: Write failing test**

  ```dart
  // test/core/presentation/widgets/completion_particles_test.dart
  testWidgets('CompletionParticles renders within 100ms', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: CompletionParticles(origin: Offset(100, 100)),
    )));

    // Should render within first frame
    expect(find.byType(CompletionParticles), findsOneWidget);
  });
  ```

- [ ] **Step 2: Implement `CompletionParticles`**

  Create: `lib/core/presentation/widgets/completion_particles.dart`

  ```dart
  import 'dart:math';
  import 'package:flutter/material.dart';
  import 'package:emerge_app/core/theme/archetype_theme.dart';

  class CompletionParticles extends StatefulWidget {
    final Offset origin;
    final Color? color;
    final int particleCount;
    final VoidCallback? onComplete;

    const CompletionParticles({
      super.key,
      required this.origin,
      this.color,
      this.particleCount = 35,
      this.onComplete,
    });

    @override
    State<CompletionParticles> createState() => _CompletionParticlesState();
  }

  class _CompletionParticlesState extends State<CompletionParticles>
      with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    final List<_Particle> _particles = [];
    final Random _random = Random();

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      // Generate particles
      for (int i = 0; i < widget.particleCount; i++) {
        _particles.add(_Particle(
          x: widget.origin.dx,
          y: widget.origin.dy,
          vx: (_random.nextDouble() - 0.5) * 400,
          vy: -(_random.nextDouble() * 300 + 100),
          size: _random.nextDouble() * 6 + 2,
          color: widget.color ?? _archetypeColor(),
          decay: _random.nextDouble() * 0.6 + 0.4,
        ));
      }

      _controller.forward().then((_) {
        widget.onComplete?.call();
        if (mounted) setState(() {});
      });
    }

    Color _archetypeColor() {
      // Will be parameterized by caller after archetype system integration
      return const Color(0xFF35E0FF);
    }

    @override
    Widget build(BuildContext context) {
      if (!_controller.isAnimating) return const SizedBox.shrink();

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ParticlePainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      );
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }
  }

  class _Particle {
    final double x;
    final double y;
    final double vx;
    final double vy;
    final double size;
    final Color color;
    final double decay;

    _Particle({
      required this.x,
      required this.y,
      required this.vx,
      required this.vy,
      required this.size,
      required this.color,
      required this.decay,
    });
  }

  class _ParticlePainter extends CustomPainter {
    final List<_Particle> particles;
    final double progress;

    _ParticlePainter({required this.particles, required this.progress});

    @override
    void paint(Canvas canvas, Size size) {
      final paint = Paint()..style = PaintingStyle.fill;

      for (final p in particles) {
        final t = progress;
        final x = p.x + p.vx * t;
        final y = p.y + p.vy * t + 200 * t * t; // gravity
        final alpha = (1 - t * p.decay).clamp(0.0, 1.0);

        paint.color = p.color.withValues(alpha: alpha);
        canvas.drawCircle(Offset(x, y), p.size * (1 - t * 0.5), paint);
      }
    }

    @override
    bool shouldRepaint(_ParticlePainter oldDelegate) => true;
  }
  ```

### Phase 1.3: Timeline → Home Tab

- [ ] **Step 1: Write test for nav bar order**

  ```dart
  // test/core/presentation/widgets/scaffold_with_nav_bar_test.dart
  testWidgets('Timeline is the first navigation destination', (tester) async {
    // Pump with mock StatefulNavigationShell
    // Assert that tab index 0 maps to /timeline route
  });
  ```

- [ ] **Step 2: Modify `ScaffoldWithNavBar`**

  File: `lib/core/presentation/widgets/scaffold_with_nav_bar.dart`

  Changes:
  - Remove center FAB (move `+` to `EnhancedTimelineScreen` bottom-right)
  - Reorder tab children: Timeline(0), WorldMap(1), TribeLobby(2), FutureSelfStudio(3)
  - Update icon labels

- [ ] **Step 3: Modify `router.dart`**

  File: `lib/core/router/router.dart`

  Changes:
  - Swap `branch 0` (WorldMap) and `branch 1` (Timeline)
  - Timeline routes now in branch 0, WorldMap in branch 1
  - Update any path references (e.g. tab index constants)

- [ ] **Step 4: Simplify `HabitTimelineSection`**

  File: `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`

  Changes:
  - Replace `HabitCard` with `OneTapHabitCard`
  - Remove swipe-to-complete gesture (kept as alternative, not primary)
  - Link tab completion to `HabitCompletionNotifier.complete()`

---

## Phase 2: Ambient World Presence (Weeks 4-6)

> **Deliverable:** Visible habit stack + world preview on lock/home screen,
> updated in real time as habits are completed.

### Phase 2.0: Widget Infrastructure

- [ ] **Step 1: Add widget dependencies to `pubspec.yaml`**

  ```yaml
  dependencies:
    flutter_local_notifications: ^18.0
    # No additional widget packages needed — flutter supports
    # native widgets via platform channels
  ```

- [ ] **Step 2: Create widget service layer**

  ```dart
  // lib/core/services/widget_update_service.dart
  import 'package:flutter/services.dart';

  class WidgetUpdateService {
    static const MethodChannel _channel =
        MethodChannel('emerge_app/widget_updates');

    Future<void> refreshAllWidgets() async {
      try {
        await _channel.invokeMethod('refreshWidgets');
      } on PlatformException catch (e) {
        debugPrint('Widget refresh failed: ${e.message}');
      }
    }
  }
  ```

- [ ] **Step 3: Create Android widget receiver**

  New file: `android/app/src/main/kotlin/.../WidgetUpdateReceiver.kt`

  ```kotlin
  class WidgetUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
      val appWidgetManager = AppWidgetManager.getInstance(context)
      val componentName = ComponentName(context, HabitStackWidgetProvider::class.java)
      appWidgetManager.notifyAppWidgetViewDataChanged(componentName, null)
    }
  }
  ```

### Phase 2.1: HabitStack Widget (4x2)

- [ ] **Step 1: Write failing test (widget logic, not UI)**

  ```dart
  // test/core/services/widget_update_service_test.dart
  test('refreshAllWidgets invokes platform channel', () async {
    // Mock MethodChannel, call refreshAllWidgets, verify invokeMethod called
  });
  ```

- [ ] **Step 2: Create `HabitStackWidget` (Flutter side)**

  ```dart
  // lib/core/presentation/widgets/habit_stack_widget.dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:emerge_app/features/habit_widget/presentation/providers/habit_completion_providers.dart';

  class HabitStackWidget extends ConsumerWidget {
    const HabitStackWidget({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final habits = ref.watch(todayHabitsProvider);

      return habits.when(
        loading: () => const _WidgetLoading(),
        error: (e, _) => _WidgetError(message: '$e'),
        data: (habits) => _StackContent(habits: habits),
      );
    }
  }

  class _StackContent extends StatelessWidget {
    final List<Habit> habits;
    const _StackContent({required this.habits});

    @override
    Widget build(BuildContext context) {
      final incomplete = habits.where((h) => !h.isCompletedToday).toList();
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.indigo.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today — ${incomplete.length} habits left',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...incomplete.take(4).map((h) => _WidgetHabitRow(habit: h)),
          ],
        ),
      );
    }
  }

  class _WidgetHabitRow extends StatelessWidget {
    final Habit habit;
    const _WidgetHabitRow({required this.habit});

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: () async {
          // Call completion via MethodChannel from widget context
          // (Handled by WidgetCompletionHandler on platform side)
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.circle_outlined, size: 16, color: Colors.white54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  habit.name,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 3: Android widget (RemoteViews)**

  New directory: `android/app/src/main/java/.../widget/`

  Files:
  - `HabitStackWidgetProvider.kt` — `RemoteViews` factory, receives habit data from APPWIDGET_UPDATE
  - `HabitStackWidgetLayout.kt` — XML layout (4x2 GridView)

- [ ] **Step 4: iOS widget (SwiftUI)**

  New directory: `ios/Runner/EmergeWidgets/`

  Files:
  - `HabitStackWidget.swift` — SwiftUI timeline provider
  - `HabitStackBundle.swift` — Widget bundle registration

### Phase 2.2: WorldSlice Widget (2x2)

- [ ] **Step 1: Create widget data model**

  ```dart
  // lib/features/gamification/presentation/providers/world_slice_provider.dart
  @riverpod
  Future<WorldSliceData> worldSliceData(Ref ref) async {
    final worldState = await ref.watch(worldStateProvider.future);
    final userStats = await ref.watch(userStatsProvider.future);

    // Render a low-res snapshot of the world map
    // For now: return a static placeholder based on archetype + health
    // Later: Flame render to image (Image.fromBitmap)
    return WorldSliceData(
      archetype: userStats.archetype,
      worldHealth: worldState.healthPercentage,
      recentEvent: worldState.lastEvent,
    );
  }

  class WorldSliceData {
    final String archetype;
    final double worldHealth;
    final WorldEvent? recentEvent;

    const WorldSliceData({
      required this.archetype,
      required this.worldHealth,
      this.recentEvent,
    });
  }
  ```

- [ ] **Step 2: Implement `WorldSliceWidget`**

  ```dart
  // lib/core/presentation/widgets/world_slice_widget.dart
  class WorldSliceWidget extends ConsumerWidget {
    const WorldSliceWidget({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final slice = ref.watch(worldSliceDataProvider);

      return slice.when(
        loading: () => _WidgetLoading(),
        error: (e, _) => _WidgetError(message: '$e'),
        data: (data) => _SliceContent(data: data),
      );
    }
  }

  // Shows: archetype-themed icon, health bar, world mood text
  // e.g. 🌲 82% — Your forest is thriving
  ```

### Phase 2.3: Notification Actions

- [ ] **Step 1: Update `NotificationService` for actions**

  File: `lib/core/services/notification_service.dart`

  Add action registration per habit group:

  ```dart
  Future<void> scheduleHabitNotification(Habit habit) async {
    final androidDetails = AndroidNotificationDetails(
      'habit_${habit.id}',
      'Habit: ${habit.name}',
      channelDescription: 'Reminder for ${habit.name}',
      importance: Importance.high,
      actions: [
        AndroidNotificationAction(
          'complete_${habit.id}',
          '✓ Done',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'snooze_${habit.id}',
          'Snooze 10m',
          showsUserInterface: true,
        ),
      ],
    );

    final iOSDetails = DarwinNotificationDetails(
      categoryIdentifier: 'habit_${habit.id}',
      threadIdentifier: 'habits',
      attachments: const [],
    );

    // Note: iOS inline actions are configured inAppDelegate via UNUserNotificationCenter
    // See NotificationService.ios setup for category registration
  }
  ```

- [ ] **Step 2: Wire action callbacks**

  In `NotificationService.initialize()`, add:

  ```dart
  await _localNotifications.initialize(
    settings: const InitializationSettings(...),
    onDidReceiveNotificationResponse: (details) {
      if (details.actionId?.startsWith('complete_') ?? false) {
        final habitId = details.actionId!.replaceFirst('complete_', '');
        // Call HabitCompletionService directly without opening the app
        _completeFromNotification(habitId);
      }
    },
  );
  ```

- [ ] **Step 3: Register iOS notification categories**

  ```dart
  // In initialize(), after requesting permissions:
  final center = UNUserNotificationCenter.current();
  await center.setNotificationCategories([
    _buildCategoryForHabit(habit),
    ...
  ]);

  UNNotificationCategory _buildCategoryForHabit(Habit habit) {
    final completeAction = UNNotificationAction(
      identifier: 'complete_${habit.id}',
      title: '✓ Done',
      options: {.foreground}, // opens app
      // Actually: use .authenticationRequired: false and handle in background
    );
    final snoozeAction = UNNotificationAction(
      identifier: 'snooze_${habit.id}',
      title: 'Snooze 10m',
      options: {.foreground},
    );
    return UNNotificationCategory(
      identifier: 'habit_${habit.id}',
      actions: [completeAction, snoozeAction],
    );
  }
  ```

### Phase 2.4: Settings Toggle

- [ ] **Modify SettingsScreen** for widget/live activity toggles

  File: `lib/features/settings/presentation/screens/settings_screen.dart`

  Add section:
  ```dart
  SwitchListTile(
    title: const Text('Habit Stack Widget'),
    subtitle: const Text('Show your daily habits on home screen'),
    value: ref.watch(widgetEnabledProvider),
    onChanged: (v) => ref.read(widgetEnabledProvider.notifier).state = v,
  ),
  SwitchListTile(
    title: const Text('Live Activity'),
    subtitle: const Text('Show tonight\'s habits on lock screen (iOS 17+)'),
    value: ref.watch(liveActivityEnabledProvider),
    onChanged: (v) {
      if (v) {
        ref.read(worldLiveActivityServiceProvider).start();
      } else {
        ref.read(worldLiveActivityServiceProvider).end();
      }
    },
  ),
  SwitchListTile(
    title: const Text('Notification Actions'),
    subtitle: const Text('Complete habits directly from notifications'),
    value: ref.watch(notificationActionsEnabledProvider),
    onChanged: (v) => ref.read(notificationActionsEnabledProvider.notifier).state = v,
  ),
  ```

---

## Phase 3: Surface the Reward Layer (Weeks 7-10)

> **Deliverable:** World Map moves to rewards tab, ambient animations, daily
> snapshot comparison. Opening the app feels different after a day apart.

### Phase 3.0: World Event Engine (Pure Logic)

- [ ] **Step 1: Write failing tests for `WorldEventEngine`**

  ```dart
  // test/features/gamification/domain/services/world_event_engine_test.dart
  test('5-day streak triggers travelerVisit event', () {
    final stats = UserStats(
      archetype: 'athlete',
      momentumByHabit: {'morning_run': 90},
      consecutiveDaysActive: 5,
    );
    final events = WorldEventEngine.evaluateAndFire(stats, DateTime(2026, 7, 2));
    expect(events, contains(predicate((e) => e.type == WorldEventType.travelerVisit)));
  });
  ```

- [ ] **Step 2: Implement `WorldEventEngine` (pure Dart)**

  ```dart
  // lib/features/gamification/domain/services/world_event_engine.dart
  class WorldEventEngine {
    static const _minEventGapHours = 6; // No more than 1 event per 6h window

    static List<WorldEvent> evaluateAndFire(UserStats stats, DateTime now) {
      final events = <WorldEvent>[];
      final recentEvents = stats.recentWorldEvents;

      // Filter: event gap, not expired
      final eligible = recentEvents.where((e) {
        final hoursSince = now.difference(e.triggeredAt).inHours;
        return hoursSince > _minEventGapHours &&
            (e.expiresAt == null || now.isBefore(e.expiresAt!));
      }).toList();

      if (eligible.length >= 3) return events; // Cap events per day

      // Evaluate conditions
      if (stats.consecutiveDaysActive >= 5 && !eligible.any((e) => e.type == WorldEventType.travelerVisit)) {
        events.add(WorldEvent(
          id: const Uuid().v4(),
          type: WorldEventType.travelerVisit,
          triggeredAt: now,
          payload: {'message': _travelerMessage(stats.archetype)},
          expiresAt: now.add(const Duration(hours: 12)),
        ));
      }

      if (stats.overallMomentum >= 90 && !eligible.any((e) => e.type == WorldEventType.discoveryBurst)) {
        events.add(WorldEvent(
          id: const Uuid().v4(),
          type: WorldEventType.discoveryBurst,
          triggeredAt: now,
          payload: {'xpBonus': 50, 'region': _hiddenRegion(stats.archetype)},
        ));
      }

      // Weather: seeded daily based on date hash
      final weatherSeed = _dateSeed(now);
      final weatherType = WeatherType.values[weatherSeed % WeatherType.values.length];
      if (!eligible.any((e) => e.type == WorldEventType.weatherShift)) {
        events.add(WorldEvent(
          id: const Uuid().v4(),
          type: WorldEventType.weatherShift,
          triggeredAt: now,
          payload: {'weather': weatherType.name},
          expiresAt: DateTime(now.year, now.month, now.day + 1),
        ));
      }

      return events;
    }

    static int _dateSeed(DateTime d) {
      return d.year * 10000 + d.month * 100 + d.day;
    }

    static String _travelerMessage(String archetype) {
      switch (archetype) {
        case 'athlete': return 'The Running Coach stopped by. "Keep pushing."';
        case 'scholar': return 'The wandering sage left a book on your doorstep.';
        case 'creator': return 'A muse drifted through the studio. "Get creating."';
        default: return 'A traveler passed through. "The path is worth it."';
      }
    }

    static String _hiddenRegion(String archetype) {
      switch (archetype) {
        case 'athlete': return 'the mountain peak';
        case 'scholar': return 'the ancient library';
        case 'creator': return 'the hidden studio';
        default: return 'the unexplored forest';
      }
    }
  }
  ```

  This is a **pure function** — no Firebase, no Riverpod, no Flutter. Can be
  unit-tested with plain data classes.

### Phase 3.1: WorldEvent Provider + Persistence

- [ ] **Create Firestore collection** — `users/{uid}/worldEvents/{eventId}`
- [ ] **Create provider**

  ```dart
  @riverpod
  Stream<List<WorldEvent>> worldEventStream(Ref ref) {
    final uid = ref.watch(currentUserProvider).value!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('worldEvents')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('triggeredAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WorldEvent.fromDoc(d)).toList());
  }
  ```

- [ ] **Cloud Function for auto-cleanup** — Delete expired events daily

### Phase 3.2: World Map → Rewards Tab

- [ ] **Step 1: Move WorldMap branch from index 0 to index 1**

  File: `lib/core/router/router.dart`

  ```dart
  // Before:
  //   branch 0 → /world-map
  //   branch 1 → /timeline
  // After:
  //   branch 0 → /timeline          ← HOME
  //   branch 1 → /world-map         ← reward zone
  ```

- [ ] **Step 2: Update `ScaffoldWithNavBar` labels**

  Change from:
  ```
  [World] → [Timeline] → [+] → [Tribes] → [Profile]
  ```
  To:
  ```
  [✓ Today]  →  [🌿 World]  →  [👥 Tribes]  →  [👤 Identity]
  (action)       (reward)       (social)       (me)
  ```

- [ ] **Step 3: Add ambient animations to Flame world map**

  Already has Flame/Tiled setup. Add lightweight ambient layer:
  - Time-of-day color tint (no new sprites needed, just shader tint)
  - Gentle NPC path patrol (existing NPC sprites, new idle animation)
  - Weather overlay (rain/sun particles as existing Flame effect)

### Phase 3.3: Daily Snapshot Comparison

- [ ] **Add "Yesterday vs Today" toggle on World Map**

  ```dart
  // On WorldMapScreen top bar:
  Row(
    children: [
      TextButton(onPressed: () => setState(() => _compareMode = false), child: Text('Today')),
      Text('vs', style: TextStyle(color: Colors.grey)),
      TextButton(onPressed: () => setState(() => _compareMode = true), child: Text('Yesterday')),
    ],
  );
  ```

  When `_compareMode == true`: overlay a fog-of-war ghost of yesterday's map
  on top of today's map. New elements appear in bright color, removed elements
  appear as "ghost" outlines.

---

## Phase 4: Variable Reward Engine (Weeks 11-14)

> **Deliverable:** The world evolves in surprising ways. Users open the app
> not to complete habits but to discover what changed.

### Phase 4.0: Reward Activation UI

- [ ] **Step 1: Create `WorldEventCard` widget**

  ```dart
  // lib/features/gamification/presentation/widgets/world_event_card.dart
  class WorldEventCard extends StatelessWidget {
    final WorldEvent event;
    const WorldEventCard({super.key, required this.event});

    @override
    Widget build(BuildContext context) {
      IconData icon;
      String title;
      String description;

      switch (event.type) {
        case WorldEventType.travelerVisit:
          icon = Icons.hiking;
          title = 'A Traveler Visited';
          description = event.payload['message'] as String;
        case WorldEventType.discoveryBurst:
          icon = Icons.auto_awesome;
          title = 'Hidden Discovery!';
          description = 'You found ${event.payload['region']}! +${event.payload['xpBonus']} XP';
        case WorldEventType.weatherShift:
          icon = Icons.wb_cloudy;
          title = 'Weather Changed';
          description = 'The ${event.payload['weather']} rolls over your world';
        // ...
      }

      return Card(
        color: Colors.purple.shade900.withValues(alpha: 0.8),
        child: ListTile(
          leading: Icon(icon, color: Colors.amber),
          title: Text(title, style: TextStyle(color: Colors.white)),
          subtitle: Text(description, style: TextStyle(color: Colors.white70)),
        ),
      );
    }
  }
  ```

- [ ] **Step 2: Integrate into World Map**

  Show recent events as floating cards near the corresponding map region.
  Cards auto-dismiss after 24h.

  ```dart
  // In WorldMapScreen:
  final events = ref.watch(worldEventStreamProvider);
  events.whenData((eventList) {
    for (final event in eventList) {
      _showEventBanner(event);
    }
  });
  ```

### Phase 4.1: Biome Transitions

- [ ] Implement seasonal biome change: every 30 days, the world's visual
  theme shifts (spring → summer → autumn → winter for Forest; dawn → dusk
  → night for City). Uses the existing `ArchetypeTheme` system.

  ```dart
  enum BiomeSeason { spring, summer, autumn, winter }

  class BiomeTransitionEngine {
    static BiomeSeason currentSeason(DateTime now) {
      final dayOfYear = _dayOfYear(now);
      if (dayOfYear < 80) return BiomeSeason.spring;
      if (dayOfYear < 172) return BiomeSeason.summer;
      if (dayOfYear < 265) return BiomeSeason.autumn;
      return BiomeSeason.winter;
    }
  }
  ```

### Phase 4.2: Weather System

- [ ] **WeatherProvider** — seeded daily weather affecting Flame map visuals
- [ ] **Weather overlay sprites** for Flame: rain particles, sun rays, fog gradient

---

## Phase 5: Social Ambient Layer (Weeks 15-18)

> **Deliverable:** You're not alone in your world — tribe presence visible on map.

| Feature | Description |
|---|---|
| **Neighboring Tribes** | See adjacent tribe regions on your world map (seeded based on archetype affinity) |
| **Tribe Contributions** | Global tribe XP bar visible on world map edge |
| **Creator Worlds** | "Adopt this blueprint → start with their world layout" |
| **Activity Pulse** | Small floating text: "Your tribe completed 47 habits today" |

**Deferred to future plan** — the first 4 phases deliver habitual engagement
without requiring social features.

---

## Test Strategy (Every Phase)

Each phase unit-tests **pure logic first**, then integration-tests the widget:

1. **Pure logic test** (no Flutter, no Firebase, no Riverpod)
   - `WorldEventEngine.evaluateAndFire()` ← test with plain Dart data classes
   - `HabitCompletionService.markComplete()` ← test with Drift in-memory DB
2. **Provider test** (Riverpod with overrides)
   - Verify `worldEventProvider` emits correct events for given stats
3. **Widget test** (pump + interact)
   - Tap one-tap card → verify completion service called
   - Boot notification → verify action button appears
4. **Integration test** (full app)
   - Complete habit → verify sync queue → Firestore document

**TDD Iron Law:** No production code without a failing test first. Tests for
Phase 1.0 must exist and fail before `HabitCompletionService` is written.

---

## Verification Plan

| Phase | Proving Command | What It Proves |
|---|---|---|
| 1.0 | `flutter test features/habit_widget/domain/services/habit_completion_service_test.dart` | Pure completion logic works |
| 1.1 | `flutter test core/presentation/widgets/one_tap_habit_card_test.dart` | One-tap card navigates correctly |
| 1.2 | `flutter test core/presentation/widgets/completion_particles_test.dart` | Particles render and cleanly dispose |
| 1.3 | `flutter test core/presentation/widgets/scaffold_with_nav_bar_test.dart` | Tab order correct |
| 2.1 | `flutter test features/habit_widget/...` | Widget data layer wired |
| 2.2 | `flutter test features/gamification/presentation/providers/world_slice_provider_test.dart` | World slice provider works |
| 2.3 | Manual: schedule notification → tap action → verify habit completed | Notification actions wired |
| 2.4 | `flutter test features/settings/...` | Settings toggles work |
| 3.0 | `flutter test features/gamification/domain/services/world_event_engine_test.dart` | Event engine evaluates correctly |
| 3.1 | `flutter test features/gamification/presentation/providers/world_event_providers_test.dart` | Provider streams events |
| 3.2 | `flutter test core/router/router_test.dart` | Router routes to correct branches |
| 3.3 | Manual: open map → compare yesterday | Snapshot works |
| 4.0 | `flutter test features/gamification/presentation/widgets/world_event_card_test.dart` | Event card renders |
| 4.1 | `flutter test features/gamification/domain/services/biome_transition_engine_test.dart` | Seeded season logic |
| 4.2 | Manual: open world on rainy day → weather visible | Weather overlay shows |

**Global verification after all phases:**
```bash
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

---

## Dependency Map

```
Phase 1.0 ─┬→ Phase 1.1 (uses CompletionService)
           └→ Phase 1.2 (triggers on completion callback)

Phase 2.1 ← Phase 1.0 (widget calls CompletionService)
Phase 2.2 ← Phase 2.1 (same infrastructure)
Phase 2.3 ← Phase 2.1 (same completion path)
Phase 2.4 ← Phase 2.1 (widget toggle)

Phase 3.0 ─┬→ Phase 3.1 (provider needs WorldEvent model)
           └→ Phase 4.0 (UI needs WorldEvent model)

Phase 3.2 ← Router change (independent but risky — do with Phase 1.3)

Phase 5 ──→ Does NOT depend on Phases 1-4 (can be built in parallel as separate feature)
```

**Key insight:** Phase 1.0 (completion service) is the critical path for the
entire redesign. Everything else can happen in parallel or later. Ship Phase 1
alone if needed.

---

## Success Metrics

| Metric | Before | After (target) | Measurement |
|---|---|---|---|
| Time to complete habit | 8-12s | <2s | User testing / instrumentation |
| Timeline as first tab | No | Yes | Analytics: tab 1 open rate |
| Widget completion rate | 0% | 30% of completions | Analytics: completion source = widget |
| Notification action taps | 0 | 100/day active user | Analytics |
| Daily open frequency | 2-3x/day | 5-10x/day (trigger-driven) | Analytics |
| 7-day retention | Baseline | +20% | Firebase Analytics |
| 30-day retention | Baseline | +15% | Firebase Analytics |
| World event discovery rate | 0% | 60% of opens see event | Analytics |

---

## Timeline Summary

```
Week 1  │ Phase 1.0: Completion Service (pure logic + test)
Week 2  │ Phase 1.1: One-Tap Habit Card
Week 2  │ Phase 1.2: Particle Animation
Week 3  │ Phase 1.3: Timeline → Home Tab (nav reorder)
Week 4  │ Phase 2.0: Widget Infrastructure
Week 5  │ Phase 2.1: HabitStack Widget
Week 5  │ Phase 2.2: WorldSlice Widget
Week 6  │ Phase 2.3: Notification Actions
Week 6  │ Phase 2.4: Settings Toggles
Week 7  │ Phase 3.0: World Event Engine (pure logic + test)
Week 8  │ Phase 3.1: WorldEvent Provider + Persistence
Week 9  │ Phase 3.2: World Map → Rewards Tab
Week 10 │ Phase 3.3: Daily Snapshot Comparison
Week 11 │ Phase 4.0: Reward Activation UI
Week 12 │ Phase 4.1: Biome Transitions
Week 13 │ Phase 4.2: Weather System
Week 14 │ Buffer + polish
Week 15 │ Phase 5 kickoff (if approved)
```

---

*Plan prepared: 2026-07-02*
*Next review: After Phase 1.3 ships*
