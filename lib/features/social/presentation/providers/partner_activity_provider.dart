import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/domain/repositories/partner_activity_repository.dart';

final partnerActivityRepositoryProvider =
    Provider<PartnerActivityRepository>((ref) {
  return FirestorePartnerActivityRepository(FirebaseFirestore.instance);
});

/// Stream of partner-activity events for the current user.
/// Reads `users/{me}/partner_activity` ordered by `timestamp` desc.
/// Returns an empty list stream when there is no authenticated user.
final partnerActivityProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(<Map<String, dynamic>>[]);

  final repository = ref.watch(partnerActivityRepositoryProvider);
  return repository.watchPartnerActivity(user.id);
});
