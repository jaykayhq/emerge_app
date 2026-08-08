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
    when(() => mockAuth.sendVerificationEmail())
        .thenAnswer((_) async => const Right<Failure, void>(null));
    when(() => mockAuth.checkEmailVerified())
        .thenAnswer((_) async => const Right<Failure, bool>(true));
  });

  testWidgets('renders check-your-email title and actions', (tester) async {
    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();
    // Let the resend cooldown elapse so the label is the plain "Resend link".
    await tester.pump(const Duration(seconds: 61));

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text("I've verified — continue"), findsOneWidget);
    expect(find.text('Resend link'), findsOneWidget);
  });

  testWidgets('sends the verification email on load and surfaces failures',
      (tester) async {
    when(() => mockAuth.sendVerificationEmail()).thenAnswer(
        (_) async => Left<Failure, void>(
            AuthFailure('Too many emails sent recently. Try again later.')));
    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    expect(find.textContaining('Too many emails'), findsOneWidget);
  });

  testWidgets('continue when already verified shows confirmation',
      (tester) async {
    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I've verified — continue"));
    await tester.pumpAndSettle();

    verify(() => mockAuth.checkEmailVerified()).called(1);
    expect(find.textContaining('taking you to the app'), findsOneWidget);
  });

  testWidgets('continue when not yet verified shows retry guidance',
      (tester) async {
    when(() => mockAuth.checkEmailVerified())
        .thenAnswer((_) async => const Right<Failure, bool>(false));
    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I've verified — continue"));
    await tester.pumpAndSettle();

    expect(find.textContaining('Not verified yet'), findsOneWidget);
  });

  testWidgets('shows locked variant when past the grace period',
      (tester) async {
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
}
