import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Intercepts the Android hardware back button.
///
/// Use [AppBackToHome] for screens that should exit to a specific named
/// route (e.g. lobby → world map), and [AppDoubleTapExit] for root screens
/// that should require a double back-press to exit the app (e.g. world map).
class AppBackToHome extends StatelessWidget {
  final Widget child;
  final String homeRoute;

  const AppBackToHome({
    super.key,
    required this.child,
    this.homeRoute = '/world-map',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(homeRoute);
        }
      },
      child: child,
    );
  }
}

/// Double-tap-to-exit wrapper. The first back press shows a SnackBar
/// "Tap back again to exit"; the second back press within [exitWindow]
/// exits the app via [SystemNavigator.pop].
class AppDoubleTapExit extends StatefulWidget {
  final Widget child;
  final String snackBarMessage;
  final Duration exitWindow;

  const AppDoubleTapExit({
    super.key,
    required this.child,
    this.snackBarMessage = 'Tap back again to exit',
    this.exitWindow = const Duration(seconds: 2),
  });

  @override
  State<AppDoubleTapExit> createState() => _AppDoubleTapExitState();
}

class _AppDoubleTapExitState extends State<AppDoubleTapExit> {
  DateTime? _lastBack;

  void _handleBack() {
    final now = DateTime.now();
    final last = _lastBack;
    if (last != null && now.difference(last) < widget.exitWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.snackBarMessage),
          duration: widget.exitWindow,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: widget.child,
    );
  }
}
