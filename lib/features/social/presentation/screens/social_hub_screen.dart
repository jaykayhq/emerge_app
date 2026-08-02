import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/pulse_feed/presentation/screens/pulse_feed_screen.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_lobby_screen.dart';

/// The Social tab's root screen.
///
/// When the user has an active tribe membership, renders [TribeLobbyScreen]
/// for the joined tribe (the canonical club hub). While the membership stream
/// is loading, or when there is no membership (signed out / not in a club),
/// it falls back to [PulseFeedScreen] so the tab never flickers between
/// states. Navigation to a specific tribe still happens via explicit user
/// action (tapping a club from the pulse feed or after onboarding club
/// selection).
class SocialHubScreen extends ConsumerWidget {
  const SocialHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(activeMembershipProvider).value;
    if (membership == null) {
      return const PulseFeedScreen();
    }
    return TribeLobbyScreen(tribeId: membership.tribeId);
  }
}
