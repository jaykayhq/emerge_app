// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase?, AppDatabase?, AppDatabase?>
    with $Provider<AppDatabase?> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase? create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase?>(value),
    );
  }
}

String _$appDatabaseHash() => r'c2e6efbf9a346984023daa65533362d6e28b830f';

@ProviderFor(userStatsDao)
final userStatsDaoProvider = UserStatsDaoProvider._();

final class UserStatsDaoProvider
    extends $FunctionalProvider<UserStatsDao?, UserStatsDao?, UserStatsDao?>
    with $Provider<UserStatsDao?> {
  UserStatsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStatsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStatsDaoHash();

  @$internal
  @override
  $ProviderElement<UserStatsDao?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserStatsDao? create(Ref ref) {
    return userStatsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserStatsDao? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserStatsDao?>(value),
    );
  }
}

String _$userStatsDaoHash() => r'f5d9d1ae8b751517d61276509680a2e3454a426b';

@ProviderFor(habitsDao)
final habitsDaoProvider = HabitsDaoProvider._();

final class HabitsDaoProvider
    extends $FunctionalProvider<HabitsDao?, HabitsDao?, HabitsDao?>
    with $Provider<HabitsDao?> {
  HabitsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitsDaoHash();

  @$internal
  @override
  $ProviderElement<HabitsDao?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HabitsDao? create(Ref ref) {
    return habitsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitsDao? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitsDao?>(value),
    );
  }
}

String _$habitsDaoHash() => r'5b7a8a28a5aea9f74df9ec26f92c87173be9b524';

@ProviderFor(habitCompletionsDao)
final habitCompletionsDaoProvider = HabitCompletionsDaoProvider._();

final class HabitCompletionsDaoProvider
    extends
        $FunctionalProvider<
          HabitCompletionsDao?,
          HabitCompletionsDao?,
          HabitCompletionsDao?
        >
    with $Provider<HabitCompletionsDao?> {
  HabitCompletionsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitCompletionsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitCompletionsDaoHash();

  @$internal
  @override
  $ProviderElement<HabitCompletionsDao?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HabitCompletionsDao? create(Ref ref) {
    return habitCompletionsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitCompletionsDao? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitCompletionsDao?>(value),
    );
  }
}

String _$habitCompletionsDaoHash() =>
    r'bc49e9c21bb9e901537c0638f23c8904f19a754a';

@ProviderFor(challengeProgressDao)
final challengeProgressDaoProvider = ChallengeProgressDaoProvider._();

final class ChallengeProgressDaoProvider
    extends
        $FunctionalProvider<
          ChallengeProgressDao?,
          ChallengeProgressDao?,
          ChallengeProgressDao?
        >
    with $Provider<ChallengeProgressDao?> {
  ChallengeProgressDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'challengeProgressDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$challengeProgressDaoHash();

  @$internal
  @override
  $ProviderElement<ChallengeProgressDao?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChallengeProgressDao? create(Ref ref) {
    return challengeProgressDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChallengeProgressDao? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChallengeProgressDao?>(value),
    );
  }
}

String _$challengeProgressDaoHash() =>
    r'f81a759b299f25cac35ce5b4a61c9195581b9e4a';

@ProviderFor(tribeStatsDao)
final tribeStatsDaoProvider = TribeStatsDaoProvider._();

final class TribeStatsDaoProvider
    extends $FunctionalProvider<TribeStatsDao?, TribeStatsDao?, TribeStatsDao?>
    with $Provider<TribeStatsDao?> {
  TribeStatsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tribeStatsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tribeStatsDaoHash();

  @$internal
  @override
  $ProviderElement<TribeStatsDao?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TribeStatsDao? create(Ref ref) {
    return tribeStatsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TribeStatsDao? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TribeStatsDao?>(value),
    );
  }
}

String _$tribeStatsDaoHash() => r'1c520e6a687f5df1be943e20e0327fc1780c8a52';

@ProviderFor(leaderboardEntriesDao)
final leaderboardEntriesDaoProvider = LeaderboardEntriesDaoProvider._();

final class LeaderboardEntriesDaoProvider
    extends
        $FunctionalProvider<
          LeaderboardEntriesDao?,
          LeaderboardEntriesDao?,
          LeaderboardEntriesDao?
        >
    with $Provider<LeaderboardEntriesDao?> {
  LeaderboardEntriesDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaderboardEntriesDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaderboardEntriesDaoHash();

  @$internal
  @override
  $ProviderElement<LeaderboardEntriesDao?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LeaderboardEntriesDao? create(Ref ref) {
    return leaderboardEntriesDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeaderboardEntriesDao? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeaderboardEntriesDao?>(value),
    );
  }
}

String _$leaderboardEntriesDaoHash() =>
    r'569b62f41a44fff65d76e1993b24dda9aeb95c83';

@ProviderFor(blueprintsDao)
final blueprintsDaoProvider = BlueprintsDaoProvider._();

final class BlueprintsDaoProvider
    extends $FunctionalProvider<BlueprintsDao?, BlueprintsDao?, BlueprintsDao?>
    with $Provider<BlueprintsDao?> {
  BlueprintsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blueprintsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blueprintsDaoHash();

  @$internal
  @override
  $ProviderElement<BlueprintsDao?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BlueprintsDao? create(Ref ref) {
    return blueprintsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BlueprintsDao? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BlueprintsDao?>(value),
    );
  }
}

String _$blueprintsDaoHash() => r'cee1fe0d2ea099c185c810abd0b45cbca7b2c24e';

@ProviderFor(mutationQueueDao)
final mutationQueueDaoProvider = MutationQueueDaoProvider._();

final class MutationQueueDaoProvider
    extends
        $FunctionalProvider<
          MutationQueueDao?,
          MutationQueueDao?,
          MutationQueueDao?
        >
    with $Provider<MutationQueueDao?> {
  MutationQueueDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mutationQueueDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mutationQueueDaoHash();

  @$internal
  @override
  $ProviderElement<MutationQueueDao?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MutationQueueDao? create(Ref ref) {
    return mutationQueueDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MutationQueueDao? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MutationQueueDao?>(value),
    );
  }
}

String _$mutationQueueDaoHash() => r'4567ca4119e7538e8a20bb49fd2c47b1628f5511';

@ProviderFor(tribeActivityDao)
final tribeActivityDaoProvider = TribeActivityDaoProvider._();

final class TribeActivityDaoProvider
    extends
        $FunctionalProvider<
          TribeActivityDao?,
          TribeActivityDao?,
          TribeActivityDao?
        >
    with $Provider<TribeActivityDao?> {
  TribeActivityDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tribeActivityDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tribeActivityDaoHash();

  @$internal
  @override
  $ProviderElement<TribeActivityDao?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TribeActivityDao? create(Ref ref) {
    return tribeActivityDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TribeActivityDao? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TribeActivityDao?>(value),
    );
  }
}

String _$tribeActivityDaoHash() => r'712a053b5ad7cb659ad2e86bdebf38fd3b4d9e81';
