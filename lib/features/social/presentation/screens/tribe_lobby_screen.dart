// lib/features/social/presentation/screens/tribe_lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';

class TribeLobbyScreen extends StatelessWidget {
  const TribeLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  const Text("THE SCHOLARS 🔰", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("1,247 members · Your streak: 🔥14d", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  const Text("🗡️ Collective Quest: 73%", style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(value: 0.73, backgroundColor: Colors.white24, color: Colors.green),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.flash_on),
                    label: const Text("ENTER TRIBE"),
                    onPressed: () {
                      context.push('/social/space');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
