import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/core/deletion/delete_account_backend.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

/// Calls the server-side `deleteMyAccount` callable (Admin SDK purge),
/// passing the idempotent deletionRequestId so retries are deduped.
class CloudFunctionDeleteBackend implements DeleteAccountBackend {
  final FirebaseFunctions _functions;
  CloudFunctionDeleteBackend(this._functions);

  @override
  Future<Either<Failure, Unit>> delete(
      {required String deletionRequestId}) async {
    try {
      final result = await _functions
          .httpsCallable('deleteMyAccount')
          .call({'deletionRequestId': deletionRequestId});
      if (result.data != null && (result.data as Map)['success'] == true) {
        return const Right(unit);
      }
      return const Left(ServerFailure('Account deletion failed'));
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        return const Left(AuthFailure('Please log in again.'));
      }
      return Left(ServerFailure(e.message ?? 'Delete failed'));
    } on PlatformException catch (e) {
      return Left(ServerFailure(e.message ?? 'Delete failed'));
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
