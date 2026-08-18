import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manage_premium_service.g.dart';

/// Thin seam so the service is testable without a Firebase emulator.
abstract interface class ManagePremiumCaller {
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data);
}

/// Default adapter over the Firebase Functions SDK.
class FirebaseFunctionsCaller implements ManagePremiumCaller {
  final FirebaseFunctions _functions;
  FirebaseFunctionsCaller(this._functions);

  @override
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final result = await _functions.httpsCallable(name).call(data);
    return result.data as Map<String, dynamic>;
  }
}

/// Calls the `managePremium` Cloud Function (pause/cancel).
///
/// Web is the primary consumer (grant revocation for a one-time Paystack
/// charge); the Android path uses the store manage page instead and never
/// calls this.
class ManagePremiumService {
  final ManagePremiumCaller _caller;

  ManagePremiumService(this._caller);

  Future<Either<String, void>> cancel() => _run('cancel');

  Future<Either<String, void>> pause() => _run('pause');

  Future<Either<String, void>> _run(String action) async {
    try {
      await _caller.call('managePremium', {'action': action});
      return const Right(null);
    } catch (e, s) {
      AppLogger.e('managePremium ($action) failed', e, s);
      return Left(e.toString());
    }
  }
}

@riverpod
ManagePremiumService managePremiumService(Ref ref) {
  return ManagePremiumService(
    FirebaseFunctionsCaller(FirebaseFunctions.instance),
  );
}
