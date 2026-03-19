import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onlinePresenceServiceProvider = Provider(
  (ref) => OnlinePresenceService(FirebaseFirestore.instance),
);

class OnlinePresenceService {
  final FirebaseFirestore _firestore;
  Timer? _heartbeatTimer;

  OnlinePresenceService(this._firestore);

  void startHeartbeat(String userId) {
    if (userId.isEmpty) return;

    _heartbeatTimer?.cancel();

    // Initial pulse
    _updateActivity(userId);

    // Periodic pulse every 5 minutes
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateActivity(userId);
    });

    AppLogger.i('OnlinePresenceService: Heartbeat started for $userId');
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    AppLogger.i('OnlinePresenceService: Heartbeat stopped');
  }

  Future<void> _updateActivity(String userId) async {
    try {
      // Update the path watched by FriendRepository.watchOnlineStatus
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('presence')
          .doc('status')
          .set({
            'online': true,
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Also update lastActiveDate in user_stats for game logic
      await _firestore.collection('user_stats').doc(userId).set({
        'worldState': {'lastActiveDate': FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));

      AppLogger.d('OnlinePresenceService: Online status updated for $userId');
    } catch (e) {
      AppLogger.e('OnlinePresenceService: Failed to update activity', e);
    }
  }
}
