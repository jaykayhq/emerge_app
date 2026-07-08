import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:emerge_app/features/reflections/presentation/providers/reflection_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline mood + 1-line note widget for the timeline.
/// Empty state → expanded (emoji row + note input + Save).
/// Save → collapsed summary.
/// Tap collapsed → re-expand for editing.
class TimelineReflectionCard extends ConsumerStatefulWidget {
  final String userId;
  final DateTime date;
  const TimelineReflectionCard({super.key, required this.userId, required this.date});

  @override
  ConsumerState<TimelineReflectionCard> createState() => _TimelineReflectionCardState();
}

class _TimelineReflectionCardState extends ConsumerState<TimelineReflectionCard> {
  Mood? _mood;
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;
  bool _collapsedAfterSave = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncExisting = ref.watch(
      dailyReflectionProvider(userId: widget.userId, date: widget.date),
    );

    return asyncExisting.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _buildError(),
      data: (existing) {
        if (_collapsedAfterSave && _mood != null) {
          return _buildCollapsed(_mood!, _noteCtrl.text);
        }
        if (existing != null) {
          return _buildCollapsed(existing.mood, existing.note);
        }
        return _buildExpanded();
      },
    );
  }

  Widget _buildError() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange),
        ),
        child: const Text(
          'Could not load reflection. Pull to refresh.',
          style: TextStyle(color: Colors.orange),
        ),
      );

  Widget _buildExpanded() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            EmergeColors.violet.withValues(alpha: 0.1),
            EmergeColors.teal.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: EmergeColors.violet.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REFLECT',
            style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          const Text(
            'How does today feel so far?',
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final m in Mood.values) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mood = m),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _mood == m
                              ? EmergeColors.teal.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color: _mood == m ? EmergeColors.teal : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(m.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLength: 140,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add a one-line note (optional)...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              FilledButton(
                onPressed: _mood == null || _isSaving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: EmergeColors.teal),
                child: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsed(Mood mood, String note) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _collapsedAfterSave = false;
          _mood = mood;
          _noteCtrl.text = note;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                note.isEmpty ? 'You felt ${mood.name} today.' : note,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            const Icon(Icons.edit, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_mood == null) return;
    setState(() => _isSaving = true);
    final result = await ref.read(reflectionRepositoryProvider).save(
          userId: widget.userId,
          localDate: widget.date,
          mood: _mood!,
          note: _noteCtrl.text.trim(),
        );
    setState(() {
      _isSaving = false;
      _collapsedAfterSave = result.isRight();
    });
    ref.invalidate(dailyReflectionProvider(userId: widget.userId, date: widget.date));
  }
}
