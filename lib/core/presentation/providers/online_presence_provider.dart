import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:emerge_app/core/services/online_presence_service.dart';

part 'online_presence_provider.g.dart';

/// Provider for the online presence service instance.
///
/// This provider keeps the service alive for the app lifetime.
/// The service will be properly disposed when the provider is disposed.
@Riverpod(keepAlive: true)
OnlinePresenceService onlinePresenceService(Ref ref) {
  final service = OnlinePresenceService(FirebaseFirestore.instance);

  // Ensure the heartbeat is stopped when the provider is disposed
  ref.onDispose(() {
    service.stopHeartbeat();
  });

  return service;
}
