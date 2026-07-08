import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart' as emerge_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import 'package:flutter/foundation.dart';

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

    // Generate a welcome card to ensure the pulse feed isn't empty on first load.
    try {
      final user = ref.read(emerge_auth.firebaseAuthProvider).currentUser;
      if (user != null) {
        final firestore = ref.read(emerge_auth.firestoreProvider);
        final cardsRef = firestore
            .collection('pulse_feed_cards')
            .doc(user.uid)
            .collection('cards');
            
        await cardsRef.add({
          'userId': user.uid,
          'type': 'tribeActivity',
          'headline': 'Welcome to the Pulse Feed',
          'subtext': 'This is where you will see updates from your network, challenges, and creator blueprints.',
          'createdAt': cloud_firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (e, stack) {
      // Non-fatal, just log it.
      debugPrint('Failed to generate welcome pulse feed card: $e\n$stack');
    }
  }
}
