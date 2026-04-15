// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'magnifier_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MagnifierConfigCWProxy {
  MagnifierConfig enable(bool enable);

  MagnifierConfig margin(EdgeInsets margin);

  MagnifierConfig size(Size size);

  MagnifierConfig magnificationScale(double magnificationScale);

  MagnifierConfig clipBehavior(Clip clipBehavior);

  MagnifierConfig decorationOpacity(double decorationOpacity);

  MagnifierConfig decorationShadows(List<BoxShadow>? decorationShadows);

  MagnifierConfig shapeSide(BorderSide shapeSide);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MagnifierConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MagnifierConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  MagnifierConfig call({
    bool enable,
    EdgeInsets margin,
    Size size,
    double magnificationScale,
    Clip clipBehavior,
    double decorationOpacity,
    List<BoxShadow>? decorationShadows,
    BorderSide shapeSide,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMagnifierConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMagnifierConfig.copyWith.fieldName(...)`
class _$MagnifierConfigCWProxyImpl implements _$MagnifierConfigCWProxy {
  const _$MagnifierConfigCWProxyImpl(this._value);

  final MagnifierConfig _value;

  @override
  MagnifierConfig enable(bool enable) => this(enable: enable);

  @override
  MagnifierConfig margin(EdgeInsets margin) => this(margin: margin);

  @override
  MagnifierConfig size(Size size) => this(size: size);

  @override
  MagnifierConfig magnificationScale(double magnificationScale) =>
      this(magnificationScale: magnificationScale);

  @override
  MagnifierConfig clipBehavior(Clip clipBehavior) =>
      this(clipBehavior: clipBehavior);

  @override
  MagnifierConfig decorationOpacity(double decorationOpacity) =>
      this(decorationOpacity: decorationOpacity);

  @override
  MagnifierConfig decorationShadows(List<BoxShadow>? decorationShadows) =>
      this(decorationShadows: decorationShadows);

  @override
  MagnifierConfig shapeSide(BorderSide shapeSide) => this(shapeSide: shapeSide);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MagnifierConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MagnifierConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  MagnifierConfig call({
    Object? enable = const $CopyWithPlaceholder(),
    Object? margin = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
    Object? magnificationScale = const $CopyWithPlaceholder(),
    Object? clipBehavior = const $CopyWithPlaceholder(),
    Object? decorationOpacity = const $CopyWithPlaceholder(),
    Object? decorationShadows = const $CopyWithPlaceholder(),
    Object? shapeSide = const $CopyWithPlaceholder(),
  }) {
    return MagnifierConfig(
      enable: enable == const $CopyWithPlaceholder()
          ? _value.enable
          // ignore: cast_nullable_to_non_nullable
          : enable as bool,
      margin: margin == const $CopyWithPlaceholder()
          ? _value.margin
          // ignore: cast_nullable_to_non_nullable
          : margin as EdgeInsets,
      size: size == const $CopyWithPlaceholder()
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as Size,
      magnificationScale: magnificationScale == const $CopyWithPlaceholder()
          ? _value.magnificationScale
          // ignore: cast_nullable_to_non_nullable
          : magnificationScale as double,
      clipBehavior: clipBehavior == const $CopyWithPlaceholder()
          ? _value.clipBehavior
          // ignore: cast_nullable_to_non_nullable
          : clipBehavior as Clip,
      decorationOpacity: decorationOpacity == const $CopyWithPlaceholder()
          ? _value.decorationOpacity
          // ignore: cast_nullable_to_non_nullable
          : decorationOpacity as double,
      decorationShadows: decorationShadows == const $CopyWithPlaceholder()
          ? _value.decorationShadows
          // ignore: cast_nullable_to_non_nullable
          : decorationShadows as List<BoxShadow>?,
      shapeSide: shapeSide == const $CopyWithPlaceholder()
          ? _value.shapeSide
          // ignore: cast_nullable_to_non_nullable
          : shapeSide as BorderSide,
    );
  }
}

extension $MagnifierConfigCopyWith on MagnifierConfig {
  /// Returns a callable class that can be used as follows: `instanceOfMagnifierConfig.copyWith(...)` or like so:`instanceOfMagnifierConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MagnifierConfigCWProxy get copyWith => _$MagnifierConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MagnifierConfig _$MagnifierConfigFromJson(Map<String, dynamic> json) =>
    MagnifierConfig(
      enable: json['enable'] as bool? ?? true,
      margin: json['margin'] == null
          ? const EdgeInsets.all(1)
          : const EdgeInsetsConverter()
              .fromJson(json['margin'] as Map<String, dynamic>),
      size: json['size'] == null
          ? const Size(80, 80)
          : const SizeConverter()
              .fromJson(json['size'] as Map<String, dynamic>),
      magnificationScale: (json['magnificationScale'] as num?)?.toDouble() ?? 2,
      clipBehavior: json['clipBehavior'] == null
          ? Clip.none
          : const ClipConverter().fromJson(json['clipBehavior'] as String),
      decorationOpacity: (json['decorationOpacity'] as num?)?.toDouble() ?? 1.0,
      decorationShadows: (json['decorationShadows'] as List<dynamic>?)
          ?.map((e) =>
              const BoxShadowConverter().fromJson(e as Map<String, dynamic>))
          .toList(),
      shapeSide: json['shapeSide'] == null
          ? BorderSide.none
          : const BorderSideConvert()
              .fromJson(json['shapeSide'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MagnifierConfigToJson(MagnifierConfig instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'margin': const EdgeInsetsConverter().toJson(instance.margin),
      'size': const SizeConverter().toJson(instance.size),
      'magnificationScale': instance.magnificationScale,
      'clipBehavior': const ClipConverter().toJson(instance.clipBehavior),
      'decorationOpacity': instance.decorationOpacity,
      if (instance.decorationShadows
              ?.map(const BoxShadowConverter().toJson)
              .toList()
          case final value?)
        'decorationShadows': value,
      'shapeSide': const BorderSideConvert().toJson(instance.shapeSide),
    };
