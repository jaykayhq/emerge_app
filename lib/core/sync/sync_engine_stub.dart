/// Web‑safe stub for [EnhancedSyncEngine]. Never instantiated on web.

class EnhancedSyncEngine {
  EnhancedSyncEngine(Object mutationQueue, Object firestore);

  Future<void> processMutationQueue() async {}

  Future<void> enqueueSet({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {}

  Future<void> enqueueDelete({
    required String collectionPath,
    required String documentId,
  }) async {}
}
