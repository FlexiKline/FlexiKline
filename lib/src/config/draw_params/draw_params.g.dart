// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draw_params.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DrawParamsCWProxy {
  DrawParams arrowsRadians(double arrowsRadians);

  DrawParams arrowsLen(double arrowsLen);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DrawParams(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DrawParams(...).copyWith(id: 12, name: "My name")
  /// ````
  DrawParams call({
    double? arrowsRadians,
    double? arrowsLen,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDrawParams.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDrawParams.copyWith.fieldName(...)`
class _$DrawParamsCWProxyImpl implements _$DrawParamsCWProxy {
  const _$DrawParamsCWProxyImpl(this._value);

  final DrawParams _value;

  @override
  DrawParams arrowsRadians(double arrowsRadians) =>
      this(arrowsRadians: arrowsRadians);

  @override
  DrawParams arrowsLen(double arrowsLen) => this(arrowsLen: arrowsLen);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DrawParams(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DrawParams(...).copyWith(id: 12, name: "My name")
  /// ````
  DrawParams call({
    Object? arrowsRadians = const $CopyWithPlaceholder(),
    Object? arrowsLen = const $CopyWithPlaceholder(),
  }) {
    return DrawParams(
      arrowsRadians:
          arrowsRadians == const $CopyWithPlaceholder() || arrowsRadians == null
              ? _value.arrowsRadians
              // ignore: cast_nullable_to_non_nullable
              : arrowsRadians as double,
      arrowsLen: arrowsLen == const $CopyWithPlaceholder() || arrowsLen == null
          ? _value.arrowsLen
          // ignore: cast_nullable_to_non_nullable
          : arrowsLen as double,
    );
  }
}

extension $DrawParamsCopyWith on DrawParams {
  /// Returns a callable class that can be used as follows: `instanceOfDrawParams.copyWith(...)` or like so:`instanceOfDrawParams.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DrawParamsCWProxy get copyWith => _$DrawParamsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrawParams _$DrawParamsFromJson(Map<String, dynamic> json) => DrawParams(
      arrowsRadians: (json['arrowsRadians'] as num?)?.toDouble() ?? pi30,
      arrowsLen: (json['arrowsLen'] as num?)?.toDouble() ?? 16.0,
    );

Map<String, dynamic> _$DrawParamsToJson(DrawParams instance) =>
    <String, dynamic>{
      'arrowsRadians': instance.arrowsRadians,
      'arrowsLen': instance.arrowsLen,
    };
