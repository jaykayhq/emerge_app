import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlueprintRepository {
  final FirebaseFirestore _firestore;

  BlueprintRepository(this._firestore);

  Stream<List<CreatorBlueprint>> getBlueprints() {
    return _firestore
        .collection('creator_blueprints')
        .orderBy('adoptionCount', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CreatorBlueprint.fromMap(d.data()))
            .toList());
  }

  Future<void> seedBlueprintsIfEmpty() async {
    final snap = await _firestore.collection('creator_blueprints').limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final blueprints = [
      // PRODUCTIVITY
      CreatorBlueprint(
        id: 'bp_productivity_1',
        creatorUserId: 'system',
        creatorName: 'The Architect',
        creatorArchetype: 'Athlete',
        blueprintName: 'The Focus Engine',
        description: 'A hybrid system combining the Pomodoro Technique with Eisenhower Matrix prioritization to eliminate busywork and maximize high-impact output.',
        habitTitles: ['Eisenhower Prioritization', '90-Minute Focus Block', 'Pomodoro Rest Cycle', 'Daily Output Review'],
        adoptionCount: 1250,
        category: 'Productivity',
        imageUrl: 'assets/images/blueprints/blueprint_productivity_1777545113334.png',
        createdAt: DateTime.now(),
      ),
      CreatorBlueprint(
        id: 'bp_productivity_2',
        creatorUserId: 'system',
        creatorName: 'Deep Work Master',
        creatorArchetype: 'Scholar',
        blueprintName: 'Digital Minimalism',
        description: 'Advice: Your attention is your most valuable asset. Protect it by ruthlessly eliminating digital clutter and context switching.',
        habitTitles: ['Phone-Free Morning', 'Tab Audit', 'Asynchronous Communication', 'Single-Task Focus'],
        adoptionCount: 950,
        category: 'Productivity',
        imageUrl: 'assets/images/blueprints/blueprint_productivity_1777545113334.png',
        createdAt: DateTime.now(),
      ),
      
      // SELF IMPROVEMENT
      CreatorBlueprint(
        id: 'bp_self_1',
        creatorUserId: 'system',
        creatorName: 'Identity Strategist',
        creatorArchetype: 'Stoic',
        blueprintName: 'The 1% Identity',
        description: 'Focus on becoming the type of person who achieves your goals. Shift from outcome-based habits to identity-based evolution with 1% daily improvements.',
        habitTitles: ['Identity Vote Action', '1% Improvement Task', 'Habit Stacking Anchor', 'Evening Reflection'],
        adoptionCount: 2800,
        category: 'Self Improvement',
        imageUrl: 'assets/images/blueprints/blueprint_self_improvement_1777545132966.png',
        createdAt: DateTime.now(),
      ),
      CreatorBlueprint(
        id: 'bp_self_2',
        creatorUserId: 'system',
        creatorName: 'Growth Coach',
        creatorArchetype: 'Creator',
        blueprintName: 'Growth Mindset Loop',
        description: 'Advice: Reframe failure as data. Every setback is a signal for where to optimize your system next.',
        habitTitles: ['Failure Deconstruction', 'Challenge Pursuit', 'Effort-Based Praise', 'Skill Deep-Dive'],
        adoptionCount: 1400,
        category: 'Self Improvement',
        imageUrl: 'assets/images/blueprints/blueprint_self_improvement_1777545132966.png',
        createdAt: DateTime.now(),
      ),

      // GOAL SETTING
      CreatorBlueprint(
        id: 'bp_goal_1',
        creatorUserId: 'system',
        creatorName: 'Strategic Planner',
        creatorArchetype: 'Scholar',
        blueprintName: 'Strategic Intent',
        description: 'Master the science of achievement using SMART goals combined with Mental Contrasting and Implementation Intentions (If-Then planning).',
        habitTitles: ['SMART Goal Audit', 'Mental Contrasting Session', 'If-Then Obstacle Plan', 'Weekly Milestone Check'],
        adoptionCount: 1950,
        category: 'Goal Setting',
        imageUrl: 'assets/images/blueprints/blueprint_goal_setting_1777545151153.png',
        createdAt: DateTime.now(),
      ),
      CreatorBlueprint(
        id: 'bp_goal_2',
        creatorUserId: 'system',
        creatorName: 'Visionary',
        creatorArchetype: 'Creator',
        blueprintName: 'Reverse Engineering Success',
        description: 'Advice: Start at the finish line. Break your 10-year goal down into 1-year, 1-month, and 1-day actionable steps.',
        habitTitles: ['Backwards Planning', 'Daily Tiny Step', 'Vision Board Review', 'Milestone Celebration'],
        adoptionCount: 1100,
        category: 'Goal Setting',
        imageUrl: 'assets/images/blueprints/blueprint_goal_setting_1777545151153.png',
        createdAt: DateTime.now(),
      ),

      // BEHAVIORAL PSYCHOLOGY
      CreatorBlueprint(
        id: 'bp_psych_1',
        creatorUserId: 'system',
        creatorName: 'Behavioral Scientist',
        creatorArchetype: 'Scholar',
        blueprintName: 'The Behavior Design',
        description: 'Apply the B=MAT model to decode your habits. Optimize your triggers and ability to make desired behaviors inevitable and undesired ones impossible.',
        habitTitles: ['Trigger Mapping', 'Friction Reduction', 'Small Success Celebration', 'Zeigarnik Task Start'],
        adoptionCount: 3100,
        category: 'Behavioral Psychology',
        imageUrl: 'assets/images/blueprints/blueprint_behavioral_psychology_1777545169964.png',
        createdAt: DateTime.now(),
      ),
      CreatorBlueprint(
        id: 'bp_psych_2',
        creatorUserId: 'system',
        creatorName: 'Habit Lab',
        creatorArchetype: 'Stoic',
        blueprintName: 'Neural Path Sculpting',
        description: 'Advice: Habits aren\'t just behaviors; they are physical pathways in your brain. Repetition is the only way to thicken those wires.',
        habitTitles: ['Habit Stacking', 'Environmental Cueing', 'Immediate Reward', 'Behavior Tracking'],
        adoptionCount: 2200,
        category: 'Behavioral Psychology',
        imageUrl: 'assets/images/blueprints/blueprint_behavioral_psychology_1777545169964.png',
        createdAt: DateTime.now(),
      ),

      // PROCRASTINATION
      CreatorBlueprint(
        id: 'bp_proc_1',
        creatorUserId: 'system',
        creatorName: 'Resistance Breaker',
        creatorArchetype: 'Athlete',
        blueprintName: 'Resistance Breaker',
        description: 'Shatter procrastination loops using the 5-Minute Rule and emotional labeling. Transform anxiety into action through temptation bundling.',
        habitTitles: ['5-Minute Task Start', 'Emotional State Labeling', 'Temptation Bundle Setup', 'Instant Launch Countdown'],
        adoptionCount: 4500,
        category: 'Procrastination',
        imageUrl: 'assets/images/blueprints/blueprint_procrastination_1777545184036.png',
        createdAt: DateTime.now(),
      ),
      CreatorBlueprint(
        id: 'bp_proc_2',
        creatorUserId: 'system',
        creatorName: 'Action Instigator',
        creatorArchetype: 'Athlete',
        blueprintName: 'The 2-Minute Sprint',
        description: 'Advice: Procrastination is a wall you can jump over with a 2-minute run. Once you start, the momentum takes over.',
        habitTitles: ['2-Minute Task Kickoff', 'Decision Deletion', 'External Accountability', 'Public Shipping'],
        adoptionCount: 3800,
        category: 'Procrastination',
        imageUrl: 'assets/images/blueprints/blueprint_procrastination_1777545184036.png',
        createdAt: DateTime.now(),
      ),

      // WILLPOWER
      CreatorBlueprint(
        id: 'bp_will_1',
        creatorUserId: 'system',
        creatorName: 'Environment Architect',
        creatorArchetype: 'Stoic',
        blueprintName: 'Environment Architecture',
        description: 'Stop relying on finite willpower. Design your surroundings to automate discipline and minimize decision fatigue through spatial anchoring.',
        habitTitles: ['Environmental Audit', 'Decision Automation', 'Visual Cue Placement', 'Night Before Prep'],
        adoptionCount: 1800,
        category: 'Willpower',
        imageUrl: 'assets/images/blueprints/blueprint_willpower_1777545209964.png',
        createdAt: DateTime.now(),
      ),
      CreatorBlueprint(
        id: 'bp_will_2',
        creatorUserId: 'system',
        creatorName: 'Stoic Guide',
        creatorArchetype: 'Stoic',
        blueprintName: 'Voluntary Discomfort',
        description: 'Advice: Willpower is built through struggle. By choosing small discomforts, you harden your mind against larger challenges.',
        habitTitles: ['Cold Shower Burst', 'Delayed Gratification', 'Focus Stamina', 'Mental Resilience Exercise'],
        adoptionCount: 1600,
        category: 'Willpower',
        imageUrl: 'assets/images/blueprints/blueprint_willpower_1777545209964.png',
        createdAt: DateTime.now(),
      ),

      // MOTIVATION
      CreatorBlueprint(
        id: 'bp_mot_1',
        creatorUserId: 'system',
        creatorName: 'Purpose Sync',
        creatorArchetype: 'Creator',
        blueprintName: 'Purpose Synchronization',
        description: 'Align your daily actions with intrinsic values. Build sustainable motivation through social accountability loops and progress visualization.',
        habitTitles: ['Value-Action Audit', 'Public Commitment', 'Progress Visual Update', 'Purpose Re-centering'],
        adoptionCount: 950,
        category: 'Motivation',
        imageUrl: 'assets/images/blueprints/blueprint_motivation_1777545226464.png',
        createdAt: DateTime.now(),
      ),
      CreatorBlueprint(
        id: 'bp_mot_2',
        creatorUserId: 'system',
        creatorName: 'Dopamine Designer',
        creatorArchetype: 'Creator',
        blueprintName: 'The Small Win Spiral',
        description: 'Advice: Motivation is the result of progress, not the cause. Engineer a series of tiny wins to trigger a dopamine-driven spiral of action.',
        habitTitles: ['Task Chunking', 'Micro-Win Celebration', 'Streak Tracking', 'Visual Rewards'],
        adoptionCount: 1200,
        category: 'Motivation',
        imageUrl: 'assets/images/blueprints/blueprint_motivation_1777545226464.png',
        createdAt: DateTime.now(),
      ),
    ];

    final batch = _firestore.batch();
    for (final bp in blueprints) {
      final docRef = _firestore.collection('creator_blueprints').doc(bp.id);
      batch.set(docRef, bp.toMap());
    }
    await batch.commit();
  }
}

final blueprintRepositoryProvider = Provider<BlueprintRepository>((ref) {
  return BlueprintRepository(FirebaseFirestore.instance);
});
