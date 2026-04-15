// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loading_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LoadingConfigCWProxy {
  LoadingConfig size(double size);

  LoadingConfig strokeWidth(double strokeWidth);

  LoadingConfig backgroundColor(Color? backgroundColor);

  LoadingConfig valueColor(Color? valueColor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LoadingConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LoadingConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  LoadingConfig call({
    double size,
    double strokeWidth,
    Color? backgroundColor,
    Color? valueColor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLoadingConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLoadingConfig.copyWith.fieldName(...)`
class _$LoadingConfigCWProxyImpl implements _$LoadingConfigCWProxy {
  const _$LoadingConfigCWProxyImpl(this._value);

  final LoadingConfig _value;

  @override
  LoadingConfig size(double size) => this(size: size);

  @override
  LoadingConfig strokeWidth(double strokeWidth) =>
      this(strokeWidth: strokeWidth);

  @override
  LoadingConfig backgroundColor(Color? backgroundColor) =>
      this(backgroundColor: backgroundColor);

  @override
  LoadingConfig valueColor(Color? valueColor) => this(valueColor: valueColor);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LoadingConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LoadingConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  LoadingConfig call({
    Object? size = const $CopyWithPlaceholder(),
    Object? strokeWidth = const $CopyWithPlaceholder(),
    Object? backgroundColor = const $CopyWithPlaceholder(),
    Object? valueColor = const $CopyWithPlaceholder(),
  }) {
    return LoadingConfig(
      size: size == const $CopyWithPlaceholder()
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as double,
      strokeWidth: strokeWidth == const $CopyWithPlaceholder()
          ? _value.strokeWidth
          // ignore: cast_nullable_to_non_nullable
          : strokeWidth as double,
      backgroundColor: backgroundColor == const $CopyWithPlaceholder()
          ? _value.backgroundColor
          // ignore: cast_nullable_to_non_nullable
          : backgroundColor as Color?,
      valueColor: valueColor == const $CopyWithPlaceholder()
          ? _value.valueColor
          // ignore: cast_nullable_to_non_nullable
          : valueColor as Color?,
    );
  }
}

extension $LoadingConfigCopyWith on LoadingConfig {
  /// Returns a callable class that can be used as follows: `instanceOfLoadingConfig.copyWith(...)` or like so:`instanceOfLoadingConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LoadingConfigCWProxy get copyWith => _$LoadingConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoadingConfig _$LoadingConfigFromJson(Map<String, dynamic> json) =>
    LoadingConfig(
      size: (json['size'] as num?)?.toDouble() ?? 24,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 4,
      backgroundColor: _$JsonConverterFromJson<String, Color>(
          json['backgroundColor'], const ColorConverter().fromJson),
      valueColor: _$JsonConverterFromJson<String, Color>(
          json['valueColor'], const ColorConverter().fromJson),
    );

Map<String, dynamic> _$LoadingConfigToJson(LoadingConfig instance) =>
    <String, dynamic>{
      'size': instance.size,
      'strokeWidth': instance.strokeWidth,
      if (_$JsonConverterToJson<String, Color>(
              instance.backgroundColor, const ColorConverter().toJson)
          case final value?)
        'backgroundColor': value,
      if (_$JsonConverterToJson<String, Color>(
              instance.valueColor, const ColorConverter().toJson)
          case final value?)
        'valueColor': value,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
