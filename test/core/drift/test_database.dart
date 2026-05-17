import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';

AppDatabase createTestDatabase() {
  return AppDatabase.withExecutor(NativeDatabase.memory());
}
