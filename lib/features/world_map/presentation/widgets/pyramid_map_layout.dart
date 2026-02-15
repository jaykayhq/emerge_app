import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/structure_node.dart';
import 'package:flutter/material.dart';

/// A scrollable map layout that arranges nodes in a pyramid/vertical hierarchy.
/// Supports infinite sections (conceptually), grouping nodes into sections of 5 levels.
class PyramidMapLayout extends StatelessWidget {
  final List<WorldNode> nodes;
  final Color primaryColor;
  final Function(WorldNode) onNodeTap;
  final ScrollController scrollController;

  const PyramidMapLayout({
    super.key,
    required this.nodes,
    required this.primaryColor,
    required this.onNodeTap,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Sort nodes by level/requirements
    final sortedNodes = List<WorldNode>.from(nodes)
      ..sort((a, b) => a.requiredLevel.compareTo(b.requiredLevel));

    // We want "Ascent" mode.
    // Level 1 should be at the BOTTOM.
    // Standard Vertical Scroll: Top=Start.
    // Reverse Vertical Scroll: Bottom=Start.
    // So we use reverse: true on SingleChildScrollView.
    // And we keep the nodes in Ascending order [Level 1, ..., Level N].
    // Level 1 will be at the visually "bottom" (start of reverse list).

    final renderNodes = sortedNodes; // Keep ascending [1..N]

    return SingleChildScrollView(
      controller: scrollController,
      reverse: true, // Start at bottom, scroll up
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 100, // Padding for header/footer
          horizontal: 24,
        ),
        child: Column(children: _buildNodeRows(renderNodes)),
      ),
    );
  }

  List<Widget> _buildNodeRows(List<WorldNode> nodes) {
    final List<Widget> rows = [];

    // Pattern: 1 node, then 2, then 1, then 2... (from top to bottom now, or bottom to top?)
    // If we reversed the list, the first nodes we process are the HIGHEST levels.
    // The pattern applies to them.
    // Let's use a simple grouping.

    int index = 0;
    int patternIndex = 0;
    const patterns = [1, 2, 1, 3]; // Repeatable pattern of nodes per row

    while (index < nodes.length) {
      final take = patterns[patternIndex % patterns.length];
      // Be careful not to exceed bounds
      final end = (index + take < nodes.length) ? index + take : nodes.length;
      final chunk = nodes.sublist(index, end);

      if (chunk.isEmpty) break;

      rows.add(
        _NodeRow(
          nodes: chunk,
          primaryColor: primaryColor,
          onNodeTap: onNodeTap,
        ),
      );

      // Add specific spacing between rows
      rows.add(const SizedBox(height: 60));

      index = end;
      patternIndex++;
    }

    return rows;
  }
}

class _NodeRow extends StatelessWidget {
  final List<WorldNode> nodes;
  final Color primaryColor;
  final Function(WorldNode) onNodeTap;

  const _NodeRow({
    required this.nodes,
    required this.primaryColor,
    required this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: nodes.map((node) {
        // Calculate size/importance?
        final bool isBoss = node.requiredLevel % 5 == 0;
        final double size = isBoss ? 80.0 : 64.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              StructureNode(
                node: node,
                primaryColor: primaryColor,
                onTap: () => onNodeTap(node),
                size: size,
              ),
              const SizedBox(height: 8),
              if (node.state != NodeState.locked)
                Text(
                  'LVL ${node.requiredLevel}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
