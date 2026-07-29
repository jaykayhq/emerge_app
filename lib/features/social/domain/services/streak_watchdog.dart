import 'dart:collection';
import 'package:emerge_app/core/drift/daos/habit_completions_dao.dart';
import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/domain/repositories/friend_repository.dart';

class StreakWatchdog {
  final FriendRepository friendRepo;
  final HabitCompletionsDao habitCompletionsDao;
  final SocialNotificationService notificationService;
  final HashMap<String, DateTime> _lastCheck = HashMap();

  StreakWatchdog({
    required this.friendRepo,
    required this.habitCompletionsDao,
    required this.notificationService,
  });

  Future<void> checkPartners({
    required String userId,
    required String tribeId,
  }) async {
    try {
      final partners = await friendRepo.getFriends(userId);
      for (final partner in partners) {
        // Rate-limit: skip if checked within last 24h
        final lastChecked = _lastCheck[partner.id];
        if (lastChecked != null &&
            DateTime.now().difference(lastChecked).inHours < 24) {
          continue;
        }
        _lastCheck[partner.id] = DateTime.now();

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
              body: 'Send them some encouragement!',
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
