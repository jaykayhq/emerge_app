import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_limit_dialog.dart';
import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_discovery_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_sanctum_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_quests_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_members_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_bonds_tab.dart';

final discoveryClubsProvider = StreamProvider<List<Tribe>>((ref) {
  return FirebaseFirestore.instance
      .collection('tribes')
      .snapshots()
      .map((snap) => snap.docs.map((d) => Tribe.fromMap(d.data())).toList());
});

Future<bool> clubJoinBlockedByFreeTier(
  WidgetRef ref,
  BuildContext context,
  String userId,
) async {
  bool isPremium = false;
  try {
    isPremium = await ref.read(isPremiumProvider.future);
  } catch (e, s) {
    AppLogger.e('clubJoinBlockedByFreeTier: isPremium resolve failed', e, s);
  }
  if (isPremium) return false;
  try {
    final tribes = await ref.read(tribeRepositoryProvider).getUserTribes(userId);
    if (!context.mounted) return true;
    if (tribes.isNotEmpty) {
      showPremiumLimitDialog(context, limitType: PremiumLimitType.club);
      return true;
    }
    return false;
  } catch (e, s) {
    AppLogger.e('clubJoinBlockedByFreeTier: getUserTribes failed', e, s);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't verify your membership — please try again."),
        ),
      );
    }
    return true;
  }
}

class TribeTabContent extends ConsumerStatefulWidget {
  const TribeTabContent({super.key});

  @override
  ConsumerState<TribeTabContent> createState() => _TribeTabContentState();
}

class _TribeTabContentState extends ConsumerState<TribeTabContent> {
  bool _showFirstVisitGuide = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final repo = ref.read(companionRepositoryProvider);
      if (!repo.hasVisited('/tribes')) {
        repo.markVisited('/tribes');
        ref
            .read(companionEngineProvider.notifier)
            .triggerEvent(
              eventType: CompanionEventType.firstFeatureVisit,
              userContext: {'route': '/tribes'},
            );
        setState(() => _showFirstVisitGuide = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasClubAsync = ref.watch(hasClubProvider);

    return Stack(
      children: [
        hasClubAsync.when(
          data: (hasClub) {
            if (!hasClub) return const TribeDiscoveryScreen();
            return DefaultTabController(
              length: 4,
              child: Scaffold(
                appBar: TabBar(
                  tabs: const [
                    Tab(text: 'SANCTUM'),
                    Tab(text: 'QUESTS'),
                    Tab(text: 'MEMBERS'),
                    Tab(text: 'BONDS'),
                  ],
                ),
                body: const TabBarView(
                  children: [
                    TribeSanctumTab(),
                    TribeQuestsTab(),
                    TribeMembersTab(),
                    TribeBondsTab(),
                  ],
                ),
              ),
            );
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 5),
          error: (_, _) => const TribeSanctumTab(),
        ),
        if (_showFirstVisitGuide)
          FeatureCoachMark(
            title: "Tribe Sanctum",
            primaryColor: EmergeColors.green,
            items: const [
              CoachItemData(
                icon: Icons.shield_outlined,
                title: "Tribe Momentum Score",
                body: "Check your team's current weekly momentum, active members, and territory tier.",
              ),
              CoachItemData(
                icon: Icons.people_outline,
                title: "Tribe Accountability",
                body: "Track who completed which habits today and maintain your collective streak.",
              ),
            ],
            onDismiss: () => setState(() => _showFirstVisitGuide = false),
          ),
      ],
    );
  }
}
