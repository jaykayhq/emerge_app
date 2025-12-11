// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authRepositoryHash() => r'c60848f66a991b090c9366b7047f1e7c9b9b0d11';

/// See also [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = Provider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = ProviderRef<AuthRepository>;
String _$authStateChangesHash() => r'8e4ae7b18c2bb57c81d66378c876cd43eded4b30';

/// See also [authStateChanges].
@ProviderFor(authStateChanges)
final authStateChangesProvider = StreamProvider<AuthUser>.internal(
  authStateChanges,
  name: r'authStateChangesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateChangesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateChangesRef = StreamProviderRef<AuthUser>;
String _$signInHash() => r'9abaebc4a7eab1020b4aab3dfd10389f2cb08f45';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [signIn].
@ProviderFor(signIn)
const signInProvider = SignInFamily();

/// See also [signIn].
class SignInFamily extends Family<AsyncValue<void>> {
  /// See also [signIn].
  const SignInFamily();

  /// See also [signIn].
  SignInProvider call(String email, String password) {
    return SignInProvider(email, password);
  }

  @override
  SignInProvider getProviderOverride(covariant SignInProvider provider) {
    return call(provider.email, provider.password);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'signInProvider';
}

/// See also [signIn].
class SignInProvider extends AutoDisposeFutureProvider<void> {
  /// See also [signIn].
  SignInProvider(String email, String password)
    : this._internal(
        (ref) => signIn(ref as SignInRef, email, password),
        from: signInProvider,
        name: r'signInProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$signInHash,
        dependencies: SignInFamily._dependencies,
        allTransitiveDependencies: SignInFamily._allTransitiveDependencies,
        email: email,
        password: password,
      );

  SignInProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.email,
    required this.password,
  }) : super.internal();

  final String email;
  final String password;

  @override
  Override overrideWith(FutureOr<void> Function(SignInRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: SignInProvider._internal(
        (ref) => create(ref as SignInRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        email: email,
        password: password,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _SignInProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SignInProvider &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, email.hashCode);
    hash = _SystemHash.combine(hash, password.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SignInRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `email` of this provider.
  String get email;

  /// The parameter `password` of this provider.
  String get password;
}

class _SignInProviderElement extends AutoDisposeFutureProviderElement<void>
    with SignInRef {
  _SignInProviderElement(super.provider);

  @override
  String get email => (origin as SignInProvider).email;
  @override
  String get password => (origin as SignInProvider).password;
}

String _$signOutHash() => r'4b280108d412d729ffb848f22e53cee3550fc524';

/// See also [signOut].
@ProviderFor(signOut)
final signOutProvider = AutoDisposeFutureProvider<void>.internal(
  signOut,
  name: r'signOutProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$signOutHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SignOutRef = AutoDisposeFutureProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
