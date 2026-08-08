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
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isSending = false;
  String? _error;
  String? _info;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .sendEmailVerificationCode();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isSending = false;
      }),
      (_) => setState(() {
        _isSending = false;
        _info = 'We sent a 6-digit code to your email.';
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

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    final result =
        await ref.read(authRepositoryProvider).verifyEmailCode(code);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isVerifying = false;
      }),
      (_) {
        setState(() {
          _isVerifying = false;
          _info = 'Email verified!';
        });
        // Router's decideRedirect now lets the user through; land on a shell
        // path and let the router resolve onboarding/dashboard.
        try {
          context.go('/timeline');
        } catch (_) {
          // No router in this harness (pure widget tests) — safe to ignore.
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailLockedAt = ref.watch(currentEmailLockedAtProvider).value;
    final isLocked = emailLockedAt != null;

    return Scaffold(
      backgroundColor: EmergeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMainDark),
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
                ? 'Your 7-day verification window has passed. Enter a new code to unlock your account.'
                : 'We sent a 6-digit code to ${authUser.email.isEmpty ? 'your email' : authUser.email}.',
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
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textMainDark, fontSize: 22, letterSpacing: 6),
            decoration: InputDecoration(
              hintText: '000000',
              counterText: '',
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: EmergeColors.hexLine),
              ),
            ),
          ),
          const Gap(16),
          FilledButton(
            onPressed: (_isVerifying || _isSending) ? null : _verify,
            style: FilledButton.styleFrom(
              backgroundColor: EmergeColors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : const Text('Verify',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const Gap(12),
          OutlinedButton(
            onPressed: (_cooldown > 0 || _isSending) ? null : _sendCode,
            child: Text(
              _cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code',
            ),
          ),
        ],
      ),
    );
  }
}
