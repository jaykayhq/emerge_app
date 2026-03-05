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
}
