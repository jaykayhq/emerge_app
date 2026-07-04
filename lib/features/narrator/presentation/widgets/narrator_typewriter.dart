import 'dart:async';

import 'package:flutter/material.dart';

/// A character-by-character text reveal widget with pauses at punctuation.
///
/// Default timing:
/// - Base character: 28ms
/// - Period ('.'): 250ms
/// - Question mark ('?'): 300ms
/// - Exclamation ('!'): 300ms
/// - Comma (','): 150ms
class NarratorTypewriter extends StatefulWidget {
  /// The full text to reveal.
  final String text;

  /// Base delay per character in milliseconds.
  final int baseDelayMs;

  /// Custom pause durations keyed by punctuation character.
  final Map<String, int> pauseDurations;

  /// Called when the full text has been revealed.
  final VoidCallback? onComplete;

  /// The text style to apply.
  final TextStyle? style;

  const NarratorTypewriter({
    super.key,
    required this.text,
    this.baseDelayMs = 28,
    this.pauseDurations = const {
      '.': 250,
      '?': 300,
      '!': 300,
      ',': 150,
    },
    this.onComplete,
    this.style,
  });

  @override
  NarratorTypewriterState createState() => NarratorTypewriterState();
}

/// Public state so parent widgets can call [skipToEnd].
class NarratorTypewriterState extends State<NarratorTypewriter> {
  final ValueNotifier<String> _displayedTextNotifier = ValueNotifier<String>('');
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(NarratorTypewriter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _currentIndex = 0;
      _displayedTextNotifier.value = '';
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _displayedTextNotifier.dispose();
    super.dispose();
  }

  void _startTyping() {
    _typeNextCharacter();
  }

  void _typeNextCharacter() {
    if (_currentIndex >= widget.text.length) {
      widget.onComplete?.call();
      return;
    }

    _displayedTextNotifier.value = widget.text.substring(0, _currentIndex + 1);

    final char = widget.text[_currentIndex];
    final pause = widget.pauseDurations[char] ?? widget.baseDelayMs;
    _currentIndex++;

    _timer = Timer(Duration(milliseconds: pause), _typeNextCharacter);
  }

  /// Instantly reveals all remaining text (used by skip button).
  void skipToEnd() {
    _timer?.cancel();
    _displayedTextNotifier.value = widget.text;
    _currentIndex = widget.text.length;
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _displayedTextNotifier,
      builder: (context, text, _) {
        return Text(
          text,
          style: widget.style,
        );
      },
    );
  }
}
