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
  late Ticker _ticker;
  double _time = 0.0;
  Offset _pan = Offset.zero;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
      });
    })..start();
  }

  Future<void> _loadShader() async {
    final program = await FragmentProgram.fromAsset('shaders/cracked_orb.frag');
    if (mounted) setState(() => _program = program);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null) return const CircularProgressIndicator();

    final healthPct = (widget.currentHealth / widget.maxHealth).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: _handleTap,
      onPanUpdate: (details) {
        setState(() {
          _pan += details.delta;
        });
      },
      child: CustomPaint(
        size: const Size(200, 200),
        painter: _OrbPainter(
          program: _program!,
          time: _time,
          pan: _pan,
          healthPct: healthPct,
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final FragmentProgram program;
  final double time;
  final Offset pan;
  final double healthPct;

  _OrbPainter({required this.program, required this.time, required this.pan, required this.healthPct});

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, pan.dx);
    shader.setFloat(4, pan.dy);
    shader.setFloat(5, healthPct);
    
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => true;
}
