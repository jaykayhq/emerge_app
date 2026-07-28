import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
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
      next.whenOrNull(data: (hasClub) {
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

  void _navigateToUserTribe() {
    final archetype = ref.read(currentArchetypeProvider);
    if (archetype == UserArchetype.none) return;
    final tribe = ref.read(userClubProvider(archetype.name)).valueOrNull;
    if (tribe != null && context.mounted) {
      context.go('/social/tribe/${tribe.id}');
    }
  }
}
