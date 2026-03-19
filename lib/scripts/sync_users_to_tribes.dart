// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/data/services/tribe_sync_service.dart';

/// Script to sync all existing users to their archetype tribes.
///
/// Run this once to fix users who weren't added to tribes during onboarding.
///
/// Usage:
///   flutter run lib/scripts/sync_users_to_tribes.dart
///
/// Or from Firebase Admin SDK (Node.js):
///   cd functions && npm run sync-tribes
Future<void> main() async {
  print('🚀 Starting tribe sync script...');

  final firestore = FirebaseFirestore.instance;
  final syncService = TribeSyncService(firestore: firestore);

  print('📊 Syncing all users to their archetype tribes...');
  final results = await syncService.syncAllUsersToTribes();

  print('');
  print('===========================================');
  print('✅ TRIBE SYNC COMPLETE');
  print('===========================================');
  print('   Synced:  ${results['success']}');
  print('   Skipped: ${results['skipped']} (no archetype)');
  print('   Failed:  ${results['failed']}');
  print('===========================================');
  print('');

  // Recalculate member counts for all tribes
  print('🔄 Recalculating tribe member counts...');
  final tribesSnapshot = await firestore.collection('tribes').get();

  for (final tribeDoc in tribesSnapshot.docs) {
    await syncService.recalculateTribeMemberCount(tribeDoc.id);
  }

  print('✅ All tribe member counts updated!');
  print('');
  print('💡 Restart the app to see updated tribe stats.');
}
