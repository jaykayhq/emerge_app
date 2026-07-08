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
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
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
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'c9b315997d4620b75f971a029620ab310c5b3296';

@ProviderFor(userStatsDao)
final userStatsDaoProvider = UserStatsDaoProvider._();

final class UserStatsDaoProvider
    extends $FunctionalProvider<UserStatsDao, UserStatsDao, UserStatsDao>
    with $Provider<UserStatsDao> {
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
  $ProviderElement<UserStatsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserStatsDao create(Ref ref) {
    return userStatsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserStatsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserStatsDao>(value),
    );
  }
}

String _$userStatsDaoHash() => r'4266e0c4f2a46d1511d5205cf266a5de8bcb03fa';

@ProviderFor(habitsDao)
final habitsDaoProvider = HabitsDaoProvider._();

final class HabitsDaoProvider
    extends $FunctionalProvider<HabitsDao, HabitsDao, HabitsDao>
    with $Provider<HabitsDao> {
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
  $ProviderElement<HabitsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HabitsDao create(Ref ref) {
    return habitsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitsDao>(value),
    );
  }
}

String _$habitsDaoHash() => r'3b4543458058b682a91ca62c33f12482458761f6';

@ProviderFor(habitCompletionsDao)
final habitCompletionsDaoProvider = HabitCompletionsDaoProvider._();

final class HabitCompletionsDaoProvider
    extends
        $FunctionalProvider<
          HabitCompletionsDao,
          HabitCompletionsDao,
          HabitCompletionsDao
        >
    with $Provider<HabitCompletionsDao> {
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
  $ProviderElement<HabitCompletionsDao> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HabitCompletionsDao create(Ref ref) {
    return habitCompletionsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitCompletionsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitCompletionsDao>(value),
    );
  }
}

String _$habitCompletionsDaoHash() =>
    r'15811473fbe8456f88614df38e45b3b7ea3578d6';

@ProviderFor(challengeProgressDao)
final challengeProgressDaoProvider = ChallengeProgressDaoProvider._();

final class ChallengeProgressDaoProvider
    extends
        $FunctionalProvider<
          ChallengeProgressDao,
          ChallengeProgressDao,
          ChallengeProgressDao
        >
    with $Provider<ChallengeProgressDao> {
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
  $ProviderElement<ChallengeProgressDao> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChallengeProgressDao create(Ref ref) {
    return challengeProgressDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChallengeProgressDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChallengeProgressDao>(value),
    );
  }
}

String _$challengeProgressDaoHash() =>
    r'95f784919164c4964c9659d8f12acc8947f29e73';

@ProviderFor(tribeStatsDao)
final tribeStatsDaoProvider = TribeStatsDaoProvider._();

final class TribeStatsDaoProvider
    extends $FunctionalProvider<TribeStatsDao, TribeStatsDao, TribeStatsDao>
    with $Provider<TribeStatsDao> {
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
  $ProviderElement<TribeStatsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TribeStatsDao create(Ref ref) {
    return tribeStatsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TribeStatsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TribeStatsDao>(value),
    );
  }
}

String _$tribeStatsDaoHash() => r'9b037be7882a8e95397b1d54445b98f1fbcc870f';

@ProviderFor(leaderboardEntriesDao)
final leaderboardEntriesDaoProvider = LeaderboardEntriesDaoProvider._();

final class LeaderboardEntriesDaoProvider
    extends
        $FunctionalProvider<
          LeaderboardEntriesDao,
          LeaderboardEntriesDao,
          LeaderboardEntriesDao
        >
    with $Provider<LeaderboardEntriesDao> {
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
  $ProviderElement<LeaderboardEntriesDao> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LeaderboardEntriesDao create(Ref ref) {
    return leaderboardEntriesDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeaderboardEntriesDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeaderboardEntriesDao>(value),
    );
  }
}

String _$leaderboardEntriesDaoHash() =>
    r'749b485219bc1d452d30f40c595e0852fe37717c';

@ProviderFor(mutationQueueDao)
final mutationQueueDaoProvider = MutationQueueDaoProvider._();

final class MutationQueueDaoProvider
    extends
        $FunctionalProvider<
          MutationQueueDao,
          MutationQueueDao,
          MutationQueueDao
        >
    with $Provider<MutationQueueDao> {
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
  $ProviderElement<MutationQueueDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MutationQueueDao create(Ref ref) {
    return mutationQueueDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MutationQueueDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MutationQueueDao>(value),
    );
  }
}

String _$mutationQueueDaoHash() => r'd874d48f2ee5a6d9f55b7af4d7ff3d79dc246d81';

@ProviderFor(tribeActivityDao)
final tribeActivityDaoProvider = TribeActivityDaoProvider._();

final class TribeActivityDaoProvider
    extends
        $FunctionalProvider<
          TribeActivityDao,
          TribeActivityDao,
          TribeActivityDao
        >
    with $Provider<TribeActivityDao> {
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
  $ProviderElement<TribeActivityDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TribeActivityDao create(Ref ref) {
    return tribeActivityDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TribeActivityDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TribeActivityDao>(value),
    );
  }
}

String _$tribeActivityDaoHash() => r'de601102a250401a43f7f6d392941bf457d5c6ce';

@ProviderFor(narratorNotesDao)
final narratorNotesDaoProvider = NarratorNotesDaoProvider._();

final class NarratorNotesDaoProvider
    extends
        $FunctionalProvider<
          NarratorNotesDao,
          NarratorNotesDao,
          NarratorNotesDao
        >
    with $Provider<NarratorNotesDao> {
  NarratorNotesDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'narratorNotesDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$narratorNotesDaoHash();

  @$internal
  @override
  $ProviderElement<NarratorNotesDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NarratorNotesDao create(Ref ref) {
    return narratorNotesDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NarratorNotesDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NarratorNotesDao>(value),
    );
  }
}

String _$narratorNotesDaoHash() => r'076d0026ab8fc2ab6824c63e4ffed8f17512ebb9';

@ProviderFor(pulseFeedDao)
final pulseFeedDaoProvider = PulseFeedDaoProvider._();

final class PulseFeedDaoProvider
    extends $FunctionalProvider<PulseFeedDao, PulseFeedDao, PulseFeedDao>
    with $Provider<PulseFeedDao> {
  PulseFeedDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pulseFeedDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pulseFeedDaoHash();

  @$internal
  @override
  $ProviderElement<PulseFeedDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PulseFeedDao create(Ref ref) {
    return pulseFeedDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PulseFeedDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PulseFeedDao>(value),
    );
  }
}

String _$pulseFeedDaoHash() => r'599b0b77b9efba88f371665864f3d63462de60bd';
