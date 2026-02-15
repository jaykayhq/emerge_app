import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:flutter/material.dart';

/// Tooltip that appears when tapping on the silhouette
/// Shows evolution progress, phase info, and unlocked artifacts
class ProfilePreviewTooltip extends StatefulWidget {
  final EvolutionPhase currentPhase;
  final double progressToNext;
  final int level;
  final int streak;
  final List<String> unlockedArtifacts;
  final Color primaryColor;

  const ProfilePreviewTooltip({
    super.key,
    required this.currentPhase,
    required this.progressToNext,
    required this.level,
    required this.streak,
    required this.unlockedArtifacts,
    required this.primaryColor,
  });

  /// Shows tooltip as a modal bottom sheet
  static void show(
    BuildContext context, {
    required EvolutionPhase currentPhase,
    required double progressToNext,
    required int level,
    required int streak,
    required List<String> unlockedArtifacts,
    required Color primaryColor,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ProfilePreviewTooltip(
        currentPhase: currentPhase,
        progressToNext: progressToNext,
        level: level,
        streak: streak,
        unlockedArtifacts: unlockedArtifacts,
        primaryColor: primaryColor,
      ),
    );
  }

  @override
  State<ProfilePreviewTooltip> createState() => _ProfilePreviewTooltipState();
}

class _ProfilePreviewTooltipState extends State<ProfilePreviewTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _progressAnimation = Tween<double>(begin: 0, end: widget.progressToNext)
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  String get _phaseDisplayName {
    switch (widget.currentPhase) {
      case EvolutionPhase.phantom:
        return 'Phantom';
      case EvolutionPhase.construct:
        return 'Construct';
      case EvolutionPhase.incarnate:
        return 'Incarnate';
      case EvolutionPhase.radiant:
        return 'Radiant';
      case EvolutionPhase.ascended:
        return 'Ascended';
    }
  }

  EvolutionPhase? get _nextPhase {
    final index = widget.currentPhase.index;
    if (index >= EvolutionPhase.values.length - 1) return null;
    return EvolutionPhase.values[index + 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [EmergeColors.backgroundLight, EmergeColors.surface],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header with phase info
                _buildPhaseHeader(),

                const SizedBox(height: 20),

                // Progress to next phase
                if (_nextPhase != null) _buildProgressSection(),

                const SizedBox(height: 20),

                // Stats row
                _buildStatsRow(),

                // Unlocked artifacts
                if (widget.unlockedArtifacts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildArtifactsSection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.primaryColor.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(
            _getPhaseIcon(widget.currentPhase),
            size: 32,
            color: widget.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evolution Phase',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _phaseDisplayName.toUpperCase(),
                style: TextStyle(
                  color: widget.primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        // Phase tier indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${widget.currentPhase.index + 1}/5',
            style: TextStyle(
              color: widget.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    final nextPhase = _nextPhase!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress to ${nextPhase.name.toUpperCase()}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, _) => Text(
                '${(_progressAnimation.value * 100).toInt()}%',
                style: TextStyle(
                  color: widget.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, _) => Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.primaryColor, EmergeColors.teal],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.trending_up,
            label: 'Level',
            value: widget.level.toString(),
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '${widget.streak} days',
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.star,
            label: 'Artifacts',
            value: widget.unlockedArtifacts.length.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: widget.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildArtifactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UNLOCKED ARTIFACTS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.unlockedArtifacts.map((artifact) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                artifact,
                style: TextStyle(color: widget.primaryColor, fontSize: 12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getPhaseIcon(EvolutionPhase phase) {
    switch (phase) {
      case EvolutionPhase.phantom:
        return Icons.blur_on;
      case EvolutionPhase.construct:
        return Icons.architecture;
      case EvolutionPhase.incarnate:
        return Icons.person;
      case EvolutionPhase.radiant:
        return Icons.auto_awesome;
      case EvolutionPhase.ascended:
        return Icons.local_fire_department;
    }
  }
}
