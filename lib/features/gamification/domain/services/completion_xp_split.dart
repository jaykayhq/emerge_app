/// Pure per-channel XP split for a habit/challenge completion.
///
/// Credit and undo MUST debit exactly what was credited, per channel
/// (SP-G D5/D6). `user_stats` receives base + challenge XP; tribe totals
/// and contributor records only ever receive base XP (challenge XP reaches
/// tribe totals via the server recalc, which sums user_stats.totalXp).
class CompletionXpSplit {
  final int xpGained;
  final int challengeXp;

  const CompletionXpSplit({required this.xpGained, required this.challengeXp});

  /// Mirror constructor for the undo side (values come from a stored
  /// completion row's `xpGained`/`challengeXp` fields).
  const factory CompletionXpSplit.fromStoredRow({
    required int xpGained,
    required int challengeXp,
  }) = CompletionXpSplit._undo;

  /// What user_stats is credited (and debited on undo).
  int get userStatsDelta => xpGained + challengeXp;

  /// What tribe totals/contributors are credited (and debited on undo).
  int get tribeDelta => xpGained;

  const CompletionXpSplit._undo({
    required int xpGained,
    required int challengeXp,
  }) : xpGained = -xpGained,
       challengeXp = -challengeXp;
}

/// The single `user_stats` enqueue shape used by the credit path
/// (completeHabit, challenge completion) AND the undo path, so credit and
/// debit can never drift apart. Mirrors the local Drift
/// updateAttributeXp semantics (totalXp + attribute bucket move together).
Map<String, dynamic> buildUserStatsXpPayload({
  required int totalDelta,
  required String attr,
  required int level,
  required int streak,
  required String updatedAt,
}) => {
  'avatarStats.totalXp': {'__type__': 'increment', 'value': totalDelta},
  'avatarStats.level': level,
  'avatarStats.streak': streak,
  'avatarStats.${attr}Xp': {'__type__': 'increment', 'value': totalDelta},
  'updatedAt': updatedAt,
};
