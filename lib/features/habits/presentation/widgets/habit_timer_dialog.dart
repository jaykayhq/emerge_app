import 'dart:async';
import 'dart:ui';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Countdown timer dialog with customizable duration
class TwoMinuteTimerDialog extends StatefulWidget {
  final String habitTitle;
  final Color neonColor;
  final VoidCallback onComplete;
  final int durationMinutes;

  const TwoMinuteTimerDialog({
    required this.habitTitle,
    required this.neonColor,
    required this.onComplete,
    this.durationMinutes = 2,
    super.key,
  });

  @override
  State<TwoMinuteTimerDialog> createState() => _TwoMinuteTimerDialogState();
}

class _TwoMinuteTimerDialogState extends State<TwoMinuteTimerDialog>
    with SingleTickerProviderStateMixin {
  late Duration _timerDuration;
  late Timer _timer;
  late Duration _remaining;
  bool _isComplete = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _timerDuration = Duration(minutes: widget.durationMinutes);
    _remaining = _timerDuration;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining = _remaining - const Duration(seconds: 1);
        } else {
          _timer.cancel();
          _isComplete = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    return 1 - (_remaining.inSeconds / _timerDuration.inSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                  const Color(0xFF0F0F1A).withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.neonColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  _isComplete ? '🎉 Great Job!' : widget.habitTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textMainDark,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(32),

                // Timer ring
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isComplete
                                          ? Colors.green
                                          : widget.neonColor)
                                      .withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                      ),
                      // Progress ring
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: _isComplete ? 1.0 : _progress,
                          strokeWidth: 8,
                          backgroundColor: widget.neonColor.withValues(
                            alpha: 0.2,
                          ),
                          valueColor: AlwaysStoppedAnimation(
                            _isComplete ? Colors.green : widget.neonColor,
                          ),
                        ),
                      ),
                      // Time display
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isComplete ? Icons.check : Icons.timer,
                            color: _isComplete
                                ? Colors.green
                                : widget.neonColor,
                            size: 32,
                          ),
                          const Gap(8),
                          Text(
                            _isComplete ? 'Done!' : _formatDuration(_remaining),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: _isComplete
                                      ? Colors.green
                                      : AppTheme.textMainDark,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(32),

                // Action buttons
                if (_isComplete) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        widget.onComplete();
                      },
                      icon: const Icon(Icons.bolt),
                      label: const Text('Mark Complete'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: TextStyle(color: AppTheme.textSecondaryDark),
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pause/Resume button
                      IconButton.filled(
                        onPressed: () {
                          setState(() => _isPaused = !_isPaused);
                        },
                        icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                        style: IconButton.styleFrom(
                          backgroundColor: widget.neonColor.withValues(
                            alpha: 0.2,
                          ),
                          foregroundColor: widget.neonColor,
                        ),
                      ),
                      const Gap(16),
                      // Cancel button
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.textSecondaryDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
