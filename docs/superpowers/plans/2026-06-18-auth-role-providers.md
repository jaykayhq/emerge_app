# Role Verification Providers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Riverpod providers `isNormalUserProvider` and `isCreatorProvider` to verify user roles based on the existence of their respective documents in Firestore, with unit test coverage.

**Architecture:** Create a `firestoreProvider` to inject `FirebaseFirestore` instance, allowing clean mocking during unit tests, and implement `isNormalUser` and `isCreator` providers.

**Tech Stack:** Flutter, Riverpod (with Code Generation), Cloud Firestore, fake_cloud_firestore, mocktail.

---

### Task 1: Add Firestore Provider & Role Check Stubs to Auth Providers

**Files:**
*   Modify: `lib/features/auth/presentation/providers/auth_providers.dart`

- [ ] **Step 1: Write stubs for the new providers**
  Add `firestoreProvider`, `isNormalUserProvider` stub, and `isCreatorProvider` stub returning `Future.value(false)` to let the tests compile.
  
  ```dart
  @riverpod
  FirebaseFirestore firestore(Ref ref) {
    return FirebaseFirestore.instance;
  }

  @riverpod
  Future<bool> isNormalUser(Ref ref, String uid) async {
    return false;
  }

  @riverpod
  Future<bool> isCreator(Ref ref, String uid) async {
    return false;
  }
  ```

- [ ] **Step 2: Generate the Riverpod code**
  Run: `flutter pub run build_runner build --delete-conflicting-outputs`
  Expected: Code generates successfully and `auth_providers.g.dart` is updated.

- [ ] **Step 3: Verify build compiles**
  Run: `flutter test test/features/auth/presentation/providers/auth_providers_test.dart`
  Expected: Existing tests compile and pass successfully.

---

### Task 2: Write Failing Tests for Role Check Providers

**Files:**
*   Modify: `test/features/auth/presentation/providers/auth_providers_test.dart`

- [ ] **Step 1: Import Firestore dependencies**
  Add imports for `cloud_firestore` and `fake_cloud_firestore`.
  
  ```dart
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
  ```

- [ ] **Step 2: Add test cases for role check providers**
  Add a new test group `'role check providers'` that verifies `isNormalUserProvider` and `isCreatorProvider` return true if documents exist, and false otherwise.
  
  ```dart
  group('role check providers', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('isNormalUserProvider returns true if users/{uid} document exists', () async {
      await fakeFirestore.collection('users').doc('user123').set({'name': 'Test User'});

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await container.read(isNormalUserProvider('user123').future);
      expect(result, isTrue);
      container.dispose();
    });

    test('isNormalUserProvider returns false if users/{uid} document does not exist', () async {
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await container.read(isNormalUserProvider('user123').future);
      expect(result, isFalse);
      container.dispose();
    });

    test('isCreatorProvider returns true if creator_profiles/{uid} document exists', () async {
      await fakeFirestore.collection('creator_profiles').doc('creator123').set({'name': 'Test Creator'});

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await container.read(isCreatorProvider('creator123').future);
      expect(result, isTrue);
      container.dispose();
    });

    test('isCreatorProvider returns false if creator_profiles/{uid} document does not exist', () async {
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await container.read(isCreatorProvider('creator123').future);
      expect(result, isFalse);
      container.dispose();
    });
  });
  ```

- [ ] **Step 3: Run the new tests to verify they fail**
  Run: `flutter test test/features/auth/presentation/providers/auth_providers_test.dart`
  Expected: Tests in the `'role check providers'` group fail because the stubs return `false` (i.e. RED state).

---

### Task 3: Implement Providers and Run Tests (Green)

**Files:**
*   Modify: `lib/features/auth/presentation/providers/auth_providers.dart`

- [ ] **Step 1: Implement role check logic using firestoreProvider**
  Update `isNormalUser` and `isCreator` to fetch document existence from `firestoreProvider`.
  
  ```dart
  @riverpod
  Future<bool> isNormalUser(Ref ref, String uid) async {
    final firestore = ref.watch(firestoreProvider);
    final doc = await firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  @riverpod
  Future<bool> isCreator(Ref ref, String uid) async {
    final firestore = ref.watch(firestoreProvider);
    final doc = await firestore.collection('creator_profiles').doc(uid).get();
    return doc.exists;
  }
  ```

- [ ] **Step 2: Run tests to verify all pass**
  Run: `flutter test test/features/auth/presentation/providers/auth_providers_test.dart`
  Expected: All tests pass (Green).

- [ ] **Step 3: Commit the changes**
  Run:
  ```bash
  git add lib/features/auth/presentation/providers/auth_providers.dart test/features/auth/presentation/providers/auth_providers_test.dart
  git commit -m "feat: add role check providers for normal and creator profiles"
  ```

---

### Task 4: Address Code Quality Reviewer Feedback

**Files:**
*   Modify: `lib/features/auth/presentation/providers/auth_providers.dart`
*   Modify: `test/features/auth/presentation/providers/auth_providers_test.dart`

- [ ] **Step 1: Write failing tests for empty UID check and derived role providers**
  Add test cases to verify:
  1. `isNormalUserProvider` and `isCreatorProvider` return false immediately for empty/whitespace UID.
  2. `isCurrentNormalUserProvider` and `isCurrentCreatorProvider` return correct values based on `authStateChangesProvider`.
  
  Expected: Compile errors/failures (RED).

- [ ] **Step 2: Implement the fixes in auth_providers.dart**
  - Make `firestoreProvider` keepAlive: true.
  - Refactor `authRepositoryProvider` to watch `firestoreProvider`.
  - Add empty/whitespace checks in `isNormalUser` and `isCreator`.
  - Implement `isCurrentNormalUser` and `isCurrentCreator` providers.

- [ ] **Step 3: Run build_runner to regenerate providers**
  Run: `flutter pub run build_runner build --delete-conflicting-outputs`
  Expected: Succeeds and updates `auth_providers.g.dart`.

- [ ] **Step 4: Verify all tests pass**
  Run: `flutter test test/features/auth/presentation/providers/auth_providers_test.dart`
  Expected: PASS (GREEN).

- [ ] **Step 5: Commit changes**
  Run:
  ```bash
  git add lib/features/auth/presentation/providers/auth_providers.dart lib/features/auth/presentation/providers/auth_providers.g.dart test/features/auth/presentation/providers/auth_providers_test.dart
  git commit -m "refactor: address review comments on role check providers"
  ```

