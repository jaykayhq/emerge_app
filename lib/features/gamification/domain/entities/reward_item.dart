import 'package:equatable/equatable.dart';

/// Types of rewards in Emerge.
enum RewardType {
  /// Title: e.g., "The Unyielding", displayed after display name.
  title,

  /// Nameplate: background card style for friends list / leaderboard.
  nameplate,

  /// Emblem: icon/badge displayed on profile.
  emblem,
}

/// Rarity tiers for rewards.
enum RewardRarity {
  /// Earned through basic milestones.
  common,

  /// Earned through consistency (streaks, challenges).
  rare,

  /// Earned through major achievements.
  epic,

  /// IAP-exclusive or extremely rare milestones.
  legendary,
}

/// How a reward is obtained.
enum RewardSource {
  /// Earned by reaching a milestone (level, streak, etc.).
  milestone,

  /// Earned by completing a challenge.
  challenge,

  /// Earned through referral program.
  referral,

  /// Purchased via IAP.
  purchase,
}

/// A single reward item in the Emerge reward catalog.
class RewardItem extends Equatable {
  final String id;
  final String name;
  final RewardType type;
  final RewardRarity rarity;
  final RewardSource source;

  /// For titles: the prefix/suffix text. For nameplates: gradient key.
  final String displayValue;

  /// Human-readable description of how to earn or what it represents.
  final String description;

  /// Minimum level required (0 = no requirement).
  final int levelRequirement;

  /// Archetype restriction (null = any archetype).
  final String? archetypeId;

  /// IAP product ID if this is a purchasable reward.
  final String? iapProductId;

  /// Price in XP if purchasable via in-game currency (0 = not purchasable).
  final int xpCost;

  /// Whether this item is currently available in the catalog.
  final bool isAvailable;

  const RewardItem({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.source,
    required this.displayValue,
    this.description = '',
    this.levelRequirement = 0,
    this.archetypeId,
    this.iapProductId,
    this.xpCost = 0,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rarity': rarity.name,
      'source': source.name,
      'displayValue': displayValue,
      'description': description,
      'levelRequirement': levelRequirement,
      'archetypeId': archetypeId,
      'iapProductId': iapProductId,
      'xpCost': xpCost,
      'isAvailable': isAvailable,
    };
  }

  factory RewardItem.fromMap(Map<String, dynamic> map) {
    return RewardItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: RewardType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RewardType.title,
      ),
      rarity: RewardRarity.values.firstWhere(
        (e) => e.name == map['rarity'],
        orElse: () => RewardRarity.common,
      ),
      source: RewardSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => RewardSource.milestone,
      ),
      displayValue: map['displayValue'] ?? '',
      description: map['description'] ?? '',
      levelRequirement: map['levelRequirement']?.toInt() ?? 0,
      archetypeId: map['archetypeId'],
      iapProductId: map['iapProductId'],
      xpCost: map['xpCost']?.toInt() ?? 0,
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    rarity,
    source,
    displayValue,
    description,
    levelRequirement,
    archetypeId,
    iapProductId,
    xpCost,
    isAvailable,
  ];
}
