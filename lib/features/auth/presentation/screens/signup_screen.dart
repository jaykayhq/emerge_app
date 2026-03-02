import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_app_icon.dart';
import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/utils/validators.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
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
    if (formState == null || !formState.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );

      await result.fold((error) => throw Exception(error), (user) async {
        // Create User Profile with initial onboarding state
        final onboardingState = ref.read(onboardingStateProvider);

        final profile = UserProfile(
          uid: user.id,
          archetype: onboardingState.selectedArchetype ?? UserArchetype.none,
          avatarStats: UserAvatarStats(
            strengthXp: (onboardingState.attributes['Strength'] ?? 0) * 50,
            intellectXp: (onboardingState.attributes['Intellect'] ?? 0) * 50,
            vitalityXp: (onboardingState.attributes['Vitality'] ?? 0) * 50,
            creativityXp: (onboardingState.attributes['Creativity'] ?? 0) * 50,
            focusXp: (onboardingState.attributes['Focus'] ?? 0) * 50,
            spiritXp: (onboardingState.attributes['Spirit'] ?? 0) * 50,
            level: GamificationService.calculateLevel(
              onboardingState.attributes.values.fold(
                    0,
                    (sum, val) => sum + val,
                  ) *
                  50,
            ),
          ),
          why: onboardingState.why,
          anchors: onboardingState.anchors,
          habitStacks: onboardingState.habitStacks,
          onboardingProgress: 0, // Start at step 0
          onboardingStartedAt: DateTime.now(),
        );

        final profileRepo = ref.read(userProfileRepositoryProvider);
        final profileResult = await profileRepo.createProfile(profile);

        await profileResult.fold(
          (error) => throw Exception('Failed to create profile: $error'),
          (_) async {
            if (mounted) {
              // Navigate to onboarding - user will complete all steps before dashboard
              context.go('/onboarding/identity-studio');
            }
          },
        );
      });
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        if (errorMessage.contains('email-already-in-use')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Email already in use. Please login instead.',
              ),
              action: SnackBarAction(
                label: 'Login',
                onPressed: () => context.go('/login'),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage.replaceAll('Exception: ', ''))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authRepositoryProvider).signInWithGoogle();
      await result.fold((error) => throw Exception(error), (user) async {
        // Create User Profile with initial onboarding state
        final onboardingState = ref.read(onboardingStateProvider);

        final profile = UserProfile(
          uid: user.id,
          archetype: onboardingState.selectedArchetype ?? UserArchetype.none,
          avatarStats: UserAvatarStats(
            strengthXp: (onboardingState.attributes['Strength'] ?? 0) * 50,
            intellectXp: (onboardingState.attributes['Intellect'] ?? 0) * 50,
            vitalityXp: (onboardingState.attributes['Vitality'] ?? 0) * 50,
            creativityXp: (onboardingState.attributes['Creativity'] ?? 0) * 50,
            focusXp: (onboardingState.attributes['Focus'] ?? 0) * 50,
            spiritXp: (onboardingState.attributes['Spirit'] ?? 0) * 50,
            level: GamificationService.calculateLevel(
              onboardingState.attributes.values.fold(
                    0,
                    (sum, val) => sum + val,
                  ) *
                  50,
            ),
          ),
          why: onboardingState.why,
          anchors: onboardingState.anchors,
          habitStacks: onboardingState.habitStacks,
          onboardingProgress: 0, // Start at step 0
          onboardingStartedAt: DateTime.now(),
        );

        final profileRepo = ref.read(userProfileRepositoryProvider);
        await profileRepo.createProfile(profile);

        if (mounted) {
          // Navigate to onboarding - user will complete all steps before dashboard
          context.go('/onboarding/identity-studio');
        }
      });
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        if (errorMessage.contains('email-already-in-use') ||
            errorMessage.contains('account-exists-with-different-credential')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account already exists. Please login.'),
              action: SnackBarAction(
                label: 'Login',
                onPressed: () => context.go('/login'),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage.replaceAll('Exception: ', ''))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMainDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // 1. Background
          const Positioned.fill(child: HexMeshBackground()),

          // 2. Ambient Glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    EmergeColors.violet.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Content
          ResponsiveLayout(
            mobile: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      const Center(child: EmergeAppIcon(size: 64)),
                      const Gap(24),

                      Text(
                        'Begin Your Quest',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.textMainDark,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(8),
                      Text(
                        'Create your character and start your journey.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(32),

                      // Username Field
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: AppTheme.textMainDark),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondaryDark,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: EmergeColors.teal,
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.hexLine),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.hexLine),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.teal),
                          ),
                        ),
                        validator: AppValidators.validateUsername,
                      ),
                      const Gap(16),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: AppTheme.textMainDark),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondaryDark,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: EmergeColors.teal,
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.hexLine),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.hexLine),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.teal),
                          ),
                        ),
                        validator: AppValidators.validateEmail,
                      ),
                      const Gap(16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppTheme.textMainDark),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondaryDark,
                          ),
                          prefixIcon: Icon(
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
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.hexLine),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.hexLine),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.teal),
                          ),
                        ),
                        validator: AppValidators.validatePassword,
                      ),
                      const Gap(16),

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: AppTheme.textMainDark),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondaryDark,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: EmergeColors.teal,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textSecondaryDark,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.hexLine),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.hexLine),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: EmergeColors.teal),
                          ),
                        ),
                        validator: (value) =>
                            AppValidators.validateConfirmPassword(
                              value,
                              _passwordController.text,
                            ),
                      ),
                      const Gap(24),

                      // Sign Up Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [EmergeColors.teal, EmergeColors.teal],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: EmergeColors.teal.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FilledButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                  'Sign Up',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .black, // Dark text on bright gradient
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const Gap(16),

                      // Google Sign Up
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signUpWithGoogle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: EmergeColors.teal.withValues(alpha: 0.5),
                          ),
                          foregroundColor: AppTheme.textMainDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          color: EmergeColors.teal,
                        ),
                        label: const Text('Sign up with Google'),
                      ),
                      const Gap(24),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(color: AppTheme.textSecondaryDark),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: EmergeColors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            tablet: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Card(
                  color: AppTheme.surfaceDark,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: EmergeColors.hexLine),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              EmergeAppIcon(size: 80),
                              const Gap(24),
                              Text(
                                'Start Journey',
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      color: EmergeColors.teal,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const Gap(16),
                              Text(
                                'Create your account and start building better habits today.',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryDark,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        VerticalDivider(width: 64, color: EmergeColors.hexLine),
                        // ... (Repeat form logic for tablet if needed, or refactor to reuse widget.
                        // For brevity, I'll direct user to the mobile form widget or just duplicate standard fields)
                        // Note: To keep this clean, I'll copy the fields logic but usually I'd extract a widget.
                        // I will put a placeholder for the form reuse here or copy the fields.
                        // Given the instruction is "replace build method", I'll just reuse the same form styling logic here.
                        Expanded(
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              // *Simplification*: The original code duplicated the form.
                              // I'll direct the user to look at the mobile layout for simplicity or duplicate the fields if I must match exact functionality.
                              // I will duplicate the fields with the new styling.
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Create Account',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: AppTheme.textMainDark,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const Gap(32),
                                  // Username Field
                                  TextFormField(
                                    // Note: reusing controllers in two places simultaneously is bad if both exist,
                                    // but ResponsiveLayout only shows one.
                                    controller: _usernameController,
                                    style: const TextStyle(
                                      color: AppTheme.textMainDark,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Username',
                                      labelStyle: TextStyle(
                                        color: AppTheme.textSecondaryDark,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.person_outline,
                                        color: EmergeColors.teal,
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.surfaceDark,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: EmergeColors.hexLine,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: EmergeColors.teal,
                                        ),
                                      ),
                                    ),
                                    validator: AppValidators.validateUsername,
                                  ),
                                  const Gap(16),
                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(
                                      color: AppTheme.textMainDark,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: TextStyle(
                                        color: AppTheme.textSecondaryDark,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: EmergeColors.teal,
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.surfaceDark,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: EmergeColors.hexLine,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: EmergeColors.teal,
                                        ),
                                      ),
                                    ),
                                    validator: AppValidators.validateEmail,
                                  ),
                                  const Gap(16),
                                  // Password
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(
                                      color: AppTheme.textMainDark,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: TextStyle(
                                        color: AppTheme.textSecondaryDark,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: EmergeColors.teal,
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.surfaceDark,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: EmergeColors.hexLine,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: EmergeColors.teal,
                                        ),
                                      ),
                                    ),
                                    validator: AppValidators.validatePassword,
                                  ),
                                  const Gap(16),
                                  // Confirm
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    style: const TextStyle(
                                      color: AppTheme.textMainDark,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      labelStyle: TextStyle(
                                        color: AppTheme.textSecondaryDark,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: EmergeColors.teal,
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.surfaceDark,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: EmergeColors.hexLine,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: EmergeColors.teal,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        AppValidators.validateConfirmPassword(
                                          value,
                                          _passwordController.text,
                                        ),
                                  ),
                                  const Gap(24),
                                  // Button
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          EmergeColors.teal,
                                          EmergeColors.teal,
                                        ],
                                      ),
                                    ),
                                    child: FilledButton(
                                      onPressed: _isLoading ? null : _signUp,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : const Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const Gap(16),
                                  // Google Sign Up
                                  OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _signUpWithGoogle,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      side: BorderSide(
                                        color: EmergeColors.teal.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      foregroundColor: AppTheme.textMainDark,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const FaIcon(
                                      FontAwesomeIcons.google,
                                      color: EmergeColors.teal,
                                      size: 20,
                                    ),
                                    label: const Text('Sign up with Google'),
                                  ),
                                  const Gap(24),
                                  // Login Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account?',
                                        style: TextStyle(
                                          color: AppTheme.textSecondaryDark,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => context.go('/login'),
                                        child: Text(
                                          'Login',
                                          style: TextStyle(
                                            color: EmergeColors.teal,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
        ],
      ),
    );
  }
}
