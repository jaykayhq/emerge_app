import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';
import 'package:emerge_app/features/tutorials/domain/node_guide_registry.dart';
import 'package:emerge_app/features/tutorials/presentation/providers/node_guide_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows a node guide as a full-screen overlay dialog (for surfaces that
/// cannot host a [NodeGuideHost], e.g. the narrator coach sheet).
///
/// No-op (returns immediately) when tutorials are disabled or the node was
/// already seen. Marks the node as seen on dismiss.
class NodeGuideOverlay {
  static Future<void> show(BuildContext context, String nodeId) async {
    final controller = ProviderScope.containerOf(context, listen: false)
        .read(nodeGuideControllerProvider);
    if (!await controller.shouldShow(nodeId)) return;
    final definition = NodeGuideRegistry.forNode(nodeId);
    if (definition == null || !context.mounted) return;

    await showGeneralDialog<void>(
      context: context,
      // Lock the barrier: tapping outside must NOT dismiss the guide, or the
      // node would never be marked seen and the guide would reappear on every
      // coach open. The GOT IT button guarantees markSeen runs.
      barrierDismissible: false,
      barrierLabel: 'Node guide',
      barrierColor: Colors.black54,
      pageBuilder: (_, _, _) => FeatureCoachMark(
        title: definition.title,
        primaryColor: definition.primaryColor,
        titleIcon: definition.titleIcon,
        items: definition.items
            .map(
              (i) => CoachItemData(icon: i.icon, title: i.title, body: i.body),
            )
            .toList(),
        onDismiss: () {
          controller.markSeen(nodeId);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
