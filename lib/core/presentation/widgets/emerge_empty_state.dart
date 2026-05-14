import 'package:flutter/material.dart';

/// A reusable empty state widget with an illustration, title, and optional CTA.
///
/// Use this instead of ad-hoc "No data" text or empty Containers
/// across the app (dashboard, timeline, insights, etc.).
class EmergeEmptyState extends StatelessWidget {
  /// Primary label, e.g. "No habits yet".
  final String title;

  /// Supportive explanation / next-step hint.
  final String? subtitle;

  /// Icon displayed above the title.
  final IconData icon;

  /// Optional call-to-action button.
  final String? actionLabel;

  /// Callback when the CTA button is pressed.
  final VoidCallback? onAction;

  const EmergeEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
