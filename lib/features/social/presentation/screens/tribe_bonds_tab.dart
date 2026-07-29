import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_accountability_section.dart';

class TribeBondsTab extends ConsumerStatefulWidget {
  const TribeBondsTab({super.key});

  @override
  ConsumerState<TribeBondsTab> createState() => _TribeBondsTabState();
}

class _TribeBondsTabState extends ConsumerState<TribeBondsTab> {
  final _bondsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Gap(16),
          TribeAccountabilitySection(key: _bondsKey).animate().fadeIn(delay: 400.ms),
          const Gap(32),
        ],
      ),
    );
  }
}
