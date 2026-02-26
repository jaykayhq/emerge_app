import 'dart:math' as math;
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:flutter/material.dart';

/// Stitch-style world map canvas with nodes connected by thin curved lines.
/// Nodes flow TOP-TO-BOTTOM (not reversed). Active node has green halo + play icon.
class NodeMapCanvas extends StatefulWidget {
  final List<WorldNode> nodes;
  final Color primaryColor;
  final Color accentColor;
  final int currentLevel;
  final ValueChanged<WorldNode>? onNodeTap;
  final ScrollController? scrollController;

  const NodeMapCanvas({
    super.key,
    required this.nodes,
    required this.primaryColor,
    required this.accentColor,
    required this.currentLevel,
    this.onNodeTap,
    this.scrollController,
  });

  @override
  State<NodeMapCanvas> createState() => _NodeMapCanvasState();
}

class _NodeMapCanvasState extends State<NodeMapCanvas>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _activeGlowController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _activeGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _revealController.dispose();
    _activeGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxY = widget.nodes.isEmpty
        ? 1.0
        : widget.nodes.map((n) => n.position.dy).reduce(math.max);
    final mapHeight = math.max(800.0, maxY * 1200 + 200);

    return SingleChildScrollView(
      controller: widget.scrollController,
      child: SizedBox(
        height: mapHeight,
        child: Stack(
          children: [
            // Connector lines (behind nodes)
            CustomPaint(
              size: Size(double.infinity, mapHeight),
              painter: _StitchConnectionsPainter(
                nodes: widget.nodes,
                primaryColor: widget.primaryColor,
                currentLevel: widget.currentLevel,
              ),
            ),

            // Nodes with staggered reveal animation
            ...widget.nodes.asMap().entries.map((entry) {
              final index = entry.key;
              final node = entry.value;
              return _buildStitchNode(context, node, mapHeight, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchNode(
    BuildContext context,
    WorldNode node,
    double mapHeight,
    int index,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final x = node.position.dx * screenWidth;
    final y = node.position.dy * mapHeight + 40; // Top-to-bottom: no inversion

    final isUnlocked = node.requiredLevel <= widget.currentLevel;
    final isActive =
        node.state == NodeState.available || node.state == NodeState.inProgress;
    final isCompleted =
        node.state == NodeState.completed || node.state == NodeState.mastered;
    final isLocked = !isUnlocked && node.state == NodeState.locked;

    // Staggered reveal from top
    final staggerDelay = (index * 0.08).clamp(0.0, 0.8);
    final revealInterval = Interval(
      staggerDelay,
      (staggerDelay + 0.3).clamp(0.0, 1.0),
      curve: Curves.easeOutBack,
    );

    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        final revealProgress = revealInterval.transform(
          _revealController.value,
        );
        final slideOffset = 40 * (1 - revealProgress);
        final opacity = revealProgress;

        return Positioned(
          left: x - (isActive ? 36 : 24),
          top: y - (isActive ? 36 : 24) + slideOffset,
          child: Opacity(
            opacity: opacity,
            child: GestureDetector(
              onTap: isLocked ? null : () => widget.onNodeTap?.call(node),
              child: _StitchNodeWidget(
                node: node,
                primaryColor: widget.primaryColor,
                isActive: isActive,
                isCompleted: isCompleted,
                isLocked: isLocked,
                glowController: _activeGlowController,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Individual Stitch-style node
/// Active: Large green circle with play icon + green glow halo + "ACTIVE NODE" pill
/// Completed: Green circle with check icon
/// Locked: Smaller dark circle with lock icon + border
/// Upcoming: Smaller circle with node-type icon
class _StitchNodeWidget extends StatelessWidget {
  final WorldNode node;
  final Color primaryColor;
  final bool isActive;
  final bool isCompleted;
  final bool isLocked;
  final AnimationController glowController;

  const _StitchNodeWidget({
    required this.node,
    required this.primaryColor,
    required this.isActive,
    required this.isCompleted,
    required this.isLocked,
    required this.glowController,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) return _buildActiveNode(context);
    if (isCompleted) return _buildCompletedNode(context);
    if (isLocked) return _buildLockedNode(context);
    return _buildUpcomingNode(context);
  }

  /// Large green circle + play icon + glow halo + "ACTIVE NODE" pill
  Widget _buildActiveNode(BuildContext context) {
    return AnimatedBuilder(
      animation: glowController,
      builder: (context, child) {
        final glowAlpha = 0.3 + 0.3 * glowController.value;
        final scale = 1.0 + 0.04 * glowController.value;

        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green glowing circle with play icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: glowAlpha),
                      blurRadius: 24,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: primaryColor.withValues(alpha: glowAlpha * 0.5),
                      blurRadius: 40,
                      spreadRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Color(0xFF112218),
                  size: 36,
                ),
              ),
              // "ACTIVE NODE" pill label below
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ACTIVE NODE',
                  style: TextStyle(
                    color: Color(0xFF112218),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Green filled circle with checkmark
  Widget _buildCompletedNode(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withValues(alpha: 0.25),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(Icons.check, color: primaryColor, size: 22),
    );
  }

  /// Dark circle with lock icon and border
  Widget _buildLockedNode(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF193324),
            border: Border.all(color: const Color(0xFF326747), width: 2),
          ),
          child: const Icon(Icons.lock, color: Color(0xFF92c9a8), size: 18),
        ),
        // Level requirement badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF193324),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF326747), width: 1),
          ),
          child: Text(
            'Lv.${node.requiredLevel}',
            style: const TextStyle(
              color: Color(0xFF92c9a8),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Upcoming node: subdued circle with type-specific icon
  Widget _buildUpcomingNode(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF193324).withValues(alpha: 0.8),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        _getNodeIcon(),
        color: primaryColor.withValues(alpha: 0.6),
        size: 20,
      ),
    );
  }

  IconData _getNodeIcon() {
    switch (node.type) {
      case NodeType.milestone:
        return Icons.emoji_events;
      case NodeType.challenge:
        return Icons.flash_on;
      case NodeType.resource:
        return Icons.diamond_outlined;
      case NodeType.landmark:
        return Icons.flag;
      case NodeType.waypoint:
        return Icons.circle_outlined;
    }
  }
}

/// Thin curved connector lines between nodes (Stitch style)
class _StitchConnectionsPainter extends CustomPainter {
  final List<WorldNode> nodes;
  final Color primaryColor;
  final int currentLevel;

  _StitchConnectionsPainter({
    required this.nodes,
    required this.primaryColor,
    required this.currentLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in nodes) {
      for (final connectedId in node.connectedNodeIds) {
        final connectedNode = nodes.firstWhere(
          (n) => n.id == connectedId,
          orElse: () => node,
        );
        if (connectedNode.id == node.id) continue;

        // Top-to-bottom coordinates (no inversion)
        final fromX = node.position.dx * size.width;
        final fromY = node.position.dy * size.height;
        final toX = connectedNode.position.dx * size.width;
        final toY = connectedNode.position.dy * size.height;

        final isActive = node.requiredLevel <= currentLevel;

        // Thin line style matching Stitch
        final paint = Paint()
          ..color = isActive
              ? primaryColor.withValues(alpha: 0.4)
              : const Color(0xFF326747).withValues(alpha: 0.5)
          ..strokeWidth = isActive ? 2 : 1.5
          ..style = PaintingStyle.stroke;

        // Curved path
        final path = Path();
        path.moveTo(fromX, fromY);

        final midY = (fromY + toY) / 2;
        final controlX = (fromX + toX) / 2 + (toX > fromX ? 15 : -15);

        path.quadraticBezierTo(controlX, midY, toX, toY);
        canvas.drawPath(path, paint);

        // Green glow dot at midpoint for active paths
        if (isActive) {
          final glowPaint = Paint()
            ..color = primaryColor.withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(Offset(controlX, midY), 4, glowPaint);

          final dotPaint = Paint()
            ..color = primaryColor.withValues(alpha: 0.5)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(controlX, midY), 2, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
