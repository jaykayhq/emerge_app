// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(firebaseAuth)
final firebaseAuthProvider = FirebaseAuthProvider._();

final class FirebaseAuthProvider
    extends
        $FunctionalProvider<
          firebase_auth.FirebaseAuth,
          firebase_auth.FirebaseAuth,
          firebase_auth.FirebaseAuth
        >
    with $Provider<firebase_auth.FirebaseAuth> {
  FirebaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<firebase_auth.FirebaseAuth> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  firebase_auth.FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(firebase_auth.FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<firebase_auth.FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'dffd78b4e77d56a1066f36e3d8d40a004d636084';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'2f55a520bde3835945366f53d9c10b838e00c188';

@ProviderFor(authStateChanges)
final authStateChangesProvider = AuthStateChangesProvider._();

final class AuthStateChangesProvider
    extends
        $FunctionalProvider<AsyncValue<AuthUser>, AuthUser, Stream<AuthUser>>
    with $FutureModifier<AuthUser>, $StreamProvider<AuthUser> {
  AuthStateChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateChangesHash();

  @$internal
  @override
  $StreamProviderElement<AuthUser> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthUser> create(Ref ref) {
    return authStateChanges(ref);
  }
}

String _$authStateChangesHash() => r'8e4ae7b18c2bb57c81d66378c876cd43eded4b30';

@ProviderFor(signIn)
final signInProvider = SignInFamily._();

final class SignInProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SignInProvider._({
    required SignInFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'signInProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signInHash();

  @override
  String toString() {
    return r'signInProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (String, String);
    return signIn(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SignInProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signInHash() => r'7a832775e884281049cc17dae4ee120e390754c9';

final class SignInFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, (String, String)> {
  SignInFamily._()
    : super(
        retry: null,
        name: r'signInProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SignInProvider call(String email, String password) =>
      SignInProvider._(argument: (email, password), from: this);

  @override
  String toString() => r'signInProvider';
}

@ProviderFor(signOut)
final signOutProvider = SignOutProvider._();

final class SignOutProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SignOutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signOutProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signOutHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return signOut(ref);
  }
}

String _$signOutHash() => r'6840d641d6cee42f9727d4232b28ca92351e1fe7';

@ProviderFor(firestore)
final firestoreProvider = FirestoreProvider._();

final class FirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  FirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firestoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firestoreHash() => r'a56abe42f3fb3ee8bfee4e56b46a7bf8561bdc93';

@ProviderFor(isNormalUser)
final isNormalUserProvider = IsNormalUserFamily._();

final class IsNormalUserProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsNormalUserProvider._({
    required IsNormalUserFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isNormalUserProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isNormalUserHash();

  @override
  String toString() {
    return r'isNormalUserProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isNormalUser(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsNormalUserProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isNormalUserHash() => r'0185c240387854155815805c6957ddb4c1691ded';

final class IsNormalUserFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsNormalUserFamily._()
    : super(
        retry: null,
        name: r'isNormalUserProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsNormalUserProvider call(String uid) =>
      IsNormalUserProvider._(argument: uid, from: this);

  @override
  String toString() => r'isNormalUserProvider';
}

@ProviderFor(isCreator)
final isCreatorProvider = IsCreatorFamily._();

final class IsCreatorProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsCreatorProvider._({
    required IsCreatorFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isCreatorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isCreatorHash();

  @override
  String toString() {
    return r'isCreatorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isCreator(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsCreatorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isCreatorHash() => r'ad0121ac1010146e8857752fbece3040faf069e2';

final class IsCreatorFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsCreatorFamily._()
    : super(
        retry: null,
        name: r'isCreatorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsCreatorProvider call(String uid) =>
      IsCreatorProvider._(argument: uid, from: this);

  @override
  String toString() => r'isCreatorProvider';
}

@ProviderFor(isCurrentNormalUser)
final isCurrentNormalUserProvider = IsCurrentNormalUserProvider._();

final class IsCurrentNormalUserProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsCurrentNormalUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isCurrentNormalUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isCurrentNormalUserHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isCurrentNormalUser(ref);
  }
}

String _$isCurrentNormalUserHash() =>
    r'ede53b9213fc56cd4780cf55a7307546e3df256b';

@ProviderFor(isCurrentCreator)
final isCurrentCreatorProvider = IsCurrentCreatorProvider._();

final class IsCurrentCreatorProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsCurrentCreatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isCurrentCreatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isCurrentCreatorHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isCurrentCreator(ref);
  }
}

String _$isCurrentCreatorHash() => r'17b72a3bee3494537ba60cad6eefe0f2edc071bd';

@ProviderFor(signUpCreator)
final signUpCreatorProvider = SignUpCreatorFamily._();

final class SignUpCreatorProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SignUpCreatorProvider._({
    required SignUpCreatorFamily super.from,
    required (String, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'signUpCreatorProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signUpCreatorHash();

  @override
  String toString() {
    return r'signUpCreatorProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (String, String, String);
    return signUpCreator(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is SignUpCreatorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signUpCreatorHash() => r'ea8eb2c47f0090fa7b2defcbb4751dab5f07bda8';

final class SignUpCreatorFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, (String, String, String)> {
  SignUpCreatorFamily._()
    : super(
        retry: null,
        name: r'signUpCreatorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  SignUpCreatorProvider call(String email, String password, String username) =>
      SignUpCreatorProvider._(
        argument: (email, password, username),
        from: this,
      );

  @override
  String toString() => r'signUpCreatorProvider';
}

@ProviderFor(signUpCreatorWithGoogle)
final signUpCreatorWithGoogleProvider = SignUpCreatorWithGoogleProvider._();

final class SignUpCreatorWithGoogleProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SignUpCreatorWithGoogleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpCreatorWithGoogleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpCreatorWithGoogleHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return signUpCreatorWithGoogle(ref);
  }
}

String _$signUpCreatorWithGoogleHash() =>
    r'e810679a2502ffabb1116ed9169b8e6ea6dcbdc6';
