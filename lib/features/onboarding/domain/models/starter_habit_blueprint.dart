import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/onboarding/domain/models/interest.dart';

/// A pre-authored, simple starter habit. One blueprint → many possible users.
///
/// All entries are intentionally short (≤10 minutes, ideally ≤2), no equipment
/// or one common item, and tied to one or more readable sources so the user
/// can find the original advice if they want to.
class StarterHabitBlueprint {
  /// Stable id. Convention: `<archetype.name>.<slug>`.
  final String id;

  /// User-facing title. Should be an imperative verb phrase.
  final String title;

  /// Where in the day this habit gets stacked. Used as the `cue` field on the
  /// resulting `Habit`.
  final String shortCue;

  /// Maps to `HabitAttribute` for gamification (XP routing, attribute radar).
  final HabitAttribute attribute;

  /// Which archetype this blueprint primarily serves.
  final UserArchetype archetype;

  /// Interest categories this blueprint serves. Used for ranking.
  final List<InterestCategory> interestCategories;

  /// Club tags this blueprint serves. Used as tiebreaker.
  final List<String> clubTags;

  /// Human-readable source citation. Required for catalog entries.
  final String sourceAttribution;

  const StarterHabitBlueprint({
    required this.id,
    required this.title,
    required this.shortCue,
    required this.attribute,
    required this.archetype,
    required this.interestCategories,
    required this.clubTags,
    required this.sourceAttribution,
  });

