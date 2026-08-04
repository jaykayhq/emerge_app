import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/core/presentation/widgets/typewriter_text.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/ai/data/services/groq_ai_service.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/coach_ask_quota_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_limit_dialog.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/services/card_line_resolver.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Day Card — the narrator's always-visible timeline surface.
///
/// Typed day-line (pending milestone → latest insight → computed day status),
/// glanceable status chips (streak, remaining today), and an inline coach
/// ask that reuses the premium quota + Groq plumbing that used to live in
/// NarratorSheet.
class NarratorCard extends ConsumerStatefulWidget {
  const NarratorCard({super.key});

  @override
  ConsumerState<NarratorCard> createState() => _NarratorCardState();
}

class _NarratorCardState extends ConsumerState<NarratorCard> {
  final GlobalKey _rootKey = GlobalKey();
  final TextEditingController _askController = TextEditingController();
  final FocusNode _askFocus = FocusNode();
  bool _askOpen = false;
  bool _isAsking = false;
  NarratorLine? _replyLine;

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
    _askFocus.addListener(_onAskFocusChanged);
  }

  void _onAskFocusChanged() {
    if (_askFocus.hasFocus && !_askOpen) setState(() => _askOpen = true);
  }

  @override
  void dispose() {
    _askController.dispose();
    _askFocus.dispose();
    super.dispose();
  }

  void _openAskFromAvatar() {
    setState(() => _askOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        _rootKey.currentContext!,
        duration: const Duration(milliseconds: 200),
      );
      _askFocus.requestFocus();
    });
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
          _replyLine = line;
          _askController.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _replyLine = const GenericLine("I'm here — keep going."),
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
    if (ref.watch(narratorCardDismissedProvider)) {
      return const SizedBox.shrink();
    }
    ref.listen(narratorAskFocusProvider, (previous, next) {
      if (next > (previous ?? 0)) _openAskFromAvatar();
    });

    final pendingLine = ref.watch(pendingMilestoneProvider)?.line;
    final insightAsync = ref.watch(latestNarratorInsightProvider);
    final insightText = insightAsync.value?.data['shellText'] as String?;

    final habits = ref.watch(habitsProvider).value ?? const <Habit>[];
    final now = DateTime.now();
    final active = habits.where((h) => h.isActiveOnDay(now)).toList();
    final completed = active.where((h) => h.isCompletedOn(now)).length;
    final incomplete = active.where((h) => !h.isCompletedOn(now)).toList();
    final firstIncomplete = incomplete.isEmpty ? null : incomplete.first.title;
    final streak =
        ref.watch(userStatsStreamProvider).value?.avatarStats.streak ?? 0;

    final line = resolveCardLine(
      pendingLine: pendingLine,
      insightText: insightText,
      day: DayStatus(
        completed: completed,
        total: active.length,
        streak: streak,
        firstIncompleteName: firstIncomplete,
      ),
    );
    if (line == null) return const SizedBox.shrink();

    final isPersonal = line is PersonalLine;
    final remaining = active.length - completed;

    return GlassmorphismCard(
      key: _rootKey,
      glowColor: EmergeColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CardAvatar(),
              const SizedBox(width: 10),
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
              if (isPersonal)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: EmergeColors.warmGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DATA-GROUNDED',
                    style: TextStyle(
                      fontSize: 8,
                      color: EmergeColors.warmGold,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () =>
                    ref.read(narratorCardDismissedProvider.notifier).dismiss(),
                icon: const Icon(Icons.close, size: 18, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TypewriterText(
            key: ValueKey('card-line-${line.text}'),
            text: line.text,
            style: const TextStyle(color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (streak > 0)
                _StatusChip(
                  icon: '🔥',
                  label: '$streak-day streak',
                  emphasized: true,
                ),
              if (active.isNotEmpty)
                _StatusChip(
                  icon: remaining == 0 ? '✓' : '',
                  label: remaining == 0 ? 'All done' : '$remaining left today',
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_askOpen)
            GestureDetector(
              onTap: () => setState(() => _askOpen = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 14, color: Colors.white54),
                    SizedBox(width: 6),
                    Text(
                      '✎ Ask the narrator',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _askController,
                  focusNode: _askFocus,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _isAsking
                        ? 'Consulting your coach…'
                        : 'Ask your coach anything…',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
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
                      icon: const Icon(Icons.send, color: EmergeColors.teal),
                    ),
                  ],
                ),
              ],
            ),
          if (_replyLine != null) ...[
            const SizedBox(height: 12),
            TypewriterText(
              key: ValueKey('reply-${_replyLine!.text}'),
              text: _replyLine!.text,
              style: const TextStyle(color: Colors.white, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardAvatar extends StatelessWidget {
  const _CardAvatar();

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

class _StatusChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool emphasized;

  const _StatusChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: emphasized
            ? EmergeColors.warmGold.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.07),
        border: Border.all(
          color: emphasized
              ? EmergeColors.warmGold.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        '$icon $label'.trim(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: emphasized ? FontWeight.bold : FontWeight.w500,
          color: emphasized ? EmergeColors.warmGold : Colors.white70,
        ),
      ),
    );
  }
}
