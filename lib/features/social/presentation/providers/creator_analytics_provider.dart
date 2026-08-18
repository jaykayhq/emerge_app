// lib/features/social/presentation/providers/creator_analytics_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/social/data/services/creator_analytics_service.dart';
import 'package:emerge_app/features/social/data/services/tribe_analytics_snapshot_service.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';

part 'creator_analytics_provider.g.dart';

@Riverpod(keepAlive: true)
CreatorAnalyticsService creatorAnalyticsService(Ref ref) {
  return CreatorAnalyticsService();
}

@Riverpod(keepAlive: true)
TribeAnalyticsSnapshotService tribeAnalyticsSnapshotService(Ref ref) {
  return TribeAnalyticsSnapshotService();
}

/// Full analytics for (uid, tribeId). Refreshes on invalidation
/// (e.g. after a share action or pull-to-refresh).
@riverpod
Future<CreatorAnalytics> creatorAnalytics(
  Ref ref, {
  required String uid,
  required String tribeId,
}) async {
  final service = ref.watch(creatorAnalyticsServiceProvider);
  final snapshotService = ref.watch(tribeAnalyticsSnapshotServiceProvider);
  final dao = ref.watch(tribeAnalyticsDaoProvider);

  // Fire the snapshot write and the KPI read concurrently. The KPI render
  // never waits on the Firestore write, so a slow network can't stall the
  // tab before the offline Drift fallback can render.
  final snapshotWrite = snapshotService.ensureTodaySnapshot(
    uid: uid,
    tribeId: tribeId,
  );
  final analyticsResult = await service.getCreatorAnalytics(
    uid: uid,
    tribeId: tribeId,
  );

  // Today's trend point needs the snapshot to exist first — join the write
  // before reading the history.
  await snapshotWrite;
  final trendsResult = await snapshotService.getTrends(tribeId: tribeId);

  // Cache the current aggregation for offline-first repeat opens. Joined
  // before the fallback read below so a subsequent cached read sees it.
  await analyticsResult.fold((_) => Future.value(), (analytics) async {
    try {
      await dao.upsertSnapshot(
        userId: uid,
        tribeId: tribeId,
        date: TribeAnalyticsSnapshotService.dateKey(DateTime.now()),
        memberCount: analytics.memberCount,
        totalXp: analytics.totalXp,
        totalHabitsCompleted: analytics.totalHabitsCompleted,
        totalChallengesCompleted: analytics.totalChallengesCompleted,
        activeMembers: analytics.activeMembers,
        newMembersThisWeek: analytics.newMembersThisWeek,
      );
    } catch (_) {
      // Cache misses are fine — the next successful open refills it.
    }
  });

  // Offline-first: when Firestore is unreachable, render the last cached
  // snapshot instead of failing the whole tab.
  if (analyticsResult.isLeft()) {
    final cached = await dao.getLatest(userId: uid, tribeId: tribeId);
    if (cached != null) {
      return CreatorAnalytics(
        tribeId: cached.tribeId,
        tribeName: '',
        memberCount: cached.memberCount,
        totalXp: cached.totalXp,
        totalHabitsCompleted: cached.totalHabitsCompleted,
        totalChallengesCompleted: cached.totalChallengesCompleted,
        newMembersThisWeek: cached.newMembersThisWeek,
        activeMembers: cached.activeMembers,
        activeRate: cached.memberCount > 0
            ? cached.activeMembers / cached.memberCount
            : 0,
        blueprintStats: const <BlueprintStat>[],
        topMembers: const <MemberStat>[],
        challengeStats: const <ChallengeStat>[],
        trends: const [],
      );
    }
  }

  return analyticsResult.fold(
    (error) => throw error,
    (analytics) => CreatorAnalytics(
      tribeId: analytics.tribeId,
      tribeName: analytics.tribeName,
      memberCount: analytics.memberCount,
      totalXp: analytics.totalXp,
      totalHabitsCompleted: analytics.totalHabitsCompleted,
      totalChallengesCompleted: analytics.totalChallengesCompleted,
      newMembersThisWeek: analytics.newMembersThisWeek,
      activeMembers: analytics.activeMembers,
      activeRate: analytics.activeRate,
      blueprintStats: analytics.blueprintStats,
      topMembers: analytics.topMembers,
      challengeStats: analytics.challengeStats,
      // Trends are best-effort: if the snapshot read fails, render KPIs
      // with an empty trend list rather than failing the whole tab.
      trends: trendsResult.getRight().toNullable() ?? const [],
    ),
  );
}
