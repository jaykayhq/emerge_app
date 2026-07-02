import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_semantics.dart';
import 'package:emerge_app/core/theme/emerge_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

/// Custom bottom navigation bar (no center FAB).
///
/// Navigation order: Today (Timeline) → World → Tribes → Identity
class EmergeBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const EmergeBottomNav({
    super.key,
    required this.navigationShell,
  });

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
              _NavItem(
                icon: Icons.check_circle_outline,
                label: 'Today',
                isSelected: currentIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              _NavItem(
                icon: Icons.public,
                label: 'World',
                isSelected: currentIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              _NavItem(
                icon: Icons.groups,
                label: 'Tribe',
                isSelected: currentIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              _NavItem(
                icon: Icons.person,
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
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? EmergeColors.teal : AppTheme.textSecondaryDark;

    return Expanded(
      child: EmergeTappable(
        label: label,
        hint: isSelected ? 'Currently on $label screen' : 'Navigate to $label',
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
                child: Icon(icon, color: color, size: 24),
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
