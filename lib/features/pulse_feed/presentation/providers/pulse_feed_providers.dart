import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/pulse_feed/data/repositories/pulse_feed_repository.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';

part 'pulse_feed_providers.g.dart';

// ---------------------------------------------------------------------------
// Repository provider (keep-alive singleton)
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
PulseFeedRepository pulseFeedRepository(Ref ref) {
  return PulseFeedRepository(FirebaseFirestore.instance);
}

// ---------------------------------------------------------------------------
// Pulse feed stream (auto-dispose)
// ---------------------------------------------------------------------------

/// Streams the latest pulse-feed cards for the currently authenticated user.
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
