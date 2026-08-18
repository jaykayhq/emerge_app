import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_semantics.dart';
import 'package:emerge_app/core/theme/emerge_dimensions.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/timeline/presentation/providers/goal_gradient_helpers.dart';
import 'package:emerge_app/features/timeline/presentation/providers/goal_gradient_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

/// Custom bottom navigation bar (no center FAB).
///
/// Navigation order: Today (Timeline) → World → Tribes → Identity
class EmergeBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const EmergeBottomNav({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Container(
      decoration: const BoxDecoration(color: EmergeColors.background),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: EmergeDimensions.navBarHeight,
          child: Row(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final incomplete = ref.watch(incompleteCountProvider);
                  final streak = ref.watch(userStreakProvider).value ?? 0;
                  final pulse = shouldPulseIncompleteBadge(
                    incomplete,
                    DateTime.now(),
                  );
                  return _NavItem(
                    icon: _TodayNavIcon(incomplete: incomplete, pulse: pulse),
                    label: 'Today',
                    isSelected: currentIndex == 0,
                    onTap: () => _onItemTapped(0),
                    badgeText: incomplete > 0 ? '$incomplete' : null,
                    // Momentum signal reused for a11y hint on the primary tab.
                    hint: streak > 0
                        ? 'Today screen · $streak-day streak'
                        : 'Currently on Today screen',
                  );
                },
              ),
              _NavItem(
                icon: const Icon(Icons.public, size: 24),
                label: 'World',
                isSelected: currentIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              _NavItem(
                icon: const Icon(Icons.groups, size: 24),
                label: 'Tribe',
                isSelected: currentIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              _NavItem(
                icon: const Icon(Icons.person, size: 24),
                label: 'Identity',
                isSelected: currentIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Individual navigation item with accessibility support
class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badgeText;
  final String hint;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeText,
    this.hint = '',
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? EmergeColors.teal : AppTheme.textSecondaryDark;

    final iconWithBadge = badgeText != null
        ? Badge(
            label: Text(badgeText!),
            backgroundColor: const Color(0xFFFF6B6B),
            textColor: Colors.white,
            child: icon,
          )
        : icon;

    return Expanded(
      child: EmergeTappable(
        label: label,
        hint: hint.isNotEmpty
            ? hint
            : (isSelected
                  ? 'Currently on $label screen'
                  : 'Navigate to $label'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: EmergeDimensions.animationMedium,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? EmergeColors.teal.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconTheme(
                  data: IconThemeData(color: color, size: 24),
                  child: iconWithBadge,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: EmergeDimensions.minFontSize, // 12px minimum
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today-tab icon: the checklist glyph with an optional subtle pulse when
/// daylight is nearly gone and habits remain incomplete (Goal Gradient nudge).
class _TodayNavIcon extends StatefulWidget {
  final int incomplete;
  final bool pulse;

  const _TodayNavIcon({required this.incomplete, required this.pulse});

  @override
  State<_TodayNavIcon> createState() => _TodayNavIconState();
}

class _TodayNavIconState extends State<_TodayNavIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_TodayNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      widget.incomplete > 0 ? Icons.check_circle_outline : Icons.check_circle,
      size: 24,
    );
    if (!widget.pulse) return icon;
    return ScaleTransition(scale: _scale, child: icon);
  }
}
