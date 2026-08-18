// lib/features/gamification/presentation/widgets/recap_share_sheet.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:emerge_app/core/presentation/services/share_delivery.dart';
import 'package:emerge_app/core/presentation/services/shareable_image_exporter.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/features/gamification/presentation/services/recap_to_shareable_cards.dart';

/// Lets the user export the current recap slide or all slides as branded
/// PNGs, then share them (native share sheet / web download).
class RecapShareSheet extends StatefulWidget {
  final UserWeeklyRecap recap;
  final int currentIndex;

  /// Test seam: replaces the real export+share pipeline with a fake that
  /// returns whether sharing "succeeded".
  final Future<bool> Function()? onExportOverride;

  const RecapShareSheet({
    super.key,
    required this.recap,
    required this.currentIndex,
    this.onExportOverride,
  });

  @override
  State<RecapShareSheet> createState() => _RecapShareSheetState();
}

class _RecapShareSheetState extends State<RecapShareSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _export({required bool all}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final override = widget.onExportOverride;
      if (override != null) {
        if (!mounted) return;
        final ok = await override();
        if (!mounted) return;
        if (ok) {
          Navigator.of(context).pop();
        } else {
          setState(() => _error = 'Could not share the recap image.');
        }
        return;
      }

      final cards = recapToShareableCards(widget.recap);
      final selected = all
          ? cards
          : [cards[widget.currentIndex.clamp(0, cards.length - 1)]];
      // Render first, share once — one native sheet / one download bundle.
      // A missing slide aborts the whole batch: silently dropping part of
      // the recap would look like a harness bug to the recipient.
      final images = <Uint8List>[];
      final names = <String>[];
      final epoch = DateTime.now().microsecondsSinceEpoch;
      for (var i = 0; i < selected.length; i++) {
        if (!mounted) return;
        final bytes = await ShareableImageExporter.renderPng(
          context,
          selected[i],
        );
        if (bytes == null) {
          if (mounted) {
            setState(() => _error = 'Could not render the recap image.');
          }
          return;
        }
        images.add(bytes);
        names.add('emerge_recap_${epoch}_$i.png');
      }
      final result = await sharePngImages(
        fileNames: names,
        images: images,
        text: 'My Emerge Weekly Recap 🌟 #EmergeApp',
      );
      if (!mounted) return;
      switch (result) {
        case ShareDeliveryResult.success:
          Navigator.of(context).pop();
        case ShareDeliveryResult.dismissed:
          break; // user cancelled — keep the sheet open for a retry
        case ShareDeliveryResult.failed:
          setState(() => _error = 'Could not share the recap image.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share your recap',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _OptionTile(
              icon: Icons.image_rounded,
              title: 'Share current slide',
              subtitle: 'Export this card as a branded 9:16 image',
              onTap: _busy ? null : () => _export(all: false),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.collections_rounded,
              title: 'Share all slides',
              subtitle: 'Export the full recap as a set of images',
              onTap: _busy ? null : () => _export(all: true),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: EmergeColors.coral, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: EmergeColors.neonTeal, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
