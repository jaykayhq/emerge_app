import 'dart:async';

import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class TwoMinuteTimerScreen extends StatefulWidget {
  const TwoMinuteTimerScreen({super.key});

  @override
  State<TwoMinuteTimerScreen> createState() => _TwoMinuteTimerScreenState();
}

class _TwoMinuteTimerScreenState extends State<TwoMinuteTimerScreen> {
  static const int _durationSeconds = 120;
  int _remainingSeconds = _durationSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleted = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _isCompleted = true;
        }
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _durationSeconds;
      _isRunning = false;
      _isCompleted = false;
    });
  }

  String get _timerText {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GrowthBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isCompleted) ...[
                const Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: AppTheme.accent,
                ),
                const Gap(24),
                Text(
                  'Victory!',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(16),
                Text(
                  'You showed up. That\'s what matters.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.backgroundDark,
                    ),
                    child: const Text('Claim Victory'),
                  ),
                ),
              ] else ...[
                Text(
                  'Two-Minute Rule',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textMainDark,
                  ),
                ),
                const Gap(8),
                Text(
                  'Just start. You can stop after 2 minutes.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(64),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: CircularProgressIndicator(
                        value: 1 - (_remainingSeconds / _durationSeconds),
                        strokeWidth: 12,
                        backgroundColor: AppTheme.surfaceDark,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      _timerText,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.textMainDark,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const Gap(64),
                if (!_isRunning)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _startTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.backgroundDark,
                      ),
                      child: const Text('Start'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _resetTimer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondaryDark,
                        side: const BorderSide(
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
