import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/providers/social_onboarding_provider.dart';

class SocialOnboardingScreen extends ConsumerWidget {
  const SocialOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: EmergeColors.cosmicVoidDark), // Updated theme import
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "YOUR TRIBE AWAITS",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Every legend belongs to a tribe. Choose yours.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),
                _buildOptionCard(
                  context,
                  title: "🏛️ ARCHETYPE TRIBE",
                  description: "Join thousands of Scholars, Athletes, Creators & more.\n✓ Matched to your identity\n✓ Global community",
                  buttonText: "JOIN ARCHETYPE TRIBE",
                  onTap: () {
                    ref.read(socialOnboardingCompletedProvider.notifier).completeOnboarding();
                    context.go('/social');
                  },
                ),
                const SizedBox(height: 24),
                _buildOptionCard(
                  context,
                  title: "⚡ CREATOR TRIBE",
                  description: "Follow a verified creator. Adopt their exact blueprint.\n✓ Curated habit blueprint\n✓ Tight-knit community",
                  buttonText: "BROWSE CREATORS",
                  onTap: () {
                    ref.read(socialOnboardingCompletedProvider.notifier).completeOnboarding();
                    context.go('/social');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, {required String title, required String description, required String buttonText, required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(color: Colors.white70, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
