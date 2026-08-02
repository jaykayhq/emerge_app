import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribe_blueprints_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/blueprint_card.dart';

class TribeBlueprintsSection extends ConsumerWidget {
  final Tribe tribe;

  const TribeBlueprintsSection({super.key, required this.tribe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Creator tribes carry no archetype id, so they surface the tribe's own
    // published blueprints; archetype clubs get their curated set instead.
    final archetypeId = tribe.archetypeId;
    final blueprintsAsync = archetypeId != null
        ? ref.watch(tribeBlueprintsProvider(archetypeId))
        : ref.watch(tribeCreatorBlueprintsProvider(tribe.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Text(
                'BLUEPRINTS',
                style: TextStyle(
                  color: EmergeColors.nebulaPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: blueprintsAsync.when(
            data: (blueprints) {
              if (blueprints.isEmpty) {
                return const _EmptyState();
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: blueprints.length,
                separatorBuilder: (_, _) => const Gap(12),
                itemBuilder: (context, index) {
                  final bp = blueprints[index];
                  return SizedBox(
                    width: 150,
                    child: BlueprintCard(blueprint: bp),
                  );
                },
              );
            },
            loading: () => const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => const _EmptyState(),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'No blueprints for this tribe yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        ),
      ),
    );
  }
}
