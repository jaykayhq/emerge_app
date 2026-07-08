import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/pulse_feed_cards_table.dart';

part 'pulse_feed_dao.g.dart';

/// DAO for pulse feed card persistence.
///
/// Each card is identified by its Firestore document ID so we can
/// upsert without creating duplicates during sync.
@DriftAccessor(tables: [PulseFeedCardsTable])
class PulseFeedDao extends DatabaseAccessor<AppDatabase>
    with _$PulseFeedDaoMixin {
  PulseFeedDao(super.db);

  /// Streams all cards ordered by creation time descending.
  Stream<List<PulseFeedCardsTableData>> watchAll(String userId) {
    return (select(pulseFeedCardsTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Gets all cards (one-shot).
  Future<List<PulseFeedCardsTableData>> getAll(String userId) {
    return (select(pulseFeedCardsTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Upserts a single card.
  Future<void> upsertCard(PulseFeedCardsTableCompanion card) =>
      into(pulseFeedCardsTable).insertOnConflictUpdate(card);

  /// Upserts multiple cards in a batch.
  Future<void> upsertCards(List<PulseFeedCardsTableCompanion> cards) async {
    await batch((b) {
      for (final card in cards) {
        b.insert(pulseFeedCardsTable, card,
            mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Deletes all cards for a user (used before re-seeding).
  Future<void> clearAll() => delete(pulseFeedCardsTable).go();

  /// Gets the count of cached cards.
  Future<int> count() => select(pulseFeedCardsTable).watch().length;
}
