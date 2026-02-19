import 'package:flutter/material.dart';

/// A reusable shimmer-effect loading skeleton.
///
/// Replaces raw `CircularProgressIndicator` throughout the app with
/// content-aware skeleton loaders that match the layout being loaded.
class EmergeLoadingSkeleton extends StatefulWidget {
  /// Number of skeleton rows to display.
  final int itemCount;

  /// Whether to show a circular avatar placeholder.
  final bool showAvatar;

  /// Height of each skeleton row.
  final double itemHeight;

  const EmergeLoadingSkeleton({
    super.key,
    this.itemCount = 3,
    this.showAvatar = false,
    this.itemHeight = 72,
  });

  @override
  State<EmergeLoadingSkeleton> createState() => _EmergeLoadingSkeletonState();
}

class _EmergeLoadingSkeletonState extends State<EmergeLoadingSkeleton>
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
    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: List.generate(widget.itemCount, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SkeletonRow(
                  height: widget.itemHeight,
                  showAvatar: widget.showAvatar,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  shimmerOffset: _animation.value,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  final double height;
  final bool showAvatar;
  final Color baseColor;
  final Color highlightColor;
  final double shimmerOffset;

  const _SkeletonRow({
    required this.height,
    required this.showAvatar,
    required this.baseColor,
    required this.highlightColor,
    required this.shimmerOffset,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          if (showAvatar) ...[
            _ShimmerBox(
              width: 48,
              height: 48,
              borderRadius: 24,
              baseColor: baseColor,
              highlightColor: highlightColor,
              shimmerOffset: shimmerOffset,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ShimmerBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  shimmerOffset: shimmerOffset,
                ),
                const SizedBox(height: 8),
                _ShimmerBox(
                  width: 160,
                  height: 10,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  shimmerOffset: shimmerOffset,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final double shimmerOffset;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
    required this.shimmerOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(shimmerOffset - 1, 0),
          end: Alignment(shimmerOffset + 1, 0),
          colors: [baseColor, highlightColor, baseColor],
        ),
      ),
    );
  }
}
