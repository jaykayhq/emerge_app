import 'package:emerge_app/features/gamification/domain/entities/reward_item.dart';

/// Static catalog of all available rewards in Emerge.
/// Titles, Nameplates, and Emblems — organized by rarity and source.
class RewardCatalog {
  RewardCatalog._();

  // ===================== TITLES =====================

  // --- Common Titles (Milestone-based) ---
  static const titleInitiate = RewardItem(
    id: 'title_initiate',
    name: 'The Initiate',
    type: RewardType.title,
    rarity: RewardRarity.common,
    source: RewardSource.milestone,
    displayValue: ', The Initiate',
    description: 'Complete your first habit.',
    levelRequirement: 1,
  );

  static const titleFocused = RewardItem(
    id: 'title_focused',
    name: 'The Focused',
    type: RewardType.title,
    rarity: RewardRarity.common,
    source: RewardSource.milestone,
    displayValue: ', The Focused',
    description: 'Reach a 3-day streak.',
    levelRequirement: 1,
  );

  static const titleDisciplined = RewardItem(
    id: 'title_disciplined',
    name: 'The Disciplined',
    type: RewardType.title,
    rarity: RewardRarity.common,
    source: RewardSource.milestone,
    displayValue: ', The Disciplined',
    description: 'Complete 10 habits.',
    levelRequirement: 2,
  );

  // --- Rare Titles (Consistency-based) ---
  static const titleUnyielding = RewardItem(
    id: 'title_unyielding',
    name: 'The Unyielding',
    type: RewardType.title,
    rarity: RewardRarity.rare,
    source: RewardSource.milestone,
    displayValue: ', The Unyielding',
    description: 'Reach a 7-day streak.',
    levelRequirement: 3,
  );

  static const titleIronclad = RewardItem(
    id: 'title_ironclad',
    name: 'Ironclad',
    type: RewardType.title,
    rarity: RewardRarity.rare,
    source: RewardSource.milestone,
    displayValue: 'Ironclad ',
    description: 'Reach a 14-day streak.',
    levelRequirement: 4,
  );

  static const titleRelentless = RewardItem(
    id: 'title_relentless',
    name: 'The Relentless',
    type: RewardType.title,
    rarity: RewardRarity.rare,
    source: RewardSource.challenge,
    displayValue: ', The Relentless',
    description: 'Complete 3 challenges.',
    levelRequirement: 3,
  );

  // --- Epic Titles (Major achievements) ---
  static const titleAscendant = RewardItem(
    id: 'title_ascendant',
    name: 'The Ascendant',
    type: RewardType.title,
    rarity: RewardRarity.epic,
    source: RewardSource.milestone,
    displayValue: ', The Ascendant',
    description: 'Reach Level 5.',
    levelRequirement: 5,
  );

  static const titleEmerged = RewardItem(
    id: 'title_emerged',
    name: 'Emerged',
    type: RewardType.title,
    rarity: RewardRarity.epic,
    source: RewardSource.milestone,
    displayValue: 'Emerged ',
    description: 'Complete the Emerge gate.',
    levelRequirement: 5,
  );

  static const titleForgemaster = RewardItem(
    id: 'title_forgemaster',
    name: 'Forgemaster',
    type: RewardType.title,
    rarity: RewardRarity.epic,
    source: RewardSource.milestone,
    displayValue: 'Forgemaster ',
    description: 'Reach a 30-day streak.',
    levelRequirement: 5,
  );

  static const titleReferrer = RewardItem(
    id: 'title_referrer',
    name: 'The Connector',
    type: RewardType.title,
    rarity: RewardRarity.rare,
    source: RewardSource.referral,
    displayValue: ', The Connector',
    description: 'Refer 5 friends.',
    levelRequirement: 2,
  );

  // --- Legendary Titles (IAP or extreme milestones) ---
  static const titleGilded = RewardItem(
    id: 'title_gilded',
    name: 'The Gilded',
    type: RewardType.title,
    rarity: RewardRarity.legendary,
    source: RewardSource.purchase,
    displayValue: ', The Gilded',
    description: 'Premium title — The Bazaar exclusive.',
    iapProductId: 'emerge_title_gilded',
  );

  static const titleUntouchable = RewardItem(
    id: 'title_untouchable',
    name: 'The Untouchable',
    type: RewardType.title,
    rarity: RewardRarity.legendary,
    source: RewardSource.purchase,
    displayValue: ', The Untouchable',
    description: 'Premium title — The Bazaar exclusive.',
    iapProductId: 'emerge_title_untouchable',
  );

  static const titleEternal = RewardItem(
    id: 'title_eternal',
    name: 'The Eternal',
    type: RewardType.title,
    rarity: RewardRarity.legendary,
    source: RewardSource.milestone,
    displayValue: ', The Eternal',
    description: 'Reach a 100-day streak.',
    levelRequirement: 8,
  );

