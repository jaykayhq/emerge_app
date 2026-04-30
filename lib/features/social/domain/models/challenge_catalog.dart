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
    Challenge(
      id: 'template_procrastination_slayer',
      title: 'Procrastination Slayer',
      description: 'Advice: Procrastination is emotional regulation. Learn to name your resistance and dismantle it with micro-actions over 30 days.',
      imageUrl: 'assets/images/challenges/challenge_procrastination_slayer.png',
      reward: '750 XP & Action Blade',
      participants: 0,
      daysLeft: 30,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 750,
      archetypeId: 'athlete',
      category: ChallengeCategory.productivity,
      steps: [
        ChallengeStep(day: 1, title: 'Day 1: Resistance Labeling', description: 'Write down the emotion you feel when avoiding your top task.'),
        ChallengeStep(day: 2, title: 'Day 2: The 5-Minute Start', description: 'Commit to only 5 minutes of work on an avoided task.'),
        ChallengeStep(day: 3, title: 'Day 3: Eisenhower Audit', description: 'Sort your tasks: Urgent/Important vs. Busywork.'),
        ChallengeStep(day: 4, title: 'Day 4: Micro-Tasking', description: 'Break one task into 10 tiny pieces.'),
        ChallengeStep(day: 5, title: 'Day 5: Temptation Bundle', description: 'Pair a boring task with something you love.'),
        ChallengeStep(day: 6, title: 'Day 6: No-Screen Start', description: 'Start your first task without checking any apps.'),
        ChallengeStep(day: 7, title: 'Day 7: First Week Win', description: 'Review your 7 days of action.'),
        ChallengeStep(day: 8, title: 'Day 8: Deep Work Setup', description: 'Clear all physical and digital distractions.'),
        ChallengeStep(day: 9, title: 'Day 9: The Frog', description: 'Do your hardest task first thing in the morning.'),
        ChallengeStep(day: 10, title: 'Day 10: Momentum Check', description: 'Observe the reduction in task-related anxiety.'),
        ChallengeStep(day: 11, title: 'Day 11: Just-In-Time Planning', description: 'Plan only the next 3 actionable steps.'),
        ChallengeStep(day: 12, title: 'Day 12: Public Commitment', description: 'Tell someone about a task you will ship today.'),
        ChallengeStep(day: 13, title: 'Day 13: Time Blocking', description: 'Dedicate 1 hour solely to the "scary" task.'),
        ChallengeStep(day: 14, title: 'Day 14: Halfway Persistence', description: 'Two weeks of fighting the resistance.'),
        ChallengeStep(day: 15, title: 'Day 15: Reflection', description: 'Where does the wall still feel high?'),
        ChallengeStep(day: 16, title: 'Day 16: Zero-Excuses Day', description: 'Perform the task regardless of your "feelings".'),
        ChallengeStep(day: 17, title: 'Day 17: Environment Pivot', description: 'Change locations to reset focus.'),
        ChallengeStep(day: 18, title: 'Day 18: Accountability Loop', description: 'Report your progress to your tribe.'),
        ChallengeStep(day: 19, title: 'Day 19: Batching', description: 'Batch all small tasks to free up deep time.'),
        ChallengeStep(day: 20, title: 'Day 20: Identity Vote', description: 'Tell yourself: "I am someone who gets things done."'),
        ChallengeStep(day: 21, title: 'Day 21: Three Weeks', description: 'The habit of starting is forming.'),
        ChallengeStep(day: 22, title: 'Day 22: Focus Stamina', description: 'Extend your focus session by 10 minutes.'),
        ChallengeStep(day: 23, title: 'Day 23: Review Ritual', description: 'End the day by planning tomorrow\'s 1st task.'),
        ChallengeStep(day: 24, title: 'Day 24: Discipline Over Motivation', description: 'Start even if motivation is zero.'),
        ChallengeStep(day: 25, title: 'Day 25: The Final Push', description: 'Tackle the biggest project on your list.'),
        ChallengeStep(day: 26, title: 'Day 26: Mastery', description: 'The 5-minute start is now automatic.'),
        ChallengeStep(day: 27, title: 'Day 27: System Check', description: 'Refine your personal anti-procrastination system.'),
        ChallengeStep(day: 28, title: 'Day 28: Results', description: 'Ship or finish a major deliverable.'),
        ChallengeStep(day: 29, title: 'Day 29: Final Preparation', description: 'Prepare to celebrate 30 days of action.'),
        ChallengeStep(day: 30, title: 'Day 30: Slayer Title', description: 'Challenge complete. You have slain the resistance.'),
      ],
    ),
    Challenge(
      id: 'template_willpower_forge',
      title: 'Willpower Forge',
      description: 'Advice: Willpower is a skill, not a limited resource. Harden your resolve through 30 days of voluntary discomfort and discipline.',
      imageUrl: 'assets/images/challenges/challenge_willpower_forge.png',
      reward: '800 XP & Iron Resolve',
      participants: 0,
      daysLeft: 30,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 800,
      archetypeId: 'stoic',
      category: ChallengeCategory.mindfulness,
      steps: [
        ChallengeStep(day: 1, title: 'Day 1: The Cold Start', description: '30-second cold shower blast.'),
        ChallengeStep(day: 2, title: 'Day 2: No-Phone Morning', description: 'No devices for the first 60 minutes after waking.'),
        ChallengeStep(day: 3, title: 'Day 3: Sugar Detox', description: 'No added sugar all day.'),
        ChallengeStep(day: 4, title: 'Day 4: Delayed Gratification', description: 'Wait 10 minutes before responding to notifications.'),
        ChallengeStep(day: 5, title: 'Day 5: Posture Control', description: 'Maintain perfect posture throughout all meetings/work.'),
        ChallengeStep(day: 6, title: 'Day 6: Deep Silence', description: '15 minutes of sitting in total silence.'),
        ChallengeStep(day: 7, title: 'Day 7: First Week Forge', description: 'Reflect on your increased discipline.'),
        ChallengeStep(day: 8, title: 'Day 8: Early Rise', description: 'Wake up 30 minutes earlier than usual.'),
        ChallengeStep(day: 9, title: 'Day 9: Physical Grit', description: 'Double your usual exercise intensity.'),
        ChallengeStep(day: 10, title: 'Day 10: Stoic Response', description: 'Do not complain about anything today.'),
        ChallengeStep(day: 11, title: 'Day 11: Focused Fast', description: 'Skip one meal to practice appetite control.'),
        ChallengeStep(day: 12, title: 'Day 12: Digital Sunset', description: 'No screens 90 minutes before bed.'),
        ChallengeStep(day: 13, title: 'Day 13: Financial Discipline', description: 'Zero discretionary spending today.'),
        ChallengeStep(day: 14, title: 'Day 14: Fortnight of Iron', description: 'Two weeks of resolve.'),
        ChallengeStep(day: 15, title: 'Day 15: Midway Test', description: 'Face your biggest temptation head-on and say "No".'),
        ChallengeStep(day: 16, title: 'Day 16: Cold Exposure+', description: '60-second cold shower blast.'),
        ChallengeStep(day: 17, title: 'Day 17: Attention Guard', description: 'Block all distractions for 4 hours.'),
        ChallengeStep(day: 18, title: 'Day 18: Uncomfortable Conversation', description: 'Address a lingering issue you\'ve been avoiding.'),
        ChallengeStep(day: 19, title: 'Day 19: Minimalism Day', description: 'Live with only the bare essentials today.'),
        ChallengeStep(day: 20, title: 'Day 20: Mental Fortitude', description: 'Perform 10 minutes of box breathing.'),
        ChallengeStep(day: 21, title: 'Day 21: Three Weeks', description: 'Your self-control is visibly stronger.'),
        ChallengeStep(day: 22, title: 'Day 22: Radical Honesty', description: 'Be 100% honest in all interactions.'),
        ChallengeStep(day: 23, title: 'Day 23: Endurance Focus', description: 'Complete a task you dislike for 1 hour.'),
        ChallengeStep(day: 24, title: 'Day 24: Grit Test', description: 'Push through a physical or mental barrier.'),
        ChallengeStep(day: 25, title: 'Day 25: Final Stretch', description: 'Maintain all previous disciplines.'),
        ChallengeStep(day: 26, title: 'Day 26: Mastery of Self', description: 'You dictate your actions, not your impulses.'),
        ChallengeStep(day: 27, title: 'Day 27: Optimized Resolve', description: 'Refine your personal discipline protocol.'),
        ChallengeStep(day: 28, title: 'Day 28: Longevity Prep', description: 'Plan how to keep this resolve for life.'),
        ChallengeStep(day: 29, title: 'Day 29: Final Reflection', description: 'Who were you 29 days ago?'),
        ChallengeStep(day: 30, title: 'Day 30: Iron Resolve', description: 'Forge complete. You are the master of your will.'),
      ],
    ),

    // --- Research Based Challenges ---
    Challenge(
      id: 'template_deep_work_1',
      title: 'Flow State Quest',
      description: 'Master the art of focused concentration. 60 minutes of uninterrupted work daily.',
      imageUrl: 'assets/images/challenges/challenge_flow_state_quest.png',
      reward: '500 XP & Focus Emblem',
      participants: 0,
      daysLeft: 30,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 500,
      archetypeId: 'scholar',
      category: ChallengeCategory.learning,
      steps: [
        ChallengeStep(day: 1, title: 'Day 1: Setup', description: 'Configure your environment for deep work.'),
        ChallengeStep(day: 2, title: 'Day 2: First Session', description: 'Complete your first 60-minute deep work session.'),
        ChallengeStep(day: 3, title: 'Day 3: Consistency', description: 'Complete day 3 of deep work.'),
        ChallengeStep(day: 4, title: 'Day 4: Flow State', description: 'Reach flow state during your session.'),
        ChallengeStep(day: 5, title: 'Day 5: Week 1 Reflection', description: 'Review your focus level for the past 5 days.'),
        ChallengeStep(day: 6, title: 'Day 6: Deep Dive', description: 'Tackle a complex task during your session.'),
        ChallengeStep(day: 7, title: 'Day 7: Persistence', description: 'Maintain focus despite distractions.'),
        ChallengeStep(day: 8, title: 'Day 8: Optimized Environment', description: 'Further refine your focus environment.'),
        ChallengeStep(day: 9, title: 'Day 9: Expanding Capacity', description: 'Focus on your most challenging task.'),
        ChallengeStep(day: 10, title: 'Day 10: Momentum', description: '10 days of deep work completed.'),
        ChallengeStep(day: 11, title: 'Day 11: Recovery', description: 'Ensure quality rest between sessions.'),
        ChallengeStep(day: 12, title: 'Day 12: Clarity', description: 'Observe increased mental clarity.'),
        ChallengeStep(day: 13, title: 'Day 13: Mastery', description: 'Focus becomes easier.'),
        ChallengeStep(day: 14, title: 'Day 14: Fortitude', description: 'Two weeks of focus achieved.'),
        ChallengeStep(day: 15, title: 'Day 15: Halfway Point', description: 'Reflect on your progress so far.'),
        ChallengeStep(day: 16, title: 'Day 16: New Baseline', description: 'Deep work is now a standard part of your day.'),
        ChallengeStep(day: 17, title: 'Day 17: Complexity', description: 'Use your focus for strategic planning.'),
        ChallengeStep(day: 18, title: 'Day 18: Unshakable', description: 'Ignore all external pings during work.'),
        ChallengeStep(day: 19, title: 'Day 19: Precision', description: 'Work with higher accuracy.'),
        ChallengeStep(day: 20, title: 'Day 20: Elite Performance', description: 'Experience the benefits of long-term focus.'),
        ChallengeStep(day: 21, title: 'Day 21: Three Weeks', description: 'Identity shift: You are a focused creator.'),
        ChallengeStep(day: 22, title: 'Day 22: Endurance', description: 'Session feels effortless.'),
        ChallengeStep(day: 23, title: 'Day 23: Synthesis', description: 'Connect ideas faster.'),
        ChallengeStep(day: 24, title: 'Day 24: Discipline', description: 'Focus even on lower energy days.'),
        ChallengeStep(day: 25, title: 'Day 25: The Home Stretch', description: 'Final week of the sprint begins.'),
        ChallengeStep(day: 26, title: 'Day 26: Peak Focus', description: 'Execute at your highest potential.'),
        ChallengeStep(day: 27, title: 'Day 27: Systematization', description: 'Your deep work system is robust.'),
        ChallengeStep(day: 28, title: 'Day 28: Results', description: 'Observe major project output.'),
        ChallengeStep(day: 29, title: 'Day 29: Final Preparation', description: 'Prepare for your final session.'),
        ChallengeStep(day: 30, title: 'Day 30: Completion', description: 'Sprint finished. You have mastered deep work.'),
      ],
    ),
    Challenge(
      id: 'template_digital_sunset_1',
      title: 'Digital Sunset',
      description: 'Disconnect to reconnect. No screens 60 minutes before bed for 30 days.',
      imageUrl: 'assets/images/challenges/challenge_digital_sunset_1777545298974.png',
      reward: '400 XP & Zen Spark',
      participants: 0,
      daysLeft: 30,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 400,
      archetypeId: 'stoic',
      category: ChallengeCategory.mindfulness,
      steps: [
        ChallengeStep(day: 1, title: 'Day 1: Threshold', description: 'Power down at 9 PM (or 1hr before bed).'),
        ChallengeStep(day: 2, title: 'Day 2: Analog Evening', description: 'Read a physical book instead of scrolling.'),
        ChallengeStep(day: 3, title: 'Day 3: Quiet Mind', description: 'Observe the silence before sleep.'),
        ChallengeStep(day: 4, title: 'Day 4: Ritual', description: 'Create a non-digital wind-down routine.'),
        ChallengeStep(day: 5, title: 'Day 5: Sleep Quality', description: 'Note any changes in your rest.'),
        ChallengeStep(day: 6, title: 'Day 6: Resistance', description: 'Acknowledge the urge to check notifications.'),
        ChallengeStep(day: 7, title: 'Day 7: One Week', description: 'Reflect on a week of analog evenings.'),
        ChallengeStep(day: 8, title: 'Day 8: Charging Station', description: 'Keep devices out of the bedroom.'),
        ChallengeStep(day: 9, title: 'Day 9: Evening Clarity', description: 'Process your day without digital input.'),
        ChallengeStep(day: 10, title: 'Day 10: Habit Formation', description: 'The routine feels more natural now.'),
        ChallengeStep(day: 11, title: 'Day 11: Reading Habit', description: 'Engage with longer-form thoughts.'),
        ChallengeStep(day: 12, title: 'Day 12: Circadian Sync', description: 'Feel your body clock adjusting.'),
        ChallengeStep(day: 13, title: 'Day 13: Evening Peace', description: 'Zero blue light exposure before bed.'),
        ChallengeStep(day: 14, title: 'Day 14: Two Weeks', description: 'Your brain is relearning how to idle.'),
        ChallengeStep(day: 15, title: 'Day 15: Midway Reflection', description: 'How has your focus changed?'),
        ChallengeStep(day: 16, title: 'Day 16: Consistent Calm', description: 'The sunset ritual is established.'),
        ChallengeStep(day: 17, title: 'Day 17: Deep Sleep', description: 'Experience more vivid dreams.'),
        ChallengeStep(day: 18, title: 'Day 18: No FomO', description: 'Realize that nothing urgent is missed.'),
        ChallengeStep(day: 19, title: 'Day 19: Evening Journaling', description: 'Write down your thoughts.'),
        ChallengeStep(day: 20, title: 'Day 20: Digital Discipline', description: 'You control the device, not vice versa.'),
        ChallengeStep(day: 21, title: 'Day 21: Three Weeks', description: 'The physiological benefits are clear.'),
        ChallengeStep(day: 22, title: 'Day 22: Nightly Freedom', description: 'Enjoy the freedom from the feed.'),
        ChallengeStep(day: 23, title: 'Day 23: Mental Recovery', description: 'Brain feels less "fried" in the morning.'),
        ChallengeStep(day: 24, title: 'Day 24: Introspection', description: 'Spend time in self-reflection.'),
        ChallengeStep(day: 25, title: 'Day 25: The Final Lap', description: 'Almost there.'),
        ChallengeStep(day: 26, title: 'Day 26: Master of Attention', description: 'Your attention span has increased.'),
        ChallengeStep(day: 27, title: 'Day 27: Optimized Sleep', description: 'Waking up feels refreshed.'),
        ChallengeStep(day: 28, title: 'Day 28: Sustainable Habits', description: 'Planning to keep this ritual forever.'),
        ChallengeStep(day: 29, title: 'Day 29: Final Preparation', description: 'Prepare for the 30-day milestone.'),
        ChallengeStep(day: 30, title: 'Day 30: Digital Sovereignty', description: 'Sunset challenge complete.'),
      ],
    ),
    Challenge(
      id: 'template_morning_routine_1',
      title: 'Morning Momentum',
      description: 'Own your morning. Wake up at the same time and complete your routine for 30 days.',
      imageUrl: 'assets/images/challenges/challenge_morning_routine_1777545315494.png',
      reward: '600 XP & Dawn Breaker',
      participants: 0,
      daysLeft: 30,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 600,
      archetypeId: 'athlete',
      category: ChallengeCategory.fitness,
      steps: [
        ChallengeStep(day: 1, title: 'Day 1: The Wake Up', description: 'Rise at your target time.'),
        ChallengeStep(day: 2, title: 'Day 2: Early Win', description: 'Complete your first task before 8 AM.'),
        ChallengeStep(day: 3, title: 'Day 3: Hydration', description: 'Start with 500ml of water immediately.'),
        ChallengeStep(day: 4, title: 'Day 4: Movement', description: 'Add 5 minutes of stretching.'),
        ChallengeStep(day: 5, title: 'Day 5: Daylight', description: 'Get direct sunlight in your eyes.'),
        ChallengeStep(day: 6, title: 'Day 6: Persistence', description: 'Push through the morning grogginess.'),
        ChallengeStep(day: 7, title: 'Day 7: First Week', description: 'Review your morning consistency.'),
        ChallengeStep(day: 8, title: 'Day 8: Prep the Night Before', description: 'Set out your clothes tonight.'),
        ChallengeStep(day: 9, title: 'Day 9: No Snooze', description: 'Get up on the first alarm.'),
        ChallengeStep(day: 10, title: 'Day 10: Momentum Building', description: 'Morning energy is noticeably higher.'),
        ChallengeStep(day: 11, title: 'Day 11: Cold Exposure', description: 'Try a 30-second cold blast in the shower.'),
        ChallengeStep(day: 12, title: 'Day 12: Mindful Start', description: 'No phone for the first 30 minutes.'),
        ChallengeStep(day: 13, title: 'Day 13: Focus Work', description: 'Use your peak energy for deep work.'),
        ChallengeStep(day: 14, title: 'Day 14: Two Weeks', description: 'The routine is becoming automated.'),
        ChallengeStep(day: 15, title: 'Day 15: Halfway Reflection', description: 'How has this changed your productivity?'),
        ChallengeStep(day: 16, title: 'Day 16: New Baseline', description: 'You are now an early riser.'),
        ChallengeStep(day: 17, title: 'Day 17: Optimized Breakfast', description: 'Fuel correctly for the day ahead.'),
        ChallengeStep(day: 18, title: 'Day 18: Unshakable Routine', description: 'Follow the steps even if you slept poorly.'),
        ChallengeStep(day: 19, title: 'Day 19: Morning Stillness', description: 'Enjoy the quiet before the world wakes.'),
        ChallengeStep(day: 20, title: 'Day 20: Elite Performance', description: 'Own the day before it begins.'),
        ChallengeStep(day: 21, title: 'Day 21: Three Weeks', description: 'Neural pathways are firmly set.'),
        ChallengeStep(day: 22, title: 'Day 22: Effortless Rise', description: 'Wake up without an alarm.'),
        ChallengeStep(day: 23, title: 'Day 23: Morning Synthesis', description: 'Plan your day with total clarity.'),
        ChallengeStep(day: 24, title: 'Day 24: Grit', description: 'Rise even on weekends.'),
        ChallengeStep(day: 25, title: 'Day 25: The Home Stretch', description: 'Final week begins.'),
        ChallengeStep(day: 26, title: 'Day 26: Peak Morning', description: 'Your most productive morning yet.'),
        ChallengeStep(day: 27, title: 'Day 27: Mastery', description: 'The routine is part of your identity.'),
        ChallengeStep(day: 28, title: 'Day 28: Consistency Check', description: 'Verify 28 days of success.'),
        ChallengeStep(day: 29, title: 'Day 29: Final Preparation', description: 'One more sunrise.'),
        ChallengeStep(day: 30, title: 'Day 30: Dawn Breaker', description: '30-day morning challenge complete.'),
      ],
    ),
    Challenge(
      id: 'template_hydration_1',
      title: 'Hydration Protocol',
      description: 'Optimize your energy. Drink your target water intake every day for a month.',
      imageUrl: 'assets/images/challenges/challenge_hydration_focus_1777545329563.png',
      reward: '300 XP & Aqua Core',
      participants: 0,
      daysLeft: 30,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 300,
      archetypeId: 'athlete',
      category: ChallengeCategory.nutrition,
      steps: [
        ChallengeStep(day: 1, title: 'Day 1: Baseline', description: 'Track every glass today.'),
        ChallengeStep(day: 2, title: 'Day 2: Morning Flush', description: 'Drink 500ml upon waking.'),
        ChallengeStep(day: 3, title: 'Day 3: Consistency', description: 'Hit your target for 3 days.'),
        ChallengeStep(day: 4, title: 'Day 4: Electrolytes', description: 'Add a pinch of salt to your morning water.'),
        ChallengeStep(day: 5, title: 'Day 5: Focus Boost', description: 'Note increased mental clarity.'),
        ChallengeStep(day: 6, title: 'Day 6: Evening Taper', description: 'Drink most water before 6 PM.'),
        ChallengeStep(day: 7, title: 'Day 7: Week 1', description: 'Successful first week of hydration.'),
        ChallengeStep(day: 8, title: 'Day 8: Re-baseline', description: 'Calculate target based on activity.'),
        ChallengeStep(day: 9, title: 'Day 9: Visual Cues', description: 'Keep a water bottle in sight.'),
        ChallengeStep(day: 10, title: 'Day 10: Skin Health', description: 'Observe physical changes.'),
        ChallengeStep(day: 11, title: 'Day 11: Habit stacking', description: 'Drink after every bathroom break.'),
        ChallengeStep(day: 12, title: 'Day 12: Energy Levels', description: 'Feel more energized mid-afternoon.'),
        ChallengeStep(day: 13, title: 'Day 13: Pure Intake', description: 'Avoid sugary drinks today.'),
        ChallengeStep(day: 14, title: 'Day 14: Fortnight', description: '14 days of optimal hydration.'),
        ChallengeStep(day: 15, title: 'Day 15: Halfway', description: 'Reflect on your energy shift.'),
        ChallengeStep(day: 16, title: 'Day 16: Persistence', description: 'Maintain target on busy days.'),
        ChallengeStep(day: 17, title: 'Day 17: Performance', description: 'Observe workout recovery.'),
        ChallengeStep(day: 18, title: 'Day 18: Detoxification', description: 'Feeling lighter and cleaner.'),
        ChallengeStep(day: 19, title: 'Day 19: Appetite Control', description: 'Less snacking between meals.'),
        ChallengeStep(day: 20, title: 'Day 20: Cellular Health', description: 'Optimizing at a micro level.'),
        ChallengeStep(day: 21, title: 'Day 21: Three Weeks', description: 'Hydration is now second nature.'),
        ChallengeStep(day: 22, title: 'Day 22: Resilience', description: 'Stay hydrated during travel.'),
        ChallengeStep(day: 23, title: 'Day 23: Mental Edge', description: 'Sharp focus maintained all day.'),
        ChallengeStep(day: 24, title: 'Day 24: Discipline', description: 'No days missed.'),
        ChallengeStep(day: 25, title: 'Day 25: The Stretch', description: 'Final week begins.'),
        ChallengeStep(day: 26, title: 'Day 26: Optimization', description: 'Adjusting for peak performance.'),
        ChallengeStep(day: 27, title: 'Day 27: Systematized', description: 'Your hydration system is flawless.'),
        ChallengeStep(day: 28, title: 'Day 28: Longevity', description: 'Investing in future health.'),
        ChallengeStep(day: 29, title: 'Day 29: Final Push', description: 'One day to go.'),
        ChallengeStep(day: 30, title: 'Day 30: Aqua Core', description: 'Hydration Protocol complete.'),
      ],
    ),
    Challenge(
      id: 'template_mindfulness_1',
      title: 'The Daily Pause',
      description: 'Practice presence. 10 minutes of mindfulness meditation every day.',
      imageUrl: 'assets/images/challenges/challenge_mindfulness_1777545342779.png',
      reward: '450 XP & Inner Peace',
      participants: 0,
      daysLeft: 30,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 450,
      archetypeId: 'stoic',
      category: ChallengeCategory.mindfulness,
      steps: [
        ChallengeStep(day: 1, title: 'Day 1: Just Sitting', description: 'Observe your breath for 10 minutes.'),
        ChallengeStep(day: 2, title: 'Day 2: Awareness', description: 'Notice when your mind wanders.'),
        ChallengeStep(day: 3, title: 'Day 3: Body Scan', description: 'Scan from toes to head.'),
        ChallengeStep(day: 4, title: 'Day 4: Sound', description: 'Meditate on the sounds around you.'),
        ChallengeStep(day: 5, title: 'Day 5: Breath Focus', description: 'Return to the anchor of breath.'),
        ChallengeStep(day: 6, title: 'Day 6: Thoughts as Clouds', description: 'Let thoughts pass without judgment.'),
        ChallengeStep(day: 7, title: 'Day 7: Week 1', description: 'Reflect on a week of stillness.'),
        ChallengeStep(day: 8, title: 'Day 8: Emotional Awareness', description: 'Observe feelings as they arise.'),
        ChallengeStep(day: 9, title: 'Day 9: Non-Striving', description: 'Just be, don\'t try to "do".'),
        ChallengeStep(day: 10, title: 'Day 10: Patience', description: 'Meditation feels less restless.'),
        ChallengeStep(day: 11, title: 'Day 11: Loving Kindness', description: 'Direct positive intent to others.'),
        ChallengeStep(day: 12, title: 'Day 12: Gratitude', description: 'Meditate on three things you\'re grateful for.'),
        ChallengeStep(day: 13, title: 'Day 13: Choice-less Awareness', description: 'Open focus to all experience.'),
        ChallengeStep(day: 14, title: 'Day 14: Fortnight', description: 'Two weeks of presence.'),
        ChallengeStep(day: 15, title: 'Day 15: Deepening', description: 'Stay with the breath longer.'),
        ChallengeStep(day: 16, title: 'Day 16: Resilience', description: 'Meditate even during stress.'),
        ChallengeStep(day: 17, title: 'Day 17: Walking Meditation', description: 'Apply presence to movement.'),
        ChallengeStep(day: 18, title: 'Day 18: Daily Integration', description: 'Take a mindful breath during work.'),
        ChallengeStep(day: 19, title: 'Day 19: Inner Silence', description: 'Experience moments of deep quiet.'),
        ChallengeStep(day: 20, title: 'Day 20: Equanimity', description: 'Maintain balance amidst chaos.'),
        ChallengeStep(day: 21, title: 'Day 21: Three Weeks', description: 'Identity: I am a mindful person.'),
        ChallengeStep(day: 22, title: 'Day 22: Effortless Focus', description: 'Breath focus feels natural.'),
        ChallengeStep(day: 23, title: 'Day 23: Boundless Mind', description: 'Experience the vastness of awareness.'),
        ChallengeStep(day: 24, title: 'Day 24: Forgiveness', description: 'Let go of old mental burdens.'),
        ChallengeStep(day: 25, title: 'Day 25: Home Stretch', description: 'Final week begins.'),
        ChallengeStep(day: 26, title: 'Day 26: Radiating Peace', description: 'Feel peace affecting your interactions.'),
        ChallengeStep(day: 27, title: 'Day 27: Wisdom', description: 'See through mental distortions.'),
        ChallengeStep(day: 28, title: 'Day 28: Total Presence', description: 'Live the meditation.'),
        ChallengeStep(day: 29, title: 'Day 29: Final Preparation', description: 'One more pause.'),
        ChallengeStep(day: 30, title: 'Day 30: Inner Peace', description: '30-day mindfulness challenge complete.'),
      ],
    ),
    Challenge(
      id: 'template_declutter_1',
      title: 'Space Architecture',
      description: 'Clear environment, clear mind. 15 minutes of decluttering daily.',
      imageUrl: 'assets/images/challenges/challenge_declutter_1777545373157.png',
      reward: '350 XP & Order Crest',
      participants: 0,
      daysLeft: 30,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 350,
      archetypeId: 'creator',
      category: ChallengeCategory.creative,
      steps: [
        ChallengeStep(day: 1, title: 'Day 1: Desk Zero', description: 'Clear your primary workspace.'),
        ChallengeStep(day: 2, title: 'Day 2: Digital Cleanup', description: 'Clear your desktop and downloads.'),
        ChallengeStep(day: 3, title: 'Day 3: Drawer #1', description: 'Organize one small storage space.'),
        ChallengeStep(day: 4, title: 'Day 4: Inbox Sweep', description: 'Archive old emails.'),
        ChallengeStep(day: 5, title: 'Day 5: Closet Corner', description: 'Tackle a small section of clothing.'),
        ChallengeStep(day: 6, title: 'Day 6: Paper Trail', description: 'Shred or file old documents.'),
        ChallengeStep(day: 7, title: 'Day 7: Week 1', description: 'Success: Environment is improving.'),
        ChallengeStep(day: 8, title: 'Day 8: Kitchen Surface', description: 'Clear the counters.'),
        ChallengeStep(day: 9, title: 'Day 9: Shelf Life', description: 'Organize one bookshelf.'),
        ChallengeStep(day: 10, title: 'Day 10: Tool Maintenance', description: 'Clean and organize your tools.'),
        ChallengeStep(day: 11, title: 'Day 11: Phone Purge', description: 'Delete unused apps.'),
        ChallengeStep(day: 12, title: 'Day 12: Bag/Wallet', description: 'Empty and reorganize.'),
        ChallengeStep(day: 13, title: 'Day 13: Bathroom Cabinet', description: 'Discard expired items.'),
        ChallengeStep(day: 14, title: 'Day 14: Fortnight', description: 'Two weeks of order.'),
        ChallengeStep(day: 15, title: 'Day 15: Halfway Point', description: 'Reflect on mental clarity.'),
        ChallengeStep(day: 16, title: 'Day 16: Entryway', description: 'Organize shoes and keys.'),
        ChallengeStep(day: 17, title: 'Day 17: Car/Vehicle', description: 'Quick interior cleanup.'),
        ChallengeStep(day: 18, title: 'Day 18: Notification Audit', description: 'Disable non-essential pings.'),
        ChallengeStep(day: 19, title: 'Day 19: Storage Bin', description: 'Sort through one box of memories.'),
        ChallengeStep(day: 20, title: 'Day 20: Visual Silence', description: 'Remove distracting decor.'),
        ChallengeStep(day: 21, title: 'Day 21: Three Weeks', description: 'Order is your new default.'),
        ChallengeStep(day: 22, title: 'Day 22: Laundry System', description: 'Streamline your flow.'),
        ChallengeStep(day: 23, title: 'Day 23: Bedside Table', description: 'Keep only essentials.'),
        ChallengeStep(day: 24, title: 'Day 24: Habit Check', description: 'Put everything back immediately.'),
        ChallengeStep(day: 25, title: 'Day 25: Home Stretch', description: 'Final week begins.'),
        ChallengeStep(day: 26, title: 'Day 26: High Traffic Area', description: 'Deep clean one frequent spot.'),
        ChallengeStep(day: 27, title: 'Day 27: Aesthetic Polish', description: 'Make a space beautiful.'),
        ChallengeStep(day: 28, title: 'Day 28: Sustainability', description: 'Prevent future clutter.'),
        ChallengeStep(day: 29, title: 'Day 29: Final Pass', description: 'Scan the house for outliers.'),
        ChallengeStep(day: 30, title: 'Day 30: Order Crest', description: 'Space Architecture complete.'),
      ],
    ),
    Challenge(
      id: 'template_movement_1',
      title: 'The Kinetic Minimum',
      description: 'Keep moving. Commit to at least 20 minutes of physical activity every day.',
      imageUrl: 'assets/images/challenges/challenge_movement_minimum_1777545387521.png',
      reward: '500 XP & Kinetic Soul',
      participants: 0,
      daysLeft: 30,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      xpReward: 500,
      archetypeId: 'athlete',
      category: ChallengeCategory.fitness,
      steps: [
        ChallengeStep(day: 1, title: 'Day 1: Start Moving', description: '20 minutes of brisk walking.'),
        ChallengeStep(day: 2, title: 'Day 2: Elevation', description: 'Add some stairs or hills.'),
        ChallengeStep(day: 3, title: 'Day 3: Bodyweight', description: 'Add 5 minutes of pushups/squats.'),
        ChallengeStep(day: 4, title: 'Day 4: Flexibility', description: 'Focus on full range of motion.'),
        ChallengeStep(day: 5, title: 'Day 5: Intensity', description: 'Push your heart rate slightly higher.'),
        ChallengeStep(day: 6, title: 'Day 6: Outdoor', description: 'Take your movement outside.'),
        ChallengeStep(day: 7, title: 'Day 7: Week 1', description: '7 days of momentum.'),
        ChallengeStep(day: 8, title: 'Day 8: New Route', description: 'Explore a new path.'),
        ChallengeStep(day: 9, title: 'Day 9: Strength Focus', description: 'Include resistance work.'),
        ChallengeStep(day: 10, title: 'Day 10: Double Down', description: 'Try 40 minutes today.'),
        ChallengeStep(day: 11, title: 'Day 11: Morning Burst', description: 'Move before breakfast.'),
        ChallengeStep(day: 12, title: 'Day 12: Recovery Move', description: 'Gentle yoga or swim.'),
        ChallengeStep(day: 13, title: 'Day 13: Core Work', description: 'Focus on stability.'),
        ChallengeStep(day: 14, title: 'Day 14: Fortnight', description: 'Two weeks of kinetic energy.'),
        ChallengeStep(day: 15, title: 'Day 15: Halfway', description: 'Reflect on physical vitality.'),
        ChallengeStep(day: 16, title: 'Day 16: Speed Work', description: 'Add short intervals.'),
        ChallengeStep(day: 17, title: 'Day 17: Functional Move', description: 'Lifting or carrying tasks.'),
        ChallengeStep(day: 18, title: 'Day 18: Group Move', description: 'Move with a friend or tribe.'),
        ChallengeStep(day: 19, title: 'Day 19: Persistence', description: 'Move even when busy.'),
        ChallengeStep(day: 20, title: 'Day 20: Peak Vitality', description: 'Energy levels are optimized.'),
        ChallengeStep(day: 21, title: 'Day 21: Three Weeks', description: 'Identity: I am an active person.'),
        ChallengeStep(day: 22, title: 'Day 22: Endurance', description: 'Target 30 minutes comfortably.'),
        ChallengeStep(day: 23, title: 'Day 23: Playful Movement', description: 'Try a new sport or activity.'),
        ChallengeStep(day: 24, title: 'Day 24: Mindful Motion', description: 'Focus on form and breath.'),
        ChallengeStep(day: 25, title: 'Day 25: Home Stretch', description: 'Final week begins.'),
        ChallengeStep(day: 26, title: 'Day 26: High Intensity', description: 'Your most vigorous session yet.'),
        ChallengeStep(day: 27, title: 'Day 27: Consistency', description: 'Zero days missed.'),
        ChallengeStep(day: 28, title: 'Day 28: Results', description: 'Observe increased fitness.'),
        ChallengeStep(day: 29, title: 'Day 29: Final Preparation', description: 'Prepare for the finish.'),
        ChallengeStep(day: 30, title: 'Day 30: Kinetic Soul', description: 'Kinetic Minimum complete.'),
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

  /// Returns all templates marked as featured.
  static List<Challenge> getFeatured() {
    return _templates.where((c) => c.status == ChallengeStatus.featured).toList();
  }
}
