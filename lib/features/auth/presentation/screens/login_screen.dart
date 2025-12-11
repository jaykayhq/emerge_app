import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'test@emerge.com');
  final _passwordController = TextEditingController(text: 'password');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(
        signInProvider(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        ).future,
      );
      // Navigation is handled by the router's redirect
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

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authRepositoryProvider).signInWithGoogle();
      result.fold(
        (error) => throw Exception(error),
        (_) => null, // Navigation handled by router
      );
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

    return GrowthBackground(
      child: ResponsiveLayout(
        mobile: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Branding
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    width: 100,
                  ),
                  const Gap(16),
                  Text(
                    'Emerge',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Become who you are.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.slateBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(48),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
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
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _forgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const Gap(8),

                  // Login Button
                  FilledButton(
                    onPressed: _isLoading ? null : _login,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.deepSunriseOrange,
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
                        : const Text('Login'),
                  ),
                  const Gap(16),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.slateBlue),
                    ),
                    icon: const FaIcon(
                      FontAwesomeIcons.google,
                      color: Colors.red,
                    ),
                    label: const Text('Sign in with Google'),
                  ),
                  const Gap(16),

                  // Sign Up Link
                  TextButton(
                    onPressed: () {
                      context.push('/signup');
                    },
                    child: const Text("Don't have an account? Sign Up"),
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
                            height: 150,
                            width: 150,
                          ),
                          const Gap(24),
                          Text(
                            'Emerge',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(16),
                          Text(
                            'Become who you are.',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppTheme.slateBlue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 64),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome Back',
                                style: theme.textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                              const Gap(32),
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
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
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _forgotPassword,
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              const Gap(8),

                              // Login Button
                              FilledButton(
                                onPressed: _isLoading ? null : _login,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: AppTheme.deepSunriseOrange,
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
                                    : const Text('Login'),
                              ),
                              const Gap(16),
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _loginWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(color: AppTheme.slateBlue),
                                ),
                                icon: const FaIcon(
                                  FontAwesomeIcons.google,
                                  color: Colors.red,
                                ),
                                label: const Text('Sign in with Google'),
                              ),
                              const Gap(16),

                              // Sign Up Link
                              TextButton(
                                onPressed: () {
                                  context.push('/signup');
                                },
                                child: const Text(
                                  "Don't have an account? Sign Up",
                                ),
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
