# Creator Verify Email Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Creator Verify Email screen with an Amber/Gold theme matching the Emerge app creator aesthetics. The screen will support reloading the user's status, resending the verification email, and signing out to return to login.

**Architecture:** A Riverpod-powered ConsumerStatefulWidget that accesses `firebaseAuthProvider` for user reloading and email verification, and `authRepositoryProvider` for signing out. All navigation uses `go_router`.

**Tech Stack:** Flutter, Riverpod, GoRouter, Firebase Auth, Google Fonts, Mocktail (for widget tests).

---

## Files Map
*   **Create:** `lib/features/auth/presentation/screens/creator_verify_email_screen.dart` — Creator Verify Email UI.
*   **Create:** `test/features/auth/presentation/screens/creator_verify_email_screen_test.dart` — Unit/widget tests.

---

## Tasks

### Task 1: Create CreatorVerifyEmailScreen

**Files:**
- Create: `lib/features/auth/presentation/screens/creator_verify_email_screen.dart`

- [ ] **Step 1: Write the screen implementation**
  Create `lib/features/auth/presentation/screens/creator_verify_email_screen.dart` with:
  *   Amber/gold gradient/glow themed UI matching the Emerge app creator aesthetics.
  *   HexMeshBackground decoration.
  *   Helpful instructions to verify the email.
  *   "I have verified my email" button: Reloads user, redirects to `/creator/dashboard` if verified, otherwise shows a SnackBar.
  *   "Resend Email" button: Calls `sendEmailVerification()` and shows a SnackBar.
  *   "Back to Login" button: Calls `authRepository.signOut()` and redirects to `/creator/login`.

  ```dart
  import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
  import 'package:emerge_app/core/presentation/widgets/emerge_app_icon.dart';
  import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
  import 'package:emerge_app/core/theme/app_theme.dart';
  import 'package:emerge_app/core/theme/emerge_colors.dart';
  import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:gap/gap.dart';
  import 'package:go_router/go_router.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:flutter_animate/flutter_animate.dart';

  class CreatorVerifyEmailScreen extends ConsumerStatefulWidget {
    const CreatorVerifyEmailScreen({super.key});

    @override
    ConsumerState<CreatorVerifyEmailScreen> createState() => _CreatorVerifyEmailScreenState();
  }

  class _CreatorVerifyEmailScreenState extends ConsumerState<CreatorVerifyEmailScreen> {
    bool _isReloading = false;
    bool _isResending = false;

    Future<void> _checkEmailVerified() async {
      setState(() => _isReloading = true);
      try {
        final auth = ref.read(firebaseAuthProvider);
        final user = auth.currentUser;
        if (user != null) {
          await user.reload();
          // Fetch user again after reload to get updated status
          final updatedUser = auth.currentUser;
          if (updatedUser != null && updatedUser.emailVerified) {
            if (mounted) {
              context.go('/creator/dashboard');
            }
            return;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not verified yet. Please check your inbox.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isReloading = false);
        }
      }
    }

    Future<void> _resendVerificationEmail() async {
      setState(() => _isResending = true);
      try {
        final user = ref.read(firebaseAuthProvider).currentUser;
        if (user != null) {
          await user.sendEmailVerification();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification email resent.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception('No authenticated user found.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resending email: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isResending = false);
        }
      }
    }

    Future<void> _signOutAndBack() async {
      try {
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) {
          context.go('/creator/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: ${e.toString()}')),
          );
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final user = ref.watch(firebaseAuthProvider).currentUser;
      final email = user?.email ?? 'your email';

      return Scaffold(
        backgroundColor: EmergeColors.background,
        body: Stack(
          children: [
            const Positioned.fill(child: HexMeshBackground()),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.amber.withValues(alpha: 0.15),
                      EmergeColors.violet.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ResponsiveLayout(
                  mobile: _buildContent(theme, email, isMobile: true),
                  tablet: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Card(
                      elevation: 8,
                      color: EmergeColors.background.withValues(alpha: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: Colors.amber, width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: _buildContent(theme, email, isMobile: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildContent(ThemeData theme, String email, {required bool isMobile}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: const Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: Colors.amber,
            ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.backOut),
          ),
          const Gap(24),
          Text(
            'Verify your Email',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const Gap(16),
          Text(
            'We sent a verification link to:\n$email',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const Gap(8),
          Text(
            'Please click the link in the email to activate your creator account.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
          const Gap(32),

          // Primary Button: I have verified my email
          Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
            ),
            child: ElevatedButton(
              onPressed: _isReloading ? null : _checkEmailVerified,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isReloading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'I have verified my email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.95, 0.95)),
          const Gap(16),

          // Secondary Button: Resend Email
          OutlinedButton.icon(
            onPressed: _isResending ? null : _resendVerificationEmail,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: Colors.amber.withValues(alpha: 0.5),
              ),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: _isResending
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.amber,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.amber),
            label: const Text(
              'Resend Email',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
          const Gap(24),

          // Text link: Back to Login
          TextButton(
            onPressed: _signOutAndBack,
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Back to Login',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ).animate().fadeIn(delay: 700.ms),
        ],
      );
    }
  }
  ```

