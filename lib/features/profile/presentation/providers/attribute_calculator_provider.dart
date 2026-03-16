import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider family for calculating attributes
/// Memoizes calculations to prevent recalculating on every rebuild
final attributeCalculatorProvider = Provider.family<AttributeValues, UserAvatarStats>((ref, stats) {
  return _calculateAttributes(stats);
});

/// Wrapper class for attribute calculations
/// Used for clean API and to avoid Map type issues
class AttributeValues {
  final double strength;
  final double intellect;
  final double creativity;
  final double focus;
  final double vitality;
  final double spirit;
  final double resilience;

  const AttributeValues({
    required this.strength,
    required this.intellect,
    required this.creativity,
    required this.focus,
    required this.vitality,
    required this.spirit,
    required this.resilience,
  });

  double operator [](String key) {
    switch (key) {
      case 'Strength': return strength;
      case 'Intellect': return intellect;
      case 'Creativity': return creativity;
      case 'Focus': return focus;
      case 'Vitality': return vitality;
      case 'Spirit': return spirit;
      case 'Resilience': return resilience;
      default: return 0.0;
    }
  }
  
  /// Create from map for backwards compatibility
  factory AttributeValues.fromMap(Map<String, double> map) {
    return AttributeValues(
      strength: map['Strength'] ?? 0.0,
      intellect: map['Intellect'] ?? 0.0,
      creativity: map['Creativity'] ?? 0.0,
      focus: map['Focus'] ?? 0.0,
      vitality: map['Vitality'] ?? 0.0,
      spirit: map['Spirit'] ?? 0.0,
      resilience: map['Resilience'] ?? 0.0,
    );
  }
}

/// Calculate normalized attribute values (0.0 to 1.0)
/// Used for avatar aura intensity and visual feedback
AttributeValues _calculateAttributes(UserAvatarStats stats) {
  // Determine the max xp scaling based on the highest attribute, with a minimum floor
  final highestAttributeXp = [
    stats.strengthXp,
    stats.intellectXp,
    stats.creativityXp,
    stats.focusXp,
    stats.vitalityXp,
    stats.spiritXp,
  ].reduce((a, b) => a > b ? a : b);

  // Scale dynamically, but ensure at least level 1 max (500)
  final maxXp = highestAttributeXp > 500.0
      ? highestAttributeXp.toDouble()
      : 500.0;

  return AttributeValues(
    strength: (stats.strengthXp / maxXp).clamp(0.0, 1.0),
    intellect: (stats.intellectXp / maxXp).clamp(0.0, 1.0),
    creativity: (stats.creativityXp / maxXp).clamp(0.0, 1.0),
    focus: (stats.focusXp / maxXp).clamp(0.0, 1.0),
    vitality: (stats.vitalityXp / maxXp).clamp(0.0, 1.0),
    spirit: (stats.spiritXp / maxXp).clamp(0.0, 1.0),
    resilience: ((stats.strengthXp + stats.focusXp) / 2 / maxXp).clamp(
      0.0,
      1.0,
    ),
  );
}
