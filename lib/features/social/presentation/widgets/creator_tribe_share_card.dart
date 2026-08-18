// lib/features/social/presentation/widgets/creator_tribe_share_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:emerge_app/core/presentation/services/shareable_image_exporter.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/services/tribe_to_shareable_card.dart';

/// Exports the creator's tribe stats as a branded 9:16 card and shares it.
class CreatorTribeShareCard extends StatelessWidget {
  final String tribeName;
  final String creatorName;
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  final Future<void> Function()? onExport; // test seam

  const CreatorTribeShareCard({
    super.key,
    required this.tribeName,
    required this.creatorName,
    required this.memberCount,
    required this.totalXp,
    required this.totalHabitsCompleted,
    required this.totalChallengesCompleted,
    this.onExport,
  });

  Future<void> _export(BuildContext context) async {
    if (onExport != null) return onExport!();
    try {
      final card = tribeToShareableCard(
        tribeName: tribeName,
        creatorName: creatorName,
        memberCount: memberCount,
        totalXp: totalXp,
        totalHabitsCompleted: totalHabitsCompleted,
        totalChallengesCompleted: totalChallengesCompleted,
      );
      if (!context.mounted) return;
      final bytes = await ShareableImageExporter.renderPng(context, card);
      if (bytes == null) {
        _toast(context, 'Could not render the tribe card.');
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/emerge_tribe_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Join my tribe on Emerge!'),
      );
    } catch (e) {
      if (context.mounted) _toast(context, 'Sharing failed: $e');
    }
  }

  void _toast(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EmergeColors.coral,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _export(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.ios_share_rounded, color: EmergeColors.neonTeal, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Share tribe card',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}