import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/screens/cinematic_recap_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LevelUpListener extends ConsumerStatefulWidget {
  final Widget child;

  const LevelUpListener({super.key, required this.child});

  @override
  ConsumerState<LevelUpListener> createState() => _LevelUpListenerState();
}

class _LevelUpListenerState extends ConsumerState<LevelUpListener> {
  int? _previousLevel;

  @override
  Widget build(BuildContext context) {
    // Listen to user stats
    ref.listen<AsyncValue<UserProfile>>(userStatsStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((userProfile) {
        final currentLevel = userProfile.avatarStats.level;

        // Initial load
        if (_previousLevel == null) {
          _previousLevel = currentLevel;
          return;
        }

        // Level Up detected
        if (currentLevel > _previousLevel!) {
          _showLevelUpScreen(context, currentLevel, userProfile.archetype.name);
          _previousLevel = currentLevel;
        }
      });
    });

    return widget.child;
  }

  void _showLevelUpScreen(
    BuildContext context,
    int newLevel,
    String archetype,
  ) {
    // Use a dialog or full screen overlay
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      pageBuilder: (context, anim1, anim2) {
        return CinematicRecapScreen(
          newLevel: newLevel,
          userArchetype: archetype,
          onDismiss: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
