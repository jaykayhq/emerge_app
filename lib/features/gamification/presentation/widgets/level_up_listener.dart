import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelUpListener extends ConsumerStatefulWidget {
  final Widget child;

  const LevelUpListener({super.key, required this.child});

  @override
  ConsumerState<LevelUpListener> createState() => _LevelUpListenerState();
}

class _LevelUpListenerState extends ConsumerState<LevelUpListener> {
  int? _previousLevel;
  bool _isShowingReward = false;
  SharedPreferences? _prefs;
  static const String _lastCelebratedLevelKey = 'last_celebrated_level';

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to user stats
    ref.listen<AsyncValue<UserProfile>>(userStatsStreamProvider, (
      previous,
      next,
    ) {
      if (_isShowingReward) return; // Don't trigger while already showing

      next.whenData((userProfile) {
        final currentLevel = userProfile.effectiveLevel;

        // Initial load - just track, don't celebrate
        if (_previousLevel == null) {
          _previousLevel = currentLevel;
          return;
        }

        // Level Up detected - check if we need to celebrate
        if (currentLevel > _previousLevel!) {
          _checkForLevelUp(userProfile);
          _previousLevel = currentLevel;
        }
      });
    });

    return widget.child;
  }

  /// Check for level-ups and trigger reward screen for each level gained
  void _checkForLevelUp(UserProfile userProfile) {
    if (_prefs == null) return;

    final currentLevel = userProfile.effectiveLevel;
    final lastCelebrated =
        _prefs!.getInt(_lastCelebratedLevelKey) ?? _previousLevel ?? 0;

    // Check if we've gained any levels since last celebration
    // Only celebrate level 2+ (level 1 is the starting level)
    if (currentLevel > lastCelebrated && currentLevel >= 2) {
      // Celebrate each level we haven't celebrated yet (starting from level 2 min)
      final startLevel = lastCelebrated < 1 ? 2 : lastCelebrated + 1;
      for (int level = startLevel; level <= currentLevel; level++) {
        _showLevelUpRewardScreen(context, level);
      }

      // Store the new celebrated level
      _prefs!.setInt(_lastCelebratedLevelKey, currentLevel);
    }
  }

  void _showLevelUpRewardScreen(BuildContext context, int level) {
    _isShowingReward = true;

    // Navigate to the Level Up Reward screen with the specific level
    context.push('/profile/level-up-reward/$level').then((_) {
      _isShowingReward = false;
    });
  }
}
