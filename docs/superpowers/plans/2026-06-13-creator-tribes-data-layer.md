# Creator Tribes Data Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the foundation by creating the new Firestore collections, updating the `Blueprint` model with creator fields, and adding necessary repositories and providers.

**Architecture:** We are introducing new domain entities (`CreatorProfile`, `TribeMembership`, `CollectiveQuest`) and extending the existing `Blueprint` and `Tribe` models to support creator-led communities. The data access layer will use Riverpod providers and new repository classes.

**Tech Stack:** Flutter, Riverpod, Cloud Firestore, freezed/json_serializable

---

### Task 1: Update Blueprint Model

**Files:**
- Modify: `lib/features/blueprints/domain/models/blueprint.dart`

- [ ] **Step 1: Add creator fields to Blueprint model**

```dart
// Modify lib/features/blueprints/domain/models/blueprint.dart
// Inside the Blueprint class, add the following fields:
  final String? creatorBio;
  final List<String> specialityTags;
  final String? creatorHeroImageUrl;
  final int tribeMemberCount;
  final bool isCreatorBlueprint;
  final String? creatorTribeId;

// Ensure copyWith, toMap, and fromMap are updated to handle these fields.
// For fromMap defaults:
// specialityTags: List<String>.from(map['specialityTags'] ?? [])
// tribeMemberCount: map['tribeMemberCount']?.toInt() ?? 0
// isCreatorBlueprint: map['isCreatorBlueprint'] ?? false
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/blueprints/domain/models/blueprint.dart
git commit -m "feat: add creator fields to Blueprint model"
```

### Task 2: Create New Domain Entities

**Files:**
- Create: `lib/features/social/domain/entities/creator_profile.dart`
- Create: `lib/features/social/domain/entities/tribe_membership.dart`

- [ ] **Step 1: Create CreatorProfile entity**

```dart
// lib/features/social/domain/entities/creator_profile.dart
class CreatorProfile {
  final String userId;
  final String bio;
  final List<String> specialityTags;
  final bool isVerifiedCreator;
  final String? blueprintId;
  final String? tribeId;

  const CreatorProfile({
    required this.userId,
    this.bio = '',
    this.specialityTags = const [],
    this.isVerifiedCreator = false,
    this.blueprintId,
    this.tribeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bio': bio,
      'specialityTags': specialityTags,
      'isVerifiedCreator': isVerifiedCreator,
      'blueprintId': blueprintId,
      'tribeId': tribeId,
    };
  }

  factory CreatorProfile.fromMap(Map<String, dynamic> map) {
    return CreatorProfile(
      userId: map['userId'] ?? '',
      bio: map['bio'] ?? '',
      specialityTags: List<String>.from(map['specialityTags'] ?? []),
      isVerifiedCreator: map['isVerifiedCreator'] ?? false,
      blueprintId: map['blueprintId'],
      tribeId: map['tribeId'],
    );
  }
}
```

- [ ] **Step 2: Create TribeMembership entity**

```dart
// lib/features/social/domain/entities/tribe_membership.dart
enum MembershipType { archetype, creator }

class TribeMembership {
  final String userId;
  final String tribeId;
  final MembershipType type;
  final DateTime joinedAt;
  final int streak;

  const TribeMembership({
    required this.userId,
    required this.tribeId,
    required this.type,
    required this.joinedAt,
    this.streak = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tribeId': tribeId,
      'type': type.name,
      'joinedAt': joinedAt.toIso8601String(),
      'streak': streak,
    };
  }

  factory TribeMembership.fromMap(Map<String, dynamic> map) {
    return TribeMembership(
      userId: map['userId'] ?? '',
      tribeId: map['tribeId'] ?? '',
      type: MembershipType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MembershipType.archetype,
      ),
      joinedAt: map['joinedAt'] != null 
          ? DateTime.tryParse(map['joinedAt']) ?? DateTime.now()
          : DateTime.now(),
      streak: map['streak']?.toInt() ?? 0,
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/domain/entities/creator_profile.dart lib/features/social/domain/entities/tribe_membership.dart
git commit -m "feat: add CreatorProfile and TribeMembership domain entities"
```

### Task 3: Create Repositories & Providers

**Files:**
- Create: `lib/features/social/data/repositories/creator_repository.dart`
- Create: `lib/features/social/presentation/providers/creator_provider.dart`

- [ ] **Step 1: Create CreatorRepository**

```dart
// lib/features/social/data/repositories/creator_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';

class CreatorRepository {
  final FirebaseFirestore _firestore;

  CreatorRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<CreatorProfile?> watchCreatorProfile(String userId) {
    return _firestore
        .collection('creator_profiles')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? CreatorProfile.fromMap(doc.data()!) : null);
  }

  Future<void> updateCreatorProfile(CreatorProfile profile) async {
    await _firestore
        .collection('creator_profiles')
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }
}
```

- [ ] **Step 2: Create CreatorProvider**

```dart
// lib/features/social/presentation/providers/creator_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/data/repositories/creator_repository.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';

final creatorRepositoryProvider = Provider<CreatorRepository>((ref) {
  return CreatorRepository();
});

final creatorProfileProvider = StreamProvider.family<CreatorProfile?, String>((ref, userId) {
  final repository = ref.watch(creatorRepositoryProvider);
  return repository.watchCreatorProfile(userId);
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/data/repositories/creator_repository.dart lib/features/social/presentation/providers/creator_provider.dart
git commit -m "feat: add CreatorRepository and CreatorProvider"
```
