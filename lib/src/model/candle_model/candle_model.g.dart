// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CandleModel _$CandleModelFromJson(Map<String, dynamic> json) => CandleModel(
      timestamp: valueToInt(json['timestamp']),
      open: const DecimalConverter().fromJson(json['open']),
      high: const DecimalConverter().fromJson(json['high']),
      low: const DecimalConverter().fromJson(json['low']),
      close: const DecimalConverter().fromJson(json['close']),
      vol: const DecimalConverter().fromJson(json['vol']),
      volCcy: const DecimalConverter().fromJson(json['volCcy']),
      volCcyQuote: const DecimalConverter().fromJson(json['volCcyQuote']),
      confirm: json['confirm'] as String? ?? '1',
    );

Map<String, dynamic> _$CandleModelToJson(CandleModel instance) =>
    <String, dynamic>{
      'timestamp': intToString(instance.timestamp),
      'open': const DecimalConverter().toJson(instance.open),
      'high': const DecimalConverter().toJson(instance.high),
      'low': const DecimalConverter().toJson(instance.low),
      'close': const DecimalConverter().toJson(instance.close),
      'vol': const DecimalConverter().toJson(instance.vol),
      'volCcy': _$JsonConverterToJson<dynamic, Decimal>(
          instance.volCcy, const DecimalConverter().toJson),
      'volCcyQuote': _$JsonConverterToJson<dynamic, Decimal>(
          instance.volCcyQuote, const DecimalConverter().toJson),
      'confirm': instance.confirm,
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
