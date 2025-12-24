import 'package:equatable/equatable.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unknown error occurred']);
}

/// Comprehensive error handling service for the Emerge app
class ErrorHandler {
  /// Handle errors that occur in UI operations and show appropriate messages to the user
  static void handleUIError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackBar = true,
  }) {
    // Log the error with full details
    AppLogger.e('UI Error', error, StackTrace.current);

    // Determine the error message to show
    String message = customMessage ?? _getErrorMessage(error);

    if (showSnackBar) {
      // Show error message to the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            action: onRetry != null
                ? SnackBarAction(
                    label: 'Retry',
                    onPressed: onRetry,
                  )
                : null,
          ),
        );
      }
    } else {
      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Something went wrong'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onRetry();
                  },
                  child: const Text('Retry'),
                ),
            ],
          ),
        );
      }
    }
  }

  /// Handle errors that occur in repository/data layer operations
  static Either<Exception, T> handleRepositoryError<T>(
    T Function() operation,
  ) {
    try {
      final result = operation();
      return Right(result);
    } catch (e, stack) {
      AppLogger.e('Repository Error', e, stack);
      return Left(Exception(e.toString()));
    }
  }

  /// Handle errors that occur in async operations
  static Future<Either<Exception, T>> handleAsyncError<T>(
    Future<T> Function() operation,
  ) async {
    try {
      final result = await operation();
      return Right(result);
    } catch (e, stack) {
      AppLogger.e('Async Operation Error', e, stack);
      return Left(Exception(e.toString()));
    }
  }

  /// Create a user-friendly error widget for displaying errors in the UI
  static Widget buildErrorWidget({
    required String message,
    VoidCallback? onRetry,
    bool showRetryButton = true,
  }) {
    return AppErrorWidget(
      message: message,
      onRetry: showRetryButton ? onRetry : null,
    );
  }

  /// Get a user-friendly error message based on the error type
  static String _getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    } else if (error is Exception) {
      return error.toString();
    } else if (error is Map<String, dynamic>) {
      // Handle Firestore errors
      return error['message'] ?? 'An error occurred';
    } else if (error is Exception) {
      return error.toString();
    } else {
      return error?.toString() ?? 'An unknown error occurred';
    }
  }

  /// Handle navigation errors
  static void handleNavigationError(
    BuildContext context,
    String errorMessage,
  ) {
    AppLogger.e('Navigation Error', errorMessage, StackTrace.current);

    if (context.mounted) {
      context.go('/'); // Navigate to home in case of navigation errors
    }
  }

  /// Handle authentication errors specifically
  static void handleAuthError(
    BuildContext context,
    dynamic error, {
    required VoidCallback onSignOut,
    String? customMessage,
  }) {
    AppLogger.e('Authentication Error', error, StackTrace.current);

    final message = customMessage ?? 'Authentication error occurred';

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Authentication Issue'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onSignOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );
    }
  }
}
