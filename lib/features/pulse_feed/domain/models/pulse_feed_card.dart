/// The type of card displayed in the Pulse Feed.
///
/// Each type has a distinct visual treatment (badge colour, icon).
enum PulseFeedCardType {
  /// Someone voted on your identity tags.
  identityVote,

  /// Activity within your tribe (someone completed a habit, etc.).
  tribeActivity,

  /// AI-generated weekly insight about your habits or identity.
  weeklyInsight,
}

/// A single card in the Pulse Feed — the identity-reinforcing feed that
/// replaces the Tribe Lobby.
///
/// Cards are stored in Firestore under
/// `pulse_feed_cards/{userId}/cards/{cardId}`.
class PulseFeedCard {
  final String id;
  final PulseFeedCardType type;
  final String headline;
  final String? subtext;
  final DateTime createdAt;
  final String? habitId;
  final String? tribeUserId;

  const PulseFeedCard({
    required this.id,
    required this.type,
    required this.headline,
    this.subtext,
    required this.createdAt,
    this.habitId,
    this.tribeUserId,
  });

  factory PulseFeedCard.fromJson(Map<String, dynamic> json) {
    return PulseFeedCard(
      id: json['id'] as String? ?? '',
      type: PulseFeedCardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PulseFeedCardType.tribeActivity,
      ),
      headline: json['headline'] as String? ?? '',
      subtext: json['subtext'] as String?,
      createdAt: (json['createdAt'] as dynamic) is String
          ? DateTime.parse(json['createdAt'] as String)
          : (json['createdAt'] as dynamic) is num
              ? DateTime.fromMillisecondsSinceEpoch(
                  (json['createdAt'] as num).toInt(),
                )
              : DateTime.now(),
      habitId: json['habitId'] as String?,
      tribeUserId: json['tribeUserId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'headline': headline,
      if (subtext != null) 'subtext': subtext,
      'createdAt': createdAt.toIso8601String(),
      if (habitId != null) 'habitId': habitId,
      if (tribeUserId != null) 'tribeUserId': tribeUserId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PulseFeedCard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          headline == other.headline &&
          subtext == other.subtext &&
          createdAt == other.createdAt &&
          habitId == other.habitId &&
          tribeUserId == other.tribeUserId;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        headline,
        subtext,
        createdAt,
        habitId,
        tribeUserId,
      );

  @override
  String toString() =>
      'PulseFeedCard(id: $id, type: ${type.name}, headline: $headline)';
}
