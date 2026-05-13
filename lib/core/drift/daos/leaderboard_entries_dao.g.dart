// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_entries_dao.dart';

// ignore_for_file: type=lint
mixin _$LeaderboardEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LeaderboardEntriesTableTable get leaderboardEntriesTable =>
      attachedDatabase.leaderboardEntriesTable;
  LeaderboardEntriesDaoManager get managers =>
      LeaderboardEntriesDaoManager(this);
}

class LeaderboardEntriesDaoManager {
  final _$LeaderboardEntriesDaoMixin _db;
  LeaderboardEntriesDaoManager(this._db);
  $$LeaderboardEntriesTableTableTableManager get leaderboardEntriesTable =>
      $$LeaderboardEntriesTableTableTableManager(
        _db.attachedDatabase,
        _db.leaderboardEntriesTable,
      );
}
