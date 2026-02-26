import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/domain/services/node_state_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A widget representing a map node as a Stitch-style circle.
/// Features states: Locked, Available (active), Completed, Mastered.
/// Uses Material icons instead of emoji — matches the Stitch world map design.
class StructureNode extends StatefulWidget {
  final WorldNode node;
  final Color primaryColor;
  final VoidCallback? onTap;
  final double size;
  final UserProfile? userProfile; // For soft gate logic
  final List<String> completedNodeIds; // For state calculation

  const StructureNode({
    super.key,
    required this.node,
    required this.primaryColor,
    this.onTap,
    this.size = 64.0,
    this.userProfile,
    this.completedNodeIds = const [],
  });

  @override
  State<StructureNode> createState() => _StructureNodeState();
}

class _StructureNodeState extends State<StructureNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

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

  void _handleTap(BuildContext context) {
    final isLocked = widget.node.state == NodeState.locked;

    // Check soft gate if user profile is provided
    if (widget.userProfile != null && isLocked) {
      final progressionState = NodeStateService.calculateState(
        widget.node,
        widget.userProfile!,
        widget.completedNodeIds,
      );

      if (progressionState == ProgressionState.locked) {
        // Show soft gate message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NodeStateService.getLockReason(widget.node, widget.userProfile!)),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // If not locked or gate passed, call original onTap
    if (!isLocked && widget.onTap != null) {
      widget.onTap!();
    } else if (!isLocked) {
      // Navigate to node detail if no onTap provided
      context.push('/node/${widget.node.id}');
    }
  }

  Widget _buildXPDisplay() {
    final xpProgress = widget.node.completionPercent.clamp(0.0, 1.0);
    final xpText = '${widget.node.nodeXp}/${widget.node.nodeXpRequired}';

    // Get color for primary attribute
    final primaryAttr = widget.node.primaryAttributes.firstOrNull;
    final xpColor = primaryAttr != null
        ? ArchetypeColors.forAttribute(primaryAttr)
        : widget.primaryColor;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          // XP Progress Bar
          SizedBox(
            width: widget.size * 0.9,
            height: 4,
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Progress fill
                FractionallySizedBox(
                  widthFactor: xpProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: xpColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // XP text
          SizedBox(height: 2),
          Text(
            xpText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: widget.size * 0.12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.node.state == NodeState.locked;
    final isCompleted =
        widget.node.state == NodeState.completed ||
        widget.node.state == NodeState.mastered;
    final isAvailable = widget.node.state == NodeState.available;
    final isMilestone = widget.node.type == NodeType.milestone;

    final activeSize = isMilestone ? widget.size * 1.3 : widget.size;
    final nodeSize = isAvailable ? activeSize : widget.size * 0.75;

    return Semantics(
      label: '${widget.node.name} - ${widget.node.state.name}',
      button: true,
      enabled: true,
      onTap: () => _handleTap(context),
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = isAvailable
                ? 1.0 + 0.05 * _pulseAnimation.value
                : 1.0;

            return Transform.scale(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "ACTIVE NODE" pill for available nodes
                  if (isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: const Color(0xFF112218),
                          fontSize: widget.size * 0.13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                  // Node circle
                  Container(
                    width: nodeSize,
                    height: nodeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getNodeColor(),
                      border: Border.all(
                        color: _getBorderColor(),
                        width: isAvailable ? 0 : 2,
                      ),
                      boxShadow: [
                        if (isAvailable)
                          BoxShadow(
                            color: widget.primaryColor.withValues(
                              alpha: 0.3 + 0.3 * _pulseAnimation.value,
                            ),
                            blurRadius: 20,
                            spreadRadius: 6,
                          ),
                        if (isAvailable)
                          BoxShadow(
                            color: widget.primaryColor.withValues(
                              alpha: 0.15 + 0.15 * _pulseAnimation.value,
                            ),
                            blurRadius: 36,
                            spreadRadius: 12,
                          ),
                        if (isCompleted)
                          BoxShadow(
                            color: widget.primaryColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Icon(
                      _getIcon(),
                      color: _getIconColor(),
                      size: isAvailable ? nodeSize * 0.5 : nodeSize * 0.45,
                    ),
                  ),

                  // Level tag for locked nodes
                  if (isLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      margin: const EdgeInsets.only(top: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF193324),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF326747),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Lv.${widget.node.requiredLevel}',
                        style: TextStyle(
                          color: EmergeColors.tealMuted,
                          fontSize: widget.size * 0.14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // XP Display for unlocked nodes
                  if (!isLocked)
                    _buildXPDisplay(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getNodeColor() {
    switch (widget.node.state) {
      case NodeState.available:
        return widget.primaryColor; // Solid green
      case NodeState.completed:
        return widget.primaryColor.withValues(alpha: 0.25);
      case NodeState.mastered:
        return widget.primaryColor.withValues(alpha: 0.35);
      case NodeState.inProgress:
        return widget.primaryColor.withValues(alpha: 0.5);
      case NodeState.locked:
        return const Color(0xFF193324);
    }
  }

  Color _getBorderColor() {
    switch (widget.node.state) {
      case NodeState.available:
        return Colors.transparent;
      case NodeState.completed:
      case NodeState.mastered:
        return widget.primaryColor.withValues(alpha: 0.6);
      case NodeState.inProgress:
        return widget.primaryColor.withValues(alpha: 0.4);
      case NodeState.locked:
        return const Color(0xFF326747);
    }
  }

  Color _getIconColor() {
    switch (widget.node.state) {
      case NodeState.available:
        return const Color(0xFF112218); // Dark on green
      case NodeState.completed:
      case NodeState.mastered:
        return widget.primaryColor;
      case NodeState.inProgress:
        return widget.primaryColor.withValues(alpha: 0.8);
      case NodeState.locked:
        return const Color(0xFF92c9a8);
    }
  }

  IconData _getIcon() {
    if (widget.node.state == NodeState.locked) return Icons.lock;
    if (widget.node.state == NodeState.available) return Icons.play_arrow;
    if (widget.node.state == NodeState.completed ||
        widget.node.state == NodeState.mastered) {
      return Icons.check;
    }

    // In-progress or unlocked: use node type icon
    switch (widget.node.type) {
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
