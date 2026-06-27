import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_app_icon.dart';
import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/utils/validators.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreatorSignUpScreen extends ConsumerStatefulWidget {
  const CreatorSignUpScreen({super.key});

  @override
  ConsumerState<CreatorSignUpScreen> createState() => _CreatorSignUpScreenState();
}

class _CreatorSignUpScreenState extends ConsumerState<CreatorSignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final provider = signUpCreatorProvider(
      _emailController.text.trim(),
      _passwordController.text,
      _usernameController.text.trim(),
    );
    final subscription = ref.listenManual(provider, (previous, next) {});
    try {
      await ref.read(provider.future);
      if (mounted) {
        context.go('/splash');
      }
    } catch (e, stack) {
      debugPrint('CATCH ERROR _signUp: $e\n$stack');
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      subscription.close();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(signUpCreatorWithGoogleProvider.future);
      if (mounted) {
        context.go('/splash');
      }
    } catch (e) {
      debugPrint('CATCH ERROR _signUpWithGoogle: $e');
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
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
                                'Create blueprints, lead tribes, and inspire your community.',
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
                'Register to start leading.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ).animate(delay: 0.ms).fadeIn().slideY(begin: -0.05),
          const Gap(32),
        ] else ...[
          Text(
            'Creator Sign Up',
            style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
        ],

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Username
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
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
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.amber),
                ),
                validator: AppValidators.validateUsername,
              ).animate(delay: 100.ms).fadeIn().slideX(begin: 0.02),
              const Gap(16),

              // Email
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
                validator: AppValidators.validateEmail,
              ).animate(delay: 150.ms).fadeIn().slideX(begin: 0.02),
              const Gap(16),

              // Password
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
                validator: AppValidators.validatePassword,
              ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.02),
              const Gap(16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
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
                  prefixIcon: const Icon(Icons.lock_clock_outlined, color: Colors.amber),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
                  ),
                ),
                validator: (value) => AppValidators.validateConfirmPassword(
                  value,
                  _passwordController.text,
                ),
              ).animate(delay: 250.ms).fadeIn().slideX(begin: 0.02),
              const Gap(24),

              // Submit Button
              Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
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
                          'Register as Creator',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ).animate(delay: 300.ms).fadeIn().scale(begin: const Offset(0.97, 0.97)),
              const Gap(16),

              // Google Sign-Up button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signUpWithGoogle,
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
                label: const Text('Sign up with Google'),
              ).animate(delay: 350.ms).fadeIn().scale(begin: const Offset(0.97, 0.97)),
              const Gap(24),

              // Link to Login
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "Already have a creator account? ",
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () => context.go('/creator/login'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Login',
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
