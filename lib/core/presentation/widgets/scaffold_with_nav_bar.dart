import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GrowthBackground(child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: AppTheme.primary),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.public),
            selectedIcon: Icon(Icons.public, color: AppTheme.primary),
            label: 'World',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups, color: AppTheme.accent),
            label: 'Tribes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.secondary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
