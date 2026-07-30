import 'package:emerge_app/core/drift/daos/habit_completions_dao.dart';
import 'package:emerge_app/core/drift/daos/tribe_membership_dao.dart';
import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/domain/repositories/friend_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakWatchdog {
  final FriendRepository friendRepo;
  final HabitCompletionsDao habitCompletionsDao;
  final SocialNotificationService notificationService;
  final TribeMembershipDao tribeMembershipDao;

  StreakWatchdog({
    required this.friendRepo,
    required this.habitCompletionsDao,
    required this.notificationService,
    required this.tribeMembershipDao,
  });

  /// Checks whether [partnerId] was already checked within the last 24 hours.
  /// Persisted via SharedPreferences so rate-limit survives app restarts.
  Future<bool> _isRateLimited(String partnerId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckKey = 'watchdog_last_check_$partnerId';
    final lastCheckMs = prefs.getInt(lastCheckKey);
    if (lastCheckMs != null) {
      final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);
      if (DateTime.now().difference(lastCheck) < const Duration(hours: 24)) {
        return true;
      }
    }
    return false;
  }

  /// Marks [partnerId] as checked now. Persisted via SharedPreferences.
  Future<void> _markChecked(String partnerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'watchdog_last_check_$partnerId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> checkPartners({
    required String userId,
    required String tribeId,
  }) async {
    try {
      final partners = await friendRepo.getFriends(userId);
      for (final partner in partners) {
        // Scope to tribe: only notify about partners in the same tribe.
        final membership = await tribeMembershipDao.getMembership(
          partner.id,
          tribeId,
        );
        if (membership == null) continue;

        // Rate-limit: skip if checked within last 24h (persisted)
        if (await _isRateLimited(partner.id)) {
          continue;
        }
        await _markChecked(partner.id);

        final lastCompletion = await habitCompletionsDao.getLastCompletion(partner.id);
        if (lastCompletion == null) continue;

        final completedAt = DateTime.parse(lastCompletion.completedAt);
        final daysSince = DateTime.now().difference(completedAt).inDays;
        if (daysSince >= 2) {
          await notificationService.sendNotification(
            userId,
            AppNotification(
              id: '',
              type: AppNotificationType.tribeActivity,
              title: '${partner.name} missed 2 days',
              body: 'Your tribe ($tribeId) partner needs encouragement!',
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    } catch (error, stack) {
      AppLogger.e('StreakWatchdog error in checkPartners', error, stack);
    }
  }
}
