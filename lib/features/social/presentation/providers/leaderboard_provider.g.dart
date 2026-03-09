// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the LeaderboardRepository instance

@ProviderFor(leaderboardRepository)
final leaderboardRepositoryProvider = LeaderboardRepositoryProvider._();

/// Provides the LeaderboardRepository instance

final class LeaderboardRepositoryProvider
    extends
        $FunctionalProvider<
          LeaderboardRepository,
          LeaderboardRepository,
          LeaderboardRepository
        >
    with $Provider<LeaderboardRepository> {
  /// Provides the LeaderboardRepository instance
  LeaderboardRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaderboardRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaderboardRepositoryHash();

  @$internal
  @override
  $ProviderElement<LeaderboardRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LeaderboardRepository create(Ref ref) {
    return leaderboardRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeaderboardRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeaderboardRepository>(value),
    );
  }
}

String _$leaderboardRepositoryHash() =>
    r'3790361f3c08bec7fc8e7b1af36c9b30b135c7db';

/// Stream provider for club leaderboard
/// Returns empty stream if user is not authenticated

@ProviderFor(clubLeaderboard)
final clubLeaderboardProvider = ClubLeaderboardFamily._();

/// Stream provider for club leaderboard
/// Returns empty stream if user is not authenticated

final class ClubLeaderboardProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LeaderboardEntry>>,
          List<LeaderboardEntry>,
          Stream<List<LeaderboardEntry>>
        >
    with
        $FutureModifier<List<LeaderboardEntry>>,
        $StreamProvider<List<LeaderboardEntry>> {
  /// Stream provider for club leaderboard
  /// Returns empty stream if user is not authenticated
  ClubLeaderboardProvider._({
    required ClubLeaderboardFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clubLeaderboardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubLeaderboardHash();

  @override
  String toString() {
    return r'clubLeaderboardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<LeaderboardEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LeaderboardEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return clubLeaderboard(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubLeaderboardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubLeaderboardHash() => r'eee00455cc392fa18499e337ca77a238be58e7f3';

/// Stream provider for club leaderboard
/// Returns empty stream if user is not authenticated

final class ClubLeaderboardFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<LeaderboardEntry>>, String> {
  ClubLeaderboardFamily._()
    : super(
        retry: null,
        name: r'clubLeaderboardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream provider for club leaderboard
  /// Returns empty stream if user is not authenticated

  ClubLeaderboardProvider call(String clubId) =>
      ClubLeaderboardProvider._(argument: clubId, from: this);

  @override
  String toString() => r'clubLeaderboardProvider';
}

/// Stream provider for challenge leaderboard
/// Returns empty stream if user is not authenticated

@ProviderFor(challengeLeaderboard)
final challengeLeaderboardProvider = ChallengeLeaderboardFamily._();

/// Stream provider for challenge leaderboard
/// Returns empty stream if user is not authenticated

final class ChallengeLeaderboardProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LeaderboardEntry>>,
          List<LeaderboardEntry>,
          Stream<List<LeaderboardEntry>>
        >
    with
        $FutureModifier<List<LeaderboardEntry>>,
        $StreamProvider<List<LeaderboardEntry>> {
  /// Stream provider for challenge leaderboard
  /// Returns empty stream if user is not authenticated
  ChallengeLeaderboardProvider._({
    required ChallengeLeaderboardFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'challengeLeaderboardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$challengeLeaderboardHash();

  @override
  String toString() {
    return r'challengeLeaderboardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<LeaderboardEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LeaderboardEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return challengeLeaderboard(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeLeaderboardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$challengeLeaderboardHash() =>
    r'ad4aeb9601bbd922a9e6a5d76eaa1a5c67e518ee';

/// Stream provider for challenge leaderboard
/// Returns empty stream if user is not authenticated

final class ChallengeLeaderboardFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<LeaderboardEntry>>, String> {
  ChallengeLeaderboardFamily._()
    : super(
        retry: null,
        name: r'challengeLeaderboardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream provider for challenge leaderboard
  /// Returns empty stream if user is not authenticated

  ChallengeLeaderboardProvider call(String challengeId) =>
      ChallengeLeaderboardProvider._(argument: challengeId, from: this);

  @override
  String toString() => r'challengeLeaderboardProvider';
}
