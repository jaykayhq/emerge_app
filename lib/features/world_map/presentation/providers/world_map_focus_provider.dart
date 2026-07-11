import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'world_map_focus_provider.g.dart';

/// Provider for transient focus events on the world map.
/// Set this to an attribute name (e.g. 'strength') to trigger an animation
/// on the WorldMapScreen. The screen will consume the event and then clear it.
@riverpod
class MapFocusEvent extends _$MapFocusEvent {
  @override
  String? build() => null;

  void setFocus(String? focus) {
    state = focus;
  }
}
