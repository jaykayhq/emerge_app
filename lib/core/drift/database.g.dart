// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UserStatsTableTable extends UserStatsTable
    with TableInfo<$UserStatsTableTable, UserStatsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserStatsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalXpMeta = const VerificationMeta(
    'totalXp',
  );
  @override
  late final GeneratedColumn<int> totalXp = GeneratedColumn<int>(
    'total_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _streakMeta = const VerificationMeta('streak');
  @override
  late final GeneratedColumn<int> streak = GeneratedColumn<int>(
    'streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _strengthXpMeta = const VerificationMeta(
    'strengthXp',
  );
  @override
  late final GeneratedColumn<int> strengthXp = GeneratedColumn<int>(
    'strength_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _intellectXpMeta = const VerificationMeta(
    'intellectXp',
  );
  @override
  late final GeneratedColumn<int> intellectXp = GeneratedColumn<int>(
    'intellect_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vitalityXpMeta = const VerificationMeta(
    'vitalityXp',
  );
  @override
  late final GeneratedColumn<int> vitalityXp = GeneratedColumn<int>(
    'vitality_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _creativityXpMeta = const VerificationMeta(
    'creativityXp',
  );
  @override
  late final GeneratedColumn<int> creativityXp = GeneratedColumn<int>(
    'creativity_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _focusXpMeta = const VerificationMeta(
    'focusXp',
  );
  @override
  late final GeneratedColumn<int> focusXp = GeneratedColumn<int>(
    'focus_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _spiritXpMeta = const VerificationMeta(
    'spiritXp',
  );
  @override
  late final GeneratedColumn<int> spiritXp = GeneratedColumn<int>(
    'spirit_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _challengeXpMeta = const VerificationMeta(
    'challengeXp',
  );
  @override
  late final GeneratedColumn<int> challengeXp = GeneratedColumn<int>(
    'challenge_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _worldHealthScoreMeta = const VerificationMeta(
    'worldHealthScore',
  );
  @override
  late final GeneratedColumn<double> worldHealthScore = GeneratedColumn<double>(
    'world_health_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _archetypeMeta = const VerificationMeta(
    'archetype',
  );
  @override
  late final GeneratedColumn<String> archetype = GeneratedColumn<String>(
    'archetype',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarJsonMeta = const VerificationMeta(
    'avatarJson',
  );
  @override
  late final GeneratedColumn<String> avatarJson = GeneratedColumn<String>(
    'avatar_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _worldStateJsonMeta = const VerificationMeta(
    'worldStateJson',
  );
  @override
  late final GeneratedColumn<String> worldStateJson = GeneratedColumn<String>(
    'world_state_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(''),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<String> syncedAt = GeneratedColumn<String>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onboardingProgressMeta =
      const VerificationMeta('onboardingProgress');
  @override
  late final GeneratedColumn<int> onboardingProgress = GeneratedColumn<int>(
    'onboarding_progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _onboardingCompletedAtMeta =
      const VerificationMeta('onboardingCompletedAt');
  @override
  late final GeneratedColumn<String> onboardingCompletedAt =
      GeneratedColumn<String>(
        'onboarding_completed_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    totalXp,
    level,
    streak,
    strengthXp,
    intellectXp,
    vitalityXp,
    creativityXp,
    focusXp,
    spiritXp,
    challengeXp,
    worldHealthScore,
    archetype,
    avatarJson,
    worldStateJson,
    updatedAt,
    syncedAt,
    onboardingProgress,
    onboardingCompletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_stats_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserStatsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('total_xp')) {
      context.handle(
        _totalXpMeta,
        totalXp.isAcceptableOrUnknown(data['total_xp']!, _totalXpMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('streak')) {
      context.handle(
        _streakMeta,
        streak.isAcceptableOrUnknown(data['streak']!, _streakMeta),
      );
    }
    if (data.containsKey('strength_xp')) {
      context.handle(
        _strengthXpMeta,
        strengthXp.isAcceptableOrUnknown(data['strength_xp']!, _strengthXpMeta),
      );
    }
    if (data.containsKey('intellect_xp')) {
      context.handle(
        _intellectXpMeta,
        intellectXp.isAcceptableOrUnknown(
          data['intellect_xp']!,
          _intellectXpMeta,
        ),
      );
    }
    if (data.containsKey('vitality_xp')) {
      context.handle(
        _vitalityXpMeta,
        vitalityXp.isAcceptableOrUnknown(data['vitality_xp']!, _vitalityXpMeta),
      );
    }
    if (data.containsKey('creativity_xp')) {
      context.handle(
        _creativityXpMeta,
        creativityXp.isAcceptableOrUnknown(
          data['creativity_xp']!,
          _creativityXpMeta,
        ),
      );
    }
    if (data.containsKey('focus_xp')) {
      context.handle(
        _focusXpMeta,
        focusXp.isAcceptableOrUnknown(data['focus_xp']!, _focusXpMeta),
      );
    }
    if (data.containsKey('spirit_xp')) {
      context.handle(
        _spiritXpMeta,
        spiritXp.isAcceptableOrUnknown(data['spirit_xp']!, _spiritXpMeta),
      );
    }
    if (data.containsKey('challenge_xp')) {
      context.handle(
        _challengeXpMeta,
        challengeXp.isAcceptableOrUnknown(
          data['challenge_xp']!,
          _challengeXpMeta,
        ),
      );
    }
    if (data.containsKey('world_health_score')) {
      context.handle(
        _worldHealthScoreMeta,
        worldHealthScore.isAcceptableOrUnknown(
          data['world_health_score']!,
          _worldHealthScoreMeta,
        ),
      );
    }
    if (data.containsKey('archetype')) {
      context.handle(
        _archetypeMeta,
        archetype.isAcceptableOrUnknown(data['archetype']!, _archetypeMeta),
      );
    }
    if (data.containsKey('avatar_json')) {
      context.handle(
        _avatarJsonMeta,
        avatarJson.isAcceptableOrUnknown(data['avatar_json']!, _avatarJsonMeta),
      );
    }
    if (data.containsKey('world_state_json')) {
      context.handle(
        _worldStateJsonMeta,
        worldStateJson.isAcceptableOrUnknown(
          data['world_state_json']!,
          _worldStateJsonMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('onboarding_progress')) {
      context.handle(
        _onboardingProgressMeta,
        onboardingProgress.isAcceptableOrUnknown(
          data['onboarding_progress']!,
          _onboardingProgressMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_completed_at')) {
      context.handle(
        _onboardingCompletedAtMeta,
        onboardingCompletedAt.isAcceptableOrUnknown(
          data['onboarding_completed_at']!,
          _onboardingCompletedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  UserStatsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserStatsTableData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      totalXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_xp'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      streak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak'],
      )!,
      strengthXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}strength_xp'],
      )!,
      intellectXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intellect_xp'],
      )!,
      vitalityXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vitality_xp'],
      )!,
      creativityXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}creativity_xp'],
      )!,
      focusXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}focus_xp'],
      )!,
      spiritXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spirit_xp'],
      )!,
      challengeXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}challenge_xp'],
      )!,
      worldHealthScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}world_health_score'],
      )!,
      archetype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archetype'],
      ),
      avatarJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_json'],
      ),
      worldStateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world_state_json'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synced_at'],
      ),
      onboardingProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}onboarding_progress'],
      )!,
      onboardingCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}onboarding_completed_at'],
      ),
    );
  }

  @override
  $UserStatsTableTable createAlias(String alias) {
    return $UserStatsTableTable(attachedDatabase, alias);
  }
}

