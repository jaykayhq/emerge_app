import 'package:emerge_app/features/social/domain/models/challenge.dart';

/// A static catalog of challenge templates used to generate daily and weekly challenges locally.
class ChallengeCatalog {
  static final List<Challenge> _templates = [
    // --- The Athletes ---
    const Challenge(
      id: 'template_athlete_1',
      title: 'The Steel Protocol',
      description: 'Push your physical limits for 7 days straight. No excuses.',
      imageUrl: 'assets/images/challenges/athlete_steel.png',
      reward: '500 XP & Steel Emblem',
      participants: 0,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 500,
      archetypeId: 'athlete',
      category: ChallengeCategory.fitness,
      steps: [
        ChallengeStep(
          day: 1,
          title: 'Day 1: Foundation',
          description: 'Complete a 30-minute intense workout.',
        ),
        ChallengeStep(
          day: 2,
          title: 'Day 2: Endurance',
          description: 'Run or cycle for 45 minutes.',
        ),
        ChallengeStep(
          day: 3,
          title: 'Day 3: Strength',
          description: 'Focus on core and upper body strength.',
        ),
        ChallengeStep(
          day: 4,
          title: 'Day 4: Recovery',
          description: 'Active recovery: stretching or yoga.',
        ),
        ChallengeStep(
          day: 5,
          title: 'Day 5: HIIT',
          description: '20 minutes of High-Intensity Interval Training.',
        ),
        ChallengeStep(
          day: 6,
          title: 'Day 6: The Long Push',
          description: 'A 60-minute steady-state workout.',
        ),
        ChallengeStep(
          day: 7,
          title: 'Day 7: The Pinnacle',
          description: 'Achieve a new personal best.',
        ),
      ],
    ),
    const Challenge(
      id: 'template_athlete_2',
      title: 'Iron Will',
      description:
          'A test of daily consistency and discipline in your training.',
      imageUrl: 'assets/images/challenges/athlete_iron.png',
      reward: '400 XP',
      participants: 0,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 400,
      archetypeId: 'athlete',
      category: ChallengeCategory.fitness,
      steps: [
        ChallengeStep(
          day: 1,
          title: 'Morning Routine',
          description: 'Work out before 8 AM.',
        ),
        ChallengeStep(
          day: 2,
          title: 'Hydration Focus',
          description: 'Drink 3 liters of water minimum.',
        ),
        ChallengeStep(
          day: 3,
          title: 'Mobility',
          description: 'Spend 20 mins on deep stretching.',
        ),
        ChallengeStep(
          day: 4,
          title: 'Strength',
          description: 'Lift heavy or do advanced calisthenics.',
        ),
        ChallengeStep(
          day: 5,
          title: 'Cardio Boost',
          description: 'Elevate heart rate for 30 mins.',
        ),
        ChallengeStep(
          day: 6,
          title: 'Active Rest',
          description: 'Light walk or swim.',
        ),
        ChallengeStep(
          day: 7,
          title: 'Reflection',
          description: 'Log your weekly progress and max lifts.',
        ),
      ],
    ),

    // --- The Scholars ---
    const Challenge(
      id: 'template_scholar_1',
      title: 'Deep Work Sprint',
      description: 'Engage in focused, distraction-free learning sessions.',
      imageUrl: 'assets/images/challenges/scholar_deep.png',
      reward: '500 XP',
      participants: 0,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 500,
      archetypeId: 'scholar',
      category: ChallengeCategory.learning,
      steps: [
        ChallengeStep(
          day: 1,
          title: 'Setup',
          description: 'Organize your workspace for deep work.',
        ),
        ChallengeStep(
          day: 2,
          title: 'Focus 1',
          description: 'Complete 2 hours of uninterrupted study.',
        ),
        ChallengeStep(
          day: 3,
          title: 'Synthesis',
          description: 'Write a summary of what you learned.',
        ),
        ChallengeStep(
          day: 4,
          title: 'Focus 2',
          description: 'Another 2 hours of deep concentration.',
        ),
        ChallengeStep(
          day: 5,
          title: 'Application',
          description: 'Apply your knowledge to a practical problem.',
        ),
        ChallengeStep(
          day: 6,
          title: 'Review',
          description: 'Review your notes and identify gaps.',
        ),
        ChallengeStep(
          day: 7,
          title: 'Mastery',
          description: 'Teach the concept to someone else.',
        ),
      ],
    ),
    const Challenge(
      id: 'template_scholar_2',
      title: 'The Codex Challenge',
      description: 'Consume and summarize high-density information.',
      imageUrl: 'assets/images/challenges/scholar_codex.png',
      reward: '450 XP',
      participants: 0,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 450,
      archetypeId: 'scholar',
      category: ChallengeCategory.learning,
      steps: [
        ChallengeStep(
          day: 1,
          title: 'Selection',
          description: 'Choose a complex book or paper.',
        ),
        ChallengeStep(
          day: 2,
          title: 'First Pass',
          description: 'Read the intro, conclusion, and headers.',
        ),
        ChallengeStep(
          day: 3,
          title: 'Deep Dive 1',
          description: 'Read and annotate the first half.',
        ),
        ChallengeStep(
          day: 4,
          title: 'Deep Dive 2',
          description: 'Read and annotate the second half.',
        ),
        ChallengeStep(
          day: 5,
          title: 'Distillation',
          description: 'Extract the top 5 key insights.',
        ),
        ChallengeStep(
          day: 6,
          title: 'Connection',
          description: 'Link these insights to existing knowledge.',
        ),
        ChallengeStep(
          day: 7,
          title: 'Publish',
          description: 'Share your summary publicly.',
        ),
      ],
    ),

    // --- The Creators ---
    const Challenge(
      id: 'template_creator_1',
      title: '7 Days of Creation',
      description: 'Ship one small piece of art, code, or writing every day.',
      imageUrl: 'assets/images/challenges/creator_ship.png',
      reward: '500 XP',
      participants: 0,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 500,
      archetypeId: 'creator',
      category: ChallengeCategory.creative,
      steps: [
        ChallengeStep(
          day: 1,
          title: 'Ideation',
          description: 'Brainstorm and draft your first piece.',
        ),
        ChallengeStep(
          day: 2,
          title: 'Momentum',
          description: 'Create and ship piece #2.',
        ),
        ChallengeStep(
          day: 3,
          title: 'Experiment',
          description: 'Try a slightly different style for piece #3.',
        ),
        ChallengeStep(
          day: 4,
          title: 'Consistency',
          description: 'Ship piece #4, focus on quality.',
        ),
        ChallengeStep(
          day: 5,
          title: 'Collaboration',
          description: 'Incorporate feedback into piece #5.',
        ),
        ChallengeStep(
          day: 6,
          title: 'Refinement',
          description: 'Spend extra time polishing piece #6.',
        ),
        ChallengeStep(
          day: 7,
          title: 'The Portfolio',
          description: 'Ship piece #7 and review the week.',
        ),
      ],
    ),
    const Challenge(
      id: 'template_creator_2',
      title: 'The Spark',
      description: 'Ignite your creativity by breaking routine.',
      imageUrl: 'assets/images/challenges/creator_spark.png',
      reward: '400 XP',
      participants: 0,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 400,
      archetypeId: 'creator',
      category: ChallengeCategory.creative,
      steps: [
        ChallengeStep(
          day: 1,
          title: 'Observation',
          description: 'Spend 30 mins observing without devices.',
        ),
        ChallengeStep(
          day: 2,
          title: 'New Medium',
          description: 'Create using a tool you normally avoid.',
        ),
        ChallengeStep(
          day: 3,
          title: 'Limitation',
          description: 'Create something using only 2 colors/tools.',
        ),
        ChallengeStep(
          day: 4,
          title: 'Recreation',
          description: 'Remix a piece of art you admire.',
        ),
        ChallengeStep(
          day: 5,
          title: 'The Void',
          description: 'Sit in silence for 15 mins before creating.',
        ),
        ChallengeStep(
          day: 6,
          title: 'Drafting',
          description: 'Outline a major project idea.',
        ),
        ChallengeStep(
          day: 7,
          title: 'Execution',
          description: 'Take the first concrete step on the major project.',
        ),
      ],
    ),

    // --- The Stoics ---
    const Challenge(
      id: 'template_stoic_1',
      title: 'Mind of Marble',
      description: 'Practice emotional regulation and voluntary discomfort.',
      imageUrl: 'assets/images/challenges/stoic_marble.png',
      reward: '500 XP',
      participants: 0,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 500,
      archetypeId: 'stoic',
      category: ChallengeCategory.mindfulness,
      steps: [
        ChallengeStep(
          day: 1,
          title: 'Silence',
          description: 'No complaining, out loud or internally, all day.',
        ),
        ChallengeStep(
          day: 2,
          title: 'Discomfort',
          description: 'Take a cold shower or sleep without a pillow.',
        ),
        ChallengeStep(
          day: 3,
          title: 'Meditation',
          description: '20 minutes of mindful breathing.',
        ),
        ChallengeStep(
          day: 4,
          title: 'Negative Visualization',
          description: 'Reflect on losing what you value.',
        ),
        ChallengeStep(
          day: 5,
          title: 'Fasting',
          description: 'Skip one meal to appreciate sustenance.',
        ),
        ChallengeStep(
          day: 6,
          title: 'Digital Detox',
          description: 'Zero screen time outside of essential work.',
        ),
        ChallengeStep(
          day: 7,
          title: 'Journaling',
          description: 'Write an honest reflection of your character.',
        ),
      ],
    ),
    const Challenge(
      id: 'template_stoic_2',
      title: 'The Inner Citadel',
      description: 'Build resilience against external events.',
      imageUrl: 'assets/images/challenges/stoic_citadel.png',
      reward: '450 XP',
      participants: 0,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 450,
      archetypeId: 'stoic',
      category: ChallengeCategory.mindfulness,
      steps: [
        ChallengeStep(
          day: 1,
          title: 'Dichotomy of Control',
          description: 'List what is and isn\'t in your power today.',
        ),
        ChallengeStep(
          day: 2,
          title: 'Pause',
          description: 'Wait 5 seconds before responding to any stimulus.',
        ),
        ChallengeStep(
          day: 3,
          title: 'Amor Fati',
          description: 'Embrace a setback that happens today.',
        ),
        ChallengeStep(
          day: 4,
          title: 'View from Above',
          description: 'Meditate on the vastness of the universe.',
        ),
        ChallengeStep(
          day: 5,
          title: 'Poverty Practice',
          description: 'Live today as simply and cheaply as possible.',
        ),
        ChallengeStep(
          day: 6,
          title: 'Objective Framing',
          description: 'Describe events today without value judgments.',
        ),
        ChallengeStep(
          day: 7,
          title: 'Evening Review',
          description: 'Review your actions: what was done well/poorly?',
        ),
      ],
    ),

    // --- The Zealots ---
    const Challenge(
      id: 'template_zealot_1',
      title: 'Unwavering Devotion',
      description: 'Commit to your core purpose with absolute intensity.',
      imageUrl: 'assets/images/challenges/zealot_devotion.png',
      reward: '500 XP',
      participants: 0,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 500,
      archetypeId: 'zealot',
      category: ChallengeCategory.faith,
      steps: [
        ChallengeStep(
          day: 1,
          title: 'Declaration',
          description: 'Write down your ultimate mission clearly.',
        ),
        ChallengeStep(
          day: 2,
          title: 'Purge',
          description: 'Eliminate one major distraction from your life.',
        ),
        ChallengeStep(
          day: 3,
          title: 'Sacrifice',
          description: 'Give up a comfort to focus on your mission.',
        ),
        ChallengeStep(
          day: 4,
          title: 'Deep Immersion',
          description: 'Spend 2 hours solely dedicated to your cause.',
        ),
        ChallengeStep(
          day: 5,
          title: 'Evangelize',
          description: 'Share your passion or mission with someone else.',
        ),
        ChallengeStep(
          day: 6,
          title: 'Study the Greats',
          description: 'Analyze someone who achieved your mission.',
        ),
        ChallengeStep(
          day: 7,
          title: 'Vow',
          description: 'Make a binding commitment for the next month.',
        ),
      ],
    ),
    const Challenge(
      id: 'template_zealot_2',
      title: 'Trial by Fire',
      description: 'Test your commitment through rigorous action.',
      imageUrl: 'assets/images/challenges/zealot_fire.png',
      reward: '450 XP',
      participants: 0,
      daysLeft: 7,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 450,
      archetypeId: 'zealot',
      category: ChallengeCategory.faith,
      steps: [
        ChallengeStep(
          day: 1,
          title: 'The Spark',
          description: 'Take immediate action on a delayed goal.',
        ),
        ChallengeStep(
          day: 2,
          title: 'The Flame',
          description: 'Double your usual effort today.',
        ),
        ChallengeStep(
          day: 3,
          title: 'The Heat',
          description: 'Push through when you feel like quitting.',
        ),
        ChallengeStep(
          day: 4,
          title: 'The Burn',
          description: 'Sustain high intensity for the whole day.',
        ),
        ChallengeStep(
          day: 5,
          title: 'The Crucible',
          description: 'Face your biggest fear related to your goal.',
        ),
        ChallengeStep(
          day: 6,
          title: 'The Forge',
          description: 'Refine your approach based on the week\'s trials.',
        ),
        ChallengeStep(
          day: 7,
          title: 'The Steel',
          description: 'Emerge stronger and plan the next conquest.',
        ),
      ],
    ),
  ];

