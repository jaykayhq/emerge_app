import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main scaffold wrapper that provides the growth background and
/// custom bottom navigation with elevated diamond FAB.
///
/// Navigation order: World → Timeline → [+FAB] → Tribes → Profile
class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GrowthBackground(child: navigationShell),
      bottomNavigationBar: EmergeBottomNav(
        navigationShell: navigationShell,
        onFabPressed: () => context.push('/create-habit'),
      ),
    );
  }
}