---

### Task 2: Create Widget Tests

**Files:**
- Create: `test/features/auth/presentation/screens/creator_verify_email_screen_test.dart`

- [ ] **Step 1: Write widget and logic tests**
  Create `test/features/auth/presentation/screens/creator_verify_email_screen_test.dart` that tests:
  *   Visual elements: title, subtitle, verification email address, buttons.
  *   Tapping "I have verified my email" when `emailVerified == true`.
  *   Tapping "I have verified my email" when `emailVerified == false`.
  *   Tapping "Resend Email" button.
  *   Tapping "Back to Login" button.
  *   Utilizing mocktail mocks/fakes for:
      - `FirebaseAuth`
      - `User`
      - `AuthRepository`

  ```dart
  import 'package:dartz/dartz.dart';
  import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
  import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
  import 'package:emerge_app/features/auth/presentation/screens/creator_verify_email_screen.dart';
  import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mocktail/mocktail.dart';
  import 'package:go_router/go_router.dart';

  class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}
  class MockUser extends Mock implements firebase_auth.User {}
  class MockAuthRepository extends Mock implements AuthRepository {}
  class MockGoRouter extends Mock implements GoRouter {}

  void main() {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockAuthRepository mockAuthRepository;
    late MockGoRouter mockGoRouter;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockAuthRepository = MockAuthRepository();
      mockGoRouter = MockGoRouter();

      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('creator@emerge.app');
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
        child: MaterialApp(
          home: InheritedGoRouter(
            goRouter: mockGoRouter,
            child: const CreatorVerifyEmailScreen(),
          ),
        ),
      );
    }

    testWidgets('renders all visual elements correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
      expect(find.text('Verify your Email'), findsOneWidget);
      expect(find.textContaining('creator@emerge.app'), findsOneWidget);
      expect(find.text('I have verified my email'), findsOneWidget);
      expect(find.text('Resend Email'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('clicking "I have verified my email" when email is verified redirects to dashboard', (tester) async {
      when(() => mockUser.reload()).thenAnswer((_) async {});
      when(() => mockUser.emailVerified).thenReturn(true);
      when(() => mockGoRouter.go('/creator/dashboard')).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('I have verified my email'));
      await tester.pump(); // Start action

      verify(() => mockUser.reload()).called(1);
      verify(() => mockGoRouter.go('/creator/dashboard')).called(1);
    });

    testWidgets('clicking "I have verified my email" when email is NOT verified shows SnackBar', (tester) async {
      when(() => mockUser.reload()).thenAnswer((_) async {});
      when(() => mockUser.emailVerified).thenReturn(false);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('I have verified my email'));
      await tester.pumpAndSettle();

      verify(() => mockUser.reload()).called(1);
      expect(find.text('Email not verified yet. Please check your inbox.'), findsOneWidget);
    });

    testWidgets('clicking "Resend Email" calls sendEmailVerification and shows SnackBar', (tester) async {
      when(() => mockUser.sendEmailVerification()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resend Email'));
      await tester.pumpAndSettle();

      verify(() => mockUser.sendEmailVerification()).called(1);
      expect(find.text('Verification email resent.'), findsOneWidget);
    });

    testWidgets('clicking "Back to Login" calls signOut and redirects', (tester) async {
      when(() => mockAuthRepository.signOut()).thenAnswer((_) async => const Right(null));
      when(() => mockGoRouter.go('/creator/login')).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to Login'));
      await tester.pump();

      verify(() => mockAuthRepository.signOut()).called(1);
      verify(() => mockGoRouter.go('/creator/login')).called(1);
    });
  }
  ```

---

## Verification Plan

### Automated Tests
Run the newly created widget test:
`flutter test test/features/auth/presentation/screens/creator_verify_email_screen_test.dart`

### Code Quality & Lints
Run standard code analyzer check:
`flutter analyze`
