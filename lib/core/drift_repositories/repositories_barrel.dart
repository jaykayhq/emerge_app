// Conditional import barrier for Drift*Repository classes.
//
// With WASM SQLite on web, all Drift types are real, so the drift
// repositories compile and work on both platforms.
export 'repositories_web.dart' if (dart.library.io) 'repositories_native.dart';