  /// Generates deterministic challenges based on archetype and time.
  static Challenge getWeeklySpotlight(String archetypeId) {
    final archetypeTemplates = _templates
        .where((c) => c.archetypeId == archetypeId)
        .toList();

    // Fallback if no templates exist
    if (archetypeTemplates.isEmpty) {
      return _templates.first.copyWith(
        id: 'weekly_fallback',
        archetypeId: archetypeId,
      );
    }

    final now = DateTime.now().toUtc();
    // Weeks since epoch (approx)
    final weekNumber = (now.difference(DateTime.utc(2020)).inDays / 7).floor();

    final index = weekNumber % archetypeTemplates.length;
    final template = archetypeTemplates[index];

    return Challenge(
      id: 'weekly_${archetypeId}_$weekNumber',
      title: template.title,
      description: template.description,
      imageUrl: template.imageUrl,
      reward: template.reward,
      participants: template
          .participants, // This could be fetched from global firestore doc later
      daysLeft: 7 - (now.weekday - 1), // Days left in current week
      totalDays: template.totalDays,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: template.xpReward,
      category: template.category,
      steps: template.steps,
      archetypeId: template.archetypeId,
      isFeatured: true,
      isPremium: template.isPremium,
      rewardTitleId: template.rewardTitleId,
      rewardNameplateId: template.rewardNameplateId,
    );
  }