  // ===================== NAMEPLATES =====================

  static const nameplateDefault = RewardItem(
    id: 'nameplate_default',
    name: 'Standard',
    type: RewardType.nameplate,
    rarity: RewardRarity.common,
    source: RewardSource.milestone,
    displayValue: 'default',
    description: 'Default nameplate.',
  );

  static const nameplateEmber = RewardItem(
    id: 'nameplate_ember',
    name: 'Ember Glow',
    type: RewardType.nameplate,
    rarity: RewardRarity.rare,
    source: RewardSource.milestone,
    displayValue: 'ember',
    description: 'Reach a 7-day streak.',
    levelRequirement: 3,
  );

  static const nameplateAurora = RewardItem(
    id: 'nameplate_aurora',
    name: 'Aurora',
    type: RewardType.nameplate,
    rarity: RewardRarity.epic,
    source: RewardSource.milestone,
    displayValue: 'aurora',
    description: 'Reach Level 5.',
    levelRequirement: 5,
  );

  static const nameplateVoidStar = RewardItem(
    id: 'nameplate_voidstar',
    name: 'Void Star',
    type: RewardType.nameplate,
    rarity: RewardRarity.legendary,
    source: RewardSource.purchase,
    displayValue: 'voidstar',
    description: 'Premium nameplate — The Bazaar exclusive.',
    iapProductId: 'emerge_nameplate_voidstar',
  );

  static const nameplateNebula = RewardItem(
    id: 'nameplate_nebula',
    name: 'Nebula',
    type: RewardType.nameplate,
    rarity: RewardRarity.legendary,
    source: RewardSource.purchase,
    displayValue: 'nebula',
    description: 'Premium nameplate — The Bazaar exclusive.',
    iapProductId: 'emerge_nameplate_nebula',
  );

  // ===================== EMBLEMS =====================

  static const emblemFirstStep = RewardItem(
    id: 'emblem_first_step',
    name: 'First Step',
    type: RewardType.emblem,
    rarity: RewardRarity.common,
    source: RewardSource.milestone,
    displayValue: '🌱',
    description: 'Complete your first habit.',
  );

  static const emblemStreak7 = RewardItem(
    id: 'emblem_streak_7',
    name: '7-Day Flame',
    type: RewardType.emblem,
    rarity: RewardRarity.rare,
    source: RewardSource.milestone,
    displayValue: '🔥',
    description: 'Reach a 7-day streak.',
    levelRequirement: 2,
  );

  static const emblemStreak30 = RewardItem(
    id: 'emblem_streak_30',
    name: '30-Day Inferno',
    type: RewardType.emblem,
    rarity: RewardRarity.epic,
    source: RewardSource.milestone,
    displayValue: '⚡',
    description: 'Reach a 30-day streak.',
    levelRequirement: 4,
  );

  static const emblemContractKeeper = RewardItem(
    id: 'emblem_contract_keeper',
    name: 'Contract Keeper',
    type: RewardType.emblem,
    rarity: RewardRarity.rare,
    source: RewardSource.milestone,
    displayValue: '🤝',
    description: 'Complete 3 accountability contracts.',
    levelRequirement: 3,
  );

  // ===================== FULL CATALOG =====================

  static const List<RewardItem> all = [
    // Titles
    titleInitiate,
    titleFocused,
    titleDisciplined,
    titleUnyielding,
    titleIronclad,
    titleRelentless,
    titleAscendant,
    titleEmerged,
    titleForgemaster,
    titleReferrer,
    titleGilded,
    titleUntouchable,
    titleEternal,
    // Nameplates
    nameplateDefault,
    nameplateEmber,
    nameplateAurora,
    nameplateVoidStar,
    nameplateNebula,
    // Emblems
    emblemFirstStep,
    emblemStreak7,
    emblemStreak30,
    emblemContractKeeper,
  ];

  /// Get all rewards of a specific type.
  static List<RewardItem> byType(RewardType type) {
    return all.where((r) => r.type == type).toList();
  }

  /// Get all rewards of a specific rarity.
  static List<RewardItem> byRarity(RewardRarity rarity) {
    return all.where((r) => r.rarity == rarity).toList();
  }

  /// Get all rewards from a specific source.
  static List<RewardItem> bySource(RewardSource source) {
    return all.where((r) => r.source == source).toList();
  }

  /// Get reward by ID, or null if not found.
  static RewardItem? getById(String id) {
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all purchasable rewards (IAP).
  static List<RewardItem> get purchasable {
    return all.where((r) => r.iapProductId != null).toList();
  }

  /// Get all rewards available at a specific level.
  static List<RewardItem> availableAtLevel(int level) {
    return all.where((r) => r.levelRequirement <= level).toList();
  }
}
