import 'package:emerge_app/core/presentation/widgets/animated_flame_logo.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

/// Spotify Wrapped-style weekly recap widget
/// Features: Animated gradients, swipeable cards, progress dots, sharing
class SpotifyWrappedRecap extends ConsumerStatefulWidget {
  final UserWeeklyRecap recap;
  final VoidCallback onClose;

  const SpotifyWrappedRecap({
    super.key,
    required this.recap,
    required this.onClose,
  });

  @override
  ConsumerState<SpotifyWrappedRecap> createState() =>
      _SpotifyWrappedRecapState();
}

class _SpotifyWrappedRecapState extends ConsumerState<SpotifyWrappedRecap>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  // Slide types to manage gradients and visibility
  List<Widget> _getSlides() {
    final slides = <Widget>[];
    
    // 0. Progress slide (Only if not complete)
    if (!widget.recap.isComplete) {
      slides.add(_ProgressSlide(recap: widget.recap));
    }
    
    // 1. Intro (Always first)
    slides.add(_WrappedIntro(recap: widget.recap));
    
    // 2. Identity (If available)
    if (widget.recap.dominantIdentityThisWeek != null) {
      slides.add(_IdentitySlide(
        identity: widget.recap.dominantIdentityThisWeek!,
        headline: widget.recap.identityHeadline ?? '',
        motive: ref.watch(userStatsStreamProvider).value?.dominantMotive,
      ));
    }
    
    // 3. Stats
    slides.add(_WrappedStats(recap: widget.recap));
    
    // 4. Top Habit
    slides.add(_WrappedTopHabit(recap: widget.recap));
    
    // 5. AI Insight
    slides.add(_AiInsightSlide(recap: widget.recap));
    
    // 6. Outro
    slides.add(_WrappedOutro(recap: widget.recap, onShare: _shareRecap));
    
    return slides;
  }

  List<Color> _getCurrentGradient() {
    final slides = _getSlides();
    if (_currentPage >= slides.length) return [const Color(0xFF0D1B2A), const Color(0xFF1B263B)];
    
    final currentSlide = slides[_currentPage];
    
    if (currentSlide is _ProgressSlide) return [const Color(0xFF0D1B2A), const Color(0xFF1B263B)];
    if (currentSlide is _WrappedIntro) return [const Color(0xFF1A0A2A), const Color(0xFF2A1B4E)];
    if (currentSlide is _IdentitySlide) return [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)];
    if (currentSlide is _WrappedStats) return [const Color(0xFF112218), const Color(0xFF1DB954)];
    if (currentSlide is _WrappedTopHabit) return [const Color(0xFF2A1A3A), const Color(0xFFFFD700)];
    if (currentSlide is _AiInsightSlide) return [const Color(0xFF2C0735), const Color(0xFF4B296B)];
    if (currentSlide is _WrappedOutro) return [const Color(0xFF0A1A3A), const Color(0xFF9C27B0)];
    
    return [const Color(0xFF0D1B2A), const Color(0xFF1B263B)];
  }

  int get _totalSlides => _getSlides().length;

  @override
  void dispose() {
    _pageController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _gradientController.forward(from: 0);
  }

  Future<void> _shareRecap() async {
    try {
      // Create share text
      final dateFormat = DateFormat('MMM dd');
      final startDate = dateFormat.format(widget.recap.startDate);
      final endDate = dateFormat.format(widget.recap.endDate);

      final shareText =
          '''
🌟 My Emerge Weekly Recap! 🌟

Week of $startDate - $endDate

✅ ${widget.recap.totalHabitsCompleted} habits completed
🔥 ${widget.recap.perfectDays} perfect days
⭐ ${widget.recap.totalXpEarned} XP earned
🏆 MVP: ${widget.recap.topHabitName}
📈 Level ${widget.recap.currentLevel}

Building my identity, one habit at a time. 💪

#EmergeApp #HabitTracking
''';

      // ignore: deprecated_member_use
      await Share.share(shareText);
    } catch (e) {
      debugPrint('Error sharing recap: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = _getSlides();
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated gradient background
        _buildAnimatedBackground(),

        // Main content
        PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: slides,
        ),

        // Close button (Placed after PageView to be on top)
        Positioned(
          top: 50,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onClose,
            ),
          ),
        ),

        // Progress dots
        Positioned(bottom: 40, left: 0, right: 0, child: _buildProgressDots()),
      ],
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _getCurrentGradient(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSlides, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: isActive ? 12 : 8,
          width: isActive ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? EmergeColors.teal
                : Colors.white.withValues(alpha: 0.4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: EmergeColors.teal.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

// ============================================================================
// SLIDE 1: INTRO
// ============================================================================

class _WrappedIntro extends StatelessWidget {
  final UserWeeklyRecap recap;

  const _WrappedIntro({required this.recap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd');
    final startDate = dateFormat.format(recap.startDate);
    final endDate = dateFormat.format(recap.endDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animation
          SizedBox(
            height: 80,
            width: 80,
            child: const AnimatedFlameLogo(size: 80),
          ).animate().fadeIn(duration: 600.ms).scale(),

          const Gap(40),

          // "WEEKLY RECAP" text
          Text(
            'WEEKLY',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w300,
              letterSpacing: 8,
              fontSize: 28,
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),

          const Gap(8),

          Text(
            'RECAP',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontSize: 64,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 800.ms).scale(),

          const Gap(32),

          // Date range
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: EmergeColors.teal.withValues(alpha: 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '$startDate - $endDate',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: EmergeColors.teal,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).scale(),

          const Gap(40),

          // Tagline
          Text(
            'Your week in numbers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 18,
            ),
          ).animate().fadeIn(delay: 900.ms),

          const Gap(8),

          Text(
            'Swipe to discover',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ).animate().fadeIn(delay: 1000.ms),

          const Gap(60),

          // Swipe indicator
          Icon(
                Icons.swipe_left,
                color: Colors.white.withValues(alpha: 0.3),
                size: 32,
              )
              .animate()
              .fadeIn(delay: 1200.ms)
              .then()
              .animate(onPlay: (controller) => controller.repeat())
              .slideX(
                begin: 0,
                end: 0.3,
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }
}

// ============================================================================
// SLIDE 2: STATS
// ============================================================================

class _WrappedStats extends StatelessWidget {
  final UserWeeklyRecap recap;

  const _WrappedStats({required this.recap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Section title
          Text(
            'YOUR NUMBERS',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 4,
              fontWeight: FontWeight.w300,
            ),
          ).animate().fadeIn(duration: 400.ms),

          const Gap(40),

          // Habits Completed
          _StatCard(
            label: 'Habits Completed',
            value: recap.totalHabitsCompleted.toString(),
            icon: Icons.check_circle_outline,
            color: EmergeColors.teal,
            delay: 0,
          ),

          const Gap(24),

          // Perfect Days
          _StatCard(
            label: 'Perfect Days',
            value: recap.perfectDays.toString(),
            icon: Icons.whatshot,
            color: EmergeColors.yellow,
            delay: 200,
          ),

          const Gap(24),

          // XP Earned
          _StatCard(
            label: 'XP Earned',
            value: '+${recap.totalXpEarned}',
            icon: Icons.stars,
            color: EmergeColors.violet,
            delay: 400,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ).animate().fadeIn(delay: delay.ms).scale(),

          const Gap(20),

          // Value
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 40,
            ),
          ).animate().fadeIn(delay: (delay + 100).ms).slideX(begin: -0.2),

          const Spacer(),

          // Label
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: (delay + 200).ms),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.3, end: 0);
  }
}

