import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_cache_service.g.dart';

/// Single global instance initialized eagerly in main() before ProviderScope.
/// This avoids viral async propagation through the entire provider graph.
/// Must call LocalCacheService.instance.init() in initApp() before runApp().
LocalCacheService? _globalCacheInstance;

/// Synchronous provider — safe because init() is called before runApp().
/// If called before init(), it throws a clear error instead of a cryptic null crash.
@Riverpod(keepAlive: true)
LocalCacheService localCacheService(Ref ref) {
  assert(
    _globalCacheInstance != null,
    'LocalCacheService.instance not initialized! '
    'Call await LocalCacheService.initialize() in initApp() before runApp().',
  );
  return _globalCacheInstance!;
}

/// Fix #7: Reactive sync queue size using Hive.watch() instead of 2-second polling.
/// Zero CPU cost when the queue is empty.
@Riverpod(keepAlive: true)
Stream<int> syncQueueSize(Ref ref) async* {
  final service = ref.watch(localCacheServiceProvider);

  // Emit the current size immediately
  yield service.getMutationQueue().length;

  // Then emit on every Hive mutation event
  final box = Hive.box(LocalCacheService.mutationBoxName);
  await for (final _ in box.watch()) {
    yield service.getMutationQueue().length;
  }
}

class LocalCacheService {
  static const mutationBoxName = 'mutation_queue';
  static const _cacheBoxName = 'global_cache';
  static const _secureStorageKey = 'hive_encryption_key_v2';

  /// Initialize and register the global instance.
  /// Call this in initApp() before runApp().
  static Future<LocalCacheService> initialize() async {
    if (_globalCacheInstance != null) return _globalCacheInstance!;
    final service = LocalCacheService._();
    await service.init();
    _globalCacheInstance = service;
    return service;
  }

  LocalCacheService._();

  Future<void> init() async {
    await Hive.initFlutter();

    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyString = await secureStorage.read(key: _secureStorageKey);

    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      encryptionKeyString = base64UrlEncode(key);
      await secureStorage.write(key: _secureStorageKey, value: encryptionKeyString);
    }

    final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);
    final cipher = HiveAesCipher(encryptionKeyUint8List);

    await Future.wait([
      _openBox(mutationBoxName, cipher),
      _openBox(_cacheBoxName, cipher),
    ]);
  }

  Future<Box> _openBox(String name, HiveAesCipher cipher) async {
    try {
      if (Hive.isBoxOpen(name)) return Hive.box(name);
      return await Hive.openBox(name, encryptionCipher: cipher);
    } catch (e) {
      debugPrint('⚠️ Failed to open box $name: $e. Deleting and recreating...');
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox(name, encryptionCipher: cipher);
    }
  }

  // Generic Cache Methods
  Future<void> put(String key, dynamic value) async {
    final box = Hive.box(_cacheBoxName);
    await box.put(key, value);
  }

  dynamic get(String key, {dynamic defaultValue}) {
    final box = Hive.box(_cacheBoxName);
    return box.get(key, defaultValue: defaultValue);
  }

  // User Profile Cache
  Future<void> saveUserProfile(Map<String, dynamic> profileMap) async {
    await put('user_profile', profileMap);
  }

  Map<String, dynamic>? getUserProfile() {
    final data = get('user_profile');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  // Insights Cache
  Future<void> saveLatestRecap(Map<String, dynamic> recapMap) async {
    await put('latest_recap', recapMap);
  }

  Map<String, dynamic>? getLatestRecap() {
    final data = get('latest_recap');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveReflections(List<Map<String, dynamic>> reflections) async {
    await put('reflections', reflections);
  }

  List<Map<String, dynamic>>? getReflections() {
    final data = get('reflections');
    if (data == null) return null;
    return (data as List).cast<Map<String, dynamic>>();
  }

  // Tribe Cache
  Future<void> saveTribes(List<Map<String, dynamic>> tribes) async {
    await put('tribes', tribes);
  }

  List<Map<String, dynamic>>? getTribes() {
    final data = get('tribes');
    if (data == null) return null;
    return (data as List).cast<Map<String, dynamic>>();
  }

  // Premium Status Cache (RevenueCat fallback)
  Future<void> savePremiumStatus(bool isPremium) async {
    await put('is_premium', isPremium);
    await put('last_premium_check', DateTime.now().toIso8601String());
  }

  Map<String, dynamic>? getPremiumStatus() {
    final isPremium = get('is_premium');
    final lastCheck = get('last_premium_check');
    if (isPremium == null || lastCheck == null) return null;
    return {
      'isPremium': isPremium as bool,
      'lastCheck': lastCheck as String,
    };
  }

  // Mutation Queue Methods
  Future<void> enqueueMutation({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
    required String operation, // 'set', 'update', 'delete', 'add'
  }) async {
    final box = Hive.box(mutationBoxName);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, {
      'collectionPath': collectionPath,
      'documentId': documentId,
      'data': data,
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Enqueues a mutation with Firestore FieldValue semantics stored as
  /// serializable marker strings that SyncEngine expands on flush.
  ///
  /// Marker format:
  /// - `__arrayUnion_<field>` → FieldValue.arrayUnion
  /// - `__arrayRemove_<field>` → FieldValue.arrayRemove
  /// - `__increment_<field>` → FieldValue.increment
  Future<void> enqueueMutationWithSentinels({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
    Map<String, List<dynamic>> arrayUnions = const {},
    Map<String, List<dynamic>> arrayRemovals = const {},
    Map<String, num> increments = const {},
  }) async {
    final serializable = Map<String, dynamic>.from(data);
    arrayUnions.forEach((field, values) {
      serializable['__arrayUnion_$field'] = values;
    });
    arrayRemovals.forEach((field, values) {
      serializable['__arrayRemove_$field'] = values;
    });
    increments.forEach((field, amount) {
      serializable['__increment_$field'] = amount;
    });

    await enqueueMutation(
      collectionPath: collectionPath,
      documentId: documentId,
      data: serializable,
      operation: 'update',
    );
  }

  Map<String, Map<String, dynamic>> getMutationQueue() {
    final box = Hive.box(mutationBoxName);
    return box.toMap().cast<String, Map<String, dynamic>>();
  }

  Future<void> removeMutation(String id) async {
    final box = Hive.box(mutationBoxName);
    await box.delete(id);
  }
}
