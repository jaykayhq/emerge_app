import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';

/// Repository for Pulse Feed cards stored in Firestore.
///
/// Cards live under `pulse_feed_cards/{userId}/cards/` and are ordered
/// by `createdAt` descending. The feed is capped at 30 cards per user.
class PulseFeedRepository {
  final FirebaseFirestore _firestore;

  PulseFeedRepository(this._firestore);

  static const _maxCards = 30;

  CollectionReference _cardsRef(String userId) =>
      _firestore
          .collection('pulse_feed_cards')
          .doc(userId)
          .collection('cards');

  /// Fetches the latest pulse-feed cards for [userId] (one-shot).
  Future<List<PulseFeedCard>> getPulseFeed(String userId) async {
    try {
      final snapshot = await _cardsRef(userId)
          .orderBy('createdAt', descending: true)
          .limit(_maxCards)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return PulseFeedCard.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('PulseFeedRepository.getPulseFeed error: $e');
      return [];
    }
  }

  /// Streams the latest pulse-feed cards for [userId] (reactive).
  Stream<List<PulseFeedCard>> watchPulseFeed(String userId) {
    try {
      return _cardsRef(userId)
          .orderBy('createdAt', descending: true)
          .limit(_maxCards)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return PulseFeedCard.fromJson(data);
        }).toList();
      });
    } catch (e) {
      debugPrint('PulseFeedRepository.watchPulseFeed error: $e');
      return Stream.value([]);
    }
  }
}
