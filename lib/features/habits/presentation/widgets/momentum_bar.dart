import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

class MomentumBar extends StatelessWidget {
  final int momentumScore;
  final HabitStreakState streakState;
  final bool showLabel;

  const MomentumBar({
    super.key,
    required this.momentumScore,
    required this.streakState,
    this.showLabel = true,
  });

  Color get _stateColor {
    switch (streakState) {
      case HabitStreakState.onFire:
        return const Color(0xFF00FF9C);
      case HabitStreakState.strong:
        return const Color(0xFF4CAF50);
      case HabitStreakState.building:
        return const Color(0xFF00BCD4);
      case HabitStreakState.atRisk:
        return const Color(0xFFFFC107);
      case HabitStreakState.recovery:
        return const Color(0xFFFF9800);
      case HabitStreakState.reset:
        return const Color(0xFFFF5252);
    }
  }

  String get _label {
    switch (streakState) {
      case HabitStreakState.onFire:
        return "On Fire 🔥";
      case HabitStreakState.strong:
        return "Strong";
      case HabitStreakState.building:
        return "Building";
      case HabitStreakState.atRisk:
        return "At Risk";
      case HabitStreakState.recovery:
        return "Recovery";
      case HabitStreakState.reset:
        return "Fresh Start";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(
                height: 4,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: _stateColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                height: 4,
                width:
                    constraints.maxWidth *
                    (momentumScore / 100).clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: _stateColor,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: _stateColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _label,
                style: TextStyle(
                  color: _stateColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '$momentumScore',
                style: TextStyle(
                  color: _stateColor.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
