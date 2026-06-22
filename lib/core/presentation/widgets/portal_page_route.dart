import 'package:flutter/material.dart';

/// A custom portal transition that creates a "stepping into a portal" effect
/// when navigating from the Tribe Lobby into Tribe Space.
///
/// The outgoing screen scales down + fades, while the incoming screen
/// expands from the centre with a glow effect.
class PortalPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  PortalPageRoute({required this.builder, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Incoming: scale from 0.85 → 1.0 with fade-in
            final incomingScale = Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            final incomingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
              ),
            );

            // Outgoing: scale down 1.0 → 0.92 + fade out
            final outgoingScale =
                Tween<double>(begin: 1.0, end: 0.92).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOut,
              ),
            );
            final outgoingFade =
                Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
              ),
            );

            return Stack(
              children: [
                // Outgoing screen fades and shrinks
                FadeTransition(
                  opacity: outgoingFade,
                  child: ScaleTransition(
                    scale: outgoingScale,
                    child: const SizedBox.expand(),
                  ),
                ),
                // Incoming screen: scale-up + fade-in
                FadeTransition(
                  opacity: incomingFade,
                  child: ScaleTransition(
                    scale: incomingScale,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
}
