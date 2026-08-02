import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/creator_card.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_card.dart';
import 'package:emerge_app/features/tutorials/presentation/widgets/node_guide_host.dart';

class AllTribesScreen extends ConsumerStatefulWidget {
  const AllTribesScreen({super.key});

  @override
  ConsumerState<AllTribesScreen> createState() => _AllTribesScreenState();
}

class _AllTribesScreenState extends ConsumerState<AllTribesScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tribesAsync = ref.watch(allArchetypeClubsProvider);
    final creatorsAsync = ref.watch(verifiedCreatorsStreamProvider);

    return NodeGuideHost(
      nodeId: 'all_tribes',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'ALL TRIBES',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: tribesAsync.when(
          data: (tribes) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allArchetypeClubsProvider);
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── CREATORS ──
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'CREATORS',
                        style: TextStyle(
                          color: EmergeColors.nebulaPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _creatorsBody(creatorsAsync)),
                  // ── TRIBES ──
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'TRIBES',
                        style: TextStyle(
                          color: EmergeColors.nebulaPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  if (tribes.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No tribes available',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => TribeCard(tribe: tribes[index]),
                          childCount: tribes.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () =>
              const Center(child: EmergeLoadingSkeleton(itemCount: 5)),
          error: (error, stack) => Center(
            child: AppErrorWidget(
              message: 'Could not load tribes',
              onRetry: () => ref.invalidate(allArchetypeClubsProvider),
            ),
          ),
        ),
      ),
    );
  }

  /// CREATORS section body: horizontal card row, spinner while loading, or
  /// the "coming soon" empty state. Errors degrade to the empty state —
  /// the tribes grid must never be blocked by the creators stream.
  Widget _creatorsBody(AsyncValue<List<CreatorProfile>> creatorsAsync) {
    return SizedBox(
      height: 118,
      child: creatorsAsync.when(
        data: (creators) {
          if (creators.isEmpty) return const _CreatorsEmptyState();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: creators.length,
            separatorBuilder: (_, _) => const Gap(14),
            itemBuilder: (context, index) =>
                CreatorCard(creator: creators[index]),
          );
        },
        loading: () => const Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => const _CreatorsEmptyState(),
      ),
    );
  }
}

class _CreatorsEmptyState extends StatelessWidget {
  const _CreatorsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Creators are coming',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(4),
            Text(
              'Verified creators will appear here soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
