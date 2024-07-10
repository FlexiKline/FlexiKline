// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sar.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SARIndicatorCWProxy {
  SARIndicator key(ValueKey<dynamic> key);

  SARIndicator name(String name);

  SARIndicator height(double height);

  SARIndicator padding(EdgeInsets padding);

  SARIndicator zIndex(int zIndex);

  SARIndicator calcParam(SARParam calcParam);

  SARIndicator radius(double? radius);

  SARIndicator paint(PaintConfig paint);

  SARIndicator tipsPadding(EdgeInsets tipsPadding);

  SARIndicator tipsStyle(TextStyle tipsStyle);

  SARIndicator tickCount(int tickCount);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SARIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SARIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  SARIndicator call({
    ValueKey<dynamic>? key,
    String? name,
    double? height,
    EdgeInsets? padding,
    int? zIndex,
    SARParam? calcParam,
    double? radius,
    PaintConfig? paint,
    EdgeInsets? tipsPadding,
    TextStyle? tipsStyle,
    int? tickCount,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSARIndicator.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSARIndicator.copyWith.fieldName(...)`
class _$SARIndicatorCWProxyImpl implements _$SARIndicatorCWProxy {
  const _$SARIndicatorCWProxyImpl(this._value);

  final SARIndicator _value;

  @override
  SARIndicator key(ValueKey<dynamic> key) => this(key: key);

  @override
  SARIndicator name(String name) => this(name: name);

  @override
  SARIndicator height(double height) => this(height: height);

  @override
  SARIndicator padding(EdgeInsets padding) => this(padding: padding);

  @override
  SARIndicator zIndex(int zIndex) => this(zIndex: zIndex);

  @override
  SARIndicator calcParam(SARParam calcParam) => this(calcParam: calcParam);

  @override
  SARIndicator radius(double? radius) => this(radius: radius);

  @override
  SARIndicator paint(PaintConfig paint) => this(paint: paint);

  @override
  SARIndicator tipsPadding(EdgeInsets tipsPadding) =>
      this(tipsPadding: tipsPadding);

  @override
  SARIndicator tipsStyle(TextStyle tipsStyle) => this(tipsStyle: tipsStyle);

  @override
  SARIndicator tickCount(int tickCount) => this(tickCount: tickCount);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SARIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SARIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  SARIndicator call({
    Object? key = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? zIndex = const $CopyWithPlaceholder(),
    Object? calcParam = const $CopyWithPlaceholder(),
    Object? radius = const $CopyWithPlaceholder(),
    Object? paint = const $CopyWithPlaceholder(),
    Object? tipsPadding = const $CopyWithPlaceholder(),
    Object? tipsStyle = const $CopyWithPlaceholder(),
    Object? tickCount = const $CopyWithPlaceholder(),
  }) {
    return SARIndicator(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as ValueKey<dynamic>,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      height: height == const $CopyWithPlaceholder() || height == null
          ? _value.height
          // ignore: cast_nullable_to_non_nullable
          : height as double,
      padding: padding == const $CopyWithPlaceholder() || padding == null
          ? _value.padding
          // ignore: cast_nullable_to_non_nullable
          : padding as EdgeInsets,
      zIndex: zIndex == const $CopyWithPlaceholder() || zIndex == null
          ? _value.zIndex
          // ignore: cast_nullable_to_non_nullable
          : zIndex as int,
      calcParam: calcParam == const $CopyWithPlaceholder() || calcParam == null
          ? _value.calcParam
          // ignore: cast_nullable_to_non_nullable
          : calcParam as SARParam,
      radius: radius == const $CopyWithPlaceholder()
          ? _value.radius
          // ignore: cast_nullable_to_non_nullable
          : radius as double?,
      paint: paint == const $CopyWithPlaceholder() || paint == null
          ? _value.paint
          // ignore: cast_nullable_to_non_nullable
          : paint as PaintConfig,
      tipsPadding:
          tipsPadding == const $CopyWithPlaceholder() || tipsPadding == null
              ? _value.tipsPadding
              // ignore: cast_nullable_to_non_nullable
              : tipsPadding as EdgeInsets,
      tipsStyle: tipsStyle == const $CopyWithPlaceholder() || tipsStyle == null
          ? _value.tipsStyle
          // ignore: cast_nullable_to_non_nullable
          : tipsStyle as TextStyle,
      tickCount: tickCount == const $CopyWithPlaceholder() || tickCount == null
          ? _value.tickCount
          // ignore: cast_nullable_to_non_nullable
          : tickCount as int,
    );
  }
}

extension $SARIndicatorCopyWith on SARIndicator {
  /// Returns a callable class that can be used as follows: `instanceOfSARIndicator.copyWith(...)` or like so:`instanceOfSARIndicator.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SARIndicatorCWProxy get copyWith => _$SARIndicatorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SARIndicator _$SARIndicatorFromJson(Map<String, dynamic> json) => SARIndicator(
      key: const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'SAR',
      height: (json['height'] as num).toDouble(),
      padding: json['padding'] == null
          ? defaultMainIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      calcParam: json['calcParam'] == null
          ? const SARParam(startAf: 0.02, step: 0.02, maxAf: 0.2)
          : SARParam.fromJson(json['calcParam'] as Map<String, dynamic>),
      radius: (json['radius'] as num?)?.toDouble(),
      paint: PaintConfig.fromJson(json['paint'] as Map<String, dynamic>),
      tipsPadding: const EdgeInsetsConverter()
          .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      tipsStyle: const TextStyleConverter()
          .fromJson(json['tipsStyle'] as Map<String, dynamic>),
      tickCount: (json['tickCount'] as num?)?.toInt() ?? defaultSubTickCount,
    );

Map<String, dynamic> _$SARIndicatorToJson(SARIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'zIndex': instance.zIndex,
      'calcParam': instance.calcParam.toJson(),
      'radius': instance.radius,
      'paint': instance.paint.toJson(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'tipsStyle': const TextStyleConverter().toJson(instance.tipsStyle),
      'tickCount': instance.tickCount,
    };
