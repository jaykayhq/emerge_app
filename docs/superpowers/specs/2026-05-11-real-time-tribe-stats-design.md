# Real-Time Tribe Stats with Hybrid Approach

**Date:** 2026-05-11  
**Topic:** Real-time tribe statistics with caching and "See All" tribes functionality

## Problem Statement

The tribes section currently displays placeholder/incorrect values for tribe ascendancy and global collective power. Users need to see real individual tribe and collective global stats. Additionally, users need a way to browse and potentially join other tribes.

## Solution Overview

Implement a hybrid approach that calculates accurate tribe statistics on-demand and caches them locally with periodic refresh. Add a "See All" button to allow users to browse and join other tribes.

## Architecture

### Enhanced Provider Layer

**CachedTribeStatsProvider:**
- Wraps `realTimeTribeStatsProvider` with local caching and periodic refresh logic
- Uses `TribeStatsService` to calculate real stats from member data
- Caches results with 5-minute TTL
- Provides refresh method for manual updates
- Falls back to direct calculation if cache fails

### Local Caching Strategy

**Cache Structure:**
```dart
class TribeStatsCache {
  final Map<String, CachedStats> _cache = {};
  
  static const Duration _cacheTtl = Duration(minutes: 5);
  
  CachedStats? get(String tribeId) {
    final cached = _cache[tribeId];
    if (cached == null) return null;
    
    if (DateTime.now().difference(cached.timestamp) > _cacheTtl) {
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
}
```

**Cache Invalidation:**
- Time-based: 5-minute TTL
- Manual: User can pull-to-refresh
- Event-based: When user joins/leaves a tribe, refresh that tribe's stats

### All Tribes Screen

**AllTribesScreen:**
- New screen displaying all available tribes with their real-time stats
- Shows tribe name, description, member count, total XP, and join status
- Allows users to join tribes (if not already joined)
- Filters/sorting options (by member count, XP, etc.)
- Consistent styling with existing tribe UI

**UI Components:**
- Tribe card with emblem, name, description
- Real-time stats display (member count, total XP, habits completed, challenges completed)
- Join/Leave button based on user's membership status
- Search and filter functionality
- Pull-to-refresh for manual cache refresh

## Data Flow

### Stats Loading Flow

1. User opens tribes tab → `CachedTribeStatsProvider` is invoked
2. Provider checks local cache for tribe stats
3. If cache exists and is within 5-minute TTL → return cached data immediately
4. If cache is stale or empty → use `TribeStatsService` to calculate real stats from Firestore
5. Cache the calculated results with current timestamp
6. UI displays stats via `RealTimeTribeProgressMetrics`
7. Background refresh triggers every 5 minutes to update cache

### "See All" Flow

1. User clicks "See All" button → navigate to `AllTribesScreen`
2. Screen loads all tribes via `allArchetypeClubsProvider`
3. For each tribe, `CachedTribeStatsProvider` fetches stats (using cache if available)
4. Display list with tribe info, real-time stats, and join status
5. User can join tribes (if not already joined) → updates tribe membership in Firestore
6. Join action triggers cache refresh for affected tribes

## Components

### Enhanced Stats Provider

**File:** `lib/features/social/presentation/providers/cached_tribe_stats_provider.dart`

**Responsibilities:**
- Wrap existing `realTimeTribeStatsProvider` with caching logic
- Implement 5-minute TTL for cached stats
- Provide manual refresh capability
- Handle cache failures gracefully

**Key Methods:**
```dart
final cachedTribeStatsProvider = StreamProvider.family<TribeStats, String>((ref, tribeId) {
  final cache = ref.watch(tribeStatsCacheProvider);
  final statsService = ref.watch(tribeStatsServiceProvider);
  
  // Check cache first
  final cached = cache.get(tribeId);
  if (cached != null) {
    return Stream.value(cached.stats);
  }
  
  // Calculate fresh stats
  return statsService.getTribeStats(tribeId).asStream().map((data) {
    final stats = TribeStats(
      memberCount: data['memberCount'],
      totalXp: data['totalXp'],
      totalHabitsCompleted: data['totalHabitsCompleted'],
      totalChallengesCompleted: data['totalChallengesCompleted'],
    );
    cache.set(tribeId, stats);
    return stats;
  });
});
```

### All Tribes Screen

**File:** `lib/features/social/presentation/screens/all_tribes_screen.dart`

**Responsibilities:**
- Display list of all available tribes
- Show real-time stats for each tribe
- Allow users to join/leave tribes
- Implement search and filter functionality
- Handle pull-to-refresh

