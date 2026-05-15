// Conditional import barrier for [createDriftConnection].
export 'app_database_connection_web.dart'
    if (dart.library.io) 'app_database_connection_native.dart';
