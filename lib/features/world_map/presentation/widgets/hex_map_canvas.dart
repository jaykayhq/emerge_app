import 'dart:math';
import 'dart:ui';

import 'package:emerge_app/features/world_map/domain/logic/hex_grid_logic.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:flutter/material.dart';

/// Premium hex grid map canvas with glowing nodes and animated paths
/// Auto-centers on the first available node for immediate visibility
class HexMapCanvas extends StatefulWidget {
  final List<WorldNode> nodes;
  final Function(WorldNode) onNodeTap;
  final Color? primaryColor;
  final Color? accentColor;

  const HexMapCanvas({
    super.key,
    required this.nodes,
    required this.onNodeTap,
    this.primaryColor,
    this.accentColor,
  });

  @override
  State<HexMapCanvas> createState() => _HexMapCanvasState();
}

class _HexMapCanvasState extends State<HexMapCanvas>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();

  late HexLayout _layout;
  static const double _hexSize = 42.0; // Balanced size for visibility and fit
  static const Offset _canvasCenter = Offset(1000, 1000);
  static const double _canvasSize = 2000;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _pathController;

  bool _hasCentered = false;

  @override
  void initState() {
    super.initState();

    _layout = const HexLayout(
      size: _hexSize,
      orientation: HexOrientation.pointy,
    );

    // Pulse animation for current/available nodes
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Path particle animation
    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pulseController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  void _centerOnFirstNode(Size viewportSize) {
    if (_hasCentered || widget.nodes.isEmpty) return;
    _hasCentered = true;

    // Find first available node, or fallback to first node
    final targetNode = widget.nodes.firstWhere(
      (n) => n.state == NodeState.available || n.state == NodeState.inProgress,
      orElse: () => widget.nodes.first,
    );

    final nodePixel = _layout.hexToPixel(targetNode.hexLocation);
    final nodeOnCanvas = nodePixel + _canvasCenter;

    // Calculate transform to center this node in viewport
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final translation = viewportCenter - nodeOnCanvas;

    _transformationController.value = Matrix4.identity()
      ..setTranslationRaw(translation.dx, translation.dy, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    final accentColor = widget.accentColor ?? theme.colorScheme.secondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Auto-center on first build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _centerOnFirstNode(Size(constraints.maxWidth, constraints.maxHeight));
        });

        return Stack(
          children: [
            // Interactive map
            GestureDetector(
              onTapUp: _handleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(500),
                minScale: 0.4,
                maxScale: 2.5,
                constrained: false,
                child: SizedBox(
                  width: _canvasSize,
                  height: _canvasSize,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _pulseController,
                      _pathController,
                    ]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _PremiumHexGridPainter(
                          nodes: widget.nodes,
                          layout: _layout,
                          primaryColor: primaryColor,
                          accentColor: accentColor,
                          offset: _canvasCenter,
                          pulseValue: _pulseController.value,
                          pathProgress: _pathController.value,
                        ),
                        size: const Size(_canvasSize, _canvasSize),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Center button
            Positioned(
              right: 16,
              bottom: 16,
              child: _CenterButton(
                onPressed: () {
                  _hasCentered = false;
                  _centerOnFirstNode(
                    Size(constraints.maxWidth, constraints.maxHeight),
                  );
                },
                color: primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleTap(TapUpDetails details) {
    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.tryInvert(matrix);

    if (inverseMatrix != null) {
      final localPoint = MatrixUtils.transformPoint(
        inverseMatrix,
        details.localPosition,
      );
      final logicPoint = localPoint - _canvasCenter;
      final hex = _layout.pixelToHex(logicPoint);

      // Find node at tapped hex location
      WorldNode? tappedNode;
      for (final n in widget.nodes) {
        if (n.hexLocation == hex) {
          tappedNode = n;
          break;
        }
      }

      if (tappedNode != null && tappedNode.state != NodeState.locked) {
        widget.onNodeTap(tappedNode);
      }
    }
  }
}

/// Glassmorphism center button
class _CenterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;

  const _CenterButton({required this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.1),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.my_location, color: color, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium hex grid painter with glow effects and animated paths
class _PremiumHexGridPainter extends CustomPainter {
  final List<WorldNode> nodes;
  final HexLayout layout;
  final Color primaryColor;
  final Color accentColor;
  final Offset offset;
  final double pulseValue;
  final double pathProgress;

  _PremiumHexGridPainter({
    required this.nodes,
    required this.layout,
    required this.primaryColor,
    required this.accentColor,
    required this.offset,
    required this.pulseValue,
    required this.pathProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw path connections first (behind nodes)
    _drawConnections(canvas, size);

    // 2. Draw path particles
    _drawPathParticles(canvas, size);

    // 3. Draw nodes
    _drawNodes(canvas, size);
  }

  void _drawConnections(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (final node in nodes) {
      if (node.state == NodeState.locked) continue;

      final start = layout.hexToPixel(node.hexLocation) + offset;

      for (final targetId in node.connectedNodeIds) {
        try {
          final target = nodes.firstWhere((n) => n.id == targetId);
          final end = layout.hexToPixel(target.hexLocation) + offset;

          // Determine path color based on connection state
          final isActive = target.state != NodeState.locked;
          final pathColor = isActive
              ? primaryColor.withValues(alpha: 0.6)
              : Colors.grey.withValues(alpha: 0.2);

          // Draw glow for active paths
          if (isActive) {
            final glowPaint = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = primaryColor.withValues(alpha: 0.15)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
            canvas.drawLine(start, end, glowPaint);
          }

          basePaint.color = pathColor;
          canvas.drawLine(start, end, basePaint);
        } catch (e) {
          // Target not found
        }
      }
    }
  }

  void _drawPathParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = primaryColor;

    for (final node in nodes) {
      if (node.state == NodeState.locked) continue;

      final start = layout.hexToPixel(node.hexLocation) + offset;

      for (final targetId in node.connectedNodeIds) {
        try {
          final target = nodes.firstWhere((n) => n.id == targetId);
          if (target.state == NodeState.locked) continue;

          final end = layout.hexToPixel(target.hexLocation) + offset;

          // Animate particle along path
          final t = (pathProgress + node.id.hashCode * 0.1) % 1.0;
          final particlePos = Offset.lerp(start, end, t)!;

          particlePaint.color = primaryColor.withValues(alpha: 0.8);
          particlePaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawCircle(particlePos, 4, particlePaint);

          particlePaint.maskFilter = null;
          particlePaint.color = Colors.white.withValues(alpha: 0.9);
          canvas.drawCircle(particlePos, 2, particlePaint);
        } catch (e) {
          // Target not found
        }
      }
    }
  }

  void _drawNodes(Canvas canvas, Size size) {
    // 3D depth configuration
    const double extrusionDepth = 12.0; // How "tall" the 3D block appears
    const Offset lightDirection = Offset(-0.5, 0.7); // Light from top-left

    for (final node in nodes) {
      final center = layout.hexToPixel(node.hexLocation) + offset;

      // Determine visibility (fog of war)
      if (node.state == NodeState.locked && !_isNearUnlocked(node)) {
        continue;
      }

      final style = _getNodeStyle(node);

      // === LAYER 1: Drop Shadow ===
      _drawNodeShadow(canvas, center, layout.size, style, extrusionDepth);

      // === LAYER 2: 3D Extrusion (side faces) ===
      _drawNodeExtrusion(canvas, center, layout.size, style, extrusionDepth);

      // === LAYER 3: Top Face with Gradient ===
      _drawNodeTopFace(canvas, center, layout.size, style, lightDirection);

      // === LAYER 4: Inner Glow/Shine ===
      if (node.state != NodeState.locked) {
        _drawNodeInnerShine(canvas, center, layout.size, style);
      }

      // === LAYER 5: Outer Glow (active nodes only) ===
      if (node.state != NodeState.locked) {
        _drawNodeOuterGlow(canvas, center, layout.size, style);
      }

      // === LAYER 6: Border/Edge Highlight ===
      _drawNodeBorder(canvas, center, layout.size, style);

      // === LAYER 7: Icon ===
      _drawIcon(canvas, center, node.icon, style.iconColor, layout.size * 0.45);

      // === LAYER 8: Progress Ring ===
      if (node.progress > 0 && node.progress < 100) {
        _drawProgressRing(canvas, center, node.progress, style.color);
      }

      // === LAYER 9: Completion Badge ===
      if (node.state == NodeState.completed ||
          node.state == NodeState.mastered) {
        _drawCompletionBadge(canvas, center, style.color, node.state);
      }

      // === LAYER 10: Node Label ===
      _drawNodeLabel(canvas, center, node.name, style.color);
    }
  }

  /// Draws a soft shadow beneath the 3D hex block
  void _drawNodeShadow(
    Canvas canvas,
    Offset center,
    double size,
    _NodeStyle style,
    double depth,
  ) {
    final shadowOffset = Offset(depth * 0.3, depth * 0.8);
    final shadowPath = _getHexPath(center + shadowOffset, size * 0.95);

    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(shadowPath, shadowPaint);
  }

  /// Draws the extruded side faces of the 3D hex block
  void _drawNodeExtrusion(
    Canvas canvas,
    Offset center,
    double size,
    _NodeStyle style,
    double depth,
  ) {
    // Get hex vertices
    final vertices = _getHexVertices(center, size);
    final bottomVertices = vertices.map((v) => v + Offset(0, depth)).toList();

    // Only draw visible faces (bottom 3 sides for this perspective)
    // Faces: 3-4, 4-5, 5-0 (bottom half of the hex)
    final visibleFaces = [
      [3, 4],
      [4, 5],
      [5, 0],
    ];

    for (var i = 0; i < visibleFaces.length; i++) {
      final startIdx = visibleFaces[i][0];
      final endIdx = visibleFaces[i][1];

      final facePath = Path()
        ..moveTo(vertices[startIdx].dx, vertices[startIdx].dy)
        ..lineTo(vertices[endIdx].dx, vertices[endIdx].dy)
        ..lineTo(bottomVertices[endIdx].dx, bottomVertices[endIdx].dy)
        ..lineTo(bottomVertices[startIdx].dx, bottomVertices[startIdx].dy)
        ..close();

      // Darker shade for side faces
      final shade = 0.3 + (i * 0.15); // Varying darkness for each face
      final faceColor = Color.lerp(style.fillColor, Colors.black, shade)!;

      final facePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = faceColor;

      canvas.drawPath(facePath, facePaint);

      // Edge line for definition
      final edgePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = style.color.withValues(alpha: 0.3);

      canvas.drawPath(facePath, edgePaint);
    }
  }

  /// Draws the top face with gradient lighting
  void _drawNodeTopFace(
    Canvas canvas,
    Offset center,
    double size,
    _NodeStyle style,
    Offset lightDir,
  ) {
    final topPath = _getHexPath(center, size);

    // Create gradient from top-left (light) to bottom-right (shadow)
    final gradientPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment(-lightDir.dx, -lightDir.dy),
        end: Alignment(lightDir.dx, lightDir.dy),
        colors: [
          Color.lerp(style.fillColor, Colors.white, 0.2)!,
          style.fillColor,
          Color.lerp(style.fillColor, Colors.black, 0.15)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size));

    canvas.drawPath(topPath, gradientPaint);
  }

  /// Draws the inner shine/glow for active nodes
  void _drawNodeInnerShine(
    Canvas canvas,
    Offset center,
    double size,
    _NodeStyle style,
  ) {
    // Inner radial glow
    final innerSize = size * 0.7;
    final shinePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          style.color.withValues(alpha: 0.4 * style.glowIntensity),
          style.color.withValues(alpha: 0.1 * style.glowIntensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: innerSize));

    canvas.drawCircle(center, innerSize, shinePaint);

    // Specular highlight (small bright spot)
    final highlightOffset = center + const Offset(-8, -8);
    final highlightPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.3 * style.glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(highlightOffset, size * 0.15, highlightPaint);
  }

  /// Draws the outer glow for active nodes
  void _drawNodeOuterGlow(
    Canvas canvas,
    Offset center,
    double size,
    _NodeStyle style,
  ) {
    final glowRadius =
        size * (1.0 + style.glowIntensity * 0.3 + pulseValue * 0.1);
    final glowPaint = Paint()
      ..color = style.color.withValues(alpha: 0.25 * style.glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.4);

    canvas.drawCircle(center, size * 1.1, glowPaint);
  }

  /// Draws the border/edge of the top face
  void _drawNodeBorder(
    Canvas canvas,
    Offset center,
    double size,
    _NodeStyle style,
  ) {
    final topPath = _getHexPath(center, size);

    // Main border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.borderWidth
      ..color = style.color;

    canvas.drawPath(topPath, borderPaint);

    // Inner edge highlight (bevel effect)
    final innerPath = _getHexPath(center, size - 3);
    final bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.15);

    canvas.drawPath(innerPath, bevelPaint);
  }

  /// Helper to get hex vertices as a list
  List<Offset> _getHexVertices(Offset center, double size) {
    final vertices = <Offset>[];
    for (var i = 0; i < 6; i++) {
      final angleDeg = 60 * i - 30;
      final angleRad = pi / 180 * angleDeg;
      vertices.add(
        Offset(
          center.dx + size * cos(angleRad),
          center.dy + size * sin(angleRad),
        ),
      );
    }
    return vertices;
  }

  bool _isNearUnlocked(WorldNode node) {
    // Simple fog of war - show locked nodes adjacent to unlocked ones
    for (final other in nodes) {
      if (other.state != NodeState.locked &&
          node.hexLocation.distanceTo(other.hexLocation) <= 2) {
        return true;
      }
    }
    return false;
  }

  _NodeStyle _getNodeStyle(WorldNode node) {
    switch (node.state) {
      case NodeState.mastered:
        return _NodeStyle(
          color: const Color(0xFFFFD700), // Gold
          fillColor: const Color(0xFF2A2520),
          iconColor: const Color(0xFFFFD700),
          glowIntensity: 1.0,
          borderWidth: 3.5,
        );
      case NodeState.completed:
        return _NodeStyle(
          color: primaryColor,
          fillColor: primaryColor.withValues(alpha: 0.15),
          iconColor: primaryColor,
          glowIntensity: 0.7,
          borderWidth: 3.0,
        );
      case NodeState.inProgress:
        return _NodeStyle(
          color: accentColor,
          fillColor: accentColor.withValues(alpha: 0.2),
          iconColor: accentColor,
          glowIntensity: 0.9,
          borderWidth: 3.0,
        );
      case NodeState.available:
        return _NodeStyle(
          color: primaryColor,
          fillColor: primaryColor.withValues(alpha: 0.1),
          iconColor: primaryColor.withValues(alpha: 0.8),
          glowIntensity: 0.5 + pulseValue * 0.3,
          borderWidth: 2.5,
        );
      case NodeState.locked:
        return _NodeStyle(
          color: Colors.grey.shade600,
          fillColor: Colors.grey.shade900.withValues(alpha: 0.3),
          iconColor: Colors.grey.shade700,
          glowIntensity: 0.0,
          borderWidth: 1.5,
        );
    }
  }

  Path _getHexPath(Offset center, double size) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angleDeg = 60 * i - 30;
      final angleRad = pi / 180 * angleDeg;
      final x = center.dx + size * cos(angleRad);
      final y = center.dy + size * sin(angleRad);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _drawIcon(
    Canvas canvas,
    Offset center,
    IconData icon,
    Color color,
    double size,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawProgressRing(
    Canvas canvas,
    Offset center,
    int progress,
    Color color,
  ) {
    final rect = Rect.fromCircle(center: center, radius: layout.size + 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.8);

    // Background ring
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi,
      false,
      paint..color = color.withValues(alpha: 0.2),
    );

    // Progress arc
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * (progress / 100),
      false,
      paint..color = color,
    );
  }

  void _drawCompletionBadge(
    Canvas canvas,
    Offset center,
    Color color,
    NodeState state,
  ) {
    final badgeCenter = center + Offset(layout.size * 0.6, -layout.size * 0.6);

    // Badge glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(badgeCenter, 10, glowPaint);

    // Badge fill
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(badgeCenter, 8, fillPaint);

    // Checkmark or star
    final iconData = state == NodeState.mastered ? Icons.star : Icons.check;
    _drawIcon(canvas, badgeCenter, iconData, Colors.white, 10);
  }

  void _drawNodeLabel(Canvas canvas, Offset center, String name, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.9),
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: layout.size * 3);

    final labelOffset =
        center + Offset(-textPainter.width / 2, layout.size + 8);
    textPainter.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant _PremiumHexGridPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.pathProgress != pathProgress ||
        oldDelegate.nodes != nodes;
  }
}

class _NodeStyle {
  final Color color;
  final Color fillColor;
  final Color iconColor;
  final double glowIntensity;
  final double borderWidth;

  const _NodeStyle({
    required this.color,
    required this.fillColor,
    required this.iconColor,
    required this.glowIntensity,
    required this.borderWidth,
  });
}
