/// One enforced free-tier limit, as listed on the paywall and in
/// docs/FREEMIUM_MODEL.md. Deliberately UI-free: the presentation layer
/// resolves icons/colors/dialog enums from [featureKey] / [dialogCopyKey].
class FreeTierLimit {
  /// Stable key: 'habits' | 'clubs' | 'coachAsk' | 'themes'.
  final String featureKey;

  /// Free-tier cap value (habits=5, clubs=1, coachAsk=3/day, themes=1).
  final int freeValue;

  /// Human unit for the free value, e.g. 'active habits'.
  final String unit;

  /// Whether premium removes this cap. False for themes: SP-C locks them
  /// as 'coming soon' for everyone — not a premium bypass.
  final bool premiumBypasses;

  /// Key into `PremiumLimitType` (premium_limit_dialog.dart) or null when
  /// the limit has no premium dialog (themes). The dialog enum lives in the
  /// presentation layer; the catalog only carries the key string.
  final String? dialogCopyKey;

  /// Paywall offer headline, e.g. 'UNLIMITED HABITS'.
  final String paywallTitle;

  /// Honest paywall offer subtitle, e.g. 'Free: 5 active habits · Premium: no cap'.
  final String paywallSubtitle;

  /// Who enforces this: 'remote_config' | 'code' | 'SP-C'.
  final String enforcedBy;

  const FreeTierLimit({
    required this.featureKey,
    required this.freeValue,
    required this.unit,
    required this.premiumBypasses,
    required this.dialogCopyKey,
    required this.paywallTitle,
    required this.paywallSubtitle,
    required this.enforcedBy,
  });
}

/// Single source of truth for every enforced free-tier limit.
///
/// Drives the paywall offer copy and must stay in sync with
/// docs/FREEMIUM_MODEL.md. Runtime enforcement keeps its own
/// configuration (Remote Config `free_habit_limit`, CoachAskQuota, club
/// join gate); the catalog is the declared product surface.
class LimitsCatalog {
  static const FreeTierLimit habits = FreeTierLimit(
    featureKey: 'habits',
    freeValue: 5,
    unit: 'active habits',
    premiumBypasses: true,
    dialogCopyKey: 'habit',
    paywallTitle: 'UNLIMITED HABITS',
    paywallSubtitle: 'Free: 5 active habits · Premium: no cap',
    enforcedBy: 'remote_config',
  );

  static const FreeTierLimit clubs = FreeTierLimit(
    featureKey: 'clubs',
    freeValue: 1,
    unit: 'club',
    premiumBypasses: true,
    dialogCopyKey: 'club',
    paywallTitle: 'UNLIMITED CLUBS',
    paywallSubtitle: 'Free: 1 club · Premium: no cap',
    enforcedBy: 'code',
  );

  static const FreeTierLimit coachAsk = FreeTierLimit(
    featureKey: 'coachAsk',
    freeValue: 3,
    unit: 'coach asks/day',
    premiumBypasses: true,
    dialogCopyKey: 'coachAsk',
    paywallTitle: 'UNLIMITED COACH ASKS',
    paywallSubtitle: 'Free: 3 asks/day · Premium: unlimited',
    enforcedBy: 'code',
  );

  /// SP-C locks 5 of 6 themes as 'coming soon'; nebula is the free theme.
  static const FreeTierLimit themes = FreeTierLimit(
    featureKey: 'themes',
    freeValue: 1,
    unit: 'world theme',
    premiumBypasses: false,
    dialogCopyKey: null,
    paywallTitle: 'MORE WORLD THEMES',
    paywallSubtitle: 'Free: 1 theme · 5 more coming soon',
    enforcedBy: 'SP-C',
  );

  static const List<FreeTierLimit> all = [habits, clubs, coachAsk, themes];

  static FreeTierLimit? forFeature(String featureKey) {
    for (final limit in all) {
      if (limit.featureKey == featureKey) return limit;
    }
    return null;
  }
}
