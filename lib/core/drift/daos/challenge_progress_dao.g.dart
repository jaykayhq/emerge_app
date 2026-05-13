// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_progress_dao.dart';

// ignore_for_file: type=lint
mixin _$ChallengeProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChallengeProgressTableTable get challengeProgressTable =>
      attachedDatabase.challengeProgressTable;
  ChallengeProgressDaoManager get managers => ChallengeProgressDaoManager(this);
}

class ChallengeProgressDaoManager {
  final _$ChallengeProgressDaoMixin _db;
  ChallengeProgressDaoManager(this._db);
  $$ChallengeProgressTableTableTableManager get challengeProgressTable =>
      $$ChallengeProgressTableTableTableManager(
        _db.attachedDatabase,
        _db.challengeProgressTable,
      );
}
