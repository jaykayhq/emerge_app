import 'dart:math' as math;
import 'package:emerge_app/features/monetization/presentation/providers/paywall_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emerge_app/features/monetization/presentation/screens/paystack_checkout_screen.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_badge.dart';

/// Redesigned paywall: "Go Beyond the 5" headline, hyperbolic-discounting
/// framing ("less than a coffee per day"), gold shimmer CTA, animated cosmic
/// background. Purchase wiring (RevenueCat packages, web Paystack, restore)
/// is preserved via [paywallControllerProvider].
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paywallControllerProvider.notifier).fetchOfferings();
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paywallState = ref.watch(paywallControllerProvider);
    final offerings = paywallState.offerings;

    // Automatically close the paywall if purchase succeeds; surface errors.
    ref.listen(paywallControllerProvider, (previous, next) {
      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        if (context.canPop()) context.pop();
      }
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          _buildCosmicBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                        ),
                        const Gap(8),
                        const Text(
                          'Go Beyond the 5',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          "You've built your foundation.\n"
                          "Now unlock what's waiting.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const Gap(40),
                        const _BenefitBlock(
                          icon: Icons.lock_open,
                          title: 'UNLIMITED',
                          subtitle: 'Habits, clubs, themes',
                          color: Colors.cyanAccent,
                        ),
                        const Gap(12),
                        const _BenefitBlock(
                          icon: Icons.insights,
                          title: 'PREMIUM INSIGHTS',
                          subtitle: 'Full evolution graphs & analytics',
                          color: Colors.purpleAccent,
                        ),
                        const Gap(12),
                        const _BenefitBlock(
                          icon: Icons.auto_awesome,
                          title: 'EXCLUSIVE STYLE',
                          subtitle: 'Gold nameplate, shimmer badge & more',
                          color: Color(0xFFFFD700),
                          trailing: PremiumBadge(size: 28),
                        ),
                        const Gap(40),
                        _buildPurchaseSection(paywallState, offerings),
                        const Gap(16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => ref
                                  .read(paywallControllerProvider.notifier)
                                  .restorePurchases(),
                              child: Text(
                                'Restore',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            const Gap(16),
                            TextButton(
                              onPressed: () => launchUrl(
                                Uri.parse('https://example.com/terms'),
                              ),
                              child: Text(
                                'Terms & Privacy',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Chooses the correct purchase UI: web uses Paystack, native uses the
  /// RevenueCat packages returned by the controller.
  Widget _buildPurchaseSection(PaywallState state, Offerings? offerings) {
    if (kIsWeb) {
      return _buildWebPurchase();
    }
    if (state.isLoading && offerings == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }
    if (offerings != null && offerings.current != null) {
      final packages = offerings.current!.availablePackages;
      // Only make the per-day ("coffee") framing when an actual annual package
      // exists — showing it against a monthly price would be misleading.
      Package? annual;
      for (final p in packages) {
        if (p.packageType == PackageType.annual) {
          annual = p;
          break;
        }
      }
      return Column(
        children: [
          if (annual != null) ...[
            Text(
              annual.storeProduct.priceString,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'per year — less than a coffee a week',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
            const Gap(20),
          ],
          ...packages.map(
            (package) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PackageButton(
                package: package,
                isLoading: state.isLoading,
                onTap: () => ref
                    .read(paywallControllerProvider.notifier)
                    .purchasePackage(package),
              ),
            ),
          ),
        ],
      );
    }
    return const Center(
      child: Text(
        'No subscription packages available currently.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }

  Widget _buildWebPurchase() {
    return _GoldShimmerButton(
      onPressed: () {
        final email =
            FirebaseAuth.instance.currentUser?.email ?? 'anonymous@emerge.com';
        Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => PaystackCheckoutScreen(
              amount: 10.0,
              email: email,
              identityType: 'premium',
            ),
          ),
        ).then((success) {
          if (!mounted) return;
          if (success == true && context.canPop()) {
            context.pop();
          }
        });
      },
      child: const _CtaLabel(price: '\$10.00 / mo'),
    );
  }

  Widget _buildCosmicBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) => CustomPaint(
        painter: _CosmicPainter(
          progress: _particleController.value,
          color: Colors.cyanAccent,
        ),
        size: MediaQuery.of(context).size,
      ),
    );
  }
}

class _CtaLabel extends StatelessWidget {
  final String? price;
  const _CtaLabel({this.price});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.auto_awesome, color: Colors.black87, size: 20),
        const Gap(8),
        Text(
          price == null ? 'UNLOCK YOUR POTENTIAL' : 'UPGRADE — $price',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _BenefitBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;

  const _BenefitBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const Gap(12), trailing!],
        ],
      ),
    );
  }
}

class _PackageButton extends StatelessWidget {
  final Package package;
  final bool isLoading;
  final VoidCallback onTap;

  const _PackageButton({
    required this.package,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAnnual = package.packageType == PackageType.annual;
    // Highlight the best-value (annual) package with the gold shimmer CTA.
    if (isAnnual) {
      return _GoldShimmerButton(
        onPressed: isLoading ? () {} : onTap,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black87,
                ),
              )
            : _CtaLabel(price: package.storeProduct.priceString),
      );
    }
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              package.storeProduct.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Text(
                package.storeProduct.priceString,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoldShimmerButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _GoldShimmerButton({required this.child, required this.onPressed});

  @override
  State<_GoldShimmerButton> createState() => _GoldShimmerButtonState();
}

class _GoldShimmerButtonState extends State<_GoldShimmerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: SweepGradient(
            colors: const [
              Color(0xFFFFD700),
              Color(0xFFFFA500),
              Color(0xFFFFD700),
              Colors.white70,
              Color(0xFFFFD700),
            ],
            transform: GradientRotation(_controller.value * 2 * math.pi),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple cosmic particle painter for the animated background.
class _CosmicPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CosmicPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    for (int i = 0; i < 20; i++) {
      final x = (i * 97 + progress * 50) % size.width;
      final y = (i * 131 + progress * 30) % size.height;
      final radius = 20 + (progress * 10);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPainter old) =>
      old.progress != progress;
}
