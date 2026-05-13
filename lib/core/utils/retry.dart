import 'dart:async';
import 'package:flutter/foundation.dart';

/// Retry an async operation with exponential backoff.
/// Returns the result on success, throws the last error after max retries.
Future<T> retry<T>(
  Future<T> Function() fn, {
  int maxRetries = 3,
  Duration baseDelay = const Duration(seconds: 1),
  bool Function(Object)? retryIf,
}) async {
  int attempt = 0;
  while (true) {
    try {
      return await fn();
    } catch (e) {
      attempt++;
      if (attempt >= maxRetries) rethrow;
      if (retryIf != null && !retryIf(e)) rethrow;
      final delay = baseDelay * (1 << (attempt - 1));
      debugPrint('Retry: attempt $attempt/$maxRetries failed, retrying in ${delay.inMilliseconds}ms...');
      await Future.delayed(delay);
    }
  }
}
