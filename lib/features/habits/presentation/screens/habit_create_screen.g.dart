// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_create_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HabitCreateState)
final habitCreateStateProvider = HabitCreateStateProvider._();

final class HabitCreateStateProvider
    extends $NotifierProvider<HabitCreateState, HabitFormData> {
  HabitCreateStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitCreateStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitCreateStateHash();

  @$internal
  @override
  HabitCreateState create() => HabitCreateState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitFormData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitFormData>(value),
    );
  }
}

String _$habitCreateStateHash() => r'4b69b62812fea3489afcd3144ecb2da3a0f27767';

abstract class _$HabitCreateState extends $Notifier<HabitFormData> {
  HabitFormData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HabitFormData, HabitFormData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HabitFormData, HabitFormData>,
              HabitFormData,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
