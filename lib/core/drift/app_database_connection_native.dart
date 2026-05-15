// Native database connection factory — uses dart:io + path_provider.
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Opens a [NativeDatabase] backed by a file on disk.
QueryExecutor createDriftConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'emerge_app.sqlite'));
    return NativeDatabase(file);
  });
}
