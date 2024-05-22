// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'macd_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MACDParam _$MACDParamFromJson(Map<String, dynamic> json) => MACDParam(
      s: (json['s'] as num).toInt(),
      l: (json['l'] as num).toInt(),
      m: (json['m'] as num).toInt(),
    );

Map<String, dynamic> _$MACDParamToJson(MACDParam instance) => <String, dynamic>{
      's': instance.s,
      'l': instance.l,
      'm': instance.m,
    };
