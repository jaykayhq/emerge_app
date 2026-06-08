import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// The Identity Engine analyzes user behavioral patterns and votes
/// to determine their core identity archetype within the Emerge system.
class IdentityEngine {
  /// Analyzes the user's accumulated identity votes and returns the dominant archetype.
  /// If there is a tie, it resolves it deterministically (alphabetical order).
  /// If there are no votes, it returns [UserArchetype.none].
  static UserArchetype calculateDominantArchetype(Map<String, int> identityVotes) {
    if (identityVotes.isEmpty) {
      return UserArchetype.none;
    }

    String dominantKey = '';
    int maxVotes = -1;

    // Sort keys alphabetically to ensure deterministic tie-breaking
    final sortedKeys = identityVotes.keys.toList()..sort();

    for (final key in sortedKeys) {
      final votes = identityVotes[key]!;
      if (votes > maxVotes) {
        maxVotes = votes;
        dominantKey = key;
      }
    }

    // Map the string key back to the enum.
    // Handles cases where keys might be capitalized (e.g., 'Athlete').
    final normalizedKey = dominantKey.toLowerCase();
    
    return UserArchetype.values.firstWhere(
      (a) => a.name == normalizedKey,
      orElse: () => UserArchetype.none,
    );
  }
}
