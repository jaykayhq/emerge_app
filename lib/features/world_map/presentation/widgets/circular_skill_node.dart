import 'dart:math';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

/// A premium, tactile 3D-style circular node inspired by Duolingo
/// Features:
/// - 3D press effect
/// - Animated progress ring
/// - State-dependent styling (Locked, Available, Completed, Mastered)
/// - "Juicy" interactions
class CircularSkillNode extends StatefulWidget {
  final WorldNode node;
  final Color primaryColor;
  final VoidCallback onTap;
  final bool isNext;

  const CircularSkillNode({
    super.key,
    required this.node,
    required this.primaryColor,
    required this.onTap,
    this.isNext = false,
  });

  @override
  State<CircularSkillNode> createState() => _CircularSkillNodeState();
}

class _CircularSkillNodeState extends State<CircularSkillNode>
    with AnimationMixin {
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // Pulse animation for "Next" available nodes
    if (widget.isNext) {
      controller.loop(duration: const Duration(milliseconds: 2000));
    } else {
      controller.play(duration: const Duration(milliseconds: 600));
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getNodeStyle();
    final size = widget.node.state == NodeState.mastered ? 90.0 : 80.0;

    // Scale for press effect
    final scale = _isPressed ? 0.92 : 1.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.node.state != NodeState.locked) widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.diagonal3Values(scale, scale, 1.0),
        transformAlignment: Alignment.center,
        child: SizedBox(
          width: size,
          height: size + 10, // Extra space for 3D extrusion
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // 1. 3D Extrusion (Bottom Layer)
              Positioned(
                top: 8,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: style.shadowColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Button Face (Top Layer)
              Positioned(
                top: _isPressed ? 6 : 0, // Move down when pressed
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        style.faceColor.withValues(alpha: 0.9), // Highlight
                        style.faceColor, // Base
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Icon with glow if active
                        if (widget.node.state != NodeState.locked)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                          ),
                        Icon(
                          widget.node.icon,
                          size: size * 0.45,
                          color: style.iconColor,
                        ),

                        // Progress Ring (If in progress)
                        if (widget.node.progress > 0 &&
                            widget.node.progress < 100)
                          SizedBox(
                            width: size * 0.85,
                            height: size * 0.85,
                            child: CircularProgressIndicator(
                              value: widget.node.progress / 100,
                              strokeWidth: 4,
                              backgroundColor: Colors.black12,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Crown/Mastery Indicator
              if (widget.node.state == NodeState.mastered)
                Positioned(top: -12, right: -4, child: _MasteryCrown()),

              // 4. "Start" Label for Next Node
              if (widget.isNext)
                Positioned(
                  bottom: -24,
                  child: PlayAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 5.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          sin(value * pi) * 3,
                        ), // Bobbing effect
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: widget.primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            "START",
                            style: TextStyle(
                              color: widget.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _NodeVisualStyle _getNodeStyle() {
    switch (widget.node.state) {
      case NodeState.locked:
        return _NodeVisualStyle(
          faceColor: const Color(0xFF374151), // Gray-700
          shadowColor: const Color(0xFF1F2937), // Gray-800
          iconColor: Colors.white30,
        );
      case NodeState.available:
      case NodeState.inProgress:
        return _NodeVisualStyle(
          faceColor: widget.primaryColor,
          shadowColor: Color.lerp(widget.primaryColor, Colors.black, 0.4)!,
          iconColor: Colors.white,
        );
      case NodeState.completed:
        return _NodeVisualStyle(
          faceColor: const Color(0xFFFFD700), // Gold
          shadowColor: const Color(0xFFB45309), // Amber-700
          iconColor: Colors.white,
        );
      case NodeState.mastered:
        return _NodeVisualStyle(
          faceColor: const Color(0xFF8B5CF6), // Violet
          shadowColor: const Color(0xFF5B21B6), // Violet-800
          iconColor: Colors.white,
        );
    }
  }
}

class _NodeVisualStyle {
  final Color faceColor;
  final Color shadowColor;
  final Color iconColor;

  _NodeVisualStyle({
    required this.faceColor,
    required this.shadowColor,
    required this.iconColor,
  });
}

class _MasteryCrown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.amber,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 8),
        ],
      ),
      child: const Icon(Icons.star, color: Colors.white, size: 14),
    );
  }
}
