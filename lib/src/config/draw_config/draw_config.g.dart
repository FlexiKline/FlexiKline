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

  DrawConfig magnifier(MagnifierConfig magnifier);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DrawConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DrawConfig(...).copyWith(id: 12, name: "My name")
  /// ````
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
    MagnifierConfig magnifier,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDrawConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDrawConfig.copyWith.fieldName(...)`
class _$DrawConfigCWProxyImpl implements _$DrawConfigCWProxy {
  const _$DrawConfigCWProxyImpl(this._value);

  final DrawConfig _value;

  @override
  DrawConfig enable(bool enable) => this(enable: enable);

  @override
  DrawConfig allowSelectWhenExit(bool allowSelectWhenExit) =>
      this(allowSelectWhenExit: allowSelectWhenExit);

  @override
  DrawConfig crosspoint(PointConfig crosspoint) => this(crosspoint: crosspoint);

  @override
  DrawConfig crosshair(LineConfig crosshair) => this(crosshair: crosshair);

  @override
  DrawConfig drawLine(LineConfig drawLine) => this(drawLine: drawLine);

  @override
  DrawConfig drawPoint(PointConfig drawPoint) => this(drawPoint: drawPoint);

  @override
  DrawConfig ticksText(TextAreaConfig ticksText) => this(ticksText: ticksText);

  @override
  DrawConfig spacing(double spacing) => this(spacing: spacing);

  @override
  DrawConfig ticksGapBgOpacity(double ticksGapBgOpacity) =>
      this(ticksGapBgOpacity: ticksGapBgOpacity);

  @override
  DrawConfig hitTestMinDistance(double hitTestMinDistance) =>
      this(hitTestMinDistance: hitTestMinDistance);

  @override
  DrawConfig magnetMinDistance(double magnetMinDistance) =>
      this(magnetMinDistance: magnetMinDistance);

  @override
  DrawConfig magnifier(MagnifierConfig magnifier) => this(magnifier: magnifier);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DrawConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DrawConfig(...).copyWith(id: 12, name: "My name")
  /// ````
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
    Object? magnifier = const $CopyWithPlaceholder(),
  }) {
    return DrawConfig(
      enable: enable == const $CopyWithPlaceholder()
          ? _value.enable
          // ignore: cast_nullable_to_non_nullable
          : enable as bool,
      allowSelectWhenExit: allowSelectWhenExit == const $CopyWithPlaceholder()
          ? _value.allowSelectWhenExit
          // ignore: cast_nullable_to_non_nullable
          : allowSelectWhenExit as bool,
      crosspoint: crosspoint == const $CopyWithPlaceholder()
          ? _value.crosspoint
          // ignore: cast_nullable_to_non_nullable
          : crosspoint as PointConfig,
      crosshair: crosshair == const $CopyWithPlaceholder()
          ? _value.crosshair
          // ignore: cast_nullable_to_non_nullable
          : crosshair as LineConfig,
      drawLine: drawLine == const $CopyWithPlaceholder()
          ? _value.drawLine
          // ignore: cast_nullable_to_non_nullable
          : drawLine as LineConfig,
      drawPoint: drawPoint == const $CopyWithPlaceholder()
          ? _value.drawPoint
          // ignore: cast_nullable_to_non_nullable
          : drawPoint as PointConfig,
      ticksText: ticksText == const $CopyWithPlaceholder()
          ? _value.ticksText
          // ignore: cast_nullable_to_non_nullable
          : ticksText as TextAreaConfig,
      spacing: spacing == const $CopyWithPlaceholder()
          ? _value.spacing
          // ignore: cast_nullable_to_non_nullable
          : spacing as double,
      ticksGapBgOpacity: ticksGapBgOpacity == const $CopyWithPlaceholder()
          ? _value.ticksGapBgOpacity
          // ignore: cast_nullable_to_non_nullable
          : ticksGapBgOpacity as double,
      hitTestMinDistance: hitTestMinDistance == const $CopyWithPlaceholder()
          ? _value.hitTestMinDistance
          // ignore: cast_nullable_to_non_nullable
          : hitTestMinDistance as double,
      magnetMinDistance: magnetMinDistance == const $CopyWithPlaceholder()
          ? _value.magnetMinDistance
          // ignore: cast_nullable_to_non_nullable
          : magnetMinDistance as double,
      magnifier: magnifier == const $CopyWithPlaceholder()
          ? _value.magnifier
          // ignore: cast_nullable_to_non_nullable
          : magnifier as MagnifierConfig,
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
      allowSelectWhenExit: json['allowSelectWhenExit'] as bool? ?? true,
      crosspoint:
          PointConfig.fromJson(json['crosspoint'] as Map<String, dynamic>),
      crosshair: LineConfig.fromJson(json['crosshair'] as Map<String, dynamic>),
      drawLine: LineConfig.fromJson(json['drawLine'] as Map<String, dynamic>),
      drawPoint:
          PointConfig.fromJson(json['drawPoint'] as Map<String, dynamic>),
      ticksText:
          TextAreaConfig.fromJson(json['ticksText'] as Map<String, dynamic>),
      spacing: (json['spacing'] as num).toDouble(),
      ticksGapBgOpacity: (json['ticksGapBgOpacity'] as num?)?.toDouble() ?? 0.1,
      hitTestMinDistance:
          (json['hitTestMinDistance'] as num?)?.toDouble() ?? 10,
      magnetMinDistance: (json['magnetMinDistance'] as num?)?.toDouble() ?? 10,
      magnifier: json['magnifier'] == null
          ? const MagnifierConfig()
          : MagnifierConfig.fromJson(json['magnifier'] as Map<String, dynamic>),
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
      'magnifier': instance.magnifier.toJson(),
    };
