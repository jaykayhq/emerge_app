import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/tribe.dart';

/// Service for managing club/tribe creation and approval workflow
/// Implements phased rollout: Official → Private → Public clubs
class ClubCreationService {
  final FirebaseFirestore _firestore;

  ClubCreationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _tribesCollection => _firestore.collection('tribes');
  CollectionReference get _pendingClubsCollection =>
      _firestore.collection('pendingClubApprovals');

  /// Checks if a user can create a club based on:
  /// - Level 10+ requirement
  /// - 30-day streak requirement
  Future<bool> canCreateClub(String userId) async {
    try {
      // Get user stats
      final userStatsDoc = await _firestore
          .collection('user_stats')
          .doc(userId)
          .get();

      if (!userStatsDoc.exists) {
        debugPrint('User stats not found for $userId');
        return false;
      }

      final data = userStatsDoc.data() as Map<String, dynamic>;
      final level = data['level'] as int? ?? 0;
      final currentStreak = data['currentStreak'] as int? ?? 0;

      // Requirements: Level 10+, 30-day streak
      final canCreate = level >= 10 && currentStreak >= 30;

      if (!canCreate) {
        debugPrint('User does not meet club creation requirements. '
            'Level: $level (need 10+), Streak: $currentStreak (need 30+)');
      }

      return canCreate;
    } catch (e) {
      debugPrint('Error checking club creation eligibility: $e');
      return false;
    }
  }

  /// Submits a private club for admin approval
  /// Club will be reviewed before being listed publicly
  Future<void> submitPrivateClub(Tribe clubRequest) async {
    try {
      // Create club document with pending status
      final docRef = await _tribesCollection.add(clubRequest.toMap());

      // Also add to pending approvals collection for admin review
      await _pendingClubsCollection.doc(docRef.id).set({
        'clubId': docRef.id,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'submitterId': clubRequest.ownerId,
        'clubName': clubRequest.name,
        'clubType': clubRequest.type.name,
      });

      debugPrint('Club submitted for approval: ${docRef.id}');
    } catch (e) {
      debugPrint('Error submitting club: $e');
      rethrow;
    }
  }

  /// Approves a pending club (admin only)
  /// In production, this should be secured by Firebase Security Rules
  Future<void> approveClub(String clubId) async {
    try {
      // Update club to be visible
      await _tribesCollection.doc(clubId).update({
        'isVerified': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Remove from pending approvals
      await _pendingClubsCollection.doc(clubId).update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Club approved: $clubId');
    } catch (e) {
      debugPrint('Error approving club: $e');
      rethrow;
    }
  }

  /// Rejects a pending club (admin only)
  Future<void> rejectClub(String clubId, String reason) async {
    try {
      // Mark club as inactive
      await _tribesCollection.doc(clubId).update({
        'isActive': false,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Update pending approval status
      await _pendingClubsCollection.doc(clubId).update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });

      debugPrint('Club rejected: $clubId, Reason: $reason');
    } catch (e) {
      debugPrint('Error rejecting club: $e');
      rethrow;
    }
  }

  /// Gets list of pending club approvals for admin review
  Future<List<PendingClubApproval>> getPendingApprovals() async {
    try {
      final snapshot = await _pendingClubsCollection
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PendingClubApproval(
          clubId: data['clubId'] as String,
          submittedAt: data['submittedAt'] is Timestamp
              ? (data['submittedAt'] as Timestamp).toDate()
              : DateTime.now(),
          status: data['status'] as String? ?? 'pending',
          submitterId: data['submitterId'] as String? ?? '',
          clubName: data['clubName'] as String? ?? '',
          clubType: data['clubType'] as String? ?? 'userPrivate',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting pending approvals: $e');
      return [];
    }
  }

  /// Checks if a club is at maximum capacity
  Future<bool> isClubFull(String clubId) async {
    try {
      final doc = await _tribesCollection.doc(clubId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final maxMembers = data['maxMembers'] as int?;
      final memberCount = data['memberCount'] as int? ?? 0;

      return maxMembers != null && memberCount >= maxMembers;
    } catch (e) {
      debugPrint('Error checking club capacity: $e');
      return false;
    }
  }

  /// Updates member count for a club
  Future<void> updateMemberCount(String clubId) async {
    try {
      // Count members from tribe_members subcollection
      final membersSnapshot = await _tribesCollection
          .doc(clubId)
          .collection('members')
          .get();

      final memberCount = membersSnapshot.docs.length;

      await _tribesCollection.doc(clubId).update({
        'memberCount': memberCount,
        'lastMemberCountUpdate': FieldValue.serverTimestamp(),
      });

      debugPrint('Updated member count for $clubId: $memberCount');
    } catch (e) {
      debugPrint('Error updating member count: $e');
    }
  }
}

/// Represents a pending club approval for admin review
class PendingClubApproval {
  final String clubId;
  final DateTime submittedAt;
  final String status;
  final String submitterId;
  final String clubName;
  final String clubType;

  const PendingClubApproval({
    required this.clubId,
    required this.submittedAt,
    required this.status,
    required this.submitterId,
    required this.clubName,
    required this.clubType,
  });
}
