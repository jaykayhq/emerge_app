import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final socialOnboardingCompletedProvider = AsyncNotifierProvider<SocialOnboardingNotifier, bool>(() {
  return SocialOnboardingNotifier();
});

class SocialOnboardingNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('social_onboarding_complete') ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('social_onboarding_complete', true);
    state = const AsyncData(true);
  }
}
