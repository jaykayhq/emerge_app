import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:emerge_app/core/router/router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-scoped dismissal latch for the verification banner.
class EmailVerificationBannerDismissed extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
}

final emailVerificationBannerDismissedProvider =
    NotifierProvider<EmailVerificationBannerDismissed, bool>(
        EmailVerificationBannerDismissed.new);

/// Non-blocking "verify your email" banner shown during the 7-day grace
/// period. Sign-up never blocks on verification; this top overlay nudges
/// the user until the server-side lock (emailLockedAt) kicks in — at which
/// point the full-screen VerifyEmailScreen takes over.
class EmailVerificationBanner extends ConsumerWidget {
  final Widget child;

  const EmailVerificationBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateChangesProvider).value;
    final emailLockedAt = ref.watch(currentEmailLockedAtProvider).value;
    final dismissed = ref.watch(emailVerificationBannerDismissedProvider);

    final showBanner = !dismissed &&
        authUser != null &&
        authUser.isNotEmpty &&
        authUser.emailVerified == false &&
        emailLockedAt == null;

    if (!showBanner) return child;

    // Hide on the verify screen itself — it has its own messaging. The
    // router state read is guarded: GoRouter throws when no route matches
    // (tests / deep links mid-transition).
    String currentPath;
    try {
      currentPath = ref.read(routerProvider).state.uri.path;
    } catch (_) {
      return child;
    }
    if (currentPath == '/verify-email') return child;

    return Scaffold(
      body: Stack(
        children: [
          child,
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: EmergeColors.warmGold.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Verify your email to keep your account.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        try {
                          ref.read(routerProvider).push('/verify-email');
                        } catch (_) {
                          // No router in the test harness — safe to ignore.
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Verify',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(emailVerificationBannerDismissedProvider.notifier)
                          .dismiss(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
