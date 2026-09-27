// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draw_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DrawConfigCWProxy {
  DrawConfig enable(bool enable);

  DrawConfig allowSelectWhenExit(bool allowSelectWhenExit);

  DrawConfig crosspoint(PointConfig crosspoint);

  DrawConfig crosshair(LineConfig crosshair);

  DrawConfig drawLine(LineConfig drawLine);

  DrawConfig drawPoint(PointConfig drawPoint);

  DrawConfig ticksText(TextAreaConfig ticksText);

  DrawConfig spacing(double spacing);

  DrawConfig ticksGapBgOpacity(double ticksGapBgOpacity);

  DrawConfig hitTestMinDistance(double hitTestMinDistance);

  DrawConfig magnetMinDistance(double magnetMinDistance);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `DrawConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DrawConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  DrawConfig call({
    bool enable,
    bool allowSelectWhenExit,
    PointConfig crosspoint,
    LineConfig crosshair,
    LineConfig drawLine,
    PointConfig drawPoint,
    TextAreaConfig ticksText,
    double spacing,
    double ticksGapBgOpacity,
    double hitTestMinDistance,
    double magnetMinDistance,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDrawConfig.copyWith(...)` or call `instanceOfDrawConfig.copyWith.fieldName(value)` for a single field.
class _$DrawConfigCWProxyImpl implements _$DrawConfigCWProxy {
  const _$DrawConfigCWProxyImpl(this._value);

  final DrawConfig _value;

  @override
  DrawConfig enable(bool enable) => call(enable: enable);

  @override
  DrawConfig allowSelectWhenExit(bool allowSelectWhenExit) =>
      call(allowSelectWhenExit: allowSelectWhenExit);

  @override
  DrawConfig crosspoint(PointConfig crosspoint) => call(crosspoint: crosspoint);

  @override
  DrawConfig crosshair(LineConfig crosshair) => call(crosshair: crosshair);

  @override
  DrawConfig drawLine(LineConfig drawLine) => call(drawLine: drawLine);

  @override
  DrawConfig drawPoint(PointConfig drawPoint) => call(drawPoint: drawPoint);

  @override
  DrawConfig ticksText(TextAreaConfig ticksText) => call(ticksText: ticksText);

  @override
  DrawConfig spacing(double spacing) => call(spacing: spacing);

  @override
  DrawConfig ticksGapBgOpacity(double ticksGapBgOpacity) =>
      call(ticksGapBgOpacity: ticksGapBgOpacity);

  @override
  DrawConfig hitTestMinDistance(double hitTestMinDistance) =>
      call(hitTestMinDistance: hitTestMinDistance);

