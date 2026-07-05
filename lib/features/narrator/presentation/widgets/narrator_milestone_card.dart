import 'dart:async';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:flutter/material.dart';

/// Slide-up milestone card. Non-blocking. Auto-dismisses after [autoDismissAfter].
class NarratorMilestoneCard extends StatefulWidget {
  final NarratorLine line;
  final NarratorTrigger trigger;
  final Duration autoDismissAfter;
  final VoidCallback? onDismissed;

  const NarratorMilestoneCard({
    super.key,
    required this.line,
    required this.trigger,
    this.autoDismissAfter = const Duration(seconds: 6),
    this.onDismissed,
  });

  @override
  State<NarratorMilestoneCard> createState() => _NarratorMilestoneCardState();
}

class _NarratorMilestoneCardState extends State<NarratorMilestoneCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.autoDismissAfter, _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPersonal = widget.line is PersonalLine;
    return Dismissible(
      key: ValueKey(widget.line.text),
      direction: DismissDirection.up,
      onDismissed: (_) => _dismiss(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              EmergeColors.violet.withValues(alpha: 0.95),
              EmergeColors.teal.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: EmergeColors.violet.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: const Center(
                child: Text('✦', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _labelFor(widget.trigger),
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      if (isPersonal)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: EmergeColors.warmGold.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PERSONAL',
                            style: TextStyle(
                              fontSize: 8,
                              color: EmergeColors.warmGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.line.text,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Swipe ↑',
              style: TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(NarratorTrigger t) => switch (t) {
        NarratorTrigger.onFireState => 'ON FIRE',
        NarratorTrigger.levelUp => 'LEVEL UP',
        NarratorTrigger.streakBreakFirstMiss => 'STREAK',
        NarratorTrigger.longAbsence => 'WELCOME BACK',
        NarratorTrigger.weeklyRecap => 'WEEKLY RECAP',
        NarratorTrigger.morningBriefEarlyDays => 'GOOD MORNING',
        NarratorTrigger.eveningReflection => 'EVENING',
        NarratorTrigger.onboardingPostArchetype => 'WELCOME',
        NarratorTrigger.askNarrator => 'YOU ASKED',
      };
}
