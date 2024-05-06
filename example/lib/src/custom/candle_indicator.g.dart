// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_indicator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomCandleIndicator _$CustomCandleIndicatorFromJson(
        Map<String, dynamic> json) =>
    CustomCandleIndicator(
      height: (json['height'] as num).toDouble(),
      latestPriceRectBackgroundColor: const ColorConverter()
          .fromJson(json['latestPriceRectBackgroundColor'] as String?),
    )
      ..tipsHeight = (json['tipsHeight'] as num).toDouble()
      ..padding = const EdgeInsetsConverter()
          .fromJson(json['padding'] as Map<String, dynamic>);

Map<String, dynamic> _$CustomCandleIndicatorToJson(
        CustomCandleIndicator instance) =>
    <String, dynamic>{
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'latestPriceRectBackgroundColor': _$JsonConverterToJson<String?, Color>(
          instance.latestPriceRectBackgroundColor,
          const ColorConverter().toJson),
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