  /// Generates a list of available daily/weekly challenges for the archetype
  static List<Challenge> getAvailableChallenges(String archetypeId) {
    final archetypeTemplates = _templates
        .where((c) => c.archetypeId == archetypeId)
        .toList();
    if (archetypeTemplates.isEmpty) return [];

    final now = DateTime.now().toUtc();
    final weekNumber = (now.difference(DateTime.utc(2020)).inDays / 7).floor();

    // Return the weekly spotlight and perhaps a shifted "daily" one if you want
    final weekly = getWeeklySpotlight(archetypeId);

    // We can just use the next template in the array as a secondary active challenge
    final secondIndex = (weekNumber + 1) % archetypeTemplates.length;
    final secondary = archetypeTemplates[secondIndex];
    final secondaryChallenge = Challenge(
      id: 'secondary_${archetypeId}_$weekNumber',
      title: secondary.title,
      description: secondary.description,
      imageUrl: secondary.imageUrl,
      reward: secondary.reward,
      participants: secondary.participants,
      daysLeft: 7 - (now.weekday - 1),
      totalDays: secondary.totalDays,
      currentDay: 0,
      status: ChallengeStatus.active,
      xpReward: secondary.xpReward,
      category: secondary.category,
      steps: secondary.steps,
      archetypeId: secondary.archetypeId,
      isFeatured: false,
    );

    return [weekly, secondaryChallenge];
  }

