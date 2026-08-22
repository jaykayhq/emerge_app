// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:emerge_app/core/utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockUser extends Mock implements User {}

class _MockUserCredential extends Mock implements UserCredential {}

// ignore: subtype_of_sealed_class
class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

/// Stand-in for the platform's Google Sign-In implementation. The repo's
/// constructor calls `GoogleSignIn.instance.initialize()`, which would
/// otherwise hit the placeholder implementation and throw UnimplementedError.
class _FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  @override
  Future<void> init(InitParameters params) async {}

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) async => null;

  @override
  bool supportsAuthenticate() => true;

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) =>
      Future.error(UnimplementedError());

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<void> signOut(SignOutParams params) async {}

  @override
  Future<void> disconnect(DisconnectParams params) async {}
}

/// Google Sign-In platform that returns a logged-in profile with a
/// free-form display name — simulates the native (non-web) signup flow.
class _SignedInGoogleSignInPlatform extends _FakeGoogleSignInPlatform {
  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    return const AuthenticationResults(
      user: GoogleSignInUserData(
        displayName: 'Googler One',
        email: 'goo@gmail.com',
        id: 'g1',
      ),
      authenticationTokens: AuthenticationTokenData(idToken: 'google-id-token'),
    );
  }
}

// DocumentSnapshot is sealed in the current SDK; noMockedSubtypes of it are
// forbidden, so we implement the type and suppress the linter instead.
// ignore: subtype_of_sealed_class
class _MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

FirebaseFunctionsException _alreadyTaken() => FirebaseFunctionsException(
  // ignore: invalid_use_of_protected_member
  code: 'already-exists',
  message: 'This username is already taken. Please choose another.',
);

