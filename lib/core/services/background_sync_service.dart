import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:emerge_app/core/services/local_cache_service.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';

const String syncTaskName = "com.jaykayhq.emerge.syncTask";

/// Fix #6: Background isolates do NOT inherit the main isolate's state.
/// Hive.initFlutter() MUST be called before LocalCacheService.init()
/// in the background context.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // 1. Initialize Firebase for the background isolate
      await Firebase.initializeApp();

      // 2. Initialize Hive for the background isolate — required before
      //    LocalCacheService.init() can open any boxes
      await Hive.initFlutter();

      // 3. Initialize and open local cache boxes via static factory
      //    (re-entrant: returns existing instance if already initialized)
      final localCache = await LocalCacheService.initialize();

      // 4. Run sync engine
      final syncEngine = SyncEngine(
        FirebaseFirestore.instance,
        localCache,
      );

      await syncEngine.processMutationQueue();

      debugPrint("Background sync task completed: $task");
      return Future.value(true);
    } catch (e) {
      debugPrint("Background sync task failed: $e");
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static Future<void> initialize() async {
    if (kIsWeb) return;

    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> schedulePeriodicSync() async {
    if (kIsWeb) return;

    await Workmanager().registerPeriodicTask(
      "periodic-sync-task",
      syncTaskName,
      frequency: const Duration(hours: 1), // Minimum 15 minutes on Android
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }
}
