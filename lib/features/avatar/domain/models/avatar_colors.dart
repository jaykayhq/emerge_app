import 'dart:ui';

/// Color scheme for an avatar figure.
///
/// Contains skin/base fill, outline/rim accent, eye/details accent,
/// and evolution glow color. Each archetype has a default palette.
class AvatarColors {
  final Color skin;
  final Color outline;
  final Color accent;
  final Color glow;

  const AvatarColors({
    required this.skin,
    required this.outline,
    required this.accent,
    required this.glow,
  });

  AvatarColors copyWith({
    Color? skin,
    Color? outline,
    Color? accent,
    Color? glow,
  }) =>
      AvatarColors(
        skin: skin ?? this.skin,
        outline: outline ?? this.outline,
        accent: accent ?? this.accent,
        glow: glow ?? this.glow,
      );

  // Archetype presets
  factory AvatarColors.hero() => const AvatarColors(
        skin: Color(0xFF12161F),
        outline: Color(0xFF35E0FF),
        accent: Color(0xFFBDF4FF),
        glow: Color(0xFF35E0FF),
      );

  factory AvatarColors.athlete() => const AvatarColors(
        skin: Color(0xFF1A0A0A),
        outline: Color(0xFFFF6B35),
        accent: Color(0xFFFFB26B),
        glow: Color(0xFFFF6B35),
      );

  factory AvatarColors.scholar() => const AvatarColors(
        skin: Color(0xFF0A0A1A),
        outline: Color(0xFFB886FF),
        accent: Color(0xFFDABFFF),
        glow: Color(0xFFB886FF),
      );

  factory AvatarColors.creator() => const AvatarColors(
        skin: Color(0xFF1A1200),
        outline: Color(0xFFFFD600),
        accent: Color(0xFFFFF0B3),
        glow: Color(0xFFFFD600),
      );

  factory AvatarColors.stoic() => const AvatarColors(
        skin: Color(0xFF0A1A16),
        outline: Color(0xFF00E5C7),
        accent: Color(0xFFB3FFF6),
        glow: Color(0xFF00E5C7),
      );

  factory AvatarColors.zealot() => const AvatarColors(
        skin: Color(0xFF1A0A1A),
        outline: Color(0xFFE040FF),
        accent: Color(0xFFFFB3FF),
        glow: Color(0xFFE040FF),
      );

  /// Return the palette for the given archetype string.
  /// Falls back to [hero] for unknown archetypes.
  static AvatarColors forArchetype(String archetype) {
    switch (archetype.toLowerCase()) {
      case 'athlete':
        return AvatarColors.athlete();
      case 'scholar':
        return AvatarColors.scholar();
      case 'creator':
        return AvatarColors.creator();
      case 'stoic':
        return AvatarColors.stoic();
      case 'zealot':
        return AvatarColors.zealot();
      default:
        return AvatarColors.hero();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarColors &&
          skin == other.skin &&
          outline == other.outline &&
          accent == other.accent &&
          glow == other.glow;

  @override
  int get hashCode => Object.hash(skin, outline, accent, glow);
}
