import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';

/// Streams only the blueprints owned by the currently authenticated creator.
final _myBlueprintsProvider = StreamProvider.autoDispose<List<Blueprint>>((ref) {
  final authUserAsync = ref.watch(authStateChangesProvider);
  final uid = authUserAsync.value?.id;
  if (uid == null) return Stream.value([]);
  
  // Directly use the repo's stream and filter client-side — avoids composite index.
  final repo = ref.watch(blueprintRepositoryProvider);
  return repo.getBlueprints().map(
    (list) => list.where((b) => b.creatorUserId == uid).toList(),
  );
});

class CreatorBlueprintsTab extends ConsumerWidget {
  const CreatorBlueprintsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blueprintsAsync = ref.watch(_myBlueprintsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprint Studio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New'),
            style: FilledButton.styleFrom(
              backgroundColor: EmergeColors.neonTeal,
              foregroundColor: Colors.black,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              context.push('/creator/dashboard/blueprints/blueprint-builder');
            },
          ),
          const Gap(12),
        ],
      ),
      body: blueprintsAsync.when(
        data: (blueprints) {
          if (blueprints.isEmpty) {
            return _EmptyBlueprintState(
              onCreateTap: () => context.push('/creator/dashboard/blueprints/blueprint-builder'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: blueprints.length,
            itemBuilder: (context, index) {
              final blueprint = blueprints[index];
              return _CreatorBlueprintCard(blueprint: blueprint);
            },
          );
        },
        loading: () => const EmergeLoadingSkeleton(itemCount: 4),
        error: (e, st) => AppErrorWidget(
          message: 'Could not load your blueprints.',
          onRetry: () => ref.invalidate(_myBlueprintsProvider),
        ),
      ),
    );
  }
}

// ── Creator Blueprint Card ───────────────────────────────────────────────────
class _CreatorBlueprintCard extends StatelessWidget {
  final Blueprint blueprint;

  const _CreatorBlueprintCard({required this.blueprint});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/blueprint/${blueprint.id}', extra: blueprint),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EmergeColors.neonTeal.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EmergeColors.neonTeal.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chip
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: EmergeColors.neonTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    blueprint.difficulty.name.toUpperCase(),
                    style: TextStyle(
                      color: EmergeColors.neonTeal,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.more_vert_rounded,
                    size: 16, color: Colors.white38),
              ],
            ),
            const Spacer(),
            Icon(Icons.widgets_rounded, size: 32, color: EmergeColors.neonTeal),
            const Gap(8),
            Text(
              blueprint.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(4),
            Text(
              '${blueprint.habits.length} habits  ·  '
              '${blueprint.adoptionCount} adopted',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────
class _EmptyBlueprintState extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _EmptyBlueprintState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EmergeColors.neonTeal.withValues(alpha: 0.08),
                border: Border.all(
                    color: EmergeColors.neonTeal.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.widgets_outlined,
                  size: 48, color: Colors.white24),
            ),
            const Gap(24),
            const Text(
              'No blueprints yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            const Text(
              'Create your first blueprint to share your habit system with your tribe.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
            ),
            const Gap(24),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Blueprint'),
              style: FilledButton.styleFrom(
                backgroundColor: EmergeColors.neonTeal,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onCreateTap,
            ),
          ],
        ),
      ),
    );
  }
}
