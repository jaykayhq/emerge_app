import 'dart:math';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/structure_node.dart';
import 'package:flutter/material.dart';

/// A scrollable map layout that arranges nodes in an S-curve.
/// Nodes are stacked behind each other vertically, simulating depth
/// similar to the Stitch World Map Progression concept.
class CurvedMapLayout extends StatelessWidget {
  final List<WorldNode> nodes;
  final Color primaryColor;
  final Function(WorldNode) onNodeTap;
  final ScrollController scrollController;
  final GlobalKey? firstNodeKey;

  const CurvedMapLayout({
    super.key,
    required this.nodes,
    required this.primaryColor,
    required this.onNodeTap,
    required this.scrollController,
    this.firstNodeKey,
  });

  @override
  Widget build(BuildContext context) {
    // Sort nodes by level (ascending - Level 1 first at bottom)
    final sortedNodes = List<WorldNode>.from(nodes)
      ..sort((a, b) => a.requiredLevel.compareTo(b.requiredLevel));

    final screenHeight = MediaQuery.of(context).size.height;
    // Calculate spacing to fit exactly ~3 nodes on the screen vertically
    final double nodeSpacingY = screenHeight * 0.35;
    const double nodeSizeNormal = 64.0;
    const double nodeSizeBoss = 80.0;

    // Total height = padding + (nodes * spacing)
    final double mapHeight =
        200.0 + (sortedNodes.length * nodeSpacingY) + 160.0;

    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      // Start from bottom so new users see Level 1 first
      reverse: true,
      child: SizedBox(
        height: mapHeight,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          // Reversing children ensures higher level nodes are drawn behind lower ones,
          // or we can just draw them in order (0 to N) so level 1 is drawn first and higher levels draw on top.
          children: _buildNodes(
            sortedNodes,
            nodeSpacingY,
            nodeSizeNormal,
            nodeSizeBoss,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNodes(
    List<WorldNode> nodes,
    double spacingY,
    double sizeNormal,
    double sizeBoss,
  ) {
    final List<Widget> positionedNodes = [];
    final double amplitude = 80.0; // Horizontal wave width

    // Add path connections behind nodes first
    positionedNodes.add(_buildPath(nodes, spacingY, amplitude));

    // Render nodes from bottom to top index so higher levels draw on top of lower ones
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final bool isBoss = node.requiredLevel % 5 == 0;
      final double size = isBoss ? sizeBoss : sizeNormal;

      // Calculate vertical position from bottom
      // Bottom padding + (index * spacing)
      final double bottomPos = 160.0 + (i * spacingY);

      // Calculate horizontal curve using sine wave
      // Add offset so different levels swing left/right
      final double xOffset = sin(i * 0.8) * amplitude;

      positionedNodes.add(
        Positioned(
          bottom: bottomPos,
          // Centered horizontally with sine curve offset
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: scrollController,
            builder: (context, child) {
              double opacity = 1.0;
              if (scrollController.hasClients) {
                final currentScroll = scrollController.offset;
                final screenHeight = MediaQuery.of(context).size.height;
                // As you scroll up, currentScroll increases.
                // The top edge of the viewport in terms of 'bottom offset' is currentScroll + screenHeight.
                // If the node's bottomPos is significantly higher than the top edge, it hasn't been reached.
                // Reveal effect: fade in as it enters the top 20% of the screen.
                final distanceFromTopEdge = bottomPos - currentScroll;

                if (distanceFromTopEdge > screenHeight * 0.8) {
                  // It's in the top 20% of the screen or above, start fading it in
                  // Fade from 0 at the very top (screenHeight) to 1 at screenHeight * 0.8
                  final progress =
                      (screenHeight - distanceFromTopEdge) /
                      (screenHeight * 0.2);
                  opacity = progress.clamp(0.0, 1.0);
                }
              }

              // Also dim locked nodes
              if (node.state == NodeState.locked) {
                opacity *= 0.6; // 60% base opacity for locked nodes
              }

              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(xOffset, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StructureNode(
                        key: i == 0 ? firstNodeKey : null,
                        node: node,
                        primaryColor: primaryColor,
                        onTap: () => onNodeTap(node),
                        size: size,
                      ),
                      const SizedBox(height: 8),
                      if (node.state != NodeState.locked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'LVL ${node.requiredLevel}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return positionedNodes;
  }

  Widget _buildPath(List<WorldNode> nodes, double spacingY, double amplitude) {
    return Positioned.fill(
      bottom: 160.0 + 32.0, // Start higher up to match first node center
      child: CustomPaint(
        painter: _PathPainter(
          nodeCount: nodes.length,
          spacingY: spacingY,
          amplitude: amplitude,
          pathColor: primaryColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final int nodeCount;
  final double spacingY;
  final double amplitude;
  final Color pathColor;

  _PathPainter({
    required this.nodeCount,
    required this.spacingY,
    required this.amplitude,
    required this.pathColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCount <= 1) return;

    final paint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerX = size.width / 2;

    for (int i = 0; i < nodeCount; i++) {
      // Y goes from size.height bottom upwards
      final double y = size.height - (i * spacingY);
      final double xOffset = sin(i * 0.8) * amplitude;
      final double x = centerX + xOffset;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Find previous point to curve between them
        final prevY = size.height - ((i - 1) * spacingY);
        final prevX = centerX + (sin((i - 1) * 0.8) * amplitude);

        // Control point logic for smooth S-curve look
        path.quadraticBezierTo(prevX, prevY - (spacingY / 2), x, y);
      }
    }

    // Add glow effect to the path
    canvas.drawShadow(path, pathColor.withValues(alpha: 0.5), 10, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.nodeCount != nodeCount ||
        oldDelegate.spacingY != spacingY ||
        oldDelegate.amplitude != amplitude;
  }
}
