// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VolumeIndicatorCWProxy {
  VolumeIndicator key(ValueKey<dynamic> key);

  VolumeIndicator name(String name);

  VolumeIndicator zIndex(int zIndex);

  VolumeIndicator height(double height);

  VolumeIndicator padding(EdgeInsets padding);

  VolumeIndicator paintMode(PaintMode paintMode);

  VolumeIndicator volTips(TipsConfig volTips);

  VolumeIndicator tipsPadding(EdgeInsets tipsPadding);

  VolumeIndicator tickCount(int tickCount);

  VolumeIndicator precision(int precision);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VolumeIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VolumeIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  VolumeIndicator call({
    ValueKey<dynamic>? key,
    String? name,
    int? zIndex,
    double? height,
    EdgeInsets? padding,
    PaintMode? paintMode,
    TipsConfig? volTips,
    EdgeInsets? tipsPadding,
    int? tickCount,
    int? precision,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfVolumeIndicator.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfVolumeIndicator.copyWith.fieldName(...)`
class _$VolumeIndicatorCWProxyImpl implements _$VolumeIndicatorCWProxy {
  const _$VolumeIndicatorCWProxyImpl(this._value);

  final VolumeIndicator _value;

  @override
  VolumeIndicator key(ValueKey<dynamic> key) => this(key: key);

  @override
  VolumeIndicator name(String name) => this(name: name);

  @override
  VolumeIndicator zIndex(int zIndex) => this(zIndex: zIndex);

  @override
  VolumeIndicator height(double height) => this(height: height);

  @override
  VolumeIndicator padding(EdgeInsets padding) => this(padding: padding);

  @override
  VolumeIndicator paintMode(PaintMode paintMode) => this(paintMode: paintMode);

  @override
  VolumeIndicator volTips(TipsConfig volTips) => this(volTips: volTips);

  @override
  VolumeIndicator tipsPadding(EdgeInsets tipsPadding) =>
      this(tipsPadding: tipsPadding);

  @override
  VolumeIndicator tickCount(int tickCount) => this(tickCount: tickCount);

  @override
  VolumeIndicator precision(int precision) => this(precision: precision);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VolumeIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VolumeIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  VolumeIndicator call({
    Object? key = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? zIndex = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? paintMode = const $CopyWithPlaceholder(),
    Object? volTips = const $CopyWithPlaceholder(),
    Object? tipsPadding = const $CopyWithPlaceholder(),
    Object? tickCount = const $CopyWithPlaceholder(),
    Object? precision = const $CopyWithPlaceholder(),
  }) {
    return VolumeIndicator(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as ValueKey<dynamic>,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      zIndex: zIndex == const $CopyWithPlaceholder() || zIndex == null
          ? _value.zIndex
          // ignore: cast_nullable_to_non_nullable
          : zIndex as int,
      height: height == const $CopyWithPlaceholder() || height == null
          ? _value.height
          // ignore: cast_nullable_to_non_nullable
          : height as double,
      padding: padding == const $CopyWithPlaceholder() || padding == null
          ? _value.padding
          // ignore: cast_nullable_to_non_nullable
          : padding as EdgeInsets,
      paintMode: paintMode == const $CopyWithPlaceholder() || paintMode == null
          ? _value.paintMode
          // ignore: cast_nullable_to_non_nullable
          : paintMode as PaintMode,
      volTips: volTips == const $CopyWithPlaceholder() || volTips == null
          ? _value.volTips
          // ignore: cast_nullable_to_non_nullable
          : volTips as TipsConfig,
      tipsPadding:
          tipsPadding == const $CopyWithPlaceholder() || tipsPadding == null
              ? _value.tipsPadding
              // ignore: cast_nullable_to_non_nullable
              : tipsPadding as EdgeInsets,
      tickCount: tickCount == const $CopyWithPlaceholder() || tickCount == null
          ? _value.tickCount
          // ignore: cast_nullable_to_non_nullable
          : tickCount as int,
      precision: precision == const $CopyWithPlaceholder() || precision == null
          ? _value.precision
          // ignore: cast_nullable_to_non_nullable
          : precision as int,
    );
  }
}

extension $VolumeIndicatorCopyWith on VolumeIndicator {
  /// Returns a callable class that can be used as follows: `instanceOfVolumeIndicator.copyWith(...)` or like so:`instanceOfVolumeIndicator.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VolumeIndicatorCWProxy get copyWith => _$VolumeIndicatorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VolumeIndicator _$VolumeIndicatorFromJson(Map<String, dynamic> json) =>
    VolumeIndicator(
      key: const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'VOL',
      zIndex: (json['zIndex'] as num?)?.toInt() ?? -2,
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      padding: json['padding'] == null
          ? defaultSubIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      paintMode: json['paintMode'] == null
          ? PaintMode.alone
          : const PaintModeConverter().fromJson(json['paintMode'] as String),
      volTips: TipsConfig.fromJson(json['volTips'] as Map<String, dynamic>),
      tipsPadding: const EdgeInsetsConverter()
          .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      tickCount: (json['tickCount'] as num?)?.toInt() ?? defaultSubTickCount,
      precision: (json['precision'] as num?)?.toInt() ?? 2,
    );

Map<String, dynamic> _$VolumeIndicatorToJson(VolumeIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'paintMode': const PaintModeConverter().toJson(instance.paintMode),
      'zIndex': instance.zIndex,
      'volTips': instance.volTips.toJson(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'tickCount': instance.tickCount,
      'precision': instance.precision,
    };
