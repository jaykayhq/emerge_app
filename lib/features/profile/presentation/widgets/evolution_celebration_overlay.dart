import 'dart:math' as math;
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:emerge_app/features/profile/domain/services/evolution_haptic_service.dart';
import 'package:flutter/material.dart';

/// Full-screen celebration overlay displayed when user evolves to a new phase
/// Features: confetti particles, phase announcement, silhouette preview
class EvolutionCelebrationOverlay extends StatefulWidget {
  final EvolutionPhase newPhase;
  final EvolutionPhase? previousPhase;
  final Color primaryColor;
  final VoidCallback? onDismiss;

  const EvolutionCelebrationOverlay({
    super.key,
    required this.newPhase,
    this.previousPhase,
    required this.primaryColor,
    this.onDismiss,
  });

  /// Shows the celebration overlay as a modal route
  static Future<void> show(
    BuildContext context, {
    required EvolutionPhase newPhase,
    EvolutionPhase? previousPhase,
    required Color primaryColor,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Evolution Celebration',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return EvolutionCelebrationOverlay(
          newPhase: newPhase,
          previousPhase: previousPhase,
          primaryColor: primaryColor,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<EvolutionCelebrationOverlay> createState() =>
      _EvolutionCelebrationOverlayState();
}

class _EvolutionCelebrationOverlayState
    extends State<EvolutionCelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _confettiController;
  late Animation<double> _textScale;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Trigger haptic celebration
    EvolutionHapticService().evolutionComplete();

    // Start animations
    _textController.forward();
    _confettiController.repeat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String get _phaseDisplayName {
    switch (widget.newPhase) {
      case EvolutionPhase.phantom:
        return 'THE PHANTOM';
      case EvolutionPhase.construct:
        return 'THE CONSTRUCT';
      case EvolutionPhase.incarnate:
        return 'THE INCARNATE';
      case EvolutionPhase.radiant:
        return 'THE RADIANT';
      case EvolutionPhase.ascended:
        return 'THE ASCENDED';
    }
  }

  String get _phaseTagline {
    switch (widget.newPhase) {
      case EvolutionPhase.phantom:
        return 'You are potential, undefined.';
      case EvolutionPhase.construct:
        return 'Your form takes shape.';
      case EvolutionPhase.incarnate:
        return 'You have become real.';
      case EvolutionPhase.radiant:
        return 'Your spirit shines through.';
      case EvolutionPhase.ascended:
        return 'You have transcended.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Confetti particles
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(
                    progress: _confettiController.value,
                    colors: [
                      widget.primaryColor,
                      EmergeColors.teal,
                      EmergeColors.violet,
                      EmergeColors.yellow,
                    ],
                  ),
                ),
              ),
            ),

            // Central content
            Center(
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: Transform.scale(
                      scale: _textScale.value,
                      child: child,
                    ),
                  );
                },
                child: _buildContent(context),
              ),
            ),

            // Tap to dismiss hint
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Text(
                  'TAP ANYWHERE TO CONTINUE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Evolution icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.primaryColor.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(_getPhaseIcon(), size: 80, color: widget.primaryColor),
        ),

        const SizedBox(height: 24),

        // "EVOLUTION" header
        Text(
          'EVOLUTION',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 6,
          ),
        ),

        const SizedBox(height: 12),

        // Phase name
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [widget.primaryColor, EmergeColors.teal],
          ).createShader(bounds),
          child: Text(
            _phaseDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Tagline
        Text(
          _phaseTagline,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),

        const SizedBox(height: 40),

        // Phase indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final isCompleted = index <= widget.newPhase.index;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? widget.primaryColor
                    : Colors.white.withValues(alpha: 0.2),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  IconData _getPhaseIcon() {
    switch (widget.newPhase) {
      case EvolutionPhase.phantom:
        return Icons.blur_on;
      case EvolutionPhase.construct:
        return Icons.architecture;
      case EvolutionPhase.incarnate:
        return Icons.person;
      case EvolutionPhase.radiant:
        return Icons.auto_awesome;
      case EvolutionPhase.ascended:
        return Icons.local_fire_department;
    }
  }
}

/// Paints falling confetti particles
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _ConfettiPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    const particleCount = 60;

    for (int i = 0; i < particleCount; i++) {
      final startX = random.nextDouble() * size.width;
      final speed = 0.5 + random.nextDouble() * 0.5;
      final phase = random.nextDouble();
      final particleSize = 4 + random.nextDouble() * 6;
      final rotation = random.nextDouble() * math.pi * 2;

      // Calculate position with looping animation
      final animProgress = (progress * speed + phase) % 1.0;
      final y = animProgress * size.height * 1.2 - size.height * 0.1;
      final wobble = math.sin(animProgress * math.pi * 4 + i) * 20;
      final x = startX + wobble;

      // Skip particles outside view
      if (y < -20 || y > size.height + 20) continue;

      final color = colors[i % colors.length];
      final paint = Paint()
        ..color = color.withValues(alpha: 0.8 * (1 - animProgress * 0.5));

      // Draw rotated rectangle (confetti piece)
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation + progress * math.pi * 2);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particleSize,
        height: particleSize * 0.6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
