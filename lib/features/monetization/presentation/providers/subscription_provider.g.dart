// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$monetizationRepositoryHash() =>
    r'f79b9a3db446c65f59a8406009b481c1743b0d7e';

/// See also [monetizationRepository].
@ProviderFor(monetizationRepository)
final monetizationRepositoryProvider =
    Provider<MonetizationRepository>.internal(
      monetizationRepository,
      name: r'monetizationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$monetizationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MonetizationRepositoryRef = ProviderRef<MonetizationRepository>;
String _$isPremiumHash() => r'c143dca94f3104dbd2700d1fed4bcbcff369f78d';

/// See also [IsPremium].
@ProviderFor(IsPremium)
final isPremiumProvider = AsyncNotifierProvider<IsPremium, bool>.internal(
  IsPremium.new,
  name: r'isPremiumProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isPremiumHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$IsPremium = AsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
