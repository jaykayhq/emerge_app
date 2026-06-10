import 'package:emerge_app/core/domain/entities/cue.dart';
import 'package:emerge_app/core/presentation/widgets/cue_popups.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_bottom_nav.dart';
import 'package:emerge_app/features/habits/presentation/providers/cue_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/presentation/widgets/companion_overlay.dart';
import 'package:emerge_app/features/companion/presentation/widgets/companion_panel.dart';
import 'package:emerge_app/features/companion/presentation/widgets/companion_inline_card.dart';
import 'package:emerge_app/features/companion/presentation/widgets/ask_mentor_button.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:emerge_app/core/theme/emerge_dimensions.dart';

/// Main scaffold wrapper that provides the growth background and
/// custom bottom navigation with elevated diamond FAB.
///
/// Navigation order: World → Timeline → [+FAB] → Tribes → Profile
///
/// Also serves as the CueEngine display layer — listens to cueStreamProvider
/// and shows [CuePopupDialog] or [CueBanner] for in-app habit cues.
class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wire the CueEngine stream: show popup/banner whenever a new cue fires
    ref.listen<AsyncValue<Cue>>(cueStreamProvider, (_, next) {
      next.whenData((cue) {
        if (!context.mounted) return;
        _showCue(context, cue);
      });
    });

    // Wire the CompanionEngine bottom panel bottom sheet
    ref.listen<CompanionState?>(companionVisibilityProvider, (previous, next) {
      if (next != null && next.visible && next.mode == CompanionMode.panel) {
        if (!context.mounted) return;
        CompanionPanel.show(
          context,
          message: next.message!,
          persona: next.persona!,
        ).then((_) {
          ref.read(companionEngineProvider.notifier).dismiss();
        });
      }
    });

    final companionState = ref.watch(companionVisibilityProvider);

    return Scaffold(
      body: WorldBackground(
        useSafeArea: false,
        child: Stack(
          children: [
            navigationShell,
            // Floating AskMentorButton
            Positioned(
              right: 16,
              bottom: EmergeDimensions.navBarHeight + 16,
              child: AskMentorButton(
                onTap: () => ref.read(companionEngineProvider.notifier).openPanel(),
              ),
            ),
            // Overlay Mode
            if (companionState != null &&
                companionState.visible &&
                companionState.mode == CompanionMode.overlay &&
                companionState.message != null &&
                companionState.persona != null)
              CompanionOverlay(
                message: companionState.message!,
                persona: companionState.persona!,
                targetKey: companionState.targetKey,
                onDismiss: () => ref.read(companionEngineProvider.notifier).dismiss(),
                onSkip: () => ref.read(companionEngineProvider.notifier).dismiss(),
              ),
            // Inline Card Mode
            if (companionState != null &&
                companionState.visible &&
                companionState.mode == CompanionMode.inlineCard &&
                companionState.message != null &&
                companionState.persona != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 0,
                right: 0,
                child: CompanionInlineCard(
                  message: companionState.message!,
                  persona: companionState.persona!,
                  onDismiss: () => ref.read(companionEngineProvider.notifier).dismiss(),
                  onTap: () {
                    ref.read(companionEngineProvider.notifier).dismiss();
                    ref.read(companionEngineProvider.notifier).openPanel();
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: EmergeBottomNav(
        navigationShell: navigationShell,
        onFabPressed: () => context.push('/timeline/create-habit'),
      ),
    );
  }

  void _showCue(BuildContext context, Cue cue) {
    // Use banner for gentle cues, full popup for urgent/milestone cues
    if (cue.intensity == CueIntensity.urgent ||
        cue.category == CueCategory.celebration ||
        cue.category == CueCategory.recovery) {
      showDialog<void>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (_) =>
            CuePopupDialog(cue: cue, onActionTaken: () {}, onDismissed: () {}),
      );
    } else {
      // Show as a top-of-screen banner via overlay for gentle cues
      final overlay = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => entry.remove(),
              child: CueBanner(
                cue: cue,
                onTap: () => entry.remove(),
                onDismiss: () => entry.remove(),
              ),
            ),
          ),
        ),
      );
      overlay.insert(entry);
      // Auto-remove banner after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (entry.mounted) entry.remove();
      });
    }
  }
}
