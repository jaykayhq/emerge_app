import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'creator_invite_provider.g.dart';

/// Injectable Firebase Functions handle — tests override this with a mock
/// instead of touching the live `FirebaseFunctions.instance`.
@Riverpod(keepAlive: true)
FirebaseFunctions firebaseFunctions(Ref ref) => FirebaseFunctions.instance;

/// Generates single-use creator invite codes via the
/// `generateCreatorInviteCode` callable (server-verified creator, 10-code
/// outstanding cap, 7-day expiry). State holds the last generated code
/// (null until the first successful generation) so reopening the dialog
/// doesn't burn another code.
@Riverpod(keepAlive: true)
class CreatorInviteController extends _$CreatorInviteController {
  @override
  String? build() => null;

  /// Calls the server-side generator and returns the code. Rethrows so the
  /// dialog can surface the failure — callers decide how to present it.
  Future<String?> generate() async {
    final functions = ref.read(firebaseFunctionsProvider);
    final result = await functions
        .httpsCallable('generateCreatorInviteCode')
        .call(<String, dynamic>{});
    final data = result.data;
    final code = data is Map<String, dynamic> ? data['code'] as String? : null;
    if (code == null) {
      throw Exception('Invite code generation returned no code');
    }
    state = code;
    return code;
  }
}
