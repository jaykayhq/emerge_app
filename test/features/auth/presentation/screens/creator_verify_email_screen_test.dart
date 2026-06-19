import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/creator_verify_email_screen.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}
class MockUser extends Mock implements firebase_auth.User {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late MockAuthRepository mockAuthRepository;
  late GoRouter router;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockAuthRepository = MockAuthRepository();

    when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.email).thenReturn('creator@emerge.app');

    router = GoRouter(
      initialLocation: '/creator/verify-email',
      routes: [
        GoRoute(
          path: '/creator/verify-email',
          builder: (context, state) => const CreatorVerifyEmailScreen(enableTimer: false),
        ),
        GoRoute(
          path: '/creator/dashboard',
          builder: (context, state) => const Scaffold(
            body: Text('dashboard-page'),
          ),
        ),
        GoRoute(
          path: '/creator/login',
          builder: (context, state) => const Scaffold(
            body: Text('login-page'),
          ),
        ),
      ],
    );
  });

  Future<void> setMobileViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('renders all visual elements and instruction text correctly', (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
    expect(find.text('Verify your Email'), findsOneWidget);
    expect(find.textContaining('creator@emerge.app'), findsOneWidget);
    expect(find.text('I have verified my email'), findsOneWidget);
    expect(find.text('Resend Email'), findsOneWidget);
    expect(find.text('Back to Login'), findsOneWidget);
  });

  testWidgets('clicking "I have verified my email" when email is verified redirects to dashboard', (tester) async {
    await setMobileViewport(tester);

    bool isEmailVerified = false;
    when(() => mockUser.emailVerified).thenAnswer((_) => isEmailVerified);
    when(() => mockUser.reload()).thenAnswer((_) async {
      isEmailVerified = true;
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('I have verified my email'));
    await tester.pumpAndSettle();

    verify(() => mockUser.reload()).called(1);
    expect(find.text('dashboard-page'), findsOneWidget);
  });

  testWidgets('clicking "I have verified my email" when email is NOT verified shows SnackBar error', (tester) async {
    await setMobileViewport(tester);

    when(() => mockUser.emailVerified).thenReturn(false);
    when(() => mockUser.reload()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('I have verified my email'));
    await tester.pumpAndSettle();

    verify(() => mockUser.reload()).called(1);
    expect(find.text('Email not verified yet. Please check your inbox.'), findsOneWidget);
  });

  testWidgets('clicking "Resend Email" calls sendEmailVerification and shows success SnackBar', (tester) async {
    await setMobileViewport(tester);

    when(() => mockUser.sendEmailVerification()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Resend Email'));
    await tester.pumpAndSettle();

    verify(() => mockUser.sendEmailVerification()).called(1);
    expect(find.text('Verification email resent.'), findsOneWidget);
  });

  testWidgets('clicking "Back to Login" calls signOut on AuthRepository and redirects to creator login', (tester) async {
    await setMobileViewport(tester);

    when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();

    verify(() => mockAuthRepository.signOut()).called(1);
    expect(find.text('login-page'), findsOneWidget);
  });
}
