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
  return val;
}
