import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:emerge_app/features/auth/presentation/screens/verify_email_screen.dart';
import '../../../../helpers/widget_test_utils.dart';
import '../../../../helpers/mocks/auth_mocks.dart';

Widget _buildTest(
  AuthRepository repo, {
  List<Override> overrides = const [],
}) {
  return createScreenUnderTest(
    screen: const VerifyEmailScreen(),
    overrides: [authRepositoryProvider.overrideWithValue(repo), ...overrides],
  );
}

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    mockAuth = MockAuthRepository();
    when(() => mockAuth.user).thenAnswer((_) => const Stream.empty());
    when(() => mockAuth.sendEmailVerificationCode())
        .thenAnswer((_) async => const Right<Failure, void>(null));
    when(() => mockAuth.verifyEmailCode(any()))
        .thenAnswer((_) async => const Right<Failure, void>(null));
  });

  testWidgets('renders code entry and verify button', (tester) async {
    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('sends the code on load and surfaces failures', (tester) async {
    when(() => mockAuth.sendEmailVerificationCode()).thenAnswer(
        (_) async => Left<Failure, void>(AuthFailure('Too many codes sent recently. Try again later.')));
    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    expect(find.textContaining('Too many codes'), findsOneWidget);
  });

  testWidgets('verifies a code and shows success', (tester) async {
    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    verify(() => mockAuth.verifyEmailCode('123456')).called(1);
    expect(find.textContaining('verified'), findsWidgets);
  });

  testWidgets('shows locked variant when past the grace period', (tester) async {
    await tester.pumpWidget(_buildTest(
      mockAuth,
      overrides: [
        currentEmailLockedAtProvider
            .overrideWith((ref) async => DateTime(2026, 1, 8)),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Account locked — verify your email'), findsOneWidget);
  });

  testWidgets('rejects a short code without calling the repository',
      (tester) async {
    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    verifyNever(() => mockAuth.verifyEmailCode(any()));
    expect(find.text('Enter the 6-digit code.'), findsOneWidget);
  });
}
