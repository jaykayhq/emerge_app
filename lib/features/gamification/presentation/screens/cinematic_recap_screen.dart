import 'dart:io';

import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/world_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class CinematicRecapScreen extends ConsumerStatefulWidget {
  const CinematicRecapScreen({super.key});

  @override
  ConsumerState<CinematicRecapScreen> createState() =>
      _CinematicRecapScreenState();
}

class _CinematicRecapScreenState extends ConsumerState<CinematicRecapScreen> {
  final PageController _pageController = PageController();
  final ScreenshotController _screenshotController = ScreenshotController();
  int _currentPage = 0;
  bool _isSharing = false;

  final int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _shareSummary(UserProfile profile) async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Capture the widget
      final image = await _screenshotController.captureFromWidget(
        _buildSummaryCard(profile),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0,
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File(
        '${directory.path}/emerge_summary.png',
      ).create();
      await imagePath.writeAsBytes(image);

      await SharePlus.instance.share(
        ShareParams(
          text: 'Check out my journey on Emerge! #EmergeApp',
          files: [XFile(imagePath.path)],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStatsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: userStatsAsync.when(
        data: (profile) {
          return Stack(
            children: [
              // Page View
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildIntroSlide(profile),
                  _buildStatsSlide(profile),
                  _buildHabitsSlide(profile),
                  _buildWorldSlide(profile),
                  _buildOutroSlide(profile),
                ],
              ),

              // Progress Indicator (Story style)
              Positioned(
                top: 50,
                left: 10,
                right: 10,
                child: Row(
                  children: List.generate(_totalPages, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Close Button
              Positioned(
                top: 60,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),

              // Tap areas for navigation
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () {
                        if (_currentPage > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _nextPage,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildIntroSlide(UserProfile profile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.secondary],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Journey',
              style: GoogleFonts.outfit(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
            const Gap(20),
            Text(
              'So Far...',
              style: GoogleFonts.outfit(
                fontSize: 32,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSlide(UserProfile profile) {
    return Container(
      color: AppTheme.backgroundDark,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Level ${profile.avatarStats.level}',
              style: GoogleFonts.outfit(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: AppTheme.vitalityGreen,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const Gap(40),
            _buildStatRow('Total XP', '${profile.avatarStats.totalXp}'),
            const Gap(20),
            _buildStatRow('Streak', '${profile.avatarStats.streak} days'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 24, color: Colors.white),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ).animate().fadeIn().slideX();
  }

  Widget _buildHabitsSlide(UserProfile profile) {
    return Container(
      color: const Color(0xFF2D1E40), // Deep purple
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const Gap(20),
            Text(
              'Consistency King',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Gap(20),
            Text(
              'You are building\nunstoppable momentum.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorldSlide(UserProfile profile) {
    final isCity = profile.worldTheme == 'city'
        ? true
        : profile.worldTheme == 'forest'
        ? false
        : (profile.archetype == UserArchetype.creator ||
              profile.archetype == UserArchetype.scholar);

    return Stack(
      fit: StackFit.expand,
      children: [
        WorldView(worldState: profile.worldState, isCity: isCity),
        Container(color: Colors.black.withValues(alpha: 0.3)),
        Center(
          child: Text(
            'Your World is Evolving',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                const Shadow(
                  blurRadius: 10,
                  color: Colors.black,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 1000.ms),
        ),
      ],
    );
  }

  Widget _buildOutroSlide(UserProfile profile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppTheme.secondary, AppTheme.primary],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Keep Going!',
            style: GoogleFonts.outfit(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().scale(),
          const Gap(40),
          ElevatedButton.icon(
            onPressed: _isSharing ? null : () => _shareSummary(profile),
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            label: Text(_isSharing ? 'Generating...' : 'Share Summary'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hidden widget used for screenshot generation
  Widget _buildSummaryCard(UserProfile profile) {
    return Container(
      width: 400,
      height: 600,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.secondary],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 60, color: Colors.white),
          const Gap(20),
          Text(
            'My Emerge Journey',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Gap(40),
          _buildSummaryStat('Level', '${profile.avatarStats.level}'),
          _buildSummaryStat('Total XP', '${profile.avatarStats.totalXp}'),
          const Gap(40),
          Text(
            'emerge.app',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.outfit(fontSize: 24, color: Colors.white),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
