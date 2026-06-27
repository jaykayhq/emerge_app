import 'dart:ui' as ui show Gradient, Gradient, Shader;
import 'package:flutter/material.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_data.dart';

/// Body positions computed once per [paint] call for reuse during rendering.
class BodyPositions {
  final Offset headCenter;
  final Offset neckBase;
  final Offset chestCenter;
  final Offset pelvisCenter;
  final Offset leftShoulder;
  final Offset rightShoulder;
  final Offset leftHip;
  final Offset rightHip;
  final Offset leftElbow;
  final Offset leftHand;
  final Offset rightElbow;
  final Offset rightHand;
  final Offset leftKnee;
  final Offset leftFoot;
  final Offset rightKnee;
  final Offset rightFoot;
  final double scale;
  final double headRadius;
  final double torsoWidth;

  BodyPositions._({
    required this.headCenter,
    required this.neckBase,
    required this.chestCenter,
    required this.pelvisCenter,
    required this.leftShoulder,
    required this.rightShoulder,
    required this.leftHip,
    required this.rightHip,
    required this.leftElbow,
    required this.leftHand,
    required this.rightElbow,
    required this.rightHand,
    required this.leftKnee,
    required this.leftFoot,
    required this.rightKnee,
    required this.rightFoot,
    required this.scale,
    required this.headRadius,
    required this.torsoWidth,
  });

  factory BodyPositions.compute(AvatarData data, Size size) {
    final centerX = size.width / 2;
    final scale = size.width / 100;
    final p = data.proportions;

    final headCenter = Offset(centerX, 20 * scale);
    final neckBase = Offset(centerX, 30 * scale);
    final chestCenter = Offset(centerX, 42 * scale);
    final pelvisCenter = Offset(centerX, 70 * scale);
    final torsoWidth = 8 * p.torsoWidth * scale;
    final headRadius = 10 * p.headSize * scale;

    final leftShoulder = Offset(centerX - (10 * p.torsoWidth * scale),
                                chestCenter.dy - 2 * scale);
    final rightShoulder = Offset(centerX + (10 * p.torsoWidth * scale),
                                 chestCenter.dy - 2 * scale);
    final leftHip = Offset(pelvisCenter.dx - (5 * scale), pelvisCenter.dy);
    final rightHip = Offset(pelvisCenter.dx + (5 * scale), pelvisCenter.dy);

    final legLength = 25 * p.legLength * scale;
    final armLength = 20 * p.armLength * scale;

    final leftKnee = Offset(leftHip.dx - (3 * scale) +
                                data.pose.leftLegAngle * 10 * scale,
                            leftHip.dy + legLength / 2);
    final leftFoot = Offset(leftKnee.dx - (1 * scale),
                            leftKnee.dy + legLength / 2);
    final rightKnee = Offset(rightHip.dx + (3 * scale) +
                                 data.pose.rightLegAngle * 10 * scale,
                             rightHip.dy + legLength / 2);
    final rightFoot = Offset(rightKnee.dx + (1 * scale),
                             rightKnee.dy + legLength / 2);

    final leftElbow = Offset(leftShoulder.dx - (5 * scale) +
                                data.pose.leftArmAngle * 8 * scale,
                            leftShoulder.dy + armLength / 2);
    final leftHand = Offset(leftElbow.dx - (3 * scale),
                            leftElbow.dy + armLength / 2);
    final rightElbow = Offset(rightShoulder.dx + (5 * scale) +
                                  data.pose.rightArmAngle * 8 * scale,
                              rightShoulder.dy + armLength / 2);
    final rightHand = Offset(rightElbow.dx + (3 * scale),
                             rightElbow.dy + armLength / 2);

    return BodyPositions._(
      headCenter: headCenter,
      neckBase: neckBase,
      chestCenter: chestCenter,
      pelvisCenter: pelvisCenter,
      leftShoulder: leftShoulder,
      rightShoulder: rightShoulder,
      leftHip: leftHip,
      rightHip: rightHip,
      leftElbow: leftElbow,
      leftHand: leftHand,
      rightElbow: rightElbow,
      rightHand: rightHand,
      leftKnee: leftKnee,
      leftFoot: leftFoot,
      rightKnee: rightKnee,
      rightFoot: rightFoot,
      scale: scale,
      headRadius: headRadius,
      torsoWidth: torsoWidth,
    );
  }
}

/// Draws a capsule-shaped figure using gradient-filled rounded shapes.
///
/// The figure consists of: head (circle), neck (capsule), torso (tapered
/// trapezoid), upper arms (capsules), forearms (capsules), thighs (capsules),
/// shins (capsules), and eyes (small circles). A radial gradient on the head
/// and vertical gradient on the torso simulate 3D lighting.
class ProceduralAvatarPainter extends CustomPainter {
  final AvatarData avatarData;

  ProceduralAvatarPainter({required this.avatarData});

