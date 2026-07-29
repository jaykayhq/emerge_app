import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/pulse_feed/presentation/screens/pulse_feed_screen.dart';

class SocialHubScreen extends ConsumerStatefulWidget {
  const SocialHubScreen({super.key});

  @override
  ConsumerState<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends ConsumerState<SocialHubScreen> {
  bool _navigatedToTribe = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(hasClubProvider, (prev, next) {
      next.whenData((hasClub) {
        if (hasClub && !_navigatedToTribe) {
          _navigatedToTribe = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToUserTribe();
          });
        } else if (!hasClub) {
          _navigatedToTribe = false;
        }
      });
    });

    return const PulseFeedScreen();
  }

  Future<void> _navigateToUserTribe() async {
    final userId = ref.read(authStateChangesProvider).value?.id;
    if (userId == null) return;
    final dao = ref.read(tribeMembershipDaoProvider);
    final membership = await dao.watchActiveMembership(userId).first;
    if (membership != null && mounted) {
      context.go('/social/tribe/${membership.tribeId}');
    }
  }
}
