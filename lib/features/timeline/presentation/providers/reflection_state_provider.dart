import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reflection_state_provider.g.dart';

@riverpod
class TodayReflectionState extends _$TodayReflectionState {
  @override
  bool build() {
    return false; // Has user logged reflection today?
  }

  void setLogged(bool logged) {
    state = logged;
  }

  void resetForNewDay() {
    state = false;
  }
}
