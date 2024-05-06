// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CandleReq _$CandleReqFromJson(Map<String, dynamic> json) => CandleReq(
      instId: json['instId'] as String,
      bar: json['bar'] as String? ?? '1m',
      limit: (json['limit'] as num?)?.toInt() ?? 100,
      precision: (json['precision'] as num?)?.toInt() ?? 4,
      after: (json['after'] as num?)?.toInt(),
      before: (json['before'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CandleReqToJson(CandleReq instance) => <String, dynamic>{
      'instId': instance.instId,
      'after': instance.after,
      'before': instance.before,
      'bar': instance.bar,
      'limit': instance.limit,
      'precision': instance.precision,
    };
