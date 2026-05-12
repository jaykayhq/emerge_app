# Real-Time Tribe Stats Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement real-time tribe statistics with hybrid caching approach and add "See All" tribes functionality for browsing and joining tribes.

**Architecture:** Hybrid approach that calculates accurate stats on-demand using TribeStatsService, caches results locally with 5-minute TTL, and provides periodic refresh. New AllTribesScreen allows browsing and joining tribes with real-time stats.

**Tech Stack:** Flutter, Riverpod, Firestore, existing TribeStatsService, go_router

---

## File Structure

**New Files:**
- `lib/features/social/presentation/providers/cached_tribe_stats_provider.dart` - Cache provider with TTL logic
- `lib/features/social/presentation/screens/all_tribes_screen.dart` - Screen for browsing all tribes
- `lib/features/social/presentation/widgets/tribe_card.dart` - Reusable tribe card component
- `lib/features/social/domain/models/cached_stats.dart` - Cache data model
- `lib/features/social/data/services/tribe_membership_service.dart` - Service for joining/leaving tribes

**Modified Files:**
- `lib/features/social/presentation/screens/tribe_tab_content.dart` - Add "See All" button
- `lib/features/social/presentation/widgets/tribe_header_widgets.dart` - Update to use cached provider
- `lib/core/router/router.dart` - Add route for AllTribesScreen

---

## Task 1: Create Cache Data Model

**Files:**
- Create: `lib/features/social/domain/models/cached_stats.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/domain/models/cached_stats_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/models/cached_stats.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

void main() {
  group('CachedStats', () {
    test('should store stats with timestamp', () {
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );
      final timestamp = DateTime(2026, 5, 11, 12, 0);
      
      final cached = CachedStats(stats, timestamp);
      
      expect(cached.stats, equals(stats));
      expect(cached.timestamp, equals(timestamp));
    });

    test('should check if cache is expired', () {
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );
      final oldTimestamp = DateTime.now().subtract(const Duration(minutes: 6));
      final recentTimestamp = DateTime.now().subtract(const Duration(minutes: 4));
      
      final oldCache = CachedStats(stats, oldTimestamp);
      final recentCache = CachedStats(stats, recentTimestamp);
      
      expect(oldCache.isExpired(), isTrue);
      expect(recentCache.isExpired(), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/domain/models/cached_stats_test.dart`
