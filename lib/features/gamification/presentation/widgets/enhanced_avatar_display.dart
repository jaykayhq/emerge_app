import 'package:emerge_app/features/gamification/domain/models/enhanced_avatar.dart';
import 'package:flutter/material.dart';

class EnhancedAvatarDisplay extends StatelessWidget {
  final EnhancedAvatar avatar;
  final double size;
  final bool useThumbnail;
  final bool animate;

  const EnhancedAvatarDisplay({
    super.key,
    required this.avatar,
    this.size = 200,
    this.useThumbnail = false,
    this.animate = false,
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

      // For now, continue using the existing 3D avatar approach
      // In a real implementation, we'd load the 3D model here
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: Colors.grey[600],
        ),
      );
    }

    // Enhanced 2D custom painted avatar
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EnhancedAvatarPainter(
          avatar: avatar,
          skinColor: _getSkinColor(avatar.skinTone),
          hairColor: _getHairColor(avatar.hairColor),
          outfitPrimaryColor: avatar.outfitPrimaryColor,
          outfitSecondaryColor: avatar.outfitSecondaryColor,
          animate: animate,
        ),
      ),
    );
  }

  Color _getSkinColor(EnhancedAvatarSkinTone tone) {
    switch (tone) {
      case EnhancedAvatarSkinTone.pale:
        return const Color(0xFFFFE0BD);
      case EnhancedAvatarSkinTone.fair:
        return const Color(0xFFFFCD94);
      case EnhancedAvatarSkinTone.tan:
        return const Color(0xFFEAC086);
      case EnhancedAvatarSkinTone.olive:
        return const Color(0xFFFFAD60);
      case EnhancedAvatarSkinTone.brown:
        return const Color(0xFF8D5524);
      case EnhancedAvatarSkinTone.dark:
        return const Color(0xFF3B2219);
      case EnhancedAvatarSkinTone.lightBeige:
        return const Color(0xFFF1C27D);
      case EnhancedAvatarSkinTone.mediumBeige:
        return const Color(0xFFE0AC69);
      case EnhancedAvatarSkinTone.darkBeige:
        return const Color(0xFFC68642);
      case EnhancedAvatarSkinTone.lightWarm:
        return const Color(0xFF8D5524);
      case EnhancedAvatarSkinTone.mediumWarm:
        return const Color(0xFF6B4423);
      case EnhancedAvatarSkinTone.darkWarm:
        return const Color(0xFF4D291C);
      case EnhancedAvatarSkinTone.lightCool:
        return const Color(0xFFCA8546);
      case EnhancedAvatarSkinTone.mediumCool:
        return const Color(0xFFA46A29);
      case EnhancedAvatarSkinTone.darkCool:
        return const Color(0xFF704214);
    }
  }

  Color _getHairColor(EnhancedAvatarHairColor color) {
    switch (color) {
      case EnhancedAvatarHairColor.black:
        return Colors.black;
      case EnhancedAvatarHairColor.brown:
        return Colors.brown;
      case EnhancedAvatarHairColor.blonde:
        return Colors.amber.shade200;
      case EnhancedAvatarHairColor.red:
        return Colors.red.shade900;
      case EnhancedAvatarHairColor.grey:
        return Colors.grey;
      case EnhancedAvatarHairColor.white:
        return Colors.white;
      case EnhancedAvatarHairColor.blue:
        return Colors.blue;
      case EnhancedAvatarHairColor.pink:
        return Colors.pink;
      case EnhancedAvatarHairColor.purple:
        return Colors.purple;
      case EnhancedAvatarHairColor.green:
        return Colors.green;
      case EnhancedAvatarHairColor.orange:
        return Colors.orange;
      case EnhancedAvatarHairColor.auburn:
        return Colors.red.shade700;
      case EnhancedAvatarHairColor.chestnut:
        return const Color(0xFFD2691E);
      case EnhancedAvatarHairColor.golden:
        return Colors.amber.shade300;
      case EnhancedAvatarHairColor.silver:
        return Colors.grey.shade300;
      case EnhancedAvatarHairColor.rainbow:
        return Colors.purple; // Will be handled specially in the painter
    }
  }
}

/// Enhanced custom painter for rendering a highly customizable 2D avatar
class _EnhancedAvatarPainter extends CustomPainter {
  final EnhancedAvatar avatar;
  final Color skinColor;
  final Color hairColor;
  final Color outfitPrimaryColor;
  final Color outfitSecondaryColor;
  final bool animate;
  
  // Cached paint objects for performance
  late final Paint _skinPaint;
  late final Paint _skinShadowPaint;
  late final Paint _skinHighlightPaint;
  late final Paint _hairPaint;
  late final Paint _hairHighlightPaint;
  late final Paint _outfitPrimaryPaint;
  late final Paint _outfitSecondaryPaint;
  late final Paint _outfitShadowPaint;
  late final Paint _outlinePaint;

