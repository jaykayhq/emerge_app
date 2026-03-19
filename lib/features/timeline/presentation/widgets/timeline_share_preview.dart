import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/theme/emerge_earthy_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimelineSharePreviewDialog extends ConsumerStatefulWidget {
  final int completedHabits;
  final int totalHabits;
  final int totalStreaks;
  final int totalVotes;

  const TimelineSharePreviewDialog({
    super.key,
    required this.completedHabits,
    required this.totalHabits,
    required this.totalStreaks,
    required this.totalVotes,
  });

  @override
  ConsumerState<TimelineSharePreviewDialog> createState() =>
      _TimelineSharePreviewDialogState();
}

class _TimelineSharePreviewDialogState
    extends ConsumerState<TimelineSharePreviewDialog> {
  final GlobalKey _previewKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareImage() async {
    setState(() => _isSharing = true);
    try {
      final boundary =
          _previewKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/emerge_progress_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create();
      await file.writeAsBytes(buffer);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              'Building my Future Self with Emerge. +${widget.completedHabits} habits today, ${widget.totalStreaks} total streaks! 🔥',
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: EmergeColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userStatsStreamProvider);
    final userProfile = userProfileAsync.value;
    final level = userProfile?.effectiveLevel ?? 1;
    final archetype = userProfile?.archetype.name.toUpperCase() ?? 'SEEKER';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The Capture Boundary
          RepaintBoundary(
            key: _previewKey,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    EmergeColors.background,
                    EmergeColors.background.withValues(alpha: 0.9),
                  ],
                ),
                border: Border.all(
                  color: EmergeColors.teal.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GlassmorphismCard(
                  glowColor: EmergeColors.teal,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              ArchetypeTheme.forArchetype(
                                userProfile?.archetype ?? UserArchetype.none,
                              ).journeyIcon,
                              color: EmergeColors.teal,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    archetype,
                                    style: TextStyle(
                                      color: EmergeEarthyColors.terracotta,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    'Level $level',
                                    style: TextStyle(
                                      color: EmergeEarthyColors.cream
                                          .withValues(alpha: 0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEmojiStat(
                              emoji: '🔥',
                              value: '${widget.totalStreaks}',
                              label: 'Streaks',
                              color: EmergeColors.coral,
                            ),
                            _buildEmojiStat(
                              emoji: '🗳️',
                              value: '${widget.totalVotes}',
                              label: 'Votes',
                              color: EmergeColors.warmGold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Created with Emerge',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons (Not Captured)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _isSharing ? null : _shareImage,
                icon: _isSharing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share),
                label: const Text('Share Progress'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmergeColors.teal,
                  foregroundColor: EmergeColors.background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiStat({
    required String emoji,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
