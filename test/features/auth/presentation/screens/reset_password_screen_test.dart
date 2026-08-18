import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/reset_password_screen.dart';
import '../../../../helpers/mocks/auth_mocks.dart';

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    mockAuth = MockAuthRepository();
    when(() => mockAuth.user).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAuth.resetPasswordWithCode(
        oobCode: any(named: 'oobCode'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async => const Right<Failure, void>(null));
  });

  Widget buildWithRouter({String path = '/reset-password?oobCode=abc123'}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('LOGIN'))),
        ),
      ],
      initialLocation: path,
    );
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuth)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('renders the branded reset form with password fields', (
    tester,
  ) async {
    await tester.pumpWidget(buildWithRouter());
    await tester.pumpAndSettle();

    expect(find.text('Choose a new password'), findsOneWidget);
    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Confirm New Password'), findsOneWidget);
    expect(find.text('Update password'), findsOneWidget);
  });

  testWidgets('shows an error when the reset link has no oobCode', (
    tester,
  ) async {
    await tester.pumpWidget(buildWithRouter(path: '/reset-password'));
    await tester.pumpAndSettle();

    expect(find.textContaining('missing its code'), findsOneWidget);
    verifyNever(
      () => mockAuth.resetPasswordWithCode(
        oobCode: any(named: 'oobCode'),
        newPassword: any(named: 'newPassword'),
      ),
    );
  });

  testWidgets('validates passwords before submitting', (tester) async {
    await tester.pumpWidget(buildWithRouter());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'New Password'),
      'short',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm New Password'),
      'short',
    );
    await tester.ensureVisible(find.text('Update password'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    verifyNever(
      () => mockAuth.resetPasswordWithCode(
        oobCode: any(named: 'oobCode'),
        newPassword: any(named: 'newPassword'),
      ),
    );
    expect(find.textContaining('at least'), findsOneWidget);
  });

  testWidgets('applies the oobCode and navigates to login on success', (
    tester,
  ) async {
    await tester.pumpWidget(buildWithRouter());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'New Password'),
      'Str0ngP@sswd!',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm New Password'),
      'Str0ngP@sswd!',
    );
    await tester.ensureVisible(find.text('Update password'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    verify(
      () => mockAuth.resetPasswordWithCode(
        oobCode: 'abc123',
        newPassword: 'Str0ngP@sswd!',
      ),
    ).called(1);
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('surfaces the failure message from the repository', (
    tester,
  ) async {
    when(
      () => mockAuth.resetPasswordWithCode(
        oobCode: any(named: 'oobCode'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer(
      (_) async =>
          Left<Failure, void>(AuthFailure('Invalid or expired reset link.')),
    );

    await tester.pumpWidget(buildWithRouter());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'New Password'),
      'Str0ngP@sswd!',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm New Password'),
      'Str0ngP@sswd!',
    );
    await tester.ensureVisible(find.text('Update password'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid or expired reset link.'), findsOneWidget);
  });
}
