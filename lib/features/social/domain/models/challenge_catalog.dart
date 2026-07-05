import 'package:emerge_app/features/social/domain/models/challenge.dart';

/// A static catalog of challenge templates used to generate daily and weekly challenges locally.
class ChallengeCatalog {
  static final List<Challenge> _templates = [
    // --- Featured Quests (The Metropolis Series) ---
    const Challenge(
      id: 'quest_deep_work_protocol',
      title: 'The Deep Work Protocol',
      description:
          'Master your cognitive capacity. Complete 14 days of distraction-free deep work sessions in your flow state.',
      imageUrl: 'assets/images/challenges/deep_work_protocol.png',
      reward: '800 XP & Neural Link Emblem',
      participants: 1240,
      daysLeft: 14,
      totalDays: 14,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 800,
      archetypeId: 'scholar',
      category: ChallengeCategory.learning,
      steps: [
        ChallengeStep(day: 1, title: 'Foundation', description: 'Setup your deep work environment and complete a 60min session.'),
        ChallengeStep(day: 2, title: 'Day 2 Check-in', description: 'Complete your second deep work session.'),
        ChallengeStep(day: 3, title: 'Day 3 Check-in', description: 'Stay consistent and complete a deep work session.'),
        ChallengeStep(day: 4, title: 'Day 4 Check-in', description: 'Maintain your deep work streak.'),
        ChallengeStep(day: 5, title: 'Day 5 Check-in', description: 'Halfway to the first milestone — keep going.'),
        ChallengeStep(day: 6, title: 'Day 6 Check-in', description: 'One more day until your milestone.'),
        ChallengeStep(day: 7, title: 'The Plateau', description: 'Complete a 120min session without a single digital distraction.'),
        ChallengeStep(day: 8, title: 'Day 8 Check-in', description: 'Resume your routine after the milestone.'),
        ChallengeStep(day: 9, title: 'Day 9 Check-in', description: 'Building momentum toward the final week.'),
        ChallengeStep(day: 10, title: 'Day 10 Check-in', description: 'Two thirds done — stay disciplined.'),
        ChallengeStep(day: 11, title: 'Day 11 Check-in', description: 'The final stretch is approaching.'),
        ChallengeStep(day: 12, title: 'Day 12 Check-in', description: 'Almost there — keep your focus sharp.'),
        ChallengeStep(day: 13, title: 'Day 13 Check-in', description: 'One day left — finish strong.'),
        ChallengeStep(day: 14, title: 'Cognitive Mastery', description: 'Reach a total of 20 hours of deep work in 14 days.'),
      ],
    ),
    const Challenge(
      id: 'quest_system_reset',
      title: 'The System Reset',
      description:
          'Regulate your nervous system. 10 days of analog evenings and sunset rituals to reclaim your focus.',
      imageUrl: 'assets/images/challenges/system_reset.png',
      reward: '600 XP & Zen Spark',
      participants: 850,
      daysLeft: 10,
      totalDays: 10,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 600,
      archetypeId: 'stoic',
      category: ChallengeCategory.mindfulness,
      steps: [
        ChallengeStep(day: 1, title: 'Analog Evening', description: 'No screens 60 minutes before bed.'),
        ChallengeStep(day: 2, title: 'Day 2 Check-in', description: 'Continue your analog evening routine.'),
        ChallengeStep(day: 3, title: 'Day 3 Check-in', description: 'Notice changes in your sleep quality.'),
        ChallengeStep(day: 4, title: 'Day 4 Check-in', description: 'Stay consistent with your sunset ritual.'),
        ChallengeStep(day: 5, title: 'Circadian Sync', description: 'Get direct morning sunlight and maintain the sunset ritual.'),
        ChallengeStep(day: 6, title: 'Day 6 Check-in', description: 'Halfway through — keep up the routine.'),
        ChallengeStep(day: 7, title: 'Day 7 Check-in', description: 'Your nervous system is recalibrating.'),
        ChallengeStep(day: 8, title: 'Day 8 Check-in', description: 'Almost there — stay the course.'),
        ChallengeStep(day: 9, title: 'Day 9 Check-in', description: 'One more day before final calibration.'),
        ChallengeStep(day: 10, title: 'Full Calibration', description: 'Observe the shift in your sleep quality and focus.'),
      ],
    ),
    const Challenge(
      id: 'quest_creation_first',
      title: 'Creation First Initiative',
      description:
          'Shift from consumer to creator. Produce one meaningful artifact every morning before checking any feed.',
      imageUrl: 'assets/images/challenges/creation_first.png',
      reward: '500 XP & Maker Mark',
      participants: 2100,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 500,
      archetypeId: 'creator',
      category: ChallengeCategory.productivity,
      steps: [
        ChallengeStep(day: 1, title: 'The Spark', description: 'Create your first artifact before 9 AM.'),
        ChallengeStep(day: 2, title: 'Day 2 Check-in', description: 'Create before consuming — repeat yesterday\'s success.'),
        ChallengeStep(day: 3, title: 'Day 3 Check-in', description: 'Three days of creation — you\'re building momentum.'),
        ChallengeStep(day: 4, title: 'Momentum', description: 'Four consecutive days of creation before consumption.'),
        ChallengeStep(day: 5, title: 'Day 5 Check-in', description: 'Over halfway there — the habit is forming.'),
        ChallengeStep(day: 6, title: 'Day 6 Check-in', description: 'Almost a week of creation-first mindset.'),
        ChallengeStep(day: 7, title: 'Identity Shift', description: 'Finalize a small project started during the week.'),
      ],
    ),
    const Challenge(
      id: 'quest_titan_endurance',
      title: 'The Titan Endurance',
      description:
          'Forge physical resilience. 21 days of progressive physical mastery and recovery discipline.',
      imageUrl: 'assets/images/challenges/titan_endurance.png',
      reward: '1000 XP & Titan Sigil',
      participants: 560,
      daysLeft: 21,
      totalDays: 21,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 1000,
      archetypeId: 'athlete',
      category: ChallengeCategory.fitness,
      steps: [
        ChallengeStep(day: 1, title: 'Initial Push', description: 'Complete your baseline endurance test.'),
        ChallengeStep(day: 2, title: 'Day 2 Check-in', description: 'Recovery matters — complete your workout.'),
        ChallengeStep(day: 3, title: 'Day 3 Check-in', description: 'Stay consistent with your training.'),
        ChallengeStep(day: 4, title: 'Day 4 Check-in', description: 'Push through the initial soreness.'),
        ChallengeStep(day: 5, title: 'Day 5 Check-in', description: 'The body adapts — keep going.'),
        ChallengeStep(day: 6, title: 'Day 6 Check-in', description: 'Nearly a week of training.'),
        ChallengeStep(day: 7, title: 'Day 7 Check-in', description: 'One week down — you\'re building discipline.'),
        ChallengeStep(day: 8, title: 'Day 8 Check-in', description: 'Your endurance is improving every day.'),
        ChallengeStep(day: 9, title: 'Day 9 Check-in', description: 'Stay focused on your training goals.'),
        ChallengeStep(day: 10, title: 'Day 10 Check-in', description: 'Double digits — approaching the peak volume week.'),
        ChallengeStep(day: 11, title: 'The Grind', description: 'Maintain intensity during the peak volume week.'),
        ChallengeStep(day: 12, title: 'Day 12 Check-in', description: 'Through the peak — keep your discipline.'),
        ChallengeStep(day: 13, title: 'Day 13 Check-in', description: 'The body is getting stronger.'),
        ChallengeStep(day: 14, title: 'Day 14 Check-in', description: 'Two weeks of consistent training.'),
        ChallengeStep(day: 15, title: 'Day 15 Check-in', description: 'Over halfway — the finish line is in sight.'),
        ChallengeStep(day: 16, title: 'Day 16 Check-in', description: 'Keep your form sharp and your mind focused.'),
        ChallengeStep(day: 17, title: 'Day 17 Check-in', description: 'The final week is approaching.'),
        ChallengeStep(day: 18, title: 'Day 18 Check-in', description: 'Three days left — maintain intensity.'),
        ChallengeStep(day: 19, title: 'Day 19 Check-in', description: 'Two days remaining — give it everything.'),
        ChallengeStep(day: 20, title: 'Day 20 Check-in', description: 'One day left before the final test.'),
        ChallengeStep(day: 21, title: 'Ascension', description: 'Surpass your previous endurance limits.'),
      ],
    ),
    const Challenge(
      id: 'quest_absolute_protocol',
      title: 'The Absolute Protocol',
      description:
          'Zero tolerance for mediocrity. 30 days of uncompromising discipline across all life dimensions.',
      imageUrl:
          'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?q=80&w=1000',
      reward: '1500 XP & Zenith Seal',
      participants: 320,
      daysLeft: 30,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 1500,
      archetypeId: 'zealot',
      category: ChallengeCategory.productivity,
      steps: [
        ChallengeStep(day: 1, title: 'The Vow', description: 'Commit to the protocol and eliminate your primary vice.'),
        ChallengeStep(day: 2, title: 'Day 2 Check-in', description: 'Day 2 — stay true to your commitment.'),
        ChallengeStep(day: 3, title: 'Day 3 Check-in', description: 'The first week is the hardest — push through.'),
        ChallengeStep(day: 4, title: 'Day 4 Check-in', description: 'Discipline is doing what\'s hard.'),
        ChallengeStep(day: 5, title: 'Day 5 Check-in', description: 'Five days — you\'re proving yourself.'),
        ChallengeStep(day: 6, title: 'Day 6 Check-in', description: 'The habit loop is forming.'),
        ChallengeStep(day: 7, title: 'Day 7 Check-in', description: 'One week of absolute discipline.'),
        ChallengeStep(day: 8, title: 'Day 8 Check-in', description: 'You\'ve defeated your first week\'s resistance.'),
        ChallengeStep(day: 9, title: 'Day 9 Check-in', description: 'Keep your standards high.'),
        ChallengeStep(day: 10, title: 'Day 10 Check-in', description: 'Double digits — the protocol is becoming routine.'),
        ChallengeStep(day: 11, title: 'Day 11 Check-in', description: 'Halfway to the mid-point milestone.'),
        ChallengeStep(day: 12, title: 'Day 12 Check-in', description: 'Stay vigilant — complacency is the enemy.'),
        ChallengeStep(day: 13, title: 'Day 13 Check-in', description: 'Nearly two weeks of transformation.'),
        ChallengeStep(day: 14, title: 'Day 14 Check-in', description: 'One day before the Crucible.'),
        ChallengeStep(day: 15, title: 'The Crucible', description: 'Maintain total focus through the midpoint fatigue.'),
        ChallengeStep(day: 16, title: 'Day 16 Check-in', description: 'You\'ve passed the midpoint — keep going.'),
        ChallengeStep(day: 17, title: 'Day 17 Check-in', description: 'Your new identity is solidifying.'),
        ChallengeStep(day: 18, title: 'Day 18 Check-in', description: 'Don\'t let up now — you\'re past the hardest part.'),
        ChallengeStep(day: 19, title: 'Day 19 Check-in', description: 'Two thirds done. The end is in sight.'),
        ChallengeStep(day: 20, title: 'Day 20 Check-in', description: 'Twenty days of discipline.'),
        ChallengeStep(day: 21, title: 'Day 21 Check-in', description: 'Three weeks of the Absolute Protocol.'),
        ChallengeStep(day: 22, title: 'Day 22 Check-in', description: 'Your habits have rewired.'),
        ChallengeStep(day: 23, title: 'Day 23 Check-in', description: 'The final week approaches.'),
        ChallengeStep(day: 24, title: 'Day 24 Check-in', description: 'One week left — finish with purpose.'),
        ChallengeStep(day: 25, title: 'Day 25 Check-in', description: 'Five days remaining. Stay sharp.'),
        ChallengeStep(day: 26, title: 'Day 26 Check-in', description: 'Four days to Absolute Dominion.'),
        ChallengeStep(day: 27, title: 'Day 27 Check-in', description: 'Three days left — no compromises.'),
        ChallengeStep(day: 28, title: 'Day 28 Check-in', description: 'Two days remaining — you\'ve come so far.'),
        ChallengeStep(day: 29, title: 'Day 29 Check-in', description: 'One day left. Finish what you started.'),
        ChallengeStep(day: 30, title: 'Absolute Dominion', description: 'Complete the 30-day ascension protocol.'),
      ],
    ),
  ];

