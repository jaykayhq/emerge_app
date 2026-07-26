import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/services/smart_defaults_service.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'habit_suggestions_provider.g.dart';

/// Curated fallback suggestions shown when the archetype pool is thin.
const _curatedFallback = <String>[
  'Drink water',
  'Read for 10 minutes',
  'Meditate',
  'Go for a walk',
  'Stretch',
  'Journal',
  'Take vitamins',
  'Make the bed',
];

/// Habit title suggestions, sorted by relevance:
/// 1. Habits the user has already created (anchoring/endowment)
/// 2. Archetype-matched suggestions
/// 3. Curated fallback
///
/// Auto-disposes when no longer watched.
@riverpod
List<String> habitSuggestions(Ref ref) {
  final archetype = ref.watch(currentArchetypeProvider);
  final habitsAsync = ref.watch(habitsProvider);

  final userCreated = (habitsAsync.value ?? [])
      .where((h) => !h.isArchived)
      .map((h) => h.title)
      .toList();

  final archetypeTitles = ArchetypeTheme.forArchetype(archetype)
      .suggestedHabits
      .map((s) => s.title)
      .toList();

  final all = <String>[
    ...userCreated,
    ...archetypeTitles,
    ..._curatedFallback,
  ];

  return sortedSuggestions(
    all,
    userCreatedHabits: userCreated,
    archetypeName: archetype.name,
    interestTags: const [],
  );
}
