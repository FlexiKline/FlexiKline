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

Map<String, dynamic> _$CandleModelToJson(CandleModel instance) {
  final val = <String, dynamic>{
    'timestamp': intToString(instance.timestamp),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('o', const DecimalConverter().toJson(instance.o));
  writeNotNull('h', const DecimalConverter().toJson(instance.h));
  writeNotNull('l', const DecimalConverter().toJson(instance.l));
  writeNotNull('c', const DecimalConverter().toJson(instance.c));
  writeNotNull('v', const DecimalConverter().toJson(instance.v));
  writeNotNull(
      'vc',
      _$JsonConverterToJson<dynamic, Decimal>(
          instance.vc, const DecimalConverter().toJson));
  writeNotNull(
      'vcq',
      _$JsonConverterToJson<dynamic, Decimal>(
          instance.vcq, const DecimalConverter().toJson));
  val['confirm'] = instance.confirm;
  return val;
}

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
