// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CandleModelImpl _$$CandleModelImplFromJson(Map<String, dynamic> json) =>
    _$CandleModelImpl(
      open: valueToDecimal(json['open']),
      close: valueToDecimal(json['close']),
      high: valueToDecimal(json['high']),
      low: valueToDecimal(json['low']),
      volume: valueToDecimal(json['volume']),
      date: valueToDateTime(json['date']),
    );

Map<String, dynamic> _$$CandleModelImplToJson(_$CandleModelImpl instance) =>
    <String, dynamic>{
      'open': valueToString(instance.open),
      'close': valueToString(instance.close),
      'high': valueToString(instance.high),
      'low': valueToString(instance.low),
      'volume': valueToString(instance.volume),
      'date': dateTimeToString(instance.date),
    };
