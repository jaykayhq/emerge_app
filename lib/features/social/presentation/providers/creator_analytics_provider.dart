// lib/features/social/presentation/providers/creator_analytics_provider.dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
Future<CreatorAnalytics> creatorAnalytics(Ref ref, {
  required String uid,
  required String tribeId,
}) async {
  final service = ref.watch(creatorAnalyticsServiceProvider);
  final snapshotService = ref.watch(tribeAnalyticsSnapshotServiceProvider);

  // Non-blocking snapshot write when stale (never awaited before render).
  unawaited(snapshotService.ensureTodaySnapshot(uid: uid, tribeId: tribeId));

  final analyticsResult = await service.getCreatorAnalytics(
    uid: uid,
    tribeId: tribeId,
  );
  final trendsResult = await snapshotService.getTrends(tribeId: tribeId);

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