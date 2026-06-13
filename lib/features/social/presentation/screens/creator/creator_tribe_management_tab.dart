// lib/features/social/presentation/screens/creator/creator_tribe_management_tab.dart
import 'package:flutter/material.dart';

class CreatorTribeManagementTab extends StatelessWidget {
  const CreatorTribeManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tribe Management')),
      body: const Center(
        child: Text('Tribe Management', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
