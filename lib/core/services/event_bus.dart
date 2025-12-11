import 'dart:async';

class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;

  final _controller = StreamController<dynamic>.broadcast();

  EventBus._internal();

  void fire(dynamic event) {
    _controller.add(event);
  }

  Stream<T> on<T>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  void destroy() {
    _controller.close();
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
