import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final socialOnboardingCompletedProvider = StateNotifierProvider<SocialOnboardingNotifier, bool>((ref) {
  return SocialOnboardingNotifier();
});

class SocialOnboardingNotifier extends StateNotifier<bool> {
  SocialOnboardingNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('social_onboarding_complete') ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('social_onboarding_complete', true);
    state = true;
  }
}