// ============================================================================
// SLIDE 3: TOP HABIT (MVP)
// ============================================================================

class _WrappedTopHabit extends StatelessWidget {
  final UserWeeklyRecap recap;

  const _WrappedTopHabit({required this.recap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Star icon with glow
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      EmergeColors.yellow.withValues(alpha: 0.4),
                      EmergeColors.yellow.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ).animate().scale(duration: 1500.ms, curve: Curves.easeInOut),

              // Star icon
              Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: EmergeColors.yellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: EmergeColors.yellow.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 48,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(delay: 300.ms, curve: Curves.elasticOut),
            ],
          ),

          const Gap(32),

          // "YOUR MVP" title
          Text(
            'YOUR MVP',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: -0.2),

          const Gap(16),

          // Top habit name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  EmergeColors.yellow.withValues(alpha: 0.2),
                  EmergeColors.coral.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: EmergeColors.yellow.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Text(
              recap.topHabitName.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 900.ms).scale(),

          const Gap(24),

          // Description
          Text(
            'Most consistent habit this week',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 1200.ms),
        ],
      ),
    );
  }
}

// ============================================================================
// SLIDE 4: OUTRO
// ============================================================================

class _WrappedOutro extends StatelessWidget {
  final UserWeeklyRecap recap;
  final VoidCallback onShare;

