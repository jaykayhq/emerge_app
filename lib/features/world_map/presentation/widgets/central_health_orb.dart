// lib/features/world_map/presentation/widgets/central_health_orb.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CentralHealthOrb extends StatefulWidget {
  final double currentHealth;
  final double maxHealth;
  final VoidCallback? onTap;
  final VoidCallback? onEasterEggTriggered;

  const CentralHealthOrb({
    super.key,
    required this.currentHealth,
    required this.maxHealth,
    this.onTap,
    this.onEasterEggTriggered,
  });

  @override
  State<CentralHealthOrb> createState() => _CentralHealthOrbState();
}

class _CentralHealthOrbState extends State<CentralHealthOrb> with SingleTickerProviderStateMixin {
  FragmentProgram? _program;
  bool _shaderError = false;
  late Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier(0.0);
  final ValueNotifier<Offset> _pan = ValueNotifier(Offset.zero);
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      _time.value = elapsed.inMilliseconds / 1000.0;
    })..start();
  }

  Future<void> _loadShader() async {
    try {
      final program = await FragmentProgram.fromAsset('shaders/cracked_orb.frag');
      if (mounted) setState(() => _program = program);
    } catch (e) {
      if (mounted) setState(() => _shaderError = true);
    }
  }

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 1)) {
      _tapCount = 1;
    } else {
      _tapCount++;
      if (_tapCount == 7) {
        widget.onEasterEggTriggered?.call();
        _tapCount = 0;
      }
    }
    _lastTapTime = now;
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _pan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shaderError) {
      return Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }
    if (_program == null) return const CircularProgressIndicator();

    final healthPct = (widget.currentHealth / widget.maxHealth).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        _pan.value += details.delta;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth < double.infinity 
              ? constraints.maxWidth * 0.4 
              : 140.0;
          final clampedSize = size.clamp(100.0, 200.0);

          return CustomPaint(
            size: Size(clampedSize, clampedSize),
            painter: _OrbPainter(
              program: _program!,
              time: _time,
              pan: _pan,
              healthPct: healthPct,
            ),
          );
        },
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final FragmentProgram program;
  final ValueNotifier<double> time;
  final ValueNotifier<Offset> pan;
  final double healthPct;

  _OrbPainter({
    required this.program,
    required this.time,
    required this.pan,
    required this.healthPct,
  }) : super(repaint: Listenable.merge([time, pan]));

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time.value);
    shader.setFloat(3, pan.value.dx);
    shader.setFloat(4, pan.value.dy);
    shader.setFloat(5, healthPct);
    
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) {
    return oldDelegate.healthPct != healthPct || oldDelegate.program != program;
  }
}
