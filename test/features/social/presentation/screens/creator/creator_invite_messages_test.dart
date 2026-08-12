import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_invite_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps resource-exhausted to the outstanding-code limit message', () {
    final error = FirebaseFunctionsException(
      code: 'resource-exhausted',
      message: 'limit reached',
    );
    final message = inviteCodeErrorMessage(error);
    expect(message, contains('10 outstanding'));
    expect(message, contains('expiry'));
  });

  test('maps permission-denied to the admin-only message', () {
    final error = FirebaseFunctionsException(
      code: 'permission-denied',
      message: 'denied',
    );
    final message = inviteCodeErrorMessage(error);
    expect(message, contains('admin creator'));
  });

  test('falls back to a generic message for unknown errors', () {
    expect(inviteCodeErrorMessage(Exception('boom')), contains('Could not'));
    expect(inviteCodeErrorMessage('plain string'), contains('Could not'));
  });
}
