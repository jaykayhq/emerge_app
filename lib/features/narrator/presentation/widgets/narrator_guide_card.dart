import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/typewriter_text.dart';
import 'package:flutter/material.dart';

/// Bottom narrator card for a first-visit guide step: the script types out,
/// then the advance button enables. Skip (✕) is always available.
class NarratorGuideCard extends StatefulWidget {
  final String script;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onAdvance;
  final VoidCallback onSkip;

  const NarratorGuideCard({
    super.key,
    required this.script,
    required this.stepIndex,
    required this.stepCount,
    required this.onAdvance,
    required this.onSkip,
  });

  @override
  State<NarratorGuideCard> createState() => _NarratorGuideCardState();
}

class _NarratorGuideCardState extends State<NarratorGuideCard> {
  bool _typingDone = false;
  bool get _isLast => widget.stepIndex == widget.stepCount - 1;

  @override
  void didUpdateWidget(NarratorGuideCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.script != widget.script) _typingDone = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.violet.withValues(alpha: 0.5)),
        gradient: LinearGradient(
          colors: [
            EmergeColors.violet.withValues(alpha: 0.28),
            const Color(0xFF12122A).withValues(alpha: 0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: EmergeColors.violet.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _GuideAvatar(),
              const SizedBox(width: 8),
              const Text(
                'NARRATOR',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.bold,
                  color: EmergeColors.teal,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.stepIndex + 1}/${widget.stepCount}',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              IconButton(
                onPressed: widget.onSkip,
                icon: const Icon(Icons.close, size: 18, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TypewriterText(
            text: widget.script,
            onComplete: () => setState(() => _typingDone = true),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _typingDone ? widget.onAdvance : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _typingDone
                      ? EmergeColors.teal
                      : Colors.white.withValues(alpha: 0.08),
                ),
                child: Text(
                  _isLast ? 'Got it' : 'Next →',
                  style: TextStyle(
                    color: _typingDone ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideAvatar extends StatelessWidget {
  const _GuideAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [EmergeColors.violet, EmergeColors.teal],
        ),
      ),
      child: const Center(
        child: Text('✦', style: TextStyle(fontSize: 12, color: Colors.white)),
      ),
    );
  }
}
