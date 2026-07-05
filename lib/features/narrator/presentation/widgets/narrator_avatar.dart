import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 44dp persistent narrator avatar. Idle: subtle pulse.
/// Has-pending-line: green status dot. Tap → opens NarratorSheet via callback.
class NarratorAvatar extends ConsumerStatefulWidget {
  final VoidCallback? onTap;
  const NarratorAvatar({super.key, this.onTap});

  @override
  ConsumerState<NarratorAvatar> createState() => _NarratorAvatarState();
}

class _NarratorAvatarState extends ConsumerState<NarratorAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingMilestoneProvider);
    final hasPending = pending != null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    EmergeColors.violet.withValues(alpha: 0.35),
                    EmergeColors.teal.withValues(alpha: 0.15),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [EmergeColors.violet, EmergeColors.teal],
                    ),
                  ),
                  child: const Center(
                    child: Text('✦', style: TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
          if (hasPending)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EmergeColors.teal,
                  boxShadow: [
                    BoxShadow(color: EmergeColors.teal.withValues(alpha: 0.6), blurRadius: 6),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
