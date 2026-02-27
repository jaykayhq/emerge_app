import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:flutter/material.dart';

/// AI Coach card that provides reflections and habit suggestions
/// Combines the AI Reflections and Goldilocks features into one unified card
class AiCoachCard extends StatelessWidget {
  final String? insight;
  final String? suggestedHabit;
  final VoidCallback? onReflect;
  final VoidCallback? onAddHabit;
  final VoidCallback? onLockedTap; // Callback when locked premium button is tapped
  final bool isLoading;
  final Color? accentColor; // Optional archetype theming
  final bool isPremiumLocked; // Whether Reflect is premium locked

  const AiCoachCard({
    super.key,
    this.insight,
    this.suggestedHabit,
    this.onReflect,
    this.onAddHabit,
    this.onLockedTap,
    this.isLoading = false,
    this.accentColor,
    this.isPremiumLocked = true, // AI Reflections are premium by default
  });

  Color get _accent => accentColor ?? EmergeColors.teal;

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      glowColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with premium badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.smart_toy, color: _accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AI Coach',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isPremiumLocked) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: EmergeColors.warmGold.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: EmergeColors.warmGold.withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock,
                                  size: 10,
                                  color: EmergeColors.warmGold,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'PREMIUM',
                                  style: TextStyle(
                                    color: EmergeColors.warmGold,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Personalized insights for your journey',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EmergeColors.tealMuted.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Insight text
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accent,
                  ),
                ),
              ),
            )
          else
            Text(
              insight ??
                  'Keep building your identity through consistent habits!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMainDark,
                height: 1.5,
              ),
            ),

          // Suggested habit (if any)
          if (suggestedHabit != null && !isLoading) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EmergeColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EmergeColors.teal.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: EmergeColors.teal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suggested: $suggestedHabit',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EmergeColors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Reflect',
                  onTap: isPremiumLocked ? null : onReflect,
                  onLockedTap: onLockedTap,
                  color: EmergeColors.violet,
                  isLocked: isPremiumLocked,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Add Habit',
                  onTap: onAddHabit,
                  color: EmergeColors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;
  final Color color;
  final bool isLocked;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.onLockedTap,
    required this.color,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLockedState = isLocked || onTap == null;

    return GestureDetector(
      onTap: isLockedState ? onLockedTap : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(
              alpha: isLockedState ? 0.15 : 0.3,
            ),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLockedState)
                Icon(
                  Icons.lock_outline,
                  color: color.withValues(alpha: 0.5),
                  size: 16,
                )
              else
                Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isLockedState
                      ? color.withValues(alpha: 0.5)
                      : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
