import 'package:flutter/material.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_data.dart';
import 'package:emerge_app/features/avatar/presentation/renderers/procedural_avatar_painter.dart';

/// Displays the procedural avatar figure within a fixed-size box.
///
/// Defaults to 60×90 logical pixels (60 wide × 90 tall, matching the
/// 1:1.5 aspect ratio of the stickman). Wrapped in a [RepaintBoundary]
/// so that repainting the avatar doesn't trigger relayout of parent widgets.
class StickmanAvatar extends StatelessWidget {
  final AvatarData avatarData;
  final double size;

  const StickmanAvatar({
    super.key,
    required this.avatarData,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.5,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: ProceduralAvatarPainter(avatarData: avatarData),
        ),
      ),
    );
  }
}
