import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/pulse_feed/data/repositories/drift_pulse_feed_repository.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';

part 'pulse_feed_providers.g.dart';

// ---------------------------------------------------------------------------
// Repository provider (keep-alive singleton)
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
DriftPulseFeedRepository pulseFeedRepository(Ref ref) {
  final dao = ref.watch(pulseFeedDaoProvider);
  return DriftPulseFeedRepository(
    dao: dao,
    firestore: FirebaseFirestore.instance,
  );
}

// ---------------------------------------------------------------------------
// Pulse feed stream (auto-dispose)
// ---------------------------------------------------------------------------

/// Streams pulse-feed cards — local first, Firestore in background.
///
/// Automatically disposes when no longer watched. Returns an empty stream
/// when the user is not signed in.
@riverpod
Stream<List<PulseFeedCard>> pulseFeed(Ref ref) {
  final user = ref.watch(authStateChangesProvider).value;
  final userId = user?.id;
  if (userId == null || userId.isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(pulseFeedRepositoryProvider);
  return repository.watchPulseFeed(userId);
}
