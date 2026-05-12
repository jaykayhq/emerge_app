import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_card.dart';

class AllTribesScreen extends ConsumerWidget {
  const AllTribesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: tribesAsync.when(
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
        loading: () => const Center(
          child: EmergeLoadingSkeleton(itemCount: 5),
        ),
        error: (error, stack) => Center(
          child: AppErrorWidget(
            message: 'Could not load tribes',
            onRetry: () => ref.invalidate(allArchetypeClubsProvider),
          ),
        ),
      ),
    );
  }
}