Expected: FAIL with "CachedStats not defined"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/social/domain/models/cached_stats.dart
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class CachedStats {
  final TribeStats stats;
  final DateTime timestamp;
  
  static const Duration _cacheTtl = Duration(minutes: 5);
  
  CachedStats(this.stats, this.timestamp);
  
  bool isExpired() {
    return DateTime.now().difference(timestamp) > _cacheTtl;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/domain/models/cached_stats_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/domain/models/cached_stats.dart test/features/social/domain/models/cached_stats_test.dart
git commit -m "feat: add CachedStats model with TTL logic"
```

---

## Task 2: Create Cache Provider

**Files:**
- Create: `lib/features/social/presentation/providers/cached_tribe_stats_provider.dart`
- Test: `test/features/social/presentation/providers/cached_tribe_stats_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/presentation/providers/cached_tribe_stats_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

void main() {
  group('TribeStatsCache', () {
    test('should store and retrieve cached stats', () {
      final cache = TribeStatsCache();
      final tribeId = 'test-tribe-1';
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );
      
      cache.set(tribeId, stats);
      final retrieved = cache.get(tribeId);
      
      expect(retrieved, isNotNull);
      expect(retrieved!.stats, equals(stats));
    });

    test('should return null for non-existent cache', () {
      final cache = TribeStatsCache();
      final result = cache.get('non-existent');
      
      expect(result, isNull);
    });

    test('should expire cache after TTL', () async {
      final cache = TribeStatsCache();
      final tribeId = 'test-tribe-2';
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );
      
      cache.set(tribeId, stats);
      
      // Wait for cache to expire
      await Future.delayed(const Duration(minutes: 6));
      
      final retrieved = cache.get(tribeId);
      expect(retrieved, isNull);
    });

    test('should invalidate cache', () {
      final cache = TribeStatsCache();
      final tribeId = 'test-tribe-3';
      final stats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );
      
      cache.set(tribeId, stats);
      cache.invalidate(tribeId);
      
      final retrieved = cache.get(tribeId);
      expect(retrieved, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/providers/cached_tribe_stats_provider_test.dart`
Expected: FAIL with "TribeStatsCache not defined"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/social/presentation/providers/cached_tribe_stats_provider.dart
import 'package:emerge_app/features/social/domain/models/cached_stats.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class TribeStatsCache {
  final Map<String, CachedStats> _cache = {};
  
  CachedStats? get(String tribeId) {
    final cached = _cache[tribeId];
    if (cached == null) return null;
    
    if (cached.isExpired()) {
      _cache.remove(tribeId);
      return null;
    }
    
    return cached;
  }
  
  void set(String tribeId, TribeStats stats) {
    _cache[tribeId] = CachedStats(stats, DateTime.now());
  }
  
  void invalidate(String tribeId) {
    _cache.remove(tribeId);
  }
  
  void clear() {
    _cache.clear();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/providers/cached_tribe_stats_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/providers/cached_tribe_stats_provider.dart test/features/social/presentation/providers/cached_tribe_stats_provider_test.dart
git commit -m "feat: add TribeStatsCache with TTL and invalidation"
```

---

## Task 3: Create Cached Stats Provider

**Files:**
- Modify: `lib/features/social/presentation/providers/cached_tribe_stats_provider.dart`
- Test: `test/features/social/presentation/providers/cached_tribe_stats_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/presentation/providers/cached_tribe_stats_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/data/services/tribe_stats_service.dart';

@GenerateMocks([TribeStatsService])
import 'cached_tribe_stats_provider_test.mocks.dart';

void main() {
  group('cachedTribeStatsProvider', () {
    late ProviderContainer container;
    late MockTribeStatsService mockStatsService;
    
    setUp(() {
      mockStatsService = MockTribeStatsService();
      container = ProviderContainer(
        overrides: [
          tribeStatsServiceProvider.overrideWithValue(mockStatsService),
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('should return cached stats if available', () async {
      final tribeId = 'test-tribe-1';
      final expectedStats = TribeStats(
        memberCount: 10,
        totalXp: 1000,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 5,
      );
      
      // Set cache
      container.read(tribeStatsCacheProvider).set(tribeId, expectedStats);
      
      // Read provider
      final statsAsync = container.read(cachedTribeStatsProvider(tribeId).future);
      final stats = await statsAsync;
      
      expect(stats, equals(expectedStats));
      verifyNever(mockStatsService.getTribeStats(any));
    });

    test('should calculate fresh stats if cache is empty', () async {
      final tribeId = 'test-tribe-2';
      final expectedStats = TribeStats(
        memberCount: 20,
        totalXp: 2000,
        totalHabitsCompleted: 100,
        totalChallengesCompleted: 10,
      );
      
      when(mockStatsService.getTribeStats(tribeId))
          .thenAnswer((_) async => {
                'memberCount': 20,
                'totalXp': 2000,
                'totalHabitsCompleted': 100,
                'totalChallengesCompleted': 10,
              });
      
      final statsAsync = container.read(cachedTribeStatsProvider(tribeId).future);
      final stats = await statsAsync;
      
      expect(stats, equals(expectedStats));
      verify(mockStatsService.getTribeStats(tribeId)).called(1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/providers/cached_tribe_stats_provider_test.dart`
Expected: FAIL with "cachedTribeStatsProvider not defined"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/social/presentation/providers/cached_tribe_stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/domain/models/cached_stats.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/data/services/tribe_stats_service.dart';

final tribeStatsCacheProvider = Provider<TribeStatsCache>((ref) {
  return TribeStatsCache();
});

final cachedTribeStatsProvider = FutureProvider.family<TribeStats, String>((
  ref,
  tribeId,
) async {
  final cache = ref.watch(tribeStatsCacheProvider);
  final statsService = ref.watch(tribeStatsServiceProvider);
  
  // Check cache first
  final cached = cache.get(tribeId);
  if (cached != null) {
    return cached.stats;
  }
  
  // Calculate fresh stats
  final data = await statsService.getTribeStats(tribeId);
  final stats = TribeStats(
    memberCount: data['memberCount'] as int? ?? 0,
    totalXp: data['totalXp'] as int? ?? 0,
    totalHabitsCompleted: data['totalHabitsCompleted'] as int? ?? 0,
    totalChallengesCompleted: data['totalChallengesCompleted'] as int? ?? 0,
  );
  
  // Cache the result
  cache.set(tribeId, stats);
  
  return stats;
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/providers/cached_tribe_stats_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/providers/cached_tribe_stats_provider.dart test/features/social/presentation/providers/cached_tribe_stats_provider_test.dart
git commit -m "feat: add cachedTribeStatsProvider with cache-first logic"
```

---

## Task 4: Update Tribe Header Widgets to Use Cached Provider

**Files:**
- Modify: `lib/features/social/presentation/widgets/tribe_header_widgets.dart`

- [ ] **Step 1: Update imports**

```dart
// lib/features/social/presentation/widgets/tribe_header_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
```

- [ ] **Step 2: Update RealTimeMemberCount to use cached provider**

```dart
// lib/features/social/presentation/widgets/tribe_header_widgets.dart
class RealTimeMemberCount extends ConsumerWidget {
  final String tribeId;

  const RealTimeMemberCount({super.key, required this.tribeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedTribeStatsProvider(tribeId));

    return statsAsync.when(
      data: (stats) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, color: Theme.of(context).primaryColor, size: 16),
            const Gap(4),
            Text(
              '${stats.memberCount} Members',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, color: Theme.of(context).primaryColor, size: 16),
          const Gap(4),
          const Text(
            'Loading...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      error: (error, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, color: Theme.of(context).primaryColor, size: 16),
          const Gap(4),
          const Text(
            '-- Members',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Update RealTimeTribeProgressMetrics to use cached provider**

```dart
// lib/features/social/presentation/widgets/tribe_header_widgets.dart
class RealTimeTribeProgressMetrics extends ConsumerWidget {
  final bool isGlobal;
  final String tribeId;
  final ArchetypeTheme theme;

  const RealTimeTribeProgressMetrics({
    super.key,
    required this.isGlobal,
    required this.tribeId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedTribeStatsProvider(tribeId));

    return statsAsync.when(
      data: (stats) {
        final xpScore = stats.totalXp;
        final habitsCount = stats.totalHabitsCompleted;
        final questsCount = stats.totalChallengesCompleted;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                EmergeColors.glassWhite.withValues(alpha:0.1),
                EmergeColors.glassWhite.withValues(alpha:0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EmergeColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isGlobal ? Icons.public : Icons.local_fire_department,
                    color: isGlobal ? EmergeColors.teal : EmergeColors.coral,
                    size: 20,
                  ),
                  const Gap(8),
                  Text(
                    isGlobal ? 'Global Collective Power' : 'Tribe Ascendancy',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatOrb(
                    label: 'Total XP',
                    value:
                        '${xpScore >= 1000 ? '${(xpScore / 1000).toStringAsFixed(1)}k' : xpScore}',
                    color: EmergeColors.yellow,
                    icon: Icons.electric_bolt,
                  ),
                  StatOrb(
                    label: isGlobal ? 'Habits Overcome' : 'Habits Conquered',
                    value: _formatCount(habitsCount),
                    color: EmergeColors.teal,
                    icon: Icons.check_circle_outline,
                  ),
                  StatOrb(
                    label: 'Quests Beaten',
                    value: _formatCount(questsCount),
                    color: EmergeColors.violet,
                    icon: Icons.emoji_events,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _MetricsLoadingState(),
      error: (error, _) => _MetricsErrorState(),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/presentation/widgets/tribe_header_widgets.dart
git commit -m "refactor: update tribe widgets to use cached stats provider"
```

---

## Task 5: Create Tribe Card Widget

**Files:**
- Create: `lib/features/social/presentation/widgets/tribe_card.dart`
- Test: `test/features/social/presentation/widgets/tribe_card_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/presentation/widgets/tribe_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_card.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

void main() {
  testWidgets('TribeCard displays tribe information', (tester) async {
    final tribe = Tribe(
      id: 'test-tribe-1',
      name: 'Test Tribe',
      description: 'A test tribe',
      imageUrl: 'https://example.com/image.png',
      memberCount: 10,
      ownerId: 'owner-1',
      tags: ['test'],
      levelRequirement: 1,
      rank: 1,
      totalXp: 1000,
      type: TribeType.userPublic,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TribeCard(tribe: tribe),
          ),
        ),
      ),
    );

    expect(find.text('TEST TRIBE'), findsOneWidget);
    expect(find.text('A test tribe'), findsOneWidget);
  });

  testWidgets('TribeCard displays stats', (tester) async {
    final tribe = Tribe(
      id: 'test-tribe-1',
      name: 'Test Tribe',
      description: 'A test tribe',
      imageUrl: 'https://example.com/image.png',
      memberCount: 10,
      ownerId: 'owner-1',
      tags: ['test'],
      levelRequirement: 1,
      rank: 1,
      totalXp: 1000,
      type: TribeType.userPublic,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cachedTribeStatsProvider(tribe.id).overrideWithValue(
            AsyncValue.data(TribeStats(
              memberCount: 10,
              totalXp: 1000,
              totalHabitsCompleted: 50,
              totalChallengesCompleted: 5,
            )),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TribeCard(tribe: tribe),
          ),
        ),
      ),
    );

    expect(find.text('10'), findsOneWidget);
    expect(find.text('1.0k'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/widgets/tribe_card_test.dart`
Expected: FAIL with "TribeCard not defined"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/social/presentation/widgets/tribe_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class TribeCard extends ConsumerWidget {
  final Tribe tribe;

  const TribeCard({super.key, required this.tribe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedTribeStatsProvider(tribe.id));
    final theme = ArchetypeTheme.forArchetype(
      tribe.archetypeId != null
          ? UserArchetype.values.firstWhere(
              (a) => a.name == tribe.archetypeId,
              orElse: () => UserArchetype.scholar,
            )
          : UserArchetype.scholar,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EmergeColors.glassWhite.withValues(alpha:0.1),
            EmergeColors.glassWhite.withValues(alpha:0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.primaryColor, theme.accentColor],
                  ),
                ),
                child: Center(
                  child: Text(
                    theme.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tribe.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      tribe.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          statsAsync.when(
            data: (stats) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Members',
                  value: '${stats.memberCount}',
                  icon: Icons.people,
                  color: EmergeColors.teal,
                ),
                _StatItem(
                  label: 'XP',
                  value: stats.totalXp >= 1000
                      ? '${(stats.totalXp / 1000).toStringAsFixed(1)}k'
                      : '${stats.totalXp}',
                  icon: Icons.electric_bolt,
                  color: EmergeColors.yellow,
                ),
                _StatItem(
                  label: 'Habits',
                  value: '${stats.totalHabitsCompleted}',
                  icon: Icons.check_circle_outline,
                  color: EmergeColors.violet,
                ),
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: EmergeColors.teal),
            ),
            error: (_, __) => const Center(
              child: Text(
                'Error loading stats',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const Gap(4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/widgets/tribe_card_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/widgets/tribe_card.dart test/features/social/presentation/widgets/tribe_card_test.dart
git commit -m "feat: add TribeCard widget with real-time stats"
```

---

## Task 6: Create All Tribes Screen

**Files:**
- Create: `lib/features/social/presentation/screens/all_tribes_screen.dart`
- Test: `test/features/social/presentation/screens/all_tribes_screen_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/presentation/screens/all_tribes_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/all_tribes_screen.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

void main() {
  testWidgets('AllTribesScreen displays list of tribes', (tester) async {
    final tribes = [
      Tribe(
        id: 'tribe-1',
        name: 'Tribe 1',
        description: 'Description 1',
        imageUrl: 'https://example.com/image1.png',
        memberCount: 10,
        ownerId: 'owner-1',
        tags: ['test'],
        levelRequirement: 1,
        rank: 1,
        totalXp: 1000,
        type: TribeType.userPublic,
      ),
      Tribe(
        id: 'tribe-2',
        name: 'Tribe 2',
        description: 'Description 2',
        imageUrl: 'https://example.com/image2.png',
        memberCount: 20,
        ownerId: 'owner-2',
        tags: ['test'],
        levelRequirement: 1,
        rank: 2,
        totalXp: 2000,
        type: TribeType.userPublic,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allArchetypeClubsProvider.overrideWithValue(
            AsyncValue.data(tribes),
          ),
        ],
        child: const MaterialApp(
          home: AllTribesScreen(),
        ),
      ),
    );

    expect(find.text('TRIBE 1'), findsOneWidget);
    expect(find.text('TRIBE 2'), findsOneWidget);
  });

  testWidgets('AllTribesScreen shows loading state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allArchetypeClubsProvider.overrideWithValue(
            const AsyncValue.loading(),
          ),
        ],
        child: const MaterialApp(
          home: AllTribesScreen(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/screens/all_tribes_screen_test.dart`
Expected: FAIL with "AllTribesScreen not defined"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/social/presentation/screens/all_tribes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_card.dart';

class AllTribesScreen extends ConsumerWidget {
  const AllTribesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tribesAsync = ref.watch(allArchetypeClubsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'All Tribes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: tribesAsync.when(
        data: (tribes) {
          if (tribes.isEmpty) {
            return const Center(
              child: Text(
                'No tribes available',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allArchetypeClubsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: tribes.length,
              itemBuilder: (context, index) {
                return TribeCard(tribe: tribes[index]);
              },
            ),
          );
        },
        loading: () => const EmergeLoadingSkeleton(itemCount: 3),
        error: (error, stack) => AppErrorWidget(
          message: 'Could not load tribes',
          onRetry: () => ref.invalidate(allArchetypeClubsProvider),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/screens/all_tribes_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/screens/all_tribes_screen.dart test/features/social/presentation/screens/all_tribes_screen_test.dart
git commit -m "feat: add AllTribesScreen with tribe list and refresh"
```

---

## Task 7: Create Tribe Membership Service

**Files:**
- Create: `lib/features/social/data/services/tribe_membership_service.dart`
- Test: `test/features/social/data/services/tribe_membership_service_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/data/services/tribe_membership_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:emerge_app/features/social/data/services/tribe_membership_service.dart';

@GenerateMocks([FirebaseFirestore, DocumentReference, CollectionReference])
import 'tribe_membership_service_test.mocks.dart';

void main() {
  group('TribeMembershipService', () {
    late TribeMembershipService service;
    late MockFirebaseFirestore mockFirestore;
    late MockDocumentReference mockDocRef;
    late MockCollectionReference mockCollectionRef;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockDocRef = MockDocumentReference();
      mockCollectionRef = MockCollectionRef();
      service = TribeMembershipService(firestore: mockFirestore);
    });

    test('should add user to tribe members', () async {
      final tribeId = 'tribe-1';
      final userId = 'user-1';

      when(mockFirestore.collection('tribes')).thenReturn(mockCollectionRef);
      when(mockCollectionRef.doc(tribeId)).thenReturn(mockDocRef);
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      await service.joinTribe(tribeId, userId);

      verify(mockDocRef.update({
        'members': FieldValue.arrayUnion([userId])
      })).called(1);
    });

    test('should remove user from tribe members', () async {
      final tribeId = 'tribe-1';
      final userId = 'user-1';

      when(mockFirestore.collection('tribes')).thenReturn(mockCollectionRef);
      when(mockCollectionRef.doc(tribeId)).thenReturn(mockDocRef);
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      await service.leaveTribe(tribeId, userId);

      verify(mockDocRef.update({
        'members': FieldValue.arrayRemove([userId])
      })).called(1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/data/services/tribe_membership_service_test.dart`
Expected: FAIL with "TribeMembershipService not defined"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/social/data/services/tribe_membership_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TribeMembershipService {
  final FirebaseFirestore _firestore;

  TribeMembershipService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> joinTribe(String tribeId, String userId) async {
    try {
      await _firestore.collection('tribes').doc(tribeId).update({
        'members': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Failed to join tribe: $e');
    }
  }

  Future<void> leaveTribe(String tribeId, String userId) async {
    try {
      await _firestore.collection('tribes').doc(tribeId).update({
        'members': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw Exception('Failed to leave tribe: $e');
    }
  }

  Future<bool> isMember(String tribeId, String userId) async {
    try {
      final doc = await _firestore.collection('tribes').doc(tribeId).get();
      if (!doc.exists) return false;

      final members = doc.data()?['members'] as List<dynamic>?;
      return members?.contains(userId) ?? false;
    } catch (e) {
      return false;
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/data/services/tribe_membership_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/data/services/tribe_membership_service.dart test/features/social/data/services/tribe_membership_service_test.dart
git commit -m "feat: add TribeMembershipService for join/leave functionality"
```

---

## Task 8: Update TribeCard with Join/Leave Button

**Files:**
- Modify: `lib/features/social/presentation/widgets/tribe_card.dart`
- Test: `test/features/social/presentation/widgets/tribe_card_test.dart`

- [ ] **Step 1: Add membership check and join/leave button**

```dart
// lib/features/social/presentation/widgets/tribe_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/data/services/tribe_membership_service.dart';

final tribeMembershipServiceProvider = Provider<TribeMembershipService>((ref) {
  return TribeMembershipService();
});

class TribeCard extends ConsumerWidget {
  final Tribe tribe;

  const TribeCard({super.key, required this.tribe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedTribeStatsProvider(tribe.id));
    final authState = ref.watch(authStateChangesProvider);
    final userId = authState.value;
    final theme = ArchetypeTheme.forArchetype(
      tribe.archetypeId != null
          ? UserArchetype.values.firstWhere(
              (a) => a.name == tribe.archetypeId,
              orElse: () => UserArchetype.scholar,
            )
          : UserArchetype.scholar,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EmergeColors.glassWhite.withValues(alpha:0.1),
            EmergeColors.glassWhite.withValues(alpha:0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.primaryColor, theme.accentColor],
                  ),
                ),
                child: Center(
                  child: Text(
                    theme.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tribe.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      tribe.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          statsAsync.when(
            data: (stats) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Members',
                      value: '${stats.memberCount}',
                      icon: Icons.people,
                      color: EmergeColors.teal,
                    ),
                    _StatItem(
                      label: 'XP',
                      value: stats.totalXp >= 1000
                          ? '${(stats.totalXp / 1000).toStringAsFixed(1)}k'
                          : '${stats.totalXp}',
                      icon: Icons.electric_bolt,
                      color: EmergeColors.yellow,
                    ),
                    _StatItem(
                      label: 'Habits',
                      value: '${stats.totalHabitsCompleted}',
                      icon: Icons.check_circle_outline,
                      color: EmergeColors.violet,
                    ),
                  ],
                ),
                const Gap(12),
                if (userId != null)
                  _MembershipButton(
                    tribeId: tribe.id,
                    userId: userId,
                  ),
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: EmergeColors.teal),
            ),
            error: (_, __) => const Center(
              child: Text(
                'Error loading stats',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipButton extends ConsumerStatefulWidget {
  final String tribeId;
  final String userId;

  const _MembershipButton({
    required this.tribeId,
    required this.userId,
  });

  @override
  ConsumerState<_MembershipButton> createState() => _MembershipButtonState();
}

class _MembershipButtonState extends ConsumerState<_MembershipButton> {
  bool _isMember = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkMembership();
  }

  Future<void> _checkMembership() async {
    final service = ref.read(tribeMembershipServiceProvider);
    final isMember = await service.isMember(widget.tribeId, widget.userId);
    if (mounted) {
      setState(() {
        _isMember = isMember;
      });
    }
  }

  Future<void> _handleJoinLeave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(tribeMembershipServiceProvider);
      if (_isMember) {
        await service.leaveTribe(widget.tribeId, widget.userId);
      } else {
        await service.joinTribe(widget.tribeId, widget.userId);
      }

      // Invalidate cache to refresh stats
      ref.read(tribeStatsCacheProvider).invalidate(widget.tribeId);
      ref.invalidate(cachedTribeStatsProvider(widget.tribeId));

      if (mounted) {
        setState(() {
          _isMember = !_isMember;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isMember ? 'Failed to leave tribe' : 'Failed to join tribe'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleJoinLeave,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isMember
              ? EmergeColors.glassWhite.withValues(alpha:0.1)
              : EmergeColors.teal,
          foregroundColor: _isMember ? Colors.white70 : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _isMember ? EmergeColors.glassBorder : Colors.transparent,
            ),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: EmergeColors.teal,
                ),
              )
            : Text(
                _isMember ? 'Leave Tribe' : 'Join Tribe',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const Gap(4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Update test for join/leave button**

```dart
// test/features/social/presentation/widgets/tribe_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_card.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/data/services/tribe_membership_service.dart';

@GenerateMocks([TribeMembershipService])
import 'tribe_card_test.mocks.dart';

void main() {
  testWidgets('TribeCard displays join button when not member', (tester) async {
    final tribe = Tribe(
      id: 'test-tribe-1',
      name: 'Test Tribe',
      description: 'A test tribe',
      imageUrl: 'https://example.com/image.png',
      memberCount: 10,
      ownerId: 'owner-1',
      tags: ['test'],
      levelRequirement: 1,
      rank: 1,
      totalXp: 1000,
      type: TribeType.userPublic,
    );

    final mockService = MockTribeMembershipService();
    when(mockService.isMember(any, any)).thenAnswer((_) async => false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cachedTribeStatsProvider(tribe.id).overrideWithValue(
            AsyncValue.data(TribeStats(
              memberCount: 10,
              totalXp: 1000,
              totalHabitsCompleted: 50,
              totalChallengesCompleted: 5,
            )),
          ),
          tribeMembershipServiceProvider.overrideWithValue(mockService),
          authStateChangesProvider.overrideWithValue(
            AsyncValue.data('user-1'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TribeCard(tribe: tribe),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Join Tribe'), findsOneWidget);
  });

  testWidgets('TribeCard displays leave button when member', (tester) async {
    final tribe = Tribe(
      id: 'test-tribe-1',
      name: 'Test Tribe',
      description: 'A test tribe',
      imageUrl: 'https://example.com/image.png',
      memberCount: 10,
      ownerId: 'owner-1',
      tags: ['test'],
      levelRequirement: 1,
      rank: 1,
      totalXp: 1000,
      type: TribeType.userPublic,
    );

    final mockService = MockTribeMembershipService();
    when(mockService.isMember(any, any)).thenAnswer((_) async => true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cachedTribeStatsProvider(tribe.id).overrideWithValue(
            AsyncValue.data(TribeStats(
              memberCount: 10,
              totalXp: 1000,
              totalHabitsCompleted: 50,
              totalChallengesCompleted: 5,
            )),
          ),
          tribeMembershipServiceProvider.overrideWithValue(mockService),
          authStateChangesProvider.overrideWithValue(
            AsyncValue.data('user-1'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TribeCard(tribe: tribe),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Leave Tribe'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/widgets/tribe_card_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/presentation/widgets/tribe_card.dart test/features/social/presentation/widgets/tribe_card_test.dart
git commit -m "feat: add join/leave button to TribeCard"
```

---

## Task 9: Update AllTribesScreen to Handle Join/Leave Actions

**Files:**
- Modify: `lib/features/social/presentation/screens/all_tribes_screen.dart`

- [ ] **Step 1: Add refresh on join/leave**

```dart
// lib/features/social/presentation/screens/all_tribes_screen.dart
// Update the RefreshIndicator onRefresh callback (around line 1021)
RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(allArchetypeClubsProvider);
    // Also invalidate all cached stats
    final tribes = ref.read(allArchetypeClubsProvider).value ?? [];
    for (final tribe in tribes) {
      ref.read(tribeStatsCacheProvider).invalidate(tribe.id);
      ref.invalidate(cachedTribeStatsProvider(tribe.id));
    }
  },
  child: ListView.builder(
    padding: const EdgeInsets.only(bottom: 32),
    itemCount: tribes.length,
    itemBuilder: (context, index) {
      return TribeCard(tribe: tribes[index]);
    },
  ),
),
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/social/presentation/screens/all_tribes_screen.dart
git commit -m "refactor: refresh all stats on join/leave in AllTribesScreen"
```

---

## Task 10: Add "See All" Button to Tribe Tab Content

**Files:**
- Modify: `lib/features/social/presentation/screens/tribe_tab_content.dart`

- [ ] **Step 1: Add "See All" button to header**

```dart
// lib/features/social/presentation/screens/tribe_tab_content.dart
// Add after the club name and subtitle section (around line 145)
const Gap(16),

// ===== SEE ALL BUTTON =====
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    GestureDetector(
      onTap: () => context.push('/tribes/all'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: EmergeColors.glassWhite.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EmergeColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'See All',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: EmergeColors.teal,
                letterSpacing: 0.5,
              ),
            ),
            const Gap(4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: EmergeColors.teal,
            ),
          ],
        ),
      ),
    ),
  ],
).animate().fadeIn(delay: 250.ms),

const Gap(16),
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_tab_content.dart
git commit -m "feat: add 'See All' button to tribe tab content"
```

---

## Task 11: Add Router Route for All Tribes Screen

**Files:**
- Modify: `lib/core/router/router.dart`

- [ ] **Step 1: Add import**

```dart
// lib/core/router/router.dart
import 'package:emerge_app/features/social/presentation/screens/all_tribes_screen.dart';
```

- [ ] **Step 2: Add route**

```dart
// lib/core/router/router.dart
// Add this route inside the tribes branch routes (after line 276)
GoRoute(
  path: 'all',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => const AllTribesScreen(),
),
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/router/router.dart
git commit -m "feat: add route for AllTribesScreen"
```

---

## Task 12: Integration Testing

**Files:**
- Test: `test/integration/tribe_stats_integration_test.dart`

- [ ] **Step 1: Write integration test**

```dart
// test/integration/tribe_stats_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

void main() {
  group('Tribe Stats Integration', () {
    test('cache provider integrates with stats service', () async {
      final container = ProviderContainer();
      
      try {
        final tribeId = 'test-tribe-1';
        
        // First call should calculate stats
        final stats1 = await container.read(
          cachedTribeStatsProvider(tribeId).future,
        );
        
        expect(stats1, isNotNull);
        
        // Second call should use cache
        final stats2 = await container.read(
          cachedTribeStatsProvider(tribeId).future,
        );
        
        expect(stats2, equals(stats1));
      } finally {
        container.dispose();
      }
    });

    test('cache invalidation works correctly', () async {
      final container = ProviderContainer();
      
      try {
        final tribeId = 'test-tribe-2';
        final cache = container.read(tribeStatsCacheProvider);
        
        // Set initial cache
        final initialStats = TribeStats(
          memberCount: 10,
          totalXp: 1000,
          totalHabitsCompleted: 50,
          totalChallengesCompleted: 5,
        );
        cache.set(tribeId, initialStats);
        
        // Verify cache is set
        final cached = cache.get(tribeId);
        expect(cached, isNotNull);
        expect(cached!.stats, equals(initialStats));
        
        // Invalidate cache
        cache.invalidate(tribeId);
        
        // Verify cache is cleared
        final afterInvalidation = cache.get(tribeId);
        expect(afterInvalidation, isNull);
      } finally {
        container.dispose();
      }
    });
  });
}
```

- [ ] **Step 2: Run integration test**

Run: `flutter test test/integration/tribe_stats_integration_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add test/integration/tribe_stats_integration_test.dart
git commit -m "test: add integration tests for tribe stats caching"
```

---

## Task 13: Manual Testing and Verification

**Files:**
- None (manual testing)

- [ ] **Step 1: Run the app**

```bash
flutter run
```

- [ ] **Step 2: Navigate to tribes tab**

Verify:
- Tribe ascendancy stats display real values (not placeholders)
- Member count is accurate
- Total XP is calculated from actual member data
- Habits completed and challenges completed show real values

- [ ] **Step 3: Click "See All" button**

Verify:
- Navigate to AllTribesScreen
- See list of all available tribes
- Each tribe card shows real-time stats
- Pull-to-refresh works and updates stats

- [ ] **Step 4: Test cache behavior**

Verify:
- Stats load quickly on subsequent views (using cache)
- Stats update after 5 minutes (cache expiration)
- Manual refresh updates stats immediately

- [ ] **Step 5: Test error handling**

Verify:
- Network errors show appropriate error states
- App doesn't crash on failures
- Retry functionality works

- [ ] **Step 6: Run all tests**

```bash
flutter test
```

Expected: All tests pass

- [ ] **Step 7: Run linting**

```bash
flutter analyze
```

Expected: No issues

- [ ] **Step 8: Commit final changes**

```bash
git add .
git commit -m "test: complete manual testing and verification"
```

---

## Summary

This implementation plan creates a complete real-time tribe statistics system with:

1. **Cache Data Model** - `CachedStats` with TTL logic
2. **Cache Provider** - `TribeStatsCache` for managing cached stats
3. **Cached Stats Provider** - `cachedTribeStatsProvider` with cache-first logic
4. **Updated Widgets** - Tribe widgets now use cached provider for real stats
5. **Tribe Card Component** - Reusable widget displaying tribe info and stats
6. **All Tribes Screen** - Browse and view all tribes with real-time stats
7. **Tribe Membership Service** - Service for joining and leaving tribes
8. **Join/Leave Functionality** - TribeCard with join/leave buttons and membership status
9. **"See All" Button** - Easy navigation to tribes list
10. **Router Integration** - Route for AllTribesScreen
11. **Comprehensive Testing** - Unit, widget, and integration tests
12. **Manual Verification** - End-to-end testing of all functionality

The hybrid approach ensures accurate stats while maintaining good performance through intelligent caching. Users can browse all tribes, view real-time statistics, and join/leave tribes with automatic cache invalidation.