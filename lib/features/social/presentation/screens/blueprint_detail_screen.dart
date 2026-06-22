import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/presentation/widgets/blueprint_adopt_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emerge_app/features/blueprints/presentation/providers/blueprint_detail_controller.dart';
class BlueprintDetailScreen extends ConsumerWidget {
  final Blueprint blueprint;

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
                    if (blueprint.isCreatorBlueprint && blueprint.creatorUserId.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(blueprint.creatorName.isNotEmpty ? blueprint.creatorName : 'Creator'),
                          subtitle: Text('${blueprint.tribeMemberCount} tribe members'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push('/social/creator/${blueprint.creatorUserId}');
                          },
                        ),
                      ),
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
              blueprint.imageUrl!.startsWith('images/')
                  ? Image.asset(blueprint.imageUrl!, fit: BoxFit.cover)
                  : CachedNetworkImage(
                      imageUrl: blueprint.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
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
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    EmergeColors.background,
                  ],
                ),
              ),
            ),
          ],
        ),
        title: Text(
          blueprint.title,
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
          backgroundColor: EmergeColors.teal.withValues(alpha: 0.2),
          child: Text(
            blueprint.creatorName[0].toUpperCase(),
            style: const TextStyle(
              color: EmergeColors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Gap(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By ${blueprint.creatorName}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              blueprint.creatorArchetype,
              style: const TextStyle(
                color: EmergeColors.teal,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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
        ...blueprint.habits.asMap().entries.map((entry) {
          final index = entry.key;
          final habit = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: EmergeColors.teal.withValues(alpha: 0.2),
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
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _StatBadge(
                            icon: Icons.schedule,
                            label: habit.frequency,
                          ),
                          if (habit.timeOfDay != null)
                            _StatBadge(
                              icon: Icons.wb_sunny,
                              label: habit.timeOfDay!,
                            ),
                          if (habit.timerDurationMinutes > 0)
                            _StatBadge(
                              icon: Icons.timer_outlined,
                              label: '${habit.timerDurationMinutes}M',
                            ),
                          if (habit.integrationType == HabitIntegrationType.healthSteps)
                            _StatBadge(
                              icon: Icons.directions_walk,
                              label: 'Steps',
                            ),
                          if (habit.integrationType == HabitIntegrationType.screenTimeLimit)
                            _StatBadge(
                              icon: Icons.phone_android,
                              label: 'Screen Time',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAdoptButton(
    BuildContext context,
    WidgetRef ref,
    String? userId,
  ) {
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final isPremium = isPremiumAsync.value ?? false;
    final isLoading = ref.watch(blueprintDetailControllerProvider).isLoading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
              : () async {
                if (userId == null) return;

                var didAdopt = false;
                String? reminderTimeString;
                await showDialog(
                  context: context,
                  builder: (ctx) => BlueprintAdoptDialog(
                    blueprint: blueprint,
                    onAdopt: (time) {
                      didAdopt = true;
                      reminderTimeString = time;
                    },
                  ),
                );

                if (!didAdopt || !context.mounted) return;

                try {
                  TimeOfDay? reminderTime;
                  if (reminderTimeString != null) {
                    final parts = reminderTimeString!.split(':');
                    reminderTime = TimeOfDay(
                      hour: int.parse(parts[0]),
                      minute: int.parse(parts[1]),
                    );
                  }
                  await ref
                      .read(blueprintDetailControllerProvider.notifier)
                      .adoptBlueprint(blueprint, reminderTime: reminderTime);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Adopted successfully'),
                        backgroundColor: EmergeColors.teal,
                      ),
                    );
                    context.go('/timeline');
                  }
                } catch (e) {
                  if (context.mounted) {
                    final errorMsg = e.toString().replaceAll('Exception: ', '');
                    if (errorMsg == 'Premium required') {
                      context.push('/paywall');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMsg),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: blueprint.isPremium
              ? EmergeColors.yellow
              : EmergeColors.teal,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                blueprint.isPremium && !isPremium
                    ? 'UNLOCK PREMIUM STACK'
                    : 'ADOPT BLUEPRINT',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
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
        color: Colors.white.withValues(alpha: 0.05),
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
