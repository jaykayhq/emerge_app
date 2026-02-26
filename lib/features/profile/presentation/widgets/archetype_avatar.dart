import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter/material.dart';

/// Archetype Avatar with glowing attribute auras
/// Displays a silhouette image with animated glowing zones that indicate attribute strength
class ArchetypeAvatar extends StatefulWidget {
  final UserArchetype archetype;
  final int level;
  final Map<String, double> attributes; // 0.0 - 1.0 for each attribute
  final double size;
  final ValueChanged<String>? onAttributeTap;

  const ArchetypeAvatar({
    super.key,
    required this.archetype,
    required this.level,
    required this.attributes,
    this.size = 300,
    this.onAttributeTap,
  });

  @override
  State<ArchetypeAvatar> createState() => _ArchetypeAvatarState();
}

class _ArchetypeAvatarState extends State<ArchetypeAvatar>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _auraController;

  @override
  void initState() {
    super.initState();

    // Slow breathing animation - 4 second cycle
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    // Aura pulse animation - 3 second cycle
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _auraController.dispose();
    super.dispose();
  }

  String _getAvatarAsset() {
    switch (widget.archetype) {
      case UserArchetype.athlete:
        return 'assets/images/avatars/athlete_silhouette.png';
      case UserArchetype.scholar:
        return 'assets/images/avatars/scholar_silhouette.png';
      case UserArchetype.creator:
        return 'assets/images/avatars/creator_silhouette.png';
      case UserArchetype.stoic:
        return 'assets/images/avatars/stoic_silhouette.png';
      case UserArchetype.zealot:
        return 'assets/images/avatars/zealot_silhouette.png';
      case UserArchetype.none:
        return 'assets/images/avatars/athlete_silhouette.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ArchetypeTheme.forArchetype(widget.archetype);
    final primaryColor = theme.primaryColor;

    return SizedBox(
      width: widget.size,
      height: widget.size * 1.3,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathingController, _auraController]),
        builder: (context, child) {
          // Subtle breathing scale
          final breathScale = 1.0 + (_breathingController.value * 0.015);
          // Aura pulse intensity
          final auraPulse = 0.7 + (_auraController.value * 0.3);

          return Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: Outer glow based on level
              if (widget.level >= 5)
                Container(
                  width: widget.size * 0.85,
                  height: widget.size * 1.1,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.4),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(
                          alpha:
                              0.2 * auraPulse * (widget.level / 50).clamp(0, 1),
                        ),
                        blurRadius: widget.level * 3.0,
                        spreadRadius: widget.level * 0.5,
                      ),
                    ],
                  ),
                ),

              // Layer 2: Attribute auras
              CustomPaint(
                size: Size(widget.size, widget.size * 1.3),
                painter: AttributeAuraPainter(
                  attributes: widget.attributes,
                  auraPulse: auraPulse,
                  archetype: widget.archetype,
                ),
              ),

              // Layer 3: Main silhouette image
              Transform.scale(
                scale: breathScale,
                child: Image.asset(
                  _getAvatarAsset(),
                  width: widget.size * 0.9,
                  height: widget.size * 1.2,
                  fit: BoxFit.contain,
                  color: Colors.white.withValues(alpha: 0.05),
                  colorBlendMode: BlendMode.lighten,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to the old silhouette painter if image fails
                    return CustomPaint(
                      size: Size(widget.size * 0.9, widget.size * 1.2),
                      painter: _FallbackSilhouettePainter(
                        color: primaryColor,
                        level: widget.level,
                      ),
                    );
                  },
                ),
              ),

              // Layer 4: Highlight aura effect on top
              if (widget.level >= 10)
                CustomPaint(
                  size: Size(widget.size, widget.size * 1.3),
                  painter: _HighlightAuraPainter(
                    color: primaryColor,
                    intensity: auraPulse * (widget.level / 30).clamp(0, 1),
                  ),
                ),

              // Layer 5: Gesture detection zones for attributes
              ..._buildAttributeZones(),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildAttributeZones() {
    final zones = <Widget>[];
    final zoneData = [
      // Strength - arms/shoulders area
      (name: 'Strength', top: 0.2, left: 0.1, width: 0.3, height: 0.25),
      (name: 'Strength', top: 0.2, left: 0.6, width: 0.3, height: 0.25),
      // Intellect - head/temple
      (name: 'Intellect', top: 0.0, left: 0.3, width: 0.4, height: 0.18),
      // Vitality - chest/core
      (name: 'Vitality', top: 0.22, left: 0.3, width: 0.4, height: 0.25),
      // Focus - eyes (small zone on head)
      (name: 'Focus', top: 0.06, left: 0.35, width: 0.3, height: 0.1),
      // Resilience - spine/back (center zone)
      (name: 'Resilience', top: 0.45, left: 0.35, width: 0.3, height: 0.3),
      // Creativity - hands
      (name: 'Creativity', top: 0.4, left: 0.05, width: 0.2, height: 0.2),
      (name: 'Creativity', top: 0.4, left: 0.75, width: 0.2, height: 0.2),
    ];

    for (final zone in zoneData) {
      zones.add(
        Positioned(
          top: widget.size * 1.3 * zone.top,
          left: widget.size * zone.left,
          width: widget.size * zone.width,
          height: widget.size * 1.3 * zone.height,
          child: GestureDetector(
            onTap: () => widget.onAttributeTap?.call(zone.name),
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
      );
    }

    return zones;
  }
}

/// Paints glowing auras on the avatar based on attribute strength
class AttributeAuraPainter extends CustomPainter {
  final Map<String, double> attributes;
  final double auraPulse;
  final UserArchetype archetype;

  // Attribute zone definitions (relative to canvas)
  static const _attributeZones = {
    'Strength': [(0.15, 0.25), (0.85, 0.25)], // Arms/shoulders
    'Intellect': [(0.5, 0.08)], // Head
    'Vitality': [(0.5, 0.35)], // Chest
    'Focus': [(0.5, 0.1)], // Eyes
    'Resilience': [(0.5, 0.55)], // Spine
    'Creativity': [(0.1, 0.48), (0.9, 0.48)], // Hands
  };

  // Attribute colors
  static const _attributeColors = {
    'Strength': Color(0xFFf7768e), // Coral
    'Intellect': Color(0xFFbb9af7), // Violet
    'Vitality': Color(0xFF9ece6a), // Green
    'Focus': Color(0xFF00F0FF), // Cyan
    'Resilience': Color(0xFF7aa2f7), // Blue
    'Creativity': Color(0xFFe0af68), // Yellow
  };

  AttributeAuraPainter({
    required this.attributes,
    required this.auraPulse,
    required this.archetype,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in _attributeZones.entries) {
      final attrName = entry.key;
      final zones = entry.value;
      final value = (attributes[attrName] ?? 0.0).clamp(0.0, 1.0);

      // Only draw if attribute has value
      if (value < 0.1) continue;

      final color = _attributeColors[attrName] ?? EmergeColors.teal;
      final glowRadius = size.width * 0.12 * value;
      final glowOpacity = 0.3 * value * auraPulse;

      for (final zone in zones) {
        final center = Offset(zone.$1 * size.width, zone.$2 * size.height);

        // Draw soft radial glow
        final gradient = RadialGradient(
          colors: [
            color.withValues(alpha: glowOpacity),
            color.withValues(alpha: glowOpacity * 0.4),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        final paint = Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: glowRadius),
          );

        canvas.drawCircle(center, glowRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AttributeAuraPainter oldDelegate) {
    return oldDelegate.auraPulse != auraPulse ||
        oldDelegate.attributes != attributes;
  }
}

/// Highlight aura painter for high-level avatars
class _HighlightAuraPainter extends CustomPainter {
  final Color color;
  final double intensity;

  _HighlightAuraPainter({required this.color, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.1 * intensity),
        color.withValues(alpha: 0),
      ],
      stops: const [0.3, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.6),
      );

    canvas.drawCircle(center, size.width * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant _HighlightAuraPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}

/// Fallback silhouette painter if image fails to load
class _FallbackSilhouettePainter extends CustomPainter {
  final Color color;
  final int level;

  _FallbackSilhouettePainter({required this.color, required this.level});

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

    // Draw simple humanoid shape
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
