import 'dart:ui';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_pulse_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the Narrator as a centered glassmorphic dialog.
///
/// Callers should use [NarratorSheet.show] to display it.
/// Renders instant text — no typewriter.
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = widget.appearance;
    final isPersonal = appearance.line is PersonalLine;
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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
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
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
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
                              const Spacer(),
                              if (isPersonal)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: EmergeColors.warmGold
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'DATA-GROUNDED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: EmergeColors.warmGold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Instant text (no typewriter)
                          Text(
                            appearance.line.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  height: 1.6,
                                ),
                          ),

                          const SizedBox(height: 20),

                          // Action buttons (always visible)
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  label: appearance.buttonA,
                                  color: EmergeColors.teal,
                                  onTap: () {
                                    _onButtonTap(appearance.buttonA);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  label: appearance.buttonB,
                                  color: EmergeColors.violet,
                                  onTap: () {
                                    _onButtonTap(appearance.buttonB);
                                  },
                                ),
                              ),
                            ],
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
      ),
    );
  }

  void _onButtonTap(String buttonLabel) {
    widget.onResponse?.call(buttonLabel, null);
    ref.read(narratorStateProvider.notifier).dismiss();
    Navigator.of(context).pop();
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
