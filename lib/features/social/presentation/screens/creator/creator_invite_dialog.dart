import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_invite_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_invite_messages.dart';

/// Generates and shows a single-use creator invite code. Codes are generated
/// on demand (single-use, 7-day expiry, 10-outstanding cap) — never
/// auto-generated on dialog open so a stray open doesn't burn quota.
class CreatorInviteDialog extends ConsumerStatefulWidget {
  const CreatorInviteDialog({super.key});

  @override
  ConsumerState<CreatorInviteDialog> createState() =>
      CreatorInviteDialogState();
}

class CreatorInviteDialogState extends ConsumerState<CreatorInviteDialog> {
  bool _generating = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      await ref.read(creatorInviteControllerProvider.notifier).generate();
    } catch (e) {
      if (mounted) {
        setState(() => _error = inviteCodeErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite code copied'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(creatorInviteControllerProvider);
    return AlertDialog(
      backgroundColor: const Color(0xFF1A0A2A),
      title: const Text(
        'Invite a Creator',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate a single-use invite code. New creators enter it at '
            'signup — it expires in 7 days.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const Gap(16),
          if (code != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: EmergeColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EmergeColors.teal.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
            ),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _copy(code),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text(
                  'COPY CODE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmergeColors.teal,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generating ? null : _generate,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.card_giftcard_rounded, size: 18),
                label: Text(
                  _generating ? 'GENERATING…' : 'GENERATE INVITE CODE',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmergeColors.warmGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_error != null) ...[
              const Gap(12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
