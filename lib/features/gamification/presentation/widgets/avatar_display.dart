import 'package:emerge_app/features/gamification/domain/models/avatar.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/ready_player_me_avatar.dart';
import 'package:flutter/material.dart';

class AvatarDisplay extends StatelessWidget {
  final Avatar avatar;
  final double size;

  final bool useThumbnail;

  const AvatarDisplay({
    super.key,
    required this.avatar,
    this.size = 200,
    this.useThumbnail = false,
  });

  @override
  Widget build(BuildContext context) {
    if (avatar.modelUrl != null && avatar.modelUrl!.isNotEmpty) {
      final isRpm = avatar.modelUrl!.contains('readyplayer.me');
      // Use 2D render if it's a small display or explicitly requested, and it is a RPM model
      if (isRpm && (useThumbnail || size < 150)) {
        final renderUrl = avatar.modelUrl!
            .replaceAll('.glb', '.png')
            .replaceAll(
              '?frameApi',
              '??scene=fullbody-portrait-v1-transparent',
            );
        return SizedBox(
          width: size,
          height: size,
          child: Image.network(
            renderUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.person, size: size, color: Colors.grey),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              );
            },
          ),
        );
      }

      return ReadyPlayerMeAvatar(
        modelUrl: avatar.modelUrl!,
        height: size,
        width: size,
      );
    }

    // Custom painted avatar fallback when no 3D model exists
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AvatarPainter(
          avatar: avatar,
          skinColor: _getSkinColor(avatar.skinTone),
          hairColor: _getHairColor(avatar.hairColor),
          outfitColor: _getOutfitColor(avatar.outfit),
        ),
      ),
    );
  }

  Color _getSkinColor(AvatarSkinTone tone) {
    switch (tone) {
      case AvatarSkinTone.pale:
        return const Color(0xFFFFE0BD);
      case AvatarSkinTone.fair:
        return const Color(0xFFFFCD94);
      case AvatarSkinTone.tan:
        return const Color(0xFFEAC086);
      case AvatarSkinTone.olive:
        return const Color(0xFFFFAD60);
      case AvatarSkinTone.brown:
        return const Color(0xFF8D5524);
      case AvatarSkinTone.dark:
        return const Color(0xFF3B2219);
    }
  }

  Color _getHairColor(AvatarHairColor color) {
    switch (color) {
      case AvatarHairColor.black:
        return Colors.black;
      case AvatarHairColor.brown:
        return Colors.brown;
      case AvatarHairColor.blonde:
        return Colors.amber.shade200;
      case AvatarHairColor.red:
        return Colors.red.shade900;
      case AvatarHairColor.grey:
        return Colors.grey;
      case AvatarHairColor.white:
        return Colors.white;
      case AvatarHairColor.blue:
        return Colors.blue;
      case AvatarHairColor.pink:
        return Colors.pink;
    }
  }

  Color _getOutfitColor(AvatarOutfit outfit) {
    switch (outfit) {
      case AvatarOutfit.casual:
        return Colors.blueGrey;
      case AvatarOutfit.athletic:
        return Colors.orangeAccent;
      case AvatarOutfit.suit:
        return Colors.black87;
      case AvatarOutfit.armor:
        return Colors.amber;
      case AvatarOutfit.robe:
        return Colors.purple;
    }
  }
}

/// Custom painter for rendering a stylized 2D avatar with improved graphics
class _AvatarPainter extends CustomPainter {
  final Avatar avatar;
  final Color skinColor;
  final Color hairColor;
  final Color outfitColor;

  // Cached paint objects for performance
  late final Paint _skinPaint;
  late final Paint _skinShadowPaint;
  late final Paint _skinHighlightPaint;
  late final Paint _hairPaint;
  late final Paint _hairHighlightPaint;
  late final Paint _outfitPaint;
  late final Paint _outfitShadowPaint;
  late final Paint _outlinePaint;

