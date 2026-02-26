import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/avatar/data/services/avatar_asset_service.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_config.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:flutter/material.dart';

/// Widget that renders a full-character avatar with evolution overlays.
///
/// Instead of compositing multiple body-part images, AvatarRenderer displays
/// a single pre-generated character image and layers code-driven evolution
/// effects (glow, sparkles, phase labels) on top.
///
/// Rendering layers (back to front):
/// 1. Background glow (evolution phase intensity)
/// 2. Full character image (single PNG, transparent bg)
/// 3. Evolution overlay (border glow for Radiant/Ascended)
/// 4. Foreground sparkles (Ascended phase only)
/// 5. Phase label text
class AvatarRenderer extends StatelessWidget {
  /// Configuration defining the avatar's appearance
  final AvatarConfig config;

  /// Size of the avatar in logical pixels
  final double size;

  /// Whether to show the phase label overlay
  final bool showPhaseLabel;

  /// Callback when avatar is tapped
  final VoidCallback? onTap;

  const AvatarRenderer({
    super.key,
    required this.config,
    this.size = 300,
    this.showPhaseLabel = true,
    this.onTap,
  });

  AvatarAssetService get _assetService => AvatarAssetService();

  Color get _primaryColor =>
      ArchetypeTheme.forArchetype(config.archetype).primaryColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size * 1.2,
        child: RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: Background glow
              _buildBackgroundGlow(),

              // Layer 2: Full character image
              _buildCharacterImage(),

              // Layer 3: Evolved state overlay (Radiant/Ascended)
              if (config.showEvolvedOverlay)
                _buildEvolvedOverlay(config.evolvedState),

              // Layer 4: Foreground sparkles (Ascended only)
              if (config.evolvedState == EvolutionPhase.ascended)
                _buildSparkles(),

              // Layer 5: Phase label
              if (showPhaseLabel) _buildPhaseLabel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    final phase = config.evolvedState;
    final intensity = (phase.index + 1) / 5;

    return Container(
      width: size * 0.9,
      height: size * 1.1,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.45),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.1 * intensity),
            blurRadius: 40 * intensity,
            spreadRadius: 10 * intensity,
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterImage() {
    final characterPath = _assetService.getCharacterPathFromConfig(config);

    return SizedBox(
      width: size,
      height: size * 1.2,
      child: Image.asset(
        characterPath,
        width: size,
        height: size * 1.2,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fall back to silhouette if character image not found
          return Image.asset(
            _assetService.getSilhouettePath(config.archetype),
            width: size,
            height: size * 1.2,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              // Ultimate fallback: painted silhouette
              return CustomPaint(
                size: Size(size, size * 1.2),
                painter: _FallbackSilhouettePainter(color: _primaryColor),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEvolvedOverlay(EvolutionPhase phase) {
    final overlayColor = _getEvolvedOverlayColor(phase);

    return SizedBox(
      width: size,
      height: size * 1.2,
      child: Stack(
        children: [
          // Image overlay (if exists)
          Image.asset(
            _assetService.getEvolvedOverlayPath(phase),
            width: size,
            height: size * 1.2,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // Colored border effect
          Container(
            width: size,
            height: size * 1.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.45),
              border: Border.all(
                color: overlayColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkles() {
    return SizedBox(
      width: size,
      height: size * 1.2,
      child: Image.asset(
        _assetService.getSparklesPath(),
        width: size,
        height: size * 1.2,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildPhaseLabel() {
    final state = config.evolvedState;
    final phaseName = _getPhaseName(state);

    return Positioned(
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _primaryColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              phaseName.toUpperCase(),
              style: TextStyle(
                color: _primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            if (state != EvolutionPhase.phantom)
              Text(
                _getPhaseDescription(state),
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }

  Color _getEvolvedOverlayColor(EvolutionPhase phase) {
    switch (phase) {
      case EvolutionPhase.phantom:
      case EvolutionPhase.construct:
        return Colors.white;
      case EvolutionPhase.incarnate:
        return _primaryColor;
      case EvolutionPhase.radiant:
        return const Color(0xFFFFD700); // Gold for kintsugi
      case EvolutionPhase.ascended:
        return const Color(0xFFE0FFFF); // Cyan for transcendence
    }
  }

  String _getPhaseName(EvolutionPhase phase) {
    switch (phase) {
      case EvolutionPhase.phantom:
        return 'The Phantom';
      case EvolutionPhase.construct:
        return 'The Construct';
      case EvolutionPhase.incarnate:
        return 'The Incarnate';
      case EvolutionPhase.radiant:
        return 'The Radiant';
      case EvolutionPhase.ascended:
        return 'The Ascended';
    }
  }

  String _getPhaseDescription(EvolutionPhase phase) {
    switch (phase) {
      case EvolutionPhase.phantom:
        return 'I am potential.';
      case EvolutionPhase.construct:
        return 'I am building.';
      case EvolutionPhase.incarnate:
        return 'I am consistent.';
      case EvolutionPhase.radiant:
        return 'I am powerful.';
      case EvolutionPhase.ascended:
        return 'I have transcended.';
    }
  }
}

/// Fallback silhouette painter if no image assets are available
class _FallbackSilhouettePainter extends CustomPainter {
  final Color color;

  _FallbackSilhouettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final centerX = size.width / 2;

    // Head
    final headY = size.height * 0.12;
    final headRadius = size.width * 0.12;
    canvas.drawCircle(Offset(centerX, headY), headRadius, paint);
    canvas.drawCircle(Offset(centerX, headY), headRadius, glowPaint);

    // Body
    final bodyPath = Path();
    final neckY = headY + headRadius;
    final bodyBottom = size.height * 0.55;
    final shoulderWidth = size.width * 0.4;

    bodyPath.moveTo(centerX, neckY);
    bodyPath.lineTo(centerX - shoulderWidth / 2, neckY + size.height * 0.08);
    bodyPath.lineTo(centerX - size.width * 0.18, bodyBottom);
    bodyPath.lineTo(centerX + size.width * 0.18, bodyBottom);
    bodyPath.lineTo(centerX + shoulderWidth / 2, neckY + size.height * 0.08);
    bodyPath.close();

    canvas.drawPath(bodyPath, paint);
    canvas.drawPath(bodyPath, glowPaint);

    // Legs
    final legPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX - size.width * 0.08, bodyBottom),
      Offset(centerX - size.width * 0.12, size.height * 0.95),
      legPaint,
    );
    canvas.drawLine(
      Offset(centerX + size.width * 0.08, bodyBottom),
      Offset(centerX + size.width * 0.12, size.height * 0.95),
      legPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FallbackSilhouettePainter oldDelegate) => false;
}
