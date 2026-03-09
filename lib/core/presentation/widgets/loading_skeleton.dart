import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A configurable loading skeleton widget with shimmer effect.
///
/// Unlike [EmergeLoadingSkeleton] which is list-focused, this widget
/// can create skeleton placeholders for any widget shape/size.
///
/// Example:
/// ```dart
/// LoadingSkeleton(
///   width: 200,
///   height: 100,
///   borderRadius: 12,
/// )
/// ```
///
/// For a box that matches another widget's size:
/// ```dart
/// LoadingSkeleton.fromWidget(
///   child: MyComplexWidget(),
/// )
/// ```
class LoadingSkeleton extends StatefulWidget {
  /// Width of the skeleton box.
  final double? width;

  /// Height of the skeleton box.
  final double? height;

  /// Border radius for rounded corners.
  final double borderRadius;

  /// Optional child to base skeleton dimensions on.
  final Widget? child;

  /// Shimmer effect direction.
  final Axis shimmerDirection;

  /// Shimmer animation duration.
  final Duration shimmerDuration;

  /// Base color of the skeleton (when not shimmering).
  final Color? baseColor;

  /// Highlight color of the shimmer effect.
  final Color? highlightColor;

  const LoadingSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.child,
    this.shimmerDirection = Axis.horizontal,
    this.shimmerDuration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
  }) : assert(
          width != null || height != null || child != null,
          'Must specify width, height, or child',
        );

  /// Creates a skeleton that matches the size of the given child widget.
  factory LoadingSkeleton.fromWidget({
    Key? key,
    required Widget child,
    double borderRadius = 8,
    Axis shimmerDirection = Axis.horizontal,
    Duration shimmerDuration = const Duration(milliseconds: 1500),
    Color? baseColor,
    Color? highlightColor,
  }) {
    return LoadingSkeleton(
      key: key,
      borderRadius: borderRadius,
      shimmerDirection: shimmerDirection,
      shimmerDuration: shimmerDuration,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: widget.shimmerDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseColor =
        widget.baseColor ?? theme.colorScheme.surfaceContainerHighest;
    final highlightColor =
        widget.highlightColor ?? theme.colorScheme.surface;

    if (widget.child != null) {
      return _LayoutBuilderWrapper(
        child: widget.child!,
        builder: (constraints) => _ShimmerContainer(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          borderRadius: widget.borderRadius,
          baseColor: baseColor,
          highlightColor: highlightColor,
          shimmerController: _shimmerController,
          shimmerDirection: widget.shimmerDirection,
        ),
      );
    }

    return _ShimmerContainer(
      width: widget.width,
      height: widget.height,
      borderRadius: widget.borderRadius,
      baseColor: baseColor,
      highlightColor: highlightColor,
      shimmerController: _shimmerController,
      shimmerDirection: widget.shimmerDirection,
    );
  }
}

class _ShimmerContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final AnimationController shimmerController;
  final Axis shimmerDirection;

  const _ShimmerContainer({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
    required this.shimmerController,
    required this.shimmerDirection,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        final offset = (shimmerController.value - 0.5) * 2;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: shimmerDirection == Axis.horizontal
                  ? Alignment(offset - 0.3, 0)
                  : Alignment(0, offset - 0.3),
              end: shimmerDirection == Axis.horizontal
                  ? Alignment(offset + 0.3, 0)
                  : Alignment(0, offset + 0.3),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Wrapper to measure child widget size.
class _LayoutBuilderWrapper extends StatelessWidget {
  final Widget child;
  final Widget Function(BoxConstraints) builder;

  const _LayoutBuilderWrapper({
    required this.child,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure child by rendering it off-screen
        return MeasureSize(
          onChange: (size) {
            // Size captured by MeasureSize
          },
          child: Offstage(
            child: child,
          ),
        );
      },
    );
  }
}

/// A widget that measures its child's size.
class MeasureSize extends StatefulWidget {
  final Widget child;
  final void Function(Size) onChange;

  const MeasureSize({
    super.key,
    required this.child,
    required this.onChange,
  });

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  final _key = GlobalKey();
  Size? _oldSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  void _notifySize() {
    final context = _key.currentContext;
    if (context == null) return;

    final size = context.size;
    if (size != null && _oldSize != size) {
      _oldSize = size;
      widget.onChange(size);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
    return Container(
      key: _key,
      child: widget.child,
    );
  }
}

/// Pre-defined skeleton shapes for common UI patterns.
class SkeletonShapes {
  /// Circular avatar skeleton (e.g., user profile pictures).
  static Widget avatar({
    double size = 48,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return LoadingSkeleton(
      width: size,
      height: size,
      borderRadius: size / 2,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// Rectangular card skeleton.
  static Widget card({
    double? width,
    double height = 120,
    double borderRadius = 16,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return LoadingSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// Text line skeleton.
  static Widget textLine({
    double? width,
    double height = 14,
    double borderRadius = 4,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return LoadingSkeleton(
      width: width ?? double.infinity,
      height: height,
      borderRadius: borderRadius,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// Button skeleton.
  static Widget button({
    double? width,
    double height = 40,
    double borderRadius = 20,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return LoadingSkeleton(
      width: width ?? 120,
      height: height,
      borderRadius: borderRadius,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// List item skeleton with optional leading avatar.
  static Widget listItem({
    bool showAvatar = true,
    double height = 72,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Row(
      children: [
        if (showAvatar) ...[
          avatar(size: 48, baseColor: baseColor, highlightColor: highlightColor),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              textLine(
                width: double.infinity,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
              const SizedBox(height: 8),
              textLine(
                width: 160,
                height: 10,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A convenient builder for creating complex skeleton layouts.
///
/// Example:
/// ```dart
/// LoadingSkeletonBuilder(
///   itemCount: 5,
///   builder: (context, index) => SkeletonShapes.listItem(),
/// )
/// ```
class LoadingSkeletonBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) builder;
  final bool useAnimatedOpacity;

  const LoadingSkeletonBuilder({
    super.key,
    required this.itemCount,
    required this.builder,
    this.useAnimatedOpacity = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: useAnimatedOpacity
              ? builder(context, index)
                  .animate(onPlay: (controller) => controller.repeat())
                  .fadeIn(duration: 600.ms)
                  .then()
                  .fadeOut(duration: 600.ms)
              : builder(context, index),
        ),
      ),
    );
  }
}
