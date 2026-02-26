import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glassmorphism card widget matching the Stitch design system.
///
/// Wraps content in a frosted-glass container with backdrop blur,
/// semi-transparent background, and optional green glow effect.
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? glowColor;
  final double glassOpacity;
  final double blurSigma;
  final bool showBorder;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.borderRadius = 16,
    this.glowColor,
    this.glassOpacity = 0.08,
    this.blurSigma = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: glassOpacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A themed glassmorphism card with Stitch green glow.
class EmergeGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const EmergeGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      padding: padding,
      margin: margin,
      glowColor: const Color(0xFF2BEE79), // Keep original green
      child: child,
    );
  }
}
