import 'dart:math' as math;
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:flutter/material.dart';

/// CustomPainter widget that renders the world map with nodes and connections
class NodeMapCanvas extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Calculate map height based on highest node Y position
    final maxY = nodes.isEmpty
        ? 1.0
        : nodes.map((n) => n.position.dy).reduce(math.max);
    final mapHeight = math.max(800.0, maxY * 1200 + 200);

    return SingleChildScrollView(
      controller: scrollController,
      reverse: true, // Start at bottom (beginning of journey)
      child: SizedBox(
        height: mapHeight,
        child: Stack(
          children: [
            // Draw connections first (behind nodes)
            CustomPaint(
              size: Size(double.infinity, mapHeight),
              painter: _ConnectionsPainter(
                nodes: nodes,
                primaryColor: primaryColor,
                currentLevel: currentLevel,
              ),
            ),

            // Draw nodes
            ...nodes.map((node) => _buildNodeWidget(context, node, mapHeight)),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeWidget(
    BuildContext context,
    WorldNode node,
    double mapHeight,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final x = node.position.dx * screenWidth;
    final y = mapHeight - (node.position.dy * mapHeight) - 40; // Flip Y axis

    final isUnlocked = node.requiredLevel <= currentLevel;
    final isAvailable = node.state == NodeState.available || isUnlocked;

    return Positioned(
      left: x - 30,
      top: y - 30,
      child: GestureDetector(
        onTap: isAvailable ? () => onNodeTap?.call(node) : null,
        child: _NodeWidget(
          node: node,
          primaryColor: primaryColor,
          accentColor: accentColor,
          isUnlocked: isUnlocked,
        ),
      ),
    );
  }
}

/// Individual node widget with visual states
class _NodeWidget extends StatelessWidget {
  final WorldNode node;
  final Color primaryColor;
  final Color accentColor;
  final bool isUnlocked;

  const _NodeWidget({
    required this.node,
    required this.primaryColor,
    required this.accentColor,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final size = node.type == NodeType.milestone ? 70.0 : 56.0;
    final innerSize = size - 8;

    Color nodeColor;
    double opacity;

    if (node.state == NodeState.mastered) {
      nodeColor = Colors.amber;
      opacity = 1.0;
    } else if (node.state == NodeState.completed) {
      nodeColor = primaryColor;
      opacity = 1.0;
    } else if (node.state == NodeState.inProgress) {
      nodeColor = accentColor;
      opacity = 0.9;
    } else if (isUnlocked) {
      nodeColor = primaryColor;
      opacity = 0.7;
    } else {
      nodeColor = Colors.grey;
      opacity = 0.4;
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceDark,
          border: Border.all(
            color: nodeColor,
            width: node.type == NodeType.milestone ? 3 : 2,
          ),
          boxShadow: isUnlocked && node.state != NodeState.locked
              ? [
                  BoxShadow(
                    color: nodeColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring
            if (node.progress > 0 && node.progress < 100)
              SizedBox(
                width: innerSize,
                height: innerSize,
                child: CircularProgressIndicator(
                  value: node.progress / 100,
                  strokeWidth: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(nodeColor),
                ),
              ),

            // Node icon
            Icon(
              node.icon,
              color: nodeColor,
              size: node.type == NodeType.milestone ? 28 : 22,
            ),

            // Completed checkmark
            if (node.state == NodeState.completed ||
                node.state == NodeState.mastered)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: nodeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 10),
                ),
              ),

            // Level requirement badge (if locked)
            if (!isUnlocked)
              Positioned(
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lv.${node.requiredLevel}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Painter for drawing connections between nodes
class _ConnectionsPainter extends CustomPainter {
  final List<WorldNode> nodes;
  final Color primaryColor;
  final int currentLevel;

  _ConnectionsPainter({
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

        final fromX = node.position.dx * size.width;
        final fromY = size.height - (node.position.dy * size.height);
        final toX = connectedNode.position.dx * size.width;
        final toY = size.height - (connectedNode.position.dy * size.height);

        final isActive = node.requiredLevel <= currentLevel;

        final paint = Paint()
          ..color = isActive
              ? primaryColor.withValues(alpha: 0.6)
              : Colors.grey.withValues(alpha: 0.3)
          ..strokeWidth = isActive ? 3 : 2
          ..style = PaintingStyle.stroke;

        // Draw curved path
        final path = Path();
        path.moveTo(fromX, fromY);

        // Control point for bezier curve
        final midY = (fromY + toY) / 2;
        final controlX = (fromX + toX) / 2 + (toX > fromX ? 20 : -20);

        path.quadraticBezierTo(controlX, midY, toX, toY);

        canvas.drawPath(path, paint);

        // Draw glowing dots along active paths
        if (isActive) {
          final dotPaint = Paint()
            ..color = primaryColor
            ..style = PaintingStyle.fill;

          // Midpoint dot
          canvas.drawCircle(Offset(controlX, midY), 3, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
