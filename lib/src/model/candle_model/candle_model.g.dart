// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CandleModelImpl _$$CandleModelImplFromJson(Map<String, dynamic> json) =>
    _$CandleModelImpl(
      timestamp: json['timestamp'] as int,
      dateTime: valueToDateTime(json['dateTime']),
      open: stringToDecimal(json['open']),
      high: stringToDecimal(json['high']),
      low: stringToDecimal(json['low']),
      close: stringToDecimal(json['close']),
      vol: stringToDecimal(json['vol']),
      volCcy: stringToDecimalOrNull(json['volCcy']),
      volCcyQuote: stringToDecimalOrNull(json['volCcyQuote']),
      confirm: json['confirm'] as String? ?? "1",
    );

Map<String, dynamic> _$$CandleModelImplToJson(_$CandleModelImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'dateTime': dateTimeToInt(instance.dateTime),
      'open': decimalToString(instance.open),
      'high': decimalToString(instance.high),
      'low': decimalToString(instance.low),
      'close': decimalToString(instance.close),
      'vol': decimalToString(instance.vol),
      'volCcy': decimalToStringOrNull(instance.volCcy),
      'volCcyQuote': decimalToStringOrNull(instance.volCcyQuote),
      'confirm': instance.confirm,
    };
