import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Social-proof pill shown above the habit list for users in a tribe.
///
/// Compact one-liner: "🏟️ Tribe: N members done <label> so far".
/// Tapping navigates to the Pulse Feed (`/social`). Only render this when the user
/// actually belongs to a tribe — the caller owns that gating.
class TribalPresenceStrip extends StatelessWidget {
  final int memberCount;
  final String habitLabel;

  const TribalPresenceStrip({
    super.key,
    required this.memberCount,
    required this.habitLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tribe: $memberCount members done $habitLabel so far. '
          'Open Pulse Feed.',
      child: GestureDetector(
        onTap: () => context.go('/social'),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏟️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Tribe: $memberCount members done $habitLabel so far',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
