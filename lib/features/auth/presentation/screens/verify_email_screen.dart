import 'dart:async';

import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isSending = false;
  bool _isChecking = false;
  String? _error;
  String? _info;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  bool _navigatedOnVerify = false;

  @override
  void initState() {
    super.initState();
    // Deep link: the worker's verification email points straight back to
    // /verify-email?oobCode=... (handleCodeInApp). Apply the code directly
    // so the user is verified the moment the link opens the app. Otherwise
    // the first verification email is sent at signup (non-blocking) — only
    // auto-send here when no link has ever been sent, so visiting the
    // screen (banner tap / settings) never re-sends silently.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Deep links carry ?oobCode=; guarded because widget-test harnesses
      // have no GoRouter ancestor.
      String? oobCode;
      try {
        oobCode = GoRouterState.of(context).uri.queryParameters['oobCode'];
      } catch (_) {}
      if (oobCode != null && oobCode.isNotEmpty) {
        _applyOobCode(oobCode);
      } else {
        _maybeAutoSend();
      }
    });
  }

  Future<void> _applyOobCode(String oobCode) async {
    setState(() {
      _isChecking = true;
      _error = null;
      _info = 'Verifying your email…';
    });
    final result =
        await ref.read(authRepositoryProvider).applyVerificationCode(oobCode);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isChecking = false;
        _error = failure.message;
        _info = null;
      }),
      (_) {
        // Verified — the auth stream listener navigates once the reloaded
        // user (emailVerified: true) hits the stream.
        _cooldownTimer?.cancel();
        setState(() {
          _isChecking = false;
          _info = 'Email verified — taking you to the app.';
        });
      },
    );
  }

  void _maybeAutoSend() {
    final sentAt = ref.read(emailVerificationSentAtProvider).value;
    if (sentAt == null) _sendLink();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendLink() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _error = null;
      _info = null;
    });
    final result =
        await ref.read(authRepositoryProvider).sendVerificationEmail();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isSending = false;
      }),
      (_) => setState(() {
        _isSending = false;
        _info = 'Verification link sent — check your inbox.';
        _startCooldown();
      }),
    );
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _checkVerified() async {
    if (_isChecking || _isSending) return;
    setState(() {
      _isChecking = true;
      _error = null;
    });
    final result = await ref.read(authRepositoryProvider).checkEmailVerified();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isChecking = false;
      }),
      (verified) {
        _cooldownTimer?.cancel();
        setState(() {
          _isChecking = false;
          if (verified) {
            // The auth stream listener below navigates once the reloaded
            // user (emailVerified: true) hits the stream — the guard on
            // _navigatedOnVerify prevents double navigation.
            _info = 'Verified — taking you to the app.';
          } else {
            _error = 'Not verified yet — check your inbox (and spam) '
                'for the link, then try again.';
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Navigate once verification flips the auth stream. The stream delivery
    // lags the reload in checkEmailVerified (idTokenChanges), so we react to
    // the state transition instead of navigating eagerly — eager navigation
    // races decideRedirect, which still reads emailVerified as false and
    // bounces back to /verify-email.
    ref.listen<AsyncValue<AuthUser>>(authStateChangesProvider, (prev, next) {
      final verified = next.value?.emailVerified ?? false;
      if (verified && !_navigatedOnVerify) {
        _navigatedOnVerify = true;
        _cooldownTimer?.cancel();
        if (mounted) {
          try {
            context.go('/timeline');
          } catch (_) {
            // No router in the test harness — safe to ignore.
          }
        }
      }
    });

    // Loading/error fall back to "unlocked" — treat as within the grace
    // period, consistent with the router's guarded read. A stale lock only
    // relaxes an already-gated path.
    final emailLockedAt = ref.watch(currentEmailLockedAtProvider).value;
    final isLocked = emailLockedAt != null;

    return Scaffold(
      backgroundColor: EmergeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Locked users arrive via a redirect bounce; a back arrow that pops
        // back into a gated surface would just re-trigger the redirect loop.
        automaticallyImplyLeading: false,
        leading: isLocked
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppTheme.textMainDark),
                tooltip: 'Back',
                onPressed: () {
                  try {
                    context.pop();
                  } catch (_) {
                    // No router in this harness — safe to ignore.
                  }
                },
              ),
      ),
      body: ResponsiveLayout(
        mobile: _buildBody(context, isLocked),
        tablet: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildBody(context, isLocked),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isLocked) {
    final authUser = ref.watch(authStateChangesProvider).value ??
        const AuthUser(id: '', email: '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Gap(32),
          Icon(Icons.mark_email_read_outlined,
              size: 72, color: EmergeColors.teal),
          const Gap(16),
          Text(
            isLocked
                ? 'Account locked — verify your email'
                : 'Verify your email',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textMainDark,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(8),
          Text(
            isLocked
                ? 'Your 7-day verification window has passed. Resend the '
                    'link and verify to unlock your account.'
                : 'We sent a verification link to '
                    '${authUser.email.isEmpty ? 'your email' : authUser.email}. '
                    'Open it and click the link to confirm your account.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryDark,
                ),
          ),
          const Gap(24),
          if (_info != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_info!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: EmergeColors.teal)),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          const Gap(16),
          Semantics(
            label: 'I have verified my email',
            child: FilledButton(
              onPressed: (_isChecking || _isSending) ? null : _checkVerified,
              style: FilledButton.styleFrom(
                backgroundColor: EmergeColors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isChecking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text("I've verified — continue",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ),
          const Gap(12),
          OutlinedButton(
            onPressed: (_cooldown > 0 || _isSending) ? null : _sendLink,
            child: Text(
              _cooldown > 0 ? 'Resend link in ${_cooldown}s' : 'Resend link',
            ),
          ),
        ],
      ),
    );
  }
}
