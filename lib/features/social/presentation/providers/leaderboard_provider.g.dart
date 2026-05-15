// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(leaderboardRepository)
final leaderboardRepositoryProvider = LeaderboardRepositoryProvider._();

final class LeaderboardRepositoryProvider
    extends
        $FunctionalProvider<
          LeaderboardRepository,
          LeaderboardRepository,
          LeaderboardRepository
        >
    with $Provider<LeaderboardRepository> {
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
    r'4c7453db12a2d228b59a8c63b8f9fa39c0206231';

@ProviderFor(clubLeaderboard)
final clubLeaderboardProvider = ClubLeaderboardFamily._();

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

String _$clubLeaderboardHash() => r'b70916aa5c24310a374867e3050fa7be1a5109b3';

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

  ClubLeaderboardProvider call(String clubId) =>
      ClubLeaderboardProvider._(argument: clubId, from: this);

  @override
  String toString() => r'clubLeaderboardProvider';
}

@ProviderFor(challengeLeaderboard)
final challengeLeaderboardProvider = ChallengeLeaderboardFamily._();

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
    r'9518ab4945c2e2b03cf55a32dbcda451a0658762';

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

  ChallengeLeaderboardProvider call(String challengeId) =>
      ChallengeLeaderboardProvider._(argument: challengeId, from: this);

  @override
  String toString() => r'challengeLeaderboardProvider';
}
