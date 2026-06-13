import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_feed_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/my_tribe_tab.dart';

class TribeSpaceScaffold extends StatefulWidget {
  const TribeSpaceScaffold({super.key});

  @override
  State<TribeSpaceScaffold> createState() => _TribeSpaceScaffoldState();
}

class _TribeSpaceScaffoldState extends State<TribeSpaceScaffold> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    TribeFeedTab(),
    MyTribeTab(),
    Center(child: Text("Board", style: TextStyle(color: Colors.white))),
    Center(child: Text("Discover", style: TextStyle(color: Colors.white))),
  ];

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
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
