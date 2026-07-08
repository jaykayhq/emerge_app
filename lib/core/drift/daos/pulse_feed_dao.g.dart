// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pulse_feed_dao.dart';

// ignore_for_file: type=lint
mixin _$PulseFeedDaoMixin on DatabaseAccessor<AppDatabase> {
  $PulseFeedCardsTableTable get pulseFeedCardsTable =>
      attachedDatabase.pulseFeedCardsTable;
  PulseFeedDaoManager get managers => PulseFeedDaoManager(this);
}

class PulseFeedDaoManager {
  final _$PulseFeedDaoMixin _db;
  PulseFeedDaoManager(this._db);
  $$PulseFeedCardsTableTableTableManager get pulseFeedCardsTable =>
      $$PulseFeedCardsTableTableTableManager(
        _db.attachedDatabase,
        _db.pulseFeedCardsTable,
      );
}
