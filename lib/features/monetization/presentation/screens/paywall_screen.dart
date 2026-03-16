import 'dart:ui';
import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/features/monetization/presentation/providers/paywall_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paywallState = ref.watch(paywallControllerProvider);
    final offerings = paywallState.offerings;
    
    // Automatically close the paywall if purchase succeeds
    ref.listen(paywallControllerProvider, (previous, next) {
      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        if (context.canPop()) {
           context.pop();
        }
      }
      
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent, // Let GrowthBackground show through
      body: GrowthBackground(
        child: Stack(
          children: [
            // Glassmorphism Overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                     child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () => context.pop(),
                            ),
                          ),
                          const Gap(20),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.purpleAccent, Colors.cyanAccent],
                            ).createShader(bounds),
                            child: Text(
                              'Evolve Your Avatar.',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                          Text(
                            'Command Your Entropy.',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const Gap(40),
                          _BenefitRow(
                            icon: Icons.psychology,
                            title: 'Unlimited "Oracle" AI Coach',
                            description: 'Deep psychological habit analysis & strategies.',
                          ),
                          const Gap(24),
                          _BenefitRow(
                            icon: Icons.filter_drama,
                            title: 'Avant-Garde World Themes',
                            description: 'Unlock Cosmic Void, Cyberpunk District, and Monolith.',
                          ),
                          const Gap(24),
                          _BenefitRow(
                            icon: Icons.handshake,
                            title: 'Advanced Identity Mechanics',
                            description: 'Unlimited Social Contracts & Archetype Tribes.',
                          ),
                          const Gap(24),
                          _BenefitRow(
                            icon: Icons.timeline,
                            title: 'Deep Time Insights',
                            description: 'Multi-month identity evolution graphs & analytics.',
                          ),
                          const Gap(40),
                          if (paywallState.isLoading && offerings == null)
                             const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                          else if (offerings != null && offerings.current != null)
                             ...[
                               ...offerings.current!.availablePackages.map(
                                 (package) => Padding(
                                   padding: const EdgeInsets.only(bottom: 16.0),
                                   child: _PackageButton(
                                     package: package,
                                     isLoading: paywallState.isLoading,
                                     onTap: () {
                                        ref.read(paywallControllerProvider.notifier).purchasePackage(package);
                                     },
                                   ),
                                 )
                               ),
                             ]
                          else 
                             const Center(child: Text("No subscription packages available currently.", style: TextStyle(color: Colors.white))),
                             
                          const Gap(32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () {
                                  ref.read(paywallControllerProvider.notifier).restorePurchases();
                                },
                                child: Text('Restore Purchases', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                              ),
                              Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                              TextButton(
                                onPressed: () {
                                  launchUrl(Uri.parse('https://example.com/terms'));
                                },
                                child: Text('Terms & Privacy', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                              ),
                            ],
                          ),
                          const Gap(40),
                        ],
                      ),
                    ),
                  )
                ]
              ),
            ),
          ],
        ),
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
      
      return InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isAnnual 
                 ? [Colors.purpleAccent.withValues(alpha: 0.2), Colors.cyanAccent.withValues(alpha: 0.2)]
                 : [Colors.white10, Colors.white10],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isAnnual ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.white24,
              width: isAnnual ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.storeProduct.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  ),
                  if (isAnnual) ...[
                     const Gap(4),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.cyanAccent.withValues(alpha: 0.2),
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: const Text('BEST VALUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                     ),
                  ]
                ],
              ),
               if (isLoading)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
               else 
                  Text(
                    package.storeProduct.priceString,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                  ),
            ],
          ),
        ),
      );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.cyanAccent, size: 24),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const Gap(4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
