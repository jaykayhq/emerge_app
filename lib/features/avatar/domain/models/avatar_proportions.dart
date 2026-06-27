/// Body proportions multipliers for an avatar figure.
///
/// Each archetype has a distinct body silhouette defined as multipliers
/// against the hero/base proportions (1.0 = standard).
class AvatarProportions {
  final double torsoWidth;
  final double armLength;
  final double legLength;
  final double headSize;

  const AvatarProportions({
    required this.torsoWidth,
    required this.armLength,
    required this.legLength,
    required this.headSize,
  });

  factory AvatarProportions.hero() => const AvatarProportions(
        torsoWidth: 1.0,
        armLength: 1.0,
        legLength: 1.0,
        headSize: 1.0,
      );

  factory AvatarProportions.athlete() => const AvatarProportions(
        torsoWidth: 1.15,
        armLength: 1.05,
        legLength: 1.05,
        headSize: 0.9,
      );

  factory AvatarProportions.scholar() => const AvatarProportions(
        torsoWidth: 0.9,
        armLength: 0.95,
        legLength: 0.95,
        headSize: 1.1,
      );

  factory AvatarProportions.creator() => const AvatarProportions(
        torsoWidth: 0.95,
        armLength: 0.95,
        legLength: 1.0,
        headSize: 1.0,
      );

  factory AvatarProportions.stoic() => const AvatarProportions(
        torsoWidth: 1.0,
        armLength: 1.0,
        legLength: 1.0,
        headSize: 1.0,
      );

  factory AvatarProportions.zealot() => const AvatarProportions(
        torsoWidth: 1.05,
        armLength: 1.05,
        legLength: 1.05,
        headSize: 0.95,
      );

  /// Return proportions for the given archetype string.
  /// Falls back to [hero] for unknown archetypes.
  static AvatarProportions forArchetype(String archetype) {
    switch (archetype.toLowerCase()) {
      case 'athlete':
        return AvatarProportions.athlete();
      case 'scholar':
        return AvatarProportions.scholar();
      case 'creator':
        return AvatarProportions.creator();
      case 'stoic':
        return AvatarProportions.stoic();
      case 'zealot':
        return AvatarProportions.zealot();
      default:
        return AvatarProportions.hero();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarProportions &&
          torsoWidth == other.torsoWidth &&
          armLength == other.armLength &&
          legLength == other.legLength &&
          headSize == other.headSize;

  @override
  int get hashCode => Object.hash(torsoWidth, armLength, legLength, headSize);
}
