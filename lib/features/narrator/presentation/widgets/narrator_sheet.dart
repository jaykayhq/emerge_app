import 'dart:async';
import 'dart:ui';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_pulse_indicator.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_typewriter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the Narrator as a centered glassmorphic dialog.
///
/// Callers should use [NarratorSheet.show] to display it.
class NarratorSheet extends ConsumerStatefulWidget {
  final NarratorAppearance appearance;
  final void Function(String buttonLabel, String? typedText)? onResponse;

  const NarratorSheet({
    super.key,
    required this.appearance,
    this.onResponse,
  });

  /// Displays the Narrator as a centered dialog.
  static Future<void> show(
    BuildContext context,
    NarratorAppearance appearance, {
    void Function(String buttonLabel, String? typedText)? onResponse,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => NarratorSheet(
        appearance: appearance,
        onResponse: onResponse,
      ),
    );
  }

  @override
  ConsumerState<NarratorSheet> createState() => _NarratorSheetState();
}

class _NarratorSheetState extends ConsumerState<NarratorSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  final _typewriterKey = GlobalKey<NarratorTypewriterState>();
  bool _textComplete = false;
  final _noteController = TextEditingController();
  bool _actionButtonADone = false;
  bool _actionButtonBDone = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _skipTyping() {
    _typewriterKey.currentState?.skipToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = widget.appearance;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.85).clamp(0.0, 400.0);

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent dismiss when tapping inside card
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2BEE79).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Main content
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  NarratorPulseIndicator(
                                    color: EmergeColors.teal,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'EMERGE',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: EmergeColors.teal,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 3,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Typewriter text
                              NarratorTypewriter(
                                key: _typewriterKey,
                                text: appearance.shellText,
                                baseDelayMs: 28,
                                pauseDurations: const {
                                  '.': 250,
                                  '?': 300,
                                  '!': 300,
                                  ',': 150,
                                },
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      height: 1.6,
                                    ),
                                onComplete: () {
                                  if (mounted) {
                                    setState(() => _textComplete = true);
                                  }
                                },
                              ),

                              // Optional text field (eveningReflection only)
                              if (appearance.hasTextField) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _noteController,
                                  maxLines: 3,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'How was your day?',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                    filled: true,
                                    fillColor:
                                        Colors.white.withValues(alpha: 0.08),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: EmergeColors.teal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Action buttons (fade in after text completes)
                              AnimatedOpacity(
                                opacity: _textComplete ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _ActionButton(
                                        label: appearance.buttonA,
                                        color: EmergeColors.teal,
                                        isSelected: _actionButtonADone,
                                        onTap: () {
                                          setState(() =>
                                              _actionButtonADone = true);
                                          _onButtonTap(appearance.buttonA);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ActionButton(
                                        label: appearance.buttonB,
                                        color: EmergeColors.violet,
                                        isSelected: _actionButtonBDone,
                                        onTap: () {
                                          setState(() =>
                                              _actionButtonBDone = true);
                                          _onButtonTap(appearance.buttonB);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Skip button (top-right, only visible during typing)
                        if (!_textComplete)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _skipTyping,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  '✕',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onButtonTap(String buttonLabel) {
    widget.onResponse?.call(
      buttonLabel,
      _noteController.text.isEmpty ? null : _noteController.text,
    );
    try {
      ref.read(narratorStateProvider.notifier).dismiss();
    } catch (_) {
      // Provider might not be available in test context
    }
    Navigator.of(context).pop();
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.6)
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            isSelected ? '✓ $label' : label,
            style: TextStyle(
              color: isSelected ? color : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
