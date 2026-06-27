import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_card.dart';

class AllTribesScreen extends ConsumerStatefulWidget {
  const AllTribesScreen({super.key});

  @override
  ConsumerState<AllTribesScreen> createState() => _AllTribesScreenState();
}

class _AllTribesScreenState extends ConsumerState<AllTribesScreen> {
  Timer? _initTimer;
  bool _showFirstVisitGuide = false;

  @override
  void initState() {
    super.initState();
    _initTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final repo = ref.read(companionRepositoryProvider);
      if (!repo.hasVisited('/social/all')) {
        repo.markVisited('/social/all');
        ref
            .read(companionEngineProvider.notifier)
            .triggerEvent(
              eventType: CompanionEventType.firstFeatureVisit,
              userContext: {'route': '/social/all'},
            );
        setState(() => _showFirstVisitGuide = true);
      }
    });
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tribesAsync = ref.watch(allArchetypeClubsProvider);

    return Scaffold(
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
      body: Stack(
        children: [
          tribesAsync.when(
            data: (tribes) {
              if (tribes.isEmpty) {
                return const Center(
                  child: Text(
                    'No tribes available',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(allArchetypeClubsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 32, top: 8),
                  itemCount: tribes.length,
                  itemBuilder: (context, index) {
                    return TribeCard(tribe: tribes[index]);
                  },
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
          if (_showFirstVisitGuide)
            FeatureCoachMark(
              title: "All Tribes",
              primaryColor: EmergeColors.nebulaPrimary,
              items: const [
                CoachItemData(
                  icon: Icons.explore,
                  title: "Browse Archetype Clubs",
                  body: "Explore all the archetype tribes available. Find your community and join one that resonates with your path.",
                ),
              ],
              onDismiss: () => setState(() => _showFirstVisitGuide = false),
            ),
        ],
      ),
    );
  }
}
