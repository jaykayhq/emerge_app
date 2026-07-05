import 'package:flutter/material.dart';

class AskMentorButton extends StatelessWidget {
  final VoidCallback onTap;

  const AskMentorButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      onPressed: onTap,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      child: const Icon(Icons.auto_awesome, color: Colors.white70, size: 20),
    );
  }
}
