import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/pulse_feed/presentation/screens/pulse_feed_screen.dart';

/// The Social tab's root screen.
///
/// Always renders [PulseFeedScreen] as the lobby. Navigation to a specific
/// tribe only happens via explicit user action (tapping a club from the
/// pulse feed or after onboarding club selection) — never auto-redirected.
class SocialHubScreen extends ConsumerWidget {
  const SocialHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PulseFeedScreen();
  }
}
