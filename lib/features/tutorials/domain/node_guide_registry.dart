import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter/material.dart';

/// One explanatory bullet inside a node guide.
class NodeGuideItem {
  final IconData icon;
  final String title;
  final String body;

  const NodeGuideItem({
    required this.icon,
    required this.title,
    required this.body,
  });
}

/// Static configuration for a first-visit tutorial on one screen.
class NodeGuideDefinition {
  final String nodeId;
  final String title;
  final Color primaryColor;
  final IconData titleIcon;
  final List<NodeGuideItem> items;

  const NodeGuideDefinition({
    required this.nodeId,
    required this.title,
    required this.primaryColor,
    required this.titleIcon,
    required this.items,
  });
}

/// Pure registry of all node guides.
///
/// One entry per live, front-facing screen. Screens that no longer exist
/// must not be added here — when a screen dies (e.g. the blueprints page
/// in SP-F), its node entry dies with it.
class NodeGuideRegistry {
  static const List<NodeGuideDefinition> all = [
    NodeGuideDefinition(
      nodeId: 'timeline',
      title: 'Your Daily Timeline',
      primaryColor: EmergeColors.teal,
      titleIcon: Icons.view_timeline_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.touch_app_outlined,
          title: 'Log habits in one tap',
          body: 'Tap any habit to complete it. Tap again to undo.',
        ),
        NodeGuideItem(
          icon: Icons.ring_volume_outlined,
          title: 'Watch the ring fill',
          body: "The FAB ring shows today's completion. Green is on track.",
        ),
        NodeGuideItem(
          icon: Icons.auto_awesome_outlined,
          title: 'Meet your narrator',
          body: 'The avatar top-right is your coach. Tap it to ask anything.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'habit_create',
      title: 'Create a Habit',
      primaryColor: EmergeColors.violet,
      titleIcon: Icons.add_task,
      items: [
        NodeGuideItem(
          icon: Icons.schedule_outlined,
          title: 'Anchor it to a time',
          body: 'Habits stick when they live at the same moment every day.',
        ),
        NodeGuideItem(
          icon: Icons.bolt_outlined,
          title: 'Start tiny',
          body: 'A 2-minute version is easier to keep than a 2-hour one.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'streak_recovery',
      title: 'Streak Recovery',
      primaryColor: EmergeColors.warmGold,
      titleIcon: Icons.healing_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.replay_outlined,
          title: 'One miss is not a fall',
          body: 'Get back in today — momentum rebuilds fast.',
        ),
        NodeGuideItem(
          icon: Icons.stairs_outlined,
          title: 'Small step first',
          body: 'Pick the easiest habit to restart your streak.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'world_map',
      title: 'Your Living World',
      primaryColor: EmergeColors.teal,
      titleIcon: Icons.public_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.eco_outlined,
          title: 'Your world mirrors your habits',
          body: 'Complete habits to keep it thriving; misses decay it.',
        ),
        NodeGuideItem(
          icon: Icons.travel_explore_outlined,
          title: 'Explore as you grow',
          body: 'New regions unlock as your world heals.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'leveling',
      title: 'Leveling & XP',
      primaryColor: EmergeColors.violet,
      titleIcon: Icons.workspace_premium_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.stars_outlined,
          title: 'Earn XP from habits',
          body: 'Harder habits and longer streaks pay more.',
        ),
        NodeGuideItem(
          icon: Icons.control_point_outlined,
          title: 'Attributes shape your avatar',
          body: 'XP flows into strength, intellect, vitality and more.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'future_self',
      title: 'Future Self Studio',
      primaryColor: EmergeColors.violet,
      titleIcon: Icons.face_retouching_natural_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.edit_outlined,
          title: 'Set your motive',
          body: 'Write the why that keeps you going on hard days.',
        ),
        NodeGuideItem(
          icon: Icons.architecture_outlined,
          title: 'Shape your future self',
          body: 'Attribute XP and base avatars evolve as you grow.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'challenges',
      title: 'Challenges',
      primaryColor: EmergeColors.warmGold,
      titleIcon: Icons.emoji_events_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.flag_outlined,
          title: 'Join a public challenge',
          body: 'Compete on progress, not perfection.',
        ),
        NodeGuideItem(
          icon: Icons.leaderboard_outlined,
          title: 'Track the leaderboard',
          body: 'See where you stand and earn completion badges.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'all_tribes',
      title: 'All Tribes',
      primaryColor: EmergeColors.teal,
      titleIcon: Icons.groups_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.handshake_outlined,
          title: 'Find your people',
          body: 'Join an archetype tribe that matches how you grow.',
        ),
        NodeGuideItem(
          icon: Icons.swap_horiz_outlined,
          title: 'Switch freely',
          body: 'You can leave and join another tribe anytime.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'tribe_lobby',
      title: 'Your Tribe',
      primaryColor: EmergeColors.warmGold,
      titleIcon: Icons.diversity_3_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.people_alt_outlined,
          title: 'Members & partners',
          body: 'Your circle, your partners, and the tribe pulse live here.',
        ),
        NodeGuideItem(
          icon: Icons.auto_stories_outlined,
          title: 'Tribe blueprints',
          body: 'Curated blueprints for your tribe appear in this section.',
        ),
        NodeGuideItem(
          icon: Icons.swap_horiz_outlined,
          title: 'Switch tribes',
          body: 'Switch tribes anytime from the All Tribes screen.',
        ),
      ],
    ),
    NodeGuideDefinition(
      nodeId: 'coach',
      title: 'Your Coach',
      primaryColor: EmergeColors.teal,
      titleIcon: Icons.auto_awesome_outlined,
      items: [
        NodeGuideItem(
          icon: Icons.forum_outlined,
          title: 'Ask anything',
          body: 'Type a question and the narrator answers as your coach.',
        ),
        NodeGuideItem(
          icon: Icons.local_fire_department_outlined,
          title: '3 free asks a day',
          body: 'Premium unlocks unlimited personal, data-grounded advice.',
        ),
      ],
    ),
  ];

  static NodeGuideDefinition? forNode(String nodeId) {
    for (final d in all) {
      if (d.nodeId == nodeId) return d;
    }
    return null;
  }
}
