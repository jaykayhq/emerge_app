// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mutation_queue_dao.dart';

// ignore_for_file: type=lint
mixin _$MutationQueueDaoMixin on DatabaseAccessor<AppDatabase> {
  $MutationQueueTableTable get mutationQueueTable =>
      attachedDatabase.mutationQueueTable;
  MutationQueueDaoManager get managers => MutationQueueDaoManager(this);
}

class MutationQueueDaoManager {
  final _$MutationQueueDaoMixin _db;
  MutationQueueDaoManager(this._db);
  $$MutationQueueTableTableTableManager get mutationQueueTable =>
      $$MutationQueueTableTableTableManager(
        _db.attachedDatabase,
        _db.mutationQueueTable,
      );
}