  /// Curated starter catalog. ~30 entries: 6 per selectable archetype.
  ///
  /// Sources:
  /// - Athlete: happytrainers.com 10-minute beginner routine, CDC physical-activity
  ///   guidelines (2024), Mayo Clinic 5-step fitness program
  /// - Scholar: Cal Newport (Deep Work), Sönke Ahrens (How to Take Smart Notes),
  ///   James Clear (2-minute rule)
  /// - Creator: The Write Practice, Anna Yang daily routine, James Clear on
  ///   brainstorming, MasterClass 25-minute Pomodoro
  /// - Stoic: Marcus Aurelius Meditations, Daily Stoic morning routine,
  ///   5-Minute Journal format (Seneca evening examination)
  /// - Zealot: FaithTime Holy Habits, FaithTime Bible-study methods,
  ///   FaithTime prayer micro-plan, Five Ways to Practice Your Faith Daily
  static const List<StarterHabitBlueprint> catalog = [
    // ============ ATHLETE ============
    StarterHabitBlueprint(
      id: 'athlete.squats.10',
      title: '10 squats',
      shortCue: 'After breakfast',
      attribute: HabitAttribute.vitality,
      archetype: UserArchetype.athlete,
      interestCategories: [InterestCategory.movement],
      clubTags: ['fitness', 'morning'],
      sourceAttribution: 'happytrainers.com — 10-minute beginner routine',
    ),
    StarterHabitBlueprint(
      id: 'athlete.plank.60s',
      title: '60-second plank',
      shortCue: 'After waking up',
      attribute: HabitAttribute.vitality,
      archetype: UserArchetype.athlete,
      interestCategories: [InterestCategory.movement],
      clubTags: ['fitness', 'morning'],
      sourceAttribution: 'happytrainers.com — 10-minute beginner routine',
    ),
    StarterHabitBlueprint(
      id: 'athlete.walk.10min',
      title: '10-minute walk outside',
      shortCue: 'After lunch',
      attribute: HabitAttribute.vitality,
      archetype: UserArchetype.athlete,
      interestCategories: [
        InterestCategory.movement,
        InterestCategory.mindfulness,
      ],
      clubTags: ['fitness', 'walking'],
      sourceAttribution: 'Mayo Clinic 5-step fitness program',
    ),
    StarterHabitBlueprint(
      id: 'athlete.warmup.breath',
      title: '5 slow breaths before training',
      shortCue: 'Before workout',
      attribute: HabitAttribute.focus,
      archetype: UserArchetype.athlete,
      interestCategories: [
        InterestCategory.mindfulness,
        InterestCategory.movement,
      ],
      clubTags: ['fitness'],
      sourceAttribution: 'happytrainers.com warm-up guide',
    ),
    StarterHabitBlueprint(
      id: 'athlete.hydration.glass',
      title: 'Drink one glass of water',
      shortCue: 'After waking up',
      attribute: HabitAttribute.vitality,
      archetype: UserArchetype.athlete,
      interestCategories: [
        InterestCategory.nutrition,
        InterestCategory.movement,
      ],
      clubTags: ['fitness', 'wellness'],
      sourceAttribution: 'CDC hydration guidance',
    ),
    StarterHabitBlueprint(
      id: 'athlete.mobility.flow',
      title: '5-minute mobility flow',
      shortCue: 'After waking up',
      attribute: HabitAttribute.vitality,
      archetype: UserArchetype.athlete,
      interestCategories: [
        InterestCategory.movement,
        InterestCategory.mindfulness,
      ],
      clubTags: ['fitness', 'morning', 'mobility'],
      sourceAttribution: 'happytrainers.com — beginner bodyweight',
    ),

    // ============ SCHOLAR ============
    StarterHabitBlueprint(
      id: 'scholar.read.2pages',
      title: 'Read 2 pages',
      shortCue: 'Before bed',
      attribute: HabitAttribute.intellect,
      archetype: UserArchetype.scholar,
      interestCategories: [InterestCategory.learning],
      clubTags: ['reading', 'night-owl', 'learning'],
      sourceAttribution: 'James Clear 2-minute rule (Atomic Habits)',
    ),
    StarterHabitBlueprint(
      id: 'scholar.focus.10min',
      title: '10-minute focus sprint',
      shortCue: 'After coffee',
      attribute: HabitAttribute.focus,
      archetype: UserArchetype.scholar,
      interestCategories: [InterestCategory.learning],
      clubTags: ['productivity', 'focus', 'deep-work'],
      sourceAttribution: 'Cal Newport — Deep Work',
    ),
    StarterHabitBlueprint(
      id: 'scholar.question.1',
      title: 'Write down one question',
      shortCue: 'After waking up',
      attribute: HabitAttribute.intellect,
      archetype: UserArchetype.scholar,
      interestCategories: [
        InterestCategory.learning,
        InterestCategory.creativity,
      ],
      clubTags: ['productivity', 'curiosity'],
      sourceAttribution: 'Sönke Ahrens — How to Take Smart Notes',
    ),
    StarterHabitBlueprint(
      id: 'scholar.review.notes',
      title: 'Review yesterday\u0027s notes for 2 minutes',
      shortCue: 'Before bed',
      attribute: HabitAttribute.intellect,
      archetype: UserArchetype.scholar,
      interestCategories: [InterestCategory.learning],
      clubTags: ['reading', 'night-owl', 'study'],
      sourceAttribution: 'Cal Newport / Andy Matuschak — spaced review',
    ),
    StarterHabitBlueprint(
      id: 'scholar.vocab.5min',
      title: '5 minutes of language practice',
      shortCue: 'After work',
      attribute: HabitAttribute.intellect,
      archetype: UserArchetype.scholar,
      interestCategories: [InterestCategory.learning],
      clubTags: ['language', 'learning'],
      sourceAttribution: 'Language learner community — micro-session norm',
    ),
    StarterHabitBlueprint(
      id: 'scholar.curiosity.1',
      title: 'Spend 5 minutes on one curiosity',
      shortCue: 'After lunch',
      attribute: HabitAttribute.intellect,
      archetype: UserArchetype.scholar,
      interestCategories: [InterestCategory.learning],
      clubTags: ['curiosity', 'learning'],
      sourceAttribution: 'James Clear — daily curiosity ritual',
    ),

    // ============ CREATOR ============
    StarterHabitBlueprint(
      id: 'creator.write.1sentence',
      title: 'Write 1 sentence',
      shortCue: 'After coffee',
      attribute: HabitAttribute.creativity,
      archetype: UserArchetype.creator,
      interestCategories: [InterestCategory.creativity],
      clubTags: ['writing', 'morning'],
      sourceAttribution: 'The Write Practice — keystone habits for writers',
    ),
    StarterHabitBlueprint(
      id: 'creator.read.10min',
      title: 'Read for 10 minutes',
      shortCue: 'Before bed',
      attribute: HabitAttribute.creativity,
      archetype: UserArchetype.creator,
      interestCategories: [
        InterestCategory.creativity,
        InterestCategory.learning,
      ],
      clubTags: ['reading', 'night-owl'],
      sourceAttribution: 'The Write Practice — keystone habits for writers',
    ),
    StarterHabitBlueprint(
      id: 'creator.brainstorm.3bad',
      title: 'Brainstorm 3 bad ideas for 5 minutes',
      shortCue: 'After lunch',
      attribute: HabitAttribute.creativity,
      archetype: UserArchetype.creator,
      interestCategories: [InterestCategory.creativity],
      clubTags: ['creativity'],
      sourceAttribution: 'James Clear — daily brainstorming ritual',
    ),
    StarterHabitBlueprint(
      id: 'creator.capture.idea',
      title: 'Capture today\u0027s creative idea',
      shortCue: 'After waking up',
      attribute: HabitAttribute.creativity,
      archetype: UserArchetype.creator,
      interestCategories: [InterestCategory.creativity],
      clubTags: ['writing', 'morning'],
      sourceAttribution: 'Anna Yang — daily creator routine',
    ),
    StarterHabitBlueprint(
      id: 'creator.sketch.30s',
      title: 'Sketch one rough shape',
      shortCue: 'After work',
      attribute: HabitAttribute.creativity,
      archetype: UserArchetype.creator,
      interestCategories: [InterestCategory.creativity],
      clubTags: ['art', 'creativity'],
      sourceAttribution: 'See Jane Write — sketch a day for 30s',
    ),
    StarterHabitBlueprint(
      id: 'creator.pomodoro.25',
      title: '25-minute Pomodoro on one project',
      shortCue: 'After coffee',
      attribute: HabitAttribute.focus,
      archetype: UserArchetype.creator,
      interestCategories: [
        InterestCategory.creativity,
        InterestCategory.learning,
      ],
      clubTags: ['writing', 'productivity', 'deep-work'],
      sourceAttribution: 'MasterClass — Pomodoro for writers',
    ),

    // ============ STOIC ============
    StarterHabitBlueprint(
      id: 'stoic.journal.2min',
      title: '2-minute morning journal',
      shortCue: 'After waking up',
      attribute: HabitAttribute.focus,
      archetype: UserArchetype.stoic,
      interestCategories: [
        InterestCategory.mindfulness,
        InterestCategory.learning,
      ],
      clubTags: ['morning', 'stoic'],
      sourceAttribution: 'Marcus Aurelius — Meditations morning practice',
    ),
    StarterHabitBlueprint(
      id: 'stoic.meditations.read',
      title: 'Read one Meditations passage',
      shortCue: 'Before bed',
      attribute: HabitAttribute.intellect,
      archetype: UserArchetype.stoic,
      interestCategories: [
        InterestCategory.mindfulness,
        InterestCategory.learning,
      ],
      clubTags: ['reading', 'night-owl', 'stoic'],
      sourceAttribution: 'Daily Stoic — morning routine',
    ),
    StarterHabitBlueprint(
      id: 'stoic.evening.examine',
      title: '60-second evening reflection',
      shortCue: 'Before bed',
      attribute: HabitAttribute.focus,
      archetype: UserArchetype.stoic,
      interestCategories: [InterestCategory.mindfulness],
      clubTags: ['night-owl', 'stoic'],
      sourceAttribution: 'Seneca — evening examination (5-Minute Journal format)',
    ),
    StarterHabitBlueprint(
      id: 'stoic.breath.pre',
      title: '60-second box breath',
      shortCue: 'Before a hard conversation',
      attribute: HabitAttribute.focus,
      archetype: UserArchetype.stoic,
      interestCategories: [InterestCategory.mindfulness],
      clubTags: ['stoic', 'breathwork'],
      sourceAttribution: 'Stoic preparatory practice — pre-action pause',
    ),
    StarterHabitBlueprint(
      id: 'stoic.dichotomy.1',
      title: 'Note one thing you control today',
      shortCue: 'After waking up',
      attribute: HabitAttribute.focus,
      archetype: UserArchetype.stoic,
      interestCategories: [InterestCategory.mindfulness],
      clubTags: ['morning', 'stoic'],
      sourceAttribution: 'Epictetus — dichotomy of control',
    ),
    StarterHabitBlueprint(
      id: 'stoic.virtue.1',
      title: 'Pick one virtue to practice today',
      shortCue: 'After waking up',
      attribute: HabitAttribute.spirit,
      archetype: UserArchetype.stoic,
      interestCategories: [
        InterestCategory.mindfulness,
        InterestCategory.faith,
      ],
      clubTags: ['stoic'],
      sourceAttribution: 'Marcus Aurelius — Meditations 2.1',
    ),

    // ============ ZEALOT ============
    StarterHabitBlueprint(
      id: 'zealot.prayer.2min',
      title: '2-minute morning prayer',
      shortCue: 'After waking up',
      attribute: HabitAttribute.spirit,
      archetype: UserArchetype.zealot,
      interestCategories: [
        InterestCategory.faith,
        InterestCategory.mindfulness,
      ],
      clubTags: ['morning', 'prayer', 'faith'],
      sourceAttribution: 'FaithTime — 7-day prayer micro-plan Day 1-2',
    ),
    StarterHabitBlueprint(
      id: 'zealot.scripture.passage',
      title: 'Read one short Scripture passage',
      shortCue: 'After waking up',
      attribute: HabitAttribute.spirit,
      archetype: UserArchetype.zealot,
      interestCategories: [InterestCategory.faith],
      clubTags: ['morning', 'scripture', 'reading'],
      sourceAttribution: 'FaithTime — Bible study methods',
    ),
    StarterHabitBlueprint(
      id: 'zealot.gratitude.1',
      title: 'Write one sentence of gratitude',
      shortCue: 'Before bed',
      attribute: HabitAttribute.spirit,
      archetype: UserArchetype.zealot,
      interestCategories: [
        InterestCategory.faith,
        InterestCategory.mindfulness,
      ],
      clubTags: ['night-owl', 'devotional'],
      sourceAttribution: 'Five Ways to Practice Your Faith Daily',
    ),
    StarterHabitBlueprint(
      id: 'zealot.listening.1min',
      title: 'One minute of quiet listening',
      shortCue: 'After work',
      attribute: HabitAttribute.spirit,
      archetype: UserArchetype.zealot,
      interestCategories: [
        InterestCategory.faith,
        InterestCategory.mindfulness,
      ],
      clubTags: ['devotional', 'prayer'],
      sourceAttribution: 'FaithTime — Day 3-4 prayer step',
    ),
    StarterHabitBlueprint(
      id: 'zealot.share.1prayer',
      title: 'Share one prayer request with a friend',
      shortCue: 'After waking up',
      attribute: HabitAttribute.spirit,
      archetype: UserArchetype.zealot,
      interestCategories: [InterestCategory.faith],
      clubTags: ['community', 'prayer'],
      sourceAttribution: 'FaithTime — Day 5-7 community step',
    ),
    StarterHabitBlueprint(
      id: 'zealot.devotional.1',
      title: 'Read a one-paragraph devotional',
      shortCue: 'Before bed',
      attribute: HabitAttribute.spirit,
      archetype: UserArchetype.zealot,
      interestCategories: [InterestCategory.faith],
      clubTags: ['night-owl', 'devotional'],
      sourceAttribution: 'FaithTime — daily devotional benefits',
    ),
  ];

