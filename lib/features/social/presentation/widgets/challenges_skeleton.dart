import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter/material.dart';

/// Unified skeleton loader for ChallengesScreen
/// Replaces per-section loading indicators with a single cohesive loading state
class ChallengesSkeletonLoader extends StatelessWidget {
  const ChallengesSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 80),
          // Weekly Spotlight skeleton
          _ShimmerCard(height: 220, width: double.infinity),
          const SizedBox(height: 20),
          // Daily Quest skeleton
          _ShimmerCard(height: 160, width: double.infinity),
          const SizedBox(height: 20),
          // Solo quests skeletons
          _ShimmerCard(height: 140, width: double.infinity),
          const SizedBox(height: 16),
          _ShimmerCard(height: 140, width: double.infinity),
          const SizedBox(height: 20),
          // Archetype challenges skeletons
          _ShimmerCard(height: 100, width: double.infinity),
          const SizedBox(height: 12),
          _ShimmerCard(height: 100, width: double.infinity),
          const SizedBox(height: 12),
          _ShimmerCard(height: 100, width: double.infinity),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  final double height;
  final double width;

  const _ShimmerCard({required this.height, this.width = double.infinity});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width.isFinite ? widget.width : double.infinity,
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(_animation.value, 0),
                  end: Alignment(_animation.value + 0.5, 0),
                  colors: [
                    EmergeColors.glassWhite.withValues(alpha: 0.5),
                    EmergeColors.glassWhite.withValues(alpha: 0.8),
                    EmergeColors.glassWhite.withValues(alpha: 0.5),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
