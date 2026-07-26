import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Social-proof pill shown above the habit list for users in a tribe.
///
/// Renders an honest presence line: "🏟️ Tribe: N members strong". The count
/// is the tribe's membership total (not a per-day completion figure), so the
/// copy deliberately says "strong" rather than claiming everyone finished
/// their habits.
///
/// Tapping navigates to the Pulse Feed (`/social`). Only render this when the
/// user actually belongs to a tribe — the caller owns that gating.
class TribalPresenceStrip extends StatelessWidget {
  final int memberCount;

  const TribalPresenceStrip({super.key, required this.memberCount});

  String get _label => 'Tribe: $memberCount members strong';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$_label. Open Pulse Feed.',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => context.go('/social'),
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏟️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _label,
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
          ),
        ),
      ),
    );
  }
}