  _EnhancedAvatarPainter({
    required this.avatar,
    required this.skinColor,
    required this.hairColor,
    required this.outfitPrimaryColor,
    required this.outfitSecondaryColor,
    required this.animate,
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
    _outfitPrimaryPaint = Paint()..color = outfitPrimaryColor;
    _outfitSecondaryPaint = Paint()..color = outfitSecondaryColor;
    _outfitShadowPaint = Paint()
      ..color = HSLColor.fromColor(outfitPrimaryColor)
          .withLightness(
            (HSLColor.fromColor(outfitPrimaryColor).lightness - 0.15).clamp(0.0, 1.0),
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

    // Apply pose transformation
    _applyPoseTransform(canvas, cx, cy, scale);

    // Body dimensions based on type and scale
    final isFeminine = avatar.bodyType == EnhancedAvatarBodyType.feminine;
    final isChild = avatar.bodyType == EnhancedAvatarBodyType.child;
    final isHeavyset = avatar.bodyType == EnhancedAvatarBodyType.heavyset;
    final isAthletic = avatar.bodyType == EnhancedAvatarBodyType.athletic;
    final isThin = avatar.bodyType == EnhancedAvatarBodyType.thin;

    // Draw in order: body -> neck -> head -> hair -> face -> accessories
    _drawBody(canvas, cx, cy, scale, isFeminine, isChild, isHeavyset, isAthletic, isThin);
    _drawNeck(canvas, cx, cy, scale);
    _drawHead(canvas, cx, cy, scale);
    _drawHair(canvas, cx, cy, scale);
    _drawFace(canvas, cx, cy, scale);
    _drawAccessories(canvas, cx, cy, scale);
  }

  void _applyPoseTransform(Canvas canvas, double cx, double cy, double scale) {
    // Apply transformations based on pose
    switch (avatar.pose) {
      case AvatarPose.sitting:
        canvas.translate(0, 20 * scale);
        break;
      case AvatarPose.walking:
        // Slight forward lean and offset
        canvas.translate(-5 * scale, 0);
        break;
      case AvatarPose.running:
        canvas.translate(-10 * scale, 0);
        break;
      case AvatarPose.dancing:
        // Slight rotation
        canvas.rotate(0.1);
        break;
      case AvatarPose.waving:
        // Could add animation here
        break;
      case AvatarPose.thumbsUp:
        // Could add gesture here
        break;
      case AvatarPose.superhero:
        // Raised arms pose
        break;
      case AvatarPose.standing:
        // No transformation for standing
        break;
    }
  }

  void _drawBody(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    bool isFeminine,
    bool isChild,
    bool isHeavyset,
    bool isAthletic,
    bool isThin,
  ) {
    // Base dimensions
    var shoulderW = (isFeminine ? 48.0 : 58.0) * scale;
    var waistW = (isFeminine ? 32.0 : 44.0) * scale;
    var bodyH = 75.0 * scale;
    
    // Apply body type modifications
    if (isChild) {
      shoulderW *= 0.7;
      waistW *= 0.7;
      bodyH *= 0.7;
    } else if (isHeavyset) {
      shoulderW *= 1.4;
      waistW *= 1.6;
    } else if (isAthletic) {
      shoulderW *= 1.2;
      waistW *= 0.8; // More defined waist
    } else if (isThin) {
      shoulderW *= 0.8;
      waistW *= 0.8;
    }
    
    // Apply body scale
    shoulderW *= avatar.bodyScale;
    waistW *= avatar.bodyScale;
    bodyH *= avatar.bodyScale;
    
    // Position adjustments based on limb scale
    final bodyTop = cy - (5 * scale);
    final bodyBottom = cy + bodyH;

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

    // Main body with outfit color
    canvas.drawPath(bodyPath, _outfitPrimaryPaint);

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

    // Outfit details based on outfit type
    _drawOutfitDetails(canvas, cx, cy, scale, bodyTop, bodyBottom);

    // Body outline
    canvas.drawPath(bodyPath, _outlinePaint);
  }

  void _drawOutfitDetails(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    double bodyTop,
    double bodyBottom,
  ) {
    switch (avatar.outfit) {
      case EnhancedAvatarOutfit.casual:
        // V-neck collar
        final collarPath = Path();
        collarPath.moveTo(cx - 18 * scale, bodyTop);
        collarPath.quadraticBezierTo(
          cx,
          bodyTop + 20 * scale,
          cx + 18 * scale,
          bodyTop,
        );
        canvas.drawPath(collarPath, _skinPaint);
        canvas.drawPath(collarPath, _outlinePaint);
        // Pockets
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx - 15 * scale, cy + 20 * scale),
            width: 20 * scale,
            height: 15 * scale,
          ),
          Paint()
            ..color = _outfitSecondaryPaint.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1 * scale,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx + 15 * scale, cy + 20 * scale),
            width: 20 * scale,
            height: 15 * scale,
          ),
          Paint()
            ..color = _outfitSecondaryPaint.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1 * scale,
        );
        break;

      case EnhancedAvatarOutfit.athletic:
        // Tank top straps and stripes
        canvas.drawLine(
          Offset(cx - 25 * scale, bodyTop + 10 * scale),
          Offset(cx + 25 * scale, bodyTop + 10 * scale),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.6)
            ..strokeWidth = 5 * scale
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(cx - 20 * scale, bodyTop + 25 * scale),
          Offset(cx + 20 * scale, bodyTop + 25 * scale),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.4)
            ..strokeWidth = 3 * scale
            ..strokeCap = StrokeCap.round,
        );
        // Collar
        final athleticCollar = Path();
        athleticCollar.moveTo(cx - 15 * scale, bodyTop);
        athleticCollar.quadraticBezierTo(
          cx,
          bodyTop + 15 * scale,
          cx + 15 * scale,
          bodyTop,
        );
        canvas.drawPath(athleticCollar, _skinPaint);
        break;

      case EnhancedAvatarOutfit.suit:
        // Suit lapels
        final leftLapel = Path();
        leftLapel.moveTo(cx - 5 * scale, bodyTop);
        leftLapel.lineTo(cx - 25 * scale, bodyTop + 45 * scale);
        leftLapel.lineTo(cx - 35 * scale, bodyTop + 40 * scale);
        leftLapel.lineTo(cx - 20 * scale, bodyTop);
        leftLapel.close();
        canvas.drawPath(leftLapel, _outfitSecondaryPaint);

        final rightLapel = Path();
        rightLapel.moveTo(cx + 5 * scale, bodyTop);
        rightLapel.lineTo(cx + 25 * scale, bodyTop + 45 * scale);
        rightLapel.lineTo(cx + 35 * scale, bodyTop + 40 * scale);
        rightLapel.lineTo(cx + 20 * scale, bodyTop);
        rightLapel.close();
        canvas.drawPath(rightLapel, _outfitSecondaryPaint);

        // White shirt underneath
        final shirtPath = Path();
        shirtPath.moveTo(cx - 12 * scale, bodyTop);
        shirtPath.lineTo(cx, bodyTop + 15 * scale);
        shirtPath.lineTo(cx + 12 * scale, bodyTop);
        canvas.drawPath(shirtPath, Paint()..color = Colors.white);

        // Tie
        final tiePath = Path();
        tiePath.moveTo(cx - 6 * scale, bodyTop + 10 * scale);
        tiePath.lineTo(cx + 6 * scale, bodyTop + 10 * scale);
        tiePath.lineTo(cx + 4 * scale, bodyTop + 50 * scale);
        tiePath.lineTo(cx, bodyTop + 55 * scale);
        tiePath.lineTo(cx - 4 * scale, bodyTop + 50 * scale);
        tiePath.close();
        canvas.drawPath(tiePath, Paint()..color = Colors.red.shade700);
        // Tie knot
        canvas.drawCircle(
          Offset(cx, bodyTop + 13 * scale),
          5 * scale,
          Paint()..color = Colors.red.shade800,
        );
        break;

      case EnhancedAvatarOutfit.armor:
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

      case EnhancedAvatarOutfit.robe:
        // Robe folds
        for (var i = 0; i < 3; i++) {
          final foldY = bodyTop + 25 * scale + i * 18 * scale;
          canvas.drawLine(
            Offset(cx - 30 * scale + i * 5 * scale, foldY),
            Offset(cx + 30 * scale - i * 5 * scale, foldY),
            Paint()
              ..color = _outfitPrimaryPaint.color.withValues(alpha: 0.3)
              ..strokeWidth = 2 * scale
              ..strokeCap = StrokeCap.round,
          );
        }
        // Hood opening
        final hoodPath = Path();
        hoodPath.moveTo(cx - 25 * scale, bodyTop);
        hoodPath.quadraticBezierTo(
          cx,
          bodyTop + 10 * scale,
          cx + 25 * scale,
          bodyTop,
        );
        canvas.drawPath(hoodPath, _skinPaint);
        // Mystical emblem
        canvas.drawCircle(
          Offset(cx, cy + 30 * scale),
          10 * scale,
          Paint()..color = Colors.amber.withValues(alpha: 0.6),
        );
        break;

      case EnhancedAvatarOutfit.formal:
        // Formal dress with defined waist
        final dressPath = Path();
        dressPath.moveTo(cx - 35 * scale, bodyTop);
        dressPath.lineTo(cx - 30 * scale, bodyBottom);
        dressPath.lineTo(cx + 30 * scale, bodyBottom);
        dressPath.lineTo(cx + 35 * scale, bodyTop);
        dressPath.close();
        canvas.drawPath(dressPath, _outfitPrimaryPaint);
        // Waist detail
        canvas.drawLine(
          Offset(cx - 25 * scale, cy + 5 * scale),
          Offset(cx + 25 * scale, cy + 5 * scale),
          Paint()
            ..color = _outfitSecondaryPaint.color
            ..strokeWidth = 3 * scale,
        );
        break;

      case EnhancedAvatarOutfit.business:
        // Business blazer
        final blazerPath = Path();
        blazerPath.moveTo(cx - 30 * scale, bodyTop);
        blazerPath.lineTo(cx - 25 * scale, bodyBottom - 10 * scale);
        blazerPath.lineTo(cx - 30 * scale, bodyBottom);
        blazerPath.lineTo(cx + 30 * scale, bodyBottom);
        blazerPath.lineTo(cx + 25 * scale, bodyBottom - 10 * scale);
        blazerPath.lineTo(cx + 30 * scale, bodyTop);
        blazerPath.close();
        canvas.drawPath(blazerPath, _outfitPrimaryPaint);
        
        // Lapels
        final leftBlazerLapel = Path();
        leftBlazerLapel.moveTo(cx, bodyTop + 5 * scale);
        leftBlazerLapel.lineTo(cx - 25 * scale, cy + 10 * scale);
        leftBlazerLapel.lineTo(cx - 30 * scale, bodyTop + 5 * scale);
        canvas.drawPath(leftBlazerLapel, _outfitSecondaryPaint);
        
        final rightBlazerLapel = Path();
        rightBlazerLapel.moveTo(cx, bodyTop + 5 * scale);
        rightBlazerLapel.lineTo(cx + 25 * scale, cy + 10 * scale);
        rightBlazerLapel.lineTo(cx + 30 * scale, bodyTop + 5 * scale);
        canvas.drawPath(rightBlazerLapel, _outfitSecondaryPaint);
        break;

      case EnhancedAvatarOutfit.beach:
        // Beach outfit - tank top and shorts
        // Top
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy - 10 * scale),
            width: 45 * scale,
            height: 25 * scale,
          ),
          _outfitPrimaryPaint,
        );
        // Shorts
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy + 40 * scale),
            width: 50 * scale,
            height: 20 * scale,
          ),
          _outfitSecondaryPaint,
        );
        break;

      case EnhancedAvatarOutfit.winter:
        // Winter coat with collar
        final coatPath = Path();
        coatPath.moveTo(cx - 40 * scale, bodyTop);
        coatPath.lineTo(cx - 30 * scale, bodyBottom);
        coatPath.lineTo(cx + 30 * scale, bodyBottom);
        coatPath.lineTo(cx + 40 * scale, bodyTop);
        coatPath.close();
        canvas.drawPath(coatPath, _outfitPrimaryPaint);
        
        // Collar
        final leftCollar = Path();
        leftCollar.moveTo(cx, bodyTop + 5 * scale);
        leftCollar.lineTo(cx - 35 * scale, bodyTop + 15 * scale);
        leftCollar.lineTo(cx - 25 * scale, bodyTop);
        canvas.drawPath(leftCollar, _outfitSecondaryPaint);
        
        final rightCollar = Path();
        rightCollar.moveTo(cx, bodyTop + 5 * scale);
        rightCollar.lineTo(cx + 35 * scale, bodyTop + 15 * scale);
        rightCollar.lineTo(cx + 25 * scale, bodyTop);
        canvas.drawPath(rightCollar, _outfitSecondaryPaint);
        
        // Buttons
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(cx, cy - 10 * scale + i * 20 * scale),
            3 * scale,
            Paint()..color = Colors.white,
          );
        }
        break;

      case EnhancedAvatarOutfit.summer:
        // Summer dress with floral pattern
        final summerDress = Path();
        summerDress.moveTo(cx - 25 * scale, bodyTop + 15 * scale);
        summerDress.lineTo(cx, bodyTop);
        summerDress.lineTo(cx + 25 * scale, bodyTop + 15 * scale);
        summerDress.lineTo(cx + 35 * scale, bodyBottom);
        summerDress.lineTo(cx - 35 * scale, bodyBottom);
        summerDress.close();
        canvas.drawPath(summerDress, _outfitPrimaryPaint);
        
        // Floral details
        for (int i = 0; i < 4; i++) {
          for (int j = 0; j < 2; j++) {
            canvas.drawCircle(
              Offset(cx - 15 * scale + i * 10 * scale, cy - 10 * scale + j * 20 * scale),
              2 * scale,
              _outfitSecondaryPaint,
            );
          }
        }
        break;

      case EnhancedAvatarOutfit.fantasy:
        // Fantasy outfit with ornate details
        final fantasyTop = Path();
        fantasyTop.moveTo(cx - 35 * scale, bodyTop);
        fantasyTop.lineTo(cx - 30 * scale, cy - 5 * scale);
        fantasyTop.lineTo(cx - 35 * scale, cy + 10 * scale);
        fantasyTop.lineTo(cx + 35 * scale, cy + 10 * scale);
        fantasyTop.lineTo(cx + 30 * scale, cy - 5 * scale);
        fantasyTop.lineTo(cx + 35 * scale, bodyTop);
        fantasyTop.close();
        canvas.drawPath(fantasyTop, _outfitPrimaryPaint);
        
        // Ornate patterns
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(cx - 20 * scale + i * 20 * scale, cy - 10 * scale),
            4 * scale,
            _outfitSecondaryPaint,
          );
        }
        break;

      case EnhancedAvatarOutfit.sciFi:
        // Sci-fi outfit with geometric patterns
        final sciFiTop = Path();
        sciFiTop.moveTo(cx - 30 * scale, bodyTop);
        sciFiTop.lineTo(cx - 25 * scale, bodyBottom - 20 * scale);
        sciFiTop.lineTo(cx, bodyBottom);
        sciFiTop.lineTo(cx + 25 * scale, bodyBottom - 20 * scale);
        sciFiTop.lineTo(cx + 30 * scale, bodyTop);
        sciFiTop.close();
        canvas.drawPath(sciFiTop, _outfitPrimaryPaint);
        
        // Tech patterns
        final techPath = Path();
        techPath.moveTo(cx - 10 * scale, cy - 10 * scale);
        techPath.lineTo(cx - 5 * scale, cy - 5 * scale);
        techPath.lineTo(cx, cy - 10 * scale);
        techPath.lineTo(cx + 5 * scale, cy - 5 * scale);
        techPath.lineTo(cx + 10 * scale, cy - 10 * scale);
        canvas.drawPath(techPath, Paint()
          ..color = Colors.blue.shade300
          ..strokeWidth = 2 * scale
          ..style = PaintingStyle.stroke);
        break;

      case EnhancedAvatarOutfit.medieval:
        // Medieval outfit with tunic style
        final medievalTop = Path();
        medievalTop.moveTo(cx - 30 * scale, bodyTop);
        medievalTop.lineTo(cx - 25 * scale, bodyBottom);
        medievalTop.lineTo(cx + 25 * scale, bodyBottom);
        medievalTop.lineTo(cx + 30 * scale, bodyTop);
        medievalTop.close();
        canvas.drawPath(medievalTop, _outfitPrimaryPaint);
        
        // Belt
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy + 10 * scale),
            width: 50 * scale,
            height: 8 * scale,
          ),
          _outfitSecondaryPaint,
        );
        break;
    }
  }

  void _drawNeck(Canvas canvas, double cx, double cy, double scale) {
    final neckWidth = 18 * scale * avatar.bodyScale;
    final neckTop = cy - 35 * scale * avatar.headScale;
    final neckBottom = cy - 5 * scale * avatar.headScale;

    // Adjust for proportional differences
    final neckPath = Path();
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
    // Apply head scale and calculate head dimensions
    final headWidth = _getHeadWidth(avatar.faceShape) * scale * avatar.headScale;
    final headHeight = _getHeadHeight(avatar.faceShape) * scale * avatar.headScale;
    final headCy = cy - 60 * scale * avatar.headScale;

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
    final headCy = cy - 60 * scale * avatar.headScale;
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.fill;
    final eyebrowPaint = Paint()
      ..color = hairColor.withValues(alpha: 0.8)
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Eyebrows - style based on expression
    switch (avatar.expression) {
      case AvatarExpression.angry:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx - 15 * scale, headCy - 18 * scale),
            width: 18 * scale,
            height: 8 * scale,
          ),
          3.14 + 0.2,
          1.0,
          false,
          eyebrowPaint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx + 15 * scale, headCy - 18 * scale),
            width: 18 * scale,
            height: 8 * scale,
          ),
          3.14 + 1.2,
          1.0,
          false,
          eyebrowPaint,
        );
        break;
      case AvatarExpression.surprised:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx - 15 * scale, headCy - 20 * scale),
            width: 18 * scale,
            height: 10 * scale,
          ),
          0,
          3.14,
          false,
          eyebrowPaint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx + 15 * scale, headCy - 20 * scale),
            width: 18 * scale,
            height: 10 * scale,
          ),
          0,
          3.14,
          false,
          eyebrowPaint,
        );
        break;
      case AvatarExpression.happy:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx - 15 * scale, headCy - 15 * scale),
            width: 18 * scale,
            height: 8 * scale,
          ),
          0,
          3.14,
          false,
          eyebrowPaint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx + 15 * scale, headCy - 15 * scale),
            width: 18 * scale,
            height: 8 * scale,
          ),
          0,
          3.14,
          false,
          eyebrowPaint,
        );
        break;
      default:
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
    }

    // Eyes - style based on expression
    switch (avatar.expression) {
      case AvatarExpression.winking:
        // Left eye is normal, right eye is winking (horizontal line)
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx - 15 * scale, headCy - 5 * scale),
            width: 16 * scale,
            height: 14 * scale,
          ),
          eyePaint,
        );
        // Right eye is a line
        canvas.drawLine(
          Offset(cx + 10 * scale, headCy - 5 * scale),
          Offset(cx + 20 * scale, headCy - 5 * scale),
          Paint()
            ..color = const Color(0xFF2D2D2D)
            ..strokeWidth = 2 * scale
            ..strokeCap = StrokeCap.round,
        );
        break;
      case AvatarExpression.surprised:
        // Both eyes are wide open
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx - 15 * scale, headCy - 5 * scale),
            width: 18 * scale,
            height: 18 * scale,
          ),
          eyePaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx + 15 * scale, headCy - 5 * scale),
            width: 18 * scale,
            height: 18 * scale,
          ),
          eyePaint,
        );
        break;
      default:
        // Normal eyes
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
    }

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

    // Pupils - position based on expression
    switch (avatar.expression) {
      case AvatarExpression.surprised:
        // Larger pupils
        canvas.drawCircle(
          Offset(cx - 14 * scale, headCy - 4 * scale),
          6 * scale,
          pupilPaint,
        );
        canvas.drawCircle(
          Offset(cx + 16 * scale, headCy - 4 * scale),
          6 * scale,
          pupilPaint,
        );
        break;
      default:
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
    }

    // Eye highlights - vary by expression
    switch (avatar.expression) {
      case AvatarExpression.happy:
        canvas.drawCircle(
          Offset(cx - 12 * scale, headCy - 7 * scale),
          2.5 * scale,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(cx + 18 * scale, headCy - 7 * scale),
          2.5 * scale,
          Paint()..color = Colors.white,
        );
        break;
      case AvatarExpression.surprised:
        canvas.drawCircle(
          Offset(cx - 11 * scale, headCy - 7 * scale),
          3 * scale,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(cx + 19 * scale, headCy - 7 * scale),
          3 * scale,
          Paint()..color = Colors.white,
        );
        break;
      default:
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
    }

    // Nose - style based on face shape
    final nosePath = Path();
    switch (avatar.faceShape) {
      case EnhancedAvatarFaceShape.heart:
        // Delicate nose
        nosePath.moveTo(cx, headCy + 2 * scale);
        nosePath.quadraticBezierTo(
          cx + 2 * scale,
          headCy + 8 * scale,
          cx,
          headCy + 10 * scale,
        );
        break;
      case EnhancedAvatarFaceShape.diamond:
        // More defined nose
        nosePath.moveTo(cx, headCy + 1 * scale);
        nosePath.quadraticBezierTo(
          cx + 3 * scale,
          headCy + 12 * scale,
          cx,
          headCy + 14 * scale,
        );
        break;
      default:
        // Default nose
        nosePath.moveTo(cx, headCy + 2 * scale);
        nosePath.quadraticBezierTo(
          cx + 4 * scale,
          headCy + 10 * scale,
          cx,
          headCy + 12 * scale,
        );
    }
    canvas.drawPath(
      nosePath,
      Paint()
        ..color = _skinShadowPaint.color
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Mouth - style based on expression
    final mouthPath = Path();
    switch (avatar.expression) {
      case AvatarExpression.happy:
        // Bigger smile
        mouthPath.moveTo(cx - 12 * scale, headCy + 22 * scale);
        mouthPath.quadraticBezierTo(
          cx,
          headCy + 30 * scale,
          cx + 12 * scale,
          headCy + 22 * scale,
        );
        break;
      case AvatarExpression.sad:
        // Frown
        mouthPath.moveTo(cx - 12 * scale, headCy + 25 * scale);
        mouthPath.quadraticBezierTo(
          cx,
          headCy + 20 * scale,
          cx + 12 * scale,
          headCy + 25 * scale,
        );
        break;
      case AvatarExpression.surprised:
        // Open mouth (circle)
        canvas.drawCircle(
          Offset(cx, headCy + 24 * scale),
          6 * scale,
          Paint()
            ..color = const Color(0xFFE57373)
            ..style = PaintingStyle.fill,
        );
        return; // Skip the normal mouth drawing
      case AvatarExpression.angry:
        // Thin, tight mouth
        canvas.drawLine(
          Offset(cx - 10 * scale, headCy + 24 * scale),
          Offset(cx + 10 * scale, headCy + 24 * scale),
          Paint()
            ..color = const Color(0xFFE57373)
            ..strokeWidth = 3 * scale
            ..strokeCap = StrokeCap.round,
        );
        return; // Skip the normal mouth drawing
      case AvatarExpression.winking:
        // Slightly smiling mouth
        mouthPath.moveTo(cx - 10 * scale, headCy + 22 * scale);
        mouthPath.quadraticBezierTo(
          cx,
          headCy + 26 * scale,
          cx + 10 * scale,
          headCy + 22 * scale,
        );
        break;
      case AvatarExpression.laughing:
        // Big smile
        mouthPath.moveTo(cx - 14 * scale, headCy + 20 * scale);
        mouthPath.quadraticBezierTo(
          cx,
          headCy + 35 * scale,
          cx + 14 * scale,
          headCy + 20 * scale,
        );
        break;
      case AvatarExpression.tongueOut:
        // Smiling mouth with tongue
        mouthPath.moveTo(cx - 12 * scale, headCy + 22 * scale);
        mouthPath.quadraticBezierTo(
          cx,
          headCy + 30 * scale,
          cx + 12 * scale,
          headCy + 22 * scale,
        );
        // Tongue
        canvas.drawCircle(
          Offset(cx, headCy + 28 * scale),
          4 * scale,
          Paint()..color = const Color(0xFFE57373),
        );
        break;
      default:
        // Neutral expression
        mouthPath.moveTo(cx - 10 * scale, headCy + 20 * scale);
        mouthPath.quadraticBezierTo(
          cx,
          headCy + 26 * scale,
          cx + 10 * scale,
          headCy + 20 * scale,
        );
    }
    
    if (!avatar.expression.toString().contains('angry') && 
        !avatar.expression.toString().contains('surprised')) {
      canvas.drawPath(
        mouthPath,
        Paint()
          ..color = const Color(0xFFE57373)
          ..strokeWidth = 3 * scale
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    // Blush (optional cute detail)
    if (avatar.expression == AvatarExpression.happy || 
        avatar.expression == AvatarExpression.surprised) {
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
  }

  void _drawHair(Canvas canvas, double cx, double cy, double scale) {
    final headCy = cy - 60 * scale * avatar.headScale;
    final headWidth = _getHeadWidth(avatar.faceShape) * scale * avatar.headScale;
    final headHeight = _getHeadHeight(avatar.faceShape) * scale * avatar.headScale;

    // Apply hair length factor to all hair styles
    final lengthFactor = avatar.hairLength;
    
    switch (avatar.hairStyle) {
      case EnhancedAvatarHairStyle.short:
        // Short styled hair with volume
        final hairPath = Path();
        hairPath.moveTo(cx - headWidth * 0.55, headCy - headHeight * 0.1);
        hairPath.quadraticBezierTo(
          cx - headWidth * 0.6,
          headCy - headHeight * 0.5 * lengthFactor,
          cx,
          headCy - headHeight * 0.55 * lengthFactor,
        );
        hairPath.quadraticBezierTo(
          cx + headWidth * 0.6,
          headCy - headHeight * 0.5 * lengthFactor,
          cx + headWidth * 0.55,
          headCy - headHeight * 0.1,
        );
        hairPath.quadraticBezierTo(
          cx + headWidth * 0.5,
          headCy - headHeight * 0.3 * lengthFactor,
          cx,
          headCy - headHeight * 0.35 * lengthFactor,
        );
        hairPath.quadraticBezierTo(
          cx - headWidth * 0.5,
          headCy - headHeight * 0.3 * lengthFactor,
          cx - headWidth * 0.55,
          headCy - headHeight * 0.1,
        );
        canvas.drawPath(hairPath, _hairPaint);
        // Hair highlight
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx + 5 * scale, headCy - headHeight * 0.4 * lengthFactor),
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

      case EnhancedAvatarHairStyle.long:
        // Long flowing hair
        final longHairPath = Path();
        // Top of hair
        longHairPath.moveTo(cx - headWidth * 0.7, headCy);
        longHairPath.quadraticBezierTo(
          cx - headWidth * 0.75,
          headCy - headHeight * 0.6 * lengthFactor,
          cx,
          headCy - headHeight * 0.6 * lengthFactor,
        );
        longHairPath.quadraticBezierTo(
          cx + headWidth * 0.75,
          headCy - headHeight * 0.6 * lengthFactor,
          cx + headWidth * 0.7,
          headCy,
        );
        // Right side flowing down
        longHairPath.quadraticBezierTo(
          cx + headWidth * 0.8,
          headCy + headHeight * 0.4 * lengthFactor,
          cx + headWidth * 0.6,
          cy + 40 * scale * lengthFactor,
        );
        longHairPath.lineTo(cx + headWidth * 0.3, cy + 45 * scale * lengthFactor);
        // Bottom connecting
        longHairPath.lineTo(cx - headWidth * 0.3, cy + 45 * scale * lengthFactor);
        // Left side flowing down
        longHairPath.lineTo(cx - headWidth * 0.6, cy + 40 * scale * lengthFactor);
        longHairPath.quadraticBezierTo(
          cx - headWidth * 0.8,
          headCy + headHeight * 0.4 * lengthFactor,
          cx - headWidth * 0.7,
          headCy,
        );
        longHairPath.close();
        canvas.drawPath(longHairPath, _hairPaint);
        // Hair strands/highlights
        for (var i = 0; i < 3; i++) {
          final strandX = cx - 15 * scale + i * 15 * scale;
          canvas.drawLine(
            Offset(strandX, headCy - headHeight * 0.3 * lengthFactor),
            Offset(strandX + 5 * scale, cy + 20 * scale * lengthFactor),
            Paint()
              ..color = _hairHighlightPaint.color
              ..strokeWidth = 2 * scale,
          );
        }
        break;

      case EnhancedAvatarHairStyle.bald:
        // Just a shine on the head
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx + 5 * scale, headCy - headHeight * 0.35 * lengthFactor),
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

      case EnhancedAvatarHairStyle.buzz:
        // Buzz cut - very short textured hair
        final buzzPath = Path();
        buzzPath.addArc(
          Rect.fromCenter(
            center: Offset(cx, headCy - headHeight * 0.15 * lengthFactor),
            width: headWidth * 1.05,
            height: headHeight * 0.75 * lengthFactor,
          ),
          3.14,
          3.14,
        );
        canvas.drawPath(buzzPath, _hairPaint);
        // Texture dots
        for (var i = 0; i < 8; i++) {
          final angle = 3.14 + (i / 8) * 3.14;
          final dotX = cx + (headWidth * 0.4) * (angle - 4.7).abs() / 1.6 * (i % 2 == 0 ? 1 : -1);
          final dotY = headCy - headHeight * 0.25 * lengthFactor - (i % 3) * 5 * scale;
          canvas.drawCircle(
            Offset(dotX, dotY),
            1.5 * scale,
            _hairHighlightPaint,
          );
        }
        break;

      case EnhancedAvatarHairStyle.pony:
        // Ponytail style
        // Front hair
        final frontPath = Path();
        frontPath.moveTo(cx - headWidth * 0.55, headCy);
        frontPath.quadraticBezierTo(
          cx - headWidth * 0.6,
          headCy - headHeight * 0.55 * lengthFactor,
          cx,
          headCy - headHeight * 0.55 * lengthFactor,
        );
        frontPath.quadraticBezierTo(
          cx + headWidth * 0.6,
          headCy - headHeight * 0.55 * lengthFactor,
          cx + headWidth * 0.55,
          headCy,
        );
        frontPath.quadraticBezierTo(
          cx + headWidth * 0.4,
          headCy - headHeight * 0.3 * lengthFactor,
          cx,
          headCy - headHeight * 0.35 * lengthFactor,
        );
        frontPath.quadraticBezierTo(
          cx - headWidth * 0.4,
          headCy - headHeight * 0.3 * lengthFactor,
          cx - headWidth * 0.55,
          headCy,
        );
        canvas.drawPath(frontPath, _hairPaint);
        // Ponytail
        final ponyPath = Path();
        ponyPath.moveTo(cx + headWidth * 0.4, headCy - headHeight * 0.2 * lengthFactor);
        ponyPath.quadraticBezierTo(
          cx + headWidth * 0.8,
          headCy - headHeight * 0.1 * lengthFactor + 10 * scale * lengthFactor,
          cx + headWidth * 0.7,
          headCy + headHeight * 0.5 * lengthFactor,
        );
        ponyPath.quadraticBezierTo(
          cx + headWidth * 0.6,
          headCy + headHeight * 0.7 * lengthFactor,
          cx + headWidth * 0.4,
          headCy + headHeight * 0.6 * lengthFactor,
        );
        ponyPath.quadraticBezierTo(
          cx + headWidth * 0.5,
          headCy + headHeight * 0.3 * lengthFactor,
          cx + headWidth * 0.4,
          headCy - headHeight * 0.2 * lengthFactor,
        );
        canvas.drawPath(ponyPath, _hairPaint);
        // Hair tie
        canvas.drawCircle(
          Offset(cx + headWidth * 0.45, headCy - headHeight * 0.15 * lengthFactor),
          5 * scale,
          Paint()..color = Colors.pink.shade300,
        );
        break;

      case EnhancedAvatarHairStyle.bun:
        // Top bun style
        // Base hair
        final bunBasePath = Path();
        bunBasePath.moveTo(cx - headWidth * 0.55, headCy - headHeight * 0.1);
        bunBasePath.quadraticBezierTo(
          cx - headWidth * 0.6,
          headCy - headHeight * 0.5 * lengthFactor,
          cx,
          headCy - headHeight * 0.5 * lengthFactor,
        );
        bunBasePath.quadraticBezierTo(
          cx + headWidth * 0.6,
          headCy - headHeight * 0.5 * lengthFactor,
          cx + headWidth * 0.55,
          headCy - headHeight * 0.1,
        );
        bunBasePath.quadraticBezierTo(
          cx + headWidth * 0.4,
          headCy - headHeight * 0.25 * lengthFactor,
          cx,
          headCy - headHeight * 0.3 * lengthFactor,
        );
        bunBasePath.quadraticBezierTo(
          cx - headWidth * 0.4,
          headCy - headHeight * 0.25 * lengthFactor,
          cx - headWidth * 0.55,
          headCy - headHeight * 0.1,
        );
        canvas.drawPath(bunBasePath, _hairPaint);
        // The bun
        canvas.drawCircle(
          Offset(cx, headCy - headHeight * 0.65 * lengthFactor),
          18 * scale,
          _hairPaint,
        );
        canvas.drawCircle(
          Offset(cx + 3 * scale, headCy - headHeight * 0.7 * lengthFactor),
          5 * scale,
          _hairHighlightPaint,
        );
        // Hair tie
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx, headCy - headHeight * 0.5 * lengthFactor),
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

      case EnhancedAvatarHairStyle.afro:
        // Big, voluminous afro
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, headCy - headHeight * 0.3 * lengthFactor),
            width: headWidth * 1.4,
            height: headHeight * 1.2 * lengthFactor,
          ),
          _hairPaint,
        );
        // Texture details
        for (int i = 0; i < 5; i++) {
          for (int j = 0; j < 5; j++) {
            canvas.drawCircle(
              Offset(
                cx - headWidth * 0.5 + i * headWidth * 0.25,
                headCy - headHeight * 0.5 + j * headHeight * 0.25 * lengthFactor,
              ),
              2 * scale,
              _hairHighlightPaint,
            );
          }
        }
        break;

      case EnhancedAvatarHairStyle.curly:
        // Curly hair with spiral pattern
        final curlyPath = Path();
        curlyPath.moveTo(cx - headWidth * 0.6, headCy);
        for (int i = 0; i < 5; i++) {
          curlyPath.quadraticBezierTo(
            cx - headWidth * 0.6 + i * headWidth * 0.3,
            headCy - headHeight * (0.1 + i * 0.1) * lengthFactor,
            cx - headWidth * 0.5 + i * headWidth * 0.3,
            headCy - headHeight * (0.2 + i * 0.1) * lengthFactor,
          );
        }
        curlyPath.lineTo(cx + headWidth * 0.6, headCy);
        curlyPath.close();
        canvas.drawPath(curlyPath, _hairPaint);
        break;

      case EnhancedAvatarHairStyle.wavy:
        // Wavy hair pattern
        final wavyPath = Path();
        wavyPath.moveTo(cx - headWidth * 0.6, headCy);
        // Create a wavy line
        for (int i = 0; i < 10; i++) {
          final x = cx - headWidth * 0.6 + i * headWidth * 0.12;
          final y = headCy - headHeight * 0.1 * lengthFactor - 
                   (i % 2 == 0 ? 1 : -1) * headHeight * 0.05 * lengthFactor;
          wavyPath.lineTo(x, y);
        }
        wavyPath.lineTo(cx + headWidth * 0.6, headCy);
        wavyPath.close();
        canvas.drawPath(wavyPath, _hairPaint);
        break;

      case EnhancedAvatarHairStyle.spiky:
        // Spiky hair with individual spikes
        for (int i = 0; i < 7; i++) {
          final spikeX = cx - headWidth * 0.5 + i * headWidth * 0.16;
          canvas.drawLine(
            Offset(spikeX, headCy),
            Offset(spikeX, headCy - headHeight * 0.4 * lengthFactor - (i % 3) * 5 * scale),
            Paint()
              ..color = _hairPaint.color
              ..strokeWidth = 4 * scale
              ..strokeCap = StrokeCap.round,
          );
        }
        break;

      case EnhancedAvatarHairStyle.straight:
        // Straight hair with gentle curves
        final straightPath = Path();
        straightPath.moveTo(cx - headWidth * 0.6, headCy);
        straightPath.quadraticBezierTo(
          cx - headWidth * 0.65,
          headCy - headHeight * 0.3 * lengthFactor,
          cx - headWidth * 0.6,
          headCy - headHeight * 0.5 * lengthFactor,
        );
        straightPath.lineTo(cx + headWidth * 0.6, headCy - headHeight * 0.5 * lengthFactor);
        straightPath.quadraticBezierTo(
          cx + headWidth * 0.65,
          headCy - headHeight * 0.3 * lengthFactor,
          cx + headWidth * 0.6,
          headCy,
        );
        straightPath.close();
        canvas.drawPath(straightPath, _hairPaint);
        break;

      case EnhancedAvatarHairStyle.mohawk:
        // Mohawk - hair only on top
        final mohawkPath = Path();
        mohawkPath.moveTo(cx - headWidth * 0.1, headCy);
        mohawkPath.quadraticBezierTo(
          cx,
          headCy - headHeight * 0.6 * lengthFactor,
          cx + headWidth * 0.1,
          headCy,
        );
        canvas.drawPath(mohawkPath, _hairPaint);
        break;

      case EnhancedAvatarHairStyle.bob:
        // Bob cut - chin length
        final bobPath = Path();
        bobPath.moveTo(cx - headWidth * 0.6, headCy);
        bobPath.quadraticBezierTo(
          cx - headWidth * 0.7,
          headCy - headHeight * 0.5 * lengthFactor,
          cx,
          headCy - headHeight * 0.5 * lengthFactor,
        );
        bobPath.quadraticBezierTo(
          cx + headWidth * 0.7,
          headCy - headHeight * 0.5 * lengthFactor,
          cx + headWidth * 0.6,
          headCy,
        );
        bobPath.lineTo(cx + headWidth * 0.5, headCy + headHeight * 0.3 * lengthFactor);
        bobPath.lineTo(cx - headWidth * 0.5, headCy + headHeight * 0.3 * lengthFactor);
        bobPath.close();
        canvas.drawPath(bobPath, _hairPaint);
        break;

      case EnhancedAvatarHairStyle.pixie:
        // Short pixie cut
        final pixiePath = Path();
        pixiePath.moveTo(cx - headWidth * 0.5, headCy);
        pixiePath.quadraticBezierTo(
          cx - headWidth * 0.6,
          headCy - headHeight * 0.4 * lengthFactor,
          cx,
          headCy - headHeight * 0.4 * lengthFactor,
        );
        pixiePath.quadraticBezierTo(
          cx + headWidth * 0.6,
          headCy - headHeight * 0.4 * lengthFactor,
          cx + headWidth * 0.5,
          headCy,
        );
        canvas.drawPath(pixiePath, _hairPaint);
        break;

      case EnhancedAvatarHairStyle.dreadlocks:
        // Dreadlocks - multiple rope-like strands
        for (int i = 0; i < 10; i++) {
          final x = cx - headWidth * 0.5 + i * headWidth * 0.11;
          canvas.drawPath(
            Path()
              ..moveTo(x, headCy - headHeight * 0.1 * lengthFactor)
              ..relativeQuadraticBezierTo(
                -2 * scale, headHeight * 0.2 * lengthFactor,
                0, headHeight * 0.4 * lengthFactor,
              ),
            Paint()
              ..color = _hairPaint.color
              ..strokeWidth = 3 * scale,
          );
        }
        break;

      case EnhancedAvatarHairStyle.braids:
        // Braided hairstyle
        final braidPath = Path();
        braidPath.moveTo(cx - headWidth * 0.6, headCy);
        braidPath.quadraticBezierTo(
          cx - headWidth * 0.7,
          headCy - headHeight * 0.1 * lengthFactor,
          cx - headWidth * 0.65,
          headCy - headHeight * 0.3 * lengthFactor,
        );
        braidPath.quadraticBezierTo(
          cx - headWidth * 0.6,
          headCy - headHeight * 0.5 * lengthFactor,
          cx - headWidth * 0.5,
          headCy - headHeight * 0.4 * lengthFactor,
        );
        braidPath.lineTo(cx + headWidth * 0.5, headCy - headHeight * 0.4 * lengthFactor);
        braidPath.quadraticBezierTo(
          cx + headWidth * 0.6,
          headCy - headHeight * 0.5 * lengthFactor,
          cx + headWidth * 0.65,
          headCy - headHeight * 0.3 * lengthFactor,
        );
        braidPath.quadraticBezierTo(
          cx + headWidth * 0.7,
          headCy - headHeight * 0.1 * lengthFactor,
          cx + headWidth * 0.6,
          headCy,
        );
        braidPath.close();
        canvas.drawPath(braidPath, _hairPaint);
        
        // Braid details
        for (int i = 0; i < 4; i++) {
          canvas.drawLine(
            Offset(cx - headWidth * 0.4 + i * headWidth * 0.25, headCy - headHeight * 0.35 * lengthFactor),
            Offset(cx - headWidth * 0.35 + i * headWidth * 0.25, headCy - headHeight * 0.2 * lengthFactor),
            Paint()
              ..color = _hairHighlightPaint.color
              ..strokeWidth = 1 * scale,
          );
        }
        break;
    }
  }

  void _drawAccessories(Canvas canvas, double cx, double cy, double scale) {
    final headCy = cy - 60 * scale * avatar.headScale;
    final headWidth = _getHeadWidth(avatar.faceShape) * scale * avatar.headScale;

    for (final accessory in avatar.accessories) {
      switch (accessory) {
        case AvatarAccessory.glasses:
          // Regular glasses
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx - 0.2 * headWidth, headCy - 8 * scale),
              width: 25 * scale,
              height: 10 * scale,
            ),
            Paint()
              ..color = Colors.transparent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 * scale,
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx + 0.2 * headWidth, headCy - 8 * scale),
              width: 25 * scale,
              height: 10 * scale,
            ),
            Paint()
              ..color = Colors.transparent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 * scale,
          );
          // Bridge
          canvas.drawLine(
            Offset(cx - 0.1 * headWidth, headCy - 8 * scale),
            Offset(cx + 0.1 * headWidth, headCy - 8 * scale),
            Paint()
              ..color = Colors.black
              ..strokeWidth = 1 * scale,
          );
          // Arms
          canvas.drawLine(
            Offset(cx - 0.5 * headWidth, headCy - 8 * scale),
            Offset(cx - 0.6 * headWidth, headCy - 12 * scale),
            Paint()
              ..color = Colors.black
              ..strokeWidth = 1.5 * scale,
          );
          canvas.drawLine(
            Offset(cx + 0.5 * headWidth, headCy - 8 * scale),
            Offset(cx + 0.6 * headWidth, headCy - 12 * scale),
            Paint()
              ..color = Colors.black
              ..strokeWidth = 1.5 * scale,
          );
          break;

        case AvatarAccessory.sunglasses:
          // Larger sunglasses
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx - 0.2 * headWidth, headCy - 10 * scale),
              width: 30 * scale,
              height: 12 * scale,
            ),
            Paint()
              ..color = Colors.black
              ..style = PaintingStyle.fill,
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx + 0.2 * headWidth, headCy - 10 * scale),
              width: 30 * scale,
              height: 12 * scale,
            ),
            Paint()
              ..color = Colors.black
              ..style = PaintingStyle.fill,
          );
          // Bridge
          canvas.drawLine(
            Offset(cx - 0.1 * headWidth, headCy - 10 * scale),
            Offset(cx + 0.1 * headWidth, headCy - 10 * scale),
            Paint()
              ..color = Colors.black
              ..strokeWidth = 2 * scale,
          );
          break;

        case AvatarAccessory.hat:
          // Regular hat
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx, headCy - 25 * scale),
              width: headWidth * 1.2,
              height: 10 * scale,
            ),
            Paint()..color = Colors.brown,
          );
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(cx, headCy - 35 * scale),
              width: headWidth * 0.6,
              height: 20 * scale,
            ),
            Paint()..color = Colors.brown,
          );
          break;

        case AvatarAccessory.cap:
          // Baseball cap
          final capPath = Path();
          capPath.moveTo(cx - headWidth * 0.4, headCy - 20 * scale);
          capPath.lineTo(cx - headWidth * 0.6, headCy - 25 * scale);
          capPath.lineTo(cx + headWidth * 0.6, headCy - 25 * scale);
          capPath.lineTo(cx + headWidth * 0.4, headCy - 20 * scale);
          capPath.close();
          canvas.drawPath(capPath, Paint()..color = Colors.blue);
          // Cap brim
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx, headCy - 15 * scale),
              width: headWidth * 0.9,
              height: 5 * scale,
            ),
            Paint()..color = Colors.blue.shade700,
          );
          break;

        case AvatarAccessory.earrings:
          // Earrings
          canvas.drawCircle(
            Offset(cx - headWidth * 0.5, headCy),
            4 * scale,
            Paint()..color = Colors.yellow,
          );
          canvas.drawCircle(
            Offset(cx + headWidth * 0.5, headCy),
            4 * scale,
            Paint()..color = Colors.yellow,
          );
          break;

        case AvatarAccessory.necklace:
          // Necklace
          canvas.drawCircle(
            Offset(cx, cy - 10 * scale),
            8 * scale,
            Paint()..color = Colors.yellow,
          );
          break;

        case AvatarAccessory.beard:
          // Beard based on growth level
          if (avatar.facialHairGrowth > 0.3) {
            final beardPath = Path();
            beardPath.moveTo(cx - 20 * scale, headCy + 15 * scale);
            beardPath.quadraticBezierTo(
              cx,
              headCy + 15 * scale + avatar.facialHairGrowth * 20 * scale,
              cx + 20 * scale,
              headCy + 15 * scale,
            );
            beardPath.lineTo(cx + 15 * scale, headCy + 30 * scale);
            beardPath.quadraticBezierTo(
              cx,
              headCy + 30 * scale + avatar.facialHairGrowth * 10 * scale,
              cx - 15 * scale,
              headCy + 30 * scale,
            );
            beardPath.close();
            canvas.drawPath(beardPath, _hairPaint);
          }
          break;

        case AvatarAccessory.mustache:
          // Mustache based on growth level
          if (avatar.facialHairGrowth > 0.1) {
            final mustachePath = Path();
            mustachePath.moveTo(cx - 15 * scale, headCy + 10 * scale);
            mustachePath.quadraticBezierTo(
              cx,
              headCy + 5 * scale + avatar.facialHairGrowth * 10 * scale,
              cx + 15 * scale,
              headCy + 10 * scale,
            );
            mustachePath.lineTo(cx + 12 * scale, headCy + 18 * scale);
            mustachePath.quadraticBezierTo(
              cx,
              headCy + 18 * scale,
              cx - 12 * scale,
              headCy + 18 * scale,
            );
            mustachePath.close();
            canvas.drawPath(mustachePath, _hairPaint);
          }
          break;

        default:
          // No accessory
          break;
      }
    }
  }

  double _getHeadHeight(EnhancedAvatarFaceShape shape) {
    switch (shape) {
      case EnhancedAvatarFaceShape.round:
        return 68.0;
      case EnhancedAvatarFaceShape.oval:
        return 78.0;
      case EnhancedAvatarFaceShape.square:
        return 62.0;
      case EnhancedAvatarFaceShape.heart:
        return 65.0;
      case EnhancedAvatarFaceShape.diamond:
        return 70.0;
      case EnhancedAvatarFaceShape.oblong:
        return 80.0;
    }
  }

  double _getHeadWidth(EnhancedAvatarFaceShape shape) {
    switch (shape) {
      case EnhancedAvatarFaceShape.round:
        return 64.0;
      case EnhancedAvatarFaceShape.oval:
        return 56.0;
      case EnhancedAvatarFaceShape.square:
        return 62.0;
      case EnhancedAvatarFaceShape.heart:
        return 58.0;
      case EnhancedAvatarFaceShape.diamond:
        return 60.0;
      case EnhancedAvatarFaceShape.oblong:
        return 58.0;
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedAvatarPainter oldDelegate) {
    return oldDelegate.avatar != avatar ||
        oldDelegate.skinColor != skinColor ||
        oldDelegate.hairColor != hairColor ||
        oldDelegate.outfitPrimaryColor != outfitPrimaryColor ||
        oldDelegate.outfitSecondaryColor != outfitSecondaryColor ||
        oldDelegate.animate != animate;
  }
}