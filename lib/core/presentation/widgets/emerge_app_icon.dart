import 'package:flutter/material.dart';

/// Emerge App Icon Widget - displays the new stylized flame app icon with a sleek rounded rectangle clip
/// and a subtle glow matching the inner fire aesthetic.
class EmergeAppIcon extends StatelessWidget {
  final double size;

  const EmergeAppIcon({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          size * 0.22,
        ), // Standard app icon rounding
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF2BEE79,
            ).withValues(alpha: 0.2), // Subtle green glow
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(
              0xFF8E44AD,
            ).withValues(alpha: 0.2), // Subtle purple glow
            blurRadius: 25,
            spreadRadius: -2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/icons/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
