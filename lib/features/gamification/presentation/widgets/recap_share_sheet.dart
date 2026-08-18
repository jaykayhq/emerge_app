// lib/features/gamification/presentation/widgets/recap_share_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:emerge_app/core/presentation/services/shareable_image_exporter.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/features/gamification/presentation/services/recap_to_shareable_cards.dart';

/// Lets the user export the current recap slide or all slides as branded
/// PNGs, then share them (native share sheet / web download).
class RecapShareSheet extends StatefulWidget {
  final UserWeeklyRecap recap;
  final int currentIndex;

  const RecapShareSheet({
    super.key,
    required this.recap,
    required this.currentIndex,
  });

  @override
  State<RecapShareSheet> createState() => _RecapShareSheetState();
}

class _RecapShareSheetState extends State<RecapShareSheet> {
  bool _busy = false;

  Future<void> _export({required bool all}) async {
    setState(() => _busy = true);
    try {
      final cards = recapToShareableCards(widget.recap);
      final selected = all
          ? cards
          : [
              cards[(widget.currentIndex).clamp(0, cards.length - 1)],
            ];
      final files = <XFile>[];
      for (final card in selected) {
        if (!mounted) return;
        final bytes = await ShareableImageExporter.renderPng(context, card);
        if (bytes == null) continue;
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/emerge_recap_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(bytes);
        files.add(XFile(file.path));
      }
      if (files.isEmpty) {
        _toast('Could not render the recap image.');
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: 'My Emerge Weekly Recap 🌟 #EmergeApp',
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('Sharing failed: $e');
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share your recap',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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