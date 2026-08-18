import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:emerge_app/core/utils/validators.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/widgets/password_requirement_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Branded "choose a new password" screen. Users land here from the native
/// Firebase Auth password-reset email (ActionCodeSettings url points at
/// /reset-password?oobCode=...). Applies the oobCode with
/// [AuthRepository.resetPasswordWithCode] and returns to /login.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Read the oobCode from the reset link (?oobCode=...) — the email's
    // styled button opens this route directly. Guarded because widget-test
    // harnesses have no GoRouter ancestor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final oobCode = GoRouterState.of(
          context,
        ).uri.queryParameters['oobCode'];
        if (oobCode == null || oobCode.isEmpty) {
          setState(() {
            _error =
                'This reset link is missing its code. '
                'Please request a new one.';
          });
        }
      } catch (_) {
        // No router in the test harness — the test passes oobCode via extra.
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final oobCode = _extractOobCode();
    if (oobCode == null || oobCode.isEmpty) {
      setState(() {
        _error =
            'This reset link is missing its code. '
            'Please request a new one.';
      });
      return;
    }
    final passwordError = AppValidators.validatePassword(
      _passwordController.text,
    );
    if (passwordError != null) {
      setState(() => _error = passwordError);
      return;
    }
    final confirmError = AppValidators.validateConfirmPassword(
      _passwordController.text,
      _confirmController.text,
    );
    if (confirmError != null) {
      setState(() => _error = confirmError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .resetPasswordWithCode(
          oobCode: oobCode,
          newPassword: _passwordController.text,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isSubmitting = false;
        _error = failure.message;
      }),
      (_) {
        // Password changed — send the user to the login screen. The reset
        // link flow was initiated while signed out, so there is no session
        // to sign out of.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset — log in with your new password.'),
          ),
        );
        try {
          context.go('/login');
        } catch (_) {
          // No router in the test harness.
          setState(() => _isSubmitting = false);
        }
      },
    );
  }

  String? _extractOobCode() {
    try {
      return GoRouterState.of(context).uri.queryParameters['oobCode'];
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMainDark),
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
        mobile: _buildBody(context),
        tablet: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Gap(16),
          Icon(Icons.lock_reset_outlined, size: 72, color: EmergeColors.teal),
          const Gap(16),
          Text(
            'Choose a new password',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textMainDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          Text(
            'Your reset link is valid — set a strong new password to '
            'continue.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
          ),
          const Gap(24),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppTheme.textMainDark),
            decoration: InputDecoration(
              labelText: 'New Password',
              labelStyle: const TextStyle(color: AppTheme.textSecondaryDark),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: EmergeColors.teal,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondaryDark,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: EmergeColors.hexLine),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: EmergeColors.hexLine),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: EmergeColors.teal),
              ),
            ),
          ),
          PasswordRequirementChecklist(passwordController: _passwordController),
          const Gap(16),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            style: const TextStyle(color: AppTheme.textMainDark),
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              labelStyle: const TextStyle(color: AppTheme.textSecondaryDark),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: EmergeColors.teal,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondaryDark,
                ),
                onPressed: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
              ),
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: EmergeColors.hexLine),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: EmergeColors.hexLine),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: EmergeColors.teal),
              ),
            ),
          ),
          const Gap(24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: EmergeColors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Update password',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
