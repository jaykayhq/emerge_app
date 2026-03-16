// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paywall_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaywallState {

 bool get isLoading; Offerings? get offerings; String? get error; bool get isSuccess;
/// Create a copy of PaywallState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaywallStateCopyWith<PaywallState> get copyWith => _$PaywallStateCopyWithImpl<PaywallState>(this as PaywallState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaywallState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.offerings, offerings) || other.offerings == offerings)&&(identical(other.error, error) || other.error == error)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,offerings,error,isSuccess);

@override
String toString() {
  return 'PaywallState(isLoading: $isLoading, offerings: $offerings, error: $error, isSuccess: $isSuccess)';
}


}

/// @nodoc
abstract mixin class $PaywallStateCopyWith<$Res>  {
  factory $PaywallStateCopyWith(PaywallState value, $Res Function(PaywallState) _then) = _$PaywallStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, Offerings? offerings, String? error, bool isSuccess
});




}
/// @nodoc
class _$PaywallStateCopyWithImpl<$Res>
    implements $PaywallStateCopyWith<$Res> {
  _$PaywallStateCopyWithImpl(this._self, this._then);

  final PaywallState _self;
  final $Res Function(PaywallState) _then;

/// Create a copy of PaywallState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? offerings = freezed,Object? error = freezed,Object? isSuccess = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,offerings: freezed == offerings ? _self.offerings : offerings // ignore: cast_nullable_to_non_nullable
as Offerings?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PaywallState].
extension PaywallStatePatterns on PaywallState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaywallState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaywallState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaywallState value)  $default,){
final _that = this;
switch (_that) {
case _PaywallState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaywallState value)?  $default,){
final _that = this;
switch (_that) {
case _PaywallState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  Offerings? offerings,  String? error,  bool isSuccess)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaywallState() when $default != null:
return $default(_that.isLoading,_that.offerings,_that.error,_that.isSuccess);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  Offerings? offerings,  String? error,  bool isSuccess)  $default,) {final _that = this;
switch (_that) {
case _PaywallState():
return $default(_that.isLoading,_that.offerings,_that.error,_that.isSuccess);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  Offerings? offerings,  String? error,  bool isSuccess)?  $default,) {final _that = this;
switch (_that) {
case _PaywallState() when $default != null:
return $default(_that.isLoading,_that.offerings,_that.error,_that.isSuccess);case _:
  return null;

}
}

}

/// @nodoc


class _PaywallState implements PaywallState {
  const _PaywallState({this.isLoading = false, this.offerings, this.error, this.isSuccess = false});
  

@override@JsonKey() final  bool isLoading;
@override final  Offerings? offerings;
@override final  String? error;
@override@JsonKey() final  bool isSuccess;

/// Create a copy of PaywallState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaywallStateCopyWith<_PaywallState> get copyWith => __$PaywallStateCopyWithImpl<_PaywallState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaywallState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.offerings, offerings) || other.offerings == offerings)&&(identical(other.error, error) || other.error == error)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,offerings,error,isSuccess);

@override
String toString() {
  return 'PaywallState(isLoading: $isLoading, offerings: $offerings, error: $error, isSuccess: $isSuccess)';
}


}

/// @nodoc
abstract mixin class _$PaywallStateCopyWith<$Res> implements $PaywallStateCopyWith<$Res> {
  factory _$PaywallStateCopyWith(_PaywallState value, $Res Function(_PaywallState) _then) = __$PaywallStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, Offerings? offerings, String? error, bool isSuccess
});




}
/// @nodoc
class __$PaywallStateCopyWithImpl<$Res>
    implements _$PaywallStateCopyWith<$Res> {
  __$PaywallStateCopyWithImpl(this._self, this._then);

  final _PaywallState _self;
  final $Res Function(_PaywallState) _then;

/// Create a copy of PaywallState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? offerings = freezed,Object? error = freezed,Object? isSuccess = null,}) {
  return _then(_PaywallState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,offerings: freezed == offerings ? _self.offerings : offerings // ignore: cast_nullable_to_non_nullable
as Offerings?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
