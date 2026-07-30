import 'package:flutter/material.dart';

/// Sentence-based habit builder UI.
/// Displays the habit as a natural sentence with tappable pills for each element.
class IdentitySentenceBuilder extends StatelessWidget {
  final String emoji;
  final String action;
  final String time;
  final String location;
  final String frequency;
  final VoidCallback onEmojiTap;
  final VoidCallback onActionTap;
  final VoidCallback onTimeTap;
  final VoidCallback onLocationTap;
  final VoidCallback onFrequencyTap;

  const IdentitySentenceBuilder({
    super.key,
    required this.emoji,
    required this.action,
    required this.time,
    required this.location,
    required this.frequency,
    required this.onEmojiTap,
    required this.onActionTap,
    required this.onTimeTap,
    required this.onLocationTap,
    required this.onFrequencyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am the type of person who',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _GlassPill(
              label: emoji,
              onTap: onEmojiTap,
              isSet: true,
              isEmoji: true,
            ),
            _GlassPill(
              label: action.isEmpty ? 'action' : action,
              onTap: onActionTap,
              isSet: action.isNotEmpty,
            ),
            _GlassPill(
              label: time.isEmpty ? 'at...' : 'at $time',
              onTap: onTimeTap,
              isSet: time.isNotEmpty,
            ),
            _GlassPill(
              label: location.isEmpty ? 'where...' : 'in $location',
              onTap: onLocationTap,
              isSet: location.isNotEmpty,
            ),
            _GlassPill(
              label: frequency.isEmpty ? 'how often...' : frequency,
              onTap: onFrequencyTap,
              isSet: frequency.isNotEmpty,
            ),
          ],
        ),
      ],
    );
  }
}

/// Glassmorphic pill for sentence elements.
class _GlassPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSet;
  final bool isEmoji;

  const _GlassPill({
    required this.label,
    required this.onTap,
    this.isSet = false,
    this.isEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: isEmoji
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSet
              ? const Color(0xFF2BEE79).withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSet
                ? const Color(0xFF2BEE79).withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSet
                ? const Color(0xFF2BEE79)
                : Colors.white.withValues(alpha: 0.5),
            fontSize: isEmoji ? 20 : 13,
            fontWeight: isSet ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
