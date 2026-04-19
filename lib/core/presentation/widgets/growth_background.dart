// ignore_for_file: deprecated_member_use_from_same_package
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:flutter/material.dart';

/// Legacy wrapper — delegates to [WorldBackground].
/// Kept for backward compatibility so existing call-sites need no changes.
class GrowthBackground extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  /// [showPattern] and [overrideGradient] are ignored in the new system.
  /// Retained in the constructor so existing call-sites need no changes.
  const GrowthBackground({
    super.key,
    required this.child,
    this.appBar,
    @Deprecated('No longer used — WorldBackground renders the environment')
    bool showPattern = true,
    @Deprecated('No longer used — WorldBackground renders the environment')
    List<Color>? overrideGradient,
  });

  @override
  Widget build(BuildContext context) {
    return WorldBackground(appBar: appBar, child: child);
  }
}
