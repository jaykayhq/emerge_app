import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared top-of-screen header: avatar on the left, status chips on the
/// right (design reference: docs/timeline-redesign-preview.html).
///
/// Watches only [isPremiumProvider] to decide between the "PRO" and
/// "Free Trial" chips; everything else is driven by constructor params.
class EmergeHeader extends ConsumerWidget {
  final String displayName;
  final bool showToday;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onUpgradeTap;
  final Widget? trailing;

  const EmergeHeader({
    super.key,
    required this.displayName,
    this.showToday = false,
    this.onAvatarTap,
    this.onUpgradeTap,
    this.trailing,
  });

  static const _teal = Color(0xFF34D4B8);

  String get _initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumAsync = ref.watch(isPremiumProvider);

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Avatar (tappable, opens profile)
            Semantics(
              label: 'Profile',
              button: true,
              child: GestureDetector(
                onTap: onAvatarTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _initial,
                      style: TextStyle(
                        color: _teal.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Status chips
            Row(
              children: [
                if (showToday) ...[
                  _HeaderChip(
                    label: 'Today',
                    textColor:
                        const Color(0xFFF6F7FB).withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 8),
                ],
                premiumAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (isPremium) => isPremium
                      ? _HeaderChip(
                          label: 'PRO',
                          textColor: _teal,
                          fontWeight: FontWeight.w600,
                          backgroundColor: _teal.withValues(alpha: 0.12),
                          borderColor: _teal.withValues(alpha: 0.30),
                        )
                      : GestureDetector(
                          onTap: onUpgradeTap,
                          behavior: HitTestBehavior.opaque,
                          child: _HeaderChip(
                            label: 'Free Trial',
                            textColor: const Color(0xFFF5A623)
                                .withValues(alpha: 0.85),
                          ),
                        ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped chip used by [EmergeHeader]; defaults to the standard
/// low-contrast chip style.
class _HeaderChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final FontWeight fontWeight;
  final Color? backgroundColor;
  final Color? borderColor;

  const _HeaderChip({
    required this.label,
    required this.textColor,
    this.fontWeight = FontWeight.normal,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
