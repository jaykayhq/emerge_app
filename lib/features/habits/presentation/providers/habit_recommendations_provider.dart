import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_suggestions_provider.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_template_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'habit_recommendations_provider.g.dart';

/// A ranked recommendation for the create-screen typeahead. Templates carry
/// an emoji (and optionally attribute/timer) so picking one fills more than
/// just the title.
class HabitRecommendation {
  final String title;
  final String? emoji;
  final HabitAttribute? attribute;
  final int? timerMinutes;

  const HabitRecommendation({
    required this.title,
    this.emoji,
    this.attribute,
    this.timerMinutes,
  });
}

/// Pure recommendation filter — testable without Riverpod/Drift.
///
/// Ranking: prefix matches (case-insensitive) before substring matches,
/// suggestions before templates within the same tier, deduped by title,
/// capped at [limit].
List<HabitRecommendation> filterHabitRecommendations({
  required String term,
  required List<HabitTemplate> templates,
  List<String> suggestions = const [],
  int limit = 8,
}) {
  final query = term.trim().toLowerCase();
  final seen = <String>{};
  final out = <HabitRecommendation>[];

  void add({
    required String title,
    String? emoji,
    HabitAttribute? attribute,
    int? timerMinutes,
  }) {
    if (!seen.add(title.toLowerCase())) return;
    out.add(
      HabitRecommendation(
        title: title,
        emoji: emoji,
        attribute: attribute,
        timerMinutes: timerMinutes,
      ),
    );
  }

  void addSuggestion(String title) => add(title: title);
  void addTemplate(HabitTemplate t) => add(
    title: t.title,
    emoji: t.emoji,
    attribute: t.attribute,
    timerMinutes: t.timerDurationMinutes > 0 ? t.timerDurationMinutes : null,
  );

  if (query.isEmpty) {
    // Nothing typed yet: the user's/archetype/curated suggestions first, then
    // the emoji-rich template library.
    for (final s in suggestions) {
      addSuggestion(s);
    }
    for (final t in templates) {
      addTemplate(t);
    }
    return out.take(limit).toList();
  }

  for (final t in templates) {
    if (t.title.toLowerCase().startsWith(query)) addTemplate(t);
  }
  for (final s in suggestions) {
    if (s.toLowerCase().startsWith(query)) addSuggestion(s);
  }
  for (final t in templates) {
    if (!t.title.toLowerCase().startsWith(query) &&
        t.title.toLowerCase().contains(query)) {
      addTemplate(t);
    }
  }
  for (final s in suggestions) {
    if (!s.toLowerCase().startsWith(query) && s.toLowerCase().contains(query)) {
      addSuggestion(s);
    }
  }
  return out.take(limit).toList();
}

/// Live recommendations for the create screen's title field. Re-evaluates as
/// the user types (auto-dispose family keyed by the current term).
@riverpod
List<HabitRecommendation> habitRecommendations(Ref ref, String term) {
  final suggestions = ref.watch(habitSuggestionsProvider);
  return filterHabitRecommendations(
    term: term,
    templates: habitTemplateCatalog,
    suggestions: suggestions,
  );
}
