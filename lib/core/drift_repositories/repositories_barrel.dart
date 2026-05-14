/// Conditional import barrier for Drift*Repository classes.
///
/// On native the real implementations are used; on web the stubs in
/// [repositories_stub] are compiled instead (never instantiated because all
/// providers return Firestore-based repos when `kIsWeb` is true).
export 'repositories_stub.dart' if (dart.library.io) 'repositories_native.dart';
