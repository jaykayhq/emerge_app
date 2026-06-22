import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_app_icon.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/creator_onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Step 3 of creator onboarding — final reveal screen.
///
/// Confirms that onboarding is complete (saves progress = 3 + completedAt)
/// and gives the creator a moment to land before being routed to the
/// creator dashboard.
class CreatorOnboardingRevealScreen extends ConsumerStatefulWidget {
  const CreatorOnboardingRevealScreen({super.key});

  @override
  ConsumerState<CreatorOnboardingRevealScreen> createState() =>
      _CreatorRevealScreenState();
}

class _CreatorRevealScreenState extends ConsumerState<CreatorOnboardingRevealScreen> {
  bool _isCompleting = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    // Save completion lazily on mount so even if the user kills the app
    // right here we still mark them done.
    _saveCompletion();
  }

  Future<void> _saveCompletion() async {
    if (_completed) return;
    setState(() => _isCompleting = true);
    try {
      await ref.read(saveCreatorOnboardingProgressProvider(progress: 3).future);
      _completed = true;
    } catch (e) {
      // Non-fatal — the user can hit "Enter Creator Hub" which retries.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e. Tap continue to retry.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  Future<void> _enter() async {
    if (!_completed) await _saveCompletion();
    if (!mounted) return;
    context.go('/creator/dashboard');
  }

  @override
  Widget build(BuildContext context) {
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
                  radius: 1.0,
                  colors: [
                    Colors.amber.withValues(alpha: 0.25),
                    EmergeColors.violet.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Center(
                    child: const EmergeAppIcon(size: 96)
                        .animate()
                        .scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        )
                        .then()
                        .shimmer(
                          duration: 1500.ms,
                          color: Colors.amber,
                        ),
                  ),
                  const Gap(32),
                  Text(
                    'Welcome to the Creator Hub',
                    style: GoogleFonts.splineSans(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  const Gap(16),
                  Text(
                    "Your space is ready. Build blueprints, lead tribes, "
                    "and turn your best work into a system others can follow.",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 500.ms),
                  const Spacer(),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _isCompleting ? null : _enter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isCompleting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enter Creator Hub',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                  const Gap(16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
