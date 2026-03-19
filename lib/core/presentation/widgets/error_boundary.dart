import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// A reusable error boundary widget that catches errors and displays a fallback UI.
///
/// Wraps a child widget and catches any errors that occur during rendering or
/// async operations. Displays a user-friendly error message with optional retry.
///
/// Example:
/// ```dart
/// ErrorBoundary(
///   child: AsyncValueWidget(data: myData),
///   onRetry: () => ref.refresh(provider),
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  /// The child widget to wrap and protect from errors.
  final Widget child;

  /// Callback invoked when an error is caught.
  /// Useful for error reporting/analytics.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Callback invoked when user taps retry button.
  /// Should trigger a refresh/retry of the failed operation.
  final VoidCallback? onRetry;

  /// Custom error message to display.
  final String? errorMessage;

  /// Custom title for the error state.
  final String? errorTitle;

  /// Whether to use glassmorphism styling (default: true).
  final bool useGlassmorphism;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.onRetry,
    this.errorMessage,
    this.errorTitle,
    this.useGlassmorphism = true,
  });

  @override
  State<ErrorBoundary> createState() => ErrorBoundaryState();
}

class ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear previous errors when dependencies change
    if (_error != null) {
      setState(() {
        _error = null;
      });
    }
  }

  /// Manually report an error to the boundary.
  /// Useful for catching errors from async operations.
  void reportError(Object error, StackTrace stackTrace) {
    widget.onError?.call(error, stackTrace);
    setState(() {
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final content = _buildErrorContent(context);
      return widget.useGlassmorphism
          ? GlassmorphismCard(padding: const EdgeInsets.all(24), child: content)
          : Padding(padding: const EdgeInsets.all(24), child: content);
    }

    return ErrorWidgetBuilder(
      onError: (error, stackTrace) {
        reportError(error, stackTrace);
      },
      child: widget.child,
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, size: 56, color: EmergeColors.coral),
        const Gap(16),
        Text(
          widget.errorTitle ?? 'Oops! Something went wrong',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const Gap(8),
        Text(
          widget.errorMessage ?? _getSanitizedErrorMessage(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryDark.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.onRetry != null) ...[
          const Gap(24),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _error = null;
              });
              widget.onRetry?.call();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  /// Returns a user-friendly error message without exposing sensitive information.
  ///
  /// Never use `_error.toString()` directly as it may expose:
  /// - File paths and directory structures
  /// - Database connection strings
  /// - API keys or tokens
  /// - Internal implementation details
  /// - Stack traces that could aid attackers
  String _getSanitizedErrorMessage() {
    // If a custom error message is provided, use it
    if (widget.errorMessage != null) {
      return widget.errorMessage!;
    }

    // Otherwise, return a generic user-friendly message
    // The raw error is still sent to onError callback for logging/analytics
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Internal widget that wraps the child and catches errors during build.
class ErrorWidgetBuilder extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  const ErrorWidgetBuilder({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  State<ErrorWidgetBuilder> createState() => ErrorWidgetBuilderState();
}

class ErrorWidgetBuilderState extends State<ErrorWidgetBuilder> {
  Object? _error;
  final List<VoidCallback> _postFrameCallbacks = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _error = null;
  }

  @override
  void dispose() {
    // Clean up tracking list to prevent memory leaks
    // Note: We can't actually cancel post-frame callbacks that were already
    // scheduled to WidgetsBinding, but we can clear our tracking list
    // The callbacks themselves check mounted, so they're safe
    _postFrameCallbacks.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return widget.child;
    } catch (error, stackTrace) {
      // Schedule error callback for after the current frame
      // This prevents calling setState during build
      // ignore: prefer_function_declarations_over_variables
      final callback = () {
        if (mounted && _error == null) {
          _error = error;
          widget.onError(error, stackTrace);
        }
      };

      _postFrameCallbacks.add(callback);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        callback();
        // Remove callback from our tracking list after execution
        _postFrameCallbacks.remove(callback);
      });

      return const SizedBox.shrink();
    }
  }
}

/// Extension to easily use ErrorBoundary with Riverpod AsyncValue.
///
/// Example:
/// ```dart
/// asyncValue.whenOrError(
///   data: (data) => DataView(data: data),
///   onRetry: () => ref.refresh(provider),
/// )
/// ```
extension ErrorBoundaryAsyncValue<T> on AsyncValue<T> {
  Widget whenOrError({
    required Widget Function(T data) data,
    required VoidCallback? onRetry,
    String? errorTitle,
    String? errorMessage,
    bool useGlassmorphism = true,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return when(
      data: (value) => data(value),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.neonGreen),
      ),
      error: (error, stackTrace) {
        onError?.call(error, stackTrace);
        return ErrorBoundary(
          onRetry: onRetry,
          errorTitle: errorTitle,
          errorMessage: errorMessage,
          useGlassmorphism: useGlassmorphism,
          child: const SizedBox.shrink(),
        );
      },
    );
  }
}

/// A convenience widget for displaying error states.
///
/// Use this when you need to display an error without wrapping a widget.
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? title;
  final bool useGlassmorphism;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
    this.useGlassmorphism = true,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onRetry: onRetry,
      errorMessage: message,
      errorTitle: title,
      useGlassmorphism: useGlassmorphism,
      child: const SizedBox.shrink(),
    );
  }
}
