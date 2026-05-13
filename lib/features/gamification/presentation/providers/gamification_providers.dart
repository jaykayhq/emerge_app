import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/gamification/data/repositories/firestore_user_profile_repository.dart';
import 'package:emerge_app/features/gamification/domain/repositories/user_profile_repository.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gamification_providers.g.dart';

@Riverpod(keepAlive: true)
GamificationService gamificationService(Ref ref) {
  return GamificationService();
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return FirestoreUserProfileRepository(FirebaseFirestore.instance);
});
