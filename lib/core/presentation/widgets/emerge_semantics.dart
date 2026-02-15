import 'package:flutter/material.dart';

/// Emerge Semantics Wrapper
///
/// Provides consistent accessibility labels and hints throughout the app.
/// Wraps Flutter's Semantics widget with Emerge-specific defaults.
///
/// Example:
/// ```dart
/// EmergeSemantics(
///   label: 'Create new habit',
///   hint: 'Opens the habit creation screen',
///   button: true,
///   child: FloatingActionButton(...),
/// )
/// ```
class EmergeSemantics extends StatelessWidget {
  /// The accessibility label read by screen readers.
  final String label;

  /// Optional hint providing additional context.
  final String? hint;

  /// The child widget to wrap with semantics.
  final Widget child;

  /// Whether this widget represents a button.
  final bool button;

  /// Whether this widget is in a selected/checked state.
  final bool selected;

  /// Whether this widget is enabled/tappable.
  final bool enabled;

  /// Optional value for stateful widgets (e.g., progress value).
  final String? value;

  /// Whether to exclude this widget from the semantics tree.
  final bool exclude;

  const EmergeSemantics({
    super.key,
    required this.label,
    this.hint,
    required this.child,
    this.button = false,
    this.selected = false,
    this.enabled = true,
    this.value,
    this.exclude = false,
  });

  @override
  Widget build(BuildContext context) {
    if (exclude) {
      return ExcludeSemantics(child: child);
    }

    return Semantics(
      label: label,
      hint: hint,
      button: button,
      selected: selected,
      enabled: enabled,
      value: value,
      child: child,
    );
  }
}

/// Emerge Tappable Semantics
///
/// Combines a tappable area with proper semantics for accessibility.
/// Ensures minimum tap target size of 44x44 (WCAG AAA).
class EmergeTappable extends StatelessWidget {
  /// The accessibility label.
  final String label;

  /// Optional hint.
  final String? hint;

  /// Callback when tapped.
  final VoidCallback onTap;

  /// The child widget to display.
  final Widget child;

  /// Minimum size for tap target (default 44x44).
  final double minSize;

  const EmergeTappable({
    super.key,
    required this.label,
    this.hint,
    required this.onTap,
    required this.child,
    this.minSize = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      container: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: _ensureMinSize(child),
      ),
    );
  }

  Widget _ensureMinSize(Widget child) {
    return Container(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: child,
    );
  }
}

/// Labeled tap target for icons that need larger touch areas.
///
/// Example:
/// ```dart
/// EmergeIconLabel(
///   icon: Icons.search,
///   label: 'Search clubs',
///   onTap: () => showSearch(),
/// )
/// ```
class EmergeIconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final Color? color;
  final double size;
  final bool selected;

  const EmergeIconLabel({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    this.onTap,
    this.color,
    this.size = 24.0,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).iconTheme.color;

    if (onTap != null) {
      return EmergeTappable(
        label: label,
        hint: hint,
        onTap: onTap!,
        child: Padding(
          padding: const EdgeInsets.all(10), // Ensure 44x44 tap target
          child: Icon(icon, color: effectiveColor, size: size),
        ),
      );
    }

    return Semantics(
      label: label,
      hint: hint,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: effectiveColor, size: size),
      ),
    );
  }
}

/// Progress indicator with accessibility support.
///
/// Automatically announces progress percentage to screen readers.
class EmergeProgressIndicator extends StatelessWidget {
  /// Progress value from 0.0 to 1.0.
  final double value;

  /// Optional label (e.g., "Loading habits").
  final String? label;

  /// Whether to show as a circular or linear indicator.
  final bool circular;

  /// Optional custom color.
  final Color? color;

  const EmergeProgressIndicator({
    super.key,
    required this.value,
    this.label,
    this.circular = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).toInt();
    final progressLabel = label ?? 'Progress';
    final semanticLabel = '$progressLabel: $percentage%';

    if (circular) {
      return Semantics(
        label: semanticLabel,
        value: '$percentage%',
        child: SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(value: value, color: color),
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      value: '$percentage%',
      child: LinearProgressIndicator(value: value, color: color),
    );
  }
}
