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
    final theme = Theme.of(context);
    
    // Determine colors based on health state using Theme colors
    Color baseColor;
    Color glowColor;
    
    if (healthPct > 0.6) {
      baseColor = theme.colorScheme.primary; 
      glowColor = theme.colorScheme.primary.withOpacity(0.4);
    } else if (healthPct > 0.3) {
      baseColor = theme.colorScheme.tertiary; 
      glowColor = theme.colorScheme.tertiary.withOpacity(0.4);
    } else {
      baseColor = theme.colorScheme.error; 
      glowColor = theme.colorScheme.error.withOpacity(0.4);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use a fraction of the available width, capped at a reasonable max size.
          // If unconstrained (e.g. in a Row), fallback to 140.
          final size = constraints.maxWidth < double.infinity 
              ? constraints.maxWidth * 0.4 
              : 140.0;
          final clampedSize = size.clamp(100.0, 200.0);

          return Container(
            width: clampedSize,
            height: clampedSize,
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
                  blurRadius: clampedSize * 0.15,
                  spreadRadius: clampedSize * 0.05,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    size: clampedSize * 0.2,
                  ),
                  SizedBox(height: clampedSize * 0.05),
                  Text(
                    '${currentHealth.round()} / ${maxHealth.round()}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
