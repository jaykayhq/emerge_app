import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_pulse_indicator.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Always-visible inline card that shows the Narrator's latest insight.
///
/// Features:
/// - Shows the last aiInsight note or a fallback message
/// - "Hear more" button opens the Narrator sheet with a dailyInsight template
/// - "Add a habit" button navigates to habit creation
class NarratorSummaryCard extends ConsumerWidget {
  const NarratorSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestInsightAsync = ref.watch(latestNarratorInsightProvider);

    return GlassmorphismCard(
      glowColor: EmergeColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with pulse indicator
          Row(
            children: [
              NarratorPulseIndicator(
                color: EmergeColors.teal,
                size: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Narrator',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your personal habit observer',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EmergeColors.tealMuted.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Insight or fallback
          latestInsightAsync.when(
            data: (note) {
              final insightText = note != null
                  ? (note.data['shellText'] as String?) ??
                      _formatInsightFromNote(note)
                  : "I'm watching how you work...";

              return Text(
                insightText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              );
            },
            loading: () => Text(
              "I'm watching how you work...",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
            error: (_, _) => Text(
              "I'm watching how you work...",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _SummaryActionButton(
                  icon: Icons.volume_up_outlined,
                  label: 'Hear More',
                  color: EmergeColors.teal,
                  onTap: () {
                    final appearance = NarratorAppearance(
                      trigger: NarratorTrigger.askNarrator,
                      shellText:
                          'You asked for more. Tell me what you\'re noticing, or what you want to understand better.',
                      buttonA: 'Got it',
                      buttonB: 'Tell me more',
                      line: const GenericLine(
                        'You asked for more. Tell me what you\'re noticing, or what you want to understand better.',
                      ),
                    );
                    NarratorSheet.show(context, appearance);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Add Habit',
                  color: EmergeColors.violet,
                  onTap: () => context.push('/timeline/create-habit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatInsightFromNote(NarratorNote note) {
    // Fallback: use a generic message based on the note type
    switch (note.type) {
      case NarratorNoteType.aiInsight:
        return "I've noticed some interesting patterns in your habits.";
      case NarratorNoteType.reflectionLogged:
        return 'Keep reflecting on your progress.';
      case NarratorNoteType.streakMilestone:
        return 'You\'re on a roll! Keep the momentum going.';
      case NarratorNoteType.levelUp:
        return 'You\'ve grown stronger. Let\'s keep building.';
      default:
        return "I'm watching how you work...";
    }
  }
}

class _SummaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SummaryActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