  @override
  void paint(Canvas canvas, Size size) {
    final data = avatarData;
    final colors = data.colors;
    final phase = data.phase;
    final pos = BodyPositions.compute(data, size);

    void drawCapsule(Offset a, Offset b, double radius,
        Color fill, Color outline) {
      final paint = Paint()
        ..color = fill
        ..style = PaintingStyle.fill;
      final path = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(
            a.dx - radius, a.dy,
            b.dx + radius, b.dy,
          ),
          Radius.circular(radius),
        ));
      canvas.drawPath(path, paint);
      final outlinePaint = Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * pos.scale;
      canvas.drawPath(path, outlinePaint);
    }

    // Draw order: back → front

    // 1. Back limbs (darker, behind torso)
    drawCapsule(pos.leftHip, pos.leftKnee, 4 * pos.scale,
        colors.skin.withOpacity(phase.alpha * 0.7),
        colors.outline.withOpacity(phase.alpha));
    drawCapsule(pos.leftKnee, pos.leftFoot, 3.5 * pos.scale,
        colors.skin.withOpacity(phase.alpha * 0.7),
        colors.outline.withOpacity(phase.alpha));

    // 2. Torso (tapered trapezoid with vertical gradient)
    final torsoPath = Path()
      ..moveTo(pos.chestCenter.dx - pos.torsoWidth,
               pos.chestCenter.dy - (8 * pos.scale))
      ..lineTo(pos.chestCenter.dx + pos.torsoWidth,
               pos.chestCenter.dy - (8 * pos.scale))
      ..lineTo(pos.pelvisCenter.dx + pos.torsoWidth * 0.7,
               pos.pelvisCenter.dy)
      ..lineTo(pos.pelvisCenter.dx - pos.torsoWidth * 0.7,
               pos.pelvisCenter.dy)
      ..close();

    final torsoFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.skin.withOpacity(phase.alpha * 0.9),
          colors.skin.withOpacity(phase.alpha * 0.6),
        ],
      ).createShader(Rect.fromLTRB(
        pos.chestCenter.dx - pos.torsoWidth,
        pos.chestCenter.dy - (8 * pos.scale),
        pos.chestCenter.dx + pos.torsoWidth,
        pos.pelvisCenter.dy,
      ));
    canvas.drawPath(torsoPath, torsoFillPaint);

    final torsoOutlinePaint = Paint()
      ..color = colors.outline.withOpacity(phase.alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * pos.scale;
    canvas.drawPath(torsoPath, torsoOutlinePaint);

    // 3. Neck
    drawCapsule(pos.neckBase, pos.chestCenter, 3 * pos.scale,
        colors.skin.withOpacity(phase.alpha),
        colors.outline.withOpacity(phase.alpha));

    // 4. Head (circle with radial gradient for 3D lighting effect)
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [
          colors.skin.withOpacity(phase.alpha * 1.0),
          colors.skin.withOpacity(phase.alpha * 0.7),
        ],
      ).createShader(Rect.fromCircle(
        center: pos.headCenter, radius: pos.headRadius));
    canvas.drawCircle(pos.headCenter, pos.headRadius, headPaint);

    final headOutlinePaint = Paint()
      ..color = colors.outline.withOpacity(phase.alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * pos.scale;
    canvas.drawCircle(pos.headCenter, pos.headRadius, headOutlinePaint);

    // 5. Core glow (incarnate+)
    if (phase.hasCoreGlow) {
      final corePaint = Paint()
        ..color = colors.glow.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos.chestCenter, 6 * pos.scale, corePaint);
    }

    // 6. Front arms
    drawCapsule(pos.leftShoulder, pos.leftElbow, 3.5 * pos.scale,
        colors.skin.withOpacity(phase.alpha),
        colors.outline.withOpacity(phase.alpha));
    drawCapsule(pos.leftElbow, pos.leftHand, 3 * pos.scale,
        colors.skin.withOpacity(phase.alpha),
        colors.outline.withOpacity(phase.alpha));
    drawCapsule(pos.rightShoulder, pos.rightElbow, 3.5 * pos.scale,
        colors.skin.withOpacity(phase.alpha),
        colors.outline.withOpacity(phase.alpha));
    drawCapsule(pos.rightElbow, pos.rightHand, 3 * pos.scale,
        colors.skin.withOpacity(phase.alpha),
        colors.outline.withOpacity(phase.alpha));

    // 7. Eyes
    final eyePaint = Paint()
      ..color = colors.accent.withOpacity(phase.alpha);
    canvas.drawCircle(
      Offset(pos.headCenter.dx - (3 * pos.scale),
             pos.headCenter.dy - (1 * pos.scale)),
      1.5 * pos.scale,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(pos.headCenter.dx + (3 * pos.scale),
             pos.headCenter.dy - (1 * pos.scale)),
      1.5 * pos.scale,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProceduralAvatarPainter oldDelegate) {
    return avatarData != oldDelegate.avatarData;
  }
}
