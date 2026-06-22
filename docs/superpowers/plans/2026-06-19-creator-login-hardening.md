# Creator Login Screen Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the Creator Login Screen by adding role checks, email verification checks, a themed Google Sign-In button, a creator signup link, and comprehensive widget tests.

**Architecture:** Use Riverpod providers (`signInProvider`, `firebaseAuthProvider`, `isCreatorProvider`, and `signUpCreatorWithGoogleProvider`) inside the presentation layer to implement authentication logic. Redirection uses GoRouter (`context.go`).

**Tech Stack:** Flutter, flutter_riverpod, go_router, firebase_auth, mocktail, flutter_test.

---

### Task 1: Hardened Email/Password Login Logic & Tests

**Files:**
- Modify: `lib/features/auth/presentation/screens/creator_login_screen.dart`
- Modify: `test/features/auth/presentation/screens/creator_login_screen_test.dart`

- [ ] **Step 1: Update existing tests in `test/features/auth/presentation/screens/creator_login_screen_test.dart` to support new providers**
  Update the `_buildTest` helper and mocking setup to stub `firebaseAuthProvider`, `signInProvider`, and `isCreatorProvider` so that existing tests don't break.
  ```dart
  // In creator_login_screen_test.dart:
  // Add necessary Mock classes and update _buildTest
  class MockFirebaseAuth extends Mock implements FirebaseAuth {}
  class MockUser extends Mock implements User {}
  class MockProviderSubscription extends Mock implements ProviderSubscription {}

  // Update _buildTest to override providers:
  Widget _buildTest({
    required AuthRepository repo,
    required FirebaseAuth firebaseAuth,
    required bool Function(String) isCreatorMock,
  }) {
    return createScreenUnderTest(
      screen: const CreatorLoginScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        firebaseAuthProvider.overrideWithValue(firebaseAuth),
        isCreatorProvider.overrideWith((ref, uid) async => isCreatorMock(uid)),
      ],
    );
  }
  ```

- [ ] **Step 2: Add failing widget test for non-creator login**
  Write a test case where a user signs in, but `isCreatorProvider` returns `false`. Verify `signOut` is called on the repo, and the appropriate snackbar is shown.
  ```dart
  testWidgets('shows error and signs out if user is not a creator', (tester) async {
    await setMobileViewport(tester);

    final mockUser = MockUser();
    when(() => mockUser.uid).thenReturn('non-creator-uid');
    final mockAuthInstance = MockFirebaseAuth();
    when(() => mockAuthInstance.currentUser).thenReturn(mockUser);

    when(() => mockAuth.signInWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => right(testAuthUser));

    when(() => mockAuth.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(_buildTest(
      repo: mockAuth,
      firebaseAuth: mockAuthInstance,
      isCreatorMock: (uid) => false,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login to Creator Hub'));
    await tester.pumpAndSettle();

    verify(() => mockAuth.signOut()).called(1);
    expect(find.text('This account is not registered as a creator.'), findsOneWidget);
  });
  ```

- [ ] **Step 3: Run the new test and verify it fails**
  Run: `flutter test test/features/auth/presentation/screens/creator_login_screen_test.dart`
  Expected: FAIL (either doesn't compile or the check for signOut/snackbar fails because we haven't implemented it).

- [ ] **Step 4: Implement email/password verification checks in `_login`**
  Modify `_login` in `lib/features/auth/presentation/screens/creator_login_screen.dart` to retrieve the current user, call `isCreatorProvider`, and perform verification/signout/routing logic.
  ```dart
  // In creator_login_screen.dart:
  Future<void> _login() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(
        signInProvider(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        ).future,
      );

      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw Exception('User not found');
      }

      final isCreator = await ref.read(isCreatorProvider(user.uid).future);
      if (!isCreator) {
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This account is not registered as a creator.')),
          );
        }
        return;
      }

      if (!user.emailVerified) {
        if (mounted) {
          context.go('/creator/verify-email');
        }
        return;
      }

      if (mounted) {
        context.go('/creator/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  ```

- [ ] **Step 5: Run tests and verify they pass**
  Run: `flutter test test/features/auth/presentation/screens/creator_login_screen_test.dart`
  Expected: PASS

