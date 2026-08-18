// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'next_identity_vote_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [NextIdentityVoteService]

@ProviderFor(nextIdentityVoteService)
final nextIdentityVoteServiceProvider = NextIdentityVoteServiceProvider._();

/// Provider for [NextIdentityVoteService]

final class NextIdentityVoteServiceProvider
    extends
        $FunctionalProvider<
          NextIdentityVoteService,
          NextIdentityVoteService,
          NextIdentityVoteService
        >
    with $Provider<NextIdentityVoteService> {
  /// Provider for [NextIdentityVoteService]
  NextIdentityVoteServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nextIdentityVoteServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nextIdentityVoteServiceHash();

  @$internal
  @override
  $ProviderElement<NextIdentityVoteService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NextIdentityVoteService create(Ref ref) {
    return nextIdentityVoteService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NextIdentityVoteService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NextIdentityVoteService>(value),
    );
  }
}

String _$nextIdentityVoteServiceHash() =>
    r'0dfaec8ba27158324f837319c1bc421fea737236';

/// Computes the active [NextIdentityVote] by watching [habitsProvider]
/// and [worldEntropyStreamProvider].

@ProviderFor(nextIdentityVote)
final nextIdentityVoteProvider = NextIdentityVoteProvider._();

/// Computes the active [NextIdentityVote] by watching [habitsProvider]
/// and [worldEntropyStreamProvider].

final class NextIdentityVoteProvider
    extends
        $FunctionalProvider<
          NextIdentityVote,
          NextIdentityVote,
          NextIdentityVote
        >
    with $Provider<NextIdentityVote> {
  /// Computes the active [NextIdentityVote] by watching [habitsProvider]
  /// and [worldEntropyStreamProvider].
  NextIdentityVoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nextIdentityVoteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nextIdentityVoteHash();

  @$internal
  @override
  $ProviderElement<NextIdentityVote> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NextIdentityVote create(Ref ref) {
    return nextIdentityVote(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NextIdentityVote value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NextIdentityVote>(value),
    );
  }
}

String _$nextIdentityVoteHash() => r'366a623959274c575c20e7f3def849a4fefc8244';
