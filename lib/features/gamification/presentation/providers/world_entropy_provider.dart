import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';

List<String> calculateWorldEntropyEffects(double entropy) {
  if (entropy > 0.3) {
    return ['fog', 'weeds', 'dark_sky'];
  } else if (entropy > 0.1) {
    return ['fog'];
  }
  return [];
}

final worldEntropyProvider = Provider<List<String>>((ref) {
  final profileAsync = ref.watch(userStatsStreamProvider);
  return profileAsync.maybeWhen(
    data: (profile) => calculateWorldEntropyEffects(profile.worldState.entropy),
    orElse: () => [],
  );
});
