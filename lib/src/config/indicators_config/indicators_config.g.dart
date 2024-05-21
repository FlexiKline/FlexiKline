// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicators_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndicatorsConfig _$IndicatorsConfigFromJson(Map<String, dynamic> json) =>
    IndicatorsConfig(
      candle: json['candle'] == null
          ? null
          : CandleIndicator.fromJson(json['candle'] as Map<String, dynamic>),
      volume: json['volume'] == null
          ? null
          : VolumeIndicator.fromJson(json['volume'] as Map<String, dynamic>),
      ma: json['ma'] == null
          ? null
          : MAIndicator.fromJson(json['ma'] as Map<String, dynamic>),
      ema: json['ema'] == null
          ? null
          : EMAIndicator.fromJson(json['ema'] as Map<String, dynamic>),
      boll: json['boll'] == null
          ? null
          : BOLLIndicator.fromJson(json['boll'] as Map<String, dynamic>),
      time: json['time'] == null
          ? null
          : TimeIndicator.fromJson(json['time'] as Map<String, dynamic>),
      macd: json['macd'] == null
          ? null
          : MACDIndicator.fromJson(json['macd'] as Map<String, dynamic>),
      kdj: json['kdj'] == null
          ? null
          : KDJIndicator.fromJson(json['kdj'] as Map<String, dynamic>),
      mavol: json['mavol'] == null
          ? null
          : MAVolumeIndicator.fromJson(json['mavol'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$IndicatorsConfigToJson(IndicatorsConfig instance) =>
    <String, dynamic>{
      'candle': instance.candle.toJson(),
      'volume': instance.volume.toJson(),
      'ma': instance.ma.toJson(),
      'ema': instance.ema.toJson(),
      'boll': instance.boll.toJson(),
      'time': instance.time.toJson(),
      'macd': instance.macd.toJson(),
      'kdj': instance.kdj.toJson(),
      'mavol': instance.mavol.toJson(),
    };
