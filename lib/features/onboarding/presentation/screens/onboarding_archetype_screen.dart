import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/data/services/remote_config_service.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingArchetypeScreen extends ConsumerStatefulWidget {
  const OnboardingArchetypeScreen({super.key});

  @override
  ConsumerState<OnboardingArchetypeScreen> createState() =>
      _OnboardingArchetypeScreenState();
}

class _OnboardingArchetypeScreenState
    extends ConsumerState<OnboardingArchetypeScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.75);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch archetypes from Remote Config
    final config = ref.watch(remoteConfigServiceProvider).getOnboardingConfig();
    final archetypes = config.archetypes;
    final selectedArchetype = ref.watch(selectedArchetypeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Step 1 of 3: Choose Your North Star',
          style: GoogleFonts.splineSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              // Skip this milestone and go to next
              await ref
                  .read(onboardingControllerProvider.notifier)
                  .skipMilestone(0);
              if (context.mounted) {
                context.go('/'); // Return to timeline
              }
            },
            child: Text(
              'Skip for now',
              style: GoogleFonts.splineSans(
                color: AppTheme.slateBlue,
                fontSize: 14,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 1 / 3, // Step 1 of 3
            backgroundColor: AppTheme.surfaceDark,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.vitalityGreen,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: archetypes.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final archetype = archetypes[index];
                final isFocused = index == _currentPage;
                final isSelected = selectedArchetype?.name == archetype.id;

                return GestureDetector(
                  onTap: () {
                    // Map string ID to UserArchetype enum
                    final userArchetype = UserArchetype.values.firstWhere(
                      (e) => e.name == archetype.id,
                      orElse: () => UserArchetype.none,
                    );

                    ref
                        .read(onboardingStateProvider.notifier)
                        .update(
                          (state) =>
                              state.copyWith(selectedArchetype: userArchetype),
                        );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuint,
                    margin: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: isFocused ? 0 : 30,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                            child: archetype.imageUrl.startsWith('http')
                                ? Image.network(
                                    archetype.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      );
                                    },
                                  )
                                : Image.asset(
                                    archetype.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  archetype.title,
                                  style: GoogleFonts.splineSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  archetype.description,
                                  style: GoogleFonts.splineSans(
                                    fontSize: 14,
                                    color: const Color(0xFF92C9A8),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select a card to learn more.',
            style: GoogleFonts.splineSans(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: AppTheme.primary,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: selectedArchetype != null
                      ? () async {
                          // Complete milestone and go to next step
                          await ref
                              .read(onboardingControllerProvider.notifier)
                              .completeMilestone(0);
                          if (context.mounted) {
                            context.push(
                              '/onboarding/anchors',
                            ); // Go to next step
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(28),
                  child: Center(
                    child: Text(
                      'Begin My Journey',
                      style: GoogleFonts.splineSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.backgroundDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
