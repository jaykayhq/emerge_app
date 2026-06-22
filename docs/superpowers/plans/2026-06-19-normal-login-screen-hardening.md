# Normal Login Screen Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the normal login screen by verifying that the user has the normal user role during email/password and Google login, signing out and prompting them if they are a creator.

**Architecture:** Integrate `isNormalUserProvider` and `firebaseAuthProvider` checks inside `_login` and `_loginWithGoogle`. Mock the authentication state, user roles, and repository operations in tests to verify normal user access is permitted and creator access is blocked with a sign-out.

**Tech Stack:** Flutter, Riverpod, Firebase Auth, Mocktail, GoRouter.

---

### Task 1: Normal Login Screen Logical Hardening

**Files:**
- Modify: `lib/features/auth/presentation/screens/login_screen.dart`

- [ ] **Step 1: Modify email/password login**
  Modify `_login` inside `lib/features/auth/presentation/screens/login_screen.dart` to check that the logged-in user is a normal user. If not, sign out and throw the creator hub redirection warning exception.
  
  ```dart
  Future<void> _login() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      await ref.read(signInProvider(email, password).future);

      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw Exception('User not found');
      }

      final isNormal = await ref.read(isNormalUserProvider(user.uid).future);
      if (!isNormal) {
        await ref.read(authRepositoryProvider).signOut();
        throw Exception('This is a creator account. Please log in through the Creator Hub.');
      }
      
      // Navigation is handled by the router's redirect
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

- [ ] **Step 2: Modify Google login**
  Modify `_loginWithGoogle` inside `lib/features/auth/presentation/screens/login_screen.dart` to perform the same checks after a successful Google sign-in.
  
  ```dart
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authRepositoryProvider).signInWithGoogle(isLogin: true);
      
      bool proceed = false;
      result.fold(
        (error) {
          // 'redirect_initiated' is not a real error — on web the page
          // navigates away to Google OAuth. Keep loading; do not show snackbar.
          if (error.message == 'redirect_initiated') return;
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.message)));
          }
        },
        (_) => proceed = true,
      );

      if (proceed) {
        final user = ref.read(firebaseAuthProvider).currentUser;
        if (user == null) {
          throw Exception('User not found');
        }

        final isNormal = await ref.read(isNormalUserProvider(user.uid).future);
        if (!isNormal) {
          await ref.read(authRepositoryProvider).signOut();
          throw Exception('This is a creator account. Please log in through the Creator Hub.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      // Don't reset loading on web redirect — the page will navigate away.
      // Only reset if still mounted and not mid-redirect.
      if (mounted) setState(() => _isLoading = false);
    }
  }
  ```

---

### Task 2: Implement Widget Tests and Verifications

**Files:**
- Modify: `test/features/auth/presentation/screens/login_screen_test.dart`

- [ ] **Step 1: Set up mocks and update `_buildTest` overrides**
  In `test/features/auth/presentation/screens/login_screen_test.dart`, define `MockFirebaseAuth` and `MockUser` classes. Initialize them in `setUp` and override them in `_buildTest` so they are accessible and predictable in tests. Override `isNormalUserProvider` to return `true` by default.
  
  ```dart
  class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}
  class MockUser extends Mock implements firebase_auth.User {}

  late MockAuthRepository mockAuth;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  // Update _buildTest
  Widget _buildTest(
    AuthRepository repo, {
    List<Override> overrides = const [],
  }) {
    return createScreenUnderTest(
      screen: const LoginScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        isNormalUserProvider('test-uid').overrideWith((ref) async => true),
        ...overrides,
      ],
    );
  }
  ```

- [ ] **Step 2: Add test case for creator attempting normal login**
  Verify that logging in with standard email/password as a creator account signs the user out and displays the correct SnackBar error message. Make sure to yield control via `await Future.value()` in stubs before throwing.
  
  ```dart
  testWidgets('logging in as a creator/non-normal user signs out and shows snackbar', (tester) async {
    await setMobileViewport(tester);

    when(() => mockUser.uid).thenReturn('creator-uid');
    when(() => mockAuth.signInWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => right(testAuthUser));
    when(() => mockAuth.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(_buildTest(
      mockAuth,
      overrides: [
        isNormalUserProvider('creator-uid').overrideWith((ref) async {
          await Future.value();
          return false;
        }),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'creator@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();

    verify(() => mockAuth.signOut()).called(1);
    expect(find.text('This is a creator account. Please log in through the Creator Hub.'), findsOneWidget);
  });
  ```

- [ ] **Step 3: Add test case for creator attempting Google login**
  Verify that Google Sign-in with a creator account signs the user out and displays the appropriate SnackBar.
  
  ```dart
  testWidgets('Google Sign-In with a creator account signs out and shows snackbar', (tester) async {
    await setMobileViewport(tester);

    when(() => mockUser.uid).thenReturn('creator-uid');
    when(() => mockAuth.signInWithGoogle(isLogin: true)).thenAnswer((_) async => right(testAuthUser));
    when(() => mockAuth.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(_buildTest(
      mockAuth,
      overrides: [
        isNormalUserProvider('creator-uid').overrideWith((ref) async {
          await Future.value();
          return false;
        }),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    verify(() => mockAuth.signOut()).called(1);
    expect(find.text('This is a creator account. Please log in through the Creator Hub.'), findsOneWidget);
  });
  ```

- [ ] **Step 4: Run widget tests and verify they pass**
  Run command: `flutter test test/features/auth/presentation/screens/login_screen_test.dart`
  Expected: All tests pass cleanly.
