import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';

import 'package:flutter/material.dart';

class GrowthBackground extends StatelessWidget {
  final Widget child;
  final bool showPattern;
  final PreferredSizeWidget? appBar;
  final List<Color>? overrideGradient;

  const GrowthBackground({
    super.key,
    required this.child,
    this.showPattern = true,
    this.appBar,
    this.overrideGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      extendBodyBehindAppBar: true,
      backgroundColor: EmergeColors.background, // Ensure base color is correct
      body: Stack(
        children: [
          // 1. Hex Mesh Background (The core Emerge look)
          if (showPattern) const Positioned.fill(child: HexMeshBackground()),

          // 2. Ambient Glow (Subtle)
          if (showPattern)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [
                      EmergeColors.teal.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // 3. Main Content
          SafeArea(child: child),
        ],
      ),
    );
  }
}