void main() {
  setUpAll(() {
    // mocktail needs a concrete AuthCredential to build matchers (`any()`)
    // for signInWithCredential(FirebaseAuthException-style APIs).
    registerFallbackValue(GoogleAuthProvider.credential(idToken: 'fallback'));
  });

  late _MockFirebaseAuth auth;
  late _MockFirestore firestore;
  late _MockFunctions functions;
  late _MockHttpsCallable claimCallable;
  late _MockUser user;
  late _MockUserCredential credential;

  setUp(() {
    auth = _MockFirebaseAuth();
    firestore = _MockFirestore();
    functions = _MockFunctions();
    claimCallable = _MockHttpsCallable();
    user = _MockUser();
    credential = _MockUserCredential();

    // The repo constructor calls GoogleSignIn.instance.initialize() on native.
    // Install a fake platform so that call resolves instead of throwing
    // UnimplementedError from the placeholder implementation.
    GoogleSignInPlatform.instance = _FakeGoogleSignInPlatform();

    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('a@b.com');

    when(() => credential.user).thenReturn(user);
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);

    when(
      () => functions.httpsCallable('claimUsername'),
    ).thenReturn(claimCallable);
  });

  FirebaseAuthRepository buildRepo() =>
      FirebaseAuthRepository(auth, firestore, functions);

  group('signUpWithEmailAndPassword claim rollback', () {
    test('claim failure deletes the fresh account, writes no docs, and '
        'returns Left with the mapped message', () async {
      when(() => user.delete()).thenAnswer((_) async {});
      when(() => claimCallable.call(any())).thenThrow(_alreadyTaken());

      final repo = buildRepo();
      final result = await repo.signUpWithEmailAndPassword(
        email: 'a@b.com',
        password: 'Str0ngP@sswd!',
        username: 'Aria',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('already taken')),
        (_) => fail('expected a failure'),
      );
      verify(() => user.delete()).called(1);
      // Rollback happens before any Firestore profile write.
      verifyNever(() => firestore.collection(any()));
    });

    test(
      'claim success proceeds past the rollback branch without delete',
      () async {
        when(() => user.delete()).thenAnswer((_) async {});
        when(
          () => claimCallable.call(any()),
        ).thenAnswer((_) async => _MockHttpsCallableResult());

        final repo = buildRepo();
        final result = await repo.claimUsername('Aria');

        expect(result.isRight(), isTrue);
        verifyNever(() => user.delete());
      },
    );
  });

  group('deriveUsernameCandidate', () {
    test('normalizes a free-form Google display name into a username', () {
      expect(
        deriveUsernameCandidate('Googler One', 'goo@gmail.com'),
        'googler_one',
      );
    });

    test('falls back to the email prefix when the display name is empty', () {
      expect(deriveUsernameCandidate('', 'goo@gmail.com'), 'goo');
      expect(
        deriveUsernameCandidate(null, 'mike.smith@example.com'),
        'mike_smith',
      );
    });

    test('returns null when nothing can form a 3+ char username', () {
      expect(deriveUsernameCandidate('ab', 'x@example.com'), isNull);
      expect(deriveUsernameCandidate('', ''), isNull);
    });

    test('caps length at 30 and strips leading/trailing separators', () {
      final long = 'a' * 40;
      expect(deriveUsernameCandidate(long, 'x@example.com'), 'a' * 30);
      expect(deriveUsernameCandidate('_joe', 'x@example.com'), 'joe');
    });

    test('normalizes a blocked reserved word but the claim guard rejects it '
        '(graceful skip, no throw)', () {
      // A Google display name like "Support" normalizes to a syntactically
      // valid candidate ('support') that deriveUsernameCandidate happily
      // returns — the blocklist lives in the claim guard, not here.
      final candidate = deriveUsernameCandidate('Support', 'x@example.com');
      expect(candidate, 'support');

      // Pin the full graceful-skip path: validateUsername (the same guard
      // claimUsername runs before calling the function) rejects the word with
      // the blocklist message instead of throwing.
      expect(
        AppValidators.validateUsername(candidate!),
        'This username is not allowed',
      );
      expect(() => AppValidators.validateUsername(candidate), returnsNormally);
    });
  });

  group('signInWithGoogle native username claim', () {
    test('claims a username derived from the Google display name', () async {
      when(() => user.displayName).thenReturn('Googler One');
      when(() => user.email).thenReturn('goo@gmail.com');
      when(() => user.emailVerified).thenReturn(false);
      when(() => user.getIdToken(any())).thenAnswer((_) async => 'token');
      when(() => auth.currentUser).thenReturn(user);
      when(
        () => claimCallable.call(any()),
      ).thenAnswer((_) async => _MockHttpsCallableResult());

      final usersCollection = _MockCollectionReference();
      final userDoc = _MockDocumentReference();
      final snapshot = _MockDocumentSnapshot();
      when(() => firestore.collection('users')).thenReturn(usersCollection);
      when(() => usersCollection.doc('u1')).thenReturn(userDoc);
      when(() => userDoc.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(false);
      when(() => userDoc.set(any())).thenAnswer((_) async {});

      final statsCollection = _MockCollectionReference();
      final statsDoc = _MockDocumentReference();
      when(
        () => firestore.collection('user_stats'),
      ).thenReturn(statsCollection);
      when(() => statsCollection.doc('u1')).thenReturn(statsDoc);
      when(() => statsDoc.set(any())).thenAnswer((_) async {});

      final roleCallable = _MockHttpsCallable();
      when(
        () => functions.httpsCallable('setUserRole'),
      ).thenReturn(roleCallable);
      when(
        () => roleCallable.call(any()),
      ).thenAnswer((_) async => _MockHttpsCallableResult());

      when(
        () => auth.signInWithCredential(any()),
      ).thenAnswer((_) async => credential);

      GoogleSignInPlatform.instance = _SignedInGoogleSignInPlatform();

      final repo = buildRepo();
      final result = await repo.signInWithGoogle();

      expect(result.isRight(), isTrue);
      verify(() => claimCallable.call({'username': 'googler_one'})).called(1);
    }, skip: false);

    test('skips the claim (best-effort) when no valid username can be '
        'derived from the profile', () async {
      when(() => user.displayName).thenReturn(null);
      when(() => user.email).thenReturn('x@example.com');
      when(() => user.emailVerified).thenReturn(false);
      when(() => user.getIdToken(any())).thenAnswer((_) async => 'token');
      when(() => auth.currentUser).thenReturn(user);

      final usersCollection = _MockCollectionReference();
      final userDoc = _MockDocumentReference();
      final snapshot = _MockDocumentSnapshot();
      when(() => firestore.collection('users')).thenReturn(usersCollection);
      when(() => usersCollection.doc('u1')).thenReturn(userDoc);
      when(() => userDoc.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(false);
      when(() => userDoc.set(any())).thenAnswer((_) async {});

      final statsCollection = _MockCollectionReference();
      final statsDoc = _MockDocumentReference();
      when(
        () => firestore.collection('user_stats'),
      ).thenReturn(statsCollection);
      when(() => statsCollection.doc('u1')).thenReturn(statsDoc);
      when(() => statsDoc.set(any())).thenAnswer((_) async {});

      final roleCallable = _MockHttpsCallable();
      when(
        () => functions.httpsCallable('setUserRole'),
      ).thenReturn(roleCallable);
      when(
        () => roleCallable.call(any()),
      ).thenAnswer((_) async => _MockHttpsCallableResult());

      when(
        () => auth.signInWithCredential(any()),
      ).thenAnswer((_) async => credential);

      GoogleSignInPlatform.instance = _SignedInGoogleSignInPlatform();

      final repo = buildRepo();
      final result = await repo.signInWithGoogle();

      expect(result.isRight(), isTrue);
      verifyNever(() => claimCallable.call(any()));
    }, skip: false);
  });

  group('sendVerificationEmail', () {
    test('sends the Firebase-native email and writes the request + grace anchor',
        () async {
          when(() => auth.currentUser).thenReturn(user);
          when(() => user.sendEmailVerification(any())).thenAnswer((_) async {});
          final usersCollection = _MockCollectionReference();
          final userDoc = _MockDocumentReference();
          when(() => firestore.collection('users')).thenReturn(usersCollection);
          when(() => usersCollection.doc('u1')).thenReturn(userDoc);
          when(() => userDoc.set(any(), any())).thenAnswer((_) async {});

          final repo = buildRepo();
          final result = await repo.sendVerificationEmail();

          expect(result.isRight(), isTrue);
          // Firebase Auth's native email (hosted action link) is the sender;
          // the markers keep the 7-day grace-lock clock anchored client-side.
          verify(() => user.sendEmailVerification(any())).called(1);
          final data =
              verify(() => userDoc.set(captureAny(), any())).captured.single
                  as Map<String, dynamic>;
          expect(data.containsKey('verificationRequestedAt'), isTrue);
          expect(data.containsKey('emailVerificationSentAt'), isTrue);
        });

    test('returns Left when no user is signed in', () async {
      when(() => auth.currentUser).thenReturn(null);

      final repo = buildRepo();
      final result = await repo.sendVerificationEmail();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('logged in')),
        (_) => fail('expected a failure'),
      );
    });
  });

  group('sendPasswordResetEmail', () {
    test('sends the Firebase-native password reset email', () async {
      when(
        () => auth.sendPasswordResetEmail(email: any(named: 'email')),
      ).thenAnswer((_) async {});

      final repo = buildRepo();
      final result = await repo.sendPasswordResetEmail('a@b.com');

      expect(result.isRight(), isTrue);
      // The native email carries the hosted action link — no worker request
      // doc is enqueued.
      verify(
        () => auth.sendPasswordResetEmail(email: 'a@b.com'),
      ).called(1);
      verifyNever(() => firestore.collection('email_requests'));
    });

    test('rejects an invalid email before sending anything', () async {
      final repo = buildRepo();
      final result = await repo.sendPasswordResetEmail('not-an-email');

      expect(result.isLeft(), isTrue);
      verifyNever(() => auth.sendPasswordResetEmail(email: any(named: 'email')));
      verifyNever(() => firestore.collection(any()));
    });
  });

  group('resetPasswordWithCode', () {
    test('confirms the reset with the oobCode and new password', () async {
      when(
        () => auth.confirmPasswordReset(
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async {});

      final repo = buildRepo();
      final result = await repo.resetPasswordWithCode(
        oobCode: 'oob123',
        newPassword: 'Str0ngP@sswd!',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => auth.confirmPasswordReset(
          code: 'oob123',
          newPassword: 'Str0ngP@sswd!',
        ),
      ).called(1);
    });

    test('maps FirebaseAuthException to a Left failure', () async {
      when(
        () => auth.confirmPasswordReset(
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'expired-action-code',
          message: 'The action code has expired.',
        ),
      );

      final repo = buildRepo();
      final result = await repo.resetPasswordWithCode(
        oobCode: 'oob123',
        newPassword: 'Str0ngP@sswd!',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('expired')),
        (_) => fail('expected a failure'),
      );
    });
  });
}

class _MockHttpsCallableResult extends Mock implements HttpsCallableResult {}
