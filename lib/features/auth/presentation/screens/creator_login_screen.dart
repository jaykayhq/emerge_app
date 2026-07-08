import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_app_icon.dart';
import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CreatorLoginScreen extends ConsumerStatefulWidget {
  const CreatorLoginScreen({super.key});

  @override
  ConsumerState<CreatorLoginScreen> createState() => _CreatorLoginScreenState();
}

class _CreatorLoginScreenState extends ConsumerState<CreatorLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(
        signInProvider(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        ).future,
      );
      
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw Exception('User not found');
      }

      final isCreator = await ref.read(isCreatorProvider(user.uid).future);
      if (!isCreator) {
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This account is not registered as a creator. Please log out or switch accounts.')),
          );
        }
        return;
      }

      if (mounted) {
        context.go('/creator/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authRepositoryProvider).signInWithGoogle(isLogin: true);

      bool proceed = false;
      result.fold(
        (error) {
          // 'redirect_initiated' is not a real error — on web the page
          // navigates away to Google OAuth. Keep loading; do not show snackbar.
          if (error.message == 'redirect_initiated') return;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.message)),
            );
          }
        },
        (_) => proceed = true,
      );

      if (proceed) {
        final user = ref.read(firebaseAuthProvider).currentUser;
        if (user == null) {
          throw Exception('User not found');
        }

        final isCreator = await ref.read(isCreatorProvider(user.uid).future);
        if (!isCreator) {
          await ref.read(authRepositoryProvider).signOut();
          throw Exception(
            'This account is not registered as a creator. '
            'Please log out or switch accounts.',
          );
        }

        if (mounted) {
          context.go('/creator/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      // Don't reset loading on web redirect — the page will navigate away.
      // Only reset if still mounted and not mid-redirect.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(_emailController.text.trim());
      result.fold(
        (error) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message))),
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          // 1. Hex Mesh Background
          const Positioned.fill(child: HexMeshBackground()),

          // 2. Ambient Glow (Amber/Gold for Creator mode)
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

          // 3. Content
          ResponsiveLayout(
            mobile: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildFormContent(theme, isMobile: true),
              ),
            ),
            tablet: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Card(
                  elevation: 8,
                  color: EmergeColors.background.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Colors.amber, width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              EmergeAppIcon(size: 100),
                              const Gap(24),
                              Text(
                                'Creator Hub',
                                style: GoogleFonts.poppins(
                                  textStyle: theme.textTheme.displaySmall,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Gap(16),
                              Text(
                                'Manage your tribes, content,\nand analytics.',
                                style: GoogleFonts.poppins(
                                  textStyle: theme.textTheme.titleMedium,
                                  color: AppTheme.textSecondaryDark,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ).animate(delay: 0.ms).fadeIn().slideY(begin: -0.05),
                        ),
                        const VerticalDivider(
                          width: 64,
                          color: EmergeColors.hexLine,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildFormContent(theme, isMobile: false),
                          ),
                        ),
                      ],
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

  Widget _buildFormContent(ThemeData theme, {required bool isMobile}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMobile) ...[
          Column(
            children: [
              Center(child: EmergeAppIcon(size: 80)),
              const Gap(16),
              Text(
                'Creator Hub',
                style: GoogleFonts.poppins(
                  textStyle: theme.textTheme.headlineMedium,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Manage your presence.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ).animate(delay: 0.ms).fadeIn().slideY(begin: -0.05),
          const Gap(48),
        ] else ...[
          Text(
            'Creator Login',
            style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
        ],

        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: EmergeColors.background.withValues(alpha: 0.5),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: EmergeColors.hexLine),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.amber),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.amber),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ).animate(delay: 150.ms).fadeIn().slideX(begin: 0.02),
              const Gap(16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: EmergeColors.background.withValues(alpha: 0.5),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: EmergeColors.hexLine),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.amber),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.amber),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ).animate(delay: 250.ms).fadeIn().slideX(begin: 0.02),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _forgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.amber),
                  ),
                ),
              ),
              const Gap(24),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Login to Creator Hub',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ).animate(delay: 350.ms).fadeIn().scale(begin: const Offset(0.97, 0.97)),
              const Gap(16),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: SvgPicture.asset(
                  'assets/images/google_logo.svg',
                  width: 20,
                  height: 20,
                ),
                label: const Text('Sign in with Google'),
              ).animate(delay: 400.ms).fadeIn().scale(begin: const Offset(0.97, 0.97)),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "New creator? ",
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () => context.push('/creator/signup'),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Not a creator? ",
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
