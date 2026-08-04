import 'package:flutter/material.dart';

/// Number of characters of [text] visible after [elapsedMs] at
/// [charsPerSecond]. Pure — the single source of truth for typing progress,
/// unit-tested without a widget tree.
int visibleCharCount(String text, int elapsedMs, int charsPerSecond) {
  if (text.isEmpty || charsPerSecond <= 0) return 0;
  final chars = (elapsedMs / 1000 * charsPerSecond).floor();
  return chars.clamp(0, text.length);
}

/// Types [text] out character-by-character with a blinking caret.
///
/// - Tap anywhere on the text → completes instantly (and fires [onComplete]).
/// - Reduced motion (system accessibility setting) → full text instantly,
///   no caret.
/// - [onComplete] fires once per text when typing finishes (naturally or
///   via tap-skip); when [text] changes, typing restarts and it fires again.
class TypewriterText extends StatefulWidget {
  final String text;
  final int charsPerSecond;
  final bool showCaret;
  final TextStyle? style;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.charsPerSecond = 35,
    this.showCaret = true,
    this.style,
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _caretCtrl;
  // Lazily created on first build (after initState has initialized _ctrl and
  // _caretCtrl) so AnimatedBuilder doesn't allocate a merged Listenable
  // on every rebuild.
  late final Listenable _animation = Listenable.merge([_ctrl, _caretCtrl]);
  bool _completed = false;
  bool _started = false;

  bool get _instant => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: _durationFor(widget.text),
    );
    _caretCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    // Natural completion must also finish the typing: once the controller
    // stops, lastElapsedDuration is nulled, so without this the text would
    // collapse back to empty instead of showing the full string.
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _complete();
    });
  }

  // MediaQuery (and thus [_instant]) can only be read once the element is
  // mounted and dependencies are resolved, so typing is started here instead
  // of in initState.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _start();
    }
  }

  Duration _durationFor(String text) {
    if (widget.charsPerSecond <= 0) return Duration.zero;
    final ms = text.length * 1000 ~/ widget.charsPerSecond;
    return Duration(milliseconds: ms < 1 ? 1 : ms);
  }

  void _start() {
    _completed = false;
    if (_instant) {
      _completed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // The widget may be disposed before the next frame; consumers of
        // onComplete (e.g. narrator cards) call setState and would crash.
        if (!mounted) return;
        widget.onComplete?.call();
      });
      return;
    }
    _ctrl
      ..duration = _durationFor(widget.text)
      ..forward(from: 0);
    // Restart the caret blink for the new text.
    _caretCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _ctrl.stop();
      _start();
    }
  }

  void _complete() {
    if (_completed) return;
    setState(() {
      _completed = true;
    });
    _ctrl.stop();
    // Stop the caret blink so the tree goes idle (also keeps pumpAndSettle
    // usable once typing is done).
    _caretCtrl.stop();
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _caretCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final full = widget.text;
    final showCaret = widget.showCaret && !_instant && !_completed;
    return Semantics(
      label: full,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _instant || _completed ? null : _complete,
        child: ConstrainedBox(
          // An empty paragraph is zero-width and can't be tapped; enforce a
          // minimum hit-testable area so tap-to-skip works even before the
          // first character has been typed.
          constraints: const BoxConstraints(minWidth: 1),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              final elapsed = _ctrl.lastElapsedDuration?.inMilliseconds ?? 0;
              final count = _instant || _completed
                  ? full.length
                  : visibleCharCount(full, elapsed, widget.charsPerSecond);
              final caretVisible = showCaret && _caretCtrl.value > 0.5;
              return Text.rich(
                TextSpan(
                  text: full.substring(0, count),
                  children: [
                    // WidgetSpan (not TextSpan) so toPlainText() stays clean —
                    // tests and semantics never see the caret.
                    if (caretVisible)
                      WidgetSpan(
                        child: const Text(
                          '▍',
                          style: TextStyle(color: Color(0xFF9D8FFF)),
                        ),
                      ),
                  ],
                ),
                style: widget.style,
              );
            },
          ),
        ),
      ),
    );
  }
}
