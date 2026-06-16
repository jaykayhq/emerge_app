import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_activity_feed.dart';

class TribeFeedTab extends ConsumerWidget {
  const TribeFeedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: TribeActivitySection(isGlobal: true),
    );
  }
}
