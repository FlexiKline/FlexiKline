// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loading_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LoadingConfigCWProxy {
  LoadingConfig size(double size);

  LoadingConfig strokeWidth(double strokeWidth);

  LoadingConfig background(Color background);

  LoadingConfig valueColor(Color valueColor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LoadingConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LoadingConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  LoadingConfig call({
    double? size,
    double? strokeWidth,
    Color? background,
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
  LoadingConfig background(Color background) => this(background: background);

  @override
  LoadingConfig valueColor(Color valueColor) => this(valueColor: valueColor);

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
    Object? background = const $CopyWithPlaceholder(),
    Object? valueColor = const $CopyWithPlaceholder(),
  }) {
    return LoadingConfig(
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as double,
      strokeWidth:
          strokeWidth == const $CopyWithPlaceholder() || strokeWidth == null
              ? _value.strokeWidth
              // ignore: cast_nullable_to_non_nullable
              : strokeWidth as double,
      background:
          background == const $CopyWithPlaceholder() || background == null
              ? _value.background
              // ignore: cast_nullable_to_non_nullable
              : background as Color,
      valueColor:
          valueColor == const $CopyWithPlaceholder() || valueColor == null
              ? _value.valueColor
              // ignore: cast_nullable_to_non_nullable
              : valueColor as Color,
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
      background: json['background'] == null
          ? const Color(0xFFECECEC)
          : const ColorConverter().fromJson(json['background'] as String),
      valueColor: json['valueColor'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['valueColor'] as String),
    );

Map<String, dynamic> _$LoadingConfigToJson(LoadingConfig instance) =>
    <String, dynamic>{
      'size': instance.size,
      'strokeWidth': instance.strokeWidth,
      'background': const ColorConverter().toJson(instance.background),
      'valueColor': const ColorConverter().toJson(instance.valueColor),
    };
