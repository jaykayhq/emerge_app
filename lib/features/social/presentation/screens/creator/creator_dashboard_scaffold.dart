// lib/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/auth/presentation/providers/creator_auth_provider.dart';

class CreatorDashboardScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const CreatorDashboardScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(isVerifiedCreatorProvider, (_, next) {
      next.whenData((verified) {
        if (!verified && context.mounted) {
          context.go('/creator/login');
        }
      });
    });

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;

    final items = [
      const NavigationDestination(
        icon: Icon(Icons.bar_chart),
        label: 'Overview',
      ),
      const NavigationDestination(
        icon: Icon(Icons.handyman),
        label: 'Blueprints',
      ),
      const NavigationDestination(
        icon: Icon(Icons.groups),
        label: 'Tribe',
      ),
    ];

    final railDestinations = items
        .map((item) => NavigationRailDestination(
              icon: item.icon,
              label: Text(item.label),
            ))
        .toList();

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              destinations: railDestinations,
              selectedIconTheme: IconThemeData(color: Colors.amber.shade700),
              selectedLabelTextStyle: TextStyle(color: Colors.amber.shade700),
              indicatorColor: Colors.amber.withOpacity(0.2),
            ),
          if (isWide) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              destinations: items,
              indicatorColor: Colors.amber.withOpacity(0.2),
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
