// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/features/auth/data/repositories/firebase_auth_repository.dart';
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

FirebaseFunctionsException _alreadyTaken() => FirebaseFunctionsException(
  // ignore: invalid_use_of_protected_member
  code: 'already-exists',
  message: 'This username is already taken. Please choose another.',
);

void main() {
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

    when(() => functions.httpsCallable('claimUsername'))
        .thenReturn(claimCallable);
  });

  FirebaseAuthRepository buildRepo() =>
      FirebaseAuthRepository(auth, firestore, functions);

  group('signUpWithEmailAndPassword claim rollback', () {
    test(
      'claim failure deletes the fresh account, writes no docs, and '
      'returns Left with the mapped message',
      () async {
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
      },
    );

    test('claim success proceeds past the rollback branch without delete',
        () async {
      when(() => user.delete()).thenAnswer((_) async {});
      when(() => claimCallable.call(any())).thenAnswer(
        (_) async => _MockHttpsCallableResult(),
      );

      final repo = buildRepo();
      final result = await repo.claimUsername('Aria');

      expect(result.isRight(), isTrue);
      verifyNever(() => user.delete());
    });
  });

  group('sendVerificationEmail', () {
    test('sends the native verification email via the current user',
        () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.sendEmailVerification()).thenAnswer((_) async {});

      final repo = buildRepo();
      final result = await repo.sendVerificationEmail();

      expect(result.isRight(), isTrue);
      verify(() => user.sendEmailVerification()).called(1);
    });

    test('mirrors emailVerificationSentAt so the grace-lock job can find it',
        () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.sendEmailVerification()).thenAnswer((_) async {});
      final usersCollection = _MockCollectionReference();
      final userDoc = _MockDocumentReference();
      when(() => firestore.collection('users')).thenReturn(usersCollection);
      when(() => usersCollection.doc('u1')).thenReturn(userDoc);
      when(() => userDoc.set(any(), any())).thenAnswer((_) async {});

      final repo = buildRepo();
      final result = await repo.sendVerificationEmail();

      expect(result.isRight(), isTrue);
      final data = verify(() => userDoc.set(captureAny(), any()))
          .captured
          .single as Map<String, dynamic>;
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
}

class _MockHttpsCallableResult extends Mock implements HttpsCallableResult {}