  const _WrappedOutro({required this.recap, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Level badge
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [EmergeColors.teal, EmergeColors.violet],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: EmergeColors.teal.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'LEVEL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '${recap.currentLevel}',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 48,
                            ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(delay: 300.ms, curve: Curves.elasticOut),

          const Gap(40),

          // Congratulatory message
          Text(
                'KEEP IT UP!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              )
              .animate()
              .fadeIn(delay: 900.ms)
              .shimmer(duration: 2000.ms, color: EmergeColors.yellow),

          const Gap(16),

          Text(
            'Every habit counts toward\nbuilding your identity.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 1200.ms),

          const Gap(40),

          // Share button
          _ShareButton(onPressed: onShare)
              .animate()
              .fadeIn(delay: 1500.ms)
              .scale(delay: 1700.ms, curve: Curves.elasticOut),

          const Gap(16),

          // Close hint
          Text(
            'Tap X to close',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ).animate().fadeIn(delay: 2000.ms),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ShareButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [EmergeColors.teal, EmergeColors.violet],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: EmergeColors.teal.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.share, color: Colors.white, size: 24),
            const Gap(12),
            Text(
              'Share Your Recap',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentitySlide extends StatelessWidget {
  final String identity;
  final String headline;
  final String? motive;
  const _IdentitySlide({
    required this.identity,
    required this.headline,
    this.motive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'THIS WEEK YOU WERE A',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
        const Gap(12),
        Text(
          identity.toUpperCase(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 800.ms).scale(),
        const Gap(24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            headline,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
        ),
        if (motive != null) ...[
          const Gap(40),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 48),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.format_quote, color: Colors.white24, size: 32),
                const Gap(8),
                Text(
                  motive!,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 900.ms).scale(),
        ],
      ],
    );
  }
}

class _ProgressSlide extends StatelessWidget {
  final UserWeeklyRecap recap;

  const _ProgressSlide({required this.recap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: EmergeColors.teal.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              color: EmergeColors.teal,
              size: 64,
            ),
          ).animate().rotate(duration: 2000.ms).fadeIn(),
          const Gap(40),
          Text(
            'IDENTITY\nEMERGING',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          const Gap(24),
          Text(
            "You're in the process of becoming. This recap is evolving as you complete your habits.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 800.ms),
          const Gap(40),
          _buildProgressBar(context),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    // Calculate progress through the week
    final now = DateTime.now();
    final totalDuration = recap.endDate.difference(recap.startDate).inSeconds;
    final elapsedDuration = now.difference(recap.startDate).inSeconds;
    final progress = (elapsedDuration / totalDuration).clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(EmergeColors.teal),
            minHeight: 12,
          ),
        ).animate().scaleX(delay: 1200.ms),
        const Gap(12),
        Text(
          '${(progress * 100).toInt()}% through your weekly cycle',
          style: TextStyle(
            color: EmergeColors.teal.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 1500.ms),
      ],
    );
  }
}

class _AiInsightSlide extends StatelessWidget {
  final UserWeeklyRecap recap;

  const _AiInsightSlide({required this.recap});

  @override
  Widget build(BuildContext context) {
    if (recap.isLocked) {
      return _buildLockedState(context);
    }

    return _buildUnlockedState(context);
  }

  Widget _buildLockedState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Locked Icon with Glow
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: EmergeColors.violet.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: EmergeColors.violet,
              size: 64,
            ),
          ).animate().shake(duration: 1000.ms).fadeIn(),

          const Gap(40),

          Text(
            'AI INSIGHTS',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
          ).animate().fadeIn(delay: 300.ms),

          const Gap(16),

          Text(
            'Unlock deep behavioral analysis and AI-powered growth patterns.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 600.ms),

          const Gap(48),

          // Upgrade Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [EmergeColors.violet, EmergeColors.teal],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: EmergeColors.violet.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const Gap(12),
                Text(
                  'UPGRADE TO UNLOCK',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
              ],
            ),
          ).animate().scale(delay: 900.ms, curve: Curves.elasticOut),
          
          const Gap(24),
          
          Text(
            'FREE FOR ALL PREMIUM MEMBERS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ).animate().fadeIn(delay: 1200.ms),
        ],
      ),
    );
  }

  Widget _buildUnlockedState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: EmergeColors.violet,
            size: 48,
          ).animate().scale().fadeIn(),

          const Gap(32),

          Text(
            'AI ANALYSIS',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: EmergeColors.violet,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
          ).animate().fadeIn(delay: 300.ms),

          const Gap(24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: EmergeColors.violet.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              recap.aiInsight ?? 'Analysis complete. Your patterns show a strong lean towards consistency in morning routines.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

          const Gap(32),

          Text(
            'Refined by Emerge AI',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ).animate().fadeIn(delay: 900.ms),
        ],
      ),
    );
  }
}
