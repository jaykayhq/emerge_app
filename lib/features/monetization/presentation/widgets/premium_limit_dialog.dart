import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Aspiration-forward premium limit dialog shown when a free user hits a
/// scarcity gate (habit cap or club cap).
///
/// Two entry points are supported:
///  * [PremiumLimitDialog.forLimit] — the preferred API, driven by a
///    [PremiumLimitType]. It supplies aspiration copy + honest social proof.
///  * The primary constructor with explicit [title]/[message] — retained for
///    call sites that already build their own copy (e.g. the habit-capacity
///    path in `advanced_create_habit_dialog.dart`).
///
/// Copy is intentionally honest: it frames the free cap as a "focused start"
/// and appeals to the user's own potential rather than citing fabricated
/// cross-user statistics.
enum PremiumLimitType { habit, club }

class PremiumLimitDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const PremiumLimitDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock_outline,
  });

  /// Aspiration + honest social-proof factory keyed by [limitType].
  factory PremiumLimitDialog.forLimit(PremiumLimitType limitType) {
    switch (limitType) {
      case PremiumLimitType.habit:
        return const PremiumLimitDialog(
          title: "You've reached 5 habits",
          message:
              "That's the free limit — a focused start. Premium removes the "
              "cap so you can grow as far as your ambition takes you.",
          icon: Icons.rocket_launch,
        );
      case PremiumLimitType.club:
        return const PremiumLimitDialog(
          title: "You've joined 1 club",
          message:
              "That's the free limit. Premium unlocks unlimited clubs so you "
              "can belong to every community that moves you forward.",
          icon: Icons.groups_2,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.amber, size: 40),
                ),
                const Gap(20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(12),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.pop();
                      context.push('/paywall');
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text(
                      "SHOW ME WHAT I'M MISSING",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const Gap(8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Stay focused for now',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience helper to present the aspiration dialog for a [limitType].
void showPremiumLimitDialog(
  BuildContext context, {
  required PremiumLimitType limitType,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => PremiumLimitDialog.forLimit(limitType),
  );
}
