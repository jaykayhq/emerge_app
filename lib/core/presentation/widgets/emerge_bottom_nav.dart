import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_semantics.dart';
import 'package:emerge_app/core/theme/emerge_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom bottom navigation bar with elevated center FAB (diamond shape)
///
/// Navigation order: World → Timeline → [+FAB] → Community → Profile
/// The FAB is elevated above the nav bar in a diamond shape (rotated 45°)
class EmergeBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final VoidCallback onFabPressed;

  const EmergeBottomNav({
    super.key,
    required this.navigationShell,
    required this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Container(
      decoration: BoxDecoration(
        color: EmergeColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: EmergeDimensions.navBarHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Main navigation row
              Row(
                children: [
                  // Left side: World, Timeline
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavItem(
                          icon: Icons.public,
                          label: 'World',
                          isSelected: currentIndex == 0,
                          onTap: () => _onItemTapped(0),
                        ),
                        _NavItem(
                          icon: Icons.calendar_today,
                          label: 'Timeline',
                          isSelected: currentIndex == 1,
                          onTap: () => _onItemTapped(1),
                        ),
                      ],
                    ),
                  ),
                  // Center spacer for FAB
                  const SizedBox(width: 80),
                  // Right side: Community, Profile
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavItem(
                          icon: Icons.groups,
                          label: 'Community',
                          isSelected: currentIndex == 2,
                          onTap: () => _onItemTapped(2),
                        ),
                        _NavItem(
                          icon: Icons.person,
                          label: 'Profile',
                          isSelected: currentIndex == 3,
                          onTap: () => _onItemTapped(3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Center elevated FAB (diamond shape)
              Positioned(top: -20, child: _DiamondFab(onPressed: onFabPressed)),
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

    return EmergeTappable(
      label: label,
      hint: isSelected ? 'Currently on $label screen' : 'Navigate to $label',
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: EmergeDimensions.animationMedium,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? EmergeColors.teal.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
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
    );
  }
}

/// Diamond-shaped FAB (rotated 45°) with accessibility support
class _DiamondFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _DiamondFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return EmergeSemantics(
      label: 'Create new habit',
      hint: 'Opens the habit creation screen',
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: EmergeDimensions.fabSize, // 56px standard
          height: EmergeDimensions.fabSize,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: EmergeColors.teal.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: 0.785398, // 45 degrees in radians
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [EmergeColors.teal, EmergeColors.violet],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Transform.rotate(
                angle: -0.785398, // Rotate icon back
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