  /// Get a specific generated challenge by its ID
  static Challenge? getChallengeById(String id) {
    final archetypes = ['athlete', 'scholar', 'creator', 'stoic', 'zealot'];
    for (final archetype in archetypes) {
      final weekly = getWeeklySpotlight(archetype);
      if (weekly.id == id) return weekly;

      final daily = getDailyQuest(archetype);
      if (daily.id == id) return daily;

      final available = getAvailableChallenges(archetype);
      for (final challenge in available) {
        if (challenge.id == id) return challenge;
      }
    }
    return null;
  }

  /// Get a specific template by ID (useful when joining a known generated challenge)
  static Challenge? getTemplateById(String id) {
    // Generated IDs are like 'weekly_athlete_123'. We can map back to archetype.
    // However, joinChallenge only needs the data.
    return null; // Not needed if we fetch the generated object directly
  }

  /// Daily quest templates by archetype and day of week
  static final Map<String, List<Map<String, dynamic>>> _dailyTemplates = {
    'athlete': [
      {
        'title': 'Morning Sprint',
        'description':
            'Complete a 20-minute intense cardio session to start your day with energy.',
        'category': ChallengeCategory.fitness,
      },
      {
        'title': 'Power Set',
        'description':
            'Complete 5 sets of 10 pushups throughout the day. Break it up however works for you.',
        'category': ChallengeCategory.fitness,
      },
      {
        'title': 'Active Recovery',
        'description':
            'Complete 30 minutes of stretching or mobility work to keep your body primed.',
        'category': ChallengeCategory.fitness,
      },
      {
        'title': 'Core Crusher',
        'description':
            'Complete 3 rounds of: 30 crunches, 30 second plank, 20 leg raises.',
        'category': ChallengeCategory.fitness,
      },
      {
        'title': 'Hydration Challenge',
        'description':
            'Drink 3 liters of water today. Track your intake and hit the goal.',
        'category': ChallengeCategory.nutrition,
      },
      {
        'title': 'Movement Snack',
        'description':
            'Take a 15-minute walk or do light exercises after each meal.',
        'category': ChallengeCategory.fitness,
      },
      {
        'title': 'Bodyweight Blast',
        'description':
            'Complete 100 squats, 50 lunges, and 50 jumping jacks today.',
        'category': ChallengeCategory.fitness,
      },
    ],
    'scholar': [
      {
        'title': 'Deep Focus',
        'description':
            'Complete 2 hours of uninterrupted study or reading on your chosen subject.',
        'category': ChallengeCategory.learning,
      },
      {
        'title': 'Knowledge Dump',
        'description':
            'Write a 500-word summary of what you learned this week.',
        'category': ChallengeCategory.learning,
      },
      {
        'title': 'Mind Map',
        'description':
            'Create a visual mind map connecting 5+ concepts from your current learning.',
        'category': ChallengeCategory.learning,
      },
      {
        'title': 'Question Storm',
        'description':
            'Generate 10 questions about your current topic that you cannot answer yet.',
        'category': ChallengeCategory.learning,
      },
      {
        'title': 'Teach Back',
        'description':
            'Explain a concept you learned to someone or write it as if teaching a beginner.',
        'category': ChallengeCategory.learning,
      },
      {
        'title': 'Source Hunt',
        'description':
            'Find and read 3 new articles or watch 3 videos on your topic.',
        'category': ChallengeCategory.learning,
      },
      {
        'title': 'Synthesis Session',
        'description':
            'Connect ideas from 2+ sources and write your own original insight.',
        'category': ChallengeCategory.learning,
      },
    ],
    'creator': [
      {
        'title': 'Micro Masterpiece',
        'description':
            'Create something small but complete - a sketch, poem, code snippet, or design.',
        'category': ChallengeCategory.creative,
      },
      {
        'title': 'Constraint Challenge',
        'description':
            'Create something using only one color or one tool. Limitation breeds creativity.',
        'category': ChallengeCategory.creative,
      },
      {
        'title': 'Inspiration Hunt',
        'description':
            'Find 5 examples of work that inspires you and analyze what makes them work.',
        'category': ChallengeCategory.creative,
      },
      {
        'title': 'Rapid Prototype',
        'description':
            'Create 3 quick versions of the same idea. Quantity leads to quality.',
        'category': ChallengeCategory.creative,
      },
      {
        'title': 'Reimagine',
        'description':
            'Take something existing and create your own version or remix of it.',
        'category': ChallengeCategory.creative,
      },
      {
        'title': 'Process Share',
        'description':
            'Document your creative process today - sketch, notes, drafts, anything goes.',
        'category': ChallengeCategory.creative,
      },
      {
        'title': 'Finish One',
        'description': 'Take an unfinished project and complete it. Ship it!',
        'category': ChallengeCategory.creative,
      },
    ],
    'stoic': [
      {
        'title': 'Morning Reflection',
        'description':
            'Write about what you are grateful for and what you will focus on today.',
        'category': ChallengeCategory.faith,
      },
      {
        'title': 'Negative Visualization',
        'description':
            'Spend 10 minutes visualizing losing what you have. Embrace impermanence.',
        'category': ChallengeCategory.faith,
      },
      {
        'title': 'Digital Fast',
        'description':
            'Go 4 hours without checking social media or news. Be present.',
        'category': ChallengeCategory.mindfulness,
      },
      {
        'title': 'Kindness Quest',
        'description':
            'Perform 3 anonymous acts of kindness today without expecting anything back.',
        'category': ChallengeCategory.faith,
      },
      {
        'title': 'Silence Practice',
        'description':
            'Spend 20 minutes in complete silence. No music, no podcasts, no reading.',
        'category': ChallengeCategory.mindfulness,
      },
      {
        'title': 'Evening Review',
        'description':
            'Reflect on your day: What went well? What could you improve? What did you learn?',
        'category': ChallengeCategory.faith,
      },
      {
        'title': 'Simplicity Day',
        'description':
            'Live with only what you need. Declutter one area of your space.',
        'category': ChallengeCategory.faith,
      },
    ],
    'zealot': [
      {
        'title': 'Purpose Pulse',
        'description':
            'Write about your core why. Connect today to your larger mission.',
        'category': ChallengeCategory.faith,
      },
      {
        'title': 'Community Impact',
        'description':
            'Share your message or help someone else pursue their passion today.',
        'category': ChallengeCategory.productivity,
      },
      {
        'title': 'Bold Action',
        'description':
            'Do one thing today that scares you related to your purpose.',
        'category': ChallengeCategory.productivity,
      },
      {
        'title': 'Vision Board',
        'description':
            'Create or update your vision board with where you want to be in 1 year.',
        'category': ChallengeCategory.creative,
      },
      {
        'title': 'Network Nurture',
        'description':
            'Reach out to someone who supports your mission. Thank them or collaborate.',
        'category': ChallengeCategory.productivity,
      },
      {
        'title': 'Declaration',
        'description':
            'Write a public declaration of your commitment to your purpose.',
        'category': ChallengeCategory.faith,
      },
      {
        'title': 'Celebration',
        'description':
            'Acknowledge 3 wins from your journey. Celebrate progress, not just goals.',
        'category': ChallengeCategory.faith,
      },
    ],
  };

  /// Generates a daily quest based on archetype and day of week
  static Challenge getDailyQuest(String archetypeId) {
    final templates =
        _dailyTemplates[archetypeId.toLowerCase()] ??
        _dailyTemplates['athlete']!;
    final now = DateTime.now().toUtc();
    final dayOfWeek = now.weekday - 1; // 0 = Monday, 6 = Sunday
    final template = templates[dayOfWeek % templates.length];

    return Challenge(
      id: 'daily_${archetypeId}_${now.year}_${now.month}_${now.day}',
      title: template['title'] as String,
      description: template['description'] as String,
      imageUrl: '',
      reward: '${100 + (dayOfWeek * 10)} XP',
      participants: 0,
      daysLeft: 1,
      totalDays: 1,
      currentDay: 0,
      status: ChallengeStatus.active,
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
}
