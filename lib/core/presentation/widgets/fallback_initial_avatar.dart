import 'package:flutter/material.dart';

/// Circle avatar that renders a user's initials over a stable per-name gradient.
///
/// If [imageUrl] is non-null, it is layered over the gradient fallback via
/// [NetworkImage]. Otherwise the initials of [name] are rendered on top of
/// an [HSLColor]-derived gradient so the same name always gets the same
/// colors. If [name] is empty, the widget falls back to [Icons.person_rounded].
class FallbackInitialAvatar extends StatelessWidget {
  final String? name;
  final double size;
  final String? imageUrl;
  final Color? seedColor;
  final Color borderColor;
  final double borderWidth;

  const FallbackInitialAvatar({
    super.key,
    this.name,
    this.size = 48,
    this.imageUrl,
    this.seedColor,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
  });

  String _initials(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';
    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.characters.first.length).toUpperCase();
    }
    final first = parts.first.characters.first;
    final last = parts.last.characters.first;
    return (first + last).toUpperCase();
  }

  List<Color> _colorsFor(String? seed) {
    final base = seedColor ??
        HSLColor.fromAHSL(
          1.0,
          (seed?.codeUnits.fold<int>(0, (a, b) => a + b) ?? 0) % 360,
          0.55,
          0.45,
        ).toColor();
    final hsl = HSLColor.fromColor(base);
    return [
      hsl.withLightness(0.35).toColor(),
      hsl.withLightness(0.55).toColor(),
    ];
  }

  Widget _buildFallbackBox() {
    final initials = _initials(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _colorsFor(name),
        ),
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      alignment: Alignment.center,
      child: initials.isEmpty
          ? Icon(
              Icons.person_rounded,
              color: Colors.white.withValues(alpha: 0.85),
              size: size * 0.55,
            )
          : Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _buildFallbackBox();
    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    // Layer the network image on top of the gradient fallback so it remains
    // visible while loading or on network failure.
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            fallback,
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox.shrink();
              },
            ),
            if (borderWidth > 0)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
