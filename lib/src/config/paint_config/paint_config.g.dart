// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paint_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaintConfigCWProxy {
  PaintConfig color(Color color);

  PaintConfig strokeWidth(double strokeWidth);

  PaintConfig style(PaintingStyle style);

  PaintConfig blendMode(BlendMode blendMode);

  PaintConfig isAntiAlias(bool isAntiAlias);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PaintConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PaintConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  PaintConfig call({
    Color color,
    double strokeWidth,
    PaintingStyle style,
    BlendMode blendMode,
    bool isAntiAlias,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPaintConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPaintConfig.copyWith.fieldName(...)`
class _$PaintConfigCWProxyImpl implements _$PaintConfigCWProxy {
  const _$PaintConfigCWProxyImpl(this._value);

  final PaintConfig _value;

  @override
  PaintConfig color(Color color) => this(color: color);

  @override
  PaintConfig strokeWidth(double strokeWidth) => this(strokeWidth: strokeWidth);

  @override
  PaintConfig style(PaintingStyle style) => this(style: style);

  @override
  PaintConfig blendMode(BlendMode blendMode) => this(blendMode: blendMode);

  @override
  PaintConfig isAntiAlias(bool isAntiAlias) => this(isAntiAlias: isAntiAlias);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PaintConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PaintConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  PaintConfig call({
    Object? color = const $CopyWithPlaceholder(),
    Object? strokeWidth = const $CopyWithPlaceholder(),
    Object? style = const $CopyWithPlaceholder(),
    Object? blendMode = const $CopyWithPlaceholder(),
    Object? isAntiAlias = const $CopyWithPlaceholder(),
  }) {
    return PaintConfig(
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as Color,
      strokeWidth: strokeWidth == const $CopyWithPlaceholder()
          ? _value.strokeWidth
          // ignore: cast_nullable_to_non_nullable
          : strokeWidth as double,
      style: style == const $CopyWithPlaceholder()
          ? _value.style
          // ignore: cast_nullable_to_non_nullable
          : style as PaintingStyle,
      blendMode: blendMode == const $CopyWithPlaceholder()
          ? _value.blendMode
          // ignore: cast_nullable_to_non_nullable
          : blendMode as BlendMode,
      isAntiAlias: isAntiAlias == const $CopyWithPlaceholder()
          ? _value.isAntiAlias
          // ignore: cast_nullable_to_non_nullable
          : isAntiAlias as bool,
    );
  }
}

extension $PaintConfigCopyWith on PaintConfig {
  /// Returns a callable class that can be used as follows: `instanceOfPaintConfig.copyWith(...)` or like so:`instanceOfPaintConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaintConfigCWProxy get copyWith => _$PaintConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaintConfig _$PaintConfigFromJson(Map<String, dynamic> json) => PaintConfig(
      color: json['color'] == null
          ? const Color(0x00000000)
          : const ColorConverter().fromJson(json['color'] as String),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0,
      style: json['style'] == null
          ? PaintingStyle.stroke
          : const PaintingStyleConverter().fromJson(json['style'] as String),
      blendMode: json['blendMode'] == null
          ? BlendMode.srcOver
          : const BlendModeConverter().fromJson(json['blendMode'] as String),
      isAntiAlias: json['isAntiAlias'] as bool? ?? true,
    );

Map<String, dynamic> _$PaintConfigToJson(PaintConfig instance) =>
    <String, dynamic>{
      'color': const ColorConverter().toJson(instance.color),
      'strokeWidth': instance.strokeWidth,
      'style': const PaintingStyleConverter().toJson(instance.style),
      'blendMode': const BlendModeConverter().toJson(instance.blendMode),
      'isAntiAlias': instance.isAntiAlias,
    };
