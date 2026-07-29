import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// First-screen interstitial shown once after sign-up to "endow" the new
/// user with the starter goods they already own (habit pack, tribe, world map).
class EndowmentInterstitialScreen extends ConsumerWidget {
  final String userName;

  const EndowmentInterstitialScreen({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EmergeColors.cosmicVoidDark,
              EmergeColors.cosmicVoidCenter,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                AnimatedOnboardingProgressBar(
                  targetProgress: 0.2,
                  label: onboardingLabelFor(0.2),
                ),
                const Text('✨', style: TextStyle(fontSize: 48)),
                const Gap(16),
                Text(
                  'Welcome, $userName',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Gap(8),
                Text(
                  'Your world seed is planted.\nHere\'s what you already have:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const Gap(32),
                const _EndowmentItem(
                  emoji: '🎁',
                  title: 'Starter habit pack',
                  subtitle: 'reserved for you',
                ),
                const Gap(12),
                const _EndowmentItem(
                  emoji: '🏟️',
                  title: 'Archetype tribe',
                  subtitle: 'waiting for you',
                ),
                const Gap(12),
                const _EndowmentItem(
                  emoji: '🌍',
                  title: 'Your world map',
                  subtitle: 'ready to grow',
                ),
                const Gap(40),
                ElevatedButton(
                  onPressed: () async {
                    // Mark the one-time interstitial as seen so the router
                    // won't route back here on the next redirect.
                    await ref
                        .read(localSettingsRepositoryProvider)
                        .markEndowmentSeen();
                    if (context.mounted) {
                      context.go('/onboarding/identity-studio');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'BEGIN FORGING →',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single endowment row: emoji badge + title + subtitle.
class _EndowmentItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _EndowmentItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Gap(2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
