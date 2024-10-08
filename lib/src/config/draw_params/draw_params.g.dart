// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draw_params.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DrawParamsCWProxy {
  DrawParams arrowsRadians(double arrowsRadians);

  DrawParams arrowsLen(double arrowsLen);

  DrawParams priceText(TextAreaConfig? priceText);

  DrawParams priceTextMargin(EdgeInsets priceTextMargin);

  DrawParams angleText(TextAreaConfig? angleText);

  DrawParams angleBaseLineMinLen(double angleBaseLineMinLen);

  DrawParams angleRadSize(Size angleRadSize);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DrawParams(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DrawParams(...).copyWith(id: 12, name: "My name")
  /// ````
  DrawParams call({
    double? arrowsRadians,
    double? arrowsLen,
    TextAreaConfig? priceText,
    EdgeInsets? priceTextMargin,
    TextAreaConfig? angleText,
    double? angleBaseLineMinLen,
    Size? angleRadSize,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDrawParams.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDrawParams.copyWith.fieldName(...)`
class _$DrawParamsCWProxyImpl implements _$DrawParamsCWProxy {
  const _$DrawParamsCWProxyImpl(this._value);

  final DrawParams _value;

  @override
  DrawParams arrowsRadians(double arrowsRadians) =>
      this(arrowsRadians: arrowsRadians);

  @override
  DrawParams arrowsLen(double arrowsLen) => this(arrowsLen: arrowsLen);

  @override
  DrawParams priceText(TextAreaConfig? priceText) => this(priceText: priceText);

  @override
  DrawParams priceTextMargin(EdgeInsets priceTextMargin) =>
      this(priceTextMargin: priceTextMargin);

  @override
  DrawParams angleText(TextAreaConfig? angleText) => this(angleText: angleText);

  @override
  DrawParams angleBaseLineMinLen(double angleBaseLineMinLen) =>
      this(angleBaseLineMinLen: angleBaseLineMinLen);

  @override
  DrawParams angleRadSize(Size angleRadSize) =>
      this(angleRadSize: angleRadSize);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DrawParams(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DrawParams(...).copyWith(id: 12, name: "My name")
  /// ````
  DrawParams call({
    Object? arrowsRadians = const $CopyWithPlaceholder(),
    Object? arrowsLen = const $CopyWithPlaceholder(),
    Object? priceText = const $CopyWithPlaceholder(),
    Object? priceTextMargin = const $CopyWithPlaceholder(),
    Object? angleText = const $CopyWithPlaceholder(),
    Object? angleBaseLineMinLen = const $CopyWithPlaceholder(),
    Object? angleRadSize = const $CopyWithPlaceholder(),
  }) {
    return DrawParams(
      arrowsRadians:
          arrowsRadians == const $CopyWithPlaceholder() || arrowsRadians == null
              ? _value.arrowsRadians
              // ignore: cast_nullable_to_non_nullable
              : arrowsRadians as double,
      arrowsLen: arrowsLen == const $CopyWithPlaceholder() || arrowsLen == null
          ? _value.arrowsLen
          // ignore: cast_nullable_to_non_nullable
          : arrowsLen as double,
      priceText: priceText == const $CopyWithPlaceholder()
          ? _value.priceText
          // ignore: cast_nullable_to_non_nullable
          : priceText as TextAreaConfig?,
      priceTextMargin: priceTextMargin == const $CopyWithPlaceholder() ||
              priceTextMargin == null
          ? _value.priceTextMargin
          // ignore: cast_nullable_to_non_nullable
          : priceTextMargin as EdgeInsets,
      angleText: angleText == const $CopyWithPlaceholder()
          ? _value.angleText
          // ignore: cast_nullable_to_non_nullable
          : angleText as TextAreaConfig?,
      angleBaseLineMinLen:
          angleBaseLineMinLen == const $CopyWithPlaceholder() ||
                  angleBaseLineMinLen == null
              ? _value.angleBaseLineMinLen
              // ignore: cast_nullable_to_non_nullable
              : angleBaseLineMinLen as double,
      angleRadSize:
          angleRadSize == const $CopyWithPlaceholder() || angleRadSize == null
              ? _value.angleRadSize
              // ignore: cast_nullable_to_non_nullable
              : angleRadSize as Size,
    );
  }
}

extension $DrawParamsCopyWith on DrawParams {
  /// Returns a callable class that can be used as follows: `instanceOfDrawParams.copyWith(...)` or like so:`instanceOfDrawParams.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DrawParamsCWProxy get copyWith => _$DrawParamsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrawParams _$DrawParamsFromJson(Map<String, dynamic> json) => DrawParams(
      arrowsRadians: (json['arrowsRadians'] as num?)?.toDouble() ?? pi30,
      arrowsLen: (json['arrowsLen'] as num?)?.toDouble() ?? 16.0,
      priceText: json['priceText'] == null
          ? null
          : TextAreaConfig.fromJson(json['priceText'] as Map<String, dynamic>),
      priceTextMargin: json['priceTextMargin'] == null
          ? EdgeInsets.zero
          : const EdgeInsetsConverter()
              .fromJson(json['priceTextMargin'] as Map<String, dynamic>),
      angleText: json['angleText'] == null
          ? null
          : TextAreaConfig.fromJson(json['angleText'] as Map<String, dynamic>),
      angleBaseLineMinLen:
          (json['angleBaseLineMinLen'] as num?)?.toDouble() ?? 80,
      angleRadSize: json['angleRadSize'] == null
          ? const Size(50, 50)
          : const SizeConverter()
              .fromJson(json['angleRadSize'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DrawParamsToJson(DrawParams instance) {
  final val = <String, dynamic>{
    'arrowsRadians': instance.arrowsRadians,
    'arrowsLen': instance.arrowsLen,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('priceText', instance.priceText?.toJson());
  val['priceTextMargin'] =
      const EdgeInsetsConverter().toJson(instance.priceTextMargin);
  writeNotNull('angleText', instance.angleText?.toJson());
  val['angleBaseLineMinLen'] = instance.angleBaseLineMinLen;
  val['angleRadSize'] = const SizeConverter().toJson(instance.angleRadSize);
  return val;
}
