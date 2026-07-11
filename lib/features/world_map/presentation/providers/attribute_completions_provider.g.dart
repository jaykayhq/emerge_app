// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attribute_completions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(attributeCompletions)
final attributeCompletionsProvider = AttributeCompletionsFamily._();

final class AttributeCompletionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<int>>,
          List<int>,
          FutureOr<List<int>>
        >
    with $FutureModifier<List<int>>, $FutureProvider<List<int>> {
  AttributeCompletionsProvider._({
    required AttributeCompletionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'attributeCompletionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attributeCompletionsHash();

  @override
  String toString() {
    return r'attributeCompletionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<int>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<int>> create(Ref ref) {
    final argument = this.argument as String;
    return attributeCompletions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AttributeCompletionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attributeCompletionsHash() =>
    r'8dc2e4bd8cbc0c6473d2ffefcee57becc42d4dfd';

final class AttributeCompletionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<int>>, String> {
  AttributeCompletionsFamily._()
    : super(
        retry: null,
        name: r'attributeCompletionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AttributeCompletionsProvider call(String attributeName) =>
      AttributeCompletionsProvider._(argument: attributeName, from: this);

  @override
  String toString() => r'attributeCompletionsProvider';
}
