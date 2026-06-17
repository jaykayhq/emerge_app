import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/attribute_progress_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _makeContainer(UserProfile profile) {
  return ProviderContainer(
    overrides: [
      userStatsStreamProvider.overrideWithValue(
        AsyncValue.data(profile),
      ),
    ],
  );
}

ProviderContainer _makeEmptyContainer() {
  return ProviderContainer(
    overrides: [
      userStatsStreamProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
    ],
  );
}

/// Creates a container that overrides the stream-derived providers with
/// known values so they can be read synchronously.
ProviderContainer _makeContainerWithAvatarValues({
  required UserProfile profile,
  UserAvatarStats? avatarStats,
  int? level,
  int? streak,
}) {
  return ProviderContainer(
    overrides: [
      userStatsStreamProvider.overrideWithValue(
        AsyncValue.data(profile),
      ),
      if (avatarStats != null)
        userAvatarStatsProvider.overrideWithValue(AsyncValue.data(avatarStats)),
      if (level != null)
        userLevelProvider.overrideWithValue(AsyncValue.data(level)),
      if (streak != null)
        userStreakProvider.overrideWithValue(AsyncValue.data(streak)),
    ],
  );
}

void main() {
  group('currentArchetypeProvider', () {
    test('returns athlete when profile archetype is athlete', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test', archetype: UserArchetype.athlete),
      );
      expect(container.read(currentArchetypeProvider), UserArchetype.athlete);
      container.dispose();
    });

    test('returns scholar when profile archetype is scholar', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test', archetype: UserArchetype.scholar),
      );
      expect(container.read(currentArchetypeProvider), UserArchetype.scholar);
      container.dispose();
    });

    test('returns creator when profile archetype is creator', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test', archetype: UserArchetype.creator),
      );
      expect(container.read(currentArchetypeProvider), UserArchetype.creator);
      container.dispose();
    });

    test('returns stoic when profile archetype is stoic', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test', archetype: UserArchetype.stoic),
      );
      expect(container.read(currentArchetypeProvider), UserArchetype.stoic);
      container.dispose();
    });

    test('returns none when profile has no archetype', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test'),
      );
      expect(container.read(currentArchetypeProvider), UserArchetype.none);
      container.dispose();
    });
  });

  group('isOnboardingCompleteProvider', () {
    test('returns true when onboardingCompletedAt is set', () {
      final container = _makeContainer(
        UserProfile(uid: 'test', onboardingCompletedAt: DateTime(2024)),
      );
      expect(container.read(isOnboardingCompleteProvider), true);
      container.dispose();
    });

    test('returns false when onboardingCompletedAt is null', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test'),
      );
      expect(container.read(isOnboardingCompleteProvider), false);
      container.dispose();
    });
  });

  group('userAvatarStatsProvider', () {
    test('returns avatar stats from profile', () {
      const stats = UserAvatarStats(level: 5, streak: 10);
      final container = _makeContainerWithAvatarValues(
        profile: const UserProfile(uid: 'test').copyWith(avatarStats: stats),
        avatarStats: stats,
      );
      expect(
        container.read(userAvatarStatsProvider).requireValue,
        stats,
      );
      container.dispose();
    });

    test('returns empty stats when profile has defaults', () {
      final container = _makeContainerWithAvatarValues(
        profile: const UserProfile(uid: 'test'),
        avatarStats: const UserAvatarStats(),
      );
      expect(
        container.read(userAvatarStatsProvider).requireValue,
        const UserAvatarStats(),
      );
      container.dispose();
    });
  });

  group('userLevelProvider', () {
    test('returns level from profile avatar stats', () {
      final container = _makeContainerWithAvatarValues(
        profile: const UserProfile(uid: 'test').copyWith(
          avatarStats: const UserAvatarStats(level: 10),
        ),
        level: 10,
      );
      expect(container.read(userLevelProvider).requireValue, 10);
      container.dispose();
    });

    test('returns 1 as default when stats are empty', () {
      final container = _makeContainerWithAvatarValues(
        profile: const UserProfile(uid: 'test'),
        level: 1,
      );
      expect(container.read(userLevelProvider).requireValue, 1);
      container.dispose();
    });
  });

  group('userStreakProvider', () {
    test('returns streak from profile avatar stats', () {
      final container = _makeContainerWithAvatarValues(
        profile: const UserProfile(uid: 'test').copyWith(
          avatarStats: const UserAvatarStats(streak: 25),
        ),
        streak: 25,
      );
      expect(container.read(userStreakProvider).requireValue, 25);
      container.dispose();
    });

    test('returns 0 as default when streak is not set', () {
      final container = _makeContainerWithAvatarValues(
        profile: const UserProfile(uid: 'test'),
        streak: 0,
      );
      expect(container.read(userStreakProvider).requireValue, 0);
      container.dispose();
    });
  });

  group('attributeProgressFromHabitsProvider', () {
    test('returns empty map when profile is null', () {
      final container = _makeEmptyContainer();
      expect(container.read(attributeProgressFromHabitsProvider), {});
      container.dispose();
    });

    test('calculates progress for all 6 attributes', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test').copyWith(
          avatarStats: const UserAvatarStats(
            strengthXp: 300,
            intellectXp: 200,
            vitalityXp: 150,
            creativityXp: 100,
            focusXp: 150,
            spiritXp: 100,
          ),
        ),
      );
      final result = container.read(attributeProgressFromHabitsProvider);
      expect(result.length, 6);
      expect(result.containsKey('strength'), true);
      expect(result.containsKey('intellect'), true);
      expect(result.containsKey('vitality'), true);
      expect(result.containsKey('creativity'), true);
      expect(result.containsKey('focus'), true);
      expect(result.containsKey('spirit'), true);
      container.dispose();
    });
  });

  group('attributeProgressProvider', () {
    test('returns progress for a specific attribute', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test').copyWith(
          avatarStats: const UserAvatarStats(
            strengthXp: 300,
          ),
        ),
      );
      final result = container.read(attributeProgressProvider('strength'));
      expect(result, isNotNull);
      expect(result!.attribute, 'strength');
      expect(result.totalXp, 300);
      container.dispose();
    });

    test('returns null for unknown attribute', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test'),
      );
      expect(container.read(attributeProgressProvider('unknown')), isNull);
      container.dispose();
    });

    test('is case-insensitive', () {
      final container = _makeContainer(
        const UserProfile(uid: 'test').copyWith(
          avatarStats: const UserAvatarStats(strengthXp: 200),
        ),
      );
      expect(container.read(attributeProgressProvider('Strength')), isNotNull);
      container.dispose();
    });
  });
}
