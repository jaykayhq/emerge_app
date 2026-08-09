import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Shown after a Paystack web checkout redirects back with a reference.
/// Pure receipt/acknowledgement — entitlement flips via the webhook stream.
class OrderConfirmedScreen extends StatelessWidget {
  final String? reference;

  const OrderConfirmedScreen({super.key, this.reference});

  @override
  Widget build(BuildContext context) {
    final referenceText = (reference == null || reference!.isEmpty)
        ? 'Payment received'
        : 'Reference: $reference';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 96, color: EmergeColors.teal),
                const Gap(24),
                const Text(
                  'Order complete',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(12),
                Text(
                  'Your payment went through. Welcome to Emerge Premium.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const Gap(24),
                SelectableText(
                  referenceText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const Gap(40),
                FilledButton(
                  onPressed: () => context.go('/timeline'),
                  style: FilledButton.styleFrom(
                    backgroundColor: EmergeColors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                  ),
                  child: const Text(
                    'Start exploring',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
