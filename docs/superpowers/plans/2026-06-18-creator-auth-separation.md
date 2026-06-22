# Creator Auth Separation & Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement separate, hardened authentication and signup flows for normal users and creators, ensuring creators register and verify their email via a post-registration verification screen before accessing the Creator Hub.

**Architecture:** We use Firestore-based verification of profile document existence to check roles (`users/{uid}` for normal, `creator_profiles/{uid}` for creators). We harden page actions and `GoRouter` redirects to block cross-role navigation, and use `sendEmailVerification()` for creators.

**Tech Stack:** Flutter, Firebase Auth, Cloud Firestore, Riverpod, GoRouter, Mocktail (for testing).

---

## Files Map
*   **Create:** [creator_signup_screen.dart](file:///C:/Users/HP/Downloads/emerge_app/lib/features/auth/presentation/screens/creator_signup_screen.dart) — Creator sign-up UI (amber/gold style).
*   **Create:** [creator_verify_email_screen.dart](file:///C:/Users/HP/Downloads/emerge_app/lib/features/auth/presentation/screens/creator_verify_email_screen.dart) — Friendly email verification screen.
*   **Modify:** [auth_providers.dart](file:///C:/Users/HP/Downloads/emerge_app/lib/features/auth/presentation/providers/auth_providers.dart) — Add Riverpod providers for role verification.
*   **Modify:** [creator_login_screen.dart](file:///C:/Users/HP/Downloads/emerge_app/lib/features/auth/presentation/screens/creator_login_screen.dart) — Update login buttons, add link to signup, add Google login, validate role/verification.
*   **Modify:** [login_screen.dart](file:///C:/Users/HP/Downloads/emerge_app/lib/features/auth/presentation/screens/login_screen.dart) — Harden normal login button to validate normal user role.
*   **Modify:** [router.dart](file:///C:/Users/HP/Downloads/emerge_app/lib/core/router/router.dart) — Harden guards and add new routes.
*   **Create/Modify Tests:**
    *   `test/features/auth/presentation/providers/auth_providers_test.dart`
    *   `test/features/auth/presentation/screens/creator_signup_screen_test.dart`
    *   `test/features/auth/presentation/screens/creator_verify_email_screen_test.dart`
    *   `test/features/auth/presentation/screens/creator_login_screen_test.dart`

---

## Tasks

### Task 1: Riverpod Role Verification Providers

**Files:**
*   Modify: `lib/features/auth/presentation/providers/auth_providers.dart`
*   Modify: `test/features/auth/presentation/providers/auth_providers_test.dart`

- [ ] **Step 1: Write test for new role providers**
  Open `test/features/auth/presentation/providers/auth_providers_test.dart` and add tests under a new group `'role check providers'` to verify that `isNormalUserProvider` and `isCreatorProvider` read from Firestore correctly.
  
  ```dart
  // In test/features/auth/presentation/providers/auth_providers_test.dart
  // Add this mock at the top level
  class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
  class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
  class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
  class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
  ```
  And add the tests:
  ```dart
  group('Role check providers', () {
    test('isNormalUserProvider returns true if user doc exists', () async {
      // Stubbing firestore doc read to return true
      // We will override the providers using a fake FirebaseFirestore instance if injected, 
      // or simply override the provider itself.
    });
  });
  ```
  Wait, let's write a simple implementation of `isNormalUserProvider` and `isCreatorProvider` that uses standard Firestore and allows overriding.
  Let's add the providers to `lib/features/auth/presentation/providers/auth_providers.dart`:
  ```dart
  @riverpod
  Future<bool> isNormalUser(Ref ref, String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists;
  }

  @riverpod
  Future<bool> isCreator(Ref ref, String uid) async {
    final doc = await FirebaseFirestore.instance.collection('creator_profiles').doc(uid).get();
    return doc.exists;
  }
  ```

- [ ] **Step 2: Run tests to verify compiling**
  Run: `flutter test test/features/auth/presentation/providers/auth_providers_test.dart`
  Expected: Compile successfully (tests pass or fail on stubs).

- [ ] **Step 3: Modify auth_providers.dart**
  Implement the providers in `lib/features/auth/presentation/providers/auth_providers.dart`:
  Add the following lines to `lib/features/auth/presentation/providers/auth_providers.dart` (at the bottom of the file):
  ```dart
  @riverpod
  Future<bool> isNormalUser(Ref ref, String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists;
  }

  @riverpod
  Future<bool> isCreator(Ref ref, String uid) async {
    final doc = await FirebaseFirestore.instance.collection('creator_profiles').doc(uid).get();
    return doc.exists;
  }
  ```

- [ ] **Step 4: Run tests and ensure they pass**
  Run: `flutter test test/features/auth/presentation/providers/auth_providers_test.dart`
  Expected: All tests pass.

- [ ] **Step 5: Commit**
  Run:
  ```bash
  git add lib/features/auth/presentation/providers/auth_providers.dart
  git commit -m "feat: add role check providers for normal and creator profiles"
  ```

---

### Task 2: Creator Sign-Up Screen

**Files:**
*   Create: `lib/features/auth/presentation/screens/creator_signup_screen.dart`
*   Create: `test/features/auth/presentation/screens/creator_signup_screen_test.dart`

- [ ] **Step 1: Create CreatorSignUpScreen**
  Write the screen to `lib/features/auth/presentation/screens/creator_signup_screen.dart` with:
  *   Amber/gold theme matching Creator Hub.
  *   Fields for Email, Password, Username.
  *   Submit button "Register as Creator".
  *   Google Sign-Up button.
  *   Sign up with Email calls `createUserWithEmailAndPassword`, then writes a default `CreatorProfile` in `/creator_profiles/{uid}`, triggers `sendEmailVerification()`, and redirects to `/creator/verify-email`.
  *   Sign up with Google calls `signInWithGoogle`, verifies they do not exist in `users` (normal profiles). If they do, throws an error. If they don't, writes to `creator_profiles` and redirects directly to `/creator/dashboard`.

  Code structure:
  ```dart
  // Complete implementation will be written during Task 2 execution
  ```

- [ ] **Step 2: Create creator_signup_screen_test.dart**
  Write widget tests for `CreatorSignUpScreen` in `test/features/auth/presentation/screens/creator_signup_screen_test.dart` to verify input fields rendering, validation messages, and button triggers.

- [ ] **Step 3: Run the tests**
  Run: `flutter test test/features/auth/presentation/screens/creator_signup_screen_test.dart`
  Expected: PASS

- [ ] **Step 4: Commit**
  Run:
  ```bash
  git add lib/features/auth/presentation/screens/creator_signup_screen.dart test/features/auth/presentation/screens/creator_signup_screen_test.dart
  git commit -m "feat: add creator signup screen and widget tests"
  ```

---

### Task 3: Creator Verify Email Screen

**Files:**
*   Create: `lib/features/auth/presentation/screens/creator_verify_email_screen.dart`
*   Create: `test/features/auth/presentation/screens/creator_verify_email_screen_test.dart`

- [ ] **Step 1: Create CreatorVerifyEmailScreen**
  Write the verification screen to `lib/features/auth/presentation/screens/creator_verify_email_screen.dart` with:
  *   Gold/amber themed UI, showing verification instructions.
  *   "I have verified my email" button: calls `await FirebaseAuth.instance.currentUser?.reload()`. If `emailVerified` is true, goes to `/creator/dashboard`. Else shows toast.
  *   "Resend email" button: calls `await FirebaseAuth.instance.currentUser?.sendEmailVerification()`.
  *   "Back to Login" button: calls `await ref.read(authRepositoryProvider).signOut()` and redirects to `/creator/login`.

- [ ] **Step 2: Create creator_verify_email_screen_test.dart**
  Write tests in `test/features/auth/presentation/screens/creator_verify_email_screen_test.dart` checking elements, button taps, and reload logic.

- [ ] **Step 3: Run tests**
  Run: `flutter test test/features/auth/presentation/screens/creator_verify_email_screen_test.dart`
  Expected: PASS

- [ ] **Step 4: Commit**
  Run:
  ```bash
  git add lib/features/auth/presentation/screens/creator_verify_email_screen.dart test/features/auth/presentation/screens/creator_verify_email_screen_test.dart
  git commit -m "feat: add creator verify email screen and widget tests"
  ```

---

### Task 4: Creator Login Screen Hardening

**Files:**
*   Modify: `lib/features/auth/presentation/screens/creator_login_screen.dart`
*   Modify: `test/features/auth/presentation/screens/creator_login_screen_test.dart`

- [ ] **Step 1: Modify CreatorLoginScreen**
  Edit `lib/features/auth/presentation/screens/creator_login_screen.dart`:
  *   Add a text link at the bottom: "Are you a creator? Sign Up". Clicking it navigates to `/creator/signup`.
  *   Add a "Sign in with Google" button.
  *   In the `_login` method (and Google login): after Firebase Auth login returns credentials, fetch `isCreatorProvider` for the logged-in uid.
  *   If the user is NOT a creator, call `signOut()` and show SnackBar: *"This account is not registered as a creator."*
  *   If they are a creator, check if they authenticated via email and if `user.emailVerified == false`. If so, do not throw an error but navigate directly to `/creator/verify-email`.

- [ ] **Step 2: Update CreatorLoginScreen tests**
  Modify `test/features/auth/presentation/screens/creator_login_screen_test.dart` to verify that when logging in as a non-creator, it shows an error, and when logging in as an unverified creator, it redirects to verify email.

- [ ] **Step 3: Run tests**
  Run: `flutter test test/features/auth/presentation/screens/creator_login_screen_test.dart`
  Expected: PASS

- [ ] **Step 4: Commit**
  Run:
  ```bash
  git add lib/features/auth/presentation/screens/creator_login_screen.dart test/features/auth/presentation/screens/creator_login_screen_test.dart
  git commit -m "feat: harden creator login flow with role and verification checks"
  ```

---

### Task 5: Normal Login Screen Hardening

**Files:**
*   Modify: `lib/features/auth/presentation/screens/login_screen.dart`
*   Modify: `test/features/auth/presentation/screens/login_screen_test.dart`

- [ ] **Step 1: Modify LoginScreen**
  Edit `lib/features/auth/presentation/screens/login_screen.dart`:
  *   In the email login and Google login methods: after Firebase Auth login, verify `isNormalUserProvider` is `true`.
  *   If `isNormalUser` is `false` (meaning they are a creator or have no profile), call `signOut()` and throw an Exception/show SnackBar: *"This is a creator account. Please log in through the Creator Hub."*

- [ ] **Step 2: Update LoginScreen tests**
  Modify `test/features/auth/presentation/screens/login_screen_test.dart` to add a test case verifying that logging in with a creator account throws a role validation error.

- [ ] **Step 3: Run tests**
  Run: `flutter test test/features/auth/presentation/screens/login_screen_test.dart`
  Expected: PASS

- [ ] **Step 4: Commit**
  Run:
  ```bash
  git add lib/features/auth/presentation/screens/login_screen.dart test/features/auth/presentation/screens/login_screen_test.dart
  git commit -m "feat: harden normal login flow to block creator accounts"
  ```

---

### Task 6: GoRouter Guard and Route Definition

**Files:**
*   Modify: `lib/core/router/router.dart`

- [ ] **Step 1: Add routes and update redirect guard**
  Edit `lib/core/router/router.dart`:
  *   Import `creator_signup_screen.dart` and `creator_verify_email_screen.dart`.
  *   Add GoRoute paths: `/creator/signup` (CreatorSignUpScreen) and `/creator/verify-email` (CreatorVerifyEmailScreen).
  *   In redirect guard:
      *   If user is logged in:
          *   Check if they are a creator (using Firestore snapshot/cache or provider check).
          *   If they are a creator with an unverified email address, redirect them to `/creator/verify-email` if they aren't already there.
          *   If they have a creator profile and try to access any non-creator page (e.g. `/` or onboarding), redirect to `/creator/dashboard`.
          *   If they do NOT have a creator profile (normal user) and try to access `/creator/*` pages, redirect to `/login`.

- [ ] **Step 2: Run all project tests**
  Run: `flutter test`
  Expected: All tests pass.

- [ ] **Step 3: Commit**
  Run:
  ```bash
  git add lib/core/router/router.dart
  git commit -m "feat: add creator signup and verify email routes, enforce role guards"
  ```
