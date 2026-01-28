import 'package:flutter/material.dart';

/// Emerge Logo Widget - displays the hexagonal app icon with optional sizing.
/// This uses the pre-rendered hexagonal icon with the compact spiral
/// for better mobile appearance.
class EmergeHexLogo extends StatelessWidget {
  final double size;

  const EmergeHexLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E44AD).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.15),
        child: Image.asset(
          'assets/images/emerge_hex_icon.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
