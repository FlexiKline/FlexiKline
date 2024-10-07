// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'magnifier_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MagnifierConfigCWProxy {
  MagnifierConfig enable(bool enable);

  MagnifierConfig times(double times);

  MagnifierConfig opactity(double opactity);

  MagnifierConfig opactityWhenOverlap(double opactityWhenOverlap);

  MagnifierConfig margin(EdgeInsets margin);

  MagnifierConfig size(Size size);

  MagnifierConfig boder(BorderSide boder);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MagnifierConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MagnifierConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  MagnifierConfig call({
    bool? enable,
    double? times,
    double? opactity,
    double? opactityWhenOverlap,
    EdgeInsets? margin,
    Size? size,
    BorderSide? boder,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMagnifierConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMagnifierConfig.copyWith.fieldName(...)`
class _$MagnifierConfigCWProxyImpl implements _$MagnifierConfigCWProxy {
  const _$MagnifierConfigCWProxyImpl(this._value);

  final MagnifierConfig _value;

  @override
  MagnifierConfig enable(bool enable) => this(enable: enable);

  @override
  MagnifierConfig times(double times) => this(times: times);

  @override
  MagnifierConfig opactity(double opactity) => this(opactity: opactity);

  @override
  MagnifierConfig opactityWhenOverlap(double opactityWhenOverlap) =>
      this(opactityWhenOverlap: opactityWhenOverlap);

  @override
  MagnifierConfig margin(EdgeInsets margin) => this(margin: margin);

  @override
  MagnifierConfig size(Size size) => this(size: size);

  @override
  MagnifierConfig boder(BorderSide boder) => this(boder: boder);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MagnifierConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MagnifierConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  MagnifierConfig call({
    Object? enable = const $CopyWithPlaceholder(),
    Object? times = const $CopyWithPlaceholder(),
    Object? opactity = const $CopyWithPlaceholder(),
    Object? opactityWhenOverlap = const $CopyWithPlaceholder(),
    Object? margin = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
    Object? boder = const $CopyWithPlaceholder(),
  }) {
    return MagnifierConfig(
      enable: enable == const $CopyWithPlaceholder() || enable == null
          ? _value.enable
          // ignore: cast_nullable_to_non_nullable
          : enable as bool,
      times: times == const $CopyWithPlaceholder() || times == null
          ? _value.times
          // ignore: cast_nullable_to_non_nullable
          : times as double,
      opactity: opactity == const $CopyWithPlaceholder() || opactity == null
          ? _value.opactity
          // ignore: cast_nullable_to_non_nullable
          : opactity as double,
      opactityWhenOverlap:
          opactityWhenOverlap == const $CopyWithPlaceholder() ||
                  opactityWhenOverlap == null
              ? _value.opactityWhenOverlap
              // ignore: cast_nullable_to_non_nullable
              : opactityWhenOverlap as double,
      margin: margin == const $CopyWithPlaceholder() || margin == null
          ? _value.margin
          // ignore: cast_nullable_to_non_nullable
          : margin as EdgeInsets,
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as Size,
      boder: boder == const $CopyWithPlaceholder() || boder == null
          ? _value.boder
          // ignore: cast_nullable_to_non_nullable
          : boder as BorderSide,
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
      times: (json['times'] as num?)?.toDouble() ?? 2,
      opactity: (json['opactity'] as num?)?.toDouble() ?? 1.0,
      opactityWhenOverlap:
          (json['opactityWhenOverlap'] as num?)?.toDouble() ?? 0.75,
      margin: json['margin'] == null
          ? EdgeInsets.zero
          : const EdgeInsetsConverter()
              .fromJson(json['margin'] as Map<String, dynamic>),
      size: json['size'] == null
          ? const Size(80, 80)
          : const SizeConverter()
              .fromJson(json['size'] as Map<String, dynamic>),
      boder: json['boder'] == null
          ? BorderSide.none
          : const BorderSideConvert()
              .fromJson(json['boder'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MagnifierConfigToJson(MagnifierConfig instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'opactity': instance.opactity,
      'opactityWhenOverlap': instance.opactityWhenOverlap,
      'times': instance.times,
      'margin': const EdgeInsetsConverter().toJson(instance.margin),
      'size': const SizeConverter().toJson(instance.size),
      'boder': const BorderSideConvert().toJson(instance.boder),
    };
