import 'package:flutter/material.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

/// Preview widget for Koa the Cosmic Turtle mascot.
/// Run this to see the mascot design in action.
///
/// Usage: Add to any screen or run as standalone preview.
class MascotPreview extends StatelessWidget {
  const MascotPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.cosmicVoidDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Koa — Mascot Preview',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Main mascot display
              const Text(
                'Default (Explorer)',
                style: TextStyle(
                  color: EmergeColors.mintMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              const KoaMascot(
                size: 200,
                expression: MascotExpression.neutral,
                archetype: Archetype.explorer,
              ),
              const SizedBox(height: 32),

              // Expression grid
              const Text(
                'Expressions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildExpressionGrid(),

              const SizedBox(height: 32),

              // Archetype shells
              const Text(
                'Archetype Shells',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildArchetypeGrid(),

              const SizedBox(height: 32),

              // Size variants
              const Text(
                'Size Variants',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSizeVariants(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpressionGrid() {
    final expressions = MascotExpression.values;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: expressions.map((expr) {
        return Column(
          children: [
            KoaMascot(
              size: 80,
              expression: expr,
              archetype: Archetype.explorer,
            ),
            const SizedBox(height: 8),
            Text(
              expr.name,
              style: const TextStyle(
                color: EmergeColors.mintMuted,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildArchetypeGrid() {
    final archetypes = Archetype.values;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: archetypes.map((arch) {
        return Column(
          children: [
            KoaMascot(
              size: 80,
              expression: MascotExpression.neutral,
              archetype: arch,
            ),
            const SizedBox(height: 8),
            Text(
              arch.name,
              style: const TextStyle(
                color: EmergeColors.mintMuted,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSizeVariants() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        KoaMascot(
          size: 32,
          expression: MascotExpression.happy,
          archetype: Archetype.explorer,
        ),
        SizedBox(width: 16),
        KoaMascot(
          size: 48,
          expression: MascotExpression.happy,
          archetype: Archetype.explorer,
        ),
        SizedBox(width: 16),
        KoaMascot(
          size: 64,
          expression: MascotExpression.happy,
          archetype: Archetype.explorer,
        ),
        SizedBox(width: 16),
        KoaMascot(
          size: 96,
          expression: MascotExpression.happy,
          archetype: Archetype.explorer,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum MascotExpression {
  neutral,
  happy,
  excited,
  encouraging,
  sad,
  sleepy,
  proud,
}

enum Archetype {
  athlete,
  scholar,
  creator,
  stoic,
  zealot,
  explorer,
}

// ---------------------------------------------------------------------------
// Core Mascot Widget
// ---------------------------------------------------------------------------

class KoaMascot extends StatefulWidget {
  final double size;
  final MascotExpression expression;
  final Archetype archetype;
  final bool animate;

  const KoaMascot({
    super.key,
    required this.size,
    required this.expression,
    required this.archetype,
    this.animate = true,
  });

  @override
  State<KoaMascot> createState() => _KoaMascotState();
}

class _KoaMascotState extends State<KoaMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _breatheAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _idleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shellColors = _getArchetypeColors(widget.archetype);

    return AnimatedBuilder(
      animation: _breatheAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animate ? _breatheAnimation.value : 1.0,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: KoaPainter(
                expression: widget.expression,
                shellPrimary: shellColors.$1,
                shellAccent: shellColors.$2,
                bodyColor: EmergeColors.cosmicMidPurple,
                eyeGlow: EmergeColors.neonTeal,
              ),
            ),
          ),
        );
      },
    );
  }

  (Color, Color) _getArchetypeColors(Archetype archetype) {
    switch (archetype) {
      case Archetype.athlete:
        return (const Color(0xFFFF5252), const Color(0xFFFF8E72));
      case Archetype.scholar:
        return (const Color(0xFF7C3AED), const Color(0xFFB794F6));
      case Archetype.creator:
        return (const Color(0xFFFFD700), const Color(0xFFFFD93D));
      case Archetype.stoic:
        return (const Color(0xFF26A69A), const Color(0xFF4DD4AC));
      case Archetype.zealot:
        return (const Color(0xFF991B1B), const Color(0xFFB45309));
      case Archetype.explorer:
        return (const Color(0xFF009688), const Color(0xFF64FFDA));
    }
  }
}

// ---------------------------------------------------------------------------
// Custom Painter — Koa the Cosmic Turtle
// ---------------------------------------------------------------------------

class KoaPainter extends CustomPainter {
  final MascotExpression expression;
  final Color shellPrimary;
  final Color shellAccent;
  final Color bodyColor;
  final Color eyeGlow;

  KoaPainter({
    required this.expression,
    required this.shellPrimary,
    required this.shellAccent,
    required this.bodyColor,
    required this.eyeGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Center point
    final cx = w / 2;
    final cy = h / 2;

    // Scale factor for responsive sizing
    final s = w / 200;

    // --- Shell (background) ---
    _drawShell(canvas, cx, cy, s);

    // --- Body (belly) ---
    _drawBody(canvas, cx, cy, s);

    // --- Head ---
    _drawHead(canvas, cx, cy, s);

    // --- Eyes ---
    _drawEyes(canvas, cx, cy, s);

    // --- Mouth ---
    _drawMouth(canvas, cx, cy, s);

    // --- Cheeks ---
    _drawCheeks(canvas, cx, cy, s);

    // --- Limbs ---
    _drawLimbs(canvas, cx, cy, s);
  }

  void _drawShell(Canvas canvas, double cx, double cy, double s) {
    final shellPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [shellPrimary, shellAccent],
      ).createShader(
        Rect.fromCircle(center: Offset(cx, cy - 10 * s), radius: 70 * s),
      );

    // Shell shape (rounded rectangle with dome top)
    final shellPath = Path();
    shellPath.moveTo(cx - 55 * s, cy + 30 * s);
    shellPath.lineTo(cx - 50 * s, cy - 20 * s);
    shellPath.quadraticBezierTo(cx, cy - 75 * s, cx + 50 * s, cy - 20 * s);
    shellPath.lineTo(cx + 55 * s, cy + 30 * s);
    shellPath.quadraticBezierTo(
      cx,
      cy + 45 * s,
      cx - 55 * s,
      cy + 30 * s,
    );
    canvas.drawPath(shellPath, shellPaint);

    // Shell pattern (nebula swirls)
    final patternPaint = Paint()
      ..color = shellAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;

    // Swirl 1
    final swirl1 = Path();
    swirl1.moveTo(cx - 20 * s, cy + 10 * s);
    swirl1.quadraticBezierTo(cx - 30 * s, cy - 30 * s, cx, cy - 40 * s);
    canvas.drawPath(swirl1, patternPaint);

    // Swirl 2
    final swirl2 = Path();
    swirl2.moveTo(cx + 15 * s, cy + 15 * s);
    swirl2.quadraticBezierTo(cx + 25 * s, cy - 20 * s, cx + 10 * s, cy - 45 * s);
    canvas.drawPath(swirl2, patternPaint);

    // Shell outline
    final outlinePaint = Paint()
      ..color = EmergeColors.cosmicVoidDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s;
    canvas.drawPath(shellPath, outlinePaint);
  }

  void _drawBody(Canvas canvas, double cx, double cy, double s) {
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    // Belly (oval in front of shell)
    final bellyPath = Path();
    bellyPath.addOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 15 * s),
        width: 70 * s,
        height: 50 * s,
      ),
    );
    canvas.drawPath(bellyPath, bodyPaint);

    // Belly highlight
    final highlightPaint = Paint()
      ..color = EmergeColors.glassWhite
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 5 * s),
        width: 50 * s,
        height: 25 * s,
      ),
      highlightPaint,
    );
  }

  void _drawHead(Canvas canvas, double cx, double cy, double s) {
    final headPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    // Head circle
    canvas.drawCircle(
      Offset(cx, cy - 45 * s),
      35 * s,
      headPaint,
    );

    // Head outline
    final outlinePaint = Paint()
      ..color = EmergeColors.cosmicVoidDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s;
    canvas.drawCircle(
      Offset(cx, cy - 45 * s),
      35 * s,
      outlinePaint,
    );
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double s) {
    final eyeSpacing = 18 * s;
    final eyeY = cy - 50 * s;
    final eyeSize = 12 * s;

    // White of eyes
    final eyeWhitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - eyeSpacing, eyeY), eyeSize, eyeWhitePaint);
    canvas.drawCircle(Offset(cx + eyeSpacing, eyeY), eyeSize, eyeWhitePaint);

    // Iris (based on expression)
    final irisColor = _getIrisColor();
    final irisPaint = Paint()..color = irisColor;
    final irisSize = eyeSize * 0.6;

    // Iris position varies by expression
    final irisOffset = _getIrisOffset();

    canvas.drawCircle(
      Offset(cx - eyeSpacing + irisOffset.dx, eyeY + irisOffset.dy),
      irisSize,
      irisPaint,
    );
    canvas.drawCircle(
      Offset(cx + eyeSpacing + irisOffset.dx, eyeY + irisOffset.dy),
      irisSize,
      irisPaint,
    );

    // Pupil
    final pupilPaint = Paint()..color = EmergeColors.cosmicVoidDark;
    final pupilSize = irisSize * 0.5;
    canvas.drawCircle(
      Offset(cx - eyeSpacing + irisOffset.dx, eyeY + irisOffset.dy),
      pupilSize,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(cx + eyeSpacing + irisOffset.dx, eyeY + irisOffset.dy),
      pupilSize,
      pupilPaint,
    );

    // Eye shine
    final shinePaint = Paint()..color = Colors.white;
    final shineSize = pupilSize * 0.4;
    canvas.drawCircle(
      Offset(
        cx - eyeSpacing + irisOffset.dx - 2 * s,
        eyeY + irisOffset.dy - 2 * s,
      ),
      shineSize,
      shinePaint,
    );
    canvas.drawCircle(
      Offset(
        cx + eyeSpacing + irisOffset.dx - 2 * s,
        eyeY + irisOffset.dy - 2 * s,
      ),
      shineSize,
      shinePaint,
    );

    // Sleepy eyelids
    if (expression == MascotExpression.sleepy) {
      final lidPaint = Paint()
        ..color = bodyColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          cx - eyeSpacing - eyeSize,
          eyeY - eyeSize,
          eyeSize * 2,
          eyeSize * 1.2, // Covers top portion of eye
        ),
        lidPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          cx + eyeSpacing - eyeSize,
          eyeY - eyeSize,
          eyeSize * 2,
          eyeSize * 1.2,
        ),
        lidPaint,
      );
    }
  }

  Color _getIrisColor() {
    switch (expression) {
      case MascotExpression.excited:
      case MascotExpression.proud:
        return EmergeColors.warmGold;
      case MascotExpression.sad:
        return const Color(0xFF90A4AE);
      default:
        return eyeGlow;
    }
  }

  Offset _getIrisOffset() {
    switch (expression) {
      case MascotExpression.happy:
      case MascotExpression.excited:
      case MascotExpression.proud:
        return const Offset(0, -1); // Look up (happy)
      case MascotExpression.sad:
        return const Offset(0, 2); // Look down (sad)
      case MascotExpression.encouraging:
        return const Offset(1, 0); // Look slightly right
      case MascotExpression.sleepy:
        return const Offset(0, 0); // Centered
      default:
        return Offset.zero;
    }
  }

  void _drawMouth(Canvas canvas, double cx, double cy, double s) {
    final mouthPaint = Paint()
      ..color = EmergeColors.cosmicVoidDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;

    final mouthY = cy - 30 * s;
    final mouthPath = Path();

    switch (expression) {
      case MascotExpression.happy:
      case MascotExpression.proud:
        // Gentle smile
        mouthPath.moveTo(cx - 12 * s, mouthY);
        mouthPath.quadraticBezierTo(cx, mouthY + 10 * s, cx + 12 * s, mouthY);
        break;

      case MascotExpression.excited:
        // Big open smile
        mouthPath.moveTo(cx - 15 * s, mouthY - 2 * s);
        mouthPath.quadraticBezierTo(cx, mouthY + 18 * s, cx + 15 * s, mouthY - 2 * s);
        break;

      case MascotExpression.sad:
        // Downturned mouth
        mouthPath.moveTo(cx - 12 * s, mouthY + 5 * s);
        mouthPath.quadraticBezierTo(cx, mouthY - 8 * s, cx + 12 * s, mouthY + 5 * s);
        break;

      case MascotExpression.sleepy:
        // Small "o" (yawning)
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, mouthY + 3 * s),
            width: 10 * s,
            height: 12 * s,
          ),
          mouthPaint,
        );
        return;

      case MascotExpression.encouraging:
        // Warm smile
        mouthPath.moveTo(cx - 10 * s, mouthY);
        mouthPath.quadraticBezierTo(cx, mouthY + 8 * s, cx + 10 * s, mouthY);
        break;

      default:
        // Neutral (slight line)
        mouthPath.moveTo(cx - 8 * s, mouthY + 2 * s);
        mouthPath.lineTo(cx + 8 * s, mouthY + 2 * s);
    }

    canvas.drawPath(mouthPath, mouthPaint);
  }

  void _drawCheeks(Canvas canvas, double cx, double cy, double s) {
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF8E72).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final cheekY = cy - 35 * s;

    // Only show cheeks for happy/excited/proud
    if (expression == MascotExpression.happy ||
        expression == MascotExpression.excited ||
        expression == MascotExpression.proud) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - 30 * s, cheekY),
          width: 14 * s,
          height: 8 * s,
        ),
        cheekPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + 30 * s, cheekY),
          width: 14 * s,
          height: 8 * s,
        ),
        cheekPaint,
      );
    }
  }

  void _drawLimbs(Canvas canvas, double cx, double cy, double s) {
    final limbPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = EmergeColors.cosmicVoidDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s;

    // Front legs
    final leftFront = Path();
    leftFront.addOval(
      Rect.fromCenter(
        center: Offset(cx - 45 * s, cy + 40 * s),
        width: 20 * s,
        height: 14 * s,
      ),
    );
    canvas.drawPath(leftFront, limbPaint);
    canvas.drawPath(leftFront, outlinePaint);

    final rightFront = Path();
    rightFront.addOval(
      Rect.fromCenter(
        center: Offset(cx + 45 * s, cy + 40 * s),
        width: 20 * s,
        height: 14 * s,
      ),
    );
    canvas.drawPath(rightFront, limbPaint);
    canvas.drawPath(rightFront, outlinePaint);

    // Back legs (smaller, peeking from behind shell)
    final leftBack = Path();
    leftBack.addOval(
      Rect.fromCenter(
        center: Offset(cx - 50 * s, cy + 25 * s),
        width: 16 * s,
        height: 12 * s,
      ),
    );
    canvas.drawPath(leftBack, limbPaint);
    canvas.drawPath(leftBack, outlinePaint);

    final rightBack = Path();
    rightBack.addOval(
      Rect.fromCenter(
        center: Offset(cx + 50 * s, cy + 25 * s),
        width: 16 * s,
        height: 12 * s,
      ),
    );
    canvas.drawPath(rightBack, limbPaint);
    canvas.drawPath(rightBack, outlinePaint);

    // Tail (small triangle peeking out)
    final tailPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    final tailPath = Path();
    tailPath.moveTo(cx, cy + 55 * s);
    tailPath.lineTo(cx - 8 * s, cy + 45 * s);
    tailPath.lineTo(cx + 8 * s, cy + 45 * s);
    tailPath.close();
    canvas.drawPath(tailPath, tailPaint);
    canvas.drawPath(tailPath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant KoaPainter oldDelegate) {
    return oldDelegate.expression != expression ||
        oldDelegate.shellPrimary != shellPrimary ||
        oldDelegate.shellAccent != shellAccent;
  }
}
