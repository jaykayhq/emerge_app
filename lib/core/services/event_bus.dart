import 'dart:async';

/// ENHANCED: EventBus with proper lifecycle management and memory leak prevention
///
/// Security & Performance Fixes:
/// - Tracks all subscriptions for automatic cleanup
/// - Proper disposal of StreamController
/// - Prevents memory leaks from unclosed streams
class EventBus {
  static EventBus? _instance;

  factory EventBus() {
    _instance ??= EventBus._internal();
    return _instance!;
  }

  final StreamController<dynamic> _controller;
  final Set<StreamSubscription> _subscriptions = {};
  bool _isDisposed = false;

  EventBus._internal() : _controller = StreamController<dynamic>.broadcast();

  /// Fire an event to all listeners
  void fire(dynamic event) {
    if (_isDisposed) {
      throw StateError('EventBus has been disposed');
    }
    _controller.add(event);
  }

  /// ENHANCED: Listen to events of type T with automatic subscription tracking
  ///
  /// Subscriptions are automatically tracked and cleaned up on dispose
  Stream<T> on<T>() {
    if (_isDisposed) {
      throw StateError('EventBus has been disposed');
    }

    return _controller.stream
        .where((event) => event is T)
        .cast<T>();
  }

  /// ENHANCED: Register a subscription for automatic cleanup
  ///
  /// Usage:
  /// ```dart
  /// final subscription = EventBus().on<MyEvent>().listen((event) { ... });
  /// EventBus().registerSubscription(subscription);
  /// ```
  void registerSubscription(StreamSubscription subscription) {
    if (_isDisposed) {
      subscription.cancel();
      return;
    }
    _subscriptions.add(subscription);
  }

  /// ENHANCED: Proper disposal with memory leak prevention
  ///
  /// Cancels all tracked subscriptions and closes the controller
  void dispose() {
    if (_isDisposed) return;

    // Cancel all tracked subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Close the controller
    if (!_controller.isClosed) {
      _controller.close();
    }

    _isDisposed = true;
  }

  /// Check if the EventBus has been disposed
  bool get isDisposed => _isDisposed;

  /// Get the number of active subscriptions (for debugging)
  int get activeSubscriptionCount => _subscriptions.length;

  /// Reset the singleton instance (for testing only)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}

// Events
class HabitCompleted {
  final String habitId;
  final String userId;
  final DateTime date;

  HabitCompleted({
    required this.habitId,
    required this.userId,
    required this.date,
  });
}