class UserStatsTableData extends DataClass
    implements Insertable<UserStatsTableData> {
  final String userId;
  final int totalXp;
  final int level;
  final int streak;
  final int strengthXp;
  final int intellectXp;
  final int vitalityXp;
  final int creativityXp;
  final int focusXp;
  final int spiritXp;
  final int challengeXp;
  final double worldHealthScore;
  final String? archetype;
  final String? avatarJson;
  final String? worldStateJson;
  final String updatedAt;
  final String? syncedAt;
  final int onboardingProgress;
  final String? onboardingCompletedAt;
  const UserStatsTableData({
    required this.userId,
    required this.totalXp,
    required this.level,
    required this.streak,
    required this.strengthXp,
    required this.intellectXp,
    required this.vitalityXp,
    required this.creativityXp,
    required this.focusXp,
    required this.spiritXp,
    required this.challengeXp,
    required this.worldHealthScore,
    this.archetype,
    this.avatarJson,
    this.worldStateJson,
    required this.updatedAt,
    this.syncedAt,
    required this.onboardingProgress,
    this.onboardingCompletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['total_xp'] = Variable<int>(totalXp);
    map['level'] = Variable<int>(level);
    map['streak'] = Variable<int>(streak);
    map['strength_xp'] = Variable<int>(strengthXp);
    map['intellect_xp'] = Variable<int>(intellectXp);
    map['vitality_xp'] = Variable<int>(vitalityXp);
    map['creativity_xp'] = Variable<int>(creativityXp);
    map['focus_xp'] = Variable<int>(focusXp);
    map['spirit_xp'] = Variable<int>(spiritXp);
    map['challenge_xp'] = Variable<int>(challengeXp);
    map['world_health_score'] = Variable<double>(worldHealthScore);
    if (!nullToAbsent || archetype != null) {
      map['archetype'] = Variable<String>(archetype);
    }
    if (!nullToAbsent || avatarJson != null) {
      map['avatar_json'] = Variable<String>(avatarJson);
    }
    if (!nullToAbsent || worldStateJson != null) {
      map['world_state_json'] = Variable<String>(worldStateJson);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<String>(syncedAt);
    }
    map['onboarding_progress'] = Variable<int>(onboardingProgress);
    if (!nullToAbsent || onboardingCompletedAt != null) {
      map['onboarding_completed_at'] = Variable<String>(onboardingCompletedAt);
    }
    return map;
  }

  UserStatsTableCompanion toCompanion(bool nullToAbsent) {
    return UserStatsTableCompanion(
      userId: Value(userId),
      totalXp: Value(totalXp),
      level: Value(level),
      streak: Value(streak),
      strengthXp: Value(strengthXp),
      intellectXp: Value(intellectXp),
      vitalityXp: Value(vitalityXp),
      creativityXp: Value(creativityXp),
      focusXp: Value(focusXp),
      spiritXp: Value(spiritXp),
      challengeXp: Value(challengeXp),
      worldHealthScore: Value(worldHealthScore),
      archetype: archetype == null && nullToAbsent
          ? const Value.absent()
          : Value(archetype),
      avatarJson: avatarJson == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarJson),
      worldStateJson: worldStateJson == null && nullToAbsent
          ? const Value.absent()
          : Value(worldStateJson),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      onboardingProgress: Value(onboardingProgress),
      onboardingCompletedAt: onboardingCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(onboardingCompletedAt),
    );
  }

  factory UserStatsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserStatsTableData(
      userId: serializer.fromJson<String>(json['userId']),
      totalXp: serializer.fromJson<int>(json['totalXp']),
      level: serializer.fromJson<int>(json['level']),
      streak: serializer.fromJson<int>(json['streak']),
      strengthXp: serializer.fromJson<int>(json['strengthXp']),
      intellectXp: serializer.fromJson<int>(json['intellectXp']),
      vitalityXp: serializer.fromJson<int>(json['vitalityXp']),
      creativityXp: serializer.fromJson<int>(json['creativityXp']),
      focusXp: serializer.fromJson<int>(json['focusXp']),
      spiritXp: serializer.fromJson<int>(json['spiritXp']),
      challengeXp: serializer.fromJson<int>(json['challengeXp']),
      worldHealthScore: serializer.fromJson<double>(json['worldHealthScore']),
      archetype: serializer.fromJson<String?>(json['archetype']),
      avatarJson: serializer.fromJson<String?>(json['avatarJson']),
      worldStateJson: serializer.fromJson<String?>(json['worldStateJson']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncedAt: serializer.fromJson<String?>(json['syncedAt']),
      onboardingProgress: serializer.fromJson<int>(json['onboardingProgress']),
      onboardingCompletedAt: serializer.fromJson<String?>(
        json['onboardingCompletedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'totalXp': serializer.toJson<int>(totalXp),
      'level': serializer.toJson<int>(level),
      'streak': serializer.toJson<int>(streak),
      'strengthXp': serializer.toJson<int>(strengthXp),
      'intellectXp': serializer.toJson<int>(intellectXp),
      'vitalityXp': serializer.toJson<int>(vitalityXp),
      'creativityXp': serializer.toJson<int>(creativityXp),
      'focusXp': serializer.toJson<int>(focusXp),
      'spiritXp': serializer.toJson<int>(spiritXp),
      'challengeXp': serializer.toJson<int>(challengeXp),
      'worldHealthScore': serializer.toJson<double>(worldHealthScore),
      'archetype': serializer.toJson<String?>(archetype),
      'avatarJson': serializer.toJson<String?>(avatarJson),
      'worldStateJson': serializer.toJson<String?>(worldStateJson),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncedAt': serializer.toJson<String?>(syncedAt),
      'onboardingProgress': serializer.toJson<int>(onboardingProgress),
      'onboardingCompletedAt': serializer.toJson<String?>(
        onboardingCompletedAt,
      ),
    };
  }

  UserStatsTableData copyWith({
    String? userId,
    int? totalXp,
    int? level,
    int? streak,
    int? strengthXp,
    int? intellectXp,
    int? vitalityXp,
    int? creativityXp,
    int? focusXp,
    int? spiritXp,
    int? challengeXp,
    double? worldHealthScore,
    Value<String?> archetype = const Value.absent(),
    Value<String?> avatarJson = const Value.absent(),
    Value<String?> worldStateJson = const Value.absent(),
    String? updatedAt,
    Value<String?> syncedAt = const Value.absent(),
    int? onboardingProgress,
    Value<String?> onboardingCompletedAt = const Value.absent(),
  }) => UserStatsTableData(
    userId: userId ?? this.userId,
    totalXp: totalXp ?? this.totalXp,
    level: level ?? this.level,
    streak: streak ?? this.streak,
    strengthXp: strengthXp ?? this.strengthXp,
    intellectXp: intellectXp ?? this.intellectXp,
    vitalityXp: vitalityXp ?? this.vitalityXp,
    creativityXp: creativityXp ?? this.creativityXp,
    focusXp: focusXp ?? this.focusXp,
    spiritXp: spiritXp ?? this.spiritXp,
    challengeXp: challengeXp ?? this.challengeXp,
    worldHealthScore: worldHealthScore ?? this.worldHealthScore,
    archetype: archetype.present ? archetype.value : this.archetype,
    avatarJson: avatarJson.present ? avatarJson.value : this.avatarJson,
    worldStateJson: worldStateJson.present
        ? worldStateJson.value
        : this.worldStateJson,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    onboardingProgress: onboardingProgress ?? this.onboardingProgress,
    onboardingCompletedAt: onboardingCompletedAt.present
        ? onboardingCompletedAt.value
        : this.onboardingCompletedAt,
  );
  UserStatsTableData copyWithCompanion(UserStatsTableCompanion data) {
    return UserStatsTableData(
      userId: data.userId.present ? data.userId.value : this.userId,
      totalXp: data.totalXp.present ? data.totalXp.value : this.totalXp,
      level: data.level.present ? data.level.value : this.level,
      streak: data.streak.present ? data.streak.value : this.streak,
      strengthXp: data.strengthXp.present
          ? data.strengthXp.value
          : this.strengthXp,
      intellectXp: data.intellectXp.present
          ? data.intellectXp.value
          : this.intellectXp,
      vitalityXp: data.vitalityXp.present
          ? data.vitalityXp.value
          : this.vitalityXp,
      creativityXp: data.creativityXp.present
          ? data.creativityXp.value
          : this.creativityXp,
      focusXp: data.focusXp.present ? data.focusXp.value : this.focusXp,
      spiritXp: data.spiritXp.present ? data.spiritXp.value : this.spiritXp,
      challengeXp: data.challengeXp.present
          ? data.challengeXp.value
          : this.challengeXp,
      worldHealthScore: data.worldHealthScore.present
          ? data.worldHealthScore.value
          : this.worldHealthScore,
      archetype: data.archetype.present ? data.archetype.value : this.archetype,
      avatarJson: data.avatarJson.present
          ? data.avatarJson.value
          : this.avatarJson,
      worldStateJson: data.worldStateJson.present
          ? data.worldStateJson.value
          : this.worldStateJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      onboardingProgress: data.onboardingProgress.present
          ? data.onboardingProgress.value
          : this.onboardingProgress,
      onboardingCompletedAt: data.onboardingCompletedAt.present
          ? data.onboardingCompletedAt.value
          : this.onboardingCompletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserStatsTableData(')
          ..write('userId: $userId, ')
          ..write('totalXp: $totalXp, ')
          ..write('level: $level, ')
          ..write('streak: $streak, ')
          ..write('strengthXp: $strengthXp, ')
          ..write('intellectXp: $intellectXp, ')
          ..write('vitalityXp: $vitalityXp, ')
          ..write('creativityXp: $creativityXp, ')
          ..write('focusXp: $focusXp, ')
          ..write('spiritXp: $spiritXp, ')
          ..write('challengeXp: $challengeXp, ')
          ..write('worldHealthScore: $worldHealthScore, ')
          ..write('archetype: $archetype, ')
          ..write('avatarJson: $avatarJson, ')
          ..write('worldStateJson: $worldStateJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('onboardingProgress: $onboardingProgress, ')
          ..write('onboardingCompletedAt: $onboardingCompletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    totalXp,
    level,
    streak,
    strengthXp,
    intellectXp,
    vitalityXp,
    creativityXp,
    focusXp,
    spiritXp,
    challengeXp,
    worldHealthScore,
    archetype,
    avatarJson,
    worldStateJson,
    updatedAt,
    syncedAt,
    onboardingProgress,
    onboardingCompletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserStatsTableData &&
          other.userId == this.userId &&
          other.totalXp == this.totalXp &&
          other.level == this.level &&
          other.streak == this.streak &&
          other.strengthXp == this.strengthXp &&
          other.intellectXp == this.intellectXp &&
          other.vitalityXp == this.vitalityXp &&
          other.creativityXp == this.creativityXp &&
          other.focusXp == this.focusXp &&
          other.spiritXp == this.spiritXp &&
          other.challengeXp == this.challengeXp &&
          other.worldHealthScore == this.worldHealthScore &&
          other.archetype == this.archetype &&
          other.avatarJson == this.avatarJson &&
          other.worldStateJson == this.worldStateJson &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.onboardingProgress == this.onboardingProgress &&
          other.onboardingCompletedAt == this.onboardingCompletedAt);
}

class UserStatsTableCompanion extends UpdateCompanion<UserStatsTableData> {
  final Value<String> userId;
  final Value<int> totalXp;
  final Value<int> level;
  final Value<int> streak;
  final Value<int> strengthXp;
  final Value<int> intellectXp;
  final Value<int> vitalityXp;
  final Value<int> creativityXp;
  final Value<int> focusXp;
  final Value<int> spiritXp;
  final Value<int> challengeXp;
  final Value<double> worldHealthScore;
  final Value<String?> archetype;
  final Value<String?> avatarJson;
  final Value<String?> worldStateJson;
  final Value<String> updatedAt;
  final Value<String?> syncedAt;
  final Value<int> onboardingProgress;
  final Value<String?> onboardingCompletedAt;
  final Value<int> rowid;
  const UserStatsTableCompanion({
    this.userId = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.level = const Value.absent(),
    this.streak = const Value.absent(),
    this.strengthXp = const Value.absent(),
    this.intellectXp = const Value.absent(),
    this.vitalityXp = const Value.absent(),
    this.creativityXp = const Value.absent(),
    this.focusXp = const Value.absent(),
    this.spiritXp = const Value.absent(),
    this.challengeXp = const Value.absent(),
    this.worldHealthScore = const Value.absent(),
    this.archetype = const Value.absent(),
    this.avatarJson = const Value.absent(),
    this.worldStateJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.onboardingProgress = const Value.absent(),
    this.onboardingCompletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserStatsTableCompanion.insert({
    required String userId,
    this.totalXp = const Value.absent(),
    this.level = const Value.absent(),
    this.streak = const Value.absent(),
    this.strengthXp = const Value.absent(),
    this.intellectXp = const Value.absent(),
    this.vitalityXp = const Value.absent(),
    this.creativityXp = const Value.absent(),
    this.focusXp = const Value.absent(),
    this.spiritXp = const Value.absent(),
    this.challengeXp = const Value.absent(),
    this.worldHealthScore = const Value.absent(),
    this.archetype = const Value.absent(),
    this.avatarJson = const Value.absent(),
    this.worldStateJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.onboardingProgress = const Value.absent(),
    this.onboardingCompletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<UserStatsTableData> custom({
    Expression<String>? userId,
    Expression<int>? totalXp,
    Expression<int>? level,
    Expression<int>? streak,
    Expression<int>? strengthXp,
    Expression<int>? intellectXp,
    Expression<int>? vitalityXp,
    Expression<int>? creativityXp,
    Expression<int>? focusXp,
    Expression<int>? spiritXp,
    Expression<int>? challengeXp,
    Expression<double>? worldHealthScore,
    Expression<String>? archetype,
    Expression<String>? avatarJson,
    Expression<String>? worldStateJson,
    Expression<String>? updatedAt,
    Expression<String>? syncedAt,
    Expression<int>? onboardingProgress,
    Expression<String>? onboardingCompletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (totalXp != null) 'total_xp': totalXp,
      if (level != null) 'level': level,
      if (streak != null) 'streak': streak,
      if (strengthXp != null) 'strength_xp': strengthXp,
      if (intellectXp != null) 'intellect_xp': intellectXp,
      if (vitalityXp != null) 'vitality_xp': vitalityXp,
      if (creativityXp != null) 'creativity_xp': creativityXp,
      if (focusXp != null) 'focus_xp': focusXp,
      if (spiritXp != null) 'spirit_xp': spiritXp,
      if (challengeXp != null) 'challenge_xp': challengeXp,
      if (worldHealthScore != null) 'world_health_score': worldHealthScore,
      if (archetype != null) 'archetype': archetype,
      if (avatarJson != null) 'avatar_json': avatarJson,
      if (worldStateJson != null) 'world_state_json': worldStateJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (onboardingProgress != null) 'onboarding_progress': onboardingProgress,
      if (onboardingCompletedAt != null)
        'onboarding_completed_at': onboardingCompletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserStatsTableCompanion copyWith({
    Value<String>? userId,
    Value<int>? totalXp,
    Value<int>? level,
    Value<int>? streak,
    Value<int>? strengthXp,
    Value<int>? intellectXp,
    Value<int>? vitalityXp,
    Value<int>? creativityXp,
    Value<int>? focusXp,
    Value<int>? spiritXp,
    Value<int>? challengeXp,
    Value<double>? worldHealthScore,
    Value<String?>? archetype,
    Value<String?>? avatarJson,
    Value<String?>? worldStateJson,
    Value<String>? updatedAt,
    Value<String?>? syncedAt,
    Value<int>? onboardingProgress,
    Value<String?>? onboardingCompletedAt,
    Value<int>? rowid,
  }) {
    return UserStatsTableCompanion(
      userId: userId ?? this.userId,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      strengthXp: strengthXp ?? this.strengthXp,
      intellectXp: intellectXp ?? this.intellectXp,
      vitalityXp: vitalityXp ?? this.vitalityXp,
      creativityXp: creativityXp ?? this.creativityXp,
      focusXp: focusXp ?? this.focusXp,
      spiritXp: spiritXp ?? this.spiritXp,
      challengeXp: challengeXp ?? this.challengeXp,
      worldHealthScore: worldHealthScore ?? this.worldHealthScore,
      archetype: archetype ?? this.archetype,
      avatarJson: avatarJson ?? this.avatarJson,
      worldStateJson: worldStateJson ?? this.worldStateJson,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      onboardingProgress: onboardingProgress ?? this.onboardingProgress,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (totalXp.present) {
      map['total_xp'] = Variable<int>(totalXp.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (streak.present) {
      map['streak'] = Variable<int>(streak.value);
    }
    if (strengthXp.present) {
      map['strength_xp'] = Variable<int>(strengthXp.value);
    }
    if (intellectXp.present) {
      map['intellect_xp'] = Variable<int>(intellectXp.value);
    }
    if (vitalityXp.present) {
      map['vitality_xp'] = Variable<int>(vitalityXp.value);
    }
    if (creativityXp.present) {
      map['creativity_xp'] = Variable<int>(creativityXp.value);
    }
    if (focusXp.present) {
      map['focus_xp'] = Variable<int>(focusXp.value);
    }
    if (spiritXp.present) {
      map['spirit_xp'] = Variable<int>(spiritXp.value);
    }
    if (challengeXp.present) {
      map['challenge_xp'] = Variable<int>(challengeXp.value);
    }
    if (worldHealthScore.present) {
      map['world_health_score'] = Variable<double>(worldHealthScore.value);
    }
    if (archetype.present) {
      map['archetype'] = Variable<String>(archetype.value);
    }
    if (avatarJson.present) {
      map['avatar_json'] = Variable<String>(avatarJson.value);
    }
    if (worldStateJson.present) {
      map['world_state_json'] = Variable<String>(worldStateJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<String>(syncedAt.value);
    }
    if (onboardingProgress.present) {
      map['onboarding_progress'] = Variable<int>(onboardingProgress.value);
    }
    if (onboardingCompletedAt.present) {
      map['onboarding_completed_at'] = Variable<String>(
        onboardingCompletedAt.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserStatsTableCompanion(')
          ..write('userId: $userId, ')
          ..write('totalXp: $totalXp, ')
          ..write('level: $level, ')
          ..write('streak: $streak, ')
          ..write('strengthXp: $strengthXp, ')
          ..write('intellectXp: $intellectXp, ')
          ..write('vitalityXp: $vitalityXp, ')
          ..write('creativityXp: $creativityXp, ')
          ..write('focusXp: $focusXp, ')
          ..write('spiritXp: $spiritXp, ')
          ..write('challengeXp: $challengeXp, ')
          ..write('worldHealthScore: $worldHealthScore, ')
          ..write('archetype: $archetype, ')
          ..write('avatarJson: $avatarJson, ')
          ..write('worldStateJson: $worldStateJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('onboardingProgress: $onboardingProgress, ')
          ..write('onboardingCompletedAt: $onboardingCompletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitsTableTable extends HabitsTable
    with TableInfo<$HabitsTableTable, HabitsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cueMeta = const VerificationMeta('cue');
  @override
  late final GeneratedColumn<String> cue = GeneratedColumn<String>(
    'cue',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routineMeta = const VerificationMeta(
    'routine',
  );
  @override
  late final GeneratedColumn<String> routine = GeneratedColumn<String>(
    'routine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rewardMeta = const VerificationMeta('reward');
  @override
  late final GeneratedColumn<String> reward = GeneratedColumn<String>(
    'reward',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('daily'),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _attributeMeta = const VerificationMeta(
    'attribute',
  );
  @override
  late final GeneratedColumn<String> attribute = GeneratedColumn<String>(
    'attribute',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentStreakMeta = const VerificationMeta(
    'currentStreak',
  );
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
    'current_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _longestStreakMeta = const VerificationMeta(
    'longestStreak',
  );
  @override
  late final GeneratedColumn<int> longestStreak = GeneratedColumn<int>(
    'longest_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _momentumScoreMeta = const VerificationMeta(
    'momentumScore',
  );
  @override
  late final GeneratedColumn<int> momentumScore = GeneratedColumn<int>(
    'momentum_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _consecutiveMissesMeta = const VerificationMeta(
    'consecutiveMisses',
  );
  @override
  late final GeneratedColumn<int> consecutiveMisses = GeneratedColumn<int>(
    'consecutive_misses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCompletedDateMeta = const VerificationMeta(
    'lastCompletedDate',
  );
  @override
  late final GeneratedColumn<String> lastCompletedDate =
      GeneratedColumn<String>(
        'last_completed_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<int> isArchived = GeneratedColumn<int>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<String> syncedAt = GeneratedColumn<String>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    cue,
    routine,
    reward,
    frequency,
    difficulty,
    attribute,
    currentStreak,
    longestStreak,
    momentumScore,
    consecutiveMisses,
    lastCompletedDate,
    isArchived,
    createdAt,
    updatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cue')) {
      context.handle(
        _cueMeta,
        cue.isAcceptableOrUnknown(data['cue']!, _cueMeta),
      );
    }
    if (data.containsKey('routine')) {
      context.handle(
        _routineMeta,
        routine.isAcceptableOrUnknown(data['routine']!, _routineMeta),
      );
    }
    if (data.containsKey('reward')) {
      context.handle(
        _rewardMeta,
        reward.isAcceptableOrUnknown(data['reward']!, _rewardMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('attribute')) {
      context.handle(
        _attributeMeta,
        attribute.isAcceptableOrUnknown(data['attribute']!, _attributeMeta),
      );
    }
    if (data.containsKey('current_streak')) {
      context.handle(
        _currentStreakMeta,
        currentStreak.isAcceptableOrUnknown(
          data['current_streak']!,
          _currentStreakMeta,
        ),
      );
    }
    if (data.containsKey('longest_streak')) {
      context.handle(
        _longestStreakMeta,
        longestStreak.isAcceptableOrUnknown(
          data['longest_streak']!,
          _longestStreakMeta,
        ),
      );
    }
    if (data.containsKey('momentum_score')) {
      context.handle(
        _momentumScoreMeta,
        momentumScore.isAcceptableOrUnknown(
          data['momentum_score']!,
          _momentumScoreMeta,
        ),
      );
    }
    if (data.containsKey('consecutive_misses')) {
      context.handle(
        _consecutiveMissesMeta,
        consecutiveMisses.isAcceptableOrUnknown(
          data['consecutive_misses']!,
          _consecutiveMissesMeta,
        ),
      );
    }
    if (data.containsKey('last_completed_date')) {
      context.handle(
        _lastCompletedDateMeta,
        lastCompletedDate.isAcceptableOrUnknown(
          data['last_completed_date']!,
          _lastCompletedDateMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      cue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cue'],
      ),
      routine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine'],
      ),
      reward: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reward'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      attribute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribute'],
      ),
      currentStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_streak'],
      )!,
      longestStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_streak'],
      )!,
      momentumScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}momentum_score'],
      )!,
      consecutiveMisses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consecutive_misses'],
      )!,
      lastCompletedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_completed_date'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $HabitsTableTable createAlias(String alias) {
    return $HabitsTableTable(attachedDatabase, alias);
  }
}

class HabitsTableData extends DataClass implements Insertable<HabitsTableData> {
  final String id;
  final String userId;
  final String title;
  final String? cue;
  final String? routine;
  final String? reward;
  final String frequency;
  final String difficulty;
  final String? attribute;
  final int currentStreak;
  final int longestStreak;
  final int momentumScore;
  final int consecutiveMisses;
  final String? lastCompletedDate;
  final int isArchived;
  final String createdAt;
  final String updatedAt;
  final String? syncedAt;
  const HabitsTableData({
    required this.id,
    required this.userId,
    required this.title,
    this.cue,
    this.routine,
    this.reward,
    required this.frequency,
    required this.difficulty,
    this.attribute,
    required this.currentStreak,
    required this.longestStreak,
    required this.momentumScore,
    required this.consecutiveMisses,
    this.lastCompletedDate,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || cue != null) {
      map['cue'] = Variable<String>(cue);
    }
    if (!nullToAbsent || routine != null) {
      map['routine'] = Variable<String>(routine);
    }
    if (!nullToAbsent || reward != null) {
      map['reward'] = Variable<String>(reward);
    }
    map['frequency'] = Variable<String>(frequency);
    map['difficulty'] = Variable<String>(difficulty);
    if (!nullToAbsent || attribute != null) {
      map['attribute'] = Variable<String>(attribute);
    }
    map['current_streak'] = Variable<int>(currentStreak);
    map['longest_streak'] = Variable<int>(longestStreak);
    map['momentum_score'] = Variable<int>(momentumScore);
    map['consecutive_misses'] = Variable<int>(consecutiveMisses);
    if (!nullToAbsent || lastCompletedDate != null) {
      map['last_completed_date'] = Variable<String>(lastCompletedDate);
    }
    map['is_archived'] = Variable<int>(isArchived);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<String>(syncedAt);
    }
    return map;
  }

  HabitsTableCompanion toCompanion(bool nullToAbsent) {
    return HabitsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      cue: cue == null && nullToAbsent ? const Value.absent() : Value(cue),
      routine: routine == null && nullToAbsent
          ? const Value.absent()
          : Value(routine),
      reward: reward == null && nullToAbsent
          ? const Value.absent()
          : Value(reward),
      frequency: Value(frequency),
      difficulty: Value(difficulty),
      attribute: attribute == null && nullToAbsent
          ? const Value.absent()
          : Value(attribute),
      currentStreak: Value(currentStreak),
      longestStreak: Value(longestStreak),
      momentumScore: Value(momentumScore),
      consecutiveMisses: Value(consecutiveMisses),
      lastCompletedDate: lastCompletedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedDate),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory HabitsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      cue: serializer.fromJson<String?>(json['cue']),
      routine: serializer.fromJson<String?>(json['routine']),
      reward: serializer.fromJson<String?>(json['reward']),
      frequency: serializer.fromJson<String>(json['frequency']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      attribute: serializer.fromJson<String?>(json['attribute']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      longestStreak: serializer.fromJson<int>(json['longestStreak']),
      momentumScore: serializer.fromJson<int>(json['momentumScore']),
      consecutiveMisses: serializer.fromJson<int>(json['consecutiveMisses']),
      lastCompletedDate: serializer.fromJson<String?>(
        json['lastCompletedDate'],
      ),
      isArchived: serializer.fromJson<int>(json['isArchived']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncedAt: serializer.fromJson<String?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'cue': serializer.toJson<String?>(cue),
      'routine': serializer.toJson<String?>(routine),
      'reward': serializer.toJson<String?>(reward),
      'frequency': serializer.toJson<String>(frequency),
      'difficulty': serializer.toJson<String>(difficulty),
      'attribute': serializer.toJson<String?>(attribute),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'longestStreak': serializer.toJson<int>(longestStreak),
      'momentumScore': serializer.toJson<int>(momentumScore),
      'consecutiveMisses': serializer.toJson<int>(consecutiveMisses),
      'lastCompletedDate': serializer.toJson<String?>(lastCompletedDate),
      'isArchived': serializer.toJson<int>(isArchived),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncedAt': serializer.toJson<String?>(syncedAt),
    };
  }

  HabitsTableData copyWith({
    String? id,
    String? userId,
    String? title,
    Value<String?> cue = const Value.absent(),
    Value<String?> routine = const Value.absent(),
    Value<String?> reward = const Value.absent(),
    String? frequency,
    String? difficulty,
    Value<String?> attribute = const Value.absent(),
    int? currentStreak,
    int? longestStreak,
    int? momentumScore,
    int? consecutiveMisses,
    Value<String?> lastCompletedDate = const Value.absent(),
    int? isArchived,
    String? createdAt,
    String? updatedAt,
    Value<String?> syncedAt = const Value.absent(),
  }) => HabitsTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    cue: cue.present ? cue.value : this.cue,
    routine: routine.present ? routine.value : this.routine,
    reward: reward.present ? reward.value : this.reward,
    frequency: frequency ?? this.frequency,
    difficulty: difficulty ?? this.difficulty,
    attribute: attribute.present ? attribute.value : this.attribute,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    momentumScore: momentumScore ?? this.momentumScore,
    consecutiveMisses: consecutiveMisses ?? this.consecutiveMisses,
    lastCompletedDate: lastCompletedDate.present
        ? lastCompletedDate.value
        : this.lastCompletedDate,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  HabitsTableData copyWithCompanion(HabitsTableCompanion data) {
    return HabitsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      cue: data.cue.present ? data.cue.value : this.cue,
      routine: data.routine.present ? data.routine.value : this.routine,
      reward: data.reward.present ? data.reward.value : this.reward,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      attribute: data.attribute.present ? data.attribute.value : this.attribute,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      longestStreak: data.longestStreak.present
          ? data.longestStreak.value
          : this.longestStreak,
      momentumScore: data.momentumScore.present
          ? data.momentumScore.value
          : this.momentumScore,
      consecutiveMisses: data.consecutiveMisses.present
          ? data.consecutiveMisses.value
          : this.consecutiveMisses,
      lastCompletedDate: data.lastCompletedDate.present
          ? data.lastCompletedDate.value
          : this.lastCompletedDate,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('cue: $cue, ')
          ..write('routine: $routine, ')
          ..write('reward: $reward, ')
          ..write('frequency: $frequency, ')
          ..write('difficulty: $difficulty, ')
          ..write('attribute: $attribute, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('momentumScore: $momentumScore, ')
          ..write('consecutiveMisses: $consecutiveMisses, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    cue,
    routine,
    reward,
    frequency,
    difficulty,
    attribute,
    currentStreak,
    longestStreak,
    momentumScore,
    consecutiveMisses,
    lastCompletedDate,
    isArchived,
    createdAt,
    updatedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.cue == this.cue &&
          other.routine == this.routine &&
          other.reward == this.reward &&
          other.frequency == this.frequency &&
          other.difficulty == this.difficulty &&
          other.attribute == this.attribute &&
          other.currentStreak == this.currentStreak &&
          other.longestStreak == this.longestStreak &&
          other.momentumScore == this.momentumScore &&
          other.consecutiveMisses == this.consecutiveMisses &&
          other.lastCompletedDate == this.lastCompletedDate &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class HabitsTableCompanion extends UpdateCompanion<HabitsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String?> cue;
  final Value<String?> routine;
  final Value<String?> reward;
  final Value<String> frequency;
  final Value<String> difficulty;
  final Value<String?> attribute;
  final Value<int> currentStreak;
  final Value<int> longestStreak;
  final Value<int> momentumScore;
  final Value<int> consecutiveMisses;
  final Value<String?> lastCompletedDate;
  final Value<int> isArchived;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> syncedAt;
  final Value<int> rowid;
  const HabitsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.cue = const Value.absent(),
    this.routine = const Value.absent(),
    this.reward = const Value.absent(),
    this.frequency = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.attribute = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.momentumScore = const Value.absent(),
    this.consecutiveMisses = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitsTableCompanion.insert({
    required String id,
    required String userId,
    required String title,
    this.cue = const Value.absent(),
    this.routine = const Value.absent(),
    this.reward = const Value.absent(),
    this.frequency = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.attribute = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.momentumScore = const Value.absent(),
    this.consecutiveMisses = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    this.isArchived = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HabitsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? cue,
    Expression<String>? routine,
    Expression<String>? reward,
    Expression<String>? frequency,
    Expression<String>? difficulty,
    Expression<String>? attribute,
    Expression<int>? currentStreak,
    Expression<int>? longestStreak,
    Expression<int>? momentumScore,
    Expression<int>? consecutiveMisses,
    Expression<String>? lastCompletedDate,
    Expression<int>? isArchived,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (cue != null) 'cue': cue,
      if (routine != null) 'routine': routine,
      if (reward != null) 'reward': reward,
      if (frequency != null) 'frequency': frequency,
      if (difficulty != null) 'difficulty': difficulty,
      if (attribute != null) 'attribute': attribute,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (longestStreak != null) 'longest_streak': longestStreak,
      if (momentumScore != null) 'momentum_score': momentumScore,
      if (consecutiveMisses != null) 'consecutive_misses': consecutiveMisses,
      if (lastCompletedDate != null) 'last_completed_date': lastCompletedDate,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? title,
    Value<String?>? cue,
    Value<String?>? routine,
    Value<String?>? reward,
    Value<String>? frequency,
    Value<String>? difficulty,
    Value<String?>? attribute,
    Value<int>? currentStreak,
    Value<int>? longestStreak,
    Value<int>? momentumScore,
    Value<int>? consecutiveMisses,
    Value<String?>? lastCompletedDate,
    Value<int>? isArchived,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? syncedAt,
    Value<int>? rowid,
  }) {
    return HabitsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      cue: cue ?? this.cue,
      routine: routine ?? this.routine,
      reward: reward ?? this.reward,
      frequency: frequency ?? this.frequency,
      difficulty: difficulty ?? this.difficulty,
      attribute: attribute ?? this.attribute,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      momentumScore: momentumScore ?? this.momentumScore,
      consecutiveMisses: consecutiveMisses ?? this.consecutiveMisses,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (cue.present) {
      map['cue'] = Variable<String>(cue.value);
    }
    if (routine.present) {
      map['routine'] = Variable<String>(routine.value);
    }
    if (reward.present) {
      map['reward'] = Variable<String>(reward.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (attribute.present) {
      map['attribute'] = Variable<String>(attribute.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (longestStreak.present) {
      map['longest_streak'] = Variable<int>(longestStreak.value);
    }
    if (momentumScore.present) {
      map['momentum_score'] = Variable<int>(momentumScore.value);
    }
    if (consecutiveMisses.present) {
      map['consecutive_misses'] = Variable<int>(consecutiveMisses.value);
    }
    if (lastCompletedDate.present) {
      map['last_completed_date'] = Variable<String>(lastCompletedDate.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<int>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<String>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('cue: $cue, ')
          ..write('routine: $routine, ')
          ..write('reward: $reward, ')
          ..write('frequency: $frequency, ')
          ..write('difficulty: $difficulty, ')
          ..write('attribute: $attribute, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('momentumScore: $momentumScore, ')
          ..write('consecutiveMisses: $consecutiveMisses, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitCompletionsTableTable extends HabitCompletionsTable
    with TableInfo<$HabitCompletionsTableTable, HabitCompletionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitCompletionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpGainedMeta = const VerificationMeta(
    'xpGained',
  );
  @override
  late final GeneratedColumn<int> xpGained = GeneratedColumn<int>(
    'xp_gained',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attributeMeta = const VerificationMeta(
    'attribute',
  );
  @override
  late final GeneratedColumn<String> attribute = GeneratedColumn<String>(
    'attribute',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _momentumAtCompletionMeta =
      const VerificationMeta('momentumAtCompletion');
  @override
  late final GeneratedColumn<int> momentumAtCompletion = GeneratedColumn<int>(
    'momentum_at_completion',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streakDayMeta = const VerificationMeta(
    'streakDay',
  );
  @override
  late final GeneratedColumn<int> streakDay = GeneratedColumn<int>(
    'streak_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wasRecoveryMeta = const VerificationMeta(
    'wasRecovery',
  );
  @override
  late final GeneratedColumn<int> wasRecovery = GeneratedColumn<int>(
    'was_recovery',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<String> syncedAt = GeneratedColumn<String>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitId,
    userId,
    completedAt,
    xpGained,
    attribute,
    momentumAtCompletion,
    streakDay,
    wasRecovery,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_completions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitCompletionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('xp_gained')) {
      context.handle(
        _xpGainedMeta,
        xpGained.isAcceptableOrUnknown(data['xp_gained']!, _xpGainedMeta),
      );
    }
    if (data.containsKey('attribute')) {
      context.handle(
        _attributeMeta,
        attribute.isAcceptableOrUnknown(data['attribute']!, _attributeMeta),
      );
    }
    if (data.containsKey('momentum_at_completion')) {
      context.handle(
        _momentumAtCompletionMeta,
        momentumAtCompletion.isAcceptableOrUnknown(
          data['momentum_at_completion']!,
          _momentumAtCompletionMeta,
        ),
      );
    }
    if (data.containsKey('streak_day')) {
      context.handle(
        _streakDayMeta,
        streakDay.isAcceptableOrUnknown(data['streak_day']!, _streakDayMeta),
      );
    }
    if (data.containsKey('was_recovery')) {
      context.handle(
        _wasRecoveryMeta,
        wasRecovery.isAcceptableOrUnknown(
          data['was_recovery']!,
          _wasRecoveryMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitCompletionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitCompletionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      )!,
      xpGained: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_gained'],
      )!,
      attribute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribute'],
      ),
      momentumAtCompletion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}momentum_at_completion'],
      ),
      streakDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_day'],
      )!,
      wasRecovery: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}was_recovery'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $HabitCompletionsTableTable createAlias(String alias) {
    return $HabitCompletionsTableTable(attachedDatabase, alias);
  }
}

class HabitCompletionsTableData extends DataClass
    implements Insertable<HabitCompletionsTableData> {
  final String id;
  final String habitId;
  final String userId;
  final String completedAt;
  final int xpGained;
  final String? attribute;
  final int? momentumAtCompletion;
  final int streakDay;
  final int wasRecovery;
  final String? syncedAt;
  const HabitCompletionsTableData({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    required this.xpGained,
    this.attribute,
    this.momentumAtCompletion,
    required this.streakDay,
    required this.wasRecovery,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['user_id'] = Variable<String>(userId);
    map['completed_at'] = Variable<String>(completedAt);
    map['xp_gained'] = Variable<int>(xpGained);
    if (!nullToAbsent || attribute != null) {
      map['attribute'] = Variable<String>(attribute);
    }
    if (!nullToAbsent || momentumAtCompletion != null) {
      map['momentum_at_completion'] = Variable<int>(momentumAtCompletion);
    }
    map['streak_day'] = Variable<int>(streakDay);
    map['was_recovery'] = Variable<int>(wasRecovery);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<String>(syncedAt);
    }
    return map;
  }

  HabitCompletionsTableCompanion toCompanion(bool nullToAbsent) {
    return HabitCompletionsTableCompanion(
      id: Value(id),
      habitId: Value(habitId),
      userId: Value(userId),
      completedAt: Value(completedAt),
      xpGained: Value(xpGained),
      attribute: attribute == null && nullToAbsent
          ? const Value.absent()
          : Value(attribute),
      momentumAtCompletion: momentumAtCompletion == null && nullToAbsent
          ? const Value.absent()
          : Value(momentumAtCompletion),
      streakDay: Value(streakDay),
      wasRecovery: Value(wasRecovery),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory HabitCompletionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitCompletionsTableData(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      userId: serializer.fromJson<String>(json['userId']),
      completedAt: serializer.fromJson<String>(json['completedAt']),
      xpGained: serializer.fromJson<int>(json['xpGained']),
      attribute: serializer.fromJson<String?>(json['attribute']),
      momentumAtCompletion: serializer.fromJson<int?>(
        json['momentumAtCompletion'],
      ),
      streakDay: serializer.fromJson<int>(json['streakDay']),
      wasRecovery: serializer.fromJson<int>(json['wasRecovery']),
      syncedAt: serializer.fromJson<String?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'userId': serializer.toJson<String>(userId),
      'completedAt': serializer.toJson<String>(completedAt),
      'xpGained': serializer.toJson<int>(xpGained),
      'attribute': serializer.toJson<String?>(attribute),
      'momentumAtCompletion': serializer.toJson<int?>(momentumAtCompletion),
      'streakDay': serializer.toJson<int>(streakDay),
      'wasRecovery': serializer.toJson<int>(wasRecovery),
      'syncedAt': serializer.toJson<String?>(syncedAt),
    };
  }

  HabitCompletionsTableData copyWith({
    String? id,
    String? habitId,
    String? userId,
    String? completedAt,
    int? xpGained,
    Value<String?> attribute = const Value.absent(),
    Value<int?> momentumAtCompletion = const Value.absent(),
    int? streakDay,
    int? wasRecovery,
    Value<String?> syncedAt = const Value.absent(),
  }) => HabitCompletionsTableData(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    userId: userId ?? this.userId,
    completedAt: completedAt ?? this.completedAt,
    xpGained: xpGained ?? this.xpGained,
    attribute: attribute.present ? attribute.value : this.attribute,
    momentumAtCompletion: momentumAtCompletion.present
        ? momentumAtCompletion.value
        : this.momentumAtCompletion,
    streakDay: streakDay ?? this.streakDay,
    wasRecovery: wasRecovery ?? this.wasRecovery,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  HabitCompletionsTableData copyWithCompanion(
    HabitCompletionsTableCompanion data,
  ) {
    return HabitCompletionsTableData(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      userId: data.userId.present ? data.userId.value : this.userId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      xpGained: data.xpGained.present ? data.xpGained.value : this.xpGained,
      attribute: data.attribute.present ? data.attribute.value : this.attribute,
      momentumAtCompletion: data.momentumAtCompletion.present
          ? data.momentumAtCompletion.value
          : this.momentumAtCompletion,
      streakDay: data.streakDay.present ? data.streakDay.value : this.streakDay,
      wasRecovery: data.wasRecovery.present
          ? data.wasRecovery.value
          : this.wasRecovery,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitCompletionsTableData(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('xpGained: $xpGained, ')
          ..write('attribute: $attribute, ')
          ..write('momentumAtCompletion: $momentumAtCompletion, ')
          ..write('streakDay: $streakDay, ')
          ..write('wasRecovery: $wasRecovery, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    habitId,
    userId,
    completedAt,
    xpGained,
    attribute,
    momentumAtCompletion,
    streakDay,
    wasRecovery,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitCompletionsTableData &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.userId == this.userId &&
          other.completedAt == this.completedAt &&
          other.xpGained == this.xpGained &&
          other.attribute == this.attribute &&
          other.momentumAtCompletion == this.momentumAtCompletion &&
          other.streakDay == this.streakDay &&
          other.wasRecovery == this.wasRecovery &&
          other.syncedAt == this.syncedAt);
}

class HabitCompletionsTableCompanion
    extends UpdateCompanion<HabitCompletionsTableData> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<String> userId;
  final Value<String> completedAt;
  final Value<int> xpGained;
  final Value<String?> attribute;
  final Value<int?> momentumAtCompletion;
  final Value<int> streakDay;
  final Value<int> wasRecovery;
  final Value<String?> syncedAt;
  final Value<int> rowid;
  const HabitCompletionsTableCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.userId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.xpGained = const Value.absent(),
    this.attribute = const Value.absent(),
    this.momentumAtCompletion = const Value.absent(),
    this.streakDay = const Value.absent(),
    this.wasRecovery = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitCompletionsTableCompanion.insert({
    required String id,
    required String habitId,
    required String userId,
    required String completedAt,
    this.xpGained = const Value.absent(),
    this.attribute = const Value.absent(),
    this.momentumAtCompletion = const Value.absent(),
    this.streakDay = const Value.absent(),
    this.wasRecovery = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       habitId = Value(habitId),
       userId = Value(userId),
       completedAt = Value(completedAt);
  static Insertable<HabitCompletionsTableData> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<String>? userId,
    Expression<String>? completedAt,
    Expression<int>? xpGained,
    Expression<String>? attribute,
    Expression<int>? momentumAtCompletion,
    Expression<int>? streakDay,
    Expression<int>? wasRecovery,
    Expression<String>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (userId != null) 'user_id': userId,
      if (completedAt != null) 'completed_at': completedAt,
      if (xpGained != null) 'xp_gained': xpGained,
      if (attribute != null) 'attribute': attribute,
      if (momentumAtCompletion != null)
        'momentum_at_completion': momentumAtCompletion,
      if (streakDay != null) 'streak_day': streakDay,
      if (wasRecovery != null) 'was_recovery': wasRecovery,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitCompletionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? habitId,
    Value<String>? userId,
    Value<String>? completedAt,
    Value<int>? xpGained,
    Value<String?>? attribute,
    Value<int?>? momentumAtCompletion,
    Value<int>? streakDay,
    Value<int>? wasRecovery,
    Value<String?>? syncedAt,
    Value<int>? rowid,
  }) {
    return HabitCompletionsTableCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      xpGained: xpGained ?? this.xpGained,
      attribute: attribute ?? this.attribute,
      momentumAtCompletion: momentumAtCompletion ?? this.momentumAtCompletion,
      streakDay: streakDay ?? this.streakDay,
      wasRecovery: wasRecovery ?? this.wasRecovery,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (xpGained.present) {
      map['xp_gained'] = Variable<int>(xpGained.value);
    }
    if (attribute.present) {
      map['attribute'] = Variable<String>(attribute.value);
    }
    if (momentumAtCompletion.present) {
      map['momentum_at_completion'] = Variable<int>(momentumAtCompletion.value);
    }
    if (streakDay.present) {
      map['streak_day'] = Variable<int>(streakDay.value);
    }
    if (wasRecovery.present) {
      map['was_recovery'] = Variable<int>(wasRecovery.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<String>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitCompletionsTableCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('xpGained: $xpGained, ')
          ..write('attribute: $attribute, ')
          ..write('momentumAtCompletion: $momentumAtCompletion, ')
          ..write('streakDay: $streakDay, ')
          ..write('wasRecovery: $wasRecovery, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChallengeProgressTableTable extends ChallengeProgressTable
    with TableInfo<$ChallengeProgressTableTable, ChallengeProgressTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChallengeProgressTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _challengeIdMeta = const VerificationMeta(
    'challengeId',
  );
  @override
  late final GeneratedColumn<String> challengeId = GeneratedColumn<String>(
    'challenge_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attributeMeta = const VerificationMeta(
    'attribute',
  );
  @override
  late final GeneratedColumn<String> attribute = GeneratedColumn<String>(
    'attribute',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentDayMeta = const VerificationMeta(
    'currentDay',
  );
  @override
  late final GeneratedColumn<int> currentDay = GeneratedColumn<int>(
    'current_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalDaysMeta = const VerificationMeta(
    'totalDays',
  );
  @override
  late final GeneratedColumn<int> totalDays = GeneratedColumn<int>(
    'total_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _xpRewardMeta = const VerificationMeta(
    'xpReward',
  );
  @override
  late final GeneratedColumn<int> xpReward = GeneratedColumn<int>(
    'xp_reward',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<String> joinedAt = GeneratedColumn<String>(
    'joined_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<String> syncedAt = GeneratedColumn<String>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    challengeId,
    userId,
    title,
    attribute,
    currentDay,
    totalDays,
    status,
    xpReward,
    joinedAt,
    updatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'challenge_progress_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChallengeProgressTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('challenge_id')) {
      context.handle(
        _challengeIdMeta,
        challengeId.isAcceptableOrUnknown(
          data['challenge_id']!,
          _challengeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_challengeIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('attribute')) {
      context.handle(
        _attributeMeta,
        attribute.isAcceptableOrUnknown(data['attribute']!, _attributeMeta),
      );
    }
    if (data.containsKey('current_day')) {
      context.handle(
        _currentDayMeta,
        currentDay.isAcceptableOrUnknown(data['current_day']!, _currentDayMeta),
      );
    }
    if (data.containsKey('total_days')) {
      context.handle(
        _totalDaysMeta,
        totalDays.isAcceptableOrUnknown(data['total_days']!, _totalDaysMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('xp_reward')) {
      context.handle(
        _xpRewardMeta,
        xpReward.isAcceptableOrUnknown(data['xp_reward']!, _xpRewardMeta),
      );
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {challengeId};
  @override
  ChallengeProgressTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChallengeProgressTableData(
      challengeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}challenge_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      attribute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribute'],
      ),
      currentDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_day'],
      )!,
      totalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_days'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      xpReward: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_reward'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}joined_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $ChallengeProgressTableTable createAlias(String alias) {
    return $ChallengeProgressTableTable(attachedDatabase, alias);
  }
}

class ChallengeProgressTableData extends DataClass
    implements Insertable<ChallengeProgressTableData> {
  final String challengeId;
  final String userId;
  final String? title;
  final String? attribute;
  final int currentDay;
  final int totalDays;
  final String status;
  final int xpReward;
  final String? joinedAt;
  final String updatedAt;
  final String? syncedAt;
  const ChallengeProgressTableData({
    required this.challengeId,
    required this.userId,
    this.title,
    this.attribute,
    required this.currentDay,
    required this.totalDays,
    required this.status,
    required this.xpReward,
    this.joinedAt,
    required this.updatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['challenge_id'] = Variable<String>(challengeId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || attribute != null) {
      map['attribute'] = Variable<String>(attribute);
    }
    map['current_day'] = Variable<int>(currentDay);
    map['total_days'] = Variable<int>(totalDays);
    map['status'] = Variable<String>(status);
    map['xp_reward'] = Variable<int>(xpReward);
    if (!nullToAbsent || joinedAt != null) {
      map['joined_at'] = Variable<String>(joinedAt);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<String>(syncedAt);
    }
    return map;
  }

  ChallengeProgressTableCompanion toCompanion(bool nullToAbsent) {
    return ChallengeProgressTableCompanion(
      challengeId: Value(challengeId),
      userId: Value(userId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      attribute: attribute == null && nullToAbsent
          ? const Value.absent()
          : Value(attribute),
      currentDay: Value(currentDay),
      totalDays: Value(totalDays),
      status: Value(status),
      xpReward: Value(xpReward),
      joinedAt: joinedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(joinedAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory ChallengeProgressTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChallengeProgressTableData(
      challengeId: serializer.fromJson<String>(json['challengeId']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String?>(json['title']),
      attribute: serializer.fromJson<String?>(json['attribute']),
      currentDay: serializer.fromJson<int>(json['currentDay']),
      totalDays: serializer.fromJson<int>(json['totalDays']),
      status: serializer.fromJson<String>(json['status']),
      xpReward: serializer.fromJson<int>(json['xpReward']),
      joinedAt: serializer.fromJson<String?>(json['joinedAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncedAt: serializer.fromJson<String?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'challengeId': serializer.toJson<String>(challengeId),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String?>(title),
      'attribute': serializer.toJson<String?>(attribute),
      'currentDay': serializer.toJson<int>(currentDay),
      'totalDays': serializer.toJson<int>(totalDays),
      'status': serializer.toJson<String>(status),
      'xpReward': serializer.toJson<int>(xpReward),
      'joinedAt': serializer.toJson<String?>(joinedAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncedAt': serializer.toJson<String?>(syncedAt),
    };
  }

  ChallengeProgressTableData copyWith({
    String? challengeId,
    String? userId,
    Value<String?> title = const Value.absent(),
    Value<String?> attribute = const Value.absent(),
    int? currentDay,
    int? totalDays,
    String? status,
    int? xpReward,
    Value<String?> joinedAt = const Value.absent(),
    String? updatedAt,
    Value<String?> syncedAt = const Value.absent(),
  }) => ChallengeProgressTableData(
    challengeId: challengeId ?? this.challengeId,
    userId: userId ?? this.userId,
    title: title.present ? title.value : this.title,
    attribute: attribute.present ? attribute.value : this.attribute,
    currentDay: currentDay ?? this.currentDay,
    totalDays: totalDays ?? this.totalDays,
    status: status ?? this.status,
    xpReward: xpReward ?? this.xpReward,
    joinedAt: joinedAt.present ? joinedAt.value : this.joinedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  ChallengeProgressTableData copyWithCompanion(
    ChallengeProgressTableCompanion data,
  ) {
    return ChallengeProgressTableData(
      challengeId: data.challengeId.present
          ? data.challengeId.value
          : this.challengeId,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      attribute: data.attribute.present ? data.attribute.value : this.attribute,
      currentDay: data.currentDay.present
          ? data.currentDay.value
          : this.currentDay,
      totalDays: data.totalDays.present ? data.totalDays.value : this.totalDays,
      status: data.status.present ? data.status.value : this.status,
      xpReward: data.xpReward.present ? data.xpReward.value : this.xpReward,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChallengeProgressTableData(')
          ..write('challengeId: $challengeId, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('attribute: $attribute, ')
          ..write('currentDay: $currentDay, ')
          ..write('totalDays: $totalDays, ')
          ..write('status: $status, ')
          ..write('xpReward: $xpReward, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    challengeId,
    userId,
    title,
    attribute,
    currentDay,
    totalDays,
    status,
    xpReward,
    joinedAt,
    updatedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChallengeProgressTableData &&
          other.challengeId == this.challengeId &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.attribute == this.attribute &&
          other.currentDay == this.currentDay &&
          other.totalDays == this.totalDays &&
          other.status == this.status &&
          other.xpReward == this.xpReward &&
          other.joinedAt == this.joinedAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class ChallengeProgressTableCompanion
    extends UpdateCompanion<ChallengeProgressTableData> {
  final Value<String> challengeId;
  final Value<String> userId;
  final Value<String?> title;
  final Value<String?> attribute;
  final Value<int> currentDay;
  final Value<int> totalDays;
  final Value<String> status;
  final Value<int> xpReward;
  final Value<String?> joinedAt;
  final Value<String> updatedAt;
  final Value<String?> syncedAt;
  final Value<int> rowid;
  const ChallengeProgressTableCompanion({
    this.challengeId = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.attribute = const Value.absent(),
    this.currentDay = const Value.absent(),
    this.totalDays = const Value.absent(),
    this.status = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChallengeProgressTableCompanion.insert({
    required String challengeId,
    required String userId,
    this.title = const Value.absent(),
    this.attribute = const Value.absent(),
    this.currentDay = const Value.absent(),
    this.totalDays = const Value.absent(),
    this.status = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.joinedAt = const Value.absent(),
    required String updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : challengeId = Value(challengeId),
       userId = Value(userId),
       updatedAt = Value(updatedAt);
  static Insertable<ChallengeProgressTableData> custom({
    Expression<String>? challengeId,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? attribute,
    Expression<int>? currentDay,
    Expression<int>? totalDays,
    Expression<String>? status,
    Expression<int>? xpReward,
    Expression<String>? joinedAt,
    Expression<String>? updatedAt,
    Expression<String>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (challengeId != null) 'challenge_id': challengeId,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (attribute != null) 'attribute': attribute,
      if (currentDay != null) 'current_day': currentDay,
      if (totalDays != null) 'total_days': totalDays,
      if (status != null) 'status': status,
      if (xpReward != null) 'xp_reward': xpReward,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChallengeProgressTableCompanion copyWith({
    Value<String>? challengeId,
    Value<String>? userId,
    Value<String?>? title,
    Value<String?>? attribute,
    Value<int>? currentDay,
    Value<int>? totalDays,
    Value<String>? status,
    Value<int>? xpReward,
    Value<String?>? joinedAt,
    Value<String>? updatedAt,
    Value<String?>? syncedAt,
    Value<int>? rowid,
  }) {
    return ChallengeProgressTableCompanion(
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      attribute: attribute ?? this.attribute,
      currentDay: currentDay ?? this.currentDay,
      totalDays: totalDays ?? this.totalDays,
      status: status ?? this.status,
      xpReward: xpReward ?? this.xpReward,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (challengeId.present) {
      map['challenge_id'] = Variable<String>(challengeId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (attribute.present) {
      map['attribute'] = Variable<String>(attribute.value);
    }
    if (currentDay.present) {
      map['current_day'] = Variable<int>(currentDay.value);
    }
    if (totalDays.present) {
      map['total_days'] = Variable<int>(totalDays.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (xpReward.present) {
      map['xp_reward'] = Variable<int>(xpReward.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<String>(joinedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<String>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChallengeProgressTableCompanion(')
          ..write('challengeId: $challengeId, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('attribute: $attribute, ')
          ..write('currentDay: $currentDay, ')
          ..write('totalDays: $totalDays, ')
          ..write('status: $status, ')
          ..write('xpReward: $xpReward, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TribeStatsTableTable extends TribeStatsTable
    with TableInfo<$TribeStatsTableTable, TribeStatsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TribeStatsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tribeIdMeta = const VerificationMeta(
    'tribeId',
  );
  @override
  late final GeneratedColumn<String> tribeId = GeneratedColumn<String>(
    'tribe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tribeNameMeta = const VerificationMeta(
    'tribeName',
  );
  @override
  late final GeneratedColumn<String> tribeName = GeneratedColumn<String>(
    'tribe_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archetypeIdMeta = const VerificationMeta(
    'archetypeId',
  );
  @override
  late final GeneratedColumn<String> archetypeId = GeneratedColumn<String>(
    'archetype_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memberCountMeta = const VerificationMeta(
    'memberCount',
  );
  @override
  late final GeneratedColumn<int> memberCount = GeneratedColumn<int>(
    'member_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalXpMeta = const VerificationMeta(
    'totalXp',
  );
  @override
  late final GeneratedColumn<int> totalXp = GeneratedColumn<int>(
    'total_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalHabitsCompletedMeta =
      const VerificationMeta('totalHabitsCompleted');
  @override
  late final GeneratedColumn<int> totalHabitsCompleted = GeneratedColumn<int>(
    'total_habits_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalChallengesCompletedMeta =
      const VerificationMeta('totalChallengesCompleted');
  @override
  late final GeneratedColumn<int> totalChallengesCompleted =
      GeneratedColumn<int>(
        'total_challenges_completed',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _userContributionXpMeta =
      const VerificationMeta('userContributionXp');
  @override
  late final GeneratedColumn<int> userContributionXp = GeneratedColumn<int>(
    'user_contribution_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _userHabitsCompletedMeta =
      const VerificationMeta('userHabitsCompleted');
  @override
  late final GeneratedColumn<int> userHabitsCompleted = GeneratedColumn<int>(
    'user_habits_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _userChallengesCompletedMeta =
      const VerificationMeta('userChallengesCompleted');
  @override
  late final GeneratedColumn<int> userChallengesCompleted =
      GeneratedColumn<int>(
        'user_challenges_completed',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<String> syncedAt = GeneratedColumn<String>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tribeId,
    tribeName,
    archetypeId,
    memberCount,
    totalXp,
    totalHabitsCompleted,
    totalChallengesCompleted,
    userContributionXp,
    userHabitsCompleted,
    userChallengesCompleted,
    updatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tribe_stats_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TribeStatsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tribe_id')) {
      context.handle(
        _tribeIdMeta,
        tribeId.isAcceptableOrUnknown(data['tribe_id']!, _tribeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tribeIdMeta);
    }
    if (data.containsKey('tribe_name')) {
      context.handle(
        _tribeNameMeta,
        tribeName.isAcceptableOrUnknown(data['tribe_name']!, _tribeNameMeta),
      );
    }
    if (data.containsKey('archetype_id')) {
      context.handle(
        _archetypeIdMeta,
        archetypeId.isAcceptableOrUnknown(
          data['archetype_id']!,
          _archetypeIdMeta,
        ),
      );
    }
    if (data.containsKey('member_count')) {
      context.handle(
        _memberCountMeta,
        memberCount.isAcceptableOrUnknown(
          data['member_count']!,
          _memberCountMeta,
        ),
      );
    }
    if (data.containsKey('total_xp')) {
      context.handle(
        _totalXpMeta,
        totalXp.isAcceptableOrUnknown(data['total_xp']!, _totalXpMeta),
      );
    }
    if (data.containsKey('total_habits_completed')) {
      context.handle(
        _totalHabitsCompletedMeta,
        totalHabitsCompleted.isAcceptableOrUnknown(
          data['total_habits_completed']!,
          _totalHabitsCompletedMeta,
        ),
      );
    }
    if (data.containsKey('total_challenges_completed')) {
      context.handle(
        _totalChallengesCompletedMeta,
        totalChallengesCompleted.isAcceptableOrUnknown(
          data['total_challenges_completed']!,
          _totalChallengesCompletedMeta,
        ),
      );
    }
    if (data.containsKey('user_contribution_xp')) {
      context.handle(
        _userContributionXpMeta,
        userContributionXp.isAcceptableOrUnknown(
          data['user_contribution_xp']!,
          _userContributionXpMeta,
        ),
      );
    }
    if (data.containsKey('user_habits_completed')) {
      context.handle(
        _userHabitsCompletedMeta,
        userHabitsCompleted.isAcceptableOrUnknown(
          data['user_habits_completed']!,
          _userHabitsCompletedMeta,
        ),
      );
    }
    if (data.containsKey('user_challenges_completed')) {
      context.handle(
        _userChallengesCompletedMeta,
        userChallengesCompleted.isAcceptableOrUnknown(
          data['user_challenges_completed']!,
          _userChallengesCompletedMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tribeId};
  @override
  TribeStatsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TribeStatsTableData(
      tribeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tribe_id'],
      )!,
      tribeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tribe_name'],
      ),
      archetypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archetype_id'],
      ),
      memberCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_count'],
      )!,
      totalXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_xp'],
      )!,
      totalHabitsCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_habits_completed'],
      )!,
      totalChallengesCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_challenges_completed'],
      )!,
      userContributionXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_contribution_xp'],
      )!,
      userHabitsCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_habits_completed'],
      )!,
      userChallengesCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_challenges_completed'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $TribeStatsTableTable createAlias(String alias) {
    return $TribeStatsTableTable(attachedDatabase, alias);
  }
}

class TribeStatsTableData extends DataClass
    implements Insertable<TribeStatsTableData> {
  final String tribeId;
  final String? tribeName;
  final String? archetypeId;
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  final int userContributionXp;
  final int userHabitsCompleted;
  final int userChallengesCompleted;
  final String updatedAt;
  final String? syncedAt;
  const TribeStatsTableData({
    required this.tribeId,
    this.tribeName,
    this.archetypeId,
    required this.memberCount,
    required this.totalXp,
    required this.totalHabitsCompleted,
    required this.totalChallengesCompleted,
    required this.userContributionXp,
    required this.userHabitsCompleted,
    required this.userChallengesCompleted,
    required this.updatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tribe_id'] = Variable<String>(tribeId);
    if (!nullToAbsent || tribeName != null) {
      map['tribe_name'] = Variable<String>(tribeName);
    }
    if (!nullToAbsent || archetypeId != null) {
      map['archetype_id'] = Variable<String>(archetypeId);
    }
    map['member_count'] = Variable<int>(memberCount);
    map['total_xp'] = Variable<int>(totalXp);
    map['total_habits_completed'] = Variable<int>(totalHabitsCompleted);
    map['total_challenges_completed'] = Variable<int>(totalChallengesCompleted);
    map['user_contribution_xp'] = Variable<int>(userContributionXp);
    map['user_habits_completed'] = Variable<int>(userHabitsCompleted);
    map['user_challenges_completed'] = Variable<int>(userChallengesCompleted);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<String>(syncedAt);
    }
    return map;
  }

  TribeStatsTableCompanion toCompanion(bool nullToAbsent) {
    return TribeStatsTableCompanion(
      tribeId: Value(tribeId),
      tribeName: tribeName == null && nullToAbsent
          ? const Value.absent()
          : Value(tribeName),
      archetypeId: archetypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(archetypeId),
      memberCount: Value(memberCount),
      totalXp: Value(totalXp),
      totalHabitsCompleted: Value(totalHabitsCompleted),
      totalChallengesCompleted: Value(totalChallengesCompleted),
      userContributionXp: Value(userContributionXp),
      userHabitsCompleted: Value(userHabitsCompleted),
      userChallengesCompleted: Value(userChallengesCompleted),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory TribeStatsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TribeStatsTableData(
      tribeId: serializer.fromJson<String>(json['tribeId']),
      tribeName: serializer.fromJson<String?>(json['tribeName']),
      archetypeId: serializer.fromJson<String?>(json['archetypeId']),
      memberCount: serializer.fromJson<int>(json['memberCount']),
      totalXp: serializer.fromJson<int>(json['totalXp']),
      totalHabitsCompleted: serializer.fromJson<int>(
        json['totalHabitsCompleted'],
      ),
      totalChallengesCompleted: serializer.fromJson<int>(
        json['totalChallengesCompleted'],
      ),
      userContributionXp: serializer.fromJson<int>(json['userContributionXp']),
      userHabitsCompleted: serializer.fromJson<int>(
        json['userHabitsCompleted'],
      ),
      userChallengesCompleted: serializer.fromJson<int>(
        json['userChallengesCompleted'],
      ),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncedAt: serializer.fromJson<String?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tribeId': serializer.toJson<String>(tribeId),
      'tribeName': serializer.toJson<String?>(tribeName),
      'archetypeId': serializer.toJson<String?>(archetypeId),
      'memberCount': serializer.toJson<int>(memberCount),
      'totalXp': serializer.toJson<int>(totalXp),
      'totalHabitsCompleted': serializer.toJson<int>(totalHabitsCompleted),
      'totalChallengesCompleted': serializer.toJson<int>(
        totalChallengesCompleted,
      ),
      'userContributionXp': serializer.toJson<int>(userContributionXp),
      'userHabitsCompleted': serializer.toJson<int>(userHabitsCompleted),
      'userChallengesCompleted': serializer.toJson<int>(
        userChallengesCompleted,
      ),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncedAt': serializer.toJson<String?>(syncedAt),
    };
  }

  TribeStatsTableData copyWith({
    String? tribeId,
    Value<String?> tribeName = const Value.absent(),
    Value<String?> archetypeId = const Value.absent(),
    int? memberCount,
    int? totalXp,
    int? totalHabitsCompleted,
    int? totalChallengesCompleted,
    int? userContributionXp,
    int? userHabitsCompleted,
    int? userChallengesCompleted,
    String? updatedAt,
    Value<String?> syncedAt = const Value.absent(),
  }) => TribeStatsTableData(
    tribeId: tribeId ?? this.tribeId,
    tribeName: tribeName.present ? tribeName.value : this.tribeName,
    archetypeId: archetypeId.present ? archetypeId.value : this.archetypeId,
    memberCount: memberCount ?? this.memberCount,
    totalXp: totalXp ?? this.totalXp,
    totalHabitsCompleted: totalHabitsCompleted ?? this.totalHabitsCompleted,
    totalChallengesCompleted:
        totalChallengesCompleted ?? this.totalChallengesCompleted,
    userContributionXp: userContributionXp ?? this.userContributionXp,
    userHabitsCompleted: userHabitsCompleted ?? this.userHabitsCompleted,
    userChallengesCompleted:
        userChallengesCompleted ?? this.userChallengesCompleted,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  TribeStatsTableData copyWithCompanion(TribeStatsTableCompanion data) {
    return TribeStatsTableData(
      tribeId: data.tribeId.present ? data.tribeId.value : this.tribeId,
      tribeName: data.tribeName.present ? data.tribeName.value : this.tribeName,
      archetypeId: data.archetypeId.present
          ? data.archetypeId.value
          : this.archetypeId,
      memberCount: data.memberCount.present
          ? data.memberCount.value
          : this.memberCount,
      totalXp: data.totalXp.present ? data.totalXp.value : this.totalXp,
      totalHabitsCompleted: data.totalHabitsCompleted.present
          ? data.totalHabitsCompleted.value
          : this.totalHabitsCompleted,
      totalChallengesCompleted: data.totalChallengesCompleted.present
          ? data.totalChallengesCompleted.value
          : this.totalChallengesCompleted,
      userContributionXp: data.userContributionXp.present
          ? data.userContributionXp.value
          : this.userContributionXp,
      userHabitsCompleted: data.userHabitsCompleted.present
          ? data.userHabitsCompleted.value
          : this.userHabitsCompleted,
      userChallengesCompleted: data.userChallengesCompleted.present
          ? data.userChallengesCompleted.value
          : this.userChallengesCompleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TribeStatsTableData(')
          ..write('tribeId: $tribeId, ')
          ..write('tribeName: $tribeName, ')
          ..write('archetypeId: $archetypeId, ')
          ..write('memberCount: $memberCount, ')
          ..write('totalXp: $totalXp, ')
          ..write('totalHabitsCompleted: $totalHabitsCompleted, ')
          ..write('totalChallengesCompleted: $totalChallengesCompleted, ')
          ..write('userContributionXp: $userContributionXp, ')
          ..write('userHabitsCompleted: $userHabitsCompleted, ')
          ..write('userChallengesCompleted: $userChallengesCompleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tribeId,
    tribeName,
    archetypeId,
    memberCount,
    totalXp,
    totalHabitsCompleted,
    totalChallengesCompleted,
    userContributionXp,
    userHabitsCompleted,
    userChallengesCompleted,
    updatedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TribeStatsTableData &&
          other.tribeId == this.tribeId &&
          other.tribeName == this.tribeName &&
          other.archetypeId == this.archetypeId &&
          other.memberCount == this.memberCount &&
          other.totalXp == this.totalXp &&
          other.totalHabitsCompleted == this.totalHabitsCompleted &&
          other.totalChallengesCompleted == this.totalChallengesCompleted &&
          other.userContributionXp == this.userContributionXp &&
          other.userHabitsCompleted == this.userHabitsCompleted &&
          other.userChallengesCompleted == this.userChallengesCompleted &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class TribeStatsTableCompanion extends UpdateCompanion<TribeStatsTableData> {
  final Value<String> tribeId;
  final Value<String?> tribeName;
  final Value<String?> archetypeId;
  final Value<int> memberCount;
  final Value<int> totalXp;
  final Value<int> totalHabitsCompleted;
  final Value<int> totalChallengesCompleted;
  final Value<int> userContributionXp;
  final Value<int> userHabitsCompleted;
  final Value<int> userChallengesCompleted;
  final Value<String> updatedAt;
  final Value<String?> syncedAt;
  final Value<int> rowid;
  const TribeStatsTableCompanion({
    this.tribeId = const Value.absent(),
    this.tribeName = const Value.absent(),
    this.archetypeId = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.totalHabitsCompleted = const Value.absent(),
    this.totalChallengesCompleted = const Value.absent(),
    this.userContributionXp = const Value.absent(),
    this.userHabitsCompleted = const Value.absent(),
    this.userChallengesCompleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TribeStatsTableCompanion.insert({
    required String tribeId,
    this.tribeName = const Value.absent(),
    this.archetypeId = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.totalHabitsCompleted = const Value.absent(),
    this.totalChallengesCompleted = const Value.absent(),
    this.userContributionXp = const Value.absent(),
    this.userHabitsCompleted = const Value.absent(),
    this.userChallengesCompleted = const Value.absent(),
    required String updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tribeId = Value(tribeId),
       updatedAt = Value(updatedAt);
  static Insertable<TribeStatsTableData> custom({
    Expression<String>? tribeId,
    Expression<String>? tribeName,
    Expression<String>? archetypeId,
    Expression<int>? memberCount,
    Expression<int>? totalXp,
    Expression<int>? totalHabitsCompleted,
    Expression<int>? totalChallengesCompleted,
    Expression<int>? userContributionXp,
    Expression<int>? userHabitsCompleted,
    Expression<int>? userChallengesCompleted,
    Expression<String>? updatedAt,
    Expression<String>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tribeId != null) 'tribe_id': tribeId,
      if (tribeName != null) 'tribe_name': tribeName,
      if (archetypeId != null) 'archetype_id': archetypeId,
      if (memberCount != null) 'member_count': memberCount,
      if (totalXp != null) 'total_xp': totalXp,
      if (totalHabitsCompleted != null)
        'total_habits_completed': totalHabitsCompleted,
      if (totalChallengesCompleted != null)
        'total_challenges_completed': totalChallengesCompleted,
      if (userContributionXp != null)
        'user_contribution_xp': userContributionXp,
      if (userHabitsCompleted != null)
        'user_habits_completed': userHabitsCompleted,
      if (userChallengesCompleted != null)
        'user_challenges_completed': userChallengesCompleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TribeStatsTableCompanion copyWith({
    Value<String>? tribeId,
    Value<String?>? tribeName,
    Value<String?>? archetypeId,
    Value<int>? memberCount,
    Value<int>? totalXp,
    Value<int>? totalHabitsCompleted,
    Value<int>? totalChallengesCompleted,
    Value<int>? userContributionXp,
    Value<int>? userHabitsCompleted,
    Value<int>? userChallengesCompleted,
    Value<String>? updatedAt,
    Value<String?>? syncedAt,
    Value<int>? rowid,
  }) {
    return TribeStatsTableCompanion(
      tribeId: tribeId ?? this.tribeId,
      tribeName: tribeName ?? this.tribeName,
      archetypeId: archetypeId ?? this.archetypeId,
      memberCount: memberCount ?? this.memberCount,
      totalXp: totalXp ?? this.totalXp,
      totalHabitsCompleted: totalHabitsCompleted ?? this.totalHabitsCompleted,
      totalChallengesCompleted:
          totalChallengesCompleted ?? this.totalChallengesCompleted,
      userContributionXp: userContributionXp ?? this.userContributionXp,
      userHabitsCompleted: userHabitsCompleted ?? this.userHabitsCompleted,
      userChallengesCompleted:
          userChallengesCompleted ?? this.userChallengesCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tribeId.present) {
      map['tribe_id'] = Variable<String>(tribeId.value);
    }
    if (tribeName.present) {
      map['tribe_name'] = Variable<String>(tribeName.value);
    }
    if (archetypeId.present) {
      map['archetype_id'] = Variable<String>(archetypeId.value);
    }
    if (memberCount.present) {
      map['member_count'] = Variable<int>(memberCount.value);
    }
    if (totalXp.present) {
      map['total_xp'] = Variable<int>(totalXp.value);
    }
    if (totalHabitsCompleted.present) {
      map['total_habits_completed'] = Variable<int>(totalHabitsCompleted.value);
    }
    if (totalChallengesCompleted.present) {
      map['total_challenges_completed'] = Variable<int>(
        totalChallengesCompleted.value,
      );
    }
    if (userContributionXp.present) {
      map['user_contribution_xp'] = Variable<int>(userContributionXp.value);
    }
    if (userHabitsCompleted.present) {
      map['user_habits_completed'] = Variable<int>(userHabitsCompleted.value);
    }
    if (userChallengesCompleted.present) {
      map['user_challenges_completed'] = Variable<int>(
        userChallengesCompleted.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<String>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TribeStatsTableCompanion(')
          ..write('tribeId: $tribeId, ')
          ..write('tribeName: $tribeName, ')
          ..write('archetypeId: $archetypeId, ')
          ..write('memberCount: $memberCount, ')
          ..write('totalXp: $totalXp, ')
          ..write('totalHabitsCompleted: $totalHabitsCompleted, ')
          ..write('totalChallengesCompleted: $totalChallengesCompleted, ')
          ..write('userContributionXp: $userContributionXp, ')
          ..write('userHabitsCompleted: $userHabitsCompleted, ')
          ..write('userChallengesCompleted: $userChallengesCompleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LeaderboardEntriesTableTable extends LeaderboardEntriesTable
    with TableInfo<$LeaderboardEntriesTableTable, LeaderboardEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LeaderboardEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tribeIdMeta = const VerificationMeta(
    'tribeId',
  );
  @override
  late final GeneratedColumn<String> tribeId = GeneratedColumn<String>(
    'tribe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Anonymous'),
  );
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
    'xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archetypeMeta = const VerificationMeta(
    'archetype',
  );
  @override
  late final GeneratedColumn<String> archetype = GeneratedColumn<String>(
    'archetype',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<String> syncedAt = GeneratedColumn<String>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tribeId,
    userId,
    userName,
    xp,
    level,
    rank,
    archetype,
    updatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'leaderboard_entries_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LeaderboardEntriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tribe_id')) {
      context.handle(
        _tribeIdMeta,
        tribeId.isAcceptableOrUnknown(data['tribe_id']!, _tribeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tribeIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    }
    if (data.containsKey('archetype')) {
      context.handle(
        _archetypeMeta,
        archetype.isAcceptableOrUnknown(data['archetype']!, _archetypeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LeaderboardEntriesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LeaderboardEntriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tribeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tribe_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      )!,
      xp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      )!,
      archetype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archetype'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $LeaderboardEntriesTableTable createAlias(String alias) {
    return $LeaderboardEntriesTableTable(attachedDatabase, alias);
  }
}

class LeaderboardEntriesTableData extends DataClass
    implements Insertable<LeaderboardEntriesTableData> {
  final String id;
  final String tribeId;
  final String userId;
  final String userName;
  final int xp;
  final int level;
  final int rank;
  final String? archetype;
  final String updatedAt;
  final String? syncedAt;
  const LeaderboardEntriesTableData({
    required this.id,
    required this.tribeId,
    required this.userId,
    required this.userName,
    required this.xp,
    required this.level,
    required this.rank,
    this.archetype,
    required this.updatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tribe_id'] = Variable<String>(tribeId);
    map['user_id'] = Variable<String>(userId);
    map['user_name'] = Variable<String>(userName);
    map['xp'] = Variable<int>(xp);
    map['level'] = Variable<int>(level);
    map['rank'] = Variable<int>(rank);
    if (!nullToAbsent || archetype != null) {
      map['archetype'] = Variable<String>(archetype);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<String>(syncedAt);
    }
    return map;
  }

  LeaderboardEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return LeaderboardEntriesTableCompanion(
      id: Value(id),
      tribeId: Value(tribeId),
      userId: Value(userId),
      userName: Value(userName),
      xp: Value(xp),
      level: Value(level),
      rank: Value(rank),
      archetype: archetype == null && nullToAbsent
          ? const Value.absent()
          : Value(archetype),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory LeaderboardEntriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LeaderboardEntriesTableData(
      id: serializer.fromJson<String>(json['id']),
      tribeId: serializer.fromJson<String>(json['tribeId']),
      userId: serializer.fromJson<String>(json['userId']),
      userName: serializer.fromJson<String>(json['userName']),
      xp: serializer.fromJson<int>(json['xp']),
      level: serializer.fromJson<int>(json['level']),
      rank: serializer.fromJson<int>(json['rank']),
      archetype: serializer.fromJson<String?>(json['archetype']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncedAt: serializer.fromJson<String?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tribeId': serializer.toJson<String>(tribeId),
      'userId': serializer.toJson<String>(userId),
      'userName': serializer.toJson<String>(userName),
      'xp': serializer.toJson<int>(xp),
      'level': serializer.toJson<int>(level),
      'rank': serializer.toJson<int>(rank),
      'archetype': serializer.toJson<String?>(archetype),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncedAt': serializer.toJson<String?>(syncedAt),
    };
  }

  LeaderboardEntriesTableData copyWith({
    String? id,
    String? tribeId,
    String? userId,
    String? userName,
    int? xp,
    int? level,
    int? rank,
    Value<String?> archetype = const Value.absent(),
    String? updatedAt,
    Value<String?> syncedAt = const Value.absent(),
  }) => LeaderboardEntriesTableData(
    id: id ?? this.id,
    tribeId: tribeId ?? this.tribeId,
    userId: userId ?? this.userId,
    userName: userName ?? this.userName,
    xp: xp ?? this.xp,
    level: level ?? this.level,
    rank: rank ?? this.rank,
    archetype: archetype.present ? archetype.value : this.archetype,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  LeaderboardEntriesTableData copyWithCompanion(
    LeaderboardEntriesTableCompanion data,
  ) {
    return LeaderboardEntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      tribeId: data.tribeId.present ? data.tribeId.value : this.tribeId,
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      xp: data.xp.present ? data.xp.value : this.xp,
      level: data.level.present ? data.level.value : this.level,
      rank: data.rank.present ? data.rank.value : this.rank,
      archetype: data.archetype.present ? data.archetype.value : this.archetype,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LeaderboardEntriesTableData(')
          ..write('id: $id, ')
          ..write('tribeId: $tribeId, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('xp: $xp, ')
          ..write('level: $level, ')
          ..write('rank: $rank, ')
          ..write('archetype: $archetype, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tribeId,
    userId,
    userName,
    xp,
    level,
    rank,
    archetype,
    updatedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LeaderboardEntriesTableData &&
          other.id == this.id &&
          other.tribeId == this.tribeId &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.xp == this.xp &&
          other.level == this.level &&
          other.rank == this.rank &&
          other.archetype == this.archetype &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class LeaderboardEntriesTableCompanion
    extends UpdateCompanion<LeaderboardEntriesTableData> {
  final Value<String> id;
  final Value<String> tribeId;
  final Value<String> userId;
  final Value<String> userName;
  final Value<int> xp;
  final Value<int> level;
  final Value<int> rank;
  final Value<String?> archetype;
  final Value<String> updatedAt;
  final Value<String?> syncedAt;
  final Value<int> rowid;
  const LeaderboardEntriesTableCompanion({
    this.id = const Value.absent(),
    this.tribeId = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.xp = const Value.absent(),
    this.level = const Value.absent(),
    this.rank = const Value.absent(),
    this.archetype = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LeaderboardEntriesTableCompanion.insert({
    required String id,
    required String tribeId,
    required String userId,
    this.userName = const Value.absent(),
    this.xp = const Value.absent(),
    this.level = const Value.absent(),
    this.rank = const Value.absent(),
    this.archetype = const Value.absent(),
    required String updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tribeId = Value(tribeId),
       userId = Value(userId),
       updatedAt = Value(updatedAt);
  static Insertable<LeaderboardEntriesTableData> custom({
    Expression<String>? id,
    Expression<String>? tribeId,
    Expression<String>? userId,
    Expression<String>? userName,
    Expression<int>? xp,
    Expression<int>? level,
    Expression<int>? rank,
    Expression<String>? archetype,
    Expression<String>? updatedAt,
    Expression<String>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tribeId != null) 'tribe_id': tribeId,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (xp != null) 'xp': xp,
      if (level != null) 'level': level,
      if (rank != null) 'rank': rank,
      if (archetype != null) 'archetype': archetype,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LeaderboardEntriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? tribeId,
    Value<String>? userId,
    Value<String>? userName,
    Value<int>? xp,
    Value<int>? level,
    Value<int>? rank,
    Value<String?>? archetype,
    Value<String>? updatedAt,
    Value<String?>? syncedAt,
    Value<int>? rowid,
  }) {
    return LeaderboardEntriesTableCompanion(
      id: id ?? this.id,
      tribeId: tribeId ?? this.tribeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      rank: rank ?? this.rank,
      archetype: archetype ?? this.archetype,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tribeId.present) {
      map['tribe_id'] = Variable<String>(tribeId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (archetype.present) {
      map['archetype'] = Variable<String>(archetype.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<String>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LeaderboardEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('tribeId: $tribeId, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('xp: $xp, ')
          ..write('level: $level, ')
          ..write('rank: $rank, ')
          ..write('archetype: $archetype, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BlueprintsTableTable extends BlueprintsTable
    with TableInfo<$BlueprintsTableTable, BlueprintsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlueprintsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _habitCountMeta = const VerificationMeta(
    'habitCount',
  );
  @override
  late final GeneratedColumn<int> habitCount = GeneratedColumn<int>(
    'habit_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFallbackMeta = const VerificationMeta(
    'isFallback',
  );
  @override
  late final GeneratedColumn<int> isFallback = GeneratedColumn<int>(
    'is_fallback',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    category,
    difficulty,
    imageUrl,
    habitCount,
    isFallback,
    dataJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blueprints_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlueprintsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('habit_count')) {
      context.handle(
        _habitCountMeta,
        habitCount.isAcceptableOrUnknown(data['habit_count']!, _habitCountMeta),
      );
    }
    if (data.containsKey('is_fallback')) {
      context.handle(
        _isFallbackMeta,
        isFallback.isAcceptableOrUnknown(data['is_fallback']!, _isFallbackMeta),
      );
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlueprintsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlueprintsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      habitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_count'],
      )!,
      isFallback: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_fallback'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BlueprintsTableTable createAlias(String alias) {
    return $BlueprintsTableTable(attachedDatabase, alias);
  }
}

class BlueprintsTableData extends DataClass
    implements Insertable<BlueprintsTableData> {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? difficulty;
  final String? imageUrl;
  final int habitCount;
  final int isFallback;
  final String? dataJson;
  final String updatedAt;
  const BlueprintsTableData({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.difficulty,
    this.imageUrl,
    required this.habitCount,
    required this.isFallback,
    this.dataJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<String>(difficulty);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['habit_count'] = Variable<int>(habitCount);
    map['is_fallback'] = Variable<int>(isFallback);
    if (!nullToAbsent || dataJson != null) {
      map['data_json'] = Variable<String>(dataJson);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  BlueprintsTableCompanion toCompanion(bool nullToAbsent) {
    return BlueprintsTableCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      habitCount: Value(habitCount),
      isFallback: Value(isFallback),
      dataJson: dataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(dataJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory BlueprintsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlueprintsTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String?>(json['category']),
      difficulty: serializer.fromJson<String?>(json['difficulty']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      habitCount: serializer.fromJson<int>(json['habitCount']),
      isFallback: serializer.fromJson<int>(json['isFallback']),
      dataJson: serializer.fromJson<String?>(json['dataJson']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String?>(category),
      'difficulty': serializer.toJson<String?>(difficulty),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'habitCount': serializer.toJson<int>(habitCount),
      'isFallback': serializer.toJson<int>(isFallback),
      'dataJson': serializer.toJson<String?>(dataJson),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  BlueprintsTableData copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<String?> difficulty = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    int? habitCount,
    int? isFallback,
    Value<String?> dataJson = const Value.absent(),
    String? updatedAt,
  }) => BlueprintsTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    category: category.present ? category.value : this.category,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    habitCount: habitCount ?? this.habitCount,
    isFallback: isFallback ?? this.isFallback,
    dataJson: dataJson.present ? dataJson.value : this.dataJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BlueprintsTableData copyWithCompanion(BlueprintsTableCompanion data) {
    return BlueprintsTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      habitCount: data.habitCount.present
          ? data.habitCount.value
          : this.habitCount,
      isFallback: data.isFallback.present
          ? data.isFallback.value
          : this.isFallback,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlueprintsTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('difficulty: $difficulty, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('habitCount: $habitCount, ')
          ..write('isFallback: $isFallback, ')
          ..write('dataJson: $dataJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    category,
    difficulty,
    imageUrl,
    habitCount,
    isFallback,
    dataJson,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlueprintsTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.difficulty == this.difficulty &&
          other.imageUrl == this.imageUrl &&
          other.habitCount == this.habitCount &&
          other.isFallback == this.isFallback &&
          other.dataJson == this.dataJson &&
          other.updatedAt == this.updatedAt);
}

class BlueprintsTableCompanion extends UpdateCompanion<BlueprintsTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> category;
  final Value<String?> difficulty;
  final Value<String?> imageUrl;
  final Value<int> habitCount;
  final Value<int> isFallback;
  final Value<String?> dataJson;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const BlueprintsTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.habitCount = const Value.absent(),
    this.isFallback = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlueprintsTableCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.habitCount = const Value.absent(),
    this.isFallback = const Value.absent(),
    this.dataJson = const Value.absent(),
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       updatedAt = Value(updatedAt);
  static Insertable<BlueprintsTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? difficulty,
    Expression<String>? imageUrl,
    Expression<int>? habitCount,
    Expression<int>? isFallback,
    Expression<String>? dataJson,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (difficulty != null) 'difficulty': difficulty,
      if (imageUrl != null) 'image_url': imageUrl,
      if (habitCount != null) 'habit_count': habitCount,
      if (isFallback != null) 'is_fallback': isFallback,
      if (dataJson != null) 'data_json': dataJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlueprintsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? category,
    Value<String?>? difficulty,
    Value<String?>? imageUrl,
    Value<int>? habitCount,
    Value<int>? isFallback,
    Value<String?>? dataJson,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return BlueprintsTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      imageUrl: imageUrl ?? this.imageUrl,
      habitCount: habitCount ?? this.habitCount,
      isFallback: isFallback ?? this.isFallback,
      dataJson: dataJson ?? this.dataJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (habitCount.present) {
      map['habit_count'] = Variable<int>(habitCount.value);
    }
    if (isFallback.present) {
      map['is_fallback'] = Variable<int>(isFallback.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlueprintsTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('difficulty: $difficulty, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('habitCount: $habitCount, ')
          ..write('isFallback: $isFallback, ')
          ..write('dataJson: $dataJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MutationQueueTableTable extends MutationQueueTable
    with TableInfo<$MutationQueueTableTable, MutationQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MutationQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _collectionPathMeta = const VerificationMeta(
    'collectionPath',
  );
  @override
  late final GeneratedColumn<String> collectionPath = GeneratedColumn<String>(
    'collection_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    collectionPath,
    documentId,
    operation,
    dataJson,
    createdAt,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mutation_queue_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MutationQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('collection_path')) {
      context.handle(
        _collectionPathMeta,
        collectionPath.isAcceptableOrUnknown(
          data['collection_path']!,
          _collectionPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionPathMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MutationQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MutationQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      collectionPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_path'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $MutationQueueTableTable createAlias(String alias) {
    return $MutationQueueTableTable(attachedDatabase, alias);
  }
}

class MutationQueueTableData extends DataClass
    implements Insertable<MutationQueueTableData> {
  final int id;
  final String collectionPath;
  final String documentId;
  final String operation;
  final String? dataJson;
  final String createdAt;
  final int retryCount;
  const MutationQueueTableData({
    required this.id,
    required this.collectionPath,
    required this.documentId,
    required this.operation,
    this.dataJson,
    required this.createdAt,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['collection_path'] = Variable<String>(collectionPath);
    map['document_id'] = Variable<String>(documentId);
    map['operation'] = Variable<String>(operation);
    if (!nullToAbsent || dataJson != null) {
      map['data_json'] = Variable<String>(dataJson);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  MutationQueueTableCompanion toCompanion(bool nullToAbsent) {
    return MutationQueueTableCompanion(
      id: Value(id),
      collectionPath: Value(collectionPath),
      documentId: Value(documentId),
      operation: Value(operation),
      dataJson: dataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(dataJson),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
    );
  }

  factory MutationQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MutationQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      collectionPath: serializer.fromJson<String>(json['collectionPath']),
      documentId: serializer.fromJson<String>(json['documentId']),
      operation: serializer.fromJson<String>(json['operation']),
      dataJson: serializer.fromJson<String?>(json['dataJson']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'collectionPath': serializer.toJson<String>(collectionPath),
      'documentId': serializer.toJson<String>(documentId),
      'operation': serializer.toJson<String>(operation),
      'dataJson': serializer.toJson<String?>(dataJson),
      'createdAt': serializer.toJson<String>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  MutationQueueTableData copyWith({
    int? id,
    String? collectionPath,
    String? documentId,
    String? operation,
    Value<String?> dataJson = const Value.absent(),
    String? createdAt,
    int? retryCount,
  }) => MutationQueueTableData(
    id: id ?? this.id,
    collectionPath: collectionPath ?? this.collectionPath,
    documentId: documentId ?? this.documentId,
    operation: operation ?? this.operation,
    dataJson: dataJson.present ? dataJson.value : this.dataJson,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
  );
  MutationQueueTableData copyWithCompanion(MutationQueueTableCompanion data) {
    return MutationQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      collectionPath: data.collectionPath.present
          ? data.collectionPath.value
          : this.collectionPath,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      operation: data.operation.present ? data.operation.value : this.operation,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MutationQueueTableData(')
          ..write('id: $id, ')
          ..write('collectionPath: $collectionPath, ')
          ..write('documentId: $documentId, ')
          ..write('operation: $operation, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    collectionPath,
    documentId,
    operation,
    dataJson,
    createdAt,
    retryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MutationQueueTableData &&
          other.id == this.id &&
          other.collectionPath == this.collectionPath &&
          other.documentId == this.documentId &&
          other.operation == this.operation &&
          other.dataJson == this.dataJson &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount);
}

class MutationQueueTableCompanion
    extends UpdateCompanion<MutationQueueTableData> {
  final Value<int> id;
  final Value<String> collectionPath;
  final Value<String> documentId;
  final Value<String> operation;
  final Value<String?> dataJson;
  final Value<String> createdAt;
  final Value<int> retryCount;
  const MutationQueueTableCompanion({
    this.id = const Value.absent(),
    this.collectionPath = const Value.absent(),
    this.documentId = const Value.absent(),
    this.operation = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  MutationQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String collectionPath,
    required String documentId,
    required String operation,
    this.dataJson = const Value.absent(),
    required String createdAt,
    this.retryCount = const Value.absent(),
  }) : collectionPath = Value(collectionPath),
       documentId = Value(documentId),
       operation = Value(operation),
       createdAt = Value(createdAt);
  static Insertable<MutationQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? collectionPath,
    Expression<String>? documentId,
    Expression<String>? operation,
    Expression<String>? dataJson,
    Expression<String>? createdAt,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectionPath != null) 'collection_path': collectionPath,
      if (documentId != null) 'document_id': documentId,
      if (operation != null) 'operation': operation,
      if (dataJson != null) 'data_json': dataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  MutationQueueTableCompanion copyWith({
    Value<int>? id,
    Value<String>? collectionPath,
    Value<String>? documentId,
    Value<String>? operation,
    Value<String?>? dataJson,
    Value<String>? createdAt,
    Value<int>? retryCount,
  }) {
    return MutationQueueTableCompanion(
      id: id ?? this.id,
      collectionPath: collectionPath ?? this.collectionPath,
      documentId: documentId ?? this.documentId,
      operation: operation ?? this.operation,
      dataJson: dataJson ?? this.dataJson,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (collectionPath.present) {
      map['collection_path'] = Variable<String>(collectionPath.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MutationQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('collectionPath: $collectionPath, ')
          ..write('documentId: $documentId, ')
          ..write('operation: $operation, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserStatsTableTable userStatsTable = $UserStatsTableTable(this);
  late final $HabitsTableTable habitsTable = $HabitsTableTable(this);
  late final $HabitCompletionsTableTable habitCompletionsTable =
      $HabitCompletionsTableTable(this);
  late final $ChallengeProgressTableTable challengeProgressTable =
      $ChallengeProgressTableTable(this);
  late final $TribeStatsTableTable tribeStatsTable = $TribeStatsTableTable(
    this,
  );
  late final $LeaderboardEntriesTableTable leaderboardEntriesTable =
      $LeaderboardEntriesTableTable(this);
  late final $BlueprintsTableTable blueprintsTable = $BlueprintsTableTable(
    this,
  );
  late final $MutationQueueTableTable mutationQueueTable =
      $MutationQueueTableTable(this);
  late final UserStatsDao userStatsDao = UserStatsDao(this as AppDatabase);
  late final HabitsDao habitsDao = HabitsDao(this as AppDatabase);
  late final HabitCompletionsDao habitCompletionsDao = HabitCompletionsDao(
    this as AppDatabase,
  );
  late final ChallengeProgressDao challengeProgressDao = ChallengeProgressDao(
    this as AppDatabase,
  );
  late final TribeStatsDao tribeStatsDao = TribeStatsDao(this as AppDatabase);
  late final LeaderboardEntriesDao leaderboardEntriesDao =
      LeaderboardEntriesDao(this as AppDatabase);
  late final BlueprintsDao blueprintsDao = BlueprintsDao(this as AppDatabase);
  late final MutationQueueDao mutationQueueDao = MutationQueueDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userStatsTable,
    habitsTable,
    habitCompletionsTable,
    challengeProgressTable,
    tribeStatsTable,
    leaderboardEntriesTable,
    blueprintsTable,
    mutationQueueTable,
  ];
}

typedef $$UserStatsTableTableCreateCompanionBuilder =
    UserStatsTableCompanion Function({
      required String userId,
      Value<int> totalXp,
      Value<int> level,
      Value<int> streak,
      Value<int> strengthXp,
      Value<int> intellectXp,
      Value<int> vitalityXp,
      Value<int> creativityXp,
      Value<int> focusXp,
      Value<int> spiritXp,
      Value<int> challengeXp,
      Value<double> worldHealthScore,
      Value<String?> archetype,
      Value<String?> avatarJson,
      Value<String?> worldStateJson,
      Value<String> updatedAt,
      Value<String?> syncedAt,
      Value<int> onboardingProgress,
      Value<String?> onboardingCompletedAt,
      Value<int> rowid,
    });
typedef $$UserStatsTableTableUpdateCompanionBuilder =
    UserStatsTableCompanion Function({
      Value<String> userId,
      Value<int> totalXp,
      Value<int> level,
      Value<int> streak,
      Value<int> strengthXp,
      Value<int> intellectXp,
      Value<int> vitalityXp,
      Value<int> creativityXp,
      Value<int> focusXp,
      Value<int> spiritXp,
      Value<int> challengeXp,
      Value<double> worldHealthScore,
      Value<String?> archetype,
      Value<String?> avatarJson,
      Value<String?> worldStateJson,
      Value<String> updatedAt,
      Value<String?> syncedAt,
      Value<int> onboardingProgress,
      Value<String?> onboardingCompletedAt,
      Value<int> rowid,
    });

class $$UserStatsTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserStatsTableTable> {
  $$UserStatsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strengthXp => $composableBuilder(
    column: $table.strengthXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intellectXp => $composableBuilder(
    column: $table.intellectXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vitalityXp => $composableBuilder(
    column: $table.vitalityXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creativityXp => $composableBuilder(
    column: $table.creativityXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get focusXp => $composableBuilder(
    column: $table.focusXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spiritXp => $composableBuilder(
    column: $table.spiritXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get challengeXp => $composableBuilder(
    column: $table.challengeXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get worldHealthScore => $composableBuilder(
    column: $table.worldHealthScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archetype => $composableBuilder(
    column: $table.archetype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarJson => $composableBuilder(
    column: $table.avatarJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worldStateJson => $composableBuilder(
    column: $table.worldStateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get onboardingProgress => $composableBuilder(
    column: $table.onboardingProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get onboardingCompletedAt => $composableBuilder(
    column: $table.onboardingCompletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserStatsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserStatsTableTable> {
  $$UserStatsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strengthXp => $composableBuilder(
    column: $table.strengthXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intellectXp => $composableBuilder(
    column: $table.intellectXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vitalityXp => $composableBuilder(
    column: $table.vitalityXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creativityXp => $composableBuilder(
    column: $table.creativityXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get focusXp => $composableBuilder(
    column: $table.focusXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spiritXp => $composableBuilder(
    column: $table.spiritXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get challengeXp => $composableBuilder(
    column: $table.challengeXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get worldHealthScore => $composableBuilder(
    column: $table.worldHealthScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archetype => $composableBuilder(
    column: $table.archetype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarJson => $composableBuilder(
    column: $table.avatarJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worldStateJson => $composableBuilder(
    column: $table.worldStateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get onboardingProgress => $composableBuilder(
    column: $table.onboardingProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get onboardingCompletedAt => $composableBuilder(
    column: $table.onboardingCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserStatsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserStatsTableTable> {
  $$UserStatsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get totalXp =>
      $composableBuilder(column: $table.totalXp, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get streak =>
      $composableBuilder(column: $table.streak, builder: (column) => column);

  GeneratedColumn<int> get strengthXp => $composableBuilder(
    column: $table.strengthXp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intellectXp => $composableBuilder(
    column: $table.intellectXp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vitalityXp => $composableBuilder(
    column: $table.vitalityXp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get creativityXp => $composableBuilder(
    column: $table.creativityXp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get focusXp =>
      $composableBuilder(column: $table.focusXp, builder: (column) => column);

  GeneratedColumn<int> get spiritXp =>
      $composableBuilder(column: $table.spiritXp, builder: (column) => column);

  GeneratedColumn<int> get challengeXp => $composableBuilder(
    column: $table.challengeXp,
    builder: (column) => column,
  );

  GeneratedColumn<double> get worldHealthScore => $composableBuilder(
    column: $table.worldHealthScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get archetype =>
      $composableBuilder(column: $table.archetype, builder: (column) => column);

  GeneratedColumn<String> get avatarJson => $composableBuilder(
    column: $table.avatarJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get worldStateJson => $composableBuilder(
    column: $table.worldStateJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get onboardingProgress => $composableBuilder(
    column: $table.onboardingProgress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get onboardingCompletedAt => $composableBuilder(
    column: $table.onboardingCompletedAt,
    builder: (column) => column,
  );
}

class $$UserStatsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserStatsTableTable,
          UserStatsTableData,
          $$UserStatsTableTableFilterComposer,
          $$UserStatsTableTableOrderingComposer,
          $$UserStatsTableTableAnnotationComposer,
          $$UserStatsTableTableCreateCompanionBuilder,
          $$UserStatsTableTableUpdateCompanionBuilder,
          (
            UserStatsTableData,
            BaseReferences<
              _$AppDatabase,
              $UserStatsTableTable,
              UserStatsTableData
            >,
          ),
          UserStatsTableData,
          PrefetchHooks Function()
        > {
  $$UserStatsTableTableTableManager(
    _$AppDatabase db,
    $UserStatsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserStatsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserStatsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserStatsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> streak = const Value.absent(),
                Value<int> strengthXp = const Value.absent(),
                Value<int> intellectXp = const Value.absent(),
                Value<int> vitalityXp = const Value.absent(),
                Value<int> creativityXp = const Value.absent(),
                Value<int> focusXp = const Value.absent(),
                Value<int> spiritXp = const Value.absent(),
                Value<int> challengeXp = const Value.absent(),
                Value<double> worldHealthScore = const Value.absent(),
                Value<String?> archetype = const Value.absent(),
                Value<String?> avatarJson = const Value.absent(),
                Value<String?> worldStateJson = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> syncedAt = const Value.absent(),
                Value<int> onboardingProgress = const Value.absent(),
                Value<String?> onboardingCompletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserStatsTableCompanion(
                userId: userId,
                totalXp: totalXp,
                level: level,
                streak: streak,
                strengthXp: strengthXp,
                intellectXp: intellectXp,
                vitalityXp: vitalityXp,
                creativityXp: creativityXp,
                focusXp: focusXp,
                spiritXp: spiritXp,
                challengeXp: challengeXp,
                worldHealthScore: worldHealthScore,
                archetype: archetype,
                avatarJson: avatarJson,
                worldStateJson: worldStateJson,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                onboardingProgress: onboardingProgress,
                onboardingCompletedAt: onboardingCompletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<int> totalXp = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> streak = const Value.absent(),
                Value<int> strengthXp = const Value.absent(),
                Value<int> intellectXp = const Value.absent(),
                Value<int> vitalityXp = const Value.absent(),
                Value<int> creativityXp = const Value.absent(),
                Value<int> focusXp = const Value.absent(),
                Value<int> spiritXp = const Value.absent(),
                Value<int> challengeXp = const Value.absent(),
                Value<double> worldHealthScore = const Value.absent(),
                Value<String?> archetype = const Value.absent(),
                Value<String?> avatarJson = const Value.absent(),
                Value<String?> worldStateJson = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> syncedAt = const Value.absent(),
                Value<int> onboardingProgress = const Value.absent(),
                Value<String?> onboardingCompletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserStatsTableCompanion.insert(
                userId: userId,
                totalXp: totalXp,
                level: level,
                streak: streak,
                strengthXp: strengthXp,
                intellectXp: intellectXp,
                vitalityXp: vitalityXp,
                creativityXp: creativityXp,
                focusXp: focusXp,
                spiritXp: spiritXp,
                challengeXp: challengeXp,
                worldHealthScore: worldHealthScore,
                archetype: archetype,
                avatarJson: avatarJson,
                worldStateJson: worldStateJson,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                onboardingProgress: onboardingProgress,
                onboardingCompletedAt: onboardingCompletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserStatsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserStatsTableTable,
      UserStatsTableData,
      $$UserStatsTableTableFilterComposer,
      $$UserStatsTableTableOrderingComposer,
      $$UserStatsTableTableAnnotationComposer,
      $$UserStatsTableTableCreateCompanionBuilder,
      $$UserStatsTableTableUpdateCompanionBuilder,
      (
        UserStatsTableData,
        BaseReferences<_$AppDatabase, $UserStatsTableTable, UserStatsTableData>,
      ),
      UserStatsTableData,
      PrefetchHooks Function()
    >;
typedef $$HabitsTableTableCreateCompanionBuilder =
    HabitsTableCompanion Function({
      required String id,
      required String userId,
      required String title,
      Value<String?> cue,
      Value<String?> routine,
      Value<String?> reward,
      Value<String> frequency,
      Value<String> difficulty,
      Value<String?> attribute,
      Value<int> currentStreak,
      Value<int> longestStreak,
      Value<int> momentumScore,
      Value<int> consecutiveMisses,
      Value<String?> lastCompletedDate,
      Value<int> isArchived,
      required String createdAt,
      required String updatedAt,
      Value<String?> syncedAt,
      Value<int> rowid,
    });
typedef $$HabitsTableTableUpdateCompanionBuilder =
    HabitsTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> title,
      Value<String?> cue,
      Value<String?> routine,
      Value<String?> reward,
      Value<String> frequency,
      Value<String> difficulty,
      Value<String?> attribute,
      Value<int> currentStreak,
      Value<int> longestStreak,
      Value<int> momentumScore,
      Value<int> consecutiveMisses,
      Value<String?> lastCompletedDate,
      Value<int> isArchived,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String?> syncedAt,
      Value<int> rowid,
    });

class $$HabitsTableTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTableTable> {
  $$HabitsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cue => $composableBuilder(
    column: $table.cue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routine => $composableBuilder(
    column: $table.routine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reward => $composableBuilder(
    column: $table.reward,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribute => $composableBuilder(
    column: $table.attribute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get momentumScore => $composableBuilder(
    column: $table.momentumScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consecutiveMisses => $composableBuilder(
    column: $table.consecutiveMisses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTableTable> {
  $$HabitsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cue => $composableBuilder(
    column: $table.cue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routine => $composableBuilder(
    column: $table.routine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reward => $composableBuilder(
    column: $table.reward,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribute => $composableBuilder(
    column: $table.attribute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get momentumScore => $composableBuilder(
    column: $table.momentumScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consecutiveMisses => $composableBuilder(
    column: $table.consecutiveMisses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTableTable> {
  $$HabitsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get cue =>
      $composableBuilder(column: $table.cue, builder: (column) => column);

  GeneratedColumn<String> get routine =>
      $composableBuilder(column: $table.routine, builder: (column) => column);

  GeneratedColumn<String> get reward =>
      $composableBuilder(column: $table.reward, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attribute =>
      $composableBuilder(column: $table.attribute, builder: (column) => column);

  GeneratedColumn<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get momentumScore => $composableBuilder(
    column: $table.momentumScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consecutiveMisses => $composableBuilder(
    column: $table.consecutiveMisses,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$HabitsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTableTable,
          HabitsTableData,
          $$HabitsTableTableFilterComposer,
          $$HabitsTableTableOrderingComposer,
          $$HabitsTableTableAnnotationComposer,
          $$HabitsTableTableCreateCompanionBuilder,
          $$HabitsTableTableUpdateCompanionBuilder,
          (
            HabitsTableData,
            BaseReferences<_$AppDatabase, $HabitsTableTable, HabitsTableData>,
          ),
          HabitsTableData,
          PrefetchHooks Function()
        > {
  $$HabitsTableTableTableManager(_$AppDatabase db, $HabitsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> cue = const Value.absent(),
                Value<String?> routine = const Value.absent(),
                Value<String?> reward = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String?> attribute = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<int> momentumScore = const Value.absent(),
                Value<int> consecutiveMisses = const Value.absent(),
                Value<String?> lastCompletedDate = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsTableCompanion(
                id: id,
                userId: userId,
                title: title,
                cue: cue,
                routine: routine,
                reward: reward,
                frequency: frequency,
                difficulty: difficulty,
                attribute: attribute,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                momentumScore: momentumScore,
                consecutiveMisses: consecutiveMisses,
                lastCompletedDate: lastCompletedDate,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String title,
                Value<String?> cue = const Value.absent(),
                Value<String?> routine = const Value.absent(),
                Value<String?> reward = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String?> attribute = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<int> momentumScore = const Value.absent(),
                Value<int> consecutiveMisses = const Value.absent(),
                Value<String?> lastCompletedDate = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<String?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsTableCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                cue: cue,
                routine: routine,
                reward: reward,
                frequency: frequency,
                difficulty: difficulty,
                attribute: attribute,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                momentumScore: momentumScore,
                consecutiveMisses: consecutiveMisses,
                lastCompletedDate: lastCompletedDate,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HabitsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTableTable,
      HabitsTableData,
      $$HabitsTableTableFilterComposer,
      $$HabitsTableTableOrderingComposer,
      $$HabitsTableTableAnnotationComposer,
      $$HabitsTableTableCreateCompanionBuilder,
      $$HabitsTableTableUpdateCompanionBuilder,
      (
        HabitsTableData,
        BaseReferences<_$AppDatabase, $HabitsTableTable, HabitsTableData>,
      ),
      HabitsTableData,
      PrefetchHooks Function()
    >;
typedef $$HabitCompletionsTableTableCreateCompanionBuilder =
    HabitCompletionsTableCompanion Function({
      required String id,
      required String habitId,
      required String userId,
      required String completedAt,
      Value<int> xpGained,
      Value<String?> attribute,
      Value<int?> momentumAtCompletion,
      Value<int> streakDay,
      Value<int> wasRecovery,
      Value<String?> syncedAt,
      Value<int> rowid,
    });
typedef $$HabitCompletionsTableTableUpdateCompanionBuilder =
    HabitCompletionsTableCompanion Function({
      Value<String> id,
      Value<String> habitId,
      Value<String> userId,
      Value<String> completedAt,
      Value<int> xpGained,
      Value<String?> attribute,
      Value<int?> momentumAtCompletion,
      Value<int> streakDay,
      Value<int> wasRecovery,
      Value<String?> syncedAt,
      Value<int> rowid,
    });

class $$HabitCompletionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $HabitCompletionsTableTable> {
  $$HabitCompletionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitId => $composableBuilder(
    column: $table.habitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpGained => $composableBuilder(
    column: $table.xpGained,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribute => $composableBuilder(
    column: $table.attribute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get momentumAtCompletion => $composableBuilder(
    column: $table.momentumAtCompletion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakDay => $composableBuilder(
    column: $table.streakDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wasRecovery => $composableBuilder(
    column: $table.wasRecovery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitCompletionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitCompletionsTableTable> {
  $$HabitCompletionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitId => $composableBuilder(
    column: $table.habitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpGained => $composableBuilder(
    column: $table.xpGained,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribute => $composableBuilder(
    column: $table.attribute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get momentumAtCompletion => $composableBuilder(
    column: $table.momentumAtCompletion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakDay => $composableBuilder(
    column: $table.streakDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wasRecovery => $composableBuilder(
    column: $table.wasRecovery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitCompletionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitCompletionsTableTable> {
  $$HabitCompletionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get habitId =>
      $composableBuilder(column: $table.habitId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get xpGained =>
      $composableBuilder(column: $table.xpGained, builder: (column) => column);

  GeneratedColumn<String> get attribute =>
      $composableBuilder(column: $table.attribute, builder: (column) => column);

  GeneratedColumn<int> get momentumAtCompletion => $composableBuilder(
    column: $table.momentumAtCompletion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get streakDay =>
      $composableBuilder(column: $table.streakDay, builder: (column) => column);

  GeneratedColumn<int> get wasRecovery => $composableBuilder(
    column: $table.wasRecovery,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$HabitCompletionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitCompletionsTableTable,
          HabitCompletionsTableData,
          $$HabitCompletionsTableTableFilterComposer,
          $$HabitCompletionsTableTableOrderingComposer,
          $$HabitCompletionsTableTableAnnotationComposer,
          $$HabitCompletionsTableTableCreateCompanionBuilder,
          $$HabitCompletionsTableTableUpdateCompanionBuilder,
          (
            HabitCompletionsTableData,
            BaseReferences<
              _$AppDatabase,
              $HabitCompletionsTableTable,
              HabitCompletionsTableData
            >,
          ),
          HabitCompletionsTableData,
          PrefetchHooks Function()
        > {
  $$HabitCompletionsTableTableTableManager(
    _$AppDatabase db,
    $HabitCompletionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitCompletionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$HabitCompletionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$HabitCompletionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> completedAt = const Value.absent(),
                Value<int> xpGained = const Value.absent(),
                Value<String?> attribute = const Value.absent(),
                Value<int?> momentumAtCompletion = const Value.absent(),
                Value<int> streakDay = const Value.absent(),
                Value<int> wasRecovery = const Value.absent(),
                Value<String?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCompletionsTableCompanion(
                id: id,
                habitId: habitId,
                userId: userId,
                completedAt: completedAt,
                xpGained: xpGained,
                attribute: attribute,
                momentumAtCompletion: momentumAtCompletion,
                streakDay: streakDay,
                wasRecovery: wasRecovery,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String habitId,
                required String userId,
                required String completedAt,
                Value<int> xpGained = const Value.absent(),
                Value<String?> attribute = const Value.absent(),
                Value<int?> momentumAtCompletion = const Value.absent(),
                Value<int> streakDay = const Value.absent(),
                Value<int> wasRecovery = const Value.absent(),
                Value<String?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCompletionsTableCompanion.insert(
                id: id,
                habitId: habitId,
                userId: userId,
                completedAt: completedAt,
                xpGained: xpGained,
                attribute: attribute,
                momentumAtCompletion: momentumAtCompletion,
                streakDay: streakDay,
                wasRecovery: wasRecovery,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HabitCompletionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitCompletionsTableTable,
      HabitCompletionsTableData,
      $$HabitCompletionsTableTableFilterComposer,
      $$HabitCompletionsTableTableOrderingComposer,
      $$HabitCompletionsTableTableAnnotationComposer,
      $$HabitCompletionsTableTableCreateCompanionBuilder,
      $$HabitCompletionsTableTableUpdateCompanionBuilder,
      (
        HabitCompletionsTableData,
        BaseReferences<
          _$AppDatabase,
          $HabitCompletionsTableTable,
          HabitCompletionsTableData
        >,
      ),
      HabitCompletionsTableData,
      PrefetchHooks Function()
    >;
typedef $$ChallengeProgressTableTableCreateCompanionBuilder =
    ChallengeProgressTableCompanion Function({
      required String challengeId,
      required String userId,
      Value<String?> title,
      Value<String?> attribute,
      Value<int> currentDay,
      Value<int> totalDays,
      Value<String> status,
      Value<int> xpReward,
      Value<String?> joinedAt,
      required String updatedAt,
      Value<String?> syncedAt,
      Value<int> rowid,
    });
typedef $$ChallengeProgressTableTableUpdateCompanionBuilder =
    ChallengeProgressTableCompanion Function({
      Value<String> challengeId,
      Value<String> userId,
      Value<String?> title,
      Value<String?> attribute,
      Value<int> currentDay,
      Value<int> totalDays,
      Value<String> status,
      Value<int> xpReward,
      Value<String?> joinedAt,
      Value<String> updatedAt,
      Value<String?> syncedAt,
      Value<int> rowid,
    });

class $$ChallengeProgressTableTableFilterComposer
    extends Composer<_$AppDatabase, $ChallengeProgressTableTable> {
  $$ChallengeProgressTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribute => $composableBuilder(
    column: $table.attribute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentDay => $composableBuilder(
    column: $table.currentDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDays => $composableBuilder(
    column: $table.totalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpReward => $composableBuilder(
    column: $table.xpReward,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChallengeProgressTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ChallengeProgressTableTable> {
  $$ChallengeProgressTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribute => $composableBuilder(
    column: $table.attribute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentDay => $composableBuilder(
    column: $table.currentDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDays => $composableBuilder(
    column: $table.totalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpReward => $composableBuilder(
    column: $table.xpReward,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChallengeProgressTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChallengeProgressTableTable> {
  $$ChallengeProgressTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get attribute =>
      $composableBuilder(column: $table.attribute, builder: (column) => column);

  GeneratedColumn<int> get currentDay => $composableBuilder(
    column: $table.currentDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDays =>
      $composableBuilder(column: $table.totalDays, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get xpReward =>
      $composableBuilder(column: $table.xpReward, builder: (column) => column);

  GeneratedColumn<String> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$ChallengeProgressTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChallengeProgressTableTable,
          ChallengeProgressTableData,
          $$ChallengeProgressTableTableFilterComposer,
          $$ChallengeProgressTableTableOrderingComposer,
          $$ChallengeProgressTableTableAnnotationComposer,
          $$ChallengeProgressTableTableCreateCompanionBuilder,
          $$ChallengeProgressTableTableUpdateCompanionBuilder,
          (
            ChallengeProgressTableData,
            BaseReferences<
              _$AppDatabase,
              $ChallengeProgressTableTable,
              ChallengeProgressTableData
            >,
          ),
          ChallengeProgressTableData,
          PrefetchHooks Function()
        > {
  $$ChallengeProgressTableTableTableManager(
    _$AppDatabase db,
    $ChallengeProgressTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChallengeProgressTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ChallengeProgressTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ChallengeProgressTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> challengeId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> attribute = const Value.absent(),
                Value<int> currentDay = const Value.absent(),
                Value<int> totalDays = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> xpReward = const Value.absent(),
                Value<String?> joinedAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChallengeProgressTableCompanion(
                challengeId: challengeId,
                userId: userId,
                title: title,
                attribute: attribute,
                currentDay: currentDay,
                totalDays: totalDays,
                status: status,
                xpReward: xpReward,
                joinedAt: joinedAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String challengeId,
                required String userId,
                Value<String?> title = const Value.absent(),
                Value<String?> attribute = const Value.absent(),
                Value<int> currentDay = const Value.absent(),
                Value<int> totalDays = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> xpReward = const Value.absent(),
                Value<String?> joinedAt = const Value.absent(),
                required String updatedAt,
                Value<String?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChallengeProgressTableCompanion.insert(
                challengeId: challengeId,
                userId: userId,
                title: title,
                attribute: attribute,
                currentDay: currentDay,
                totalDays: totalDays,
                status: status,
                xpReward: xpReward,
                joinedAt: joinedAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChallengeProgressTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChallengeProgressTableTable,
      ChallengeProgressTableData,
      $$ChallengeProgressTableTableFilterComposer,
      $$ChallengeProgressTableTableOrderingComposer,
      $$ChallengeProgressTableTableAnnotationComposer,
      $$ChallengeProgressTableTableCreateCompanionBuilder,
      $$ChallengeProgressTableTableUpdateCompanionBuilder,
      (
        ChallengeProgressTableData,
        BaseReferences<
          _$AppDatabase,
          $ChallengeProgressTableTable,
          ChallengeProgressTableData
        >,
      ),
      ChallengeProgressTableData,
      PrefetchHooks Function()
    >;
typedef $$TribeStatsTableTableCreateCompanionBuilder =
    TribeStatsTableCompanion Function({
      required String tribeId,
      Value<String?> tribeName,
      Value<String?> archetypeId,
      Value<int> memberCount,
      Value<int> totalXp,
      Value<int> totalHabitsCompleted,
      Value<int> totalChallengesCompleted,
      Value<int> userContributionXp,
      Value<int> userHabitsCompleted,
      Value<int> userChallengesCompleted,
      required String updatedAt,
      Value<String?> syncedAt,
      Value<int> rowid,
    });
typedef $$TribeStatsTableTableUpdateCompanionBuilder =
    TribeStatsTableCompanion Function({
      Value<String> tribeId,
      Value<String?> tribeName,
      Value<String?> archetypeId,
      Value<int> memberCount,
      Value<int> totalXp,
      Value<int> totalHabitsCompleted,
      Value<int> totalChallengesCompleted,
      Value<int> userContributionXp,
      Value<int> userHabitsCompleted,
      Value<int> userChallengesCompleted,
      Value<String> updatedAt,
      Value<String?> syncedAt,
      Value<int> rowid,
    });

class $$TribeStatsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TribeStatsTableTable> {
  $$TribeStatsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tribeId => $composableBuilder(
    column: $table.tribeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tribeName => $composableBuilder(
    column: $table.tribeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archetypeId => $composableBuilder(
    column: $table.archetypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalHabitsCompleted => $composableBuilder(
    column: $table.totalHabitsCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChallengesCompleted => $composableBuilder(
    column: $table.totalChallengesCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userContributionXp => $composableBuilder(
    column: $table.userContributionXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userHabitsCompleted => $composableBuilder(
    column: $table.userHabitsCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userChallengesCompleted => $composableBuilder(
    column: $table.userChallengesCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TribeStatsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TribeStatsTableTable> {
  $$TribeStatsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tribeId => $composableBuilder(
    column: $table.tribeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tribeName => $composableBuilder(
    column: $table.tribeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archetypeId => $composableBuilder(
    column: $table.archetypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalHabitsCompleted => $composableBuilder(
    column: $table.totalHabitsCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChallengesCompleted => $composableBuilder(
    column: $table.totalChallengesCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userContributionXp => $composableBuilder(
    column: $table.userContributionXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userHabitsCompleted => $composableBuilder(
    column: $table.userHabitsCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userChallengesCompleted => $composableBuilder(
    column: $table.userChallengesCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TribeStatsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TribeStatsTableTable> {
  $$TribeStatsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tribeId =>
      $composableBuilder(column: $table.tribeId, builder: (column) => column);

  GeneratedColumn<String> get tribeName =>
      $composableBuilder(column: $table.tribeName, builder: (column) => column);

  GeneratedColumn<String> get archetypeId => $composableBuilder(
    column: $table.archetypeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalXp =>
      $composableBuilder(column: $table.totalXp, builder: (column) => column);

  GeneratedColumn<int> get totalHabitsCompleted => $composableBuilder(
    column: $table.totalHabitsCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalChallengesCompleted => $composableBuilder(
    column: $table.totalChallengesCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userContributionXp => $composableBuilder(
    column: $table.userContributionXp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userHabitsCompleted => $composableBuilder(
    column: $table.userHabitsCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userChallengesCompleted => $composableBuilder(
    column: $table.userChallengesCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$TribeStatsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TribeStatsTableTable,
          TribeStatsTableData,
          $$TribeStatsTableTableFilterComposer,
          $$TribeStatsTableTableOrderingComposer,
          $$TribeStatsTableTableAnnotationComposer,
          $$TribeStatsTableTableCreateCompanionBuilder,
          $$TribeStatsTableTableUpdateCompanionBuilder,
          (
            TribeStatsTableData,
            BaseReferences<
              _$AppDatabase,
              $TribeStatsTableTable,
              TribeStatsTableData
            >,
          ),
          TribeStatsTableData,
          PrefetchHooks Function()
        > {
  $$TribeStatsTableTableTableManager(
    _$AppDatabase db,
    $TribeStatsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TribeStatsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TribeStatsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TribeStatsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tribeId = const Value.absent(),
                Value<String?> tribeName = const Value.absent(),
                Value<String?> archetypeId = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> totalHabitsCompleted = const Value.absent(),
                Value<int> totalChallengesCompleted = const Value.absent(),
                Value<int> userContributionXp = const Value.absent(),
                Value<int> userHabitsCompleted = const Value.absent(),
                Value<int> userChallengesCompleted = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TribeStatsTableCompanion(
                tribeId: tribeId,
                tribeName: tribeName,
                archetypeId: archetypeId,
                memberCount: memberCount,
                totalXp: totalXp,
                totalHabitsCompleted: totalHabitsCompleted,
                totalChallengesCompleted: totalChallengesCompleted,
                userContributionXp: userContributionXp,
                userHabitsCompleted: userHabitsCompleted,
                userChallengesCompleted: userChallengesCompleted,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tribeId,
                Value<String?> tribeName = const Value.absent(),
                Value<String?> archetypeId = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> totalHabitsCompleted = const Value.absent(),
                Value<int> totalChallengesCompleted = const Value.absent(),
                Value<int> userContributionXp = const Value.absent(),
                Value<int> userHabitsCompleted = const Value.absent(),
                Value<int> userChallengesCompleted = const Value.absent(),
                required String updatedAt,
                Value<String?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TribeStatsTableCompanion.insert(
                tribeId: tribeId,
                tribeName: tribeName,
                archetypeId: archetypeId,
                memberCount: memberCount,
                totalXp: totalXp,
                totalHabitsCompleted: totalHabitsCompleted,
                totalChallengesCompleted: totalChallengesCompleted,
                userContributionXp: userContributionXp,
                userHabitsCompleted: userHabitsCompleted,
                userChallengesCompleted: userChallengesCompleted,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TribeStatsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TribeStatsTableTable,
      TribeStatsTableData,
      $$TribeStatsTableTableFilterComposer,
      $$TribeStatsTableTableOrderingComposer,
      $$TribeStatsTableTableAnnotationComposer,
      $$TribeStatsTableTableCreateCompanionBuilder,
      $$TribeStatsTableTableUpdateCompanionBuilder,
      (
        TribeStatsTableData,
        BaseReferences<
          _$AppDatabase,
          $TribeStatsTableTable,
          TribeStatsTableData
        >,
      ),
      TribeStatsTableData,
      PrefetchHooks Function()
    >;
typedef $$LeaderboardEntriesTableTableCreateCompanionBuilder =
    LeaderboardEntriesTableCompanion Function({
      required String id,
      required String tribeId,
      required String userId,
      Value<String> userName,
      Value<int> xp,
      Value<int> level,
      Value<int> rank,
      Value<String?> archetype,
      required String updatedAt,
      Value<String?> syncedAt,
      Value<int> rowid,
    });
typedef $$LeaderboardEntriesTableTableUpdateCompanionBuilder =
    LeaderboardEntriesTableCompanion Function({
      Value<String> id,
      Value<String> tribeId,
      Value<String> userId,
      Value<String> userName,
      Value<int> xp,
      Value<int> level,
      Value<int> rank,
      Value<String?> archetype,
      Value<String> updatedAt,
      Value<String?> syncedAt,
      Value<int> rowid,
    });

class $$LeaderboardEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $LeaderboardEntriesTableTable> {
  $$LeaderboardEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tribeId => $composableBuilder(
    column: $table.tribeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archetype => $composableBuilder(
    column: $table.archetype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LeaderboardEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LeaderboardEntriesTableTable> {
  $$LeaderboardEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tribeId => $composableBuilder(
    column: $table.tribeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archetype => $composableBuilder(
    column: $table.archetype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LeaderboardEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LeaderboardEntriesTableTable> {
  $$LeaderboardEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tribeId =>
      $composableBuilder(column: $table.tribeId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<String> get archetype =>
      $composableBuilder(column: $table.archetype, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LeaderboardEntriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LeaderboardEntriesTableTable,
          LeaderboardEntriesTableData,
          $$LeaderboardEntriesTableTableFilterComposer,
          $$LeaderboardEntriesTableTableOrderingComposer,
          $$LeaderboardEntriesTableTableAnnotationComposer,
          $$LeaderboardEntriesTableTableCreateCompanionBuilder,
          $$LeaderboardEntriesTableTableUpdateCompanionBuilder,
          (
            LeaderboardEntriesTableData,
            BaseReferences<
              _$AppDatabase,
              $LeaderboardEntriesTableTable,
              LeaderboardEntriesTableData
            >,
          ),
          LeaderboardEntriesTableData,
          PrefetchHooks Function()
        > {
  $$LeaderboardEntriesTableTableTableManager(
    _$AppDatabase db,
    $LeaderboardEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LeaderboardEntriesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LeaderboardEntriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LeaderboardEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tribeId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> userName = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> rank = const Value.absent(),
                Value<String?> archetype = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LeaderboardEntriesTableCompanion(
                id: id,
                tribeId: tribeId,
                userId: userId,
                userName: userName,
                xp: xp,
                level: level,
                rank: rank,
                archetype: archetype,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tribeId,
                required String userId,
                Value<String> userName = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> rank = const Value.absent(),
                Value<String?> archetype = const Value.absent(),
                required String updatedAt,
                Value<String?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LeaderboardEntriesTableCompanion.insert(
                id: id,
                tribeId: tribeId,
                userId: userId,
                userName: userName,
                xp: xp,
                level: level,
                rank: rank,
                archetype: archetype,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LeaderboardEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LeaderboardEntriesTableTable,
      LeaderboardEntriesTableData,
      $$LeaderboardEntriesTableTableFilterComposer,
      $$LeaderboardEntriesTableTableOrderingComposer,
      $$LeaderboardEntriesTableTableAnnotationComposer,
      $$LeaderboardEntriesTableTableCreateCompanionBuilder,
      $$LeaderboardEntriesTableTableUpdateCompanionBuilder,
      (
        LeaderboardEntriesTableData,
        BaseReferences<
          _$AppDatabase,
          $LeaderboardEntriesTableTable,
          LeaderboardEntriesTableData
        >,
      ),
      LeaderboardEntriesTableData,
      PrefetchHooks Function()
    >;
typedef $$BlueprintsTableTableCreateCompanionBuilder =
    BlueprintsTableCompanion Function({
      required String id,
      required String title,
      Value<String?> description,
      Value<String?> category,
      Value<String?> difficulty,
      Value<String?> imageUrl,
      Value<int> habitCount,
      Value<int> isFallback,
      Value<String?> dataJson,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$BlueprintsTableTableUpdateCompanionBuilder =
    BlueprintsTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> description,
      Value<String?> category,
      Value<String?> difficulty,
      Value<String?> imageUrl,
      Value<int> habitCount,
      Value<int> isFallback,
      Value<String?> dataJson,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$BlueprintsTableTableFilterComposer
    extends Composer<_$AppDatabase, $BlueprintsTableTable> {
  $$BlueprintsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get habitCount => $composableBuilder(
    column: $table.habitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isFallback => $composableBuilder(
    column: $table.isFallback,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BlueprintsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BlueprintsTableTable> {
  $$BlueprintsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get habitCount => $composableBuilder(
    column: $table.habitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isFallback => $composableBuilder(
    column: $table.isFallback,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlueprintsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlueprintsTableTable> {
  $$BlueprintsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get habitCount => $composableBuilder(
    column: $table.habitCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isFallback => $composableBuilder(
    column: $table.isFallback,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BlueprintsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlueprintsTableTable,
          BlueprintsTableData,
          $$BlueprintsTableTableFilterComposer,
          $$BlueprintsTableTableOrderingComposer,
          $$BlueprintsTableTableAnnotationComposer,
          $$BlueprintsTableTableCreateCompanionBuilder,
          $$BlueprintsTableTableUpdateCompanionBuilder,
          (
            BlueprintsTableData,
            BaseReferences<
              _$AppDatabase,
              $BlueprintsTableTable,
              BlueprintsTableData
            >,
          ),
          BlueprintsTableData,
          PrefetchHooks Function()
        > {
  $$BlueprintsTableTableTableManager(
    _$AppDatabase db,
    $BlueprintsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlueprintsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlueprintsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlueprintsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> habitCount = const Value.absent(),
                Value<int> isFallback = const Value.absent(),
                Value<String?> dataJson = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlueprintsTableCompanion(
                id: id,
                title: title,
                description: description,
                category: category,
                difficulty: difficulty,
                imageUrl: imageUrl,
                habitCount: habitCount,
                isFallback: isFallback,
                dataJson: dataJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> habitCount = const Value.absent(),
                Value<int> isFallback = const Value.absent(),
                Value<String?> dataJson = const Value.absent(),
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BlueprintsTableCompanion.insert(
                id: id,
                title: title,
                description: description,
                category: category,
                difficulty: difficulty,
                imageUrl: imageUrl,
                habitCount: habitCount,
                isFallback: isFallback,
                dataJson: dataJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BlueprintsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlueprintsTableTable,
      BlueprintsTableData,
      $$BlueprintsTableTableFilterComposer,
      $$BlueprintsTableTableOrderingComposer,
      $$BlueprintsTableTableAnnotationComposer,
      $$BlueprintsTableTableCreateCompanionBuilder,
      $$BlueprintsTableTableUpdateCompanionBuilder,
      (
        BlueprintsTableData,
        BaseReferences<
          _$AppDatabase,
          $BlueprintsTableTable,
          BlueprintsTableData
        >,
      ),
      BlueprintsTableData,
      PrefetchHooks Function()
    >;
typedef $$MutationQueueTableTableCreateCompanionBuilder =
    MutationQueueTableCompanion Function({
      Value<int> id,
      required String collectionPath,
      required String documentId,
      required String operation,
      Value<String?> dataJson,
      required String createdAt,
      Value<int> retryCount,
    });
typedef $$MutationQueueTableTableUpdateCompanionBuilder =
    MutationQueueTableCompanion Function({
      Value<int> id,
      Value<String> collectionPath,
      Value<String> documentId,
      Value<String> operation,
      Value<String?> dataJson,
      Value<String> createdAt,
      Value<int> retryCount,
    });

class $$MutationQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $MutationQueueTableTable> {
  $$MutationQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectionPath => $composableBuilder(
    column: $table.collectionPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MutationQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MutationQueueTableTable> {
  $$MutationQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectionPath => $composableBuilder(
    column: $table.collectionPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MutationQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MutationQueueTableTable> {
  $$MutationQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get collectionPath => $composableBuilder(
    column: $table.collectionPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$MutationQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MutationQueueTableTable,
          MutationQueueTableData,
          $$MutationQueueTableTableFilterComposer,
          $$MutationQueueTableTableOrderingComposer,
          $$MutationQueueTableTableAnnotationComposer,
          $$MutationQueueTableTableCreateCompanionBuilder,
          $$MutationQueueTableTableUpdateCompanionBuilder,
          (
            MutationQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $MutationQueueTableTable,
              MutationQueueTableData
            >,
          ),
          MutationQueueTableData,
          PrefetchHooks Function()
        > {
  $$MutationQueueTableTableTableManager(
    _$AppDatabase db,
    $MutationQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MutationQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MutationQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MutationQueueTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> collectionPath = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String?> dataJson = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => MutationQueueTableCompanion(
                id: id,
                collectionPath: collectionPath,
                documentId: documentId,
                operation: operation,
                dataJson: dataJson,
                createdAt: createdAt,
                retryCount: retryCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String collectionPath,
                required String documentId,
                required String operation,
                Value<String?> dataJson = const Value.absent(),
                required String createdAt,
                Value<int> retryCount = const Value.absent(),
              }) => MutationQueueTableCompanion.insert(
                id: id,
                collectionPath: collectionPath,
                documentId: documentId,
                operation: operation,
                dataJson: dataJson,
                createdAt: createdAt,
                retryCount: retryCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MutationQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MutationQueueTableTable,
      MutationQueueTableData,
      $$MutationQueueTableTableFilterComposer,
      $$MutationQueueTableTableOrderingComposer,
      $$MutationQueueTableTableAnnotationComposer,
      $$MutationQueueTableTableCreateCompanionBuilder,
      $$MutationQueueTableTableUpdateCompanionBuilder,
      (
        MutationQueueTableData,
        BaseReferences<
          _$AppDatabase,
          $MutationQueueTableTable,
          MutationQueueTableData
        >,
      ),
      MutationQueueTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserStatsTableTableTableManager get userStatsTable =>
      $$UserStatsTableTableTableManager(_db, _db.userStatsTable);
  $$HabitsTableTableTableManager get habitsTable =>
      $$HabitsTableTableTableManager(_db, _db.habitsTable);
  $$HabitCompletionsTableTableTableManager get habitCompletionsTable =>
      $$HabitCompletionsTableTableTableManager(_db, _db.habitCompletionsTable);
  $$ChallengeProgressTableTableTableManager get challengeProgressTable =>
      $$ChallengeProgressTableTableTableManager(
        _db,
        _db.challengeProgressTable,
      );
  $$TribeStatsTableTableTableManager get tribeStatsTable =>
      $$TribeStatsTableTableTableManager(_db, _db.tribeStatsTable);
  $$LeaderboardEntriesTableTableTableManager get leaderboardEntriesTable =>
      $$LeaderboardEntriesTableTableTableManager(
        _db,
        _db.leaderboardEntriesTable,
      );
  $$BlueprintsTableTableTableManager get blueprintsTable =>
      $$BlueprintsTableTableTableManager(_db, _db.blueprintsTable);
  $$MutationQueueTableTableTableManager get mutationQueueTable =>
      $$MutationQueueTableTableTableManager(_db, _db.mutationQueueTable);
}

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

@ProviderFor(blueprintsDao)
final blueprintsDaoProvider = BlueprintsDaoProvider._();

final class BlueprintsDaoProvider
    extends $FunctionalProvider<BlueprintsDao, BlueprintsDao, BlueprintsDao>
    with $Provider<BlueprintsDao> {
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
  $ProviderElement<BlueprintsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BlueprintsDao create(Ref ref) {
    return blueprintsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BlueprintsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BlueprintsDao>(value),
    );
  }
}

String _$blueprintsDaoHash() => r'2e59c3ee060534b6e13c9e37b996af967d97e2e4';

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
