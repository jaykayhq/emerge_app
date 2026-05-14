import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/domain/services/weekly_recap_service.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/spotify_wrapped_recap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

class WeeklyRecapScreen extends ConsumerStatefulWidget {
  final String? recapId;
  final DateTime? startDate;
  final DateTime? endDate;

  const WeeklyRecapScreen({
    super.key,
    this.recapId,
    this.startDate,
    this.endDate,
  });

  @override
  ConsumerState<WeeklyRecapScreen> createState() => _WeeklyRecapScreenState();
}

class _WeeklyRecapScreenState extends ConsumerState<WeeklyRecapScreen> {
  @override
  Widget build(BuildContext context) {
    final recapService = ref.read(weeklyRecapServiceProvider);

    final user = ref.watch(authStateChangesProvider).value;

    // If no user logic handled by auth wrapper or router usually, but safety check:
    if (user == null) {
      return const Scaffold(
        backgroundColor: EmergeColors.background,
        body: Center(
          child: CircularProgressIndicator(color: EmergeColors.teal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          FutureBuilder(
            future: recapService.generateRecap(
              userId: user.id,
              recapId: widget.recapId,
              startDate: widget.startDate,
              endDate: widget.endDate,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: EmergeColors.teal),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 48,
                      ),
                      const Gap(16),
                      Text(
                        'Unable to generate recap',
                        style: TextStyle(color: Colors.white),
                      ),
                      const Gap(16),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                );
              }

              final recap = snapshot.data;
              if (recap == null) {
                return const Center(
                  child: CircularProgressIndicator(color: EmergeColors.teal),
                );
              }

              // Use the new Spotify Wrapped-style widget
              return SpotifyWrappedRecap(
                recap: recap,
                onClose: () => context.pop(),
              );
            },
          ),
        ],
      ),
    );
  }
}
