import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_stats.dart';
import 'package:emerge_app/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_maps_catalog.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';

// ENHANCED: Top-level function for isolate parsing (must be top-level)
// ENHANCED: Top-level function for isolate parsing (must be top-level)
UserStats _parseUserStats(Map<String, dynamic> params) {
  final userId = params['userId'] as String;
  final data = params['data'] as Map<String, dynamic>?;

  if (data == null) {
    return UserStats(userId: userId);
  }

  // Handle both flat structure (legacy) and avatarStats structure (new)
  final avatarStats = data['avatarStats'] as Map<String, dynamic>?;

  int xp = 0;
  int level = 1;
  int streak = 0;

  if (avatarStats != null) {
    // New structure
    // Summing all XP types for 'currentXp'
    final strength = avatarStats['strengthXp'] as int? ?? 0;
    final intellect = avatarStats['intellectXp'] as int? ?? 0;
    final vitality = avatarStats['vitalityXp'] as int? ?? 0;
    final creativity = avatarStats['creativityXp'] as int? ?? 0;
    final focus = avatarStats['focusXp'] as int? ?? 0;
    final spirit = avatarStats['spiritXp'] as int? ?? 0;

    xp = strength + intellect + vitality + creativity + focus + spirit;
    level = avatarStats['level'] as int? ?? 1;
    streak = avatarStats['streak'] as int? ?? 0;
  } else {
    // Legacy structure
    xp = data['currentXp'] as int? ?? 0;
    level = data['currentLevel'] as int? ?? 1;
    streak = data['currentStreak'] as int? ?? 0;
  }

  // All parsing happens in isolate, not blocking main thread
  return UserStats(
    userId: userId,
    currentXp: xp,
    currentLevel: level,
    currentStreak: streak,
    unlockedBadges:
        (data['unlockedBadges'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    identityVotes:
        (data['identityVotes'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as int),
        ) ??
        const {},
  );
}

class FirestoreGamificationRepository implements GamificationRepository {
  final FirebaseFirestore _firestore;

  FirestoreGamificationRepository(this._firestore);

  @override
  Stream<UserStats> watchUserStats(String userId) {
    return _firestore.collection('user_stats').doc(userId).snapshots().asyncMap(
      (snapshot) async {
        // ENHANCED: Move heavy parsing to isolate to prevent UI jank
        if (!snapshot.exists || snapshot.data() == null) {
          return UserStats(userId: userId);
        }

        // Parse in isolate using compute()
        return compute(_parseUserStats, {
          'userId': userId,
          'data': snapshot.data(),
        });
      },
    ).distinct();
  }

  @override
  Future<Either<Failure, Unit>> updateUserStats(UserStats stats) async {
    try {
      // Write to 'avatarStats' map to align with UserProfile
      // We map currentXp to 'vitalityXp' as a default for now to keep it simple,
      // or we probably shouldn't be overwriting 'avatarStats' completely if we can avoid it.
      // But update is usually clean.

      await _firestore.collection('user_stats').doc(stats.userId).set({
        'avatarStats': {
          'vitalityXp':
              stats.currentXp, // Mapping generic XP to Vitality for now
          'level': stats.currentLevel,
          'streak': stats.currentStreak,
          // Other stats default to 0 if not tracked in UserStats entity yet
        },
        'unlockedBadges': stats.unlockedBadges,
        'identityVotes': stats.identityVotes,
        // Legacy fields for insurance
        'currentXp': stats.currentXp,
        'currentLevel': stats.currentLevel,
        'currentStreak': stats.currentStreak,
      }, SetOptions(merge: true));
      return const Right(unit);
    } catch (e, s) {
      AppLogger.e('Update user stats failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addXp(
    String userId,
    int amount, {
    String? attributeName,
  }) async {
    try {
      final docRef = _firestore.collection('user_stats').doc(userId);

      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        Map<String, dynamic> avatarStats = {};

        // Initialize with existing data or defaults
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (data['avatarStats'] != null) {
            avatarStats = Map<String, dynamic>.from(data['avatarStats'] as Map);
          } else {
            // Migration from legacy: put existing currentXp into vitality
            final legacyXp = data['currentXp'] as int? ?? 0;
            avatarStats['vitalityXp'] = legacyXp;
          }
        }

        // Determine which attribute to update
        // Default to 'vitalityXp' if not specified or unknown
        String targetField = 'vitalityXp';
        if (attributeName != null) {
          // Map 'strength' -> 'strengthXp', etc.
          // Safe mapping in case of weird strings
          final key = '${attributeName.toLowerCase()}Xp';
          // Check if it's one of the known keys (optional, but good for safety)
          // For now just assume valid or it creates a new field which is fine
          targetField = key;
        }

        final currentVal = (avatarStats[targetField] as int?) ?? 0;
        final newVal = currentVal + amount;
        avatarStats[targetField] = newVal;

        // Recalculate Total XP and Level
        // UserAvatarStats logic: sum of all XPs
        int totalXp = 0;
        final keys = [
          'strengthXp',
          'intellectXp',
          'vitalityXp',
          'creativityXp',
          'focusXp',
          'spiritXp',
        ];
        for (final k in keys) {
          totalXp += (avatarStats[k] as int?) ?? 0;
        }

        // Internal Level Calculation (Standardized: 500 XP per level)
        // REMOVED: Level is now strictly controlled by Node Claims (1 Node = 1 Level).
        // preserve the existing level
        final currentLevel = (avatarStats['level'] as int?) ?? 1;

        transaction.set(docRef, {
          'avatarStats': avatarStats,
          // Update legacy fields for compatibility if needed
          'currentXp': totalXp,
          'currentLevel': currentLevel,
        }, SetOptions(merge: true));

        return const Right(unit);
      });
    } catch (e, s) {
      AppLogger.e('Add XP failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Award XP to a specific node and its attributes
  /// This method:
  /// 1. Adds XP to each target attribute in avatarStats
  /// 2. Tracks node XP progress separately in worldState
  /// 3. Updates total XP
  Future<Either<Failure, Unit>> awardNodeXp(
    String userId,
    String nodeId,
    int amount, {
    List<String>? attributes,
  }) async {
    try {
      final docRef = _firestore.collection('user_stats').doc(userId);

      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          return Left(ServerFailure('User stats document does not exist'));
        }

        final data = snapshot.data()!;
        final avatarStats = Map<String, dynamic>.from(
          data['avatarStats'] as Map? ?? {}
        );

        // Get the node to find its attributes
        final node = _getNodeById(nodeId);
        if (node == null) {
          return Left(ServerFailure('Node not found: $nodeId'));
        }

        // Use provided attributes or node's primaryAttributes
        final targetAttributes = attributes ?? node.primaryAttributes;

        // Initialize attributeXp map if not exists
        if (!avatarStats.containsKey('attributeXp')) {
          avatarStats['attributeXp'] = <String, int>{};
        }
        final attributeXp = Map<String, dynamic>.from(
          avatarStats['attributeXp'] as Map? ?? {}
        );

        // Add XP to each target attribute
        for (final attr in targetAttributes) {
          final key = attr.toLowerCase();
          final currentAttrXp = (attributeXp[key] as int?) ?? 0;
          attributeXp[key] = currentAttrXp + amount;

          // Also update the specific attribute field for backwards compatibility
          final attrField = '${key}Xp';
          avatarStats[attrField] = (avatarStats[attrField] as int? ?? 0) + amount;
        }
        avatarStats['attributeXp'] = attributeXp;

        // Calculate new total XP
        int totalXp = 0;
        final keys = [
          'strengthXp',
          'intellectXp',
          'vitalityXp',
          'creativityXp',
          'focusXp',
          'spiritXp',
        ];
        for (final k in keys) {
          totalXp += (avatarStats[k] as int?) ?? 0;
        }
        avatarStats['totalXp'] = totalXp;

        // Track node progress in worldState
        final worldState = Map<String, dynamic>.from(
          data['worldState'] as Map? ?? {}
        );
        final nodeProgress = Map<String, dynamic>.from(
          worldState['nodeProgress'] as Map? ?? {}
        );
        final currentNodeXp = (nodeProgress[nodeId]?['xp'] as int? ?? 0) + amount;
        final isCompleted = currentNodeXp >= (nodeProgress[nodeId]?['required'] as int? ?? 100);
        nodeProgress[nodeId] = {
          'xp': currentNodeXp,
          'completed': isCompleted,
          'required': nodeProgress[nodeId]?['required'] as int? ?? 100,
        };
        worldState['nodeProgress'] = nodeProgress;

        // If node is newly completed, add to claimedNodes
        if (isCompleted) {
          final claimedNodes = List<String>.from(worldState['claimedNodes'] as List? ?? []);
          if (!claimedNodes.contains(nodeId)) {
            claimedNodes.add(nodeId);
            worldState['claimedNodes'] = claimedNodes;
          }
        }

        // Update document
        transaction.set(docRef, {
          'avatarStats': avatarStats,
          'worldState': worldState,
          // Legacy fields
          'currentXp': totalXp,
          'currentLevel': avatarStats['level'] as int? ?? 1,
        }, SetOptions(merge: true));

        return const Right(unit);
      });
    } catch (e, s) {
      AppLogger.e('Award node XP failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Find a node by ID across all archetype catalogs
  WorldNode? _getNodeById(String nodeId) {
    // Check if node ID follows the pattern {archetype}_{stage}_{level}
    final parts = nodeId.split('_');
    if (parts.length >= 2) {
      final archetypeKey = parts[0];
      final journey = ArchetypeMapsCatalog.getArchetypeJourney(archetypeKey);
      try {
        return journey.firstWhere((n) => n.id == nodeId);
      } catch (_) {
        // Not found in archetype journey, continue to search
      }
    }

    // Search through all archetype nodes
    for (final archetype in ArchetypeMapsCatalog.allArchetypes.keys) {
      final journey = ArchetypeMapsCatalog.getArchetypeJourney(archetype);
      for (final node in journey) {
        if (node.id == nodeId) {
          return node;
        }
      }
    }

    return null;
  }
}
