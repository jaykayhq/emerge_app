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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );

      await result.fold((error) => throw Exception(error), (user) async {
        // Create User Profile
        final onboardingState = ref.read(onboardingStateProvider);

        final profile = UserProfile(
          uid: user.id,
          archetype: onboardingState.selectedArchetype ?? UserArchetype.none,
          avatarStats: UserAvatarStats(
            strengthXp: onboardingState.attributes['Strength'] ?? 0,
            intellectXp:
                onboardingState.attributes['Focus'] ??
                0, // Mapping Focus to Intellect for now
            vitalityXp: onboardingState.attributes['Vitality'] ?? 0,
          ),
          why: onboardingState.why,
          anchors: onboardingState.anchors,
          habitStacks: onboardingState.habitStacks,
        );

        final profileRepo = ref.read(userProfileRepositoryProvider);
        final profileResult = await profileRepo.createProfile(profile);

        await profileResult.fold(
          (error) => throw Exception('Failed to create profile: $error'),
          (_) async {
            if (mounted) {
              // Mark onboarding as complete locally
              await ref
                  .read(onboardingControllerProvider.notifier)
                  .completeOnboarding();

              if (mounted) {
                context.go('/onboarding/archetype');
              }
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
        // Create User Profile
        final onboardingState = ref.read(onboardingStateProvider);

        final profile = UserProfile(
          uid: user.id,
          archetype: onboardingState.selectedArchetype ?? UserArchetype.none,
          avatarStats: UserAvatarStats(
            strengthXp: onboardingState.attributes['Strength'] ?? 0,
            intellectXp: onboardingState.attributes['Focus'] ?? 0,
            vitalityXp: onboardingState.attributes['Vitality'] ?? 0,
          ),
          why: onboardingState.why,
          anchors: onboardingState.anchors,
          habitStacks: onboardingState.habitStacks,
        );

        final profileRepo = ref.read(userProfileRepositoryProvider);
        await profileRepo.createProfile(profile);

        if (mounted) {
          await ref
              .read(onboardingControllerProvider.notifier)
              .completeOnboarding();

          if (mounted) {
            context.go('/onboarding/archetype');
          }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Account'),
      ),
      body: ResponsiveLayout(
        mobile: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Begin Your Quest',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primary,
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
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: AppValidators.validateUsername,
                  ),
                  const Gap(16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: AppValidators.validateEmail,
                  ),
                  const Gap(16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        tooltip:
                            _obscurePassword ? 'Show password' : 'Hide password',
                      ),
                    ),
                    validator: AppValidators.validatePassword,
                  ),
                  const Gap(16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        tooltip:
                            _obscureConfirmPassword
                                ? 'Show password'
                                : 'Hide password',
                      ),
                    ),
                    validator:
                        (value) => AppValidators.validateConfirmPassword(
                          value,
                          _passwordController.text,
                        ),
                  ),
                  const Gap(24),

                  // Sign Up Button
                  FilledButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.backgroundDark,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.backgroundDark,
                            ),
                          )
                        : const Text(
                            'Sign Up',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                  const Gap(16),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signUpWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.textSecondaryDark),
                      foregroundColor: AppTheme.textMainDark,
                    ),
                    icon: const FaIcon(
                      FontAwesomeIcons.google,
                      color: Colors.red,
                    ),
                    label: const Text('Sign up with Google'),
                  ),
                  const Gap(24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(color: AppTheme.textSecondaryDark),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: AppTheme.primary,
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
              ),
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 120,
                            width: 120,
                          ),
                          const Gap(24),
                          Text(
                            'Start Journey',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Gap(16),
                          Text(
                            'Create your account and start building better habits today.',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: AppTheme.textSecondaryDark),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(
                      width: 64,
                      color: AppTheme.textSecondaryDark,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Create Account',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: AppTheme.textMainDark),
                                textAlign: TextAlign.center,
                              ),
                              const Gap(32),
                              // Username Field
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  return null;
                                },
                              ),
                              const Gap(16),
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  return null;
                                },
                              ),
                              const Gap(16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    tooltip:
                                        _obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const Gap(16),

                              // Confirm Password Field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                    tooltip:
                                        _obscureConfirmPassword
                                            ? 'Show password'
                                            : 'Hide password',
                                  ),
                                ),
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const Gap(24),

                              // Sign Up Button
                              FilledButton(
                                onPressed: _isLoading ? null : _signUp,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: AppTheme.backgroundDark,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.backgroundDark,
                                        ),
                                      )
                                    : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const Gap(16),
                              OutlinedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : _signUpWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(
                                    color: AppTheme.textSecondaryDark,
                                  ),
                                  foregroundColor: AppTheme.textMainDark,
                                ),
                                icon: const FaIcon(
                                  FontAwesomeIcons.google,
                                  color: Colors.red,
                                ),
                                label: const Text('Sign up with Google'),
                              ),
                              const Gap(24),
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
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: AppTheme.primary,
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
    );
  }
}
