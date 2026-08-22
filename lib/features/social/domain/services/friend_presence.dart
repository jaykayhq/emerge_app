import 'package:emerge_app/features/social/domain/entities/social_entities.dart';

/// Presence snapshot read from `users/{uid}/presence/status`.
typedef PresenceInfo = ({bool onlineFlag, DateTime? lastSeen});

/// Pure presence resolution for accountability partners.
///
/// The heartbeat service writes `users/{uid}/presence/status` with
/// `{online: bool, lastSeen: Timestamp}`, but friend documents cache an
/// `isOnline` flag that nothing ever updates. Online state must therefore
/// be derived from the live presence document, expiring after the heartbeat
/// timeout so users who force-quit don't linger as "online".
abstract final class FriendPresence {
  /// Matches [FirestoreFriendRepository.watchOnlineStatus]'s staleness window.
  static const defaultHeartbeatTimeout = Duration(minutes: 5);

  /// True when [onlineFlag] is set and [lastSeen] is within [maxAge] of now.
  static bool isOnline({
    required bool onlineFlag,
    required DateTime? lastSeen,
    DateTime? now,
    Duration maxAge = defaultHeartbeatTimeout,
  }) {
    if (!onlineFlag || lastSeen == null) return false;
    final reference = now ?? DateTime.now();
    return lastSeen.isAfter(reference.subtract(maxAge));
  }

  /// Returns only the friends whose derived presence is online, with
  /// [Friend.isOnline] set from the resolved presence data.
  static List<Friend> markOnline(
    List<Friend> friends,
    Map<String, PresenceInfo> presence, {
    DateTime? now,
  }) {
    final online = <Friend>[];
    for (final friend in friends) {
      final info = presence[friend.id];
      final isFresh = isOnline(
        onlineFlag: info?.onlineFlag ?? false,
        lastSeen: info?.lastSeen,
        now: now,
      );
      if (!isFresh) continue;
      online.add(
        Friend(
          id: friend.id,
          name: friend.name,
          archetype: friend.archetype,
          level: friend.level,
          streak: friend.streak,
          isOnline: true,
          lastSeen: friend.lastSeen,
          avatarUrl: friend.avatarUrl,
          xp: friend.xp,
          equippedTitle: friend.equippedTitle,
          equippedNameplate: friend.equippedNameplate,
          activeContractIds: friend.activeContractIds,
          lastActiveAt: friend.lastActiveAt,
        ),
      );
    }
    return online;
  }
}
