import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/drift/database.dart' hide Column;
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
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
    final activity = ref.watch(habitActivityDataProvider(widget.habitId));

    return WorldBackground(
      themeOverride: AppWorldTheme.nebula,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: activity.when(
          loading: () => const Text(''),
          error: (_, _) => const Text(''),
          data: (data) => Text(data.emoji),
        ),
      ),
      child: activity.when(
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
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IdentityCard(statement: data.identityStatement),
              const Gap(24),
              Row(
                children: [
                  _StatChip(label: '🔥 Streak', value: '${data.currentStreak}'),
                  const SizedBox(width: 12),
                  _StatChip(label: '🏆 Best', value: '${data.bestStreak}'),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: '📊 Total',
                    value: '${data.totalCompletions}',
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      color: EmergeColors.teal.withValues(alpha: 0.7),
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
            decoration: InputDecoration(
              hintText: 'Write a reflection...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
              counterText: '',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: EmergeColors.teal.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _savingReflection ? null : _saveReflection,
          style: FilledButton.styleFrom(
            backgroundColor: EmergeColors.teal,
            foregroundColor: const Color(0xFF05100B),
          ),
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save reflection. Try again.")),
        );
      }
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
    return GlassmorphismCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      glowColor: EmergeColors.teal,
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
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: EmergeColors.teal,
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
