import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

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

  // Gradient colors for each slide
  static const List<List<Color>> _slideGradients = [
    [Color(0xFF1A0A2A), Color(0xFF2A1B4E)], // Intro - Purple
    [Color(0xFF112218), Color(0xFF1DB954)], // Stats - Green
    [Color(0xFF2A1A3A), Color(0xFFFFD700)], // Top Habit - Gold
    [Color(0xFF0A1A3A), Color(0xFF9C27B0)], // Outro - Blue/Purple
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

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

      final shareText = '''
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated gradient background
        _buildAnimatedBackground(),

        // Close button
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

        // Main content
        PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            _WrappedIntro(recap: widget.recap),
            _WrappedStats(recap: widget.recap),
            _WrappedTopHabit(recap: widget.recap),
            _WrappedOutro(
              recap: widget.recap,
              onShare: _shareRecap,
            ),
          ],
        ),

        // Progress dots
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: _buildProgressDots(),
        ),
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
              colors: _slideGradients[_currentPage],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: isActive ? 12 : 8,
          width: isActive ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? EmergeColors.teal : Colors.white.withValues(alpha: 0.4),
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
            child: const EmergeLogoWidget(size: 80, animate: true),
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
          ).animate().fadeIn(delay: 1200.ms).then(
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).slideX(
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
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
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
              ).animate().fadeIn(duration: 600.ms).scale(
                    delay: 300.ms,
                    curve: Curves.elasticOut,
                  ),
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

  const _WrappedOutro({
    required this.recap,
    required this.onShare,
  });

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
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).scale(
                delay: 300.ms,
                curve: Curves.elasticOut,
              ),

          const Gap(40),

          // Congratulatory message
          Text(
            'KEEP IT UP!',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
          ).animate().fadeIn(delay: 900.ms).shimmer(
                duration: 2000.ms,
                color: EmergeColors.yellow,
              ),

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
          _ShareButton(
            onPressed: onShare,
          ).animate().fadeIn(delay: 1500.ms).scale(
                delay: 1700.ms,
                curve: Curves.elasticOut,
              ),

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
            const Icon(
              Icons.share,
              color: Colors.white,
              size: 24,
            ),
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
