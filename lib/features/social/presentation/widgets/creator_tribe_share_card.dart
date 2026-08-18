// lib/features/social/presentation/widgets/creator_tribe_share_card.dart
import 'package:flutter/material.dart';
import 'package:emerge_app/core/presentation/services/share_delivery.dart';
import 'package:emerge_app/core/presentation/services/shareable_image_exporter.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/services/tribe_to_shareable_card.dart';

/// Exports the creator's tribe stats as a branded 9:16 card and shares it.
class CreatorTribeShareCard extends StatefulWidget {
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

  @override
  State<CreatorTribeShareCard> createState() => _CreatorTribeShareCardState();
}

class _CreatorTribeShareCardState extends State<CreatorTribeShareCard> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    final onExport = widget.onExport;
    if (onExport != null) return onExport();

    setState(() => _busy = true);
    try {
      final card = tribeToShareableCard(
        tribeName: widget.tribeName,
        creatorName: widget.creatorName,
        memberCount: widget.memberCount,
        totalXp: widget.totalXp,
        totalHabitsCompleted: widget.totalHabitsCompleted,
        totalChallengesCompleted: widget.totalChallengesCompleted,
      );
      final bytes = await ShareableImageExporter.renderPng(context, card);
      if (bytes == null) {
        if (mounted) _toast('Could not render the tribe card.');
        return;
      }
      final ok = await sharePngBytes(
        bytes: bytes,
        fileName: 'emerge_tribe_${DateTime.now().microsecondsSinceEpoch}.png',
        text: 'Join my tribe on Emerge!',
      );
      if (!mounted) return;
      // A dismissal isn't a failure — the user simply changed their mind.
      if (ok == ShareDeliveryResult.failed) {
        _toast('Could not share the tribe card.');
      }
    } catch (_) {
      if (mounted) _toast('Could not share the tribe card.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
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
        onTap: _busy ? null : _export,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.ios_share_rounded,
                color: EmergeColors.neonTeal,
                size: 22,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Share tribe card',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
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
