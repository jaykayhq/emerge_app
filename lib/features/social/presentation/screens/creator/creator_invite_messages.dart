import 'package:cloud_functions/cloud_functions.dart';

/// Maps a failed `generateCreatorInviteCode` call to a user-facing message.
/// Returns the specific cause when known (10-code cap, verification), else a
/// generic retry prompt.
String inviteCodeErrorMessage(Object error) {
  if (error is FirebaseFunctionsException) {
    switch (error.code) {
      case 'resource-exhausted':
        return 'You have 10 outstanding invite codes — redeem one or wait for '
            'expiry before generating another.';
      case 'permission-denied':
        return 'Only verified creators can generate invite codes.';
    }
  }
  return 'Could not generate an invite code. Try again in a moment.';
}
