// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tribe_analytics_dao.dart';

// ignore_for_file: type=lint
mixin _$TribeAnalyticsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TribeAnalyticsTableTable get tribeAnalyticsTable =>
      attachedDatabase.tribeAnalyticsTable;
  TribeAnalyticsDaoManager get managers => TribeAnalyticsDaoManager(this);
}

class TribeAnalyticsDaoManager {
  final _$TribeAnalyticsDaoMixin _db;
  TribeAnalyticsDaoManager(this._db);
  $$TribeAnalyticsTableTableTableManager get tribeAnalyticsTable =>
      $$TribeAnalyticsTableTableTableManager(
        _db.attachedDatabase,
        _db.tribeAnalyticsTable,
      );
}
