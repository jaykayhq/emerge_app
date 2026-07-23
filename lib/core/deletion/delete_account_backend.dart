import 'package:emerge_app/core/error/failure.dart';
import 'package:fpdart/fpdart.dart';

export 'package:emerge_app/core/deletion/secure_id_store.dart'
    show SharedPreferencesIdStore;
export 'package:emerge_app/features/auth/domain/backends/cloud_function_delete_backend.dart'
    show CloudFunctionDeleteBackend;

/// Contract for the (external) server-side purge. See spec Appendix A.
abstract class DeleteAccountBackend {
  Future<Either<Failure, Unit>> delete({required String deletionRequestId});
}

/// Durable store for the idempotency key.
abstract class SecureIdStore {
  Future<String> loadOrCreateId(String key);
  Future<void> clear(String key);
}
