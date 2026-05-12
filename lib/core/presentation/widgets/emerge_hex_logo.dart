import 'package:flutter/material.dart';

/// Emerge Logo Widget - displays the hexagonal app icon with optional sizing.
/// This uses the pre-rendered hexagonal icon with the compact spiral
/// for better mobile appearance.
class EmergeHexLogo extends StatelessWidget {
  final double size;

  const EmergeHexLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(size * 0.15),
      child: Image.asset(
        'assets/icons/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
