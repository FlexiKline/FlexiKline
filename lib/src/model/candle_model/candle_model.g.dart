// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CandleModel _$CandleModelFromJson(Map<String, dynamic> json) => CandleModel(
      timestamp: valueToInt(json['timestamp']),
      o: const DecimalConverter().fromJson(json['o']),
      h: const DecimalConverter().fromJson(json['h']),
      l: const DecimalConverter().fromJson(json['l']),
      c: const DecimalConverter().fromJson(json['c']),
      v: const DecimalConverter().fromJson(json['v']),
      vc: const DecimalConverter().fromJson(json['vc']),
      vcq: const DecimalConverter().fromJson(json['vcq']),
      confirm: json['confirm'] as String? ?? '1',
    );

Map<String, dynamic> _$CandleModelToJson(CandleModel instance) =>
    <String, dynamic>{
      'timestamp': intToString(instance.timestamp),
      'o': const DecimalConverter().toJson(instance.o),
      'h': const DecimalConverter().toJson(instance.h),
      'l': const DecimalConverter().toJson(instance.l),
      'c': const DecimalConverter().toJson(instance.c),
      'v': const DecimalConverter().toJson(instance.v),
      'vc': _$JsonConverterToJson<dynamic, Decimal>(
          instance.vc, const DecimalConverter().toJson),
      'vcq': _$JsonConverterToJson<dynamic, Decimal>(
          instance.vcq, const DecimalConverter().toJson),
      'confirm': instance.confirm,
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