- [ ] **Step 6: Add widget tests for verified and unverified creator redirects**
  Add test cases in `creator_login_screen_test.dart` to verify routing:
  - If `isCreator` is `true` but `emailVerified` is `false`, redirect to `/creator/verify-email`.
  - If `isCreator` is `true` and `emailVerified` is `true`, redirect to `/creator/dashboard`.
  
  ```dart
  // Note: since go_router uses context.go, we can verify navigation or mock context/goRouter.
  // A clean way is to stub GoRouter using a mock or checking if the router redirect would be triggered,
  // or verifying that the correct context.go calls are called. Since we might need to mock GoRouter,
  // we can use a mock GoRouter or inspect the Navigator/state. Let's see if we can provide a mock GoRouter
  // in overrides or wrap the widget with a MockGoRouter. Let's check how other screens test GoRouter.
  ```

- [ ] **Step 7: Commit changes**
  ```bash
  git add lib/features/auth/presentation/screens/creator_login_screen.dart test/features/auth/presentation/screens/creator_login_screen_test.dart
  git commit -m "feat(auth): implement hardened email/password creator checks and tests"
  ```

---

### Task 2: Google Sign-In UI, Action & Tests

**Files:**
- Modify: `lib/features/auth/presentation/screens/creator_login_screen.dart`
- Modify: `test/features/auth/presentation/screens/creator_login_screen_test.dart`

- [ ] **Step 1: Add the Google Sign-In button UI**
  Insert the amber-outlined Google Sign-In button inside `_buildFormContent` under the main submit button. Import `package:flutter_svg/flutter_svg.dart`.
  ```dart
  // In creator_login_screen.dart:
  OutlinedButton.icon(
    onPressed: _isLoading ? null : _signInWithGoogle,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      side: BorderSide(
        color: Colors.amber.withValues(alpha: 0.5),
      ),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    icon: SvgPicture.asset(
      'assets/images/google_logo.svg',
      width: 20,
      height: 20,
    ),
    label: const Text('Sign in with Google'),
  ),
  ```

- [ ] **Step 2: Add `_signInWithGoogle` implementation**
  Add the `_signInWithGoogle` method in `_CreatorLoginScreenState`:
  ```dart
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final subscription = ref.listenManual(signUpCreatorWithGoogleProvider, (previous, next) {});
    try {
      await ref.read(signUpCreatorWithGoogleProvider.future);
      if (mounted) {
        context.go('/creator/dashboard');
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      subscription.close();
      if (mounted) setState(() => _isLoading = false);
    }
  }
  ```

- [ ] **Step 3: Add Google Sign-In test cases in `creator_login_screen_test.dart`**
  Add tests for success (navigates to dashboard) and failure (shows snackbar). Use a mock provider or overrides.
  ```dart
  // In creator_login_screen_test.dart:
  // Add overrides for signUpCreatorWithGoogleProvider
  ```

- [ ] **Step 4: Run tests to verify they pass**
  Run: `flutter test test/features/auth/presentation/screens/creator_login_screen_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit changes**
  ```bash
  git add lib/features/auth/presentation/screens/creator_login_screen.dart test/features/auth/presentation/screens/creator_login_screen_test.dart
  git commit -m "feat(auth): add creator Google Sign-In and tests"
  ```

---

### Task 3: Creator Sign-Up Link & Final Verification

**Files:**
- Modify: `lib/features/auth/presentation/screens/creator_login_screen.dart`

- [ ] **Step 1: Add "New creator? Sign Up" link**
  Insert the row with the sign up link below/above the "Go Back" row.
  ```dart
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        "New creator? ",
        style: TextStyle(color: Colors.white70),
      ),
      TextButton(
        onPressed: () => context.push('/creator/signup'),
        child: const Text(
          'Sign Up',
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  ),
  ```

- [ ] **Step 2: Run all workspace tests to verify compatibility**
  Run: `flutter test`
  Expected: PASS

- [ ] **Step 3: Commit changes**
  ```bash
  git add lib/features/auth/presentation/screens/creator_login_screen.dart
  git commit -m "feat(auth): add creator signup link to login screen"
  ```
