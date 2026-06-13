// lib/features/social/presentation/screens/creator/creator_blueprints_tab.dart
import 'package:flutter/material.dart';

class CreatorBlueprintsTab extends StatelessWidget {
  const CreatorBlueprintsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blueprints Studio')),
      body: const Center(
        child: Text('Blueprints Studio', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
