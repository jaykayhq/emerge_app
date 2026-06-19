import 'dart:async';

import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreatorVerifyEmailScreen extends ConsumerStatefulWidget {
  final bool enableTimer;
  const CreatorVerifyEmailScreen({
    super.key,
    this.enableTimer = true,
  });

  @override
  ConsumerState<CreatorVerifyEmailScreen> createState() => _CreatorVerifyEmailScreenState();
}

class _CreatorVerifyEmailScreenState extends ConsumerState<CreatorVerifyEmailScreen> {
  bool _isReloading = false;
  bool _isResending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.enableTimer) {
      _startVerificationCheckTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startVerificationCheckTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final auth = ref.read(firebaseAuthProvider);
        final user = auth.currentUser;
        if (user != null) {
          await user.reload();
          final updatedUser = auth.currentUser;
          if (updatedUser != null && updatedUser.emailVerified) {
            _timer?.cancel();
            if (mounted) {
              context.go('/creator/dashboard');
            }
          }
        }
      } catch (_) {
        // Silently ignore background reload errors to avoid disturbing the user
      }
    });
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _isReloading = true);
    try {
      final auth = ref.read(firebaseAuthProvider);
      final user = auth.currentUser;
      if (user != null) {
        await user.reload();
        // Fetch user again after reload to get updated status
        final updatedUser = auth.currentUser;
        if (updatedUser != null && updatedUser.emailVerified) {
          if (mounted) {
            context.go('/creator/dashboard');
          }
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReloading = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email resent.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('No authenticated user found.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resending email: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _signOutAndBack() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) {
        context.go('/creator/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final email = user?.email ?? 'your email';

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.amber.withValues(alpha: 0.15),
                    EmergeColors.violet.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ResponsiveLayout(
                mobile: _buildContent(theme, email, isMobile: true),
                tablet: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Card(
                      elevation: 8,
                      color: EmergeColors.background.withValues(alpha: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: Colors.amber, width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: _buildContent(theme, email, isMobile: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, String email, {required bool isMobile}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: const Icon(
            Icons.mark_email_unread_outlined,
            size: 80,
            color: Colors.amber,
          ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
        ),
        const Gap(24),
        Text(
          'Verify your Email',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        const Gap(16),
        Text(
          'We sent a verification link to:\n$email',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
        const Gap(8),
        Text(
          'Please click the link in the email to activate your creator account.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white54,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
        const Gap(32),

        // Primary Button: I have verified my email
        Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Colors.amber, Colors.orange],
            ),
          ),
          child: ElevatedButton(
            onPressed: _isReloading ? null : _checkEmailVerified,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _isReloading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'I have verified my email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.95, 0.95)),
        const Gap(16),

        // Secondary Button: Resend Email
        OutlinedButton.icon(
          onPressed: _isResending ? null : _resendVerificationEmail,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(
              color: Colors.amber.withValues(alpha: 0.5),
            ),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          icon: _isResending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.amber,
                  ),
                )
              : const Icon(Icons.refresh, color: Colors.amber),
          label: const Text(
            'Resend Email',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
        const Gap(24),

        // Text link: Back to Login
        TextButton(
          onPressed: _signOutAndBack,
          style: TextButton.styleFrom(
            foregroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            'Back to Login',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }
}
