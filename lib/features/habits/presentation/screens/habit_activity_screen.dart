import 'package:emerge_app/core/drift/database.dart' hide Column;
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_activity_provider.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_heatmap.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class HabitActivityScreen extends ConsumerStatefulWidget {
  final String habitId;

  const HabitActivityScreen({super.key, required this.habitId});

  @override
  ConsumerState<HabitActivityScreen> createState() =>
      _HabitActivityScreenState();
}

class _HabitActivityScreenState extends ConsumerState<HabitActivityScreen> {
  final _reflectionController = TextEditingController();
  bool _savingReflection = false;

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activity =
        ref.watch(habitActivityDataProvider(widget.habitId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: activity.when(
        loading: () => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: EmergeLoadingSkeleton(itemCount: 3),
          ),
        ),
        error: (e, _) => SafeArea(
          child: AppErrorWidget(
            message: "Couldn't load activity data.",
            onRetry: () =>
                ref.invalidate(habitActivityDataProvider(widget.habitId)),
          ),
        ),
        data: (data) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              title: Text('${data.emoji} ${data.title}'),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _IdentityCard(statement: data.identityStatement),
                  const Gap(24),
                  Row(
                    children: [
                      _StatChip(label: '🔥 Streak', value: '${data.currentStreak}'),
                      const SizedBox(width: 12),
                      _StatChip(label: '🏆 Best', value: '${data.bestStreak}'),
                      const SizedBox(width: 12),
                      _StatChip(
                          label: '📊 Total', value: '${data.totalCompletions}'),
                    ],
                  ),
                  const Gap(24),
                  _sectionLabel('ACTIVITY'),
                  const Gap(12),
                  HabitHeatmap(data: data.heatmapData),
                  const Gap(24),
                  _sectionLabel('REFLECTIONS'),
                  const Gap(12),
                  _buildReflectionInput(),
                  const Gap(12),
                  ...data.reflections.map(_buildReflectionTile),
                  if (data.reflections.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No reflections yet. Add one above.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      );

  Widget _buildReflectionInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _reflectionController,
            style: const TextStyle(color: Colors.white),
            maxLength: 140,
            decoration: const InputDecoration(
              hintText: 'Write a reflection...',
              hintStyle: TextStyle(color: Colors.white38),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _savingReflection ? null : _saveReflection,
          child: const Text('SAVE'),
        ),
      ],
    );
  }

  Widget _buildReflectionTile(HabitReflection r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const Gap(4),
          Text(
            DateFormat.yMMMd().format(r.createdAt),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveReflection() async {
    final text = _reflectionController.text.trim();
    if (text.isEmpty) return;
    final userId = ref.read(authStateChangesProvider).value?.id;
    if (userId == null || userId.isEmpty) return;

    setState(() => _savingReflection = true);
    try {
      final db = ref.read(appDatabaseProvider);
      await db.habitReflectionsDao.upsert(
        userId: userId,
        habitId: widget.habitId,
        localDate: DateTime.now(),
        mood: Mood.ok,
        note: text,
      );
      _reflectionController.clear();
      ref.invalidate(habitActivityDataProvider(widget.habitId));
    } finally {
      if (mounted) setState(() => _savingReflection = false);
    }
  }
}

class _IdentityCard extends StatelessWidget {
  final String statement;

  const _IdentityCard({required this.statement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
      ),
      child: Text(
        statement,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontStyle: FontStyle.italic,
          height: 1.4,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
