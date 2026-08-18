import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_quests_section.dart';

class TribeQuestsTab extends ConsumerWidget {
  const TribeQuestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [const Gap(16), const TribeQuestsSection(), const Gap(32)],
      ),
    );
  }
}
