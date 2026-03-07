import 'dart:io';
import 'dart:ui';

import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_map_config.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_health_bar.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen immersive level view with AI-generated background
/// Shows habits, stats, health bar, and mission controls
class LevelImmersiveScreen extends ConsumerWidget {
  final WorldNode node;
  final ArchetypeMapConfig config;

  const LevelImmersiveScreen({
    super.key,
    required this.node,
    required this.config,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: statsAsync.when(
        data: (profile) => _buildContent(context, ref, profile),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00FFCC)),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final healthPercent = _calculateWorldHealth(profile);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: AI-generated background image
        _buildBackground(screenSize),

        // Layer 2: Dark gradient overlay for readability
        _buildGradientOverlay(),

        // Layer 3: Content
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Top Bar: Back + Stage/Level badges
                _buildTopBar(context),

                const SizedBox(height: 24),

                // Hero Section: Emoji + Name + Badges
                _buildHeroSection(context),

                const SizedBox(height: 20),

                // Directive Card (floating glassmorphism)
                if (node.directive.isNotEmpty) _buildDirectiveCard(context),

                const SizedBox(height: 20),

                // Attribute XP chips (spread)
                _buildAttributeChips(context, profile),

                const SizedBox(height: 20),

                // World Health Bar
                _buildHealthSection(context, healthPercent),

                const SizedBox(height: 24),

                // Habit Cards (staggered)
                _buildHabitSection(context, profile),

                const SizedBox(height: 24),

                // Progress bar
                _buildProgressSection(context),

                const SizedBox(height: 16),

                // Action Button
                _buildActionButton(context, ref, profile),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackground(Size screenSize) {
    // Try to load AI-generated background
    if (node.backgroundImagePath != null &&
        node.backgroundImagePath!.isNotEmpty) {
      final file = File(node.backgroundImagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: screenSize.width,
          height: screenSize.height,
        );
      }
    }

    // Check for asset-bundled background
    final assetPath =
        'assets/images/levels/${node.archetype ?? 'default'}/${node.id}.png';

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      width: screenSize.width,
      height: screenSize.height,
      errorBuilder: (_, _, _) => _buildFallbackBackground(screenSize),
    );
  }

  Widget _buildFallbackBackground(Size screenSize) {
    // Gradient fallback when no background image
    return Container(
      width: screenSize.width,
      height: screenSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            config.primaryColor.withValues(alpha: 0.3),
            const Color(0xFF0A0A1A),
            const Color(0xFF0A0A1A),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.6, 1.0],
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.85),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        // Stage label
        _glassBadge(
          'STAGE ${node.stage}/5',
          Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        // Level badge
        _glassBadge(
          'LVL ${node.requiredLevel}',
          config.primaryColor,
          glow: true,
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large emoji on glass circle
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: config.primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: config.primaryColor.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: config.primaryColor.withValues(alpha: 0.2),
                blurRadius: 16,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(node.emoji, style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(width: 16),
        // Name and badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildInlineBadge(
                    node.type.name.toUpperCase(),
                    _getTypeColor(),
                  ),
                  const SizedBox(width: 6),
                  _buildInlineBadge(
                    node.tier.name.toUpperCase(),
                    _getTierColor(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectiveCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: config.primaryColor, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📜 ', style: TextStyle(fontSize: 14)),
                  Text(
                    'DIRECTIVE',
                    style: TextStyle(
                      color: config.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                node.directive,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeChips(BuildContext context, UserProfile profile) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: node.targetedAttributes.map((attr) {
        final xp = node.xpBoosts[attr] ?? 10;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _getAttributeColor(attr).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getAttributeColor(attr).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getAttributeIcon(attr),
                    color: _getAttributeColor(attr),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${attr.name[0].toUpperCase()}${attr.name.substring(1)} +$xp XP',
                    style: TextStyle(
                      color: _getAttributeColor(attr),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHealthSection(BuildContext context, double healthPercent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: WorldHealthBar(
            healthPercent: healthPercent,
            accentColor: config.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildHabitSection(BuildContext context, UserProfile profile) {
    // Get habits related to this node's attributes
    final attributeNames = node.targetedAttributes.map((a) => a.name).toList();

    // Example habits based on attributes (in real app, these come from user's habit list)
    final mockHabits = _getRelevantHabits(attributeNames);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY\'S MISSIONS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ...mockHabits.asMap().entries.map((entry) {
          final idx = entry.key;
          final habit = entry.value;
          final isCompleted = idx == 1; // Demo: second habit done

          return Padding(
            padding: EdgeInsets.only(
              left: idx.isOdd ? 24.0 : 0.0, // Stagger
              bottom: 8,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        habit['emoji'] as String,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          habit['name'] as String,
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: isCompleted ? 0.6 : 0.9,
                            ),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.withValues(alpha: 0.8),
                          size: 20,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: config.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${habit['xp']} XP',
                            style: TextStyle(
                              color: config.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NODE PROGRESS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${node.progress}%',
              style: TextStyle(
                color: config.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: node.progress / 100,
            backgroundColor: config.primaryColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(config.primaryColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final isLocked = node.state == NodeState.locked;
    final isCompleted =
        node.state == NodeState.completed || node.state == NodeState.mastered;
    final isInProgress = node.state == NodeState.inProgress;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLocked || isCompleted
            ? null
            : () => _handleAction(context, ref),
        icon: Icon(
          isLocked
              ? Icons.lock_outline
              : isCompleted
              ? Icons.emoji_events
              : isInProgress
              ? Icons.task_alt
              : Icons.play_arrow,
          size: 20,
        ),
        label: Text(
          isLocked
              ? 'LOCKED (REACH LEVEL ${node.requiredLevel})'
              : isCompleted
              ? '🏆 COMPLETED'
              : isInProgress
              ? '⚔️ COMPLETE MISSION'
              : '⚔️ BEGIN MISSION',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted
              ? config.primaryColor.withValues(alpha: 0.5)
              : config.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isCompleted
              ? config.primaryColor.withValues(alpha: 0.4)
              : Colors.grey.shade800,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref) async {
    try {
      if (node.state == NodeState.available) {
        await ref.read(userStatsControllerProvider).startMission(node.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mission started: ${node.name}'),
              backgroundColor: config.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (node.state == NodeState.inProgress) {
        final xpBoosts = node.xpBoosts.map((k, v) => MapEntry(k.name, v));
        await ref
            .read(userStatsControllerProvider)
            .completeMission(node.id, xpBoosts, node.requiredLevel);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mission complete: ${node.name}! 🎉'),
              backgroundColor: config.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────

  Widget _glassBadge(String text, Color color, {bool glow = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  double _calculateWorldHealth(UserProfile profile) {
    // Use the existing worldHealth (1.0 - entropy)
    return profile.worldState.worldHealth.clamp(0.0, 1.0);
  }

  List<Map<String, dynamic>> _getRelevantHabits(List<String> attributes) {
    // Map attributes to sample habits
    final habitMap = <String, List<Map<String, dynamic>>>{
      'vitality': [
        {'emoji': '💧', 'name': 'Drink Water', 'xp': 3},
        {'emoji': '🥗', 'name': 'Healthy Meal', 'xp': 5},
      ],
      'strength': [
        {'emoji': '💪', 'name': 'Push-ups', 'xp': 8},
        {'emoji': '🏋️', 'name': 'Workout', 'xp': 10},
      ],
      'focus': [
        {'emoji': '🧘', 'name': 'Meditation', 'xp': 5},
        {'emoji': '📵', 'name': 'No Phone', 'xp': 4},
      ],
      'intellect': [
        {'emoji': '📚', 'name': 'Read 10 Pages', 'xp': 6},
        {'emoji': '✍️', 'name': 'Journal', 'xp': 5},
      ],
      'creativity': [
        {'emoji': '🎨', 'name': 'Create Something', 'xp': 8},
        {'emoji': '📝', 'name': 'Write', 'xp': 6},
      ],
      'spirit': [
        {'emoji': '🙏', 'name': 'Prayer', 'xp': 5},
        {'emoji': '🌅', 'name': 'Sunrise Watch', 'xp': 4},
      ],
    };

    final habits = <Map<String, dynamic>>[];
    for (final attr in attributes) {
      final attrHabits = habitMap[attr];
      if (attrHabits != null) {
        habits.addAll(attrHabits);
      }
    }
    return habits.take(4).toList();
  }

  Color _getTypeColor() {
    switch (node.type) {
      case NodeType.waypoint:
        return EmergeColors.teal;
      case NodeType.milestone:
        return Colors.amber;
      case NodeType.challenge:
        return EmergeColors.coral;
      case NodeType.resource:
        return Colors.green;
      case NodeType.landmark:
        return EmergeColors.violet;
    }
  }

  Color _getTierColor() {
    switch (node.tier) {
      case NodeTier.dormant:
        return Colors.grey;
      case NodeTier.awakened:
        return Colors.blue;
      case NodeTier.thriving:
        return Colors.green;
      case NodeTier.radiant:
        return Colors.purple;
      case NodeTier.legendary:
        return Colors.amber;
    }
  }

  Color _getAttributeColor(HabitAttribute attr) {
    switch (attr) {
      case HabitAttribute.vitality:
        return const Color(0xFF00E5FF);
      case HabitAttribute.intellect:
        return const Color(0xFFE040FB);
      case HabitAttribute.creativity:
        return const Color(0xFF76FF03);
      case HabitAttribute.focus:
        return const Color(0xFFFFAB00);
      case HabitAttribute.strength:
        return const Color(0xFFFF5252);
      case HabitAttribute.spirit:
        return const Color(0xFFFFD700);
    }
  }

  IconData _getAttributeIcon(HabitAttribute attr) {
    switch (attr) {
      case HabitAttribute.vitality:
        return Icons.favorite;
      case HabitAttribute.intellect:
        return Icons.menu_book;
      case HabitAttribute.creativity:
        return Icons.palette;
      case HabitAttribute.focus:
        return Icons.center_focus_strong;
      case HabitAttribute.strength:
        return Icons.fitness_center;
      case HabitAttribute.spirit:
        return Icons.auto_awesome;
    }
  }
}