**UI Structure:**
```dart
class AllTribesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tribesAsync = ref.watch(allArchetypeClubsProvider);
    
    return tribesAsync.when(
      data: (tribes) => RefreshIndicator(
        onRefresh: () => _refreshAllStats(ref, tribes),
        child: ListView.builder(
          itemCount: tribes.length,
          itemBuilder: (context, index) {
            final tribe = tribes[index];
            return TribeCard(tribe: tribe);
          },
        ),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => ErrorWidget(error),
    );
  }
}
```

### Tribe Card Component

**File:** `lib/features/social/presentation/widgets/tribe_card.dart`

**Responsibilities:**
- Display tribe information (name, description, emblem)
- Show real-time stats (member count, XP, habits, challenges)
- Show join/leave button based on membership status
- Handle join/leave actions

**UI Elements:**
- Tribe emblem with archetype colors
- Tribe name and description
- Stats orbs (member count, XP, habits, challenges)
- Join/Leave button with appropriate styling
- Visual indicator for user's current tribe

### UI Updates

**File:** `lib/features/social/presentation/screens/tribe_tab_content.dart`

**Changes:**
- Add "See All" button in top-right corner
- Update `RealTimeTribeProgressMetrics` to use cached provider
- Ensure consistent styling with existing tribe UI

**Button Placement:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Your Archetype Tribe'),
    TextButton(
      onPressed: () => context.push('/tribes/all'),
      child: const Text('See All'),
    ),
  ],
)
```

## Error Handling

### Stats Calculation Errors

- If `TribeStatsService` fails to calculate stats → return fallback values (0 for all metrics)
- Log errors for debugging but don't block UI
- Show error state in `RealTimeTribeProgressMetrics` with retry option

### Cache Errors

- If cache read/write fails → fall back to direct calculation
- Cache failures are transparent to user
- Continue with degraded functionality

### Network Errors

- If Firestore queries fail → show loading state with timeout
- Implement exponential backoff for retries
- Display user-friendly error messages

### Join/Leave Errors

- If tribe join fails → show error message with reason (e.g., tribe full, level requirement not met)
- If tribe leave fails → show error and keep user in tribe
- Validate requirements before attempting join

## Testing

### Unit Tests

**TribeStatsService Tests:**
- Test stat calculation logic with mock data
- Test handling of empty member lists
- Test handling of missing user_stats documents
- Test batch query handling for large tribes

**Cache Provider Tests:**
- Test TTL logic (cache expires after 5 minutes)
- Test cache hit/miss scenarios
- Test cache invalidation
- Test fallback behavior on cache failures

**Error Handling Tests:**
- Test fallback behavior on service failures
- Test error logging
- Test UI error states

### Integration Tests

**End-to-End Stats Loading:**
- Test complete stats loading flow
- Verify cache is used on subsequent loads
- Verify cache refresh after TTL expires

**Cache Refresh Triggers:**
- Test manual refresh via pull-to-refresh
- Test automatic refresh after 5 minutes
- Test refresh on join/leave actions

**Join/Leave Functionality:**
- Test joining a tribe
- Test leaving a tribe
- Test validation of join requirements
- Test cache refresh after membership changes

### Widget Tests

**RealTimeTribeProgressMetrics:**
- Test display of correct data
- Test loading state
- Test error state
- Test retry functionality

**AllTribesScreen:**
- Test rendering of tribe list
- Test search functionality
- Test filter functionality
- Test pull-to-refresh

**TribeCard:**
- Test display of tribe information
- Test display of real-time stats
- Test join/leave button state
- Test join/leave actions

## Performance Considerations

**Firestore Query Optimization:**
- Batch queries for large tribes (30 members per batch)
- Limit concurrent queries to avoid hitting Firestore limits
- Implement query result caching at the service level

**Cache Management:**
- Limit cache size to prevent memory issues
- Implement LRU eviction if cache grows too large
- Clear cache on app restart

**UI Performance:**
- Use lazy loading for tribe lists
- Implement pagination for large tribe lists
- Debounce search queries to reduce unnecessary requests

## Security Considerations

**Data Access:**
- Ensure users can only view stats for tribes they have access to
- Validate join requests against tribe requirements
- Prevent unauthorized tribe modifications

**Rate Limiting:**
- Implement rate limiting for stat calculation requests
- Prevent abuse of refresh functionality
- Limit concurrent stat calculations

## Future Enhancements

**Potential Improvements:**
- Implement Cloud Functions for automatic stat synchronization
- Add real-time updates via Firestore listeners
- Implement advanced filtering and sorting options
- Add tribe comparison features
- Implement tribe recommendations based on user behavior

## Success Criteria

- Users see accurate real-time tribe statistics
- Stats are cached and refreshed appropriately
- "See All" button allows browsing and joining tribes
- Error handling is robust and user-friendly
- Performance is acceptable for typical use cases
- Tests cover critical functionality