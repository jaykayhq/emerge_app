# Design Spec: Creator Auth Separation & Hardening

This design document outlines the strategy for separating and hardening the authentication paths of normal users and creators in the Emerge application.

## 1. Overview & Objectives

Currently, the application contains separate login screens for normal users (`/login`) and creators (`/creator/login`), but there is no strict validation preventing:
1. A normal user from logging into the Creator Hub.
2. A creator account from logging into the normal application.
3. Creator sign-up, which is completely missing.

The objective is to enforce strict role boundaries using Firestore document checks, add a dedicated Creator Sign-up flow, and harden routing redirects so that each user role can only access its designated section of the application.

Both email/password and Google Sign-In authentication methods will be supported for both Normal and Creator accounts.

Additionally, to ensure email validity and account hardening, creators who sign up with email and password will go through an email verification flow with a dedicated, user-friendly verification status screen.

---

## 2. Role Boundaries (Approach A)

We will use Firestore collection presence to establish and enforce user roles:
*   **Normal Users:** Must have a document in the `/users/{uid}` collection.
*   **Creators:** Must have a document in the `/creator_profiles/{uid}` collection.

### 2.1 Sign-Up & Verification Flows
*   **Normal Sign-up (`/signup`):** Creates Firebase Auth credentials (email or Google), then creates a document in `users` and `user_stats`.
*   **Creator Sign-up (`/creator/signup`):** Creates Firebase Auth credentials (email or Google), then creates a document in `creator_profiles` (initialized with `isVerifiedCreator: false`).
    *   If using **Google Sign-In**: Creator profile is created and they are redirected to `/creator/dashboard` directly (Google accounts are pre-verified).
    *   If using **Email/Password**: We trigger `user.sendEmailVerification()`, save their creator profile, and redirect them to `/creator/verify-email`.

---

## 3. Detailed Architecture & Components

```mermaid
flowchart TD
    Start[User Login / Sign Up] --> Choice{Role Path?}
    Choice -->|Normal User| NormalFlow[Normal Login / Sign Up]
    Choice -->|Creator| CreatorFlow[Creator Login / Sign Up]

    NormalFlow --> AuthNormal[Firebase Auth Email or Google]
    AuthNormal --> VerifyNormal{Check users/{uid}?}
    VerifyNormal -->|Exists| AccessNormal[Access App /]
    VerifyNormal -->|No/Only Creator| ErrorNormal[Sign Out & Error: Creator account must use Creator Hub]

    CreatorFlow --> AuthCreator[Firebase Auth Email or Google]
    AuthCreator --> Method{Auth Method?}
    Method -->|Google| VerifyCreator{Check creator_profiles/{uid}?}
    Method -->|Email/Password| CheckVerified{Email Verified?}
    
    CheckVerified -->|Yes| VerifyCreator
    CheckVerified -->|No| RedirectVerify[Redirect to /creator/verify-email]
    
    VerifyCreator -->|Exists| AccessCreator[Access Creator Hub /creator/dashboard]
    VerifyCreator -->|No| ErrorCreator[Sign Out & Error: Normal user must use standard login]
```

### 3.1 New & Modified Files

#### 1. Riverpod Auth Providers (`auth_providers.dart`)
We will add providers to check user role status from Firestore asynchronously:
```dart
// Check if user has a normal profile
final isNormalUserProvider = FutureProvider.family<bool, String>((ref, uid) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  return doc.exists;
});

// Check if user has a creator profile
final isCreatorProvider = FutureProvider.family<bool, String>((ref, uid) async {
  final doc = await FirebaseFirestore.instance.collection('creator_profiles').doc(uid).get();
  return doc.exists;
});
```

#### 2. Creator Sign-Up Screen (`creator_signup_screen.dart`)
*   **Path:** `lib/features/auth/presentation/screens/creator_signup_screen.dart`
*   **Route:** `/creator/signup`
*   **Description:** Screen matching the amber/gold theme of the Creator Hub. Allows users to sign up as creators using their Email/Password or **Google Sign-In**. Upon email creation, it triggers `sendEmailVerification()` and redirects to `/creator/verify-email`.

#### 3. Creator Verify Email Screen (`creator_verify_email_screen.dart`)
*   **Path:** `lib/features/auth/presentation/screens/creator_verify_email_screen.dart`
*   **Route:** `/creator/verify-email`
*   **Description:** A friendly user interface showing that a verification email has been sent. It includes:
    *   An envelope animation/icon.
    *   A button "I have verified my email" which runs `user.reload()` and checks `user.emailVerified`. If true, redirects to `/creator/dashboard`. If false, shows a toast informing the user.
    *   A button to "Resend verification email".
    *   A button to go back to login (signs user out).

#### 4. Creator Login Screen (`creator_login_screen.dart`)
*   **Path:** `lib/features/auth/presentation/screens/creator_login_screen.dart`
*   **Changes:**
    *   Add a button linking to `/creator/signup`.
    *   Add a Google Sign-In button for creators.
    *   Harden the login button and Google Sign-In handlers:
        *   After Firebase Auth succeeds, check if the email is verified (if login method was email/password). If not verified, redirect to `/creator/verify-email` (do not show error).
        *   Check if the user has a creator profile. If not, sign them out and show an error.

#### 5. Normal Login Screen (`login_screen.dart`)
*   **Path:** `lib/features/auth/presentation/screens/login_screen.dart`
*   **Changes:**
    *   Harden the login button and Google Sign-In handlers:
        *   After Firebase Auth succeeds, check if they have a normal profile. If not, sign them out and show an error.

#### 6. Router Guard Hardening (`router.dart`)
*   **Path:** `lib/core/router/router.dart`
*   **Changes:**
    *   Add `/creator/verify-email` route.
    *   In the redirection block, check if the authenticated user is a creator with an unverified email. If so, restrict them to `/creator/verify-email`.
    *   Prevent normal users from accessing `/creator/*` and creators from accessing normal screens.

---

## 4. Security & Hardening Edge Cases

1.  **Direct Navigation Bypass:** If a user manually types a URL (like `/creator/dashboard` or `/habits`), the `GoRouter` redirect guard checks their Firestore profile status and email verification status, redirecting them back to `/creator/verify-email` or their appropriate login screen.
2.  **No Profile Leftover:** If a user signup fails halfway (Auth account created, but Firestore write failed), they will not have a profile. When they try to log in, the validation checks will catch the missing profile, sign them out, and tell them to register again.
3.  **Local Caching:** Using `FutureProvider` ensures we fetch the latest profile status directly from Firestore during login/guard checks to prevent caching issues.
4.  **Google Account Collisions:** If a creator uses their Google account to sign up on the normal `/signup` page, that Google account is bound to a normal profile. If they attempt to sign up as a creator with the same Google account, we will verify that a Google signup on the creator route checks if the user already has a normal profile. If they do, we block the action to prevent collision.
