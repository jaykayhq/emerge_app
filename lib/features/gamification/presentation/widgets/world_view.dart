import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class WorldView extends StatelessWidget {
  final UserWorldState worldState;
  final bool isCity; // true for City, false for Forest

  const WorldView({super.key, required this.worldState, required this.isCity});

  @override
  Widget build(BuildContext context) {
    final level = isCity ? worldState.cityLevel : worldState.forestLevel;
    final entropy = worldState.entropy;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isCity ? Colors.blueGrey[900] : Colors.green[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background (Sky/Environment)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/dashboard_card_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to a gradient if the asset fails to load
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isCity ? Colors.blueGrey[800]! : Colors.green[800]!,
                          isCity ? Colors.blueGrey[900]! : Colors.green[900]!,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Entropy Overlay (Fog/Smog)
          if (entropy > 0)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: (isCity ? Colors.grey : Colors.brown).withValues(
                    alpha: entropy * 0.8,
                  ), // Opacity based on entropy
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

          // World Elements (Placeholder for Lottie/Assets)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon removed as replaced by background image
                const Gap(8),
                const Gap(8),
                Text(
                  'Level $level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                  ),
                ),
                if (entropy > 0.3)
                  Text(
                    isCity ? 'Smog Alert!' : 'Forest Decay!',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
