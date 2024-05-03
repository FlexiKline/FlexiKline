// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CandleReqImpl _$$CandleReqImplFromJson(Map<String, dynamic> json) =>
    _$CandleReqImpl(
      instId: json['instId'] as String,
      after: (json['after'] as num?)?.toInt(),
      before: (json['before'] as num?)?.toInt(),
      bar: json['bar'] as String? ?? "1m",
      limit: (json['limit'] as num?)?.toInt() ?? 100,
      precision: (json['precision'] as num?)?.toInt() ?? 6,
    );

Map<String, dynamic> _$$CandleReqImplToJson(_$CandleReqImpl instance) =>
    <String, dynamic>{
      'instId': instance.instId,
      'after': instance.after,
      'before': instance.before,
      'bar': instance.bar,
      'limit': instance.limit,
      'precision': instance.precision,
    };