  _AvatarPainter({
    required this.avatar,
    required this.skinColor,
    required this.hairColor,
    required this.outfitColor,
  }) {
    // Initialize paints once for performance
    _skinPaint = Paint()..color = skinColor;
    _skinShadowPaint = Paint()
      ..color = HSLColor.fromColor(skinColor)
          .withLightness(
            (HSLColor.fromColor(skinColor).lightness - 0.15).clamp(0.0, 1.0),
          )
          .toColor();
    _skinHighlightPaint = Paint()
      ..color = HSLColor.fromColor(skinColor)
          .withLightness(
            (HSLColor.fromColor(skinColor).lightness + 0.1).clamp(0.0, 1.0),
          )
          .toColor();
    _hairPaint = Paint()..color = hairColor;
    _hairHighlightPaint = Paint()
      ..color = HSLColor.fromColor(hairColor)
          .withLightness(
            (HSLColor.fromColor(hairColor).lightness + 0.15).clamp(0.0, 1.0),
          )
          .toColor();
    _outfitPaint = Paint()..color = outfitColor;
    _outfitShadowPaint = Paint()
      ..color = HSLColor.fromColor(outfitColor)
          .withLightness(
            (HSLColor.fromColor(outfitColor).lightness - 0.15).clamp(0.0, 1.0),
          )
          .toColor();
    _outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 200;

    // Adjust outline width based on scale
    _outlinePaint.strokeWidth = (1.5 * scale).clamp(0.5, 3.0);

    // Body dimensions based on type
    final isFeminine = avatar.bodyType == AvatarBodyType.feminine;

    // Draw in order: body -> neck -> head -> hair -> face
    _drawBody(canvas, cx, cy, scale, isFeminine);
    _drawNeck(canvas, cx, cy, scale);
    _drawHead(canvas, cx, cy, scale);
    _drawHair(canvas, cx, cy, scale);
    _drawFace(canvas, cx, cy, scale);
  }

  void _drawBody(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    bool isFeminine,
  ) {
    final shoulderW = (isFeminine ? 48.0 : 58.0) * scale;
    final waistW = (isFeminine ? 32.0 : 44.0) * scale;
    final bodyTop = cy - 5 * scale;
    final bodyBottom = cy + 75 * scale;

    // Main body path with curved shoulders
    final bodyPath = Path();
    bodyPath.moveTo(cx - shoulderW, bodyTop);
    bodyPath.cubicTo(
      cx - shoulderW - 5 * scale,
      bodyTop + 20 * scale,
      cx - waistW - 5 * scale,
      bodyBottom - 20 * scale,
      cx - waistW,
      bodyBottom,
    );
    bodyPath.lineTo(cx + waistW, bodyBottom);
    bodyPath.cubicTo(
      cx + waistW + 5 * scale,
      bodyBottom - 20 * scale,
      cx + shoulderW + 5 * scale,
      bodyTop + 20 * scale,
      cx + shoulderW,
      bodyTop,
    );
    bodyPath.close();

    // Draw body shadow first
    canvas.save();
    canvas.translate(2 * scale, 3 * scale);
    canvas.drawPath(
      bodyPath,
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );
    canvas.restore();

    // Main body
    canvas.drawPath(bodyPath, _outfitPaint);

    // Body shading (left side shadow)
    final shadePath = Path();
    shadePath.moveTo(cx - shoulderW, bodyTop);
    shadePath.cubicTo(
      cx - shoulderW - 5 * scale,
      bodyTop + 20 * scale,
      cx - waistW - 5 * scale,
      bodyBottom - 20 * scale,
      cx - waistW,
      bodyBottom,
    );
    shadePath.lineTo(cx - waistW + 15 * scale, bodyBottom);
    shadePath.lineTo(cx - shoulderW + 15 * scale, bodyTop);
    shadePath.close();
    canvas.drawPath(shadePath, _outfitShadowPaint);

    // Outfit details
    _drawOutfitDetails(canvas, cx, cy, scale);

    // Body outline
    canvas.drawPath(bodyPath, _outlinePaint);
  }

