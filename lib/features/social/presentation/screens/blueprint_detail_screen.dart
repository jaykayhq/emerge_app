import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class BlueprintDetailScreen extends ConsumerWidget {
  final CreatorBlueprint blueprint;

  const BlueprintDetailScreen({super.key, required this.blueprint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;

    return WorldBackground(
      themeOverride: AppWorldTheme.nebula,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCreatorInfo(),
                    const Gap(24),
                    _buildDescription(),
                    const Gap(32),
                    _buildHabitStack(),
                    const Gap(48),
                    _buildAdoptButton(context, ref, user?.id),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: EmergeColors.background,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (blueprint.imageUrl != null)
              blueprint.imageUrl!.startsWith('assets/')
                  ? Image.asset(
                      blueprint.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      blueprint.imageUrl!,
                      fit: BoxFit.cover,
                    )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A1B4E), Color(0xFF1A0A2E)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome_motion_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha:0.1),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha:0.3),
                    EmergeColors.background,
                  ],
                ),
              ),
            ),
          ],
        ),
        title: Text(
          blueprint.blueprintName,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildCreatorInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: EmergeColors.teal.withValues(alpha:0.2),
          child: Text(
            blueprint.creatorName[0].toUpperCase(),
            style: const TextStyle(color: EmergeColors.teal, fontWeight: FontWeight.bold),
          ),
        ),
        const Gap(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By ${blueprint.creatorName}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            Text(
              blueprint.creatorArchetype,
              style: const TextStyle(color: EmergeColors.teal, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Spacer(),
        _StatBadge(
          icon: Icons.people_outline,
          label: '${blueprint.adoptionCount} Adoptions',
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ABOUT THIS BLUEPRINT',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Gap(12),
        Text(
          blueprint.description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildHabitStack() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THE HABIT STACK',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Gap(16),
        ...blueprint.habitTitles.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: EmergeColors.teal.withValues(alpha:0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: EmergeColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Gap(16),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAdoptButton(BuildContext context, WidgetRef ref, String? userId) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          if (userId == null) return;
          
          try {
            final repository = ref.read(habitRepositoryProvider);
            final result = await repository.createHabitsFromBlueprint(
              userId: userId,
              blueprint: blueprint,
            );

            result.fold(
              (failure) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${failure.message}'), backgroundColor: Colors.red),
                  );
                }
              },
              (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Blueprint adopted! Your new habit stack is ready.'),
                      backgroundColor: EmergeColors.teal,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
            );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: EmergeColors.teal,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          'ADOPT BLUEPRINT',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const Gap(6),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