  static final Map<String, List<Map<String, dynamic>>> _dailyTemplates = {
    'athlete': [
      {
        'title': 'The Spartan Morning',
        'description': '30s cold shower + 15min fasted mobility work.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1000',
        'category': ChallengeCategory.fitness,
      },
      {
        'title': 'Zone 2 Foundation',
        'description':
            '30 minutes of steady-state cardio at conversational pace.',
        'imageUrl':
            'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?q=80&w=1000',
        'category': ChallengeCategory.fitness,
      },
    ],
    'scholar': [
      {
        'title': 'The Socratic Question',
        'description':
            'Identify a deeply held belief and write 3 counter-arguments for it.',
        'imageUrl':
            'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=1000',
        'category': ChallengeCategory.learning,
      },
      {
        'title': 'Micro-Insight',
        'description':
            'Learn one new concept in your field and explain it to a "child".',
        'imageUrl':
            'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?q=80&w=1000',
        'category': ChallengeCategory.learning,
      },
    ],
    'creator': [
      {
        'title': 'The 4-Hour MVP',
        'description':
            'Build a basic prototype or draft of a new idea in under 4 hours.',
        'imageUrl':
            'https://images.unsplash.com/photo-1499750310107-5fef28a66643?q=80&w=1000',
        'category': ChallengeCategory.productivity,
      },
      {
        'title': 'Visual Flow',
        'description':
            'Produce a 15-minute raw sketch or brainstorming mind-map.',
        'imageUrl':
            'https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=1000',
        'category': ChallengeCategory.productivity,
      },
    ],
    'stoic': [
      {
        'title': 'The Dopamine Detox',
        'description':
            'Zero digital entertainment for 24 hours. Focus on stillness.',
        'imageUrl':
            'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=1000',
        'category': ChallengeCategory.mindfulness,
      },
      {
        'title': 'Negative Visualization',
        'description':
            'Contemplate a loss you fear and find 3 ways you would adapt.',
        'imageUrl':
            'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?q=80&w=1000',
        'category': ChallengeCategory.mindfulness,
      },
    ],
    'zealot': [
      {
        'title': 'The Absolute Focus',
        'description':
            'Complete your single most important task before 10 AM. No exceptions.',
        'imageUrl':
            'https://images.unsplash.com/photo-1497215728101-856f4ea42174?q=80&w=1000',
        'category': ChallengeCategory.productivity,
      },
      {
        'title': 'Monastic Hour',
        'description':
            'One hour of intense work with zero notifications and zero speaking.',
        'imageUrl':
            'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?q=80&w=1000',
        'category': ChallengeCategory.productivity,
      },
    ],
  };