  void _drawOutfitDetails(Canvas canvas, double cx, double cy, double scale) {
    switch (avatar.outfit) {
      case AvatarOutfit.casual:
        // V-neck collar
        final collarPath = Path();
        collarPath.moveTo(cx - 18 * scale, cy - 5 * scale);
        collarPath.quadraticBezierTo(
          cx,
          cy + 15 * scale,
          cx + 18 * scale,
          cy - 5 * scale,
        );
        canvas.drawPath(collarPath, _skinPaint);
        canvas.drawPath(collarPath, _outlinePaint);
        break;

      case AvatarOutfit.athletic:
        // Tank top straps and stripes
        canvas.drawLine(
          Offset(cx - 25 * scale, cy + 5 * scale),
          Offset(cx + 25 * scale, cy + 5 * scale),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.6)
            ..strokeWidth = 5 * scale
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(cx - 20 * scale, cy + 20 * scale),
          Offset(cx + 20 * scale, cy + 20 * scale),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.4)
            ..strokeWidth = 3 * scale
            ..strokeCap = StrokeCap.round,
        );
        // Collar
        final athleticCollar = Path();
        athleticCollar.moveTo(cx - 15 * scale, cy - 5 * scale);
        athleticCollar.quadraticBezierTo(
          cx,
          cy + 8 * scale,
          cx + 15 * scale,
          cy - 5 * scale,
        );
        canvas.drawPath(athleticCollar, _skinPaint);
        break;

      case AvatarOutfit.suit:
        // Suit lapels
        final leftLapel = Path();
        leftLapel.moveTo(cx - 5 * scale, cy - 5 * scale);
        leftLapel.lineTo(cx - 25 * scale, cy + 40 * scale);
        leftLapel.lineTo(cx - 35 * scale, cy + 35 * scale);
        leftLapel.lineTo(cx - 20 * scale, cy - 5 * scale);
        leftLapel.close();
        canvas.drawPath(leftLapel, _outfitShadowPaint);

        final rightLapel = Path();
        rightLapel.moveTo(cx + 5 * scale, cy - 5 * scale);
        rightLapel.lineTo(cx + 25 * scale, cy + 40 * scale);
        rightLapel.lineTo(cx + 35 * scale, cy + 35 * scale);
        rightLapel.lineTo(cx + 20 * scale, cy - 5 * scale);
        rightLapel.close();
        canvas.drawPath(rightLapel, _outfitShadowPaint);

        // White shirt underneath
        final shirtPath = Path();
        shirtPath.moveTo(cx - 12 * scale, cy - 5 * scale);
        shirtPath.lineTo(cx, cy + 10 * scale);
        shirtPath.lineTo(cx + 12 * scale, cy - 5 * scale);
        canvas.drawPath(shirtPath, Paint()..color = Colors.white);

        // Tie
        final tiePath = Path();
        tiePath.moveTo(cx - 6 * scale, cy + 5 * scale);
        tiePath.lineTo(cx + 6 * scale, cy + 5 * scale);
        tiePath.lineTo(cx + 4 * scale, cy + 45 * scale);
        tiePath.lineTo(cx, cy + 50 * scale);
        tiePath.lineTo(cx - 4 * scale, cy + 45 * scale);
        tiePath.close();
        canvas.drawPath(tiePath, Paint()..color = Colors.red.shade700);
        // Tie knot
        canvas.drawCircle(
          Offset(cx, cy + 8 * scale),
          5 * scale,
          Paint()..color = Colors.red.shade800,
        );
        break;

