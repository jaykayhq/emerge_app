import 'dart:math';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/circular_skill_node.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/skill_tree_path_painter.dart';
import 'package:flutter/material.dart';

/// The main scrollable canvas for the Circular Skill Tree
/// Replaces the HexMapCanvas
class CircularSkillTreeCanvas extends StatefulWidget {
  final List<WorldNode> nodes;
  final Function(WorldNode) onNodeTap;
  final Color primaryColor;

  const CircularSkillTreeCanvas({
    super.key,
    required this.nodes,
    required this.onNodeTap,
    required this.primaryColor,
  });

  @override
  State<CircularSkillTreeCanvas> createState() =>
      _CircularSkillTreeCanvasState();
}

class _CircularSkillTreeCanvasState extends State<CircularSkillTreeCanvas>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pathAnimationController;
  late Animation<double> _pathAnimation;

  // Cache node positions to avoid recalculating on every frame
  static const double _stepHeight = 140.0;

  @override
  void initState() {
    super.initState();
    _pathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pathAnimation = CurvedAnimation(
      parent: _pathAnimationController,
      curve: Curves.easeInOut,
    );
    _pathAnimationController.forward();

    // Initial scroll to the "Next" node?
    // We can do this after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveNode();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pathAnimationController.dispose();
    super.dispose();
  }

  void _scrollToActiveNode() {
    if (!mounted) return;
    // Find the first "next" or "available" node index
    int targetIndex = 0;
    for (int i = 0; i < widget.nodes.length; i++) {
      if (_isNextAvailableNode(i) ||
          widget.nodes[i].state == NodeState.inProgress) {
        targetIndex = i;
        break;
      }
    }

    // Scroll to center it if possible
    final offset =
        targetIndex * _stepHeight - (MediaQuery.of(context).size.height / 3);
    if (offset > 0) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // 1. Calculate precise positions for the path painter
        // We use a sine wave pattern for organic flow
        final nodePositions = List.generate(widget.nodes.length, (index) {
          final dx = _calculateNodeX(index, screenWidth);
          final dy =
              (index * _stepHeight) + (_stepHeight / 2) + 40; // Add padding top
          return Offset(dx, dy);
        });

        // Calculate total height
        final totalHeight = (widget.nodes.length * _stepHeight) + 100.0;

        return SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // Layer 1: The Winding Path (Background)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pathAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: SkillTreePathPainter(
                          nodePositions: nodePositions,
                          color: widget.primaryColor,
                          progress: _pathAnimation.value,
                        ),
                      );
                    },
                  ),
                ),

                // Layer 2: Nodes
                ...List.generate(widget.nodes.length, (index) {
                  final node = widget.nodes[index];
                  // Determine if this is the "Next" active node
                  final isNext = _isNextAvailableNode(index);

                  final pos = nodePositions[index];

                  return Positioned(
                    top: pos.dy - (_stepHeight / 2),
                    left: 0,
                    right: 0,
                    height: _stepHeight,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(pos.dx - (screenWidth / 2), 0),
                        child: CircularSkillNode(
                          node: node,
                          primaryColor: widget.primaryColor,
                          isNext: isNext,
                          onTap: () => widget.onNodeTap(node),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Calculates exact X position in pixels for the path and node
  double _calculateNodeX(int index, double screenWidth) {
    final center = screenWidth / 2;
    // Organic sine wave pattern
    // Period: ~6 nodes per full wave
    // Amplitude: 80 pixels
    final offset = sin(index * 0.8) * 85.0;

    // Add a little randomness or variety based on index parity to make it less perfect?
    // Nah, simpler is cleaner.

    return center + offset;
  }

  bool _isNextAvailableNode(int index) {
    final node = widget.nodes[index];

    // If it's locked, it's definitely not next
    if (node.state == NodeState.locked) {
      return false;
    }

    // If it's completed/mastered, it's not the "next" one to *start*
    if (node.state == NodeState.completed || node.state == NodeState.mastered) {
      return false;
    }

    // So it is Available or InProgress.
    // Use it if it's the first one
    if (index == 0) {
      return true;
    }

    // Or if the previous one is done
    final prev = widget.nodes[index - 1];
    return prev.state == NodeState.completed ||
        prev.state == NodeState.mastered;
  }
}
