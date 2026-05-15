// Web database connection factory — uses drift/wasm with browser storage.
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a [WasmDatabase] backed by browser storage (OPFS or IndexedDB).
QueryExecutor createDriftConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'emerge_app',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return result.resolvedExecutor;
  });
}
