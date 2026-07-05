import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/presentation/widgets/cosmic_background.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/widgets/glass_panel.dart';
import 'package:emerge_app/features/social/presentation/providers/social_onboarding_provider.dart';

class SocialOnboardingScreen extends ConsumerWidget {
  const SocialOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CosmicBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EmergeColors.nebulaPrimary.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: EmergeColors.nebulaPrimary.withValues(alpha: 0.2),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: const Icon(Icons.hub_rounded, size: 64, color: EmergeColors.nebulaPrimary),
              ),
            ),
            const Gap(32),
            const Text(
              "YOUR TRIBE AWAITS",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontFamily: 'Syne',
                letterSpacing: 2,
              ),
            ),
            const Gap(16),
            const Text(
              "Every legend belongs to a collective.\nSync to your network.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            const Gap(48),
            _buildOptionCard(
              context,
              title: "ARCHETYPE COLLECTIVE",
              description: "Join millions in the global pool.\n✓ Identity-matched network\n✓ Broad gamified objectives",
              buttonText: "INITIALIZE ARCHETYPE",
              accentColor: EmergeColors.nebulaPrimary,
              icon: Icons.public_rounded,
              onTap: () {
                ref.read(socialOnboardingCompletedProvider.notifier).completeOnboarding();
                context.go('/social');
              },
            ),
            const Gap(24),
            _buildOptionCard(
              context,
              title: "CREATOR CIRCLE",
              description: "Follow an elite creator.\n✓ Curated mission blueprints\n✓ Exclusive tight-knit squad",
              buttonText: "BROWSE CREATORS",
              accentColor: EmergeColors.nebulaSecondary,
              icon: Icons.electric_bolt_rounded,
              onTap: () {
                ref.read(socialOnboardingCompletedProvider.notifier).completeOnboarding();
                // Navigate directly to Discover tab so user can find and follow a creator
                context.go('/social');
              },
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required Color accentColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GlassPanel(
      level: GlassLevel.level2,
      isElectric: true, // we can use the electric border logic
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const Gap(16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 14),
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.15),
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onTap,
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
