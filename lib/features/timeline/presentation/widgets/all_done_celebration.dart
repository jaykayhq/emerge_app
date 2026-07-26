import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// Peak-End all-done celebration: a gentle full-screen glow pulse plus a
/// narrator one-liner shown when the user completes the last habit of the day.
///
/// Trigger it imperatively via a [GlobalKey]<[AllDoneCelebrationState]>:
///
/// ```dart
/// final key = GlobalKey<AllDoneCelebrationState>();
/// // ...
/// key.currentState?.show();
/// ```
///
/// The widget renders nothing visible at rest (opacity 0); `show()` fades the
/// glow in, holds briefly, then fades it out.
class AllDoneCelebration extends StatefulWidget {
  const AllDoneCelebration({super.key});

  static const message = 'All done. Your future self thanks you.';

  @override
  State<AllDoneCelebration> createState() => AllDoneCelebrationState();
}

class AllDoneCelebrationState extends State<AllDoneCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  /// Plays the celebration once. Ignored if already animating.
  void show() {
    if (_controller.isAnimating || _controller.value != 0.0) return;
    HapticFeedback.heavyImpact();
    // Announce for screen-reader users — the glow/text are only on-screen for
    // ~2.6s and are decorative to the a11y tree otherwise.
    SemanticsService.sendAnnouncement(
      View.of(context),
      AllDoneCelebration.message,
      Directionality.of(context),
    );
    _controller.forward().then((_) {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _glow,
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.cyanAccent.withValues(
                      alpha: 0.18 * _glow.value,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
              child: child,
            );
          },
          child: Center(
            child: Text(
              AllDoneCelebration.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
