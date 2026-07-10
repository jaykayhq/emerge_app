// lib/features/world_map/presentation/widgets/central_health_orb.dart
import 'package:flutter/material.dart';

class CentralHealthOrb extends StatelessWidget {
  final double currentHealth;
  final double maxHealth;
  final VoidCallback? onTap;

  const CentralHealthOrb({
    super.key,
    required this.currentHealth,
    required this.maxHealth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Avoid division by zero
    final safeMax = maxHealth > 0 ? maxHealth : 1.0;
    final healthPct = (currentHealth / safeMax).clamp(0.0, 1.0);
    
    // Determine colors based on health state
    Color baseColor;
    Color glowColor;
    
    if (healthPct > 0.6) {
      baseColor = const Color(0xFF00C853); // Green accent
      glowColor = const Color(0x6600E676);
    } else if (healthPct > 0.3) {
      baseColor = const Color(0xFFFFAB00); // Amber accent
      glowColor = const Color(0x66FFD600);
    } else {
      baseColor = const Color(0xFFD50000); // Red accent
      glowColor = const Color(0x66FF1744);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              baseColor.withOpacity(0.8),
              baseColor.withOpacity(0.3),
              Colors.transparent,
            ],
            stops: const [0.4, 0.8, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.white70,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                '${currentHealth.round()} / ${maxHealth.round()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