  @override
  DrawConfig magnetMinDistance(double magnetMinDistance) =>
      call(magnetMinDistance: magnetMinDistance);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `DrawConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DrawConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DrawConfig call({
    Object? enable = const $CopyWithPlaceholder(),
    Object? allowSelectWhenExit = const $CopyWithPlaceholder(),
    Object? crosspoint = const $CopyWithPlaceholder(),
    Object? crosshair = const $CopyWithPlaceholder(),
    Object? drawLine = const $CopyWithPlaceholder(),
    Object? drawPoint = const $CopyWithPlaceholder(),
    Object? ticksText = const $CopyWithPlaceholder(),
    Object? spacing = const $CopyWithPlaceholder(),
    Object? ticksGapBgOpacity = const $CopyWithPlaceholder(),
    Object? hitTestMinDistance = const $CopyWithPlaceholder(),
    Object? magnetMinDistance = const $CopyWithPlaceholder(),
  }) {
    return DrawConfig(
      enable: enable == const $CopyWithPlaceholder() || enable == null
          ? _value.enable
          // ignore: cast_nullable_to_non_nullable
          : enable as bool,
      allowSelectWhenExit:
          allowSelectWhenExit == const $CopyWithPlaceholder() ||
              allowSelectWhenExit == null
          ? _value.allowSelectWhenExit
          // ignore: cast_nullable_to_non_nullable
          : allowSelectWhenExit as bool,
      crosspoint:
          crosspoint == const $CopyWithPlaceholder() || crosspoint == null
          ? _value.crosspoint
          // ignore: cast_nullable_to_non_nullable
          : crosspoint as PointConfig,
      crosshair: crosshair == const $CopyWithPlaceholder() || crosshair == null
          ? _value.crosshair
          // ignore: cast_nullable_to_non_nullable
          : crosshair as LineConfig,
      drawLine: drawLine == const $CopyWithPlaceholder() || drawLine == null
          ? _value.drawLine
          // ignore: cast_nullable_to_non_nullable
          : drawLine as LineConfig,
      drawPoint: drawPoint == const $CopyWithPlaceholder() || drawPoint == null
          ? _value.drawPoint
          // ignore: cast_nullable_to_non_nullable
          : drawPoint as PointConfig,
      ticksText: ticksText == const $CopyWithPlaceholder() || ticksText == null
          ? _value.ticksText
          // ignore: cast_nullable_to_non_nullable
          : ticksText as TextAreaConfig,
      spacing: spacing == const $CopyWithPlaceholder() || spacing == null
          ? _value.spacing
          // ignore: cast_nullable_to_non_nullable
          : spacing as double,
      ticksGapBgOpacity:
          ticksGapBgOpacity == const $CopyWithPlaceholder() ||
              ticksGapBgOpacity == null
          ? _value.ticksGapBgOpacity
          // ignore: cast_nullable_to_non_nullable
          : ticksGapBgOpacity as double,
      hitTestMinDistance:
          hitTestMinDistance == const $CopyWithPlaceholder() ||
              hitTestMinDistance == null
          ? _value.hitTestMinDistance
          // ignore: cast_nullable_to_non_nullable
          : hitTestMinDistance as double,
      magnetMinDistance:
          magnetMinDistance == const $CopyWithPlaceholder() ||
              magnetMinDistance == null
          ? _value.magnetMinDistance
          // ignore: cast_nullable_to_non_nullable
          : magnetMinDistance as double,
    );
  }
}

extension $DrawConfigCopyWith on DrawConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDrawConfig.copyWith(...)` or `instanceOfDrawConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DrawConfigCWProxy get copyWith => _$DrawConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrawConfig _$DrawConfigFromJson(Map<String, dynamic> json) => DrawConfig(
  enable: json['enable'] as bool? ?? false,
  allowSelectWhenExit: json['allowSelectWhenExit'] as bool? ?? true,
  crosspoint: json['crosspoint'] == null
      ? const PointConfig(radius: 2, width: 0)
      : PointConfig.fromJson(json['crosspoint'] as Map<String, dynamic>),
  crosshair: json['crosshair'] == null
      ? const LineConfig(
          paint: PaintConfig(strokeWidth: defaultAuxiliaryLineWidth),
          type: LineType.dashed,
          dashes: [5, 3],
        )
      : LineConfig.fromJson(json['crosshair'] as Map<String, dynamic>),
  drawLine: json['drawLine'] == null
      ? const LineConfig(
          paint: PaintConfig(strokeWidth: 1),
          type: LineType.solid,
          dashes: [5, 3],
        )
      : LineConfig.fromJson(json['drawLine'] as Map<String, dynamic>),
  drawPoint: json['drawPoint'] == null
      ? const PointConfig(radius: 9, color: white, width: 0, borderWidth: 1)
      : PointConfig.fromJson(json['drawPoint'] as Map<String, dynamic>),
  ticksText: json['ticksText'] == null
      ? const TextAreaConfig(
          style: TextStyle(
            color: white,
            fontSize: defaultTextSize,
            fontWeight: FontWeight.normal,
            height: defaultTextHeight,
          ),
          padding: EdgeInsets.all(2),
          border: null,
          borderRadius: BorderRadius.all(Radius.circular(2)),
        )
      : TextAreaConfig.fromJson(json['ticksText'] as Map<String, dynamic>),
  spacing: (json['spacing'] as num?)?.toDouble() ?? 1,
  ticksGapBgOpacity: (json['ticksGapBgOpacity'] as num?)?.toDouble() ?? 0.1,
  hitTestMinDistance: (json['hitTestMinDistance'] as num?)?.toDouble() ?? 10,
  magnetMinDistance: (json['magnetMinDistance'] as num?)?.toDouble() ?? 10,
);

Map<String, dynamic> _$DrawConfigToJson(DrawConfig instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'allowSelectWhenExit': instance.allowSelectWhenExit,
      'crosspoint': instance.crosspoint.toJson(),
      'crosshair': instance.crosshair.toJson(),
      'drawLine': instance.drawLine.toJson(),
      'drawPoint': instance.drawPoint.toJson(),
      'ticksText': instance.ticksText.toJson(),
      'spacing': instance.spacing,
      'ticksGapBgOpacity': instance.ticksGapBgOpacity,
      'hitTestMinDistance': instance.hitTestMinDistance,
      'magnetMinDistance': instance.magnetMinDistance,
    };
