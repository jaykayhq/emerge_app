import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

class TribeSpaceScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TribeSpaceScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.cosmicVoidCenter,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text("Tribe Space"),
      ),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        backgroundColor: EmergeColors.cosmicVoidDark,
        selectedItemColor: EmergeColors.neonTeal,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'My Tribe'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Board'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
        ],
      ),
    );
  }
}
