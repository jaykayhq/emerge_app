import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';
import 'package:emerge_app/features/tutorials/domain/node_guide_registry.dart';
import 'package:emerge_app/features/tutorials/presentation/providers/node_guide_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps a screen (or dialog body) and shows the node guide for [nodeId]
/// on its first visit while tutorials are enabled.
///
/// Overlays a [FeatureCoachMark] on top of [child]; dismissing marks the
/// node as seen so the guide never reappears.
class NodeGuideHost extends ConsumerStatefulWidget {
  final String nodeId;
  final Widget child;

  const NodeGuideHost({super.key, required this.nodeId, required this.child});

  @override
  ConsumerState<NodeGuideHost> createState() => _NodeGuideHostState();
}

class _NodeGuideHostState extends ConsumerState<NodeGuideHost> {
  bool _showGuide = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_checked || !mounted) return;
    _checked = true;
    final controller = ref.read(nodeGuideControllerProvider);
    if (await controller.shouldShow(widget.nodeId) && mounted) {
      setState(() => _showGuide = true);
    }
  }

  void _dismiss() {
    ref.read(nodeGuideControllerProvider).markSeen(widget.nodeId);
    setState(() => _showGuide = false);
  }

  @override
  Widget build(BuildContext context) {
    final definition = NodeGuideRegistry.forNode(widget.nodeId);
    // Expand to the full available area (Scaffold bodies get loose
    // constraints, so a bare Stack would shrink to the child and the
    // overlay would be clipped to it).
    return SizedBox.expand(
      child: Stack(
        children: [
        widget.child,
        if (_showGuide && definition != null)
          Positioned.fill(
            child: FeatureCoachMark(
              title: definition.title,
              primaryColor: definition.primaryColor,
              titleIcon: definition.titleIcon,
              items: definition.items
                  .map(
                    (i) => CoachItemData(
                      icon: i.icon,
                      title: i.title,
                      body: i.body,
                    ),
                  )
                  .toList(),
              onDismiss: _dismiss,
            ),
          ),
        ],
      ),
    );
  }
}
