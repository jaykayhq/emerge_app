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

String _$authRepositoryHash() => r'924e0a5a942fe03f1f24a306b12cf5f4051d6976';

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

String _$signInHash() => r'9abaebc4a7eab1020b4aab3dfd10389f2cb08f45';

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
