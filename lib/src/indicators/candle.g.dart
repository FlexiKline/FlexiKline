// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CandleIndicator _$CandleIndicatorFromJson(Map<String, dynamic> json) =>
    CandleIndicator(
      key: json['key'] == null
          ? candleKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'Candle',
      height: (json['height'] as num).toDouble(),
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ?? 0.0,
      padding: json['padding'] == null
          ? defaultIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      latestPriceRectBackgroundColor: const ColorConverter()
          .fromJson(json['latestPriceRectBackgroundColor'] as String?),
    );

Map<String, dynamic> _$CandleIndicatorToJson(CandleIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
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
