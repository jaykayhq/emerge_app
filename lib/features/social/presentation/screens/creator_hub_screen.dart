// lib/features/social/presentation/screens/creator_hub_screen.dart
import 'package:flutter/material.dart';

class CreatorHubScreen extends StatelessWidget {
  const CreatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Welcome, Creator!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Card(child: ListTile(title: Text('Manage Tribe'), trailing: Icon(Icons.chevron_right))),
          Card(child: ListTile(title: Text('Blueprint Builder'), trailing: Icon(Icons.chevron_right))),
          Card(child: ListTile(title: Text('Analytics'), trailing: Icon(Icons.chevron_right))),
        ],
      ),
    );
  }
}
