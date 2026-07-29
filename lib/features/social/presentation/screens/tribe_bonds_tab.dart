import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_accountability_section.dart';

class TribeBondsTab extends ConsumerWidget {
  const TribeBondsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Gap(16),
          const TribeAccountabilitySection().animate().fadeIn(delay: 400.ms),
          const Gap(32),
        ],
      ),
    );
  }
}
