// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VolumeIndicatorCWProxy {
  VolumeIndicator zIndex(int zIndex);

  VolumeIndicator height(double height);

  VolumeIndicator padding(EdgeInsets padding);

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
    int? zIndex,
    double? height,
    EdgeInsets? padding,
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
  VolumeIndicator zIndex(int zIndex) => this(zIndex: zIndex);

  @override
  VolumeIndicator height(double height) => this(height: height);

  @override
  VolumeIndicator padding(EdgeInsets padding) => this(padding: padding);

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
    Object? zIndex = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? volTips = const $CopyWithPlaceholder(),
    Object? tipsPadding = const $CopyWithPlaceholder(),
    Object? tickCount = const $CopyWithPlaceholder(),
    Object? precision = const $CopyWithPlaceholder(),
  }) {
    return VolumeIndicator(
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
      zIndex: (json['zIndex'] as num?)?.toInt() ?? -2,
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      padding: json['padding'] == null
          ? defaultSubIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      volTips: TipsConfig.fromJson(json['volTips'] as Map<String, dynamic>),
      tipsPadding: const EdgeInsetsConverter()
          .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      tickCount: (json['tickCount'] as num?)?.toInt() ?? defaultSubTickCount,
      precision: (json['precision'] as num?)?.toInt() ?? 2,
    );

Map<String, dynamic> _$VolumeIndicatorToJson(VolumeIndicator instance) =>
    <String, dynamic>{
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'zIndex': instance.zIndex,
      'volTips': instance.volTips.toJson(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'tickCount': instance.tickCount,
      'precision': instance.precision,
    };
