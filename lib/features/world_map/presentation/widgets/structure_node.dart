import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:flutter/material.dart';

/// A widget representing a map node as a structure/shape (e.g., Diamond, Crystal)
/// Features states: Locked, Available, Completed
class StructureNode extends StatefulWidget {
  final WorldNode node;
  final Color primaryColor;
  final VoidCallback? onTap; // Nullable if locked
  final double size;

  const StructureNode({
    super.key,
    required this.node,
    required this.primaryColor,
    this.onTap,
    this.size = 64.0,
  });

  @override
  State<StructureNode> createState() => _StructureNodeState();
}

class _StructureNodeState extends State<StructureNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.node.state == NodeState.available) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StructureNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.state != oldWidget.node.state) {
      if (widget.node.state == NodeState.available) {
        _controller.repeat(reverse: true);
      } else {
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.node.state == NodeState.locked;
    final isCompleted =
        widget.node.state == NodeState.completed ||
        widget.node.state == NodeState.mastered;
    final isAvailable = widget.node.state == NodeState.available;

    return Semantics(
      label: '${widget.node.name} - ${widget.node.state.name}',
      button: true,
      enabled: !isLocked,
      onTap: isLocked ? null : widget.onTap,
      child: GestureDetector(
        onTap: isLocked ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: isAvailable ? _scaleAnimation.value : 1.0,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Glow for available nodes
                  if (isAvailable)
                    Container(
                      width: widget.size * 0.8,
                      height: widget.size * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryColor.withValues(
                              alpha: 0.6 * _pulseAnimation.value,
                            ), // Pulsing glow
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),

                  // The 3D Object (Emoji)
                  Text(
                    isLocked ? '🔒' : widget.node.emoji,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: widget.size * 0.6,
                      shadows: [
                        if (!isLocked)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                  ),

                  // Completed badge
                  if (isCompleted)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: EmergeColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          size: widget.size * 0.25,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
