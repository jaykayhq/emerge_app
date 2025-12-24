import 'package:flutter/material.dart';

class WorldVisualizer extends StatelessWidget {
  final int stage;

  const WorldVisualizer({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    // Determine image asset based on stage
    // Assuming stage 1-5 maps to forest_stage_1.png to forest_stage_5.png
    // Clamping to ensure valid range
    final safeStage = stage.clamp(1, 5);
    final imagePath = 'assets/images/forest_stage_$safeStage.png';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Image.asset(
        imagePath,
        key: ValueKey<String>(imagePath), // Key is crucial for AnimatedSwitcher
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to gradient container if image fails
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1a472a),
                  const Color(0xFF2d5a27),
                  const Color(0xFF3d7a2a),
                ],
              ),
            ),
            child: const Center(
              child: Icon(Icons.park, size: 64, color: Colors.white30),
            ),
          );
        },
      ),
    );
  }
}
