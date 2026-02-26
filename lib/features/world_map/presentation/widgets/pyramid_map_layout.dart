import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/structure_node.dart';
import 'package:flutter/material.dart';

/// A scrollable map layout that arranges nodes top-to-bottom (not reversed).
/// Supports infinite sections, grouping nodes into sections of 5 levels.
/// Nodes flow from top (early levels) to bottom (later levels).
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
    // Sort nodes by level (ascending - Level 1 first at top)
    final sortedNodes = List<WorldNode>.from(nodes)
      ..sort((a, b) => a.requiredLevel.compareTo(b.requiredLevel));

    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 100, // Padding for header
          bottom: 160, // Padding for bottom stats bar
          left: 16,
          right: 16,
        ),
        child: Column(children: _buildNodeRows(sortedNodes)),
      ),
    );
  }

  List<Widget> _buildNodeRows(List<WorldNode> nodes) {
    final List<Widget> rows = [];

    int index = 0;
    int patternIndex = 0;
    const patterns = [1, 2, 1, 3]; // Pattern of nodes per row

    while (index < nodes.length) {
      final take = patterns[patternIndex % patterns.length];
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

      // Add spacing between rows
      rows.add(const SizedBox(height: 50));

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
