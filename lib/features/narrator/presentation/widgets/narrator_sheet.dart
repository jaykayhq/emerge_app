import 'dart:ui';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/ai/data/services/groq_ai_service.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/coach_ask_quota_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_limit_dialog.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_pulse_indicator.dart';
import 'package:emerge_app/features/tutorials/presentation/widgets/node_guide_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the Narrator as a centered glassmorphic dialog.
///
/// Callers should use [NarratorSheet.show] to display it.
/// Renders instant text — no typewriter.
///
/// In coach mode ([showAskField] = true) the action buttons are replaced by
/// an ask field wired to the coach quota: free users get 3 asks/day,
/// premium users are unlimited.
class NarratorSheet extends ConsumerStatefulWidget {
  final NarratorAppearance appearance;
  final void Function(String buttonLabel, String? typedText)? onResponse;
  final bool showAskField;

  const NarratorSheet({
    super.key,
    required this.appearance,
    this.onResponse,
    this.showAskField = false,
  });

  /// Displays the Narrator as a centered dialog.
  ///
  /// In coach mode ([showAskField] = true) the first-visit coach guide is
  /// shown as a full-screen overlay before the sheet opens.
  static Future<void> show(
    BuildContext context,
    NarratorAppearance appearance, {
    void Function(String buttonLabel, String? typedText)? onResponse,
    bool showAskField = false,
  }) async {
    if (showAskField) {
      await NodeGuideOverlay.show(context, 'coach');
      if (!context.mounted) return;
    }
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => NarratorSheet(
        appearance: appearance,
        onResponse: onResponse,
        showAskField: showAskField,
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

  final TextEditingController _askController = TextEditingController();
  NarratorLine? _currentLine;
  bool _isAsking = false;

  static const List<String> _genericAskPool = [
    'Small steps compound. Pick the tiniest version of this and do it now.',
    'What would your future self thank you for today? Start there.',
    "One miss is a slip, not a fall. What's the smallest next move?",
    'Consistency beats intensity. Can you make this 2 minutes easier?',
    'Your habits are votes for the person you are becoming. Cast one today.',
  ];

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
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _entryController.forward();
  }

  @override
  void dispose() {
    _askController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _submitAsk(String raw) async {
    final question = raw.trim();
    if (question.isEmpty || _isAsking) return;
    // Set synchronously BEFORE the first await so concurrent submits are
    // serialized and the button shows the busy state during quota load.
    setState(() => _isAsking = true);
    try {
      final quotaCtrl = ref.read(coachAskQuotaControllerProvider.notifier);
      final quota = await ref.read(coachAskQuotaControllerProvider.future);
      if (!quota.canAsk) {
        if (mounted) {
          showPremiumLimitDialog(context, limitType: PremiumLimitType.coachAsk);
        }
        return;
      }
      final isPremium = ref.read(isPremiumProvider).value ?? false;
      final NarratorLine line;
      if (isPremium) {
        // Ground the LLM in the user's real progress so the DATA-GROUNDED
        // badge is honest. Empty context when the profile hasn't loaded.
        final profile = ref.read(userStatsStreamProvider).value;
        final context = profile == null
            ? ''
            : 'Level ${profile.avatarStats.level}, '
                '${profile.avatarStats.totalXp} total XP, '
                'archetype ${profile.archetype.name}, '
                'streak ${profile.avatarStats.streak}';
        final groq = GroqAiService();
        final advice = await groq.getCoachAdvice(context, question);
        line = PersonalLine(text: advice, dataBasis: 'groq_coach');
      } else {
        line = GenericLine(
          _genericAskPool[question.length % _genericAskPool.length],
        );
      }
      await quotaCtrl.consume();
      if (mounted) {
        setState(() {
          _currentLine = line;
          _askController.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _currentLine = const GenericLine("I'm here — keep going."),
        );
      }
    } finally {
      if (mounted) setState(() => _isAsking = false);
    }
  }

  String _quotaHint() {
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    if (isPremium) return 'Unlimited coach asks';
    final remaining =
        ref.watch(coachAskQuotaControllerProvider).value?.remaining ?? 3;
    return '$remaining of 3 coach asks left today';
  }

  @override
  Widget build(BuildContext context) {
    final appearance = widget.appearance;
    final isPersonal =
        _currentLine is PersonalLine || appearance.line is PersonalLine;
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
                child: Material(
                  type: MaterialType.transparency,
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
                                  widget.showAskField ? 'COACH' : 'EMERGE',
                                  style: Theme.of(context).textTheme.titleSmall
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
                                      color: EmergeColors.warmGold.withValues(
                                        alpha: 0.15,
                                      ),
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
                              _currentLine?.text ?? appearance.line.text,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.white, height: 1.6),
                            ),

                            if (widget.showAskField) ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _askController,
                                maxLines: 3,
                                minLines: 1,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: _isAsking
                                      ? 'Consulting your coach…'
                                      : 'Ask your coach anything…',
                                  hintStyle: const TextStyle(
                                    color: Colors.white38,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.06,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                ),
                                onSubmitted: _submitAsk,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _quotaHint(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _isAsking
                                        ? null
                                        : () => _submitAsk(_askController.text),
                                    icon: const Icon(
                                      Icons.send,
                                      color: EmergeColors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
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
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
