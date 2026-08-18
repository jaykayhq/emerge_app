import 'package:flutter/material.dart';

class EmojiPickerRow extends StatelessWidget {
  final String selectedEmoji;
  final ValueChanged<String> onEmojiSelected;
  final List<String> recentlyUsed;

  static const fullEmojiList = [
    '🔥',
    '💧',
    '🌿',
    '📖',
    '💪',
    '🧠',
    '✨',
    '🎯',
    '🏃',
    '💤',
    '🍎',
    '🧘',
    '🎸',
    '🎨',
    '💼',
    '🏡',
    '🔋',
    '🚀',
  ];

  const EmojiPickerRow({
    super.key,
    required this.selectedEmoji,
    required this.onEmojiSelected,
    this.recentlyUsed = const [],
  });

  @override
  Widget build(BuildContext context) {
    final emojis = recentlyUsed.take(5).toList();
    return Row(
      children: [
        ...emojis.map(
          (e) => _EmojiChip(
            emoji: e,
            isSelected: e == selectedEmoji,
            onTap: () => onEmojiSelected(e),
          ),
        ),
        _EmojiChip(
          emoji: '+',
          onTap: () => _showFullPicker(context),
          isSelected: false,
        ),
      ],
    );
  }

  void _showFullPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fullEmojiList
              .map(
                (e) => GestureDetector(
                  onTap: () {
                    onEmojiSelected(e);
                    Navigator.pop(ctx);
                  },
                  child: Text(e, style: const TextStyle(fontSize: 32)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _EmojiChip extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmojiChip({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.cyanAccent) : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