      case AvatarOutfit.armor:
        // Chest plate
        final platePath = Path();
        platePath.addOval(
          Rect.fromCenter(
            center: Offset(cx, cy + 25 * scale),
            width: 50 * scale,
            height: 40 * scale,
          ),
        );
        canvas.drawPath(platePath, Paint()..color = Colors.amber.shade400);
        canvas.drawPath(
          platePath,
          Paint()
            ..color = Colors.amber.shade200
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * scale,
        );
        // Emblem
        canvas.drawCircle(
          Offset(cx, cy + 25 * scale),
          12 * scale,
          Paint()..color = Colors.amber.shade600,
        );
        // Shoulder guards
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx - 40 * scale, cy + 5 * scale),
            width: 20 * scale,
            height: 15 * scale,
          ),
          Paint()..color = Colors.amber.shade300,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx + 40 * scale, cy + 5 * scale),
            width: 20 * scale,
            height: 15 * scale,
          ),
          Paint()..color = Colors.amber.shade300,
        );
        break;

      case AvatarOutfit.robe:
        // Robe folds
        for (var i = 0; i < 3; i++) {
          final foldY = cy + 20 * scale + i * 18 * scale;
          canvas.drawLine(
            Offset(cx - 30 * scale + i * 5 * scale, foldY),
            Offset(cx + 30 * scale - i * 5 * scale, foldY),
            Paint()
              ..color = outfitColor.withValues(alpha: 0.3)
              ..strokeWidth = 2 * scale
              ..strokeCap = StrokeCap.round,
          );
        }
        // Hood opening
        final hoodPath = Path();
        hoodPath.moveTo(cx - 25 * scale, cy - 5 * scale);
        hoodPath.quadraticBezierTo(
          cx,
          cy + 5 * scale,
          cx + 25 * scale,
          cy - 5 * scale,
        );
        canvas.drawPath(hoodPath, _skinPaint);
        // Mystical emblem
        canvas.drawCircle(
          Offset(cx, cy + 30 * scale),
          10 * scale,
          Paint()..color = Colors.amber.withValues(alpha: 0.6),
        );
        break;
    }
  }

  void _drawNeck(Canvas canvas, double cx, double cy, double scale) {
    final neckPath = Path();
    final neckWidth = 18 * scale;
    final neckTop = cy - 35 * scale;
    final neckBottom = cy - 5 * scale;

    neckPath.moveTo(cx - neckWidth / 2, neckTop);
    neckPath.lineTo(cx - neckWidth / 2 - 3 * scale, neckBottom);
    neckPath.lineTo(cx + neckWidth / 2 + 3 * scale, neckBottom);
    neckPath.lineTo(cx + neckWidth / 2, neckTop);
    neckPath.close();

    // Neck shadow
    canvas.save();
    canvas.translate(1 * scale, 2 * scale);
    canvas.drawPath(
      neckPath,
      Paint()..color = Colors.black.withValues(alpha: 0.06),
    );
    canvas.restore();

    canvas.drawPath(neckPath, _skinPaint);
    // Neck shadow on left
    final neckShadePath = Path();
    neckShadePath.moveTo(cx - neckWidth / 2, neckTop);
    neckShadePath.lineTo(cx - neckWidth / 2 - 3 * scale, neckBottom);
    neckShadePath.lineTo(cx - neckWidth / 2 + 5 * scale, neckBottom);
    neckShadePath.lineTo(cx - neckWidth / 2 + 3 * scale, neckTop);
    neckShadePath.close();
    canvas.drawPath(neckShadePath, _skinShadowPaint);
  }

  void _drawHead(Canvas canvas, double cx, double cy, double scale) {
    final headWidth = _getHeadWidth(avatar.faceShape) * scale;
    final headHeight = _getHeadHeight(avatar.faceShape) * scale;
    final headCy = cy - 60 * scale;

    // Head shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 2 * scale, headCy + 3 * scale),
        width: headWidth,
        height: headHeight,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    // Main head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, headCy),
        width: headWidth,
        height: headHeight,
      ),
      _skinPaint,
    );

    // Head shading (left cheek shadow)
    final cheekShadow = Path();
    cheekShadow.addOval(
      Rect.fromCenter(
        center: Offset(cx - headWidth * 0.35, headCy + headHeight * 0.1),
        width: headWidth * 0.25,
        height: headHeight * 0.4,
      ),
    );
    canvas.drawPath(cheekShadow, _skinShadowPaint);

    // Cheek highlight (right side)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + headWidth * 0.25, headCy - headHeight * 0.05),
        width: headWidth * 0.2,
        height: headHeight * 0.15,
      ),
      _skinHighlightPaint,
    );

    // Head outline
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, headCy),
        width: headWidth,
        height: headHeight,
      ),
      _outlinePaint,
    );

    // Ears
    _drawEars(canvas, cx, headCy, headWidth, headHeight, scale);
  }

  void _drawEars(
    Canvas canvas,
    double cx,
    double headCy,
    double headWidth,
    double headHeight,
    double scale,
  ) {
    // Left ear
    final leftEarPath = Path();
    leftEarPath.addOval(
      Rect.fromCenter(
        center: Offset(cx - headWidth * 0.48, headCy),
        width: 12 * scale,
        height: 18 * scale,
      ),
    );
    canvas.drawPath(leftEarPath, _skinPaint);
    canvas.drawPath(leftEarPath, _outlinePaint);
    // Ear inner
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - headWidth * 0.47, headCy),
        width: 6 * scale,
        height: 10 * scale,
      ),
      _skinShadowPaint,
    );

    // Right ear
    final rightEarPath = Path();
    rightEarPath.addOval(
      Rect.fromCenter(
        center: Offset(cx + headWidth * 0.48, headCy),
        width: 12 * scale,
        height: 18 * scale,
      ),
    );
    canvas.drawPath(rightEarPath, _skinPaint);
    canvas.drawPath(rightEarPath, _outlinePaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + headWidth * 0.47, headCy),
        width: 6 * scale,
        height: 10 * scale,
      ),
      _skinShadowPaint,
    );
  }

  void _drawFace(Canvas canvas, double cx, double cy, double scale) {
    final headCy = cy - 60 * scale;
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF2D2D2D);
    final eyebrowPaint = Paint()
      ..color = hairColor.withValues(alpha: 0.8)
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Eyebrows
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - 15 * scale, headCy - 18 * scale),
        width: 18 * scale,
        height: 8 * scale,
      ),
      3.14,
      0.8,
      false,
      eyebrowPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx + 15 * scale, headCy - 18 * scale),
        width: 18 * scale,
        height: 8 * scale,
      ),
      3.14 + 1.4,
      0.8,
      false,
      eyebrowPaint,
    );

    // Eyes - white part
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 15 * scale, headCy - 5 * scale),
        width: 16 * scale,
        height: 14 * scale,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 15 * scale, headCy - 5 * scale),
        width: 16 * scale,
        height: 14 * scale,
      ),
      eyePaint,
    );

    // Eye outlines
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 15 * scale, headCy - 5 * scale),
        width: 16 * scale,
        height: 14 * scale,
      ),
      _outlinePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 15 * scale, headCy - 5 * scale),
        width: 16 * scale,
        height: 14 * scale,
      ),
      _outlinePaint,
    );

    // Pupils
    canvas.drawCircle(
      Offset(cx - 14 * scale, headCy - 4 * scale),
      5 * scale,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(cx + 16 * scale, headCy - 4 * scale),
      5 * scale,
      pupilPaint,
    );

    // Eye highlights
    canvas.drawCircle(
      Offset(cx - 12 * scale, headCy - 6 * scale),
      2 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx + 18 * scale, headCy - 6 * scale),
      2 * scale,
      Paint()..color = Colors.white,
    );

    // Nose
    final nosePath = Path();
    nosePath.moveTo(cx, headCy + 2 * scale);
    nosePath.quadraticBezierTo(
      cx + 4 * scale,
      headCy + 10 * scale,
      cx,
      headCy + 12 * scale,
    );
    canvas.drawPath(
      nosePath,
      Paint()
        ..color = _skinShadowPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Mouth
    final mouthPath = Path();
    mouthPath.moveTo(cx - 10 * scale, headCy + 20 * scale);
    mouthPath.quadraticBezierTo(
      cx,
      headCy + 26 * scale,
      cx + 10 * scale,
      headCy + 20 * scale,
    );
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFFE57373)
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Blush (optional cute detail)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 28 * scale, headCy + 8 * scale),
        width: 12 * scale,
        height: 6 * scale,
      ),
      Paint()..color = Colors.pink.withValues(alpha: 0.2),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 28 * scale, headCy + 8 * scale),
        width: 12 * scale,
        height: 6 * scale,
      ),
      Paint()..color = Colors.pink.withValues(alpha: 0.2),
    );
  }

  void _drawHair(Canvas canvas, double cx, double cy, double scale) {
    final headCy = cy - 60 * scale;
    final headWidth = _getHeadWidth(avatar.faceShape) * scale;
    final headHeight = _getHeadHeight(avatar.faceShape) * scale;

    switch (avatar.hairStyle) {
      case AvatarHairStyle.short:
        // Short styled hair with volume
        final hairPath = Path();
        hairPath.moveTo(cx - headWidth * 0.55, headCy - headHeight * 0.1);
        hairPath.quadraticBezierTo(
          cx - headWidth * 0.6,
          headCy - headHeight * 0.5,
          cx,
          headCy - headHeight * 0.55,
        );
        hairPath.quadraticBezierTo(
          cx + headWidth * 0.6,
          headCy - headHeight * 0.5,
          cx + headWidth * 0.55,
          headCy - headHeight * 0.1,
        );
        hairPath.quadraticBezierTo(
          cx + headWidth * 0.5,
          headCy - headHeight * 0.3,
          cx,
          headCy - headHeight * 0.35,
        );
        hairPath.quadraticBezierTo(
          cx - headWidth * 0.5,
          headCy - headHeight * 0.3,
          cx - headWidth * 0.55,
          headCy - headHeight * 0.1,
        );
        canvas.drawPath(hairPath, _hairPaint);
        // Hair highlight
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx + 5 * scale, headCy - headHeight * 0.4),
            width: 20 * scale,
            height: 10 * scale,
          ),
          3.5,
          1.5,
          false,
          Paint()
            ..color = _hairHighlightPaint.color
            ..strokeWidth = 3 * scale
            ..style = PaintingStyle.stroke,
        );
        break;

      case AvatarHairStyle.long:
        // Long flowing hair
        final longHairPath = Path();
        // Top of hair
        longHairPath.moveTo(cx - headWidth * 0.7, headCy);
        longHairPath.quadraticBezierTo(
          cx - headWidth * 0.75,
          headCy - headHeight * 0.6,
          cx,
          headCy - headHeight * 0.6,
        );
        longHairPath.quadraticBezierTo(
          cx + headWidth * 0.75,
          headCy - headHeight * 0.6,
          cx + headWidth * 0.7,
          headCy,
        );
        // Right side flowing down
        longHairPath.quadraticBezierTo(
          cx + headWidth * 0.8,
          headCy + headHeight * 0.4,
          cx + headWidth * 0.6,
          cy + 40 * scale,
        );
        longHairPath.lineTo(cx + headWidth * 0.3, cy + 45 * scale);
        // Bottom connecting
        longHairPath.lineTo(cx - headWidth * 0.3, cy + 45 * scale);
        // Left side flowing down
        longHairPath.lineTo(cx - headWidth * 0.6, cy + 40 * scale);
        longHairPath.quadraticBezierTo(
          cx - headWidth * 0.8,
          headCy + headHeight * 0.4,
          cx - headWidth * 0.7,
          headCy,
        );
        longHairPath.close();
        canvas.drawPath(longHairPath, _hairPaint);
        // Hair strands/highlights
        for (var i = 0; i < 3; i++) {
          final strandX = cx - 15 * scale + i * 15 * scale;
          canvas.drawLine(
            Offset(strandX, headCy - headHeight * 0.3),
            Offset(strandX + 5 * scale, cy + 20 * scale),
            Paint()
              ..color = _hairHighlightPaint.color
              ..strokeWidth = 2 * scale,
          );
        }
        break;

      case AvatarHairStyle.bald:
        // Just a shine on the head
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx + 5 * scale, headCy - headHeight * 0.35),
            width: 25 * scale,
            height: 12 * scale,
          ),
          3.5,
          1.2,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..strokeWidth = 4 * scale
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
        break;

      case AvatarHairStyle.buzz:
        // Buzz cut - very short textured hair
        final buzzPath = Path();
        buzzPath.addArc(
          Rect.fromCenter(
            center: Offset(cx, headCy - headHeight * 0.15),
            width: headWidth * 1.05,
            height: headHeight * 0.75,
          ),
          3.14,
          3.14,
        );
        canvas.drawPath(buzzPath, _hairPaint);
        // Texture dots
        for (var i = 0; i < 8; i++) {
          final angle = 3.14 + (i / 8) * 3.14;
          final dotX =
              cx +
              (headWidth * 0.4) *
                  (angle - 4.7).abs() /
                  1.6 *
                  (i % 2 == 0 ? 1 : -1);
          final dotY = headCy - headHeight * 0.25 - (i % 3) * 5 * scale;
          canvas.drawCircle(
            Offset(dotX, dotY),
            1.5 * scale,
            _hairHighlightPaint,
          );
        }
        break;

      case AvatarHairStyle.pony:
        // Ponytail style
        // Front hair
        final frontPath = Path();
        frontPath.moveTo(cx - headWidth * 0.55, headCy);
        frontPath.quadraticBezierTo(
          cx - headWidth * 0.6,
          headCy - headHeight * 0.55,
          cx,
          headCy - headHeight * 0.55,
        );
        frontPath.quadraticBezierTo(
          cx + headWidth * 0.6,
          headCy - headHeight * 0.55,
          cx + headWidth * 0.55,
          headCy,
        );
        frontPath.quadraticBezierTo(
          cx + headWidth * 0.4,
          headCy - headHeight * 0.3,
          cx,
          headCy - headHeight * 0.35,
        );
        frontPath.quadraticBezierTo(
          cx - headWidth * 0.4,
          headCy - headHeight * 0.3,
          cx - headWidth * 0.55,
          headCy,
        );
        canvas.drawPath(frontPath, _hairPaint);
        // Ponytail
        final ponyPath = Path();
        ponyPath.moveTo(cx + headWidth * 0.4, headCy - headHeight * 0.2);
        ponyPath.quadraticBezierTo(
          cx + headWidth * 0.8,
          headCy - headHeight * 0.1,
          cx + headWidth * 0.7,
          headCy + headHeight * 0.5,
        );
        ponyPath.quadraticBezierTo(
          cx + headWidth * 0.6,
          headCy + headHeight * 0.7,
          cx + headWidth * 0.4,
          headCy + headHeight * 0.6,
        );
        ponyPath.quadraticBezierTo(
          cx + headWidth * 0.5,
          headCy + headHeight * 0.3,
          cx + headWidth * 0.4,
          headCy - headHeight * 0.2,
        );
        canvas.drawPath(ponyPath, _hairPaint);
        // Hair tie
        canvas.drawCircle(
          Offset(cx + headWidth * 0.45, headCy - headHeight * 0.15),
          5 * scale,
          Paint()..color = Colors.pink.shade300,
        );
        break;

      case AvatarHairStyle.bun:
        // Top bun style
        // Base hair
        final bunBasePath = Path();
        bunBasePath.moveTo(cx - headWidth * 0.55, headCy - headHeight * 0.1);
        bunBasePath.quadraticBezierTo(
          cx - headWidth * 0.6,
          headCy - headHeight * 0.5,
          cx,
          headCy - headHeight * 0.5,
        );
        bunBasePath.quadraticBezierTo(
          cx + headWidth * 0.6,
          headCy - headHeight * 0.5,
          cx + headWidth * 0.55,
          headCy - headHeight * 0.1,
        );
        bunBasePath.quadraticBezierTo(
          cx + headWidth * 0.4,
          headCy - headHeight * 0.25,
          cx,
          headCy - headHeight * 0.3,
        );
        bunBasePath.quadraticBezierTo(
          cx - headWidth * 0.4,
          headCy - headHeight * 0.25,
          cx - headWidth * 0.55,
          headCy - headHeight * 0.1,
        );
        canvas.drawPath(bunBasePath, _hairPaint);
        // The bun
        canvas.drawCircle(
          Offset(cx, headCy - headHeight * 0.65),
          18 * scale,
          _hairPaint,
        );
        canvas.drawCircle(
          Offset(cx + 3 * scale, headCy - headHeight * 0.7),
          5 * scale,
          _hairHighlightPaint,
        );
        // Hair tie
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx, headCy - headHeight * 0.5),
            width: 16 * scale,
            height: 8 * scale,
          ),
          0,
          3.14,
          false,
          Paint()
            ..color = Colors.pink.shade300
            ..strokeWidth = 3 * scale
            ..style = PaintingStyle.stroke,
        );
        break;
    }
  }

  double _getHeadHeight(AvatarFaceShape shape) {
    switch (shape) {
      case AvatarFaceShape.round:
        return 68.0;
      case AvatarFaceShape.oval:
        return 78.0;
      case AvatarFaceShape.square:
        return 62.0;
    }
  }

  double _getHeadWidth(AvatarFaceShape shape) {
    switch (shape) {
      case AvatarFaceShape.round:
        return 64.0;
      case AvatarFaceShape.oval:
        return 56.0;
      case AvatarFaceShape.square:
        return 62.0;
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.avatar != avatar ||
        oldDelegate.skinColor != skinColor ||
        oldDelegate.hairColor != hairColor ||
        oldDelegate.outfitColor != outfitColor;
  }
}
