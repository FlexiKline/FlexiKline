// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draw_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DrawConfigCWProxy {
  DrawConfig enable(bool enable);

  DrawConfig crosshair(LineConfig crosshair);

  DrawConfig point(PointConfig point);

  DrawConfig border(PointConfig? border);

  DrawConfig tickText(TextAreaConfig tickText);

  DrawConfig spacing(double spacing);

  DrawConfig gapBackground(Color gapBackground);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DrawConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DrawConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  DrawConfig call({
    bool? enable,
    LineConfig? crosshair,
    PointConfig? point,
    PointConfig? border,
    TextAreaConfig? tickText,
    double? spacing,
    Color? gapBackground,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDrawConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDrawConfig.copyWith.fieldName(...)`
class _$DrawConfigCWProxyImpl implements _$DrawConfigCWProxy {
  const _$DrawConfigCWProxyImpl(this._value);

  final DrawConfig _value;

  @override
  DrawConfig enable(bool enable) => this(enable: enable);

  @override
  DrawConfig crosshair(LineConfig crosshair) => this(crosshair: crosshair);

  @override
  DrawConfig point(PointConfig point) => this(point: point);

  @override
  DrawConfig border(PointConfig? border) => this(border: border);

  @override
  DrawConfig tickText(TextAreaConfig tickText) => this(tickText: tickText);

  @override
  DrawConfig spacing(double spacing) => this(spacing: spacing);

  @override
  DrawConfig gapBackground(Color gapBackground) =>
      this(gapBackground: gapBackground);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DrawConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DrawConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  DrawConfig call({
    Object? enable = const $CopyWithPlaceholder(),
    Object? crosshair = const $CopyWithPlaceholder(),
    Object? point = const $CopyWithPlaceholder(),
    Object? border = const $CopyWithPlaceholder(),
    Object? tickText = const $CopyWithPlaceholder(),
    Object? spacing = const $CopyWithPlaceholder(),
    Object? gapBackground = const $CopyWithPlaceholder(),
  }) {
    return DrawConfig(
      enable: enable == const $CopyWithPlaceholder() || enable == null
          ? _value.enable
          // ignore: cast_nullable_to_non_nullable
          : enable as bool,
      crosshair: crosshair == const $CopyWithPlaceholder() || crosshair == null
          ? _value.crosshair
          // ignore: cast_nullable_to_non_nullable
          : crosshair as LineConfig,
      point: point == const $CopyWithPlaceholder() || point == null
          ? _value.point
          // ignore: cast_nullable_to_non_nullable
          : point as PointConfig,
      border: border == const $CopyWithPlaceholder()
          ? _value.border
          // ignore: cast_nullable_to_non_nullable
          : border as PointConfig?,
      tickText: tickText == const $CopyWithPlaceholder() || tickText == null
          ? _value.tickText
          // ignore: cast_nullable_to_non_nullable
          : tickText as TextAreaConfig,
      spacing: spacing == const $CopyWithPlaceholder() || spacing == null
          ? _value.spacing
          // ignore: cast_nullable_to_non_nullable
          : spacing as double,
      gapBackground:
          gapBackground == const $CopyWithPlaceholder() || gapBackground == null
              ? _value.gapBackground
              // ignore: cast_nullable_to_non_nullable
              : gapBackground as Color,
    );
  }
}

extension $DrawConfigCopyWith on DrawConfig {
  /// Returns a callable class that can be used as follows: `instanceOfDrawConfig.copyWith(...)` or like so:`instanceOfDrawConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DrawConfigCWProxy get copyWith => _$DrawConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrawConfig _$DrawConfigFromJson(Map<String, dynamic> json) => DrawConfig(
      enable: json['enable'] as bool? ?? true,
      crosshair: LineConfig.fromJson(json['crosshair'] as Map<String, dynamic>),
      point: PointConfig.fromJson(json['point'] as Map<String, dynamic>),
      border: json['border'] == null
          ? null
          : PointConfig.fromJson(json['border'] as Map<String, dynamic>),
      tickText:
          TextAreaConfig.fromJson(json['tickText'] as Map<String, dynamic>),
      spacing: (json['spacing'] as num).toDouble(),
      gapBackground: json['gapBackground'] == null
          ? Colors.transparent
          : const ColorConverter().fromJson(json['gapBackground'] as String),
    );

Map<String, dynamic> _$DrawConfigToJson(DrawConfig instance) {
  final val = <String, dynamic>{
    'enable': instance.enable,
    'crosshair': instance.crosshair.toJson(),
    'point': instance.point.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('border', instance.border?.toJson());
  val['tickText'] = instance.tickText.toJson();
  val['spacing'] = instance.spacing;
  val['gapBackground'] = const ColorConverter().toJson(instance.gapBackground);
  return val;
}
