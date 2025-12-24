import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
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
        indicatorColor: Colors.transparent,
        backgroundColor: EmergeColors.background.withValues(alpha: 0.95),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.check_circle_outline,
              color: EmergeColors.teal.withValues(alpha: 0.5),
            ),
            selectedIcon: const Icon(
              Icons.check_circle,
              color: EmergeColors.teal,
            ),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.public,
              color: EmergeColors.violet.withValues(alpha: 0.5),
            ),
            selectedIcon: const Icon(Icons.public, color: EmergeColors.violet),
            label: 'World',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.groups_outlined,
              color: EmergeColors.coral.withValues(alpha: 0.5),
            ),
            selectedIcon: const Icon(Icons.groups, color: EmergeColors.coral),
            label: 'Tribes',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
              color: EmergeColors.yellow.withValues(alpha: 0.5),
            ),
            selectedIcon: const Icon(Icons.person, color: EmergeColors.yellow),
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
