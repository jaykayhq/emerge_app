import 'dart:math' as math;
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen splash reveal when user first presses EMERGE at level 5
/// Features: dramatic reveal animation, silhouette transformation preview
class EmergeSplashReveal extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback onComplete;

  const EmergeSplashReveal({
    super.key,
    required this.primaryColor,
    required this.onComplete,
  });

  /// Shows the splash reveal as a full-screen overlay
  static Future<void> show(
    BuildContext context, {
    required Color primaryColor,
    required VoidCallback onComplete,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return EmergeSplashReveal(
            primaryColor: primaryColor,
            onComplete: onComplete,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<EmergeSplashReveal> createState() => _EmergeSplashRevealState();
}

class _EmergeSplashRevealState extends State<EmergeSplashReveal>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _sequenceController;
  late Animation<double> _pulseAnim;
  late Animation<double> _textFade;
  late Animation<double> _logoScale;
  late Animation<double> _particleBurst;
  late Animation<double> _finalReveal;

  @override
  void initState() {
    super.initState();

    // Continuous pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sequence animation (4 seconds total)
    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Phase 1: Logo scales in (0-0.25)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.0, 0.25, curve: Curves.elasticOut),
      ),
    );

    // Phase 2: Text fades in (0.2-0.4)
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.2, 0.4, curve: Curves.easeIn),
      ),
    );

    // Phase 3: Particle burst (0.5-0.8)
    _particleBurst = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    // Phase 4: Final reveal flash (0.85-1.0)
    _finalReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
      ),
    );

    // Trigger haptic feedback
    HapticFeedback.heavyImpact();

    // Start sequence
    _sequenceController.forward();

    // Complete after animation
    _sequenceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _sequenceController]),
        builder: (context, child) {
          return Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        widget.primaryColor.withValues(alpha: 0.3),
                        EmergeColors.background,
                      ],
                    ),
                  ),
                ),
              ),

              // Particle burst effect
              if (_particleBurst.value > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BurstParticlePainter(
                      progress: _particleBurst.value,
                      color: widget.primaryColor,
                    ),
                  ),
                ),

              // Central content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emerging silhouette icon
                    Transform.scale(
                      scale: _logoScale.value * _pulseAnim.value,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.primaryColor.withValues(alpha: 0.5),
                              widget.primaryColor.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.primaryColor.withValues(alpha: 0.6),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // "YOU ARE READY" text
                    Opacity(
                      opacity: _textFade.value,
                      child: Column(
                        children: [
                          Text(
                            'YOU ARE READY',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [widget.primaryColor, EmergeColors.teal],
                            ).createShader(bounds),
                            child: const Text(
                              'EMERGE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Your transformation begins now',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Final white flash overlay
              if (_finalReveal.value > 0)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(
                      alpha: _finalReveal.value * 0.8,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Paints expanding particle burst effect
class _BurstParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _BurstParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42);
    const particleCount = 40;
    final maxRadius = size.width * 0.6;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * math.pi * 2 + random.nextDouble();
      final speed = 0.7 + random.nextDouble() * 0.3;
      final particleSize = 3 + random.nextDouble() * 4;

      final distance = maxRadius * progress * speed;
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      final alpha = (1 - progress * 0.8).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = i % 2 == 0
            ? color.withValues(alpha: alpha)
            : EmergeColors.teal.withValues(alpha: alpha);

      canvas.drawCircle(
        Offset(x, y),
        particleSize * (1 - progress * 0.5),
        paint,
      );
    }

    // Draw expanding ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: (1 - progress) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * (1 - progress);

    canvas.drawCircle(center, maxRadius * progress * 0.8, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _BurstParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
