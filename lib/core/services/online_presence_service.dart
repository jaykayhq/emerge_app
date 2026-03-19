import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for tracking user online presence through periodic heartbeats.
///
/// This service maintains a 2-minute heartbeat that updates the user's
/// online status in Firestore, allowing other users to see their presence.
class OnlinePresenceService {
  final FirebaseFirestore _firestore;
  Timer? _heartbeatTimer;
  String? _currentUserId;

  OnlinePresenceService(this._firestore);

  /// Starts the heartbeat timer for a specific user.
  ///
  /// Sends a heartbeat every 2 minutes to Firestore, updating the user's
  /// online status and last seen timestamp.
  ///
  /// If a heartbeat is already running for a different user, it will be
  /// stopped before starting the new one.
  Future<void> startHeartbeat(String userId) async {
    // Stop existing heartbeat if running for a different user
    if (_currentUserId != null && _currentUserId != userId) {
      await stopHeartbeat();
    }

    // Don't start if already running for this user
    if (_heartbeatTimer != null && _currentUserId == userId) {
      return;
    }

    _currentUserId = userId;

    // Send immediate heartbeat
    await _updateOnlineStatus(userId);

    // Start periodic heartbeat every 2 minutes
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await _updateOnlineStatus(userId);
    });
  }

  /// Stops the heartbeat timer.
  ///
  /// Call this when the user signs out or the app is being destroyed.
  Future<void> stopHeartbeat() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _currentUserId = null;
  }

  /// Updates the user's online status in Firestore.
  ///
  /// Writes to the `users/{userId}/presence` collection with:
  /// - `online`: true (user is currently online)
  /// - `lastSeen`: server timestamp (when this heartbeat was sent)
  Future<void> _updateOnlineStatus(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('presence')
          .doc('status')
          .set({
            'online': true,
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail to avoid spamming logs if network is unavailable
      // The heartbeat will retry on the next interval
    }
  }

  /// Marks the user as offline (optional cleanup).
  ///
  /// This can be called when the user explicitly signs out to update
  /// their status to offline. Note that without this, other users will
  /// see the user as offline based on the lastSeen timestamp.
  Future<void> setOffline(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('presence')
          .doc('status')
          .set({
            'online': false,
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail
    }
  }
}