  /// Rank blueprints for a user based on (archetype, interests, club tag
  /// overlap). Cross-archetype blueprints are filtered out so a starter pack
  /// for an athlete never contains a zealot-only blueprint.
  ///
  /// Ranking:
  /// - +10 for each matching archetype interest category
  /// - +3  for each matching club tag
  /// - +1  baseline so every same-archetype blueprint has a chance
  ///
  /// Ties are broken by source-attribution sort order, then by id
  /// lexicographic order, so the result is deterministic.
  static List<StarterHabitBlueprint> forPersonalization({
    required UserArchetype archetype,
    required List<String> interestIds,
    required List<String> clubTags,
    int limit = 3,
  }) {
    if (archetype == UserArchetype.none) return const [];

    final requestedCategories = <InterestCategory>{};
    for (final id in interestIds) {
      for (final category in InterestCategory.values) {
        if (id.startsWith(category.idPrefix)) {
          requestedCategories.add(category);
        }
      }
    }

    final sameArchetype = catalog
        .where((b) => b.archetype == archetype)
        .toList(growable: false);

    if (sameArchetype.isEmpty) return const [];

    int score(StarterHabitBlueprint b) {
      var s = 1;
      for (final cat in b.interestCategories) {
        if (requestedCategories.contains(cat)) s += 10;
      }
      for (final tag in b.clubTags) {
        if (clubTags.contains(tag)) s += 3;
      }
      return s;
    }

    final ranked = [...sameArchetype];
    ranked.sort((a, b) {
      final cmp = score(b).compareTo(score(a));
      if (cmp != 0) return cmp;
      final src = a.sourceAttribution.compareTo(b.sourceAttribution);
      if (src != 0) return src;
      return a.id.compareTo(b.id);
    });

    return ranked.take(limit).toList(growable: false);
  }
}
