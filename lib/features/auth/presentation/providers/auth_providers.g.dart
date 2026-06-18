// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$authRepositoryHash() => r'a327c9350b1516c9c5ba1ecd1e6a5f2b0497decb';

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
        isAutoDispose: true,
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

String _$signOutHash() => r'4b280108d412d729ffb848f22e53cee3550fc524';

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