  /// Returns all templates marked as featured.
  static List<Challenge> getFeatured() {
    return _templates
        .where((c) => c.status == ChallengeStatus.featured)
        .toList();
  }

  /// Returns all available challenges for an archetype (featured + generated daily).
  static List<Challenge> getAvailableChallenges(String archetypeId) {
    final archetypeFeatured = _templates
        .where((c) => c.archetypeId == archetypeId.toLowerCase())
        .toList();

    // Also include a fresh daily quest for this archetype
    final daily = getDailyQuest(archetypeId);

    return [...archetypeFeatured, daily];
  }

  /// Returns the weekly spotlight for an archetype.
  static Challenge getWeeklySpotlight(String archetypeId) {
    final archetypeTemplates = _templates
        .where((c) => c.archetypeId == archetypeId.toLowerCase())
        .toList();

    if (archetypeTemplates.isEmpty) {
      return _templates.first;
    }

    final now = DateTime.now().toUtc();
    final weekNumber = (now.difference(DateTime.utc(2024)).inDays / 7).floor();
    final index = weekNumber % archetypeTemplates.length;
    return archetypeTemplates[index];
  }

  /// Generates a daily quest based on archetype and day of week.
  static Challenge getDailyQuest(String archetypeId) {
    final templates =
        _dailyTemplates[archetypeId.toLowerCase()] ??
        _dailyTemplates['athlete']!;
    final now = DateTime.now().toUtc();
    final dayOfWeek = now.weekday - 1; // 0 = Monday, 6 = Sunday
    final template = templates[dayOfWeek % templates.length];

    final String archetypeDefaultImage = switch (archetypeId.toLowerCase()) {
      'athlete' =>
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1000',
      'scholar' =>
        'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=1000',
      'creator' =>
        'https://images.unsplash.com/photo-1499750310107-5fef28a66643?q=80&w=1000',
      'stoic' =>
        'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=1000',
      'zealot' =>
        'https://images.unsplash.com/photo-1497215728101-856f4ea42174?q=80&w=1000',
      _ =>
        'https://images.unsplash.com/photo-1497215728101-856f4ea42174?q=80&w=1000',
    };

    return Challenge(
      id: 'daily_${archetypeId}_${now.year}_${now.month}_${now.day}',
      title: template['title'] as String,
      description: template['description'] as String,
      imageUrl: template['imageUrl'] as String? ?? archetypeDefaultImage,
      reward: '${100 + (dayOfWeek * 10)} XP',
      participants: 0,
      daysLeft: 1,
      totalDays: 1,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 100 + (dayOfWeek * 10),
      category: template['category'] as ChallengeCategory,
      steps: [
        ChallengeStep(
          day: 1,
          title: template['title'] as String,
          description: template['description'] as String,
        ),
      ],
      archetypeId: archetypeId,
      isFeatured: false,
      isTeamChallenge: false,
    );
  }

  /// Get a specific challenge by its ID.
  /// Searches featured templates, weekly spotlights, and daily quests.
  static Challenge? getChallengeById(String id) {
    // Check featured templates first
    final match = _templates.where((c) => c.id == id).firstOrNull;
    if (match != null) return match;

    // Check weekly and daily generated quests for each archetype
    final archetypes = ['athlete', 'scholar', 'creator', 'stoic', 'zealot'];
    for (final archetype in archetypes) {
      final weekly = getWeeklySpotlight(archetype);
      if (weekly.id == id) return weekly;

      final daily = getDailyQuest(archetype);
      if (daily.id == id) return daily;
    }
    return null;
  }
}
