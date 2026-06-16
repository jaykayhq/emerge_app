import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_accountability_section.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_quests_section.dart';

class MyTribeTab extends ConsumerWidget {
  const MyTribeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'My Tribe',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const TribeAccountabilitySection(),
          const SizedBox(height: 24),
          const TribeQuestsSection(),
        ],
      ),
    );
  }
}
