import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';

/// Drift-first repository for the Pulse Feed.
///
/// Emits locally-cached cards immediately, then fetches fresh cards
/// from Firestore in the background and merges them into the local cache.
/// The Firestore query error handling follows the same pattern as
/// [DriftTribeRepository]: failures are logged and the UI keeps showing
/// whatever local data is available.
class DriftPulseFeedRepository {
  final PulseFeedDao _dao;
  final FirebaseFirestore _firestore;

  DriftPulseFeedRepository({
    required PulseFeedDao dao,
    required FirebaseFirestore firestore,
  })  : _dao = dao,
        _firestore = firestore;

  CollectionReference _cardsRef(String userId) => _firestore
      .collection('pulse_feed_cards')
      .doc(userId)
      .collection('cards');

  /// Streams pulse feed cards — local first, Firestore in background.
  Stream<List<PulseFeedCard>> watchPulseFeed(String userId) {
    final controller = StreamController<List<PulseFeedCard>>();

    StreamSubscription<List<PulseFeedCardsTableData>>? localSub;
    StreamSubscription<QuerySnapshot>? remoteSub;

    Future<void> emitMerged() async {
      final localRows = await _dao.getAll(userId);
      final cards = localRows.map(_rowToCard).toList();
      if (!controller.isClosed) controller.add(cards);
    }

    // Bootstrap: emit local cache immediately, then start Firestore sync
    emitMerged().then((_) {
      // Listen to local changes
      localSub = _dao.watchAll(userId).listen(
        (_) => emitMerged(),
        onError: controller.addError,
      );

      // Remote: fetch from Firestore and cache locally
      remoteSub = _cardsRef(userId)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots()
          .listen(
            (snapshot) async {
              final cards = snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return _firestoreDocToCompanion(data, userId);
              }).toList();

              if (cards.isNotEmpty) {
                await _dao.upsertCards(cards);
              }
              // emitMerged() will be called by the localSub listener
              // after the upsert triggers the watchAll stream.
            },
            onError: (Object err) {
              AppLogger.e(
                  'DriftPulseFeedRepository: Firestore sync failed', err);
              // UI stays on local data
            },
          );
    });

    controller.onCancel = () {
      localSub?.cancel();
      remoteSub?.cancel();
    };

    return controller.stream;
  }

  PulseFeedCard _rowToCard(PulseFeedCardsTableData row) {
    return PulseFeedCard(
      id: row.id,
      type: PulseFeedCardType.values.firstWhere(
        (e) => e.name == row.cardType,
        orElse: () => PulseFeedCardType.tribeActivity,
      ),
      headline: row.title,
      subtext: row.subtitle,
      createdAt: DateTime.tryParse(row.createdAt) ?? DateTime.now(),
      habitId: null, // Not stored in basic table; extend if needed.
      tribeUserId: null,
    );
  }

  PulseFeedCardsTableCompanion _firestoreDocToCompanion(
      Map<String, dynamic> data, String userId) {
    final createdAtRaw = data['createdAt'];
    final createdAtStr = createdAtRaw is String
        ? createdAtRaw
        : createdAtRaw is num
            ? DateTime.fromMillisecondsSinceEpoch(createdAtRaw.toInt())
                .toIso8601String()
            : createdAtRaw is Timestamp
                ? createdAtRaw.toDate().toIso8601String()
                : DateTime.now().toIso8601String();

    return PulseFeedCardsTableCompanion(
      id: Value(data['id'] as String? ?? ''),
      userId: Value(userId),
      cardType: Value(data['type'] as String? ?? 'tribeActivity'),
      title: Value(data['headline'] as String? ?? ''),
      subtitle: Value(data['subtext'] as String? ?? ''),
      body: Value(''),
      metadataJson: Value(''),
      priority: Value(0),
      createdAt: Value(createdAtStr),
      syncedAt: Value(DateTime.now().toIso8601String()),
    );
  }
}
