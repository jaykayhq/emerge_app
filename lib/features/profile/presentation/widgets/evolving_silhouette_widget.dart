import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:emerge_app/features/profile/domain/services/evolution_haptic_service.dart';
import 'package:emerge_app/features/profile/presentation/widgets/phases/ascended_phase_painter.dart';
import 'package:emerge_app/features/profile/presentation/widgets/phases/construct_phase_painter.dart';
import 'package:emerge_app/features/profile/presentation/widgets/phases/incarnate_phase_painter.dart';
import 'package:emerge_app/features/profile/presentation/widgets/phases/phantom_phase_painter.dart';
import 'package:emerge_app/features/profile/presentation/widgets/phases/radiant_phase_painter.dart';
import 'package:flutter/material.dart';

/// The complete evolving silhouette widget that composes all 5 phase painters
/// Selects the appropriate painter based on evolution state and animates transitions
class EvolvingSilhouetteWidget extends StatefulWidget {
  final SilhouetteEvolutionState evolutionState;
  final UserArchetype archetype;
  final Map<String, double> attributes;
  final double size;
  final VoidCallback? onEvolutionTap;

  const EvolvingSilhouetteWidget({
    super.key,
    required this.evolutionState,
    required this.archetype,
    this.attributes = const {},
    this.size = 300,
    this.onEvolutionTap,
  });

  @override
  State<EvolvingSilhouetteWidget> createState() =>
      _EvolvingSilhouetteWidgetState();
}

class _EvolvingSilhouetteWidgetState extends State<EvolvingSilhouetteWidget>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;

  @override
  void initState() {
    super.initState();

    // Primary animation for breathing/floating (4 second cycle)
    _primaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Secondary animation for particles/energy (6 second cycle)
    _secondaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  Color get _primaryColor {
    return ArchetypeTheme.forArchetype(widget.archetype).primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        EvolutionHapticService().silhouetteTap();
        widget.onEvolutionTap?.call();
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.1,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _primaryController,
            _secondaryController,
          ]),
          builder: (context, child) {
            // RepaintBoundary isolates this complex painting from parent repaints
            return RepaintBoundary(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background glow layer
                  _buildBackgroundGlow(),

                  // Main phase painter
                  _buildPhasePainter(),

                  // Attribute aura overlays
                  if (widget.attributes.isNotEmpty) _buildAttributeAuras(),

                  // Phase label overlay
                  Positioned(bottom: 0, child: _buildPhaseLabel()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    final phase = widget.evolutionState.phase;
    final glowIntensity = (phase.index + 1) / 5;

    return Container(
      width: widget.size * 0.9,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.size * 0.45),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.1 * glowIntensity),
            blurRadius: 40 * glowIntensity,
            spreadRadius: 10 * glowIntensity,
          ),
        ],
      ),
    );
  }

  Widget _buildPhasePainter() {
    final state = widget.evolutionState;
    final animValue = _primaryController.value;
    final secondaryAnimValue = _secondaryController.value;

    CustomPainter painter;

    switch (state.phase) {
      case EvolutionPhase.phantom:
        painter = PhantomPhasePainter(
          animationValue: animValue,
          primaryColor: _primaryColor,
          opacity: 0.5,
          entropyLevel: state.entropyLevel,
        );
        break;

      case EvolutionPhase.construct:
        painter = ConstructPhasePainter(
          animationValue: animValue,
          primaryColor: _primaryColor,
          opacity: 0.6,
          phaseProgress: state.phaseProgress,
        );
        break;

      case EvolutionPhase.incarnate:
        painter = IncarnatePhasePainter(
          animationValue: animValue,
          primaryColor: _primaryColor,
          opacity: 0.85,
        );
        break;

      case EvolutionPhase.radiant:
        painter = RadiantPhasePainter(
          animationValue: secondaryAnimValue,
          primaryColor: _primaryColor,
          opacity: 0.9,
          phaseProgress: state.phaseProgress,
        );
        break;

      case EvolutionPhase.ascended:
        painter = AscendedPhasePainter(
          animationValue: secondaryAnimValue,
          primaryColor: _primaryColor,
          opacity: 1.0,
        );
        break;
    }

    return CustomPaint(
      size: Size(widget.size, widget.size * 1.0),
      painter: painter,
    );
  }

  Widget _buildAttributeAuras() {
    // Only show attribute auras for Incarnate phase and above
    if (widget.evolutionState.phase.index < EvolutionPhase.incarnate.index) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: Size(widget.size, widget.size * 1.0),
      painter: _AttributeAuraOverlayPainter(
        attributes: widget.attributes,
        animationValue: _secondaryController.value,
      ),
    );
  }

  Widget _buildPhaseLabel() {
    final state = widget.evolutionState;

    return Container(
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
            state.phaseName.toUpperCase(),
            style: TextStyle(
              color: _primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Text(
            'LVL ${state.level}',
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

/// Paints attribute auras on higher-level silhouettes
class _AttributeAuraOverlayPainter extends CustomPainter {
  final Map<String, double> attributes;
  final double animationValue;

  // Attribute zone positions (relative to canvas)
  static const _attributeZones = {
    'Strength': [(0.15, 0.22), (0.85, 0.22)], // Shoulders
    'Intellect': [(0.5, 0.08)], // Head
    'Vitality': [(0.5, 0.32)], // Chest
    'Focus': [(0.5, 0.1)], // Eyes
    'Resilience': [(0.5, 0.45)], // Core
    'Creativity': [(0.1, 0.4), (0.9, 0.4)], // Hands
  };

  static const _attributeColors = {
    'Strength': Color(0xFFf7768e),
    'Intellect': Color(0xFFbb9af7),
    'Vitality': Color(0xFF9ece6a),
    'Focus': Color(0xFF00F0FF),
    'Resilience': Color(0xFF7aa2f7),
    'Creativity': Color(0xFFe0af68),
  };

  _AttributeAuraOverlayPainter({
    required this.attributes,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 0.7 + animationValue * 0.3;

    for (final entry in _attributeZones.entries) {
      final attrName = entry.key;
      final zones = entry.value;
      final value = (attributes[attrName] ?? 0.0).clamp(0.0, 1.0);

      if (value < 0.1) continue;

      final color = _attributeColors[attrName] ?? Colors.white;
      final glowRadius = size.width * 0.06 * value;
      final glowOpacity = 0.25 * value * pulse;

      for (final zone in zones) {
        final center = Offset(zone.$1 * size.width, zone.$2 * size.height);

        final gradient = RadialGradient(
          colors: [
            color.withValues(alpha: glowOpacity),
            color.withValues(alpha: glowOpacity * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
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
  bool shouldRepaint(covariant _AttributeAuraOverlayPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.attributes != attributes;
  }
}
